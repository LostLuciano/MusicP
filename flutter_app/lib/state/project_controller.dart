import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/audio_project.dart';
import '../services/project_repository.dart';
import '../services/audio_import_service.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/camera_recording_service.dart';

class ProjectController with ChangeNotifier {
  final ProjectRepository _repository = ProjectRepository();
  final AudioImportService _importService = AudioImportService();
  final AudioPlayerService _playerService = AudioPlayerService();
  final AudioRecorderService _recorderService = AudioRecorderService();
  final CameraRecordingService _cameraService = CameraRecordingService();
  final Uuid _uuid = const Uuid();

  List<AudioProject> _projects = [];
  AudioProject? _activeProject;
  bool _isLoading = false;
  bool _isRecording = false;
  String? _recordingPath;

  ChordSegment? _activeChordSegment;

  List<AudioProject> get projects => _projects;
  AudioProject? get activeProject => _activeProject;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;
  ChordSegment? get activeChordSegment => _activeChordSegment;

  AudioPlayerService get playerService => _playerService;
  AudioRecorderService get recorderService => _recorderService;
  CameraRecordingService get cameraService => _cameraService;

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

  @override
  void dispose() {
    _playerService.dispose();
    _recorderService.dispose();
    _cameraService.dispose();
    super.dispose();
  }
}
