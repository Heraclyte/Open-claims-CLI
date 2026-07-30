import Foundation

public final class ClaimVerificationProcessor {
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

    public func process(pdfPath: String, publicKeyPath: String?) async {
        state.markAsProcessing()

        do {
            let issuerURL = try await metadataReader.extractIssuerURL(fromFilePath: pdfPath)
            state.setIssuerURL(issuerURL)

            let envelope = try await httpClient.fetchClaimEnvelope(from: issuerURL)

            guard let keyPath = publicKeyPath else {
                state.setError(
                    NSError(
                        domain: "OpenClaims", code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "Missing public key path"]))
                return
            }

            guard let signature = envelope.signature else {
                state.setError(
                    NSError(
                        domain: "OpenClaims", code: 401,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Missing signature in the fetched envelope"
                        ]))
                return
            }

            let canonicalJSON = try envelope.toJSONString(excludeSignature: true)

            let isValid = try Signer.verify(
                signatureBase64: signature,
                data: Data(canonicalJSON.utf8),
                publicKeyPath: keyPath
            )

            if isValid {
                state.setEnvelope(envelope)
                state.markAsValid()
            } else {
                state.setError(
                    NSError(
                        domain: "OpenClaims", code: 403,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Cryptographic signature does not match the public key"
                        ]))
            }
        } catch {
            state.setError(error)
        }
    }
}
