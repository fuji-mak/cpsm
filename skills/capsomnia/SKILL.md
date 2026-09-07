---
name: capsomnia
description: Control the local Capsomnia macOS app through its optional cpsm CLI when the user asks to change or inspect awake mode, timers, or settings.
---

Use `cpsm` from PATH, or `/usr/local/bin/cpsm` (installed by cpsm.pkg or Capsomnia Tools). A previous manual install may be at `~/.local/bin/cpsm`. If no CLI exists, report that the optional CLI needs installation; do not fall back to the old OFF script. Use the selected `cpsm` command for every Capsomnia operation. Read its result and report the observed outcome. Do not manipulate Caps Lock through IOKit, power management through `pmset`, or preferences through `defaults` yourself.

Commands:

- `cpsm on`, `cpsm off`, `cpsm toggle`, `cpsm status`, `cpsm doctor`
- `cpsm timer set 2h|30m`, `timer status`, `timer restart`, `timer cancel`
- `cpsm settings get [key]` and `cpsm settings set <key> <value>`

The app is required; the first supported public app version is Capsomnia 4.0.0. Use `--json` when the result needs reliable parsing. The default app is `/Applications/Capsomnia.app`; pass `--app /path/to/Preview.app` for a local preview. `off` requests Mac sleep after turning awake mode off and verifying that sleep prevention is released; `toggle` does the same when it transitions into off mode. A failed operation does not establish that the Mac slept. The user's request to turn off authorizes that sleep. `timer set` is a one-shot session timer and replaces the existing timer without changing the saved app default. `timer cancel` cancels the timer and preserves the current awake state; it does not turn an already-off app on. The saved default applies again after an OFF→ON transition. One-shot timers end when the app quits. For a specific ON/OFF request, use the explicit command instead of toggle.

Settings keys are the canonical CLI names: `dedicated-caps-lock-mode`, `show-menu-bar-icon`, `language` (`en`, `ja`, `ko`, `zh-Hans`), `launch-at-login`, `keep-display-awake`, `ignore-external-caps-lock-off-while-lid-closed`, `auto-off-minutes` (0–1440), and `automatic-update-checks`. The keyboard shortcut is read-only.

If an operation times out or disconnects, its outcome may be unknown. Check status before deciding what to do next; do not automatically repeat a power operation. `sleep_requested: true` means macOS accepted the sleep request, not that continued execution after sleep was observed. Help and version work without launching the app. When working on a local preview, use the user-provided app path on every call.
