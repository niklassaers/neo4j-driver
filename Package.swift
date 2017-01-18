import PackageDescription

let package = Package(
    name: "FluentNeo4j",
    dependencies: [
        .Package(url: "https://github.com/niklassaers/neo4j-ios.git", majorVersion: 3),
        .Package(url: "https://github.com/vapor/fluent.git", majorVersion: 1),
    ]
)
