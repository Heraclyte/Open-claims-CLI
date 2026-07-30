import ArgumentParser

@main
struct OpenClaimsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "openclaims",
        abstract: "A utility for embedding verifiable claims into PDF documents.",
        version: "0.2.0",
        subcommands: [Attach.self, Create.self, VerifyCommand.self] 
    )
}
