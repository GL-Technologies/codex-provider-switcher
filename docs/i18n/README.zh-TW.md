# Codex Provider Switcher

<p align="center">
  <img src="https://raw.githubusercontent.com/GL-Technologies/codex-provider-switcher/main/docs/app-icon.png" width="112" alt="Codex Provider Switcher icon">
</p>

<p align="center">
  <a href="../../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · 繁體中文 · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a>
</p>

一款原生 macOS 工具，用來在 OpenAI 與多個 OpenAI 相容服務之間快速切換 Codex，並可自動把只支援 Chat Completions 的服務橋接為 Codex 可使用的 Responses API。

> 本專案與 OpenAI 或 App 中顯示的任何供應商品牌均無隸屬或官方合作關係。

## 主要功能

- 一鍵切換 OpenAI 與多個 Provider。
- **Auto Bridge 自動橋接**，預設開啟。
- 自動檢測 Responses API 與 Chat Completions。
- 支援相容 `/models` 端點的模型探索。
- 橋接支援標準函式、Codex custom/freeform tools、tool search、namespace、常見 reasoning 與 usage 資訊。
- macOS 選單列常駐，可快速切換 Provider、查看橋接狀態、開啟設定或退出。
- App 重新啟動後，可在 Codex 仍指向 localhost 時自動恢復橋接。
- 修改 `~/.codex/config.toml` 與 `~/.codex/.env` 前自動備份。
- 原生 SwiftUI，支援淺色／深色模式。

## 工作方式

```text
Responses 原生 Provider
Codex ─────────────────────────────→ Provider /responses

只支援 Chat Completions 的 Provider
Codex → 本機 Responses Bridge → Provider /chat/completions
```

橋接只監聽 localhost。關閉主視窗不會停止橋接，選單列圖示會讓 App 持續執行；真正退出 App 才會停止 Bridge。

## 快速開始

1. 點擊「新增 Provider」，輸入 Base URL、模型 ID 與 API Key；名稱可留空自動產生。
2. 若服務提供 `/models`，可使用「探索模型」。
3. 執行「測試連線」。App 會先測 Responses，再測 Chat Completions。
4. 點擊「使用」。
   - 支援 Responses 的服務直接連線。
   - 只支援 Chat Completions 的服務在 Auto Bridge 開啟時自動橋接。
5. 依提示重新啟動 Codex。
6. 之後可直接從 macOS 選單列快速切換 Provider。
7. 需要恢復官方配置時，選擇 OpenAI →「使用 OpenAI」。

## 安裝

從 GitHub **Releases** 下載最新版本，解壓縮後把 **Codex Provider Switcher.app** 放入「應用程式」。

目前公開版本使用 ad-hoc 簽署。如果 macOS 阻止首次啟動，請先嘗試開啟一次 App，再到「系統設定 → 隱私權與安全性」選擇「仍要開啟」。

## 憑證與資料

Provider API Key 儲存在：

```text
~/.codex/provider-switcher/credentials.json
```

檔案權限為 `0600`，狀態目錄為 `0700`。Provider 設定與備份也位於 `~/.codex/provider-switcher/` 下。

橋接 Provider 的上游 Key 保留在 Codex Provider Switcher 內；直接連線的 Responses Provider 則可能需要把目前 Key 寫入 `~/.codex/.env` 供 Codex 讀取。

更多橋接架構與支援範圍請參閱 [docs/BRIDGE.md](../BRIDGE.md)。

## License

MIT © 2026 GL-Technologies。
