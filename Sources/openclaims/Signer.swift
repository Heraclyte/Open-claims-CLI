import Foundation
import Crypto

struct Signer {
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
        // An PKCS#8 Ed25519 private key in DER format ends with the 32-byte raw private key bytes
        let seedBytes = rawBytes.suffix(32)
        return try Curve25519.Signing.PrivateKey(rawRepresentation: seedBytes)
    }
    
    private static func loadPublicKey(from data: Data) throws -> Curve25519.Signing.PublicKey {
        if data.count == 32 {
            return try Curve25519.Signing.PublicKey(rawRepresentation: data)
        }
        
        // Strip PEM headers/footers and extract trailing 32 bytes for public key DER
        let rawBytes = extractRawBytesFromPEM(data: data, prefix: "PUBLIC KEY")
        let keyBytes = rawBytes.suffix(32)
        return try Curve25519.Signing.PublicKey(rawRepresentation: keyBytes)
    }
    
    private static func extractRawBytesFromPEM(data: Data, prefix: String) -> Data {
        guard let text = String(data: data, encoding: .utf8) else { return data }
        let cleaned = text
            .replacingOccurrences(of: "-----BEGIN \(prefix)-----", with: "")
            .replacingOccurrences(of: "-----END \(prefix)-----", with: "")
            .components(separatedBy:CharacterSet.whitespacesAndNewlines)
            .joined()
        return Data(base64Encoded: cleaned) ?? data
    }
}
