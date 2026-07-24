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

    @Option(name: .long, help: "Path to the input PDF.")
    var pdf: String

    @Option(name: .long, help: "Path to write the output PDF.")
    var output: String

    mutating func run() throws {
        print("Executing Attach Command...")
        print("-> Issuer: \(issuer)")
        print("-> Claim Type: \(claimType)")
        print("-> Subject: \(subject)")
        print("-> Input PDF: \(pdf)")
        print("-> Target Output: \(output)")
    }
}
