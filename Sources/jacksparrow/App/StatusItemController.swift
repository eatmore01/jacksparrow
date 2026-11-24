import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var onLeftClick: (() -> Void)?
    var onRightClick: ((NSStatusBarButton?) -> Void)?

    var button: NSStatusBarButton? { statusItem.button }

    private lazy var brandImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "StatusIcon", withExtension: "png"),
              let image = NSImage(contentsOf: url), image.size.height > 0 else { return nil }
        let height = min(18, max(15, NSStatusBar.system.thickness - 6))
        let aspect = image.size.width / image.size.height
        image.size = NSSize(width: (height * aspect).rounded(), height: height)
        image.isTemplate = false
        return image
    }()

    func install() {
        statusItem.autosaveName = "jacksparrow.main"
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(clicked)
        button.sendAction(on: [.leftMouseDown, .rightMouseUp])
        updateIconAppearance()
    }

    func updateIconAppearance() {
        guard let button = statusItem.button else { return }
        button.toolTip = "jacksparrow"
        button.alphaValue = 1.0

        if let brand = brandImage {
            brand.accessibilityDescription = "jacksparrow"
            button.image = brand
            button.title = ""
            button.imagePosition = .imageOnly
        } else if let symbol = NSImage(systemSymbolName: "circle.grid.2x2", accessibilityDescription: "jacksparrow") {
            symbol.isTemplate = true
            button.image = symbol
            button.title = ""
            button.imagePosition = .imageOnly
        } else {
            button.image = nil
            button.title = "JS"
            button.imagePosition = .noImage
        }
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            onRightClick?(statusItem.button)
        } else {
            onLeftClick?()
        }
    }
}
