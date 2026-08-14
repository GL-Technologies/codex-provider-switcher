# Contributing

Issues and pull requests are welcome.

## Requirements

- macOS 13+
- Full Xcode installation
- Swift 5.9+

## App development

Open:

```text
Codex Provider Switcher.xcodeproj
```

Select the shared **Codex Provider Switcher** scheme and **My Mac**.

## Tests

Run the platform-neutral core tests with:

```bash
swift test
```

## Release-style local build

```bash
./scripts/build_app.command
```

The build script intentionally uses `xcodebuild` so local and GitHub Actions builds follow the same Xcode project.

## Localization

Keep user-facing text in `Localizable.strings`. English is the development language. Current translations live in:

- `en.lproj`
- `zh-Hans.lproj`
- `zh-Hant.lproj`
- `ja.lproj`
- `ko.lproj`
- `es.lproj`

## Security

Never commit API keys, real provider credentials, `.env` files, personal `xcuserdata`, signing certificates, or provisioning profiles.
