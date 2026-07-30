import Foundation

public class InputValidator {

    private let state: ValidationState

    public init(state: ValidationState) {
        self.state = state
    }

    public func executeValidation() {
        let fileManager = FileManager.default
        let fileUrl = URL(fileURLWithPath: state.documentPath)
        if fileManager.fileExists(atPath: state.documentPath) == false {
            state.encounterError = .fileMissing
            return
        }

        if fileUrl.pathExtension.lowercased() != "pdf" {
            state.encounterError = .invalidFileExtension
            return
        }

        if fileManager.isReadableFile(atPath: state.documentPath) == false {
            state.encounterError = .fileNotReadable
            return
        }

        guard let url = URL(string: state.issuerDomain) else {
            state.encounterError = .invalidUrlStructure
            return
        }

        if url.scheme != "https" {

            let isLocalhost = url.host == "localhost" || url.host == "127.0.0.1"
            if url.scheme == "http" && isLocalhost {

            } else {
                state.encounterError = .insecureProtocol
                return
            }
        }

        if url.host == nil {
            state.encounterError = .missingHost
            return
        }

        state.isFullyValid = true
    }
}
