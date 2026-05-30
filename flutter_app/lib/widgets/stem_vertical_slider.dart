import 'package:flutter/material.dart';

class StemVerticalSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double volume; // 0.0 to 1.0
  final ValueChanged<double> onChanged;

  const StemVerticalSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.volume,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The vertical slider body
        Expanded(
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              // Find local position relative to the height of the slider track
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localY = renderBox.globalToLocal(details.globalPosition).dy;
              // The track is about 150-200px tall. Let's restrict it to the vertical slider boundaries.
              final trackHeight =
                  renderBox.size.height - 40; // Subtract padding for label/icon
              if (trackHeight > 0) {
                // Calculate volume (inverting Y because top is 0.0 and bottom is trackHeight)
                final double rawVolume = 1.0 - (localY / trackHeight);
                onChanged(rawVolume.clamp(0.0, 1.0));
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final activeHeight = height * volume;

                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Background track
                    Container(
                      width: 14,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Active gradient level
                    Container(
                      width: 14,
                      height: activeHeight.clamp(0.0, height),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2E93), Color(0xFFFF8C37)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FF2E93),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    // Accent indicator dot on top of active volume level
                    Positioned(
                      bottom: (activeHeight - 7).clamp(0.0, height - 14),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black38, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Icon
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        // Label
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
