import SwiftUI

struct RequestsView: View {
    @Bindable var store: AppStore
    @State private var query = ""
    @State private var autoScroll = true

    private var requests: [ConnectionEntry] {
        store.connections
    }

    var body: some View {
        FeaturePage(
            searchText: $query,
            placeholder: "Search Requests",
            actions: [
                .init(title: autoScroll ? "Stop Auto Scroll" : "Scroll to Top", symbol: autoScroll ? "nosign" : "arrow.up.to.line") {
                    autoScroll.toggle()
                },
            ]
        ) {
            let filtered = filteredRequests
            if filtered.isEmpty {
                EmptyGlassState(title: "No Requests", symbol: "text.line.first.and.arrowtriangle.forward")
            } else {
                GlassCard(radius: 16, padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(filtered) { request in
                            ConnectionRow(connection: request, showsBlock: false)
                            if request.id != filtered.last?.id {
                                Divider().padding(.leading, 16).opacity(0.12)
                            }
                        }
                    }
                }
            }
        }
    }

    private var filteredRequests: [ConnectionEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return requests
        }
        return requests.filter {
            $0.host.localizedCaseInsensitiveContains(trimmed)
            || $0.rule.localizedCaseInsensitiveContains(trimmed)
            || $0.chain.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

struct ResourcesView: View {
    @Bindable var store: AppStore

    var body: some View {
        FeaturePage(
            placeholder: "Search Resources",
            actions: [
                .init(title: "Reload", symbol: "arrow.clockwise") {
                    Task { await store.refreshRuntimeData() }
                },
                .init(title: "Open Folder", symbol: "folder") {
                    ConfigurationFilePanel.reveal(store.managedProfilesFolderURL)
                },
            ]
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                ResourceCard(title: "GEOIP", detail: "Country Database", status: "Ready", symbol: "globe.asia.australia.fill")
                ResourceCard(title: "GEOSITE", detail: "Domain Rule Database", status: "Ready", symbol: "list.bullet.rectangle")
                ResourceCard(title: "ASN", detail: "Autonomous System Database", status: "Ready", symbol: "network")
                ResourceCard(title: "MMDB", detail: "Metadata Database", status: "Ready", symbol: "externaldrive.fill")
            }
        }
    }
}

struct ToolsView: View {
    @Bindable var store: AppStore

    var body: some View {
        FeaturePage(
            placeholder: "Search Tools",
            actions: [
                .init(title: "Open Logs", symbol: "terminal") {
                    store.selectedSection = .logs
                },
            ]
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                ToolCard(title: "Core", detail: store.isCoreRunning ? "Connected" : "Stopped", symbol: "cpu.fill", tint: store.isCoreRunning ? .green : .secondary) {
                    Task {
                        await store.toggleRuntime(configPath: store.configPath)
                    }
                }
                ToolCard(title: InterfaceCopy.systemProxy, detail: store.isSystemProxyEnabled ? "Enabled" : "Disabled", symbol: "arrow.up.left.and.arrow.down.right", tint: store.isSystemProxyEnabled ? .green : .secondary) {
                    Task {
                        await store.toggleSystemProxy()
                    }
                }
                ToolCard(title: "TUN", detail: store.isTunEnabled ? "Enabled" : "Disabled", symbol: "waveform.path.ecg", tint: store.isTunEnabled ? .green : .secondary) {
                    Task {
                        await store.setTunEnabled(!store.isTunEnabled)
                    }
                }
                ToolCard(title: "Configuration", detail: store.configPath, symbol: "doc.badge.gearshape.fill", tint: .secondary) {
                    ConfigurationFilePanel.reveal(URL(fileURLWithPath: store.configPath))
                }
            }
        }
    }
}

private struct ResourceCard: View {
    let title: String
    let detail: String
    let status: String
    let symbol: String

    var body: some View {
        GlassCard(radius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    StatusChip(text: status, symbol: "checkmark", tint: .green)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(detail)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        }
    }
}

private struct ToolCard: View {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCard(radius: 16, padding: 16) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(tint)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text(detail)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
