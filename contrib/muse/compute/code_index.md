# Voidsworn code index

Basis: repo HEAD 51337c2. Generated mechanically by hidden_files/compute/code_index.js (Compute Run 2). Read-only analysis; no game files were changed.

Total top-level definitions across the 18 build files: **1016** (218 const, 27 let, 761 function, 9 class, 1 var).

Names defined more than once: 0.

## Definitions and references per build file

| File | Definitions | References made to indexed names | References received by its definitions |
|---|---|---|---|
| meshopt3d.js | 1 | 1 | 4 |
| data.js | 45 | 102 | 594 |
| core.js | 93 | 520 | 1744 |
| battle.js | 203 | 1958 | 2222 |
| scene3d.js | 74 | 1397 | 2936 |
| ships3d.js | 118 | 950 | 451 |
| fx3d.js | 93 | 1149 | 340 |
| sfx_data.js | 1 | 1 | 2 |
| sfx.js | 1 | 81 | 87 |
| gfx3d.js | 40 | 276 | 113 |
| vfx3d.js | 36 | 350 | 129 |
| wfx3d.js | 86 | 1091 | 967 |
| campaign_meta.js | 30 | 485 | 377 |
| campaign_run.js | 27 | 693 | 91 |
| ui3d.js | 114 | 2179 | 684 |
| campaign3d.js | 24 | 413 | 104 |
| perf3d.js | 30 | 228 | 102 |
| main3d.js | 0 | 60 | 0 |

"References made" counts identifier tokens in that file that match an indexed top-level name. "References received" sums the reference counts of the names defined in that file.

## The 30 most-referenced top-level names

| Name | Kind | Defined at | References | Referenced from files |
|---|---|---|---|---|
| G | const | scene3d.js:4 | 1686 | 13 |
| B | let | battle.js:5 | 1128 | 12 |
| rr | function | wfx3d.js:124 | 491 | 6 |
| RUN | let | core.js:125 | 460 | 8 |
| C3 | const | scene3d.js:2 | 411 | 7 |
| V3 | const | scene3d.js:2 | 367 | 9 |
| esc | const | core.js:11 | 197 | 6 |
| W | const | data.js:2 | 187 | 9 |
| META | let | core.js:74 | 170 | 8 |
| ACT | const | campaign_meta.js:4 | 115 | 5 |
| hdist | function | core.js:20 | 112 | 5 |
| OV | const | ui3d.js:162 | 112 | 2 |
| SFX | const | sfx.js:10 | 87 | 5 |
| wfp | function | wfx3d.js:118 | 87 | 1 |
| HULLS | const | data.js:59 | 84 | 7 |
| rnd | function | core.js:6 | 81 | 5 |
| MB | const | scene3d.js:2 | 81 | 7 |
| clamp | const | core.js:10 | 79 | 10 |
| log | function | ui3d.js:5 | 75 | 4 |
| alive | const | battle.js:90 | 69 | 4 |
| hexWorld | function | scene3d.js:7 | 64 | 5 |
| ri | const | core.js:7 | 63 | 4 |
| HS | const | scene3d.js:3 | 59 | 3 |
| FAC3D | const | ships3d.js:2 | 59 | 5 |
| nq | function | wfx3d.js:120 | 57 | 3 |
| pick | const | core.js:8 | 55 | 7 |
| hkey | const | core.js:19 | 53 | 2 |
| BW | const | battle.js:2 | 51 | 2 |
| fxText | function | fx3d.js:410 | 47 | 3 |
| FACTIONS | const | data.js:110 | 46 | 9 |

## Method and limits

- Definitions are declarations starting at column 0 in the build files. build.py concatenates the 18 files into one flat script, so column 0 is the top level. Function declarations (including async), const, let, var and class declarations are counted; a statement declaring several names (const A=1, B=2;) contributes one definition per name. Object methods, properties (for example ACT.xxx handlers in ui3d.js) and declarations inside functions are not top-level and are not indexed.
- A reference is an identifier token in the comment-stripped, string-stripped source of the 20-file corpus (the 18 build files plus head.html and sim3d.js), excluding tokens immediately preceded by a dot (property access) and excluding the one token on each name's own declaration line. Template literal ${...} expressions are kept as code; string contents are not.
- Limits: references built by string concatenation, dynamic dispatch (obj[name]), eval-style lookups and names reached only through the DOM or Babylon registration are invisible to this count. A low count means "not referenced as a plain identifier", not "unreachable". Names declared inside sim3d.js itself are not indexed, so a token in sim3d.js that matches an indexed name is counted as a reference even if sim3d.js also declares a local of the same name (rare, and it only inflates a count, never zeroes one).
- sfx_data.js is a single giant data literal (base64 audio); meshopt3d.js is the inlined meshoptimizer decoder. Both legitimately define almost nothing.
