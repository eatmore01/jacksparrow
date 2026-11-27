import Foundation

@MainActor
final class NotesService: ObservableObject {
    @Published private(set) var text: String = ""
    @Published private(set) var barLine: String = Defaults.string(NotesService.barKey, default: "") ?? ""
    @Published private(set) var lastSaved: Date?
    @Published private(set) var lastError: String?

    private static let barKey = "notes.barLine"
    private let saveDelay: Duration = .milliseconds(500)

    private var saveTask: Task<Void, Never>?
    private var knownModification: Date?
    private var loaded = false

    static var fileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("jacksparrow", isDirectory: true)
            .appendingPathComponent("notes.md")
    }

    var fileDisplayPath: String { "~/.config/jacksparrow/notes.md" }

    func load() {
        guard !loaded else { return }
        loaded = true
        readFromDisk()
    }

    func reloadIfChangedOnDisk() {
        guard loaded, saveTask == nil else { return }
        let current = modificationDate()
        guard current != knownModification else { return }
        readFromDisk()
    }

    func update(_ newText: String) {
        guard newText != text else { return }
        text = newText
        scheduleSave()
    }

    func setBarLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != barLine else { return }
        barLine = trimmed
        Defaults.set(trimmed.isEmpty ? String?.none : trimmed, forKey: Self.barKey)
    }

    func flush() {
        saveTask?.cancel()
        saveTask = nil
        writeToDisk()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.saveDelay)
            guard !Task.isCancelled else { return }
            self.saveTask = nil
            self.writeToDisk()
        }
    }

    private func readFromDisk() {
        let url = Self.fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            text = ""
            knownModification = nil
            return
        }
        do {
            text = try String(contentsOf: url, encoding: .utf8)
            knownModification = modificationDate()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func writeToDisk() {
        let url = Self.fileURL
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(text.utf8).write(to: url, options: .atomic)
            knownModification = modificationDate()
            lastSaved = Date()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func modificationDate() -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: Self.fileURL.path)
        return attributes?[.modificationDate] as? Date
    }
}
