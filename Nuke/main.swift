//
//  main.swift
//  Nuke
//
//  Created by Federico Cappelli on 03/07/2025.
//

import Foundation

// Define the valid commands
enum NukeCommand: String, CaseIterable {
    case ddgvpn
    case ddgapp
    case xcode

    var helpText: String {
        switch self {
        case .ddgvpn:
            return "Cleans up DuckDuckGo VPN configurations and related cached data."
        case .ddgapp:
            return "Cleans up DuckDuckGo App data, including preferences, cache, or sandbox."
        case .xcode:
            return "Cleans Xcode derived data and Swift Package Manager build cache."
        }
    }

    func execute(arguments: [String]) {
        if arguments.contains("--help") {
            printHelp()
            return
        }

        switch self {
        case .ddgvpn:
            runDDGVPN()
        case .ddgapp:
            runDDGApp()
        case .xcode:
            runXcode()
        }
    }

    func printHelp() {
        print("""
        Usage: nuke \(self.rawValue) [--help]

        \(helpText)
        """)
    }
}

// Functions that correspond to each command
func runDDGVPN() {
    print("Removing all traces of the DDG macOS VPN...")

    deleteFolder(path: "/Applications/DEBUG")
    deleteFolder(path: "~/Library/Developer/Xcode/DerivedData/")

    runCommand("rm", arguments: ["-rf", "~/.Trash/*"])
    runCommand("rm", arguments: ["-rf", "~/.Trash/.*"])

    // Resetting system network extension
    runCommand("systemextensionsctl", arguments: ["reset"])

    // Terminate specified processes
    terminateProcess(matching: "com.duckduckgo.macos.vpn")
    terminateProcess(matching: "com.duckduckgo.macos.browser.network-protection.notifications")
    terminateProcess(matching: "com.duckduckgo.mobile.ios.vpn.agent.debug")
}

func runDDGApp() {
    print("Removing all traces of the DDG macOS app")

    deleteFolder(path: "/Applications/DEBUG")
    runCommand("rm", arguments: ["-rf", "~/.Trash/*"])
    runCommand("rm", arguments: ["-rf", "~/.Trash/.*"])

    // keychain


}

func runXcode() {
    print("Running xcode cleanup...")

    // 1. Terminate any running Xcode processes
    terminateProcess(matching: "Xcode")

    // 2. Delete Derived Data
    let derivedDataPath = "\(NSHomeDirectory())/Library/Developer/Xcode/DerivedData"
    deleteFolder(path: derivedDataPath)

    // 3. Delete SPM build cache
    let spmCachePath = "\(NSHomeDirectory())/Library/Caches/org.swift.swiftpm"
    deleteFolder(path: spmCachePath)

    print("Xcode cleanup complete.")
}

// Entry point

let arguments = CommandLine.arguments

guard arguments.count > 1 else {
    print("""
    Usage: nuke <command> [--help]

    Available commands:
    \(NukeCommand.allCases.map { "  \($0.rawValue)" }.joined(separator: "\n"))
    """)
    exit(1)
}

let input = arguments[1]
let extraArgs = Array(arguments.dropFirst(2))

guard let command = NukeCommand(rawValue: input) else {
    print("Unknown command: \(input)")
    print("Use `nuke <command> --help` for more info.")
    exit(1)
}

command.execute(arguments: extraArgs)
