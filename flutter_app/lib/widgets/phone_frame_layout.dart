import 'package:flutter/material.dart';

class PhoneFrameLayout extends StatelessWidget {
  final Widget child;

  const PhoneFrameLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is greater than a typical phone size (e.g., 600px), center the app as a phone frame.
        if (constraints.maxWidth > 600) {
          return Container(
            color: const Color(
              0xFF07050F,
            ), // Absolute deep dark outside background
            child: Center(
              child: Container(
                width: 410,
                height: 860,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0C1B), // Dark app background
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          );
        }

        // Standard mobile display
        return child;
      },
    );
  }
}
