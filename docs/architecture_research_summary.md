# Architecture Research Summary: iOS Local Audio Processing

## Overview
This document outlines a standardized architecture for performing local on-device audio analysis and source separation on iOS using native APIs and Apple frameworks.

```
                  ┌──────────────────────┐
                  │     Flutter UI       │
                  └──────────┬───────────┘
                             │ (MethodChannel)
                             ▼
                  ┌──────────────────────┐
                  │   Swift Native iOS   │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │    AVAudioEngine     │
                  └──────────┬───────────┘
                             │
                             ▼
             ┌───────────────┴───────────────┐
             ▼                               ▼
 ┌──────────────────────┐        ┌──────────────────────┐
 │  CoreML Classifier   │        │   STFT/iSTFT Mask    │
 └──────────────────────┘        └──────────────────────┘
 (Chords / Tempo / Beat)          (6-Stem Separation)
```

---

## 1. Native Routing & Playback Pipeline
To support low-latency local mixing, transposing, and recording, applications generally employ Apple's `AVAudioEngine` pipeline:
* **Audio Routing**: Custom node attachments (`AVAudioSourceNode`, `AVAudioMixerNode`) permit streaming channel levels to faders.
* **Recording Session**: Uses native input nodes mapped through `AVAudioEngine` configurations, backed by `NSMicrophoneUsageDescription` entries.
* **DSP Phase Vocoder**: High-quality pitch transpositions and speed (BPM) transformations are achieved via standard phase-locked overlap-add vocoder blocks.

---

## 2. Dynamic Source Separation (CoreML)
On-device stem isolation runs over Apple's **CoreML** execution engine:
* **Feature Extraction**: Stereo PCM samples are converted to stacked Short-Time Fourier Transform (STFT) frames. Tensors represent the stacked real and imaginary components of the audio channels.
* **Neural Execution**: The model predicts ideal ratio masks or complex spectrogram values for each individual stem target (e.g., vocals, drums, bass, piano, guitar, and other).
* **Synthesis**: An Inverse STFT (iSTFT) overlap-add block transforms the predicted spectrogram channels back to time-domain waveforms.

---

## 3. Chord & Tempo Analysis
* **Chord Detection**: Chromagram feature extraction maps audio spectral density to 12 pitch classes. Recurrent neural network structures (CRNN) ingest sequence tensors to classify chords chronologically.
* **Tempo Tracking**: Temporal Convolutional Networks (TCN) analyze onset patterns to output beat indices and downbeat alignments.
