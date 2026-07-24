import Foundation

public final class VerificationState: @unchecked Sendable {
    public enum Status: Equatable {
        case idle
        case processing
        case valid
        case failed

    }

    public private(set) var status: Status = .idle
    public private(set) var extractedURL: URL?
    public private(set) var envelope: ClaimEnvelope?
    public private(set) var lastError: Error?

    public init() {}

    public func markAsProcessing() {
        status = .processing
        lastError = nil
    }

    public func setIssuerURL(_ url: URL) {
        extractedURL = url
    }

    public func setEnvelope(_ envelope: ClaimEnvelope) {
        self.envelope = envelope
    }

    public func markAsValid() {
        status = .valid
    }

    public func setError(_ error: Error) {
        status = .failed
        lastError = error
    }

}
