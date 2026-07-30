import ArgumentParser
import Foundation

/// A command-line utility subcommand that generates a verifiable claim and saves it to a JSON file.
///
/// The `Create` command gathers necessary claim attributes, constructs a verifiable payload,
/// and writes the finalized JSON document to a specified local path.
struct Create: ParsableCommand {
    
    /// Configuration details for the `create` subcommand, defining its CLI name and abstract.
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Generates a verifiable claim and saves it to a JSON file."
    )

    /// The domain or identifier of the entity issuing the claim.
    @Option(name: .long, help: "The issuer domain.")
    var issuer: String

    /// The type or category of the claim (e.g., "credential").
    @Option(name: .long, help: "The type of claim (e.g., credential).")
    var claimType: String

    /// The identifier of the subject receiving the claim (e.g., an email address or unique ID).
    @Option(name: .long, help: "The subject identifier (e.g., email or ID).")
    var subject: String

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

    /// The file path where the generated JSON claim document will be saved.
    @Option(name: .long, help: "Path to write the output JSON claim file.")
    var output: String

    /// The file path to an Ed25519 private key used to cryptographically sign the claim.
    @Option(name: .long, help: "Path to the Ed25519 private key file.")
    var privateKey: String?

    /// Executes the create command operations.
    ///
    /// This method performs the following sequential steps:
    /// 1. Uses `PayloadBuilder` to construct the JSON payload based on the provided CLI arguments and optional private key.
    /// 2. Expands the provided output file path to correctly handle tildes (`~`) in the path directory.
    /// 3. Writes the generated JSON payload to the specified output destination.
    ///
    /// - Throws: An error if payload generation fails or if the system cannot write to the designated output path.
    mutating func run() throws {
        print("Executing Create Command...")
        
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
            
            let expandedOutputPath = NSString(string: output).expandingTildeInPath
            let outputURL = URL(fileURLWithPath: expandedOutputPath)
            
            try jsonPayload.write(to: outputURL, atomically: true, encoding: .utf8)
            print("✅ Successfully generated and saved claim to: \(output)")
            
        } catch {
            print("❌ Command Failure: \(error.localizedDescription)")
        }
    }
}
