# cpsm — Capsomnia CLI & Skill

Control your Mac's awake mode from a terminal or an AI agent.

`cpsm` is the command-line companion to [Capsomnia](https://capsomnia.com/).
Set one-shot timers, inspect state, change settings, or sleep your Mac when work
is finished. The included `capsomnia` Skill teaches agents the commands and their
sleep semantics.

[日本語](README.ja.md) · [Command reference](docs/commands.md) · [Release guide](docs/releasing.md)

**0.1.0 is an unpublished release candidate**, targeting Capsomnia **4.0.0+**,
also awaiting release. The public 3.5.0 app does not include the CLI service.
The repository `fuji-mak/cpsm` is private during review; downloads are not public yet.

## Install

Open the separately supplied `cpsm.pkg`. It installs `/usr/local/bin/cpsm` and
lets you choose Skill destinations: Codex, Claude Code, or both. These receive
**the same Skill**, in `~/.codex/skills/capsomnia/` and
`~/.claude/skills/capsomnia/`. Restart the agent session afterward. You can also
copy [the Skill folder](skills/capsomnia) to another compatible agent yourself.

The CLI supports Apple silicon and Intel on macOS 13.5+. **Capsomnia.app and its
helper must already be installed.** The app's packaged release requires Apple
silicon/macOS 14+; Intel users can build the app from source on macOS 13.5+.
The CLI runs as your normal user, without sudo.

Capsomnia's **Advanced Settings → CLI & Skill** provides `Capsomnia-Tools.pkg`,
combining cpsm, MacReady and both optional Skills. MacReady reads Mac conditions
without needing the app; its independent first release is also pending.

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

The package script builds universal binaries by default. Public packages need
Developer ID signing and Apple notarization; see the [release guide](docs/releasing.md).
`CapsomniaControl` is also a library product. Capsomnia vendors a versioned
snapshot of it so each repository builds independently.

## Remove

Delete the CLI and only the Skill directories you installed:

```sh
sudo rm /usr/local/bin/cpsm
sudo rm /usr/local/share/cpsm/LICENSE
sudo rmdir /usr/local/share/cpsm
rm -r ~/.codex/skills/capsomnia
rm -r ~/.claude/skills/capsomnia
```

The app, preferences and MacReady remain installed. Removing the CLI does not
release awake mode; use the app to restore normal sleep first if needed.

## Author and related work

Built by [Taketo Fujimaki](https://github.com/fuji-mak).

- [Capsomnia](https://capsomnia.com/): the Mac app behind cpsm.
- **MacReady**: Mac power, battery, thermal, lid and display state as JSON.
  Its repository `fuji-mak/MacReady` is private; public availability and the first release await review.
- [Contact](https://x.com/tf_makimaki) for feedback or collaboration.

MIT licensed. See [LICENSE](LICENSE) and [SECURITY.md](SECURITY.md).
