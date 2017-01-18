import XCTest
import Fluent
@testable import FluentNeo4j

class SerializerTests: XCTestCase {
    
    var driver:Neo4jDriver!
    var database:Fluent.Database!
    
    
    override func setUp() {
        do {
            driver = try Neo4jDriver(host: "localhost", port: 7474, transferProtocol: .http, username: "neo4j", password: "stack0verFlow")
        } catch {
            XCTFail("Could not set up database \(error)")
        }
        
        database = Database(driver)
        Atom.database = database
        do {
            try Post.revert(database)
            try Post.prepare(database)
            Post.database = database
        } catch {
            XCTFail("Could not create table \(error)")
        }
    }
    
    // public static func toCypher<T: Entity>(query: Query<T>) -> String {
    // public static func toParameters<T: Entity>(query: Query<T>) -> Dictionary<String, AnyObject> {
    
    func testCreate() throws {
        var oxygen = Atom(name: "Oxygen", protons: 8)
        try oxygen.save()
    }
    
    
    func testSelect() throws {

        let query = try Atom.query().filter("protons", .greaterThanOrEquals, 2)
        query.limit = Limit(count: 15)
        
        let cypher = try Neo4jSerializer.toCypher(query: query)
        print(cypher)
    }
    
    
}
