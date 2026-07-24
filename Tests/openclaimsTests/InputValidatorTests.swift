import XCTest

@testable import openclaims

final class InputValidatorTests: XCTestCase {

    func testValidInputPassesValidation() {
        let state = ValidationState()
        state.documentPath = "/sciezka/do/pliku.pdf"
        state.issuerDomain = "https://example.com"

        let validator = InputValidator(state: state)
        validator.executeValidation()

        XCTAssertTrue(state.isFullyValid)
        XCTAssertNil(state.encounterError)
    }

    func testInvalidFileExtensionFails() {
        let state = ValidationState()
        state.documentPath = "/sciezka/do/pliku.txt"
        state.issuerDomain = "https://example.com"

        let validator = InputValidator(state: state)
        validator.executeValidation()

        XCTAssertFalse(state.isFullyValid)
        XCTAssertEqual(state.encounterError, .invalidFileExtension)
    }

    func testInsecureProtocolFails() {
        let state = ValidationState()
        state.documentPath = "/sciezka/do/pliku.pdf"
        state.issuerDomain = "http://example.com"

        let validator = InputValidator(state: state)
        validator.executeValidation()

        XCTAssertFalse(state.isFullyValid)
        XCTAssertEqual(state.encounterError, .insecureProtocol)
    }
}
