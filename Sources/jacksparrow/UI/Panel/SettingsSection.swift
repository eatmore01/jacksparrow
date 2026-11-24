import SwiftUI

struct SettingsSection: View {
    @ObservedObject var runtime: FeatureRuntime

    @State private var loginEnabled = false
    @State private var loginTitle = "Launch at Login"
    @State private var loginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuSectionHeader(title: "Utilities")

            ForEach(UtilFeature.allCases, id: \.self) { feature in
                MenuItemRow(
                    title: feature.title,
                    isChecked: runtime.available.contains(feature),
                    tooltip: feature.detail,
                    action: { runtime.setAvailable(feature, !runtime.available.contains(feature)) }
                )
            }

            MenuCaption(text: "A disabled utility stops running and leaves the selector")

            MenuDivider()

            MenuSectionHeader(title: "Startup")

            MenuItemRow(
                title: loginTitle,
                isChecked: loginEnabled,
                tooltip: "Start jacksparrow automatically and restore every enabled utility",
                action: toggleLoginItem
            )

            if let loginError {
                MenuCaption(text: "Error: \(loginError)")
            }
        }
        .task { await refreshLoginItem() }
    }

    private func toggleLoginItem() {
        let target = !loginEnabled
        Task {
            let failure = await Task.detached {
                do {
                    try LoginItem.setEnabled(target)
                    return String?.none
                } catch {
                    return String?.some(error.localizedDescription)
                }
            }.value
            loginError = failure
            await refreshLoginItem()
        }
    }

    private func refreshLoginItem() async {
        let state = await Task.detached { (LoginItem.isEnabled, LoginItem.title) }.value
        loginEnabled = state.0
        loginTitle = state.1
    }
}
