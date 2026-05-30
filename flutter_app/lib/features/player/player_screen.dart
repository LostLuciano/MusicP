import 'package:flutter/material.dart';
import '../../widgets/waveform_placeholder.dart';
import '../../widgets/transport_controls.dart';

class PlayerScreen extends StatefulWidget {
  final String? audioPath;

  const PlayerScreen({super.key, this.audioPath});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isPlaying = false;
  final double _playbackProgress = 0.3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        title: const Text('Sekarang Diputar'),
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Centered album artwork with gradient/shadow
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF9D4EDD),
                      Color(0xFFFF2E93),
                      Color(0xFFFF8C37),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2E93).withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Track details
            Text(
              widget.audioPath != null
                  ? widget.audioPath!.split('/').last
                  : 'Sweet Chaos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'A minor • 128 BPM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Dynamic Waveform placeholder with gradient coloring
            WaveformPlaceholder(
              height: 80,
              isPlaying: _isPlaying,
              progress: _playbackProgress,
            ),
            const SizedBox(height: 24),

            // Audio Transport controls
            TransportControls(
              isPlaying: _isPlaying,
              onPlayPause: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
              onPrev: () {},
              onNext: () {},
            ),
          ],
        ),
      ),
    );
  }
}
