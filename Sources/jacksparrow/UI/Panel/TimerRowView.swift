import SwiftUI
import TimerCore

struct TimerRowView: View {
    let item: TimerItem
    let now: Date
    let onPrimary: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: actionIcon)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: MenuTheme.checkColumn, alignment: .leading)
                .foregroundStyle(hovering ? Color.white : actionTint)

            Text(item.title)
                .font(MenuTheme.itemFont)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            StopDots(used: item.stopsUsed, hovering: hovering)
                .padding(.trailing, 8)

            Text(formatRemaining(item.remaining(at: now)))
                .font(MenuTheme.itemFont)
                .monospacedDigit()
                .foregroundStyle(hovering ? Color.white : timeTint)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 16, height: 16)
                    .foregroundStyle(hovering ? Color.white.opacity(0.8) : MenuTheme.dimmedText)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .allowsHitTesting(hovering)
            .help("Delete timer")
            .padding(.leading, 4)
        }
        .padding(.horizontal, MenuTheme.contentInset)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hovering ? MenuTheme.highlight : .clear, in: RoundedRectangle(cornerRadius: MenuTheme.corner))
        .foregroundStyle(hovering ? Color.white : MenuTheme.primaryText)
        .contentShape(Rectangle())
        .onTapGesture(perform: onPrimary)
        .padding(.horizontal, MenuTheme.outerInset)
        .onHover { hovering = $0 }
        .help(actionHelp)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityValue(formatRemaining(item.remaining(at: now)))
    }

    private var timeTint: Color {
        switch item.state {
        case .finished:       return MenuTheme.dimmedText
        case .running:        return MenuTheme.primaryText
        case .idle, .paused:  return MenuTheme.secondaryText
        }
    }

    private var actionIcon: String {
        switch item.pendingAction {
        case .start, .resume:    return "play.fill"
        case .pause:             return "pause.fill"
        case .resetAfterLimit:   return "stop.fill"
        case .resetAfterFinish:  return "arrow.counterclockwise"
        }
    }

    private var actionTint: Color {
        switch item.pendingAction {
        case .start, .resume:    return MenuTheme.running
        case .pause:             return MenuTheme.secondaryText
        case .resetAfterLimit:   return MenuTheme.danger
        case .resetAfterFinish:  return MenuTheme.secondaryText
        }
    }

    private var actionHelp: String {
        switch item.pendingAction {
        case .start:            return "Start"
        case .resume:           return "Resume"
        case .pause:            return "Stop (\(item.stopsRemaining - 1) of \(TimerItem.maxStops) left)"
        case .resetAfterLimit:  return "No stops left - reset timer"
        case .resetAfterFinish: return "Reset"
        }
    }
}

private struct StopDots: View {
    let used: Int
    let hovering: Bool

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<TimerItem.maxStops, id: \.self) { index in
                Circle()
                    .fill(color(at: index))
                    .frame(width: 4, height: 4)
            }
        }
        .help("Stops used \(used) of \(TimerItem.maxStops)")
    }

    private func color(at index: Int) -> Color {
        guard index < used else {
            return hovering ? Color.white.opacity(0.3) : MenuTheme.divider
        }
        if used >= TimerItem.maxStops { return MenuTheme.danger }
        return hovering ? Color.white : MenuTheme.secondaryText
    }
}
