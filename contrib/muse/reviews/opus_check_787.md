# Outside check: PR 787, S8 paint one step lighter, the x1.85 column (R258)

Refs #256

## Verdict: GO WITH CONDITIONS

One condition, on comments in the stack that now contradict the direction document this PR amends. The paint change itself is verified end to end: the chair ran the shipped step functions on the sampled tones and every figure in the PR's table reproduces exactly; the 2048 battle median lands within one count of Ryan's chosen what-if; the sunward.md amendments match the code, and the opus_check_772 condition is discharged by this PR.

Council: blind Rey GO, notes only. DeepSeek (DeepThink on, Search off, verified both ends) GO WITH CONDITIONS. Qwen (Qwen3.8-Max, verified both ends) GO. ChatGPT (chat, GPT-6 at High, verified both ends) GO WITH CONDITIONS. Flash (Flash-Lite, verified both ends) GO WITH CONDITIONS, its condition generic and answered at the chair (see Leg notes). Grok empty (46th consecutive, bot wall).

## The brief

opus_check_787: PR 787 (merged), the S8 paint at Ryan's x1.85 pick (R258): wear tones and iron lifted, battle median 26 to 34; the sunward.md section 4 and 7 edits match what the stack does.

## (a) Wear tones, iron family, battle median

**Verified.** The chair extracted wear_tone() and stepped() from the merged stack.py (head 39e57fd5) and ran them on the CONCEPT tones. Every value in the PR's table comes back identical: wear pair (135,135,133)/(175,173,172); iron (49,44,42)/(100,98,98); iron_shade (25,25,23)/(82,74,70); iron_dark (37,34,32)/(86,82,81); iron_cast and worked (54,51,50)/(104,103,102). WEAR_FLOOR computes to 133.3 (the PR's 133). DeepSeek, Qwen and ChatGPT each recomputed the same table independently and agree.

The family order holds at both ends (shade, dark, iron, cast and worked), and the lightest plate (104) sits about 29 counts under the wear floor (133), so section 4's rule (wear tones only, never plate tones; edges lighter than every plate) survives the lift.

Medians: the merged audits_sandbox.json records battle (34,35,37) against the x1.85 what-if's (34,34,36) and the before figure (26,27,28), which the pre-787 audits on main (464cdda9ef) confirm. The brief's 26 to 34 is met. The fitted after figure (67,63,61) is within one count of the what-if (66,62,60) but appears only in the PR body; the audits file carries no fitted figure (DeepSeek and ChatGPT both flagged this; it is a note, not a defect).

Albedo: two legs flagged the "before" linear albedo (0.0176, 0.0168, 0.0168) as unsourced in the pack. The chair checked the source: the pre-787 audits_sandbox.json at 464cdda9ef records median_albedo_lin (0.01764, 0.01681, 0.01681), exactly the PR's before figure, and the after figure matches the merged audits (0.02956, 0.02843, 0.02732). The ratios are 1.68, 1.69 and 1.63, so "about x1.7" stands, verified against the repo record rather than the pack alone.

## (b) sunward.md edits, and the opus_check_772 condition

**Verified, and the 772 condition is discharged.** Section 4's painted wear hexes are the stepped wear pair (#878785 is (135,135,133); #afadac is (175,173,172)), and its IRON_STEP sentence matches stepped(). Section 7's wear floor #878785 and lightest plate #686766 (104,103,102) match the stepped output. Section 5's frost clip matches frost_rgb(), which returns the game accent with blue clipped to green ((0.8, 0.9, 0.9) from (0.8, 0.9, 1.0)). Section 1's corrected sentence matches panel_nodes(), which picks a calm tone per plate cell and keeps no cell on the shared base's broad noise. Both amendments the 772 condition asked for landed in this PR, marked with their Board citation.

## Condition

