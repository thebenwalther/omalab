# OmaLab prize demo

The strongest demo is a visible theme experiment: the desktop changes, the
panel explains exactly what changed, rewind restores the original look, and
undo brings the experiment back. The complete story fits in one minute.

## Before recording

1. Run `test/all` and confirm `bin/omalab doctor` reports `"ok": true`.
2. Close personal apps and clear notifications. Use a clean workspace with one
   terminal and the Omarchy menu.
3. Choose two visually distinct installed themes. Record their names so the
   sequence is deterministic.
4. Finish any existing Fearless Mode session before the take.
5. Start a fullscreen recording with `omarchy screenrecord --fullscreen`.

Never open a diff containing credentials, machine names, or private paths. A
theme or bar-layout change is ideal because it is visual and privacy-safe.

## One-minute sequence

| Time | Action | Narration |
| --- | --- | --- |
| 0–5s | Open on the OmaLab title card and the active experiment panel. | “Trying a new Linux setup is fun—until you wonder whether you can get back.” |
| 5–14s | Start `Trying a new rice` and show the `FEARLESS` bar badge. | “OmaLab creates a verified checkpoint without root, then watches the experiment live.” |
| 14–25s | Switch to a contrasting Omarchy theme. | “Change the theme, keybindings, plugins, or terminal. Every configuration change stays visible.” |
| 25–37s | Open the panel, metrics, changed-file row, and bounded diff. | “See exactly what moved—including package and plugin changes—before deciding what stays.” |
| 37–48s | Arm **Rewind Configs**, confirm, and show the original theme return. | “One deliberate rewind restores the integrity-checked checkpoint.” |
| 48–55s | Show **Undo Last Rewind** and the experimental theme returning. | “Even the rewind is reversible, because OmaLab preserves the experiment first.” |
| 55–60s | End on the OmaLab launch card and repository URL. | “OmaLab. Fearless Mode for Omarchy.” |

## Capture checklist

- The bar badge changes from idle to `FEARLESS · n`.
- The experiment name is readable.
- At least one file row and its diff appear on screen.
- Both two-click confirmations are visible.
- Rewind visibly restores the original theme.
- Undo visibly restores the experiment.
- The final recording contains no lock screen, passwords, private diffs, or
  notification content.

Stop recording with `omarchy screenrecord --stop-recording`. Keep the raw take,
then make a captioned version and a short silent loop for the repository.
