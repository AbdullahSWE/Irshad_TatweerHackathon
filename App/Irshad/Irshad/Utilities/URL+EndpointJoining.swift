import Foundation

enum EndpointJoiningError: Error, Equatable {
    case unsupportedEndpoint(String)
}

extension URL {
    func appendingEndpointPath(_ path: String) throws -> URL {
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedPath = "/\(trimmedPath)"

        guard JourneyEndpoint.allCases.contains(where: { $0.rawValue == normalizedPath }) else {
            throw EndpointJoiningError.unsupportedEndpoint(normalizedPath)
        }

        return appending(path: trimmedPath)
    }
}
