# Opus final recommendation (Oct 31, 2026): DRAFT, finalized when the last helpers report

For Ryan, and the starting point for the next planning chat. Plain words, links to the evidence. Status labels used throughout:
- **IMPLEMENTED:** on main.
- **VERIFIED:** Opus checked it, or a test ran and passed, with the run named.
- **PREPARED:** written but not run or not merged.
- **UNCERTAIN:** not checked.

Main at the time of writing: see HANDOFF.md section 0 for the final commit.

---

## 1. What my existing work and helpers completed (Oct 27 to 31)

### Lore rollout (R59 to R61): IMPLEMENTED on main, Godot finishing
- **Rename map:** 424 rows with file:line and owner (L). See [rename_map_final.md](compute/rename_map_final.md) and the sweep report in [lore_rollout_notes.md](compute/lore_rollout_notes.md).
- **Browser game data:**
  - display strings at 90aaf85 (step 10);
  - Ryan's Muse-session rulings plus the small renames at f770e06 (step 12).
  - Ids are unchanged, and a seeded sim gives identical output before and after both steps.
- **Title:** "Embers of the Hollow Sun" in the Godot title, window and exe product name (49f0d85). The save folder is pinned, so your saves don't move. Tagline and G2 strings at 239fdeb.
- **Story:** six arcs rewritten to round 8 (b56269f, 72b1535, fcae7f6). Story tests: 72 checks, 0 failed.
- **Art:**
  - Six faction crests (e243729).
  - Portrait prompts (257de44) and the seven admiral paintings in the approved looks (c33f18d).
  - Hull repaint code (7fb50db).
- **FINISHING (see section 0 of HANDOFF for the outcome):**
  - Godot rules strings with an oracle re-pin and parity re-run (G1);
  - campaign strings with an oracle re-pin and parity re-run (G3);
  - repaint builds and the refresh of the PC ship assets (A4);
  - the remaining portraits.

### Fixes and features: IMPLEMENTED and VERIFIED
- **Browser campaign crash.** Every browser campaign battle crashed at the start from Oct 26: a code comment had swallowed `prepBattle()` (campaign3d.js:56). Codex found it and I confirmed it. Fixed in 5a99602, with a new test ([campaign_start_test.js](tools/campaign_start_test.js)) that drives real battle starts and scans every JS file for the same mistake.
- **Windows export job.** It now stops on any failed step and keeps the previous build (c5c0d27, adopted from Codex). The PC run is queued.
- **20-ship performance.** The 4.3 s death freeze is gone. The 1% low went from 15 fps to 65 fps (1080p) and 43 fps (4K) on Forward+, measured on the RTX 5080 in runs r18 and r19 (2aac0ca; [gallery README](../../godot/fx/gallery/README.md)).
- **Weapon marks** read at battle distance; the round 8 faction palettes are in the effects (df30bc4, 5b4b732).
- **Thruster-true movement** (680324c). Smooth braking, an engine glow that drops fast after a burn (273bd1a), and a wider capture camera (e5ef5d0).
- **Battle pace** (e80a6a0). Worst enemy round 14.35 to 12.07 s at 20 ships and 17.25 to 13.97 s at 28 ships. Outcomes are identical (headless, fixed 60 fps).
- **Balance.**
  - Pass 3 (G-13) held.
  - Full-run easing in d551697 took the toy sim from 13.5% to 19.5%.
  - The bot measurement turned out to be bot-specific (section 4).
- **Godot reliability.**
  - 36 of 36 six-faction bot campaigns clean at 3be2896.
  - The exe opens through play_godot.bat to the title and a battle (ef5cab2).

### Parity records
- **G1 rules:** 48 of 48 goldens plus a 200-battle sweep at bdb1a9d (803f72d), VERIFIED. G1 is re-pinning to the strings steps now.
- **G3 campaign:** 30 of 30 seeds, PC and cloud, at 9711a7e, VERIFIED. G3 is re-pinning now.

---

## 2. QA results and remaining acceptance gaps

### Checks I ran myself on main (Oct 31)
- Check pack: 0 FAIL.
- Unit tests: b1 39, b3 17, b4 29, backlog 11, campaign start 6. All ok.

