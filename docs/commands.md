# Command reference — cpsm 0.1.1

First supported public Capsomnia version: 4.0.0.
`cpsm [--json] [--app PATH] <command>` accepts flags before or after the command.

| Command | Effect |
| --- | --- |
| `status` | Read app path/version, Caps Lock, sleep prevention and timer state |
| `doctor` | Read app/helper/LaunchAgent/control diagnostics |
| `on` | Enable awake mode |
| `off` | Disable awake mode, verify release, then request Mac sleep |
| `toggle` | Switch state; targeting off requests sleep |
| `timer set 2h` | Turn on and replace the timer for this session |
| `timer status` | Read current timer |
| `timer restart` | Restart active countdown; error if no timer is active |
| `timer cancel` | Cancel countdown; leave current awake state unchanged |
| `settings get [key]` | Read all settings or one setting |
| `settings set <key> <value>` | Change a saved setting |
| `help`, `--help` | Help without app startup |
| `version`, `--version` | CLI version without app startup |

Durations use `s`, `m` or `h`, such as `90s`, `30m`, `2h`. Numeric amount must
be at least 1 and the total cannot exceed 24 hours. A one-shot timer leaves the
saved default unchanged. Cancel and one-shot overrides end at the next OFF→ON
transition or app quit. Changing the saved default while a one-shot timer is
active does not replace that one-shot timer.

## Saved settings

| Key | Values |
| --- | --- |
| `dedicated-caps-lock-mode` | `true` / `false` (also `on` / `off`) |
| `show-menu-bar-icon` | boolean |
| `launch-at-login` | boolean |
| `keep-display-awake` | boolean |
| `ignore-external-caps-lock-off-while-lid-closed` | boolean |
| `automatic-update-checks` | boolean |
| `language` | `en`, `ja`, `ko`, `zh-Hans` |
| `auto-off-minutes` | integer 0–1440; 0 disables saved default |
| `shortcut` | read-only; configure in GUI |

Dedicated Caps Lock mode requires the app's Accessibility permission. The CLI
does not bypass macOS permissions.

## JSON and exit status

Responses have shape `{"ok":true,"result":...}` or `{"ok":false,"error":"..."}`.
Result fields depend on the command. Optional fields may be absent or null;
missing observations are not false. Use the process exit status as well as `ok`.

- `0`: successful response, help or version.
- `1`: rejected app operation, transport failure or other execution error.
- `2`: invalid arguments, missing/invalid app bundle or app launch failure.

`sleep_requested: true` means macOS accepted the request, not proof of completed
sleep. After a timeout/disconnection, query `status` before deciding whether to
retry. A mutation may already have taken effect. The CLI only retries connection
failures before sending; it never replays a request after a write/response error.

## Local protocol

CapsomniaControl uses a same-user Unix socket, not a network listener. Its
directory is mode 0700, socket mode 0600; both peers check the effective UID.
The endpoint is derived from the app bundle ID in the user's Caches directory.
Messages are newline-delimited JSON, limited to 64 KiB. Protocol v1 requests
contain `version: 1` and an `arguments` array. Unsupported versions are rejected.

Compatible additive fields do not require coordinated releases. Breaking wire
changes need a protocol version change and app/CLI updates. Capsomnia's vendored
snapshot records the exact library source used by each app candidate.
