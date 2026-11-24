import SwiftUI
import TimerCore

struct TimersSection: View {
    @ObservedObject var store: TimerStore
    @ObservedObject var chime: ChimeService

    private var activeSummary: String {
        let running = store.items.filter(\.isRunning).count
        return "Active: \(running) of \(store.items.count)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuSectionHeader(title: "Timers")

            if store.items.isEmpty {
                MenuCaption(text: "No timers yet")
            } else {
                ForEach(store.items) { item in
                    TimerRowView(
                        item: item,
                        now: store.now,
                        onPrimary: { store.primaryAction(item.id) },
                        onDelete: { store.remove(item.id) }
                    )
                }
                MenuCaption(text: activeSummary)
            }

            MenuDivider()

            AddTimerView { title, hours, minutes in
                store.add(title: title, hours: hours, minutes: minutes)
            }
            .padding(.bottom, 2)

            MenuDivider()

            SoundSettingsView(chime: chime)
        }
    }
}
