import Foundation
import SwiftUI

public enum AppSection: String, CaseIterable, Identifiable, Sendable {
    case dashboard
    case proxies
    case routing
    case profiles
    case requests
    case connections
    case resources
    case logs
    case settings

    public var id: String { rawValue }

    public var title: String {
        AppLanguage.english.text(titleKey)
    }

    public var titleKey: AppString {
        switch self {
        case .dashboard: .dashboard
        case .proxies: .proxies
        case .routing: .routing
        case .profiles: .profiles
        case .requests: .requests
        case .connections: .connections
        case .resources: .resources
        case .logs: .logs
        case .settings: .settings
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "square.grid.2x2.fill"
        case .proxies: "doc.text.fill"
        case .routing: "point.3.connected.trianglepath.dotted"
        case .profiles: "folder.fill"
        case .requests: "text.line.first.and.arrowtriangle.forward"
        case .connections: "list.bullet.rectangle.fill"
        case .resources: "server.rack"
        case .logs: "terminal.fill"
        case .settings: "wrench.and.screwdriver.fill"
        }
    }
}

enum CoreRestartIntent: Equatable, Sendable {
    case startController
    case restartController
    case restartActiveRuntime

    static func resolve(isStarted: Bool, isCoreRunning: Bool) -> Self {
        if isStarted {
            return .restartActiveRuntime
        }
        return isCoreRunning ? .restartController : .startController
    }
}

enum CoreStatusPresentation {
    static func runtimeText(isStarted: Bool, isCoreRunning: Bool) -> String {
        if isStarted {
            return "VPN Active"
        }
        return isCoreRunning ? "Controller Running" : "Stopped"
    }
}

public enum OutboundMode: String, CaseIterable, Identifiable, Sendable {
    case rule
    case global
    case direct

    public var id: Self { self }

    public var title: String {
        AppLanguage.english.text(titleKey)
    }

    public var titleKey: AppString {
        switch self {
        case .rule: .rule
        case .global: .global
        case .direct: .direct
        }
    }
}

public enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: Self { self }

    public var title: String {
        rawValue.capitalized
    }

    public func resolvedColorScheme(systemColorScheme: ColorScheme) -> ColorScheme {
        switch self {
        case .system: systemColorScheme
        case .light: .light
        case .dark: .dark
        }
    }
}

enum SettingsGroupKind: Hashable, Sendable {
    case appearance
    case language
    case about
}

enum SettingsPagePolicy {
    static let usesSinglePage = true
    static let showsSectionTabs = false
    static let groups: [SettingsGroupKind] = [
        .appearance,
        .language,
        .about,
    ]
}

public enum DashboardWidgetKind: String, CaseIterable, Identifiable, Sendable {
    case networkSpeed
    case systemProxyButton
    case tunButton
    case outboundMode
    case networkDetection
    case trafficUsage
    case intranetIp

    public var id: String { rawValue }

    public static let defaultOrder: [DashboardWidgetKind] = [
        .networkSpeed,
        .systemProxyButton,
        .tunButton,
        .outboundMode,
        .networkDetection,
        .trafficUsage,
        .intranetIp,
    ]
}

public enum ProfileValidationKind: String, Sendable {
    case notValidated
    case checking
    case valid
    case invalid
}

public struct ProfileValidationState: Equatable, Sendable {
    public let kind: ProfileValidationKind
    public let message: String?
    public let checkedAt: Date?

    public static let notValidated = ProfileValidationState(
        kind: .notValidated,
        message: nil,
        checkedAt: nil
    )

    public static let checking = ProfileValidationState(
        kind: .checking,
        message: nil,
        checkedAt: nil
    )

    public static func valid(checkedAt: Date = Date()) -> ProfileValidationState {
        ProfileValidationState(kind: .valid, message: nil, checkedAt: checkedAt)
    }

    public static func invalid(
        _ message: String,
        checkedAt: Date = Date()
    ) -> ProfileValidationState {
        ProfileValidationState(kind: .invalid, message: message, checkedAt: checkedAt)
    }

    public func title(language: AppLanguage) -> String {
        switch kind {
        case .notValidated:
            language.text(.notValidated)
        case .checking:
            language.text(.checking)
        case .valid:
            language.text(.valid)
        case .invalid:
            language.text(.invalid)
        }
    }

    public var symbol: String {
        switch kind {
        case .notValidated:
            "shield"
        case .checking:
            "arrow.triangle.2.circlepath"
        case .valid:
            "checkmark.shield.fill"
        case .invalid:
            "exclamationmark.triangle.fill"
        }
    }
}

enum ProfileHealthFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case needsFix
    case notChecked
    case valid

    var id: Self { self }

    func matches(_ state: ProfileValidationState) -> Bool {
        switch self {
        case .all:
            true
        case .needsFix:
            state.kind == .invalid
        case .notChecked:
            state.kind == .notValidated || state.kind == .checking
        case .valid:
            state.kind == .valid
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .all:
            language.text(.allProfiles)
        case .needsFix:
            language.text(.invalid)
        case .notChecked:
            language.text(.notValidated)
        case .valid:
            language.text(.valid)
        }
    }
}

