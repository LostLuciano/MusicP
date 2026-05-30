import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/audio_project.dart';
import '../services/project_repository.dart';
import '../services/audio_import_service.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/camera_recording_service.dart';
import '../services/native_ios_audio_service.dart';
import '../services/lyrics_service.dart';

class ProjectController with ChangeNotifier {
  final ProjectRepository _repository = ProjectRepository();
  final AudioImportService _importService = AudioImportService();
  final AudioPlayerService _playerService = AudioPlayerService();
  final AudioRecorderService _recorderService = AudioRecorderService();
  final CameraRecordingService _cameraService = CameraRecordingService();
  final LyricsService _lyricsService = LyricsService();
  final Uuid _uuid = const Uuid();

  List<AudioProject> _projects = [];
  AudioProject? _activeProject;
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isSearchingLyrics = false;
  String? _recordingPath;

  ChordSegment? _activeChordSegment;

  List<AudioProject> get projects => _projects;
  AudioProject? get activeProject => _activeProject;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  bool get isSearchingLyrics => _isSearchingLyrics;
  String? get recordingPath => _recordingPath;
  ChordSegment? get activeChordSegment => _activeChordSegment;

  AudioPlayerService get playerService => _playerService;
  AudioRecorderService get recorderService => _recorderService;
  CameraRecordingService get cameraService => _cameraService;
  LyricsService get lyricsService => _lyricsService;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _projects = await _repository.loadProjects();
    _isLoading = false;
    notifyListeners();
    _setupPositionListener();
  }

  void _setupPositionListener() {
    _playerService.player.positionStream.listen((pos) {
      if (_activeProject != null && _activeProject!.chordSegments.isNotEmpty) {
        final currentChord = getActiveChord(pos, _activeProject!.chordSegments);
        if (_activeChordSegment?.id != currentChord?.id) {
          _activeChordSegment = currentChord;
          notifyListeners();
        }
      }
    });
  }

  ChordSegment? getActiveChord(Duration position, List<ChordSegment> chords) {
    final int currentMs = position.inMilliseconds;
    for (final chord in chords) {
      if (currentMs >= chord.startTimeMs && currentMs < chord.endTimeMs) {
        return chord;
      }
    }
    return null;
  }

  void openProject(AudioProject project) {
    _activeProject = project;
    _activeChordSegment = null;
    _playerService.loadProjectAudio(project);
    notifyListeners();
  }

  Future<void> importAudioAsProject(File file) async {
    _isLoading = true;
    notifyListeners();

    final AudioProject? newProj = await _importService.createProjectFromAudio(file);
    if (newProj != null) {
      await _repository.addProject(newProj);
      _projects.add(newProj);
      _activeProject = newProj;
      await _playerService.loadProjectAudio(newProj);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> importVideoAsProject(File file) async {
    _isLoading = true;
    notifyListeners();

    final AudioProject? newProj = await _importService.createProjectFromVideo(file);
    if (newProj != null) {
      await _repository.addProject(newProj);
      _projects.add(newProj);
      _activeProject = newProj;
      await _playerService.loadProjectAudio(newProj);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createMashup(AudioProject projectA, AudioProject projectB) async {
    if (projectA.originalAudioPath == null || projectB.originalAudioPath == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final String id = _uuid.v4();
      final String dirPath = File(projectA.originalAudioPath!).parent.path;
      final String targetPath = '$dirPath/project_${id}_mashup.m4a';
      
      final nativeService = NativeIosAudioService();
      final String? resultPath = await nativeService.mixAudioFiles(
        projectA.originalAudioPath!,
        projectB.originalAudioPath!,
        targetPath,
      );
      
      if (resultPath != null) {
        final now = DateTime.now();
        final AudioProject mashupProj = AudioProject(
          id: id,
          title: 'Mashup: ${projectA.title} & ${projectB.title}',
          originalAudioPath: resultPath,
          createdAt: now,
          updatedAt: now,
          status: ProjectStatus.imported,
          stemStatus: AnalysisStatus.unavailable,
          chordStatus: AnalysisStatus.unavailable,
          beatStatus: AnalysisStatus.unavailable,
          stemFiles: const StemFiles(),
          recordings: const [],
        );
        
        await _repository.addProject(mashupProj);
        _projects.add(mashupProj);
        _activeProject = mashupProj;
        await _playerService.loadProjectAudio(mashupProj);
      }
    } catch (e) {
      debugPrint('Error creating mashup: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    await _repository.deleteProject(id);
    _projects.removeWhere((p) => p.id == id);
    if (_activeProject?.id == id) {
      _activeProject = null;
      _activeChordSegment = null;
      await _playerService.stop();
    }
    notifyListeners();
  }

  Future<bool> startRecording() async {
    final bool hasPermission = await _recorderService.requestPermission();
    if (!hasPermission) return false;

    final String? path = await _recorderService.startGuitarRecording();
    if (path != null) {
      _recordingPath = path;
      _isRecording = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<String?> stopRecording(RecordingType type, RecordingMode mode) async {
    if (!_isRecording) return null;

    final String? path = await _recorderService.stopGuitarRecording();
    _isRecording = false;
    _recordingPath = null;
    notifyListeners();

    if (path != null && _activeProject != null) {
      await addRecordingTake(path, type, mode);
    }
    return path;
  }

  Future<void> addRecordingTake(String filePath, RecordingType type, RecordingMode mode) async {
    if (_activeProject == null) return;

    final String takeId = _uuid.v4();
    final String extension = filePath.split('.').last;
    final String takeTitle = 'Take_${_activeProject!.recordings.length + 1}_$extension';

    final RecordingTake take = RecordingTake(
      id: takeId,
      projectId: _activeProject!.id,
      title: takeTitle,
      filePath: filePath,
      type: type,
      mode: mode,
      createdAt: DateTime.now(),
    );

    final List<RecordingTake> updatedRecordings = List.from(_activeProject!.recordings)..add(take);
    final AudioProject updatedProject = _activeProject!.copyWith(
      recordings: updatedRecordings,
      updatedAt: DateTime.now(),
    );

    _activeProject = updatedProject;
    final int index = _projects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
    }

    await _repository.updateProject(updatedProject);
    notifyListeners();
  }

  Future<void> addChordSegment(String chordName, int startTimeMs, int endTimeMs) async {
    if (_activeProject == null) return;

    final String chordId = _uuid.v4();
    final ChordSegment segment = ChordSegment(
      id: chordId,
      chordName: chordName,
      startTimeMs: startTimeMs,
      endTimeMs: endTimeMs,
    );

    final List<ChordSegment> updatedSegments = List.from(_activeProject!.chordSegments)..add(segment);
    // Sort segments chronologically by startTimeMs
    updatedSegments.sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

    final AudioProject updatedProject = _activeProject!.copyWith(
      chordSegments: updatedSegments,
      chordStatus: AnalysisStatus.ready, // Set to ready since we have valid chord segments
      updatedAt: DateTime.now(),
    );

    _activeProject = updatedProject;
    final int index = _projects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
    }

    await _repository.updateProject(updatedProject);
    notifyListeners();
  }

  Future<void> deleteChordSegment(String chordId) async {
    if (_activeProject == null) return;

    final List<ChordSegment> updatedSegments = List.from(_activeProject!.chordSegments)
      ..removeWhere((c) => c.id == chordId);

    final AudioProject updatedProject = _activeProject!.copyWith(
      chordSegments: updatedSegments,
      chordStatus: updatedSegments.isEmpty ? AnalysisStatus.unavailable : AnalysisStatus.ready,
      updatedAt: DateTime.now(),
    );

    _activeProject = updatedProject;
    final int index = _projects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
    }

    await _repository.updateProject(updatedProject);
    notifyListeners();
  }

  Future<void> updateProjectStatus(ProjectStatus status) async {
    if (_activeProject == null) return;

    final AudioProject updatedProject = _activeProject!.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    _activeProject = updatedProject;
    final int index = _projects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
    }

    await _repository.updateProject(updatedProject);
    notifyListeners();
  }

  Future<void> runProjectAnalysis() async {
    final project = _activeProject;
    if (project == null || project.originalAudioPath == null) return;

    _activeProject = project.copyWith(
      stemStatus: AnalysisStatus.processing,
      chordStatus: AnalysisStatus.processing,
      beatStatus: AnalysisStatus.processing,
    );
    notifyListeners();

    try {
      final nativeService = NativeIosAudioService();
      
      // 1. Separate stems
      final stemPaths = await nativeService.separateStems(project.originalAudioPath!);
      final stemFiles = StemFiles(
        vocals: stemPaths['vocals'],
        bass: stemPaths['bass'],
        drums: stemPaths['drums'],
        piano: stemPaths['piano'],
        guitar: stemPaths['guitar'],
        other: stemPaths['other'],
      );

      // 2. Analyze chords
      final chordData = await nativeService.analyzeChords(project.originalAudioPath!);
      final List<ChordSegment> chordSegments = chordData.map((c) {
        return ChordSegment(
          id: _uuid.v4(),
          chordName: c['name'] as String,
          startTimeMs: ((c['startTime'] as double) * 1000).toInt(),
          endTimeMs: ((c['endTime'] as double) * 1000).toInt(),
        );
      }).toList();

      // 3. Analyze beats and tempo
      final beatTempoData = await nativeService.analyzeBeatsAndTempo(project.originalAudioPath!);
      final double tempo = (beatTempoData['tempo'] as num).toDouble();
      
      String keySig = 'C';
      if (beatTempoData.containsKey('key')) {
        keySig = _mapPitchClassToKey(beatTempoData['key'] as int);
      } else {
        if (chordSegments.isNotEmpty) {
          keySig = chordSegments.first.chordName.split(':').first;
        }
      }

      // 4. Auto-fetch lyrics from LRCLIB
      String? plainLyrics;
      String? syncedLyrics;
      List<LyricLine> lyricLines = [];
      try {
        final query = project.title;
        final list = await _lyricsService.searchLyrics(query);
        if (list.isNotEmpty) {
          final matched = list.firstWhere(
            (item) => item['syncedLyrics'] != null && (item['syncedLyrics'] as String).isNotEmpty,
            orElse: () => list.first,
          );
          plainLyrics = matched['plainLyrics'] as String?;
          syncedLyrics = matched['syncedLyrics'] as String?;
          
          if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
            lyricLines = _lyricsService.parseLrc(syncedLyrics);
          } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
            final splitLines = plainLyrics.split('\n');
            for (int i = 0; i < splitLines.length; i++) {
              lyricLines.add(LyricLine(
                id: _uuid.v4(),
                timeMs: 0,
                text: splitLines[i].trim(),
              ));
            }
          }
        }
      } catch (le) {
        debugPrint('Auto lyric fetch failed: $le');
      }

      _activeProject = _activeProject!.copyWith(
        stemStatus: AnalysisStatus.ready,
        chordStatus: AnalysisStatus.ready,
        beatStatus: AnalysisStatus.ready,
        stemFiles: stemFiles,
        chordSegments: chordSegments,
        bpm: tempo,
        keySignature: keySig,
        timeSignature: '4/4',
        status: ProjectStatus.ready,
        plainLyrics: plainLyrics,
        syncedLyrics: syncedLyrics,
        lyricLines: lyricLines,
        updatedAt: DateTime.now(),
      );

      // Update project in repository and refresh player loaded project
      await _repository.updateProject(_activeProject!);
      final index = _projects.indexWhere((p) => p.id == _activeProject!.id);
      if (index != -1) {
        _projects[index] = _activeProject!;
      }
      
      // Reload audio project configuration in player service to reflect stems are ready
      await _playerService.loadProjectAudio(_activeProject!);
      notifyListeners();
    } catch (e) {
      debugPrint('Separation and analysis failed: $e');
      _activeProject = project.copyWith(
        stemStatus: AnalysisStatus.error,
        chordStatus: AnalysisStatus.error,
        beatStatus: AnalysisStatus.error,
      );
      notifyListeners();
    }
  }

  String _mapPitchClassToKey(int keyIndex) {
    const keys = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    if (keyIndex >= 0 && keyIndex < keys.length) {
      return keys[keyIndex];
    }
    return 'C';
  }

  Future<List<Map<String, dynamic>>> searchLyrics(String query) async {
    _isSearchingLyrics = true;
    notifyListeners();
    try {
      final results = await _lyricsService.searchLyrics(query);
      _isSearchingLyrics = false;
      notifyListeners();
      return results;
    } catch (_) {
      _isSearchingLyrics = false;
      notifyListeners();
      return [];
    }
  }

  Future<void> applyLyricsToProject(String projectId, Map<String, dynamic> lyricData) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final project = _projects[projectIndex];
    final String? plain = lyricData['plainLyrics'] as String?;
    final String? synced = lyricData['syncedLyrics'] as String?;
    
    List<LyricLine> lines = [];
    if (synced != null && synced.isNotEmpty) {
      lines = _lyricsService.parseLrc(synced);
    } else if (plain != null && plain.isNotEmpty) {
      final splitLines = plain.split('\n');
      for (int i = 0; i < splitLines.length; i++) {
        lines.add(LyricLine(
          id: _uuid.v4(),
          timeMs: 0,
          text: splitLines[i].trim(),
        ));
      }
    }

    final updated = project.copyWith(
      plainLyrics: plain,
      syncedLyrics: synced,
      lyricLines: lines,
    );

    _projects[projectIndex] = updated;
    if (_activeProject?.id == projectId) {
      _activeProject = updated;
    }
    await _repository.updateProject(updated);
    notifyListeners();
  }

  @override
  void dispose() {
    _playerService.dispose();
    _recorderService.dispose();
    _cameraService.dispose();
    super.dispose();
  }
}
