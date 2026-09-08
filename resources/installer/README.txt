cpsm — Capsomnia CLI & Skill

macOS 13.5以降。CLI対応版のCapsomniaアプリが必要です。
cpsmを /usr/local/bin/cpsm にインストールします。
ライセンス / License: /usr/local/share/cpsm/LICENSE
Capsomniaアプリ自体はこのパッケージに含まれません。

Skillは共通の内容で、ログイン中のユーザーへ自動導入します。
  共通: ~/.agents/skills/capsomnia/SKILL.md
  Claude Code: ~/.claude/skills/capsomnia -> 共通Skillへのsymlink
旧版の同一内容だけを安全に移行します。カスタム内容は保持し、競合時は停止します。

Requires macOS 13.5 or later and a CLI-compatible Capsomnia app.
Installs cpsm in /usr/local/bin. The Capsomnia app is not included.
Codex and Claude Code use one shared Skill installation.
The Skill is installed at ~/.agents/skills/capsomnia and Claude Code receives
a symlink at ~/.claude/skills/capsomnia. Existing identical legacy copies are
migrated; custom or conflicting content is preserved and causes the installer
to stop.

Author: Taketo Fujimaki
