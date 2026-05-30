import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraRecordingService {
  CameraController? _controller;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<bool> initializeCamera() async {
    if (kIsWeb) return false;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> startVideoRecording() async {
    if (!_isInitialized || _controller == null) return;
    try {
      await _controller!.startVideoRecording();
    } catch (e) {
      debugPrint('Failed to start video recording: $e');
    }
  }

  Future<String?> stopVideoRecording() async {
    if (!_isInitialized || _controller == null) return null;
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
