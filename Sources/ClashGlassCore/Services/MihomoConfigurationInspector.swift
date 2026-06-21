import Foundation

public struct MihomoConfigurationSettings: Equatable, Sendable {
    public let httpPort: Int
    public let socksPort: Int
    public let controllerHost: String
    public let controllerPort: Int
    public let secret: String?
    public let mode: OutboundMode
    public let tunEnabled: Bool
    public let dnsListenHost: String?
    public let dnsListenPort: Int?
}

public enum MihomoConfigurationInspector {
    public static func inspect(url: URL) throws -> MihomoConfigurationSettings {
        try inspect(yaml: String(contentsOf: url, encoding: .utf8))
    }

    public static func inspect(yaml: String) throws -> MihomoConfigurationSettings {
        var mixedPort: Int?
        var httpPort: Int?
        var socksPort: Int?
        var controller = "127.0.0.1:9090"
        var secret: String?
        var mode: OutboundMode = .rule
        var tunEnabled = false
        var insideTun = false
        var insideDNS = false
        var dnsListenHost: String?
        var dnsListenPort: Int?

        for rawLine in yaml.split(whereSeparator: \.isNewline) {
            let line = String(rawLine)
            let indentation = line.prefix { $0 == " " || $0 == "\t" }.count
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else {
                continue
            }

            if indentation == 0 {
                insideTun = trimmed.hasPrefix("tun:")
                insideDNS = trimmed.hasPrefix("dns:")
                guard let pair = keyValue(trimmed) else {
                    continue
                }
                switch pair.key {
                case "mixed-port":
                    mixedPort = Int(pair.value)
                case "port":
                    httpPort = Int(pair.value)
                case "socks-port":
                    socksPort = Int(pair.value)
                case "external-controller":
                    controller = unquote(pair.value)
                case "secret":
                    let value = unquote(pair.value)
                    secret = value.isEmpty ? nil : value
                case "mode":
                    mode = OutboundMode(rawValue: unquote(pair.value).lowercased()) ?? .rule
                default:
                    break
                }
            } else if insideTun, let pair = keyValue(trimmed), pair.key == "enable" {
                tunEnabled = ["true", "yes", "on"].contains(unquote(pair.value).lowercased())
            } else if insideDNS, let pair = keyValue(trimmed), pair.key == "listen" {
                let listen = hostAndPort(unquote(pair.value))
                dnsListenHost = listen.host
                dnsListenPort = listen.port
            }
        }

        let controllerParts = controller.split(separator: ":", maxSplits: 1).map(String.init)
        let controllerHost = controllerParts.first ?? "127.0.0.1"
        let controllerPort = controllerParts.count == 2 ? Int(controllerParts[1]) ?? 9090 : 9090
        let effectiveMixedPort = mixedPort ?? 7890

        return MihomoConfigurationSettings(
            httpPort: httpPort ?? effectiveMixedPort,
            socksPort: socksPort ?? effectiveMixedPort,
            controllerHost: controllerHost,
            controllerPort: controllerPort,
            secret: secret,
            mode: mode,
            tunEnabled: tunEnabled,
            dnsListenHost: dnsListenHost,
            dnsListenPort: dnsListenPort
        )
    }

    private static func keyValue(_ line: String) -> (key: String, value: String)? {
        guard let separator = line.firstIndex(of: ":") else {
            return nil
        }
        let key = line[..<separator].trimmingCharacters(in: .whitespaces)
        let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
        return (key, value)
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2,
              let first = value.first,
              let last = value.last,
              (first == "\"" && last == "\"") || (first == "'" && last == "'") else {
            return value
        }
        return String(value.dropFirst().dropLast())
    }

    private static func hostAndPort(_ value: String) -> (host: String?, port: Int?) {
        let parts = value.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            return (nil, nil)
        }
        return (parts[0], Int(parts[1]))
    }
}
