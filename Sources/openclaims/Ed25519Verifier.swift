import Foundation

#if canImport(CryptoKit)
    import CryptoKit
#else
    import Crypto
#endif

public protocol CryptographicVerifier {
    func validate(signature: Data, payload: Data, publicKey: Data) throws
}

public enum SecurityError: Error {
    case invalidKeyFormat
    case signatureVerificationFailed
}

public struct Ed25519Verifier: CryptographicVerifier {
    public init() {}

    public func validate(signature: Data, payload: Data, publicKey: Data) throws {
        let key = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKey)

        guard let validKey = key else {
            throw SecurityError.invalidKeyFormat
        }

        let isAuthentic = validKey.isValidSignature(signature, for: payload)

        if !isAuthentic {
            throw SecurityError.signatureVerificationFailed
        }
    }
}
