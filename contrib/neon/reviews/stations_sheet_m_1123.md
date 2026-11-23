# Neon Re-Check: PR 1772 Stations and Hulks Sheet M (Issue 1847)

**Verdict for PR 1772: Fix first.** Sheet M answers the Chorus darkness issue cleanly and proves `station_T2` at 19 hexes looks great with no dock-drum clutter or ugly lamp spill, but two visual problems still jump out to a player: (1) shrinking the full multi-tower `station_T2` model down to 1 hex (`10_ST3`) and 3 hexes (`08_ST1`) makes those stations look like miniature toys smaller than the cruiser parked beside them (with empty blocked hexes on the 3-hex rig), and (2) the two Meridian Directorate (`hegemony`) hulks in the graveyard (`07_HK0`) still gleam bright silver like live steel warships because smooth specular reflections survive the 60% paint darkening.

**Reviewer:** Neon (Gemini 4 Neon (High) via T3 Code, Antigravity harness)
**Date:** 2026-11-23
**Commits reviewed:**
- `origin/main`: `c9c11fc2` (`c9c11fc2a`)
- PR 1833 (`claude/project-thread-vr81nj`): `1145dd64` (`1145dd64cba2c6bd0bce510367e7ecec6afd1671`)
- PR 1772 (`opus/issue-1767`): head `1370358a` (PROPS_M capture at `7c7ae5554513` vs PROPS_K at `e31cd839bc68`, `installed in game`)

## 1. Proof of Reading (`docs/REVIEW_PROTOCOL.md`)

All ten Sheet M PNGs and both READMEs were extracted from `origin/claude/project-thread-vr81nj` (`1145dd64`) and opened straight from disk in the local checkout (no uploads).

| File | Commit | Total lines | Ranges read | First 40 chars of last line |
|---|---|---|---|---|
| `docs/REVIEW_PROTOCOL.md` | `c9c11fc2` | 35 | 1-35 | `- Claude checks every claim against the ` |
| `docs/review/looks_1123/README.md` | `1145dd64` | 15 | 1-15 | `\| 1809_1811_ui \| 1809, 1810, 1811 (1801 ` |
| `docs/review/looks_1123/1772_stations/sheet_m/README.md` | `1145dd64` | 15 | 1-15 | `and the run passed, so these are station` |

Pictures opened from disk (`docs/review/looks_1123/1772_stations/sheet_m/`): `01_HK_corsair_c26.png`, `02_HK_voidsworn_c26.png`, `03_HK_hegemony_c26.png`, `04_HK_ithar_c26.png`, `05_HK_chorus_c26.png`, `06_HK_deathless_c26.png`, `07_HK0_graveyard_c170.png`, `08_ST1_teaching_3hex.png`, `09_ST2_big_19hex.png`, `10_ST3_hole_1hex.png`.

## 2. PR 1840 Row 7 Points: Answered or Still Open?

1. **No station pictures:** **Evidence answered; visual look fails on small sizes.** All three station sizes are now shown at `c170` and `c26` (`08`, `09`, `10`). The 19-hex station (`09_ST2_big_19hex.png`) looks great at full scale, no fallback dock drums clutter the outer hexes, and the faint rig/ring/spire lamps cause zero ugly colour spill on nearby hulls. However, the 1-hex hole (`10_ST3_hole_1hex.png`) and 3-hex teaching cluster (`08_ST1_teaching_3hex.png`) look fake to a player (see findings 1 and 3 below).
2. **Before H vs After K looked nearly identical (Chorus read as lit tan):** **Answered.** In `05_HK_chorus_c26.png` and `07_HK0_graveyard_c170.png`, M clearly darkens Chorus from a lit khaki shell into a dry, dead olive-brown hulk while keeping its texture and dark lens glints. Hullbreakers (`01`), Sunward (`02`), and Eclipse (`06`) also read cleanly as dead hulks with none turning pure black.
3. **Silver wrecks still pop like live ships:** **Not answered.** In `07_HK0_graveyard_c170.png`, the same two Meridian Directorate hulks (lower-left-center and far-right) still pop bright silver-white at battle camera `c170` and look almost identical between K and M. Up close in `03_HK_hegemony_c26.png`, the midtone hull darkened a touch, but glossy specular highlights across the smooth upper spine and bow still gleam like live metal.
4. **Wait for Sheet M on the live PR head:** **Answered.** Sheet M is stamped `7c7ae5554513 | installed in game` (PASS), and `README.md:14` confirms `1370358a` adds main merges only.

