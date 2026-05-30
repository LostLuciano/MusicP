# Music Stem Studio

Music Stem Studio is a Flutter-based, iOS-first application designed for music workflows, guitar recordings, live camera feeds, and automated playback analytics. It is structured to utilize local Apple CoreML neural network pipelines and Swift native audio engine frameworks.

---

## Features
* **Project-based Music Workflow**: Load, import, edit, and organize individual music tracks and takes.
* **Import Audio Project**: Import external audio files safely into the sandboxed documents directory.
* **Audio Player**: Dynamic playback control driven by `just_audio` with live position stream broadcasts.
* **Guitar Recording Mode**: High-fidelity instrument recording with microphone input level controls.
* **Camera Recording**: Integrates device camera capture feeds directly into the performance workflow.
* **Project Library**: Storage system utilizing local SharedPreferences to manage multiple active tracks.
* **Stem Mixer Interface**: Interactive 6-track audio slider console mapped to individual stem files.
* **Chord Viewer Interface**: Dynamic visual playback highlighting representing active chords.
* **Beat & Tempo Interface**: Visual beat markers and metronome settings matching current song properties.
* **Future CoreML Integration**: Prepared scaffolding for on-device CoreML model processing.

---

## Current MVP Status
* **Import Audio & Projects**: Complete and fully functional file selection workflow.
* **Guitar Recording**: Fully functional local recording mapped directly to documents directory.
* **Stem Mixer**: Interactive UI faders map to stem tracks. AI separation defaults to 'Waiting Model' as models are not bundled.
* **Chord Syncing**: Real-time chord alignment checks search and update the active playing chord. Manual chords addition is functional.
* **Key/Tempo Grid**: Metronome displays and TCN-style beat grids are represented as visual guides.

---

## Tech Stack
* **Flutter & Dart**: Core cross-platform framing.
* **Provider**: Local app state management.
* **just_audio**: Dynamic multi-source playback.
* **record**: Sandboxed instrument voice recording.
* **file_picker**: Native file picker bridges.
* **path_provider**: Local documents directory path resolution.
* **permission_handler**: Core system permission prompts.
* **camera**: Local camera capture previews.
* **Swift Layer (AVAudioEngine + CoreML)**: Future iOS native machine learning pipeline.

---

## Project Structure
```text
music_stem_studio/
├── README.md
├── LICENSE
├── .gitignore
├── CONTRIBUTING.md
├── CHANGELOG.md
├── ARCHITECTURE.md
├── AI_MODEL_REQUIREMENTS.md
├── BUILD_IPA_NOTES.md
├── LEGAL_NOTES.md
├── ROADMAP.md
├── flutter_app/            # Flutter cross-platform source code
├── native_ios_reference/   # Swift audio engineering reference scaffold
├── docs/                   # General architecture and legal guidelines
├── models_placeholder/     # Folder for ML model structures
└── GITHUB_READY_REPORT.md  # Repository audit report
```

---

## Getting Started

### Run Locally (Flutter Web / Desktop / Device)
Ensure Flutter is installed on your development machine, then execute:
```bash
cd flutter_app
flutter pub get
flutter analyze
flutter run -d chrome
```

---

## iOS Build Notes
To compile a signed iOS `.ipa` distribution file, the following are required:
* macOS
* Xcode (with CLI tools)
* Apple Developer Account Subscription
* iOS Signing Certificates & Provisioning Profiles

```bash
cd flutter_app
flutter build ipa --release
```

---

## Legal Notes
* This repository is a clean-room MVP scaffold.
* No decryption, paywall circumvention, DRM bypass, or proprietary models are contained within this source control.
* Third-party AI model files must be obtained legally, trained independently, or referenced from authorized open-source repositories.
