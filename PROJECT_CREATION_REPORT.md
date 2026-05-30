# Project Creation Report: Music Stem Studio

## Project Created
A clean-room mobile application architecture scaffold has been successfully generated. This project models a premium, on-device AI music workspace allowing multi-channel stem separation, tempo estimation, and chord detection on iOS.

## Folder Location
* **Project Root**: `d:\IPA Project\music_stem_studio`

## Flutter App Location
* **Flutter Workspace**: `d:\IPA Project\music_stem_studio\flutter_app`

## Generated Files
The repository layout contains:
1. **Presentation & Core Layers**: `lib/main.dart`, `lib/app.dart`, themes, constants, and formatting utilities.
2. **Audio Services & Wrappers**: Native bridges (`native_ios_audio_service.dart`), local recording (`audio_recorder_service.dart`), and playback layers (`audio_player_service.dart`).
3. **Core Modules**: `home_screen.dart`, `player_screen.dart`, `recorder_screen.dart`, `stem_mixer_screen.dart`, `chord_viewer_screen.dart`, `beat_tempo_screen.dart`, `project_library_screen.dart`.
4. **Mixer Widgets**: Waveform visualizations, timelines, and stem mixers.
5. **iOS Native reference files**: CoreML stem separator pipelines, AVAudioEngine mixers, chord CRNN models, beat tracking TCN wrappers, and MethodChannel bridges.

## Copied Markdown Reports
* The reverse-engineering findings of the target application have been copied into the docs library: `docs/reverse_engineering_notes.md` (copied from `IPA_ANALYSIS_REPORT.md`).

## Files Not Copied For Legal Reasons
In accordance with copyright and intellectual property protections:
* **No proprietary binaries, frameworks, or dynamic libraries** (e.g. `iOSSourceSeparationPlayerAudioEngine.framework` or `blatantsPatch.dylib`) were copied.
* **No proprietary CoreML weights or compiled models** (e.g. `.mlmodelc` parameters) were copied.
* **No marketing assets, paywall bundles, fonts, or demo tracks** were copied.

## Architecture Implemented
* A clean MethodChannel bridge connects the dark-mode Flutter interface to Swift managers.
* `AVAudioEngine` routes isolated tracks to separate player channels.
* Custom Swift managers outline the pre-processing (STFT) and post-processing (iSTFT) steps needed to feed spectrogram tensors into local CoreML models.

## Native iOS Placeholder Files
* `native_ios_reference/CoreMLStemSeparator.swift`
* `native_ios_reference/AudioEngineManager.swift`
* `native_ios_reference/ChordDetectionManager.swift`
* `native_ios_reference/BeatDetectionManager.swift`
* `native_ios_reference/AudioFeatureExtractor.swift`
* `native_ios_reference/StemMixerChannel.swift`
* `native_ios_reference/FlutterMethodChannelBridge.swift`

## Flutter Screens Created
* `HomeScreen`: Central studio workspace hub.
* `PlayerScreen`: Spectrogram waveform and timeline playback.
* `RecorderScreen`: Mic capture session.
* `StemMixerScreen`: 6-channel mixer (Vocals, Drums, Bass, Guitar, Piano, Other).
* `ChordViewerScreen`: Chronological pitch chords timeline.
* `BeatTempoScreen`: TCN tempo estimate and beat-grid markers.
* `ProjectLibraryScreen`: Local track selection.

## Next Steps
1. **Integrate Open-Source Models**: Convert permissible weights (e.g., Open-Unmix or Demucs) to `.mlpackage` format and deploy in `models_placeholder/`.
2. **Implement C++ DSP layer**: Wire Accelerate framework functions to execute the STFT windowing loops defined in `AudioFeatureExtractor.swift`.
3. **Configure iOS Entitlements**: Set up micro and playback entitlements in Xcode for debugging on physical hardware.

## Commands To Run
To execute the Flutter application layout:
```bash
cd d:\IPA Project\music_stem_studio\flutter_app
flutter pub get
flutter run
```
