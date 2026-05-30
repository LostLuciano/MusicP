import Foundation

/// A single synchronized lyric line with timestamp.
public struct LyricLine: Codable {
    public let startTime: Double   // seconds
    public let endTime: Double     // seconds
    public let text: String

    public init(startTime: Double, endTime: Double, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

/// Manages loading and querying time-synced lyrics from bundled JSON files.
///
/// Lyrics JSON format expected:
/// {
///   "lyrics": [
///     { "startTime": 0.0, "endTime": 4.2, "text": "First line..." },
///     ...
///   ]
/// }
public class LyricsManager {

    public private(set) var lines: [LyricLine] = []
    public private(set) var loadedSongName: String? = nil

    public init() {}

    /// Loads the lyrics for a given song name from the app bundle.
    /// - Parameter songName: Base name of the song (e.g. "classical", "trap", "edm").
    /// - Returns: `true` if lyrics were found and loaded, `false` otherwise.
    @discardableResult
    public func loadLyrics(for songName: String) -> Bool {
        let jsonName = "\(songName)-lyrics"
        guard let url = Bundle.main.url(forResource: jsonName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawLines = json["lyrics"] as? [[String: Any]] else {
            print("LyricsManager: No lyrics found for '\(songName)'.")
            lines = []
            loadedSongName = nil
            return false
        }

        lines = rawLines.compactMap { dict -> LyricLine? in
            guard let start = dict["startTime"] as? Double,
                  let end   = dict["endTime"]   as? Double,
                  let text  = dict["text"]       as? String else { return nil }
            return LyricLine(startTime: start, endTime: end, text: text)
        }

        loadedSongName = songName
        print("LyricsManager: Loaded \(lines.count) lines for '\(songName)'.")
        return true
    }

    /// Returns the active lyric line at the given playback position.
    /// - Parameter time: Current playback position in seconds.
    public func activeLine(at time: Double) -> LyricLine? {
        return lines.first { time >= $0.startTime && time < $0.endTime }
    }

    /// Returns the next lyric line after the given time.
    public func nextLine(after time: Double) -> LyricLine? {
        return lines.first { $0.startTime > time }
    }

    /// Serializes all lines to a JSON-safe array for passing back via MethodChannel.
    public func toSerializable() -> [[String: Any]] {
        return lines.map { [
            "startTime": $0.startTime,
            "endTime":   $0.endTime,
            "text":      $0.text
        ]}
    }
}
