import Foundation

extension ConfigManager {
    func configuredProviderBaseURL() -> URL? {
        let configURL = codexURL.appendingPathComponent("config.toml")
        guard let text = try? String(contentsOf: configURL, encoding: .utf8) else { return nil }

        var inManagedProvider = false
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("[") {
                inManagedProvider = line == "[model_providers.\(ConfigComposer.providerID)]"
                continue
            }
            guard inManagedProvider, line.hasPrefix("base_url") else { continue }
            guard let equals = line.firstIndex(of: "=") else { continue }
            let value = line[line.index(after: equals)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            return URL(string: value)
        }
        return nil
    }

    func configuredBridgePort() -> UInt16? {
        guard let url = configuredProviderBaseURL(),
              url.host == "127.0.0.1" || url.host == "localhost",
              let port = url.port,
              (1...65535).contains(port) else { return nil }
        return UInt16(port)
    }

    func isConfiguredForLocalBridge() -> Bool {
        configuredBridgePort() != nil
    }
}
