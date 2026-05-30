# Model Inventory Template

Use this document to track model changes, weight hashes, dimensions, and execution performance during integration.

---

| Model Name | Source Format | CoreML Format | Weight Size | Input Shape | Output Shape | Primary Target | Performance (ms) |
| :--- | :---: | :---: | :---: | :--- | :--- | :---: | :---: |
| *e.g., dune_light_v1* | PyTorch (`.pt`) | `.mlpackage` | 10.5 MB | `[1, 4, 64, 1024]` | 6 x `[1, 4, 64, 1024]` | ANE / GPU | 14ms |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |
| | | | | | | | |

---

## Metric Reference definitions:
* **Weight Size**: Total storage size of compiled model (Espresso parameters). Keep under 15MB for fast loading and low memory usage.
* **Input Shape**: Dimensions of the preprocessed spectrogram tensor. Typically `[Batch, Channels, Time, Frequency]`.
* **Primary Target**: Hardware compute block targeting ANE (Apple Neural Engine), GPU (Metal), or CPU.
* **Performance (ms)**: Average execution time of model prediction on a single chunk. Target under 20ms to allow real-time background processing.
