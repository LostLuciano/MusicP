import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_project.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Future<void> loadProjectAudio(AudioProject project) async {
    try {
      if (project.originalAudioPath != null) {
        await _player.setFilePath(project.originalAudioPath!);
      }
    } catch (e) {
      debugPrint('Error loading project audio file: $e');
    }
  }

  Future<void> loadFile(String path) async {
    try {
      await _player.setFilePath(path);
    } catch (e) {
      debugPrint('Error loading audio file: $e');
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
