import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/waveform_placeholder.dart';
import '../../state/project_controller.dart';
import '../../models/audio_project.dart';
import '../stem_mixer/stem_mixer_screen.dart';
import '../stem_setup/stem_setup_screen.dart';
import '../chord_viewer/chord_viewer_screen.dart';
import '../record_setup/record_setup_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String title;
  const ProjectDetailScreen({super.key, required this.title});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _progress = 0.0;
  ChordSegment? _activeChord;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playSub;
  StreamSubscription? _chordSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initListeners());
  }

  void _initListeners() {
    final controller = Provider.of<ProjectController>(context, listen: false);
    final player = controller.playerService.player;

    _posSub = player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = pos;
        if (_duration.inMilliseconds > 0) {
          _progress = pos.inMilliseconds / _duration.inMilliseconds;
        }
        // Update live chord
        final proj = controller.activeProject;
        if (proj != null && proj.chordSegments.isNotEmpty) {
          _activeChord = controller.getActiveChord(pos, proj.chordSegments);
        }
      });
    });

    _durSub = player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _duration = dur);
    });

    _playSub = player.playingStream.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _chordSub?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectController>(context);
    final project = controller.activeProject;

    if (project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0C1B),
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
            child: Text('Proyek tidak ditemukan.',
                style: TextStyle(color: Colors.white70))),
      );
    }

    final hasChords = project.chordSegments.isNotEmpty;
    final stemReady = project.stemStatus == AnalysisStatus.ready;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, controller, project),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Key / BPM / Time Sig stats ─────────────────────────────
              Row(
                children: [
                  _statPill(Icons.music_note_rounded,
                      project.keySignature ?? '—', 'Key'),
                  const SizedBox(width: 10),
                  _statPill(
                      Icons.speed_rounded,
                      project.bpm != null
                          ? '${project.bpm!.toInt()} BPM'
                          : '— BPM',
                      'Tempo'),
                  const SizedBox(width: 10),
                  _statPill(Icons.grid_4x4_rounded,
                      project.timeSignature ?? '4/4', 'Birama'),
                ],
              ),
              const SizedBox(height: 20),

              // ── Live Chord Display ────────────────────────────────────
              GestureDetector(
                onTap: hasChords
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChordViewerScreen()))
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _activeChord != null
                          ? [
                              const Color(0xFF2A0E3F),
                              const Color(0xFF1A0A2E)
                            ]
                          : [
                              const Color(0xFF1A1530),
                              const Color(0xFF131022)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _activeChord != null
                          ? const Color(0xFFFF2E93).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.piano_rounded,
                                    color: Color(0xFFFF8C37), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  hasChords
                                      ? 'CHORD AKTIF'
                                      : 'DETEKSI CHORD',
                                  style: const TextStyle(
                                    color: Color(0xFFFF8C37),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _activeChord?.chordName ??
                                  (hasChords ? '—' : 'Belum Dianalisis'),
                              style: TextStyle(
                                color: _activeChord != null
                                    ? Colors.white
                                    : Colors.white38,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            if (hasChords)
                              Text(
                                '${_fmt(_position)} / ${_fmt(_duration)}',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      if (hasChords) ...[
                        // Next chord preview
                        _buildNextChordBadge(project),
                        const SizedBox(width: 12),
                      ],
                      Icon(
                        hasChords
                            ? Icons.chevron_right_rounded
                            : Icons.info_outline_rounded,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Playback Bar ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131022),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    WaveformPlaceholder(
                      height: 56,
                      progress: _progress,
                      isPlaying: _isPlaying,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded,
                              color: Colors.white70),
                          onPressed: () {
                            final newPos = _position - const Duration(seconds: 10);
                            controller.playerService.seek(
                                newPos < Duration.zero ? Duration.zero : newPos);
                          },
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            if (_isPlaying) {
                              await controller.playerService.pause();
                            } else {
                              await controller.playerService.play();
                            }
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isPlaying
                                  ? const Color(0xFFFF2E93)
                                  : const Color(0xFFFF2E93).withValues(alpha: 0.2),
                              border: Border.all(
                                  color: const Color(0xFFFF2E93), width: 1.5),
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.forward_10_rounded,
                              color: Colors.white70),
                          onPressed: () {
                            final newPos = _position + const Duration(seconds: 10);
                            controller.playerService.seek(
                                newPos > _duration ? _duration : newPos);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 3 Quick Action Buttons ──────────────────────────────────
              _sectionLabel('AKSI UTAMA'),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Open Stem Mixer
                  Expanded(
                    child: _actionCard(
                      icon: Icons.tune_rounded,
                      label: 'Atur Stem',
                      sublabel: stemReady ? 'Mixer siap' : 'Proses AI dulu',
                      color: const Color(0xFFFF2E93),
                      onTap: () {
                        if (stemReady) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StemMixerScreen()));
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StemSetupScreen()));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Chord View
                  Expanded(
                    child: _actionCard(
                      icon: Icons.piano_rounded,
                      label: 'Lihat Chord',
                      sublabel: hasChords
                          ? '${project.chordSegments.length} chord'
                          : 'Belum ada',
                      color: const Color(0xFF00C6FF),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChordViewerScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Record over backing
                  Expanded(
                    child: _actionCard(
                      icon: Icons.mic_rounded,
                      label: 'Rekam',
                      sublabel: 'Atas backing track',
                      color: const Color(0xFFFF8C37),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RecordSetupScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Processing Status ───────────────────────────────────────
              _sectionLabel('STATUS AI PROCESSING'),
              const SizedBox(height: 10),
              _statusRow('Stem Separation', project.stemStatus),
              const SizedBox(height: 6),
              _statusRow('Chord Analysis', project.chordStatus),
              const SizedBox(height: 6),
              _statusRow('Beat & Tempo', project.beatStatus),
              const SizedBox(height: 20),

              // ── Run AI Button (if not ready) ────────────────────────────
              if (project.stemStatus != AnalysisStatus.ready)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: project.stemStatus == AnalysisStatus.processing
                        ? null
                        : () {
                            // Go to setup screen to pick stems first
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StemSetupScreen()),
                            );
                          },
                    icon: project.stemStatus == AnalysisStatus.processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(
                      project.stemStatus == AnalysisStatus.processing
                          ? 'AI Sedang Memproses...'
                          : 'Pisahkan Stem & Analisis',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Saved Takes ─────────────────────────────────────────────
              _sectionLabel('REKAMAN TERSIMPAN'),
              const SizedBox(height: 10),
              if (project.recordings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131022),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: const Center(
                    child: Text('Belum ada rekaman.',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                )
              else
                ...project.recordings.map((take) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _takeTile(context, take, controller),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildNextChordBadge(AudioProject project) {
    // Find next chord after current position
    final nextMs = _position.inMilliseconds;
    final next = project.chordSegments
        .where((c) => c.startTimeMs > nextMs)
        .fold<ChordSegment?>(null, (prev, c) {
      if (prev == null) return c;
      return c.startTimeMs < prev.startTimeMs ? c : prev;
    });

    if (next == null) return const SizedBox.shrink();
    return Column(
      children: [
        const Text('BERIKUT',
            style: TextStyle(color: Colors.white24, fontSize: 9)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            next.chordName,
            style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _statPill(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF131022),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white38, size: 14),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style:
                    const TextStyle(color: Colors.white24, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 2),
            Text(sublabel,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1),
      );

  Widget _statusRow(String label, AnalysisStatus status) {
    final (text, color, icon) = switch (status) {
      AnalysisStatus.ready => ('Siap', const Color(0xFF00FF66), Icons.check_circle_outline_rounded),
      AnalysisStatus.processing => ('Memproses...', const Color(0xFFFF8C37), Icons.autorenew_rounded),
      AnalysisStatus.waitingModel => ('Menunggu Model', Colors.amber, Icons.hourglass_empty_rounded),
      AnalysisStatus.error => ('Error', Colors.redAccent, Icons.error_outline_rounded),
      AnalysisStatus.unavailable => ('Belum Diproses', Colors.white24, Icons.info_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131022),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          Row(children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(text,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _takeTile(BuildContext context, RecordingTake take, ProjectController controller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131022),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              take.type == RecordingType.video
                  ? Icons.videocam_rounded
                  : Icons.mic_rounded,
              color: const Color(0xFFFF2E93),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(take.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'Mode: ${take.mode.name} • ${take.type.name}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded,
                color: Colors.white70, size: 24),
            onPressed: () async {
              try {
                await controller.playerService.loadFile(take.filePath);
                await controller.playerService.play();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memutar: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ProjectController controller, AudioProject project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131022),
        title: const Text('Hapus Proyek',
            style: TextStyle(color: Colors.white)),
        content: Text('Hapus "${project.title}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await controller.deleteProject(project.id);
            },
            child: const Text('Hapus',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
