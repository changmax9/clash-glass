import Foundation

public struct AppChromeLayoutMetrics: Sendable {
    public let availableWidth: Double
    public let availableHeight: Double

    public init(availableWidth: Double, availableHeight: Double) {
        self.availableWidth = max(availableWidth, 1)
        self.availableHeight = max(availableHeight, 1)
    }

    public var railWidth: Double { 74 }
    public var topInset: Double { 16 }
    public var contentLeadingInset: Double { 28 }
    public var contentTrailingInset: Double { 24 }
    public var contentWidth: Double {
        max(1, availableWidth - railWidth)
    }

    public var stageWidth: Double {
        max(1, contentWidth - contentLeadingInset - contentTrailingInset)
    }

    public var stageHeight: Double {
        max(1, availableHeight - topInset)
    }

    public var usesWideDashboard: Bool {
        stageWidth >= 1_050
    }
}
