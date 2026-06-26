import Foundation

extension URL {
    func appendingEndpointPath(_ path: String) throws -> URL {
        let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: normalized, relativeTo: self)?.absoluteURL else {
            throw APIError.invalidURL(path)
        }
        return url
    }
}
