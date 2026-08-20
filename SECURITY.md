# OmaLab security model

OmaLab restores configuration, so its safest behavior matters more than its
most convenient behavior. The backend is deliberately a small, auditable Bash
program with no daemon, network client, privilege escalation, or dynamic code
evaluation.

## Trust boundary

OmaLab protects a user from accidental configuration changes made after a
checkpoint. It does not protect against a malicious process already running as
that user. Omarchy plugins run unsandboxed in `omarchy-shell`; any such plugin
can read or change the same configuration and state that OmaLab can.

The state directory defaults to `~/.local/state/omalab`, is created with
owner-only permissions, and may contain copies of the supported configuration
files. Users should protect their home directory and full-disk encryption as
they would for the original files.

OmaLab intentionally does not copy documents, projects, browser profiles,
SSH keys, password stores, or system files. Root-level rollback is delegated to
Omarchy's official Snapper flow.

## Restore invariants

Before changing live configuration, the backend proves all of the following:

1. The checkpoint metadata is valid JSON with the supported format version.
2. The target list is complete, in canonical order, and contains only the
   compiled-in allowlist below `.config/`.
3. Every file and symlink in the snapshot matches its recorded SHA-256 hash or
   link target, and the snapshot contains no FIFOs, devices, or directories
   beyond those recorded at capture time.
4. File paths contain no tab, newline, or parent traversal that could make the
   state format ambiguous.
5. A destructive action holds the exclusive state lock.
6. The live `~/.config` root matches the recorded baseline type and location,
   or is restored to those exact semantics before any target is rewritten.

If any check fails, restore stops before touching live files.

Tracked directories can be replaced by symlinks during an experiment. Restore
unlinks a top-level symlink before invoking `rsync --delete`. Checkpoints also
record whether `~/.config` itself was a directory or a symlink and where it
resolved. Before any target deletion, restore safely realigns the live root to
that baseline or fails closed when automatic alignment could discard untracked
files. It then requires every target — directory, file, link, or missing — to
resolve beneath the recorded root. A swapped `~/.config` symlink cannot
retarget rewind into another tree.

Users who already had `~/.config` symlinked when they created the checkpoint
keep that link. Restore does not blindly replace a live `.config` symlink with
a directory.

## Recovery layers

- Checkpoints are assembled in an owner-only temporary directory, verified,
  and atomically renamed into place.
- Immediately before a rewind, the experiment is captured and verified inside
  the active checkpoint.
- Immediately before undoing a rewind, the current post-rewind configuration
  is captured again.
- Failed status probes preserve the last-good UI state and surface an error.
- Interrupted scans remove their private temporary directories on exit.
- Rewind and undo are resumable from their verified safety copy after an
  interrupted restore.
- Entries whose metadata is invalid are excluded from user-facing history.
  `doctor` audits archived baseline, experiment, and pre-undo snapshot
  integrity and reports corrupt entries. Undo verifies the experiment
  checkpoint before restoring.

Package differences are reported but never reconciled automatically. This
avoids unreviewed package installation or removal and keeps the restore path
unprivileged.

Preview requests are restricted to the active computed change set. Text output
is bounded to 36 lines and 16 KiB, while binary files and files larger than
256 KiB are identified but never rendered into the shell panel.

## Reporting a vulnerability

Report security issues privately through GitHub security advisories at
https://github.com/thebenwalther/omalab/security/advisories/new.
Do not include copied configuration or checkpoint contents in a public report.
