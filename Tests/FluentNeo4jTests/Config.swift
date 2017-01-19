import Foundation
import FluentNeo4j


struct Config {
    let username: String
    let password: String
    let hostname: String
    let port: UInt
    let transferProtocol: Neo4jDriver.TransferProtocol
    
    init(pathToFile: String) {
        
        let jsonConfig: [String:Any]
        
        do {
            let filePathURL = URL(fileURLWithPath: pathToFile)
            let jsonData = try Data(contentsOf: filePathURL)
            let JSON = try JSONSerialization.jsonObject(with: jsonData, options: [])
            jsonConfig = (JSON as? [String:Any]) ?? [:]
            
        } catch {
            print("Config loading failed from \(pathToFile)")
            jsonConfig = [:]
        }
        
            
        self.username = jsonConfig["username"] as? String ?? "neo4j"
        self.password = jsonConfig["password"] as? String ?? "neo4j"
        self.hostname = jsonConfig["hostname"] as? String ?? "localhost"
        self.port     = (jsonConfig["port"] as? String)?.uint ?? 7474
        self.transferProtocol = Neo4jDriver.TransferProtocol.init(rawValue: (jsonConfig["transferProtocol"] as? String) ?? "http") ?? .http
    }
}
