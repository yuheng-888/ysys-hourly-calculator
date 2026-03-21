# Remember Project Name Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Persist the last successful project name and pre-fill it in every team-settlement entry flow on macOS and Windows.

**Architecture:** Add a small pure helper on each platform to normalize remembered project names, then wire that helper into existing settings persistence and settlement-entry forms. Reuse existing app settings storage so the change stays local, predictable, and easy to verify.

**Tech Stack:** SwiftUI with `@AppStorage`, Swift Testing, WPF/.NET 8, JSON-backed settings persistence

---

### Task 1: Document and prepare the workspace

**Files:**
- Create: `docs/plans/2026-03-21-remember-project-name-design.md`
- Create: `docs/plans/2026-03-21-remember-project-name.md`

**Step 1: Save the approved design**

Write the design doc capturing scope, chosen approach, UX details, and testing strategy.

**Step 2: Save the implementation plan**

Write the task-by-task plan for the feature so the implementation can proceed without rediscovering context.

**Step 3: Commit documentation**

Run:

```bash
git add docs/plans/2026-03-21-remember-project-name-design.md docs/plans/2026-03-21-remember-project-name.md
git commit -m "docs: capture remembered project name design"
```

Expected: new docs committed cleanly

### Task 2: Add macOS failing tests

**Files:**
- Modify: `autuo sound time v2Tests/autuo_sound_time_v2Tests.swift`
- Modify: `autuo sound time v2/audio tools.swift`

**Step 1: Write the failing test**

Add tests for a pure helper that:

- falls back to remembered project name when current input is blank
- preserves nonblank current input
- trims remembered project names and ignores whitespace-only submissions

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project "autuo sound time v2.xcodeproj" -scheme "autuo sound time v2" -destination "platform=macOS" -only-testing:"autuo sound time v2Tests/autuo_sound_time_v2Tests"
```

Expected: FAIL because the helper does not exist yet

### Task 3: Implement macOS remembered project-name behavior

**Files:**
- Modify: `autuo sound time v2/audio tools.swift`
- Test: `autuo sound time v2Tests/autuo_sound_time_v2Tests.swift`

**Step 1: Add minimal implementation**

Add:

- `lastProjectName` to `AppSettings`
- a pure helper for remembered project name normalization
- auto-mode initialization that pulls from settings
- team-settlement form reset/init behavior that restores the remembered project name
- successful add flows that persist the trimmed project name

**Step 2: Run tests to verify they pass**

Run:

```bash
xcodebuild test -project "autuo sound time v2.xcodeproj" -scheme "autuo sound time v2" -destination "platform=macOS" -only-testing:"autuo sound time v2Tests/autuo_sound_time_v2Tests"
```

Expected: PASS

### Task 4: Add Windows failing tests

**Files:**
- Create: `windows/AutuoSoundTimeV3.Tests/AutuoSoundTimeV3.Tests.csproj`
- Create: `windows/AutuoSoundTimeV3.Tests/ProjectNameMemoryTests.cs`
- Modify: `windows/AutuoSoundTimeV3/AutuoSoundTimeV3.csproj`

**Step 1: Write the failing test**

Add tests for the Windows pure helper that cover the same normalization rules as macOS.

**Step 2: Run test to verify it fails**

Run:

```bash
dotnet test windows/AutuoSoundTimeV3.Tests/AutuoSoundTimeV3.Tests.csproj
```

Expected: FAIL because the helper does not exist yet

### Task 5: Implement Windows remembered project-name behavior

**Files:**
- Modify: `windows/AutuoSoundTimeV3/Models/AppSettings.cs`
- Modify: `windows/AutuoSoundTimeV3/ViewModels/SettingsViewModel.cs`
- Modify: `windows/AutuoSoundTimeV3/ViewModels/AutoModeViewModel.cs`
- Modify: `windows/AutuoSoundTimeV3/ViewModels/TeamSettlementViewModel.cs`
- Create: `windows/AutuoSoundTimeV3/Services/ProjectNameMemory.cs`
- Test: `windows/AutuoSoundTimeV3.Tests/ProjectNameMemoryTests.cs`

**Step 1: Add minimal implementation**

Add:

- `LastProjectName` in Windows settings
- pure helper for normalization
- remembered project name initialization in both view models
- persistence after successful settlement entry creation

**Step 2: Run tests to verify they pass**

Run:

```bash
dotnet test windows/AutuoSoundTimeV3.Tests/AutuoSoundTimeV3.Tests.csproj
```

Expected: PASS

### Task 6: Verify builds and finish delivery

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Run platform verification**

Run:

```bash
xcodebuild test -project "autuo sound time v2.xcodeproj" -scheme "autuo sound time v2" -destination "platform=macOS"
dotnet build windows/AutuoSoundTimeV3/AutuoSoundTimeV3.csproj
```

Expected: both builds succeed

**Step 2: Update changelog if needed**

Add a short entry describing remembered project-name defaults.

**Step 3: Commit and push**

Run:

```bash
git add .
git commit -m "feat: remember last team settlement project name"
git push origin main
```

Expected: branch pushed to `origin/main`

**Step 4: Produce installable output**

Run the macOS packaging/build flow already used in the repo and place the new installable artifact in the workspace.

Plan complete and saved to `docs/plans/2026-03-21-remember-project-name.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints
