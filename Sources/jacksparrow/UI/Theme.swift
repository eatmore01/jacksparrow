import SwiftUI

enum MenuTheme {
    static let background = Color(red: 0.169, green: 0.169, blue: 0.180)
    static let primaryText = Color.white.opacity(0.90)
    static let secondaryText = Color.white.opacity(0.42)
    static let dimmedText = Color.white.opacity(0.30)
    static let divider = Color.white.opacity(0.13)
    static let highlight = Color.accentColor
    static let fieldBackground = Color.white.opacity(0.08)
    static let fieldBorder = Color.white.opacity(0.12)
    static let running = Color(red: 0.36, green: 0.84, blue: 0.46)
    static let danger = Color(red: 1.0, green: 0.44, blue: 0.41)

    static let width = 290.0
    static let outerInset = 5.0
    static let contentInset = 9.0
    static let checkColumn = 17.0
    static let corner = 5.0

    static let itemFont = Font.system(size: 13)
    static let captionFont = Font.system(size: 11)
}
