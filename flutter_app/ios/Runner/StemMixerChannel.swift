import Foundation

/// Models a mixer channel track configuration for an isolated audio stem.
public struct StemMixerChannel: Codable {
    public let name: String       // e.g., "vocals", "drums", "bass", etc.
    public var fileURL: URL?      // Path to isolated audio file
    public var volume: Float      // 0.0 to 1.0
    public var isMuted: Bool
    public var isSoloed: Bool
    
    public init(name: String, fileURL: URL? = nil, volume: Float = 1.0, isMuted: Bool = false, isSoloed: Bool = false) {
        self.name = name
        self.fileURL = fileURL
        self.volume = volume
        self.isMuted = isMuted
        self.isSoloed = isSoloed
    }
}
