import SwiftUI

struct LogsView: View {
    @Bindable var store: AppStore
    @State private var query = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FeaturePage(
            searchText: $query,
            placeholder: "\(store.text(.search)) \(store.text(.logs))",
            actions: [
                .init(title: store.text(.clear), symbol: "trash") {
                    store.clearLogs()
                },
                .init(title: store.text(.export), symbol: "square.and.arrow.up") {
                    do {
                        try ConfigurationFilePanel.saveLogs(store.exportedLogs)
                    } catch {
                        store.lastErrorMessage = error.localizedDescription
                    }
                },
            ]
        ) {
            let filtered = filteredLogs
            if filtered.isEmpty {
                EmptyGlassState(title: store.text(.noLogs), symbol: "terminal")
            } else {
                GlassCard(radius: 16, padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(filtered) { entry in
                            LogRow(entry: entry)
                            if entry.id != filtered.last?.id {
                                Divider().padding(.leading, 96).opacity(0.12)
                            }
                        }
                    }
                }
            }
        }
    }

    private var filteredLogs: [LogEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return store.logs
        }
        return store.logs.filter {
            $0.message.localizedCaseInsensitiveContains(trimmed)
            || $0.level.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

private struct LogRow: View {
    let entry: LogEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(entry.time)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(palette.tertiaryText)
                .frame(width: 72, alignment: .leading)
            StatusChip(text: entry.level, symbol: nil, tint: entry.tint)
                .frame(width: 58, alignment: .leading)
            Text(entry.message)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}
