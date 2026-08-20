# Changelog

## 1.0.0

- Rename the project to **OmaLab** and make Fearless Mode the primary product
  identity: a safe laboratory for Omarchy experiments.
- Move to the permanent plugin ID `io.github.thebenwalther.omalab`, the
  `bin/omalab` command, and the owner-only `~/.local/state/omalab/` state root.
- Refresh every project image and rebuild the narrated demo and promo loop for
  the OmaLab launch.
- Publish the first contest-ready stable release.

## 0.3.3

- Record the original `~/.config` root and safely realign it before restore so
  a replaced ancestor symlink cannot retarget `rsync --delete` or `rm -rf`.
  Existing checkpoint-time `.config` symlinks are preserved, while a
  replacement real directory fails closed instead of being deleted wholesale.
- Reject FIFOs, devices, and unexpected empty directories in snapshot verify.
- Fail closed when configuration inventory cannot be read.
- Keep last-good UI state when status JSON is malformed.
- Reset the Fearless badge opacity after the idle pulse stops.
- Describe rewind as restoring the entire checkpoint, not only listed rows.

## 0.3.2

- Anchor the panel to its bar icon so OmaLab opens consistently with other
  Omarchy plugins instead of appearing in the center of the screen.
- Adapt panel highlights, live metrics, action states, change types, history,
  and the active bar badge to the current Omarchy theme's accent colors.
- Add a narrated, soundtracked one-minute product demo and a short promo loop
  for the public project page and contest submission.
- Exclude repository-hosted demo videos from packaged plugin archives so
  installs remain lightweight.

## 0.3.1

- Make the idle panel's three-step checkpoint, experiment, and rewind flow
  explicit before users begin.
- Install the complete Qt QML runtime required by the presentation-model tests
  on GitHub Actions.
- Pin the current Node 24 checkout action by commit for reproducible CI.

## 0.3.0

- Preserve every experiment before rewind and support Undo Last Rewind.
- Add user-named experiments and recent-history presentation.
- Show the three newest experiments in the idle panel instead of hiding the
  archive behind a single last-session card.
- Add bounded, path-validated unified diff previews for changed files.
- Make history reads corruption-tolerant and audit every archived safety layer
  through `doctor`.
- Verify snapshot integrity before restore.
- Prevent top-level config symlink traversal during `rsync --delete`.
- Serialize state access with shared and exclusive file locks.
- Clean failed and abandoned temporary operations.
- Make all comparisons locale-independent.
- Batch manifest hashing and remove a redundant integrity pass, cutting active
  status-scan time by roughly 72% on the development checkpoint.
- Preserve spaces and literal backslashes in valid configuration filenames.
- Enforce strict ShellCheck analysis across the backend and test harness in CI.
- Unit-test QML status parsing and presentation formatting under Qt itself.
- Correct the one-minute elapsed label to use singular grammar.
- Fix live diff cards being collapsed by a collision with QML's built-in
  `Item.data` property.
- Preserve last-good UI state and surface backend failures prominently.
- Move keep and rewind controls above the scrollable change list.

## 0.1.0

- Initial Fearless Mode checkpoint, live change tracking, keep, rewind,
  history, package/plugin observation, theme restore, and Omarchy bar panel.
