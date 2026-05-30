import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_project.dart';
import 'native_ios_audio_service.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  AudioProject? _loadedProject;

  AudioPlayer get player => _player;

  Future<void> loadProjectAudio(AudioProject project) async {
    _loadedProject = project;
    try {
      if (project.originalAudioPath != null) {
        await _player.setFilePath(project.originalAudioPath!);
      }
    } catch (e) {
      debugPrint('Error loading project audio file: $e');
    }
  }

  Future<void> loadFile(String path) async {
    _loadedProject = null;
    try {
      await _player.setFilePath(path);
    } catch (e) {
      debugPrint('Error loading audio file: $e');
    }
  }

  Future<void> play() async {
    if (_loadedProject != null && _loadedProject!.stemStatus == AnalysisStatus.ready) {
      await _player.setVolume(0.0); // Mute mixture, play stems natively
      await _player.play();
      
      final stems = {
        'vocals': _loadedProject!.stemFiles?.vocals ?? '',
        'drums': _loadedProject!.stemFiles?.drums ?? '',
        'bass': _loadedProject!.stemFiles?.bass ?? '',
        'guitar': _loadedProject!.stemFiles?.guitar ?? '',
        'piano': _loadedProject!.stemFiles?.piano ?? '',
        'other': _loadedProject!.stemFiles?.other ?? '',
      };
      await NativeIosAudioService().playStemMix(stems);
    } else {
      await _player.setVolume(1.0);
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    if (_loadedProject != null && _loadedProject!.stemStatus == AnalysisStatus.ready) {
      await NativeIosAudioService().pauseStemMix();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    if (_loadedProject != null && _loadedProject!.stemStatus == AnalysisStatus.ready) {
      await NativeIosAudioService().stopStemMix();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
