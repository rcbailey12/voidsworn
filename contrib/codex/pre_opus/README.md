# Pre-Opus repair and integration packet

October 31, 2026. Source main: **355a2ac70860db4446f040a5787b19c2d746d779**. All files are Contrib candidates. No runtime source has been installed.

**Use `patches/integration.patch` for the repair batch.** It combines the earlier elite-map, shipwright and module-fit repairs with the new Nemesis and boon fixes. Add `patches/saro.patch` afterward only when adopting the optional Saro prototype. This resolves competing full-file copies; prototype policies and native Godot dialogs remain separate work.

## Changes and assertion identities

| Job | Behavior | Result against the 80-assertion control |
|---|---|---|
| Nemesis | Loss/retreat teaches one unknown weakness or confirms current-battle discoveries. The actual battle-finish caller supplies discoveries. New adaptations exclude shields against revealed ion weakness and point defense against revealed torpedo weakness, including exhausted fallback. Existing adaptations/saves are retained. | FR-2 and NEM-2 only: 10 PASS / 70 FAIL. |
| Boons | Useful on-patron and held-patron entries compete in one weighted pool. All ordinary picks use the offering patron's favour. Duo/legendary competition uses one special slot. L_storm requires shields. No duplicate, owned or incompatible ordinary fillers; exhausted useful pools return short offers. | RWD-3, RWD-4 and RWD-8 only: 11 PASS / 69 FAIL. |
| Integration | Both jobs plus elite guarantee, shipwright companion repair and module fitting; matching Godot and explicit oracle exceptions. | Exactly eight changes: FR-2, MOD-3, NEM-2, RWD-3, RWD-4, RWD-8, TXT-2, W3-1. **16 PASS / 64 FAIL.** |
| Optional Saro | Two-effect prototype layered onto every repair above. | Disabled prototype retains 16 PASS / 64 FAIL. |

The ledger governs each remaining failure; 64 failing assertions are not 64 accepted defects. No new adaptation-cap, numeric boon-scaling, reroll-charge, migration or economy fix is claimed.

## Verify and adopt

Drag Godot onto `run_checks.bat`, or run:

```
node contrib/codex/pre_opus/tools/run_checks.js --godot "path/to/godot"
```

Node, Git and Godot are required. The command verifies its source pin, regenerates candidates, builds isolated temporary projects, applies combined patches with strict whitespace checks and verifies candidate hashes. Missing output, assertion identities, terminal records or native script failures cannot pass. It does not install runtime files or write the player's Godot save. Windows execution is unverified.

1. Review the policies below and the code hunks. The long campaign-table JSON diff changes **only `BOON_NEED.L_storm = "shields"` plus its checksum**. Preparation rejects any other table change. Exported faction prices are retained.
2. Apply `integration.patch` against the source pin, or reconcile its hunks with later main. Do not stack the standalone or earlier gameplay patches on it. Full copies in `candidates/integration/` are reference material.
3. Re-run the checks and inspect the eight changed identities and exact native comparisons.
4. Optionally apply `saro.patch` **after integration**, then read `../build_system/README.md`. Native Godot dialogs and 358 skill effects are still unimplemented.

`nemesis.patch` and `boons.patch` are independently adoptable against plain main 355a2ac7. Their shared oracle README notes require reconciliation if combined manually; use integration.patch for the complete batch. `patches/manifest.json` identifies every base/candidate hash and the Saro layer's integrated base.

## Recorded evidence

| Check | Result |
|---|---|
| Standalone Nemesis / boons | 522 / 2,521 exact JS/Godot records. |
| Integrated repairs | **3,043 exact records**, including scored/exhausted fallback, force calls, six factions, debrief cases, favour/reward floors, mixed/shieldless fleets, depleted/empty pools and special-slot competition. Ninety original-JS controls remain unchanged. |
| Actual finishBattle consumer | **18 exact loss flows**, including fast-adapting Chorus. Combat discoveries arrive before adaptation and do not earn an extra debrief reveal. Small vector files are filed. |
| Elite/shipwright after integration | 4,506 exact records: 4,500 maps plus six repair cases; zero guarantee/repair-contract failures. |
| Campaign/save-reload bot | **30 seeds / 4,572 matching records**, with contiguous identities and valid start/end markers. Uses the existing stub-battle campaign harness, not real battle parity. |
| Existing Nemesis scenarios | 64 exact records. |
| Optional Saro layer | 707 model/fitting and 96 native pilot records match. Browser action-handler, range, cancellation, snapshot/save/reward and exception-cleanup checks retained. |

See `evidence/summary.json` and per-check logs. Larger repair/map vectors are cheap to reproduce; hashes and exact comparisons are retained. No numeric tolerance was added. The fixed 300-seed special-slot fixture produces both duos and legendaries; it is not a combat-balance forecast.

## Explicit candidate policies

- Ordinary pool: useful on-patron weight **3**, other held patrons **1**, without replacement. Shared offering-patron favour implements Q7; 3:1 is the chair's proposed default.
- Special slot: eligible duo weight **45**, legendary **55** when both qualify. A lone duo retains its existing 45% chance for a full offer; a short offer can take it directly. A lone eligible legendary appears. The numeric split is candidate tuning of the ruled weighted competition.
- Loss intel: debrief adds at most **one** unknown weakness. If combat supplied valid discoveries, it confirms them and adds none. Two combat discoveries remain known; no knowledge is deleted to enforce a cap. The debrief cap is a chair recommendation.
- Clash scope: the two explicitly documented direct pairs, ion/shields and torpedo/point-defense. No invented relationships or retroactive stripping of saved adaptations.

## Blender support and limits

`blender/README.md` describes a Windows launcher, generated-fixture self-test, object/material/transform observations and 18 matched painted/clay diagnostic views. The primary asset is never saved/exported over. Pure geometry tests and Python syntax pass. Blender, Windows, actual renders and production assets are **NOT RUN** here.

General real-battle parity/cutover, Saro campaign-UI parity/native dialogs, graphics/GPU acceptance, a 20-ship stress scene, fleet recipes and 358 further effects remain unfinished. Existing native hull-table drift, R33 migration and importer transport remain unresolved. Muse's controlling corrections, completed price/A3 work and closed audit are unchanged.
