import Foundation

/// A utility structure responsible for constructing and signing verifiable claim payloads.
struct PayloadBuilder {
    
    /// Constructs a complete, signed verifiable claim formatted as a JSON string.
    ///
    /// This method handles validation, metadata parsing, canonicalization, and cryptographic signing.
    /// It enforces strict requirements for specific claim types (e.g., "credential"), generates
    /// a canonical representation of the claim, and applies an Ed25519 signature if a private key is provided.
    ///
    /// - Parameters:
    ///   - issuer: The domain or identifier of the entity issuing the claim.
    ///   - claimType: The type or category of the claim (e.g., "credential").
    ///   - subject: The identifier of the subject receiving the claim (e.g., an email address or unique ID).
    ///   - recipientType: The classification of the recipient (e.g., "individual").
    ///   - assertionType: The epistemic weight or nature of the assertion (e.g., "certification"). Required if `claimType` is "credential".
    ///   - skill: The specific skill, course, or role being asserted. Required if `claimType` is "credential".
    ///   - rawMetadata: Additional custom metadata formatted as a serialized JSON string.
    ///   - privateKeyPath: The file path to an Ed25519 private key used to cryptographically sign the claim.
    /// - Returns: A fully constructed and signed JSON string representing the claim envelope.
    /// - Throws: An `NSError` if a "credential" claim is missing required fields, or if cryptographic signing or JSON serialization fails.
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
