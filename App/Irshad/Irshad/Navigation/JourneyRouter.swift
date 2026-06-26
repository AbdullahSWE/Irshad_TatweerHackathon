import Foundation
import UIKit

struct JourneyRouter {
    nonisolated init() {}

    func canOpenBackendProvidedURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty else {
            return false
        }

        switch scheme {
        case "http", "https":
            return url.host?.isEmpty == false
        case "tel":
            return url.absoluteString.count > "tel:".count
        case "mailto":
            let address = url.absoluteString.dropFirst("mailto:".count)
            return address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        default:
            return false
        }
    }

    func makeTelephoneURL(from backendPhoneNumber: String) -> URL? {
        let trimmed = backendPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let allowedCharacters = CharacterSet(charactersIn: "+0123456789-() ")
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return nil
        }

        let dialable = trimmed.filter { $0 == "+" || $0.isNumber }
        guard dialable.contains(where: \.isNumber) else {
            return nil
        }

        return URL(string: "tel:\(dialable)")
    }

    @MainActor
    func open(_ url: URL) {
        guard canOpenBackendProvidedURL(url) else {
            return
        }

        UIApplication.shared.open(url)
    }
}
