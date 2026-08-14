# Changelog

## 0.3.3

- Redesigned the macOS interface with aligned configuration grids, compact actions, detail cards, and native adaptive light/dark colors.
- Added a provider brand catalog with automatic detection and built-in visual identities for popular AI services.
- Added first-run macOS access setup that verifies write access to `~/.codex` and provides Privacy & Security troubleshooting shortcuts.
- Kept Full Disk Access optional; it is only presented as a troubleshooting path when macOS blocks local Codex configuration access.
- Removed the duplicate Add Provider action from the main toolbar.
- Added configuration and connection-test tabs to provider details.
- Expanded English, Simplified Chinese, Traditional Chinese, Japanese, Korean, and Spanish localization for the refreshed interface.
- Added a repository `VERSION` file used by release packaging.

## 0.3.2

- Moved the macOS app to a conventional Xcode project as the primary build entry point.
- Reworked the build script around `xcodebuild`, universal binaries, deterministic output paths, explicit logs, and ad-hoc signing.
- Added an actionable error when only Xcode Command Line Tools are selected.
- Reworked the UI around standard macOS sidebar, toolbar, forms, and Settings patterns.
- Removed duplicated and ambiguous controls from the main window.
- Added English-first localization resources with Simplified Chinese, Traditional Chinese, Japanese, Korean, and Spanish.
- Added multiple provider profiles, Keychain-backed credentials, connection tests, backup/restore, and OpenAI restore.
- Added CI and automated GitHub Release packaging.
- Reorganized the source tree for open-source maintenance.
- Added a dedicated macOS app icon and wired it into the Xcode asset catalog.
