import Foundation

struct Schema: Codable {
    let name: String
    let description: String
    let paths: [String]
    let commands: [String]
    let processes: [String]
}