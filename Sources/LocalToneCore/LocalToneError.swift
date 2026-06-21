import Foundation

public enum LocalToneError: Error, Equatable, LocalizedError {
    case unsupportedInputExtension(String)
    case missingInputFile(URL)
    case outputDirectoryUnavailable(URL)
    case invalidTrimStart(Double)
    case invalidDuration(Double)
    case assetHasNoAudioTrack
    case exportSessionUnavailable
    case exportFailed(String)
    case exportCancelled

    public var errorDescription: String? {
        switch self {
        case .unsupportedInputExtension(let ext):
            return "Unsupported input file extension: \(ext.isEmpty ? "none" : ext)."
        case .missingInputFile(let url):
            return "The input file could not be found: \(url.path)."
        case .outputDirectoryUnavailable(let url):
            return "The output directory is unavailable: \(url.path)."
        case .invalidTrimStart(let value):
            return "Trim start must be zero or greater. Current value: \(value)."
        case .invalidDuration(let value):
            return "Duration must be greater than zero and no more than \(RingtoneExportOptions.maximumDuration) seconds. Current value: \(value)."
        case .assetHasNoAudioTrack:
            return "The selected file does not contain an audio track."
        case .exportSessionUnavailable:
            return "The ringtone export session could not be created for this file."
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .exportCancelled:
            return "Export cancelled."
        }
    }
}
