import Foundation

public struct RecipientData: Codable {
    let recipientType: String
    let recipientIdentifier: String

    enum CodingKeys: String, CodingKey {
        case recipientType = "recipient_type"
        case recipientIdentifier = "recipient_identifier"
    }
}

public struct ClaimEnvelope: Codable {
    let specVersion: String
    let claimId: String
    let claimType: String
    let issuer: String
    let issuedAt: String
    let recipientData: RecipientData

    let assertionType: String?
    let skill: String?
    let metadata: [String: String]?
    let signature: String?

    enum CodingKeys: String, CodingKey {
        case specVersion = "spec_version"
        case claimId = "claim_id"
        case claimType = "claim_type"
        case issuer
        case issuedAt = "issued_at"
        case recipientData = "recipient_data"
        case assertionType = "assertion_type"
        case skill
        case metadata
        case signature
    }

    public func toJSONString(excludeSignature: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(self)
        guard var dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(
                domain: "ClaimEnvelope", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON dictionary"])
        }

        if excludeSignature {
            dictionary.removeValue(forKey: "signature")
        }

        func sanitize(_ input: [String: Any]) -> [String: Any] {
            var result = [String: Any]()
            for (key, value) in input {
                if value is NSNull { continue }
                if let subDict = value as? [String: Any] {
                    result[key] = sanitize(subDict)
                } else {
                    result[key] = value
                }
            }
            return result
        }

        let cleanedDict = sanitize(dictionary)
        let sortedData = try JSONSerialization.data(
            withJSONObject: cleanedDict, options: [.sortedKeys, .withoutEscapingSlashes])

        guard let jsonString = String(data: sortedData, encoding: .utf8) else {
            throw NSError(
                domain: "ClaimEnvelope", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create JSON string"])
        }

        return jsonString
    }
}
