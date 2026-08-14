# Codex Provider Switcher

<p align="center">
  <img src="docs/app-icon.png" width="112" alt="Codex Provider Switcher 图标">
</p>

一个原生 macOS 工具，用于在 Codex 的 OpenAI 官方配置与多个 OpenAI 协议兼容接口之间切换。

> 本项目与 OpenAI 及应用中列出的各接口厂商均无隶属或官方合作关系。

## 主要功能

- 保存多个 Provider 并快速切换。
- 自动探测 Base URL 与兼容的 `/models` 模型列表。
- 自动检测 Responses API 与 Chat Completions。
- 原生 Responses 接口直接连接 Codex。
- **自动桥接**仅支持 Chat Completions 的接口，默认开启，无需另外安装代理。
- 桥接支持普通函数工具、Codex 自定义/freeform 工具、tool search、namespace、常见 reasoning 输出与 token usage 转换。
- App 重新启动后自动恢复正在使用的桥接路由。
- macOS 菜单栏常驻图标，可查看当前接口、快速切换和开关自动桥接。
- 一键恢复 OpenAI 原始配置。
- 修改 `~/.codex/config.toml` 和 `~/.codex/.env` 前自动备份。
- 原生 SwiftUI，自动适配浅色/深色模式。
- 支持英语、简体中文、繁体中文、日语、韩语和西班牙语。

## 要求

- macOS 13 或更高版本。
- 已安装并正常配置 Codex。
- 接口支持 OpenAI Responses API **或** Chat Completions。

## 安装

从 GitHub **Releases** 下载最新版本，解压后将 **Codex Provider Switcher.app** 放入“应用程序”。

当前公开 Release 使用 ad-hoc 签名。如果首次打开被 macOS 阻止，请先尝试打开一次，然后进入 **系统设置 → 隐私与安全性**，找到 Codex Provider Switcher 并选择**仍要打开**。

## 使用

1. 添加接口，填写 Base URL、模型 ID 与 API Key。名称可以留空，保存时会自动生成。
2. 接口支持时，可点击**探测模型**从 `/models` 自动读取模型列表。
3. 点击**测试连接**。软件会先测试 Responses，再探测 Chat Completions。
4. 点击**切换**：
   - 原生 Responses → Codex 直接连接。
   - 仅 Chat Completions → 默认自动启动本地 Bridge，再提供给 Codex。
5. 按提示重新打开 Codex。
6. 之后可以直接从 macOS 菜单栏快速切换接口。
7. 需要恢复官方配置时，选择 OpenAI → 使用 OpenAI。

使用桥接接口时，Codex Provider Switcher 需要保持运行。**主窗口可以关闭**，菜单栏图标会让 App 继续在后台运行；真正退出 App 后 Bridge 会停止。

## Base URL 与模型探测

不同厂家的 API 路径并不统一。软件会保留明确填写的厂商路径，例如 `/api/paas/v4`；只在用户输入纯域名/根路径时才把 `/v1` 作为候选，不会把明确的 `/v4` 强行改成 `/v1`。

如果厂商提供 OpenAI 风格的 `GET /models`，软件会自动读取模型；不支持时仍可手动填写。

## 自动桥接

当前 Codex 使用 Responses API，但大量兼容接口仍只提供 Chat Completions。自动桥接的链路为：

```text
Codex
  ↓ Responses API
127.0.0.1:<本地端口>
  ↓ 协议转换
厂商 /chat/completions
```

Bridge 只监听 `127.0.0.1`。转换层已经覆盖普通消息、function tools、Codex custom/freeform tools、tool search、namespace、常见 reasoning 文本以及 usage，并会处理一些严格兼容网关对 system 消息和工具 schema 的限制。

详细设计和已知边界见 [docs/BRIDGE.md](docs/BRIDGE.md)。

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

0.3.7 的桥接兼容性审查参考了 MIT 开源项目 CC Switch 的 Codex 路由设计，但本项目使用独立的原生 Swift 实现。说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## License

MIT © 2026 GL-Technologies。
