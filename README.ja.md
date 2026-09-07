# cpsm — Capsomnia CLI & Skill

ターミナルやAIエージェントから、Macのスリープ抑止・タイマー・設定を操作するCLIです。
[Capsomnia](https://capsomnia.com/)の操作を担い、共通の `capsomnia` Skillを同梱します。

[English](README.md) · [コマンド一覧](docs/commands.md) · [配布手順](docs/releasing.md)

**0.1.0は未公開の候補版です。** 対応アプリはCapsomnia **4.0.0以降**です。
公開済み3.5.0にはCLIの受付機能がありません。`fuji-mak/cpsm` は確認用のプライベートリポジトリです。一般公開は確認後に行います。

## 導入

単体の `cpsm.pkg` を開くとCLIが `/usr/local/bin/cpsm` に入ります。
SkillはCodex／Claude Codeから導入先を選べます。本文は同じで配置先だけが異なります。

- Codex: `~/.codex/skills/capsomnia/SKILL.md`
- Claude Code: `~/.claude/skills/capsomnia/SKILL.md`

導入後はエージェントのセッションを新しくしてください。他の対応エージェントには
[Skillフォルダ](skills/capsomnia)を、そのエージェントのSkill保存先へ配置できます。

CLIはmacOS 13.5以降のApple silicon／Intelに対応します。**Capsomniaアプリとhelperの
導入が必要**です。アプリの配布pkgはApple silicon・macOS 14以降、Intel向けはmacOS
13.5以降のソースビルドです。CLIの実行にsudoは不要です。

Capsomniaの **詳細設定 → CLI & Skill** からは、cpsm・MacReadyと両Skillをまとめた
`Capsomnia-Tools.pkg` を取得できます。MacReadyは状態を読み取る独立した作品です。

## 使い方

```sh
cpsm status --json
cpsm settings get
cpsm doctor --json
```

アプリが起動していなければ、有効なコマンドの実行時に起動します。help／version／
入力エラーでは起動しません。既定は `/Applications/Capsomnia.app` です。
ソース導入の場合は `--app "$HOME/Applications/Capsomnia.app"` を指定してください。

```sh
cpsm timer set 2h
cpsm timer status --json
cpsm timer cancel
```

`timer set` はONにして今回限りのタイマーを設定し、現在のタイマーを置換します。
保存した既定時間は変更しません。`cancel` はタイマーを止め、現在のON/OFFを維持します。
次のOFF→ONで保存済み設定に戻り、アプリ終了時には今回限りの設定は消えます。

**`cpsm off` はCapsomniaをOFFにしたうえでMacをスリープさせます。**
タイマー満了時と `toggle` がOFFへ切り替わる場合もスリープを要求します。
単なる状態確認には `status` を使ってください。

Skill導入後は「Macを2時間起こしておいて」「Capsomniaの状態を教えて」などと
エージェントに頼めます。タイムアウト時に電源操作を自動再実行せず、まず状態を確認します。

## ビルド・削除

Swift 5.9以降（Xcode 15以降）が必要です。

```sh
swift build -c release --product cpsm
swift test
SKIP_SIGNING=true ./scripts/build-pkg.sh
```

未署名pkgはローカル検証用です。公開前の署名・公証は[配布手順](docs/releasing.md)を参照してください。

削除は `sudo rm /usr/local/bin/cpsm` と、導入した各エージェントの `capsomnia` Skill
フォルダの削除で行えます。アプリ・設定・MacReadyは残ります。CLIの削除自体では
スリープ抑止は解除されないため、必要に応じて先にアプリでOFFにしてください。

作者: [Taketo Fujimaki / 藤巻雄飛](https://github.com/fuji-mak)
· [Capsomnia](https://capsomnia.com/) · MacReady（`fuji-mak/MacReady`としてリポジトリ・初版を公開準備中）
· [連絡先](https://x.com/tf_makimaki)

MITライセンス。
