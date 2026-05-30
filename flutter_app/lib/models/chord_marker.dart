class ChordMarker {
  final String name;
  final double startTime;
  final double endTime;
  final int rootNote;
  final int chordType;

  ChordMarker({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.rootNote,
    required this.chordType,
  });

  factory ChordMarker.fromJson(Map<String, dynamic> json) {
    return ChordMarker(
      name: json['name'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      rootNote: json['rootNote'] as int,
      chordType: json['chordType'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'rootNote': rootNote,
      'chordType': chordType,
    };
  }
}
