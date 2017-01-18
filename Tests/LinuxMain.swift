#if os(Linux)

import XCTest
@testable import FluentNeo4jTests

XCTMain([
    testCase(FluentNeo4jTests.allTests),
])

#endif