import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/chord_strip.dart';
import '../../widgets/stem_vertical_slider.dart';
import '../../widgets/waveform_placeholder.dart';
import '../../widgets/transport_controls.dart';
import '../../state/project_controller.dart';
import '../../models/audio_project.dart';
import '../chord_viewer/chord_viewer_screen.dart';

class StemMixerScreen extends StatefulWidget {
  const StemMixerScreen({super.key});

  @override
  State<StemMixerScreen> createState() => _StemMixerScreenState();
}

class _StemMixerScreenState extends State<StemMixerScreen> {
  bool _isPlaying = false;
  int _activeTab = 0; // 0: Akor, 1: Lirik, 2: Lagi
  double _playbackProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Stems volume
  double _vocalsVol = 0.0;
  double _bassVol = 0.0;
  double _drumsVol = 0.0;
  double _pianoVol = 0.0;
  double _guitarVol = 0.0;
  double _otherVol = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPlayerListeners();
    });
  }

  void _initPlayerListeners() {
    final controller = Provider.of<ProjectController>(context, listen: false);
    final player = controller.playerService.player;

    player.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          if (_totalDuration.inMilliseconds > 0) {
            _playbackProgress =
                pos.inMilliseconds / _totalDuration.inMilliseconds;
          }
        });
      }
    });

    player.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() {
          _totalDuration = dur;
        });
      }
    });

    player.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectController>(context);
    final project = controller.activeProject;

    if (project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0C1B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tidak ada project aktif.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final isStemsReady = project.stemStatus == AnalysisStatus.ready;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        title: Text(project.title),
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.ios_share_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
        child: Column(
          children: [
            const ChordStrip(),
            const SizedBox(height: 32),

            // 6 vertical stem sliders
            Expanded(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131022),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Opacity(
                      opacity: isStemsReady ? 1.0 : 0.25,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StemVerticalSlider(
                            label: 'Vocals',
                            icon: Icons.mic_none_rounded,
                            volume: _vocalsVol,
                            onChanged: isStemsReady
                                ? (val) => setState(() => _vocalsVol = val)
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Bass',
                            icon: Icons.music_note_rounded,
                            volume: _bassVol,
                            onChanged: isStemsReady
                                ? (val) => setState(() => _bassVol = val)
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Drums',
                            icon: Icons.hearing_rounded,
                            volume: _drumsVol,
                            onChanged: isStemsReady
                                ? (val) => setState(() => _drumsVol = val)
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Piano',
                            icon: Icons.piano_rounded,
                            volume: _pianoVol,
                            onChanged: isStemsReady
                                ? (val) => setState(() => _pianoVol = val)
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Guitar',
                            icon: Icons.music_note_rounded,
                            volume: _guitarVol,
                            onChanged: isStemsReady
                                ? (val) => setState(() => _guitarVol = val)
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Other',
                            icon: Icons.blur_on_rounded,
                            volume: _otherVol,
                            onChanged: isStemsReady
                                ? (val) => setState(() => _otherVol = val)
                                : (val) {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overlay notice if stems are unavailable
                  if (!isStemsReady)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1934),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFFFF2E93),
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Separation Belum Tersedia',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Stem separation model belum diunduh / tidak tersedia offline di platform ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF2E93),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: null, // Disabled in MVP
                              child: const Text(
                                'Siapkan Model',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Waveform timeline (bound to real player position)
            WaveformPlaceholder(
              height: 60,
              progress: _playbackProgress,
              isPlaying: _isPlaying,
            ),
            const SizedBox(height: 8),

            // Time indicator row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                Text(
                  '-${_formatDuration(_totalDuration - _currentPosition)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSubTabButton(0, 'Akor'),
                _buildSubTabButton(1, 'Lirik'),
                _buildSubTabButton(2, 'Lagi'),
              ],
            ),
            const SizedBox(height: 28),

            // Playback controls
            TransportControls(
              isPlaying: _isPlaying,
              onPlayPause: () async {
                try {
                  if (_isPlaying) {
                    await controller.playerService.pause();
                  } else {
                    await controller.playerService.play();
                  }
                } catch (_) {}
              },
            ),
            const SizedBox(height: 20),

            // Stats footer: BPM and Key
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  project.bpm != null
                      ? '${project.bpm!.toInt()} BPM'
                      : 'Tempo: -',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  project.keySignature != null
                      ? 'KUNCI: ${project.keySignature}'
                      : 'KUNCI: -',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label) {
    final isSelected = _activeTab == index;
    final activeColor = const Color(0xFFFF2E93);

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChordViewerScreen()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
