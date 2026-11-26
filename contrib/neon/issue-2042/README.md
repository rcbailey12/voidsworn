# Issue 2042 (AAA Effects Sweep, Build A) Look Bench Capture

Queued on Ryan's PC GPU line after CI checks are green and review passes (RULEBOOK 3.12, R407).

## How to run

Double-click `capture_2042_before_after.bat` (or queue it on the PC):

```bat
capture_2042_before_after.bat origin/neon/issue-2042 origin/main
```

It runs `tools/pc/jobs/look_bench.bat` with `res://bench/look_moments_2042.json` against both `origin/main` (before) and `origin/neon/issue-2042` (after), using the PC-built hulls (`LB_SHIPS`) and `look_bench_sheets.py`, and writes labelled before/after comparison sheets at cameras `170` and `26` into `%USERPROFILE%\Downloads\voidsworn_test\look_bench_2042\sheets\`.

## Rows captured (cameras 170 and 26)

| Group | Code Name | Item & Faction |
|---|---|---|
| `2042_rcs_jets` | `B2042_RCS_VOID` | Item 1: Sunward Crusade directional RCS cone jets |
| `2042_rcs_jets` | `B2042_RCS_HEGE` | Item 1: Meridian Directorate directional RCS cone jets |
| `2042_rcs_jets` | `B2042_RCS_CORS` | Item 1: Ashfall Hullbreakers directional RCS cone jets |
| `2042_rcs_jets` | `B2042_RCS_ITHA` | Item 1: Glasswrights prismatic vane flare (no white cold gas) |
| `2042_rcs_jets` | `B2042_RCS_CHOR` | Item 1: Chorus organic bioluminescent vent pulse |
| `2042_rcs_jets` | `B2042_RCS_ECLI` | Item 1: Eclipse violet null ripple (no green, no orange) |
| `2042_moving_trail` | `B2042_TRL_HEGE` | Item 2: Meridian moving engine trail anchored to nozzle, tapered (style 0) |
| `2042_moving_trail` | `B2042_TRL_CORS` | Item 2: Hullbreakers moving engine trail anchored and tapered (style 1) |
| `2042_moving_trail` | `B2042_TRL_CHOR` | Item 2: Chorus moving engine trail anchored and tapered (style 2) |
| `2042_moving_trail` | `B2042_TRL_ECLI` | Item 2: Eclipse moving engine trail anchored, tapered, violet only (style 3) |
| `2042_main_plumes` | `B2042_PLM_VOID` | Item 3: Sunward Crusade main plume core and outer wash |
| `2042_main_plumes` | `B2042_PLM_HEGE` | Item 3: Meridian Directorate main plume core and outer wash |
| `2042_main_plumes` | `B2042_PLM_CORS` | Item 3: Ashfall Hullbreakers main plume core and outer wash |
| `2042_main_plumes` | `B2042_PLM_ITHA` | Item 3: Glasswrights main plume core and violet crystal wash |
| `2042_main_plumes` | `B2042_PLM_CHOR` | Item 3: Chorus main plume organic pulse core and wash |
| `2042_main_plumes` | `B2042_PLM_ECLI` | Item 3: Eclipse main plume violet core and corona wash |
| `2042_craft_trails` | `B2042_CRF_HEGE` | Item 4: Meridian patrol fighters on unified `SH.CRAFT_TRAIL` |
| `2042_craft_trails` | `B2042_CRF_ITHA` | Item 4: Glasswright patrol craft on unified `SH.CRAFT_TRAIL` |
| `2042_craft_trails` | `B2042_CRF_CHOR` | Item 4: Chorus patrol spores on unified `SH.CRAFT_TRAIL` |
