import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/recording_mode_card.dart';
import '../../widgets/input_level_meter.dart';
import '../../widgets/waveform_placeholder.dart';
import '../../state/project_controller.dart';
import '../../models/audio_project.dart';
import '../live_recording/live_recording_screen.dart';

class RecordSetupScreen extends StatefulWidget {
  const RecordSetupScreen({super.key});

  @override
  State<RecordSetupScreen> createState() => _RecordSetupScreenState();
}

class _RecordSetupScreenState extends State<RecordSetupScreen> {
  int _selectedMode = 0; // 0: Guitar Only, 1: Record All
  bool _recordWithCamera = false;
  int _monitoringMode = 1; // 0: Off, 1: Input, 2: Mix
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akses mikrofon ditolak. Silakan aktifkan di Pengaturan.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectController>(context);
    final activeProject = controller.activeProject;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        title: const Text('Record Setup'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131022),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hasPermission
                        ? const Color(0xFF00FF66).withValues(alpha: 0.2)
                        : Colors.redAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _hasPermission
                            ? const Color(0xFF0C2417)
                            : const Color(0xFF2C1013),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        color: _hasPermission
                            ? const Color(0xFF00FF66)
                            : Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasPermission
                                ? 'Mikrofon Siap'
                                : 'Akses Mikrofon Dibutuhkan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _hasPermission
                                ? 'Input: Default device mic / interface'
                                : 'Tap untuk mengizinkan akses perekaman',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_hasPermission)
                      TextButton(
                        onPressed: _requestPermission,
                        child: const Text(
                          'IZINKAN',
                          style: TextStyle(
                            color: Color(0xFFFF2E93),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF00FF66),
                        size: 20,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Project Link Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1934),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TARGET PROYEK REKAMAN',
                      style: TextStyle(
                        color: Color(0xFFFF8C37),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeProject != null
                          ? activeProject.title
                          : 'Draft Sesi Rekam (Baru)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeProject != null
                          ? 'Hasil rekaman akan ditambahkan ke proyek ini'
                          : 'Proyek baru akan dibuat secara otomatis',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'MODE REKAMAN',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  RecordingModeCard(
                    title: 'Rekam Gitar Saja',
                    subtitle: 'Hanya rekam input gitar asli / mikrofon.',
                    icon: Icons.music_note_rounded,
                    isSelected: _selectedMode == 0,
                    onTap: () => setState(() => _selectedMode = 0),
                  ),
                  const SizedBox(width: 16),
                  RecordingModeCard(
                    title: 'Rekam Semua',
                    subtitle: 'Rekam gitar + backing track (Coming soon).',
                    icon: Icons.library_music_rounded,
                    isSelected: _selectedMode == 1,
                    onTap: () {
                      setState(() => _selectedMode = 1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Record All butuh mixing native iOS. Hanya Guitar Only yang saat ini aktif.',
                          ),
                        ),
                      );
                      setState(() => _selectedMode = 0);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Camera Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF131022),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Rekam dengan Kamera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _recordWithCamera,
                      activeTrackColor: const Color(0xFFFF2E93),
                      activeThumbColor: Colors.white,
                      onChanged: (val) async {
                        if (val) {
                          final status = await Permission.camera.request();
                          if (!context.mounted) return;
                          if (!status.isGranted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Akses kamera ditolak. Perekaman video dinonaktifkan.',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        setState(() => _recordWithCamera = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Live meters
              const Text(
                'INPUT MONITOR',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              const InputLevelMeter(level: 0.45, dbValue: '-24 dB'),
              const SizedBox(height: 20),
              const WaveformPlaceholder(height: 60, isPlaying: false),
              const SizedBox(height: 32),

              // Monitoring Selector
              const Text(
                'MONITORING',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMonitorButton(0, 'Off', Icons.volume_mute_rounded),
                  _buildMonitorButton(1, 'Input', Icons.headphones_rounded),
                  _buildMonitorButton(2, 'Mix', Icons.dynamic_feed_rounded),
                ],
              ),
              const SizedBox(height: 48),

              // Big Pink Record Button
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (!_hasPermission) {
                          await _requestPermission();
                          if (!_hasPermission) return;
                        }
                        if (!context.mounted) return;

                        // Create project draft if null
                        if (controller.activeProject == null) {
                          final now = DateTime.now();
                          final newProj = AudioProject(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: 'Proyek Baru ${DateTime.now().hour}:${DateTime.now().minute}',
                            createdAt: now,
                            updatedAt: now,
                            status: ProjectStatus.draft,
                            stemStatus: AnalysisStatus.unavailable,
                            chordStatus: AnalysisStatus.unavailable,
                            beatStatus: AnalysisStatus.unavailable,
                            recordings: const [],
                          );
                          controller.openProject(newProj);
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LiveRecordingScreen(
                              recordWithCamera: _recordWithCamera,
                              isGuitarOnly: _selectedMode == 0,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF2E93),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x66FF2E93),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tekan tombol rekam untuk mulai',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonitorButton(int index, String label, IconData icon) {
    final isSelected = _monitoringMode == index;
    final activeColor = const Color(0xFFFF2E93);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _monitoringMode = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : const Color(0xFF131022),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
