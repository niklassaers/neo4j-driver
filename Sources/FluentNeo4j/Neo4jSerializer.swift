import Fluent
import Theo

/**
    Query to Neo4j Cypher expression
 */
public class Neo4jSerializer {
    
    public static func toCypher<T: Entity>(query: Query<T>) -> String {
        
        switch query.action {
        case .fetch:
            return fetchCypherQuery(query: query)
        case .count:
            return countCypherQuery(query: query)
        case .delete:
            return deleteCypherQuery(query: query)
        case .create:
            return createCypherQuery(query: query)
        case .modify:
            return modifyCypherQuery(query: query)

        }

    }
    
    private static func fetchCypherQuery<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }

    private static func countCypherQuery<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }

    private static func deleteCypherQuery<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }

    private static func createCypherQuery<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }

    private static func modifyCypherQuery<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }

    public static func toParameters<T: Entity>(query: Query<T>) -> Dictionary<String, AnyObject> {
        
        return Dictionary<String, AnyObject>()
    }
}
