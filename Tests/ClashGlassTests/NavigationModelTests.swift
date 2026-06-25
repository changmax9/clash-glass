import Foundation
import Testing
@testable import ClashGlassCore

@Test func primaryApplicationSectionsStayInOrder() {
    #expect(AppSection.allCases.map(\.title) == [
        "Dashboard",
        "Proxies",
        "Routing",
        "Profiles",
        "Requests",
        "Connections",
        "Resources",
        "Logs",
        "Settings",
    ])
}

@Test func settingsUsesOnePageWithOnlyRequestedGroups() {
    #expect(SettingsPagePolicy.usesSinglePage)
    #expect(!SettingsPagePolicy.showsSectionTabs)
    #expect(SettingsPagePolicy.groups == [
        .appearance,
        .language,
        .about,
    ])
    #expect(ApplicationDisclaimer.purpose.contains("educational"))
    #expect(ApplicationDisclaimer.purpose.contains("research"))
    #expect(ApplicationDisclaimer.responsibility.contains("applicable laws"))
    #expect(ApplicationDisclaimer.liability.contains("provided \"as is\""))
    #expect(ApplicationDisclaimer.liability.contains("not liable"))
}

@Test func appSupportsRequestedInterfaceLanguages() {
    #expect(AppLanguage.selectableCases == [
        .system,
        .english,
        .simplifiedChinese,
        .traditionalChinese,
        .japanese,
        .french,
        .russian,
        .spanish,
        .portuguese,
    ])

    for language in AppLanguage.selectableCases where language != .system {
        #expect(!language.text(.settings).isEmpty)
        #expect(!language.text(.appearance).isEmpty)
        #expect(!language.text(.language).isEmpty)
        #expect(!language.text(.about).isEmpty)
        #expect(!language.text(.update).isEmpty)
        for key in AppString.allCases {
            #expect(
                AppLocalization.hasTranslation(key, language: language),
                "Missing \(key.rawValue) in \(language.rawValue)"
            )
        }
    }

    #expect(AppLanguage.simplifiedChinese.text(.settings) == "设置")
    #expect(AppLanguage.traditionalChinese.text(.settings) == "設定")
    #expect(AppLanguage.japanese.text(.settings) == "設定")
    #expect(AppLanguage.french.text(.settings) == "Réglages")
    #expect(AppLanguage.russian.text(.settings) == "Настройки")
    #expect(AppLanguage.spanish.text(.settings) == "Ajustes")
    #expect(AppLanguage.portuguese.text(.settings) == "Definições")
}

@Test func localizedDynamicInterfaceCopyCoversProxyRoutingAndAboutSurfaces() {
    let simplified = AppLanguage.simplifiedChinese
    let traditional = AppLanguage.traditionalChinese
    let japanese = AppLanguage.japanese

    #expect(simplified.text(.tab) == "标签")
    #expect(traditional.text(.list) == "列表")
    #expect(japanese.text(.selector) == "セレクター")
    #expect(simplified.localizedProxyType("Selector") == "选择器")
    #expect(traditional.localizedProxyType("Proxy") == "代理")
    #expect(simplified.profileStorageDetail(name: "Mutdot") == "配置：Mutdot · 独立保存，不修改原 YAML")
    #expect(traditional.ruleCount(1) == "1 條規則")
    #expect(traditional.ruleCount(2) == "2 條規則")
    #expect(simplified.text(.routingExplanation).contains("直连规则"))
    #expect(traditional.text(.poweredByMihomo) == "由 Mihomo 驅動")
}

@Test func profileHealthFilterMatchesValidationStates() {
    let valid = ProfileValidationState.valid()
    let invalid = ProfileValidationState.invalid("bad config")

    #expect(ProfileHealthFilter.all.matches(.notValidated))
    #expect(ProfileHealthFilter.all.matches(.checking))
    #expect(ProfileHealthFilter.all.matches(valid))
    #expect(ProfileHealthFilter.all.matches(invalid))

    #expect(ProfileHealthFilter.needsFix.matches(invalid))
    #expect(!ProfileHealthFilter.needsFix.matches(valid))
    #expect(ProfileHealthFilter.notChecked.matches(.notValidated))
    #expect(ProfileHealthFilter.notChecked.matches(.checking))
    #expect(!ProfileHealthFilter.notChecked.matches(valid))
    #expect(ProfileHealthFilter.valid.matches(valid))
    #expect(!ProfileHealthFilter.valid.matches(invalid))
}

