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
- Auto-discover Base URL variants and compatible `/models` endpoints.
- Test Responses API and Chat Completions automatically.
- Connect native Responses providers directly.
- **Auto Bridge** Chat-Completions-only providers to Codex through a localhost Responses endpoint.
- Convert Codex functions, custom/freeform tools, tool search, namespaces, common reasoning output, and usage metadata across the bridge.
- Restore bridged routing after the app relaunches.
- Keep quick switching and bridge status in the macOS menu bar.
- Restore the original OpenAI Codex configuration with one click.
- Back up `~/.codex/config.toml` and `~/.codex/.env` before changes.
- Native SwiftUI interface with light/dark mode.
- English, Simplified Chinese, Traditional Chinese, Japanese, Korean, and Spanish UI.

## Requirements

- macOS 13 or later.
- Codex already installed and configured.
- An OpenAI-compatible provider exposing Responses API or Chat Completions.

## Install

Download the latest build from **Releases**, unzip it, and move **Codex Provider Switcher.app** to Applications.

The current GitHub release is ad-hoc signed. If macOS blocks first launch, try opening the app once, then go to **System Settings → Privacy & Security** and choose **Open Anyway**.

## Use

1. Add a provider with its Base URL, model ID, and API key. The provider name can be left blank and will be generated automatically.
2. Use **Discover Models** when the provider exposes a compatible `/models` endpoint.
3. Run **Test Connection**. Responses is probed first; Chat Completions is used as the fallback capability check.
4. Select **Switch**.
   - Native Responses: Codex connects directly.
   - Chat-Completions-only: **Auto Bridge** routes Codex through localhost automatically. Auto Bridge is on by default.
5. Relaunch Codex when prompted.
6. Use the menu bar item for quick provider switching or to reopen the main window.
7. Select **OpenAI → Use OpenAI** whenever you want to restore the original configuration.

A bridged provider requires Codex Provider Switcher to remain running. Closing the main window is safe; the menu bar item keeps the app alive. Quitting the app stops the bridge.

## Base URL and model discovery

Provider URL layouts are not standardized. The app preserves explicit vendor paths such as `/api/paas/v4`, tries known provider presets where appropriate, and only tries `/v1` when the user supplied a bare host/root URL. It never replaces an explicit vendor version path with a guessed `/v1`.

Model discovery uses compatible `GET /models` endpoints when available. Manual model entry remains available for providers that do not expose a model catalog.

## Auto Bridge

Current Codex speaks the OpenAI Responses API, while many compatible providers still expose only Chat Completions. Auto Bridge keeps Codex on a local Responses endpoint and translates requests to the provider's Chat endpoint.

```text
Codex
  ↓ Responses API
127.0.0.1:<local port>
  ↓ protocol conversion
Provider /chat/completions
```

The bridge is localhost-only. Its transformation layer handles normal messages, standard functions, Codex custom/freeform tools, tool search, namespaces, common reasoning text, and usage metadata. It also normalizes strict Chat gateways that reject multiple system messages or malformed tool schemas.

See [docs/BRIDGE.md](docs/BRIDGE.md) for architecture, supported conversions, and deliberate limits.

## Credential storage

The GitHub build is currently ad-hoc signed. Rebuilt ad-hoc apps can cause macOS Keychain to ask for access repeatedly, so provider API keys are stored locally at:

```text
~/.codex/provider-switcher/credentials.json
```

The file is owner-only (`0600`) and the state directory is owner-only (`0700`). Older Keychain entries are deliberately not read automatically; paste each provider key once after upgrading from a Keychain-based release.

For direct Responses providers, the active key may be written to `~/.codex/.env` so the Codex desktop app can read it. For bridged providers, Codex talks only to localhost and the upstream key remains inside Codex Provider Switcher.

## Storage and backups

Provider metadata and app state live under:

```text
~/.codex/provider-switcher/
```

Before configuration changes, backups are created in:

```text
~/.codex/provider-switcher/backups/
```

## Build with Xcode

The Xcode project is the primary build entry point:

```text
Codex Provider Switcher.xcodeproj
```

Open it in Xcode, select **My Mac**, and build/run the **Codex Provider Switcher** scheme.

For a universal `.app` and zip:

```bash
./scripts/build_app.command
```

The release version comes from `VERSION`. GitHub Actions runs Swift tests and a real Xcode build before release packaging.

## Tests

```bash
swift test
```

## Project structure

```text
Codex Provider Switcher.xcodeproj   Native macOS app project
Codex Provider Switcher/
  App/                              App lifecycle and state
  Core/                             Configuration and protocol transformation
  Services/                         Credentials, bridge, files, networking
  UI/                               SwiftUI and menu bar UI
  Localization/                     Localization helpers
Tests/                              Core unit tests
scripts/                            Local build/package scripts
.github/workflows/                  CI and release automation
```

## Compatibility research

The v0.3.7 bridge review studied the public, MIT-licensed CC Switch project and its mature Codex routing design. Codex Provider Switcher uses an independent native Swift implementation. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT © 2026 GL-Technologies. See [LICENSE](LICENSE).
