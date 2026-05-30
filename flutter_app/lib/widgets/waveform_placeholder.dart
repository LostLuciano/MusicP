import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPlaceholder extends StatelessWidget {
  final double height;
  final bool isPlaying;
  final double progress; // Value between 0.0 and 1.0

  const WaveformPlaceholder({
    super.key,
    this.height = 80,
    this.isPlaying = false,
    this.progress = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(42);
    const int barCount = 50;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131022),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(barCount, (index) {
              final double barProgress = index / barCount;
              final bool isPassed = barProgress <= progress;

              // Compute a dynamic height factor to simulate active waveforms
              final double factor = isPlaying
                  ? (0.2 +
                        0.8 *
                            sin(
                              index * 0.4 +
                                  DateTime.now().millisecondsSinceEpoch * 0.005,
                            ).abs())
                  : (0.1 + 0.9 * random.nextDouble());

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: height * factor * 0.8,
                  decoration: BoxDecoration(
                    gradient: isPassed
                        ? const LinearGradient(
                            colors: [Color(0xFFFF2E93), Color(0xFFFF8C37)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          )
                        : null,
                    color: !isPassed
                        ? Colors.white.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          // Vertical progress indicator line
          Align(
            alignment: Alignment(progress * 2 - 1, 0),
            child: Container(
              width: 3,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF2E93), Color(0xFFFF8C37)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
