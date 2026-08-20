# OmaLab architecture

OmaLab has one source of truth: `bin/omalab`. The QML bar widget and panel
invoke that command and render its JSON. They do not maintain an independent
checkpoint model.

## Components

- `BarWidget.qml` owns polling, last-good state, bar presentation, and plugin
  IPC.
- `Panel.qml` owns interaction, two-step confirmation, keyboard access, and
  action error presentation.
- `Model.js` contains pure formatting and JSON fallback helpers.
- `bin/omalab` owns capture, comparison, validation, restore, locking,
  history, notifications, and desktop reload.

The shell polls every five seconds while Fearless Mode is active and every
thirty seconds while idle. Manifest construction validates paths first, then
hashes regular files in bounded batches instead of launching one checksum
process per file. On the development machine, a warm status scan over a
66-file, 308 KiB checkpoint averages about 162 ms. Scans never retain a
background watcher or daemon.

Diff previews are generated only on demand. The backend accepts only a path in
the active computed change set, refuses traversal, does not render binary files
or files over 256 KiB, and limits output to 36 lines and 16 KiB before
returning JSON.

## State layout

```text
~/.local/state/omalab/
├── .lock
├── active/
│   ├── meta.json
│   ├── config-root.tsv
│   ├── directories.tsv
│   ├── targets.tsv
│   ├── manifest.tsv
│   ├── packages.txt
│   ├── plugins.txt
│   └── snapshot/.config/...
└── history/<id>-<outcome>/
    ├── ...original checkpoint...
    ├── experiment/       # captured immediately before rewind
    └── before-undo/      # captured immediately before undo
```

An exclusive lock guards start, keep, rewind, and undo. Status and history use
a shared lock. Mutating operations also remove abandoned pre-lock temporary
directories from older or interrupted versions.

## Restore flow

```text
confirm → exclusive lock → verify baseline → capture experiment →
verify experiment → align ~/.config to the checkpointed root →
restore theme → restore allowlisted targets →
reload Hyprland/shell → archive → publish inactive JSON
```

Undo follows the same structure, using `experiment/` as its restore source and
capturing `before-undo/` first.

Git metadata and OmaLab's own installed directory are excluded. This keeps
plugin repositories small in state and prevents the running restore engine
from replacing itself.
