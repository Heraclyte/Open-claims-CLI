import ArgumentParser
import Foundation

/// A command-line utility subcommand that embeds a verifiable claim into a PDF's hidden metadata layer.
///
/// The `Attach` command allows users to either inject a pre-existing JSON claim file or generate
/// a new claim dynamically using provided arguments. After the claim is resolved, it utilizes the
/// `PDFEngine` to securely embed the payload into the target PDF document.
struct Attach: ParsableCommand {
    
    /// Configuration details for the `attach` subcommand, defining its CLI name and abstract
    static let configuration = CommandConfiguration(
        commandName: "attach",
        abstract: "Embeds a claim into a PDF's hidden metadata layer. Can generate a claim on the fly or use a pre-existing one."
    )

    // Option 1: Use a pre-generated claim
    /// The file path to a pre-generated JSON claim.
    ///
    /// If provided, this overrides all on-the-fly generation arguments
    @Option(name: .long, help: "Path to a pre-generated JSON claim file. If provided, overrides on-the-fly generation arguments.")
    var payloadFile: String?

    // Option 2: On-the-fly generation arguments 
    /// The domain or identifier of the entity issuing the claim. Required if not using a pre-generated payload.
    @Option(name: .long, help: "The issuer domain. (Required if not using --payload-file)")
    var issuer: String?

    /// The type or category of the claim (e.g., "credential"). Required if not using a pre-generated payload.
    @Option(name: .long, help: "The type of claim (e.g., credential). (Required if not using --payload-file)")
    var claimType: String?

    /// The identifier of the subject receiving the claim (e.g., an email address or unique ID). Required if not using a pre-generated payload.
    @Option(name: .long, help: "The subject identifier (e.g., email or ID). (Required if not using --payload-file)")
    var subject: String?

    /// The classification of the recipient. Defaults to "individual".
    @Option(name: .long, help: "The type of recipient (individual or organization).")
    var recipientType: String = "individual"

    /// The epistemic weight or nature of the assertion (e.g., "certification", "completion"). Required for "credential" claims.
    @Option(name: .long, help: "The epistemic weight (e.g., certification, completion). Required for credentials.")
    var assertionType: String?

    /// The specific skill, course, or role being asserted by the claim. Required for "credential" claims.
    @Option(name: .long, help: "The skill, course, or role being asserted. Required for credentials.")
    var skill: String?

    /// Additional custom metadata formatted as a serialized JSON string.
    @Option(name: .long, help: "Custom metadata as a JSON string (e.g., '{\"score\":\"95\"}').")
    var metadata: String?

    /// The file path to an Ed25519 private key used to cryptographically sign the claim.
    @Option(name: .long, help: "Path to the Ed25519 private key file.")
    var privateKey: String?

    // PDF specific options (Always required)
    /// The file path to the source PDF document where the claim will be embedded.
    @Option(name: .long, help: "Path to the input PDF.")
    var pdf: String

    /// The file path where the modified PDF document will be saved.
    @Option(name: .long, help: "Path to write the output PDF.")
    var output: String


    /// Executes the attach command operations.
    ///
    /// This method performs the following sequential steps:
    /// 1. Resolves the payload by either loading a local JSON file or generating one dynamically.
    /// 2. Validates that the required generation fields (`issuer`, `claimType`, `subject`) are present if creating the payload on the fly.
    /// 3. Initializes the `PDFEngine` and processes the input PDF to embed the finalized payload, outputting the result.
    ///
    /// - Throws: `ExitCode.failure` if payload validation, generation, or PDF processing fails.
    mutating func run() throws {
        print("Executing Attach Command...")
        
        do {
            let finalPayload: String
            
            if let payloadPath = payloadFile {
    :            // Path A: Load pre-generated claim
                let expandedPath = NSString(string: payloadPath).expandingTildeInPath
                let payloadURL = URL(fileURLWithPath: expandedPath)
                finalPayload = try String(contentsOf: payloadURL, encoding: .utf8)
                print("✅ Loaded pre-generated payload from file.")
            } else {
                // Path B: Generate on the fly
                // We must validate that the required generation fields are present
                guard let issuer = issuer, let claimType = claimType, let subject = subject else {
                    throw ValidationError("You must provide --issuer, --claim-type, and --subject if you are not using --payload-file.")
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
