import 'package:flutter/material.dart';

class TransportControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const TransportControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 36,
            color: Colors.white70,
          ),
          onPressed: onPrev,
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF2E93), Color(0xFFFF8C37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x4DFF2E93),
                  blurRadius: 15,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 36,
            color: Colors.white70,
          ),
          onPressed: onNext,
        ),
      ],
    );
  }
}
