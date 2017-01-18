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
 

    func testSaveAndFind() {
//        try! database.create("posts") { creator in
//            creator.id()
//            creator.string("title")
//            creator.string("text")
//        }
        
        var post = Post(id: nil, title: "Vapor & Tests", text: "Lorem ipsum etc...")
        
        do {
            try post.save()
            print("Just saved")
        } catch {
            XCTFail("Could not save : \(error)")
        }
        
        do {
            let fetched = try Post.find(1)
            XCTAssertEqual(fetched?.title, post.title)
            XCTAssertEqual(fetched?.text, post.text)
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
                            title: longNumericName,
                            text: "Testing long number...")
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
