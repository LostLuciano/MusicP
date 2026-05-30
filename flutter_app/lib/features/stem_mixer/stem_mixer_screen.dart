import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/chord_strip.dart';
import '../../widgets/stem_vertical_slider.dart';
import '../../widgets/waveform_placeholder.dart';
import '../../widgets/transport_controls.dart';
import '../../state/project_controller.dart';
import '../../models/audio_project.dart';
import '../../services/native_ios_audio_service.dart';
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

  // Stems volume - default to 1.0 (audible)
  double _vocalsVol = 1.0;
  double _bassVol = 1.0;
  double _drumsVol = 1.0;
  double _pianoVol = 1.0;
  double _guitarVol = 1.0;
  double _otherVol = 1.0;

  // Mute state per stem
  final Map<String, bool> _muteState = {
    'vocals': false,
    'bass': false,
    'drums': false,
    'piano': false,
    'guitar': false,
    'other': false,
  };

  // Speed: 0.5x to 2.0x, default 1.0x (normal)
  double _playbackSpeed = 1.0;
  static const List<double> _speedPresets = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const List<String> _speedLabels = ['0.5×', '0.75×', '1×', '1.25×', '1.5×', '2×'];

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
                            isMuted: _muteState['vocals']!,
                            onMuteToggle: isStemsReady ? () {
                              final muted = !_muteState['vocals']!;
                              setState(() => _muteState['vocals'] = muted);
                              NativeIosAudioService().muteStem('vocals', muted);
                            } : null,
                            onChanged: isStemsReady
                                ? (val) {
                                    setState(() => _vocalsVol = val);
                                    NativeIosAudioService().setStemVolume('vocals', val);
                                  }
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Bass',
                            icon: Icons.music_note_rounded,
                            volume: _bassVol,
                            isMuted: _muteState['bass']!,
                            onMuteToggle: isStemsReady ? () {
                              final muted = !_muteState['bass']!;
                              setState(() => _muteState['bass'] = muted);
                              NativeIosAudioService().muteStem('bass', muted);
                            } : null,
                            onChanged: isStemsReady
                                ? (val) {
                                    setState(() => _bassVol = val);
                                    NativeIosAudioService().setStemVolume('bass', val);
                                  }
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Drums',
                            icon: Icons.hearing_rounded,
                            volume: _drumsVol,
                            isMuted: _muteState['drums']!,
                            onMuteToggle: isStemsReady ? () {
                              final muted = !_muteState['drums']!;
                              setState(() => _muteState['drums'] = muted);
                              NativeIosAudioService().muteStem('drums', muted);
                            } : null,
                            onChanged: isStemsReady
                                ? (val) {
                                    setState(() => _drumsVol = val);
                                    NativeIosAudioService().setStemVolume('drums', val);
                                  }
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Piano',
                            icon: Icons.piano_rounded,
                            volume: _pianoVol,
                            isMuted: _muteState['piano']!,
                            onMuteToggle: isStemsReady ? () {
                              final muted = !_muteState['piano']!;
                              setState(() => _muteState['piano'] = muted);
                              NativeIosAudioService().muteStem('piano', muted);
                            } : null,
                            onChanged: isStemsReady
                                ? (val) {
                                    setState(() => _pianoVol = val);
                                    NativeIosAudioService().setStemVolume('piano', val);
                                  }
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Guitar',
                            icon: Icons.music_note_rounded,
                            volume: _guitarVol,
                            isMuted: _muteState['guitar']!,
                            onMuteToggle: isStemsReady ? () {
                              final muted = !_muteState['guitar']!;
                              setState(() => _muteState['guitar'] = muted);
                              NativeIosAudioService().muteStem('guitar', muted);
                            } : null,
                            onChanged: isStemsReady
                                ? (val) {
                                    setState(() => _guitarVol = val);
                                    NativeIosAudioService().setStemVolume('guitar', val);
                                  }
                                : (val) {},
                          ),
                          StemVerticalSlider(
                            label: 'Other',
                            icon: Icons.blur_on_rounded,
                            volume: _otherVol,
                            isMuted: _muteState['other']!,
                            onMuteToggle: isStemsReady ? () {
                              final muted = !_muteState['other']!;
                              setState(() => _muteState['other'] = muted);
                              NativeIosAudioService().muteStem('other', muted);
                            } : null,
                            onChanged: isStemsReady
                                ? (val) {
                                    setState(() => _otherVol = val);
                                    NativeIosAudioService().setStemVolume('other', val);
                                  }
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
                              onPressed: project.stemStatus == AnalysisStatus.processing
                                  ? null
                                  : () async {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Memulai Pemisahan Stem & Analisis Musik...'),
                                        ),
                                      );
                                      await controller.runProjectAnalysis();
                                    },
                              child: Text(
                                project.stemStatus == AnalysisStatus.processing
                                    ? 'Memproses...'
                                    : 'Siapkan Model',
                                style: const TextStyle(color: Colors.white),
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
            const SizedBox(height: 12),

            // ── Speed Changer ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF131022),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, color: Color(0xFFFF8C37), size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'KECEPATAN',
                        style: TextStyle(
                          color: Color(0xFFFF8C37),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_playbackSpeed == _playbackSpeed.truncateToDouble() ? _playbackSpeed.toInt() : _playbackSpeed}×',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Preset speed buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_speedPresets.length, (i) {
                      final isSelected = _playbackSpeed == _speedPresets[i];
                      return GestureDetector(
                        onTap: () async {
                          setState(() => _playbackSpeed = _speedPresets[i]);
                          await NativeIosAudioService().setPlaybackSpeed(_speedPresets[i]);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF8C37).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF8C37)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            _speedLabels[i],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFFF8C37)
                                  : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSubTabButton(0, 'Akor'),
                _buildSubTabButton(1, 'Lirik'),
                _buildSubTabButton(2, 'Lagi'),
              ],
            ),
            const SizedBox(height: 16),

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
