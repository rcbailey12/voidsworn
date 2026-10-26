# Travel sprint Job B: B3 and B4 design and balance review (chair synthesis, Oct 26, 2026)

Trigger commit: beae728b315ad69a2ca6721c5818d012edfef60c,
"Stream B: B-18 and B-19 fixes, faction identity telemetry in the
sim", Oct 26 2026 06:58 CDT, two files changed: battle.js (+2 -1),
sim3d.js (+28 -14).

Three blind legs, all filed and screened: DeepSeek
(contrib/deepseek/sprint_jobB_deepseek_raw_2026_10_26.md), Qwen
(contrib/qwen/sprint_jobB_qwen_raw_2026_10_26.md), and Argon
(contrib/gemini/reviews/gemini_sprint_jobB_argon_high.md). Qwen and
Argon worked from the evidence pack only and could not read repo
files, so their findings are checks to close, not observed defects.
DeepSeek read the repo itself (commit diff, battle.js, sim3d.js,
ui3d.js, data.js, core.js, contrib/opus/compute/, FINDINGS.md and
the go-forward plan), so its OBSERVED findings carry the weight in
this synthesis. Where a pack-only leg and DeepSeek disagree, DeepSeek
wins, and the synthesis says so.

## Verdict: B-18 consistent, B-19 flagged, FID flagged, B3 exit NOT demonstrated

B-18 is a real fix and breaks nothing: a stalled-battle check that
sat after `//` on its own line as comment text now runs, restoring
the intended behavior. B-19 is a real improvement with a real defect
in it, and the faction identity telemetry is half built. Nothing in
this commit breaks a ruling or a faction identity, and nothing in it
claims a B3 or B4 exit. But until the two fixes below land and the
sims rerun, no balance number from before this commit can be quoted
as current, and the B3 exit criterion "the sim shows each faction
playing differently" is not yet demonstrated. The balance numbers
are stale, not wrong.

## Ranked findings

### 1. roundStart does not match the game it cites [DeepSeek OBSERVED, top code defect]

B-19 was meant to make the sim await turn-start deaths the way the
game does. The new roundStart helper in sim3d.js launches the enemy
tick before the player tick is awaited, and checks B.over only
synchronously, before the player deaths resolve. The game
(ui3d.js nextRound) awaits the player tick first and returns early
if the battle ended, so the enemy tick never starts. In the sim, if
the player's turn-start deaths (fire, acid, the dead star) end the
battle, the enemy tick has already applied its damage and queued
its deaths. The final board state and the FID loss and damage stats
can then diverge from the game in exactly the edge case B-19 was
meant to align. The helper's own comment ("player ticks, then enemy
ticks unless the battle ended, each awaited") misdescribes the code.

Opus action: make roundStart sequential (await the player tick,
return if B.over, then start and await the enemy tick), then rerun
the sims. This is a harness fix, not a rules change.

### 2. The FID faction-definer counters are dead [DeepSeek OBSERVED]

sim3d.js merges B.fstat into the per-faction FID record and reports
feed, charge, sync, syncShots, torpLaunch, torpHit, torpDodge and
revive. But nothing sets B.fstat: DeepSeek searched data.js, core.js
and battle.js and found zero matches in all three, and sim3d.js only
reads it. The merge always reads an empty object, the counters stay
0, and the report never prints them. The FID line therefore measures
only the generic metrics (range, damage split, regen, losses, dealt)
and cannot show the faction definers from the Oct 24 rulings:
Hegemony synchronized fire, Chorus feed, Ithar shield charge,
torpedoes. This turns Argon's pack-only blind-spot analysis into an
observed gap, and gives it a named mechanism to fix.

Opus action: add B.fstat producers in battle.js (increment per
faction on synchronized fire, feed heals, shield charge, torpedo
launch/hit/dodge, revives), rerun fmatrix, and confirm the FID line
shows non-zero mechanic counts. Argon's fuller counter proposal
(sync-active vs unsynced shots, Ithar bonus vs baseline regen,
capped feed heals, reanimate counts, Brace count, plus UI
visibility checks for every faction mechanic and torpedo lanes) is
the top FID recommendation and should be folded into this fix, not
treated as a separate job. Note the per-faction detail Argon asked
for is what proves the rulings: Hegemony anchor radius and collapse
and Anchored Volley non-stacking, Ithar bonus above baseline and
zero Brace uses, Chorus feed cap and zero repair outside feed,
Deathless reanimate counts and zero shield soak.

### 3. Balance numbers are stale after B-19; no sim was rerun [DeepSeek OBSERVED, all three legs agree]

B-19 changes turn-start death ordering in every sim battle loop
(sim, match, fuzz, bossCheck, bossMatrix, archMatrix, fMatrix,
rsFight, chainSim). Ordering changes can move results even when the
rules text is unchanged. The newest sim output in
contrib/opus/compute/ predates the trigger commit (b2/ committed
Oct 25 4:57 PM CDT, raw/ and CSVs Oct 24-25; beae728b landed Oct 26
6:58 AM CDT). No FID output and no post-B-19 win rates are filed
anywhere DeepSeek could find. The commit message gives no win rates.

So the admiral band is UNSURE, and the only band numbers on record
(57-89% at 96 runs per admiral, FINDINGS S6) predate B-19. Say
stale, not wrong. And keep Argon's ceiling caution attached to the
old numbers: 89% sits 1 point below the 90% ceiling, so a small
UPWARD move by the top admiral breaches the band. That framing is
about the top admiral only, not any admiral moving.

