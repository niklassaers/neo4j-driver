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
    
    public static func toCypher<T: Entity>(query: Query<T>, idKey: String) throws -> [String] {
        
        switch query.action {
        case .fetch:
            return try fetchCypherQuery(query: query, idKey: idKey)
        case .count:
            return countCypherQuery(query: query)
        case .delete:
            return deleteCypherQuery(query: query)
        case .create:
            return try createCypherQuery(query: query)
        case .modify:
            return try modifyCypherQuery(query: query, idKey: idKey)

        }

    }
    
    public static func toCypher(schema: Schema, idKey: String) throws -> [String] {
        
        
        switch schema {
        case let .create(entity, create):
            let label = entity.pluralNameAsCapitalizedSingular()
            var cypher = ["CREATE INDEX ON :\(label)(\(idKey))"]
            cypher.append("CREATE CONSTRAINT ON (n:\(label)) ASSERT n.\(idKey) IS UNIQUE")

            for field in create {
                if field.unique == true {
                    cypher.append("CREATE CONSTRAINT ON (n:\(label)) ASSERT n.\(field.name) IS UNIQUE")
                }
            }
            
            return cypher
            
        case let .modify(entity, create, delete):
            let label = entity.pluralNameAsCapitalizedSingular()
            var cypher = [String]()

            for name in delete {
                cypher += "DROP CONSTRAINT ON (n:\(label)) ASSERT n.\(name) IS UNIQUE;\n"
            }

            for field in create {
                if field.unique == true {
                    cypher.append("CREATE CONSTRAINT ON (n:\(label)) ASSERT n.\(field.name) IS UNIQUE")
                }
            }
            
            return cypher
            
        case let .delete(entity):
            let label = entity.pluralNameAsCapitalizedSingular()
            var cypher = ["MATCH (n:\(label)) DETACH DELETE n"]
            cypher.append("DROP INDEX ON :\(label)(\(idKey))")

            return cypher
        }
    }
    
    private static func fetchCypherQuery<T: Entity>(query: Query<T>, idKey: String) throws -> [String] {
        
        var cypher = "MATCH (n:\(query.singularEntity)) "
        cypher += try whereClauseFrom(query: query, idKey: idKey)
        cypher += " RETURN n"

        return [cypher]
    }
    
    private static func whereClauseFrom<T: Entity>(query: Query<T>, idKey: String) throws -> String {
        
        if query.filters.count == 0 {
            return ""
        }
        
        var cypher = "WHERE"
        
        var first = true
        for filter in query.filters {
            if first == false {
                cypher += " AND "
            } else {
                first = false
                cypher += " "
            }
            
            let condition = try Neo4jSerializer.condition(filter: filter, idKey: idKey)
            cypher += condition
            
        }

        return cypher
    }
    
    private static func condition(filter: Filter, idKey: String) throws -> String {
        var condition: String
        switch filter.method {
        case let .compare(propertyName, comparison, node):
            if propertyName == "id_string" {
                print("Breakpoint")
            }
            
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
            
            if propertyName == idKey {
                let value = node.string ?? "N/A"
                condition += "\"\(value)\""
                return condition
            }
            
            switch node {
            case .null:
                throw Error.notImplemented
            case let .bool(value):
                condition += "\(value)"
            case let .number(value):
                if Double(value.int) == value.double {
                    condition += "\(value.int)"
                } else {
                    condition += "\(value.double)"
                }
            case let .string(value):
                condition += "\"\(value)\""
            case let .array(array):
                throw Error.notImplemented
            case let .object(object):
                throw Error.notImplemented
            case let .bytes(bytes):
                throw Error.notImplemented
            }
        
            
        case let .subset(string, scope, nodeArray):
            throw Error.notImplemented
            
        case let .group(relation, filterArray):
            throw Error.notImplemented

        }
        
        return condition
    }

    private static func createCypherQuery<T: Entity>(query: Query<T>) throws -> [String] {
        
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
        
        return [cypher]
    }

    private static func deleteCypherQuery<T: Entity>(query: Query<T>) -> [String] {
        
        return []
    }

    private static func countCypherQuery<T: Entity>(query: Query<T>) -> [String] {
        
        return []
    }

    private static func modifyCypherQuery<T: Entity>(query: Query<T>, idKey: String) throws -> [String] {
        
        let idValue = "123"
        var cypher = "MATCH (n:\(query.singularEntity) { \(idKey): '\(idValue)' }) WHERE "

        // update data
        
        cypher += try whereClauseFrom(query: query, idKey: idKey)
        
        return [cypher]
    }

    public static func toParameters<T: Entity>(query: Query<T>) -> Dictionary<String, AnyObject> {
        
        return Dictionary<String, AnyObject>()
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let rest = String(characters.dropFirst())
        return first + rest
    }
    
    func pluralNameAsCapitalizedSingular() -> String {
        
        guard let lastChar = characters.last,
            lastChar == Character("s") else {
                return self
        }
        
        let toIndex = index(startIndex, offsetBy: characters.count - 1)
        let singularEntity = substring(to: toIndex)
        
        return singularEntity.capitalizingFirstLetter()
        
    }
}

public extension Query {
    public var singularEntity: String {
        get {
            let pluralEntity = self.entity
            return pluralEntity.pluralNameAsCapitalizedSingular()
        }
    }
}
