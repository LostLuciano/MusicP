import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  // Stream that emits live amplitude (0.0–1.0) for VU meter
  final StreamController<double> _levelController =
      StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  Timer? _amplitudeTimer;

  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Starts recording audio to app documents dir.
  /// Returns the output path, or null if permission denied.
  Future<String?> startGuitarRecording() async {
    final bool hasPermission = await requestPermission();
    if (!hasPermission) return null;

    // Use app documents directory — visible in iOS Files.app since
    // UIFileSharingEnabled and LSSupportsOpeningDocumentsInPlace are set.
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${directory.path}/Recordings');
    if (!recordingsDir.existsSync()) recordingsDir.createSync(recursive: true);

    final path =
        '${recordingsDir.path}/take_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentPath = path;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 192000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    // Poll amplitude every 80ms for smooth VU meter
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        // amplitude.current is in dBFS (typically -60 to 0)
        // Map to 0.0–1.0 linear scale for display
        final double normalized =
            ((amplitude.current + 60.0) / 60.0).clamp(0.0, 1.0);
        _levelController.add(normalized);
      } catch (_) {}
    });

    return path;
  }

  /// Returns a formatted dB string from current normalized level.
  static String levelToDB(double level) {
    if (level <= 0.001) return '-∞ dB';
    final db = (level * 60.0 - 60.0).clamp(-60.0, 0.0);
    return '${db.toStringAsFixed(1)} dB';
  }

  Future<void> pause() async {
    await _recorder.pause();
    _amplitudeTimer?.cancel();
    _levelController.add(0.0);
  }

  Future<void> resume() async {
    await _recorder.resume();
    // Restart amplitude polling
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        final double normalized =
            ((amplitude.current + 60.0) / 60.0).clamp(0.0, 1.0);
        _levelController.add(normalized);
      } catch (_) {}
    });
  }

  Future<String?> stopGuitarRecording() async {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _levelController.add(0.0);
    final path = await _recorder.stop();
    return path ?? _currentPath;
  }

  Future<void> dispose() async {
    _amplitudeTimer?.cancel();
    await _levelController.close();
    await _recorder.dispose();
  }
}
