import Foundation
import Fluent
import Theo

/**
    Query to Neo4j Cypher expression
 */
public class Neo4jSerializer {
    
    public enum Error: Swift.Error {
        case notImplemented
    }
    
    public static func toCypher<T: Entity>(query: Query<T>) throws -> String {
        
        switch query.action {
        case .fetch:
            return try fetchCypherQuery(query: query)
        case .count:
            return countCypherQuery(query: query)
        case .delete:
            return deleteCypherQuery(query: query)
        case .create:
            return try createCypherQuery(query: query)
        case .modify:
            return modifyCypherQuery(query: query)

        }

    }
    
    private static func fetchCypherQuery<T: Entity>(query: Query<T>) throws -> String {
        
        var cypher = "MATCH (n:\(query.singularEntity)) WHERE "
        var first = true
        for filter in query.filters {
            if first == false {
                cypher += "AND "
            }

            let condition = try Neo4jSerializer.condition(filter: filter)
            cypher += condition + " "

            first = false
        }
        
        cypher += "RETURN n"
        return cypher
    }
    
    private static func condition(filter: Filter) throws -> String {
        var condition: String
        switch filter.method {
        case let .compare(propertyName, comparison, node):
            condition = "n.\(propertyName)"
            switch comparison {
            case .equals:
                condition += " = "
            case .greaterThan:
                condition += " > "
            case .lessThan:
                condition += " < "
            case .greaterThanOrEquals:
                condition += " >= "
            case .lessThanOrEquals:
                condition += " <= "
            case .notEquals:
                condition += " != "
            case .hasSuffix:
                throw Error.notImplemented
            case .hasPrefix:
                throw Error.notImplemented
            case .contains:
                throw Error.notImplemented
            }
            
            if let i = node.int, let d = node.double, Double(i) == d, node.bool == nil {
                condition += "\(i)"
            } else  if let n = node.double, node.bool == nil {
                condition += "\(n)"
            } else if let b = node.bool {
                condition += "\(b)"
            } else if let s = node.string {
                condition += "\"\(s)\""
            }
            
        case let .subset(string, scope, nodeArray):
            throw Error.notImplemented
            
        case let .group(relation, filterArray):
            throw Error.notImplemented

        }
        
        return condition
    }

    private static func createCypherQuery<T: Entity>(query: Query<T>) throws -> String {
        
        var cypher = "CREATE (n:\(query.singularEntity) { "

        if let pairs = query.data?.object {
            
            var first = true
            for (key, node) in pairs {
                if key == "id" {
                    continue
                }
                
                let firstPart = "\(key): "
                let lastPart: String
                
                if let i = node.int, let d = node.double, Double(i) == d, node.bool == nil {
                    lastPart = "\(i)"
                } else  if let n = node.double, node.bool == nil {
                    lastPart = "\(n)"
                } else if let b = node.bool {
                    lastPart = "\(b)"
                } else if let s = node.string {
                    lastPart = "'\(s)'" // TODO: Escape 's'
                } else {
                    throw Error.notImplemented
                }
                
                if first == false {
                    cypher += ", \(firstPart)\(lastPart)"
                } else {
                    first = false
                    cypher += "\(firstPart)\(lastPart)"
                }
            }
        }
        cypher += "})"
        
        return cypher
    }

    private static func deleteCypherQuery<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }

    private static func countCypherQuery<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }

    private static func modifyCypherQuery<T: Entity>(query: Query<T>) -> String {
        
        return ""
    }

    public static func toParameters<T: Entity>(query: Query<T>) -> Dictionary<String, AnyObject> {
        
        return Dictionary<String, AnyObject>()
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
}

public extension Query {
    public var singularEntity: String {
        get {
            let pluralEntity = self.entity
            let index = pluralEntity.index(pluralEntity.startIndex, offsetBy: pluralEntity.characters.count - 1)
            let singularEntity = pluralEntity.substring(to: index)
            
            return singularEntity.capitalizingFirstLetter()
            
            let first = String(singularEntity.characters.prefix(1)).capitalized
            let rest = String(singularEntity.characters.dropFirst())
            return first + rest
        }
    }
}
