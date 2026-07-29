import Foundation

public struct ClaimEnvelope: Codable, Sendable {
    public let id: String
    public let issuer: URL
    public let issuedAt: Date
    public let claim: ClaimDetails
    public let signature: Data

    public init(
        id: String, issuer: URL, issuedAt: Date, claim: ClaimDetails, signature: Data
    ) {
        self.id = id
        self.issuer = issuer
        self.issuedAt = issuedAt
        self.claim = claim
        self.signature = signature
    }
}

public struct ClaimDetails: Codable, Sendable {
    public let subject: String
    public let assertion: String

    public init(subject: String, assertion: String) {
        self.subject = subject
        self.assertion = assertion
    }
}
