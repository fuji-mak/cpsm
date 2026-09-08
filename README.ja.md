# cpsm — Capsomnia CLI & Skill

ターミナルやAIエージェントから、Macのスリープ抑止・タイマー・設定を操作するCLIです。
[Capsomnia](https://capsomnia.com/)の操作を担い、共通の `capsomnia` Skillを同梱します。

[English](README.md) · [コマンド一覧](docs/commands.md) · [配布手順](docs/releasing.md)

**v0.1.1は2026年9月8日現在の公開版です。** 対応アプリはCapsomnia
**4.0.0以降**です。CLIに対応するCapsomniaの公開リリース系列です。
対応アプリ4.0.0以降の公開リリース系列に対応します。

[Capsomnia CLI & Skillをダウンロード](https://github.com/fuji-mak/cpsm/releases/latest/download/cpsm.pkg) ·
[Capsomnia Toolsをダウンロード](https://github.com/fuji-mak/cpsm/releases/latest/download/Capsomnia-Tools.pkg)

## 導入

単体の [`cpsm.pkg`](https://github.com/fuji-mak/cpsm/releases/latest/download/cpsm.pkg) を開くとCLIが `/usr/local/bin/cpsm` に入ります。
Skillは共通先へ自動導入され、Codex／Claude Codeから利用できます。導入先の選択はありません。

- 共通: `~/.agents/skills/capsomnia/SKILL.md`
- Claude Code: `~/.claude/skills/capsomnia`（共通先へのsymlink）

導入後はエージェントのセッションを新しくしてください。他の対応エージェントには
[Skillフォルダ](skills/capsomnia)を、そのエージェントのSkill保存先へ配置できます。

CLIはmacOS 13.5以降のApple silicon／Intelに対応します。**Capsomniaアプリとhelperの
導入が必要**です。アプリの配布pkgはApple silicon・macOS 14以降、Intel向けはmacOS
13.5以降のソースビルドです。CLIの実行にsudoは不要です。

cpsmの `v0.1.1` リリースには、cpsm・MacReadyと両Skillをまとめた
[`Capsomnia-Tools.pkg`](https://github.com/fuji-mak/cpsm/releases/latest/download/Capsomnia-Tools.pkg) も含まれます。
Capsomniaの **詳細設定 → CLI & Skill** は同じパッケージへリンクします。
MacReadyはCapsomniaを必要としない、単独利用可能なツールとして
[専用リリース](https://github.com/fuji-mak/MacReady/releases/latest/download/MacReady.pkg) も公開しています。

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

未署名pkgはローカル検証用です。署名・公証と公開後の更新は[配布手順](docs/releasing.md)を参照してください。
Tools統合版のビルドには隣接する `MacReady` リポジトリが必要です。
`./scripts/build-tools-pkg.sh` はMacReadyの単体成果物を隣接リポジトリの `dist` に置き、
統合pkgと `Tools-SHA256SUMS.txt` をこのリポジトリの `dist` に生成します。

削除は `sudo rm /usr/local/bin/cpsm` と、共通の `capsomnia` Skill
フォルダおよびClaude Codeのsymlinkの削除で行えます。アプリ・設定・MacReadyは残ります。CLIの削除自体では
スリープ抑止は解除されないため、必要に応じて先にアプリでOFFにしてください。

作者: [Taketo Fujimaki / 藤巻雄飛](https://github.com/fuji-mak)
· [Capsomnia](https://capsomnia.com/) · [MacReady](https://github.com/fuji-mak/MacReady)
· [連絡先](https://x.com/tf_makimaki)

MITライセンス。
