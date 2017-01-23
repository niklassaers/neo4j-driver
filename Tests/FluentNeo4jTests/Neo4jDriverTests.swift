
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
        
        Post.database = database

        Atom.database = database
        Compound.database = database
        Pivot<Atom, Compound>.database = database

    }
    
    func testEntityRevertAndPrepare() throws {
        
        do {
            try Post.revert(database)
            try Post.prepare(database)

            try Atom.revert(database)
            try Atom.prepare(database)

            try Compound.revert(database)
            try Compound.prepare(database)
            
            try Pivot<Atom, Compound>.revert(database)
            try Pivot<Atom, Compound>.prepare(database)
        } catch {
            XCTFail("Could not create table \(error)")
        }
    }
 

    func testSaveAndFind() {
        
        let postIdValue = UUID().uuidString
        let postTitle = "Vapor & Tests"
        let postText = "Lorem ipsum etc..."
        
        var post = Post(id: Node.string(postIdValue), title: postTitle, text: postText)
        
        do {
            try post.save()
        } catch {
            XCTFail("Could not save : \(error)")
        }
        
        do {
            let fetched = try Post.find(postIdValue)
            XCTAssertEqual(fetched?.title, postTitle)
            XCTAssertEqual(fetched?.text, postText)
        } catch {
            XCTFail("Could not fetch post : \(error)")
        }
    }
    
    func testDontFindNonexistantNode() {
    
        do {
            let post  = try Post.find(UUID().uuidString)
            XCTAssertNil(post)
        } catch {
            XCTFail("Unexpectantly found post: \(error)")
        }
    }
    
    func testSaveAndUpdate() {
        
        let postIdValue = UUID().uuidString
        let postTitle = "Vapor & Tests"
        let postText = "Lorem ipsum etc..."
        let updatedPostText = "Updated text"
        
        var post = Post(id: Node.string(postIdValue), title: postTitle, text: postText)
        
        do {
            try post.save()
        } catch {
            XCTFail("Could not save : \(error)")
        }
        
        var fetched: Post? = nil
        do {
            fetched = try Post.find(postIdValue)
            XCTAssertEqual(fetched?.title, postTitle)
            XCTAssertEqual(fetched?.text, postText)
        } catch {
            XCTFail("Could not fetch post : \(error)")
        }

        do {
            XCTAssertNotNil(fetched, "Node should be defined at this point")
            fetched?.text = updatedPostText
            try fetched?.save()
        } catch {
            XCTFail("Could not save post: \(error)")
        }
        
        do {
            fetched = try Post.find(postIdValue)
            XCTAssertEqual(fetched?.title, postTitle)
            XCTAssertEqual(fetched?.text, updatedPostText)
        } catch {
            XCTFail("Could not find updated post: \(error)")
        }
        
        
    }
    
    /**
        This test ensures that a string containing a large number will
        remain encoded as a string and not get coerced to a number internally.
      */
    func testLargeNumericInput() {
        let longNumericName = String(repeating: "1", count: 1000)
        let id = UUID().uuidString
        do {
            var post = Post(id: Fluent.Node.string(id),
                            title: "Testing long number...",
                            text: longNumericName)
            try post.save()
        } catch {
            XCTFail("Could not create post: \(error)")
        }
        
        do {
            let post = try Post.find(id)
            XCTAssertNotNil(post)
            XCTAssertEqual(post?.text, longNumericName)
        } catch {
            XCTFail("Could not find post: \(error)")
        }
        
    }
    
    func testJoins() throws {
        
        var hydrogen = Atom(name: "Hydrogen", protons: 1)
        try hydrogen.save()

        var oxygen = Atom(name: "Oxygen", protons: 8)
        try oxygen.save()
        
        var water = Compound(name: "Water")
        try water.save()
        var hydrogenWater = Pivot<Atom, Compound>(hydrogen, water)
        try hydrogenWater.save()
        var oxygenWater = Pivot<Atom, Compound>(oxygen, water)
        try oxygenWater.save()
        
        var sugar = Compound(name: "Sugar")
        try sugar.save()
        var hydrogenSugar = Pivot<Atom, Compound>(hydrogen, sugar)
        try hydrogenSugar.save()
        
        
        let compounds = try hydrogen.compounds().all()
        XCTAssertEqual(compounds.count, 2)
    }

    
}
