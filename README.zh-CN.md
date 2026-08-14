# Codex Provider Switcher

<p align="center">
  <img src="docs/app-icon.png" width="112" alt="Codex Provider Switcher 图标">
</p>

一个原生 macOS 工具，用于在 Codex 的 OpenAI 官方配置与多个 **OpenAI Responses API 兼容接口**之间切换。

> 本项目与 OpenAI 无隶属或官方合作关系。

## 主要功能

- 保存多个 Provider 配置并快速切换。
- 一键恢复切换前的 OpenAI 原始配置。
- API Key 保存在 macOS 钥匙串。
- 保存前可真实请求一次 `POST /responses` 测试连通性。
- 修改 `~/.codex/config.toml` 和 `~/.codex/.env` 前自动备份。
- Codex 桌面端和 CLI 使用同一套用户级配置，因此都会随配置切换。
- 支持英语、简体中文、繁体中文、日语、韩语和西班牙语界面。

## 要求

- macOS 13 或更高版本。
- 已安装并正常配置 Codex。
- 接口必须兼容 OpenAI Responses API。仅兼容 `/chat/completions` 不代表可以使用。

## 安装

从 GitHub **Releases** 下载最新 macOS 版本，解压后将 **Codex Provider Switcher.app** 放入“应用程序”。

当前公开 Release 使用 ad-hoc 签名，首次启动时 macOS 可能需要“右键 → 打开”。以后如果配置 Developer ID 和公证，可以改为正式签名发布。

## Xcode 构建

项目以原生 Xcode 工程作为主要构建入口：

```text
Codex Provider Switcher.xcodeproj
```

在 Xcode 中打开后选择 **My Mac**，运行 **Codex Provider Switcher** Scheme 即可。

如果需要生成通用架构 `.app` 和 zip：

```bash
./scripts/build_app.command
```

脚本要求安装完整 Xcode，而不是只有 Command Line Tools。产物在 `dist/`，构建日志在 `.build-app/build.log`。

## 数据安全

Provider 配置保存在：

```text
~/.codex/provider-switcher/
```

API Key 长期存放在 macOS Keychain。兼容接口启用时，Key 会写入 `~/.codex/.env` 供 Codex 桌面端读取；切回 OpenAI 时恢复原来的 `.env`。

每次修改配置前都会在这里创建备份：

```text
~/.codex/provider-switcher/backups/
```

## License

MIT © 2026 GL-Technologies。
