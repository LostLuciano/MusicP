# CoreML Model Integration & Optimization Guide

This guide explains how to compile, load, and optimize custom machine learning models within an iOS application.

---

## 1. Preparing the Model
CoreML requires models in the `.mlmodel` (older format) or `.mlpackage` (modern bundle) format.
If you have a model trained in PyTorch or TensorFlow, you can convert it using Apple's python library `coremltools`:

```python
import coremltools as ct
import torch

# Trace or script your PyTorch model
traced_model = torch.jit.trace(my_pytorch_model, dummy_input)

# Convert to CoreML
model = ct.convert(
    traced_model,
    inputs=[ct.TensorType(name="mixture", shape=(1, 4, 32, 2048))],
    outputs=[ct.TensorType(name="vocals"), ct.TensorType(name="drums"), ...]
)
model.save("my_separator.mlpackage")
```

---

## 2. Compilation and Xcode Setup
1. Drag the `.mlpackage` or `.mlmodel` file into your Xcode project hierarchy.
2. Xcode automatically generates a Swift interface class mapping input/output variables (e.g. `MySeparatorInput`, `MySeparatorOutput`, and `MySeparator`).
3. During compilation, Xcode builds this file into a compiled CoreML directory named `MySeparator.mlmodelc` within the application bundle.

---

## 3. Loading and Inference in Swift
To initialize and run model inference on a background thread:

```swift
import CoreML

func runModelInference(inputData: MLMultiArray) async throws -> MySeparatorOutput {
    // Configure hardware execution target
    let config = MLModelConfiguration()
    
    // Prioritize Apple Neural Engine (ANE) and GPU
    config.computeUnits = .all 
    
    // Initialize the model asynchronously to prevent UI lag
    let modelInstance = try await MySeparator.load(configuration: config)
    
    // Construct inputs
    let modelInput = MySeparatorInput(mixture: inputData)
    
    // Execute inference
    let output = try await modelInstance.prediction(input: modelInput)
    return output
}
```

---

## 4. Hardware Optimization Benchmarking
* **Apple Neural Engine (ANE)**: The Neural Engine is optimized for integer and half-precision matrix calculations (FP16). Convert model weights to FP16 to maximize performance and save battery life.
* **GPU Fallback**: If the model contains layers not supported by the ANE (e.g. custom recurrent loops or transpose layers), the CoreML engine falls back to the GPU. Keep input shapes fixed (`hasShapeFlexibility = 0`) to optimize GPU memory caching.
* **CPU Execution**: Avoid running separation models on the CPU, as it causes thermal throttling and significant frame drop in high-duty DSP environments.
