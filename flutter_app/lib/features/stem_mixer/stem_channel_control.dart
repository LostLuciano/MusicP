import 'package:flutter/material.dart';
import '../../models/stem_channel.dart';

class StemChannelControl extends StatelessWidget {
  final StemChannel channel;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onMuteToggled;
  final VoidCallback onSoloPressed;

  const StemChannelControl({
    super.key,
    required this.channel,
    required this.onVolumeChanged,
    required this.onMuteToggled,
    required this.onSoloPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: channel.isSoloed
              ? const Color(0xFF9D4EDD)
              : Colors.white.withValues(alpha: 0.05),
          width: channel.isSoloed ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                channel.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  // Mute toggle
                  IconButton(
                    icon: Icon(
                      channel.isMuted ? Icons.volume_off : Icons.volume_up,
                      color: channel.isMuted
                          ? Colors.redAccent
                          : Colors.white70,
                    ),
                    onPressed: () => onMuteToggled(!channel.isMuted),
                  ),
                  // Solo mode placeholder button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: channel.isSoloed
                          ? const Color(0xFF9D4EDD)
                          : Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: onSoloPressed,
                    child: const Text('SOLO', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white38, size: 16),
              Expanded(
                child: Slider(
                  value: channel.isMuted ? 0.0 : channel.volume,
                  onChanged: channel.isMuted ? null : onVolumeChanged,
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white38, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
