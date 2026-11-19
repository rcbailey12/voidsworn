# Attach check retest for issue 1069

On the PC, Godot 4.7.2 headless walked 36 ships, the T2 station and three stand-ins in **30.7 seconds**. It exited 0 with 5,138 points walked, zero failures and zero effects skipped. `tools/pc/get_ship_files.bat` verified all 255 files after copying the retained shared satin build from the PR 1067 audit. The current shared copy had since changed four ships. With the same verified satin files, the stock check reproduced all 17 flags and exited 1.

The check finds the closest point on the same hull triangles the attach service uses. It skips groups of triangles only when their bounding box is farther away than the best distance found so far. It takes each authored engine exit's fitted nozzle radius from the live attach service. The base limit is still 0.012 times the fitted hull length. Gun allowances and the core box check are unchanged. The check skips building fitted shields because they do not contribute to the attach triangles or points.

## Engine exits

Distances and limits are in fitted game units. The before columns use the higher-precision stock measurements from [PR 1067's audit](../audit_leftovers_1118/attach_report.json). The new distances for all 17 exits are within 0.015% of that audit's closest-triangle distances.

| Ship | Exit | Before distance | Before limit | After distance | After limit | After result |
|---|---|---:|---:|---:|---:|---|
| C13s_23 | hp_eng_0 | 0.20887 | 0.17951 | 0.189053 | 0.693794 | Pass |
| C13s_23 | hp_eng_1 | 0.17037 | 0.17004 | 0.154381 | 0.595339 | Pass |
| C14s_23 | hp_eng_0 | 0.23708 | 0.22463 | 0.214450 | 0.824264 | Pass |
| C15s_23 | hp_eng_0 | 0.34117 | 0.31802 | 0.308135 | 1.197548 | Pass |
| C19_51 | hp_eng_0 | 0.82164 | 0.55232 | 0.740878 | 2.709162 | Pass |
| C19_51 | hp_eng_1 | 0.78280 | 0.54981 | 0.705875 | 2.604721 | Pass |
| C19_51 | hp_eng_2 | 0.67080 | 0.54258 | 0.604975 | 2.303933 | Pass |
| H10_23 | hp_eng_0 | 0.66971 | 0.43628 | 0.669611 | 1.514615 | Pass |
| H10_23 | hp_eng_1 | 0.66971 | 0.43628 | 0.669611 | 1.514615 | Pass |
| H10_23 | hp_eng_2 | 0.66971 | 0.43628 | 0.669611 | 1.514615 | Pass |
| H10_23 | hp_eng_3 | 0.66971 | 0.43628 | 0.669611 | 1.514615 | Pass |
| H4_11 | hp_eng_0 | 0.67209 | 0.61768 | 0.671989 | 1.710008 | Pass |
| H4_11 | hp_eng_1 | 0.67209 | 0.61768 | 0.671989 | 1.710008 | Pass |
| H4_11 | hp_eng_2 | 0.67209 | 0.61768 | 0.671989 | 1.710008 | Pass |
| H4_11 | hp_eng_3 | 0.67209 | 0.61768 | 0.671989 | 1.710008 | Pass |
| H4_11 | hp_eng_4 | 0.67209 | 0.61768 | 0.671989 | 1.710008 | Pass |
| H4_11 | hp_eng_5 | 0.67209 | 0.61768 | 0.671989 | 1.710008 | Pass |
| C19_51, planted fault | hp_eng_0 | 2.97340 | 0.55232 | 2.950792 | 2.709162 | Fail |

For the fault run, a temporary checker copy moved the instantiated `C19_51` exit `hp_eng_0` one fitted nozzle radius (2.209962 units) aft in the ship frame before calling `fx.add_ship`. Both checkers ran with `--only C19_51`. The new checker exited 1 and named just the moved exit, which sat 0.241630 units beyond the limit. The asset files stayed intact.

## Other checks

- The GitHub stand-in command passed locally in a project with no built ship files. It walked three stand-ins, reported zero failures and zero skips, and exited 0 with no script errors.
- `node contrib/opus/tools/run_all_checks.js` reported 66 passes and two known baseline results for findings and oracle drift. The Windows GPU-slot test initially hit a sandbox restriction when hard-linking the installed Node executable. It passed all 12 groups when rerun with a temporary copy of Node.
