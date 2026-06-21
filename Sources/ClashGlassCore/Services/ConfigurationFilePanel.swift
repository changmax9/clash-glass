import AppKit
import UniformTypeIdentifiers

@MainActor
enum ConfigurationFilePanel {
    static func chooseYAML() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Import Mihomo Configuration"
        panel.prompt = "Import"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "yaml")!,
            UTType(filenameExtension: "yml")!,
        ]
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func saveLogs(_ content: String) throws {
        let panel = NSSavePanel()
        panel.title = "Export Clash Glass Logs"
        panel.nameFieldStringValue = "clash-glass.log"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}