@Test func logLevelFilterMatchesCommonMihomoLevels() {
    #expect(LogLevelFilter.all.matches("info"))
    #expect(LogLevelFilter.errors.matches("error"))
    #expect(LogLevelFilter.errors.matches("fatal"))
    #expect(!LogLevelFilter.errors.matches("warning"))
    #expect(LogLevelFilter.warnings.matches("warn"))
    #expect(LogLevelFilter.warnings.matches("warning"))
    #expect(LogLevelFilter.info.matches("Info"))
    #expect(LogLevelFilter.debug.matches("debug"))
}

@Test func proxyNodeFilterFindsSelectedUntestedAndSlowNodes() {
    let selected = ProxyNode(name: "Japan", region: "JP", latency: 80, isSelected: true)
    let untested = ProxyNode(name: "Singapore", region: "SG", latency: nil, isSelected: false)
    let slow = ProxyNode(name: "US", region: "US", latency: 480, isSelected: false)
    let group = ProxyNode(name: "Auto", region: "Proxy", latency: nil, isSelected: false, isGroup: true)

    #expect(ProxyNodeFilter.all.matches(selected))
    #expect(ProxyNodeFilter.selected.matches(selected))
    #expect(!ProxyNodeFilter.selected.matches(untested))
    #expect(ProxyNodeFilter.untested.matches(untested))
    #expect(!ProxyNodeFilter.untested.matches(group))
    #expect(ProxyNodeFilter.slow.matches(slow))
    #expect(!ProxyNodeFilter.slow.matches(selected))
}

@Test func systemAppearanceResolvesFromTheLiveMacOSScheme() {
    #expect(AppAppearance.system.resolvedColorScheme(systemColorScheme: .light) == .light)
    #expect(AppAppearance.system.resolvedColorScheme(systemColorScheme: .dark) == .dark)
    #expect(AppAppearance.light.resolvedColorScheme(systemColorScheme: .dark) == .light)
    #expect(AppAppearance.dark.resolvedColorScheme(systemColorScheme: .light) == .dark)
}

@Test func updateCapsuleDefersToSparkleForDownloadedOrVisibleUpdates() {
    #expect(UpdateReminderPolicy.shouldShowCapsule(
        standardDriverWillShowUpdate: false,
        updateIsNotDownloaded: true
    ))
    #expect(!UpdateReminderPolicy.shouldShowCapsule(
        standardDriverWillShowUpdate: true,
        updateIsNotDownloaded: true
    ))
    #expect(!UpdateReminderPolicy.shouldShowCapsule(
        standardDriverWillShowUpdate: false,
        updateIsNotDownloaded: false
    ))
}

@MainActor
@Test func appStorePersistsTheSelectedLanguage() throws {
    let suiteName = "ClashGlassTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let store = AppStore(
        profileRepository: ManagedProfileRepository(rootURL: rootURL),
        userDefaults: defaults
    )
    store.language = .japanese

    let restored = AppStore(
        profileRepository: ManagedProfileRepository(rootURL: rootURL),
        userDefaults: defaults
    )
    #expect(restored.language == .japanese)
}

@MainActor
@Test func appStoreStartsWithoutPrototypeSampleData() throws {
    let rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let repository = ManagedProfileRepository(rootURL: rootURL)
    let store = AppStore(profileRepository: repository)

    #expect(store.selectedProfile == "No Profile")
    #expect(store.proxyGroups.isEmpty)
    #expect(store.connections.isEmpty)
    #expect(store.logs.isEmpty)
}

@Test func settingsReplacesToolsInThePrimaryRail() {
    #expect(AppSection.settings.symbol == "wrench.and.screwdriver.fill")
    #expect(RailSelectionResolver.item(for: .settings) == .section(.settings))
    #expect(RailSelectionResolver.item(for: .logs) == .section(.settings))
}

