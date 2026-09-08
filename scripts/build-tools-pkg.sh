#!/bin/zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(/usr/bin/tr -d '\r\n' < "$ROOT_DIR/VERSION")"
[[ "$VERSION" == <->.<->.<-> ]] || { echo "VERSION must be x.y.z" >&2; exit 1; }
DIST_DIR="${DIST_DIR:-${1:-$ROOT_DIR/dist}}"
CPSM_REPO="$ROOT_DIR"
MACREADY_REPO="${MACREADY_REPO:-$ROOT_DIR/../MacReady}"
CPSM_DIST="${CPSM_DIST:-$DIST_DIR}"
MACREADY_DIST="${MACREADY_DIST:-$MACREADY_REPO/dist}"
SKIP_SIGNING="${SKIP_SIGNING:-false}"
PKG_SIGN_ID="${PKG_SIGN_ID:-Developer ID Installer: Taketo Fujimaki (ZJZ8627852)}"
WORK_DIR="$(mktemp -d)"
trap '/bin/rm -rf "$WORK_DIR"' EXIT
export COPYFILE_DISABLE=true
mkdir -p "$DIST_DIR"

# Build standalone installers first. Reuse exactly the same components/receipts
# in the combined installer, so switching between distributions is an upgrade.
if [[ "${SKIP_COMPONENT_BUILD:-false}" != true ]]; then
  SKIP_SIGNING="$SKIP_SIGNING" DIST_DIR="$CPSM_DIST" "$CPSM_REPO/scripts/build-pkg.sh"
  SKIP_SIGNING="$SKIP_SIGNING" DIST_DIR="$MACREADY_DIST" "$MACREADY_REPO/scripts/build-pkg.sh"
fi
CPSM_VERSION="$(cat "$CPSM_REPO/VERSION")"
MACREADY_VERSION="$(cat "$MACREADY_REPO/VERSION")"
for tool in cpsm macready; do
  component_dir="$CPSM_DIST/components"
  [[ "$tool" == macready ]] && component_dir="$MACREADY_DIST/components"
  for component in cli codex-skill claude-skill; do
    file="$component_dir/$tool-$component.pkg"
    [[ -f "$file" ]] || { echo "Missing component: $file" >&2; exit 1; }
    cp "$file" "$WORK_DIR/"
  done
done
cat > "$WORK_DIR/distribution.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <!-- CapsomniaToolsInstallFormat: 2 -->
  <title>Capsomnia Tools</title>
  <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64" />
  <volume-check script="true">
    <allowed-os-versions><os-version min="13.5" /></allowed-os-versions>
  </volume-check>
  <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true" />
  <readme file="README.txt" />
  <choices-outline>
    <line choice="cli" />
    <line choice="shared-skills" />
  </choices-outline>
  <choice id="cli" title="cpsm + MacReady CLI (required)" description="Install cpsm $CPSM_VERSION and macready $MACREADY_VERSION in /usr/local/bin. cpsm requires Capsomnia 4.0 or later." start_selected="true" enabled="false">
    <pkg-ref id="com.github.fuji-mak.cpsm.pkg.cli" />
    <pkg-ref id="com.github.fuji-mak.macready.pkg.cli" />
  </choice>
  <choice id="shared-skills" title="CLI &amp; Skills" description="Install the CLIs and compatible AI Skills." start_selected="true" enabled="false">
    <pkg-ref id="com.github.fuji-mak.cpsm.pkg.codex" />
    <pkg-ref id="com.github.fuji-mak.macready.pkg.codex" />
    <pkg-ref id="com.github.fuji-mak.cpsm.pkg.claude-code" />
    <pkg-ref id="com.github.fuji-mak.macready.pkg.claude-code" />
  </choice>
  <pkg-ref id="com.github.fuji-mak.cpsm.pkg.cli" version="$CPSM_VERSION">cpsm-cli.pkg</pkg-ref>
  <pkg-ref id="com.github.fuji-mak.cpsm.pkg.codex" version="$CPSM_VERSION">cpsm-codex-skill.pkg</pkg-ref>
  <pkg-ref id="com.github.fuji-mak.cpsm.pkg.claude-code" version="$CPSM_VERSION">cpsm-claude-skill.pkg</pkg-ref>
  <pkg-ref id="com.github.fuji-mak.macready.pkg.cli" version="$MACREADY_VERSION">macready-cli.pkg</pkg-ref>
  <pkg-ref id="com.github.fuji-mak.macready.pkg.codex" version="$MACREADY_VERSION">macready-codex-skill.pkg</pkg-ref>
  <pkg-ref id="com.github.fuji-mak.macready.pkg.claude-code" version="$MACREADY_VERSION">macready-claude-skill.pkg</pkg-ref>
</installer-gui-script>
EOF
xmllint --noout "$WORK_DIR/distribution.xml"
UNSIGNED="$WORK_DIR/unsigned.pkg"
productbuild --distribution "$WORK_DIR/distribution.xml" --package-path "$WORK_DIR" \
  --resources "$ROOT_DIR/resources/tools-installer" "$UNSIGNED"
env -u COPYFILE_DISABLE pkgutil --expand-full "$UNSIGNED" "$WORK_DIR/verify"
for tool in cpsm macready; do
  codesign --verify --strict "$WORK_DIR/verify/$tool-cli.pkg/Payload/usr/local/bin/$tool"
done
if [[ "$SKIP_SIGNING" == true ]]; then
  /usr/bin/install -m 0644 "$UNSIGNED" "$DIST_DIR/Capsomnia-Tools-$VERSION.pkg"
else
  productsign --sign "$PKG_SIGN_ID" "$UNSIGNED" "$DIST_DIR/Capsomnia-Tools-$VERSION.pkg"
fi
(cd "$DIST_DIR" && /usr/bin/install -m 0644 "Capsomnia-Tools-$VERSION.pkg" Capsomnia-Tools.pkg && /usr/bin/shasum -a 256 "Capsomnia-Tools-$VERSION.pkg" Capsomnia-Tools.pkg > Tools-SHA256SUMS.txt)
echo "$DIST_DIR/Capsomnia-Tools.pkg"
