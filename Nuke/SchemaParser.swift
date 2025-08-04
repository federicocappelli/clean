import Foundation

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
                print("Failed to parse schema from \(file.lastPathComponent): \(error)")
            }
        }
        
        return schemas
    }
}