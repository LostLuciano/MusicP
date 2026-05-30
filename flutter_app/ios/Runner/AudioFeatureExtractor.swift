import Foundation
import AVFoundation
import Accelerate

/// Real DSP feature extraction using Apple's Accelerate framework (vDSP).
/// Provides STFT, iSTFT, log-mel spectrogram, and chroma extraction
/// needed by CoreMLStemSeparator and ChordDetectionManager.
public class AudioFeatureExtractor {

    public init() {}

    // MARK: - Resampling

    /// Resamples an AVAudioPCMBuffer to a target sample rate using AVAudioConverter.
    public func resampleAudio(inputBuffer: AVAudioPCMBuffer, targetSampleRate: Double) -> AVAudioPCMBuffer? {
        let inputFormat = inputBuffer.format
        guard inputFormat.sampleRate != targetSampleRate else { return inputBuffer }

        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: inputFormat.channelCount,
            interleaved: false
        ) else { return nil }

        let ratio = targetSampleRate / inputFormat.sampleRate
        let estimatedFrames = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 512
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: estimatedFrames),
              let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else { return nil }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        if let err = error {
            print("AudioFeatureExtractor: Resampling error: \(err.localizedDescription)")
            return nil
        }
        print("AudioFeatureExtractor: Resampled \(Int(inputFormat.sampleRate))Hz → \(Int(targetSampleRate))Hz")
        return outputBuffer
    }

    // MARK: - STFT

    /// Computes STFT using vDSP FFT. Returns [frame][bin] complex magnitude arrays.
    /// Output shape: [timeFrames][nFFT/2+1] for magnitude; separate real/imag.
    public func computeSTFT(
        pcmBuffer: AVAudioPCMBuffer,
        nFFT: Int = 4096,
        hopSize: Int = 1024
    ) -> (real: [[Float]], imag: [[Float]]) {
        guard let channelData = pcmBuffer.floatChannelData else { return ([], []) }
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(pcmBuffer.frameLength)))

        let log2n = vDSP_Length(log2(Double(nFFT)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return ([], []) }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        let halfN = nFFT / 2
        var hanningWindow = [Float](repeating: 0, count: nFFT)
        vDSP_hann_window(&hanningWindow, vDSP_Length(nFFT), Int32(vDSP_HANN_NORM))

        var realFrames: [[Float]] = []
        var imagFrames: [[Float]] = []

        var frameStart = 0
        while frameStart + nFFT <= samples.count {
            var windowed = [Float](repeating: 0, count: nFFT)
            let frameSlice = Array(samples[frameStart..<(frameStart + nFFT)])
            vDSP_vmul(frameSlice, 1, hanningWindow, 1, &windowed, 1, vDSP_Length(nFFT))

            var realPart = [Float](repeating: 0, count: halfN)
            var imagPart = [Float](repeating: 0, count: halfN)

            windowed.withUnsafeMutableBufferPointer { ptr in
                var splitComplex = DSPSplitComplex(
                    realp: realPart.withUnsafeMutableBufferPointer { $0.baseAddress! },
                    imagp: imagPart.withUnsafeMutableBufferPointer { $0.baseAddress! }
                )
                // Pack real signal into split complex (interleaved trick)
                ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                    vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(halfN))
                }
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                // Scale
                var scale = Float(1.0 / Float(nFFT))
                vDSP_vsmul(realPart, 1, &scale, &realPart, 1, vDSP_Length(halfN))
                vDSP_vsmul(imagPart, 1, &scale, &imagPart, 1, vDSP_Length(halfN))
            }

            realFrames.append(realPart)
            imagFrames.append(imagPart)
            frameStart += hopSize
        }

        print("AudioFeatureExtractor: STFT computed — \(realFrames.count) frames × \(halfN) bins")
        return (realFrames, imagFrames)
    }

    // MARK: - iSTFT

    /// Reconstructs time-domain signal from STFT frames using overlap-add synthesis.
    public func computeISTFT(
        real: [[Float]],
        imag: [[Float]],
        nFFT: Int = 4096,
        hopSize: Int = 1024,
        sampleRate: Double = 44100.0
    ) -> AVAudioPCMBuffer? {
        guard !real.isEmpty, real.count == imag.count else { return nil }
        let log2n = vDSP_Length(log2(Double(nFFT)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        let halfN = nFFT / 2
        let totalFrames = (real.count - 1) * hopSize + nFFT
        var output = [Float](repeating: 0, count: totalFrames)

        var hanningWindow = [Float](repeating: 0, count: nFFT)
        vDSP_hann_window(&hanningWindow, vDSP_Length(nFFT), Int32(vDSP_HANN_NORM))

        for (frameIdx, (realFrame, imagFrame)) in zip(real, imag).enumerated() {
            var rPart = realFrame
            var iPart = imagFrame

            var splitComplex = DSPSplitComplex(
                realp: &rPart,
                imagp: &iPart
            )
            vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_INVERSE))

            var timeDomain = [Float](repeating: 0, count: nFFT)
            timeDomain.withUnsafeMutableBufferPointer { ptr in
                ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { dst in
                    vDSP_ztoc(&splitComplex, 1, dst, 2, vDSP_Length(halfN))
                }
            }

            // Apply synthesis window and overlap-add
            var windowed = [Float](repeating: 0, count: nFFT)
            vDSP_vmul(timeDomain, 1, hanningWindow, 1, &windowed, 1, vDSP_Length(nFFT))

            let offset = frameIdx * hopSize
            for i in 0..<nFFT {
                if offset + i < output.count {
                    output[offset + i] += windowed[i]
                }
            }
        }

        // Normalize
        var maxVal: Float = 0
        vDSP_maxv(output, 1, &maxVal, vDSP_Length(output.count))
        if maxVal > 0 {
            var scale = 1.0 / maxVal
            vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
        }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ), let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(output.count)
        ) else { return nil }

        pcmBuffer.frameLength = AVAudioFrameCount(output.count)
        pcmBuffer.floatChannelData![0].assign(from: output, count: output.count)

        print("AudioFeatureExtractor: iSTFT → \(output.count) samples")
        return pcmBuffer
    }

    // MARK: - Log-Mel Spectrogram

    /// Computes a log-mel spectrogram using vDSP FFT + triangular mel filterbank.
    /// Returns [timeFrames][melBins] with 128 mel bins at 44.1kHz.
    public func computeLogMelSpectrogram(
        pcmBuffer: AVAudioPCMBuffer,
        nFFT: Int = 2048,
        hopSize: Int = 512,
        nMels: Int = 128,
        fMin: Float = 0.0,
        fMax: Float = 8000.0
    ) -> [[Float]] {
        let (realFrames, imagFrames) = computeSTFT(pcmBuffer: pcmBuffer, nFFT: nFFT, hopSize: hopSize)
        guard !realFrames.isEmpty else { return [] }

        let sampleRate = Float(pcmBuffer.format.sampleRate)
        let halfN = nFFT / 2

        // Build mel filterbank
        let melFilters = buildMelFilterbank(nFFT: nFFT, nMels: nMels, sampleRate: sampleRate, fMin: fMin, fMax: fMax)

        var melSpectrogram: [[Float]] = []

        for (realFrame, imagFrame) in zip(realFrames, imagFrames) {
            // Power spectrum: |real|^2 + |imag|^2
            var power = [Float](repeating: 0, count: halfN)
            vDSP_distancesq(realFrame, 1, imagFrame, 1, &power, 1, vDSP_Length(halfN))

            // Apply mel filterbank
            var melEnergies = [Float](repeating: 0, count: nMels)
            for m in 0..<nMels {
                var energy: Float = 0
                vDSP_dotpr(power, 1, melFilters[m], 1, &energy, vDSP_Length(halfN))
                // Log compression: log(energy + epsilon)
                melEnergies[m] = log(max(energy, 1e-10))
            }
            melSpectrogram.append(melEnergies)
        }

        print("AudioFeatureExtractor: Log-mel spectrogram: \(melSpectrogram.count) frames × \(nMels) mel bins")
        return melSpectrogram
    }

    private func buildMelFilterbank(nFFT: Int, nMels: Int, sampleRate: Float, fMin: Float, fMax: Float) -> [[Float]] {
        let halfN = nFFT / 2
        func hzToMel(_ hz: Float) -> Float { return 2595 * log10(1 + hz / 700) }
        func melToHz(_ mel: Float) -> Float { return 700 * (pow(10, mel / 2595) - 1) }

        let melMin = hzToMel(fMin)
        let melMax = hzToMel(fMax)
        var melPoints = [Float](repeating: 0, count: nMels + 2)
        for i in 0..<(nMels + 2) {
            let mel = melMin + Float(i) * (melMax - melMin) / Float(nMels + 1)
            melPoints[i] = melToHz(mel)
        }

        let freqBinWidth = sampleRate / Float(nFFT)
        var filters = [[Float]](repeating: [Float](repeating: 0, count: halfN), count: nMels)

        for m in 0..<nMels {
            let lo = melPoints[m]
            let mid = melPoints[m + 1]
            let hi = melPoints[m + 2]
            for k in 0..<halfN {
                let freq = Float(k) * freqBinWidth
                if freq >= lo && freq <= mid {
                    filters[m][k] = (freq - lo) / (mid - lo)
                } else if freq > mid && freq <= hi {
                    filters[m][k] = (hi - freq) / (hi - mid)
                }
            }
        }
        return filters
    }

    // MARK: - Chroma (NNLS approximation)

    /// Computes a 12-bin chromagram from a PCM buffer.
    /// Returns [timeFrames][12] pitch class energies.
    public func computeChroma(pcmBuffer: AVAudioPCMBuffer, nFFT: Int = 4096, hopSize: Int = 2048) -> [[Float]] {
        let (realFrames, imagFrames) = computeSTFT(pcmBuffer: pcmBuffer, nFFT: nFFT, hopSize: hopSize)
        guard !realFrames.isEmpty else { return [] }

        let sampleRate = Float(pcmBuffer.format.sampleRate)
        let halfN = nFFT / 2
        var chromaFrames: [[Float]] = []

        for (realFrame, imagFrame) in zip(realFrames, imagFrames) {
            var power = [Float](repeating: 0, count: halfN)
            vDSP_distancesq(realFrame, 1, imagFrame, 1, &power, 1, vDSP_Length(halfN))

            var chroma = [Float](repeating: 0, count: 12)
            let binWidth = sampleRate / Float(nFFT)

            for k in 1..<halfN {
                let freq = Float(k) * binWidth
                guard freq > 0 else { continue }
                // Map frequency to MIDI note and then pitch class
                let midi = 69.0 + 12.0 * log2(freq / 440.0)
                let pitchClass = Int(midi.truncatingRemainder(dividingBy: 12))
                let idx = ((pitchClass % 12) + 12) % 12
                chroma[idx] += power[k]
            }

            // Normalize
            var norm: Float = 0
            vDSP_svesq(chroma, 1, &norm, 12)
            norm = sqrtf(norm)
            if norm > 0 {
                var invNorm = 1.0 / norm
                vDSP_vsmul(chroma, 1, &invNorm, &chroma, 1, 12)
            }
            chromaFrames.append(chroma)
        }

        print("AudioFeatureExtractor: Chroma: \(chromaFrames.count) frames × 12 pitch classes")
        return chromaFrames
    }
}
