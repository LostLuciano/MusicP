import 'package:flutter/material.dart';

class ProjectListTile extends StatelessWidget {
  final String title;
  final String keyName;
  final int bpm;
  final String duration;
  final String date;
  final VoidCallback onTap;
  final VoidCallback onPlayTap;

  const ProjectListTile({
    super.key,
    required this.title,
    required this.keyName,
    required this.bpm,
    required this.duration,
    required this.date,
    required this.onTap,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131022),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF9D4EDD), Color(0xFFFF2E93)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.audio_file_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    keyName,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$bpm BPM',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  duration,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.play_arrow_rounded,
            color: Color(0xFFFF2E93),
            size: 28,
          ),
          onPressed: onPlayTap,
        ),
      ),
    );
  }
}
