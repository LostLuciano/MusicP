import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/waveform_placeholder.dart';
import '../../state/project_controller.dart';
import '../../models/audio_project.dart';
import '../stem_mixer/stem_mixer_screen.dart';
import '../record_setup/record_setup_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String title;

  const ProjectDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectController>(context);
    final project = controller.activeProject;

    if (project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0C1B),
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Proyek tidak ditemukan.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final keyText = project.keySignature ?? 'Belum dianalisis';
    final bpmText = project.bpm != null
        ? '${project.bpm!.toInt()} BPM'
        : 'Belum dianalisis';
    final timeSigText = project.timeSignature ?? 'Belum dianalisis';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        title: Text(project.title),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
            onPressed: () => _confirmDelete(context, controller, project),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key/Tempo/Sig Info Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatColumn('Key', keyText),
                  _buildStatColumn('Tempo', bpmText),
                  _buildStatColumn('Time Signature', timeSigText),
                ],
              ),
              const SizedBox(height: 28),

              // Waveform summary
              const WaveformPlaceholder(
                height: 70,
                progress: 0.0,
                isPlaying: false,
              ),
              const SizedBox(height: 32),

              // Chord detection status
              const Text(
                'STATUS PROCESSING MODEL',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusCard('Stems Isolation', project.stemStatus),
              const SizedBox(height: 8),
              _buildStatusCard('Chord Analysis', project.chordStatus),
              const SizedBox(height: 8),
              _buildStatusCard('Beat & Tempo Grid', project.beatStatus),
              const SizedBox(height: 32),

              // Saved Takes section
              const Text(
                'REKAMAN TERSIMPAN',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              if (project.recordings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131022),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada hasil rekaman.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                )
              else
                Column(
                  children: project.recordings.map((take) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildTakeListTile(
                        context,
                        title: take.title,
                        subtitle:
                            'Mode: ${take.mode.toString().split('.').last} • Tipe: ${take.type.toString().split('.').last}',
                        filePath: take.filePath,
                        controller: controller,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 40),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2E93),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StemMixerScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Buka Mixer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF2E93)),
                        foregroundColor: const Color(0xFFFF2E93),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecordSetupScreen(),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_none_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Rekam Gitar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String label, AnalysisStatus status) {
    String statusText = 'Tidak Tersedia';
    Color color = Colors.redAccent;
    IconData icon = Icons.cancel_outlined;

    switch (status) {
      case AnalysisStatus.unavailable:
        statusText = 'Belum diproses / model belum tersedia';
        color = Colors.white38;
        icon = Icons.info_outline_rounded;
        break;
      case AnalysisStatus.waitingModel:
        statusText = 'Menunggu model CoreML';
        color = Colors.amber;
        icon = Icons.hourglass_empty_rounded;
        break;
      case AnalysisStatus.processing:
        statusText = 'Memproses...';
        color = const Color(0xFFFF8C37);
        icon = Icons.autorenew_rounded;
        break;
      case AnalysisStatus.ready:
        statusText = 'Siap / Ready';
        color = const Color(0xFF00FF66);
        icon = Icons.check_circle_outline_rounded;
        break;
      case AnalysisStatus.error:
        statusText = 'Error';
        color = Colors.redAccent;
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131022),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTakeListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String filePath,
    required ProjectController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131022),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Color(0xFFFF2E93),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white70,
              size: 24,
            ),
            onPressed: () async {
              try {
                await controller.playerService.loadFile(filePath);
                await controller.playerService.play();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Memutar: $title')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('File rekaman tidak ditemukan: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProjectController controller,
    AudioProject project,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131022),
        title: const Text(
          'Hapus Proyek',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${project.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () async {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop detail screen
              await controller.deleteProject(project.id);
            },
          ),
        ],
      ),
    );
  }
}
