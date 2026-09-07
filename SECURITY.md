# Security

Report sensitive issues privately to [the maintainer](https://x.com/tf_makimaki).
Include the app/CLI versions, macOS version and steps to reproduce.

cpsm runs as the signed-in user and talks to Capsomnia over a same-user Unix
socket. It has no network listener or telemetry. Capsomnia performs power
operations through its existing restricted helper; cpsm installs no privileged
helper or sudoers rule. See [Capsomnia's security model](https://github.com/fuji-mak/Capsomnia/blob/main/SECURITY.md).

The optional Skill is instructions, not a background agent. Installers write
Skill files as the console user. Public installers must be Developer ID signed
and notarized by Apple before distribution.
