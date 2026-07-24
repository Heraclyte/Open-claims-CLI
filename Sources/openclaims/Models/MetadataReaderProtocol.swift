import Foundation

public enum MetadataReaderError: Error, Equatable {
    case fileReadFailure
    case metadataNotFound
    case invalidFormat
}

public protocol MetadataReaderProtocol: Sendable {
    func extractIssuerURL(fromFilePath path: String) async throws -> URL
}
