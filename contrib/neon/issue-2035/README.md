# Issue 2035 (AAA item 9): Nebula and Ion Storm Look Bench

Queue `neon_2035_gas_bench.bat` on Ryan's Windows PC after CI checks are green and diff review passes on `neon/issue-2035` (RULEBOOK 3.12, R407).

## What it produces

1. Four Ryan-ready before/after comparison sheets (`1280 x 680 px`, strictly under the 720 px cap of RULEBOOK 1.2), stamped with `tools/picture_provenance.py`:
   - `N2035_NEB_C170.jpg`: rose nebula hex with Cruiser + Frigate inside at camera 170 (calm + weapon flash/blast)
   - `N2035_NEB_C26.jpg`: rose nebula hex with ships inside at camera 26 (calm + weapon flash/blast)
   - `N2035_STORM_C170.jpg`: teal ion storm hex with ships inside at camera 170 (calm with lightning + weapon flash/blast)
   - `N2035_STORM_C26.jpg`: teal ion storm hex with ships inside at camera 26 (calm with lightning + weapon flash/blast)
2. Solo-GPU frame-time gate runs (`nebula_bench_2035.tscn`, 3 sessions, 120 warmup, 720 measured frames) on both `main` (`PIN_OLD`) and `neon/issue-2035` (`PIN_NEW`) at 1080p (`base`) and 4K (`res_2160`) against the 12.5 ms gate (RULEBOOK 3.9).
3. `summary_2035.json` recording all sheet sizes and before/after median frame and GPU times.
