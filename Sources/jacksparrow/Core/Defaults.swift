import Foundation

enum Defaults {
    private static var store: UserDefaults { .standard }

    static func bool(_ key: String, default fallback: Bool) -> Bool {
        guard store.object(forKey: key) != nil else { return fallback }
        return store.bool(forKey: key)
    }

    static func set(_ value: Bool, forKey key: String) {
        store.set(value, forKey: key)
    }
}
