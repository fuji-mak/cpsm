# Release preparation

Candidate: **cpsm 0.1.0**, protocol **1**, Capsomnia **4.0.0+**.
Publication awaits the author's review. Local builds do not publish, install
files, or change the Mac's awake state.

## Local verification

```sh
swift test
SKIP_SIGNING=true ./scripts/build-pkg.sh
```

Review `dist/cpsm.pkg`, `dist/components/`, READMEs and Skill. The package builds arm64
and x86_64 slices. Unsigned packages are for local testing. For Developer ID
signed candidates, run `./scripts/build-pkg.sh` without `SKIP_SIGNING=true`.
`APP_SIGN_ID` and `PKG_SIGN_ID` select certificates. This still does not notarize
or publish. `dist/bin/cpsm` is the signed CLI for read-only checks.

Verify help/version and status against the matching app. Do not use off/toggle
or short timers during a running job: these can sleep the Mac.

## Coordinate with Capsomnia

1. Keep `VERSION` and `CapsomniaCLICommand.version` consistent.
2. Refresh Capsomnia's vendored library with `scripts/sync-vendor.py` when
   CapsomniaControl changes (run it from the Capsomnia repository), then run the app tests.
3. Capsomnia's `scripts/prepare-distribution.sh` builds the app, both standalone
   tools, and the combined Tools installer from sibling checkouts.
4. Both installers use the same components/receipt identifiers and versions.
   Install the product pkg, not individual components.

Receipt identifiers: `com.github.fuji-mak.cpsm.pkg.cli`, `.pkg.codex`,
`.pkg.claude-code`. The unpublished early local prototype used different
Capsomnia Tools receipts; its files are replaced at the same paths. No receipt
cleanup is needed to use the new package.

## After the author approves publication

Notarization uploads the signed package to Apple. At this stage, run:

```sh
NOTARY_PROFILE='your-keychain-profile' ./scripts/notarize-pkg.sh dist
```

The script submits to Apple, staples and validates the ticket, and refreshes the fixed package and checksums. It
does not publish. The existing `fuji-mak/cpsm` repository is private during review.
After the author approves public access, change its visibility and publish tag `v0.1.0` with
`cpsm.pkg`, `cpsm-0.1.0.pkg`, `SHA256SUMS.txt`, and update the README's candidate
notice. The repository includes the Skill; no ZIP installer is needed.

Coordinate with the app/Tools release before announcing downloads. Include
links to the author, Capsomnia and MacReady in the description and release notes.
