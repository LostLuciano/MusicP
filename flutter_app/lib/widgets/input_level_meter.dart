import 'package:flutter/material.dart';

class InputLevelMeter extends StatelessWidget {
  final double level; // Value between 0.0 (silent) and 1.0 (clipping)
  final String dbValue;

  const InputLevelMeter({
    super.key,
    required this.level,
    required this.dbValue,
  });

  @override
  Widget build(BuildContext context) {
    const int segments = 25;
    final activeSegments = (level * segments).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Input Gitar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              dbValue,
              style: const TextStyle(
                color: Color(0xFFFF8C37),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(segments, (index) {
            final isActive = index < activeSegments;
            Color segmentColor;

            // Green to yellow to red segments
            if (index < segments * 0.6) {
              segmentColor = const Color(0xFF00FF66); // Green
            } else if (index < segments * 0.85) {
              segmentColor = const Color(0xFFFFB800); // Yellow
            } else {
              segmentColor = const Color(0xFFFF2E93); // Red
            }

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? segmentColor
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: segmentColor.withValues(alpha: 0.4),
                            blurRadius: 4,
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
