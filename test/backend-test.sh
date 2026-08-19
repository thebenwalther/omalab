#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_ROOT
readonly COMMAND="$PROJECT_ROOT/bin/omarewind"
TEST_ROOT="$(mktemp -d)"
readonly TEST_ROOT

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

export HOME="$TEST_ROOT/home"
export OMAREWIND_STATE_HOME="$TEST_ROOT/state"
export FAKE_PACKAGES_FILE="$TEST_ROOT/packages"
export FAKE_PLUGINS_FILE="$TEST_ROOT/plugins.json"
export FAKE_THEME_LOG="$TEST_ROOT/theme.log"
export FAIL_RSYNC_FILE="$TEST_ROOT/fail-restore-rsync"
export FAKE_SHA_LOG="$TEST_ROOT/sha256sum.log"
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
for fixture_number in {1..40}; do
  printf 'fixture %s\n' "$fixture_number" >"$HOME/.config/hypr/fixture-$fixture_number.lua"
done

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

cat >"$TEST_ROOT/bin/rsync" <<'EOF'
#!/usr/bin/env bash
last=''
for argument in "$@"; do last="$argument"; done
if [[ -e "$FAIL_RSYNC_FILE" && "$last" == "$HOME/.config/"* ]]; then
  exit 42
fi
exec /usr/bin/rsync "$@"
EOF

cat >"$TEST_ROOT/bin/sha256sum" <<'EOF'
#!/usr/bin/env bash
printf '.\n' >>"$FAKE_SHA_LOG"
exec /usr/bin/sha256sum "$@"
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
# Start performs four full-tree hashes (capture, verification, status
# verification, and live diff), regardless of how many files are tracked.
[[ "$(wc -l <"$FAKE_SHA_LOG")" -le 4 ]]
: >"$FAKE_SHA_LOG"

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
[[ "$(wc -l <"$FAKE_SHA_LOG")" -le 2 ]]

preview="$($COMMAND preview '.config/hypr/bindings.lua')"
assert_json "$preview" '.kind == "modified" and (.text | contains("-original binding")) and (.text | contains("+changed binding"))'
preview="$($COMMAND preview '.config/hypr/new.lua')"
assert_json "$preview" '.kind == "added" and (.text | contains("+new setting"))'
if "$COMMAND" preview '.config/hypr/not-changed.lua' >/dev/null 2>&1; then
  printf 'preview unexpectedly accepted a path outside the change set\n' >&2
  exit 1
fi
if "$COMMAND" preview '../../etc/passwd' >/dev/null 2>&1; then
  printf 'preview unexpectedly accepted a path traversal\n' >&2
  exit 1
fi
printf '\0binary\n' >"$HOME/.config/hypr/binary.lua"
preview="$($COMMAND preview '.config/hypr/binary.lua')"
assert_json "$preview" '.kind == "added" and .binary == true'
rm -- "$HOME/.config/hypr/binary.lua"
printf '\377invalid utf8\n' >"$HOME/.config/hypr/non-utf8.lua"
preview="$($COMMAND preview '.config/hypr/non-utf8.lua')"
assert_json "$preview" '.kind == "added" and .binary == true'
rm -- "$HOME/.config/hypr/non-utf8.lua"
awk 'BEGIN { for (i = 0; i < 20000; i++) printf "x"; printf "\n" }' >"$HOME/.config/hypr/long-line.lua"
preview="$($COMMAND preview '.config/hypr/long-line.lua')"
assert_json "$preview" '.kind == "added" and .truncated == true and (.text | length) <= 16384'
rm -- "$HOME/.config/hypr/long-line.lua"

if "$COMMAND" rewind >/dev/null 2>&1; then
  printf 'rewind unexpectedly succeeded without --yes\n' >&2
  exit 1
fi

status="$($COMMAND rewind --yes)"
assert_json "$status" '.active == false and .historyCount == 1 and .canUndo == true and (.recentHistory | length) == 1 and .recentHistory[0].outcome == "rewound"'
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

