# Codex Provider Switcher

<p align="center">
  <img src="https://raw.githubusercontent.com/GL-Technologies/codex-provider-switcher/main/docs/app-icon.png" width="112" alt="Codex Provider Switcher icon">
</p>

<p align="center">
  <a href="../../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · 日本語 · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a>
</p>

Codex を OpenAI と複数の OpenAI 互換プロバイダー間で切り替えるためのネイティブ macOS ユーティリティです。Chat Completions のみを提供する API は、ローカルの Responses 互換ブリッジを通じて Codex から利用できます。

> 本プロジェクトは OpenAI およびアプリ内に表示される各プロバイダーブランドとは提携・公認関係にありません。

## 主な機能

- OpenAI と複数プロバイダーをワンクリックで切り替え。
- **Auto Bridge** は初期状態で有効。
- Responses API と Chat Completions を自動判定。
- 互換 `/models` エンドポイントからモデルを検索。
- 関数、Codex custom/freeform tools、tool search、namespace、一般的な reasoning、usage 情報をブリッジで変換。
- macOS メニューバーからプロバイダー切り替え、ブリッジ状態確認、設定、終了が可能。
- アプリ再起動後も Codex が localhost を指していればブリッジを自動復元。
- `~/.codex/config.toml` と `~/.codex/.env` の変更前に自動バックアップ。
- SwiftUI ネイティブ UI、ライト／ダークモード対応。

## 動作イメージ

```text
Responses 対応プロバイダー
Codex ─────────────────────────────→ Provider /responses

Chat Completions のみのプロバイダー
Codex → localhost Responses Bridge → Provider /chat/completions
```

ブリッジは localhost のみで待ち受けます。メインウィンドウを閉じてもメニューバー常駐で動作を継続し、アプリを終了した場合のみブリッジが停止します。

## クイックスタート

1. 「Add Provider」で Base URL、モデル ID、API Key を入力します。名前は空欄でも自動生成できます。
2. `/models` を提供する API では「Find Models」を利用できます。
3. 「Test Connection」を実行します。Responses を先に、Chat Completions を次に確認します。
4. 「Use」を選択します。
   - Responses 対応 API は直接接続。
   - Chat Completions のみの場合は Auto Bridge が自動的にローカル変換します。
5. 必要に応じて Codex を再起動します。
6. 以後はメニューバーから素早く切り替えできます。
7. 公式設定へ戻す場合は OpenAI → 「Use OpenAI」を選びます。

## インストール

GitHub **Releases** から最新版をダウンロードし、展開した **Codex Provider Switcher.app** を Applications に移動します。

公開ビルドは現在 ad-hoc 署名です。初回起動がブロックされた場合は、一度アプリを開いた後「システム設定 → プライバシーとセキュリティ」で「このまま開く」を選択してください。

## 認証情報とデータ

API Key は次の場所に保存されます。

```text
~/.codex/provider-switcher/credentials.json
```

ファイル権限は `0600`、状態ディレクトリは `0700` です。プロバイダー設定とバックアップも `~/.codex/provider-switcher/` 以下に保存されます。

ブリッジの詳細は [docs/BRIDGE.md](../BRIDGE.md) を参照してください。

## License

MIT © 2026 GL-Technologies.
