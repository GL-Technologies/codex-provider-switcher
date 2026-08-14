# Codex Provider Switcher

<p align="center">
  <img src="docs/app-icon.png" width="112" alt="Codex Provider Switcher icon">
</p>

A native macOS utility for switching Codex between your original OpenAI configuration and multiple OpenAI **Responses API-compatible** providers.

> This project is not affiliated with or endorsed by OpenAI.

## Features

- Save and switch between multiple provider profiles.
- Restore the original Codex configuration with one click.
- Keep API keys in macOS Keychain.
- Test a provider with a real `POST /responses` request before activating it.
- Back up `~/.codex/config.toml` and `~/.codex/.env` before changes.
- Works with the Codex desktop app and CLI because both use the same user-level Codex configuration.
- Localized for English, Simplified Chinese, Traditional Chinese, Japanese, Korean, and Spanish.

## Requirements

- macOS 13 or later.
- Codex already installed and configured.
- A provider that supports the OpenAI Responses API. Compatibility with only `/chat/completions` is not enough.

## Install

Download the latest macOS build from **Releases**, unzip it, and move **Codex Provider Switcher.app** to Applications.

The release build is ad-hoc signed. On first launch, macOS may require **Control-click → Open**. A future release can use Developer ID signing and notarization when signing credentials are available.

## Use

1. Open the app.
2. Add a provider with a name, Base URL, model ID, and optional API key.
3. Use **Test** to verify the Responses API endpoint.
4. Select **Use Provider** to activate it.
5. Relaunch Codex when prompted.
6. Select **OpenAI → Use OpenAI** to restore the original configuration.

The app does not delete your OpenAI sign-in credentials. Provider switching can change which conversation history is visible in Codex.

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

The script requires the full Xcode app, not only Command Line Tools. Output is written to `dist/` and logs to `.build-app/build.log`.

## Tests

The configuration and endpoint logic are kept in a small platform-neutral core that can be tested with Swift Package Manager:

```bash
swift test
```

## Storage and safety

Provider metadata is stored under:

```text
~/.codex/provider-switcher/
```

API keys are stored in macOS Keychain. While a provider is active, its key is written to `~/.codex/.env` so the Codex desktop app can load it. Restoring OpenAI also restores the original `.env` snapshot.

Before each configuration change, the app creates a backup in:

```text
~/.codex/provider-switcher/backups/
```

## Project structure

```text
Codex Provider Switcher.xcodeproj   Native macOS app project
Codex Provider Switcher/
  App/                              App lifecycle and state
  Core/                             Pure configuration/domain logic
  Services/                         Keychain, files, network testing
  UI/                               SwiftUI views
  Localization/                     Localization helper
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
