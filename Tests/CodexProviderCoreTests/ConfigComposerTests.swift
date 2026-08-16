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

    func testOpenAIRestoreRemovesThirdPartyProviderSelectionFromBaseline() {
        let baseline = """
        model = "deepseek-model"
        model_provider = "deepseek"
        model_reasoning_effort = "high"

        [features]
        web_search = true

        [model_providers.deepseek]
        name = "DeepSeek"
        base_url = "https://api.example.com"
        wire_api = "responses"
        """

        let result = ConfigComposer.buildOpenAIConfig(base: baseline)
        XCTAssertFalse(result.contains("model_provider = \"deepseek\""))
        XCTAssertFalse(result.contains("model = \"deepseek-model\""))
        XCTAssertFalse(result.contains("model_reasoning_effort = \"high\""))
        XCTAssertTrue(result.contains("[features]"))
        XCTAssertTrue(result.contains("web_search = true"))
        XCTAssertTrue(ConfigComposer.isOpenAIConfig(result))
    }

    func testOpenAIRestorePreservesOfficialModelChoiceWithoutCustomProvider() {
        let baseline = """
        model = "gpt-5.3-codex"
        model_reasoning_effort = "high"

        [features]
        web_search = true
        """

        let result = ConfigComposer.buildOpenAIConfig(base: baseline)
        XCTAssertTrue(result.contains("model = \"gpt-5.3-codex\""))
        XCTAssertTrue(result.contains("model_reasoning_effort = \"high\""))
        XCTAssertTrue(ConfigComposer.isOpenAIConfig(result))
    }

    func testOpenAIRestoreRemovesSwitcherProviderBlockAndManagedMarkers() {
        let managed = """
        # Managed by Codex Provider Switcher
        # Active profile: 11111111-1111-1111-1111-111111111111
        model = "vendor-model"
        model_provider = "codex_compat_active"

        [features]
        web_search = true

        [model_providers.codex_compat_active]
        name = "Vendor"
        base_url = "http://127.0.0.1:24864/v1"
        wire_api = "responses"
        """

        let result = ConfigComposer.buildOpenAIConfig(base: managed)
        XCTAssertFalse(result.contains(ConfigComposer.managedMarker))
        XCTAssertFalse(result.contains(ConfigComposer.activeMarkerPrefix))
        XCTAssertFalse(result.contains("codex_compat_active"))
        XCTAssertTrue(result.contains("[features]"))
        XCTAssertTrue(ConfigComposer.isOpenAIConfig(result))
    }

    func testOpenAIRestorePreservesUnrelatedCurrentPreferences() {
        let managed = """
        # Managed by Codex Provider Switcher
        # Active profile: 11111111-1111-1111-1111-111111111111
        model = "vendor-model"
        model_provider = "codex_compat_active"
        model_reasoning_effort = "high"

        [features]
        web_search = true

        [ui]
        language = "zh-CN"
        compact_mode = false

        [model_providers.codex_compat_active]
        name = "Vendor"
        base_url = "http://127.0.0.1:24864/v1"
        wire_api = "responses"
        """

        let result = ConfigComposer.buildOpenAIConfig(base: managed)
        XCTAssertTrue(result.contains("[ui]"))
        XCTAssertTrue(result.contains("language = \"zh-CN\""))
        XCTAssertTrue(result.contains("compact_mode = false"))
        XCTAssertFalse(result.contains("model_provider = \"codex_compat_active\""))
        XCTAssertTrue(ConfigComposer.isOpenAIConfig(result))
    }
}
