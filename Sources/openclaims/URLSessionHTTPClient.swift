import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public final class URLSessionHTTPClient: HTTPClientProtocol {
    private let session: URLSession

    public init(session: URLSession = URLSessionHTTPClient.createDefaultSession()) {
        self.session = session
    }

    public static func createDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }
    public func fetchClaimEnvelope(from url: URL) async throws -> ClaimEnvelope {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            print("Network request failed with underlying error: \(error)")
            throw HTTPClientError.invalidResponse
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPClientError.requestFailed(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ClaimEnvelope.self, from: data)
        } catch {
            throw HTTPClientError.decodingError
        }
    }
}
