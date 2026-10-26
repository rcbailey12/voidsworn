# Travel sprint Job A: rules port review (chair synthesis, Oct 26, 2026)

Scope: godot/rules/ against the JS oracle, per the engine proof
audit synthesis trap list. godot/campaign/ is NOT reviewed here:
its parity harness has not landed, and that part repeats when it
does.

Three blind legs, all filed and screened: DeepSeek
(contrib/deepseek/sprint_jobA_deepseek_raw_2026_10_26.md), Qwen
(contrib/qwen/sprint_jobA_qwen_raw_2026_10_26.md), and Argon
(contrib/gemini/reviews/gemini_sprint_jobA_argon_high.md). Weight
differs, and the synthesis keeps the tiers separate. Qwen and Argon
could not fetch live files and worked from the pack only, so their
findings are checks to close, not observed defects. DeepSeek
attached both pack files and read real files (rules.gd to line
417, battle_api.gd, jsm.gd, parity_main.gd, golden.js,
scenarios.json), so its harness and hash findings are OBSERVED at
that scope, but it did NOT read the full rules.gd battle layer:
every claim about functions beyond its truncated read is INFERRED
or UNSURE. No leg in this set read the full battle layer. That
limit shapes the whole verdict.

## Verdict: parity passing today would not prove the port matches

Two observed hash gaps mean a port bug in terrain holes, sight
lines, death-tail order or ship ids passes parity silently. On top
of that, the five golden scenarios cover only rout fights on open,
station and belt maps, so most of the battle layer is never
reached by a hash comparison at all. The port may well be correct;
this review cannot say so yet, because the harness does not yet
measure the parts most likely to differ. Fix the hash first, then
grow the scenarios, then run the sweep. Until then, a green parity
run is weak evidence, not a pass.

## Ranked findings

### 1. CUT and SOLID are hashed nowhere [DeepSeek OBSERVED, top risk]

rules.gd:27-28 declares CUT and SOLID at module level.
rules.gd:351 sets both inside genTerrain. rules.gd:238 reads CUT
in onBoard. SOLID is the hole set that blocks sight and is read
by sightBlocked and los. Neither variable is inside B, and
parity_main.gd:30-37 hashes B with SKIP_B = {units, log, cfg,
prog} and each unit with SKIP_U = {t, ship}. So CUT and SOLID are
in the canonical text on neither side. A port bug in cut-hex or
hole detection would change onBoard, sightBlocked and los without
changing the hash, and parity would pass while movement and line
of sight differed.

Opus action: add CUT and SOLID to B or to the canonical writer,
hash them as sorted arrays, and add a scenario with holes that
asserts sightBlocked and los results (scenario 2 below).

### 2. deferred and UID are hashed nowhere [DeepSeek OBSERVED, top risk]

rules.gd:29 declares deferred and UID at module level. deferred
holds the pending killUnit tails that flush_deferred runs. UID is
the ship id counter. Neither is in B, and neither is in
parity_main.gd:30-38. deferred controls the order in which death
tails run at the next flush. UID controls every new ship id. A
port bug that reorders deferred tails or skips a UID increment
would not be caught, and a reordering that leaves the final state
unchanged would pass even though event order differed.

Opus action: hash deferred as an ordered list of queued unit ids
and UID as a number, and add a scenario where a turn-start tick
queues a death, the tail runs, and the event order is asserted
(scenario 3 below). This also closes Argon's deferred-tail case
(tick-death tails vs nova chain deaths and gravity well pull
deaths) and DeepSeek's trap H point: the hash must measure order,
not just final state.

### 3. The golden scenarios cover a narrow slice [all three legs agree, DeepSeek OBSERVED from scenarios.json]

s1-s5 are all obj: "rout", on open, station and belt maps only.
There is no deadstar shape, no convoy, no breakthrough, no
boarding, no station-gun assertion, no ability-complete test and
no command-complete test. At most 2 to 3 of the 8 fight types are
covered, and only Hegemony and Corsair appear. A guard, a branch
or a whole mechanic that no scenario reaches cannot fail parity,
no matter how wrong it is.

Opus action: the merged ranked scenario list below, in that
order. The gravity well goes first because it is the most
branch-heavy terrain path; the two hash-driven scenarios go
second and third because they prove findings 1 and 2.

### 4. Enemy fleet generation is unported, and every scenario bypasses it [Qwen/Argon, DeepSeek scenario 12, API.md stated]

