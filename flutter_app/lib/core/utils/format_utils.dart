class FormatUtils {
  static String formatDuration(double seconds) {
    final int minutes = (seconds / 60).floor();
    final int remainingSeconds = (seconds % 60).floor();
    final String secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutes:$secondsStr';
  }
}
