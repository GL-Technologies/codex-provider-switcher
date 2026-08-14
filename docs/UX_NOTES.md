# macOS interaction notes

This document records the interaction-placement rules used by Codex Provider Switcher.

## Sidebar

The sidebar is navigation first. Provider rows navigate to provider details; they do not activate a provider on selection.

Provider-specific contextual commands are exposed through a native macOS context menu:

- Use Provider (only when inactive and usable)
- Edit
- Duplicate
- Delete

The same commands remain discoverable from the app menu bar or the visible detail view; the context menu is supplemental rather than the only access path.

The global **Add Provider** command belongs in the window toolbar and the File/New command (`Command-N`), not in the bottom edge of the sidebar.

The sidebar footer is reserved for the persistent Auto Bridge state because it is a global routing preference, not an item-specific action. Help may remain there because it is noncritical.

## Provider detail

The detail header keeps only commands that are directly relevant to the selected provider and frequently used:

- Edit
- Test Connection
- Use Provider (only when the provider is not already active)

Duplicate and Delete are intentionally removed from the header overflow menu. They are secondary item-management commands and are available from the provider context menu and the macOS Provider menu.

Auto Bridge is not repeated in the detail page. The detail page shows passive route/Bridge status only, while the actual Auto Bridge control has one home in the sidebar.

## Destructive actions

Delete is presented with the standard trash symbol and destructive role. Deleting a provider always passes through the existing confirmation dialog.

## Visual hierarchy

- Accent/prominent treatment is reserved for the primary route-changing action.
- Test and Edit are secondary actions.
- Active state is communicated as status, not as a disabled primary button.
- Light and dark appearance continue to use semantic macOS colors from the shared design system.
