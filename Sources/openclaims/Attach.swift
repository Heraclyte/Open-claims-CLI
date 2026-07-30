import ArgumentParser
import Foundation

struct Attach: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "attach",
        abstract: "Embeds a claim into a PDF's hidden metadata layer. Can generate a claim on the fly or use a pre-existing one."
    )

    // Option 1: Use a pre-generated claim
    @Option(name: .long, help: "Path to a pre-generated JSON claim file. If provided, overrides on-the-fly generation arguments.")
    var payloadFile: String?

    // Option 2: On-the-fly generation arguments (now optional)
    @Option(name: .long, help: "The issuer domain. (Required if not using --payload-file)")
    var issuer: String?

    @Option(name: .long, help: "The type of claim (e.g., credential). (Required if not using --payload-file)")
    var claimType: String?

    @Option(name: .long, help: "The subject identifier (e.g., email or ID). (Required if not using --payload-file)")
    var subject: String?

    @Option(name: .long, help: "The type of recipient (individual or organization).")
    var recipientType: String = "individual"

    @Option(name: .long, help: "The epistemic weight (e.g., certification, completion). Required for credentials.")
    var assertionType: String?

    @Option(name: .long, help: "The skill, course, or role being asserted. Required for credentials.")
    var skill: String?

    @Option(name: .long, help: "Custom metadata as a JSON string (e.g., '{\"score\":\"95\"}').")
    var metadata: String?
    
    @Option(name: .long, help: "Path to the Ed25519 private key file.")
    var privateKey: String?

    // PDF specific options (Always required)
    @Option(name: .long, help: "Path to the input PDF.")
    var pdf: String

    @Option(name: .long, help: "Path to write the output PDF.")
    var output: String

    mutating func run() throws {
        print("Executing Attach Command...")
        
        do {
            let finalPayload: String
            
            if let payloadPath = payloadFile {
                // Path A: Load pre-generated claim
                let expandedPath = NSString(string: payloadPath).expandingTildeInPath
                let payloadURL = URL(fileURLWithPath: expandedPath)
                finalPayload = try String(contentsOf: payloadURL, encoding: .utf8)
                print("✅ Loaded pre-generated payload from file.")
            } else {
                // Path B: Generate on the fly
                // We must validate that the required generation fields are present
                guard let issuer = issuer, let claimType = claimType, let subject = subject else {
                    throw CleanExit.message("You must provide --issuer, --claim-type, and --subject if you are not using --payload-file.")
                }
                
                finalPayload = try PayloadBuilder.build(
                    issuer: issuer,
                    claimType: claimType,
                    subject: subject,
                    recipientType: recipientType,
                    assertionType: assertionType,
                    skill: skill,
                    rawMetadata: metadata,
                    privateKeyPath: privateKey
                )
                print("✅ Generated Payload on the fly.")
            }
            
            // Proceed with PDF injection
            let engine = PDFEngine(inputPath: pdf, outputPath: output)
            try engine.process(payload: finalPayload)
            
        } catch {
            print("❌ Command Failure: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}
