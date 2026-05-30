import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/audio_project.dart';

void main() {
  group('Model Serialization Tests', () {
    test('ChordSegment serialization', () {
      final chord = ChordSegment(
        id: 'chord-123',
        chordName: 'Am',
        startTimeMs: 1000,
        endTimeMs: 5000,
      );

      final json = chord.toJson();
      expect(json['id'], 'chord-123');
      expect(json['chordName'], 'Am');
      expect(json['startTimeMs'], 1000);
      expect(json['endTimeMs'], 5000);

      final fromJson = ChordSegment.fromJson(json);
      expect(fromJson.id, 'chord-123');
      expect(fromJson.chordName, 'Am');
      expect(fromJson.startTimeMs, 1000);
      expect(fromJson.endTimeMs, 5000);
    });

    test('RecordingTake serialization', () {
      final take = RecordingTake(
        id: 'take-123',
        projectId: 'project-123',
        title: 'Take_1_m4a',
        filePath: '/mock/path/take_1.m4a',
        type: RecordingType.audio,
        mode: RecordingMode.guitarOnly,
        createdAt: DateTime.parse('2026-05-30T12:00:00Z'),
        duration: const Duration(seconds: 15),
      );

      final json = take.toJson();
      expect(json['id'], 'take-123');
      expect(json['projectId'], 'project-123');
      expect(json['type'], 'RecordingType.audio');
      expect(json['mode'], 'RecordingMode.guitarOnly');
      expect(json['durationMs'], 15000);

      final fromJson = RecordingTake.fromJson(json);
      expect(fromJson.id, 'take-123');
      expect(fromJson.projectId, 'project-123');
      expect(fromJson.type, RecordingType.audio);
      expect(fromJson.mode, RecordingMode.guitarOnly);
      expect(fromJson.createdAt, DateTime.parse('2026-05-30T12:00:00Z'));
      expect(fromJson.duration?.inMilliseconds, 15000);
    });

    test('AudioProject serialization', () {
      final project = AudioProject(
        id: 'proj-123',
        title: 'My Project',
        originalAudioPath: '/mock/audio.mp3',
        createdAt: DateTime.parse('2026-05-30T12:00:00Z'),
        updatedAt: DateTime.parse('2026-05-30T12:05:00Z'),
        status: ProjectStatus.imported,
        stemStatus: AnalysisStatus.unavailable,
        chordStatus: AnalysisStatus.ready,
        beatStatus: AnalysisStatus.processing,
        bpm: 120.0,
        keySignature: 'Am',
        timeSignature: '4/4',
        stemFiles: const StemFiles(vocals: '/mock/vocals.wav'),
        recordings: [
          RecordingTake(
            id: 'take-1',
            projectId: 'proj-123',
            title: 'Take 1',
            filePath: '/mock/take1.m4a',
            type: RecordingType.audio,
            mode: RecordingMode.guitarOnly,
            createdAt: DateTime.parse('2026-05-30T12:01:00Z'),
          ),
        ],
        chordSegments: [
          const ChordSegment(
            id: 'chord-1',
            chordName: 'C',
            startTimeMs: 0,
            endTimeMs: 2000,
          ),
        ],
      );

      final json = project.toJson();
      expect(json['id'], 'proj-123');
      expect(json['title'], 'My Project');
      expect(json['status'], 'ProjectStatus.imported');
      expect(json['chordStatus'], 'AnalysisStatus.ready');
      expect(json['beatStatus'], 'AnalysisStatus.processing');
      expect(json['bpm'], 120.0);
      expect(json['keySignature'], 'Am');
      expect(json['timeSignature'], '4/4');
      expect(json['stemFiles']['vocals'], '/mock/vocals.wav');
      expect(json['recordings'].length, 1);
      expect(json['chordSegments'].length, 1);

      final fromJson = AudioProject.fromJson(json);
      expect(fromJson.id, 'proj-123');
      expect(fromJson.title, 'My Project');
      expect(fromJson.status, ProjectStatus.imported);
      expect(fromJson.chordStatus, AnalysisStatus.ready);
      expect(fromJson.beatStatus, AnalysisStatus.processing);
      expect(fromJson.bpm, 120.0);
      expect(fromJson.keySignature, 'Am');
      expect(fromJson.timeSignature, '4/4');
      expect(fromJson.stemFiles?.vocals, '/mock/vocals.wav');
      expect(fromJson.recordings.length, 1);
      expect(fromJson.chordSegments.length, 1);
      expect(fromJson.chordSegments.first.chordName, 'C');
    });
  });
}
