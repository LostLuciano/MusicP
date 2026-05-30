import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraRecordingService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0; // 0 = back, 1 = front (if available)
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  /// Returns true if a front camera is available to switch to.
  bool get hasFrontCamera =>
      _cameras.any((c) => c.lensDirection == CameraLensDirection.front);

  /// Returns true if currently using the front camera.
  bool get isUsingFrontCamera =>
      _cameras.isNotEmpty &&
      _selectedCameraIndex < _cameras.length &&
      _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;

  Future<bool> initializeCamera({bool preferFront = false}) async {
    if (kIsWeb) return false;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return false;

      // Choose front or back camera
      if (preferFront) {
        final frontIdx = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        _selectedCameraIndex = frontIdx >= 0 ? frontIdx : 0;
      } else {
        final backIdx = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backIdx >= 0 ? backIdx : 0;
      }

      return await _createController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Switches between front and back camera.
  /// Stops any active video recording first.
  Future<bool> switchCamera() async {
    if (_cameras.length < 2) return false;

    final wasRecording = _controller?.value.isRecordingVideo ?? false;
    if (wasRecording) {
      try { await _controller?.stopVideoRecording(); } catch (_) {}
    }

    await _controller?.dispose();
    _isInitialized = false;

    // Toggle between cameras
    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _cameras.length;

    final success = await _createController(_cameras[_selectedCameraIndex]);

    if (success && wasRecording) {
      await startVideoRecording();
    }

    return success;
  }

  Future<bool> _createController(CameraDescription camera) async {
    try {
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Camera controller creation failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> startVideoRecording() async {
    if (!_isInitialized || _controller == null) return;
    if (_controller!.value.isRecordingVideo) return;
    try {
      await _controller!.startVideoRecording();
    } catch (e) {
      debugPrint('Failed to start video recording: $e');
    }
  }

  Future<String?> stopVideoRecording() async {
    if (!_isInitialized || _controller == null) return null;
    if (!_controller!.value.isRecordingVideo) return null;
    try {
      final XFile file = await _controller!.stopVideoRecording();
      return file.path;
    } catch (e) {
      debugPrint('Failed to stop video recording: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
