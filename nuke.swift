//
//  nuke.swift
//  Nuke
//
//  Created by Federico Cappelli on 03/07/2025.
//

import Foundation

struct NukeTools {
    // MARK: - Tools

    // Execute a shell command
    static func runCommand(_ command: String, arguments: [String] = [], log: Bool = true) {
        if log { print("🚀 Running: \(command) \(arguments.joined(separator: " "))") }

        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = [command] + arguments
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        do {
            try process.run()
            process.waitUntilExit()
            if log { print("✅ \(command) executed successfully.") }
        } catch {
            print("❌ Error executing \(command): \(error)")
        }
    }

    // Find and terminate a process using part of its bundle identifier
    static func terminateProcess(matching keyword: String) {
        print("🔪 Terminating process matching: \(keyword)")

        let process = Process()
        let pipe = Pipe()
        let currentPid = ProcessInfo.processInfo.processIdentifier

        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "ps aux | grep '\(keyword)' | grep -v grep"]
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
                print("🔍 No running process found for keyword: \(keyword).")
                return
            }

            let lines = output.split(separator: "\n")
            for line in lines {
                let columns = line.split(separator: " ", omittingEmptySubsequences: true)
                let pidString = columns[1]
                print("🎯 Process pid found: \(pidString)")
                if let pid = Int(pidString), pid != Int(currentPid) {
                    runCommand("kill", arguments: ["-9", String(pid)], log: false)
                    print("💀 Terminated process with keyword '\(keyword)' and PID \(pid).")
                } else if let pid = Int(pidString), pid == Int(currentPid) {
                    print("⏩ Skipping current Swift process (PID \(pid))")
                }
            }

        } catch {
            print("❌ Error finding process with keyword \(keyword): \(error)")
        }
    }

    // Function to delete a folder
    static func deleteFolder(path: String) {
        print("🗑️ Deleting folder \(path)")
        // Use shell to handle expansions like ~ and *
        runCommand("sh", arguments: ["-c", "rm -rf \(path)"], log: false)
    }
}

struct NukeApp {

    // MARK: - Schema

    struct Schema: Codable {
        let name: String
        let description: String
        let paths: [String]
        let commands: [String]
        let processes: [String]
    }

    // MARK: - Parser

    struct SchemaParser {

        static func parseSchema(from filePath: String) throws -> Schema {
            let url = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Schema.self, from: data)
        }

        static func parseSchema(from url: URL) throws -> Schema {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Schema.self, from: data)
        }

        static func parseAllSchemas(in directoryPath: String) throws -> [Schema] {
            let url = URL(fileURLWithPath: directoryPath)
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(at: url,
                                                           includingPropertiesForKeys: nil,
                                                           options: [])

            let jsonFiles = files.filter { $0.pathExtension == "json" }
            var schemas: [Schema] = []

            for file in jsonFiles {
                do {
                    let schema = try parseSchema(from: file)
                    schemas.append(schema)
                } catch {
                    print("❌ Failed to parse schema from \(file.lastPathComponent): \(error)")
                }
            }

            return schemas
        }
    }

    // MARK: -

    func executeSchema(_ schema: Schema, arguments: [String]) {
        if arguments.contains("--help") {
            print("""
            Usage: nuke \(schema.name) [--help]

            \(schema.description)
            """)
            return
        }

        print("""
            🚀 Running \(schema.name)
                - \(schema.description)
            """)

        // Terminate processes
        for process in schema.processes {
            NukeTools.terminateProcess(matching: process)
        }

        // Delete paths
        for path in schema.paths {
            NukeTools.deleteFolder(path: path)
        }

        // Execute commands
        for command in schema.commands {
            let components = command.split(separator: " ", maxSplits: 1)
            if components.count >= 1 {
                let cmd = String(components[0])
                let args = components.count > 1 ? String(components[1]).split(separator: " ").map(String.init) : []
                NukeTools.runCommand(cmd, arguments: args)
            }
        }

        print("☢️  \(schema.name) nuked")
    }

    func parseAllSchemas(schemasPath: String) -> [Schema] {
        do {
            return try SchemaParser.parseAllSchemas(in: schemasPath)
        } catch {
            print("❌ Error loading schemas: \(error)")
            exit(1)
        }
    }

    func run(arguments: [String]) {
        // Handle case where only schemas path is provided: -s <schemas_path>
        if arguments.count == 3 && arguments[1] == "-s" {
            let schemasPath = arguments[2]
            let availableSchemas = parseAllSchemas(schemasPath: schemasPath)
            
            guard !availableSchemas.isEmpty else {
                print("❌ No schemas found in path: \(schemasPath)")
                exit(1)
            }
            
            print("Available commands:")
            availableSchemas.forEach { schema in
                print("  \(schema.name) - \(schema.description)")
            }
            exit(0)
        }
        
        guard arguments.count > 3 else {
            print("""
            Usage: nuke -s <schemas_path> <command> [--help]
                   nuke -s <schemas_path>  (to list available commands)

            Arguments:
              -s <schemas_path> Path to schemas directory
              <command>         Command to execute

            Examples:
              nuke -s ~/path/schemas ddgapp
              nuke -s ~/path/schemas
            """)
            exit(1)
        }

        // Check for -s parameter as first argument
        guard arguments[1] == "-s" else {
            print("❌ Missing required -s parameter for schemas path")
            print("Usage: nuke -s <schemas_path> <command> [--help]")
            exit(1)
        }

        let schemasPath = arguments[2]
        let command = arguments[3]
        let extraArgs = Array(arguments.dropFirst(4))

        let availableSchemas = parseAllSchemas(schemasPath: schemasPath)

        guard !availableSchemas.isEmpty else {
            print("❌ No schemas found in path: \(schemasPath)")
            exit(1)
        }

        guard let schema = availableSchemas.first(where: { $0.name == command }) else {
            print("❓ Unknown command: \(command)")
            print("Available commands:")
            availableSchemas.forEach { schema in
                print("  \(schema.name) - \(schema.description)")
            }
            exit(1)
        }

        executeSchema(schema, arguments: extraArgs)
    }
}

NukeApp().run(arguments: CommandLine.arguments)