### Acceptance gaps
Honest list, most important first.
1. **Nobody has played a full Godot run with the new names, rendered, on your PC.** Everything since Oct 27 has been checked headless, by bot runs or by stills. The exe launch test opened the title and one battle, and that's all.
2. **The movement comparison clips** (smooth stop against flip-and-burn) were still rendering on lane A at the time of writing.
3. **Hull repaints aren't in the PC build yet.** The Chorus still shows pink and Eclipse green in effect shots. The V1b deck-fan fix and your V1b bow and "waviness" notes are unconfirmed in game.
4. **Balance is only known for bots.** Pass 3 tuned per-battle sims. Full-run win rates depend on the bot: 19.5% for the toy sim, 63% for Muse's campaign driver. Neither is a player rate.
5. **Compatibility renderer:** one 0.53 s frame at the first line-ship death, plus single 60 to 80 ms frames at the first heavy hits on Forward+.
6. **Save carry-over (browser to Godot)** is undecided. The Godot code cites R33 for "not carried over", but R33 says nothing about saves.

---

## 3. External contributions: what I recommend using, and why

The reviews were run by three fresh review agents plus my own checks.
- **Codex PR:** 8 of 10 items verified by running or reading.
- **Muse design programs:** read in full at the synthesis level, about 25 code claims spot-checked, about 80% held.
- **Muse tools:** each tool run on main.

