# Focused acceptance findings

Reviewed main **355a2ac70860db4446f040a5787b19c2d746d779**. Raw-view source retrieval and read proof are in `evidence/source_read_proof.json`. This review covers the battle-entry statement and the Windows export job, not a new whole-game audit.

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | A comment swallows battle preparation and the setup-time declaration in live browser source. | OBSERVED | `campaign3d.js:56`, `:59` | `round 3 prepBattle(); const setupMs=Math.round(performance.now()-setupT0);` | `setupMs` at line 59 is undeclared. Current-source campaign execution throws on entering a battle; the older campaign oracle does not have the swallowed statements. | Move the two statements before the line comment. The native control throws; the candidate calls preparation once, initializes four actual rule units and records finite setup time. | high |
| 2 | The Windows export job ignores command failures and exits successfully. | OBSERVED | `tools/pc/jobs/g2_export.bat:30`, `:31`; `tools/pc/tmo.bat:8` | `exit /b 0`; `exit /b %ERRORLEVEL%` | The timeout wrapper returns the program's status, but the caller discards it after import/export/package validation/smoke. An older executable can remain present after a failed export. | Prepared a full-copy candidate that checks each timeout-wrapper return code and missing output, then exits nonzero on failure. Windows execution remains unverified. | high |

## Read proof

| File | Lines | Exact first 40 characters of last line | Scope read |
|---|---:|---|---|
| `campaign3d.js` | 136 | empty string (blank content line) | 1-105 and cited line-56/59 windows; remainder inventoried, not reviewed |
| `tools/pc/jobs/g2_export.bat` | 31 | `exit /b 0` | 1-31, complete |
| `tools/pc/tmo.bat` | 8 | `exit /b %ERRORLEVEL%` | 1-8, complete |

Each quoted line was reopened and matched before filing. The campaign fix is tested through actual source, not by defining a missing global in a harness. The full campaign re-pin discloses all 352 changed table leaves; the price-preservation check is independent of seeded comparisons.

One recommended next step: adopt the small fixes and the explicit campaign re-pin in the documented order, then execute the prepared PC checks through the existing staging bridge.

Not checked: the rest of `campaign3d.js` outside the named windows, Windows batch execution, template download, current exported executable, Blender runtime, production mesh renders, RTX performance or the final human-visible interaction flow. No runtime/main adoption or cutover approval is claimed.
