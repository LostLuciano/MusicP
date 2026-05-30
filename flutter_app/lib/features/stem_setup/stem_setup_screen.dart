import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_controller.dart';
import '../stem_mixer/stem_mixer_screen.dart';

/// Screen shown after importing audio. Lets user pick which stems/instruments
/// they want to control, then kicks off AI separation only for those tracks.
class StemSetupScreen extends StatefulWidget {
  const StemSetupScreen({super.key});

  @override
  State<StemSetupScreen> createState() => _StemSetupScreenState();
}

class _StemSetupScreenState extends State<StemSetupScreen>
    with SingleTickerProviderStateMixin {
  // Which stems the user wants to isolate/control
  final Map<String, bool> _selectedStems = {
    'vocals': true,
    'drums': true,
    'bass': true,
    'guitar': false,
    'piano': false,
    'other': false,
  };

  bool _isProcessing = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _stemInfo = {
    'vocals': (
      label: 'Vokal',
      icon: Icons.record_voice_over_rounded,
      desc: 'Pisahkan vokal / nyanyi dari lagu',
      color: Color(0xFFFF2E93),
    ),
    'drums': (
      label: 'Drum',
      icon: Icons.album_rounded,
      desc: 'Isolasi kick, snare, hi-hat, cymbal',
      color: Color(0xFFFF8C37),
    ),
    'bass': (
      label: 'Bass',
      icon: Icons.graphic_eq_rounded,
      desc: 'Isolasi bass gitar / synth bass',
      color: Color(0xFF00C6FF),
    ),
    'guitar': (
      label: 'Gitar',
      icon: Icons.music_note_rounded,
      desc: 'Pisahkan gitar elektrik / akustik',
      color: Color(0xFF00FF66),
    ),
    'piano': (
      label: 'Piano / Keys',
      icon: Icons.piano_rounded,
      desc: 'Isolasi piano, keyboard, synth',
      color: Color(0xFFBB86FC),
    ),
    'other': (
      label: 'Lainnya',
      icon: Icons.queue_music_rounded,
      desc: 'Semua instrumen yang tidak terklasifikasi',
      color: Color(0xFFFFD700),
    ),
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _selectedCount =>
      _selectedStems.values.where((v) => v).length;

  Future<void> _startProcessing() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 instrumen untuk dipisahkan.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final controller = Provider.of<ProjectController>(context, listen: false);

    // Trigger AI separation on the native side
    await controller.runProjectAnalysis();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Navigate to mixer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StemMixerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectController>(context);
    final project = controller.activeProject;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Pilih Instrumen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Header: Song Info ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1934), Color(0xFF131022)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFF2E93).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2E93).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.audio_file_rounded,
                        color: Color(0xFFFF2E93), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project?.title ?? 'File Audio',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'AI akan memisahkan instrumen yang dipilih',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Instruction ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'INSTRUMEN YANG INGIN DIKONTROL',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Stem Cards Grid ──────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: _stemInfo.entries.map((entry) {
                  final key = entry.key;
                  final info = entry.value;
                  final isSelected = _selectedStems[key] ?? false;

                  return GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () => setState(() => _selectedStems[key] = !isSelected),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? info.color.withValues(alpha: 0.12)
                            : const Color(0xFF131022),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? info.color.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.07),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(info.icon,
                                  color: isSelected ? info.color : Colors.white38,
                                  size: 22),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? info.color : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? info.color : Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            info.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            info.desc,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white54
                                  : Colors.white24,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Bottom CTA ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            child: Column(
              children: [
                // Selected count indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_selectedCount instrumen dipilih',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.white24)),
                    const Text(
                      'Lebih banyak = proses lebih lama',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _startProcessing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2E93),
                      disabledBackgroundColor: const Color(0xFF4A1530),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FadeTransition(
                                opacity: _pulseAnim,
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'AI Memisahkan Stem...',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Pisahkan & Buka Mixer',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const StemMixerScreen()),
                          ),
                  child: const Text(
                    'Lewati → Langsung ke Mixer',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
