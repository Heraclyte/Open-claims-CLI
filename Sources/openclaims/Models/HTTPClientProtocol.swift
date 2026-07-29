import Foundation

public enum HTTPClientError: Error, Equatable {
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingError
}

public protocol HTTPClientProtocol: Sendable {
    func fetchClaimEnvelope(from url: URL) async throws -> ClaimEnvelope
}
