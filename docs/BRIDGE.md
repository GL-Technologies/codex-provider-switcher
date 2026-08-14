# Auto Bridge

Codex currently speaks the OpenAI Responses API, while many third-party and aggregator endpoints only expose OpenAI-style Chat Completions. **Auto Bridge** lets those providers remain usable without asking the user to install a separate proxy.

## Routing

Auto Bridge is enabled by default.

```text
Native Responses provider
Codex -> provider /responses

Chat-Completions-only provider
Codex -> 127.0.0.1:<local-port>/v1/responses
      -> Codex Provider Switcher
      -> provider /chat/completions
```

The bridge binds only to `127.0.0.1`. The real provider API key is not written into the localhost Codex provider configuration.

## Automatic protocol selection

When a provider is activated, the app probes conservative Base URL candidates and checks Responses before Chat Completions.

- Native Responses succeeds: direct connection.
- Responses fails but Chat Completions succeeds and Auto Bridge is on: local bridge.
- Chat Completions succeeds but Auto Bridge is off: activation is blocked until the user opts in.
- Neither succeeds: the provider remains unchanged and diagnostics are shown.

Vendor-specific paths such as `/api/paas/v4` are preserved. `/v1` is only inferred for bare host/root URLs.

## Tool compatibility

The bridge transformer currently handles:

- normal text/developer/system messages
- standard function tools and tool outputs
- Codex custom/freeform tools through a reversible function wrapper
- tool namespaces through reversible flattened names
- client-side `tool_search` calls
- common image input parts when the upstream Chat API accepts OpenAI-style multimodal content
- reasoning text returned through common `reasoning_content`, `reasoning`, `thinking`, or leading `<think>` shapes
- usage conversion, including cached input tokens and reasoning output tokens when reported upstream
- Responses JSON and synthetic Responses SSE lifecycle events

Strict Chat gateways are accommodated by collapsing system/developer messages into a single leading system message and by normalizing function schemas to `type: object`.

## Deliberate limits

The bridge does not pretend that Chat Completions and Responses are identical. Provider-hosted OpenAI tools, server-side Responses conversation state, provider-specific media/file extensions, and every proprietary reasoning parameter cannot be reproduced generically.

The current upstream request is non-streaming and is converted to a Responses SSE lifecycle after completion when Codex requests streaming. This favors compatibility over minimum first-token latency. True incremental upstream streaming can be added without changing the public bridge contract because transformation and network transport are separated.

## Background lifetime

A bridged route requires Codex Provider Switcher to remain running. Closing the main window is safe because the menu bar item keeps the app alive. Quitting the app stops the bridge. If the app is relaunched while Codex is still configured for a bridged provider, the bridge is restored automatically.

## Compatibility research

The design review for v0.3.7 studied the MIT-licensed CC Switch project, particularly its Codex Responses ↔ Chat conversion, strict-provider normalization, tool-shape restoration, and tray-based routing workflow. This project uses an independent native Swift implementation. See `THIRD_PARTY_NOTICES.md`.
