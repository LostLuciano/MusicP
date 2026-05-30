# Legal Notes & Compliance Framework

This document outlines the strict guidelines governing the codebase, engineering reference architectures, and model files of the **Music Stem Studio** project.

---

## 1. Compliance Statement
This project is built as a clean-room architectural scaffold. It is completely independent of any commercial product and contains only original code, reference API designs, and documentation. 

* **No Proprietary Files**: Under no circumstances does this repository contain files extracted from third-party iOS IPA applications, including but not limited to compiled CoreML models (`.mlmodelc`), frameworks (`.framework`), dynamic libraries (`.dylib`), app binaries, assets, fonts, videos, or demo stems.
* **No Bypass of Protections**: This codebase does not implement mechanisms to bypass paywalls, digital rights management (DRM), subscription checks, in-app purchase (IAP) validation, or encryption.

---

## 2. Research & Reverse-Engineering Boundaries
General findings from static and dynamic analysis of consumer source separation apps have been utilized solely to map out industry-standard digital signal processing (DSP) patterns (such as STFT boundaries, sample rates, and tensor shapes). 
All code segments implemented in `native_ios_reference/` and `flutter_app/` are original designs and wrappers around standard Apple AVFoundation and CoreML APIs.

---

## 3. Machine Learning Model Licensing
This repository contains no pre-trained neural network weights. To enable local on-device AI functionality, developers must train, license, or obtain open-source models with compatible licenses (such as MIT, Apache 2.0, or Creative Commons).

### Recommended Legal Pathways:
1. **Self-Trained Models**: Train a source separation network (e.g., U-Net or HTDemucs) using public multi-track datasets (e.g., MUSDB18) and compile to CoreML format using `coremltools`.
2. **Permissive Open-Source Models**: Use converted open-source weights (such as community-contributed weights for Spleeter or Open-Unmix) that align with commercial compliance.
3. **API Prototype**: For early-stage testing, delegate execution to a cloud-based server hosting licensed separation engines before compiling local weights.
