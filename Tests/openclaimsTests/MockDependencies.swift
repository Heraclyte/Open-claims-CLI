import Foundation

@testable import openclaims

public final class MockMetadataReader: MetadataReaderProtocol {
    public let resultToReturn: Result<URL, Error>

    public init(result: Result<URL, Error>) {
        self.resultToReturn = result
    }

    public func extractIssuerURL(fromFilePath path: String) async throws -> URL {
        try resultToReturn.get()
    }
}

public final class MockHTTPClient: HTTPClientProtocol {
    public let resultToReturn: Result<ClaimEnvelope, Error>

    public init(result: Result<ClaimEnvelope, Error>) {
        self.resultToReturn = result
    }

    public func fetchClaimEnvelope(from url: URL) async throws -> ClaimEnvelope {
        try resultToReturn.get()
    }
}
