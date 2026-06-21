import SwiftUI

enum PageNavigationTransitionPolicy {
    static let appliesToEverySectionChange = true
    static let usesOpacityTransition = true
    static let respectsReducedMotion = true
    static let duration = 0.20

    static func animation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: duration)
    }
}

enum ProxiesToolbarPolicy {
    static let refreshIncludesLatencyTesting = true
    static let showsSeparateDelayTestAction = false
    static let actionTitles = [
        "Refresh",
        "Providers",
        "Settings",
    ]
}
