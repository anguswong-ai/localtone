import AVFoundation
import CoreMedia
import Foundation

public struct RingtoneExportResult: Equatable, Sendable {
    public let outputURL: URL
    public let duration: Double
}

public final class RingtoneExporter: Sendable {
    public init() {}

    public func export(
        inputURL: URL,
        outputURL proposedOutputURL: URL,
        options rawOptions: RingtoneExportOptions
    ) async throws -> RingtoneExportResult {
        try SupportedAudioFile.validateInputURL(inputURL)

        let outputURL = SupportedAudioFile.normalizedOutputURL(for: proposedOutputURL)
        let outputDirectory = outputURL.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: outputDirectory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw LocalToneError.outputDirectoryUnavailable(outputDirectory)
        }

        let options = try rawOptions.validated()
        let asset = AVURLAsset(url: inputURL)

        let audioTrack: AVAssetTrack
        let assetDuration: Double
        do {
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            guard let firstTrack = audioTracks.first else {
                throw LocalToneError.assetHasNoAudioTrack
            }
            audioTrack = firstTrack
            assetDuration = try await asset.load(.duration).seconds
        } catch let error as LocalToneError {
            throw error
        } catch {
            // AVFoundation could not read the file (e.g. it is corrupt or not real media).
            throw LocalToneError.assetHasNoAudioTrack
        }

        guard assetDuration.isFinite, assetDuration > 0 else {
            throw LocalToneError.assetHasNoAudioTrack
        }
        guard options.startTime < assetDuration else {
            throw LocalToneError.invalidTrimStart(options.startTime)
        }
        let availableDuration = assetDuration - options.startTime
        let effectiveDuration = min(options.duration, availableDuration)
        let exportTimeRange = CMTimeRange(
            start: CMTime(seconds: options.startTime, preferredTimescale: 600),
            duration: CMTime(seconds: effectiveDuration, preferredTimescale: 600)
        )

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw LocalToneError.exportSessionUnavailable
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = exportTimeRange
        exportSession.shouldOptimizeForNetworkUse = false
        exportSession.audioMix = Self.audioMix(
            for: audioTrack,
            startTime: exportTimeRange.start,
            duration: exportTimeRange.duration,
            fadeInDuration: options.fadeInDuration,
            fadeOutDuration: options.fadeOutDuration
        )

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            return RingtoneExportResult(outputURL: outputURL, duration: effectiveDuration)
        case .cancelled:
            throw LocalToneError.exportCancelled
        case .failed:
            throw LocalToneError.exportFailed(exportSession.error?.localizedDescription ?? "Unknown error")
        default:
            throw LocalToneError.exportFailed("Unexpected export status: \(exportSession.status.rawValue)")
        }
    }

    private static func audioMix(
        for audioTrack: AVAssetTrack,
        startTime: CMTime,
        duration: CMTime,
        fadeInDuration rawFadeInDuration: Double,
        fadeOutDuration rawFadeOutDuration: Double
    ) -> AVAudioMix? {
        let totalSeconds = max(0, duration.seconds)
        guard totalSeconds > 0 else {
            return nil
        }

        let fadeInSeconds = min(max(0, rawFadeInDuration), totalSeconds)
        let fadeOutSeconds = min(max(0, rawFadeOutDuration), totalSeconds)
        guard fadeInSeconds > 0 || fadeOutSeconds > 0 else {
            return nil
        }

        let parameters = AVMutableAudioMixInputParameters(track: audioTrack)

        if fadeInSeconds > 0 {
            let fadeInRange = CMTimeRange(
                start: startTime,
                duration: CMTime(seconds: fadeInSeconds, preferredTimescale: 600)
            )
            parameters.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: fadeInRange)
        }

        if fadeOutSeconds > 0 {
            let fadeOutDuration = CMTime(seconds: fadeOutSeconds, preferredTimescale: 600)
            let fadeOutStart = startTime + duration - fadeOutDuration
            let fadeOutRange = CMTimeRange(start: fadeOutStart, duration: fadeOutDuration)
            parameters.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: fadeOutRange)
        }

        let mix = AVMutableAudioMix()
        mix.inputParameters = [parameters]
        return mix
    }
}
