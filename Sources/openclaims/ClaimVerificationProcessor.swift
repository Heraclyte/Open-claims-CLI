import Foundation

public final class ClaimVerificationProcessor: @unchecked Sendable {
    private let metadataReader: MetadataReaderProtocol
    private let httpClient: HTTPClientProtocol
    private let verifier: CryptographicVerifier

    public private(set) var state: VerificationState

    public init(
        metadataReader: MetadataReaderProtocol,
        httpClient: HTTPClientProtocol,
        verifier: CryptographicVerifier,
        initialState: VerificationState = VerificationState()

    ) {
        self.metadataReader = metadataReader
        self.httpClient = httpClient
        self.verifier = verifier
        self.state = initialState
    }

    public func process(pdfPath: String, issuerURL: URL) async throws {
        state.markAsProcessing()

        do {
            let extractedURL = try await metadataReader.extractIssuerURL(fromFilePath: pdfPath)

            guard extractedURL == issuerURL else {
                struct IssuerMismatchError: Error, CustomStringConvertible {
                    var description: String {
                        "Extracted URL does not match the provided issuer domain."
                    }
                }
                throw IssuerMismatchError()
            }

            state.setIssuerURL(issuerURL)

            let envelope = try await httpClient.fetchClaimEnvelope(from: issuerURL)
            let publicKey = try await httpClient.fetchPublicKey(for: issuerURL)

            let payloadData = try JSONEncoder().encode(envelope.claim)

            try verifier.validate(
                signature: envelope.signature,
                payload: payloadData,
                publicKey: publicKey
            )
            state.setEnvelope(envelope)
            state.markAsValid()
        } catch {
            state.setError(error)
            throw error
        }

    }
}
