import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'widgets/phone_frame_layout.dart';

class MusicStemStudioApp extends StatelessWidget {
  const MusicStemStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Stem Studio',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return PhoneFrameLayout(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
