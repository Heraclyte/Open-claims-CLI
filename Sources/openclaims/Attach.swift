import ArgumentParser
import Foundation

struct Attach: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "attach",
        abstract: "Generates a claim and embeds it into a PDF's hidden metadata layer."
    )

    @Option(name: .long, help: "The issuer domain.")
    var issuer: String

    @Option(name: .long, help: "The type of claim (e.g., credential).")
    var claimType: String

    @Option(name: .long, help: "The subject identifier (e.g., email or ID).")
    var subject: String

    @Option(name: .long, help: "Path to the input PDF.")
    var pdf: String

    @Option(name: .long, help: "Path to write the output PDF.")
    var output: String

    mutating func run() throws {
        print("Executing Attach Command...")
        
        // 1. Generate Dynamic Envelope Data
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
            signature: "UNINITIALIZED_SIGNATURE" // Placeholder as cryptography is deferred[cite: 1]
        )
        
        // 2. Test JSON Generation
        let jsonPayload = try envelope.toJSONString()
        print("✅ Generated Payload: \(jsonPayload)")
        
        // Initialize our isolated engine
        let engine = PDFEngine(inputPath: pdf, outputPath: output)
        
        // Execute the engine logic and pass the payload
        do {
            try engine.process(payload: jsonPayload)
        } catch {
            print("❌ Engine Failure: \(error)")
        }
    }
}
