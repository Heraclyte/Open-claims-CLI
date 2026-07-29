import XCTest

@testable import openclaims

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Handler is not set.")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class HTTPClientTests: XCTestCase {
    private var client: URLSessionHTTPClient!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)
        client = URLSessionHTTPClient(session: session)
    }

    override func tearDown() {
        client = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testFetchClaimEnvelopeSuccess() async throws {
        let testURL = try XCTUnwrap(URL(string: "https://example.com/claim"))
        let jsonString = """
            {
                "id": "claim_777",
                "issuer": "https://example.com",
                "issuedAt": "2026-02-07T12:00:00Z",
                "claim": {
                    "subject": "user_abc",
                    "assertion": "verified_status"
                }
            }
            """
        let mockData = jsonString.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, mockData)
        }

        let envelope = try await client.fetchClaimEnvelope(from: testURL)
        XCTAssertEqual(envelope.id, "claim_777")
        XCTAssertEqual(envelope.claim.subject, "user_abc")
    }

    func testFetchClaimEnvelopeHTTPError() async throws {
        let testURL = try XCTUnwrap(URL(string: "https://example.com/claim"))

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await client.fetchClaimEnvelope(from: testURL)
            XCTFail("Expected HTTPClientError, but succeeded.")
        } catch let error as HTTPClientError {
            if case .requestFailed(let code) = error {
                XCTAssertEqual(code, 404)
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Unexpected error type")
        }
    }
}
