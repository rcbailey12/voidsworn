# Brief for Muse: full catch-up audit (Oct 27, 2026)

From Opus, at Ryan's request: "I'll have muse run audits across lore and all the other work with the other LLMs to catch up and make sure things are on the right track."

Main is current as of this brief's commit. Helpers are still working, so newer commits will land while you audit; audit what is on main when each leg starts, and note the commit hash it read.

## Read first (in order)
1. `HANDOFF.md` section 0 "Status at Oct 27 midday".
2. `contrib/opus/go-forward-plan.md`: the status table and section 4 "Travel sprint" (goal R35, streams, folder ownership).
3. `contrib/opus/FINDINGS.md` rows R34 to R54 and G-12. These are Ryan's rulings and Opus's verified facts. Do not relitigate a ruling; flag only a real problem with evidence.
4. `CLAUDE.md` (ship rules: space not naval, no backward guns, blob sweep, matched pairs).

## House rules (unchanged)
- Blind legs (Argon, DeepSeek, Qwen, plus any other model you use), each run without seeing the others.
- Primary sources with links for any outside claim; `file:line` for every claim about the repo.
- UNSURE tags. Plain words, no em dashes.
- Raw returns in `contrib/<model>/`; synthesis in `contrib/muse/reviews/full_audit_2026_10_27.md`.
- No edits under `contrib/opus/`, `godot/`, `tools/`, game code or HANDOFF.md. Commit to main.
- Opus verifies every claim before anything is acted on. A ruling changes only when Ryan says so. Technical calls are Opus's; taste and direction calls are Ryan's.
- Do not report a stream's in-progress item (marked IN PROGRESS in HANDOFF section 0) as missing. Do report it if it is going the wrong way.

## Audit A: lore round 6
- Subject: `contrib/opus/compute/lore_bible_r6.md` (repo copy of the live doc https://claude.ai/artifact/SKyQf2QcJSXGmXfmxKxFpJ). Rounds 4 and 5 are history.
- Already done, so do not repeat: the round 4 review (`contrib/muse/reviews/lore_r4_review.md`), Ryan's rulings on Q1 to Q14 recorded there, and Opus's verification and calls (`contrib/opus/evidence/lore_r4_review_verification_2026_10_27.md`).
- Jobs:
  1. **Were the round 4 rulings and Opus calls applied?** Check each ruling and each Opus call against r6. List any that are missing or applied wrongly, with the r6 line.
  2. **Ryan's round 5 asks (R54):** the machine faction is not past tense; the Dimming is renamed; Caelum is renamed; the Crusade is bigger than one world; the Hegemony's reason for wanting the Sun is explained; Hullbreakers are alien. Say for each whether r6 delivers it.
  3. **New names in r6:** collision check, same method as round 4 job 1 (clear, minor echo, real collision, with a source). Only names new since r4.
  4. **Consistency:** timeline, faction wants, who-did-what between factions, patron "where it went" lines, motif and colour owners. Line numbers in r6.
  5. **Fantasy drift and 40k echoes** still left (R44, R52).
  6. **Gameplay fit:** does the lore still match R42, R46, R49 and the faction mechanics in `data.js` (FAC, doctrines)?
  7. **Questions for Ryan:** short multiple-choice, recommended option first, written for a non-technical reader.

## Audit B: the Godot port and the travel sprint work
For each stream, answer: is it on track for R35 (Ryan returns to a game he can test and refine), what looks wrong or risky, and what is missing that the plan says should exist. Cite `file:line` or commit hashes.

- **G1 rules port** (`godot/rules/`, `godot/rules/test/`, FINDINGS G-12). Is the parity record (43/43 golden, 1,500 random battles with 0 diffs, nothing NOT PORTED) backed by the files in the repo? Any JS rules in `battle.js`, `core.js` or `data.js` with no Godot counterpart? Any parity test that could pass while being wrong (for example, comparing too few fields)?
- **G2 whole game** (`godot/main/`, `godot/scenes/`, `godot/ui/`, `godot/main/FEATURES.md`, shots in `docs/shots/g2/`). Does the game flow title to final boss match the JS game? Pace (the 15 s worst-round target), the bot runs, the Windows export. The movement work (R54: main drive along the hull axis, side thrusters for sidesteps, turning that makes sense, engine trails from the real nozzles) is in progress: check the approach is sound, not that it is finished.
- **G3 campaign** (`godot/campaign/`, `godot/campaign/test/`, shots in `docs/shots/g3_campaign/`, latest `8a12941/`). Does the map meet R51 (Sins 2 star system, high-quality stops and icons, decluttered)? Campaign parity with JS.
- **G4 effects and world** (`godot/fx/`, `godot/world/`, `godot/render/`, `godot/fx/faction_looks.json`, shots in `docs/shots/g4/`). Per-weapon marks, hit reactions, shield breaks, wrecks, asteroids, the black hole. Is anything hard-coded that should be data? Performance risks at about 20 ships (R-ruling of Oct 24)? Shields keep faction colours (Oct 24 ruling).
- **A4 ships** (`tools/blender/`, shots in `docs/shots/a4/46a89fe/`). Check each shown ship against CLAUDE.md: naval tells, backward guns, floating or sunk parts, unmatched pairs, blobs. The Pyre-Barge redesign (R54) is in progress.
- **Stream B rules** (admiral band and faction tune; `data.js`, `battle.js`, check pack and sims). Do the balance changes have before-and-after sims?
- **Music and portraits** (`godot/music/`, `godot/portraits/`, CREDITS.md). Is every track's licence real and correctly credited? Check each source link.
- **Cross-stream:** folder ownership collisions, duplicated code between streams, docs that say different things (HANDOFF, plan, FINDINGS, stream READMEs), and anything a stream claims as done that the repo does not back up.

## Synthesis format
`contrib/muse/reviews/full_audit_2026_10_27.md`:
- top summary for Ryan's phone, five bullets at most;
- Audit A and Audit B sections, one subsection per job or stream;
- each claim tagged CONFIRMED BY 2+ LEGS, SINGLE LEG, or UNSURE, with `file:line`, commit hash or link;
- a severity on each problem: BLOCKER (Ryan cannot test on return), FIX (wrong but not blocking), NOTE (polish);
- questions for Ryan at the end, multiple choice, recommended option first.

File whatever finishes first; Audit A and Audit B can land separately.
