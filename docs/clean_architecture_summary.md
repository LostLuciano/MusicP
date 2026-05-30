# Clean Architecture Summary

This document summarizes the reference architecture patterns observed during analysis and how they are translated into a clean, compliant implementation plan.

---

## 1. Observed Reference Architecture
The target application is architected around on-device, low-latency processing:
* **Neural Network Execution**: Compiled CoreML models (`.mlmodelc` bundles) executed using the hardware Apple Neural Engine (ANE) or GPU via the Espresso runtime.
* **Low-Level DSP**: Custom C++ engine managing raw PCM data, STFT framing, spectrogram masks, and Inverse STFT overlap-add reconstruction.
* **Playback Management**: Standard iOS `AVAudioEngine` hosting player node pipelines.

---

## 2. Clean Implementation Plan
To build a legally compliant, original application with a similar capability footprint, this project structures a clean separation of concerns:

```text
┌────────────────────────┐
│      Flutter UI        │  <-- Presentation & User Inputs
└──────────┬─────────────┘
           │ (MethodChannel Bridge)
┌──────────▼─────────────┐
│  Swift Native Bridge   │  <-- Arguments parsing, threading, and system state routing
└──────────┬─────────────┘
           │
     ┌─────┴──────────┐
     ▼                ▼
┌──────────────┐┌──────────────┐
│ AVAudioEngine││   CoreML     │  <-- Standard OS audio playback and modular
│ Playback Graph││   Inference  │      AI models (restricted to legal licenses)
└──────────────┘└──────────────┘
```

### Core Architecture Goals:
1. **No Copied Assets**: Do not use proprietary CoreML weights, layout plists, paywall bundles, or decrypted binaries from any commercial packages.
2. **Original Interface**: Build a Flutter presentation layout using premium dark themes.
3. **AVAudioEngine Player Node Mixing**: Model playback of stems using native iOS `AVAudioPlayerNode` slots routed to a single `AVAudioMixerNode` submix graph.
4. **Decoupled Model Loading**: Create stub ML interfaces so that legal open-source or self-trained models (e.g., converted from Spleeter or HTDemucs checkouts) can be dropped in later.
5. **C++ Preprocessing Wrapper**: Decouple Fast Fourier Transform (FFT) logic using modular Swift wrappers around the Apple Accelerate framework (vDSP).
