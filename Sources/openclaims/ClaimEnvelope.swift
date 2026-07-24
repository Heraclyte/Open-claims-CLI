import Foundation

// MARK: - Recipient Data
struct RecipientData: Codable {
    let recipientType: String
    let recipientIdentifier: String
    
    enum CodingKeys: String, CodingKey {
        case recipientType = "recipient_type"
        case recipientIdentifier = "recipient_identifier"
    }
}

// MARK: - Core Envelope
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

    let signature: String
    
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
    
    func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "OpenClaims", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string."])
        }
        return jsonString
    }
}
