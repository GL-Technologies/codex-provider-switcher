# Codex Provider Switcher

<p align="center">
  <img src="docs/app-icon.png" width="112" alt="Codex Provider Switcher 图标">
</p>

一个原生 macOS 工具，用于在 Codex 的 OpenAI 官方配置与多个 **OpenAI Responses API 兼容接口**之间切换。

> 本项目与 OpenAI 及应用中列出的各接口厂商均无隶属或官方合作关系。

## 主要功能

- 保存多个 Provider 配置并快速切换。
- 常用 AI 厂商视觉图标，并可根据名称和 Base URL 自动识别。
- 原生 macOS UI，自动适配浅色/深色模式。
- API Key 保存在 macOS 钥匙串，编辑时可查看。
- 保存前可真实请求一次 `POST /responses` 测试连通性。
- 一键恢复切换前的 OpenAI 原始配置。
- 修改 `~/.codex/config.toml` 和 `~/.codex/.env` 前自动备份。
- 首次运行检查 `~/.codex` 是否可正常访问，并提供 macOS“隐私与安全性”故障处理入口。
- 支持英语、简体中文、繁体中文、日语、韩语和西班牙语界面。

## macOS 权限

正常情况下，本应用只需要访问当前用户目录下的 `~/.codex`，以及使用 macOS 钥匙串保存 API Key，**不要求默认开启“完全磁盘访问权限”**。

首次启动会在 `~/.codex` 内创建并立即删除一个测试文件，用来确认配置目录可写。如果系统阻止访问，应用会提供“打开隐私与安全性”和“完全磁盘访问权限”按钮作为故障处理入口。

## 要求

- macOS 13 或更高版本。
- 已安装并正常配置 Codex。
- 接口必须兼容 OpenAI Responses API。仅兼容 `/chat/completions` 不代表可以使用。

## 安装

从 GitHub **Releases** 下载最新 macOS 版本，解压后将 **Codex Provider Switcher.app** 放入“应用程序”。

当前公开 Release 使用 ad-hoc 签名，首次启动时 macOS 可能需要“右键 → 打开”。以后如果配置 Developer ID 和公证，可以改为正式签名发布。

## 使用

1. 第一次打开时完成 Codex 配置访问检查。
2. 添加 Provider，填写名称、Base URL、模型 ID 和 API Key。
3. 图标可自动识别，也可手动选择厂商。
4. 点击“测试连接”验证 Responses API。
5. 点击“切换”，并按提示重启 Codex。
6. 要恢复官方配置时选择 OpenAI → “使用 OpenAI”。

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

发布版本号来自仓库根目录的 `VERSION` 文件。脚本要求安装完整 Xcode，而不是只有 Command Line Tools。产物在 `dist/`，构建日志在 `.build-app/build.log`。

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
