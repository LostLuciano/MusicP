# AI / ML Model Requirements Specification

This document details the target schemas, architectural constraints, and tensor formats for integrating CoreML models into the local audio pipeline.

---

## 1. Stem Separation Model

* **Architecture**: Dense Spectrogram U-Net (TFC-TDF or similar) or HTDemucs.
* **Target Outputs (6 Stems)**: Vocals, Drums, Bass, Guitar, Piano, Other.
* **Inference Precisions**: 
  * *High-Performance*: Float32 (recommended for Apple Neural Engine).
  * *Low-Latency / Mobile*: Float16 (recommended to reduce footprint to ~10MB).
* **Sample Rate**: 44,100 Hz.
* **DSP Pre-processing**:
  * Short-Time Fourier Transform (STFT) with FFT size of 4096 (standard) or 2048 (light).
  * Hop size of 1024 frames.
* **Input Tensor Shape (`mixture`)**: `[1, 4, TimeFrames, FreqBins]`
  * Channel 0: Left Real component of STFT.
  * Channel 1: Left Imaginary component of STFT.
  * Channel 2: Right Real component of STFT.
  * Channel 3: Right Imaginary component of STFT.
  * TimeFrames: 32 or 64 frames (approx. 0.74s to 1.48s chunks).
  * FreqBins: 2048 or 1024 bins (frequency resolution).
* **Output Tensors**: 6 distinct tensors matching the input shape (`[1, 4, TimeFrames, FreqBins]`). Each represents the complex ideal ratio mask (cIRM) or direct spectrogram output for a stem.

---

## 2. Chord Detection Model

* **Architecture**: Convolutional Recurrent Neural Network (CRNN).
* **Input Tensor Shape (`bothchroma`)**: `[1, TimeSlices, ChromaBins]`
  * TimeSlices: Sequence length representing temporal alignment (e.g., 320 slices).
  * ChromaBins: 24 bins (stacked chromagram combining multiple pitch profile extractions).
* **Output Tensor Shape (`logits`)**: `[1, TimeSlices, ClassCount]`
  * ClassCount: 170 classes representing various chord combinations (Major, Minor, Sus4, Diminished, inversions, and root note indices).

---

## 3. Beat / Tempo Detection Model

* **Architecture**: Temporal Convolutional Network (TCN).
* **Input Tensor Shape (`logmel`)**: `[1, 1, TimeFrames, MelBins]`
  * TimeFrames: Log-mel spectrogram sequence length (e.g., 2048 frames).
  * MelBins: Mel frequency resolution (e.g., 128 bins).
* **Output Tensors**:
  * `beats`: `[1, TimeFrames, 1]` (frame-by-frame probability of beat onset).
  * `downbeats`: `[1, TimeFrames, 1]` (frame-by-frame probability of downbeat onset).
  * `tempo`: `[300]` (tempo probability array representing BPM indices up to 300).
