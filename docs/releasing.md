# Release preparation

Release line: **cpsm 0.1.0**, protocol **1**, Capsomnia **4.0.0+**.
The public Capsomnia app may still be on an earlier version; do not advertise
cpsm as compatible with the generally available 3.5.0 app. Local builds do not
publish, install files, or change the Mac's awake state.

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
3. Build the combined Tools installer from this repository after checking out
   `MacReady` alongside `cpsm`:

   ```sh
   SKIP_SIGNING=true ./scripts/build-tools-pkg.sh
   ```

   The script keeps the cpsm standalone output in `cpsm/dist`, writes MacReady's
   standalone output to `../MacReady/dist`, and creates
   `Capsomnia-Tools-0.1.0.pkg`, `Capsomnia-Tools.pkg`, and
   `Tools-SHA256SUMS.txt` in `cpsm/dist`. Set `MACREADY_REPO`, `DIST_DIR`, or
   `MACREADY_DIST` when the sibling checkout or output locations differ. Set
   `SKIP_COMPONENT_BUILD=true` to reuse existing standalone components.
4. Both installers use the same components/receipt identifiers and versions.
   Install the product pkg, not individual components.

Receipt identifiers: `com.github.fuji-mak.cpsm.pkg.cli`, `.pkg.codex`,
`.pkg.claude-code`. The unpublished early local prototype used different
Capsomnia Tools receipts; its files are replaced at the same paths. No receipt
cleanup is needed to use the new package.

## Sign, notarize, and publish

Notarization uploads the signed package to Apple. At this stage, run:

```sh
NOTARY_PROFILE='your-keychain-profile' ./scripts/notarize-pkg.sh dist
```

After signing the combined package, notarize it separately:

```sh
NOTARY_PROFILE='your-keychain-profile' ./scripts/notarize-tools-pkg.sh dist
```

This staples, validates, assesses, and refreshes both Tools package names and
`Tools-SHA256SUMS.txt`. It does not publish the artifacts.

The script submits to Apple, staples and validates the ticket, and refreshes the fixed package and checksums. It
does not publish. When the release artifacts are ready, publish tag `v0.1.0` with
`cpsm.pkg`, `cpsm-0.1.0.pkg`, `SHA256SUMS.txt`,
`Capsomnia-Tools.pkg`, `Capsomnia-Tools-0.1.0.pkg`, and
`Tools-SHA256SUMS.txt`, then keep the README's release links current. The
repository includes the Skill; no ZIP installer is needed.

Coordinate with the app/Tools release before announcing downloads. Include
links to the author, Capsomnia and MacReady in the description and release notes.

Capsomnia downloads the combined package from this repository's
`releases/latest/download/Capsomnia-Tools.pkg` URL. Include that asset in each
release and verify compatibility with Capsomnia 4.0.0+. The generally available
Capsomnia 3.5.0 app has no CLI service; its compatible app release is being
prepared. Tools updates can then be published without rebuilding the app.
