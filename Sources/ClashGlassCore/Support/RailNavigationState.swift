import Foundation
import SwiftUI

enum RailSurfaceMetrics {
    static let usesSystemGlassSelection = false
    static let backgroundMatchesWindow = true
    static let railZIndex = 1.0
    static let stageZIndex = 0.0
    static let selectionShadowRadius = 8.0
    static let selectionTrailingClearance = 10.0
}

enum RailHitTargetMetrics {
    static let width = 74.0
    static let height = 48.0
}

enum RailItem: Equatable {
    case section(AppSection)
}

enum RailSelectionResolver {
    static func item(for section: AppSection) -> RailItem {
        switch section {
        case .dashboard:
            .section(.dashboard)
        case .proxies, .resources:
            .section(.proxies)
        case .routing:
            .section(.routing)
        case .profiles:
            .section(.profiles)
        case .requests:
            .section(.requests)
        case .connections:
            .section(.connections)
        case .logs, .settings:
            .section(.settings)
        }
    }
}

enum RailSelectionMotion {
    static let appliesToExternalSectionChanges = true
    static let usesMatchedGeometry = true
    static let respectsReducedMotion = true

    static func animation(reduceMotion: Bool) -> Animation? {
        reduceMotion
            ? nil
            : .spring(response: 0.42, dampingFraction: 0.80)
    }
}

struct RailHoverState {
    private(set) var hoveredItem: RailItem?

    mutating func update(item: RailItem, isHovering: Bool) {
        if isHovering {
            hoveredItem = item
        } else if hoveredItem == item {
            hoveredItem = nil
        }
    }
}

struct RailItemPresentation {
    let showsSelectionBackground: Bool
    let isHovered: Bool
    let scale: Double
    let verticalOffset: Double
    let brightness: Double
    let shadowOpacity: Double

    init(
        item: RailItem,
        selectedSection: AppSection,
        hoveredItem: RailItem?,
        reduceMotion: Bool
    ) {
        showsSelectionBackground = item == RailSelectionResolver.item(for: selectedSection)

        isHovered = hoveredItem == item
        scale = isHovered && !reduceMotion ? 1.08 : 1
        verticalOffset = isHovered && !reduceMotion ? -1.5 : 0
        brightness = isHovered ? 0.025 : 0
        shadowOpacity = isHovered && !reduceMotion ? 0.12 : 0
    }
}
