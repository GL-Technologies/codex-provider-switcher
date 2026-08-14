# Third-Party Notices

Codex Provider Switcher is an independent project and is not affiliated with OpenAI or the providers shown in the app.

## CC Switch

Protocol-compatibility and local-routing design in version 0.3.7 was informed by the open-source **CC Switch** project:

- Project: `farion1231/cc-switch`
- License: MIT
- Copyright © 2025 Jason Young

We studied CC Switch's public approach to Codex Responses ↔ Chat Completions conversion, including tool-shape normalization, custom/freeform tool wrapping, namespace flattening, strict-provider message normalization, and tray-based routing controls. Codex Provider Switcher implements its own native Swift transformation and networking layer.

CC Switch's MIT license is available in its upstream repository. No affiliation or endorsement is implied.
