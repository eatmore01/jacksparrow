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

    static func string(_ key: String, default fallback: String?) -> String? {
        store.string(forKey: key) ?? fallback
    }

    static func set(_ value: String?, forKey key: String) {
        if let value {
            store.set(value, forKey: key)
        } else {
            store.removeObject(forKey: key)
        }
    }

    static func double(_ key: String, default fallback: Double) -> Double {
        guard store.object(forKey: key) != nil else { return fallback }
        return store.double(forKey: key)
    }

    static func set(_ value: Double, forKey key: String) {
        store.set(value, forKey: key)
    }
}
