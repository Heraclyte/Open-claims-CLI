import Foundation

struct RecipientData: Codable {
    let recipientType: String
    let recipientIdentifier: String
    
    enum CodingKeys: String, CodingKey {
        case recipientType = "recipient_type"
        case recipientIdentifier = "recipient_identifier"
    }
}

struct ClaimEnvelope: Codable {
    let specVersion: String
    let claimId: String
    let claimType: String
    let issuer: String
    let issuedAt: String
    let recipientData: RecipientData
    
    let assertionType: String?
    let skill: String?
    let metadata: [String: String]?
    let signature: String? // Optional so it can be omitted during canonical encoding

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
    
    func toJSONString(excludeSignature: Bool = false) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        
        if excludeSignature {
            // Create a mirror struct or encode dict explicitly dropping signature
            let canonicalDict: [String: Any?] = [
                "spec_version": specVersion,
                "claim_id": claimId,
                "claim_type": claimType,
                "issuer": issuer,
                "issued_at": issuedAt,
                "recipient_data": [
                    "recipient_type": recipientData.recipientType,
                    "recipient_identifier": recipientData.recipientIdentifier
                ],
                "assertion_type": assertionType,
                "skill": skill,
                "metadata": metadata
            ]
            let data = try JSONSerialization.data(withJSONObject: canonicalDict, options: [.sortedKeys])
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "OpenClaims", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert canonical JSON data to string."])
            }
            return jsonString
        } else {
            let data = try encoder.encode(self)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "OpenClaims", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string."])
            }
            return jsonString
        }
    }
}
