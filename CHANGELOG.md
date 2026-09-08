# Changelog

## 0.1.1 — 2026-09-08

- Unified Skill installation in `~/.agents/skills`, with a Claude Code compatibility symlink.
- Updated standalone and combined distribution documentation for the Capsomnia 4.0.0+ release line.
- Added installer coverage for shared Skill migration and conflict handling.

## 0.1.0 — 2026-09-08

- Independent Capsomnia CLI and common agent Skill.
- App auto-launch, JSON state/settings and diagnostics.
- Awake mode and one-shot timers; explicit off requests Mac sleep.
- Read/write app settings, with keyboard shortcut editing kept in the GUI.
- Universal macOS installers with shared Codex/Claude Code Skill installation.
- CapsomniaControl library for the app's versioned source snapshot.
- Migrate user-owned cache directories left by the old app updater to private permissions before starting the CLI service.
- Public release packages: standalone `cpsm.pkg` and the combined `Capsomnia-Tools.pkg`.
- Requires Capsomnia 4.0.0 or later.
