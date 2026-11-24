import SwiftUI

enum IconCache {
    private static var images: [String: NSImage] = [:]

    static func image(named name: String, pointSize: CGFloat) -> NSImage? {
        let key = "\(name)@\(pointSize)"
        if let cached = images[key] { return cached }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url), image.size.height > 0 else { return nil }
        image.isTemplate = false
        image.size = NSSize(width: pointSize * (image.size.width / image.size.height), height: pointSize)
        images[key] = image
        return image
    }
}

struct UtilIcon: View {
    let resource: String
    let symbol: String
    var pointSize: CGFloat = 16

    var body: some View {
        if let image = IconCache.image(named: resource, pointSize: pointSize) {
            Image(nsImage: image)
        } else {
            Image(systemName: symbol)
                .font(.system(size: pointSize - 3, weight: .regular))
        }
    }
}
