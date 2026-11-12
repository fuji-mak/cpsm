#!/bin/zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap '/bin/rm -rf "$WORK_DIR"' EXIT
mkdir -p "$WORK_DIR/cpsm/components" "$WORK_DIR/macready/components"
printf '0.2.0\n' > "$WORK_DIR/macready/VERSION"
CPSM_VERSION="$(cat "$ROOT_DIR/VERSION")"
make_component() {
  local tool="$1" component="$2" identifier="$3" version="$4"
  /usr/bin/pkgbuild --nopayload --identifier "$identifier" --version "$version" \
    "$WORK_DIR/$tool/components/$tool-$component.pkg" >/dev/null
}
for tool in cpsm macready; do
  version="$CPSM_VERSION"
  [[ "$tool" == macready ]] && version=0.2.0
  make_component "$tool" cli "com.github.fuji-mak.$tool.pkg.cli" "$version"
  make_component "$tool" codex-skill "com.github.fuji-mak.$tool.pkg.codex" "$version"
  make_component "$tool" claude-skill "com.github.fuji-mak.$tool.pkg.claude-code" "$version"
done
assert_rejected() {
  if SKIP_SIGNING=true SKIP_COMPONENT_BUILD=true CPSM_DIST="$WORK_DIR/cpsm" \
    MACREADY_REPO="$WORK_DIR/macready" MACREADY_DIST="$WORK_DIR/macready" \
    DIST_DIR="$WORK_DIR/dist" "$ROOT_DIR/scripts/build-tools-pkg.sh" > "$WORK_DIR/log" 2>&1; then
    echo 'Invalid reused component unexpectedly accepted' >&2
    exit 1
  fi
  /usr/bin/grep -q 'Unexpected component metadata:' "$WORK_DIR/log"
}
make_component macready cli com.github.fuji-mak.macready.pkg.cli 0.1.1
assert_rejected
make_component macready cli com.github.fuji-mak.macready.pkg.cli 0.2.0
make_component macready claude-skill com.example.foreign.pkg 0.2.0
assert_rejected
echo 'Tools component version and identifier rejection tests passed'
