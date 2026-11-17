# Rules safety net (Godot only)

Issue 979, Path D step 2. This adds two independent checks beside browser parity.
Parity stays in place. The only game change is `eval_begin()` honoring
`VS_NO_MEMO=1`; with the variable unset its behavior stays the same.

## Run it

On the PC, double-click `tools/pc/rules_safety.bat`. Watchers call
`tools\pc\rules_safety.bat nopause`; the launcher returns a failing exit code
when either check fails. It finds the console executable through `GODOT` or
`godot_path.txt`, including the PC's `Downloads\voidsworn_test\godot_path.txt`.
Set `RULES_SAFETY_WORKERS` to change the default four workers.

On Linux or Git Bash, with Node and Godot on PATH:

```sh
GODOT=/path/to/godot sh godot/rules/test/safety/run_cache_check.sh
```

The shell and PC launcher run the same supervisor, `run_cache_check.js`.
Node only reads/writes files and starts Godot. Neither check imports or executes
browser code, `golden.js`, an exporter, or browser comparison code. They read the
committed Godot tables. Re-exporting tables is an explicit prerequisite of a
data change, handled by the existing parity and freshness checks.

Every invocation creates a fresh `rules-safety-*` directory under the system
temporary folder and prints its location. It keeps partitions, both sets of
records, worker logs and `summary.json` there. Nothing is deleted or written
into the checkout or the player's save folder. Each process has its own
`XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `APPDATA` and `LOCALAPPDATA`.

Diagnostic options (both checks run with no options):

```text
--godot <console executable>  --project <godot directory>
--workers <positive integer>  --timeout <worker seconds, default 600>
--out <temporary output parent>
--cache-only                 --numbers-only
--scenarios <scenario JSON, diagnostic subsets only>
```

CI and the PC launcher always use the complete `scenarios.json` by default.
`--scenarios` is for reproducing a fault quickly, not for narrowing CI coverage.

## What fails

The cache check distributes every scenario over N partitions, round-robin in
file order. It starts one Godot process per partition using the existing
`parity_main.gd -- batch <part.json> <outdir>`, first with scoring caches enabled,
then with `VS_NO_MEMO=1`. An inherited `VS_NO_MEMO` cannot disable both arms.
It compares the `.jsonl` records byte for byte, excluding `.timing.json` files.
Empty, malformed, incomplete or missing records fail by battle name. Worker
launch failures, timeouts, nonzero exits and Godot error logs also fail by name.
Each worker must also print its expected `batch N battles` completion line:
the Windows console wrapper can return zero after the actual engine dies.
On Windows the timeout stops that worker's whole process tree.
If a batch worker dies, every battle assigned to that worker is conservatively
failed, including battles it had already written. No battle is skipped.

The numbers test reads `godot/rules/data/tables.json` directly and compares its
numbers against independent literals. Exported IEEE double strings are decoded
with `JSM.from_hex64`; there is no rounding tolerance. Missing tables or fields
fail each affected named check. The numbers test still runs after cache failure.
It is also registered in `godot/tools/ci/godot_checks.txt`, so the current Godot
game job can run it even before the separate safety job is installed.

## Values for the Board to check

Source: [FINDINGS](../../../../contrib/opus/FINDINGS.md). Each row below is one
line in `ruled_numbers_test.gd` and prints its FINDINGS id, name and expected value.

| FINDINGS | Number checked | Table path | Value |
|---|---|---|---|
| R265 | Eclipse flare hull | HULLS/d_jackal/hp | 100 |
| R265 | Null lance damage | W/nlance/dmg | 15 |
| R265 | Null lance shots | W/nlance/shots | 3 |
| R265 | Null lance range | W/nlance/r | 6 |
| R93 | Thale hull bonus | ADMIRALS/thale/fx/hpPct | 0.10 |
| R93 | Thale shield bonus | ADMIRALS/thale/fx/shPct | 0.10 |
| R93 | Ashgrove squadron hull bonus | ADMIRALS/ashgrove/fx/sqHp | 0.25 |
| R93 | Shared Iron Command base reduction | CMD_POW/iron/0 | 0.40 |
| R63 | Daybreak speed | HULLS/ascendant/sp | 2 |
| R78 | Cinder yards first run | CINDER_FIRST_RUN | 3 |
| R246 implementation tuning | Shield pool multiplier | SHIELD_POOL_MULT | 2 |
| R246 implementation tuning | Shield regeneration multiplier | SHIELD_REGEN_MULT | 1.25 |
| R246 implementation tuning | Shield routing loss | SHIELD_ROUTE_LOSS | 0.30 |
| R246 implementation tuning | Shield routing boost | SHIELD_ROUTE_BOOST | 0.20 |
| R246 implementation tuning | Maximum shield coverage | SHIELD_COV_MAX | 0.95 |

R246 rules the one-pool, per-side coverage and lossy-routing model. It leaves
the exact numbers to the Board, as [data.js](../../../../data.js) lines 62-77
explicitly say. The five shield rows pin those implementation tuning values
at this job's request; they are not claimed as numbers Ryan personally chose.
R93's doctrine values are retained by R95. These are balance inputs a rules PR
could mistype, not measured bot win rates, visual tuning or source line numbers.
An approved balance change updates the relevant expectation and its ruling
reference together; an export alone must never regenerate these expectations.

## Proof and timing

Base: main `7d4db9de71111eedfe72635c88516f5228bad9af`, plus this safety net and
its single requested hook. Godot 4.7.2, Node 22.11.0, Ryan's Windows PC,
November 17, 2026. No faults were planted in the working checkout.

| Check | Observed result | Wall time |
|---|---|---|
| Full PC launcher, 281 battles twice, four workers | PASS, 281 byte-identical pairs; all 15 numbers pass | 479.330 s total |
| Cached arm of full run | PASS, all records present | 172.449 s |
| Uncached arm of full run | PASS, all records present | 301.769 s |
| Final runner, isolated project without browser source, s1/s2/s3/Silent Archive, four workers | PASS, four identical pairs and 15 numbers | 15.625 s |
| F1, both facing keys replaced, Silent Archive only | Expected FAIL, exit 1, `battle t_ecl_silentarchive: cache on/off records differ` | 5.886 s |
| F2, hp 90 in data.js, both tables re-exported | Expected FAIL, exit 1, `R265 Eclipse flare hull`, expected 100, got 90 | 0.663 s |
| Planted self-kill in Silent Archive | Expected FAIL, exit 1, `battle t_ecl_silentarchive`, incomplete batch and missing records | 2.208 s |
| Planted self-kill after both complete records were written | Expected FAIL, exit 1, incomplete batch named for Silent Archive despite identical records; numbers still run and pass | 10.784 s |
| Planted early successful return without writing a record | Expected FAIL, exit 1, missing records named for Silent Archive | 2.372 s |
| Planted delay, one-second worker timeout | Expected FAIL, exit 1, timed-out workers and missing records named for Silent Archive | 2.395 s |
| Missing Godot executable | Expected FAIL, exit 1, launch failure and missing records named for Silent Archive | 0.013 s |
| Git Bash shell entry point, numbers only | PASS, 15 checks | 0.289 s |
| PC launcher discovery and exit-code fixture | PASS, finds bundled Node/Godot without GODOT preset, forwards worker override, preserves exit 17 | under 1 s |

The full launcher run inherited `VS_NO_MEMO=1` intentionally: the supervisor
cleared it for the cached arm and set it for the uncached arm. Full-run logs
from all eight workers were then checked against the batch-completion guard
added after the crash proof; all eight pass. The final runner's isolated
four-battle run and all fault proofs include that guard and process-tree timeout.
Times are observed PC wall times, not CI estimates or frame-time measurements.

The full standing command, `node contrib/opus/tools/run_all_checks.js`, completed
with exit 1: 62 PASS, 2 KNOWN, 1 FAIL, no skips (65 rows, 1106.62 s summed row
time). The sole failure is the existing `picture_provenance_tests` assertion:
`tools/blender/kits/hegemony_station/capture.gd` saves pictures without the shared
stamp at lines 169 and 203. That file and the provenance self-test are unchanged
from base main; the capture file's HEAD and working-copy Git blob ids both equal
`ff049b62a22f4171ce4956edb268f507e757b56d`. This job does not alter that capture.
The two KNOWN rows are the seven listed findings-test failures and twelve listed
oracle constant differences, both accepted by the existing baseline. Syntax,
shell syntax, the Godot test registry, changed-file whitespace and the
no-em-dash check also pass.

Reproduce fault F1 in a temporary copy only: replace both occurrences of
`var uf = int(z0(u.get("facing"))) if treeSkill("silentArchive") != null else 0`
in `rules.gd` with `var uf = 0`. Run the cache check on a scenario file containing
`t_ecl_silentarchive` from the real scenarios. It must return 1 and name that battle.

Reproduce F2 in a separate temporary copy: change only `d_jackal`'s `hp:100`
to `hp:90` in `data.js`, then run both exports from that copy:

```sh
node godot/rules/test/node/export_data.js godot/rules/data/tables.json
node godot/campaign/test/node/export_campaign.js godot/campaign/data/campaign_tables.json
```

Run the safety net with `--numbers-only --project <copy>/godot`. It must return 1
and print `FAIL: R265 Eclipse flare hull`, expected 100, got 90. Browser code runs
only while preparing this intentionally re-exported fault, never in either check.

For the crash proof, insert this at the start of `scenario()` in the temporary
copy's `parity_main.gd`, then run the same Silent Archive fixture:

```gdscript
if name == "t_ecl_silentarchive":
    OS.kill(OS.get_process_id())
    return 37
