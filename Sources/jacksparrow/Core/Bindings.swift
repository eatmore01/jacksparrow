import Foundation

enum HIDKey {
    static let escape: UInt64        = 0x700000029
    static let capsLock: UInt64      = 0x700000039
    static let application: UInt64   = 0x700000065
    static let leftControl: UInt64   = 0x7000000E0
    static let leftShift: UInt64     = 0x7000000E1
    static let leftAlt: UInt64       = 0x7000000E2
    static let leftCommand: UInt64   = 0x7000000E3
    static let rightControl: UInt64  = 0x7000000E4
    static let rightShift: UInt64    = 0x7000000E5
    static let rightAlt: UInt64      = 0x7000000E6
    static let rightCommand: UInt64  = 0x7000000E7
}

enum BindingGroup: String, CaseIterable, Codable {
    case leftAltCommandSwap
    case rightAltCommandSwap
    case menuToRightCommand

    var title: String {
        switch self {
        case .leftAltCommandSwap:  return "Swap Alt ⇄ Cmd — left"
        case .rightAltCommandSwap: return "Swap Alt ⇄ Cmd — right"
        case .menuToRightCommand:  return "Menu → Right Cmd"
        }
    }

    var detail: String {
        switch self {
        case .leftAltCommandSwap:
            return "The key next to the spacebar becomes Command, as on a Mac"
        case .rightAltCommandSwap:
            return "Breaks AltGr if you need it to type symbols"
        case .menuToRightCommand:
            return "The Menu key does nothing on macOS"
        }
    }

    var enabledByDefault: Bool { true }

    var mappings: [KeyMapping] {
        switch self {
        case .leftAltCommandSwap:
            return [
                KeyMapping(src: HIDKey.leftAlt, dst: HIDKey.leftCommand),
                KeyMapping(src: HIDKey.leftCommand, dst: HIDKey.leftAlt)
            ]
        case .rightAltCommandSwap:
            return [
                KeyMapping(src: HIDKey.rightAlt, dst: HIDKey.rightCommand),
                KeyMapping(src: HIDKey.rightCommand, dst: HIDKey.rightAlt)
            ]
        case .menuToRightCommand:
            return [KeyMapping(src: HIDKey.application, dst: HIDKey.rightCommand)]
        }
    }
}

enum BindingSet {
    static func mappings(for groups: Set<BindingGroup>) -> [KeyMapping] {
        var seenSources = Set<UInt64>()
        var result: [KeyMapping] = []
        for group in BindingGroup.allCases where groups.contains(group) {
            for mapping in group.mappings where seenSources.insert(mapping.src).inserted {
                result.append(mapping)
            }
        }
        return result
    }
}
