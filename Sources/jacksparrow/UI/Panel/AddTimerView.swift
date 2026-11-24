import SwiftUI
import TimerCore

struct AddTimerView: View {
    let onAdd: (String, Int, Int) -> Void

    private enum Field: Hashable {
        case title, hours, minutes
    }

    @State private var expanded = false
    @State private var title = ""
    @State private var hoursText = "0"
    @State private var minutesText = "40"
    @State private var hovering = false
    @FocusState private var focus: Field?

    private var hours: Int {
        TimerItem.clampHours(Int(hoursText.trimmingCharacters(in: .whitespaces)) ?? 0)
    }

    private var minutes: Int {
        TimerItem.clampMinutes(Int(minutesText.trimmingCharacters(in: .whitespaces)) ?? 0)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && durationSeconds(hours: hours, minutes: minutes) > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            disclosureRow

            if expanded {
                form
                    .padding(.top, 2)
                    .padding(.bottom, 2)
            }
        }
    }

    private var disclosureRow: some View {
        HStack(spacing: 0) {
            Image(systemName: expanded ? "chevron.down" : "plus")
                .font(.system(size: 10, weight: .semibold))
                .frame(width: MenuTheme.checkColumn, alignment: .leading)

            Text("New timer")
                .font(MenuTheme.itemFont)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, MenuTheme.contentInset)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hovering ? MenuTheme.highlight : .clear, in: RoundedRectangle(cornerRadius: MenuTheme.corner))
        .foregroundStyle(hovering ? Color.white : MenuTheme.primaryText)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .padding(.horizontal, MenuTheme.outerInset)
        .onHover { hovering = $0 }
        .accessibilityLabel("New timer")
        .accessibilityValue(expanded ? "expanded" : "collapsed")
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("What to do", text: $title)
                .textFieldStyle(MenuFieldStyle())
                .focused($focus, equals: .title)
                .onSubmit(submit)

            HStack(spacing: 5) {
                TextField("", text: $hoursText)
                    .textFieldStyle(MenuFieldStyle())
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 36)
                    .focused($focus, equals: .hours)
                    .onSubmit(submit)
                    .help("Hours, 0-\(TimerItem.maxHours)")
                Text("h")
                    .font(MenuTheme.captionFont)
                    .foregroundStyle(MenuTheme.secondaryText)

                TextField("", text: $minutesText)
                    .textFieldStyle(MenuFieldStyle())
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 40)
                    .focused($focus, equals: .minutes)
                    .onSubmit(submit)
                    .help("Minutes, 0-\(TimerItem.maxMinutes)")
                Text("min")
                    .font(MenuTheme.captionFont)
                    .foregroundStyle(MenuTheme.secondaryText)

                Spacer(minLength: 0)

                AddButton(isEnabled: isValid, action: submit)
            }
        }
        .padding(.leading, MenuTheme.outerInset + MenuTheme.contentInset + MenuTheme.checkColumn)
        .padding(.trailing, MenuTheme.outerInset + MenuTheme.contentInset)
        .onChange(of: hoursText) { _, _ in normalizeHours() }
        .onChange(of: minutesText) { _, _ in normalizeMinutes() }
    }

    private func toggle() {
        expanded.toggle()
        focus = expanded ? .title : nil
    }

    private func normalizeHours() {
        hoursText = normalized(hoursText, clamp: TimerItem.clampHours) ?? hoursText
    }

    private func normalizeMinutes() {
        minutesText = normalized(minutesText, clamp: TimerItem.clampMinutes) ?? minutesText
    }

    private func normalized(_ text: String, clamp: (Int) -> Int) -> String? {
        let raw = text.trimmingCharacters(in: .whitespaces)
        if raw.isEmpty || raw == "-" { return nil }
        let result = String(clamp(Int(raw) ?? 0))
        return result == text ? nil : result
    }

    private func submit() {
        guard isValid else { return }
        onAdd(title, hours, minutes)
        title = ""
        hoursText = "0"
        minutesText = "40"
        focus = .title
    }
}

private struct AddButton: View {
    let isEnabled: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text("Add")
                .font(MenuTheme.itemFont)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(background, in: RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(foreground)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering = $0 }
    }

    private var background: Color {
        guard isEnabled else { return MenuTheme.fieldBackground }
        return hovering ? MenuTheme.highlight : MenuTheme.highlight.opacity(0.75)
    }

    private var foreground: Color {
        isEnabled ? .white : MenuTheme.dimmedText
    }
}
