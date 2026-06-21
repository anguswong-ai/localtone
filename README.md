# LocalTone

LocalTone is a local-only macOS ringtone maker. Drop in an audio or video file, choose a start point and duration, optionally add fades, and export an `.m4r` AAC ringtone that is capped at 30 seconds.

<img width="1012" height="664" alt="Screenshot 2026-06-21 at 23 29 52" src="https://github.com/user-attachments/assets/28ff862d-bbe0-4f2f-b78d-a089d92e8911" />


## Features

- SwiftUI macOS interface
- Drag-and-drop and file picker import
- Supports `.m4a`, `.mp4`, `.aac`, and `.m4r` input files
- Exports AAC audio in an `.m4r` file
- Trims by start time and duration
- Enforces the 30-second ringtone limit
- Optional fade in and fade out
- Local-only: no analytics, backend, login, account system, ads, or paid features

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer
- Xcode (recommended) or Apple Command Line Tools

## Build and Run

Build and launch LocalTone as a proper macOS app bundle:

```sh
./build-app.sh
```

This compiles a release build, wraps it in a `LocalTone.app` bundle, and opens
it. Use this rather than `swift run LocalTone`: a bare executable launched with
`swift run` has no app bundle, and macOS will not give keyboard focus to the
text fields inside the system Save panel, so the ringtone name cannot be edited.
The `.app` bundle fixes that.

The built app is placed under `.build/<arch>/release/LocalTone.app`. You can drag
it into `/Applications` if you want a permanent copy you can double-click.

## Test

Running the test suite requires the full Xcode toolchain (the Command Line Tools
alone cannot link `XCTest`). If `swift test` reports `no such module 'XCTest'`,
point the toolchain at Xcode first:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Then run:

```sh
swift test
```

## Project Structure

```text
Sources/
  LocalTone/        SwiftUI macOS app
  LocalToneCore/    AVFoundation export and validation logic
Tests/
  LocalToneCoreTests/
```

## Privacy

LocalTone processes files entirely on your Mac. It does not send audio, metadata, usage data, crash data, or any other app data to a server.

## License

MIT. See [LICENSE](LICENSE).
