import Foundation

public struct ProxySelectionRepository: Sendable {
    public let rootURL: URL

    private var storeURL: URL {
        rootURL.appendingPathComponent("proxy-selections.json")
    }

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public func selections(profileID: UUID) throws -> [String: String] {
        try load()[profileID.uuidString] ?? [:]
    }

    public func save(selector: String, node: String, profileID: UUID) throws {
        var stored = try load()
        var profileSelections = stored[profileID.uuidString] ?? [:]
        profileSelections[selector] = node
        stored[profileID.uuidString] = profileSelections
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(stored).write(to: storeURL, options: .atomic)
    }

    private func load() throws -> [String: [String: String]] {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return [:]
        }
        return try JSONDecoder().decode(
            [String: [String: String]].self,
            from: Data(contentsOf: storeURL)
        )
    }
}