@Test func coreStatusPresentationDistinguishesControllerOnlyFromStopped() {
    #expect(CoreStatusPresentation.runtimeText(isStarted: true, isCoreRunning: true) == "VPN Active")
    #expect(CoreStatusPresentation.runtimeText(isStarted: false, isCoreRunning: true) == "Controller Running")
    #expect(CoreStatusPresentation.runtimeText(isStarted: false, isCoreRunning: false) == "Stopped")
}

@Test func toolbarControlsMatchTheReferencePaletteAndAlignment() {
    #expect(ToolbarControlAppearancePolicy.runningCoreSymbol == "checkmark")
    #expect(ToolbarControlAppearancePolicy.stoppedCoreSymbol == "arrow.clockwise")
    #expect(!ToolbarControlAppearancePolicy.runningCoreUsesSolidGreenSurface)
    #expect(!ToolbarControlAppearancePolicy.runningCoreUsesWhiteSymbol)
    #expect(ToolbarControlAppearancePolicy.quickEditUsesNativeMenu)
    #expect(!ToolbarControlAppearancePolicy.quickEditUsesPlainIcon)
    #expect(ToolbarControlAppearancePolicy.quickEditUsesCompactGlassSurface)
    #expect(ToolbarControlAppearancePolicy.quickEditKeepsSurfaceOutsideNativeMenuLabel)
    #expect(!ToolbarControlAppearancePolicy.quickEditVisualSurfaceAllowsHitTesting)
    #expect(!ToolbarControlAppearancePolicy.quickEditHitLayerUsesVisibleAlpha)
    #expect(ToolbarControlAppearancePolicy.quickEditUsesSingleInteractiveSurface)
    #expect(ToolbarControlAppearancePolicy.quickEditUsesAppKitMenuBridge)
    #expect(ToolbarControlAppearancePolicy.quickEditSymbol == "pencil")
    #expect(ToolbarControlMetrics.visibleSize == 34)
    #expect(ToolbarControlMetrics.hitTarget == 40)
    #expect(ToolbarControlAppearancePolicy.controlCornerRadius == 11)
}

@Test func pageNavigationUsesOneSharedFadeTransition() {
    #expect(PageNavigationTransitionPolicy.appliesToEverySectionChange)
    #expect(PageNavigationTransitionPolicy.usesOpacityTransition)
    #expect(PageNavigationTransitionPolicy.respectsReducedMotion)
    #expect(PageNavigationTransitionPolicy.duration == 0.20)
}

@Test func proxiesToolbarKeepsOnlyOneRefreshAndLatencyEntryPoint() {
    #expect(ProxiesToolbarPolicy.refreshIncludesLatencyTesting)
    #expect(!ProxiesToolbarPolicy.showsSeparateDelayTestAction)
    #expect(ProxiesToolbarPolicy.actionTitles == [
        "Refresh",
        "Providers",
        "Settings",
    ])
}

@MainActor
@Test func dashboardControlsUpdateRuntimeState() {
    let store = AppStore()

    #expect(store.isStarted == false)
    store.toggleStarted()
    #expect(store.isStarted == true)

    let initialSystemProxyState = store.isSystemProxyEnabled
    store.toggleSystemProxy()
    #expect(store.isSystemProxyEnabled == !initialSystemProxyState)

    let initialTunState = store.isTunEnabled
    store.toggleTun()
    #expect(store.isTunEnabled == !initialTunState)

    store.selectOutboundMode(.global)
    #expect(store.selectedMode == .global)
}

@Test func liquidControlMotionUsesStableHoverAndPressScales() {
    #expect(LiquidControlMotion.scale(isHovering: false, isPressed: false, reduceMotion: false) == 1)
    #expect(LiquidControlMotion.scale(isHovering: true, isPressed: false, reduceMotion: false) == 1.025)
    #expect(LiquidControlMotion.scale(isHovering: true, isPressed: true, reduceMotion: false) == 0.975)
    #expect(LiquidControlMotion.scale(isHovering: true, isPressed: true, reduceMotion: true) == 1)
    #expect(LiquidControlInteractionPolicy.usesNativeButtonPressState)
    #expect(!LiquidControlInteractionPolicy.usesSupplementalDragGesture)
    #expect(!LiquidControlInteractionPolicy.nestsInteractiveGlassInsideButton)
    #expect(LiquidControlInteractionPolicy.usesNativeButtonAction)
    #expect(!LiquidControlInteractionPolicy.triggersActionOnPressDown)
    #expect(LiquidControlInteractionPolicy.minimumHitTarget >= 40)
    #expect(ToolbarControlMetrics.visibleSize == 34)
    #expect(ToolbarControlMetrics.hitTarget > ToolbarControlMetrics.visibleSize)
}