1. **Two comments in stack.py still credit plate_var and island_tone with the forged variation.** The LAYERS comment at the sunward.md 1 line reads "forged variation by plate (plate_var, island_tone)", and the patch_warp comment says "plate_var and island_tone carry the forged variation instead." Both contradict sunward.md section 1 as this PR amends it, and panel_nodes' own docstring and body. The behaviour is right (the values remain in LAYERS, and the dark zone keeps plate_var=.05, but the hull panel path does not use them); only the comments are stale. They matter because section 1's stated purpose is that a future editor should not "fix" the order from a stale sentence, and these are now the stale sentences. Correct both comments in a later pass. (Blind Rey, DeepSeek, Qwen and ChatGPT all landed here independently; ChatGPT adds, correctly, that the values themselves need not change.)

## Notes

- **The iron band in the audits is the sampled band.** audits_sandbox.json reads iron_band as the sampled CONCEPT iron pair ((25,22,21) to (82,81,81)), and the painted range after the step is (49,44,42) to (100,98,98); the battle median (34,35,37) sits inside the sampled band and below the painted family's dark end, which is expected on a lit render and is not a failure. The PR body says "sampled iron band", which is accurate. Keep the word "sampled" in the audit's wording and in any acceptance text, so the band is never silently read as the painted range. (ChatGPT.)
- **slope.json's "why" describes the iron-step-only experiment, not the shipped build.** It says the wear tone "does not move"; in the shipped stack the wear tones do move (WEAR_STEP on BARE). The file is an experiment record and the PR body describes the final build correctly, but a reader starting from slope.json will get the mechanism wrong. A one-line header in the issue 781 evidence folder naming which files are experiments and which are the build would close it. (Blind Rey.)
- **The built stack's 1024 medians are prose only.** The evidence folder holds four medians files (main, whatif_x185, whatif_x24, iron_step_060; chair verified the listing at the PR head). None records the built stack at 1024, so its fitted (66,62,60) and battle (33,34,36) figures rest on the PR body and the issue 781 README, and the one-count battle shift between the 1024 build (33,34,36) and the 2048 build (34,35,37) is undocumented. DeepSeek first raised this as a discrepancy against medians_whatif_x185.json; that file records the what-if blend, not the build, so there is no contradiction, only the missing file. The 2048 audits are the build's record and they carry the headline claim. (DeepSeek, Qwen.)
- **Section 4's "the whole map rises together" overstates slightly.** Soot, liner, frost and every glow are unchanged by the step, as the PR body's own unchanged list says. "The wear and iron portions rise together" would match the code exactly. Wording only. (ChatGPT.)
- **PR-body-only claims.** surface_check PASS, density flags, sheet_fixture_hash PASS, the empty diffs for the shared and other faction kits, and py_compile are asserted in the PR body without their outputs in the pack. Nothing in the pack contradicts any of them, and the code diff in the pack is confined to the one paint change, but the check records them as asserted, not verified. The same applies to "every PR 772 check passes again": the 2048 audits in the pack cover the emissive, frost, lift and median checks and all pass; the picture-level reads are the Board's. (All legs, in varying words.)
- **Standing, not a condition on this PR:** the PC run (Blender 4.5, GPU, 4096 bake) and the in-game pictures were not run, as the PR states plainly. Sandbox correctness is what this check establishes; production acceptance stays where opus_check_772 left it, with the Board's pipeline. (ChatGPT.)

## Leg notes and slips

- Qwen's iron table misaligns two dark rows (iron_dark dark listed as (64,61,60) to (64,61,60); iron_cast/worked dark as (88,87,86) to (88,87,86)) against the PR table's (16,14,13) to (37,34,32) and (30,28,27) to (54,51,50), and marks every row verified anyway. Its light-end order and separation conclusions are correct, and the chair's own run of the functions covers the dark rows, so nothing in this delivery rests on Qwen's table. Recorded, not adopted.
- Flash's stated condition (that the documentation amendments be verified against the merged repository state) names no defect; the chair did that verification from the merged files, and it is the substance of sections (a) and (b) above.
- Qwen's first generation failed with an internal error and was regenerated in the same chat on the same message and model; the gate held at both ends. Recorded for completeness.
- Grok: empty seat, 46th consecutive (grok.com returned "Your request was blocked" before any chat opened). Recorded as empty, never filled.

## Not checked

- The four replacement paint pictures at picture level; the numeric audits over them are verified above.
- The PC run of the stack; the sandbox figures are the record the PR stands on, as with PR 772.
