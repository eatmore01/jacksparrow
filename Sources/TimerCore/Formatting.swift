import Foundation

public func formatRemaining(_ seconds: TimeInterval) -> String {
    let total = Int(ceil(max(0, seconds)))
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let secs = total % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
    return String(format: "%02d:%02d", minutes, secs)
}

public func durationSeconds(hours: Int, minutes: Int) -> TimeInterval {
    TimeInterval(max(0, hours) * 3600 + max(0, minutes) * 60)
}
