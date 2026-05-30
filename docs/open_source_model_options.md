# Open Source Model Options for On-Device Audio AI

This document catalogs permissible open-source frameworks, model checkpoints, and licensing options for source separation, chord recognition, and beat tracking.

---

## 1. Stem Separation

### Option A: Spleeter (by Deezer)
* **License**: MIT
* **Description**: A multi-stem separation library based on TensorFlow.
* **Conversion Path**: Extract network weights, rebuild the U-Net layers in PyTorch or Keras, and convert to CoreML format via `coremltools`.

### Option B: Open-Unmix (by INRIA)
* **License**: MIT
* **Description**: A deep learning model for music source separation.
* **Conversion Path**: Native PyTorch model definition. Easy tracking and direct conversion to CoreML.

### Option C: Demucs / HTDemucs (by Meta AI)
* **License**: MIT
* **Description**: High-fidelity source separation model.
* **Conversion Path**: Convert the PyTorch model (`demucs`) to CoreML. Note that Demucs weights can be quite large (typically > 80MB). Quantization to FP16 or INT8 is required to fit on-device memory footprints.

---

## 2. Chord Detection

### Option A: Chordino (from Vamp Plugins)
* **License**: GPL
* **Description**: Extract chroma profiles and estimate chords.
* **Conversion Path**: Best for local C++ porting. If GPL compliance is a concern, write a custom feature extractor and train a proprietary CRNN sequence model.

### Option B: PyTorch-based CRNN (e.g. BTC-CNN)
* **License**: MIT / Apache 2.0
* **Description**: Chord extraction using CNNs and recurrent loops.
* **Conversion Path**: Trace the model in PyTorch (`torch.jit.trace`) and export to CoreML format.

---

## 3. Beat & Tempo Tracking

### Option A: Madmom (by CPJKU)
* **License**: BSD 2-Clause
* **Description**: Popular audio processing library targeting beat tracking.
* **Conversion Path**: Rebuild the underlying recurrent network (RNN) or TCN layers in PyTorch and export to CoreML.

### Option B: Essentia / Essentia.js
* **License**: AGPL v3
* **Description**: Music Information Retrieval (MIR) framework containing beat/tempo and key detectors.
* **Conversion Path**: Cross-compile the C++ core to iOS static/dynamic libraries.
