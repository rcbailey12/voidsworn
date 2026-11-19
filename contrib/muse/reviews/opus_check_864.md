# Outside check: PR 864 (issue 860, runner ship-file source defaults)

Refs #256. PR 864 head 88d7e3ed, checked Nov 18, 2026. Council: blind Rey (chair, own verification below), DeepSeek, Qwen, Flash. Grok seat not run for this batch (parked, bot wall).

## Verdict: GO WITH CONDITIONS

Flash GO, Qwen GO, DeepSeek GO WITH CONDITIONS. The change is four default-path swaps and nothing else; the conditions are PC-side confirmations no repo check can make, plus one correction to the check pack's own wording that DeepSeek caught.

## What the chair verified directly (OBSERVED)

1. The diff is exactly four files (tools/pc/jobs/explosion_routes.bat, look_bench.bat, ui344_briefing_shots.bat, ui344_rollout_shots.bat), each changing comment text and one source-path assignment from a deleted per-run folder (bench351\repo\godot or audit2\repo\godot) to %VT%\build\godot. No other lines change; no file is added or removed.
2. build\godot is the standing canonical source: tools/pc/get_ship_files.bat on main documents it (line 8) as the folder holding gen\ and assets\ships\, with its own default SRC set to the same path (line 16).
3. Every read from the source in the four files at head is one of <SRC>\gen, <SRC>\assets\ships, <SRC>\.godot (explosion_routes lines 44-46, look_bench lines 131-133, ui344_briefing lines 28-30, ui344_rollout lines 26-28). Copies write only into each job's own clone or run folder, never into the source.
4. No destructive operation exists in the four files: a grep of the full files at head finds no del, erase, rmdir or rd command, and every robocopy runs with /E /XC /XN /XO or plain /E, never /PURGE or /MIR.

## Council agreement

All three legs: the diff matches the PR body with nothing hidden; gen and assets\ships are documented as living in build\godot; nothing deletes or overwrites on the PC (destination writes inside the job's own folders are the jobs' normal operation); the change repairs an already-broken state, since the old default folders were removed in the Nov 16 cleanup, so it introduces no new failure mode; the bench351 base_f disclosure in the PR body is explicit and adequate (the set was destroyed by the cleanup, not by this PR, and the body names the remedy, a fresh base capture).

## Conditions and notes

1. PC population is NOT CHECKED and cannot be checked from the repo: before the first post-merge run, someone on the PC should confirm build\godot actually holds gen, assets\ships and .godot today. The .godot import cache is the soft spot: get_ship_files.bat documents gen and assets\ships for that folder but says nothing about .godot. If the cache is absent, the ui344 jobs copy nothing for it and Godot regenerates it on open; the guarded jobs (explosion_routes, look_bench) skip silently. Low risk, worth one look.
2. Correction to the pack, caught by DeepSeek and confirmed by the chair from the full files: the pack's context said the SRC environment variable "can still override the default" in all four jobs. That is true only for FX_SHIPS and LB_SHIPS, which are guarded (if "%VAR%"=="" set ...). In both ui344 files SRC is an unconditional set (ui344_briefing_shots.bat line 18, ui344_rollout_shots.bat line 16) that overwrites any caller-provided SRC. This is unchanged by the PR (the old line was the same shape), so it is not a regression; it is recorded so nobody relies on a ui344 SRC override that does not exist. Qwen's leg called the bare set "unguarded-but-equivalent"; it is not equivalent, and the chair sides with DeepSeek on this point.
3. The ui344 ships and gen copies do not guard on source existence (pre-existing style, unchanged). If a source subpath is missing, robocopy logs the failure and the batch continues; the guarded pair skip silently instead. Neither behaviour is new. Not a merge condition; a candidate tidy-up if the Board is editing these files anyway.
4. Scope note: whether OTHER job files still default to bench351 or audit2 was outside the pack and is NOT CHECKED. A one-line grep across tools/pc on the PC or in the repo would close it.

## Method note

Pack carried the full diff, get_ship_files.bat's documentation lines, the copy lines from all four files at head, and the chair's grep results. Legs ran under their standing gates (DeepSeek DeepThink on and Search off, Qwen3.8-Max selector and header, Flash-Lite picker signed in), each verified before and after. One leg's response (Qwen, section 4 table) ended a cell mid-sentence in the model's own output; recorded as rendered, nothing rested on the missing words.
