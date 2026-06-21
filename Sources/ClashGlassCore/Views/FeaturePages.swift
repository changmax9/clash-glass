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
            placeholder: "\(store.text(.search)) \(store.text(.requests))",
            actions: [
                .init(
                    title: autoScroll ? store.text(.stopAutoScroll) : store.text(.scrollToTop),
                    symbol: autoScroll ? "nosign" : "arrow.up.to.line"
                ) {
                    autoScroll.toggle()
                },
            ]
        ) {
            let filtered = filteredRequests
            if filtered.isEmpty {
                EmptyGlassState(title: store.text(.noRequests), symbol: "text.line.first.and.arrowtriangle.forward")
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
            placeholder: "\(store.text(.search)) \(store.text(.resources))",
            actions: [
                .init(title: store.text(.reload), symbol: "arrow.clockwise") {
                    Task { await store.refreshRuntimeData() }
                },
                .init(title: store.text(.openFolder), symbol: "folder") {
                    ConfigurationFilePanel.reveal(store.managedProfilesFolderURL)
                },
            ]
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                ResourceCard(title: "GEOIP", detail: store.text(.countryDatabase), status: store.text(.ready), symbol: "globe.asia.australia.fill")
                ResourceCard(title: "GEOSITE", detail: store.text(.domainRuleDatabase), status: store.text(.ready), symbol: "list.bullet.rectangle")
                ResourceCard(title: "ASN", detail: store.text(.autonomousSystemDatabase), status: store.text(.ready), symbol: "network")
                ResourceCard(title: "MMDB", detail: store.text(.metadataDatabase), status: store.text(.ready), symbol: "externaldrive.fill")
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
