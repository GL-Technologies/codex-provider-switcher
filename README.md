# Codex Provider Switcher

<p align="center">
  <img src="docs/app-icon.png" width="112" alt="Codex Provider Switcher icon">
</p>

<p align="center">
  <strong>A native macOS provider switcher and compatibility bridge for Codex.</strong>
</p>

<p align="center">
  English · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a>
</p>

<p align="center">
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-orange?logo=swift">
  <img alt="License MIT" src="https://img.shields.io/badge/license-MIT-blue">
  <img alt="Release" src="https://img.shields.io/github/v/release/GL-Technologies/codex-provider-switcher">
</p>

Codex Provider Switcher is a native macOS utility for switching Codex between OpenAI and multiple OpenAI-compatible providers. It can connect native Responses API providers directly, and transparently bridge Chat-Completions-only providers through a local Responses-compatible endpoint.

> This project is not affiliated with or endorsed by OpenAI or any provider brand shown in the app.

## Highlights

- **One-click provider switching** between OpenAI and multiple saved providers.
- **Auto Bridge** for Chat-Completions-only APIs, enabled by default.
- **Automatic capability detection**: Responses API first, Chat Completions fallback.
- **Model discovery** through compatible `/models` endpoints with manual fallback.
- **Codex tool compatibility** across the bridge, including functions, custom/freeform tools, tool search, namespaces, common reasoning output, and usage metadata.
- **Persistent menu bar control** for quick switching, bridge status, Settings, and Quit.
- **Automatic bridge restoration** when the app relaunches and Codex still points to localhost.
- **Safe configuration handling** with backups before changing `~/.codex/config.toml` and `~/.codex/.env`.
- **Native SwiftUI experience** with light/dark mode and localized UI.
- UI languages: English, Simplified Chinese, Traditional Chinese, Japanese, Korean, and Spanish.

## How it works

```text
Native Responses provider
Codex ───────────────────────────────→ Provider /responses

Chat-Completions-only provider
Codex → localhost Responses bridge → Provider /chat/completions
```

The bridge is localhost-only and runs inside Codex Provider Switcher. Closing the main window is safe; the menu bar item keeps the app alive. Quitting the app stops the bridge.

## Requirements

- macOS 13 or later.
- Codex already installed and configured.
- An OpenAI-compatible provider exposing Responses API or Chat Completions.

## Install

Download the latest build from **Releases**, unzip it, and move **Codex Provider Switcher.app** to Applications.

The current GitHub release is ad-hoc signed. If macOS blocks the first launch, try opening the app once, then go to **System Settings → Privacy & Security** and choose **Open Anyway**.

## Quick start

1. Click **Add Provider** and enter the Base URL, model ID, and API key. The provider name can be left blank and will be generated automatically.
2. Click **Find Models** when the provider exposes a compatible `/models` endpoint.
3. Click **Test Connection**. The app probes Responses first and Chat Completions second.
4. Click **Use**.
   - Native Responses providers connect directly.
   - Chat-Completions-only providers use **Auto Bridge** automatically when enabled.
5. Relaunch Codex when prompted.
6. Use the menu bar item to switch providers without reopening the main window.
7. Choose **OpenAI → Use OpenAI** whenever you want to restore the original configuration.

## Auto Bridge

Current Codex speaks the OpenAI Responses API, while many compatible providers still expose only Chat Completions. Auto Bridge keeps Codex on a local Responses endpoint and translates requests to the provider's Chat endpoint.

```text
Codex
  ↓ Responses API
127.0.0.1:<local port>
  ↓ protocol conversion
Provider /chat/completions
```

The transformation layer handles normal messages, standard functions, Codex custom/freeform tools, tool search, namespaces, common reasoning text, usage metadata, and strict Chat gateway normalization.

See [docs/BRIDGE.md](docs/BRIDGE.md) for architecture, supported conversions, and deliberate limits.

## Base URL and model discovery

Provider URL layouts are not standardized. The app preserves explicit vendor paths such as `/api/paas/v4`, tries known provider presets where appropriate, and only tries `/v1` when the user supplied a bare host/root URL. It never replaces an explicit vendor version path with a guessed `/v1`.

Model discovery uses compatible `GET /models` endpoints when available. Manual model entry remains available for providers that do not expose a model catalog.

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

The bridge review studied the public, MIT-licensed CC Switch project and its mature Codex routing design. Codex Provider Switcher uses an independent native Swift implementation. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT © 2026 GL-Technologies. See [LICENSE](LICENSE).
