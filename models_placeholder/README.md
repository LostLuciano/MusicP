# AI Model Placeholders

This directory contains information templates and placeholders for future CoreML neural network models.

---

## Instructions for Deploying Real Models:
1. Compile your trained or converted models into `.mlmodel` or `.mlpackage` bundles.
2. Drag the models into Xcode to verify input/output schemas.
3. Replace the placeholder README files in this directory with your compiled models.
4. Update `native_ios_reference/FlutterMethodChannelBridge.swift` (or the iOS host build target) to reference the compiled classes.

---

## Manifest
* **`stem_separation_model_placeholder.mlmodel.README`**: Details input/output structures for 6-stem isolation models.
* **`chord_detection_model_placeholder.mlmodel.README`**: Details input/output structures for chord CRNN models.
* **`beat_tempo_model_placeholder.mlmodel.README`**: Details input/output structures for beat/tempo TCN models.
