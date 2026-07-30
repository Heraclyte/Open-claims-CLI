import Foundation

public final class LocalPDFMetadataReader: MetadataReaderProtocol {
    public init() {}

    public func extractIssuerURL(fromFilePath path: String) async throws -> URL {
        let fileURL = URL(fileURLWithPath: path)

        guard let data = try? Data(contentsOf: fileURL) else {
            throw MetadataReaderError.fileReadFailure
        }

        let content = String(decoding: data, as: UTF8.self)
        var foundURLString: String?

        if let payloadRange = content.range(
            of: "/Subtype /OpenClaims /Payload (", options: .backwards)
        {
            let substring = content[payloadRange.upperBound...]
            if let endRange = substring.range(of: ")") {
                let payloadJSONString = String(substring[..<endRange.lowerBound])
                    .replacingOccurrences(of: "\\)", with: ")")
                    .replacingOccurrences(of: "\\(", with: "(")
                    .replacingOccurrences(of: "\\\\", with: "\\")

                if let jsonData = payloadJSONString.data(using: .utf8),
                    let jsonObject = try? JSONSerialization.jsonObject(with: jsonData)
                        as? [String: Any],
                    let issuer = jsonObject["issuer"] as? String
                {
                    foundURLString = issuer
                }
            }
        }

        if foundURLString == nil {
            let lines: [String] = content.components(separatedBy: .newlines).reversed()
            for line in lines {
                if let range = line.range(of: "OpenClaimsIssuer: ") {
                    let substring = line[range.upperBound...]
                    let components = substring.split(whereSeparator: {
                        $0.isWhitespace || $0.isNewline
                    })
                    if let firstComponent = components.first {
                        foundURLString = String(firstComponent).trimmingCharacters(
                            in: .whitespacesAndNewlines)
                        break
                    }
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