```

Both worker processes die; the check must return 1 and name the battle, worker
failure and missing record. Replacing that block with `return 0` for the named
battle tests missing records even when a worker exits successfully.
The second crash proof puts the self-kill in `batch()`, just before its final
completion print, after `scenario()` has written its records. Both records
are complete and identical; the missing completion marker still fails the battle.

## CI job for the Board to install

`CODEX_TASK.md` explicitly forbids this PC worker from editing anything under
`.github/workflows` because its token cannot push workflow edits. Consequently
the separate cache job is **not yet installed**, and its actual CI time is
**not measured**. No CI run was started or claimed: this job also forbids pushes.
The Board must add the following one job under `jobs:` in
[checks.yml](../../../../.github/workflows/checks.yml), beside `godot-parity`,
without altering any existing job's steps. It uses the same checkout, merge,
Node and Godot setup as parity. Parity does not run an editor import; these
rules scripts use direct GDScript preloads and also need no asset import.

```yaml
  rules-safety:
    name: Rules safety net (Godot only)
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Merge main in (test the branch as it would land)
        if: github.ref != 'refs/heads/main'
        run: |
          git config user.name "checks"; git config user.email "checks@users.noreply.github.com"
          if git merge -q --no-edit origin/main; then
            echo "Testing ${GITHUB_SHA::7} merged with main $(git rev-parse --short origin/main)."
          else
            git merge --abort 2>/dev/null || true
            echo "::warning::main could not be merged into this branch (a conflict), so these checks ran on the branch alone. Merge main into the branch and push again."
          fi
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: Get Godot 4.7.2 (headless)
        id: godot
        run: |
          curl -sSL --retry 3 --retry-all-errors -o godot.zip https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
          unzip -q godot.zip -d "$RUNNER_TEMP/godot"
          echo "GODOT=$RUNNER_TEMP/godot/Godot_v4.7.2-stable_linux.x86_64" >> "$GITHUB_ENV"
      - name: Run Godot-only rules safety net
        run: sh godot/rules/test/safety/run_cache_check.sh
```

The runner reports both cache-arm wall times, worker times and total safety-net
time in its output. After the Board installs the job, record its measured CI
time here from that run, including setup separately if reporting total job time.