@Test func railUsesAFullWidthPointerTarget() {
    #expect(RailHitTargetMetrics.width == 74)
    #expect(RailHitTargetMetrics.height >= 44)
}

@Test func glassCardMotionProvidesIndependentHoverLift() {
    #expect(GlassCardMotion.scale(isHovering: false, reduceMotion: false) == 1)
    #expect(GlassCardMotion.scale(isHovering: true, reduceMotion: false) == 1.004)
    #expect(GlassCardMotion.verticalOffset(isHovering: true, reduceMotion: false) == -1)
    #expect(GlassCardMotion.shadowOpacity(isHovering: false, reduceMotion: false) == 0)
    #expect(GlassCardMotion.shadowOpacity(isHovering: true, reduceMotion: false) == 0.12)
    #expect(GlassCardMotion.shadowOpacity(isHovering: true, reduceMotion: true) == 0.08)
    #expect(GlassCardMotion.scale(isHovering: true, reduceMotion: true) == 1)
    #expect(GlassCardMotion.verticalOffset(isHovering: true, reduceMotion: true) == 0)
}

@Test func glassCardReservesEnoughOverflowForAnUnclippedHoverHalo() {
    #expect(GlassCardVisualMetrics.usesStableGlassMaterial)
    #expect(GlassCardVisualMetrics.clipsContentToRoundedShape)
    #expect(GlassCardVisualMetrics.overflowAllowance >= GlassCardVisualMetrics.shadowRadius)
    #expect(
        GlassCardVisualMetrics.overflowAllowance
            >= GlassCardVisualMetrics.shadowRadius + abs(GlassCardVisualMetrics.shadowVerticalOffset)
    )
    #expect(PageSurfaceMetrics.horizontalInset >= GlassCardVisualMetrics.minimumPageInset)
    #expect(PageSurfaceMetrics.topInset >= GlassCardVisualMetrics.minimumPageInset)
}

@Test func featurePagesKeepContentAwayFromEveryStageEdge() {
    #expect(PageSurfaceMetrics.horizontalInset == 28)
    #expect(PageSurfaceMetrics.topInset == 28)
    #expect(PageSurfaceMetrics.contentWidth(availableWidth: 854) == 798)
}

@Test func railHoverTracksOnlyThePointerTarget() {
    var hoverState = RailHoverState()
    let dashboard = RailItem.section(.dashboard)
    let profiles = RailItem.section(.profiles)

    hoverState.update(item: dashboard, isHovering: true)
    #expect(hoverState.hoveredItem == dashboard)

    hoverState.update(item: profiles, isHovering: true)
    #expect(hoverState.hoveredItem == profiles)

    hoverState.update(item: dashboard, isHovering: false)
    #expect(hoverState.hoveredItem == profiles)

    hoverState.update(item: profiles, isHovering: false)
    #expect(hoverState.hoveredItem == nil)
}

@Test func railItemsStayPlainUntilSelectedOrHovered() {
    let dashboard = RailItem.section(.dashboard)
    let profiles = RailItem.section(.profiles)
    let selected = RailItemPresentation(
        item: dashboard,
        selectedSection: .dashboard,
        hoveredItem: nil,
        reduceMotion: false
    )
    let idle = RailItemPresentation(
        item: profiles,
        selectedSection: .dashboard,
        hoveredItem: nil,
        reduceMotion: false
    )
    let hovered = RailItemPresentation(
        item: profiles,
        selectedSection: .dashboard,
        hoveredItem: profiles,
        reduceMotion: false
    )

    #expect(selected.showsSelectionBackground)
    #expect(selected.scale == 1)
    #expect(!idle.showsSelectionBackground)
    #expect(idle.scale == 1)
    #expect(!hovered.showsSelectionBackground)
    #expect(hovered.scale == 1)
}

