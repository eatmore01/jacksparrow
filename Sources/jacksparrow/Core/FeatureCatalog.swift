import Foundation

enum UtilFeature: String, CaseIterable, Hashable {
    case keyboardRemap
    case timers
    case scrollInvert = "shliker"

    var title: String {
        switch self {
        case .keyboardRemap: return "Keyboard"
        case .timers:        return "Timers"
        case .scrollInvert:  return "Shliker"
        }
    }

    var detail: String {
        switch self {
        case .keyboardRemap: return "Remap Alt and Cmd on external keyboards"
        case .timers:        return "Countdown timers with a stop limit"
        case .scrollInvert:  return "Invert wheel scrolling on external mice, trackpad untouched"
        }
    }

    var iconResource: String {
        switch self {
        case .keyboardRemap: return "StatusIcon"
        case .timers:        return "TimerIcon"
        case .scrollInvert:  return "ShlikerIcon"
        }
    }

    var symbolName: String {
        switch self {
        case .keyboardRemap: return "keyboard"
        case .timers:        return "timer"
        case .scrollInvert:  return "computermouse"
        }
    }

    var enabledByDefault: Bool { true }

    var availabilityKey: String { "feature.\(rawValue).available" }

    var isAvailable: Bool { Defaults.bool(availabilityKey, default: enabledByDefault) }

    static var availableCases: [UtilFeature] { allCases.filter(\.isAvailable) }
}
