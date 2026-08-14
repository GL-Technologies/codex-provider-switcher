# Architecture

## Overview

The repository uses a conventional native macOS Xcode project for the application and a small Swift Package target for platform-neutral core tests.

- `Codex Provider Switcher.xcodeproj`: primary app build entry point.
- `Codex Provider Switcher/Core`: domain models plus TOML/endpoint composition.
- `Codex Provider Switcher/Services`: filesystem, Keychain, preferences, and network test services.
- `Codex Provider Switcher/UI`: SwiftUI views.
- `Codex Provider Switcher/App`: app lifecycle and observable application state.
- `Tests/CodexProviderCoreTests`: tests for the core configuration logic.

The app target compiles the `Core` sources directly. `Package.swift` points at the same directory to avoid maintaining a second copy just for tests.

## Local data

- Profiles and state: `~/.codex/provider-switcher/`
- Backups: `~/.codex/provider-switcher/backups/`
- API keys: macOS Keychain
- Active Codex configuration: `~/.codex/config.toml`
- Active provider environment key: `~/.codex/.env`

The app can migrate data from earlier `~/.codex/interface-manager/` and `~/.codex/interface-switcher/` layouts without deleting the legacy copy.

## Switching contract

The first switch away from the user's normal Codex setup captures the original `config.toml` and `.env` as a baseline. Provider activation composes only the managed model/provider keys and one managed provider table while preserving unrelated Codex configuration. Restoring OpenAI restores the baseline files.

The app intentionally does not modify OpenAI authentication credentials.

## Security model

Provider API keys are stored in macOS Keychain. Codex desktop does not reliably inherit shell environment variables, so the selected provider key is also written to `~/.codex/.env` while that provider is active. The baseline `.env` is restored when returning to OpenAI.

The app is not sandboxed because it must manage the user's existing `~/.codex` directory. It does not request unrelated filesystem access.

## Connection test

A connection test sends a small request to the provider's Responses API endpoint. The endpoint is derived by appending `/responses` unless the configured Base URL already ends with `/responses`. A successful test proves basic request compatibility only; it does not guarantee every Codex tool or streaming behavior is supported by the provider.

## Release build

`scripts/build_app.sh` calls `xcodebuild` against the shared Xcode scheme, builds a universal `arm64 x86_64` Release app, copies the product to `dist/`, applies an ad-hoc signature, verifies it, and creates a zip for GitHub Releases.

Developer ID signing and notarization are intentionally not embedded in the open-source repository. They can be layered onto the release workflow later with repository secrets.
