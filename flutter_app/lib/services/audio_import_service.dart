import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/audio_project.dart';
import 'native_ios_audio_service.dart';

class AudioImportService {
  final Uuid _uuid = const Uuid();

  Future<File?> pickAudioFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        // FileType.custom with allowedExtensions triggers the full iOS Files app
        // document picker — works with iCloud Drive, Google Drive, Dropbox, etc.
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'caf', 'aiff', 'opus'],
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<File?> pickVideoFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.video,
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> copyAudioToAppDirectory(File file, String id) async {
    try {
      final Directory docDir = await getApplicationDocumentsDirectory();
      final String extension = file.path.split('.').last;
      final String newPath = '${docDir.path}/project_${id}_mixture.$extension';
      final File copiedFile = await file.copy(newPath);
      return copiedFile.path;
    } catch (_) {
      return null;
    }
  }

  Future<AudioProject?> createProjectFromAudio(File file) async {
    try {
      final String id = _uuid.v4();
      final String title = file.path
          .split(Platform.pathSeparator)
          .last
          .split('.')
          .first;
      final String? localAudioPath = await copyAudioToAppDirectory(file, id);

      if (localAudioPath == null) return null;

      final now = DateTime.now();
      return AudioProject(
        id: id,
        title: title,
        originalAudioPath: localAudioPath,
        createdAt: now,
        updatedAt: now,
        status: ProjectStatus.imported,
        stemStatus: AnalysisStatus.unavailable, // Unprocessed by default
        chordStatus: AnalysisStatus.unavailable,
        beatStatus: AnalysisStatus.unavailable,
        stemFiles: const StemFiles(),
        recordings: const [],
      );
    } catch (_) {
      return null;
    }
  }

  Future<AudioProject?> createProjectFromVideo(File videoFile) async {
    try {
      final String id = _uuid.v4();
      final String title = videoFile.path
          .split(Platform.pathSeparator)
          .last
          .split('.')
          .first;
      
      final Directory docDir = await getApplicationDocumentsDirectory();
      final String targetAudioPath = '${docDir.path}/project_${id}_mixture.m4a';
      
      final nativeService = NativeIosAudioService();
      final String? extractedPath = await nativeService.extractAudioFromVideo(
        videoFile.path,
        targetAudioPath,
      );
      
      if (extractedPath == null) return null;
      
      final now = DateTime.now();
      return AudioProject(
        id: id,
        title: '$title (Video Extracted)',
        originalAudioPath: extractedPath,
        createdAt: now,
        updatedAt: now,
        status: ProjectStatus.imported,
        stemStatus: AnalysisStatus.unavailable,
        chordStatus: AnalysisStatus.unavailable,
        beatStatus: AnalysisStatus.unavailable,
        stemFiles: const StemFiles(),
        recordings: const [],
      );
    } catch (_) {
      return null;
    }
  }
}
