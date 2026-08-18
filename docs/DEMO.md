# OmaRewind prize demo

The strongest demo is a visible theme experiment: the desktop changes, the
panel explains exactly what changed, rewind restores the original look, and
undo brings the experiment back. The complete story fits in about 75 seconds.

## Before recording

1. Run `test/all` and confirm `bin/omarewind doctor` reports `"ok": true`.
2. Close personal apps and clear notifications. Use a clean workspace with one
   terminal and the Omarchy menu.
3. Choose two visually distinct installed themes. Record their names so the
   sequence is deterministic.
4. Finish any existing Fearless Mode session before the take.
5. Start a fullscreen recording with `omarchy screenrecord --fullscreen`.

Never open a diff containing credentials, machine names, or private paths. A
theme or bar-layout change is ideal because it is visual and privacy-safe.

## 75-second sequence

| Time | Action | Narration |
| --- | --- | --- |
| 0–7s | Show the original desktop, then point to OmaRewind in the bar. | “Trying a new Linux setup is fun—until you wonder whether you can get back.” |
| 7–17s | Open OmaRewind, name the experiment `Trying a new rice`, and start Fearless Mode. | “OmaRewind checkpoints the desktop configuration without root.” |
| 17–30s | Open Omarchy’s theme picker and switch to the contrasting theme. Let the desktop visibly transform. | “Now I can experiment without keeping a mental list of every file that changed.” |
| 30–44s | Reopen OmaRewind. Show the live badge, file count, and a safe changed-file diff. | “It tracks config, plugins, and packages, and every file row has a bounded preview.” |
| 44–57s | Click **Rewind Configs**, then click the armed confirmation. Pause on the original theme returning. | “One deliberate rewind restores the verified checkpoint.” |
| 57–69s | Open OmaRewind and use **Undo Last Rewind** with its confirmation. Pause on the experimental theme returning. | “Even the rewind is reversible—the experiment was preserved first.” |
| 69–75s | End on the `FEARLESS` badge and project name. | “OmaRewind: Fearless Mode for Omarchy.” |

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
