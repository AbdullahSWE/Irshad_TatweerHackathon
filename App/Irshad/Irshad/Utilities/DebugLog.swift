import Foundation

enum DebugLog {
    nonisolated static func api(_ message: @autoclosure () -> String) {
        let resolved = message()

        #if DEBUG
        print("[IrshadDebug] \(resolved)")
        #endif
    }

    nonisolated static func preview(_ value: String, limit: Int = 2_000) -> String {
        let collapsed = value
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")

        guard collapsed.count > limit else {
            return collapsed
        }

        return "\(collapsed.prefix(limit))... <truncated \(collapsed.count - limit) chars>"
    }

    nonisolated static func preview(data: Data, limit: Int = 4_000) -> String {
        guard let text = String(data: data, encoding: .utf8) else {
            return "<\(data.count) bytes, not UTF-8>"
        }

        return preview(text, limit: limit)
    }

    nonisolated static func prettyJSONPreview(data: Data, limit: Int = 4_000) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else {
            return preview(data: data, limit: limit)
        }

        return preview(data: pretty, limit: limit)
    }

    nonisolated static func describe(_ error: Error) -> String {
        if let debugError = error as? DebuggableAPIError {
            return "\(String(describing: debugError.underlying))\n\(debugError.debugTrace)"
        }

        if let apiError = error as? APIError {
            return "APIError.\(String(describing: apiError))"
        }

        if let urlError = error as? URLError {
            let failingURL = (urlError.userInfo[NSURLErrorFailingURLErrorKey] as? URL)?.absoluteString
            let urlSuffix = failingURL.map { " failingURL=\($0)" } ?? ""
            return "URLError code=\(urlError.code.rawValue) \(urlError.code) description=\"\(urlError.localizedDescription)\"\(urlSuffix)"
        }

        return "\(type(of: error)): \(error.localizedDescription)"
    }
}
