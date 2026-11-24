import SwiftUI

struct SoundSettingsView: View {
    @ObservedObject var chime: ChimeService

    @State private var expanded = false
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            disclosureRow

            if expanded {
                MenuItemRow(
                    title: "Alert on finish",
                    isChecked: chime.isEnabled,
                    tooltip: "Play a sound through the current output device when a timer reaches zero",
                    action: { chime.setEnabled(!chime.isEnabled) }
                )

                if chime.isEnabled {
                    volumeRow

                    MenuItemRow(
                        title: ChimeService.builtinTitle,
                        isChecked: !chime.usesCustomFile,
                        tooltip: "The sound shipped inside jacksparrow",
                        action: { chime.useBuiltin() }
                    )

                    MenuItemRow(
                        title: chime.customFileName ?? "Choose file…",
                        isChecked: chime.usesCustomFile,
                        tooltip: "Pick any audio file from disk",
                        action: { chime.chooseCustomFile() }
                    )

                    if !chime.builtinIsAvailable && !chime.usesCustomFile {
                        MenuCaption(text: "Built-in sound is missing from the bundle")
                    }
                }
            }
        }
    }

    private var disclosureRow: some View {
        HStack(spacing: 0) {
            Image(systemName: expanded ? "chevron.down" : "speaker.wave.2.fill")
                .font(.system(size: 10, weight: .semibold))
                .frame(width: MenuTheme.checkColumn, alignment: .leading)

            Text("Sound: \(chime.currentTitle)")
                .font(MenuTheme.itemFont)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)

            if chime.isEnabled {
                Text("\(Int(chime.volume * 100))%")
                    .font(MenuTheme.captionFont)
                    .monospacedDigit()
                    .foregroundStyle(hovering ? Color.white.opacity(0.7) : MenuTheme.dimmedText)
            }
        }
        .padding(.horizontal, MenuTheme.contentInset)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hovering ? MenuTheme.highlight : .clear, in: RoundedRectangle(cornerRadius: MenuTheme.corner))
        .foregroundStyle(hovering ? Color.white : MenuTheme.primaryText)
        .contentShape(Rectangle())
        .onTapGesture { expanded.toggle() }
        .padding(.horizontal, MenuTheme.outerInset)
        .onHover { hovering = $0 }
        .pointingHand()
        .accessibilityLabel("Sound settings")
        .accessibilityValue(expanded ? "expanded" : "collapsed")
    }

    private var volumeRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 9))
                .foregroundStyle(MenuTheme.dimmedText)
                .frame(width: MenuTheme.checkColumn, alignment: .leading)

            Slider(
                value: Binding(
                    get: { chime.volume },
                    set: { chime.setVolume($0) }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing { chime.preview() }
                }
            )
            .controlSize(.mini)
            .tint(MenuTheme.highlight)

            Text("\(Int(chime.volume * 100))%")
                .font(MenuTheme.captionFont)
                .monospacedDigit()
                .foregroundStyle(MenuTheme.secondaryText)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, MenuTheme.contentInset)
        .padding(.vertical, 3)
        .padding(.horizontal, MenuTheme.outerInset)
        .accessibilityLabel("Volume")
        .accessibilityValue("\(Int(chime.volume * 100)) percent")
    }
}