enum LogLevelFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case errors
    case warnings
    case info
    case debug

    var id: Self { self }

    func matches(_ level: String) -> Bool {
        let normalized = level.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return switch self {
        case .all:
            true
        case .errors:
            normalized == "error" || normalized == "fatal"
        case .warnings:
            normalized == "warning" || normalized == "warn"
        case .info:
            normalized == "info"
        case .debug:
            normalized == "debug"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .all: language.text(.allLogs)
        case .errors: language.text(.errors)
        case .warnings: language.text(.warnings)
        case .info: language.text(.info)
        case .debug: language.text(.debug)
        }
    }
}

enum ProxyGroupKind: String, Codable, Sendable {
    case selector
    case urlTest
    case fallback
    case loadBalance
    case unknown

    init(mihomoType: String?) {
        switch mihomoType?.lowercased() {
        case "selector":
            self = .selector
        case "urltest", "url-test":
            self = .urlTest
        case "fallback":
            self = .fallback
        case "loadbalance", "load-balance":
            self = .loadBalance
        default:
            self = .unknown
        }
    }

    var isAutomatic: Bool {
        switch self {
        case .urlTest, .fallback, .loadBalance:
            true
        case .selector, .unknown:
            false
        }
    }
}

struct ProxyNode: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let region: String
    var latency: Int?
    var isSelected: Bool
    var isGroup: Bool = false
}

enum ProxyNodeFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case selected
    case untested
    case slow

    static let slowLatencyThreshold = 350

    var id: Self { self }

    func matches(_ node: ProxyNode) -> Bool {
        return switch self {
        case .all:
            true
        case .selected:
            node.isSelected
        case .untested:
            node.latency == nil && !node.isGroup && isConcrete(node)
        case .slow:
            (node.latency ?? 0) >= Self.slowLatencyThreshold && !node.isGroup
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .all: language.text(.allNodes)
        case .selected: language.text(.selectedOnly)
        case .untested: language.text(.untested)
        case .slow: language.text(.slowNodes)
        }
    }

    private func isConcrete(_ node: ProxyNode) -> Bool {
        !["DIRECT", "REJECT", "PASS", "COMPATIBLE"].contains(node.name.uppercased())
    }
}

struct ProxyGroup: Identifiable {
    var id: String { name }
    let name: String
    let policy: String
    var kind: ProxyGroupKind = .unknown
    var testURL: String? = nil
    var nodes: [ProxyNode]
}

struct ProxyGroupExpansionState: Equatable, Sendable {
    private var collapsedGroupNames: Set<String> = []

    func isExpanded(_ groupName: String) -> Bool {
        !collapsedGroupNames.contains(groupName)
    }

    mutating func toggle(_ groupName: String) {
        if collapsedGroupNames.contains(groupName) {
            collapsedGroupNames.remove(groupName)
        } else {
            collapsedGroupNames.insert(groupName)
        }
    }
}

enum MenuBarQuickAccessPolicy {
    static let selectorName = "Mutdot"
    static let visibleConnectionControlCount = 1
    static let showsSystemProxyToggle = false
    static let showsTunToggle = false
    static let showsOpenMainWindowButton = false
    static let clipsNodeViewport = true

    static let panelWidth: CGFloat = 360
    static let outerPadding: CGFloat = 12
    static let topInset = outerPadding
    static let bottomInset = outerPadding
    static let sectionSpacing: CGFloat = 10
    static let headerHeight: CGFloat = 66
    static let mainControlHeight: CGFloat = 72
    static let nodeHeaderHeight: CGFloat = 20
    static let nodeHeaderSpacing: CGFloat = 8
    static let nodeViewportHeight: CGFloat = 244

    static var requiredContentHeight: CGFloat {
        topInset
            + bottomInset
            + (sectionSpacing * 2)
            + headerHeight
            + mainControlHeight
            + nodeHeaderHeight
            + nodeHeaderSpacing
            + nodeViewportHeight
    }

    static var panelHeight: CGFloat {
        requiredContentHeight
    }
}

public enum MenuBarPanelMotion {
    public static let usesCustomWindowAnimator = true
    public static let usesCustomContentFade = false
    public static let startsWindowTransparent = true
    public static let fadeInDuration: TimeInterval = 0.30
    public static let fadeOutDuration: TimeInterval = 0.24
}

enum InterfaceCopy {
    static let vpn = "VPN"
    static let systemProxy = "System Proxy"
    static let networkSpeed = "Network Speed"
    static let networkDetection = "Network Detection"
    static let outboundMode = "Outbound Mode"
    static let trafficUsage = "Traffic Usage"
    static let intranetIP = "Intranet IP"

    static let multiwordTitles = [
        systemProxy,
        networkSpeed,
        networkDetection,
        outboundMode,
        trafficUsage,
        intranetIP,
        "Core Status",
        "Dashboard Settings",
        "Search Proxies",
        "Search Routing",
        "Search Profiles",
        "Search Requests",
        "Search Connections",
        "Search Resources",
        "Search Logs",
        "Validate All",
        "Open Managed Folder",
        "Close All",
        "Open Folder",
        "Open Logs",
        "Selected Profile",
        "Runtime Config",
        "Managed Profiles",
        "Network Service",
        "Color Scheme",
        "Reduce Motion",
        "Mihomo Process",
        "Last Error",
        "Validate Profiles",
        "Refresh Runtime",
        "Open Logs Page",
    ]
}

struct ConnectionEntry: Identifiable {
    let id = UUID()
    var remoteID: String? = nil
    let host: String
    let rule: String
    let chain: String
    let upload: String
    let download: String
}

struct LogEntry: Identifiable {
    let id = UUID()
    let level: String
    let message: String
    let time: String
    let tint: Color
}
