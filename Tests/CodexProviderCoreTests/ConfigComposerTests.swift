import XCTest
@testable import CodexProviderCore

final class ConfigComposerTests: XCTestCase {
    func testPreservesUnrelatedConfigAndReplacesModelKeys() {
        let base = """
        model = "old"
        model_provider = "old-provider"
        model_reasoning_effort = "low"

        [features]
        web_search = true
        """
        let profile = ProviderProfile(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Vendor A",
            model: "model-a",
            baseURL: "https://example.com/v1",
            authentication: .bearer,
            reasoningEffort: .high
        )

        let result = ConfigComposer.buildConfig(base: base, profile: profile)
        XCTAssertTrue(result.contains("model = \"model-a\""))
        XCTAssertTrue(result.contains("model_provider = \"codex_compat_active\""))
        XCTAssertTrue(result.contains("model_reasoning_effort = \"high\""))
        XCTAssertTrue(result.contains("[features]"))
        XCTAssertTrue(result.contains("web_search = true"))
        XCTAssertTrue(result.contains("env_key = \"CODEX_COMPAT_API_KEY\""))
        XCTAssertFalse(result.contains("model = \"old\""))
    }

    func testNoAuthenticationOmitsEnvKey() {
        let profile = ProviderProfile(name: "Local", model: "local", baseURL: "http://127.0.0.1:8000/v1", authentication: .none)
        let result = ConfigComposer.buildConfig(base: "", profile: profile)
        XCTAssertFalse(result.contains("env_key"))
    }

    func testEnvironmentReplacesManagedKey() {
        let base = "FOO=bar\nCODEX_COMPAT_API_KEY=old\n"
        let result = ConfigComposer.buildEnvironment(base: base, apiKey: "new-key")
        XCTAssertTrue(result.contains("FOO=bar"))
        XCTAssertTrue(result.contains("CODEX_COMPAT_API_KEY=\"new-key\""))
        XCTAssertFalse(result.contains("old"))
    }
}
