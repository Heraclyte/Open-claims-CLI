import Foundation

struct PayloadBuilder {
    /// Constructs the Open Claims JSON payload from raw inputs.
    static func build(issuer: String, claimType: String, subject: String) throws -> String {
        let isoFormatter = ISO8601DateFormatter()
        let issuedAtTimestamp = isoFormatter.string(from: Date())
        let generatedClaimId = UUID().uuidString
        
        let recipient = RecipientData(
            recipientType: "individual", // Defaulting to individual for the MVP[cite: 1]
            recipientIdentifier: subject
        )
        
        let envelope = ClaimEnvelope(
            specVersion: "v0.2",
            claimId: generatedClaimId,
            claimType: claimType,
            issuer: issuer,
            issuedAt: issuedAtTimestamp,
            recipientData: recipient,
            signature: "UNINITIALIZED_SIGNATURE" // Placeholder[cite: 1]
        )
        
        return try envelope.toJSONString()
    }
}
