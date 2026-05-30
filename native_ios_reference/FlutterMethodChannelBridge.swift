import Foundation
import Flutter
import UIKit

/// Native iOS entry point bridging requests from Flutter Dart UI code.
public class FlutterMethodChannelBridge: NSObject {
    
    private let channelName = "music_stem_studio/native_audio"
    
    // Core managers
    private let separator = CoreMLStemSeparator()
    private let audioEngine = AudioEngineManager()
    private let chordDetector = ChordDetectionManager()
    private let beatDetector = BeatDetectionManager()
    
    public func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(self, channel: channel)
    }
}

extension FlutterMethodChannelBridge: FlutterPlugin {
    
    public static func register(with registrar: any FlutterPluginRegistrar) {
        let bridge = FlutterMethodChannelBridge()
        bridge.register(with: registrar)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments must be a dictionary", details: nil))
            return
        }
        
        switch call.method {
        case "importAudio":
            // Placeholder: simulate choosing a track
            result("/var/mobile/Containers/Data/Documents/imported_mixture.mp3")
            
        case "startRecording":
            result("/var/mobile/Containers/Data/Documents/recording.wav")
            
        case "stopRecording":
            result(nil)
            
        case "separateStems":
            guard let audioPath = arguments["audioPath"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "audioPath is required", details: nil))
                return
            }
            
            let audioURL = URL(fileURLWithPath: audioPath)
            
            Task {
                do {
                    let stemURLs = try await separator.separate(audioURL: audioURL)
                    // Map local URLs to absolute path strings to pass back to Dart
                    var pathsDict: [String: String] = [:]
                    for (key, val) in stemURLs {
                        pathsDict[key] = val.path
                    }
                    
                    // Load the files directly to our audio player mixer
                    try audioEngine.loadStemFiles(stemURLs)
                    
                    DispatchQueue.main.async {
                        result(pathsDict)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "SEPARATION_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            }
            
        case "analyzeChords":
            guard let audioPath = arguments["audioPath"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "audioPath is required", details: nil))
                return
            }
            
            let audioURL = URL(fileURLWithPath: audioPath)
            
            Task {
                do {
                    let segments = try await chordDetector.analyzeChords(audioURL: audioURL)
                    
                    // Convert Codable segments to dictionary arrays
                    if let data = try? JSONEncoder().encode(segments),
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        DispatchQueue.main.async {
                            result(json)
                        }
                    } else {
                        DispatchQueue.main.async {
                            result([])
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CHORD_ANALYSIS_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            }
            
        case "analyzeBeatsAndTempo":
            guard let audioPath = arguments["audioPath"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "audioPath is required", details: nil))
                return
            }
            
            let audioURL = URL(fileURLWithPath: audioPath)
            
            Task {
                do {
                    let beatResult = try await beatDetector.analyzeBeats(audioURL: audioURL)
                    
                    if let data = try? JSONEncoder().encode(beatResult),
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        DispatchQueue.main.async {
                            result(json)
                        }
                    } else {
                        DispatchQueue.main.async {
                            result(nil)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "BEAT_ANALYSIS_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            }
            
        case "playStemMix":
            do {
                try audioEngine.play()
                result(nil)
            } catch {
                result(FlutterError(code: "PLAYBACK_FAILED", message: error.localizedDescription, details: nil))
            }
            
        case "setStemVolume":
            guard let stemName = arguments["stemName"] as? String,
                  let volume = arguments["volume"] as? Double else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "stemName and volume are required", details: nil))
                return
            }
            audioEngine.setVolume(stem: stemName, volume: Float(volume))
            result(nil)
            
        case "muteStem":
            guard let stemName = arguments["stemName"] as? String,
                  let muted = arguments["muted"] as? Bool else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "stemName and muted are required", details: nil))
                return
            }
            audioEngine.muteStem(stemName, muted: muted)
            result(nil)
            
        case "soloStem":
            guard let stemName = arguments["stemName"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "stemName is required", details: nil))
                return
            }
            audioEngine.soloStem(stemName)
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
