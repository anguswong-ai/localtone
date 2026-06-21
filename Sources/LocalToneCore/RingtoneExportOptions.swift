import Foundation

public struct RingtoneExportOptions: Equatable, Sendable {
    public static let maximumDuration: Double = 30

    public var startTime: Double
    public var duration: Double
    public var fadeInDuration: Double
    public var fadeOutDuration: Double

    public init(
        startTime: Double = 0,
        duration: Double = maximumDuration,
        fadeInDuration: Double = 0,
        fadeOutDuration: Double = 0
    ) {
        self.startTime = startTime
        self.duration = duration
        self.fadeInDuration = fadeInDuration
        self.fadeOutDuration = fadeOutDuration
    }

    public func validated() throws -> RingtoneExportOptions {
        guard startTime >= 0 else {
            throw LocalToneError.invalidTrimStart(startTime)
        }

        guard duration > 0, duration <= Self.maximumDuration else {
            throw LocalToneError.invalidDuration(duration)
        }

        return RingtoneExportOptions(
            startTime: startTime,
            duration: min(duration, Self.maximumDuration),
            fadeInDuration: max(0, fadeInDuration),
            fadeOutDuration: max(0, fadeOutDuration)
        )
    }
}
