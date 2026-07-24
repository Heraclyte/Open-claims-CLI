import Foundation

struct PayloadBuilder {
    static func build(
        issuer: String,
        claimType: String,
        subject: String,
        recipientType: String,
        assertionType: String?,
        skill: String?
    ) throws -> String {
        
        // Specification Validation: Enforce credential requirements
        if claimType == "credential" {
            guard let _ = assertionType, let _ = skill else {
                throw NSError(
                    domain: "OpenClaims",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Error: 'credential' claims strictly require --assertion-type and --skill."]
                )
            }
        }
        
        let isoFormatter = ISO8601DateFormatter()
        let issuedAtTimestamp = isoFormatter.string(from: Date())
        let generatedClaimId = UUID().uuidString
        
        let recipient = RecipientData(
            recipientType: recipientType,
            recipientIdentifier: subject
        )
        
        let envelope = ClaimEnvelope(
            specVersion: "v0.2",
            claimId: generatedClaimId,
            claimType: claimType,
            issuer: issuer,
            issuedAt: issuedAtTimestamp,
            recipientData: recipient,
            assertionType: assertionType,
            skill: skill,
            signature: "UNINITIALIZED_SIGNATURE" // Placeholder
        )
        
        return try envelope.toJSONString()
    }
}
