#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEST_ROOT="$(mktemp -d)"
readonly PACKAGE_ROOT="$TEST_ROOT/omarewind"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p -- "$PACKAGE_ROOT"
git -C "$PROJECT_ROOT" archive --format=tar HEAD | tar -xf - -C "$PACKAGE_ROOT"

jq -e '.schemaVersion == 1 and .id == "com.omarchy.omarewind" and (.kinds | index("bar-widget"))' \
  "$PACKAGE_ROOT/manifest.json" >/dev/null

while IFS= read -r entry_point; do
  [[ -f "$PACKAGE_ROOT/$entry_point" ]] || {
    printf 'missing packaged entry point: %s\n' "$entry_point" >&2
    exit 1
  }
done < <(jq -r '.entryPoints[]' "$PACKAGE_ROOT/manifest.json")

[[ -x "$PACKAGE_ROOT/bin/omarewind" ]]
[[ "$(git -C "$PROJECT_ROOT" ls-tree HEAD bin/omarewind | awk '{print $1}')" == "100755" ]]
[[ "$($PACKAGE_ROOT/bin/omarewind version)" == "$(jq -r '.version' "$PACKAGE_ROOT/manifest.json")" ]]

if find "$PACKAGE_ROOT" -type f -size +1M -print -quit | grep -q .; then
  printf 'package unexpectedly contains a file larger than 1 MiB\n' >&2
  find "$PACKAGE_ROOT" -type f -size +1M -printf '%p\t%s bytes\n' >&2
  exit 1
fi

if rg -n 'TODO|FIXME|github\.com/<|example\.com' "$PACKAGE_ROOT" \
  -g '!test/package-test.sh' >/dev/null; then
  printf 'package contains unfinished placeholder text\n' >&2
  exit 1
fi

omarchy plugin validate "$PACKAGE_ROOT"
bash -n "$PACKAGE_ROOT/bin/omarewind" "$PACKAGE_ROOT/test/"*.sh "$PACKAGE_ROOT/test/all"
"$PACKAGE_ROOT/test/backend-test.sh"

printf 'package-test: ok (%s KiB)\n' "$(( $(du -sk "$PACKAGE_ROOT" | cut -f1) ))"
