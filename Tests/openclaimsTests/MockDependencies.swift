import Foundation

@testable import openclaims

public final class MockMetadataReader: MetadataReaderProtocol, @unchecked Sendable {
    public let resultToReturn: Result<URL, Error>

    public init(result: Result<URL, Error>) {
        self.resultToReturn = result
    }

    public func extractIssuerURL(fromFilePath path: String) async throws -> URL {
        return try resultToReturn.get()
    }
}

public final class MockHTTPClient: HTTPClientProtocol, @unchecked Sendable {
    public let resultToReturn: Result<ClaimEnvelope, Error>
    public let publicKeyToReturn: Data

    public init(resultToReturn: Result<ClaimEnvelope, Error>, publicKeyToReturn: Data = Data()) {
        self.resultToReturn = resultToReturn
        self.publicKeyToReturn = publicKeyToReturn
    }

    public func fetchClaimEnvelope(from url: URL) async throws -> ClaimEnvelope {
        return try resultToReturn.get()
    }

    public func fetchPublicKey(for url: URL) async throws -> Data {
        return publicKeyToReturn
    }
}

public final class MockCryptographicVerifier: CryptographicVerifier, @unchecked Sendable {
    public var wasValidateCalled = false
    public var errorToThrow: Error?

    public init(errorToThrow: Error? = nil) {
        self.errorToThrow = errorToThrow
    }

    public func validate(signature: Data, payload: Data, publicKey: Data) throws {
        wasValidateCalled = true
        if let error = errorToThrow {
            throw error
        }
    }
}
