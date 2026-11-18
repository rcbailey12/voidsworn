# Nov 18 audit leftovers

## Attach points

The installed-ship check flagged 17 engine exits. All 17 are false positives. Three clear with denser rays at the original limit. The other 14 clear when the radius and the triangle distances are measured in the same fitted ship frame. The recipe export's open-bell test independently found a rim in all 12 sectors, an upstream throat and a clear exhaust path for every flagged exit.

`tools/pc/get_ship_files.bat` copied the shared satin build. All 255 files matched the manifest at `cef236c0`. The stock check walked 36 real ships, the T2 station and three stand-ins. It skipped zero effects. It still exits 1 with the 17 flags because it adds the raw authored radius to a limit measured on the fitted hull. The retest used 16,384 sphere directions plus each point's signed axes, and measured the exact closest point on the same triangle mesh. The fitted limit adds the nozzle radius that `fx_hull.gd` uses for the live effect. [Full attach report and retests](attach_report.json).

| Ship | Engine exit | Original distance | Original limit | Dense distance | Exact distance | Fitted limit | Verdict |
|---|---|---:|---:|---:|---:|---:|---|
| C13s_23 | hp_eng_0 | 0.20887 | 0.17951 | 0.18957 | 0.18903 | 0.69379 | Check used an unscaled radius |
| C13s_23 | hp_eng_1 | 0.17037 | 0.17004 | 0.15459 | 0.15438 | 0.59534 | Original rays read long |
| C14s_23 | hp_eng_0 | 0.23708 | 0.22463 | 0.21521 | 0.21445 | 0.82426 | Original rays read long |
| C15s_23 | hp_eng_0 | 0.34117 | 0.31802 | 0.30978 | 0.30815 | 1.19755 | Original rays read long |
| C19_51 | hp_eng_0 | 0.82164 | 0.55232 | 0.74653 | 0.74085 | 2.70916 | Check used an unscaled radius |
| C19_51 | hp_eng_1 | 0.78280 | 0.54981 | 0.71119 | 0.70584 | 2.60472 | Check used an unscaled radius |
| C19_51 | hp_eng_2 | 0.67080 | 0.54258 | 0.60933 | 0.60494 | 2.30393 | Check used an unscaled radius |
| H10_23 | hp_eng_0 | 0.66971 | 0.43628 | 0.66971 | 0.66971 | 1.51461 | Check used an unscaled radius |
| H10_23 | hp_eng_1 | 0.66971 | 0.43628 | 0.66971 | 0.66971 | 1.51461 | Check used an unscaled radius |
| H10_23 | hp_eng_2 | 0.66971 | 0.43628 | 0.66971 | 0.66971 | 1.51461 | Check used an unscaled radius |
| H10_23 | hp_eng_3 | 0.66971 | 0.43628 | 0.66971 | 0.66971 | 1.51461 | Check used an unscaled radius |
| H4_11 | hp_eng_0 | 0.67209 | 0.61768 | 0.67209 | 0.67209 | 1.71001 | Check used an unscaled radius |
| H4_11 | hp_eng_1 | 0.67209 | 0.61768 | 0.67209 | 0.67209 | 1.71001 | Check used an unscaled radius |
| H4_11 | hp_eng_2 | 0.67209 | 0.61768 | 0.67209 | 0.67209 | 1.71001 | Check used an unscaled radius |
| H4_11 | hp_eng_3 | 0.67209 | 0.61768 | 0.67209 | 0.67209 | 1.71001 | Check used an unscaled radius |
| H4_11 | hp_eng_4 | 0.67209 | 0.61768 | 0.67209 | 0.67209 | 1.71001 | Check used an unscaled radius |
| H4_11 | hp_eng_5 | 0.67209 | 0.61768 | 0.67209 | 0.67209 | 1.71001 | Check used an unscaled radius |

Distances are in fitted game units. The recipe ship C16s_23 passed the stock check. The five swap codes below were still the satin A4 exports, identified by their GLB metadata and matching hashes. All five passed.

