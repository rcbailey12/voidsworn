# Neon Outside Visual Review: Review Pack `looks_1123` (PR 1833, Issue 1834)

**Lead verdict:** Ship **PR 1737 (wrecks)** and **PR 1786 (ship exteriors V2, behind flag)** right away. Hold and **fix first** on **PR 1763 + 1755 (interiors and wounds)**, **PR 1782 (rocks)**, **PR 1776 (planets)**, **PR 1730 (acid cook-off)**, and **PR 1772 (stations and hulks)** before Ryan's look picks. Row 8 (**PRs 1809 to 1811 UI**) is context only, mislabelled as "before the fixes" when it actually shows cloud renders of PR 1810 and PR 1811, and still shows visible text and tip overlaps.

**Reviewer:** Neon (Antigravity)
**Date:** 2026-11-23
**Commits reviewed:**
- `origin/main`: `4489bef0` (`4489bef0de1bb28e4271e91bd1fb9407d7b7ce05`)
- PR 1833 (`claude/project-thread-vr81nj`): `5b9a25af` (`5b9a25af2f4b096ce2fd66b9f9f5eec81508db24`)
- Linked PR bodies read via GitHub REST API: PRs 1833, 1763 (`e1153b84`), 1755 (`90f5cf3d`), 1782 (`745cf54a`), 1776 (`916da8cd`), 1737 (`99e36a46`), 1730 (`4e55e152`), 1786 (`700bbdc9`), 1772 (`a86497ad`), 1809 (`53cdf03b`), 1810 (`c920f7f3`), 1811 (`a86fb8a0`).

## 1. Proof of Reading (`docs/REVIEW_PROTOCOL.md`)

### Text files read

| File | Commit | Total lines | Ranges read | First 40 chars of last line (or last non-empty line) |
|---|---|---|---|---|
| `docs/REVIEW_PROTOCOL.md` | `4489bef0` | 35 | 1-35 | `- Claude checks every claim against the ` |
| `docs/playbooks/deaths_and_hits.md` | `4489bef0` | 425 | 1-425 | `Each is one or two Codex runs and one lo` |
| `docs/playbooks/ships.md` (63.3 KB) | `4489bef0` | 608 | 1-350, 351-608 | `gameplay PR.` (line 608; line 609 blank) |
| `docs/playbooks/screens.md` | `4489bef0` | 313 | 1-313 | `well-specified follow-ups (a string, a t` |
| `docs/review/looks_1123/README.md` | `5b9a25af` | 15 | 1-15 | `| 1809_1811_ui | 1809, 1810, 1811 (1801 ` |

### Media inspected (all 39 files on PR 1833 at `5b9a25af`, viewed before reading PR claims)

- `1763_1755_interiors/` (4 PNG/JPG): `joint_I15_11.png`, `joint_B21_11.png`, `closeups_I15_B21.png`, `interior_lineup_r420.jpg`
- `1782_rocks/` (5 JPG): `RK1361_carbon.jpg`, `RK1361_crystal.jpg`, `RK1361_ice.jpg`, `RK1361_iron.jpg`, `RK1361_stone.jpg`
- `1776_planets/` (7 JPG): `PV2_board_c170.jpg`, `PV2_board_close.jpg`, `PV2_standin.jpg`, `PV2_backdrop_1.jpg`, `PV2_backdrop_2.jpg`, `PV2_moons.jpg`, `PV2_battle.jpg`
- `1737_wrecks/` (1 JPG + 1 MP4): `WRK4-1236_dreadnought_before_after.jpg`, `WRK4-1236_before_after.mp4` (full 2:01 video)
- `1730_acid/` (5 JPG): `AD1394I_warden_c6.jpg`, `AD1394I_c_raider_c6.jpg`, `AD1394I_penitent_c14.jpg`, `AD1394I_d_harvester_c14.jpg`, `AD1394I_h_dominion_c21.jpg`
- `1786_ship_exteriors/` (8 PNG): `sunward_c26.png`, `directorate_c26.png`, `hullbreakers_c26.png`, `chorus_c26.png`, `glasswrights_c26.png`, `eclipse_c26.png`, `board_view_a_c170.png`, `board_view_b_c170.png`
- `1772_stations/` (2 PNG): `10_HK_chorus_c26.png`, `12_HK0_graveyard_c170.png`
- `1809_1811_ui/` (6 JPG): `B1_boon_offer.jpg`, `E1_event_choices.jpg`, `F1_fleet_manifest.jpg`, `M1_map_route_rows.jpg`, `M2_map_stop_hover.jpg`, `Y1_shipyard.jpg`

