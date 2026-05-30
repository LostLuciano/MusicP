import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/feature_card.dart';
import '../../state/project_controller.dart';
import '../../services/audio_import_service.dart';
import '../../models/audio_project.dart';
import '../stem_mixer/stem_mixer_screen.dart';
import '../chord_viewer/chord_viewer_screen.dart';
import '../beat_tempo/beat_tempo_screen.dart';
import '../project_library/project_library_screen.dart';
import '../record_setup/record_setup_screen.dart';
import '../project_detail/project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Future<void> _handleImportAudio(BuildContext context) async {
    final controller = Provider.of<ProjectController>(context, listen: false);
    final File? file = await AudioImportService().pickAudioFile();
    if (!context.mounted) return;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batal memilih file.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF2E93)),
      ),
    );

    try {
      await controller.importAudioAsProject(file);
      if (!context.mounted) return;
      Navigator.pop(context); // close loader

      if (controller.activeProject != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(
              title: controller.activeProject!.title,
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengimpor file: $e')),
      );
    }
  }

  void _handleQuickNewProject(BuildContext context) async {
    final controller = Provider.of<ProjectController>(context, listen: false);
    // Create an empty dummy project with no audio to record into
    final now = DateTime.now();
    final newProj = AudioProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Proyek Sesi Rekam',
      createdAt: now,
      updatedAt: now,
      status: ProjectStatus.draft,
      stemStatus: AnalysisStatus.unavailable,
      chordStatus: AnalysisStatus.unavailable,
      beatStatus: AnalysisStatus.unavailable,
      recordings: const [],
    );
    await controller.updateProjectStatus(ProjectStatus.draft);
    controller.openProject(newProj);

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecordSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      body: IndexedStack(
        index: _currentIndex == 2
            ? 0
            : (_currentIndex == 1
                  ? 1
                  : (_currentIndex == 3 ? 2 : (_currentIndex == 4 ? 3 : 0))),
        children: [
          _buildDashboardView(),
          const ProjectLibraryScreen(),
          const RecordSetupScreen(),
          _buildProfileView(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _showQuickActionsBottomSheet(context);
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildDashboardView() {
    final controller = Provider.of<ProjectController>(context);
    final activeProject = controller.activeProject;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Halo, Musikus! 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Siap berkreasi hari ini?',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131022),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Project Status Banner
            if (activeProject == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131022),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Belum ada project aktif.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Import audio atau mulai rekam.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2E93),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handleImportAudio(context),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text(
                        'Import Audio',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProjectDetailScreen(title: activeProject.title),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1934),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF2E93).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF2E93,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_video_rounded,
                          color: Color(0xFFFF2E93),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PROJECT AKTIF',
                              style: TextStyle(
                                color: Color(0xFFFF8C37),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeProject.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Take Rekaman: ${activeProject.recordings.length}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white24,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  FeatureCard(
                    title: 'Stem Mixer',
                    description: 'Pisahkan & mix stems',
                    icon: Icons.tune_rounded,
                    color: const Color(0xFFFF2E93),
                    onTap: () {
                      if (activeProject == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Silakan pilih atau impor project terlebih dahulu.',
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StemMixerScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  FeatureCard(
                    title: 'Chord Viewer',
                    description: 'Analisis harmoni akor',
                    icon: Icons.music_note_rounded,
                    color: const Color(0xFFFF8C37),
                    onTap: () {
                      if (activeProject == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Silakan pilih atau impor project terlebih dahulu.',
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChordViewerScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  FeatureCard(
                    title: 'Beat & Tempo',
                    description: 'Tempo & metronome',
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF9D4EDD),
                    onTap: () {
                      if (activeProject == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Silakan pilih atau impor project terlebih dahulu.',
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BeatTempoScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  FeatureCard(
                    title: 'Record Guitar',
                    description: 'Via audio interface',
                    icon: Icons.cable_rounded,
                    color: const Color(0xFF00FF66),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordSetupScreen(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Record with Camera',
                    description: 'Rekam gitar + video',
                    icon: Icons.videocam_rounded,
                    color: const Color(0xFFFF3B30),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordSetupScreen(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Project Library',
                    description: 'Lihat semua proyek',
                    icon: Icons.folder_open_rounded,
                    color: const Color(0xFF00C7FF),
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    final controller = Provider.of<ProjectController>(context);
    final count = controller.projects.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF2E93), width: 3),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2E93), Color(0xFFFF8C37)],
                  ),
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rian Musisi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Premium Member • Produser Level 5',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 36),
            _buildProfileTile(
              Icons.music_video_rounded,
              'Analisis Proyek',
              '$count trek terindeks',
            ),
            _buildProfileTile(
              Icons.mic_none_rounded,
              'Rekaman Tersimpan',
              '${controller.projects.expand((p) => p.recordings).length} hasil rekaman',
            ),
            _buildProfileTile(
              Icons.settings_outlined,
              'Pengaturan Studio',
              'Hardware, buffer rate',
            ),
            _buildProfileTile(
              Icons.info_outline_rounded,
              'Tentang Aplikasi',
              'V1.0.0 Stable',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131022),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF2E93)),
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white24,
            size: 14,
          ),
        ],
      ),
    );
  }

  void _showQuickActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131022),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tindakan Cepat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.upload_file_rounded,
                  color: Color(0xFFFF2E93),
                ),
                title: const Text(
                  'Impor File Audio',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleImportAudio(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.cable_rounded,
                  color: Color(0xFFFF8C37),
                ),
                title: const Text(
                  'Rekam Gitar Baru',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleQuickNewProject(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
