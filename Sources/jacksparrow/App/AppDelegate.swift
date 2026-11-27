import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let runtime = FeatureRuntime()
    private let statusController = StatusItemController()
    private let popover = NSPopover()
    private var lastCloseDate = Date.distantPast
    private var cancellables: Set<AnyCancellable> = []
    private let reopenGuard: TimeInterval = 0.2

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpPopover()

        statusController.onLeftClick = { [weak self] in self?.togglePopover() }
        statusController.onRightClick = { [weak self] _ in self?.togglePopover() }
        statusController.install()

        runtime.$barLine
            .removeDuplicates()
            .sink { [weak self] line in self?.statusController.setBarLine(line) }
            .store(in: &cancellables)

        runtime.start()
        warmUpPanel()
    }

    private func setUpPopover() {
        popover.behavior = .transient
        popover.delegate = self
        popover.animates = false
        let host = NSHostingController(rootView: PanelView(runtime: runtime))
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
    }

    private func warmUpPanel() {
        guard let view = popover.contentViewController?.view else { return }
        view.layoutSubtreeIfNeeded()
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        guard Date().timeIntervalSince(lastCloseDate) > reopenGuard else { return }
        guard let button = statusController.button else { return }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        runtime.refreshVisibleState()
    }

    func popoverDidClose(_ notification: Notification) {
        lastCloseDate = Date()
        runtime.flushPendingWork()
    }

    func applicationWillTerminate(_ notification: Notification) {
        runtime.flushPendingWork()
    }
}