API.md states enemy fleet generation is not yet ported and that
today every scenario passes enemies. When generation lands, the
PRNG sequence shifts, so hashes recorded before it lands are not
directly comparable to hashes after. This is a known gap, not a
surprise, but it is still a missing scenario: when the port lands,
a scenario that omits cfg.enemies and asserts the generated fleet
matches JS must be added before any sweep result is quoted.

### 5. NOT PORTED guards that never fire [all three legs, INFERRED/UNSURE, grep task]

rules.gd:68-69 defines np(), which sets the NOT PORTED marker.
DeepSeek lists the functions most likely to contain guards or call
functions that do (genEnemyFleet, makeWing, deployWings, sqRole,
sqWants, sqPlan, sqAct, swarmPhase, squadronsOf, bossCmdTick,
bossCmdFire, cmdTier, cmdRec, cmdPow, cmdActive, cmdTaken,
runCommand, tacticRam, tacticBoard, escortsBreak, objectiveTick,
checkEndRules, setupObjective, objAfterMove). The structural risk
is a guard on a path that is itself only reachable through another
unported branch, so the guard never fires and the missing code
never shows. Argon adds the AI-scoring variant: a guard inside an
AI scoring path that no scenario's bot choice reaches.

Opus action: grep rules.gd for every np() call, list the branch
condition that reaches it, and add a test that forces each branch.
Mark each guard as firing or not firing. Do not close this item
on a grep count alone; an unfired guard is the finding.

### 6. The README is behind the code [CHAIR-CONFIRMED, Qwen/Argon]

The test README says records are written "after every
activation". Commit 9273632e records per action: hooks,
abilities, orders, ticks, activations and rounds. The README is
stale, and a reader trusting it will misunderstand what the
harness measures.

Opus action: update the README to itemise every record point.
Kept separate from this is Argon's INFERRED harness half, which
stays UNSURE: compare.js or parity_main.gd filtering by
activation boundaries, or mid-activation hooks inside aiStep()
never being snapshotted. That half needs the harness files read,
not a README edit.

### 7. Trap D and trap F in the unread battle layer [INFERRED/UNSURE, grep tasks]

