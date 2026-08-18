# Changelog

## 0.3.0

- Preserve every experiment before rewind and support Undo Last Rewind.
- Add user-named experiments and recent-history presentation.
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
