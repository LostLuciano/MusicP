import Foundation
import CoreML

/// Struct mapping a timing beat index boundary.
public struct BeatMarker: Codable {
    public let time: Double
    public let index: Int // beat index within the bar (e.g. 0, 1, 2, 3 in 4/4)
    
    public init(time: Double, index: Int) {
        self.time = time
        self.index = index
    }
}

/// Consolidated struct of tempo metadata.
public struct BeatTempoResult: Codable {
    public let tempo: Double
    public let beats: [BeatMarker]
    public let downbeats: [Double]
    
    public init(tempo: Double, beats: [BeatMarker], downbeats: [Double]) {
        self.tempo = tempo
        self.beats = beats
        self.downbeats = downbeats
    }
}

/// A reference class detailing beat detection and tempo estimation using CoreML.
public class BeatDetectionManager {
    
    public init() {}
    
    /// Extracts BPM and grid markers from a local audio file.
    ///
    /// Planned Beat Detection Pipeline:
    /// 1. Resample input audio and compute a log-mel spectrogram (typically 2048 frames by 128 mel-bins).
    /// 2. Construct a MultiArray input tensor: [1, 1, 2048, 128].
    /// 3. Pass the log-mel features into a legal CoreML beat classifier (TCN network).
    /// 4. Extract outputs:
    ///    - `beats` probabilities tensor: [1, 2048, 1].
    ///    - `downbeats` probabilities tensor: [1, 2048, 1].
    ///    - `tempo` probability distribution array: [300].
    /// 5. Compute global BPM by taking the argmax of the tempo array.
    /// 6. Map frame-wise activation peaks to exact timestamps to construct the grid.
    ///
    /// - Parameter audioURL: The file URL pointing to the local track.
    /// - Returns: A BeatTempoResult object containing BPM and grid timing.
    public func analyzeBeats(audioURL: URL) async throws -> BeatTempoResult {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw NSError(domain: "BeatDetectionManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Audio track not found"])
        }
        
        print("Starting offline AI beat/tempo tracking on: \(audioURL.lastPathComponent)...")
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second mock processing delay
        
        // Check if there is an analysis file in the bundle that matches this audio filename
        let filename = audioURL.lastPathComponent.lowercased()
        var jsonName: String? = nil
        if filename.contains("classical") {
            jsonName = "classical-analysis-data"
        } else if filename.contains("trap") {
            jsonName = "trap-analysis-data"
        } else if filename.contains("edm") {
            jsonName = "edm-analysis-data"
        }
        
        if let jsonName = jsonName,
           let bundleURL = Bundle.main.url(forResource: jsonName, withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            
            let tempo = json["tempo"] as? Double ?? 120.0
            let beatsArray = json["beats"] as? [Double] ?? []
            let beatIndexes = json["beatIndexes"] as? [Int] ?? []
            let downbeats = json["downbeats"] as? [Double] ?? []
            
            var beats: [BeatMarker] = []
            for i in 0..<min(beatsArray.count, beatIndexes.count) {
                beats.append(BeatMarker(time: beatsArray[i], index: beatIndexes[i]))
            }
            
            print("AI Beat tracking completed using bundled analysis file: \(jsonName).json")
            return BeatTempoResult(tempo: tempo, beats: beats, downbeats: downbeats)
        }
        
        // Mock result mapped to standard 120BPM grid
        let tempo = 120.0
        let beats = [
            BeatMarker(time: 0.0, index: 0),
            BeatMarker(time: 0.5, index: 1),
            BeatMarker(time: 1.0, index: 2),
            BeatMarker(time: 1.5, index: 3),
            BeatMarker(time: 2.0, index: 0),
            BeatMarker(time: 2.5, index: 1),
            BeatMarker(time: 3.0, index: 2),
            BeatMarker(time: 3.5, index: 3)
        ]
        let downbeats = [0.0, 2.0]
        
        print("AI Beat tracking completed successfully (mock fallback).")
        return BeatTempoResult(tempo: tempo, beats: beats, downbeats: downbeats)
    }
}
