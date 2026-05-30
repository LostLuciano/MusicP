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
    private let metronome = MetronomeManager()
    private let lyricsManager = LyricsManager()
    
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
        let arguments = call.arguments as? [String: Any]
        
        switch call.method {
        case "importAudio":
            // Placeholder: simulate choosing a track
            result("/var/mobile/Containers/Data/Documents/imported_mixture.mp3")
            
        case "startRecording":
            result("/var/mobile/Containers/Data/Documents/recording.wav")
            
        case "stopRecording":
            result(nil)
            
        case "separateStems":
            guard let args = arguments, let audioPath = args["audioPath"] as? String else {
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
            guard let args = arguments, let audioPath = args["audioPath"] as? String else {
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
            guard let args = arguments, let audioPath = args["audioPath"] as? String else {
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
            
        case "pauseStemMix":
            audioEngine.pause()
            result(nil)
            
        case "stopStemMix":
            audioEngine.stop()
            result(nil)
            
        case "setStemVolume":
            guard let args = arguments,
                  let stemName = args["stemName"] as? String,
                  let volume = args["volume"] as? Double else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "stemName and volume are required", details: nil))
                return
            }
            audioEngine.setVolume(stem: stemName, volume: Float(volume))
            result(nil)
            
        case "muteStem":
            guard let args = arguments,
                  let stemName = args["stemName"] as? String,
                  let muted = args["muted"] as? Bool else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "stemName and muted are required", details: nil))
                return
            }
            audioEngine.muteStem(stemName, muted: muted)
            result(nil)
            
        case "soloStem":
            guard let args = arguments, let stemName = args["stemName"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "stemName is required", details: nil))
                return
            }
            audioEngine.soloStem(stemName)
            result(nil)
            
        case "setPlaybackSpeed":
            guard let args = arguments, let speed = args["speed"] as? Double else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "speed is required", details: nil))
                return
            }
            audioEngine.setPlaybackSpeed(Float(speed))
            result(nil)
            
        case "extractAudioFromVideo":
            guard let args = arguments,
                  let videoPath = args["videoPath"] as? String,
                  let outputPath = args["outputPath"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "videoPath and outputPath are required", details: nil))
                return
            }
            let videoURL = URL(fileURLWithPath: videoPath)
            let outputURL = URL(fileURLWithPath: outputPath)
            
            Task {
                do {
                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        try? FileManager.default.removeItem(at: outputURL)
                    }
                    try await audioEngine.extractAudio(from: videoURL, outputURL: outputURL)
                    DispatchQueue.main.async {
                        result(outputURL.path)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "EXTRACTION_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            }
            
        case "mixAudioFiles":
            guard let args = arguments,
                  let file1Path = args["file1Path"] as? String,
                  let file2Path = args["file2Path"] as? String,
                  let outputPath = args["outputPath"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "file1Path, file2Path and outputPath are required", details: nil))
                return
            }
            let file1URL = URL(fileURLWithPath: file1Path)
            let file2URL = URL(fileURLWithPath: file2Path)
            let outputURL = URL(fileURLWithPath: outputPath)
            
            Task {
                do {
                    if FileManager.default.fileExists(atPath: outputURL.path) {
                        try? FileManager.default.removeItem(at: outputURL)
                    }
                    try await audioEngine.mixAudioFiles(file1URL: file1URL, file2URL: file2URL, outputURL: outputURL)
                    DispatchQueue.main.async {
                        result(outputURL.path)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "MIXING_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            }
            
        case "shareFile":
            guard let args = arguments, let filePath = args["filePath"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "filePath is required", details: nil))
                return
            }
            let fileURL = URL(fileURLWithPath: filePath)
            
            DispatchQueue.main.async {
                // Get the top-most view controller to present UIActivityViewController
                guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
                    result(FlutterError(code: "NO_ROOT_VC", message: "Could not find root view controller", details: nil))
                    return
                }
                
                var topVC = rootVC
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = topVC.view
                    popoverController.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                topVC.present(activityVC, animated: true, completion: {
                    result(nil)
                })
            }
            
        case "startMetronome":
            let bpm   = (arguments?["bpm"]          as? Double) ?? 120.0
            let beats = (arguments?["beatsPerBar"]  as? Int)    ?? 4
            let subs  = (arguments?["subdivisions"] as? Int)    ?? 1
            metronome.start(bpm: bpm, beatsPerBar: beats, subdivisions: subs)
            result(nil)
            
        case "stopMetronome":
            metronome.stop()
            result(nil)
            
        case "updateMetronomeBPM":
            guard let args = arguments, let bpm = args["bpm"] as? Double else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "bpm is required", details: nil))
                return
            }
            metronome.updateBPM(bpm)
            result(nil)
            
        case "loadLyrics":
            guard let args = arguments, let songName = args["songName"] as? String else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "songName is required", details: nil))
                return
            }
            let found = lyricsManager.loadLyrics(for: songName)
            result(found ? lyricsManager.toSerializable() : [])
            
        case "getLyricAt":
            guard let args = arguments, let time = args["time"] as? Double else {
                result(FlutterError(code: "MISSING_ARGUMENT", message: "time is required", details: nil))
                return
            }
            if let line = lyricsManager.activeLine(at: time) {
                result(["startTime": line.startTime, "endTime": line.endTime, "text": line.text])
            } else {
                result(nil)
            }
            
        case "getAllLyrics":
            result(lyricsManager.toSerializable())
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
