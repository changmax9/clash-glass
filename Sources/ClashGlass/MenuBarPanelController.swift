import AppKit
import ClashGlassCore
import Observation
import QuartzCore
import SwiftUI

@MainActor
final class MenuBarPanelController: NSObject {
    private let store: AppStore
    private let statusItem: NSStatusItem
    private let panel: MenuBarPanelWindow
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var fadeGeneration = 0

    init(store: AppStore) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        let rootView = MenuBarPanelRootView(store: store)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame.size = hostingView.fittingSize
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 22
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true

        panel = MenuBarPanelWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.animationBehavior = .none
        panel.collectionBehavior = [.transient, .moveToActiveSpace, .fullScreenAuxiliary]
        panel.alphaValue = 0

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePanel)
            button.toolTip = "Clash Glass"
        }

        updateStatusIcon()
        observeStore()
        installDismissMonitors()
    }

    @objc
    private func togglePanel() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else {
            return
        }

        fadeGeneration += 1
        let generation = fadeGeneration
        let statusFrame = buttonWindow.convertToScreen(button.frame)
        positionPanel(below: statusFrame)

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = MenuBarPanelMotion.fadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 1
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, generation == self.fadeGeneration else {
                    return
                }
                self.panel.alphaValue = 1
            }
        }
    }

    private func hide() {
        guard panel.isVisible else {
            return
        }

        fadeGeneration += 1
        let generation = fadeGeneration

        NSAnimationContext.runAnimationGroup { context in
            context.duration = MenuBarPanelMotion.fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, generation == self.fadeGeneration else {
                    return
                }
                self.panel.orderOut(nil)
                self.panel.alphaValue = 0
            }
        }
    }

    private func positionPanel(below statusFrame: NSRect) {
        let panelSize = panel.frame.size
        let screen = panel.screen
            ?? NSScreen.screens.first(where: { $0.frame.intersects(statusFrame) })
            ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? .zero
        let horizontalInset: CGFloat = 8
        let proposedX = statusFrame.midX - (panelSize.width / 2)
        let maximumX = visibleFrame.maxX - panelSize.width - horizontalInset
        let x = min(max(proposedX, visibleFrame.minX + horizontalInset), maximumX)
        let y = statusFrame.minY - panelSize.height - 6
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func installDismissMonitors() {
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self, self.panel.isVisible else {
                return event
            }
            if event.window === self.panel || event.window === self.statusItem.button?.window {
                return event
            }
            Task { @MainActor in
                self.hide()
            }
            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hide()
            }
        }
    }

    private func observeStore() {
        withObservationTracking {
            _ = store.isStarted
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }
                self.updateStatusIcon()
                self.observeStore()
            }
        }
    }

    private func updateStatusIcon() {
        let symbolName = store.isStarted ? "shield.lefthalf.filled" : "shield"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Clash Glass")
        image?.isTemplate = true
        statusItem.button?.image = image
    }
}

private final class MenuBarPanelWindow: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

private struct MenuBarPanelRootView: View {
    @Bindable var store: AppStore

    var body: some View {
        MenuBarPanelView(store: store)
            .preferredColorScheme(store.appearanceMode.colorScheme)
    }
}
