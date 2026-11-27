import SwiftUI

struct NotesSection: View {
    @ObservedObject var service: NotesService

    @FocusState private var barLineFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuSectionHeader(title: "Bar line")

            TextField("empty — icon only in the bar", text: barLineBinding)
                .textFieldStyle(MenuFieldStyle())
                .focused($barLineFocused)
                .padding(.horizontal, MenuTheme.outerInset + MenuTheme.contentInset)

            MenuDivider()

            HStack {
                Text("Canvas")
                    .font(MenuTheme.itemFont)
                    .foregroundStyle(MenuTheme.dimmedText)
                Spacer(minLength: 8)
                Text(savedCaption)
                    .font(MenuTheme.captionFont)
                    .monospacedDigit()
                    .foregroundStyle(MenuTheme.dimmedText)
            }
            .padding(.horizontal, MenuTheme.outerInset + MenuTheme.contentInset)
            .padding(.bottom, 4)

            TextEditor(text: canvasBinding)
                .font(MenuTheme.canvasFont)
                .foregroundStyle(MenuTheme.primaryText)
                .scrollContentBackground(.hidden)
                .background(MenuTheme.canvasBackground)
                .tint(MenuTheme.accentSoft)
                .frame(height: 196)
                .padding(.horizontal, 7)
                .padding(.vertical, 6)
                .background(MenuTheme.canvasBackground, in: RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(MenuTheme.canvasBorder, lineWidth: 1)
                )
                .padding(.horizontal, MenuTheme.outerInset + MenuTheme.contentInset)
                .padding(.bottom, 4)

            if let error = service.lastError {
                MenuCaption(text: "Error: \(error)")
            }

            MenuCaption(text: service.fileDisplayPath)
        }
        .onAppear { service.reloadIfChangedOnDisk() }
        .onDisappear { service.flush() }
    }

    private var savedCaption: String {
        guard let saved = service.lastSaved else { return "not saved yet" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "saved \(formatter.string(from: saved))"
    }

    private var barLineBinding: Binding<String> {
        Binding(
            get: { service.barLine },
            set: { service.setBarLine($0) }
        )
    }

    private var canvasBinding: Binding<String> {
        Binding(
            get: { service.text },
            set: { service.update($0) }
        )
    }
}
