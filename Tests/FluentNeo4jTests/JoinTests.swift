import XCTest
@testable import FluentNeo4j
import Fluent

class JoinTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic)
    ]

    func testBasic() {
    }
    
    /*
    var database: Fluent.Database!
    var driver: Neo4jDriver!

    override func setUp() {
        driver = Neo4jDriver.makeTestConnection()
        database = Database(driver)
    }

    func testBasic() throws {
        try Atom.revert(database)
        try Compound.revert(database)
        try Pivot<Atom, Compound>.revert(database)

        try Atom.prepare(database)
        try Compound.prepare(database)
        try Pivot<Atom, Compound>.prepare(database)

        Atom.database = database
        Compound.database = database
        Pivot<Atom, Compound>.database = database

        var hydrogen = Atom(name: "Hydrogen", protons: 1)
        try hydrogen.save()

        var water = Compound(name: "Water")
        try water.save()
        var hydrogenWater = Pivot<Atom, Compound>(hydrogen, water)
        try hydrogenWater.save()

        var sugar = Compound(name: "Sugar")
        try sugar.save()
        var hydrogenSugar = Pivot<Atom, Compound>(hydrogen, sugar)
        try hydrogenSugar.save()


        let compounds = try hydrogen.compounds().all()
        XCTAssertEqual(compounds.count, 2)
        XCTAssertEqual(compounds.first?.name.string, water.name.string)
        XCTAssertEqual(compounds.last?.id?.int, sugar.id?.int)
    }
     */
}
