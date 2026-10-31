# Voidsworn cutover gate

Status: built Oct 30, 2026 (beyond-scope slate, item 4). Plain Node, no
dependencies. One runner that executes every verification tool the audit
programs produced, reduces each to a signature, compares the signatures
against a recorded baseline, and prints one verdict. Built so Ryan can run
it by double-clicking a file, and Opus can run it like a CI step before
the Godot cutover (and after any data or rules change).

## Run it

Windows, no terminal: double-click `run_gate.bat`. It finds Node, finds
the repo (drag the repo folder onto the .bat, or let it use the repo it is
installed in, or `%USERPROFILE%\workspace\voidsworn-fresh`), runs the gate,
opens `gate_report.md`, and pauses on the verdict.

Anywhere: `node gate.js [repoDir] [--update-baseline] [--out <dir>]`

Exit code is 0 for PASS, NO CHANGE, or IMPROVEMENT, and 1 for REGRESSION
or INCOMPLETE, so a script can gate on it.

## What runs, and what each component proves

| Component | What it proves |
|---|---|
| Findings regression suite | Every BLOCKER/FIX finding from the Oct 27 to Oct 29 audit programs, the wave 3 deep QA sweep, and the wave 5 patch pack stays pinned by a test. A FAIL is a defect that is still unfixed; the test flips to PASS when a real fix lands. Baseline at recording: 80 tests, 8 pass, 72 fail. |
| Oracle drift guard | The Godot port's vendored JS oracles have not drifted beyond the recorded staleness, every oracle README pin claim still holds against git history, and the hand-copied render/world constants match the recorded comparison (120 entries: 95 matched, 25 differed, 25 browser-only at recording; the differing set is the known, documented staleness, worst in the PLANETS tables). |
| Validator: table cross-references | No id in the game data tables dangles: faction rosters and bosses, hull and variant weapons and arcs, admiral starts, boon patrons, module gates, relic name rows, price and gate rows. Baseline: 0 failures, 11 warnings (the warnings are the standing watch list: relic display-name coverage, four capital-class price gaps, the spore id collision). |
| Validator: naming linter | Current-voice docs (root docs plus docs/) do not use retired display names. Baseline: 1 hard hit ("Mending Choir" in BACKLOG.md), 100 label candidates for human triage, 13 historical/id mentions. |
| Importer fixture loader checks | All 21 recorded browser save stores (18 single-file cases plus 3 input/output pairs) still load through the game's own Persist.loadLocal, pass saneSave, and produce exactly the loaded state recorded in the fixture files. |
| Importer reference converter tests | The reference browser-to-portable converter converts all 21 fixture cases plus the synthetic repaired-copy fallback (22 checks), and its independent accounting finds no id or tracked value that disappears, appears, or changes unreported. |
| Telemetry reference demonstration | The telemetry spec addendum's lineage join catches the cross-run Nemesis adaptation clash (a weakness revealed on a loss in run 1, adapted against in run 2) that the filed spec's same-run join misses, with no false positive. Runs from a scratch copy inside the gate folder, because the demo writes its dataset beside itself. |
| Parity vector corpus (plug-in slot) | NOT RUN today, by design. See below. |

Components are located under `contrib/muse/tools/` in the tools tree the
gate is installed in, falling back to the checked repo's own copy, then
the chair staging tree. A component that is missing, times out, or errors
reports NOT RUN with the reason. NOT RUN is never counted as a pass.

## How to read the verdicts

Each component gets one verdict, and the gate's overall verdict is the
worst of them (REGRESSION beats IMPROVEMENT beats INCOMPLETE beats
NO CHANGE beats PASS):

- **PASS**: ran, signature identical to baseline, and the baseline state
  is clean for that component.
- **KNOWN-FAIL**: ran, signature identical to baseline, and the baseline
  itself records known failures. For the findings suite this is the
  normal state: 72 pinned defects, none moved. For the drift guard it
  means the drift is exactly the recorded staleness, no more, no less.
  For the naming linter it means the one known hard hit is still the
  only one.
- **REGRESSION**: a failure appeared that is not in the baseline, or an
  item that was passing (or tracked) vanished. Stop and look before
  anything ships.
- **IMPROVEMENT**: something in the baseline failure set no longer
  fails. Either a fix landed (good) or a test rotted (bad); a human
  looks, confirms which, and then refreshes the baseline.
- **NOT RUN**: the component could not run. The gate is incomplete;
  the overall verdict says so.

The signature is sets, not counts: the exact ids failing and passing.
Counts alone would hide a swap (one defect fixed, a different one
broken), so any change in set membership moves the verdict.

## The baseline

`baseline.json` beside `gate.js` records the signatures measured on
Oct 30, 2026 against clone HEAD cbffcafef9d3bb1c653feb72430f7a125871e315.
It is only ever rewritten by an explicit `node gate.js --update-baseline`
run. A normal run never touches it. Refresh it deliberately: after a fix
lands and the IMPROVEMENT verdict has been eyeballed, or after a
component is added and its first state accepted.

Two honest cautions about what the baseline means:

- The findings suite baseline (8 pass / 72 fail) pins the shipped code,
  not an aspiration. If Opus fixes defects, expect IMPROVEMENT verdicts
  in batches; that is the gate working.
- The drift guard baseline records two parity suites certifying two
  different snapshots (Oct 26 and Oct 27), neither at HEAD. When Opus
  re-pins both oracles to one agreed commit before cutover (the drift
  guard report's own remedy), the drift verdict will move to
  IMPROVEMENT; refresh the baseline at that point.

## The parity vector plug-in slot

The parity vector corpus (deterministic battle-layer behavior vectors
captured from the browser engine, for the Godot port to replay) is a
separate slate item and is not built yet. The gate already carries its
slot: the `parity_vectors` component looks for
`contrib/muse/tools/parity_vectors/run_vectors.js`. Until that file
exists the component reports NOT RUN with the reason, and the overall
verdict is INCOMPLETE rather than PASS. When the corpus lands, its
runner must print per-vector lines `PASS vector <id>` / `FAIL vector
<id>` and a summary line `parity_vectors: <pass> pass, <fail> fail,
<total> total`; the slot then activates with no gate changes, and its
baseline can be recorded with the next --update-baseline run.

## Files

- `gate.js`: the runner. Zero-dependency Node.
- `fixture_check.js`: the fixture loader check (gate-side; mirrors the
  fixture generator's own verification pass without regenerating
  anything).
- `run_gate.bat`: the double-click launcher.
- `baseline.json`: the recorded signatures.
- `gate_report.md` / `gate_report.json`: the latest run's reports,
  overwritten each run.
- `scratch/`: where file-writing components run from. Safe to delete;
  recreated each run.

The gate never modifies the repo it checks.
