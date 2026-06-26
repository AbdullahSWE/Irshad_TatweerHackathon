import Foundation

extension JSONValue {
    var displayString: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.rounded() == value ? String(Int(value)) : String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .object(let value):
            return value
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value.displayString)" }
                .joined(separator: ", ")
        case .array(let value):
            return value.map(\.displayString).joined(separator: ", ")
        case .null:
            return ""
        }
    }

    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }

        return nil
    }
}
