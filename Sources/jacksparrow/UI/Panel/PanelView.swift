import SwiftUI

struct PanelView: View {
    @ObservedObject var runtime: FeatureRuntime
    @State private var selection: PanelTab?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            UtilSelector(features: runtime.availableFeatures, selection: tabBinding)

            MenuDivider()

            content

            MenuDivider()

            PanelFooter()
        }
        .frame(width: MenuTheme.width)
        .background(MenuTheme.background)
        .environment(\.colorScheme, .dark)
    }

    private var tabBinding: Binding<PanelTab> {
        Binding(get: { effectiveTab }, set: { selection = $0 })
    }

    private var effectiveTab: PanelTab {
        if let selection, isReachable(selection) { return selection }
        return runtime.availableFeatures.first.map { PanelTab.util($0) } ?? .settings
    }

    private func isReachable(_ tab: PanelTab) -> Bool {
        switch tab {
        case .settings: return true
        case .util(let feature): return runtime.available.contains(feature)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch effectiveTab {
        case .util(.keyboardRemap):
            KeyboardSection(service: runtime.keyboard)
        case .util(.timers):
            TimersSection(store: runtime.timers, chime: runtime.chime)
        case .util(.scrollInvert):
            ShlikerSection(service: runtime.scroll)
        case .util(.notes):
            NotesSection(service: runtime.notes)
        case .settings:
            SettingsSection(runtime: runtime)
        }
    }
}

private struct PanelFooter: View {
    var body: some View {
        MenuItemRow(title: "Quit", shortcut: "\u{2318}Q") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
        .padding(.bottom, 5)
    }
}
