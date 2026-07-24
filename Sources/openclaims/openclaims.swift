// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser

@main
struct OpenClaimsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "openclaims",
        abstract: "A utility for embedding verifiable claims into PDF documents.",
        version: "0.2.0",
        // This array registers your subcommands
        subcommands: [Attach.self] 
    )

    mutating func run() throws {
        print("Hello World! ")
    }
}
