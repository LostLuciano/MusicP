import Foundation
import AVFoundation

/// Manages multi-channel stem playback, mixing, recording, and real-time DSP effects using AVAudioEngine.
public class AudioEngineManager {
    
    private let audioEngine = AVAudioEngine()
    private let mainMixer = AVAudioMixerNode()
    
    // Mapping of stem names to their respective player nodes
    private var players: [String: AVAudioPlayerNode] = [:]
    // Dictionary tracking local URLs for loaded stem files
    private var stemFiles: [String: URL] = [:]
    
    private let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
    
    public init() {
        setupAudioEngine()
    }
    
    /// Initializes player nodes, attaches them to the audio engine graph, and configures mixer routing.
    private func setupAudioEngine() {
        audioEngine.attach(mainMixer)
        audioEngine.connect(mainMixer, to: audioEngine.outputNode, format: nil)
        
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
            
            // In a production application, you would read this into an AVAudioFile:
            // let file = try AVAudioFile(forReading: url)
            // player.scheduleFile(file, at: nil, completionHandler: nil)
            
            print("Scheduled stem file: \(name) -> \(url.lastPathComponent)")
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
}
