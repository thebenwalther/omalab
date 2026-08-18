# OmaRewind architecture

OmaRewind has one source of truth: `bin/omarewind`. The QML bar widget and panel
invoke that command and render its JSON. They do not maintain an independent
checkpoint model.

## Components

- `BarWidget.qml` owns polling, last-good state, bar presentation, and plugin
  IPC.
- `Panel.qml` owns interaction, two-step confirmation, keyboard access, and
  action error presentation.
- `Model.js` contains pure formatting and JSON fallback helpers.
- `bin/omarewind` owns capture, comparison, validation, restore, locking,
  history, notifications, and desktop reload.

The shell polls every five seconds while Fearless Mode is active and every
thirty seconds while idle. On a representative 124-file configuration, a warm
status scan completes in roughly a hundredth of a second; scans never retain a
background watcher or daemon.

Diff previews are generated only on demand. The backend accepts only a path in
the active computed change set, refuses traversal, does not render binary files
or files over 256 KiB, and limits output to 36 lines before returning JSON.

## State layout

```text
~/.local/state/omarewind/
├── .lock
├── active/
│   ├── meta.json
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
verify experiment → restore theme → restore allowlisted targets →
reload Hyprland/shell → archive → publish inactive JSON
```

Undo follows the same structure, using `experiment/` as its restore source and
capturing `before-undo/` first.

Git metadata and OmaRewind's own installed directory are excluded. This keeps
plugin repositories small in state and prevents the running restore engine
from replacing itself.
