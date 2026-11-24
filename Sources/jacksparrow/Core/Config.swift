import Foundation

struct Config: Codable {
    var enabledKeyboards: Set<String>
    var bindings: Set<BindingGroup>

    static var fallback: Config {
        Config(
            enabledKeyboards: [],
            bindings: Set(BindingGroup.allCases.filter { $0.enabledByDefault })
        )
    }
}

enum ConfigStore {
    static var fileURL: URL {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("jacksparrow", isDirectory: true)
        return base.appendingPathComponent("config.json")
    }

    static func load() -> Config {
        guard let data = try? Data(contentsOf: fileURL),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return .fallback
        }
        return config
    }

    static func save(_ config: Config) {
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(config) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
