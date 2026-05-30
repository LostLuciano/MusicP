class StemChannel {
  final String name;
  final String? filePath;
  double volume;
  bool isMuted;
  bool isSoloed;

  StemChannel({
    required this.name,
    this.filePath,
    this.volume = 1.0,
    this.isMuted = false,
    this.isSoloed = false,
  });

  StemChannel copyWith({
    String? name,
    String? filePath,
    double? volume,
    bool? isMuted,
    bool? isSoloed,
  }) {
    return StemChannel(
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSoloed: isSoloed ?? this.isSoloed,
    );
  }
}
