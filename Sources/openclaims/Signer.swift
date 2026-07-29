import Foundation
import Crypto

struct Signer {
    
    // Standard PKCS#8 Ed25519 Private Key Prefix (16 bytes)
    private static let ed25519PrivateKeyPrefix: [UInt8] = [
        0x30, 0x2e, 0x02, 0x01, 0x00, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x04, 0x22, 0x04, 0x20
    ]
    
    // Standard SPKI Ed25519 Public Key Prefix (12 bytes)
    private static let ed25519PublicKeyPrefix: [UInt8] = [
        0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00
    ]

    /// Loads an Ed25519 private key (supporting raw 32 bytes or OpenSSL PEM/DER formats) and signs the data.
    static func sign(data: Data, privateKeyPath: String) throws -> String {
        let expandedPath = NSString(string: privateKeyPath).expandingTildeInPath
        let keyURL = URL(fileURLWithPath: expandedPath).standardizedFileURL
        let keyData = try Data(contentsOf: keyURL)
        
        let privateKey = try loadPrivateKey(from: keyData)
        let signatureData = try privateKey.signature(for: data)
        return signatureData.base64EncodedString()
    }
    
    static func verify(signatureBase64: String, data: Data, publicKeyPath: String) throws -> Bool {
        guard let signatureData = Data(base64Encoded: signatureBase64) else { return false }
        let expandedPath = NSString(string: publicKeyPath).expandingTildeInPath
        let keyURL = URL(fileURLWithPath: expandedPath).standardizedFileURL
        let keyData = try Data(contentsOf: keyURL)
        
        let publicKey = try loadPublicKey(from: keyData)
        return publicKey.isValidSignature(signatureData, for: data)
    }
    
    // MARK: - Key Parsing Helpers
    
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
