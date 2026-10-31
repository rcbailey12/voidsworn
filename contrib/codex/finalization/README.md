# Finalization packet for Opus

October 31, 2026. Runtime source: main **355a2ac70860db4446f040a5787b19c2d746d779**. Prepared after PR #1 at **5bac75b2**. All changes are Contrib candidates; no runtime files, player saves or cutover baseline have been installed or refreshed.

## What this adds

| Result | Evidence |
|---|---|
| Current-source real-combat parity, battle-refresh candidate | **48 scenarios / 10,670 exact action-state and PRNG records.** The existing battle harness is reused. No numeric tolerance or text filtering. |
| Native unchanged build against current source | **0 PASS / 16 FAIL** in the focused corpus. Old names, hardcoded log text and exported data are retained as failures, not normalized away. |
| Earlier repairs plus campaign hull patch plus battle refresh | **16 scenarios / 3,616 exact records.** This is a separate combined adoption check. |
| Native campaign hull synchronization | **816 / 816 exact records**, versus 776 / 816 before this patch: 51 template definitions, 663 fitting predicates, 102 Mark I/III derived-stat cases. Fixtures never substitute browser hulls into the native campaign. Display names and weapon labels are excluded only in this explicitly mechanical fixture. |
| JS action lifecycle | Six contracts: pure previews; duplicate pending fire; epoch cancellation returning the gun; an old shot unable to damage a new battle; canceled movement; stale fire-during-movement callbacks. These are JS async checks, not native animation parity. |
| Comparator | Eleven checks reject empty, truncated, missing, duplicate, invalid-hash, invalid-PRNG and divergent records. The same comparator checks both payload hashes, complete identities, round metadata and terminal markers. |
| Optional Saro after both new patches | **707 model/fitting + 96 pilot records match.** Native fitting differences are now zero. The existing Saro patch applies cleanly after the refreshes; historical full-file copies remain stale. |

See `evidence/` for source receipts, first differences, counts, logs and hashes. Full state streams are generated into isolated temporary folders whose locations are recorded; they are reproducible rather than committed as large dumps. `end none` is an explicit scenario round limit, not a win; s31 ends that way in the 48-scenario suite.

## Adoption order

1. Adopt the existing `../pre_opus/patches/integration.patch` against its recorded source pin. It contains the eight earlier assertion improvements.
2. Apply **`patches/campaign_hulls_after_integration.patch`**. It changes ten campaign oracle source rows, then regenerates only the resulting `HULLS` / `HULL_VARIANTS` table differences and checksum. All other exported tables, including faction prices and the integrated `BOON_NEED.L_storm` shield gate, remain unchanged.
3. Apply **`patches/battle_refresh.patch`**. It refreshes the battle oracle and tables from 355a2ac7, including the already-existing RAMP tuning and current names, plus nine exact text substitutions in `rules.gd`. No native battle arithmetic or control flow is changed. The oracle change is intentional and disclosed, not a claim that an old oracle certifies current source.
4. Optionally apply the existing **`../pre_opus/patches/saro.patch`** afterward. Use small patch hunks, not the historical full-file copies. See `evidence/saro_compatibility.json` for the combined pilot checks and limits.
5. Optional tooling adoption: **`patches/parity_gate_adapter.patch`** creates the canonical gate plug-in. It always tests the checked runtime and cannot select a candidate lane. The whole `contrib/codex/finalization/` packet must remain available for its implementation. The gate's parity baseline still requires explicit review; no baseline refresh is included here.

Strict application and resulting-file hashes are verified by `tools/check_patches.js` and `patches/manifest.json`. Do not overwrite later main with full candidate files. Reconcile hunks and rerun checks if source changes. Do not stack the older separate gameplay patches on integration.

The campaign hull patch is intentionally narrower than a campaign oracle re-pin. It removes all 16 current mechanical hull-field differences across 12 entries. Other campaign-table differences and old display names remain outside this repair. Correcting hull mechanics does not certify the complete campaign against current source.

## Reproduce

On Windows, double-click **`pc/run_checks.bat`**, or drag the Godot executable onto it. Node, Git and Godot are required. **Windows execution remains NOT RUN.**

Manifest preflight uses exact recorded source bytes. Use an LF checkout for the filed candidates; Windows CRLF-only transformations are not certified by these new launchers and may be rejected as source drift. No automatic source rewriting is performed.

From a checkout with unchanged runtime source:

```sh
node contrib/codex/finalization/tools/run_checks.js --godot /path/to/godot
```

The one-command launcher prepares candidates and runs the individual checks. Its orchestration has syntax validation here; the constituent commands were executed individually. It never installs runtime candidates or writes the player's save. Known simulation environment overrides are removed from verification subprocesses; none were present during the recorded runs.

To measure only the actual checked runtime, including known failures:

```sh
node contrib/codex/finalization/tools/run_vectors.js . --godot /path/to/godot
```

`--candidate --all` runs the 48 scenarios with the explicit battle candidate installed only inside a temporary project. Missing Godot, script errors, incomplete output, damaged records or source changing during execution return INCOMPLETE, never PASS. The default gate-compatible corpus has 16 fixed identities, documented in `tools/run_vectors.js`; `--all` requires all 48 existing identities.

## What stays open

- The cutover gate remains uncleared. This packet supplies current-source battle evidence and a proposed adapter, not a release verdict. No randomized 200-battle re-pin sweep, full campaign re-pin, current threading rerun, rendered UI or production Windows build acceptance is claimed.
- Migration intent remains unresolved for shipping. Read **`R33_BOUNDARY.md`**: the plan's fresh-save default is now located, but the importer audit asks for a different product contract. No wipe or importer mandate is inferred and no save is touched.
- Windows launchers, Blender self-test, production-asset renders, Pyre-Barge sign-off, roughly 20-ship GPU acceptance and the playable phased-battle interaction capture still require the PC. See **`PC_ACCEPTANCE.md`**.
- Saro remains an optional two-effect prototype. Native picker dialogs, full campaign-UI parity and 358 further effects remain unfinished.
- The original 80-assertion ledger is unchanged by this work. Earlier integration remains 16 PASS / 64 FAIL; this packet does not reinterpret the remaining ledger rows as confirmed bugs.

One next step: review and adopt the small candidate hunks in the stated order, then run the existing 200-battle sweep and PC acceptance. Preserve red results and the cutover baseline until each change is explicitly reviewed.
