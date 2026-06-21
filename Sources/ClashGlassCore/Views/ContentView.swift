import SwiftUI

public struct ContentView: View {
    @Bindable private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    public init(store: AppStore) {
        self.store = store
    }

    public var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        GeometryReader { geometry in
            let layout = AppChromeLayoutMetrics(
                availableWidth: Double(geometry.size.width),
                availableHeight: Double(geometry.size.height)
            )

            ZStack {
                palette.background.ignoresSafeArea()

                HStack(spacing: 0) {
                    IconRail(store: store)
                        .frame(width: CGFloat(layout.railWidth))
                        .background(palette.background)
                        .zIndex(RailSurfaceMetrics.railZIndex)

                    MainStage(store: store, layout: layout)
                        .zIndex(RailSurfaceMetrics.stageZIndex)
                }
            }
        }
        .foregroundStyle(palette.primaryText)
        .containerBackground(palette.background, for: .window)
        .alert(
            "Clash Glass",
            isPresented: Binding(
                get: { store.lastErrorMessage != nil },
                set: { if !$0 { store.lastErrorMessage = nil } }
            )
        ) {
            Button("OK") {
                store.lastErrorMessage = nil
            }
        } message: {
            Text(store.lastErrorMessage ?? "")
        }
        .task {
            await store.refreshNetworkIdentity()
            while !Task.isCancelled {
                await store.runtimeTick()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
}

private struct IconRail: View {
    @Bindable var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNamespace
    @State private var hoverState = RailHoverState()

    private let primarySections: [AppSection] = [
        .dashboard,
        .proxies,
        .routing,
        .profiles,
        .requests,
        .connections,
        .settings,
    ]

    var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        let selectedRailItem = RailSelectionResolver.item(for: store.selectedSection)
        VStack(spacing: 4) {
            ForEach(primarySections) { section in
                let item = RailItem.section(section)
                let presentation = RailItemPresentation(
                    item: item,
                    selectedSection: store.selectedSection,
                    hoveredItem: hoverState.hoveredItem,
                    reduceMotion: reduceMotion
                )

                Button {
                    store.selectedSection = section
                } label: {
                    ZStack {
                        Color.clear
                            .frame(
                                width: CGFloat(RailHitTargetMetrics.width),
                                height: CGFloat(RailHitTargetMetrics.height)
                            )

                        Image(systemName: section.symbol)
                            .font(.system(size: 17, weight: .bold))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(
                                presentation.isHovered
                                    ? palette.primaryText
                                    : palette.secondaryText
                            )
                            .frame(width: 54, height: 30)
                            .background {
                                if presentation.showsSelectionBackground {
                                    railSelection(palette: palette)
                                        .matchedGeometryEffect(
                                            id: "rail-selection",
                                            in: selectionNamespace
                                        )
                                }
                            }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .scaleEffect(presentation.scale)
                .offset(y: presentation.verticalOffset)
                .brightness(presentation.brightness)
                .shadow(color: .black.opacity(presentation.shadowOpacity), radius: 10, y: 5)
                .onHover { hovering in
                    hoverState.update(item: item, isHovering: hovering)
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.72), value: presentation.isHovered)
                .help(store.text(section.titleKey))
            }

            Spacer()
        }
        .padding(.top, 46)
        .animation(
            RailSelectionMotion.animation(reduceMotion: reduceMotion),
            value: selectedRailItem
        )
    }

    @ViewBuilder
    private func railSelection(palette: GlassPalette) -> some View {
        Capsule(style: .continuous)
            .fill(palette.railSelection)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(palette.selectionStroke.opacity(0.52), lineWidth: 0.8)
            }
            .shadow(
                color: palette.shadow.opacity(0.10),
                radius: RailSurfaceMetrics.selectionShadowRadius,
                y: 3
            )
    }
}

private struct MainStage: View {
    @Bindable var store: AppStore
    let layout: AppChromeLayoutMetrics
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsCoreRestartConfirmation = false
    @State private var showsProfileRename = false
    @State private var renameProfileID: ManagedProfile.ID?
    @State private var renameDraft = ""

    var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .center) {
                ZStack(alignment: .leading) {
                    Text(store.text(store.selectedSection.titleKey))
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                        .lineLimit(1)
                        .id(store.selectedSection)
                        .transition(.opacity)
                }
                .animation(
                    PageNavigationTransitionPolicy.animation(reduceMotion: reduceMotion),
                    value: store.selectedSection
                )

                Spacer()

                HStack(spacing: 18) {
                    CoreStatusToolbarButton(
                        symbol: coreStatusSymbol,
                        isRunning: store.isCoreRunning,
                        accessibilityTitle: store.text(.coreStatus)
                    ) {
                        showsCoreRestartConfirmation = true
                    }

                    ZStack {
                        ToolbarMenuIconSurface(
                            symbol: ToolbarControlAppearancePolicy.quickEditSymbol
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)

                        AppKitMenuButton(entries: [
                            .item(
                                store.text(.renameProfile),
                                symbol: "pencil",
                                isEnabled: store.selectedManagedProfile != nil
                            ) {
                                beginRenamingSelectedProfile()
                            },
                            .item(
                                store.text(.validate),
                                symbol: "checkmark.shield",
                                isEnabled: store.selectedManagedProfile != nil
                            ) {
                                guard let profileID = store.selectedManagedProfileID else {
                                    return
                                }
                                Task {
                                    await store.validateManagedProfile(profileID)
                                }
                            },
                            .item(
                                store.text(.revealInFinder),
                                symbol: "folder",
                                isEnabled: store.selectedManagedProfile != nil
                            ) {
                                guard let profile = store.selectedManagedProfile else {
                                    return
                                }
                                ConfigurationFilePanel.reveal(profile.managedConfigURL)
                            },
                            .separator,
                            .item(
                                store.text(.routing),
                                symbol: "point.3.connected.trianglepath.dotted"
                            ) {
                                store.selectedSection = .routing
                            },
                            .item(
                                store.text(.profiles),
                                symbol: "folder.fill"
                            ) {
                                store.selectedSection = .profiles
                            },
                        ], accessibilityTitle: store.text(.quickEdit))
                        .frame(
                            width: CGFloat(ToolbarControlMetrics.hitTarget),
                            height: CGFloat(ToolbarControlMetrics.hitTarget)
                        )
                    }
                    .frame(
                        width: CGFloat(ToolbarControlMetrics.hitTarget),
                        height: CGFloat(ToolbarControlMetrics.hitTarget)
                    )
                    .help(store.text(.quickEdit))
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(store.text(.quickEdit))
                }
            }
            .frame(width: CGFloat(layout.stageWidth), height: 36)

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    selectedSectionContent
                        .id(store.selectedSection)
                        .transition(.opacity)
                }
                .frame(width: CGFloat(layout.stageWidth), height: CGFloat(layout.stageHeight - 64), alignment: .topLeading)
                .animation(
                    PageNavigationTransitionPolicy.animation(reduceMotion: reduceMotion),
                    value: store.selectedSection
                )

                StartFloatingButton(store: store)
                    .padding(.trailing, 28)
                    .padding(.bottom, 28)
            }
            .frame(width: CGFloat(layout.stageWidth), height: CGFloat(layout.stageHeight - 64), alignment: .topLeading)

            Spacer(minLength: 0)
        }
        .padding(.top, CGFloat(layout.topInset))
        .padding(.leading, CGFloat(layout.contentLeadingInset))
        .padding(.trailing, CGFloat(layout.contentTrailingInset))
        .confirmationDialog(
            store.isCoreRunning ? store.text(.restartCore) : store.text(.startCore),
            isPresented: $showsCoreRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button(store.isCoreRunning ? store.text(.restartCore) : store.text(.startCore)) {
                Task {
                    await store.restartCore()
                }
            }
            Button(store.text(.cancel), role: .cancel) {}
        } message: {
            Text(coreRestartMessage)
        }
        .alert(store.text(.renameProfile), isPresented: $showsProfileRename) {
            TextField(store.text(.profileName), text: $renameDraft)
            Button(store.text(.cancel), role: .cancel) {
                renameProfileID = nil
            }
            Button(store.text(.rename)) {
                guard let renameProfileID else { return }
                store.renameManagedProfile(renameProfileID, to: renameDraft)
                self.renameProfileID = nil
            }
        } message: {
            Text("This name is also shown in the menu bar panel.")
        }
    }

    @ViewBuilder
    private var selectedSectionContent: some View {
        switch store.selectedSection {
        case .dashboard:
            DashboardView(store: store, availableWidth: layout.stageWidth)
        case .proxies:
            ProxiesView(store: store)
        case .routing:
            RoutingView(store: store)
        case .profiles:
            ProfilesView(store: store)
        case .requests:
            RequestsView(store: store)
        case .connections:
            ConnectionsView(store: store)
        case .resources:
            ResourcesView(store: store)
        case .logs:
            LogsView(store: store)
        case .settings:
            AppSettingsView(store: store)
        }
    }

    private var coreStatusSymbol: String {
        store.isCoreRunning
            ? ToolbarControlAppearancePolicy.runningCoreSymbol
            : ToolbarControlAppearancePolicy.stoppedCoreSymbol
    }

    private var coreRestartMessage: String {
        if store.isStarted {
            return "Mihomo and the active VPN session will restart, then restore the current outbound mode."
        }
        if store.isCoreRunning {
            return "Mihomo's controller-only session will restart without enabling the system VPN."
        }
        return "Mihomo is stopped. Confirm to start the core in controller-only mode."
    }

    private func beginRenamingSelectedProfile() {
        guard let profile = store.selectedManagedProfile else {
            return
        }
        renameProfileID = profile.id
        renameDraft = profile.name
        showsProfileRename = true
    }
}

private struct StartFloatingButton: View {
    @Bindable var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        Button {
            Task {
                await store.toggleRuntime(configPath: store.configPath)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: store.isStarted ? "pause.fill" : "play.fill")
                    .font(.system(size: store.isStarted ? 17 : 19, weight: .bold))
                    .frame(width: store.isStarted ? 18 : 20)

                if store.isStarted {
                    Text(store.runTimeText)
                        .font(.system(size: 17, weight: .semibold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                } else if store.coreStatus == .missingCoreBinary {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 14, weight: .black))
                        .frame(width: 10)
                }
            }
            .foregroundStyle(palette.brown)
            .frame(width: store.isStarted ? 146 : 56, height: 56)
        }
        .buttonStyle(LiquidGlassButtonStyle(
            radius: 17,
            tint: palette.rose.opacity(0.48),
            hoverScale: 1.075,
            pressedScale: 0.91
        ))
        .help(store.isStarted ? store.text(.pause) : store.text(.start))
        .animation(.spring(response: 0.36, dampingFraction: 0.72), value: store.isStarted)
        .animation(.spring(response: 0.36, dampingFraction: 0.72), value: store.coreStatus)
    }
}