## 3. Prioritized Findings (`docs/REVIEW_PROTOCOL.md`)

| # | Finding | OBSERVED / INFERRED | File / Source | Exact Quote | Why it matters | Your fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | 1-hex (`10_ST3`) and 3-hex (`08_ST1`) `station_T2` shrink a full multi-tower ring complex smaller than the cruiser next to it, reading like a toy scale bug; at `c26` in `10_ST3`, the docking arm nearly touches the cruiser's bow | OBSERVED | PR 1772 body (`1370358a`), `sheet_m/08_ST1_teaching_3hex.png`, `10_ST3_hole_1hex.png` | `"fitting strictly inside a 3-hex cluster makes the teaching station small, because the cluster has notches."` | Architectural cues (skyscraper hub, four towers, docking ring) shrink to about half a cruiser's length on 1 hex and shorter than a cruiser on 3 hexes, breaking believability on sight. | Do not shrink full `station_T2` below ~7 hexes. Put a dedicated smaller rig/spire/relay silhouette (or cropped hub/pylon kit) on 1-hex and 3-hex stations, or let 3-hex teaching stations sit on a proper small outpost asset. | high |
| 2 | Two Meridian Directorate (`hegemony`) hulks still pop bright silver-white at `c170` in `07_HK0_graveyard_c170.png` (K and M look nearly the same at battle height) because bright metallic specular glare survives the 60% paint drop (`03_HK_hegemony_c26.png`) | OBSERVED (cause INFERRED from `03_HK` glossy spine vs darkened midtones) | `sheet_m/README.md:11`, `03_HK_hegemony_c26.png`, `07_HK0_graveyard_c170.png` | `"Navy, Sunward and Hullbreakers are a touch darker and keep their colour. No hulk went to pure black."` | At battle camera `c170`, players still mistake those two gleaming silver Directorate wrecks for live warships, defeating the R425 derelict separation pass. | In the derelict material pass for metal hulks, push roughness up (and/or lower metallic/specular) alongside the 60% albedo cap so burnt Navy armor reads matte/scorched instead of glossy silver. | high |
| 3 | On `08_ST1_teaching_3hex.png`, shrinking `station_T2` into one corner leaves the bottom blocked hex and most of the upper-right blocked hex as empty space (only tiny debris specks) | OBSERVED | `sheet_m/README.md:13`, `08_ST1_teaching_3hex.png` | `"08 teaching 3 hex (rig), 09 big 19 hex (ring), 10 hole 1 hex (spire)"` | Two of the three orange blocked hexes look open to fly through, which feels fake and unfair during the teaching battle. | Fill the 3-hex cluster footprint cleanly (larger fitting outpost/rig massing or grounded flanking wreckage/pylons across the three cells) so blocked hexes visibly match solid cover. | high |
| 4 | Glasswright hulk (`04_HK_ithar_c26.png`, unchanged under M) has dark dead mosaic hulls, but its two champagne-gold cross-bridges catch a bright specular hotspot (plus a vivid purple forward orb) that pops at `c170` (`07_HK0` bottom-left) | OBSERVED | `sheet_m/README.md:7`, `04_HK_ithar_c26.png`, `07_HK0_graveyard_c170.png` | `"Chorus -38%, Hullbreakers -25%, Navy -25%, Sunward -21%, field -11%, Glasswright +1% (no change, as designed)."` | Minor compared to Directorate, but the bright cream-gold struts and vivid orb still read slightly active on an otherwise dead glass catamaran. | Slightly dull/roughen the non-glass connector struts and dim the purple orb on derelict Glasswright hulks while keeping the darkened glass character. | med |

## 4. Recommended Next Step

Before sending PR 1772 to Ryan's pick sheet, raise derelict metal roughness/dull specular so Directorate wrecks stop gleaming silver in `07_HK0_graveyard_c170.png`, and decide with Ryan whether 1-hex and 3-hex stations should get a real small-station/outpost silhouette (recommended) instead of shrinking the giant 19-hex `station_T2` into a cruiser-sized miniature.

## 5. Not Checked

- GDScript code, shaders, or material roughness/metallic constants inside PR 1772 (`opus/issue-1767`): brief requested a picture and README review only with no code changes.
- Live gameplay hex-click feel or collision checks around `station_T2` (reviewed stills only).
- Pre-1782 lumpy clay rocks visible beside hulks in `01` to `07` (belong to PR 1782, not PR 1772).
