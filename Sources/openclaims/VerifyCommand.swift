import ArgumentParser
import Foundation

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

        let formattedURLString =
            issuerDomain.contains("://") ? issuerDomain : "https://\(issuerDomain)"
        guard let issuerURL = URL(string: formattedURLString) else {
            print("Invalid issuer domain URL.")
            return
        }

        let localReader = LocalPDFMetadataReader()
        let httpClient = URLSessionHTTPClient()
        let cryptoVerifier = Ed25519Verifier()

        let processor = ClaimVerificationProcessor(
            metadataReader: localReader,
            httpClient: httpClient,
            verifier: cryptoVerifier
        )

        print("Fetching claim envelope from network: \(issuerURL.absoluteString)...")
        await processor.process(pdfPath: pdfPath)

        if processor.state.status == VerificationState.Status.valid {
            print("Success! Claim verified successfully.")
            if let envelope = processor.state.envelope {
                print("Claim ID: \(envelope.id)")
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
