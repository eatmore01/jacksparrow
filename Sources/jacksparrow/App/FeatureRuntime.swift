import Combine
import Foundation

@MainActor
final class FeatureRuntime: ObservableObject {
    @Published private(set) var available: Set<UtilFeature> = Set(UtilFeature.availableCases)
    @Published private(set) var barLine: String = ""

    private(set) lazy var keyboard = KeyboardService()
    private(set) lazy var chime = ChimeService()

    private var notesService: NotesService?
    private var notesSubscription: AnyCancellable?

    var notes: NotesService {
        if let notesService { return notesService }
        let service = NotesService()
        notesService = service
        return service
    }

    private(set) lazy var timers: TimerStore = {
        let store = TimerStore()
        store.onTimerFinished = { [weak self] _ in self?.chime.play() }
        return store
    }()
    private(set) lazy var scroll = ScrollService()

    private lazy var bindings: [UtilFeature: () -> Void] = [
        .keyboardRemap: { [weak self] in
            guard let self else { return }
            if UtilFeature.keyboardRemap.isAvailable {
                self.keyboard.activate()
            } else {
                self.keyboard.deactivate()
            }
        },
        .timers: { [weak self] in
            guard let self else { return }
            self.timers.setActive(UtilFeature.timers.isAvailable)
        },
        .notes: { [weak self] in
            guard let self else { return }
            if UtilFeature.notes.isAvailable {
                let service = self.notes
                service.load()
                self.notesSubscription = service.$barLine.sink { [weak self] line in
                    self?.barLine = line
                }
            } else {
                self.notesSubscription = nil
                self.notesService?.flush()
                self.barLine = ""
            }
        },
        .scrollInvert: { [weak self] in
            guard let self else { return }
            if UtilFeature.scrollInvert.isAvailable {
                self.scroll.activate()
            } else {
                self.scroll.deactivate()
            }
        }
    ]

    var availableFeatures: [UtilFeature] { UtilFeature.allCases.filter { available.contains($0) } }

    func start() {
        for feature in UtilFeature.allCases where feature.isAvailable {
            bindings[feature]?()
        }
    }

    func setAvailable(_ feature: UtilFeature, _ value: Bool) {
        Defaults.set(value, forKey: feature.availabilityKey)
        available = Set(UtilFeature.availableCases)
        bindings[feature]?()
    }

    func refreshVisibleState() {
        if UtilFeature.notes.isAvailable {
            notes.reloadIfChangedOnDisk()
        }
        guard UtilFeature.keyboardRemap.isAvailable else { return }
        keyboard.refreshSoon()
    }

    func flushPendingWork() {
        notesService?.flush()
    }
}