Opus action: after findings 1 and 2 are fixed, rerun fmatrix and
bossmatrix on the post-beae728b code, file the output including the
FID line in contrib/opus/compute/, and diff win rates against the
B0 baseline. Re-check every admiral against the 50-90% band on the
new numbers before any balance claim is quoted again.

### 4. B-18 is consistent, with one ordering check still open [DeepSeek OBSERVED, Argon check carried]

The bug is real: the old battle.js line 720 placed the stalled-battle
check after `//`, so it never executed; the new battle.js:721 puts
it on its own line and it now runs. The commit's "no change in the
sim, where nothing stalls" claim is plausible from the code (the
sim runs battles sequentially and awaits every death promise inside
the battle), but DeepSeek marks it INFERRED, not exhaustively
proven, and the synthesis keeps that mark. No ruling is broken and
no B3/B4 item is affected. This restores a guard; it is not a rules
change.

Still open, from Argon: if the restored check fires before Deathless
reanimation (battle.js:702) or before roundStart finishes death
queues, a Deathless fleet that should reanimate, or a
mutual-explosion edge case, resolves differently. Opus action:
verify the check runs only after reanimation plus queued explosions,
with a fixed-seed before/after diff. DeepSeek did not examine that
ordering, so Argon's check is not answered by this leg.

### 5. Voidsworn carriers: decided on main, item closed for Job B [DeepSeek OBSERVED, supersedes the pack-only legs]

Qwen flagged the carriers conflict as an open cleanup (asymmetry
list to remove or annotate "Voidsworn no carriers" as superseded by
plan B3 item 1). DeepSeek read the record and closed it: FINDINGS.md
entry F22 marks the carrier ban a Conflict with status DECIDED
(carriers stay, priced up), the go-forward plan says the same in
words, data.js confirms Commodore Sera Ashgrove (Voidsworn, Carrier
doctrine, starting fleet includes reliquary) and the reliquary as a
Voidsworn carrier, and the trigger commit touches only battle.js and
sim3d.js, so no stream B change follows the loss list over the plan.
The synthesis does NOT carry Qwen's cleanup as an open Opus action
for Job B. The plan is the approved record, and the registry already
records the decision. Cite the items as B3 item 1 (carriers) and B3
item 5 (Deathless elite attrition), not "B3.1"/"B3.5".

### 6. Small items, answered, no action needed

- FID wording: the commit message says "an FID line per faction";
  the code prints one FID line containing per-faction entries
  (sim3d.js:412). Wording nit only, no plan item broken.
- File list: Qwen's closing check (git show or diff-tree on
  beae728b) is now answered by DeepSeek's verified diff (battle.js
  +2 -1, sim3d.js +28 -14). Not carried as an open action.
- FID readability: the generic FID metrics DeepSeek verified (range,
  damage split, regen, losses, dealt) all have player-visible
  counterparts (weapon ranges, shield bars and armour, hull regrown,
  ships lost), and the install is harness-only (the applyHit,
  fireWeapon and startSideTurn wrappers delegate to the originals
  and only count). So the telemetry itself introduces no sim-only
  unreadable mechanic. The remaining gap is the dead definer
  counters in finding 2, not readability.
- B4: the trigger commit claims no B4 exit, and none is flagged.
  Argon's build-order guard stays open as a check for later B4 work:
  B4.3 verbs and B4.4 Nemesis must not bypass the B4.2 flag
  definitions they are built on.

## What is NOT exited, and what gates it

- B3 exit ("No faction runs away with win rates", "the sim shows
  each faction playing differently"): NOT demonstrated. Blocked on
  findings 1, 2 and 3 above (fix roundStart, wire the definer
  counters, rerun and file the sims), plus Ryan playing each faction
  once and saying whether it feels like itself.
- B4 exits: NOT claimed and NOT gated on this commit. Every B4 item
  needs Ryan to play it, and he is traveling. No downstream document
  should mark a B4 item exited before his return.
- Admiral band 50-90%: UNSURE on the new code, pending the rerun.
  Do not quote 57-89% as current.

## Opus actions, in order

1. Fix roundStart to sequential (await player tick, return if
   B.over, then enemy tick).
2. Add B.fstat producers in battle.js and confirm non-zero definer
   counts in the FID line, folding in Argon's per-faction counter
   proposal.
3. Rerun fmatrix and bossmatrix on the fixed code, file the output
   including the FID line in contrib/opus/compute/, diff against
   the B0 baseline, re-check the 50-90% band.
4. Run Argon's B-18 x reanimation ordering check (fixed-seed
   before/after diff).
5. Keep Argon's B4 build-order guard (B4.3/B4.4 must not bypass B4.2
   flags) as a check on later B4 work.
6. No action on carriers for Job B (decided on main, finding 5) and
   no action on the FID wording nit.

## Not checked

- Sims not executed by any leg (the browser environment has no
  terminal); all behavior claims are from reading the code.
- Admiral band on the new code: UNSURE, pending the rerun.
- B-18 stall plausibility beyond code reading: INFERRED, not
  exhaustively proven.
- Ryan's playtest (B3 feel check, all B4 exits): not checked,
  gated on his return. No date is stated here; the gate is his
  return, not a calendar day.
- Exact line numbers for ui3d.js nextRound and for battle.js
  liveFrom, queueDeath, startSideTurn and applyHit: cited by
  function name in the DeepSeek leg, because the raw page view
  carries no line numbers. This synthesis does not invent them.
