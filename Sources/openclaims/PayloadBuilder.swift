import Foundation

struct PayloadBuilder {
    static func build(
        issuer: String,
        claimType: String,
        subject: String,
        recipientType: String,
        assertionType: String?,
        skill: String?,
        rawMetadata: String?,
        privateKeyPath: String?
    ) throws -> String {
        
        if claimType == "credential" {
            guard let _ = assertionType, let _ = skill else {
                throw NSError(
                    domain: "OpenClaims",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Error: 'credential' claims strictly require --assertion-type and --skill."]
                )
            }
        }

        var parsedMetadata: [String: String]? = nil
        if let jsonString = rawMetadata, let data = jsonString.data(using: .utf8) {
            parsedMetadata = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        }

        let isoFormatter = ISO8601DateFormatter()
        let issuedAtTimestamp = isoFormatter.string(from: Date())
        let generatedClaimId = UUID().uuidString
        
        let recipient = RecipientData(
            recipientType: recipientType,
            recipientIdentifier: subject
        )
        
        // 1. Construct envelope with nil signature to establish canonical form
        let envelope = ClaimEnvelope(
            specVersion: "v0.2",
            claimId: generatedClaimId,
            claimType: claimType,
            issuer: issuer,
            issuedAt: issuedAtTimestamp,
            recipientData: recipient,
            assertionType: assertionType,
            skill: skill,
            metadata: parsedMetadata,
            signature: nil
        )
        
        let canonicalJsonString = try envelope.toJSONString(excludeSignature: true)
        let canonicalData = Data(canonicalJsonString.utf8)
        
        // 2. Generate actual signature if private key path is provided
        let finalSignature: String?
        if let keyPath = privateKeyPath {
            finalSignature = try Signer.sign(data: canonicalData, privateKeyPath: keyPath)
        } else {
            finalSignature = nil
        }
        
        // 3. Re-instantiate envelope including the valid signature string
        let signedEnvelope = ClaimEnvelope(
            specVersion: "v0.2",
            claimId: generatedClaimId,
            claimType: claimType,
            issuer: issuer,
            issuedAt: issuedAtTimestamp,
            recipientData: recipient,
            assertionType: assertionType,
            skill: skill,
            metadata: parsedMetadata,
            signature: finalSignature
        )
        
        return try signedEnvelope.toJSONString(excludeSignature: false)
    }
}
