# Native iOS Reference Architecture (Swift)

This directory contains clean Swift native reference files outlining the implementation design for integrating CoreML and AVAudioEngine on iOS.

---

## File Manifest
* **`CoreMLStemSeparator.swift`**: Outlines the pipeline for loading separation networks, feeding 4-channel STFT spectrogram inputs, and reconstructing waveform outputs.
* **`AudioEngineManager.swift`**: Models a node graph using `AVAudioEngine` with 6 dedicated player channels.
* **`ChordDetectionManager.swift`**: Models the CRNN sequence classification pipeline.
* **`BeatDetectionManager.swift`**: Models the TCN beat tracker pipeline.
* **`AudioFeatureExtractor.swift`**: Interface details for C++ DSP algorithms (STFT/iSTFT/mel-spectrogram/chroma extraction).
* **`StemMixerChannel.swift`**: Data structure tracking mixer configurations.
* **`FlutterMethodChannelBridge.swift`**: Swift entry point capturing requests from Dart.
