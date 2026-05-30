import Foundation
import AVFoundation

/// Manages multi-channel stem playback, mixing, recording, and real-time DSP effects using AVAudioEngine.
public class AudioEngineManager {
    
    private let audioEngine = AVAudioEngine()
    private let mainMixer = AVAudioMixerNode()
    private let timePitchNode = AVAudioUnitTimePitch()
    
    // Mapping of stem names to their respective player nodes
    private var players: [String: AVAudioPlayerNode] = [:]
    // Dictionary tracking local URLs for loaded stem files
    private var stemFiles: [String: URL] = [:]
    
    private let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
    
    public init() {
        configureAudioSession()
        setupAudioEngine()
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("AVAudioSession: Configured category to .playback for background audio.")
        } catch {
            print("AVAudioSession: Failed to set category: \(error.localizedDescription)")
        }
    }
    
    /// Initializes player nodes, attaches them to the audio engine graph, and configures mixer routing.
    private func setupAudioEngine() {
        audioEngine.attach(mainMixer)
        audioEngine.attach(timePitchNode)
        
        // Connect mainMixer to timePitchNode, and timePitchNode to outputNode
        audioEngine.connect(mainMixer, to: timePitchNode, format: nil)
        audioEngine.connect(timePitchNode, to: audioEngine.outputNode, format: nil)
        
        for name in stemNames {
            let player = AVAudioPlayerNode()
            players[name] = player
            audioEngine.attach(player)
            
            // Connect each player to the main mixer
            // format: nil lets AVAudioEngine resolve matching connections dynamically
            audioEngine.connect(player, to: mainMixer, format: nil)
        }
    }
    
    /// Loads isolated stem files into player buffers.
    /// - Parameter stems: Dictionary mapping stem names to local file system URLs.
    public func loadStemFiles(_ stems: [String: URL]) throws {
        self.stemFiles = stems
        
        for (name, url) in stems {
            guard let player = players[name] else { continue }
            
            // Stop active playback before scheduling new files
            player.stop()
            
            // Actually schedule the file:
            do {
                let file = try AVAudioFile(forReading: url)
                player.scheduleFile(file, at: nil, completionHandler: nil)
                print("Scheduled stem file: \(name) -> \(url.lastPathComponent)")
            } catch {
                print("Failed to schedule stem file \(name): \(error.localizedDescription)")
                throw error
            }
        }
        
        // Prepare the engine
        audioEngine.prepare()
    }
    
    /// Starts simultaneous playback of all loaded players.
    public func play() throws {
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        
        for (_, player) in players {
            player.play()
        }
        print("AVAudioEngine: Started simultaneous playback of all stem player nodes.")
    }
    
    /// Pauses all players.
    public func pause() {
        for (_, player) in players {
            player.pause()
        }
        print("AVAudioEngine: Paused playback.")
    }
    
    /// Stops all players and resets the audio engine.
    public func stop() {
        for (_, player) in players {
            player.stop()
        }
        audioEngine.stop()
        print("AVAudioEngine: Stopped engine graph.")
    }
    
    /// Adjusts the volume slider value for a specific stem channel.
    /// - Parameters:
    ///   - stem: The identifier of the stem ("vocals", "drums", etc.)
    ///   - volume: A float value between 0.0 (silent) and 1.0 (full volume).
    public func setVolume(stem: String, volume: Float) {
        guard let player = players[stem] else { return }
        player.volume = volume
        print("AVAudioEngine: Adjusted \(stem) channel volume to \(volume)")
    }
    
    /// Mutes or unmutes a specific stem.
    /// - Parameters:
    ///   - stem: The identifier of the stem.
    ///   - muted: True to mute, False to restore.
    public func muteStem(_ stem: String, muted: Bool) {
        guard let player = players[stem] else { return }
        player.volume = muted ? 0.0 : 1.0
        print("AVAudioEngine: \(stem) is \(muted ? "muted" : "unmuted")")
    }
    
    /// Solos a specific stem by muting all other active channels.
    /// - Parameter stem: The identifier of the stem to isolate.
    public func soloStem(_ stem: String) {
        guard players[stem] != nil else { return }
        
        for (name, player) in players {
            if name == stem {
                player.volume = 1.0
            } else {
                player.volume = 0.0
            }
        }
        print("AVAudioEngine: Soloed \(stem) channel. All other tracks silenced.")
    }
    
    /// Adjusts the overall playback speed (tempo) without modifying pitch.
    /// - Parameter speed: Playback speed multiplier (e.g. 0.5 to 2.0).
    public func setPlaybackSpeed(_ speed: Float) {
        timePitchNode.rate = speed
        print("AVAudioEngine: Set playback speed to \(speed)")
    }
    
    /// Extracts the audio track from a video file and writes it to a destination M4A URL.
    public func extractAudio(from videoURL: URL, outputURL: URL) async throws {
        let asset = AVURLAsset(url: videoURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        await exportSession.export()
        if exportSession.status == .failed {
            throw exportSession.error ?? NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Audio extraction failed"])
        }
        print("AVAudioEngine: Successfully extracted audio from video: \(videoURL.lastPathComponent) -> \(outputURL.lastPathComponent)")
    }
    
    /// Merges/mixes two audio files together into a single M4A file.
    public func mixAudioFiles(file1URL: URL, file2URL: URL, outputURL: URL) async throws {
        let composition = AVMutableComposition()
        
        let asset1 = AVURLAsset(url: file1URL)
        let asset2 = AVURLAsset(url: file2URL)
        
        // Wait for audio tracks to load asynchronously
        guard let audioTrack1 = try? await asset1.loadTracks(withMediaType: .audio).first,
              let audioTrack2 = try? await asset2.loadTracks(withMediaType: .audio).first else {
            throw NSError(domain: "AudioEngineManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to load audio tracks from inputs"])
        }
        
        let compTrack1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compTrack2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let duration1 = try await asset1.load(.duration)
        let duration2 = try await asset2.load(.duration)
        
        let timeRange1 = CMTimeRange(start: .zero, duration: duration1)
        let timeRange2 = CMTimeRange(start: .zero, duration: duration2)
        
        try compTrack1?.insertTimeRange(timeRange1, of: audioTrack1, at: .zero)
        try compTrack2?.insertTimeRange(timeRange2, of: audioTrack2, at: .zero)
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession for composition"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        await exportSession.export()
        if exportSession.status == .failed {
            throw exportSession.error ?? NSError(domain: "AudioEngineManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mashup composition export failed"])
        }
        print("AVAudioEngine: Successfully mixed/mashup files: \(file1URL.lastPathComponent) + \(file2URL.lastPathComponent) -> \(outputURL.lastPathComponent)")
    }
}
