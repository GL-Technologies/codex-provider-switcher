# Codex Provider Switcher

<p align="center">
  <img src="https://raw.githubusercontent.com/GL-Technologies/codex-provider-switcher/main/docs/app-icon.png" width="112" alt="Codex Provider Switcher icon">
</p>

<p align="center">
  <a href="../../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · 한국어 · <a href="README.es.md">Español</a>
</p>

Codex를 OpenAI와 여러 OpenAI 호환 공급자 사이에서 전환할 수 있는 네이티브 macOS 유틸리티입니다. Chat Completions만 지원하는 API도 로컬 Responses 호환 브리지를 통해 Codex에서 사용할 수 있습니다.

> 이 프로젝트는 OpenAI 또는 앱에 표시되는 공급자 브랜드와 제휴하거나 공식 승인을 받은 프로젝트가 아닙니다.

## 주요 기능

- OpenAI와 여러 공급자를 원클릭으로 전환.
- 기본값으로 켜져 있는 **Auto Bridge**.
- Responses API와 Chat Completions 자동 감지.
- 호환 `/models` 엔드포인트를 통한 모델 검색.
- 함수, Codex custom/freeform tools, tool search, namespace, 일반 reasoning 출력, usage 메타데이터 변환.
- macOS 메뉴 막대에서 공급자 전환, 브리지 상태 확인, 설정, 종료 가능.
- 앱 재실행 후 Codex가 localhost를 계속 가리키면 브리지를 자동 복구.
- `~/.codex/config.toml`, `~/.codex/.env` 변경 전 자동 백업.
- SwiftUI 기반 네이티브 UI와 라이트/다크 모드.

## 동작 방식

```text
Responses 지원 공급자
Codex ─────────────────────────────→ Provider /responses

Chat Completions 전용 공급자
Codex → localhost Responses Bridge → Provider /chat/completions
```

브리지는 localhost에서만 수신합니다. 메인 창을 닫아도 메뉴 막대 아이콘을 통해 앱이 계속 실행되며, 앱을 완전히 종료할 때만 브리지가 중지됩니다.

## 빠른 시작

1. **Add Provider**에서 Base URL, 모델 ID, API Key를 입력합니다. 이름은 비워 두면 자동 생성됩니다.
2. 공급자가 `/models`를 제공하면 **Find Models**를 사용할 수 있습니다.
3. **Test Connection**을 실행합니다. Responses를 먼저 검사하고 Chat Completions를 다음으로 검사합니다.
4. **Use**를 선택합니다.
   - Responses 지원 API는 직접 연결합니다.
   - Chat Completions 전용 API는 Auto Bridge가 자동으로 로컬 변환합니다.
5. 안내에 따라 Codex를 다시 시작합니다.
6. 이후에는 메뉴 막대에서 빠르게 공급자를 전환할 수 있습니다.
7. 공식 설정으로 돌아가려면 OpenAI → **Use OpenAI**를 선택합니다.

## 설치

GitHub **Releases**에서 최신 버전을 내려받고 압축을 푼 뒤 **Codex Provider Switcher.app**을 Applications 폴더로 이동합니다.

현재 공개 빌드는 ad-hoc 서명입니다. macOS가 첫 실행을 차단하면 앱을 한 번 연 뒤 **시스템 설정 → 개인정보 보호 및 보안**에서 **그래도 열기**를 선택하세요.

## 자격 증명과 데이터

API Key는 다음 위치에 저장됩니다.

```text
~/.codex/provider-switcher/credentials.json
```

파일 권한은 `0600`, 상태 디렉터리는 `0700`입니다. 공급자 설정과 백업도 `~/.codex/provider-switcher/` 아래에 저장됩니다.

브리지 아키텍처와 지원 범위는 [docs/BRIDGE.md](../BRIDGE.md)를 참고하세요.

## License

MIT © 2026 GL-Technologies.
