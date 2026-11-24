import SwiftUI

struct ShlikerSection: View {
    @ObservedObject var service: ScrollService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuStatusLine(text: service.statusTitle, tint: statusTint)

            MenuDivider()

            MenuSectionHeader(title: "Scroll")

            MenuItemRow(
                title: "Invert wheel scroll",
                isChecked: service.isEnabled,
                tooltip: "Flip the scroll direction for mice with a classic wheel",
                action: { service.setEnabled(!service.isEnabled) }
            )

            MenuCaption(text: "Trackpad and Magic Mouse keep their own direction")

            if service.needsAttention {
                MenuItemRow(
                    title: "Re-check access",
                    tooltip: "Try to install the scroll tap again right now",
                    action: { service.recheckAccess() }
                )

                MenuItemRow(
                    title: "Open Accessibility settings",
                    tooltip: "System Settings → Privacy & Security → Accessibility",
                    action: { service.requestPermission() }
                )

                MenuCaption(text: accessDiagnostics)

                MenuCaption(text: "If the checkbox is already on, the entry went stale after a rebuild")
                MenuCaption(text: "Remove jacksparrow from the list, then add it again")
                MenuCaption(text: "Retrying every second — starts by itself once access lands")
            }

            MenuDivider()

            MenuCaption(text: "Inverted events: \(service.invertedEvents)")
        }
        .onAppear { service.flushCounter() }
    }

    private var accessDiagnostics: String {
        "System reports access: \(service.systemReportsAccess ? "yes" : "no") · attempts: \(service.attempts)"
    }

    private var statusTint: Color {
        switch service.state {
        case .running:                     return MenuTheme.running
        case .paused:                      return MenuTheme.secondaryText
        case .needsPermission, .refused:   return MenuTheme.danger
        case .stopped:                     return MenuTheme.dimmedText
        }
    }
}
