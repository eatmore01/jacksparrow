import SwiftUI

struct MenuSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(MenuTheme.itemFont)
            .foregroundStyle(MenuTheme.dimmedText)
            .padding(.horizontal, MenuTheme.outerInset + MenuTheme.contentInset + MenuTheme.checkColumn)
            .padding(.top, 6)
            .padding(.bottom, 1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(MenuTheme.itemFont)
            .foregroundStyle(MenuTheme.dimmedText)
            .padding(.horizontal, MenuTheme.outerInset + MenuTheme.contentInset + MenuTheme.checkColumn)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuStatusLine: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)

            Text(text)
                .font(MenuTheme.itemFont)
                .foregroundStyle(MenuTheme.primaryText)

            Spacer(minLength: 0)
        }
        .padding(.leading, MenuTheme.outerInset + MenuTheme.contentInset + 4)
        .padding(.trailing, MenuTheme.outerInset + MenuTheme.contentInset)
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

struct MenuDivider: View {
    var body: some View {
        Rectangle()
            .fill(MenuTheme.divider)
            .frame(height: 1)
            .padding(.horizontal, MenuTheme.outerInset + 4)
            .padding(.vertical, 5)
    }
}

struct MenuItemRow: View {
    let title: String
    var isChecked = false
    var shortcut: String?
    var tooltip: String?
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .opacity(isChecked ? 1 : 0)
                    .frame(width: MenuTheme.checkColumn, alignment: .leading)

                Text(title)
                    .font(MenuTheme.itemFont)

                Spacer(minLength: 10)

                if let shortcut {
                    Text(shortcut)
                        .font(MenuTheme.itemFont)
                        .foregroundStyle(hovering ? Color.white.opacity(0.7) : MenuTheme.dimmedText)
                }
            }
            .padding(.horizontal, MenuTheme.contentInset)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hovering ? MenuTheme.highlight : .clear, in: RoundedRectangle(cornerRadius: MenuTheme.corner))
            .foregroundStyle(hovering ? Color.white : MenuTheme.primaryText)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, MenuTheme.outerInset)
        .onHover { hovering = $0 }
        .accessibilityLabel(title)
        .accessibilityValue(isChecked ? "on" : "off")
        .accessibilityAddTraits(isChecked ? [.isSelected] : [])
        .modifier(OptionalHelp(text: tooltip))
    }
}

struct OptionalHelp: ViewModifier {
    let text: String?

    func body(content: Content) -> some View {
        if let text {
            content.help(text)
        } else {
            content
        }
    }
}

struct MenuFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .font(MenuTheme.itemFont)
            .foregroundStyle(MenuTheme.primaryText)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(MenuTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(MenuTheme.fieldBorder, lineWidth: 1)
            )
    }
}
