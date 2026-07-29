import Foundation
import XCTest

@testable import openclaims

final class InputValidatorTests: XCTestCase {
    var validPDFPath: String = ""
    var invalidTXTPath: String = ""

    override func setUp() {
        super.setUp()
        let tempDir = FileManager.default.temporaryDirectory

        let validURL = tempDir.appendingPathComponent("dummy_file.pdf")
        FileManager.default.createFile(atPath: validURL.path, contents: Data(), attributes: nil)
        validPDFPath = validURL.path

        let invalidURL = tempDir.appendingPathComponent("dummy_file.txt")
        FileManager.default.createFile(atPath: invalidURL.path, contents: Data(), attributes: nil)
        invalidTXTPath = invalidURL.path
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: validPDFPath)
        try? FileManager.default.removeItem(atPath: invalidTXTPath)
        super.tearDown()
    }

    func testValidInputPassesValidation() {
        let state = ValidationState()
        state.documentPath = validPDFPath
        state.issuerDomain = "https://example.com"

        let validator = InputValidator(state: state)
        validator.executeValidation()

        XCTAssertTrue(state.isFullyValid)
        XCTAssertNil(state.encounterError)
    }
    func testInvalidFileExtensionFails() {
        let state = ValidationState()
        state.documentPath = invalidTXTPath
        state.issuerDomain = "example.com"

        let validator = InputValidator(state: state)
        validator.executeValidation()

        XCTAssertEqual(state.encounterError, ValidationError.invalidFileExtension)
    }

    func testInsecureProtocolFails() {
        let state = ValidationState()
        state.documentPath = validPDFPath
        state.issuerDomain = "http://example.com"

        let validator = InputValidator(state: state)
        validator.executeValidation()

        XCTAssertEqual(state.encounterError, ValidationError.insecureProtocol)
    }
}
