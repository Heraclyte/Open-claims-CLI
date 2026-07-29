import Foundation

public final class LocalPDFMetadataReader: MetadataReaderProtocol {
    public init() {}

    public func extractIssuerURL(fromFilePath path: String) async throws -> URL {
        let fileURL = URL(fileURLWithPath: path)

        guard let data = try? Data(contentsOf: fileURL) else {
            throw MetadataReaderError.fileReadFailure
        }

        let content = String(decoding: data, as: UTF8.self)
        let lines = content.components(separatedBy: .newlines)

        var foundURLString: String?

        for line in lines {

            if let range = line.range(of: "OpenClaimsIssuer: ") {
                let substring = line[range.upperBound...]
                let components = substring.split(separator: " ")
                if let firstComponent = components.first {
                    foundURLString = String(firstComponent).trimmingCharacters(
                        in: .whitespacesAndNewlines)
                    break
                }
            }
        }

        guard let urlString = foundURLString,
            let url = URL(string: urlString)
        else {
            throw MetadataReaderError.metadataNotFound
        }

        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw MetadataReaderError.metadataNotFound
        }

        return url
    }
}
