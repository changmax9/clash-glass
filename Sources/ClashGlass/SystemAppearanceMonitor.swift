import AppKit
import Observation
import SwiftUI

@Observable
@MainActor
final class SystemAppearanceMonitor {
    private(set) var colorScheme: ColorScheme
    private var observation: NSKeyValueObservation?

    init(application: NSApplication = .shared) {
        colorScheme = Self.colorScheme(for: application.effectiveAppearance)
        observation = application.observe(
            \.effectiveAppearance,
            options: [.initial, .new]
        ) { [weak self] application, _ in
            Task { @MainActor in
                self?.colorScheme = Self.colorScheme(
                    for: application.effectiveAppearance
                )
            }
        }
    }

    private static func colorScheme(for appearance: NSAppearance) -> ColorScheme {
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? .dark
            : .light
    }
}
