import Foundation

enum UtilFeature: String, CaseIterable, Hashable {
    case keyboardRemap
    case timers
    case scrollInvert = "shliker"
    case notes = "gratte"

    var title: String {
        switch self {
        case .keyboardRemap: return "Keyboard"
        case .timers:        return "Timers"
        case .scrollInvert:  return "Shliker"
        case .notes:         return "gratté"
        }
    }

    var detail: String {
        switch self {
        case .keyboardRemap: return "Remap Alt and Cmd on external keyboards"
        case .timers:        return "Countdown timers with a stop limit"
        case .scrollInvert:  return "Invert wheel scrolling on external mice, trackpad untouched"
        case .notes:         return "Scratch canvas with one line pinned to the menu bar"
        }
    }

    var iconResource: String {
        switch self {
        case .keyboardRemap: return "StatusIcon"
        case .timers:        return "TimerIcon"
        case .scrollInvert:  return "ShlikerIcon"
        case .notes:         return "NotesIcon"
        }
    }

    var symbolName: String {
        switch self {
        case .keyboardRemap: return "keyboard"
        case .timers:        return "timer"
        case .scrollInvert:  return "computermouse"
        case .notes:         return "note.text"
        }
    }

    var enabledByDefault: Bool { true }

    var availabilityKey: String { "feature.\(rawValue).available" }

    var isAvailable: Bool { Defaults.bool(availabilityKey, default: enabledByDefault) }

    static var availableCases: [UtilFeature] { allCases.filter(\.isAvailable) }
}
