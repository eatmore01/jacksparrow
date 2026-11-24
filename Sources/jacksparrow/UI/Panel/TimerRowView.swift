import SwiftUI
import TimerCore

struct TimerRowView: View {
    let item: TimerItem
    let now: Date
    let onPrimary: () -> Void
    let onDelete: () -> Void

    @State private var rowHovering = false

    var body: some View {
        HStack(spacing: 0) {
            RowButton(
                icon: actionIcon,
                tint: actionTint,
                hoverTint: MenuTheme.highlight,
                help: actionHelp,
                action: onPrimary
            )
            .frame(width: MenuTheme.checkColumn, alignment: .leading)

            Text(item.title)
                .font(MenuTheme.itemFont)
                .foregroundStyle(MenuTheme.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.leading, 3)

            Spacer(minLength: 8)

            Text("\(item.stopsUsed)/\(TimerItem.maxStops)")
                .font(MenuTheme.captionFont)
                .monospacedDigit()
                .foregroundStyle(stopsTint)
                .help("Stops used \(item.stopsUsed) of \(TimerItem.maxStops)")
                .padding(.trailing, 8)

            Text(formatRemaining(item.remaining(at: now)))
                .font(MenuTheme.itemFont)
                .monospacedDigit()
                .foregroundStyle(timeTint)

            RowButton(
                icon: "xmark",
                tint: MenuTheme.dimmedText,
                hoverTint: MenuTheme.danger,
                help: "Delete timer",
                isVisible: rowHovering,
                action: onDelete
            )
            .padding(.leading, 6)
        }
        .padding(.horizontal, MenuTheme.contentInset)
        .padding(.vertical, 3)
        .padding(.horizontal, MenuTheme.outerInset)
        .contentShape(Rectangle())
        .onHover { rowHovering = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(item.title)
        .accessibilityValue(formatRemaining(item.remaining(at: now)))
    }

    private var stopsTint: Color {
        item.stopsRemaining == 0 ? MenuTheme.danger : MenuTheme.dimmedText
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

private struct RowButton: View {
    let icon: String
    let tint: Color
    let hoverTint: Color
    let help: String
    var isVisible = true
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(hovering ? Color.white : tint)
                .frame(width: 17, height: 17)
                .background(hovering ? hoverTint : .clear, in: RoundedRectangle(cornerRadius: 4))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .onHover { hovering = $0 }
        .pointingHand(isVisible)
        .help(help)
        .accessibilityLabel(help)
    }
}
