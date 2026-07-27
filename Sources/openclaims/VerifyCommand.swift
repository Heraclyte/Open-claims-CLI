import ArgumentParser
import Foundation

private final class DevMetadataReader: MetadataReaderProtocol {
    let url: URL
    init(url: URL) { self.url = url }
    func extractIssuerURL(fromFilePath path: String) async throws -> URL { url }
}

private final class DevHTTPClient: HTTPClientProtocol {
    let envelope: ClaimEnvelope
    init(envelope: ClaimEnvelope) { self.envelope = envelope }
    func fetchClaimEnvelope(from url: URL) async throws -> ClaimEnvelope { envelope }
}

@main
struct VerifyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify",
        abstract: "Verifies documents compliant with the Open Claims standard."
    )

    @Argument(help: "Path to the local PDF document")
    var pdfPath: String

    @Argument(help: "Network address of the issuer domain.")
    var issuerDomain: String

    mutating func run() async throws {
        let validationState = ValidationState()
        validationState.documentPath = pdfPath
        validationState.issuerDomain = issuerDomain

        let validator = InputValidator(state: validationState)
        validator.executeValidation()

        if let validationError = validationState.encounterError {
            print("Validation process stopped due to an error")
            throw validationError
        }

        if validationState.isFullyValid {
            print("Initial validation completed successfully. Ready for the next phase.")
        }

        let dummyURL = URL(
            string: issuerDomain.contains("://") ? issuerDomain : "https://\(issuerDomain)")!
        let dummyEnvelope = ClaimEnvelope(
            id: "dev_mode_001",
            issuer: dummyURL,
            issuedAt: Date(),
            claim: ClaimDetails(subject: "tester", assertion: "valid_setup")
        )

        let devMetadataReader = DevMetadataReader(url: dummyURL)
        let devHTTPClient = DevHTTPClient(envelope: dummyEnvelope)

        let processor = ClaimVerificationProcessor(
            metadataReader: devMetadataReader,
            httpClient: devHTTPClient
        )

        print("Starting processing for file: \(pdfPath)")
        await processor.process(pdfPath: pdfPath)

        if processor.state.status == VerificationState.Status.valid {
            print("Success! Claim verified successfully.")
            if let envelope = processor.state.envelope {
                print("Subject: \(envelope.claim.subject)")
                print("Assertion: \(envelope.claim.assertion)")
            }
        } else {
            print("Verification failed!")
            if let error = processor.state.lastError {
                print("Error details: \(error)")
            }
        }

    }

}
