class BeatMarker {
  final double time;
  final int index;

  BeatMarker({required this.time, required this.index});

  factory BeatMarker.fromJson(Map<String, dynamic> json) {
    return BeatMarker(
      time: (json['time'] as num).toDouble(),
      index: json['index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'time': time, 'index': index};
  }
}
