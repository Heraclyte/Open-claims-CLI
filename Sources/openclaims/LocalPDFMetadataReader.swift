import Foundation

public final class LocalPDFMetadataReader: MetadataReaderProtocol {
    public init() {}

    public func extractIssuerURL(fromFilePath path: String) async throws -> URL {
        let fileURL = URL(fileURLWithPath: path)

        guard let data = try? Data(contentsOf: fileURL) else {
            throw MetadataReaderError.fileReadFailure
        }

        let content = String(decoding: data, as: UTF8.self)

        guard let range = content.range(of: "OpenClaimsIssuer: ") else {
            throw MetadataReaderError.metadataNotFound
        }

        let substring = content[range.upperBound...]
        let components = substring.split(separator: " ")

        guard let urlString = components.first,
            let url = URL(string: String(urlString).trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            throw MetadataReaderError.metadataNotFound
        }

        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw MetadataReaderError.metadataNotFound
        }

        return url
    }
}
