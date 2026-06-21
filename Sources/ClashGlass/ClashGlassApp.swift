import AppKit
import ClashGlassCore
import SwiftUI

@main
struct ClashGlassApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup("Clash Glass", id: "main") {
            ContentView(store: store)
                .preferredColorScheme(store.appearanceMode.colorScheme)
                .task {
                    appDelegate.store = store
                    if let section = ProcessInfo.processInfo.environment["CLASH_GLASS_SECTION"],
                       let selected = AppSection(rawValue: section) {
                        store.selectedSection = selected
                    }
                }
                .frame(minWidth: 760, minHeight: 540)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 980, height: 720)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowActivationAttempts = 0
    private var menuBarPanelController: MenuBarPanelController?
    var store: AppStore? {
        didSet {
            guard menuBarPanelController == nil, let store else {
                return
            }
            menuBarPanelController = MenuBarPanelController(store: store)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        configureWindowsWhenReady()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.shutdownForApplicationTermination()
    }

    private func configureWindowsWhenReady() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            let windows = NSApp.windows.filter { window in
                window.canBecomeKey && !(window is NSPanel)
            }

            guard !windows.isEmpty else {
                windowActivationAttempts += 1
                if windowActivationAttempts < 20 {
                    configureWindowsWhenReady()
                }
                return
            }

            for window in windows {
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.titleVisibility = .hidden
                window.toolbarStyle = .unifiedCompact
                window.backgroundColor = NSColor(name: nil) { appearance in
                    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                        ? NSColor(red: 0.08, green: 0.07, blue: 0.07, alpha: 1)
                        : NSColor(red: 1.00, green: 0.97, blue: 0.97, alpha: 1)
                }
                window.collectionBehavior.insert(.moveToActiveSpace)
                window.orderFrontRegardless()
                window.makeKeyAndOrderFront(nil)
            }
            NSRunningApplication.current.activate(options: .activateAllWindows)
        }
    }
}