---

## 2. Verdict Summary (All 8 Rows of `docs/review/looks_1123/README.md`)

| Row | Folder | PR (issue) | Verdict | One-line reason |
|---|---|---|---|---|
| 1 | `1763_1755_interiors` | 1763 (1743), 1755 (1741) | **Fix first** | Glasswright wounds read as dark grey blurry smudges (violating no black on glass); Chorus `c26` broken frame is empty space; Glasswright cutaway is unreadable neon confetti; Eclipse cutaway still shows a green core (`#1422`). |
| 2 | `1782_rocks` | 1782 (1361) | **Fix first** | Stone, iron and carbon are huge upgrades and cutting toy cyan crystals is right, but ice and comet look like twin dark rocks with white paint splatter, and no comet gas tail appears in the pack. |
| 3 | `1776_planets` | 1776 (1765) | **Fix first** | Rocky, terran, barren and `P2` look great, but ice (`B3`, `P6`, `M3`, `s7`) looks like brown cursive scribbles on a plastic ball (`M3` is also egg-stretched), and volcanic (`B4`, `s8`) lost its lava and reads as blurry brown haze. |
| 4 | `1737_wrecks` | 1737 (1236) | **Ship it** | Complete visual win across all six factions in the clip: big wrecks stay 1:1 scale and stop cleanly where they broke instead of shrinking into miniature boats. |
| 5 | `1730_acid` | 1730 (1394) | **Fix first** | Raider soot is gone, Dominion arcs are back and etched green break rims look sharp, but `now tell` adds two soft chartreuse cloud blobs on every hull, clashing with R398's no-cloud / no-vapour rule. |
| 6 | `1786_ship_exteriors` | 1786 (1777) | **Ship it** | Clean, subtle-to-modest contrast and depth lift across Sunward, Directorate, Hullbreakers, Chorus and Eclipse with zero brown-shift on Eclipse; keep behind flag until frame-time gate clears. |
| 7 | `1772_stations` | 1772 (1767) | **Fix first** | No station pictures are in the folder; Before (H) vs After (K) looks nearly identical; bright silver/white wrecks still pop like live ships; wait for Sheet M on the real PR head plus station shots. |
| 8 | `1809_1811_ui` | 1809, 1810, 1811 (1801-1803) | **Fix first** (context only) | Mislabeled as "before the fixes" (actually cloud renders of PR 1810/1811). Hover states improved, but `B1` keycaps `[4]`/`[5]` clip button text, `Y1` tip box covers `Iron Dusk`, and PC shots + PR 1809 shots are missing. |

---

## 3. Row-by-Row Visual Review

### Row 1: `1763_1755_interiors` (PR 1763 / #1743 and PR 1755 / #1741)
- **Pick: Fix first.**
- **What the pictures show:**
  - In `joint_I15_11.png` and `closeups_I15_B21.png` (left), the two Glasswright breach wounds (`j_wound_I15_11__c26.png`) look like **flat, round, blurry dark-charcoal smudges with wavy grey horizontal noise stripes**. There are no crisp crystal facets, no popped mosaic panes, and no white-gold internal light cores. On `Broken (6 s after death)`, the torn hull mouth shows dull grey rocky slabs with no warm core light. At `c170` and `c26` breached top view, the wounds barely read at all.
  - In `joint_B21_11.png` and `closeups_I15_B21.png` (right), **`Broken (6 s after death), camera 26` is empty space**: both Chorus halves drifted off the top and bottom of the frame (only tiny spine tips peek at the top edge), so the Chorus broken interior is completely unproven at `c26`. In the closeup wound (`j_wound_B21_11__c26.png`), the hole sits on a dark brown cracked dome with bright **orange/amber rim outlines** along adjacent shell edges (reading like hot metal edges on a flesh hull) and a tiny green gas puff; ivory bone ribs, wet tendon strands, and pulsing bile sacs do not read. Breached (`50%`) top views look nearly identical to Intact.
  - In `interior_lineup_r420.jpg` (which still carries a stale cloud stamp `20a1b6a76128 | cloud direction check`, not `e1153b84`), `S10` (Sunward), `H10` (Directorate), `A16` (Hullbreakers), and `C11` (Chorus) cutaways read clearly and cohesively. However, `GP1` (Glasswrights) is an **overexposed tie-dye neon confetti blur** because thick unlined outer mosaic panes bleed onto the inner face, and `E12` (Eclipse) has a **bright neon-green center sphere**.
