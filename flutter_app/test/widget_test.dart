import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/state/project_controller.dart';
import 'package:flutter_app/services/stem_separation_service.dart';
import 'package:flutter_app/services/analysis_service.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Music Stem Studio home loads', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProjectController()..init()),
          ChangeNotifierProvider(create: (_) => StemSeparationService()),
          ChangeNotifierProvider(create: (_) => AnalysisService()),
        ],
        child: const MusicStemStudioApp(),
      ),
    );

    // Re-render to let the async tasks inside init completion fire
    await tester.pump();

    // Verify that the title of the app is shown.
    expect(find.text('Halo, Musikus! 👋'), findsOneWidget);

    // Reset physical size after test
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
