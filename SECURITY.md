# Security Policy

Please do not open a public issue for a vulnerability that could expose API keys or modify Codex configuration unexpectedly.

Report security issues privately to the repository owner through GitHub's private vulnerability reporting feature when available.

The project stores long-term API keys in macOS Keychain. While a custom provider is active, its key is also written to `~/.codex/.env` so Codex can read it.
