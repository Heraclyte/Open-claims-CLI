import Foundation
import Crypto

/// A cryptographic utility structure responsible for signing and verifying data using Ed25519 keys.
struct Signer {
    
    /// The standard PKCS#8 prefix for an Ed25519 private key, consisting of 16 bytes.
    private static let ed25519PrivateKeyPrefix: [UInt8] = [
        0x30, 0x2e, 0x02, 0x01, 0x00, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x04, 0x22, 0x04, 0x20
    ]
    
    /// The standard SPKI prefix for an Ed25519 public key, consisting of 12 bytes.
    private static let ed25519PublicKeyPrefix: [UInt8] = [
        0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00
    ]

    /// Loads an Ed25519 private key (supporting raw 32 bytes or OpenSSL PEM/DER formats) and signs the data.
    ///
    /// - Parameters:
    ///   - data: The data to be cryptographically signed.
    ///   - privateKeyPath: The file path to the Ed25519 private key.
    /// - Returns: A base64-encoded string representing the generated signature.
    /// - Throws: An error if the key file cannot be read, parsed, or if the signing operation fails.
    static func sign(data: Data, privateKeyPath: String) throws -> String {
        let expandedPath = NSString(string: privateKeyPath).expandingTildeInPath
        let keyURL = URL(fileURLWithPath: expandedPath).standardizedFileURL
        let keyData = try Data(contentsOf: keyURL)
        
        let privateKey = try loadPrivateKey(from: keyData)
        let signatureData = try privateKey.signature(for: data)
        return signatureData.base64EncodedString()
    }
    
    /// Verifies a base64-encoded cryptographic signature against the provided data using an Ed25519 public key.
    ///
    /// - Parameters:
    ///   - signatureBase64: The base64-encoded signature string to verify.
    ///   - data: The original data that was signed.
    ///   - publicKeyPath: The file path to the Ed25519 public key.
    /// - Returns: A boolean indicating whether the signature is valid for the provided data.
    /// - Throws: An error if the public key file cannot be read or parsed.
    static func verify(signatureBase64: String, data: Data, publicKeyPath: String) throws -> Bool {
        guard let signatureData = Data(base64Encoded: signatureBase64) else { return false }
        let expandedPath = NSString(string: publicKeyPath).expandingTildeInPath
        let keyURL = URL(fileURLWithPath: expandedPath).standardizedFileURL
        let keyData = try Data(contentsOf: keyURL)
        
        let publicKey = try loadPublicKey(from: keyData)
        return publicKey.isValidSignature(signatureData, for: data)
    }
    
    // MARK: - Key Parsing Helpers
    
    /// Parses and instantiates an Ed25519 private key from raw data or a PEM-encoded format.
    ///
    /// - Parameter data: The raw or PEM-encoded key data.
    /// - Returns: A valid `Curve25519.Signing.PrivateKey` instance.
    /// - Throws: An `NSError` if the key format is invalid or does not match the expected 32-byte raw or PKCS#8 structure.
    private static func loadPrivateKey(from data: Data) throws -> Curve25519.Signing.PrivateKey {
        if data.count == 32 {
            return try Curve25519.Signing.PrivateKey(rawRepresentation: data)
        }
        
        // Strip PEM headers/footers and whitespaces if it's an OpenSSL PEM file
        let rawBytes = extractRawBytesFromPEM(data: data, prefix: "PRIVATE KEY")
        
        // Validate that this is exactly a 48-byte PKCS#8 Ed25519 key by checking the OID prefix
        guard rawBytes.count == 48, rawBytes.prefix(16).elementsEqual(ed25519PrivateKeyPrefix) else {
            throw NSError(
                domain: "SignerError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid key format. Expected a raw 32-byte Ed25519 private key or a valid PKCS#8 PEM/DER file."]
            )
        }
        
        // It is now safe to extract the 32-byte raw private key bytes
        let seedBytes = rawBytes.suffix(32)
        return try Curve25519.Signing.PrivateKey(rawRepresentation: seedBytes)
    }
    
    /// Parses and instantiates an Ed25519 public key from raw data or a PEM-encoded format.
    ///
    /// - Parameter data: The raw or PEM-encoded key data.
    /// - Returns: A valid `Curve25519.Signing.PublicKey` instance.
    /// - Throws: An `NSError` if the key format is invalid or does not match the expected 32-byte raw or SPKI structure.
    private static func loadPublicKey(from data: Data) throws -> Curve25519.Signing.PublicKey {
        if data.count == 32 {
            return try Curve25519.Signing.PublicKey(rawRepresentation: data)
        }
        
        // Strip PEM headers/footers and whitespaces if it's an OpenSSL PEM file
        let rawBytes = extractRawBytesFromPEM(data: data, prefix: "PUBLIC KEY")
        
        // Validate that this is exactly a 44-byte SPKI Ed25519 key by checking the OID prefix
        guard rawBytes.count == 44, rawBytes.prefix(12).elementsEqual(ed25519PublicKeyPrefix) else {
            throw NSError(
                domain: "SignerError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid key format. Expected a raw 32-byte Ed25519 public key or a valid SPKI PEM/DER file."]
            )
        }
        
        // It is now safe to extract the trailing 32 bytes for the public key
        let keyBytes = rawBytes.suffix(32)
        return try Curve25519.Signing.PublicKey(rawRepresentation: keyBytes)
    }
    
    /// Extracts raw base64-decoded bytes from a PEM-formatted data block by stripping headers, footers, and whitespace.
    ///
    /// - Parameters:
    ///   - data: The PEM-encoded data.
    ///   - prefix: The specific string prefix used in the PEM header/footer (e.g., "PRIVATE KEY" or "PUBLIC KEY").
    /// - Returns: The decoded binary data if extraction succeeds, or the original data if parsing fails.
    private static func extractRawBytesFromPEM(data: Data, prefix: String) -> Data {
        guard let text = String(data: data, encoding: .utf8) else { return data }
        let cleaned = text
            .replacingOccurrences(of: "-----BEGIN \(prefix)-----", with: "")
            .replacingOccurrences(of: "-----END \(prefix)-----", with: "")
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .joined()
        return Data(base64Encoded: cleaned) ?? data
    }
}
