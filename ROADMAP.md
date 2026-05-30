# Development & Integration Roadmap

This roadmap outlines the milestones required to transition the **Music Stem Studio** scaffolding into a production-ready application.

---

## Phase 1: Prototype Scaffolding (Current Stage)
- [x] Scaffold Flutter dark-mode studio UI.
- [x] Define Dart native audio services and MethodChannel bridge.
- [x] Create native Swift interfaces for `AVAudioEngine` routing and CoreML.
- [x] Author comprehensive documentation on DSP spectral pipelines and integration pathways.

## Phase 2: Native Audio & Mixer Integration
- [ ] Implement `AVAudioEngine` node graph in Swift.
- [ ] Connect individual `AVAudioPlayerNode` slots for the 6 target stems.
- [ ] Integrate a phase vocoder library (such as SoundTouch, SoundPipe, or custom C++) for transposition and speed controls.
- [ ] Wire Flutter volume and mute/solo controls to the native player channels.

## Phase 3: CoreML Integration & Model Hosting
- [ ] Integrate open-source model prototypes (e.g., converted Spleeter or Open-Unmix CoreML weights).
- [ ] Create Python pipelines for converting model checkpoints (`.pt` or `.onnx`) to `.mlpackage`.
- [ ] Profile GPU and Apple Neural Engine (ANE) memory execution limits.
- [ ] Implement real-time STFT/iSTFT transforms in Swift/C++.

## Phase 4: Production Polish
- [ ] Add visual waveforms and timeline synchronization on Flutter.
- [ ] Implement local database storage (SQLite/Hive) to manage user projects.
- [ ] Integrate background audio rendering configurations for continuous playback.
- [ ] Conduct performance profiling on diverse iOS hardware tiers.
