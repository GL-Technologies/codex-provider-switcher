# Changelog

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