What DeepSeek read is handled: jt at rules.gd:70 avoids the
Object.tr collision, is_same is used for unit identity in
battle_api.gd:88, :92, :128 and :161, jsm.gd:39-41 implements V8
round, jsm.gd:41-61 writes the fdlibm constants as IEEE words,
jsm.gd:114-126 names the atan helper _atan (a bare atan() would
call Godot's builtin), jsm.gd:220-228 is a stable merge sort, and
jsm.gd:236-237 formats canonical numbers as integers or "d:" plus
hex64, avoiding str() on floats. The battle layer beyond the
truncated read is unverified for all of it: int/int truncation, %
on floats, builtin round(), == on dictionaries, str() on floats,
bare sin/cos/atan2/exp/hypot/round calls instead of JSM calls,
JSON int recovery (int where JS treats a field as an integer,
exact double where JS treats it as a number), and long-decimal
literals. Likely hot spots named by DeepSeek: hitChance,
motionHit, expectedVs, applyHit, damageSection, repairSection,
systemDamage, ramEstimate, ramInfo, boardOdds, captureChance,
cmdPow, dmgMult, guardMul, ionOf, pathField, fieldDist,
aiArcSoon, aiObjScore, aiObjUrgency, sqValue, sqObjNear, plus
sightBlocked, los and genTerrain for trig and terrain noise. A
last-bit atan2 difference can flip a facing boundary; a last-bit
sin difference can change terrain noise.

Opus actions, as greps with each hit classified as intended or a
bug: (a) rules.gd for /, %, round(, == on dictionaries and str(
on floats; (b) rules.gd for sin(, cos(, atan2(, exp(, hypot( and
round(, confirming every hit is a JSM call, not a builtin;
(c) rules.gd and battle_api.gd for .sort( and .sort_custom(,
plus a line-by-line comparison of every sort in battle.js to a
JSM.ssort call in the port. On sorts, what DeepSeek read all goes
through JSM.ssort (rules.gd:262, :392, :395; battle_api.gd:169,
matching the JS activation sort at golden.js:66), but the full
grep is still open. Argon's two most specific checks belong in
this batch: comparator float truncation (int casting of a float
comparator difference in (-1.0, 1.0) collapsing to 0) and
Dictionary-iteration pre-sort order. Argon's leg-stated atan2
divergence percentage is NOT carried as a measured figure.

### 8. Event queue and combat log: omitted on both sides, hooks are the order check [DeepSeek OBSERVED, Argon refined]

SKIP_B includes log on both sides (golden.js:133 and
parity_main.gd:30-31 match exactly, as do the SKIP_U sets), so the
combat log is not hashed on either side. That is aligned, not a
mismatch, but it means event order is measured only through hook
records: golden.js:37-43 actively wraps useAbility, giveOrder,
startSideTurn and useCommand with hook() calls, and
parity_main.gd:122 records every hook. DeepSeek corrects an
earlier note here: the Node harness DOES hook abilities, orders,
ticks and commands; the block is active, not commented out. The
remaining risk is Argon's inferred half in finding 6 (events
between hooks, mid-activation hooks) and finding 2 (deferred tail
order), both closed by the deferred-tail scenario, not by
assuming the log is covered.

### 9. Tables export completeness [DeepSeek/Argon UNSURE, fail-hard check]

rules.gd:41-44 checks a SHA-256 of tables.json and refuses to run
on a mismatch, and _dec() at rules.gd:63-66 decodes #d: hex words
back to doubles. But whether every table that data.js, core.js
and battle.js build at runtime is present in tables.json is
UNSURE in all three legs: the export script and the full tables
file were not read by any leg. Argon adds the sharpest form:
tables.json silently dropping functions, Infinity, NaN, undefined
or lazily built tables would pass the SHA check (the SHA only
proves the file matches itself) while the port ran on incomplete
data.

Opus action: an export fail-hard check that enumerates every
runtime-built table on the JS side and asserts its presence in
tables.json, before any sweep result is quoted.

### 10. What is confirmed good (keep, do not re-litigate)

- SKIP_U and SKIP_B match exactly between the Node and Godot
  harnesses (DeepSeek F8).
- Node harness hooks for abilities, orders, ticks and commands
  are active on both sides (DeepSeek F7).
- jt, is_same, V8 round, IEEE-word fdlibm constants, _atan
  naming, stable merge sort and hex canonical numbers are handled
  in the code DeepSeek read (F10, F11, jsm.gd).
- Every sort DeepSeek could read goes through JSM.ssort, with no
  bare sort or sort_custom in the parts read (F9, partial).
- The harness records per action, not only per activation, on
  the code that is on main (commit 9273632e; the README just
  does not say so yet, finding 6).

## Ranked list of missing golden scenarios (merged from all three legs)

1. Gravity well (dead star). Pulled state, tick kind "tidal",
   WELL_RIM, WELL_PULL, WELL_ASSIST, WELL_DMG, deadstar shape cut.
   No scenario has a deadstar shape or a dead-star map today, and
   the well is the most branch-heavy terrain path.
2. CUT and SOLID line of sight. A shape that produces holes
   (rift or shoals) with sightBlocked and los assertions. Proves
   finding 1 after the fix.
3. Deferred death tail. A turn-start tick queues a death, the
   tail runs at the next await point, and event order is asserted.
   Proves finding 2 after the fix. Covers tick-death tails vs
   nova chain deaths and gravity well pull deaths.
4. Boarding outcomes. result "capture", "overrun" and "raid". No
   scenario calls board or tacticBoard. Capture changes a ship's
   side, a large state change the hash must catch.
5. Convoy and breakthrough. Escort fled, breakthrough, convoy
   getting through. Exercises obj.type "break" and the fled event,
   neither of which is exercised today.
6. All eight fight types. s1-s5 exercise only rout on open, belt
   and station maps. The remaining types must come from battle.js
   (see the count note below); no leg's hypothesized list is
   adopted here.
7. Station guns. s1 and s2 sit at a station map but never assert
   station guns fire (hit with unit null, per the API.md event
   table).
8. Squadrons and commands. Squadron roles, plans and actions, plus
   boss command ticks and fires. Covers the np() guard cluster in
   finding 5 from the scenario side.
9. All abilities and all commands, one dedicated scenario each
   where the bot alone cannot be relied on to choose them. The
   ability and command events and their state changes must be
   reachable, not incidental.
10. Section-down effects. section_down for prow (forward guns
    silenced), mid (broadsides and shield generator) and eng
    (engines crippled). No scenario forces a section to zero.
11. All death causes and wreck terrain. Every cause asserted, and
    a wreck asserted as blocking terrain. s1-s5 rout fights will
    produce some deaths incidentally; that is not coverage.
12. Turn-start ticks beyond fire. Tick kind "acid", kind "tidal"
    and kind "storm" (ion storm, shields only). s1-s5 may produce
    fire ticks only.
13. Ram runs. Ram event with path, dmg, recoil, soak and section
    asserted. s3's note says "ramming AI" but the scenario is rout
    with no ram assertion.
14. Terrain shapes beyond open and belt. One scenario per shape
    (hourglass, rift, shoals, colossus, archipelago, corridor,
    compact, plus belt, station, planet, storm, graveyard as
    listed at rules.gd:366). Exercises the cut and hole code paths
    and, after finding 1 is fixed, CUT and SOLID themselves.
15. Enemy fleet generation. A scenario that omits cfg.enemies and
    asserts the generated fleet matches JS, added when generation
    lands (finding 4).
16. The 200-seed sweep on the full port, across all 8 fight types
    (X19 bar). The proof slice ran 60 seeds; no evidence in any
    leg shows a 200-seed sweep on the full port. The harness
    supports a seed override (parity_main.gd:121), so the sweep is
    possible; it has not been shown to have run.

## Count discrepancies flagged, not resolved

- Abilities: the pack says "12 abilities" but lists 13 (evasive,
  reload, focus, phase, frenzy, overburn, regrow, reclaim,
  ionpulse, blink, surge, launch, nova), and API.md lists the same
  13. This synthesis does not repeat "12" as fact. The true count
  and list come from the code.
- Death causes: the pack says "8 death causes" but names 7 (cut,
  big, flay, melt, dark, tidal, blast), and API.md lists the same
  7. Argon's hypothesized 8th ("default/hull/ram death") is NOT
  adopted. The true list comes from battle.js.
- Fight types: the pack and audit bar say 8 fight types including
  the gravity well. Qwen's hypothesized set, Argon's "remaining
  2" and DeepSeek's missing-type list are all leg inferences, and
  none is adopted here. The true list comes from battle.js.
- Sort line numbers: the pack-cited battle.js sorts (about 864,
  1073, 569, 1052) do not match battle.js on main (401 lines) or
  the oracle copy (402 lines). DeepSeek found sorts at 43, 228,
  232, 308 and 361 instead. The synthesis does not repeat the
  pack-cited numbers as fact; the sort-matching grep in finding
  7 is the closing check.
- Port size vs the 1.5x threshold: NOT assessable from any leg.
  Byte-derived line estimates (Qwen, Argon, DeepSeek F14) are not
  line counts. The threshold needs wc -l on the port and the
  published estimate, and no verdict is given here.

## Stale lines NOT carried forward

- "fx/API.md is not on main" appears in all three legs at their
  check time. godot/fx/API.md has since been CONFIRMED on main
  (13,540 bytes). It is not a Job A open item, and it is not
  repeated here as current fact.
- DeepSeek's original truncated-read F1 (battle layer missing)
  was withdrawn by the model itself in the revised review. Only
  the revised text is filed, and the withdrawal is not a finding.

## Opus actions, in order

1. Hash CUT, SOLID, deferred and UID on both sides (findings 1, 2).
2. Update the test README to itemise every per-action record
   point (finding 6).
3. Add scenarios 1, 2 and 3 (gravity well, CUT/SOLID sight, deferred
   tail), then the rest of the ranked list in order.
4. Run the grep batch: np() guards with branch conditions and a
   firing test each; trap D arithmetic; trap F math calls; sorts
   to JSM.ssort; comparator truncation and Dictionary-iteration
   order (finding 7, Argon F6).
5. Add the tables export fail-hard check (finding 9).
6. Add the enemy-generation scenario when generation lands
   (finding 4), before quoting any sweep.
7. Run the 200-seed sweep across all 8 fight types on the fixed
   harness and file the output. Until steps 1-6 are done, do not
   present a parity pass as proof the port matches.
8. Repeat this review for godot/campaign/ when its parity harness
   lands.

## Not checked

- Full rules.gd battle layer: not read by any leg (DeepSeek
  truncated at 417 lines; Qwen and Argon pack-only). All
  battle-layer trap claims stay INFERRED or UNSURE until Opus or
  a future leg reads the full file.
- NOT PORTED guard enumeration: not done.
- Tables export completeness: UNSURE.
- Seed sweeps and timing numbers on the full port: not verified.
- godot/campaign/: not reviewed (harness not landed).
- Port size vs the 1.5x threshold: not assessable (see above).
- Exact line numbers for battle.js functions cited by the pack:
  not verified (see the sort note above).
- Ryan's playtest: not applicable to this job; the harness and
  scenarios stand in for it while he travels.