# Replacing a tracked directory with a symlink must never make rsync follow the
# link and delete files outside ~/.config during a rewind.
$COMMAND start 'Symlink safety test' >/dev/null
mkdir -p "$TEST_ROOT/outside"
printf 'must survive\n' >"$TEST_ROOT/outside/sentinel"
rm -rf -- "$HOME/.config/hypr"
ln -s "$TEST_ROOT/outside" "$HOME/.config/hypr"
status="$($COMMAND rewind --yes)"
assert_json "$status" '.active == false and .historyCount == 3'
[[ ! -L "$HOME/.config/hypr" ]]
grep -qx 'kept binding' "$HOME/.config/hypr/bindings.lua"
grep -qx 'must survive' "$TEST_ROOT/outside/sentinel"

# A damaged checkpoint must fail closed before touching live configuration.
$COMMAND start 'Integrity test' >/dev/null
printf 'live work\n' >"$HOME/.config/hypr/bindings.lua"
mv "$OMAREWIND_STATE_HOME/active/packages.txt" "$TEST_ROOT/packages.good"
ln -s "$FAKE_PACKAGES_FILE" "$OMAREWIND_STATE_HOME/active/packages.txt"
if "$COMMAND" rewind --yes >/dev/null 2>&1; then
  printf 'rewind unexpectedly accepted symlinked checkpoint metadata\n' >&2
  exit 1
fi
grep -qx 'live work' "$HOME/.config/hypr/bindings.lua"
rm -- "$OMAREWIND_STATE_HOME/active/packages.txt"
mv "$TEST_ROOT/packages.good" "$OMAREWIND_STATE_HOME/active/packages.txt"
printf 'tampered snapshot\n' >"$OMAREWIND_STATE_HOME/active/snapshot/.config/hypr/bindings.lua"
if "$COMMAND" rewind --yes >/dev/null 2>&1; then
  printf 'rewind unexpectedly accepted a damaged checkpoint\n' >&2
  exit 1
fi
grep -qx 'live work' "$HOME/.config/hypr/bindings.lua"
printf 'kept binding\n' >"$OMAREWIND_STATE_HOME/active/snapshot/.config/hypr/bindings.lua"
printf 'injected\n' >"$OMAREWIND_STATE_HOME/active/snapshot/.config/hypr/not-in-manifest.lua"
if "$COMMAND" rewind --yes >/dev/null 2>&1; then
  printf 'rewind unexpectedly accepted an injected snapshot file\n' >&2
  exit 1
fi
grep -qx 'live work' "$HOME/.config/hypr/bindings.lua"
rm -- "$OMAREWIND_STATE_HOME/active/snapshot/.config/hypr/not-in-manifest.lua"
$COMMAND keep --yes >/dev/null

# Failed status probes must clean their private work directory.
$COMMAND start 'Cleanup test' >/dev/null
cp "$OMAREWIND_STATE_HOME/active/manifest.tsv" "$TEST_ROOT/manifest.good"
tac "$TEST_ROOT/manifest.good" >"$OMAREWIND_STATE_HOME/active/manifest.tsv"
if "$COMMAND" status >/dev/null 2>&1; then
  printf 'status unexpectedly accepted an unsorted manifest\n' >&2
  exit 1
fi
[[ "$(find "$OMAREWIND_STATE_HOME" -maxdepth 1 -type d -name '.status.*' | wc -l)" -eq 0 ]]
cp "$TEST_ROOT/manifest.good" "$OMAREWIND_STATE_HOME/active/manifest.tsv"
$COMMAND keep --yes >/dev/null

# Rewind preserves the experiment and supports one deliberate undo.
$COMMAND start 'Undo test' >/dev/null
printf 'rescue this experiment\n' >"$HOME/.config/hypr/bindings.lua"
status="$($COMMAND rewind --yes)"
assert_json "$status" '.active == false and .canUndo == true and .lastSession.outcome == "rewound"'
grep -qx 'live work' "$HOME/.config/hypr/bindings.lua"
if "$COMMAND" undo >/dev/null 2>&1; then
  printf 'undo unexpectedly succeeded without --yes\n' >&2
  exit 1
