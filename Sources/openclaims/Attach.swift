import ArgumentParser

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

    @Option(name: .long, help: "The type of recipient (individual or organization).")
    var recipientType: String = "individual"

    @Option(name: .long, help: "The epistemic weight (e.g., certification, completion). Required for credentials.")
    var assertionType: String?

    @Option(name: .long, help: "The skill, course, or role being asserted. Required for credentials.")
    var skill: String?

    @Option(name: .long, help: "Custom metadata as a JSON string (e.g., '{\"score\":\"95\"}').")
    var metadata: String?

    @Option(name: .long, help: "Path to the input PDF.")
    var pdf: String

    @Option(name: .long, help: "Path to write the output PDF.")
    var output: String

    @Option(name: .long, help: "Path to the Ed25519 private key file.")
    var privateKey: String?

    mutating func run() throws {
        print("Executing Attach Command...")
        
        do {
            let jsonPayload = try PayloadBuilder.build(
                issuer: issuer,
                claimType: claimType,
                subject: subject,
                recipientType: recipientType,
                assertionType: assertionType,
                skill: skill,
                rawMetadata: metadata,
                privateKeyPath: privateKey
            )
            print("✅ Generated Payload: \(jsonPayload)")
            
            let engine = PDFEngine(inputPath: pdf, outputPath: output)
            try engine.process(payload: jsonPayload)
            
        } catch {
            print("❌ Command Failure: \(error.localizedDescription)")
        }
    }
}
