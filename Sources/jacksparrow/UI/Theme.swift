import SwiftUI

enum MenuTheme {
    static let background = Color(red: 0.118, green: 0.086, blue: 0.094)
    static let primaryText = Color(red: 0.957, green: 0.910, blue: 0.910).opacity(0.90)
    static let secondaryText = Color(red: 0.957, green: 0.910, blue: 0.910).opacity(0.46)
    static let dimmedText = Color(red: 0.957, green: 0.910, blue: 0.910).opacity(0.32)
    static let divider = Color(red: 1.0, green: 0.882, blue: 0.882).opacity(0.10)
    static let highlight = Color(red: 0.639, green: 0.227, blue: 0.227)
    static let accentSoft = Color(red: 0.769, green: 0.361, blue: 0.361)
    static let fieldBackground = Color(red: 1.0, green: 0.824, blue: 0.824).opacity(0.06)
    static let fieldBorder = Color(red: 1.0, green: 0.745, blue: 0.745).opacity(0.14)
    static let canvasBackground = Color(red: 0.078, green: 0.055, blue: 0.059)
    static let canvasBorder = Color(red: 1.0, green: 0.745, blue: 0.745).opacity(0.10)
    static let running = Color(red: 0.40, green: 0.74, blue: 0.48)
    static let danger = Color(red: 0.769, green: 0.361, blue: 0.361)

    static let width = 290.0
    static let outerInset = 5.0
    static let contentInset = 9.0
    static let checkColumn = 17.0
    static let corner = 5.0

    static let itemFont = Font.system(size: 13)
    static let captionFont = Font.system(size: 11)
    static let canvasFont = Font.system(size: 11.5, design: .monospaced)
}
