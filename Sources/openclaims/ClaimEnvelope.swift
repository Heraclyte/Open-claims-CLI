import Foundation

/// A structure representing the recipient details within a verifiable claim.
struct RecipientData: Codable {
    /// The classification of the recipient (e.g., "individual" or "organization").
    let recipientType: String
    /// The unique identifier for the recipient (e.g., an email address or ID).
    let recipientIdentifier: String
    
    /// Keys used to map `RecipientData` properties to their respective JSON fields.
    enum CodingKeys: String, CodingKey {
        case recipientType = "recipient_type"
        case recipientIdentifier = "recipient_identifier"
    }
}

/// A structure representing the complete payload of a verifiable claim.
///
/// `ClaimEnvelope` contains all the necessary metadata, subject information,
/// and optional cryptographic signatures required to structure and validate a claim.
struct ClaimEnvelope: Codable {
    /// The specification version of the claim format.
    let specVersion: String
    /// A unique identifier generated for the specific claim.
    let claimId: String
    /// The type or category of the claim being issued.
    let claimType: String
    /// The domain or identifier of the entity issuing the claim.
    let issuer: String
    /// The timestamp indicating when the claim was generated.
    let issuedAt: String
    /// An object containing the recipient's type and identifier.
    let recipientData: RecipientData
    
    /// The epistemic weight or nature of the assertion.
    let assertionType: String?
    /// The specific skill, course, or role being asserted.
    let skill: String?
    /// Additional custom metadata provided as key-value pairs.
    let metadata: [String: String]?
    /// The cryptographic signature of the claim payload.
    /// Optional so it can be omitted during canonical encoding prior to signing.
    let signature: String?

    /// Keys used to map `ClaimEnvelope` properties to their respective JSON fields.
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
    
    /// Converts the claim envelope into a formatted JSON string.
    ///
    /// - Parameter excludeSignature: A boolean indicating whether to omit the `signature` field from the output.
    ///   When `true`, the method generates a canonical JSON representation (with sorted keys) used to create the data payload for signing.
    /// - Returns: A string representation of the encoded JSON data[.
    /// - Throws: An `NSError` if the JSON data cannot be serialized or converted to a UTF-8 string[.
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
