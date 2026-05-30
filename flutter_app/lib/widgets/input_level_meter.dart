import 'package:flutter/material.dart';

/// A live audio input level meter. Feed it a real [level] (0.0–1.0)
/// from a stream (e.g. AudioRecorder.onAmplitudeChanged) for dynamic response.
class InputLevelMeter extends StatelessWidget {
  /// Signal level, 0.0 = silent, 1.0 = full scale / clipping.
  final double level;

  /// Formatted dB string shown on the right (e.g. "-24 dB").
  final String dbValue;

  /// Label shown on the left. Defaults to "Input Suara".
  final String label;

  const InputLevelMeter({
    super.key,
    required this.level,
    required this.dbValue,
    this.label = 'Input Suara',
  });

  @override
  Widget build(BuildContext context) {
    const int segments = 25;
    final activeSegments = (level.clamp(0.0, 1.0) * segments).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 100),
              style: TextStyle(
                color: level > 0.85
                    ? const Color(0xFFFF2E93)
                    : level > 0.6
                        ? const Color(0xFFFFB800)
                        : const Color(0xFFFF8C37),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              child: Text(dbValue),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(segments, (index) {
            final isActive = index < activeSegments;
            final Color segmentColor;

            if (index < segments * 0.6) {
              segmentColor = const Color(0xFF00FF66); // Green - safe zone
            } else if (index < segments * 0.85) {
              segmentColor = const Color(0xFFFFB800); // Yellow - caution
            } else {
              segmentColor = const Color(0xFFFF2E93); // Red - clipping!
            }

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: isActive ? 10 : 8, // Active segments are slightly taller
                decoration: BoxDecoration(
                  color: isActive
                      ? segmentColor
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: segmentColor.withValues(alpha: 0.5),
                            blurRadius: 5,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
