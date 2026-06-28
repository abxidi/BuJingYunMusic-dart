String formatDurationMs(int milliseconds) {
  final totalSeconds = milliseconds ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String formatSizeBytes(int bytes) {
  if (bytes <= 0) {
    return '未知大小';
  }
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