### Adopt (use as is, or nearly)
- **Codex's five gameplay fixes.** All confirmed in code, and none touches save fields:
  - the shipwright repairs the wrong ship (campaign_run.js:369);
  - 84 of 4,500 maps have no elite (core.js:267, reproduced exactly);
  - modules have no fit guard (campaign_run.js:140);
  - a lost Nemesis meeting reveals nothing (campaign_run.js:311), which your Q5 ruling says it should;
  - the boon offer bugs (data.js:689, core.js:181-188).

  Port them as small hunks from `contrib/codex/pre_opus/patches/integration.patch` (PR #1). The boon fix changes the seeded random rolls and can produce short offers, so it needs your sign-off on the policy. Its 45/55 duo-legendary split is Muse's tuning.
- **Codex's fail-closed Windows export job:** adopted (c5c0d27).
- **Muse's standing checks:**
  - fleet_invariants;
  - save_fuzz (with the PR's random-source fix);
  - table_xref;
  - softlock_sweep (goes green after the elite fix);
  - the browser save fixture checks;
  - the 8 passing findings pins plus pins for the confirmed bugs.

  All of these ran on main given a repo path. Fold them into one check-pack runner with fixed paths.
- **Ryan's rulings recorded in Muse sessions** (Oct 27 to 29): now registered as FINDINGS R61 to R63. They are the most valuable output of the week.
- **Muse's Godot desktop 3D brief:** use as the reference for the effects pass. Forward+ and Vulkan are already set.

### Adapt
- **Codex's phased-battle acceptance checklist** (OPUS_START_HERE, "Next useful artifact"). Use it as the acceptance test for phased activation (R63), which builds as a UI layer on today's rules. The red team's "it's a rules rewrite" is wrong: the rules already end movement once a ship fires (battle.js:761).
- **Muse's small ruled-fix list.** These are your rulings; each is small:
  - the Q5 loss reveal;
  - a free exit from the haven event;
  - the off-core rarity tax;
  - the L_storm gate;
  - veteran ships skipping their brace;
  - the duplicate gsentry gun;
  - the salvage (relic) fixes;
  - disclosing the variant that drops a gun;
  - renaming the h_repair modifier;
  - the missing Eclipse battleship price key.

  Batch them with the Codex five in one stream B step and one re-pin.
- **The confirmed-bug list from the tools review:**
  - the decommission NaN;
  - mastery overpaying;
  - event flags that record presence rather than the choice made;
  - a seer option that can never appear;
  - legacy Nemesis migration losing data;
  - the protocol reroll charging for nothing;
  - the wrong hint after moving;
  - dead purchase paths.

  Same batch.
- **The Muse story pack.** Take its beat 3 core decisions, learning lines and admiral spotlights first, and its six faction finales one at a time. Its claim to replace the story source was never your ruling. See [lore_rollout_notes.md section 4](compute/lore_rollout_notes.md).
- **Muse's campaign Monte Carlo driver.** It is the better campaign-level instrument: it plays the real reward, shop, event and Nemesis code. Make it the full-run measure, and keep stream B's runsim for quick per-battle deltas. Neither is a player rate.
- **The telemetry spec.** Build a minimal local logger behind the existing `tel()` in campaign.gd, for the three "revisit with play data" rulings.

### Defer
- **The skill tree content.** All 360 texts are written. The effect pool (`sumFx`, core.js:171) has no caps, and many effects need engine hooks that don't exist. Fix the pool first, then build one faction as a test slice.
- **Codex's Saro two-effect pilot.** It's well made, but it touches battle, rules, core and UI at once. Do it as part of the skill tree slice.
- **The 33-event expansion and event variants.** After the playtest.
- **Muse balance grids, including the Chorus A3 price change.** Hold all faction tuning until the two instruments are reconciled and you've played.

### Discard (superseded or wrong)
- **Codex's four oracle and table re-pin patches.** My helpers' re-pins replace them; one no longer even applies. The stale 355a2ac pins throughout the packet go with them.
- **Refuted claims, already retracted by Muse:** the Chorus feed is missing (FS-5); the oracle carries the boot grant (DRIFT-1); prices are lost in the export; damcon is dominated (MOD-4). Also the old "20% win rate" figure.
- **Balance bible line 11** ("Ryan rejected the more-ships ramp") contradicts R1.
- **The main-branch gate.** It reports IMPROVEMENT with the parity slot NOT RUN. Use the PR's gate after revising its hard-coded pair count.
- **The "phased activation is a rules rewrite" framing.**

---

## 4. Findings I reject, revise or consider superseded

| Finding | My call | Why |
|---|---|---|
| "72 failing assertions" | Revised | 11 confirmed bugs, 9 probable, 11 ruled-but-unbuilt, 41 opinions. Not 72 bugs. |
| Bot win rate 63% / 80% (Muse) vs 19.5% (B) | Both kept, both bot-relative | Same commit, same difficulty. The gap is the campaign bot: B's runsim routes randomly and skips events and prizes. |
| NEM-4 "Nemesis strikes do nothing" | Partly false | Duel, reinforce and challenge act in battle (battle.js:550-576). Only the map text is empty. |
| 42-battle six-faction smoke (Codex) | True but generous | Only one run won, and three ended in sector 1. API-level, not rendered. |
| naming_lint | Revise | Thin coverage, and with no arguments it scans zero files. Rebuild it from the rename map. |
| Story pack "supersedes outlines" | Not adopted as a source | Not ruled; merge pieces instead (above). |
| Red team "freeze audits" | Agree | 816 contrib files against about 9,000 lines of game code. The next evidence should be play, not audits. |

### Not verified by me or the reviewers
- the line-by-line text of the 360 tree texts, the event variants, the 41 Nemesis lines and the 16 tutorial tips;
- every individual Qwen, DeepSeek and Argon leg (sampled through the syntheses);
- Codex's 3,840-build catalogue and its progression model;
- the PR's Blender diagnostics (no Windows or Blender there, and not run by us).

### Independence
Muse's "four of four" agreement is weaker than it looks: every prong worked from the same chair-built evidence pack. That shared pack is how the false "no Chorus feed" premise spread into five documents. Codex's findings were independently reproduced by my reviewer: the elite gap exactly, plus 10 battles and 3 campaign seeds re-run.

---

## 5. Most significant remaining problems, ranked

1. **No human playtest of the Godot game.** The biggest unknown, and it decides what the rest of the list should be.
2. **Battle controls.** Clicking an enemy to inspect it also fires, attack-move can move a ship somewhere you never saw, and phased activation (ruled) isn't built. This is the core feel of every battle.
3. **Known rules bugs:** about 20 small, confirmed ones (section 3), including two that touch your rulings (Q5 and the off-core value). None crash; all are cheap.
4. **Balance for real players is unknown,** and faction strength differs by instrument. The Crusade is weakest in every measure: 0 of 6 Godot bot runs, and about 50% in Muse's driver against 85 to 89% for the Chorus.
5. **The save carry-over decision** (browser to Godot) is open.
6. **The art isn't on the PC build:** hull repaints, the V1b bow and waviness, the remaining portraits. Plus the ruled content not yet built: the Eclipse battleship hull, Daybreak at speed 2, the boss objective table.
7. **Progression depth:** admiral skill trees are ruled but not built, and the story finales are thin.
8. **Process risk:**
   - Oracle drift means re-pins after every rules step.
   - Muse's checks aren't in the check pack yet.
   - A shared git stash swapped work between helpers once (fixed by policy).
   - The cloud disk filled up twice.
9. **Performance edge cases:** the Compatibility renderer's single long frame and the first-hit hitches.

---

## 6. Recommended next build phase: "Play it"

Goal: you play full Godot runs and the game responds to what you find. Order and rough effort (helper-days; S is under a day, M is 1 to 3 days, L is more):

| Step | What | Who | Effort | Depends on |
|---|---|---|---|---|
| 0 | Finish the rollout: G1 and G3 re-pins and parity, A4 repaint builds and the PC asset refresh, portraits. A fresh exe through the fail-closed export job | G1, G3, A4, P, G2 | S (in progress) | none |
| 1 | **Playtest build and your first runs:** one or two full runs, notes in your own words (a short template provided) | You | 1 to 2 hours | 0 |
| 2 | **Rules fix batch:** the Codex five, the confirmed bugs and the small ruled fixes, as one stream B step. Then one G1/G3 re-pin, with tests for each fix | B, G1, G3 | M | 0 (in parallel with 1) |
| 3 | **Phased activation in the Godot battle UI:** inspect, rehearse, commit move, fire, brace and pass, cancel. Acceptance is Codex's checklist with a capture for you | G2 | M to L | 0. Shaped by 1 |
| 4 | **Standing checks:** fold Muse's checks into one runner and the PR's gate. A naming lint built from the map | B or a tools helper | S to M | 2 (softlock goes green) |
| 5 | **Balance instrument and telemetry:** Muse's driver as the full-run measure, a minimal play log in Godot, then faction tuning (the Crusade first) from your play plus the driver | B, G2 | M | 1, 2, 4 |
| 6 | **Art and ruled content:** repaint confirmation, the V1b bow, waviness, the Eclipse battleship hull, Daybreak speed 2, the boss objective table | A4, B, G1 | M to L | 0 |
| 7 | **Progression slice:** cap the effect pool, then one faction's admiral tree (the Saro pilot as the seed), then pieces of the story pack | B, L, G3 | L | 2, 5. Your call on order |

Keep running the Muse program only for targeted checks you ask for (for example "review the phased UI capture"). No new broad audit waves until step 1 has happened.

---

## 7. Decisions I need from you

1. **Save carry-over:**
   - **PICK:** start fresh in Godot. The browser profile's unlocks came from the testing boot grant, and nothing else of value lives there.
   - Or import career records only, with a converter, stripping the grant.
2. **Boon (protocol) offer policy:**
   - **PICK:** adopt the fix (one pool, the core's picks weighted 3 to 1, a short offer pays 60 credits), accepting that seeded rewards shift.
   - Or keep today's always-full offers.
3. **Flip-and-burn:**
   - **PICK:** off. On the dreadnought it looks frantic.
   - Or keep it for cruisers only, if the cruiser clip reads well.
4. **Freeze new audit programs until you've played:**
   - **PICK:** yes.
5. **Story:**
   - **PICK:** bring in the Muse pack's core decisions, learning lines and admiral spotlights in step 7; finales one at a time.
   - Or replace the story outright.
6. **Order of steps 3 and 7:**
   - **PICK:** battle controls before progression.
7. **Vetoable names** (map section 13). Anything you want changed? Examples: Admiral Roderic Vex, the Glasswright admirals Tamsa, Saro, Vell and Brin, the sync tiers Listening to Full sync, Spinal cannon.
8. **Small design questions,** answerable later, after play:
   - should refitting cost something;
   - should the spore wing get its own job;
   - should Veteran AI be locked for new players.
