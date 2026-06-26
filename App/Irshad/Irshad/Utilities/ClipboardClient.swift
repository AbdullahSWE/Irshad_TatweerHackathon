import UIKit

@MainActor
struct ClipboardClient {
    func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}