| Code | Installed hull |
|---|---|
| D9_23 | Eclipse mote, frigate |
| D20_23 | Eclipse flare, destroyer |
| D21_23 | Eclipse zenith, cruiser |
| D22_23 | The Unsetting, tomb-ark |
| V1b_r_23 | Daybreak-class dreadnought |

## Battle and debrief

The `keel_log_open` case reproduces with the existing capture's seed 7, `--ui-demo --obj ambush`, at camera 170 in round 1. Unyielding Oath (Sunward Crusade cruiser, `x04`, hex 7,11, facing 0) targeted Fleet Marshal Petra Valk (Hegemony Navy, `x08`, hex 8,16, facing 4) at six hexes. The target stayed alive and went from 168 to 159 hull and from 47 to 38.82 pooled shield. The line of sight was clear. Move plan and attack move were empty. Brace was off. After firing, the armed selection cleared and the firing set was empty.

| Slot and weapon | Limit | Target in arc | State after firing |
|---|---:|---|---|
| 0, port Sear battery | 5 | No | Ready, unfired, out of range |
| 1, starboard Sear battery | 5 | Yes | Ready, unfired, out of range |
| 2, prow Oath lance | 7 | Yes | Fired, in range, unavailable |

All three weapons had zero cooldown and zero offline time. The Oath lance was the only weapon that could fire before the shot. The state and the shot match before and after. The shelf and firing toast now say “No ready gun can reach it.”

| Before-and-after picture | What to inspect |
|---|---|
| [KEEL firing message](../issue-1051-codex/keel_log_open.png) | The target message describes the ready guns. |
| [KEEL target hover](../issue-1051-codex/target_hover.png) | The ledger hover shows 25% armor and 0 evasion for Valk at 18 px. Both target views use the same display values, including the evasion buff. |
| [Shields and hull](../issue-1051-codex/shields_and_hull.png) | The blue meter is the ship's shield pool and the pale meter is hull. Four sides share the pool and their coverage affects how much damage they catch, as in R246. |
| [DB1 debrief](../issue-1051-codex/DB1_win.png) | The heir cards use “shadow XP,” matching the casing in lineage details and hover text. |

## Palette inventory

R191 retired lime as screens move to the ember orders sheet, R210 reserved Glacier for shield readouts, and the KEEL v5 build retained that palette. The governing values are in [RULEBOOK section 9](../../RULEBOOK.md#9-screens-and-interface) and the [screens playbook](../../playbooks/screens.md).

| Code | Where the palette appears |
|---|---|
| `glass_shell.gd` | `GILT` (#c8f53a), `GILT2` and `GILT_HOVER` are still in legacy buttons, selected buttons, the finish action, keycaps, frame marks and the shared default tooltip border. |
| `campaign_ui.gd` | The legacy theme and helper calls still lead to lime on campaign setup and admiral selection, run options, between-battle choices and action buttons, vault and unlock pages, Help, the admiral skill tree, and the post-battle reward modal. The map's orders-sheet theme supplies its own tooltip style. |
| `hud.gd` | The battle HUD starts from the shared theme and replaces its button and tooltip colors. `recol` maps legacy lime markup to ember. KEEL draws its shelf accent from `MAP_EMBER`. |
| `main/title.gd` | The title and the active playtest notice still use its local #d0a64b gold. Primary buttons use that gold and a lighter hover fill. Secondary buttons use navy, bone text and the local dim-gold hover outline. Settings and Credits use gold headings, bone body text and the same button styles. Title toasts use local #f0b35a. |

## Runner check

The PowerShell probe budget in `runner_job_tests.js` is 240 seconds inside the 300-second standing check row. It prints probe elapsed time on success. The Windows run passed all 58 probe groups and the simultaneous claim test. A temporary copy with Base parsing disabled exited 1 at “runner committed both merge parents.”

Standing checks finished with 67 passes and two known baseline results (findings and oracle drift). The KEEL readability and DB1 debrief checks passed. All four comparison sheets passed provenance verification.
