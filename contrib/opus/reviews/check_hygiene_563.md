# Issue 563: check-suite hygiene (sweep 545 rows 1, 8, 9, 10)

Refs #563. Branch work/issue-563-deepseek. DeepSeek workhorse, opus seat released. ASCII only, no em dashes.

## Changed files

1. contrib/opus/tools/run_all_checks.js: a check row can now be marked as a gating row (`gate: true`, :125-126).
   `--fast` still runs a gating row instead of skipping it (:224-225), and a gating row that still reports SKIP
   is turned into FAIL (:234). The 120-2 enum row is marked gating (:135).
2. godot/campaign/test/node/nem_assign_enum.js: the malformed-assignment failure and the hunter-not-in-RUN.foes
   failure have separate counters (`badLen`, new `missingFoe`, :27, :32, :36) and separate rows
   "120-2 assignment length" (:50) and "120-2 hunter is a run foe" (:51).
3. godot/story/rival.gd: the comment at :6-7 now names C.nemRead (the screen read) and C.nemActive (the campaign
   resolver) instead of RUN.nem.
4. contrib/opus/reviews/check_hygiene_563.md: this report.

## 248 NOTE 4 (a gating check must not become SKIP under --fast)

Route chosen: the gating row runs under --fast. A non-gate slow row still SKIPs, so the fast path keeps its
purpose; the enum gate is always in force. Proof:

```
node contrib/opus/tools/run_all_checks.js --only nem_assign_enum --fast
nem_assign_enum | PASS | 0.63 | PASS: all issue 120 enumeration checks

node contrib/opus/tools/run_all_checks.js --only r1_tests --fast
r1_tests | SKIP | 0.00 | SKIP: fast
```

## 248 NOTE 5 (two failures under one label)

Fixed at nem_assign_enum.js:27, :32, :36, :50-51. The quick gate now prints five rows, one per constraint,
including "120-2 hunter is a run foe missing=0" next to "120-2 assignment length bad=0".

## 248 NOTE 10 (rival.gd comment)

Fixed at godot/story/rival.gd:6-7.

## 248 NOTE 1 (campaign_ui.gd reader of the local alias)

Already fixed on main; no reader remains. The sector modal no longer reads `R.get("nem")` or `R["nem"]["fac"]`:
it draws `adaptWho`, `adaptFac` and `adaptWhy` from its payload (godot/ui/campaign/campaign_ui.gd:1636-1642), and
the payload is built from nemActive() in godot/campaign/campaign.gd:3020-3029. A repo search for
`R["nem"]` / `R.get("nem")` under godot/ui returns nothing. No change needed.

## 248 NOTE 7 (scenario twins)

Already standing; no change needed.
- .github/workflows/checks.yml:97-99 runs `sh godot/campaign/test/run_nem_scenarios.sh`.
- That script runs node node/nem_scenarios.js and res://campaign/test/nem_scenarios.gd and compares them byte
  for byte (godot/campaign/test/run_nem_scenarios.sh:6-8).
- The .gd twin has its line at godot/tools/ci/godot_checks.txt:23 (setup step: Nemesis scenarios).
- Local proof: `PASS: Nemesis scenarios identical (219 records)`.

## 248 NOTE 8 (report only: does drawing the panel or portrait create run state?)

No. The drawing paths read through C.nemRead, which never migrates, creates, draws or writes the cache.
- Path: campaign_ui.gd `_nemesis_block` (:933) gets N from View.nemesis(C) (:765, :785); `_dossier` (:1010) and
  `nem_portrait` (:1131) get N from View.nem(C).
- campaign_view.gd `nem` (:109-110) returns C.nemRead().
- campaign.gd nemRead (:1961-1988) resolves the current assignment against the registry and returns one of the
  already-built records; it has no nemMigrate, no newNemesis, no RUN write and no rnd() call.
- The lazy create still exists for rules callers: nemActive (:1951-1960) does `reg[fac] = newNemesis(fac)` (:1957)
  and points RUN["nem"] at it (:1959), and newNemesis draws from the run PRNG (rnd, pick, shuffle,
  campaign.gd:1871-1886). The panel and portrait no longer call that path.
- Proof: `Map read-only: PASS (119 checks)` (the test opens the real map, Dossier and Map key on runs whose
  record is present and deliberately missing, and holds the run, save and random stream unchanged).

## 274 (the two pronoun-class text sites)

Already fixed on main (PR 282); no change needed. Both twins now pass the text through nemSay.
- (a) sector modal adaptation reason: campaign_run.js:715 uses nemAdaptWhyLine; Godot builds `adaptWhy` with
  nemAdaptWhyLine (campaign.gd:3029) and draws it at campaign_ui.gd:1641. Records ag2 and ag4 show
  `"her own way of war"` and `"its own way of war"` in the built modal.
