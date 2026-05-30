import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../widgets/input_level_meter.dart';
import '../../widgets/waveform_placeholder.dart';
import '../../state/project_controller.dart';
import '../../models/audio_project.dart';
import '../project_detail/project_detail_screen.dart';

class LiveRecordingScreen extends StatefulWidget {
  final bool recordWithCamera;
  final bool isGuitarOnly;

  const LiveRecordingScreen({
    super.key,
    required this.recordWithCamera,
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

  @override
  void initState() {
    super.initState();
    _startRecordingSession();
    _startTimer();
    if (widget.recordWithCamera) {
      _initCamera();
    }
  }

  Future<void> _startRecordingSession() async {
    final controller = Provider.of<ProjectController>(context, listen: false);
    final bool started = await controller.startRecording();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memulai perekaman audio.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _initCamera() async {
    final controller = Provider.of<ProjectController>(context, listen: false);
    final bool success = await controller.cameraService.initializeCamera();
    if (mounted) {
      setState(() {
        _cameraInitialized = success;
      });
    }
    if (success) {
      await controller.cameraService.startVideoRecording();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSecs) {
    final hrs = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final mins = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$hrs:$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectController>(context);
    final activeProject = controller.activeProject;

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
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Sedang Merekam',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Timer Display
            Text(
              _formatTimer(_seconds),
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Video Preview area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF131022),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
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
                        Container(
                          color: const Color(0xFF131022),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.recordWithCamera
                                      ? Icons.videocam_off_rounded
                                      : Icons.mic_rounded,
                                  color: Colors.white24,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.recordWithCamera
                                      ? 'Camera preview hanya tersedia di device.'
                                      : 'Perekaman Audio Saja',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Positioned(
                        top: 16,
                        left: 16,
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.redAccent,
                              size: 12,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'REC • LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Inputs status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131022),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cable_rounded,
                        color: Color(0xFFFF8C37),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isGuitarOnly
                            ? 'Input: Gitar / Mic'
                            : 'Input: Guitar + Playback Mix',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '-12 dB',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const InputLevelMeter(level: 0.65, dbValue: '-12 dB'),
                  const SizedBox(height: 16),
                  const WaveformPlaceholder(height: 50, isPlaying: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mode Aktif:',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                Text(
                  widget.isGuitarOnly ? 'Gitar Saja' : 'Rekam Semua',
                  style: const TextStyle(
                    color: Color(0xFFFF2E93),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pause button
                _buildRoundButton(
                  icon: _isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  label: _isPaused ? 'Mulai' : 'Jeda',
                  onTap: () async {
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                    // Pause/resume recorder service
                    if (_isPaused) {
                      await controller.recorderService.pause();
                    } else {
                      await controller.recorderService.resume();
                    }
                  },
                ),
                // Stop/Finish recording button
                GestureDetector(
                  onTap: () async {
                    _timer?.cancel();

                    String? videoPath;
                    if (widget.recordWithCamera && _cameraInitialized) {
                      videoPath = await controller.cameraService
                          .stopVideoRecording();
                    }

                    await controller.stopRecording(
                      widget.recordWithCamera
                          ? RecordingType.video
                          : RecordingType.audio,
                      widget.isGuitarOnly
                          ? RecordingMode.guitarOnly
                          : RecordingMode.recordAll,
                    );

                    // If a video path exists, add it as a separate take or update
                    if (videoPath != null && mounted) {
                      await controller.addRecordingTake(
                        videoPath,
                        RecordingType.video,
                        widget.isGuitarOnly
                            ? RecordingMode.guitarOnly
                            : RecordingMode.recordAll,
                      );
                    }

                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailScreen(
                          title: activeProject?.title ?? 'Proyek Sesi Rekam',
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33FF0000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Berhenti',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Cancel/Reset button
                _buildRoundButton(
                  icon: Icons.cancel_outlined,
                  label: 'Batal',
                  onTap: () async {
                    _timer?.cancel();
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

  Widget _buildRoundButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
