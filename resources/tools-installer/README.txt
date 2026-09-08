Capsomnia Tools

CLI と Skill を追加します。Capsomnia アプリは別途インストールが必要です。

・CLI（必須）：/usr/local/bin/cpsm と /usr/local/bin/macready
・Skill（任意）：Capsomnia と MacReady
  共通導入先：~/.agents/skills/
  Claude Code：~/.claude/skills/ は共通先へのsymlink

Skill の内容と導入先は共通です。インストーラーは選択なしで両方を導入します。
Skill は現在このMacにログイン中のユーザーへインストールします。

導入後は cpsm help で使い方を確認できます。

Capsomnia Tools

This installer adds the optional local tools for Capsomnia:

* CLI (required): cpsm and macready, installed at /usr/local/bin.
* Skills: Capsomnia and MacReady, shared by every agent under ~/.agents/skills.
  Claude Code paths are symlinks to the shared Skills.

The Skills are written to the home directory of the user currently signed in
at the Mac console. No Skill files are installed into a system root directory.

Use `cpsm help` to see available commands. The Capsomnia GUI app is installed
separately by the main Capsomnia installer.
