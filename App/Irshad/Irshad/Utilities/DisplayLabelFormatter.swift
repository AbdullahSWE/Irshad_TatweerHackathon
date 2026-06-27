import Foundation

enum DisplayLabelFormatter {
    static func humanizeKey(_ key: String) -> String {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        let spaced = trimmed
            .replacingOccurrences(
                of: #"([a-z0-9])([A-Z])"#,
                with: "$1 $2",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"([A-Z]+)([A-Z][a-z])"#,
                with: "$1 $2",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"[_-]+"#,
                with: " ",
                options: .regularExpression
            )

        return spaced
            .split(separator: " ")
            .map { word in
                let text = String(word)
                if text == text.uppercased() {
                    return text
                }
                return text.prefix(1).uppercased() + text.dropFirst()
            }
            .joined(separator: " ")
    }

    static func humanizeIfMachineLabel(_ label: String) -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        if trimmed.range(of: #"[_-]|[a-z0-9][A-Z]"#, options: .regularExpression) != nil {
            return humanizeKey(trimmed)
        }

        if trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
           trimmed.first?.isLowercase == true {
            return humanizeKey(trimmed)
        }

        return trimmed
    }
}
