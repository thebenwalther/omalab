# OmaRewind

**Fearless Mode for Omarchy.** Capture your desktop configuration, experiment
freely, then keep the result or rewind to exactly where you started.

OmaRewind is an Omarchy 4 bar plugin built for the moment before you install a
wild theme, replace your keybindings, or try an unfamiliar plugin and think:
*I hope I can get back from this.*

## What the MVP does

- Creates a local checkpoint of Omarchy, Hyprland, supported terminal, and
  common shell-tool configuration without requiring root.
- Watches the experiment and reports added, changed, and removed files.
- Tracks explicit package and enabled-plugin changes.
- Restores checkpointed configuration after an explicit two-step confirmation.
- Restores the starting Omarchy theme when it changed.
- Preserves OmaRewind's own installed plugin directory during a rewind.
- Archives kept and rewound experiments under
  `~/.local/state/omarewind/history/`.
- Opens Omarchy's official `omarchy snapshot create` flow for an optional root
  snapshot before package or kernel experiments.

Package changes are **reported but never automatically installed or removed**
in version 0.1. A configuration rewind is predictable; silently changing the
system package set is not.

## The experience

When idle, OmaRewind is a small history icon in the bar. Start Fearless Mode
and it becomes a live badge:

```text
FEARLESS · 7
```

The panel separates file, package, and plugin changes, shows recent modified
paths, and offers two intentional exits:

- **Keep Changes** archives the checkpoint and leaves the experiment in place.
- **Rewind Configs** restores the checkpoint and archives a record of what was
  rewound.

Both actions require a second click within five seconds. The same flow is fully
keyboard accessible with `S`, `K`, `R`, and `Esc`.

## Development install

The repository root is the plugin root. Link it into the user plugin directory
so QML changes hot-reload while developing:

```bash
ln -s "$HOME/Work/omarewind" \
  "$HOME/.config/omarchy/plugins/com.omarchy.omarewind"
omarchy shell shell rescanPlugins
omarchy plugin enable com.omarchy.omarewind --section right
```

Remove the development link with:

```bash
omarchy plugin disable com.omarchy.omarewind
rm "$HOME/.config/omarchy/plugins/com.omarchy.omarewind"
omarchy shell shell rescanPlugins
```

No user configuration is modified merely by cloning this repository or running
the tests.

## Command-line interface

The QML interface uses the same auditable command available to users:

```bash
bin/omarewind start "Trying a new rice"
bin/omarewind status
bin/omarewind keep --yes
bin/omarewind rewind --yes
bin/omarewind history
bin/omarewind doctor
```

`status` is stable JSON so the bar, tests, and future integrations all observe
the same state.

## Protected configuration

Version 0.1 checkpoints these targets when they exist:

- `~/.config/hypr/`
- `~/.config/omarchy/`
- Alacritty, Foot, Kitty, and Ghostty configuration
- Starship, Fastfetch, btop, Lazygit, and Git configuration

Git metadata is excluded. OmaRewind's own plugin directory is also excluded
from both checkpoint and deletion passes, preventing the restore engine from
replacing itself while it is running.

This is a local configuration safety net, **not a backup of personal files**.
Documents, projects, photos, and other user data are intentionally out of
scope. Root snapshots are delegated to Omarchy's existing Snapper integration.

## Safety model

- Restore targets are a fixed allowlist below `~/.config/`.
- The backend refuses a rewind without `--yes`.
- The UI requires a second confirmation within five seconds.
- No network access, telemetry, root daemon, or credential storage.
- Package changes are observational in the MVP.
- Checkpoint creation is atomic: an incomplete checkpoint never becomes active.
- Rewinds are archived rather than silently discarded.

## Test

```bash
test/all
```

The test suite uses an isolated fake home directory. It verifies change
detection, confirmation enforcement, restoration, history, self-preservation,
manifest validity, shell syntax, and QML linting without touching the live
desktop configuration.

## Roadmap

- A visual experiment timeline and named checkpoints.
- Selective per-file rewind with a readable diff preview.
- Package reconciliation plans that open in a terminal for explicit review.
- Snapper checkpoint detection and pairing without maintaining a privileged
  daemon.
- Disk-usage and snapshot-health warnings.
- Exportable, privacy-safe experiment reports for support requests.

## License

MIT
