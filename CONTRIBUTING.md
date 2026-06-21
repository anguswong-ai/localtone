# Contributing to LocalTone

Thanks for taking the time to improve LocalTone.

## Ground Rules

- Keep the app local-only.
- Do not add analytics, telemetry, backend services, login, ads, subscriptions, or paid feature gates.
- Prefer simple, native macOS UI and AVFoundation APIs.
- Keep export behavior predictable: AAC `.m4r`, maximum 30 seconds.

## Development

Build the app:

```sh
swift build
```

Run the app:

```sh
swift run LocalTone
```

Run tests:

```sh
swift test
```

## Pull Requests

Please include:

- A short description of the change
- Any user-facing behavior changes
- Test coverage for success and failure paths where feasible
- Manual verification notes for audio export or UI changes
