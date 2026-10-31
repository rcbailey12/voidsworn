# Finalization review: current-source battles, hull inventory and save boundary

Reviewed main **355a2ac70860db4446f040a5787b19c2d746d779**, with prepared integration from PR #1 at **5bac75b2**. The recovered local PR tree was independently matched to GitHub tree `f725a1de7c80c7c434c6e466c3d5e6d483717e08`. No runtime files were edited. Raw GitHub retrieval of all 13 listed sources matches local byte counts and FNV-1a64; SHA-256 and read-proof inventories accompany this review.

This is a bounded review of the cited function/data windows and executable exports, not another full game audit. Existing battle parity already exists; the missing gate plug-in did not mean no battle harness existed. The new runner reuses that harness against actual current browser source rather than silently accepting its old vendored oracle.

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Campaign hull inventory differs mechanically from current battle/browser hulls in 16 fields across 12 of 51 template entries. | OBSERVED | `godot/campaign/test/oracle/data.js:567`; `data.js:570` | `mod:{hangar:3,sh:30}` versus `mod:{hangar:3,sh:22,sp:3}` | The carrier has different weapons, shields and speed. Four fitting differences were only a subset of the stale inventory. Native derived stats differ too. | Separate campaign-only hull patch after integration; all 816 native mechanical records match afterward, versus 776 before. Preserve unrelated campaign tables and prices. | high |
| 2 | Unchanged native battle text/data does not certify current browser source. | OBSERVED | `godot/rules/rules.gd:1256`; `battle.js:354` | ` on the auspex.` versus `on the scanners.` | All 16 focused current-source controls fail. Generated names and exported data also differ; accepting the old oracle would hide the source gap. | Explicit battle oracle/table refresh and nine text substitutions. All 48 current-source scenarios then match across 10,670 records with no tolerance or filtering. Combined with prior repairs and hull patch: 16 scenarios, 3,616 exact records. | high |
| 3 | The fresh-save default exists in the plan, but is not a separately quoted owner rejection of carryover. | OBSERVED | `contrib/opus/go-forward-plan.md:277`, `:267` | `old browser saves are not carried over unless Ryan asks`; `Claude's technical calls, vetoable` | Code comments alone overstate R33 provenance; the later importer audit argues for a different contract. An audit label is not authorization to migrate or delete saves. | File the exact boundary and keep shipping intent unresolved. Preserve both lineages; do not implement transport or wipe from test counts. | high |

## Read proof

Line counts exclude a terminal newline, not a blank content line. Exact last-line starts are below; the JSON inventory also records byte counts and hashes. The end of every listed source was reachable.

| File | Lines | First 40 characters of last line |
|---|---:|---|
| data.js | 697 | `  admiral:{n:'Aspect of the Admiral',d:'` |
| battle.js | 1402 | `}` |
| core.js | 349 | `function findNode(id){ for(const c of RU` |
| godot/campaign/campaign.gd | 2626 | `		"events": tel_log.slice(max(0, tel_log` |
| godot/rules/rules.gd | 3979 | `	B["aiActive"] = null; u["activated"] = ` |
| godot/rules/battle_api.gd | 856 | `	phase = "over"; _queue.clear(); R.emit(` |
| godot/rules/test/node/golden.js | 252 | `})().catch(e => { console.error(e); proc` |
| godot/rules/test/parity_main.gd | 206 | `	return 0` |
| godot/campaign/test/oracle/data.js | 694 | `  admiral:{n:'Aspect of the Admiral',d:'` |
| godot/rules/test/oracle/data.js | 695 | `  admiral:{n:'Aspect of the Admiral',d:'` |
| contrib/opus/go-forward-plan.md | 560 | ````` |
| contrib/opus/FINDINGS.md | 231 | `\| X17 \| Muse follow-up pass over unasses` |
| contrib/muse/tools/importer_reference/README.md | 279 | `   or passes through this intermediate s` |

Windows used for source review, with large files explicitly partial:

- `data.js`: 70-125 and 566-573; complete evaluated HULLS inventories compared by exporter.
- `battle.js`: 120-145, 280-355, 447-472, 754-785 and 1055-1075; changed battle-oracle hunks inspected separately.
- `core.js`: constructor and derive windows at 169-175 and 204-234.
- `godot/campaign/campaign.gd`: 1-130, 185-215, 350-420 and 637-680.
- `godot/rules/rules.gd`: text-change windows at 969-970, 1228-1262, 2718-2748, 3468-3480 and 3523-3534.
- `godot/rules/battle_api.gd`: 1-160, 242-280, 294-322 and 355-385.
- `golden.js`: battle setup, hooks, state writer and dispatch; `parity_main.gd`: full harness. Runtime executions use the complete unchanged harness files, not extracted algorithms.
- Campaign oracle `data.js`: hull rows and 490-580; rules oracle `data.js`: cited variant rows and corresponding exported hull inventory.
- Plan: 263-279; registry: 56-61; importer README: introductory contract, portable format at 85-120 and policy/transport boundary at 235-281.

The reviewed text substitutions are exact anchors in the preparation tool. Each quoted source line was reopened and checked before filing. Evidence records complete output identities and terminal markers. The comparator's 11 adversarial cases and the six JS async contracts are separate checks, not inflated battle counts.

One recommended next step: adopt the prepared hunks in the packet's stated order, then run the existing randomized re-pin sweep and PC acceptance before treating cutover as cleared.

Not checked: the rest of large-file implementations outside the listed windows, a new 200-battle randomized sweep, complete campaign re-pin, full native animation/cancellation equivalence, current threaded-shell execution, rendered gameplay, Windows, GPU timing, Blender execution, production meshes, player saves, live cloud data or a complete archive of owner conversations. No new release approval or save policy is claimed.
