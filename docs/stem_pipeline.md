# On-Device Stem Separation Pipeline

This document details the step-by-step processing pipeline for executing local, offline audio source separation on iOS.

---

## Processing Flow

```text
[Audio Input] 
       │
       ▼
[Resample to 44.1 kHz] 
       │
       ▼
[STFT Windowing (FFT size 4096 / Hop 1024)]
       │
       ▼
[Construct Spectrogram Tensor (4-Channels)]
       │
       ▼
[CoreML Neural Engine Inference] 
       │
       ▼ (Compute Stems & cIRM Masks)
[iSTFT Overlap-Add Signal Reconstruction]
       │
       ▼
[Write WAV/M4A Files to Local App Folder]
       │
       ▼
[Schedule Stems in AVAudioEngine Playback Graph]
```

### 1. Ingestion & Pre-processing
* The input audio file (mp3, wav, m4a) is loaded and decoded to raw PCM float buffers.
* To match model training specifications, the audio is resampled to a constant **44,100 Hz**.

### 2. Spectral Analysis (STFT)
* Short-Time Fourier Transform (STFT) is calculated with an FFT size of **4096 bins** and hop size of **1024 frames**.
* Windowing functions (such as Hann windowing) are applied to each overlapping frame to reduce spectral leakage.
* The output complex values are stacked to represent stereo information:
  * Channel 0: Left Channel Real Component.
  * Channel 1: Left Channel Imaginary Component.
  * Channel 2: Right Channel Real Component.
  * Channel 3: Right Channel Imaginary Component.

### 3. Model Execution
* The stacked 4-channel tensor of shape `[1, 4, TimeFrames, FreqBins]` is passed to the CoreML model.
* The model executes on the Apple Neural Engine (ANE) or GPU, outputting separate spectrogram masks for each target stem (`vocals`, `drums`, `bass`, `guitar`, `piano`, `other`).

### 4. Waveform Synthesis (iSTFT)
* Complex multiplication is applied to isolate each stem's spectrogram.
* Inverse Short-Time Fourier Transform (iSTFT) is calculated using overlap-add synthesis to convert the frequency representations back to time-domain PCM waveforms.
* The PCM audio is written to disk in a standard audio container (WAV or M4A).

### 5. Playback Mixing
* The output stem file URLs are passed to `AudioEngineManager`.
* Stems are loaded into distinct player nodes and triggered synchronously to allow real-time volume adjustments and muting.
