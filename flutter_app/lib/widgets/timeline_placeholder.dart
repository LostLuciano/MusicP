import 'package:flutter/material.dart';

class TimelinePlaceholder extends StatelessWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration>? onSeek;

  const TimelinePlaceholder({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final double value = totalDuration.inSeconds > 0
        ? currentPosition.inSeconds / totalDuration.inSeconds
        : 0.0;

    return Column(
      children: [
        Slider(
          value: value.clamp(0.0, 1.0),
          onChanged: (newValue) {
            if (onSeek != null) {
              final seconds = (newValue * totalDuration.inSeconds).round();
              onSeek!(Duration(seconds: seconds));
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentPosition),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                _formatDuration(totalDuration),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