- **Claims and playbook clashes:**
  - PR 1755 claims `"no soot or black on glass"` and `docs/playbooks/deaths_and_hits.md:290-291` requires `"straight-edged crystalline fracture facets and popped mosaic panes over braided light cores glowing white-gold (zero soot, zero black holes, zero radial sine webs)"`. The dark blurry smudges on `I15_11` violate both directly.
  - `docs/playbooks/deaths_and_hits.md:275,288-289` calls for `"snapped bone ribs and wet tendon strands"` over `"muddy olive-umber hide, ivory bone hoops and pulsing yellow-green bile sacs"`. Neither reads in `closeups_I15_B21.png`.
  - `docs/playbooks/ships.md:85,103,448` requires `"all violet, no green on the hull"` and `"zero green inside"`. PR 1763 notes honestly that `E12`'s green sphere is exterior `ecore` (`CORE_RGB`) waiting on `#1422` and that `GP1`'s mosaic bleed is `ithar/hull.py` lacking an inner liner. Both still clash visually with the approved look (and `E12`'s green core appears again in Row 6 `eclipse_c26.png`).
- **Why fix first:** Metal and Chorus cutaways in PR 1763 are strong, but Wounds V2 (PR 1755) is visibly broken on Glasswrights and unreadable/unframed on Chorus, and Glasswright cutaways (`GP1`) need an inner liner (or dark inner face) before Ryan signs off. Re-capture `joint_B21_11` on top of PR 1737 so the broken halves stay inside `c26`.

### Row 2: `1782_rocks` (PR 1782 / #1361)
- **Pick: Fix first.**
- **What the pictures show:**
  - `RK1361_stone.jpg`, `RK1361_iron.jpg`, and `RK1361_carbon.jpg` are **night-and-day upgrades**. Before, all three looked like the exact same puffy tan clay potato. After, `stone` has sharp layered craggy cliffs, `iron` reads as dark pitted gunmetal with crisp metallic glints, and `carbon` reads as deep matte charcoal basalt.
  - `RK1361_crystal.jpg` removes the cartoonish glowing cyan crystal spikes, which is a big taste win.
  - **The problem:** compare `RK1361_crystal.jpg` (AFTER, "comet") directly beside `RK1361_ice.jpg` (AFTER, "ice"). Both are elongated dark charcoal ovals covered in **blurry mottled white patches that look like white paint splatter or stucco on dark grey slate**. They look almost identical to each other at both `c170` and `c26`. No translucent ice sheen, no subtle cold vent glow, and no far-edge comet gas tails appear anywhere in the five sheets.
  - Minor proof hygiene note: every BEFORE and AFTER panel stamps the exact same commit `745cf54a080f | installed in game` (only the clock changes from `10:57` to `11:05`), likely from toggling `VS_1361_OLD=1` on one install rather than capturing `main e4b7d034` as stated in `README.md`.
- **Claims and playbook clashes:**
  - PR 1782 claims `"ice frost only on the fresh shelves"`, `"comet nuclei (dark crust, sheets of white ice, a dim cold glow only in a few deep vents)"`, and `"two or three big nuclei beyond the far edge with soft anti-sun gas tails"`. None of those distinguish `crystal` from `ice` in the `ROCKS_I` captures, and the gas tails are absent.
- **Why fix first:** Stone, iron, and carbon are ready to ship today. Separate `ice` (brighter pale glacial blue-white body with sharp ice facets) from `comet` (darker carbon nucleus with crisp frost seams, dim cold vent glints, and a wide capture proving the anti-sun tails) so the two kinds do not read as twins.

### Row 3: `1776_planets` (PR 1776 / #1765)
- **Pick: Fix first.**
- **What the pictures show:**
  - `PV2-B0 rocky after`, `PV2-B1 terran after`, `PV2-B5 barren after`, `PV2-P2 after`, `PV2-P3 after`, and `PV2-M1 after` are **massive upgrades**. Rocky, terran, and barren look crisp, photorealistic, and grounded in the real battle shots (`PV2_battle.jpg` `s5`, `s6`, `s9`), and replacing neon-purple gas giant `P2` with banded slate/bronze/cream fits the game's tone completely.
  - **Blocker 1 (Ice):** `PV2-B3 ice after` (`PV2_board_c170.jpg`, `PV2_board_close.jpg`), `PV2-P6 after` (`PV2_backdrop_2.jpg`), `PV2-M3 after` (`PV2_moons.jpg`), and `PV2-s7 ice, cold` (`PV2_battle.jpg`) look **fake and distracting**. The lines meant to be Europa's tectonic lineae loop back on themselves like **brown cursive crayon scribbles ("W" and "o" loops, tangled spaghetti)** drawn on a smooth glossy plastic sphere. In `PV2_moons.jpg`, `PV2-M3 after` is also visibly **stretched vertically into an egg** (pre-existing on `M3 before`, still unfixed). In `PV2_standin.jpg`, `PV2-B3 ice stand-in` looks like half rusty desert mud and half blue cloud instead of ice.
  - **Blocker 2 (Volcanic):** `PV2-B4 volcanic after`, `PV2-P4 after`, and `PV2-s8 volcanic, cold` **no longer read as volcanic at all**. While the old lava web was too loud, the new version went all the way to a **blurry, smooth, dusty orange-brown haze ball** (softer than rocky `B0`!) with almost zero visible lava fissures, flows, or calderas even up close in `PV2_board_close.jpg`.
  - Minor note: `PV2-M0 after` (grey) and `PV2-M2 after` (basalt) look almost identical in `PV2_moons.jpg`.
- **Claims and playbook clashes:**
  - PR 1776 claims `"ice: Europa-style lineae, chaos terrain and a gloss sheen"` and `"volcanic: flows, canyon grit and fissure glow"`. Real Europa lineae are straight or gently arcing intersecting tectonic bands, never tangled loops; and volcanic shows neither readable canyon grit nor fissure glow at battle distance.
- **Why fix first:** Keep rocky, terran, barren, `P2`, and `M1` untouched, fix the ice lineae generator into crisp straight/gently-arcing cracks (plus fix `M3`'s egg stretch and `B3`'s muddy stand-in), and give volcanic dark crisp basalt ridges with restrained glowing caldera/fissure veins so players recognize it immediately.

### Row 4: `1737_wrecks` (PR 1737 / #1236)
- **Pick: Ship it.**
- **What the pictures and video show:**
  - In `WRK4-1236_dreadnought_before_after.jpg` and across all six ship classes in `WRK4-1236_before_after.mp4` (Directorate dreadnought, Sunward, Hullbreakers, Glasswrights, Chorus), BEFORE visibly shrinks broken capitals down to comical 25% scale toy boats. AFTER holds every wreck at full 1:1 scale right where it broke, with both halves drifting slightly apart and braking to a calm stop.
  - Provenance clarification: `README.md` implies `99e36a46` (Artoo's stop-turning fix) was added after capture `6ce553cb`, but PR 1737's body confirms `"After pin: 6ce553cb (99e36a46 plus the same bench files)"`, and every half stops spinning cleanly in the video.
  - Unrelated bugs visible in the clip (different PRs, not blockers here): on the Glasswright catamaran (`01:29` to `01:38`), glowing purple-white engine plumes stay firing on the dead stern half after death, and its hull snaps from rainbow mosaic to dark metal-brown slats; the Directorate dreadnought cavity is jet black because this clip predates PR 1763/1755 interiors.
- **Claims and playbook clashes:** Matches PR 1737 and `docs/playbooks/deaths_and_hits.md` ("A wreck that blocks its hex") completely.
- **Why ship it:** Cleanest, biggest visual improvement in the pack. Merging it first also fixes the drifting-out-of-frame Chorus halves seen in Row 1 (`joint_B21_11.png`).

### Row 5: `1730_acid` (PR 1730 / #1394)
- **Pick: Fix first.**
- **What the pictures show:**
  - PR 1730's two targeted fixes clearly worked: on `AD1394I_c_raider_c6.jpg`, the dark soot cloud above the Hullbreaker Raider in `before split` / `before core` is completely gone in `now split` / `now core`; on `AD1394I_h_dominion_c21.jpg`, the Directorate Dominion's signature white-blue electrical arcs fire cleanly in `now core`; and across all five ships (`warden`, `raider`, `penitent`, `harvester`, `dominion`), torn wreck faces (`now wreck`, `now settled`) now show crisp yellow-green etched acid corrosion instead of orange fire, while removing the glowing green center orb from `before tell` on Eclipse `d_harvester`.
  - **The problem (`now tell`):** On ALL FIVE sheets (`AD1394I_warden_c6.jpg`, `c_raider`, `penitent`, `d_harvester`, `h_dominion`), `now tell` shows **two soft, blurry, glowing chartreuse-green cloud puffs** sitting loosely above the armor (especially obvious on the giant Dominion hull in `AD1394I_h_dominion_c21.jpg`, where they look like two small floating green cotton puffs, alongside a brown stain patch that vanishes in `now split`).
  - Sheet layout hygiene: every sheet orders its columns `tell -> split -> wreck -> core -> settled`, so `core` shows the broken halves closer together again after `wreck` already blew them apart; none of the five sheets carry a commit stamp.
- **Claims and playbook clashes:**
  - `docs/playbooks/deaths_and_hits.md:152` states: `"the plating glows a sick yellow-green only where the acid hit (each hit a ragged patch that spreads until the hull parts)... never the soft green bloom (it read as a cloud)... no fire, no smoke, no vapour (R398)"`. The soft chartreuse puffs in `now tell` read as green clouds/vapour, directly tripping R398.
- **Why fix first:** `split`, `core`, `wreck`, and `settled` are already strong and solve 1394G's soot and big-hull arc problems cleanly. Tighten the `now tell` green puffs into crisp hull-hugging ragged corrosion patches (zero floating cloud look) before Ryan accepts.

### Row 6: `1786_ship_exteriors` (PR 1786 / #1777)
- **Pick: Ship it.** (Keep behind `VS_SHIP_LOOK_V2=0` until the solo RTX 5080 frame-time gate clears and head `700bbdc9` / `996bc09d` matches `b0768e6b`.)
- **What the pictures show:**
  - Across `sunward_c26.png`, `directorate_c26.png`, `hullbreakers_c26.png`, `chorus_c26.png`, `eclipse_c26.png`, `board_view_a_c170.png`, and `board_view_b_c170.png`, turning V2 on gives a **clean, grounded contrast and crevice-depth upgrade** with zero new artifacts. Sunward loses its chalky grey wash, Directorate panels sharpen, Hullbreakers gain richer oxblood-red depth (darker red, not muddy), Chorus chitin gets a subtle wet clearcoat lift, and **Eclipse stays crisp obsidian-violet** (the PR's feared brown-shift did not happen).
  - On `glasswrights_c26.png`, `I8_37` (champagne pearl ribbons + recessed stained glass, matching `ships.md:75-81`) gains slight depth, while `I15_11` (head-to-toe rainbow confetti) barely changes at all.
- **Cross-row clashes noticed (pre-existing on `V2 off`, NOT introduced by PR 1786):**
  - `eclipse_c26.png` and `board_view_b_c170.png` show `D21_23` (E12)'s **green central core** in both `V2 off` and `V2 on` (same `#1422` clash seen in Row 1 `interior_lineup_r420.jpg`).
  - `I15_11` clashes sharply with `I8_37` inside the same faction sheet (`glasswrights_c26.png`): `I8_37` obeys `ships.md:76-81`, whereas `I15_11` has almost no pearl ribbons and reads as loud rainbow confetti (the same noisy hull that hides wounds in Row 1).
  - Pre-1755 damage artifacts are visible on the `damaged` rows in both `V2 off` and `V2 on`: bubblegum-pink smears on Chorus `B21_11 damaged` (`chorus_c26.png`, violating `deaths_and_hits.md:289` "zero magenta"), white cobweb net on Glasswright `I15_11 damaged` (`glasswrights_c26.png`, violating `deaths_and_hits.md:291` "zero radial sine webs"), and orange inner bay on Directorate `H10_23 damaged` (`directorate_c26.png`, violating `deaths_and_hits.md:287-288` "zero orange"). These belong to Wounds V2 (PR 1755), not PR 1786.
- **Why ship it:** V2 delivers an honest visual lift across five of six factions with zero V2 regressions and stays safely switch-gated until frame-time proof lands.

### Row 7: `1772_stations` (PR 1772 / #1767)
- **Pick: Fix first.**
- **What the pictures show:**
  - **Missing station coverage:** Despite the folder name `1772_stations`, there are **zero pictures of `station_T2`** (no small 3-hex cluster, no teaching station, no lone hole, no 19-hex cluster, no biome kind-lamp light spill check). PR 1772 itself flags station size, fallback dock drums, and lamp spill as its top risks for Ryan to inspect.
  - In `10_HK_chorus_c26.png` and `12_HK0_graveyard_c170.png`, **Before (H, `494595a4`, 0.04 floor) and After (K, `e31cd839`, 0.025) look virtually identical to the naked eye**. The Chorus hulk still reads as pale khaki/tan at roughly live Chorus brightness (compare Row 6 `board_view_a_c170.png` `B21_11`), and up close at `c26` its twin round recessed brown nozzles on the pale beige rear hull read like cartoon owl eyes next to an old pre-1782 clay rock.
  - In `12_HK0_graveyard_c170.png`, two pale silver/white wrecks (lower-left center and far right) still pop brighter than everything else on the board like live ships, and `README.md` notes Sheet K is already superseded by PR head `7c7ae555` (`a86497ad` on GitHub) awaiting Sheet M for R425 (wrecks never lighter than 60% of live paint).
- **Claims and playbook clashes:** PR 1772 cannot be approved from stale Sheet K when the station half of the PR has zero pictures and the wreck-darkening change is invisible in Sheet K.
- **Why fix first:** Wait for Sheet M on the live PR head AND include the missing `station_T2` cluster, hole, and kind-lamp captures before sending to Ryan.

### Row 8: `1809_1811_ui` (PRs 1809, 1810, 1811 / #1801 to #1803)
- **Pick: Fix first (context only, not acceptance-ready).**
- **What the pictures show:**
  - First, `README.md:15` misdescribes these six JPGs as `"UI audit shots before the fixes"`. Every image header explicitly shows side-by-side **cloud lavapipe** captures comparing `BEFORE: main cbb6165a` against `AFTER: PR 1810 @ c920f7f3` and `AFTER: PR 1811 @ a86fb8a0` (`ship models are cloud placeholders`). PR 1809 (Battle HUD `#1803`) has zero screenshots here.
  - **Real improvements in AFTER:** `M2_map_stop_hover.jpg` shows clear step-by-step polish (no hover -> PR 1810 orange focus box -> PR 1811 structured stop hover card). `M1_map_route_rows.jpg` and `F1_fleet_manifest.jpg` add clean row hover shading in PR 1811. `E1_event_choices.jpg` reads cleanly.
  - **Visible UI bugs still live in AFTER (`PR 1811 @ a86fb8a0`):**
    1. `B1_boon_offer.jpg`: boxed `[4]` and `[5]` shortcut badges sit directly on top of the button labels, clipping `"Reroll the offer (25 credits, onc[4]"` and `"Decline: take 40 credits[5]"`.
    2. `Y1_shipyard.jpg`: the `"REPAIR AND REFIT"` onboarding tip card sits directly over the 4th ship column (`Iron Dusk`), hiding its stats and weapons.
    3. `M1_map_route_rows.jpg` and `F1_fleet_manifest.jpg`: hover tooltips overlap the Nemesis banner (`LENS-KEEPER DREAE`) and clip adjacent ship names (`BRIGHT CENSUR`), and `M1`'s tooltip exposes raw internal scaling math (`"their strength is about 23% of your fleet's (includes Standard AI -5%)"`).
- **Claims and playbook clashes:** `docs/playbooks/screens.md:29,36,40` forbids keycap boxes (`"No pills, key badges, glows or shadows"`, `"No key caps"`) and requires `"no overlaps at any fleet size or name length"`. `B1` violates both; `Y1` violates no overlaps. Both PR 1810 and PR 1811 also still show `FAIL: standing checks` in their runner blocks.
- **Why fix first:** Keep as context only; fix `B1`'s `[4]`/`[5]` overlap and `Y1`'s tip overlap, get standing checks green, and run real PC captures (including PR 1809 Battle HUD) before acceptance.

---

## 4. Prioritized Findings Table (`docs/REVIEW_PROTOCOL.md`, Top 10)

| # | Finding | OBSERVED / INFERRED | File / Source | Exact Quote | Why it matters | Your fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Glasswright Wounds V2 (`I15_11`) render as blurry dark-charcoal smudges with grey stripes instead of crystal fractures and white-gold cores | OBSERVED | `docs/playbooks/deaths_and_hits.md:290-291` (and `1763_1755_interiors/closeups_I15_B21.png`) | `"zero soot, zero black holes, zero radial sine webs"` | Directly breaks both PR 1755's claim ("no soot or black on glass") and the deaths playbook; looks like dirty smudges on stained glass. | Replace the Glasswright breach/mark shader mask with crisp straight-edged translucent facets and emissive white-gold braided cores; remove dark grey/soot attenuation on glass. | high |
| 2 | Ice planet and ice moon (`PV2-B3`, `PV2-P6`, `PV2-M3`, `PV2-s7`) show looping brown cursive scribbles on a plastic ball; `M3` is vertically stretched like an egg | OBSERVED | PR 1776 body (and `1776_planets/PV2_board_close.jpg`, `PV2_moons.jpg`) | `"ice: Europa-style lineae, chaos terrain and a gloss sheen"` | Reads immediately as fake crayon scribbles to any player, ruining the otherwise photorealistic planet upgrade across board, backdrop and moon views. | Replace curled/looped noise splines with long straight or gently arcing great-circle fracture bands with tight subtle double ridges; fix `M3`'s aspect/UV stretch and muddy `B3` stand-in. | high |
| 3 | Volcanic planet (`PV2-B4`, `PV2-P4`, `PV2-s8`) looks like a blurry dusty orange haze ball with almost zero lava or surface detail | OBSERVED | PR 1776 body (and `1776_planets/PV2_board_close.jpg`, `PV2_battle.jpg`) | `"volcanic: flows, canyon grit and fissure glow"` | Softer than rocky `B0` and unrecognizable as volcanic in live battle (`PV2-s8`); players will mistake it for a blurry Mars clone. | Give volcanic crisp dark basalt/caldera relief like rocky/barren, then add restrained dark-crust lava rivers and caldera hot spots visible at `c170`. | high |
| 4 | Chorus `B21_11` `c26` broken shot is empty space, and Chorus wounds show orange/amber plate rims without readable bone ribs or organs | OBSERVED | `docs/playbooks/deaths_and_hits.md:288-289` (and `1763_1755_interiors/joint_B21_11.png`, `closeups_I15_B21.png`) | `"muddy olive-umber hide, ivory bone hoops and pulsing yellow-green bile sacs"` | Fails to prove Chorus broken interiors at `c26`, and amber rim edges make a flesh warship read like heated metal. | Re-capture `joint_B21_11` with PR 1737's wreck brake merged; remove warm orange rim tint on Chorus wounds and boost readable ivory ribs and wet olive-umber/bile interior contrast. | high |
| 5 | Glasswright interior cutaway (`GP1`) is blinding tie-dye confetti, and `I15_11` clashes with `I8_37` across Rows 1 and 6 | OBSERVED | `docs/playbooks/ships.md:76-78` (and `1763_1755_interiors/interior_lineup_r420.jpg`, `1786_ship_exteriors/glasswrights_c26.png`) | `"opaque, reflective champagne pearl ribbons"` | In cutaway (`GP1`), unlined mosaic bleed completely destroys interior readability; on `I15_11`, full-hull confetti hides wounds and clashes with `I8_37`. | Add a dark/frosted inner liner (or separate subdued inner face) in `tools/blender/kits/ithar/hull.py` so Glasswright interiors read cleanly; flag `I15_11` exterior mosaic coverage for rebake alignment with `I8_37`. | high |
| 6 | Eclipse `E12` (`D21_23`) still displays a bright green core across BOTH Row 1 (`interior_lineup_r420.jpg`) and Row 6 (`eclipse_c26.png`) | OBSERVED | `docs/playbooks/ships.md:85` (and `1763_1755_interiors/interior_lineup_r420.jpg`, `1786_ship_exteriors/eclipse_c26.png`) | `"all violet, no green on the hull"` | Direct visual violation of Ryan's Nov 20 no-green Eclipse ruling sitting dead-center in two separate review packs. | Land `#1422` (`CORE_RGB` flip to violet-white) and re-capture `interior_lineup_r420` and `eclipse_c26` before Ryan signs off on Eclipse visuals. | high |
| 7 | Acid kill `now tell` draws two soft glowing chartreuse cloud blobs on all five hulls, clashing with R398's no-cloud / no-vapour rule | OBSERVED | `docs/playbooks/deaths_and_hits.md:152` (and `1730_acid/AD1394I_h_dominion_c21.jpg`) | `"never the soft green bloom (it read as a cloud)"` | While `split` to `settled` look great, the floating lime puffs in `now tell` look like green smoke clouds above the armor and will trip Ryan's R398 objection. | Replace the soft floating `now tell` puffs with tight hull-conforming ragged acid-etch glow patches; also swap `wreck`/`core` column order and add commit stamps to the 1394I bench script. | high |
| 8 | PR 1772 (`1772_stations`) pack has zero station pictures, negligible visible delta in Sheet K, and bright silver wrecks awaiting Sheet M | OBSERVED | `docs/review/looks_1123/README.md:14` (and `1772_stations/10_HK_chorus_c26.png`, `12_HK0_graveyard_c170.png`) | `"R425 (wrecks never lighter than 60 percent of live paint) sheet M follows after its PC run."` | Half of PR 1772 (`station_T2` scaling, dock drums, kind-lamp spill) is completely unseen, and Sheet K's Chorus darkening is invisible by eye while pale wrecks still read live. | Hold PR 1772 until Sheet M captures the actual PR head (`7c7ae555`/`a86497ad`) AND adds `station_T2` 3-hex, 19-hex, lone-hole, and kind-lamp shots. | high |
| 9 | Rocks `ice` and `crystal` (now ice comets) look nearly identical (dark rocks with white paint splatter) and show no comet gas tails | OBSERVED | `docs/review/looks_1123/README.md:9` (and `1782_rocks/RK1361_ice.jpg`, `RK1361_crystal.jpg`) | `"ROCKS_I: one sheet per rock kind (carbon, crystal now ice comets, ice, iron, stone)."` | Players cannot tell ice fields from comet fields at `c170`, white speckles read as paint spots at `c26`, and PR 1782's claimed far-edge comet tails are unverified. | Differentiate `ice` (brighter crystalline glacial tone/facets) from `comet` (darker crust + crisp frost seams + dim cold vents) and include a wide shot proving the anti-sun tails. | high |
| 10 | UI pack (`1809_1811_ui`) is mislabelled in `README.md`, and `AFTER: PR 1811` still clips `B1` button text under `[4]`/`[5]` badges and covers `Iron Dusk` with a tip box in `Y1` | OBSERVED | `docs/playbooks/screens.md:39-40` (and `1809_1811_ui/B1_boon_offer.jpg`, `Y1_shipyard.jpg`) | `"no overlaps at any fleet size or name length"` | Directly breaks orders-sheet readability (`screens.md:29,36,40`) on two high-traffic campaign screens; `B1` cuts off `"once)"` and `"credits"`. | Replace boxed keycaps in `B1` with right-aligned plain keys (`screens.md:36`) or widen/shorten the buttons; anchor `Y1` onboarding tips clear of ship cards; fix `README.md` label and run PC acceptance shots after CI passes. | high |

---

## 5. Recommended Next Step

Merge **PR 1737 (wrecks)** first (clean ship-it win that immediately stabilizes broken halves on camera), keep **PR 1786 (ship exteriors V2)** queued for its solo RTX 5080 frame-time gate, and kick back **PR 1776 (ice + volcanic planets)**, **PR 1755 (Glasswright + Chorus wounds)**, **PR 1763 (`GP1` inner liner)**, **PR 1782 (ice vs comet split + tail shot)**, **PR 1730 (`now tell` green cloud blobs)**, and **PR 1772 (Sheet M + station shots)** for one targeted visual fix pass before putting the pick sheet in front of Ryan.

---

## 6. Not Checked

- **Source code and shaders inside the open PR branches:** per the `#1834` brief ("no code changes", review the pictures and PR bodies against `docs/playbooks/`), I did not check out or audit GDScript/GLSL/Python code inside PRs 1763, 1755, 1782, 1776, 1737, 1730, 1786, 1772, or 1809 to 1811.
- **Unrendered / post-capture commits:**
  - PR 1786 commits after captured `b0768e6b` (GitHub head `700bbdc9`, README note `996bc09d`) and its solo RTX 5080 frame-time gate.
  - PR 1772 Sheet M (head `7c7ae555` / `a86497ad`) and any `station_T2` captures (absent from PR 1833).
  - PR 1782 wide comet-tail capture (`RK_crystal_comets_c420`, absent from PR 1833).
  - PR 1809 Battle HUD visual or keyboard checks (no media in `1809_1811_ui/`) and real PC captures for PRs 1810 and 1811 (only cloud lavapipe renders present).
- **Audio and frame-time telemetry:** `WRK4-1236_before_after.mp4` was reviewed visually via extracted video frames and waveform cues; no live PC playthrough or RTX 5080 millisecond profiling was run.
