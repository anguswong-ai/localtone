import AppKit
import LocalToneCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputURL: URL?
    @State private var outputURL: URL?
    @State private var startTime = 0.0
    @State private var duration = RingtoneExportOptions.maximumDuration
    @State private var fadeInDuration = 0.5
    @State private var fadeOutDuration = 1.0
    @State private var statusText = "Choose an audio or video file to begin."
    @State private var isTargeted = false
    @State private var isImporting = false
    @State private var isExporting = false

    private let exporter = RingtoneExporter()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                importPanel
                Divider()
                settingsPanel
            }
            Divider()
            footer
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: Self.allowedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("LocalTone")
                    .font(.system(size: 28, weight: .semibold))
                Text("Local ringtone export for macOS")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                isImporting = true
            } label: {
                Label("Choose File", systemImage: "folder")
            }
            .keyboardShortcut("o", modifiers: .command)
        }
        .padding(24)
    }

    private var importPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(isTargeted ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                                style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                            )
                    )
                VStack(spacing: 12) {
                    Image(systemName: "waveform.badge.plus")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text(inputURL?.lastPathComponent ?? "Drop .m4a, .mp4, .aac, or .m4r here")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    if let inputURL {
                        Text(inputURL.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(24)
            }
            .frame(minHeight: 250)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                loadDroppedFile(from: providers)
            }

            Text(statusText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 360)
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Export")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Start")
                    Spacer()
                    Text("\(startTime, specifier: "%.1f")s")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $startTime, in: 0...600, step: 0.1)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(duration, specifier: "%.1f")s")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $duration, in: 1...RingtoneExportOptions.maximumDuration, step: 0.1)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Fade In")
                    Spacer()
                    Text("\(fadeInDuration, specifier: "%.1f")s")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $fadeInDuration, in: 0...5, step: 0.1)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Fade Out")
                    Spacer()
                    Text("\(fadeOutDuration, specifier: "%.1f")s")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $fadeOutDuration, in: 0...5, step: 0.1)
            }

            Spacer()

            Button {
                presentSavePanelAndExport()
            } label: {
                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Export .m4r", systemImage: "square.and.arrow.down")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(inputURL == nil || isExporting)
        }
        .padding(24)
        .frame(minWidth: 340)
    }

    private var footer: some View {
        HStack {
            Image(systemName: "lock.shield")
                .foregroundStyle(.secondary)
            Text("Local-only. No analytics, backend, login, or paid features.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .font(.caption)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var defaultOutputBaseName: String {
        inputURL?.deletingPathExtension().lastPathComponent ?? "LocalTone"
    }

    private static var allowedContentTypes: [UTType] {
        [
            .mpeg4Audio,
            .mpeg4Movie,
            .audio,
            UTType(filenameExtension: "aac"),
            UTType(filenameExtension: "m4r")
        ].compactMap { $0 }
    }

    @MainActor
    private func presentSavePanelAndExport() {
        guard inputURL != nil else {
            statusText = "Choose an input file first."
            return
        }

        let panel = NSSavePanel()
        panel.title = "Export Ringtone"
        panel.prompt = "Export"
        panel.nameFieldLabel = "Ringtone name:"
        panel.nameFieldStringValue = "\(defaultOutputBaseName).\(SupportedAudioFile.outputExtension)"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        if let m4rType = UTType(filenameExtension: SupportedAudioFile.outputExtension) {
            panel.allowedContentTypes = [m4rType]
        }

        // Ensure the app is frontmost so the panel's name field can take keyboard focus.
        NSApplication.shared.activate(ignoringOtherApps: true)

        if panel.runModal() == .OK, let chosenURL = panel.url {
            let outputFileURL = SupportedAudioFile.normalizedOutputURL(for: chosenURL)
            outputURL = outputFileURL
            export(to: outputFileURL)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                return
            }
            try selectInputURL(url)
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func loadDroppedFile(from providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let error {
                Task { @MainActor in statusText = error.localizedDescription }
                return
            }

            let url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                url = item as? URL
            }

            Task { @MainActor in
                guard let url else {
                    statusText = "The dropped item was not a file URL."
                    return
                }
                do {
                    try selectInputURL(url)
                } catch {
                    statusText = error.localizedDescription
                }
            }
        }
        return true
    }

    private func selectInputURL(_ url: URL) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        try SupportedAudioFile.validateInputURL(url)
        inputURL = url
        outputURL = nil
        statusText = "Ready to export \(url.lastPathComponent)."
    }

    private func export(to url: URL) {
        guard let inputURL else {
            statusText = "Choose an input file first."
            return
        }

        let options = RingtoneExportOptions(
            startTime: startTime,
            duration: duration,
            fadeInDuration: fadeInDuration,
            fadeOutDuration: fadeOutDuration
        )

        isExporting = true
        statusText = "Exporting ringtone..."

        Task {
            do {
                let didAccessInput = inputURL.startAccessingSecurityScopedResource()
                let didAccessOutput = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccessInput {
                        inputURL.stopAccessingSecurityScopedResource()
                    }
                    if didAccessOutput {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let result = try await exporter.export(inputURL: inputURL, outputURL: url, options: options)
                await MainActor.run {
                    isExporting = false
                    outputURL = result.outputURL
                    statusText = "Exported \(result.outputURL.lastPathComponent)."
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    statusText = error.localizedDescription
                }
            }
        }
    }
}
