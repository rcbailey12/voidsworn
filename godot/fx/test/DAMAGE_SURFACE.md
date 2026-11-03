# R80 damage checks

Double-click `check_damage_surface.bat` on Ryan's PC. It stages this checkout in
TEMP, uses the real hulls already in the PC build, runs the damage contracts,
captures stages 0 to 4 at 4K, and measures 20 real ships at stages 0, 3 and 4.
It does not change the play build. Logs and captures stay in TEMP.

The probe uses fixed seeds and anchors on the real top skin. Eclipse's existing
D22 hull is drawn at battleship length, since the hull table has no separate
Eclipse battleship entry. Its anchors sit on the ring beside the central tower.
There are five factions, including two metal factions. `*_detail.png` adds a
close look at the midsection, and repair captures show the start and the scar.
Raised repair plates require supporting skin across their whole outline. Narrow
towers and steep curves use the conforming patch overlay, so no plate floats.

Probe controls: `DAMAGE_OUT` (required), `DAMAGE_MODE=capture|fleet`,
`DAMAGE_LABEL=baseline|final`, `DAMAGE_FACTIONS` (optional comma-separated ids).
The same script runs against a saved baseline project for comparison. The
Compatibility renderer exercises the actual safe-mode path.

`damage_surface_sheets.py` makes labelled contact sheets from the captures using
the Pillow already bundled with ComfyUI. Pass the capture folder, output folder
and label. Original PNGs keep their full 3840 by 2160 resolution. Battle sheets
use labelled centre crops so small hulls remain legible in the sheet.

The frame probe disables vsync, warms 90 frames and samples 240 drawn frames at
4K per stage. `fleet.json` reports average and p99 frame time, p99 main-thread
FX step time, rebuild wall time, the accumulated `fx.prof_take()` values in
microseconds, and actual emitter and particle counts. This measures stationary
damaged ships, not a whole battle with weapons and deaths. Rebuild wall time
includes serial waits for all 20 worker jobs and must not be called frame cost.

The mix is 10 light, 6 medium and 4 heavy ships. The adopted per-class limits
allow 34 fire sources and 54 smoke/vent sources for that mix. The research's
46-smoke estimate does not follow its own class-cap table. The runtime uses the
table, and counts include equivalent spore/vapour sources and repair fades.
