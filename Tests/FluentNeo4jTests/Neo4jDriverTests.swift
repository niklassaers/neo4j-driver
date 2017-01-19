
import XCTest
@testable import FluentNeo4j
@testable import Fluent


class Neo4jDriverTests: XCTestCase {
    static var allTests: [(String, (Neo4jDriverTests) -> () throws -> Void)] {
        return [
           ("testSaveAndFind", testSaveAndFind)
        ]
    }
    
    var driver:Neo4jDriver!
    var database:Fluent.Database!

    class func loadConfig() -> Config {
        
        let testPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().path
        
        let filePath = "\(testPath)/FluentNeo4j.json"
        
        return Config(pathToFile: filePath)
    }

    override func setUp() {
        
        super.setUp()
        
        continueAfterFailure = false
        
        do {
            let config = Neo4jDriverTests.loadConfig()
            driver = try Neo4jDriver(
                host: config.hostname,
                port: config.port,
                transferProtocol: config.transferProtocol,
                username: config.username,
                password: config.password)
        } catch {
            XCTFail("Could not set up database \(error)")
        }
        
        database = Database(driver)
        Atom.database = database
        Post.database = database
    }
    
    func testEntityRevertAndPrepare() throws {
        
        do {
            try Post.revert(database)
            try Post.prepare(database)

            try Atom.revert(database)
            try Atom.prepare(database)
        } catch {
            XCTFail("Could not create table \(error)")
        }
    }
 

    func testSaveAndFind() {
        
        let idValue = UUID().uuidString
        var post = Post(id: Node.string(idValue), title: "Vapor & Tests", text: "Lorem ipsum etc...")
        
        do {
            try post.save()
        } catch {
            XCTFail("Could not save : \(error)")
        }
        
        do {
            var fetched = try Post.find(idValue)
            XCTAssertEqual(fetched?.title, post.title)
            XCTAssertEqual(fetched?.text, post.text)
            
            fetched?.text = "Updated text"
            try fetched?.save()
        } catch {
            XCTFail("Could not fetch user : \(error)")
        }
        
        do {
            let post  = try Post.find(2)
            XCTAssertNil(post)
        } catch {
            XCTFail("Could not find post: \(error)")
        }
        
        
    }
    
    /**
        This test ensures that a string containing a large number will
        remain encoded as a string and not get coerced to a number internally.
      */
    func testLargeNumericInput() {
        let longNumericName = String(repeating: "1", count: 1000)
        do {
            var post = Post(id: nil,
                            title: "Testing long number...",
                            text: longNumericName)
            try post.save()
        } catch {
            XCTFail("Could not create post: \(error)")
        }
        
        do {
            let post = try Post.find(1)
            XCTAssertNotNil(post)
            XCTAssertEqual(post?.title, longNumericName)
        } catch {
            XCTFail("Could not find post: \(error)")
        }
        
    }
    
}
