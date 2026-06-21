import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case core
    case network
    case appearance
    case diagnostics

    var id: Self { self }
    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .core: "cpu"
        case .network: "network"
        case .appearance: "paintbrush"
        case .diagnostics: "stethoscope"
        }
    }
}

public struct AppSettingsView: View {
    @Bindable private var store: AppStore
    @State private var section: SettingsSection = .general
    @Environment(\.colorScheme) private var colorScheme

    public init(store: AppStore) {
        self.store = store
    }

    public var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Clash Glass")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                ForEach(SettingsSection.allCases) { item in
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
                            section = item
                        }
                    } label: {
                        Label(item.title, systemImage: item.symbol)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                    }
                    .buttonStyle(LiquidGlassButtonStyle(
                        radius: 11,
                        tint: section == item ? palette.rose.opacity(0.24) : nil
                    ))
                }

                Spacer()

                HStack(spacing: 8) {
                    StatusDot(isOn: store.isCoreRunning)
                    Text(store.isCoreRunning ? "Core Running" : "Core Stopped")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }
            .frame(width: 170)
            .padding(14)

            Divider().opacity(0.12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SettingsHeader(section: section)
                    settingsContent
                }
                .padding(PageSurfaceMetrics.horizontalInset)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(palette.primaryText)
        .background(palette.background)
    }

    @ViewBuilder
    private var settingsContent: some View {
        switch section {
        case .general:
            generalSettings
        case .core:
            coreSettings
        case .network:
            networkSettings
        case .appearance:
            appearanceSettings
        case .diagnostics:
            diagnosticsSettings
        }
    }

    private var generalSettings: some View {
        SettingsGroup(title: "Runtime", symbol: "play.circle") {
            SettingsValueRow(title: "Selected Profile", value: store.selectedManagedProfile?.name ?? "No Profile")
            SettingsValueRow(title: "Status", value: runtimeStatus)
            SettingsValueRow(title: "Uptime", value: store.runTimeText)
            SettingsCommandRow(
                title: store.isStarted ? "Stop VPN" : "Start VPN",
                detail: store.isStarted
                    ? "Disable system proxying and stop the active Mihomo session."
                    : "Start the selected profile and enable system proxying.",
                actionTitle: store.isStarted ? "Stop" : "Start",
                symbol: store.isStarted ? "stop.fill" : "play.fill"
            ) {
                Task { await store.toggleRuntime(configPath: store.configPath) }
            }
        }
    }

    private var coreSettings: some View {
        VStack(spacing: 14) {
            SettingsGroup(title: "Managed Configuration", symbol: "doc.badge.gearshape") {
                SettingsValueRow(title: "Runtime Config", value: store.configPath)
                SettingsValueRow(title: "Controller", value: store.controllerURL.absoluteString)
                SettingsValueRow(title: "Core", value: coreStatus)
                SettingsCommandRow(
                    title: "Import Configuration",
                    detail: "Copy and validate a YAML file into Clash Glass.",
                    actionTitle: "Import",
                    symbol: "square.and.arrow.down"
                ) {
                    guard let url = ConfigurationFilePanel.chooseYAML() else { return }
                    Task { await store.importManagedProfile(from: url) }
                }
                SettingsCommandRow(
                    title: "Managed Profiles",
                    detail: store.managedProfilesFolderURL.path,
                    actionTitle: "Reveal",
                    symbol: "folder"
                ) {
                    ConfigurationFilePanel.reveal(store.managedProfilesFolderURL)
                }
            }
        }
    }

    private var networkSettings: some View {
        VStack(spacing: 14) {
            SettingsGroup(title: "Proxy", symbol: "arrow.up.left.and.arrow.down.right") {
                SettingsTextRow(title: "Network Service", value: $store.networkService)
                SettingsTextRow(title: "Host", value: $store.proxyHost)
                SettingsNumberRow(title: "HTTP / Mixed Port", value: $store.httpPort)
                SettingsNumberRow(title: "SOCKS Port", value: $store.socksPort)
                SettingsToggleRow(title: InterfaceCopy.systemProxy, detail: "Apply macOS proxy settings to the selected service.", isOn: store.isSystemProxyEnabled) {
                    Task { await store.toggleSystemProxy(service: store.networkService) }
                }
                SettingsToggleRow(title: "TUN", detail: "Route traffic through Mihomo's TUN stack.", isOn: store.isTunEnabled) {
                    Task { await store.setTunEnabled(!store.isTunEnabled) }
                }
            }

            SettingsGroup(title: "Outbound Mode", symbol: "arrow.triangle.branch") {
                HStack {
                    Text("Mode")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Spacer()
                    PillSegment(values: OutboundMode.allCases, selection: modeBinding) { $0.title }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
            }
        }
    }

    private var appearanceSettings: some View {
        SettingsGroup(title: "Appearance", symbol: "paintbrush") {
            HStack {
                Text("Color Scheme")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer()
                PillSegment(values: AppAppearance.allCases, selection: $store.appearanceMode) { $0.title }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            SettingsToggleRow(
                title: "Reduce Motion",
                detail: "Keep glass feedback without scaling and morph movement.",
                isOn: store.reduceMotion
            ) {
                store.reduceMotion.toggle()
            }
        }
    }

    private var diagnosticsSettings: some View {
        SettingsGroup(title: "Diagnostics", symbol: "stethoscope") {
            SettingsValueRow(title: "Mihomo Process", value: store.isCoreRunning ? "Running" : "Stopped")
            SettingsValueRow(title: "Controller", value: store.controllerURL.absoluteString)
            SettingsValueRow(title: "Last Error", value: store.lastErrorMessage ?? "None")
            SettingsCommandRow(
                title: "Validate Profiles",
                detail: "Run Mihomo validation against every managed configuration.",
                actionTitle: "Validate",
                symbol: "checkmark.shield"
            ) {
                Task { await store.validateAllManagedProfiles() }
            }
            SettingsCommandRow(
                title: "Refresh Runtime",
                detail: "Reload configs, proxies, traffic, connections, and logs.",
                actionTitle: "Refresh",
                symbol: "arrow.clockwise"
            ) {
                Task {
                    await store.refreshRuntimeConfiguration()
                    await store.refreshRuntimeData()
                }
            }
            SettingsCommandRow(
                title: "Open Logs Page",
                detail: "Inspect the live Mihomo log stream in the main window.",
                actionTitle: "Open",
                symbol: "terminal"
            ) {
                store.selectedSection = .logs
            }
        }
    }

    private var modeBinding: Binding<OutboundMode> {
        Binding(
            get: { store.selectedMode },
            set: { mode in Task { await store.setOutboundMode(mode) } }
        )
    }

    private var runtimeStatus: String {
        CoreStatusPresentation.runtimeText(
            isStarted: store.isStarted,
            isCoreRunning: store.isCoreRunning
        )
    }

    private var coreStatus: String {
        switch store.coreStatus {
        case .stopped: "Stopped"
        case .starting: "Starting"
        case .running: "Running"
        case .missingCoreBinary: "Missing Core"
        case let .failed(message): "Failed: \(message)"
        }
    }
}

private struct SettingsHeader: View {
    let section: SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.title)
                .font(.system(size: 23, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        switch section {
        case .general: "Control the active Clash Glass session."
        case .core: "Manage validated YAML configurations and Mihomo."
        case .network: "Configure proxy routing and outbound behavior."
        case .appearance: "Tune the native Liquid Glass experience."
        case .diagnostics: "Inspect and troubleshoot the runtime."
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        GlassCard(radius: 16, padding: 0) {
            VStack(spacing: 0) {
                Label(title, systemImage: symbol)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                Divider().opacity(0.12)
                content
            }
        }
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

private struct SettingsTextRow: View {
    let title: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer()
            TextField(title, text: $value)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .frame(width: 220)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

private struct SettingsNumberRow: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer()
            TextField(title, value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(width: 100)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let detail: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            LiquidToggle(isOn: isOn, action: action)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

private struct SettingsCommandRow: View {
    let title: String
    let detail: String
    let actionTitle: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            LiquidActionButton(title: actionTitle, symbol: symbol, compact: true, action: action)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}
