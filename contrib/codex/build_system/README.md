# Opus adoption packet: builds, progression and Saro

Source pin: main **355a2ac70860db4446f040a5787b19c2d746d779**. Everything here is Contrib work. No runtime file on main has been changed.

## What is ready

| Deliverable | What it proves |
|---|---|
| `data/catalog.json` | All 360 authored texts retain stable slot ids, original text, source lines/hashes, owners, sharing and primary-Command scope. All 24 admirals resolve 20 slots. Extracted timing/actor/limit evidence and suggested hooks expose missing terms. Two pilot effects have operational contracts; the other 358 remain explicitly unimplemented and need effect-level resolution. |
| `src/lineage.js` / `src/lineage.gd` | Choice eligibility, exclusive pairs, prerequisite tiers, immutable transactions, save validation, respec pricing, variable native XP, proposed Heat/shadow accounting, overflow banking and idempotent settlements. 3,840 complete legal builds validate. |
| `evidence/progression_report.md` | Exact outcome traces and finite-horizon crossing distributions. No new campaign simulations. Early losses are not assumed to pay 10 XP. Probabilities are sensitivity inputs, not human forecasts. |
| `candidates/module_fit/` | Compatibility enforced in both UI and the mutation action, including slots/ability, weapon kind, shields and malformed indices. Only MOD-3 flips in the 80-assertion control: 9 PASS / 71 FAIL. |
| `candidates/lineage_pilot/` | Opt-in Saro prototype: two alternative A1 effects, browser picker/respec/Command dialog, run snapshots, native save/reward integration, matching Godot rules/model, and explicit oracle exceptions. Disabled prototype: original 8 PASS / 72 FAIL. |
| `preview.html` | Offline, editable workbench using the tested model and measured native fixtures. Open with `open_preview.bat`. It has its own fixture save key and does not edit a game save. Rendered browser QA is unverified in this environment. |
| `candidates/tree_copy/` | 19 proposed Chorus slot copy edits and four branch headings, following Lore Bible r8's song ban. `data/tree_copy_edits.json` gives every before/after and source anchor. Mechanics and original provenance are retained. |

## Verify

On Windows, drag the Godot executable onto **`run_checks.bat`**, or double-click it if `godot` is on PATH. Node and Git are also required. Equivalent:

```
node contrib/codex/build_system/tools/run_checks.js --godot "path/to/godot"
```

The command checks its source pin, rebuilds the packet, creates isolated temporary browser/Godot test trees, runs both engines, compares exact records, and records the assertion identities. Git history for 355a2ac7 must be available. Checkout CRLF/LF differences are accepted; content/table drift is rejected. If Opus has integrated intervening changes, rebase the scoped candidates and their pin/expectations before rerunning. It never installs a candidate into runtime source or writes the player's Godot save. A missing Godot executable is an incomplete run, not a pass.

Expected result: **360 texts; 3,840 legal builds; 707 model/fitting records; 96 native pilot records**. The latter include exact combat state/RNG and native reward/save records. Forty native JS control cases preserve original behavior. Floating inputs and outputs use the port's IEEE-hex convention, avoiding JSON decimal-rounding artifacts. The comparator requires the expected record count and rejects duplicate, truncated, changed or missing records.

Model/fitting parity uses identical inputs. `evidence/native_table_drift.json` separately records four native compatibility differences caused by two existing variant weapon-loadout discrepancies. This packet does not fix or clear that table drift. The general cutover gate remains INCOMPLETE because its general battle corpus is absent.

## Adopt in small pieces

1. Start with **module fitting**. Apply `patches/module_fit.patch`, or reconcile the corresponding full copies. Preserve any intervening changes. Re-run the 80 assertions and inspect MOD-3's identity, not just the count.
2. Review the **state policies** below and the targeted audit. The catalog is source-preserving data, not 360 implemented mechanics.
3. Adopt the **Saro pilot** as one opt-in experiment using `patches/lineage_pilot.patch`. It adds a button below Saro's browser mastery display. Choosing a path between runs enables the prototype for future Saro runs; the toggle can disable it. Changes during an active/saved run are refused.
4. Adopt the **Chorus copy edits** separately if wanted; they do not enable any tree effect.

Full candidate paths mirror their intended targets after stripping `candidates/<job>/`. Module fit and Saro both touch `core.js` and the Godot campaign. **Do not copy one full file over the other.** The job patches apply individually against 355a2ac7. For both runtime jobs, use `patches/combined_runtime.patch`: it merges their shared oracle README notes and keeps both code changes. The combined runtime and tree-copy patches also apply sequentially. They also need reconciliation with the earlier elite/shipwright candidates. Oracle changes are narrow exceptions; no whole-oracle re-pin is implied.

## Saro's two implemented effects

- **Focus Drawn Long:** on the primary Burning glass Command, an individual weapon's shots deal x1.20 damage when hex distance is strictly greater than half that weapon's printed maximum range. The full volley remains. This resolves the draft's unspecified “ship range” per weapon.
- **One Lens, One Target:** per ship, choose normal volley or one legal weapon. A chosen weapon fires **one projectile**, at x1.25 damage, instead of that ship's full Command volley. Its original shot count/cooldown/movement state is restored afterward. Invalid/offline/flak/out-of-range choices do not spend the Command. Cancel and Escape clear the draft without spending it.

Both are restricted to Saro's primary Command. Alternate Commands, other admirals and normal fire receive no bonus. A run owns a snapshot of its chosen skill; later META changes cannot rewrite the active battle. Temporary state is restored on JS exceptions and abandoned-battle completion. Native Godot effects and save/reward logic pass headless validation. **Native Godot picker/Command dialogs are not included**: its UI must collect a per-unit `B.lineageIntent` before committing a focused Command. Missing intent deliberately keeps the normal volley.

## Explicit prototype policies to review

These choices resolve gaps for a bounded prototype; they are not new owner rulings:

- Base XP follows actual native statistics: `battles + 2*elites + 5*bosses + victory*10`. The proposal's flat 10-XP loss is retained only as a calculator comparison.
- Shadow XP retains exact quarter-points. Ordinary 25% shadow includes Heat's flown payout. Every benched line with a named-heir flag doubles its ordinary shadow; there is no artificial one-heir-per-faction limit.
- Heat's additional +1 per point is accumulated in a faction pool, **not silently duplicated across all bench admirals**. Pool distribution is still unspecified.
- XP can continue while choices are pending, up to 600; excess is retained in each line's `overflowQ` bank. Intermediate-cap interpretation and overflow distribution remain adoption decisions. No XP is deleted.
- A respec transaction charges every removed pick at `25 + 10*priorRespecTransactions`, then increments the line's transaction count once. Removing a prerequisite without removing its dependent picks is rejected. XP is retained; no renown is refunded.
- Empty capstone is `""`, not null, because the native Godot serializer omits null dictionary members. The known save shape survives native serialization. Unknown/future save versions are rejected without overwriting them.

Read `../reviews/build_system_audit_2026_10_31.md` for the bounded findings and read receipt. Browser security rejected the local `file://` render, so there is no screenshot or claim of rendered-browser validation. Windows double-click execution and native Godot dialogs remain unverified. Fleet recipes and the full 24-admiral visual rollout remain next packets.
