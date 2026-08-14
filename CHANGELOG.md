# Changelog

## 0.3.8

- Expanded GitHub README navigation to English, Simplified Chinese, Traditional Chinese, Japanese, Korean, and Spanish.
- Added dedicated Traditional Chinese, Japanese, Korean, and Spanish README files and refreshed the Simplified Chinese landing page.
- Improved the repository homepage with a clearer product summary, release/platform badges, architecture overview, and a shorter quick-start flow.
- Refined the macOS sidebar with a clearer active-provider indicator and a compact Auto Bridge status card.
- Added a dedicated connection-status card to provider details, including direct/bridge state and the Auto Bridge switch.
- Improved menu bar hierarchy with clearer icons for active route, provider switching, Settings, and Quit.
- Reworked Settings into clearer native grouped sections with visual bridge state, credentials, storage, and security actions.

## 0.3.7

- Added **Auto Bridge** as a first-class, default-on switch in the main sidebar, Settings, and menu bar.
- Chat-Completions-only providers now test as ready when Auto Bridge is enabled instead of showing a blocking compatibility warning.
- Fixed provider creation appearing to do nothing: provider names can be generated automatically, Save has local validation, and save failures are shown inside the editor sheet.
- Added a persistent macOS menu bar item with active-route status, quick provider switching, Auto Bridge control, Settings, and Quit.
- A bridged provider is restored automatically after relaunch when Codex is still configured for the local bridge.
- Reworked bridge transformation into a testable core and expanded compatibility for Codex function tools, custom/freeform tools, tool search, namespaces, reasoning text, strict system-message ordering, tool schemas, and token usage.
- Increased local bridge request capacity to 64 MiB and added a local health endpoint.
- Added bridge transformation unit tests for custom tools, namespace tools, and strict message normalization.
- Added third-party acknowledgements for CC Switch, whose MIT-licensed routing architecture informed the compatibility review.

## 0.3.6

- Added a localhost Responses-to-Chat-Completions bridge so Chat-Completions-only providers can be used by current Codex.
- Provider activation now auto-detects protocol support: Responses-compatible providers connect directly; Chat-Completions-only providers are routed through the bridge automatically.
- The bridge translates text conversations, standard function tools, function-call outputs, and Responses SSE lifecycle events.
- Added bridge status/badges to the provider UI and localized bridge messaging in all supported languages.
- Replaced automatic macOS Keychain reads in GitHub/ad-hoc builds with a local owner-only credential file (`~/.codex/provider-switcher/credentials.json`, mode 0600) to avoid recurring login-keychain approval prompts after app rebuilds/updates.
- Existing Keychain values are not read automatically; affected users paste each provider key once after upgrading.

## 0.3.5

- Added conservative Base URL auto-discovery: the exact URL is tried first, then `/v1` only when the user entered a host/root URL.
- Preserves explicit vendor paths such as `/api/paas/v4` instead of replacing them with `/v1`.
- Connection tests now probe all candidate Base URLs for Responses API before falling back to Chat Completions diagnostics.
- Successful tests automatically adopt the resolved Base URL in the provider editor.
- Added model discovery through OpenAI-compatible `GET /models` endpoints, with a selectable model menu and manual-entry fallback.
- Added localized endpoint/model discovery status text in all supported UI languages.
- Connection diagnostics now show the resolved Base URL used by the successful request.

## 0.3.4

- Replaced the macOS permission gate with an installation/security guide for approving unsigned builds through System Settings → Privacy & Security → Open Anyway.
- Removed Full Disk Access from the normal setup flow and Settings UI.
- Added adaptive endpoint normalization for Base URLs that already include `/responses` or `/chat/completions`.
- Added automatic two-stage connection testing: Responses API first, then Chat Completions for diagnosis.
- Distinguishes providers that are directly compatible with current Codex from providers whose API works but requires a Responses-compatible bridge.
- Added built-in endpoint presets for common providers, including DeepSeek and Zhipu AI.
- Prevents switching after a test proves that the configured endpoint is Chat-Completions-only.
- Added localized protocol-detection and installation-guide text for all supported UI languages.

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
