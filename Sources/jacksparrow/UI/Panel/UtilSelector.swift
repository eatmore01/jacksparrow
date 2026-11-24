import SwiftUI

enum PanelTab: Hashable {
    case util(UtilFeature)
    case settings
}

struct UtilSelector: View {
    let features: [UtilFeature]
    @Binding var selection: PanelTab

    var body: some View {
        HStack(spacing: 2) {
            ForEach(features, id: \.self) { feature in
                SelectorButton(
                    isSelected: selection == .util(feature),
                    tooltip: feature.title,
                    action: { selection = .util(feature) }
                ) {
                    UtilIcon(resource: feature.iconResource, symbol: feature.symbolName)
                }
            }

            Spacer(minLength: 0)

            SelectorButton(
                isSelected: selection == .settings,
                tooltip: "Settings",
                action: { selection = .settings }
            ) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .regular))
            }
        }
        .padding(.horizontal, MenuTheme.outerInset + 4)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}

private struct SelectorButton<Content: View>: View {
    let isSelected: Bool
    let tooltip: String
    let action: () -> Void
    @ViewBuilder let content: Content

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            content
                .frame(width: 30, height: 24)
                .foregroundStyle(isSelected ? Color.white : MenuTheme.secondaryText)
                .background(background, in: RoundedRectangle(cornerRadius: MenuTheme.corner))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .pointingHand()
        .help(tooltip)
        .accessibilityLabel(tooltip)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var background: Color {
        if isSelected { return MenuTheme.highlight.opacity(0.9) }
        return hovering ? MenuTheme.fieldBackground : .clear
    }
}
