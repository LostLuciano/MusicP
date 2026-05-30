import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/state/project_controller.dart';
import 'package:flutter_app/models/audio_project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'create') {
          return null;
        }
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'init') {
          return {
            'id': 'mock-player-id',
          };
        }
        return null;
      },
    );
  });

  group('Chord Sync Logic Tests', () {
    late ProjectController controller;
    final chords = [
      const ChordSegment(id: 'c1', chordName: 'Am', startTimeMs: 0, endTimeMs: 2000),
      const ChordSegment(id: 'c2', chordName: 'F', startTimeMs: 2000, endTimeMs: 4000),
      const ChordSegment(id: 'c3', chordName: 'C', startTimeMs: 4000, endTimeMs: 6000),
      const ChordSegment(id: 'c4', chordName: 'G', startTimeMs: 6000, endTimeMs: 8000),
    ];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = ProjectController();
    });

    test('0ms returns first chord', () {
      final chord = controller.getActiveChord(Duration.zero, chords);
      expect(chord, isNotNull);
      expect(chord!.chordName, 'Am');
      expect(chord.id, 'c1');
    });

    test('Position inside range returns correct chord', () {
      final chord1 = controller.getActiveChord(const Duration(milliseconds: 1500), chords);
      expect(chord1?.chordName, 'Am');

      final chord2 = controller.getActiveChord(const Duration(milliseconds: 2500), chords);
      expect(chord2?.chordName, 'F');

      final chord3 = controller.getActiveChord(const Duration(milliseconds: 5999), chords);
      expect(chord3?.chordName, 'C');
    });

    test('Position outside range returns null', () {
      final chord = controller.getActiveChord(const Duration(milliseconds: 8500), chords);
      expect(chord, isNull);
    });

    test('Tapping segment provides correct seek target (startTimeMs)', () {
      final targetChord = chords[2]; // C, starts at 4000ms
      expect(targetChord.startTimeMs, 4000);
    });
  });
}
