import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<String?> startGuitarRecording() async {
    final bool hasPermission = await requestPermission();
    if (!hasPermission) return null;

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/guitar_take_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentPath = path;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    return path;
  }

  Future<void> pause() async {
    await _recorder.pause();
  }

  Future<void> resume() async {
    await _recorder.resume();
  }

  Future<String?> stopGuitarRecording() async {
    final path = await _recorder.stop();
    return path ?? _currentPath;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
