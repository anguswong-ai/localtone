import AVFoundation
import Darwin
import XCTest
@testable import LocalToneCore

final class LocalToneCoreTests: XCTestCase {
    func testSupportedInputExtensionsAreAcceptedWhenFileExists() throws {
        for ext in SupportedAudioFile.inputExtensions {
            let url = temporaryURL(extension: ext)
            _ = FileManager.default.createFile(atPath: url.path, contents: Data("x".utf8))
            XCTAssertNoThrow(try SupportedAudioFile.validateInputURL(url))
            try FileManager.default.removeItem(at: url)
        }
    }

    func testUnsupportedInputExtensionFails() throws {
        let url = temporaryURL(extension: "wav")
        _ = FileManager.default.createFile(atPath: url.path, contents: Data("x".utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(try SupportedAudioFile.validateInputURL(url)) { error in
            XCTAssertEqual(error as? LocalToneError, .unsupportedInputExtension("wav"))
        }
    }

    func testMissingInputFileFailsAfterExtensionPasses() {
        let url = temporaryURL(extension: "m4a")

        XCTAssertThrowsError(try SupportedAudioFile.validateInputURL(url)) { error in
            XCTAssertEqual(error as? LocalToneError, .missingInputFile(url))
        }
    }

    func testOutputURLIsNormalizedToM4R() {
        let url = URL(fileURLWithPath: "/tmp/song.m4a")

        XCTAssertEqual(
            SupportedAudioFile.normalizedOutputURL(for: url).lastPathComponent,
            "song.m4r"
        )
    }

    func testOptionsRejectNegativeStartTime() {
        let options = RingtoneExportOptions(startTime: -0.1, duration: 10)

        XCTAssertThrowsError(try options.validated()) { error in
            XCTAssertEqual(error as? LocalToneError, .invalidTrimStart(-0.1))
        }
    }

    func testOptionsRejectDurationOverThirtySeconds() {
        let options = RingtoneExportOptions(startTime: 0, duration: 30.1)

        XCTAssertThrowsError(try options.validated()) { error in
            XCTAssertEqual(error as? LocalToneError, .invalidDuration(30.1))
        }
    }

    func testExporterFailsForFileWithoutAudioTrack() async throws {
        let inputURL = temporaryURL(extension: "m4a")
        let outputURL = temporaryURL(extension: "m4r")
        _ = FileManager.default.createFile(atPath: inputURL.path, contents: Data("not audio".utf8))
        defer {
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        do {
            _ = try await RingtoneExporter().export(
                inputURL: inputURL,
                outputURL: outputURL,
                options: RingtoneExportOptions(duration: 1)
            )
            XCTFail("Expected export to fail for invalid audio data.")
        } catch let error as LocalToneError {
            XCTAssertTrue(
                [.assetHasNoAudioTrack, .exportSessionUnavailable].contains(error),
                "Unexpected LocalToneError: \(error)"
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExporterCreatesM4RFromGeneratedAudio() async throws {
        let inputURL = temporaryURL(extension: "m4a")
        let outputURL = temporaryURL(extension: "m4r")
        defer {
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        try writeGeneratedAACAudio(to: inputURL, seconds: 2)

        let result = try await RingtoneExporter().export(
            inputURL: inputURL,
            outputURL: outputURL,
            options: RingtoneExportOptions(startTime: 0, duration: 1, fadeInDuration: 0.1, fadeOutDuration: 0.1)
        )

        XCTAssertEqual(result.outputURL.pathExtension, "m4r")
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.outputURL.path))
        XCTAssertGreaterThan(try FileManager.default.attributesOfItem(atPath: result.outputURL.path)[.size] as? UInt64 ?? 0, 0)
    }

    private func temporaryURL(extension ext: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }

    private func writeGeneratedAACAudio(to url: URL, seconds: Double) throws {
        let sampleRate = 44_100.0
        let channels: AVAudioChannelCount = 1
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels)!
        let file = try AVAudioFile(
            forWriting: url,
            settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
                AVEncoderBitRateKey: 128_000
            ]
        )

        let frameCount = AVAudioFrameCount(sampleRate * seconds)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            channel[frame] = Float(sin(2 * Double.pi * 440 * time) * 0.2)
        }

        try file.write(from: buffer)
    }
}
