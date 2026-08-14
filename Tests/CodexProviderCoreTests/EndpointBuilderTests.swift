import XCTest
@testable import CodexProviderCore

final class EndpointBuilderTests: XCTestCase {
    func testAddsResponsesPath() {
        XCTAssertEqual(EndpointBuilder.responsesURL(from: "https://example.com/v1")?.absoluteString, "https://example.com/v1/responses")
    }

    func testDoesNotDuplicateResponsesPath() {
        XCTAssertEqual(EndpointBuilder.responsesURL(from: "https://example.com/v1/responses")?.absoluteString, "https://example.com/v1/responses")
    }

    func testStripsFullChatEndpointBeforeBuildingResponses() {
        XCTAssertEqual(
            EndpointBuilder.responsesURL(from: "https://open.bigmodel.cn/api/paas/v4/chat/completions")?.absoluteString,
            "https://open.bigmodel.cn/api/paas/v4/responses"
        )
    }

    func testBuildsChatEndpointForVersionedProviderBase() {
        XCTAssertEqual(
            EndpointBuilder.chatCompletionsURL(from: "https://open.bigmodel.cn/api/paas/v4")?.absoluteString,
            "https://open.bigmodel.cn/api/paas/v4/chat/completions"
        )
    }

    func testDeepSeekBaseDoesNotInventV1() {
        XCTAssertEqual(
            EndpointBuilder.chatCompletionsURL(from: "https://api.deepseek.com")?.absoluteString,
            "https://api.deepseek.com/chat/completions"
        )
    }

    func testRejectsInvalidURL() {
        XCTAssertNil(EndpointBuilder.responsesURL(from: "example.com/v1"))
    }
}
