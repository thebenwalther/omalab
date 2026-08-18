# Changelog

## 0.3.0

- Preserve every experiment before rewind and support Undo Last Rewind.
- Add user-named experiments and recent-history presentation.
- Verify snapshot integrity before restore.
- Prevent top-level config symlink traversal during `rsync --delete`.
- Serialize state access with shared and exclusive file locks.
- Clean failed and abandoned temporary operations.
- Make all comparisons locale-independent.
- Preserve last-good UI state and surface backend failures prominently.
- Move keep and rewind controls above the scrollable change list.

## 0.1.0

- Initial Fearless Mode checkpoint, live change tracking, keep, rewind,
  history, package/plugin observation, theme restore, and Omarchy bar panel.
