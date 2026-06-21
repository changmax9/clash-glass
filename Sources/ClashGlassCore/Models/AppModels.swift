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
    case tools
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .proxies: "Proxies"
        case .routing: "Routing"
        case .profiles: "Profiles"
        case .requests: "Requests"
        case .connections: "Connections"
        case .resources: "Resources"
        case .logs: "Logs"
        case .tools: "Tools"
        case .settings: "Settings"
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
        case .tools: "wrench.and.screwdriver.fill"
        case .settings: "gearshape"
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
        switch self {
        case .rule: "Rule"
        case .global: "Global"
        case .direct: "Direct"
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

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
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
        "Search Tools",
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
