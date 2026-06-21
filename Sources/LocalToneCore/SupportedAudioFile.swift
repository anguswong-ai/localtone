import Foundation

public enum SupportedAudioFile {
    public static let inputExtensions: Set<String> = ["m4a", "mp4", "aac", "m4r"]
    public static let outputExtension = "m4r"

    public static func validateInputURL(_ url: URL) throws {
        let ext = url.pathExtension.lowercased()
        guard inputExtensions.contains(ext) else {
            throw LocalToneError.unsupportedInputExtension(ext)
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw LocalToneError.missingInputFile(url)
        }
    }

    public static func normalizedOutputURL(for proposedURL: URL) -> URL {
        proposedURL.deletingPathExtension().appendingPathExtension(outputExtension)
    }
}
