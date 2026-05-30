# Building IPA Notes - Music Stem Studio

## Build Prerequisites
To compile and distribute a signed `.ipa` file for iOS devices, the following system requirements must be met:
1. **OS**: Apple macOS
2. **IDE**: Xcode (with Command Line Tools installed)
3. **Flutter SDK**: Matching target development channel
4. **Apple Developer Account**: Individual or Organization membership
5. **Signing Materials**:
   - iOS Distribution Certificate
   - Provisioning Profile linking the App ID and designated Test Flight / Ad Hoc devices

---

## Build Commands

### Full Signed IPA Release
```bash
flutter build ipa --release
```
*Creates the `.ipa` package, outputting it directly inside `build/ios/ipa/` ready for App Store Connect or Ad Hoc distribution.*

### Local Simulators or Local Device (No Codesign Test)
If you want to compile the build target locally to verify compiler settings without setting up developer keys/certificates:
```bash
flutter build ios --release --no-codesign
```

---

## Configuration & Permissions
The following permission descriptors are initialized within the main configuration manifest `ios/Runner/Info.plist`:

* **`NSMicrophoneUsageDescription`**: "Aplikasi membutuhkan mikrofon untuk merekam gitar atau audio."
* **`NSCameraUsageDescription`**: "Aplikasi membutuhkan kamera untuk merekam video saat bermain musik."
* **`NSPhotoLibraryUsageDescription`**: "Aplikasi membutuhkan akses galeri untuk memilih media."
* **`NSPhotoLibraryAddUsageDescription`**: "Aplikasi membutuhkan akses untuk menyimpan hasil rekaman."

---

## Device Verification & Edge Cases
When validating the build on a physical iPhone device, check:
1. **Sandboxing Paths**: Ensure files recorded using the `record` package utilize paths resolved inside `getApplicationDocumentsDirectory()`, as iOS sandboxes and resets documents directory paths when apps undergo updates.
2. **Audio Mixing Hardware**: Test hardware interfaces (such as an iRig or portable USB interface connected via lightning/USB-C) to verify that input levels map cleanly to the stereo input faders.
3. **CoreML Hardware Acceleration**: CoreML inference executes on the Apple Neural Engine (ANE). Watch out for thread memory leaks or stack-overflow states during high-rate STFT audio chunking.
