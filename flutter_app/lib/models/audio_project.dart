enum ProjectStatus {
  draft,
  imported,
  ready,
  recording,
  error,
}

enum AnalysisStatus {
  unavailable,
  waitingModel,
  processing,
  ready,
  error,
}

enum RecordingType {
  audio,
  video,
}

enum RecordingMode {
  guitarOnly,
  recordAll,
}

class StemFiles {
  final String? vocals;
  final String? bass;
  final String? drums;
  final String? piano;
  final String? guitar;
  final String? other;

  const StemFiles({
    this.vocals,
    this.bass,
    this.drums,
    this.piano,
    this.guitar,
    this.other,
  });

  factory StemFiles.fromJson(Map<String, dynamic> json) {
    return StemFiles(
      vocals: json['vocals'] as String?,
      bass: json['bass'] as String?,
      drums: json['drums'] as String?,
      piano: json['piano'] as String?,
      guitar: json['guitar'] as String?,
      other: json['other'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vocals': vocals,
      'bass': bass,
      'drums': drums,
      'piano': piano,
      'guitar': guitar,
      'other': other,
    };
  }

  bool get isEmpty =>
      vocals == null &&
      bass == null &&
      drums == null &&
      piano == null &&
      guitar == null &&
      other == null;

  bool get isNotEmpty => !isEmpty;
}

class RecordingTake {
  final String id;
  final String projectId;
  final String title;
  final String filePath;
  final RecordingType type;
  final RecordingMode mode;
  final DateTime createdAt;
  final Duration? duration;

  const RecordingTake({
    required this.id,
    required this.projectId,
    required this.title,
    required this.filePath,
    required this.type,
    required this.mode,
    required this.createdAt,
    this.duration,
  });

  factory RecordingTake.fromJson(Map<String, dynamic> json) {
    return RecordingTake(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String,
      type: RecordingType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => RecordingType.audio,
      ),
      mode: RecordingMode.values.firstWhere(
        (e) => e.toString() == json['mode'],
        orElse: () => RecordingMode.guitarOnly,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'filePath': filePath,
      'type': type.toString(),
      'mode': mode.toString(),
      'createdAt': createdAt.toIso8601String(),
      'durationMs': duration?.inMilliseconds,
    };
  }
}

class ChordSegment {
  final String id;
  final String chordName;
  final int startTimeMs;
  final int endTimeMs;

  const ChordSegment({
    required this.id,
    required this.chordName,
    required this.startTimeMs,
    required this.endTimeMs,
  });

  factory ChordSegment.fromJson(Map<String, dynamic> json) {
    return ChordSegment(
      id: json['id'] as String,
      chordName: json['chordName'] as String,
      startTimeMs: json['startTimeMs'] as int,
      endTimeMs: json['endTimeMs'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chordName': chordName,
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
    };
  }
}

class LyricLine {
  final String id;
  final int timeMs;
  final String text;

  const LyricLine({
    required this.id,
    required this.timeMs,
    required this.text,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      id: json['id'] as String? ?? '',
      timeMs: json['timeMs'] as int,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeMs': timeMs,
      'text': text,
    };
  }
}

class AudioProject {
  final String id;
  final String title;
  final String? originalAudioPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectStatus status;
  final AnalysisStatus stemStatus;
  final AnalysisStatus chordStatus;
  final AnalysisStatus beatStatus;
  final double? bpm;
  final String? keySignature;
  final String? timeSignature;
  final StemFiles? stemFiles;
  final List<RecordingTake> recordings;
  final List<ChordSegment> chordSegments;
  final String? plainLyrics;
  final String? syncedLyrics;
  final List<LyricLine> lyricLines;

  const AudioProject({
    required this.id,
    required this.title,
    this.originalAudioPath,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.stemStatus,
    required this.chordStatus,
    required this.beatStatus,
    this.bpm,
    this.keySignature,
    this.timeSignature,
    this.stemFiles,
    this.recordings = const [],
    this.chordSegments = const [],
    this.plainLyrics,
    this.syncedLyrics,
    this.lyricLines = const [],
  });

  factory AudioProject.fromJson(Map<String, dynamic> json) {
    return AudioProject(
      id: json['id'] as String,
      title: json['title'] as String,
      originalAudioPath: json['originalAudioPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: ProjectStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ProjectStatus.draft,
      ),
      stemStatus: AnalysisStatus.values.firstWhere(
        (e) => e.toString() == json['stemStatus'],
        orElse: () => AnalysisStatus.unavailable,
      ),
      chordStatus: AnalysisStatus.values.firstWhere(
        (e) => e.toString() == json['chordStatus'],
        orElse: () => AnalysisStatus.unavailable,
      ),
      beatStatus: AnalysisStatus.values.firstWhere(
        (e) => e.toString() == json['beatStatus'],
        orElse: () => AnalysisStatus.unavailable,
      ),
      bpm: (json['bpm'] as num?)?.toDouble(),
      keySignature: json['keySignature'] as String?,
      timeSignature: json['timeSignature'] as String?,
      stemFiles: json['stemFiles'] != null
          ? StemFiles.fromJson(json['stemFiles'] as Map<String, dynamic>)
          : null,
      recordings: (json['recordings'] as List<dynamic>?)
              ?.map((item) => RecordingTake.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      chordSegments: (json['chordSegments'] as List<dynamic>?)
              ?.map((item) => ChordSegment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      plainLyrics: json['plainLyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] as String?,
      lyricLines: (json['lyricLines'] as List<dynamic>?)
              ?.map((item) => LyricLine.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalAudioPath': originalAudioPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.toString(),
      'stemStatus': stemStatus.toString(),
      'chordStatus': chordStatus.toString(),
      'beatStatus': beatStatus.toString(),
      'bpm': bpm,
      'keySignature': keySignature,
      'timeSignature': timeSignature,
      'stemFiles': stemFiles?.toJson(),
      'recordings': recordings.map((item) => item.toJson()).toList(),
      'chordSegments': chordSegments.map((item) => item.toJson()).toList(),
      'plainLyrics': plainLyrics,
      'syncedLyrics': syncedLyrics,
      'lyricLines': lyricLines.map((item) => item.toJson()).toList(),
    };
  }

  AudioProject copyWith({
    String? title,
    String? originalAudioPath,
    DateTime? updatedAt,
    ProjectStatus? status,
    AnalysisStatus? stemStatus,
    AnalysisStatus? chordStatus,
    AnalysisStatus? beatStatus,
    double? bpm,
    String? keySignature,
    String? timeSignature,
    StemFiles? stemFiles,
    List<RecordingTake>? recordings,
    List<ChordSegment>? chordSegments,
    String? plainLyrics,
    String? syncedLyrics,
    List<LyricLine>? lyricLines,
  }) {
    return AudioProject(
      id: id,
      title: title ?? this.title,
      originalAudioPath: originalAudioPath ?? this.originalAudioPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      stemStatus: stemStatus ?? this.stemStatus,
      chordStatus: chordStatus ?? this.chordStatus,
      beatStatus: beatStatus ?? this.beatStatus,
      bpm: bpm ?? this.bpm,
      keySignature: keySignature ?? this.keySignature,
      timeSignature: timeSignature ?? this.timeSignature,
      stemFiles: stemFiles ?? this.stemFiles,
      recordings: recordings ?? this.recordings,
      chordSegments: chordSegments ?? this.chordSegments,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      lyricLines: lyricLines ?? this.lyricLines,
    );
  }
}
