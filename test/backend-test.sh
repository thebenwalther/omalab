#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly COMMAND="$PROJECT_ROOT/bin/omarewind"
readonly TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

export HOME="$TEST_ROOT/home"
export OMAREWIND_STATE_HOME="$TEST_ROOT/state"
export FAKE_PACKAGES_FILE="$TEST_ROOT/packages"
export FAKE_PLUGINS_FILE="$TEST_ROOT/plugins.json"
export FAKE_THEME_LOG="$TEST_ROOT/theme.log"
export PATH="$TEST_ROOT/bin:$PATH"

mkdir -p "$HOME/.config/hypr" \
  "$HOME/.config/omarchy/plugins/com.omarchy.omarewind" \
  "$HOME/.config/ghostty" \
  "$TEST_ROOT/bin"

printf 'original binding\n' >"$HOME/.config/hypr/bindings.lua"
printf 'original terminal\n' >"$HOME/.config/ghostty/config"
printf 'plugin version one\n' >"$HOME/.config/omarchy/plugins/com.omarchy.omarewind/BarWidget.qml"
printf 'base-package\n' >"$FAKE_PACKAGES_FILE"
printf '%s\n' '[{"id":"omarchy.clock","enabled":true}]' >"$FAKE_PLUGINS_FILE"

cat >"$TEST_ROOT/bin/pacman" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Qqe" ]]; then cat "$FAKE_PACKAGES_FILE"; else exit 1; fi
EOF

cat >"$TEST_ROOT/bin/omarchy" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "theme" && "${2:-}" == "current" ]]; then
  printf 'Tokyo Night\n'
elif [[ "${1:-}" == "theme" && "${2:-}" == "set" ]]; then
  printf '%s\n' "${3:-}" >>"$FAKE_THEME_LOG"
elif [[ "${1:-}" == "plugin" && "${2:-}" == "list" ]]; then
  cat "$FAKE_PLUGINS_FILE"
elif [[ "${1:-}" == "shell" ]]; then
  exit 0
else
  exit 0
fi
EOF

cat >"$TEST_ROOT/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat >"$TEST_ROOT/bin/omarchy-notification-send" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$TEST_ROOT/bin/"*

assert_json() {
  local json="$1" expression="$2"
  jq -e "$expression" >/dev/null <<<"$json" || {
    printf 'JSON assertion failed: %s\n%s\n' "$expression" "$json" >&2
    exit 1
  }
}

status="$($COMMAND start 'Test experiment')"
assert_json "$status" '.active == true and .label == "Test experiment" and .totalChanges == 0'

printf 'changed binding\n' >"$HOME/.config/hypr/bindings.lua"
printf 'new setting\n' >"$HOME/.config/hypr/new.lua"
rm -- "$HOME/.config/ghostty/config"
printf 'plugin version two\n' >"$HOME/.config/omarchy/plugins/com.omarchy.omarewind/BarWidget.qml"
printf 'base-package\nnew-package\n' >"$FAKE_PACKAGES_FILE"
printf '%s\n' '[{"id":"omarchy.clock","enabled":true},{"id":"community.test","enabled":true}]' >"$FAKE_PLUGINS_FILE"

# Omarchy's graphical shell can run plugins under a UTF-8 locale even when a
# login shell uses C ordering. The backend must remain deterministic in both.
status="$(LC_ALL=en_US.UTF-8 "$COMMAND" status)"
assert_json "$status" '.active == true'
assert_json "$status" '.files.added == 1 and .files.modified == 1 and .files.deleted == 1'
assert_json "$status" '.packages.added == 1 and .plugins.added == 1 and .totalChanges == 5'

if "$COMMAND" rewind >/dev/null 2>&1; then
  printf 'rewind unexpectedly succeeded without --yes\n' >&2
  exit 1
fi

status="$($COMMAND rewind --yes)"
assert_json "$status" '.active == false and .historyCount == 1'
grep -qx 'original binding' "$HOME/.config/hypr/bindings.lua"
grep -qx 'original terminal' "$HOME/.config/ghostty/config"
grep -qx 'plugin version two' "$HOME/.config/omarchy/plugins/com.omarchy.omarewind/BarWidget.qml"
[[ ! -e "$HOME/.config/hypr/new.lua" ]]

history="$($COMMAND history)"
assert_json "$history" 'length == 1 and .[0].outcome == "rewound"'

$COMMAND start 'Keep test' >/dev/null
printf 'kept binding\n' >"$HOME/.config/hypr/bindings.lua"
status="$($COMMAND keep --yes)"
assert_json "$status" '.active == false and .historyCount == 2'
grep -qx 'kept binding' "$HOME/.config/hypr/bindings.lua"

doctor="$($COMMAND doctor)"
assert_json "$doctor" '.ok == true and .pluginId == "com.omarchy.omarewind"'

printf 'backend-test: ok\n'
