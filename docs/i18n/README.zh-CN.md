# Codex Provider Switcher

<p align="center">
  <img src="https://raw.githubusercontent.com/GL-Technologies/codex-provider-switcher/main/docs/app-icon.png" width="112" alt="Codex Provider Switcher 图标">
</p>

<p align="center">
  <strong>为 Codex 设计的原生 macOS 接口切换器与兼容桥接工具。</strong>
</p>

<p align="center">
  <a href="../../README.md">English</a> · 简体中文 · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a>
</p>

<p align="center">
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple">
  <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-orange?logo=swift">
  <img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue">
  <img alt="Release" src="https://img.shields.io/github/v/release/GL-Technologies/codex-provider-switcher">
</p>

一个原生 macOS 工具，用于在 Codex 的 OpenAI 官方配置与多个 OpenAI 协议兼容接口之间快速切换。原生 Responses API 可以直接连接；只支持 Chat Completions 的接口则可通过内置 Auto Bridge 自动转换给 Codex 使用。

> 本项目与 OpenAI 及应用中列出的各接口厂商均无隶属或官方合作关系。

## 核心能力

- **一键切换接口**：OpenAI 与多个已保存 Provider 之间快速切换。
- **自动桥接**：Chat-Completions-only 接口自动通过本地 Responses Bridge 使用，默认开启。
- **自动能力检测**：先检测 Responses API，再检测 Chat Completions。
- **模型探测**：兼容 `/models` 的接口可自动读取模型列表，不支持时仍可手动填写。
- **Codex 工具兼容**：桥接支持普通函数、custom/freeform tools、tool search、namespace、常见 reasoning 输出与 usage 信息。
- **菜单栏常驻**：无需反复打开主窗口即可查看状态、快速切换接口、开关桥接和进入设置。
- **桥接自动恢复**：App 重新启动后，如果 Codex 仍指向 localhost，会恢复之前的桥接 Provider。
- **配置保护**：修改 `~/.codex/config.toml` 与 `~/.codex/.env` 前自动备份。
- **原生 SwiftUI**：适配浅色/深色模式，并支持英语、简体中文、繁体中文、日语、韩语和西班牙语。

## 工作方式

```text
原生 Responses Provider
Codex ─────────────────────────────→ Provider /responses

仅 Chat Completions Provider
Codex → 本地 Responses Bridge → Provider /chat/completions
```

Bridge 只监听 localhost。**关闭主窗口不会停止桥接**，菜单栏图标会让 App 继续运行；只有真正退出 App 后 Bridge 才会停止。

## 要求

- macOS 13 或更高版本。
- 已安装并正常配置 Codex。
- 接口支持 OpenAI Responses API **或** Chat Completions。

## 安装

从 GitHub **Releases** 下载最新版本，解压后将 **Codex Provider Switcher.app** 放入“应用程序”。

当前公开 Release 使用 ad-hoc 签名。如果首次打开被 macOS 阻止，请先尝试打开一次，然后进入 **系统设置 → 隐私与安全性**，找到 Codex Provider Switcher 并选择**仍要打开**。

## 快速开始

1. 添加接口，填写 Base URL、模型 ID 与 API Key。名称可以留空，保存时会自动生成。
2. 接口支持时，可点击**探测模型**从 `/models` 自动读取模型列表。
3. 点击**测试连接**。软件会先测试 Responses，再探测 Chat Completions。
4. 点击**使用/切换**：
   - 原生 Responses → Codex 直接连接。
   - 仅 Chat Completions → Auto Bridge 自动启动本地转换后提供给 Codex。
5. 按提示重新打开 Codex。
6. 之后可以直接从 macOS 菜单栏快速切换接口。
7. 需要恢复官方配置时，选择 OpenAI → **使用 OpenAI**。

## Base URL 与模型探测

不同厂家的 API 路径并不统一。软件会保留明确填写的厂商路径，例如 `/api/paas/v4`；只在用户输入纯域名/根路径时才把 `/v1` 作为候选，不会把明确的 `/v4` 强行改成 `/v1`。

如果厂商提供 OpenAI 风格的 `GET /models`，软件会自动读取模型；不支持时仍可手动填写。

## 自动桥接

当前 Codex 使用 Responses API，但大量兼容接口仍只提供 Chat Completions。自动桥接链路为：

```text
Codex
  ↓ Responses API
127.0.0.1:<本地端口>
  ↓ 协议转换
厂商 /chat/completions
```

Bridge 只监听 `127.0.0.1`。转换层覆盖普通消息、function tools、Codex custom/freeform tools、tool search、namespace、常见 reasoning 文本与 usage，并处理部分严格兼容网关对 system 消息和工具 schema 的限制。

详细设计和已知边界见 [docs/BRIDGE.md](../BRIDGE.md)。

## API Key 存储

GitHub 公开版目前使用 ad-hoc 签名。重新构建的 ad-hoc App 访问 macOS Keychain 时可能反复弹出授权窗口，因此当前版本将 Provider API Key 保存到：

```text
~/.codex/provider-switcher/credentials.json
```

文件权限为当前用户独占的 `0600`，目录权限为 `0700`。旧版本 Keychain 中的 Key 不会主动读取，升级后每个 Provider 重新粘贴一次即可。

直接 Responses 接口启用时，当前 Key 可能写入 `~/.codex/.env` 供 Codex 桌面端读取；桥接模式下 Codex 只访问 localhost，真实上游 Key 保留在 Codex Provider Switcher 内。

## 数据与备份

Provider 元数据和 App 状态位于：

```text
~/.codex/provider-switcher/
```

配置修改前的备份位于：

```text
~/.codex/provider-switcher/backups/
```

## Xcode 构建

主工程：

```text
Codex Provider Switcher.xcodeproj
```

在 Xcode 里选择 **My Mac** 即可 Build/Run。生成 Universal `.app`：

```bash
./scripts/build_app.command
```

GitHub Actions 会在发布前执行 Swift 单元测试和真实 Xcode macOS 构建。

## 开源兼容性参考

桥接兼容性审查参考了 MIT 开源项目 CC Switch 的 Codex 路由设计，但本项目使用独立的原生 Swift 实现。说明见 [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md)。

## License

MIT © 2026 GL-Technologies。
