# Contributing Guidelines

Thank you for contributing to Music Stem Studio! To maintain codebase quality and prevent leaking sensitive data, please follow these guidelines:

## Development Workflow
1. Clone the repository and navigate to the application folder:
   ```bash
   cd flutter_app
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the development server or launch a simulator:
   ```bash
   flutter run
   ```

## Pre-Commit Verification
Before submitting commits or creating pull requests, please execute the following checks locally:
* **Code Formatting**:
  ```bash
  dart format lib test
  ```
* **Static Analysis**:
  ```bash
  flutter analyze
  ```
* **Automated Tests**:
  ```bash
  flutter test
  ```

## Security & Privacy Rules
* **No Sensitive Info**: Never commit certificates, provisioning profiles, API keys, `.env` configurations, or decrypter/patch logs.
* **No Proprietary Models**: Do not commit large pre-compiled models (`.mlmodel`, `.mlmodelc`, `.onnx`, `.tflite`, etc.). Keep all machine learning models in local storage or download them on-demand via the application.
* **Local Private Notes**: Save all private notes or reverse engineering drafts inside the `_private_notes/` folder, which is explicitly ignored in `.gitignore`.