@Test func railItemsUseQuietHoverWithoutLayoutMotion() {
    let dashboard = RailItem.section(.dashboard)
    let profiles = RailItem.section(.profiles)
    let selected = RailItemPresentation(
        item: dashboard,
        selectedSection: .dashboard,
        hoveredItem: nil,
        reduceMotion: false
    )
    let hovered = RailItemPresentation(
        item: profiles,
        selectedSection: .dashboard,
        hoveredItem: profiles,
        reduceMotion: false
    )
    let reducedHover = RailItemPresentation(
        item: profiles,
        selectedSection: .dashboard,
        hoveredItem: profiles,
        reduceMotion: true
    )

    #expect(selected.iconScale == 1)
    #expect(selected.horizontalOffset == 0)
    #expect(!selected.showsHoverBackground)
    #expect(hovered.showsHoverBackground)
    #expect(hovered.scale == 1)
    #expect(hovered.iconScale == 1.035)
    #expect(hovered.horizontalOffset == 0)
    #expect(hovered.verticalOffset == 0)
    #expect(hovered.shadowOpacity == 0)
    #expect(hovered.selectionGlowOpacity == 0.08)
    #expect(reducedHover.scale == 1)
    #expect(reducedHover.iconScale == 1)
    #expect(reducedHover.horizontalOffset == 0)
    #expect(reducedHover.showsHoverBackground)
}

@Test func railSelectionFollowsEveryNavigationEntryPoint() {
    #expect(RailSelectionMotion.appliesToExternalSectionChanges)
    #expect(RailSelectionMotion.usesMatchedGeometry)
    #expect(RailSelectionMotion.respectsReducedMotion)

    #expect(RailSelectionResolver.item(for: .dashboard) == .section(.dashboard))
    #expect(RailSelectionResolver.item(for: .resources) == .section(.proxies))
    #expect(RailSelectionResolver.item(for: .logs) == .section(.settings))
    #expect(RailSelectionResolver.item(for: .routing) == .section(.routing))
    #expect(RailSelectionResolver.item(for: .profiles) == .section(.profiles))
    #expect(RailSelectionResolver.item(for: .settings) == .section(.settings))
}

@Test func secondaryPagesKeepTheirParentRailItemSelected() {
    let resourcesPresentation = RailItemPresentation(
        item: .section(.proxies),
        selectedSection: .resources,
        hoveredItem: nil,
        reduceMotion: false
    )
    let logsPresentation = RailItemPresentation(
        item: .section(.settings),
        selectedSection: .logs,
        hoveredItem: nil,
        reduceMotion: false
    )

    #expect(resourcesPresentation.showsSelectionBackground)
    #expect(logsPresentation.showsSelectionBackground)
}

@Test func railUsesTheWindowBackgroundAndDrawsAboveTheMainStage() {
    #expect(RailSurfaceMetrics.usesSystemGlassSelection == false)
    #expect(RailSurfaceMetrics.backgroundMatchesWindow)
    #expect(RailSurfaceMetrics.railZIndex > RailSurfaceMetrics.stageZIndex)
    #expect(
        RailSurfaceMetrics.selectionShadowRadius
            <= RailSurfaceMetrics.selectionTrailingClearance
    )
}

@Test func selectionIndicatorMovesWithoutMovingItsLabel() {
    #expect(SelectionControlMotion.indicatorScale(
        isHovering: false,
        isPressed: false,
        reduceMotion: false
    ) == 1)
    #expect(SelectionControlMotion.indicatorScale(
        isHovering: true,
        isPressed: false,
        reduceMotion: false
    ) == 1.08)
    #expect(SelectionControlMotion.indicatorScale(
        isHovering: true,
        isPressed: true,
        reduceMotion: false
    ) == 0.92)
    #expect(SelectionControlMotion.indicatorScale(
        isHovering: true,
        isPressed: true,
        reduceMotion: true
    ) == 1)
    #expect(SelectionControlMotion.labelScale == 1)
    #expect(ModeRowInteractionPolicy.usesFullRowHitTarget)
    #expect(ModeRowInteractionPolicy.animatesIndicatorOnly)
    #expect(ModeRowInteractionPolicy.usesNativeButtonAction)
    #expect(!ModeRowInteractionPolicy.triggersActionOnPressDown)
    #expect(ModeRowInteractionPolicy.minimumHitHeight >= 40)
}
