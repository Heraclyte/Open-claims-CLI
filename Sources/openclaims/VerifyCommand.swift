import ArgumentParser
import Foundation

struct VerifyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify",
        abstract: "Verifies documents compliant with the Open Claims standard."
    )

    @Argument(help: "Path to the local PDF document")
    var pdfPath: String

    @Argument(help: "Network address of the issuer domain.")
    var issuerDomain: String

    @Option(
        name: .customLong("public-key"),
        help: "Path to the issuer's public key PEM file for signature verification")
    var publicKeyPath: String?

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

        let processor = ClaimVerificationProcessor(
            metadataReader: localReader,
            httpClient: httpClient
        )

        print("Fetching claim envelope from network: \(issuerURL.absoluteString)...")
        await processor.process(pdfPath: pdfPath, publicKeyPath: publicKeyPath)

        if processor.state.status == VerificationState.Status.valid {
            print("Success! Claim verified successfully.")
            if let envelope = processor.state.envelope {
                print("Claim ID: \(envelope.claimId)")
                print("Subject: \(envelope.recipientData.recipientIdentifier)")
                print("Assertion: \(envelope.assertionType ?? "N/A")")
            }
        } else {
            print("Verification failed!")
            if let error = processor.state.lastError {
                print("Error details: \(error.localizedDescription)")
            }

            throw ExitCode.failure
        }
    }
}
