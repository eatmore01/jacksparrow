import Foundation

public enum RunState: Equatable, Sendable {
    case idle
    case running(endDate: Date)
    case paused(remaining: TimeInterval)
    case finished
}

public enum TimerAction: Equatable, Sendable {
    case start
    case pause
    case resume
    case resetAfterLimit
    case resetAfterFinish
}

public struct TimerItem: Identifiable, Equatable, Sendable {
    public static let maxStops = 2
    public static let maxHours = 23
    public static let maxMinutes = 60

    public let id: UUID
    public var title: String
    public let hours: Int
    public let minutes: Int
    public var state: RunState
    public var stopsUsed: Int

    public init(
        id: UUID = UUID(),
        title: String,
        hours: Int = 0,
        minutes: Int,
        state: RunState = .idle,
        stopsUsed: Int = 0
    ) {
        self.id = id
        self.title = title
        self.hours = Self.clampHours(hours)
        self.minutes = Self.clampMinutes(minutes)
        self.state = state
        self.stopsUsed = stopsUsed
    }

    public static func clampHours(_ value: Int) -> Int {
        min(maxHours, max(0, value))
    }

    public static func clampMinutes(_ value: Int) -> Int {
        min(maxMinutes, max(0, value))
    }

    public var duration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60)
    }

    public var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    public var stopsRemaining: Int {
        max(0, Self.maxStops - stopsUsed)
    }

    public func remaining(at now: Date) -> TimeInterval {
        switch state {
        case .idle:
            return duration
        case .running(let endDate):
            return max(0, endDate.timeIntervalSince(now))
        case .paused(let remaining):
            return max(0, remaining)
        case .finished:
            return 0
        }
    }

    public var pendingAction: TimerAction {
        switch state {
        case .idle:
            return .start
        case .paused:
            return .resume
        case .running:
            return stopsUsed >= Self.maxStops ? .resetAfterLimit : .pause
        case .finished:
            return .resetAfterFinish
        }
    }

    public mutating func primaryAction(now: Date) {
        tick(now: now)
        switch pendingAction {
        case .start, .resume:
            let left = remaining(at: now)
            state = left > 0 ? .running(endDate: now.addingTimeInterval(left)) : .finished
        case .pause:
            state = .paused(remaining: remaining(at: now))
            stopsUsed += 1
        case .resetAfterLimit, .resetAfterFinish:
            state = .idle
            stopsUsed = 0
        }
    }

    public mutating func tick(now: Date) {
        guard case .running = state, remaining(at: now) <= 0 else { return }
        state = .finished
    }
}
