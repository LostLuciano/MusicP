import Foundation
import AVFoundation

/// Provides a precise click-track metronome using AVAudioEngine scheduled buffers.
/// Uses the three click sounds from Stemz.app:
///   - click-downbeat.m4a  → Beat 1 (strong accent)
///   - click-upbeat.m4a    → Beat 2, 3, 4 (soft)
///   - click-subbeat.m4a   → Subdivision (e.g., 8th notes)
public class MetronomeManager {

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    private var downbeatBuffer: AVAudioPCMBuffer?
    private var upbeatBuffer:   AVAudioPCMBuffer?
    private var subbeatBuffer:  AVAudioPCMBuffer?

    private var bpm: Double = 120.0
    private var beatsPerBar: Int = 4
    private var subdivisions: Int = 1  // 1 = quarter, 2 = eighth

    private var isRunning = false
    private var currentBeat = 0
    private var schedulingTimer: Timer?

    public init() {
        loadClickBuffers()
        setupEngine()
    }

    private func loadClickBuffers() {
        downbeatBuffer = loadBuffer(named: "click-downbeat", ext: "m4a")
        upbeatBuffer   = loadBuffer(named: "click-upbeat",   ext: "m4a")
        subbeatBuffer  = loadBuffer(named: "click-subbeat",  ext: "m4a")
    }

    private func loadBuffer(named name: String, ext: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("MetronomeManager: Could not find \(name).\(ext) in bundle.")
            return nil
        }
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try file.read(into: buffer)
            return buffer
        } catch {
            print("MetronomeManager: Failed to load \(name): \(error.localizedDescription)")
            return nil
        }
    }

    private func setupEngine() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        do {
            try engine.start()
        } catch {
            print("MetronomeManager: Failed to start engine: \(error.localizedDescription)")
        }
    }

    /// Start the metronome at the given BPM, time signature, and subdivision.
    public func start(bpm: Double, beatsPerBar: Int = 4, subdivisions: Int = 1) {
        guard !isRunning else { return }
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.subdivisions = subdivisions
        self.currentBeat = 0
        isRunning = true

        playerNode.play()
        scheduleTick()
    }

    /// Stop the metronome.
    public func stop() {
        isRunning = false
        schedulingTimer?.invalidate()
        schedulingTimer = nil
        playerNode.stop()
    }

    public func updateBPM(_ newBPM: Double) {
        let wasRunning = isRunning
        if wasRunning { stop() }
        bpm = newBPM
        if wasRunning { start(bpm: newBPM, beatsPerBar: beatsPerBar, subdivisions: subdivisions) }
    }

    private func scheduleTick() {
        guard isRunning else { return }

        let intervalSeconds = 60.0 / (bpm * Double(subdivisions))
        let isDownbeat = (currentBeat % (beatsPerBar * subdivisions)) == 0
        let isMainBeat = (currentBeat % subdivisions) == 0

        let buffer: AVAudioPCMBuffer?
        if isDownbeat {
            buffer = downbeatBuffer
        } else if isMainBeat {
            buffer = upbeatBuffer
        } else {
            buffer = subbeatBuffer
        }

        if let buf = buffer {
            playerNode.scheduleBuffer(buf, completionHandler: nil)
        }

        currentBeat += 1

        schedulingTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: false) { [weak self] _ in
            self?.scheduleTick()
        }
    }

    deinit {
        stop()
        engine.stop()
    }
}
