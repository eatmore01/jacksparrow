import SwiftUI

struct KeyboardSection: View {
    @ObservedObject var service: KeyboardService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuCaption(text: service.headerTitle)

            if let error = service.currentError {
                MenuCaption(text: "Error: \(error)")
            }

            MenuDivider()

            MenuSectionHeader(title: "Keyboards")

            if service.snapshot.states.isEmpty {
                MenuCaption(text: "connect an external keyboard")
            } else {
                ForEach(service.snapshot.states, id: \.keyboard.id) { state in
                    MenuItemRow(
                        title: state.keyboard.name,
                        isChecked: state.isActive,
                        tooltip: String(
                            format: "VendorID 0x%04X · ProductID 0x%04X · active remaps: %d",
                            state.keyboard.vendorID,
                            state.keyboard.productID,
                            state.activeMappings.count
                        ),
                        action: { service.toggleKeyboard(state.keyboard) }
                    )
                }
            }

            MenuDivider()

            MenuSectionHeader(title: "Bindings")

            ForEach(BindingGroup.allCases, id: \.self) { group in
                MenuItemRow(
                    title: group.title,
                    isChecked: service.config.bindings.contains(group),
                    tooltip: group.detail,
                    action: { service.toggleBinding(group) }
                )
            }

            MenuDivider()

            MenuCaption(text: "Active remaps: \(service.snapshot.activeCount) of \(service.totalMappings)")

            MenuItemRow(title: "Reapply", shortcut: "⌘R") {
                service.reapply()
            }
            .keyboardShortcut("r", modifiers: .command)

            MenuItemRow(title: "Reset all") {
                service.resetAll()
            }
        }
        .onAppear { service.refreshSoon() }
    }
}
