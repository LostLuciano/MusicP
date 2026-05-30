import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../widgets/project_list_tile.dart';
import '../../widgets/mini_player_bar.dart';
import '../../state/project_controller.dart';
import '../../services/audio_import_service.dart';
import '../project_detail/project_detail_screen.dart';

class ProjectLibraryScreen extends StatefulWidget {
  const ProjectLibraryScreen({super.key});

  @override
  State<ProjectLibraryScreen> createState() => _ProjectLibraryScreenState();
}

class _ProjectLibraryScreenState extends State<ProjectLibraryScreen> {
  int _selectedTab = 0; // 0: All, 1: Songs, 2: Sessions, 3: Imports
  bool _isPlaying = false;
  String _currentPlayingTitle = '';
  String _currentPlayingDetail = '';

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

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectController>(context);
    final projects = controller.projects;

    // Filter projects based on tabs
    final filteredProjects = projects.where((proj) {
      if (_selectedTab == 0) {
        return true;
      }
      if (_selectedTab == 1 && proj.status.toString().contains('ready')) {
        return true;
      }
      if (_selectedTab == 2 && proj.status.toString().contains('draft')) {
        return true;
      }
      if (_selectedTab == 3 && proj.status.toString().contains('imported')) {
        return true;
      }
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        title: const Text('My Library'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: Colors.white70),
            onPressed: () => _handleImportAudio(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 12,
              bottom: 90,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal category bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTabButton(0, 'All'),
                    _buildTabButton(1, 'Songs'),
                    _buildTabButton(2, 'Sessions'),
                    _buildTabButton(3, 'Imports'),
                  ],
                ),
                const SizedBox(height: 24),

                // Projects List or Empty State
                if (projects.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.library_music_outlined,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada project.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Import audio atau mulai rekam.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF2E93),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _handleImportAudio(context),
                            icon: const Icon(
                              Icons.upload_file_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Import Audio',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filteredProjects.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Tidak ada proyek di kategori ini.',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final proj = filteredProjects[index];
                        final isAct = controller.activeProject?.id == proj.id;
                        final bpmText = proj.bpm != null
                            ? '${proj.bpm!.toInt()} BPM'
                            : 'Belum dianalisis';
                        final keyText = proj.keySignature ?? 'Kunci: -';

                        return ProjectListTile(
                          title: proj.title,
                          keyName: keyText,
                          bpm: proj.bpm?.toInt() ?? 0,
                          duration: 'Audio',
                          date:
                              '${proj.createdAt.day}/${proj.createdAt.month}/${proj.createdAt.year}',
                          onTap: () {
                            controller.openProject(proj);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProjectDetailScreen(title: proj.title),
                              ),
                            );
                          },
                          onPlayTap: () async {
                            controller.openProject(proj);
                            try {
                              if (_isPlaying && isAct) {
                                await controller.playerService.pause();
                                setState(() {
                                  _isPlaying = false;
                                });
                              } else {
                                await controller.playerService.loadProjectAudio(
                                  proj,
                                );
                                await controller.playerService.play();
                                setState(() {
                                  _isPlaying = true;
                                  _currentPlayingTitle = proj.title;
                                  _currentPlayingDetail = '$keyText • $bpmText';
                                });
                                // Keep track of complete playback end
                                controller
                                    .playerService
                                    .player
                                    .processingStateStream
                                    .listen((state) {
                                      if (state == ProcessingState.completed) {
                                        if (mounted) {
                                          setState(() {
                                            _isPlaying = false;
                                          });
                                        }
                                      }
                                    });
                              }
                            } catch (_) {}
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Sticky mini player bar if a song is loaded
          if (_currentPlayingTitle.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayerBar(
                title: _currentPlayingTitle,
                subtitle: _currentPlayingDetail,
                isPlaying: _isPlaying,
                onPlayPause: () async {
                  try {
                    if (_isPlaying) {
                      await controller.playerService.pause();
                    } else {
                      await controller.playerService.play();
                    }
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  } catch (_) {}
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    final activeColor = const Color(0xFFFF2E93);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : const Color(0xFF131022),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
