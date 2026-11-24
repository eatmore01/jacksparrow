import AppKit

struct KeyboardState {
    let keyboard: Keyboard
    let activeMappings: [KeyMapping]

    var isActive: Bool { !activeMappings.isEmpty }
}

struct Snapshot {
    var states: [KeyboardState] = []
    var error: String?

    var activeCount: Int { states.reduce(0) { $0 + $1.activeMappings.count } }
    var activeKeyboards: [KeyboardState] { states.filter { $0.isActive } }
}

@MainActor
final class KeyboardService: ObservableObject {
    @Published private(set) var snapshot = Snapshot()
    @Published private(set) var config = ConfigStore.load()
    @Published private(set) var lastActionError: String?

    private let refreshQueue = DispatchQueue(label: "jacksparrow.keyboard.refresh")
    private let refreshInterval: TimeInterval = 5.0
    private var timer: Timer?

    var currentError: String? { snapshot.error ?? lastActionError }

    var totalMappings: Int { BindingSet.mappings(for: config.bindings).count }

    var headerTitle: String {
        if snapshot.states.isEmpty { return "No external keyboards" }
        let active = snapshot.activeKeyboards
        if active.isEmpty { return "Win mode: OFF" }
        if active.count == 1 { return "Win mode: ON — \(active[0].keyboard.name)" }
        return "Win mode: ON — \(active.count) keyboards"
    }

    func activate() {
        startPolling()
        refreshQueue.async {
            let fresh = Self.readSnapshot()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.snapshot = fresh
                self.applyToEnabledKeyboards()
            }
        }
    }

    func deactivate() {
        stopPolling()
        refreshQueue.async {
            var failure: String?
            for state in Self.readSnapshot().states {
                do {
                    try HIDUtil.reset(state.keyboard)
                } catch {
                    failure = error.localizedDescription
                }
            }
            let fresh = Self.readSnapshot()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.snapshot = fresh
                self.lastActionError = failure
            }
        }
    }

    func refresh() {
        snapshot = Self.readSnapshot()
    }

    func refreshSoon() {
        refreshInBackground()
    }

    func toggleKeyboard(_ keyboard: Keyboard) {
        guard let state = snapshot.states.first(where: { $0.keyboard.id == keyboard.id }) else { return }

        if state.isActive {
            config.enabledKeyboards.remove(keyboard.id)
            perform { try HIDUtil.reset(keyboard) }
            assume(keyboard.id, mappings: [])
        } else {
            let mappings = BindingSet.mappings(for: config.bindings)
            config.enabledKeyboards.insert(keyboard.id)
            perform { try HIDUtil.apply(mappings, to: keyboard) }
            assume(keyboard.id, mappings: mappings)
        }
        ConfigStore.save(config)
        refreshSoon()
    }

    func toggleBinding(_ group: BindingGroup) {
        if config.bindings.contains(group) {
            config.bindings.remove(group)
        } else {
            config.bindings.insert(group)
        }
        ConfigStore.save(config)
        applyToEnabledKeyboards()
        refreshSoon()
    }

    func reapply() {
        applyToEnabledKeyboards()
        refreshSoon()
    }

    func resetAll() {
        for state in snapshot.states {
            perform { try HIDUtil.reset(state.keyboard) }
            assume(state.keyboard.id, mappings: [])
        }
        config.enabledKeyboards.removeAll()
        ConfigStore.save(config)
        refreshSoon()
    }

    private func applyToEnabledKeyboards() {
        let mappings = BindingSet.mappings(for: config.bindings)
        for state in snapshot.states where config.enabledKeyboards.contains(state.keyboard.id) {
            let keyboard = state.keyboard
            perform { try HIDUtil.apply(mappings, to: keyboard) }
            assume(keyboard.id, mappings: mappings)
        }
    }

    private func assume(_ keyboardID: String, mappings: [KeyMapping]) {
        guard let index = snapshot.states.firstIndex(where: { $0.keyboard.id == keyboardID }) else { return }
        let existing = snapshot.states[index].keyboard
        snapshot.states[index] = KeyboardState(keyboard: existing, activeMappings: mappings)
    }

    private func startPolling() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshInBackground()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func refreshInBackground() {
        refreshQueue.async {
            let fresh = Self.readSnapshot()
            Task { @MainActor [weak self] in
                self?.snapshot = fresh
            }
        }
    }

    private nonisolated static func readSnapshot() -> Snapshot {
        var result = Snapshot()
        do {
            for keyboard in try HIDUtil.externalKeyboards() {
                let mappings = (try? HIDUtil.activeMappings(for: keyboard)) ?? []
                result.states.append(KeyboardState(keyboard: keyboard, activeMappings: mappings))
            }
        } catch {
            result.error = error.localizedDescription
        }
        return result
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
            lastActionError = nil
        } catch {
            lastActionError = error.localizedDescription
        }
    }
}