fi
status="$($COMMAND undo --yes)"
assert_json "$status" '.active == false and .canUndo == false and .lastSession.outcome == "rewind-undone"'
grep -qx 'rescue this experiment' "$HOME/.config/hypr/bindings.lua"

# Competing start requests serialize cleanly and leave one valid checkpoint.
set +e
"$COMMAND" start 'Concurrent A' >"$TEST_ROOT/start-a.out" 2>"$TEST_ROOT/start-a.err" &
pid_a=$!
"$COMMAND" start 'Concurrent B' >"$TEST_ROOT/start-b.out" 2>"$TEST_ROOT/start-b.err" &
pid_b=$!
wait "$pid_a"; code_a=$?
wait "$pid_b"; code_b=$?
set -e
[[ $((code_a + code_b)) -eq 1 ]]
status="$($COMMAND status)"
assert_json "$status" '.active == true and (.label == "Concurrent A" or .label == "Concurrent B")'
$COMMAND keep --yes >/dev/null
[[ "$(stat -c '%a' "$OMAREWIND_STATE_HOME")" == "700" ]]
[[ "$(stat -c '%a' "$OMAREWIND_STATE_HOME/.lock")" == "600" ]]

# A rewind interrupted after its experiment capture resumes from the verified
# safety copy instead of overwriting it or becoming permanently stuck.
$COMMAND start 'Interrupted rewind test' >/dev/null
printf 'interrupted change\n' >"$HOME/.config/hypr/bindings.lua"
: >"$FAIL_RSYNC_FILE"
if "$COMMAND" rewind --yes >/dev/null 2>&1; then
  printf 'rewind unexpectedly survived the forced restore failure\n' >&2
  exit 1
fi
[[ -d "$OMAREWIND_STATE_HOME/active/experiment" ]]
assert_json "$($COMMAND status)" '.active == true'
rm -- "$FAIL_RSYNC_FILE"
status="$($COMMAND rewind --yes)"
assert_json "$status" '.active == false and .canUndo == true'
grep -qx 'rescue this experiment' "$HOME/.config/hypr/bindings.lua"
: >"$FAIL_RSYNC_FILE"
if "$COMMAND" undo --yes >/dev/null 2>&1; then
  printf 'undo unexpectedly survived the forced restore failure\n' >&2
  exit 1
fi
latest_history="$(find "$OMAREWIND_STATE_HOME/history" -mindepth 1 -maxdepth 1 -type d -print | sort -r | head -n 1)"
[[ -d "$latest_history/before-undo" ]]
rm -- "$FAIL_RSYNC_FILE"
status="$($COMMAND undo --yes)"
assert_json "$status" '.active == false and .canUndo == false and .lastSession.outcome == "rewind-undone"'
grep -qx 'interrupted change' "$HOME/.config/hypr/bindings.lua"

# Metadata cannot turn an archive destination into a path traversal.
$COMMAND start 'Metadata safety test' >/dev/null
printf 'metadata live work\n' >"$HOME/.config/hypr/bindings.lua"
cp "$OMAREWIND_STATE_HOME/active/meta.json" "$TEST_ROOT/meta.good"
jq '.id = "../../escape"' "$TEST_ROOT/meta.good" >"$OMAREWIND_STATE_HOME/active/meta.json"
if "$COMMAND" keep --yes >/dev/null 2>&1; then
  printf 'keep unexpectedly accepted a hostile checkpoint id\n' >&2
  exit 1
fi
[[ ! -e "$TEST_ROOT/escape-kept" ]]
grep -qx 'metadata live work' "$HOME/.config/hypr/bindings.lua"
cp "$TEST_ROOT/meta.good" "$OMAREWIND_STATE_HOME/active/meta.json"
$COMMAND keep --yes >/dev/null

