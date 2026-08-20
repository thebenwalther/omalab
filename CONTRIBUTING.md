# Contributing to OmaLab

OmaLab changes user configuration, so a contribution is complete only when
its failure path is as deliberate as its success path.

## Local checks

Run the complete suite on Omarchy 4:

```bash
test/all
```

The backend tests use a temporary fake home and never touch the live desktop.
They should cover the normal case, malformed state, interruption or
concurrency where relevant, and the exact safety invariant affected by a
change.

For UI changes, also install the repository through the development symlink,
test top/bottom and vertical bar positions, exercise keyboard and pointer
flows, and capture both idle and active panel states.

## Design rules

- Keep `bin/omalab` as the source of truth. QML renders its JSON and invokes
  its commands; it does not implement a second restore engine.
- Never add a restore target without an explicit allowlist entry and an
  isolated round-trip test.
- Never follow a changed symlink during deletion or restore.
- Never turn a failed status probe into an inactive result.
- Never add network access, telemetry, or privilege escalation to the default
  flow.
- Require explicit confirmation for operations that overwrite configuration.

Use the Omarchy UI kit and theme colors rather than fixed colors or dimensions.
Keep the panel fully usable from the keyboard.
