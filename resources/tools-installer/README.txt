Capsomnia Tools

CLI と Skill を追加します。Capsomnia アプリは別途インストールが必要です。

・CLI（必須）：/usr/local/bin/cpsm と /usr/local/bin/macready
・Skill（任意）：Capsomnia と MacReady
  導入先 Codex：~/.codex/skills/
  導入先 Claude Code：~/.claude/skills/

Skill の内容は共通です。インストール項目の「Skillをインストール」で、
導入先を選んでください。両方が初期選択されており、複数選択も可能です。
Skill は現在このMacにログイン中のユーザーへインストールします。

導入後は cpsm help で使い方を確認できます。

Capsomnia Tools

This installer adds the optional local tools for Capsomnia:

* CLI (required): cpsm and macready, installed at /usr/local/bin.
* Skills (optional): Capsomnia and MacReady, with the same content for every agent.
  Choose Codex (~/.codex/skills) and/or Claude Code (~/.claude/skills) as destinations.

Both destinations are selected by default and can be deselected in Customize.
The Skills are written to the home directory of the user currently signed in
at the Mac console. No Skill files are installed into a system root directory.

Use `cpsm help` to see available commands. The Capsomnia GUI app is installed
separately by the main Capsomnia installer.
