import AppKit
import UniformTypeIdentifiers

@MainActor
final class ChimeService: ObservableObject {
    static let builtinTitle = "alredy red"

    private static let enabledKey = "timers.sound.enabled"
    private static let customKey = "timers.sound.customPath"
    private static let volumeKey = "timers.sound.volume"
    private static let builtinResource = "AlertSound"
    private static let builtinExtension = "mp3"

    @Published private(set) var isEnabled = Defaults.bool(ChimeService.enabledKey, default: true)
    @Published private(set) var customPath = Defaults.string(ChimeService.customKey, default: nil)
    @Published private(set) var volume = Defaults.double(ChimeService.volumeKey, default: 0.7)

    private var player: NSSound?

    var usesCustomFile: Bool { !(customPath ?? "").isEmpty }

    var customFileName: String? {
        guard let customPath, !customPath.isEmpty else { return nil }
        return (customPath as NSString).lastPathComponent
    }

    var currentTitle: String {
        guard isEnabled else { return "off" }
        return customFileName ?? Self.builtinTitle
    }

    var builtinIsAvailable: Bool { Self.builtinURL != nil }

    func setEnabled(_ value: Bool) {
        guard value != isEnabled else { return }
        isEnabled = value
        Defaults.set(value, forKey: Self.enabledKey)
        if value { preview() } else { player?.stop() }
    }

    func setVolume(_ value: Double) {
        let clamped = min(1, max(0, value))
        guard clamped != volume else { return }
        volume = clamped
        Defaults.set(clamped, forKey: Self.volumeKey)
    }

    func useBuiltin() {
        guard usesCustomFile else {
            preview()
            return
        }
        customPath = nil
        Defaults.set(String?.none, forKey: Self.customKey)
        preview()
    }

    func chooseCustomFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Use sound"
        NSApp.activate(ignoringOtherApps: true)

        guard panel.runModal() == .OK, let url = panel.url else { return }
        customPath = url.path
        Defaults.set(url.path, forKey: Self.customKey)
        preview()
    }

    func preview() {
        guard isEnabled else { return }
        play()
    }

    func play() {
        guard isEnabled, let sound = makeSound() else { return }
        player?.stop()
        sound.volume = Float(volume)
        player = sound
        sound.play()
    }

    private static var builtinURL: URL? {
        Bundle.main.url(forResource: builtinResource, withExtension: builtinExtension)
    }

    private func makeSound() -> NSSound? {
        if let customPath, !customPath.isEmpty {
            return NSSound(contentsOfFile: customPath, byReference: true)
        }
        guard let url = Self.builtinURL else { return nil }
        return NSSound(contentsOf: url, byReference: true)
    }
}
