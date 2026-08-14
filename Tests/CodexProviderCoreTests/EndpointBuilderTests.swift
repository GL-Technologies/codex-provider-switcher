import XCTest
@testable import CodexProviderCore

final class EndpointBuilderTests: XCTestCase {
    func testAddsResponsesPath() {
        XCTAssertEqual(EndpointBuilder.responsesURL(from: "https://example.com/v1")?.absoluteString, "https://example.com/v1/responses")
    }

    func testDoesNotDuplicateResponsesPath() {
        XCTAssertEqual(EndpointBuilder.responsesURL(from: "https://example.com/v1/responses")?.absoluteString, "https://example.com/v1/responses")
    }

    func testRejectsInvalidURL() {
        XCTAssertNil(EndpointBuilder.responsesURL(from: "example.com/v1"))
    }
}
