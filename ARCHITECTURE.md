# Architectural Reference Design

This document details the software architecture, modular layering, and data flow of the **Music Stem Studio** application.

---

## 1. High-Level Modular Design

The application consists of a cross-platform presentation layer (Flutter/Dart) communicating with a native iOS engine (Swift/C++) via a high-performance MethodChannel bridge.

```text
┌─────────────────────────────────────────────────────────────┐
│                       Presentation (Flutter/Dart)           │
│  - User Interface (Dark Music Studio Theme)                 │
│  - Mixer Sliders, Mute/Solo States, Track Library Lists     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼ (MethodChannel: music_stem_studio/native_audio)
┌─────────────────────────────────────────────────────────────┐
│                    Native Bridge Layer (Swift)              │
│  - FlutterMethodChannelBridge                               │
│  - Directs calls to AudioEngine, CoreML, and DSP components │
└──────────────────────────────┬──────────────────────────────┘
                               │
             ┌─────────────────┴─────────────────┐
             ▼                                   ▼
┌───────────────────────────┐       ┌───────────────────────────┐
│     CoreML Engine (iOS)   │       │   AVAudioEngine Engine    │
│ - Stem Separation Network │       │ - Multi-Channel Player    │
│ - Chord Recognition CRNN  │       │ - Recording Node          │
│ - Beat TCN Analyzer       │       │ - Sub-Mixer & DSP Effects │
└────────────┬──────────────┘       └────────────▲──────────────┘
             │                                   │
             ▼                                   │
┌────────────────────────────────────────────────┴──────────────┐
│                  STFT / iSTFT C++ DSP Pipeline                │
│  - Overlap-Add Spectral Signal Reconstruction                 │
│  - Phase Vocoder Pitch/Tempo Adjustments                      │
└───────────────────────────────────────────────────────────────┘
```

---

## 2. Core Modules & Responsibilities

### A. Presentation Layer (Flutter/Dart)
* **Features**: Houses the `Home`, `Player`, `Recorder`, `StemMixer`, `ChordViewer`, and `BeatTempo` screens.
* **Services**: Exposes Dart API wrappers (`AudioPlayerService`, `StemSeparationService`, `NativeIosAudioService`) that map state to native controllers.
* **Widgets**: Tailored canvas elements displaying mock visual waveforms and playback markers.

### B. Native Bridge (Swift)
* **`FlutterMethodChannelBridge.swift`**: Routes incoming JSON and string calls from Dart to Swift subsystems, ensuring background thread delegation to avoid blocking the main UI loop.

### C. Audio Engine (`AVAudioEngine`)
* **`AudioEngineManager.swift`**: Initializes a graph consisting of `AVAudioPlayerNode` slots corresponding to each isolated stem (`vocals`, `drums`, `bass`, `guitar`, `piano`, `other`). These feed into a main `AVAudioMixerNode` to support zero-latency volume adjustments, solo modes, and real-time transpositions.

### D. Machine Learning Inference (CoreML)
* **`CoreMLStemSeparator.swift`**: Maps the real and imaginary components of stereo audio frames to input tensors, executes inference on the Neural Engine (ANE), and returns raw stem masks.
* **`ChordDetectionManager.swift`**: Analyzes chromagram features via a sequence classifier (CRNN) to output named chord segments.
* **`BeatDetectionManager.swift`**: Analyzes log-mel spectrogram features to estimate tempo (BPM) and beat timings.

### E. Signal Processing (STFT/iSTFT DSP)
* **`AudioFeatureExtractor.swift`**: Stub interface mapping out how raw audio bytes are resampled to 44.1 kHz, converted to frequency spectrograms via Short-Time Fourier Transform (STFT), and reconstructed back to PCM streams via Inverse Short-Time Fourier Transform (iSTFT) using overlap-add synthesis.
