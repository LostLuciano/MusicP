import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'state/project_controller.dart';
import 'services/stem_separation_service.dart';
import 'services/analysis_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectController()..init()),
        ChangeNotifierProvider(create: (_) => StemSeparationService()),
        ChangeNotifierProvider(create: (_) => AnalysisService()),
      ],
      child: const MusicStemStudioApp(),
    ),
  );
}
