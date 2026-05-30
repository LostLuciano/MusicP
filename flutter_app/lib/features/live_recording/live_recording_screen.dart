import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../widgets/input_level_meter.dart';
import '../../widgets/waveform_placeholder.dart';
import '../../state/project_controller.dart';
import '../../models/audio_project.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/native_ios_audio_service.dart';
import '../project_detail/project_detail_screen.dart';

class LiveRecordingScreen extends StatefulWidget {
  final bool recordWithCamera;
  final bool useFrontCamera;
  final bool isGuitarOnly;

  const LiveRecordingScreen({
    super.key,
    required this.recordWithCamera,
    this.useFrontCamera = false,
    required this.isGuitarOnly,
  });

  @override
  State<LiveRecordingScreen> createState() => _LiveRecordingScreenState();
}

class _LiveRecordingScreenState extends State<LiveRecordingScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _isPaused = false;
  bool _cameraInitialized = false;

  // Live VU meter state
  double _inputLevel = 0.0;
  String _dbString = '-∞ dB';
  StreamSubscription<double>? _levelSub;

  @override
  void initState() {
    super.initState();
    _startRecordingSession();
    _startTimer();
    if (widget.recordWithCamera) _initCamera();
  }

  Future<void> _startRecordingSession() async {
    final controller = Provider.of<ProjectController>(context, listen: false);
    final bool started = await controller.startRecording();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memulai perekaman audio.')),
      );
      Navigator.pop(context);
      return;
    }

    // Subscribe to live amplitude from recorder
    _levelSub = controller.recorderService.levelStream.listen((lvl) {
      if (mounted) {
        setState(() {
          _inputLevel = lvl;
          _dbString = AudioRecorderService.levelToDB(lvl);
        });
      }
    });
  }

  Future<void> _initCamera() async {
    final controller = Provider.of<ProjectController>(context, listen: false);
    final bool success = await controller.cameraService
        .initializeCamera(preferFront: widget.useFrontCamera);
    if (mounted) setState(() => _cameraInitialized = success);
    if (success) await controller.cameraService.startVideoRecording();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _levelSub?.cancel();
    super.dispose();
  }

  String _formatTimer(int s) {
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  // ── Export Dialog ──────────────────────────────────────────────────────────
  Future<void> _showExportDialog({
    required String? videoPath,
    required String? audioPath,
    required ProjectController controller,
  }) async {
    if (!mounted) return;

    // Audio-only mode: skip the dialog, just go back
    if (videoPath == null) {
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
              title: controller.activeProject?.title ?? 'Sesi Rekam'),
        ),
      );
      return;
    }

    // Both audio + video available: show export choice
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131022),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Simpan Hasil Rekaman',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Pilih format output yang ingin disimpan.',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 24),
            _exportOption(
              icon: Icons.audio_file_rounded,
              color: const Color(0xFFFF2E93),
              title: 'Audio Saja (.m4a)',
              subtitle: 'Hanya file suara rekaman tanpa video',
              onTap: () async {
                Navigator.pop(ctx);
                // Share audio only via native share sheet
                if (audioPath != null && audioPath.isNotEmpty) {
                  await NativeIosAudioService().shareFile(audioPath);
                }
                if (!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(
                      title: controller.activeProject?.title ?? 'Sesi Rekam'),
                ));
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.video_file_rounded,
              color: const Color(0xFFFF8C37),
              title: 'Video Lengkap (.mp4)',
              subtitle: 'Video + audio rekaman digabungkan',
              onTap: () async {
                Navigator.pop(ctx);
                if (videoPath != null && videoPath.isNotEmpty) {
                  await NativeIosAudioService().shareFile(videoPath);
                }
                if (!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(
                      title: controller.activeProject?.title ?? 'Sesi Rekam'),
                ));
              },
            ),
            const SizedBox(height: 12),
            _exportOption(
              icon: Icons.folder_copy_rounded,
              color: Colors.white38,
              title: 'Keduanya',
              subtitle: 'Simpan audio + video ke Files.app',
              onTap: () async {
                Navigator.pop(ctx);
                if (audioPath != null && audioPath.isNotEmpty) {
                  await NativeIosAudioService().shareFile(audioPath);
                }
                if (videoPath != null && videoPath.isNotEmpty && context.mounted) {
                  await NativeIosAudioService().shareFile(videoPath);
                }
                if (!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(
                      title: controller.activeProject?.title ?? 'Sesi Rekam'),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text('Sedang Merekam',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // Camera flip button (only shown when camera is active)
          if (widget.recordWithCamera && _cameraInitialized)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70),
              tooltip: 'Ganti Kamera',
              onPressed: () async {
                await controller.cameraService.switchCamera();
                if (mounted) setState(() {});
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ── Timer ─────────────────────────────────────────────────────
            Text(
              _formatTimer(_seconds),
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            // ── Camera Preview ─────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF131022),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.recordWithCamera &&
                          _cameraInitialized &&
                          controller.cameraService.controller != null)
                        CameraPreview(controller.cameraService.controller!)
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.recordWithCamera
                                    ? Icons.videocam_off_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white24,
                                size: 56,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.recordWithCamera
                                    ? 'Kamera hanya tersedia di device fisik.'
                                    : 'Mode Perekaman Audio',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      // REC badge
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 6),
                              Text('REC',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Live VU Meter ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131022),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  InputLevelMeter(level: _inputLevel, dbValue: _dbString),
                  const SizedBox(height: 12),
                  WaveformPlaceholder(height: 44, isPlaying: !_isPaused),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Mode Label ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mode Aktif:',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                Text(
                  widget.isGuitarOnly ? 'Audio Saja' : 'Rekam Semua',
                  style: const TextStyle(
                      color: Color(0xFFFF2E93),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Control Buttons ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pause/Resume
                _roundBtn(
                  icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: _isPaused ? 'Lanjut' : 'Jeda',
                  onTap: () async {
                    setState(() => _isPaused = !_isPaused);
                    if (_isPaused) {
                      await controller.recorderService.pause();
                    } else {
                      await controller.recorderService.resume();
                    }
                  },
                ),

                // STOP button
                GestureDetector(
                  onTap: () async {
                    _timer?.cancel();
                    _levelSub?.cancel();

                    String? videoPath;
                    if (widget.recordWithCamera && _cameraInitialized) {
                      videoPath =
                          await controller.cameraService.stopVideoRecording();
                    }

                    final audioPath = await controller.stopRecording(
                      widget.recordWithCamera
                          ? RecordingType.video
                          : RecordingType.audio,
                      widget.isGuitarOnly
                          ? RecordingMode.guitarOnly
                          : RecordingMode.recordAll,
                    );

                    if (videoPath != null && mounted) {
                      await controller.addRecordingTake(
                        videoPath,
                        RecordingType.video,
                        widget.isGuitarOnly
                            ? RecordingMode.guitarOnly
                            : RecordingMode.recordAll,
                      );
                    }

                    if (!mounted) return;
                    await _showExportDialog(
                      videoPath: videoPath,
                      audioPath: audioPath,
                      controller: controller,
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x33FF0000),
                                blurRadius: 12,
                                offset: Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.stop_rounded,
                            color: Colors.white, size: 34),
                      ),
                      const SizedBox(height: 8),
                      const Text('Berhenti',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // Cancel
                _roundBtn(
                  icon: Icons.cancel_outlined,
                  label: 'Batal',
                  onTap: () async {
                    _timer?.cancel();
                    _levelSub?.cancel();
                    await controller.recorderService.stopGuitarRecording();
                    if (widget.recordWithCamera && _cameraInitialized) {
                      await controller.cameraService.stopVideoRecording();
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
