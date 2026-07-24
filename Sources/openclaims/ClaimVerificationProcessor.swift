import Foundation

public final class ClaimVerificationProcessor: @unchecked Sendable {
    private let metadataReader: MetadataReaderProtocol
    private let httpClient: HTTPClientProtocol

    public private(set) var state: VerificationState

    public init(
        metadataReader: MetadataReaderProtocol,
        httpClient: HTTPClientProtocol,
        initialState: VerificationState = VerificationState()

    ) {
        self.metadataReader = metadataReader
        self.httpClient = httpClient
        self.state = initialState
    }

    public func process(pdfPath: String) async {
        state.markAsProcessing()

        do {
            let issuerURL = try await metadataReader.extractIssuerURL(fromFilePath: pdfPath)
            state.setIssuerURL(issuerURL)

            let envelope = try await httpClient.fetchClaimEnvelope(from: issuerURL)
            state.setEnvelope(envelope)
            state.markAsValid()
        } catch {
            state.setError(error)
        }
    }
}
