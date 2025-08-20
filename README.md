# 🧹 Clean

A Swift command-line utility for cleaning up development environments by executing schema-based cleanup tasks. Clean allows you to define custom cleanup routines through JSON schemas that can terminate processes, delete files/folders, and run shell commands.

## Features

- **Schema-based cleanup** 📋: Define cleanup tasks using simple JSON configuration files
- **Process termination** 🔪: Find and kill processes by keyword matching
- **File/folder deletion** 🗑️: Remove specified directories and files with shell expansion support
- **Command execution** 🚀: Run arbitrary shell commands as part of cleanup routines
- **Multiple schemas** 📁: Support for multiple cleanup configurations in a single directory

## Installation

1. Clone this repository
2. Make sure you have Swift installed on your system
3. You're ready to run the script directly!

### Optional: Create Terminal Alias

For easier usage, you can create a terminal alias to avoid typing the full path each time:

```bash
# Add to your shell profile (~/.bashrc, ~/.zshrc, etc.)
alias clean='swift ~/Developer/clean/clean.swift -s ~/Developer/clean/schemas/'

# Reload your shell or run:
source ~/.zshrc  # or ~/.bashrc
```

After setting up the alias, you can use the shorter syntax:
```bash
# List available commands
clean -s ./schemas

# Execute a specific command
clean -s ./schemas ddgvpn
```

## Usage

```bash
swift clean.swift -s <schemas_path> <command> [--help]
swift clean.swift -s <schemas_path>  # List available commands
```

### Arguments

- `-s <schemas_path>`: Path to the directory containing schema JSON files
- `<command>`: Name of the schema/command to execute (optional - omit to list available commands)
- `--help`: Show help for a specific command

### Examples

```bash
# List all available commands with descriptions
swift clean.swift -s ./schemas

# Clean Xcode derived data and caches
swift clean.swift -s ./schemas xcode

# Clean DuckDuckGo app data
swift clean.swift -s ./schemas ddgapp

# Clean DuckDuckGo VPN data
swift clean.swift -s ./schemas ddgvpn

# Show help for a specific command
swift clean.swift -s ./schemas xcode --help
```

## Schema Format

Schemas are JSON files that define cleanup tasks. Each schema must have the following structure:

```json
{
  "name": "schema-name",
  "description": "Description of what this schema does",
  "paths": [
    "/path/to/delete",
    "~/another/path/with/expansion",
    "~/path/with/wildcards/*"
  ],
  "commands": [
    "command arg1 arg2",
    "another-command --flag"
  ],
  "processes": [
    "ProcessName",
    "partial-process-match"
  ]
}
```

### Schema Properties

- **name**: Unique identifier for the schema (used as command name)
- **description**: Human-readable description of the cleanup task
- **paths**: Array of file/folder paths to delete (supports `~` expansion and wildcards)
- **commands**: Array of shell commands to execute
- **processes**: Array of process keywords to find and terminate

## Example Schemas

### Xcode Cleanup (`xcode.json`)

```json
{
  "name": "xcode",
  "description": "Cleans Xcode derived data and Swift Package Manager build cache",
  "paths": [
    "~/Library/Developer/Xcode/DerivedData",
    "~/Library/Caches/org.swift.swiftpm"
  ],
  "commands": [],
  "processes": [
    "Xcode"
  ]
}
```

### DuckDuckGo App Cleanup (`ddgapp.json`)

```json
{
  "name": "ddgapp",
  "description": "Cleans up DuckDuckGo App data, including preferences, cache, or sandbox",
  "paths": [
    "/Applications/DEBUG",
    "~/.Trash/*"
  ],
  "commands": [],
  "processes": []
}
```

## Project Structure

```
clean/
├── clean.swift          # Main application source code
├── schemas/            # Directory containing cleanup schemas
│   ├── ddgapp.json    # DuckDuckGo app cleanup schema
│   ├── ddgvpn.json    # DuckDuckGo VPN cleanup schema
│   └── xcode.json     # Xcode cleanup schema
└── README.md          # This file
```

## Safety Features

- **Process protection**: Prevents the clean process from terminating itself
- **Error handling**: Graceful error handling for file operations and process execution
- **Confirmation**: Clear logging of all operations being performed

## How It Works

1. **Schema loading**: Clean loads all JSON schemas from the specified directory
2. **Command matching**: Finds the schema matching the requested command name
3. **Process termination**: Kills any processes matching the keywords in the `processes` array
4. **File deletion**: Removes all paths specified in the `paths` array using `rm -rf`
5. **Command execution**: Runs all shell commands specified in the `commands` array

## Contributing

1. Fork the repository
2. Create your feature branch
3. Add or modify schemas in the `schemas/` directory as needed
4. Test your changes
5. Submit a pull request

## License

See LICENSE file for details.