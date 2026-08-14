import Foundation

enum BridgeStrings {
    static func value(for key: String) -> String? {
        let language = Bundle.main.preferredLocalizations.first ?? Locale.current.language.languageCode?.identifier ?? "en"
        let table = translations[language] ?? translations[String(language.prefix(2))] ?? translations["en"]!
        return table[key] ?? translations["en"]?[key]
    }

    private static let translations: [String: [String: String]] = [
        "en": [
            "key.stored": "Saved locally",
            "bridge.enabled_title": "Local bridge enabled",
            "bridge.enabled_message": "This Chat Completions provider is now exposed to Codex through the local Responses bridge at %@. Keep Codex Provider Switcher running while using this provider.",
            "bridge.status": "Local Responses bridge",
            "bridge.active": "Active",
            "bridge.inactive": "Direct provider connection",
            "bridge.badge": "Bridge",
            "settings.credentials": "Credentials",
            "settings.credentials_detail": "GitHub builds store provider keys in ~/.codex/provider-switcher/credentials.json with owner-only permissions (0600). This avoids recurring macOS Keychain prompts caused by ad-hoc signing."
        ],
        "zh-Hans": [
            "key.stored": "已保存在本地",
            "bridge.enabled_title": "已启用本地桥接",
            "bridge.enabled_message": "该 Chat Completions 接口已通过本地 Responses Bridge 提供给 Codex：%@。使用此接口期间请保持 Codex 接口切换器运行。",
            "bridge.status": "本地 Responses Bridge",
            "bridge.active": "已启用",
            "bridge.inactive": "接口直连",
            "bridge.badge": "桥接",
            "settings.credentials": "凭据存储",
            "settings.credentials_detail": "当前 GitHub 构建将 API Key 保存在 ~/.codex/provider-switcher/credentials.json，并设置为仅当前用户可读写（0600）。这样可避免 ad-hoc 签名版本反复触发 macOS 钥匙串授权。"
        ],
        "zh-Hant": [
            "key.stored": "已儲存在本機",
            "bridge.enabled_title": "已啟用本機橋接",
            "bridge.enabled_message": "此 Chat Completions 介面已透過本機 Responses Bridge 提供給 Codex：%@。使用期間請保持 Codex Provider Switcher 執行。",
            "bridge.status": "本機 Responses Bridge",
            "bridge.active": "已啟用",
            "bridge.inactive": "介面直連",
            "bridge.badge": "橋接",
            "settings.credentials": "憑證儲存",
            "settings.credentials_detail": "GitHub 版本將 API Key 儲存在 ~/.codex/provider-switcher/credentials.json，權限為 0600，以避免 ad-hoc 簽署版本反覆要求鑰匙圈授權。"
        ],
        "ja": [
            "key.stored": "ローカルに保存済み",
            "bridge.enabled_title": "ローカルブリッジを有効化しました",
            "bridge.enabled_message": "この Chat Completions プロバイダーは %@ のローカル Responses ブリッジ経由で Codex に接続されます。使用中は Codex Provider Switcher を起動したままにしてください。",
            "bridge.status": "ローカル Responses ブリッジ",
            "bridge.active": "有効",
            "bridge.inactive": "直接接続",
            "bridge.badge": "Bridge",
            "settings.credentials": "認証情報",
            "settings.credentials_detail": "GitHub ビルドでは API Key を ~/.codex/provider-switcher/credentials.json に 0600 権限で保存し、ad-hoc 署名によるキーチェーンの繰り返し確認を回避します。"
        ],
        "ko": [
            "key.stored": "로컬에 저장됨",
            "bridge.enabled_title": "로컬 브리지가 활성화됨",
            "bridge.enabled_message": "이 Chat Completions 공급자는 %@의 로컬 Responses 브리지를 통해 Codex에 연결됩니다. 사용하는 동안 Codex Provider Switcher를 실행 상태로 유지하세요.",
            "bridge.status": "로컬 Responses 브리지",
            "bridge.active": "활성",
            "bridge.inactive": "직접 연결",
            "bridge.badge": "Bridge",
            "settings.credentials": "자격 증명",
            "settings.credentials_detail": "GitHub 빌드는 API Key를 ~/.codex/provider-switcher/credentials.json에 0600 권한으로 저장하여 ad-hoc 서명으로 인한 반복적인 키체인 승인을 피합니다."
        ],
        "es": [
            "key.stored": "Guardada localmente",
            "bridge.enabled_title": "Puente local activado",
            "bridge.enabled_message": "Este proveedor de Chat Completions se expone a Codex mediante el puente local Responses en %@. Mantén Codex Provider Switcher abierto mientras lo uses.",
            "bridge.status": "Puente local Responses",
            "bridge.active": "Activo",
            "bridge.inactive": "Conexión directa",
            "bridge.badge": "Bridge",
            "settings.credentials": "Credenciales",
            "settings.credentials_detail": "Las compilaciones de GitHub guardan las API Key en ~/.codex/provider-switcher/credentials.json con permisos 0600 para evitar avisos repetidos del Llavero causados por la firma ad-hoc."
        ]
    ]
}
