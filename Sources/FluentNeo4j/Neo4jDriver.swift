import Fluent
import Theo
import Dispatch

public class Neo4jDriver: Fluent.Driver {

    public var idKey: String = "id"

    let database: Client
    
    public enum TransferProtocol: String {
        case http = "http"
        case https = "https"
    }

    /**
        Creates a new Neo4jDriver pointing
        to the database at the supplied path.
    */
    public init(host: String = "localhost", port: UInt = 7474, transferProtocol: TransferProtocol = .http, username: String = "neo4j", password: String = "neo4j") throws {
        let baseUrlPath = "\(transferProtocol.rawValue)://\(host):\(port)"
        self.database = Client(baseURL: baseUrlPath, user: username, pass: password)
    }

    /**
        Describes the errors this
        driver can throw.
    */
    public enum Error: Swift.Error {
        case unsupported(String)
    }

    /**
        Executes the query.
    */
    @discardableResult
    public func query<T: Entity>(_ query: Query<T>) throws -> Fluent.Node {
        
        let queries = try Neo4jSerializer.toCypher(query: query, idKey: idKey)
        let params = Neo4jSerializer.toParameters(query: query)
        
        var lastResultNode = Fluent.Node.null
        let dispatchGroup = DispatchGroup()
        
        for cypher in queries {
            dispatchGroup.enter()
            
            database.executeCypher(cypher, params: params) { (result, error) in
                
                print("DEBUG: Running query Cypher: \n\(cypher)")
                if error != nil {
                    print("Neo4jDriver.query(...): Got error!")
                } else {
                    if let data = result?.data {
                        var nodeArray: [Fluent.Node] = []
                        for resultDict in data {
                            for (_, dictionary) in resultDict {
                                guard let dictionary = dictionary as? Dictionary<String, Any> else {
                                    print("Neo4jDriver.query(...): Could not convert result into proper node")
                                    continue
                                }
                                
                                let theoNode = Theo.Node(data: dictionary)
                                guard let idValue = theoNode.getProp(self.idKey) as? String else {
                                    print("Neo4jDriver.query(...): Could not get node id")
                                    continue
                                }
                                
                                var nodeProperties: [String:Fluent.Node] = [self.idKey: Fluent.Node.string(idValue)]
                                for property in theoNode.allProperties {
                                    let propertyNode: Fluent.Node
                                    let propertyValue = theoNode[property]
                                    if let propertyValue = propertyValue as? UInt {
                                        propertyNode = Fluent.Node.number(.uint(propertyValue))

                                    } else if let propertyValue = propertyValue as? Int {
                                        propertyNode = Fluent.Node.number(.int(propertyValue))
                                        
                                    } else if let propertyValue = propertyValue as? Double {
                                        propertyNode = Fluent.Node.number(.double(propertyValue))
                                        
                                    } else if let propertyValue = propertyValue as? String {
                                        propertyNode = Fluent.Node.string(propertyValue)
                                        
                                    } else if let propertyValue = propertyValue as? Bool {
                                        propertyNode = Fluent.Node.bool(propertyValue)
                                        
                                    } else {
                                        if let propertyValue = propertyValue {
                                            print("Neo4jDriver.query(...): Data type of \(property) (\(type(of:propertyValue))) is unsupported")
                                        } else {
                                            print("Neo4jDriver.query(...): Data type of \(property) is unsupported")
                                        }
                                        continue
                                    }
                                
                                    nodeProperties[property] = propertyNode
                                }

                                let objectNode = Fluent.Node.object(nodeProperties)
                                nodeArray.append(objectNode)
                            }
                        }
                        
                        lastResultNode = Fluent.Node.array(nodeArray)
                    } else {
                        print("Neo4jDriver.query(...): No error, but also no result!")
                    }
                }
                
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
        }
        
        return lastResultNode
    }

    // While no explicit schema, this is a great time to make some indexes
    public func schema(_ schema: Schema) throws {
        let queries = try Neo4jSerializer.toCypher(schema: schema, idKey: idKey)

        let dispatchGroup = DispatchGroup()
        for cypher in queries {
            dispatchGroup.enter()
            
            database.executeCypher(cypher, params: nil) { (result, error) in
                
                print("DEBUG: Running schema Cypher: \n\(cypher)")
                if error != nil {
                    if cypher.hasPrefix("DROP INDEX ON ") ||
                        cypher.hasPrefix("DROP CONSTRAINT ON ") {
                        // Silently ignore a DROP INDEX/CONSTRAINT ON too much
                    } else {
                        print("Neo4jDriver.schema(...): Got error!")
                    }
                }
                
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
        }
        
    }

    /**
        Executes a raw query with an
        optional array of paramterized
        values and returns the results.
    */
    public func raw(_ statement: String, _ values: [Fluent.Node] = []) throws -> Fluent.Node {
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        let params = Dictionary<String, AnyObject>()
        database.executeCypher(statement, params: params) { (result, error) in
            
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        // How is it this function can expect to return synchronously?
        
        return .null
    }
}
