# iOS Native Audio Pipeline & AVAudioEngine Configuration

This guide details how to configure `AVAudioSession` and `AVAudioEngine` for low-latency playback, recording, and stem mixing on iOS.

---

## 1. AVAudioSession Configuration
To support real-time audio playback alongside background mixing and recording, `AVAudioSession` must be configured in your app entry point:

```swift
import AVFoundation

func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
        // Set category to play and record to support mic input and playback
        // Set mode to measurement or default depending on DSP needs
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
        try session.setActive(true)
        
        // Request low buffer latency (approx. 5ms to 10ms target)
        try session.setPreferredIOBufferDuration(0.005) 
    } catch {
        print("AudioSession configuration failed: \(error)")
    }
}
```

---

## 2. AVAudioEngine Topology
`AVAudioEngine` models a dynamic node graph. For a 6-stem mixer application, the graph topology consists of:

```text
[Vocals PlayerNode] ──┐
[Drums PlayerNode]  ──┼──> [Main MixerNode] ──> [Hardware Output]
[Bass PlayerNode]   ──┤
[Guitar PlayerNode] ──┤
[Piano PlayerNode]  ──┤
[Other PlayerNode]  ──┘

[Hardware InputNode] ──> [Recording Format Resampler] ──> [WAV File Writer]
```

### Key Subsystems:
* **`AVAudioPlayerNode`**: Used to schedule audio buffers or stream files from local storage. Six dedicated instances run in parallel.
* **`AVAudioMixerNode`**: Merges output channels. It provides built-in gain control, panning, and rendering callback attachments.
* **`AVAudioInputNode`**: The microphone capture tap. By installing an audio tap on this node, we record ambient inputs.

---

## 3. Playback Synchronization & Latency
To ensure all six player nodes play in perfect synchronization:
1. Load stem files into memory or prepare disk readers.
2. Schedule files on all nodes beforehand using `scheduleFile` or `scheduleBuffer`.
3. Sample-accurate synchronization is achieved by triggering playback with a specific host time baseline:
   ```swift
   let sampleTime = AVAudioTime(sampleTime: 0, atRate: 44100)
   for (_, player) in players {
       player.play(at: sampleTime)
   }
   ```
4. **Latency Considerations**: Reduce hardware IO buffer duration to minimize playback start delay. Ensure all DSP code executes in background threads to avoid dropping samples on the real-time audio thread.
5. **Background Audio**: Add `audio` to `UIBackgroundModes` in your app's `Info.plist` to prevent the system from suspending the audio graph when the app is minimized.
