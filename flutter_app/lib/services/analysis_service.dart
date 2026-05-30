import 'package:flutter/foundation.dart';
import '../models/audio_project.dart';

class AnalysisService with ChangeNotifier {
  AnalysisStatus _chordStatus = AnalysisStatus.unavailable;
  AnalysisStatus _beatStatus = AnalysisStatus.unavailable;

  AnalysisStatus get chordStatus => _chordStatus;
  AnalysisStatus get beatStatus => _beatStatus;

  Future<Map<String, dynamic>?> analyzeChordAndTempo(
    AudioProject project,
  ) async {
    _chordStatus = AnalysisStatus.processing;
    _beatStatus = AnalysisStatus.processing;
    notifyListeners();

    try {
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate analysis delay

      // Default to unavailable until actual CoreML models are embedded in build process.
      _chordStatus = AnalysisStatus.unavailable;
      _beatStatus = AnalysisStatus.unavailable;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Analysis processing failed: $e');
      _chordStatus = AnalysisStatus.error;
      _beatStatus = AnalysisStatus.error;
      notifyListeners();
      return null;
    }
  }

  void setStatuses({AnalysisStatus? chord, AnalysisStatus? beat}) {
    if (chord != null) _chordStatus = chord;
    if (beat != null) _beatStatus = beat;
    notifyListeners();
  }
}
