import 'package:flutter/foundation.dart';
import '../models/audio_project.dart';

class StemSeparationService with ChangeNotifier {
  AnalysisStatus _status = AnalysisStatus.unavailable;

  AnalysisStatus get status => _status;

  Future<StemFiles?> processSeparation(AudioProject project) async {
    _status = AnalysisStatus.processing;
    notifyListeners();

    try {
      // For now, since native models aren't shipped in MVP, return unavailable/waitingModel.
      // If running on a real iOS device with MethodChannel support, we can check.
      // But we will default to unavailable to avoid faking AI.
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate process delay

      _status = AnalysisStatus
          .unavailable; // Set to unavailable as coreml model is not shipped
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Stem Separation processing failed: $e');
      _status = AnalysisStatus.error;
      notifyListeners();
      return null;
    }
  }

  void setStatus(AnalysisStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
