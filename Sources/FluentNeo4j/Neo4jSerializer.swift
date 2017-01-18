import Fluent
import Theo

/**
    Query to Neo4j Cypher expression
 */
public class Neo4jSerializer {
    
    public static func toCypher<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }
    
    public static func toParameters<T: Entity>(query: Query<T>) -> Dictionary<String, AnyObject> {
        
        return Dictionary<String, AnyObject>()
    }
}
