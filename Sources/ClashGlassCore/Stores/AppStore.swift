import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
public final class AppStore {
    private let userDefaults: UserDefaults
    private let coreService: MihomoCoreService
    private var apiService: MihomoAPIService
    private let systemProxyService: SystemProxyService
    private let profileRepository: ManagedProfileRepository
    private let runtimeConfigurationPreparer: RuntimeConfigurationPreparer
    private let networkIdentityService: NetworkIdentityService
    private let proxySelectionRepository: ProxySelectionRepository
    private let routingOverrideRepository: RoutingOverrideRepository
    private var previousSystemProxySnapshot: SystemProxySnapshot?
    private var runStartedAt: Date?
    private var runtimeTickCount = 0
    private var trafficStreamTask: Task<Void, Never>?
    private var latestUploadBytesPerSecond = 0
    private var latestDownloadBytesPerSecond = 0
    private var confirmedOutboundMode: OutboundMode = .rule
    private var isApplyingOutboundMode = false
    private var pendingOutboundMode: OutboundMode?
    public var selectedSection: AppSection = .dashboard
    public var isCoreRunning = false
    public var isStarted = false
    public var coreStatus: CoreRuntimeStatus = .stopped
    public var isSystemProxyEnabled = false
    public var isTunEnabled = false
    public var proxyHost = "127.0.0.1"
    public var networkService = "Wi-Fi"
    public var appearanceMode: AppAppearance = .system {
        didSet {
            userDefaults.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    public var language: AppLanguage = .system {
        didSet {
            userDefaults.set(language.rawValue, forKey: "language")
        }
    }
    public var reduceMotion = false {
        didSet {
            userDefaults.set(reduceMotion, forKey: "reduceMotion")
        }
    }
    public var httpPort = 7890
    public var socksPort = 7891
    public var selectedMode: OutboundMode = .rule
    public private(set) var stagedOutboundMode: OutboundMode?
    public var selectedProfile = "No Profile"
    public var configPath = "\(NSHomeDirectory())/.config/clash/config.yaml"
    public private(set) var managedProfiles: [ManagedProfile] = []
    public private(set) var selectedManagedProfileID: ManagedProfile.ID?
    var routingOverrides: [RoutingOverride] = []
    public private(set) var controllerURL = URL(string: "http://127.0.0.1:9090")!
    public private(set) var controllerSecret: String?
    public var runSeconds = 0
    public var externalIP = "Detecting..."
    public var networkCountryCode = ""
    public var networkCountryName = ""
    public var intranetIP = "Detecting..."
    public var uploadSpeedText = "0B/s"
    public var downloadSpeedText = "0B/s"
    public var uploadTotalText = "0"
    public var downloadTotalText = "0"
    public var uploadTrafficUnit = "B"
    public var downloadTrafficUnit = "B"
    public var lastErrorMessage: String?
    public private(set) var profileValidationStates: [ManagedProfile.ID: ProfileValidationState] = [:]
    var isLatencyTesting = false
    var latencyTestProgress = LatencyTestProgress(completed: 0, total: 0)
    public var dashboardWidgets = DashboardWidgetKind.defaultOrder
    public var speedSamples: [Double] = Array(repeating: 0, count: 28)

    var proxyGroups: [ProxyGroup] = []
    var connections: [ConnectionEntry] = []
    var logs: [LogEntry] = []

    public init(
        coreService: MihomoCoreService = MihomoCoreService(),
        apiService: MihomoAPIService = MihomoAPIService(
            requestBuilder: MihomoAPIRequest(baseURL: URL(string: "http://127.0.0.1:9090")!)
        ),
        systemProxyService: SystemProxyService = SystemProxyService(),
        profileRepository: ManagedProfileRepository = ManagedProfileRepository(),
        runtimeConfigurationPreparer: RuntimeConfigurationPreparer = RuntimeConfigurationPreparer(),
        networkIdentityService: NetworkIdentityService = NetworkIdentityService(),
        proxySelectionRepository: ProxySelectionRepository? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
        self.coreService = coreService
        self.apiService = apiService
        self.systemProxyService = systemProxyService
        self.profileRepository = profileRepository
        self.runtimeConfigurationPreparer = runtimeConfigurationPreparer
        self.networkIdentityService = networkIdentityService
        self.proxySelectionRepository = proxySelectionRepository
            ?? ProxySelectionRepository(rootURL: profileRepository.rootURL)
        routingOverrideRepository = RoutingOverrideRepository(rootURL: profileRepository.rootURL)
        appearanceMode = AppAppearance(
            rawValue: userDefaults.string(forKey: "appearanceMode") ?? ""
        ) ?? .system
        language = AppLanguage(
            rawValue: userDefaults.string(forKey: "language") ?? ""
        ) ?? .system
        reduceMotion = userDefaults.bool(forKey: "reduceMotion")
        controllerURL = apiService.requestBuilder.baseURL
        controllerSecret = apiService.requestBuilder.secret
        configPath = profileRepository.runtimeConfigURL.path
        reloadManagedProfiles()
        reloadRoutingOverrides()
        if let profile = selectedManagedProfile {
            synchronizeConfiguration(from: profile.managedConfigURL)
        }
    }

    public var selectedManagedProfile: ManagedProfile? {
        guard let selectedManagedProfileID else {
            return nil
        }
        return managedProfiles.first { $0.id == selectedManagedProfileID }
    }

    public func text(_ key: AppString) -> String {
        language.text(key)
    }

    public var menuBarProfileTitle: String {
        selectedManagedProfile?.name ?? selectedProfile
    }

    var menuBarProxyNodes: [ProxyNode] {
        proxyGroups
            .first(where: { $0.name == MenuBarQuickAccessPolicy.selectorName })?
            .nodes
            .filter { !$0.isGroup } ?? []
    }

    var menuBarSelectedNodeName: String? {
        menuBarProxyNodes.first(where: \.isSelected)?.name
    }

    public var managedProfilesFolderURL: URL {
        profileRepository.rootURL.appendingPathComponent("Profiles", isDirectory: true)
    }

    public func validationState(for id: ManagedProfile.ID) -> ProfileValidationState {
        profileValidationStates[id] ?? .notValidated
    }

    public func importManagedProfile(from sourceURL: URL) async {
        do {
            let profile = try await profileRepository.importProfile(from: sourceURL) { [coreService] stagedURL in
                await coreService.validateConfig(path: stagedURL.path)
            }
            try profileRepository.select(profile.id)
            reloadManagedProfiles()
            reloadRoutingOverrides()
            synchronizeConfiguration(from: profile.managedConfigURL)
            profileValidationStates[profile.id] = .valid()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func selectManagedProfile(_ id: ManagedProfile.ID) async {
        do {
            let wasStarted = isStarted
            if isCoreRunning {
                if wasStarted {
                    await stopRuntime(userInitiated: true)
                } else {
                    await stopControllerOnly(userInitiated: true)
                }
            }
            try profileRepository.select(id)
            reloadManagedProfiles()
            guard let profile = selectedManagedProfile else {
                throw ManagedProfileError.profileNotFound
            }
            reloadRoutingOverrides()
            synchronizeConfiguration(from: profile.managedConfigURL)
            if wasStarted {
                await toggleRuntime(configPath: configPath)
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func removeManagedProfile(_ id: ManagedProfile.ID) {
        do {
            try profileRepository.remove(id)
            try? routingOverrideRepository.removeProfile(id)
            profileValidationStates.removeValue(forKey: id)
            reloadManagedProfiles()
            reloadRoutingOverrides()
            if let profile = selectedManagedProfile {
                synchronizeConfiguration(from: profile.managedConfigURL)
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func renameManagedProfile(_ id: ManagedProfile.ID, to name: String) {
        do {
            try profileRepository.rename(id, to: name)
            reloadManagedProfiles()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func validateManagedProfile(_ id: ManagedProfile.ID) async {
        guard let profile = managedProfiles.first(where: { $0.id == id }) else {
            lastErrorMessage = ManagedProfileError.profileNotFound.localizedDescription
            return
        }
        profileValidationStates[id] = .checking
        switch await coreService.validateConfig(path: profile.managedConfigURL.path) {
        case .success:
            profileValidationStates[id] = .valid()
            lastErrorMessage = nil
        case let .failure(message):
            profileValidationStates[id] = .invalid(message)
            lastErrorMessage = message
        }
    }

    public func validateAllManagedProfiles() async {
        var firstFailure: String?
        for profile in managedProfiles {
            profileValidationStates[profile.id] = .checking
            switch await coreService.validateConfig(path: profile.managedConfigURL.path) {
            case .success:
                profileValidationStates[profile.id] = .valid()
            case let .failure(message):
                profileValidationStates[profile.id] = .invalid(message)
                if firstFailure == nil {
                    firstFailure = "\(profile.name): \(message)"
                }
            }
        }
        lastErrorMessage = firstFailure
    }

    public func clearLogs() {
        logs.removeAll()
    }

    func addRoutingOverride(input: String, policy: RoutingPolicy) async {
        guard let profileID = selectedManagedProfileID else {
            lastErrorMessage = "Select a managed profile before adding routing rules."
            return
        }
        do {
            let domain = try RoutingInputNormalizer.domain(from: input)
            if policy == .vpn,
               let profile = selectedManagedProfile {
                let yaml = try String(
                    contentsOf: profile.managedConfigURL,
                    encoding: .utf8
                )
                guard RoutingVPNTargetResolver.target(from: yaml) != nil else {
                    throw RuntimeConfigurationError.missingVPNPolicyGroup
                }
            }
            try routingOverrideRepository.upsert(
                domain: domain,
                policy: policy,
                profileID: profileID
            )
            reloadRoutingOverrides()
            try await restartRuntimeForRoutingChangesIfNeeded()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func removeRoutingOverride(domain: String) async {
        guard let profileID = selectedManagedProfileID else {
            return
        }
        do {
            try routingOverrideRepository.remove(domain: domain, profileID: profileID)
            reloadRoutingOverrides()
            try await restartRuntimeForRoutingChangesIfNeeded()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public var exportedLogs: String {
        logs.reversed().map { "[\($0.time)] \($0.level): \($0.message)" }
            .joined(separator: "\n")
    }

    public func toggleCore() {
        isCoreRunning.toggle()
    }

    public func toggleStarted() {
        isStarted.toggle()
    }

    public func toggleRuntime(configPath: String) async {
        if isStarted {
            await stopRuntime(userInitiated: true)
            return
        }

        let requestedMode = stagedOutboundMode
        guard await ensureControllerAvailable(configPath: configPath) else {
            return
        }
        if let requestedMode,
           !(await applyOutboundModeToController(requestedMode)) {
            return
        }

        isStarted = true
        isCoreRunning = true
        runStartedAt = Date()
        runtimeTickCount = 0
        latestUploadBytesPerSecond = 0
        latestDownloadBytesPerSecond = 0
        runSeconds = 0
        startTrafficStream()
        await refreshRuntimeConfiguration()
        await refreshProxies()
        await refreshConnections()
        await applySystemProxy(enabled: true, service: networkService)
        await refreshNetworkIdentity()
        await refreshLogs()
    }

    public func shutdownRuntime() async {
        if isStarted {
            await stopRuntime(userInitiated: true)
        } else if isCoreRunning {
            await stopControllerOnly(userInitiated: true)
        }
    }

    public func restartCore() async {
        let intent = CoreRestartIntent.resolve(
            isStarted: isStarted,
            isCoreRunning: isCoreRunning
        )
        let activeMode = selectedMode

        switch intent {
        case .startController:
            guard await ensureControllerAvailable(configPath: configPath) else {
                return
            }
            if selectedMode != activeMode {
                _ = await applyOutboundModeToController(activeMode)
            }
            await refreshProxies()
        case .restartController:
            await stopControllerOnly(userInitiated: true)
            guard await ensureControllerAvailable(configPath: configPath) else {
                return
            }
            if selectedMode != activeMode {
                _ = await applyOutboundModeToController(activeMode)
            }
            await refreshProxies()
        case .restartActiveRuntime:
            stagedOutboundMode = activeMode
            await stopRuntime(userInitiated: true)
            await toggleRuntime(configPath: configPath)
        }
    }

    public func shutdownForApplicationTermination() {
        stopTrafficStream()
        if let previousSystemProxySnapshot {
            try? systemProxyService.apply(
                .restore(service: networkService, snapshot: previousSystemProxySnapshot)
            )
            self.previousSystemProxySnapshot = nil
        }
        coreService.stopImmediately()
        coreStatus = coreService.status
        isStarted = false
        isCoreRunning = false
        isSystemProxyEnabled = false
    }

    public func toggleSystemProxy() {
        isSystemProxyEnabled.toggle()
    }

    public func toggleSystemProxy(service: String = "Wi-Fi") async {
        guard isStarted else {
            isSystemProxyEnabled.toggle()
            return
        }
        await applySystemProxy(enabled: !isSystemProxyEnabled, service: service)
    }

    public func setSystemProxyEnabled(_ enabled: Bool) {
        isSystemProxyEnabled = enabled
    }

    public func currentSystemProxyCommand(service: String) -> SystemProxyCommand {
        if isSystemProxyEnabled {
            return .enable(service: service, host: proxyHost, httpPort: httpPort, socksPort: socksPort)
        }
        return .disable(service: service)
    }

    public func toggleTun() {
        isTunEnabled.toggle()
    }

    public func selectOutboundMode(_ mode: OutboundMode) {
        selectedMode = mode
    }

    public func setOutboundMode(_ mode: OutboundMode) async {
        selectedMode = mode
        guard isCoreRunning else {
            stagedOutboundMode = mode
            lastErrorMessage = nil
            return
        }
        stagedOutboundMode = nil
        pendingOutboundMode = mode
        guard !isApplyingOutboundMode else {
            return
        }
        isApplyingOutboundMode = true
        defer {
            isApplyingOutboundMode = false
        }
        while let requestedMode = pendingOutboundMode {
            pendingOutboundMode = nil
            switch await requestOutboundModeFromController(requestedMode) {
            case let .success(effectiveMode):
                confirmedOutboundMode = effectiveMode
                if pendingOutboundMode == nil {
                    selectedMode = effectiveMode
                    lastErrorMessage = nil
                }
            case let .failure(error):
                if pendingOutboundMode == nil {
                    selectedMode = confirmedOutboundMode
                    lastErrorMessage = error.localizedDescription
                }
            }
        }
    }

    public func setTunEnabled(_ enabled: Bool) async {
        let previousValue = isTunEnabled
        isTunEnabled = enabled
        guard isStarted else {
            return
        }
        do {
            _ = try await apiService.data(for: .updateConfigs(mode: nil, tunEnabled: enabled))
            lastErrorMessage = nil
        } catch {
            isTunEnabled = previousValue
            lastErrorMessage = error.localizedDescription
        }
    }

    public func selectProxy(groupName: String, nodeName: String) {
        guard let groupIndex = proxyGroups.firstIndex(where: { $0.name == groupName }) else {
            return
        }
        for nodeIndex in proxyGroups[groupIndex].nodes.indices {
            proxyGroups[groupIndex].nodes[nodeIndex].isSelected = proxyGroups[groupIndex].nodes[nodeIndex].name == nodeName
        }
    }

    public func selectProxyRemote(groupName: String, nodeName: String) async {
        guard await ensureControllerAvailable(configPath: configPath) else {
            return
        }
        let targetGroups = ProxySelectionResolver.targetGroups(
            selectedGroupName: groupName,
            nodeName: nodeName,
            groups: proxyGroups
        )
        guard !targetGroups.isEmpty else {
            lastErrorMessage = "This automatic group cannot be manually locked without a parent selector."
            return
        }
        let previousGroups = proxyGroups
        for targetGroup in targetGroups {
            selectProxy(groupName: targetGroup, nodeName: nodeName)
        }
        do {
            for targetGroup in targetGroups {
                _ = try await apiService.data(
                    for: .changeProxy(group: targetGroup, proxy: nodeName)
                )
                if let profileID = selectedManagedProfileID {
                    try proxySelectionRepository.save(
                        selector: targetGroup,
                        node: nodeName,
                        profileID: profileID
                    )
                }
            }
            _ = try await apiService.data(for: .closeAllConnections)
            lastErrorMessage = nil
            await refreshProxies()
            if isStarted {
                await refreshNetworkIdentity()
            }
        } catch {
            proxyGroups = previousGroups
            lastErrorMessage = error.localizedDescription
        }
    }

    public func delayTestAll(timeout: Int = 5_000) async {
        guard !isLatencyTesting else {
            return
        }
        guard await ensureControllerAvailable(configPath: configPath) else {
            return
        }
        let plan = LatencyTestPlanner.plan(groups: proxyGroups)
        let service = apiService
        guard !plan.nodeNames.isEmpty else {
            lastErrorMessage = "No concrete proxy nodes are available for latency testing."
            return
        }
        isLatencyTesting = true
        latencyTestProgress = LatencyTestProgress(completed: 0, total: plan.nodeNames.count)
        defer {
            isLatencyTesting = false
        }

        var successfulMeasurements = 0
        var completedNodeNames = Set<String>()
        func publish(
            delays: [String: Int],
            completed names: Set<String>
        ) {
            completedNodeNames.formUnion(names)
            latencyTestProgress = LatencyTestProgress(
                completed: completedNodeNames.count,
                total: plan.nodeNames.count
            )
            successfulMeasurements += delays.count
            for (nodeName, latency) in delays {
                for groupIndex in proxyGroups.indices {
                    for nodeIndex in proxyGroups[groupIndex].nodes.indices
                    where proxyGroups[groupIndex].nodes[nodeIndex].name == nodeName {
                        proxyGroups[groupIndex].nodes[nodeIndex].latency = latency
                    }
                }
            }
        }

        for batchStart in stride(
            from: 0,
            to: plan.groupTests.count,
            by: LatencyTestPlan.maximumConcurrentGroupTests
        ) {
            let batchEnd = min(
                batchStart + LatencyTestPlan.maximumConcurrentGroupTests,
                plan.groupTests.count
            )
            let batch = plan.groupTests[batchStart..<batchEnd]
            await withTaskGroup(of: (LatencyGroupTest, [String: Int]).self) { taskGroup in
                for test in batch {
                    taskGroup.addTask {
                        let delays = (try? await service.groupDelays(
                            group: test.groupName,
                            url: test.url,
                            timeout: timeout
                        )) ?? [:]
                        return (test, delays)
                    }
                }
                for await (test, delays) in taskGroup {
                    publish(delays: delays, completed: test.nodeNames)
                }
            }
        }

        for batchStart in stride(
            from: 0,
            to: plan.fallbackTests.count,
            by: LatencyTestPlan.maximumConcurrentFallbackTests
        ) {
            let batchEnd = min(
                batchStart + LatencyTestPlan.maximumConcurrentFallbackTests,
                plan.fallbackTests.count
            )
            let batch = plan.fallbackTests[batchStart..<batchEnd]
            await withTaskGroup(of: (String, Int?).self) { taskGroup in
                for test in batch {
                    taskGroup.addTask {
                        let latency = await service.medianDelay(
                            proxy: test.proxyName,
                            url: test.url,
                            attempts: LatencyTestPlan.attemptsPerProxy,
                            timeout: timeout
                        )
                        return (test.proxyName, latency)
                    }
                }
                for await (nodeName, latency) in taskGroup {
                    publish(
                        delays: latency.map { [nodeName: $0] } ?? [:],
                        completed: [nodeName]
                    )
                }
            }
        }
        lastErrorMessage = successfulMeasurements > 0
            ? nil
            : "No proxy returned a successful delay measurement."
    }

    func closeConnection(_ connection: ConnectionEntry) async {
        guard let remoteID = connection.remoteID else {
            return
        }
        do {
            _ = try await apiService.data(for: .closeConnection(id: remoteID))
            connections.removeAll { $0.remoteID == remoteID }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func closeAllConnections() async {
        do {
            _ = try await apiService.data(for: .closeAllConnections)
            connections.removeAll()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        await refreshConnections()
    }

    public func refreshRuntimeData() async {
        await refreshProxies()
        await refreshConnections()
        await refreshLogs()
    }

    public func refreshRuntimeConfiguration() async {
        do {
            let data = try await apiService.data(for: .configs)
            let config = try MihomoAPIDecoder.runtimeConfig(from: data)
            if let mixedPort = config.mixedPort {
                httpPort = mixedPort
                socksPort = mixedPort
            }
            selectedMode = config.mode
            confirmedOutboundMode = config.mode
            isTunEnabled = config.tunEnabled
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func runtimeTick() async {
        guard isStarted else {
            return
        }
        guard coreService.isProcessRunning else {
            stopTrafficStream()
            isStarted = false
            isCoreRunning = false
            coreStatus = .failed("Mihomo exited unexpectedly.")
            await restorePreviousSystemProxy()
            return
        }
        if let runStartedAt {
            runSeconds = max(0, Int(Date().timeIntervalSince(runStartedAt)))
        }
        runtimeTickCount += 1
        advanceSpeedGraph()
        if runtimeTickCount.isMultiple(of: 4) {
            await refreshConnections()
        }
        if runtimeTickCount.isMultiple(of: 10) {
            await refreshRuntimeConfiguration()
            await refreshLogs()
        }
        if runtimeTickCount.isMultiple(of: 20) {
            await refreshNetworkIdentity()
        }
    }

    public func refreshProxies() async {
        guard await ensureControllerAvailable(configPath: configPath) else {
            return
        }
        do {
            let data = try await apiService.data(for: .proxies)
            applyProxyResponse(data)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func refreshProxiesAndLatency(timeout: Int = 5_000) async {
        await refreshProxies()
        guard lastErrorMessage == nil, !proxyGroups.isEmpty else {
            return
        }
        await delayTestAll(timeout: timeout)
    }

    public func refreshConnections() async {
        guard isStarted else {
            return
        }
        do {
            let data = try await apiService.data(for: .connections)
            applyConnectionsResponse(data)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func refreshTraffic() async {
        guard isStarted else {
            return
        }
        advanceSpeedGraph()
    }

    public func refreshLogs() async {
        guard isStarted else {
            return
        }
        do {
            let data = try await apiService.firstLineData(for: .logs, timeout: .milliseconds(400))
            guard !data.isEmpty else {
                return
            }
            applyLogResponse(data)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func applyProxyResponse(_ data: Data) {
        do {
            let measuredLatencies = Dictionary(
                proxyGroups
                    .flatMap(\.nodes)
                    .compactMap { node in
                        node.latency.map { (node.name, $0) }
                    },
                uniquingKeysWith: { current, _ in current }
            )
            var groups = try MihomoAPIDecoder.proxyGroups(from: data)
            for groupIndex in groups.indices {
                for nodeIndex in groups[groupIndex].nodes.indices {
                    let nodeName = groups[groupIndex].nodes[nodeIndex].name
                    groups[groupIndex].nodes[nodeIndex].latency = measuredLatencies[nodeName]
                }
            }
            if !groups.isEmpty {
                proxyGroups = groups
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func applyConnectionsResponse(_ data: Data) {
        do {
            let snapshot = try MihomoAPIDecoder.connectionsSnapshot(from: data)
            connections = snapshot.entries
            let upload = Self.trafficAmount(snapshot.uploadTotal)
            let download = Self.trafficAmount(snapshot.downloadTotal)
            uploadTotalText = upload.value
            uploadTrafficUnit = upload.unit
            downloadTotalText = download.value
            downloadTrafficUnit = download.unit
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func applyTrafficResponse(_ data: Data) {
        applyTrafficResponse(data, appendSample: true)
    }

    func applyLiveTrafficResponse(_ data: Data) {
        applyTrafficResponse(data, appendSample: false)
    }

    private func applyTrafficResponse(_ data: Data, appendSample: Bool) {
        do {
            let snapshot = try MihomoAPIDecoder.traffic(from: data)
            latestUploadBytesPerSecond = snapshot.up
            latestDownloadBytesPerSecond = snapshot.down
            uploadSpeedText = Self.speedText(snapshot.up)
            downloadSpeedText = Self.speedText(snapshot.down)
            if appendSample {
                appendSpeedSample(up: snapshot.up, down: snapshot.down)
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func applyLogResponse(_ data: Data) {
        do {
            logs = try MihomoAPIDecoder.logEntries(from: data) + logs
            logs = Array(logs.prefix(200))
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    public func applySystemProxy(enabled: Bool, service: String = "Wi-Fi") async {
        do {
            if enabled, previousSystemProxySnapshot == nil {
                previousSystemProxySnapshot = try? systemProxyService.capture(service: service)
            }
            if !enabled {
                await restorePreviousSystemProxy()
                return
            }
            let command = enabled
                ? SystemProxyCommand.enable(service: service, host: proxyHost, httpPort: httpPort, socksPort: socksPort)
                : SystemProxyCommand.disable(service: service)
            try systemProxyService.apply(command)
            isSystemProxyEnabled = enabled
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            isSystemProxyEnabled = !enabled
        }
    }

    public func refreshNetworkIdentity() async {
        if let localIP = networkIdentityService.localIPv4Address() {
            intranetIP = localIP
        }
        do {
            let identity = if isStarted {
                try await networkIdentityService.fetchViaProxy(host: proxyHost, port: httpPort)
            } else {
                try await networkIdentityService.fetchDirect()
            }
            guard NetworkAddressPolicy.isIPv4(identity.ip) else {
                throw NetworkIdentityError.invalidResponse(
                    "The network identity service returned IPv6."
                )
            }
            externalIP = identity.ip
            networkCountryCode = identity.countryCode
            networkCountryName = identity.countryName
        } catch {
            if externalIP == "Detecting..." {
                externalIP = "Unavailable"
            }
        }
    }

    public var runTimeText: String {
        let hours = runSeconds / 3600
        let minutes = (runSeconds % 3600) / 60
        let seconds = runSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func speedText(_ bytesPerSecond: Int) -> String {
        if bytesPerSecond >= 1_000_000 {
            return String(format: "%.1fMB/s", Double(bytesPerSecond) / 1_000_000)
        }
        if bytesPerSecond >= 1_000 {
            return String(format: "%.1fKB/s", Double(bytesPerSecond) / 1_000)
        }
        return "\(bytesPerSecond)B/s"
    }

    static func trafficAmount(_ bytes: Int) -> (value: String, unit: String) {
        let value = Double(bytes)
        if value >= 1_000_000_000 {
            return (String(format: "%.1f", value / 1_000_000_000), "GB")
        }
        if value >= 1_000_000 {
            return (String(format: "%.1f", value / 1_000_000), "MB")
        }
        if value >= 1_000 {
            return (String(format: "%.1f", value / 1_000), "KB")
        }
        return ("\(bytes)", "B")
    }

    private func appendSpeedSample(up: Int, down: Int) {
        let sample = min(1.0, Double(max(up, down)) / 1_000_000)
        speedSamples.append(sample)
        if speedSamples.count > 28 {
            speedSamples.removeFirst(speedSamples.count - 28)
        }
    }

    func advanceSpeedGraph() {
        appendSpeedSample(
            up: latestUploadBytesPerSecond,
            down: latestDownloadBytesPerSecond
        )
    }

    private func startTrafficStream() {
        stopTrafficStream()
        let service = apiService
        trafficStreamTask = Task { [weak self] in
            while !Task.isCancelled, self?.isStarted == true {
                do {
                    for try await data in service.lineDataStream(for: .traffic) {
                        guard !Task.isCancelled, let self, self.isStarted else {
                            return
                        }
                        self.applyLiveTrafficResponse(data)
                    }
                } catch {
                    guard !Task.isCancelled else {
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(350))
                }
            }
        }
    }

    private func stopTrafficStream() {
        trafficStreamTask?.cancel()
        trafficStreamTask = nil
    }

    private func reloadManagedProfiles() {
        do {
            managedProfiles = try profileRepository.loadProfiles()
            selectedManagedProfileID = try profileRepository.selectedProfileID()
            let managedProfileIDs = Set(managedProfiles.map(\.id))
            profileValidationStates = profileValidationStates.filter {
                managedProfileIDs.contains($0.key)
            }
            if let selectedManagedProfile {
                selectedProfile = selectedManagedProfile.name
            } else {
                selectedProfile = "No Profile"
            }
        } catch {
            managedProfiles = []
            selectedManagedProfileID = nil
            lastErrorMessage = error.localizedDescription
        }
    }

    private func reloadRoutingOverrides() {
        guard let profileID = selectedManagedProfileID else {
            routingOverrides = []
            return
        }
        do {
            routingOverrides = try routingOverrideRepository.overrides(profileID: profileID)
        } catch {
            routingOverrides = []
            lastErrorMessage = error.localizedDescription
        }
    }

    private func applyOutboundModeToController(_ mode: OutboundMode) async -> Bool {
        switch await requestOutboundModeFromController(mode) {
        case let .success(effectiveMode):
            selectedMode = effectiveMode
            confirmedOutboundMode = effectiveMode
            stagedOutboundMode = nil
            lastErrorMessage = nil
            return true
        case let .failure(error):
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    private func requestOutboundModeFromController(
        _ mode: OutboundMode
    ) async -> Result<OutboundMode, Error> {
        do {
            _ = try await apiService.data(
                for: .updateConfigs(mode: mode, tunEnabled: nil)
            )
            let data = try await apiService.data(for: .configs)
            let config = try MihomoAPIDecoder.runtimeConfig(from: data)
            guard config.mode == mode else {
                return .failure(OutboundModeRuntimeError.modeMismatch(
                    requested: mode,
                    effective: config.mode
                ))
            }
            return .success(config.mode)
        } catch {
            return .failure(error)
        }
    }

    private func synchronizeConfiguration(from url: URL) {
        do {
            let settings = try MihomoConfigurationInspector.inspect(url: url)
            httpPort = settings.httpPort
            socksPort = settings.socksPort
            selectedMode = settings.mode
            confirmedOutboundMode = settings.mode
            isTunEnabled = settings.tunEnabled
            controllerURL = URL(string: "http://\(settings.controllerHost):\(settings.controllerPort)")!
            controllerSecret = settings.secret
            apiService = MihomoAPIService(
                requestBuilder: MihomoAPIRequest(baseURL: controllerURL, secret: controllerSecret),
                session: apiService.session
            )
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func applyPreparedRuntimeConfiguration(_ prepared: PreparedRuntimeConfiguration) {
        configPath = prepared.configURL.path
        httpPort = prepared.mixedPort
        socksPort = prepared.mixedPort
        controllerURL = prepared.controllerURL
        controllerSecret = prepared.controllerSecret
        apiService = MihomoAPIService(
            requestBuilder: MihomoAPIRequest(baseURL: controllerURL, secret: controllerSecret),
            session: apiService.session
        )
        do {
            let settings = try MihomoConfigurationInspector.inspect(url: prepared.configURL)
            selectedMode = settings.mode
            confirmedOutboundMode = settings.mode
            isTunEnabled = settings.tunEnabled
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    private func ensureControllerAvailable(configPath: String) async -> Bool {
        if coreService.isProcessRunning,
           (try? await apiService.data(for: .version)) != nil {
            coreService.markRunning()
            coreStatus = coreService.status
            isCoreRunning = true
            return true
        }

        if coreService.isProcessRunning {
            await coreService.stop(userInitiated: false)
        }

        do {
            let sourceURL: URL
            if let selectedManagedProfile {
                sourceURL = selectedManagedProfile.managedConfigURL
            } else {
                sourceURL = URL(fileURLWithPath: configPath)
            }
            let prepared = try runtimeConfigurationPreparer.prepare(
                sourceURL: sourceURL,
                runtimeDirectoryURL: profileRepository.runtimeDirectoryURL,
                routingOverrides: routingOverrides
            )
            applyPreparedRuntimeConfiguration(prepared)
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }

        await coreService.start(
            configPath: self.configPath,
            runtimeDirectoryURL: profileRepository.runtimeDirectoryURL
        )
        coreStatus = coreService.status
        guard coreStatus == .starting else {
            lastErrorMessage = coreStatus.failureMessage ?? "Mihomo could not start."
            isCoreRunning = false
            return false
        }

        guard await waitForController() else {
            let failure = coreService.status.failureMessage
                ?? coreService.recentOutput
                    .split(whereSeparator: \.isNewline)
                    .last
                    .map(String.init)
                ?? "Mihomo controller did not become ready at \(controllerURL.absoluteString)."
            await coreService.stop(userInitiated: false)
            coreStatus = coreService.status
            isStarted = false
            isCoreRunning = false
            lastErrorMessage = failure
            return false
        }

        coreService.markRunning()
        coreStatus = coreService.status
        isCoreRunning = true
        isStarted = false
        await restoreSavedProxySelections()
        lastErrorMessage = nil
        return true
    }

    private func restartRuntimeForRoutingChangesIfNeeded() async throws {
        let wasStarted = isStarted
        let wasControllerRunning = isCoreRunning
        let activeMode = selectedMode
        guard wasControllerRunning else {
            return
        }
        if wasStarted {
            stagedOutboundMode = activeMode
            await stopRuntime(userInitiated: true)
            await toggleRuntime(configPath: configPath)
            if !isStarted {
                throw RoutingRuntimeError.restartFailed(
                    lastErrorMessage ?? "Mihomo did not restart with the new routing rules."
                )
            }
        } else {
            await stopControllerOnly(userInitiated: true)
            guard await ensureControllerAvailable(configPath: configPath) else {
                throw RoutingRuntimeError.restartFailed(
                    lastErrorMessage ?? "Mihomo controller did not restart with the new routing rules."
                )
            }
            if selectedMode != activeMode,
               !(await applyOutboundModeToController(activeMode)) {
                throw RoutingRuntimeError.restartFailed(
                    lastErrorMessage ?? "Mihomo did not restore the active outbound mode."
                )
            }
            await refreshProxies()
        }
    }

    private func restoreSavedProxySelections() async {
        guard let profileID = selectedManagedProfileID,
              let selections = try? proxySelectionRepository.selections(profileID: profileID) else {
            return
        }
        for (selector, node) in selections {
            _ = try? await apiService.data(for: .changeProxy(group: selector, proxy: node))
        }
    }

    private func stopRuntime(userInitiated: Bool) async {
        stopTrafficStream()
        await restorePreviousSystemProxy()
        await coreService.stop(userInitiated: userInitiated)
        coreStatus = coreService.status
        isStarted = false
        isCoreRunning = false
        isSystemProxyEnabled = false
        runStartedAt = nil
        runtimeTickCount = 0
        latestUploadBytesPerSecond = 0
        latestDownloadBytesPerSecond = 0
        uploadSpeedText = "0B/s"
        downloadSpeedText = "0B/s"
        speedSamples = Array(repeating: 0, count: 28)
        await refreshNetworkIdentity()
    }

    private func stopControllerOnly(userInitiated: Bool) async {
        stopTrafficStream()
        await coreService.stop(userInitiated: userInitiated)
        coreStatus = coreService.status
        isStarted = false
        isCoreRunning = false
        runStartedAt = nil
        runtimeTickCount = 0
    }

    private func restorePreviousSystemProxy() async {
        guard let previousSystemProxySnapshot else {
            isSystemProxyEnabled = false
            return
        }
        do {
            try systemProxyService.apply(
                .restore(service: networkService, snapshot: previousSystemProxySnapshot)
            )
            self.previousSystemProxySnapshot = nil
            isSystemProxyEnabled = false
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func waitForController() async -> Bool {
        for _ in 0..<60 {
            guard coreService.isProcessRunning else {
                coreStatus = coreService.status
                return false
            }
            if (try? await apiService.data(for: .version)) != nil {
                return true
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
        return false
    }
}

private enum OutboundModeRuntimeError: Error, LocalizedError {
    case modeMismatch(requested: OutboundMode, effective: OutboundMode)

    var errorDescription: String? {
        switch self {
        case let .modeMismatch(requested, effective):
            "Mihomo kept \(effective.title) mode instead of \(requested.title)."
        }
    }
}