# State control files themselves may not be symlinks.
printf 'lock sentinel\n' >"$TEST_ROOT/lock-sentinel"
mv "$OMAREWIND_STATE_HOME/.lock" "$TEST_ROOT/real-lock"
ln -s "$TEST_ROOT/lock-sentinel" "$OMAREWIND_STATE_HOME/.lock"
if "$COMMAND" status >/dev/null 2>&1; then
  printf 'status unexpectedly followed a symlinked lock file\n' >&2
  exit 1
fi
grep -qx 'lock sentinel' "$TEST_ROOT/lock-sentinel"
rm -- "$OMAREWIND_STATE_HOME/.lock"
mv "$TEST_ROOT/real-lock" "$OMAREWIND_STATE_HOME/.lock"

mkdir -p "$TEST_ROOT/fake-active"
ln -s "$TEST_ROOT/fake-active" "$OMAREWIND_STATE_HOME/active"
if "$COMMAND" status >/dev/null 2>&1; then
  printf 'status unexpectedly followed a symlinked active checkpoint\n' >&2
  exit 1
fi
rm -- "$OMAREWIND_STATE_HOME/active"

if "$COMMAND" start $'unsafe\nlabel' >/dev/null 2>&1; then
  printf 'start unexpectedly accepted a multiline label\n' >&2
  exit 1
fi
[[ ! -d "$OMAREWIND_STATE_HOME/active" ]]

# Spaces and backslashes are valid configuration filenames. Batched hashing
# must preserve them byte-for-byte instead of parsing checksum output as text.
printf 'space original\n' >"$HOME/.config/hypr/space name.lua"
printf 'slash original\n' >"$HOME/.config/hypr/back\\slash.lua"
$COMMAND start 'Filename compatibility test' >/dev/null
printf 'space changed\n' >"$HOME/.config/hypr/space name.lua"
printf 'slash changed\n' >"$HOME/.config/hypr/back\\slash.lua"
status="$($COMMAND status)"
assert_json "$status" '([.changes[].path] | index(".config/hypr/space name.lua")) != null'
assert_json "$status" '([.changes[].path] | index(".config/hypr/back\\slash.lua")) != null'
$COMMAND rewind --yes >/dev/null
grep -qx 'space original' "$HOME/.config/hypr/space name.lua"
grep -qx 'slash original' "$HOME/.config/hypr/back\\slash.lua"

status="$($COMMAND status)"
assert_json "$status" '(.recentHistory | length) == 5 and .recentHistory[0].label == "Filename compatibility test"'

# Unsupported path separators fail atomically rather than producing an
# ambiguous TSV checkpoint that could restore the wrong file.
printf 'odd\n' >"$HOME/.config/hypr/has"$'\t'"tab"
if "$COMMAND" start 'Odd filename test' >/dev/null 2>&1; then
  printf 'start unexpectedly accepted a tab in a filename\n' >&2
  exit 1
fi
[[ ! -d "$OMAREWIND_STATE_HOME/active" ]]
[[ "$(find "$OMAREWIND_STATE_HOME" -maxdepth 1 -type d -name '.starting.*' | wc -l)" -eq 0 ]]
rm -- "$HOME/.config/hypr/has"$'\t'"tab"

# Corrupt history is skipped from stable JSON and reported by doctor instead
# of poisoning the last-session model.
corrupt_history="$(find "$OMAREWIND_STATE_HOME/history" -mindepth 1 -maxdepth 1 -type d -print | sort -r | head -n 1)"
cp "$corrupt_history/meta.json" "$TEST_ROOT/history-meta.good"
printf '{broken\n' >"$corrupt_history/meta.json"
assert_json "$($COMMAND history)" 'type == "array"'
doctor="$($COMMAND doctor)"
assert_json "$doctor" '.ok == false and .history.corruptEntries == 1'
cp "$TEST_ROOT/history-meta.good" "$corrupt_history/meta.json"

doctor="$($COMMAND doctor)"
assert_json "$doctor" '.ok == true and .pluginId == "com.omarchy.omarewind" and .version == "0.3.2"'

printf 'backend-test: ok\n'
