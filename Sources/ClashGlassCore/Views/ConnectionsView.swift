import SwiftUI

struct ConnectionsView: View {
    @Bindable var store: AppStore
    @State private var query = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FeaturePage(
            searchText: $query,
            placeholder: "Search Connections",
            actions: [
                .init(title: "Close All", symbol: "trash") {
                    Task {
                        await store.closeAllConnections()
                    }
                },
                .init(title: "Refresh", symbol: "arrow.clockwise") {
                    Task {
                        await store.refreshConnections()
                    }
                },
            ]
        ) {
            if filteredConnections.isEmpty {
                EmptyGlassState(title: "No Connections", symbol: "network.slash")
            } else {
                GlassCard(radius: 16, padding: 0) {
                    VStack(spacing: 0) {
                        ConnectionHeader()
                        Divider().opacity(0.16)
                        ForEach(filteredConnections) { connection in
                            ConnectionRow(connection: connection, showsBlock: true) {
                                Task {
                                    await store.closeConnection(connection)
                                }
                            }
                            if connection.id != filteredConnections.last?.id {
                                Divider().padding(.leading, 16).opacity(0.12)
                            }
                        }
                    }
                }
            }
        }
    }

    private var filteredConnections: [ConnectionEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return store.connections
        }
        return store.connections.filter {
            $0.host.localizedCaseInsensitiveContains(trimmed)
            || $0.rule.localizedCaseInsensitiveContains(trimmed)
            || $0.chain.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

private struct ConnectionHeader: View {
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                HeaderText("Host")
                HeaderText("Rule")
                HeaderText("Chain")
                HeaderText("Upload")
                HeaderText("Download")
                HeaderText("")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct ConnectionRow: View {
    let connection: ConnectionEntry
    let showsBlock: Bool
    var closeAction: (() -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                Text(connection.host)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                Text(connection.rule)
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(1)
                Text(connection.chain)
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(1)
                Text(connection.upload)
                    .monospacedDigit()
                    .lineLimit(1)
                Text(connection.download)
                    .monospacedDigit()
                    .lineLimit(1)
                if showsBlock {
                    LiquidIconButton(
                        title: "Close Connection",
                        symbol: "xmark",
                        tint: .red.opacity(0.14),
                        size: 24
                    ) {
                        closeAction?()
                    }
                }
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

private struct HeaderText: View {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    var body: some View {
        Text(value)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}
