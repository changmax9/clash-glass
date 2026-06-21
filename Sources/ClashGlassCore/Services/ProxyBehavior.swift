import Foundation

enum ProxySelectionResolver {
    static func targetGroups(
        selectedGroupName: String,
        nodeName: String,
        groups: [ProxyGroup]
    ) -> [String] {
        guard let selectedGroup = groups.first(where: { $0.name == selectedGroupName }) else {
            return []
        }
        if selectedGroup.kind.isAutomatic {
            return preferredParentSelector(
                selectedGroupName: selectedGroupName,
                nodeName: nodeName,
                groups: groups
            ).map { [$0] } ?? []
        }
        guard selectedGroup.kind == .selector || selectedGroup.kind == .unknown else {
            return []
        }
        guard selectedGroup.name == "GLOBAL" else {
            return [selectedGroup.name]
        }
        let preferred = groups
            .filter { candidate in
                candidate.name != "GLOBAL"
                    && candidate.kind == .selector
                    && candidate.nodes.contains(where: { $0.name == nodeName })
            }
            .min { lhs, rhs in
                lhs.nodes.count < rhs.nodes.count
            }?
            .name
        return [selectedGroup.name, preferred].compactMap { $0 }
    }

    static func targetGroup(
        selectedGroupName: String,
        nodeName: String,
        groups: [ProxyGroup]
    ) -> String? {
        targetGroups(
            selectedGroupName: selectedGroupName,
            nodeName: nodeName,
            groups: groups
        ).last
    }

    private static func preferredParentSelector(
        selectedGroupName: String,
        nodeName: String,
        groups: [ProxyGroup]
    ) -> String? {
        groups
            .filter { candidate in
                candidate.kind == .selector
                    && candidate.nodes.contains(where: { $0.name == selectedGroupName })
                    && candidate.nodes.contains(where: { $0.name == nodeName })
            }
            .min { lhs, rhs in
                if lhs.nodes.count == rhs.nodes.count {
                    return lhs.name != "GLOBAL" && rhs.name == "GLOBAL"
                }
                return lhs.nodes.count < rhs.nodes.count
            }?
            .name
    }
}

enum LatencyMeasurement {
    static func median(_ values: [Int?]) -> Int? {
        let successful = values.compactMap { $0 }.sorted()
        guard !successful.isEmpty else {
            return nil
        }
        let middle = successful.count / 2
        if successful.count.isMultiple(of: 2) {
            return (successful[middle - 1] + successful[middle]) / 2
        }
        return successful[middle]
    }
}

enum LatencyTestTargetResolver {
    static func testURL(nodeName: String, groups: [ProxyGroup]) -> String {
        groups.first(where: { group in
            group.kind.isAutomatic
                && group.testURL?.isEmpty == false
                && group.nodes.contains(where: { $0.name == nodeName })
        })?.testURL
            ?? groups.first(where: { group in
                group.testURL?.isEmpty == false
                    && group.nodes.contains(where: { $0.name == nodeName })
            })?.testURL
            ?? LatencyTestPlan.defaultTestURL
    }
}

enum LatencyTestPlan {
    static let maximumConcurrentGroupTests = 2
    static let maximumConcurrentFallbackTests = 8
    static let attemptsPerProxy = 1
    static let defaultTestURL = "https://www.gstatic.com/generate_204"
}

struct LatencyGroupTest: Equatable, Sendable {
    let groupName: String
    let url: String
    let nodeNames: Set<String>
}

struct LatencyProxyTest: Equatable, Sendable {
    let proxyName: String
    let url: String
}

struct LatencyTestBatchPlan: Equatable, Sendable {
    let groupTests: [LatencyGroupTest]
    let fallbackTests: [LatencyProxyTest]

    var nodeNames: Set<String> {
        groupTests.reduce(into: Set<String>()) { result, test in
            result.formUnion(test.nodeNames)
        }.union(fallbackTests.map(\.proxyName))
    }
}

enum LatencyTestPlanner {
    static func plan(groups: [ProxyGroup]) -> LatencyTestBatchPlan {
        let automaticCandidates = groups
            .filter { $0.kind.isAutomatic }
            .map { group in
                LatencyGroupTest(
                    groupName: group.name,
                    url: group.testURL.flatMap { $0.isEmpty ? nil : $0 }
                        ?? LatencyTestPlan.defaultTestURL,
                    nodeNames: Set(
                        group.nodes
                            .filter(isLatencyTestable)
                            .map(\.name)
                    )
                )
            }
            .filter { !$0.nodeNames.isEmpty }
            .sorted { lhs, rhs in
                if lhs.nodeNames.count == rhs.nodeNames.count {
                    return lhs.groupName < rhs.groupName
                }
                return lhs.nodeNames.count > rhs.nodeNames.count
            }

        var covered = Set<String>()
        var groupTests: [LatencyGroupTest] = []
        for candidate in automaticCandidates
        where !candidate.nodeNames.subtracting(covered).isEmpty {
            groupTests.append(candidate)
            covered.formUnion(candidate.nodeNames)
        }

        let allConcreteNames = Set(
            groups.flatMap { group in
                group.nodes.filter(isLatencyTestable).map(\.name)
            }
        )
        let fallbackTests = allConcreteNames
            .subtracting(covered)
            .sorted()
            .map { nodeName in
                LatencyProxyTest(
                    proxyName: nodeName,
                    url: LatencyTestTargetResolver.testURL(
                        nodeName: nodeName,
                        groups: groups
                    )
                )
            }
        return LatencyTestBatchPlan(
            groupTests: groupTests,
            fallbackTests: fallbackTests
        )
    }

    private static func isLatencyTestable(_ node: ProxyNode) -> Bool {
        guard !node.isGroup else {
            return false
        }
        return !["DIRECT", "REJECT", "PASS", "COMPATIBLE"]
            .contains(node.name.uppercased())
    }
}

struct LatencyTestProgress: Equatable, Sendable {
    let completed: Int
    let total: Int

    var fraction: Double {
        guard total > 0 else {
            return 0
        }
        return min(1, Double(completed) / Double(total))
    }

    var text: String {
        "Testing \(completed)/\(total)"
    }
}
