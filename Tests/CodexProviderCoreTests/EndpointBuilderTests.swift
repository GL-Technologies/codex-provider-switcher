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

    func testDeepSeekBaseDoesNotInventV1ForDirectEndpoint() {
        XCTAssertEqual(
            EndpointBuilder.chatCompletionsURL(from: "https://api.deepseek.com")?.absoluteString,
            "https://api.deepseek.com/chat/completions"
        )
    }

    func testRootHostCandidatesIncludeV1Fallback() {
        let candidates = EndpointBuilder.candidateBaseURLs(from: "https://aiapi.example.com")
            .map(\.absoluteString)
        XCTAssertEqual(candidates, ["https://aiapi.example.com", "https://aiapi.example.com/v1"])
    }

    func testExistingV4PathIsPreserved() {
        let candidates = EndpointBuilder.candidateBaseURLs(from: "https://open.bigmodel.cn/api/paas/v4", brand: .zhipu)
            .map(\.absoluteString)
        XCTAssertEqual(candidates.first, "https://open.bigmodel.cn/api/paas/v4")
        XCTAssertFalse(candidates.contains("https://open.bigmodel.cn/api/paas/v4/v1"))
    }

    func testModelsPathIsNormalized() {
        XCTAssertEqual(
            EndpointBuilder.modelsURL(from: "https://example.com/v1/models")?.absoluteString,
            "https://example.com/v1/models"
        )
    }

    func testRejectsInvalidURL() {
        XCTAssertNil(EndpointBuilder.responsesURL(from: "example.com/v1"))
    }
}
