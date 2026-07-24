import Foundation

// MARK: - Recipient Data
// Supports both individuals and organizations, per the specification.
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
    let signature: String
    
    enum CodingKeys: String, CodingKey {
        case specVersion = "spec_version"
        case claimId = "claim_id"
        case claimType = "claim_type"
        case issuer
        case issuedAt = "issued_at"
        case recipientData = "recipient_data"
        case signature
    }
    
    // Helper method to convert the struct into a formatted JSON String
    func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        // We do NOT use pretty printing here because we want the JSON 
        // to be as compact as possible for embedding in the PDF bytes.
        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "OpenClaims", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string."])
        }
        return jsonString
    }
}
