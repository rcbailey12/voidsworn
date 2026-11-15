# Open work ledger (FINDINGS R194)

Kept by the Board: one row for every open issue and parked pull request, read at every board check. Rewritten Nov 15 2026,
01:20 UTC, by the new Board thread; the Nov 11 ledger is in docs/archive/OPEN_WORK_2026-11-11.md. Status lives in LOOP.md;
this file says what each item waits on, so nothing agreed sits silently.

Verdicts: RUNNING; QUEUED (named run); WAITING ON (the named thing); HELD (pull request sent back, with the brief); STANDING.

## Pull requests

| PR | Issue | Verdict | What it waits on |
|---|---|---|---|
| 701 | 463 small deaths | WAITING ON green CI | Board fixes pushed (fallback, report, scale table merge, destroyer band); Muse opus_check_701b after merge |
| 715 | 538 hits pass 2 | WAITING ON green CI (dispatched) | Board looked at the torpedo linger and fight strips: thrown matter reads; merge before Codex 367 starts |
| 731 | 730 runner hot fix | WAITING ON green CI | merge before Kimi reaches 722 (same files); already hot-copied to the PC |
| 713 | 708 fleet inventory | WAITING ON green CI (dispatched) | Muse delivery, docs only |
| 696 | 688 A20 bow and flanks | QUEUED, next Codex window | conflicts with 691's A20 sheet: resolve the -partial before the run (LOOP); brief in the issue body |
| 700 | 373 station T2 | QUEUED, Codex chain 15A | run 2 brief in the issue body: uniform size to scale.md, every class beside it, sheet only, Refs not Closes |
| 716 | 367 trails and beams | QUEUED, Codex chain 15A | run 1 was CPU only (no GPU go); GPU cleared for the night |
| 717 | 368 nebula and storm | QUEUED, Codex chain 15A | same; -partial merged with main's scale constants |
| 725 | 369 planet and rocks | QUEUED, next Codex window | three textures over 8 MB were refused: ship them under the cap |
| 704 | 41 captured hulls | HELD | Muse NO-GO leg: balance pack missing, the prize Add path bypasses the ripped rule; needs a Kimi run 2 after 371 |
| 705 | 44 finale dawn | HELD | the dawn drew an opaque tan hex sheet; run 2 brief in the issue body (light, not a plane) |

## Issues

| # | Verdict | What it waits on |
|---|---|---|
| 371 shield model | RUNNING (Kimi run 3, resumed from its partial) | if it ends partial again, split the job (rules, then Godot, then balance pack) |
| 372 shield look | WAITING ON 371 | R246 Rim and Gap (comment Nov 15) |
| 720, 721, 729 | RUNNING (DeepSeek lane, one after another) | small jobs from audit 706 and the 644 report |
| 722 runner stamp, disk floor, hashes | QUEUED (Kimi, after 371) | needs 731 merged first |
| 726 Hullbreaker patches bigger and paler | QUEUED, Codex chain 15A (cap 7200 s) | R252 |
| 728 debrief follow-up | QUEUED, next Codex window | opus_check_702 conditions 2, 4, 5 |
| 727 Glasswright species to the Loom | WAITING ON Ryan starting Muse | posted on 256 |
| 732 commit lint on main, bot seeds | WAITING ON the Board | audit 706 findings 4 and 8 |
| 733 one home for LIGHT_GAIN | WAITING ON 726 | audit 706 finding 11 |
| 730 runner hot fix | WAITING ON PR 731 | |
| 100 terrain fx 2 | WAITING ON 368 and 369 | same files; brief predates the scale table, re-read it against scale.md before launch |
| 211 Foley probe | WAITING ON the sound redo scope | Ryan's sound redo (R171) sets which moments first |
| 405 the program | STANDING | the one finished battle (Sunward against Eclipse) |
| 507 cinematic audit builds | STANDING | hits (538) and deaths (463) in review; sound weight and the kill moment still to file |
| 545 sweep follow-ups | STANDING | the Board's list in its comments |
| 256 Muse outside checks | STANDING | queue: opus_check_719, 702b, 714b, 727, 701b, 691b |
| 708 fleet inventory | WAITING ON PR 713 | then plan the next concept and build rounds from its gaps file |

## Not yet filed (so nothing drops)

- Portraits: a headless check of campaign_ui.gd's levelled face path (opus_check_707 condition 3b).
- The paint reruns from main: Eclipse queued tonight (ECL_PAINT_MAIN_1115.bat, eclmain1115out); Hullbreakers come with 726.
- Station, terrain and planet jobs each delete their KNOWN rows in godot/render/test/scale_check.gd when their sizes pass.
