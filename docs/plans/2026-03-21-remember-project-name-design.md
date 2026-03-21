# Remember Project Name Design

**Date:** 2026-03-21

## Context

The team-settlement flow currently requires entering the project name by hand every time. This happens in two places:

- macOS auto mode when adding the current calculation to team settlement
- macOS team-settlement manual entry sheet
- Windows auto mode when adding to team settlement
- Windows team-settlement entry form

The app already persists user preferences such as rates, selected tab, and theme. The project name should follow the same persistence model so users do not need to re-enter it repeatedly.

## Goals

- Remember the last successfully used project name
- Pre-fill the project name field in every team-settlement entry point
- Update the remembered value only after a successful add
- Avoid saving blank or whitespace-only values
- Keep behavior aligned across macOS and Windows

## Non-Goals

- Auto-detect project names from file paths
- Maintain multiple recent projects or favorites
- Infer project names per producer

## Selected Approach

Store a single `lastProjectName` value in each platform's existing settings storage:

- macOS: `AppSettings` with `@AppStorage`
- Windows: `settings.json` via `SettingsViewModel`

Each entry form loads the remembered value when it appears or initializes. After a settlement entry is added successfully, the app trims the submitted project name and persists it as the new remembered value.

## Why This Approach

- Minimal UI change with immediate payoff
- Reuses existing persistence patterns already present in the app
- Stable behavior that does not depend on current settlement history
- Easy to verify and keep consistent across platforms

## UX Details

- If a remembered project name exists, the project field starts with that value
- If the user types a different project and adds the entry, that new value becomes the remembered default
- Blank values never overwrite the remembered default
- In macOS auto mode, project name stays populated after adding so repeated settlement entries are faster
- In macOS team mode, resetting the form restores the remembered project name instead of clearing it completely

## Testing Strategy

- Add a tiny pure helper on each platform for normalizing remembered project names
- Test that blank current input falls back to remembered value
- Test that nonblank current input is preserved
- Test that remembered values are trimmed and blank submissions are ignored
- Run platform build verification after wiring the helper into UI/view-model logic
