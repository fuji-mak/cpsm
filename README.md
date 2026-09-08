# cpsm — Capsomnia CLI & Skill

Control your Mac's awake mode from a terminal or an AI agent.

`cpsm` is the command-line companion to [Capsomnia](https://capsomnia.com/).
Set one-shot timers, inspect state, change settings, or sleep your Mac when work
is finished. The included `capsomnia` Skill teaches agents the commands and their
sleep semantics.

[日本語](README.ja.md) · [Command reference](docs/commands.md) · [Release guide](docs/releasing.md)

**v0.1.1 is the current public release (September 8, 2026)** and requires
Capsomnia **4.0.0+**. This is the first CLI-compatible Capsomnia release line.

[Download cpsm CLI & Skill](https://github.com/fuji-mak/cpsm/releases/latest/download/cpsm.pkg) ·
[Download Capsomnia Tools](https://github.com/fuji-mak/cpsm/releases/latest/download/Capsomnia-Tools.pkg)

## Install

Open the [cpsm.pkg](https://github.com/fuji-mak/cpsm/releases/latest/download/cpsm.pkg).
It installs `/usr/local/bin/cpsm` and
installs one shared Skill for Codex and Claude Code at
`~/.agents/skills/capsomnia/`, with `~/.claude/skills/capsomnia` linked to it.
There are no agent destination choices. Restart the agent session afterward. You can also
copy [the Skill folder](skills/capsomnia) to another compatible agent yourself.

The CLI supports Apple silicon and Intel on macOS 13.5+. **Capsomnia.app and its
helper must already be installed.** The app's packaged release requires Apple
silicon/macOS 14+; Intel users can build the app from source on macOS 13.5+.
The CLI runs as your normal user, without sudo.

The cpsm `v0.1.1` release also provides
[`Capsomnia-Tools.pkg`](https://github.com/fuji-mak/cpsm/releases/latest/download/Capsomnia-Tools.pkg),
combining cpsm, MacReady and both shared Skills. MacReady reads Mac conditions
without needing the app and is also available as an independent
[MacReady release](https://github.com/fuji-mak/MacReady/releases/latest/download/MacReady.pkg).
Capsomnia's **Advanced Settings → CLI & Skill** links to the same Tools package.

## Try it

```sh
cpsm status --json
cpsm settings get
cpsm doctor --json
```

Valid commands start Capsomnia if needed. Help, version and invalid commands do
not launch it. The default app path is `/Applications/Capsomnia.app`. For a
source install, use `cpsm --app "$HOME/Applications/Capsomnia.app" status --json`.

```sh
cpsm timer set 2h
cpsm timer status --json
cpsm timer cancel
```

`timer set` enables awake mode and replaces the current timer **without changing
the saved default**. Cancel leaves the current awake state unchanged. Timer
expiry requests sleep. The saved default returns on the next OFF→ON transition;
one-shot settings end when the app quits.

**`cpsm off` includes Mac sleep.** Capsomnia turns Caps Lock off, confirms sleep
prevention has been released, then asks macOS to sleep. `toggle` also sleeps when
its target is off. Regular GUI off retains its existing normal-sleep behavior.

After installing the Skill, ask your agent to “keep this Mac awake for two
hours” or “show Capsomnia's remaining timer.” The Skill reports observed results
and avoids replaying power commands after a timeout with an unknown outcome.

## Build and test

Requires Xcode 15+ / Swift 5.9+. From this repository:

```sh
swift build -c release --product cpsm
swift test
.build/release/cpsm help
SKIP_SIGNING=true ./scripts/build-pkg.sh
```

The package script builds universal binaries by default. See the [release guide](docs/releasing.md)
for the release build and verification workflow.
Building the combined Tools package requires a sibling `MacReady` checkout;
`./scripts/build-tools-pkg.sh` places its standalone output in that checkout's
`dist` directory and writes the combined package and `Tools-SHA256SUMS.txt` to
this repository's `dist` directory.
`CapsomniaControl` is also a library product. Capsomnia vendors a versioned
snapshot of it so each repository builds independently.

## Remove

Delete the CLI and the shared Skill:

```sh
sudo rm /usr/local/bin/cpsm
sudo rm /usr/local/share/cpsm/LICENSE
sudo rmdir /usr/local/share/cpsm
rm -r ~/.agents/skills/capsomnia
rm ~/.claude/skills/capsomnia
```

The app, preferences and MacReady remain installed. Removing the CLI does not
release awake mode; use the app to restore normal sleep first if needed.

## Author and related work

Built by [Taketo Fujimaki](https://github.com/fuji-mak).

- [Capsomnia](https://capsomnia.com/): the Mac app behind cpsm.
- [MacReady](https://github.com/fuji-mak/MacReady): Mac power, battery, thermal,
  lid and display state as JSON. It is independently usable and does not require
  Capsomnia.
- [Contact](https://x.com/tf_makimaki) for feedback or collaboration.

MIT licensed. See [LICENSE](LICENSE) and [SECURITY.md](SECURITY.md).
