import ArgumentParser
import Foundation

struct Create: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Generates a verifiable claim and saves it to a JSON file."
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

    @Option(name: .long, help: "Path to write the output JSON claim file.")
    var output: String

    @Option(name: .long, help: "Path to the Ed25519 private key file.")
    var privateKey: String?

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
