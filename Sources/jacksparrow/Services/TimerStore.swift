import Foundation
import TimerCore

@MainActor
final class TimerStore: ObservableObject {
    var onTimerFinished: ((TimerItem) -> Void)?

    @Published private(set) var items: [TimerItem] = []
    @Published private(set) var now: Date = .now

    private var tickTask: Task<Void, Never>?
    private let tickInterval: Duration = .milliseconds(250)

    func add(title: String, hours: Int, minutes: Int) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, durationSeconds(hours: hours, minutes: minutes) > 0 else { return }
        items.append(TimerItem(title: trimmed, hours: hours, minutes: minutes))
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        syncTicker()
    }

    func setActive(_ active: Bool) {
        if active {
            syncTicker()
        } else {
            tickTask?.cancel()
            tickTask = nil
        }
    }

    func primaryAction(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        now = .now
        let wasFinished = items[index].state == .finished
        items[index].primaryAction(now: now)
        notifyIfJustFinished(at: index, wasFinished: wasFinished)
        syncTicker()
    }

    private func notifyIfJustFinished(at index: Int, wasFinished: Bool) {
        guard !wasFinished, items[index].state == .finished else { return }
        onTimerFinished?(items[index])
    }

    var menuBarTitle: String? {
        let running = items
            .filter(\.isRunning)
            .map { $0.remaining(at: now) }
        guard let soonest = running.min() else { return nil }
        return formatRemaining(soonest)
    }

    private func syncTicker() {
        if items.contains(where: \.isRunning) {
            startTicker()
        } else {
            tickTask?.cancel()
            tickTask = nil
        }
    }

    private func startTicker() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: self?.tickInterval ?? .milliseconds(250))
                guard !Task.isCancelled, let self else { return }
                self.pulse()
            }
        }
    }

    private func pulse() {
        let instant = Date.now
        now = instant
        for index in items.indices {
            let wasFinished = items[index].state == .finished
            items[index].tick(now: instant)
            notifyIfJustFinished(at: index, wasFinished: wasFinished)
        }
        if !items.contains(where: \.isRunning) {
            tickTask?.cancel()
            tickTask = nil
        }
    }
}
