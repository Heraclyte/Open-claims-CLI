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
        let state = ValidationState()
        state.documentPath = pdfPath
        state.issuerDomain = issuerDomain

        let validator = InputValidator(state: state)
        validator.executeValidation()

        if let validationError = state.encounterError {
            print("Validation process stopped due to an error")
            throw validationError
        }

        if state.isFullyValid {
            print("Initial validation completed successfully. Ready for the next phase.")
        }
    }

}
