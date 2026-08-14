# Codex Provider Switcher

<p align="center">
  <img src="docs/app-icon.png" width="112" alt="Codex Provider Switcher icon">
</p>

<p align="center">
  <a href="README.zh-CN.md">简体中文</a>
</p>

A native macOS utility for switching Codex between OpenAI and multiple OpenAI-compatible model providers.

> This project is not affiliated with or endorsed by OpenAI or the provider brands shown in the app.

## Features

- Save and switch between multiple provider profiles.
- Auto-discover common Base URL variants and OpenAI-compatible `/models` endpoints.
- Test both Responses API and Chat Completions compatibility.
- Use Responses-compatible providers directly.
- Route Chat-Completions-only providers through a built-in localhost Responses bridge.
- Translate standard text conversations and function-tool loops between Responses and Chat Completions.
- Restore the original Codex configuration with one click.
- Back up `~/.codex/config.toml` and `~/.codex/.env` before changes.
- Native macOS UI with light/dark mode and provider identities.
- Localized for English, Simplified Chinese, Traditional Chinese, Japanese, Korean, and Spanish.

## Requirements

- macOS 13 or later.
- Codex already installed and configured.
- An OpenAI-compatible provider exposing either Responses API or Chat Completions.

## Install

Download the latest macOS build from **Releases**, unzip it, and move **Codex Provider Switcher.app** to Applications.

The current GitHub release is ad-hoc signed. If macOS blocks the first launch, try opening the app once, then go to **System Settings → Privacy & Security** and choose **Open Anyway** for Codex Provider Switcher.

## Use

1. Add a provider with its Base URL, model ID, and API key.
2. Optionally use **Discover Models** to load models from a compatible `/models` endpoint.
3. Run **Test Connection**. The app probes Responses first, then Chat Completions.
4. Select **Switch**.
   - Responses-compatible providers are configured directly in Codex.
   - Chat-Completions-only providers are exposed through the local Responses bridge automatically.
5. Relaunch Codex when prompted.
6. Select **OpenAI → Use OpenAI** to restore the original configuration.

When a provider is using the local bridge, keep Codex Provider Switcher running. Closing the main window is fine; quitting the app stops the localhost bridge.

## Base URL discovery

Provider paths are not standardized. The app keeps explicit vendor paths such as `/api/paas/v4`, tries known provider presets where available, and only tries `/v1` as a fallback when the user entered a bare host/root URL. It never replaces an explicit `/v4` or other vendor path with `/v1`.

## Local Responses bridge

Current Codex uses Responses-style requests. Many OpenAI-compatible vendors still expose only `/chat/completions`. For those providers, Codex Provider Switcher starts a localhost-only bridge and configures Codex to use it as a Responses endpoint.

The current bridge focuses on the coding-agent path that can be represented by both APIs:

- text messages;
- standard function tools;
- function calls and tool outputs;
- Responses-compatible SSE lifecycle events.

Hosted OpenAI-only tools, server-managed provider state, and provider-specific reasoning traces are not emulated. Compatibility still depends on the upstream model's function-calling behavior.

## Credential storage

The current GitHub build is ad-hoc signed. macOS Keychain access control tracks application identity through code signing, and rebuilding an ad-hoc app can cause repeated keychain approval prompts. Until releases use a stable Developer ID signature, provider API keys are stored in:

```text
~/.codex/provider-switcher/credentials.json
```

The file is created with owner-only permissions (`0600`), and the containing state directory uses owner-only access (`0700`). Existing keys from older Keychain-based builds are deliberately not read automatically; paste each provider key once after upgrading.

For direct Responses providers, the active key may still be written to `~/.codex/.env` because the Codex desktop app needs access to the provider credential. For bridged providers, the upstream key remains inside Codex Provider Switcher and Codex talks only to localhost.

## Storage and backups

Provider metadata is stored under:

```text
~/.codex/provider-switcher/
```

Before each configuration change, the app creates a backup in:

```text
~/.codex/provider-switcher/backups/
```

## Provider icons

The app includes compact visual identities for common providers including OpenAI, Anthropic, Google Gemini, DeepSeek, Mistral AI, Qwen, Groq, OpenRouter, Ollama, Perplexity, xAI, Azure OpenAI, Cohere, Moonshot/Kimi, Together AI, SiliconFlow, Zhipu AI, and Volcengine. These are UI identifiers and do not imply affiliation or endorsement.

## Build with Xcode

The Xcode project is the primary build entry point:

```text
Codex Provider Switcher.xcodeproj
```

Open it in Xcode, select **My Mac**, and build/run the **Codex Provider Switcher** scheme.

For a distributable universal `.app` and zip:

```bash
./scripts/build_app.command
```

The release version comes from the repository `VERSION` file. The script requires the full Xcode app. Output is written to `dist/` and logs to `.build-app/build.log`.

## Tests

```bash
swift test
```

GitHub Actions also builds the macOS app with Xcode before a change is merged/released.

## Project structure

```text
Codex Provider Switcher.xcodeproj   Native macOS app project
Codex Provider Switcher/
  App/                              App lifecycle and state
  Core/                             Configuration/domain logic
  Services/                         Credentials, bridge, files, network testing
  UI/                               SwiftUI views
  Localization/                     Localization helpers
  *.lproj/                          Localized strings
Tests/                              Core unit tests
scripts/                            Local build/package scripts
.github/workflows/                  CI and release automation
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for implementation details.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT © 2026 GL-Technologies. See [LICENSE](LICENSE).