- (b) map card strike line: campaign_run.js:320-321 `nemStrikeLine` wraps nemSay. Godot campaign.gd:2065-2066
  does the same, and the card reads it at campaign_view.gd:143 and :179. Scenario record ag1 reads
  `"Her fleet is coming: your next fight is her."` and ag3 reads `"Its fleet is coming: your next fight is its."`
- (c) clock-full message: campaign_run.js:319 and campaign.gd:2062 wrap the message in nemSay. Record ae1 reads
  `"Your next fight will be against its fleet."`, ae2 and ae3 read `"against her fleet"`. The cited scenario run
  above includes these records (identical in both twins) and passed.

## 341 condition 1 (audit.py must fail when ANY gun lacks a mount normal)

Already fixed on main; no change needed.
- tools/recipe/audit.py:32-33 builds `bare` and appends a failure when any gun's normal is None, so one missing
  normal fails stage 4 (not only all of them).
- tools/recipe/audit_selftest.py:13 and :23-25 break one gun's normal and require the audit to refuse it;
  tools/recipe/4_parts_kit.bat:17-18 fails stage 4 when the self-test does not.
- Not run here: the recipe needs Blender and a built blend, which this seat does not have. The code path is
  already on main, so there was no new line to test.

## 349 (campaign view read-only claim and the map3d detail lines)

Already fixed; no change needed.
- Condition 1: campaign_view.gd's header :10-16 states the nemRead contract; `nem` is nemRead (:109-110),
  `nem_node_is` passes the commander (:113-115), and the fight card uses it (:281). No nemActive in the view.
  `Map read-only: PASS (119 checks)` is the property test.
- Condition 2: the three old detail lines are handled. The shape/modifier line and the reward line now sit in
  the tip card, a solid panel (map3d.gd:1069 theme, :1082-1086 content). The IN FLIGHT line carries the dark
  halo (map3d.gd:1000-1002, GS.halo_text), and the campaign map is the named exception to the backing rule
  (contrib/opus/briefs/ui_style.md:23-24; docs/playbooks/screens.md:28).

## Checks run

```
node contrib/opus/tools/run_all_checks.js
checks_truth_tests | PASS | 0.06 | PASS: the checks runner result words behave as issue 358 requires
oracle_copy_test | PASS | 0.26 | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files
save_fuzz | PASS | 0.10 | PASS: exit 0
nem_assign_enum | PASS | 0.50 | PASS: all issue 120 enumeration checks
```

The full table had no FAIL row and no SKIP row (PASS and the two KNOWN rows: findings_tests and
oracle_drift_guard, both inside their baselines).

```
node godot/campaign/test/node/nem_assign_enum.js
PASS 120-2 assignment length bad=0
PASS 120-2 hunter is a run foe missing=0
PASS 120-2 no own-faction hunter own=0
PASS 120-2 no H2=H1 repeat count=0
PASS 120-2 no H3=H2 repeat count=0
PASS: all issue 120 enumeration checks
```

```
cmd.exe //c "tools\pc\parity.bat nopause"
PASS: the Godot port matches the game's rules exactly.
PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
```

```
GODOT=<godot console exe> sh godot/campaign/test/run_nem_scenarios.sh
PASS: Nemesis scenarios identical (219 records)
Nemesis read: PASS
Map read-only: PASS (119 checks)
```

## How the change reaches the rest of the game

- Callers: searched the repo for `badLen`, `missingFoe`, the enum file name, and `buildChecks`/`gate`. The enum
  counters are local to nem_assign_enum.js; the new `gate` argument defaults to false, so every existing
  `add(...)` call keeps its old meaning. checks_truth_tests (which imports the runner) PASSed.
- Saves: no save field added, renamed or reshaped; player profiles and run saves are untouched. The full check
  pack includes save_fuzz (PASS) and campaign parity compares the saved copy on all 30 seeded runs (PASS).
- Twins: no change to battle.js, data.js or core.js, so no table re-export was needed. oracle_copy_test PASSed,
  and rules parity and campaign parity PASSed.
- UI: no UI file changed. The Nemesis panel, portrait, Dossier and map paths were traced and already read through
  C.nemRead; the 274 text sites (card strike line, clock-full line) already go through nemSay in both twins.
- CI: no new test file, so nothing to add to run_all_checks.js. GitHub runs `node contrib/opus/tools/run_all_checks.js`
  (checks.yml:56) without --fast, so the enum gate ran there before this change too; it now also runs under --fast.

## Skipped

- The recipe stage 4 and 7 bats: they need Blender and a built blend. The audit.py and audit_selftest.py lines are
  already on main, so this seat had no new recipe code to exercise.
- The full headless Godot check list: not run here. The relevant behaviour tests were run directly (Nemesis
  scenarios, read test, map read-only), and parity ran the rules and campaign suites.
