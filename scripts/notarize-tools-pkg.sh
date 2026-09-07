#!/bin/zsh
# Deliberate manual release step: uploads the signed Tools package to Apple.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(/usr/bin/tr -d '\r\n' < "$ROOT_DIR/VERSION")"
DIST_DIR="${DIST_DIR:-${1:-$ROOT_DIR/dist}}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to an existing notarytool keychain profile}"
VERSIONED_PKG="$DIST_DIR/Capsomnia-Tools-$VERSION.pkg"
/usr/sbin/pkgutil --check-signature "$VERSIONED_PKG"
xcrun notarytool submit "$VERSIONED_PKG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$VERSIONED_PKG"
xcrun stapler validate "$VERSIONED_PKG"
/usr/sbin/spctl --assess --type install --verbose=2 "$VERSIONED_PKG"
/usr/bin/install -m 0644 "$VERSIONED_PKG" "$DIST_DIR/Capsomnia-Tools.pkg"
(cd "$DIST_DIR" && /usr/bin/shasum -a 256 "Capsomnia-Tools-$VERSION.pkg" Capsomnia-Tools.pkg > Tools-SHA256SUMS.txt)
echo "Tools notarization complete. Artifacts have not been published."
