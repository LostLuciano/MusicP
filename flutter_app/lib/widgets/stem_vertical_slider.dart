import 'package:flutter/material.dart';

class StemVerticalSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double volume; // 0.0 to 1.0
  final bool isMuted;
  final ValueChanged<double> onChanged;
  final VoidCallback? onMuteToggle;

  const StemVerticalSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.volume,
    required this.onChanged,
    this.isMuted = false,
    this.onMuteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveVolume = isMuted ? 0.0 : volume;

    return Column(
      children: [
        // The vertical slider body
        Expanded(
          child: GestureDetector(
            onVerticalDragUpdate: isMuted
                ? null
                : (details) {
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localY =
                        renderBox.globalToLocal(details.globalPosition).dy;
                    final trackHeight = renderBox.size.height - 40;
                    if (trackHeight > 0) {
                      final double rawVolume = 1.0 - (localY / trackHeight);
                      onChanged(rawVolume.clamp(0.0, 1.0));
                    }
                  },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final activeHeight = height * effectiveVolume;

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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 14,
                      height: activeHeight.clamp(0.0, height),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMuted
                              ? [Colors.white24, Colors.white10]
                              : [const Color(0xFFFF2E93), const Color(0xFFFF8C37)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isMuted
                            ? []
                            : const [
                                BoxShadow(
                                  color: Color(0x33FF2E93),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                      ),
                    ),
                    // Accent indicator dot
                    if (!isMuted)
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
        const SizedBox(height: 10),
        // Mute toggle icon
        GestureDetector(
          onTap: onMuteToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isMuted
                  ? const Color(0xFFFF2E93).withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: isMuted ? const Color(0xFFFF2E93) : Colors.white54,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 3),
        // Label
        Text(
          label,
          style: TextStyle(
            color: isMuted ? const Color(0xFFFF2E93) : Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
