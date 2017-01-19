import Fluent
import Theo
import Dispatch

public class Neo4jDriver: Fluent.Driver {

    public var idKey: String = "id_string"

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
        
        let dispatchGroup = DispatchGroup()
        
        for cypher in queries {
            dispatchGroup.enter()
            
            database.executeCypher(cypher, params: params) { (result, error) in
                
                print("Running query Cypher: \n\(cypher)")
                if error != nil {
                    print("Got error!")
                }
                
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
        }
        
        return .null
    }

    // While no explicit schema, this is a great time to make some indexes
    public func schema(_ schema: Schema) throws {
        let queries = try Neo4jSerializer.toCypher(schema: schema, idKey: idKey)

        let dispatchGroup = DispatchGroup()
        for cypher in queries {
            dispatchGroup.enter()
            
            database.executeCypher(cypher, params: nil) { (result, error) in
                
                print("Running schema Cypher: \n\(cypher)")
                if error != nil {
                    if cypher.hasPrefix("DROP INDEX ON ") ||
                        cypher.hasPrefix("DROP CONSTRAINT ON ") {
                        // Silently ignore a DROP INDEX/CONSTRAINT ON too much
                    } else {
                        print("Got error!")
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
