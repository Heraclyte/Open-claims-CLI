import XCTest

@testable import openclaims

private final class StubMetadataReader: MetadataReaderProtocol {
    let result: Result<URL, Error>

    init(result: Result<URL, Error>) {
        self.result = result
    }

    func extractIssuerURL(fromFilePath path: String) async throws -> URL {
        try result.get()
    }
}

private final class StubHTTPClient: HTTPClientProtocol {
    let result: Result<ClaimEnvelope, Error>

    init(result: Result<ClaimEnvelope, Error>) {
        self.result = result
    }

    func fetchClaimEnvelope(from url: URL) async throws -> ClaimEnvelope {
        try result.get()
    }
}

final class Stage2Tests: XCTestCase {

    // 1. Test sprawdzający dekodowanie i kodowanie formatu JSON (Codable)
    func testClaimEnvelopeCodable() throws {
        let sampleJSON = """
            {
                "id": "claim_123",
                "issuer": "https://example.com/issuer",
                "issuedAt": 1700000000,
                "claim": {
                    "subject": "user_456",
                    "assertion": "is_over_18"
                }
            }
            """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let envelope = try decoder.decode(ClaimEnvelope.self, from: sampleJSON)

        XCTAssertEqual(envelope.id, "claim_123")
        XCTAssertEqual(envelope.issuer.absoluteString, "https://example.com/issuer")
        XCTAssertEqual(envelope.claim.subject, "user_456")
        XCTAssertEqual(envelope.claim.assertion, "is_over_18")
    }

    func testProcessorSuccessFlow() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "https://valid.issuer.com"))
        let expectedEnvelope = ClaimEnvelope(
            id: "test_id",
            issuer: expectedURL,
            issuedAt: Date(),
            claim: ClaimDetails(subject: "sub", assertion: "assert")
        )

        let mockReader = StubMetadataReader(result: .success(expectedURL))
        let mockClient = StubHTTPClient(result: .success(expectedEnvelope))

        let processor = ClaimVerificationProcessor(
            metadataReader: mockReader,
            httpClient: mockClient
        )

        XCTAssertEqual(processor.state.status, VerificationState.Status.idle)

        await processor.process(pdfPath: "/dummy/path.pdf")

        XCTAssertEqual(processor.state.status, VerificationState.Status.valid)
        XCTAssertEqual(processor.state.extractedURL, expectedURL)
        XCTAssertEqual(processor.state.envelope?.id, "test_id")
        XCTAssertNil(processor.state.lastError)
    }

    func testProcessorMetadataFailureFlow() async {
        let mockReader = StubMetadataReader(result: .failure(MetadataReaderError.metadataNotFound))
        let mockClient = StubHTTPClient(result: .failure(HTTPClientError.invalidResponse))

        let processor = ClaimVerificationProcessor(
            metadataReader: mockReader,
            httpClient: mockClient
        )

        await processor.process(pdfPath: "/dummy/path.pdf")

        XCTAssertEqual(processor.state.status, VerificationState.Status.failed)
        XCTAssertNil(processor.state.extractedURL)
        XCTAssertNil(processor.state.envelope)
        XCTAssertNotNil(processor.state.lastError)
    }
}
