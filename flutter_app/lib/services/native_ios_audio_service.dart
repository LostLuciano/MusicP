import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';

class NativeIosAudioService {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.methodChannelName,
  );

  Future<String?> importAudio() async {
    try {
      final String? path = await _channel.invokeMethod<String>('importAudio');
      return path ?? 'placeholder_mixture.mp3';
    } catch (e) {
      debugPrint('Native importAudio unavailable, using web fallback: $e');
      return 'placeholder_mixture.mp3';
    }
  }

  Future<String?> startRecording() async {
    try {
      final String? path = await _channel.invokeMethod<String>(
        'startRecording',
      );
      return path ?? 'placeholder_recording.wav';
    } catch (e) {
      debugPrint('Native startRecording unavailable, using web fallback: $e');
      return 'placeholder_recording.wav';
    }
  }

  Future<String?> stopRecording() async {
    try {
      final String? path = await _channel.invokeMethod<String>('stopRecording');
      return path;
    } catch (e) {
      debugPrint('Native stopRecording unavailable, using web fallback: $e');
      return null;
    }
  }

  Future<Map<String, String>> separateStems(String audioPath) async {
    try {
      final Map? result = await _channel.invokeMethod<Map>('separateStems', {
        'audioPath': audioPath,
      });
      if (result != null) {
        return result.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
      return _placeholderStems();
    } catch (e) {
      debugPrint('Native separateStems unavailable, using web fallback: $e');
      return _placeholderStems();
    }
  }

  Future<List<Map<String, dynamic>>> analyzeChords(String audioPath) async {
    try {
      final List? result = await _channel.invokeMethod<List>('analyzeChords', {
        'audioPath': audioPath,
      });
      if (result != null) {
        return result
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return _placeholderChords();
    } catch (e) {
      debugPrint('Native analyzeChords unavailable, using web fallback: $e');
      return _placeholderChords();
    }
  }

  Future<Map<String, dynamic>> analyzeBeatsAndTempo(String audioPath) async {
    try {
      final Map? result = await _channel.invokeMethod<Map>(
        'analyzeBeatsAndTempo',
        {'audioPath': audioPath},
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return _placeholderBeats();
    } catch (e) {
      debugPrint(
        'Native analyzeBeatsAndTempo unavailable, using web fallback: $e',
      );
      return _placeholderBeats();
    }
  }

  Future<void> playStemMix(Map<String, String> stemPaths) async {
    try {
      await _channel.invokeMethod('playStemMix', {'stemPaths': stemPaths});
    } catch (e) {
      debugPrint('Native playStemMix unavailable, using web fallback: $e');
    }
  }

  Future<void> setStemVolume(String stemName, double volume) async {
    try {
      await _channel.invokeMethod('setStemVolume', {
        'stemName': stemName,
        'volume': volume,
      });
    } catch (e) {
      debugPrint('Native setStemVolume unavailable, using web fallback: $e');
    }
  }

  Future<void> muteStem(String stemName, bool muted) async {
    try {
      await _channel.invokeMethod('muteStem', {
        'stemName': stemName,
        'muted': muted,
      });
    } catch (e) {
      debugPrint('Native muteStem unavailable, using web fallback: $e');
    }
  }

  Future<void> soloStem(String stemName) async {
    try {
      await _channel.invokeMethod('soloStem', {'stemName': stemName});
    } catch (e) {
      debugPrint('Native soloStem unavailable, using web fallback: $e');
    }
  }

  // --- Fallback Placeholders ---

  Map<String, String> _placeholderStems() {
    return {
      'vocals': 'placeholder_vocals.wav',
      'drums': 'placeholder_drums.wav',
      'bass': 'placeholder_bass.wav',
      'guitar': 'placeholder_guitar.wav',
      'piano': 'placeholder_piano.wav',
      'other': 'placeholder_other.wav',
    };
  }

  List<Map<String, dynamic>> _placeholderChords() {
    return [
      {
        'name': 'C:maj',
        'startTime': 0.0,
        'endTime': 4.2,
        'rootNote': 0,
        'chordType': 1,
      },
      {
        'name': 'G:maj',
        'startTime': 4.2,
        'endTime': 8.5,
        'rootNote': 7,
        'chordType': 1,
      },
      {
        'name': 'A:min',
        'startTime': 8.5,
        'endTime': 12.8,
        'rootNote': 9,
        'chordType': 2,
      },
      {
        'name': 'F:maj',
        'startTime': 12.8,
        'endTime': 16.4,
        'rootNote': 5,
        'chordType': 1,
      },
    ];
  }

  Map<String, dynamic> _placeholderBeats() {
    return {
      'tempo': 120.0,
      'beats': [
        {'time': 0.0, 'index': 0},
        {'time': 0.5, 'index': 1},
        {'time': 1.0, 'index': 2},
        {'time': 1.5, 'index': 3},
        {'time': 2.0, 'index': 0},
        {'time': 2.5, 'index': 1},
        {'time': 3.0, 'index': 2},
        {'time': 3.5, 'index': 3},
      ],
      'downbeats': [0.0, 2.0],
    };
  }
}
