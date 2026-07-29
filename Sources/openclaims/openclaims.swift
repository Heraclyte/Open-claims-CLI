// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser

/// The main entry point for the OpenClaims command-line interface tool.
///
/// `OpenClaimsCommand` serves as the root executable that configures and routes
/// user commands for securely generating and embedding verifiable cryptographic 
/// data payloads within PDF documents.
@main
struct OpenClaimsCommand: ParsableCommand {

    /// The configuration for the root command, defining its identity, abstract, version,
    /// and the available subcommands for execution.
    static let configuration = CommandConfiguration(
        commandName: "openclaims",
        abstract: "A utility for embedding verifiable claims into PDF documents.",
        version: "0.2.0",
        // This array registers your subcommands
        subcommands: [Attach.self, Create.self, VerifyCommand.self] 
    )
}
