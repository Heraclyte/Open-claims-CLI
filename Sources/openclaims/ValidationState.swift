import Foundation

public enum ValidationError: Error, Equatable {
    case fileMissing
    case insecureProtocol
    case invalidUrlStructure
    case invalidFileExtension
    case fileNotReadable
    case missingHost
}

public class ValidationState {
    var documentPath: String = ""
    var issuerDomain: String = ""
    var encounterError: ValidationError? = nil
    var isFullyValid: Bool = false

    public init() {}
}
