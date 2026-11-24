import Foundation

struct Keyboard: Hashable {
    let vendorID: Int
    let productID: Int
    let name: String

    var id: String { "\(vendorID):\(productID)" }

    var isBuiltInLookalike: Bool { vendorID == 0 && productID == 0 }

    var matchingDictionary: [String: Any] {
        [
            "VendorID": vendorID,
            "ProductID": productID,
            "PrimaryUsagePage": 1,
            "PrimaryUsage": 6
        ]
    }
}

struct KeyMapping: Hashable {
    let src: UInt64
    let dst: UInt64
}

enum HIDUtilError: LocalizedError {
    case launchFailed(String)
    case exitStatus(Int32, String)
    case refusedBuiltIn

    var errorDescription: String? {
        switch self {
        case .launchFailed(let message):
            return "Could not launch hidutil: \(message)"
        case .exitStatus(let code, let output):
            return "hidutil exited with code \(code): \(output)"
        case .refusedBuiltIn:
            return "Refused: the target looks like the built-in keyboard"
        }
    }
}

enum HIDUtil {
    static let executablePath = "/usr/bin/hidutil"

    @discardableResult
    static func run(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let output = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = output
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw HIDUtilError.launchFailed(error.localizedDescription)
        }

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let stdoutText = String(data: outputData, encoding: .utf8) ?? ""
        let stderrText = String(data: errorData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw HIDUtilError.exitStatus(process.terminationStatus, stderrText.isEmpty ? stdoutText : stderrText)
        }
        return stdoutText
    }

    static func externalKeyboards() throws -> [Keyboard] {
        let entries = try listEntries()
        let manufacturers = manufacturerIndex(from: entries)

        var seen = Set<String>()
        var result: [Keyboard] = []

        for entry in entries {
            guard (entry["type"] as? String) == "service" else { continue }
            guard (entry["Built-In"] as? Bool) != true else { continue }

            let vendorID = (entry["VendorID"] as? NSNumber)?.intValue ?? 0
            let productID = (entry["ProductID"] as? NSNumber)?.intValue ?? 0
            guard !(vendorID == 0 && productID == 0) else { continue }

            let manufacturer = identityKeys(for: entry).compactMap { manufacturers[$0] }.first
            let keyboard = Keyboard(
                vendorID: vendorID,
                productID: productID,
                name: displayName(
                    product: text(entry["Product"]),
                    manufacturer: manufacturer ?? text(entry["Manufacturer"]),
                    vendorID: vendorID,
                    productID: productID
                )
            )
            guard seen.insert(keyboard.id).inserted else { continue }
            result.append(keyboard)
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func listEntries() throws -> [[String: Any]] {
        let output = try run(["list", "--ndjson", "--matching", "keyboard"])
        return output.split(separator: "\n").compactMap { line in
            guard let data = line.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
            return object as? [String: Any]
        }
    }

    private static func manufacturerIndex(from entries: [[String: Any]]) -> [String: String] {
        var index: [String: String] = [:]
        for entry in entries {
            guard let manufacturer = text(entry["Manufacturer"]) else { continue }
            for key in identityKeys(for: entry) where index[key] == nil {
                index[key] = manufacturer
            }
        }
        return index
    }

    private static func identityKeys(for entry: [String: Any]) -> [String] {
        let vendorID = (entry["VendorID"] as? NSNumber)?.intValue ?? 0
        let productID = (entry["ProductID"] as? NSNumber)?.intValue ?? 0
        var keys: [String] = []
        if let location = (entry["LocationID"] as? NSNumber)?.intValue {
            keys.append("\(vendorID):\(productID):\(location)")
        }
        keys.append("\(vendorID):\(productID)")
        return keys
    }

    private static func text(_ value: Any?) -> String? {
        guard let string = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty else { return nil }
        return string
    }

    static func displayName(product: String?, manufacturer: String?, vendorID: Int, productID: Int) -> String {
        if let product {
            guard let manufacturer else { return product }
            if product.localizedCaseInsensitiveContains(manufacturer) { return product }
            return "\(manufacturer) \(product)"
        }
        if let manufacturer { return "\(manufacturer) Keyboard" }
        return String(format: "Keyboard 0x%04X:0x%04X", vendorID, productID)
    }

    static func activeMappings(for keyboard: Keyboard) throws -> [KeyMapping] {
        let output = try run(["property", "--matching", json(keyboard.matchingDictionary), "--get", "UserKeyMapping"])
        return parseMappings(output)
    }

    static func apply(_ mappings: [KeyMapping], to keyboard: Keyboard) throws {
        guard !keyboard.isBuiltInLookalike else { throw HIDUtilError.refusedBuiltIn }
        let payload: [String: Any] = [
            "UserKeyMapping": mappings.map {
                [
                    "HIDKeyboardModifierMappingSrc": NSNumber(value: $0.src),
                    "HIDKeyboardModifierMappingDst": NSNumber(value: $0.dst)
                ]
            }
        ]
        try run(["property", "--matching", json(keyboard.matchingDictionary), "--set", json(payload)])
    }

    static func reset(_ keyboard: Keyboard) throws {
        try apply([], to: keyboard)
    }

    static func parseMappings(_ output: String) -> [KeyMapping] {
        var result: [KeyMapping] = []
        for block in output.components(separatedBy: "{").dropFirst() {
            let body = block.components(separatedBy: "}").first ?? block
            guard let src = number(named: "HIDKeyboardModifierMappingSrc", in: body),
                  let dst = number(named: "HIDKeyboardModifierMappingDst", in: body) else { continue }
            result.append(KeyMapping(src: src, dst: dst))
        }
        return result
    }

    private static func number(named key: String, in text: String) -> UInt64? {
        guard let range = text.range(of: key) else { return nil }
        let tail = text[range.upperBound...]
        guard let equals = tail.firstIndex(of: "=") else { return nil }
        let digits = tail[tail.index(after: equals)...]
            .prefix { $0 == " " || $0.isHexDigit || $0 == "x" || $0 == "X" }
            .trimmingCharacters(in: .whitespaces)
        if digits.lowercased().hasPrefix("0x") {
            return UInt64(digits.dropFirst(2), radix: 16)
        }
        return UInt64(digits)
    }

    private static func json(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
