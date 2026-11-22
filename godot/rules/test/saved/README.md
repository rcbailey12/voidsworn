# Saved Godot results

Issue 990, Path D step 3. Since issue 1654 (R405, Nov 22 2026) the browser rules
twin is retired and this is the rules gate: `run_parity.sh` runs Godot alone and
compares every battle, the PRNG draws, the math verdict and the threat maps with
the results accepted in the repo. The math inputs come from the saved `math.txt`.
`RULES_TWIN=browser` still runs the old comparison with the frozen browser files,
for history only. It exports to a scratch file, never to the live table, and stops if
the Godot table no longer matches the frozen export. CI also lists every saved result
a branch changes compared with main (`diff_vs_main.js`), so a deliberate update stays
visible even when the check is green. Read "browser parity" below as that historical mode; an update
needs no browser check in the default mode. The campaign has its own saved
results: `godot/campaign/test/saved/`, checked by `run_campaign_checks.sh`.

Double-click `tools/pc/saved_results.bat`, or call it with `nopause` from a watcher.
It runs fresh parity and this check using the same Godot batch records. It prints
PASS or FAIL, battle names, the saved comparison time, and the whole parity step
time. It discovers bundled Node 22 and `godot_path.txt` above any lane checkout;
an existing `GODOT` override is honored. No campaign check is added to this
launcher. The ordinary `parity.bat` keeps its campaign hand-off.

On Linux, `GODOT=/path/to/godot sh godot/rules/test/run_parity.sh` runs both gates.
No new CI command or second Godot run is needed. The existing parity step runs
this gate even when earlier parity comparisons failed. Its original failures
still count and cannot be cleared by changing these saved results. The Godot-only
cache and ruled-number safety net remains separate.

## Files and size

`results.json` has one entry per scenario: the SHA-256 of its exact Godot JSONL
bytes, raw byte length, record count, scenario hash, and archive name. Separate
entries save the 10,000 draws for seeds 1001, 7 and 4242424242, the math inputs
with all expected values, Godot's successful math verdict, and threat maps s4,
s19 and s23, rounds 1 to 3. The math harness checks those input values inside
Godot; it does not write a second computed-values file. We preserve the verified
input file and its verdict instead of claiming the engine wrote one.

`records/*.br` preserves the exact result bytes with Brotli quality 5 and a 16 MB
window. This was smaller than ordinary gzip on the repeated large battle states
and retains every field needed to explain a change. Node 22 supplies compression
and decompression; no extra package is needed. Timing samples, engine banners,
worker paths and player saves are excluded. The saved manifest plus 289 archives
occupies 5,277,069 bytes, about 5.03 MiB, at the initial baseline. The manifest is
plain text so a PR visibly names every changed battle; only its changed archives
need rewriting. The checker verifies the archive hashes even for unchanged
battles, validates every state hash, and requires complete original batches.

The original files total 916,029,631 bytes. On s1, s4 and s23, gzip level 9
uses 31,509, 1,151,862 and 4,395,737 bytes; the chosen Brotli form uses 13,172,
28,758 and 66,819 bytes. Its larger window suits repeated complete states.

## Review and update a rules change

1. Run parity or `saved_results.bat`. Intended battle changes fail the saved gate.
   Read `changed-battles.txt` in the printed temporary run folder. Each changed
   battle gets its first turn, round, unit, field, before and after values, then
   the number of later changed records and the old and new record counts.
2. Judge those differences against the intended rule. The first field is selected
   from units, then battle state, then globals; keys inside those groups are
   sorted. Units are compared in their recorded order. This helps find a changed
   hull before its downstream log message, but is not a claim about root cause.
   Later counts compare records at the same turn index, not matching actions
   after the two battles have diverged. Large values are shortened to 180
   characters; exact values remain in the archives and live record files.
3. When the change is accepted, use the bundled Node to run:

   ```text
   node godot/rules/test/saved/update.js --from <the printed parity run folder>
   ```

   Every original parity check must have passed. A saved-gate failure alone is
   allowed. A partial run, unfinished worker, changed scenario since the run,
   missing record, invalid hash or failed math check refuses the update.
4. Include `results.json`, its changed archives, and `changes.txt` in the same PR.
   The updater writes `changes.txt` with the old and new manifest hashes and the
   before/after report. Later checks and no-op updates leave that report intact.
   Link it from the PR description, and explain which differences were intended.
   Rerun the check against the saved run to verify the updated baseline:

   ```text
   node godot/rules/test/saved/check.js --from <the printed parity run folder>
   ```

Updating never runs automatically. It rewrites existing files but deletes
nothing. Removed scenarios disappear from the manifest; their old archives can
remain unreferenced. A reviewer can reconstruct an exact saved record with:

```javascript
const R = require('./godot/rules/test/saved/records');
const bytes = R.unpack(R.HOME, R.manifest().battles.s1);
require('fs').writeFileSync(process.env.TEMP + '/saved-s1.jsonl', bytes);
```

Explicit battle arguments to `run_parity.js` remain diagnostic subset runs.
They check that subset plus the normal PRNG, math and threat files; they cannot
update the complete baseline. The ordinary PC and CI commands use every scenario.

## Evidence, checks and CI

The pilot and observed PC timing are in
[the pilot report](../../../../docs/shots/saved_results/README.md).
`node godot/rules/test/saved/self_test.js` exercises gate failures and updating
using small temporary fixtures. `GODOT=... node godot/rules/test/saved/pilot.js`
recreates F2, F5, historical PRs 442 and 797, and the extra PR 449 noise control
under TEMP, and writes reports and `pilot.json` under `docs/shots/saved_results`.
It never changes the checkout's rules. Historical copies receive only batch
completion print lines needed by the evidence guard; rules, bot and record
writer come from the named commits. Each historical pair runs the merged PR's
scenario suite in both arms. This holds PR 797's eight reseeded fixtures
constant rather than confusing seed changes with rules changes. F2 re-exports both tables.
Each planted case runs all scenarios in Godot, then checks browser parity on
every changed battle. The pilot is evidence work, not a new standing CI job.

Every normal run keeps `changed-battles.txt`, `saved_summary.json`, and the whole
`summary.json` in a fresh temporary folder. In CI the runner uses `RUNNER_TEMP`
and appends the report, saved comparison time and whole-step time to
`GITHUB_STEP_SUMMARY`. A rules PR's tracked `changes.txt` remains directly linkable.

The PC worker may not edit workflows or push, so this job has no measured CI
run yet. The existing workflow already enforces the gate through `run_parity.sh`.
For downloadable evidence on failed CI runs, the Board should add this step
immediately after the existing rules parity step in `.github/workflows/checks.yml`:

```yaml
- name: Keep changed-battles evidence
  if: ${{ always() }}
  uses: actions/upload-artifact@v4
  with:
    name: saved-godot-results
    path: |
      ${{ runner.temp }}/voidsworn-parity-*/changed-battles.txt
      ${{ runner.temp }}/voidsworn-parity-*/saved_summary.json
      ${{ runner.temp }}/voidsworn-parity-*/summary.json
```

This upload is for access to the files; the gate and CI timing do not depend on it.
