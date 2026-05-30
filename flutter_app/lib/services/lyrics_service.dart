import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/audio_project.dart';

class LyricsService {
  static const String _baseUrl = 'https://lrclib.net/api';
  final _uuid = const Uuid();

  /// Search for lyrics on LRCLIB by query string.
  Future<List<Map<String, dynamic>>> searchLyrics(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {'q': query});
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'MusicStemStudio/1.0.0 (https://github.com/LostLuciano/MusicP)'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error searching lyrics: $e');
    }
    return [];
  }

  /// Get lyrics for a specific song signature.
  Future<Map<String, dynamic>?> getLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
    double? durationSeconds,
  }) async {
    try {
      final Map<String, String> params = {
        'track_name': trackName,
        'artist_name': artistName,
      };
      if (albumName != null) params['album_name'] = albumName;
      if (durationSeconds != null) {
        params['duration'] = durationSeconds.round().toString();
      }

      final uri = Uri.parse('$_baseUrl/get').replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'MusicStemStudio/1.0.0 (https://github.com/LostLuciano/MusicP)'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting exact lyrics: $e');
    }
    return null;
  }

  /// Parse LRC format string into a list of LyricLines.
  List<LyricLine> parseLrc(String lrcContent) {
    final lines = lrcContent.split('\n');
    final List<LyricLine> list = [];
    
    // Matches patterns like [00:12.34], [00:12:34], [00:12]
    final regex = RegExp(r'^\[(\d+):(\d+)(?:[.:](\d+))?\](.*)$');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final milliStr = match.group(3) ?? '00';
        
        int ms = 0;
        if (milliStr.length == 2) {
          ms = int.parse(milliStr) * 10;
        } else if (milliStr.length == 3) {
          ms = int.parse(milliStr);
        } else if (milliStr.length == 1) {
          ms = int.parse(milliStr) * 100;
        }

        final timeMs = (min * 60 + sec) * 1000 + ms;
        final text = match.group(4)!.trim();

        list.add(LyricLine(
          id: _uuid.v4(),
          timeMs: timeMs,
          text: text,
        ));
      }
    }

    list.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    return list;
  }
}
