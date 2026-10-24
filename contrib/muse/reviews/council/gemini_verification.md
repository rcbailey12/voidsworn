# Verification of the Gemini audits (`contrib/gemini/`)

**Verifier:** Muse council seat, adversarial verification pass
**Date:** October 23, 2026
**Bases used:** ship pipeline audit checked against commit `2cfbde2` (Oct 21, the kit v10 code it describes); texture pass checked against its own stated basis `fad56d6`; staleness checked against HEAD `eca489e`. Every claim below was tested by reading or grepping the cited file at the cited commit.

## Verdict

Gemini's output is usable as a lead generator and unusable as a citation source. Its geometric reading of the kit script and its GLSL quoting are often genuinely accurate, and one of its headline recommendations was adopted almost verbatim by the main repo. But its ship pipeline audit contains inverted findings (it reports as missing two things the code already does), one phantom bug of exactly the kind this project once discarded an audit for, a roughly 40x error in the triangle budget, and line citations that land on unrelated code often enough that nothing from it should be merged by line number. Trust the texture pass more than the ship audit; verify every ship audit claim before acting on it.

## Tally

70 checkable claims tabled. Recommendations, predictions and time estimates are excluded from the tally and listed as uncheckable by category.

| Source | Verified | Wrong | Stale | Uncheckable |
| :--- | ---: | ---: | ---: | ---: |
| `NOTES.md` + `contrib/gemini/tools/` | 11 | 1 | 0 | 0 |
| `reviews/ship_pipeline_audit.md` | 19 | 13 | 0 | 2 |
| `reviews/texture_pass.md` | 17 | 4 | 0 | 1 |
| Superseded context (both reviews) | 0 | 0 | 2 | 0 |
| **Total** | **47** | **18** | **2** | **3** |

## The tools in `contrib/gemini/tools/`

Four files. `blender/hs/c19_kit.py` is a full fixed copy of the kit script (side tanks, forward casemate guns, yawed long guns, chevron front slabs, tier2 bridge, vertex colour export). `blender/project_paint.py` is a fixed copy of the paint script (multi-object join, bare-path auto-upgrade, Standard view transform, energy-neutral DETAIL, optional unified GAIN). `blender/auto_sweep.py` is an island/wire pruner plus protrusion socket extractor. `pc/jobs/c19_4_kit_to_game.bat` is the v11 job file with explicit pipe-format view arguments. The kit and paint copies genuinely implement what the reviews recommend, and the main repo merged equivalents as kit v11 in commit `6d4bc86` ("v55 (audit fixes)"). The exception is `auto_sweep.py`: it does not contain the wavy-plate flattening or the symmetrized bow loft that NOTES.md credits it with (see row N10b).

## Claim table: NOTES.md and the tools

| # | Claim | Verdict | Evidence |
| :--- | :--- | :--- | :--- |
| N1 | Contrib kit builds `sidetank` on `tanksaddle` mounts | VERIFIED | `contrib/gemini/tools/blender/hs/c19_kit.py` section 4: `cyl(f'sidetank{s_}'...)`, two `tanksaddle` boxes per side |
| N2 | Contrib `casegun` on `caseball`, aimed `(-1, s_*.25, -.02)` | VERIFIED | Same file, section 8 (base x is .152, NOTES says .155; trivial) |
| N3 | Contrib `longgun` yawed 8 deg, `casemate` frustum, `aftbay` caps the .285 to .36 cutout | VERIFIED | Same file: `Ryaw = Matrix.Rotation(s_*radians(-8)...)`, `frustum(f'casemate{s_}'...)`, `aftbaycoam`/`aftbaylid` at x=.322 |
| N4 | Contrib deck guns use `cyl(..., axis='Z', rot=Rn)`, aft tip z1 lowered .080 to .028 | VERIFIED | Same file section 5 and the `GUNS` header comment |
| N5 | Contrib `fun1`/`fun2` centred on y=0, `hatch2` mirrored | VERIFIED | Same file sections 2 and 6 (`hatch2_{s_}` loop) |
| N6 | Contrib front slabs are chevron lofts with `frontcheek`, `frontspine`, `IRON` paint | VERIFIED | Same file section 10: `loft(f'frontslab{k}'...)`, `tag(IRON)`, IRON=(.075,.058,.050) |
| N7 | Contrib bridge adds `tier2`, visor, 4 lamps, `wingsponson`, `brvents`, `mastcollar`, tripod | VERIFIED | Same file section 3 |
| N8 | Contrib kit export writes FLOAT_COLOR `Col` and calls `hs_lib.finish('kit')` | VERIFIED | Same file section 12 |
| N9 | Contrib paint script: join + Base Color fallback, bare-path auto-upgrade, Standard view transform, energy-neutral DETAIL | VERIFIED | `contrib/gemini/tools/blender/project_paint.py`: join block, `_parse_view_arg`, `view_transform = 'Standard'`, DETAIL values centred near 1.0 (brick 1.03/.98, noise map .88 to 1.12, bevel map 1.28 to .98) |
| N10a | Contrib `auto_sweep.py` deletes islands and wire debris under 7 mm and writes sockets JSON | VERIFIED | `contrib/gemini/tools/blender/auto_sweep.py`: components under 250 faces deleted, ray test at 0.007, `<pre>_sockets.json` written |
| N10b | Contrib `auto_sweep.py` "flattens wavy macro plates" and "auto-lofts a symmetrized bow from 16 cross-sections" | WRONG | Neither exists in the delivered script. No planesnap call, no bow loft, no ring-residual waviness test; the header comment promises the waviness step the code never performs |
| N11 | Contrib `.bat` passes explicit `view\|mask\|az\|el\|weight` arguments | VERIFIED | `contrib/gemini/tools/pc/jobs/c19_4_kit_to_game.bat` line 14 |

## Claim table: ship pipeline audit (basis `2cfbde2`)

| # | Claim | Verdict | Evidence |
| :--- | :--- | :--- | :--- |
| S1 | `project_paint.py` DETAIL multiplies albedo by brick Scale=38, noise Scale=900, bevel Radius=0.0015 | VERIFIED | `tools/blender/project_paint.py` at `2cfbde2`, DETAIL block (cited lines 87-99, actual about 101-113) |
| S2 | `smart_project(angle_limit=55, island_margin=0.006)` at line 20 | VERIFIED | Same file line 25; values exact, line off by 5 |
| S3 | `planesnap.py` exists, from Bake-off Entry E, TOL=0.006 | VERIFIED | `tools/blender/hs/planesnap.py:1` ("Bake-off entry E"), `:6` (TOL default .006) |
| S4 | planesnap "snaps every vertex within TOL of any region with > 5 faces" | WRONG | The region gate is area: `AMIN=.0015` (`planesnap.py:6`), small regions discarded at `:39-40`. No face-count criterion exists |
| S5 | `c19_kit.py` is a 280-line script | WRONG | 319 lines at `2cfbde2` |
| S6 | C19_51 took 10 kit versions | VERIFIED | `docs/ship_pipeline/SHIP_QUEUE.md`: "kit v10 in game Oct 21" |
| S7 | Hard-coded coordinate example `(-.235, -.120, -.150, -.060)` | VERIFIED | `c19_kit.py:44` (the `SIDE` table) |
| S8 | Track component counts (Voidsworn 6, Hegemony 5, Corsair 4 remaining, Deathless 4, obj 3; Chorus codes B22/B16/B19/B20/B21; Ithar 5; craft 3) | VERIFIED | Counted against `SHIP_QUEUE.md` rows at `2cfbde2` |
| S9 | "Track A: 21 hulls" and "11 of the 35 (6 Chorus + 5 Ithar)" | WRONG | Its own components sum to 22 (6+5+4+4+3), and its Track B table lists 5 Chorus, not 6. 22+10+3=35 is the consistent arithmetic |
| S10 | Desktop loads `hulls_hi/C19_51.vsm` at 1.5M to 2M triangles, ~11 to 14 MB per hull | WRONG | No `.vsm` file is in the repo. The shipped `hulls_hi/C19_51.json` carries t=38000 triangles, and the loader comment in `ships3d.js` (`loadAIHulls`) describes the dense exports as "20k to 38k triangles". The 30M to 40M battle-triangle alarm built on this collapses |
| S11 | Bug 1: `TANK` measured lines 44-50, cut at line 58, "never referenced again", leaving holes; `SHIP_QUEUE.md` wrong to say tanks rebuilt | WRONG | Measure is at `c19_kit.py:61-68`; `TANK` is reused at `:282`; tanks are rebuilt at `:281-289` as capsules with end caps and two straps each, almost exactly the fix the audit prescribes. The queue was right |
| S12 | Bug 2: `casegun` direction `(1, s_*.05, -.01)` points aft | VERIFIED | `c19_kit.py:216`, verbatim |
| S13 | Bug 2 cited at line 132, supported by a line 121 comment "aimed outward and slightly forward" | WRONG | The call is at line 216. No such comment exists; the actual section comment at `:203-204` says the barrel is "aimed aft along the side". The quoted comment is fabricated, and it reverses what the code says |
| S14 | Bug 3: `longgun` built with `axis='X'`, no rotation, zero outboard yaw | VERIFIED | `c19_kit.py:218` (cited 134-138). The "muzzle at x=0.158" is a small slip: the barrel spans .1525 to .3275 |
| S15 | Bug 4: `brace` starts at `(-.032, 0, .123)`, floating above the bridge roof (zt=0.102) | VERIFIED | `c19_kit.py:134` and `:148` (zt=.102). The float is real; the stated 19 mm is not (it is 21 mm from zt) |
| S16 | Bug 5: line 84 passes `axis=Rn` into `cyl()`, breaking the `hs_lib` axis lookup | WRONG | Phantom bug. No `axis=Rn` exists anywhere. `c19_kit.py:143` passes `rot=Rn` with the default axis, which is correct usage. `cyl` is defined at `hs_lib.py:30` with the axis dict at `:32`, not at line 25 as cited |
| S17 | Bug 5, second half: aft `GUNS` pair (z .006 to .080) aims about 59 deg up | VERIFIED | `c19_kit.py:16-17`; computed elevation 58.7 deg |
| S18 | Bug 6: `fun1` at y=+.010, `fun2` at y=-.012, staggered off centreline | VERIFIED | `c19_kit.py:122` (cited line 64) |
| S19 | Bug 6: `hatch2` is port-only with no starboard mate | WRONG | `c19_kit.py:192` places `hatch2` at y=+.045 and `hatch3` at y=-.045 in the same statement. The mate exists |
| S20 | Bug 7: `ellipsoid()` defined but never called; casemate built with `box()` | VERIFIED | Definition at `c19_kit.py:205`, no call anywhere; `box(f'casemate{s_}'...)` at `:212` (cited 122/127) |
| S21 | Bug 7: the .285 to .36 aft deck cut is never covered by a kit part | UNCHECKABLE | The cut exists (`cut_extra`, `c19_kit.py:75`, cited as line 56), but coverage is a rendered-geometry question; no dedicated cap part exists by name, and the contrib fix adds one |
| S22 | Bug 8: export block (lines 267-280) never calls `hs_lib.finish('kit')`, never writes `COL` to a vertex attribute, exports 200+ unjoined Principled-material objects | WRONG | All three checkable points are inverted. `c19_kit.py:312-314` writes `COL` into a FLOAT_COLOR `Col` attribute on every part, `:315` calls `finish('C19_kit')`, and `:319` exports the joined mesh with vertex colours. Colours were never separate Principled materials; they come from the `tag()`/`COL` mechanism at `:97-100` |
| S23 | Q3: front slabs are 4 flat pitch-only boxes, uniform 16 mm, identical plaques, SLATE=(.06,.06,.065) | VERIFIED | `c19_kit.py:248-256` (t_=.016, `rot=(0,-a_,0)`, SLATE at `:249`) |
| S24 | Q3: bridge crown is one flat slab plus `rooftank` and two bare mast cylinders, "plain and sparse" | WRONG | The same file already carries a bridge-top dressing section at `:292-311`: crow's nest, radar dish, whip aerials, searchlights, rangefinder, roof vents and a roof hatch. The premise ignores a quarter of the file it audited |
| S25 | `hs_lib.vents` "already implemented in hs_lib.py line 46" | WRONG | `vents` is at `hs_lib.py:58`. Line 46 is `barrel` |
| S26 | Q5 root cause 1: `paint_level.level()` forces the non-black texel mean to 0.8 x concept mean, bisecting gain in lo/hi = 0.5/8.0 | VERIFIED | `tools/blender/paint_level.py:6-12`, as cited |
| S27 | Q5 premise: `paint_level` is run on hull and kit separately | VERIFIED | `tools/blender/pixal_to_game.py:52` levels the hull albedo; `:89` levels the kit paint (`'kit paint level'`) |
| S28 | Q5 numbers: hull gain g=2.35, kit floored at 0.5, a 4.7x luminance ratio | UNCHECKABLE | No run output, log or screenshot in the repo supports the specific values. They are presented as measured fact with no source |
| S29 | Q5 root cause 2: repo `c19_4_kit_to_game.bat` line 14 calls `project_paint.py` with bare image paths, causing IndexError | WRONG | The invocation is at line 15 and already uses the full pipe format (`"%V%_left.png\|%V%_left_mask.png\|0\|0\|1"` etc.). Line 14 is the `KEEP` set line. The quoted command does not exist in the file |
| S30 | Q5 root cause 3 (micro-facts): `project_paint.py` takes the first MESH object (line 15) and reads a `ShaderNodeVertexColor` (line 68) | VERIFIED | Actual lines 16 and about 72. But the root cause built on them depends on S22, which is false: the kit arrives joined, with vertex colours, so the failure described cannot occur |
| S31 | Q5 root cause 4: the EMIT bake in `project_paint.py` runs with no view-transform override | VERIFIED | No `view_settings` anywhere in the Oct 21 file; bake and save at about line 123 (cited 104) |
| S32 | `aiKitMat`: roughness 0.68, metallic 0.08, texture level 0.95/1.15, 0.3 self-light | VERIFIED | `ships3d.js:777-779` at `2cfbde2`, all four values exact |
| S33 | `aiKitMat`: `environmentIntensity = 0.6` | WRONG | Actual value is 1.25 (`ships3d.js:778`) |
| S34 | Q4: face adjacency `adj` is at `planesnap.py` line 26 | VERIFIED | `planesnap.py:26`, exact |

## Claim table: texture pass (basis `fad56d6`)

| # | Claim | Verdict | Evidence |
| :--- | :--- | :--- | :--- |
| T1 | Proof of reading: REVIEW_PROTOCOL.md 35 lines, last line as quoted | VERIFIED | `docs/REVIEW_PROTOCOL.md` at `fad56d6`: 35 lines, last line "- Claude checks every claim against the code before merging" |
| T2 | Proof: AGENTS.md 45 lines, last line as quoted | VERIFIED | `AGENTS.md` at `fad56d6`: 45 lines, last line matches |
| T3 | Proof: TEXTURE_PASS.md 43 lines, last line as quoted (37 chars) | VERIFIED | `docs/ship_pipeline/TEXTURE_PASS.md` at `fad56d6`: 43 lines, last line "pick. Free tools and CC0 assets only." |
| T4 | Proof: gfx3d.js totals 486 lines | WRONG | 479 lines at `fad56d6`, still 479 at HEAD. Its quoted last line is genuinely the last line (479), so the content was read and the count is invented or mis-added |
| T5 | Proof: project_paint.py totals 196 lines | WRONG | 195 lines at `fad56d6`; the quoted last line is line 195. Off by one |
| T6 | Q1: TEXTURE_PASS.md describes `tex_dl.ps1`, the Downloads path and the eight search terms | VERIFIED | `docs/ship_pipeline/TEXTURE_PASS.md:14-17` |
| T7 | Q1: `HULLFX_STYLE` map at `gfx3d.js:10` with the stated values | VERIFIED | `gfx3d.js:10`, exact, values exact |
| T8 | Q1: `HULLFX_PLATE` gated off for styles 2 and 3 at `gfx3d.js:21` | VERIFIED | `gfx3d.js:21`: `defines.HULLFX_PLATE=this.style!==2&&this.style!==3&&!this.ai;` |
| T9 | Q2: sampler registration (`getSamplers`, `getActiveTextures`, `ubo.setTexture`) at lines 24/25/29 | VERIFIED | Content exact; actual lines 22/23/27. A consistent small drift affects most of this review's gfx3d.js citations (see below) |
| T10 | Q2: GLSL classification block (steel/rust/grime from `surfaceAlbedo`) and the `HULLFX_MAP` block, quoted | VERIFIED | Quotes verbatim at `gfx3d.js:65-68` and `:71-78` (cited 69-72 and 74-81) |
| T11 | Q2/Q4: dominant-axis expression `an.x>an.y&&an.x>an.z?...` at lines 89 and 118 | VERIFIED | Verbatim at `gfx3d.js:85` and `:114`, except the code spells the varyings `vHfxL`/`vHfxN`, not `vHfXL`/`vHfXN` as transcribed throughout |
| T12 | Q3: `oc = tco.outputs['Object']` at `project_paint.py:103`; noise scales 32/7, 140/4, 500/2; "unit cube spanning 1/1.1" at line 3 | VERIFIED | `project_paint.py:103`, `:3`, and the noise calls in the PROC block (500/2 at `:133`) |
| T13 | Finding 1: the EXPORT block links only Base Color and never links the baked `_orm`/`_nrm` into the GLB | VERIFIED | `project_paint.py:190-195`, link at `:193` (cited 194). Caveat: the maps are not discarded; they are saved as PNG files at `:185` and `:188` in the same run |
| T14 | Finding 2: bevel radius .0008 at `project_paint.py:127` with the `.985` to `.80` dot-product range | VERIFIED | `project_paint.py:127` and the `rng(dp.outputs['Value'], .985, .80, 0, 1)` call beside it |
| T15 | Finding 3: height derived from luminance, `ht=sqrt(max(hfxLum,0.0))*0.05` | VERIFIED | Quote verbatim at `gfx3d.js:100` (cited 104) |
| T16 | Finding 4: steel/rust/grime inferred from saturation and luminance | VERIFIED | Quote verbatim at `gfx3d.js:66` (cited 70) |
| T17 | Finding 5: triplanar projection hard-switches axes with no blend weights | VERIFIED | `gfx3d.js:85` and `:114` |
| T18 | Finding 6: damage cloning at `gfx3d.js:323` copies a field list omitting `paint`, `det`, `kit`, `fin`, so damaged hulls lose their finish defines | WRONG | Line 323 is nebula GLSL (`NEB_GLSL`), not cloning code. The real code is `shipDamageFx` at `gfx3d.js:430`, where the quoted object is only the second argument of the assign (the fallback half), and where an existing plugin (`if(pl) Object.assign(pl,opts)`) keeps its unlisted fields. The defect as stated is not established |
| T19 | Finding 7: `smart_project(angle_limit=math.radians(55), island_margin=0.0002)` at `project_paint.py:27` | VERIFIED | `project_paint.py:27`, exact |
| T20 | Q4: `pid=hfxH(vec3(cx,row,1.3))`, `id=hfxH(vec3(ci,2.7+hfxS.x))`, `bl=hfxN(vHfXL*0.35+hfxS.x*2.0)` | VERIFIED | Verbatim at `gfx3d.js:120`, `:123` and `:152` (cited 124, 127, 152; the third is exact) |
| T21 | Q2 snippet: `normalW=normalize(mix(normalW,nb,pf*0.8*dk))` fed by `dk=1.0-smoothstep(0.15,0.45,hfxMet)` | WRONG | The actual mix at `gfx3d.js:133` is `mix(normalW,nb,0.85*dk)`, and the quoted `dk` computation does not exist (only `float dk=1.0;` at `:129`). Two details of the snippet are invented |
| T22 | Q1: specific ambientCG asset IDs, and the download/VRAM size estimates | UNCHECKABLE | External catalogue facts and projections; nothing in the repo can confirm them |

## Stale (true when written, superseded at HEAD)

| # | Claim | Evidence |
| :--- | :--- | :--- |
| ST1 | `aiKitMat` is a separate material with its own PBR values and self-light (ship audit Q5) | At HEAD, `ships3d.js:785-788` clones the hull material instead, with a comment crediting the audits: "v55 (audits, Oct 22): painted parts use the hull paint's own material settings and its HullFx layer... The old 0.3 self-light is gone". Gemini's recommended fix was adopted; its description is now history |
| ST2 | Kit `DETAIL=1` baking is the live detail mechanism (ship audit Q0 framing) | At HEAD, `tools/blender/project_paint.py:153` defaults DETAIL to '0', "off by default; the shared in-game detail layer (HullFx DET) covers hull and parts alike" |

## Most consequential errors

1. **Bugs 1 and 8 invert reality, and they are load-bearing.** The side tanks were already rebuilt (S11) and the kit already wrote vertex colours, called `finish()` and exported joined (S22). Together they manufacture Q5 root cause 3 and a fix step for a non-problem. Anyone merging from this audit would have spent effort re-fixing working code, and the audit even contradicts `SHIP_QUEUE.md` on the tanks when the queue was right.
2. **Bug 5 (`axis=Rn`) is a phantom bug** (S16). The mechanism description of `hs_lib.cyl` is accurate, but the triggering call does not exist; the real call passes `rot=Rn`, which is correct. This is precisely the failure mode that got a previous outside audit discarded on this project.
3. **The triangle budget is wrong by about 40x** (S10). The shipped dense hull is 38k triangles, not 1.5M to 2M. The LOD recommendation may still be sensible for the raw Pixal3D source, but as a claim about what the desktop game loads it is false, and the 30M to 40M battle alarm derived from it is unfounded.
4. **A pattern of partial reading presented as full reading.** `hatch2` condemned as asymmetric with its mate `hatch3` on the same line (S19); the bridge condemned as bare with a full dressing section later in the same file (S24); a supporting comment quote fabricated and reversed (S13); a `.bat` invocation quoted that does not exist in the file (S29). Individually small, together they mean the ship audit's negative claims specifically cannot be trusted without re-checking.
5. **Citations are not mergeable.** Ship audit line numbers drift by +17 to +107 lines and land on unrelated code (its export block citation, 267-280, points into the side-tank and bulkhead sections). The texture pass is better: quotes are verbatim and several citations exact, but its gfx3d.js numbers drift by +2 to +4 through the shader region, its two headline line counts are wrong (T4, T5), and its finding 6 cites nebula code for a damage-cloning claim (T18).

## What Gemini got notably right

- **The paint_level root cause is real and well-evidenced** (S26, S27): the level mechanics are quoted accurately, and the premise that hull and kit are levelled independently is confirmed by `pixal_to_game.py:52` and `:89`. This is the strongest analytical work in either review.
- **The aiKitMat readout and fix** (S32): four of five values exact, and its recommendation (make the kit material a clone of the hull material) is what the main repo shipped in v55, with a comment crediting the audits (ST1).
- **Several geometric findings on the v10 kit are accurate** even where the line map is not: the aft-pointing `casegun` (S12), the un-yawed `longgun` (S14), the floating `brace` (S15), the near-vertical aft deck guns (S17), the staggered funnels (S18), the unused `ellipsoid()` (S20), and the front slab description down to the SLATE colour value (S23).
- **The texture pass quotes GLSL verbatim** (T10, T11, T15, T16, T20) and lands several citations exactly (`gfx3d.js:10`, `:21`, `:152`; `project_paint.py:27`, `:103`, `:127`). Its proof-of-reading quotes for the three docs are all genuine (T1-T3); only its counts fail.
- **Its own tools mostly do what NOTES.md says** (N1-N9, N11), and the repo history shows the main agent merged equivalents within a day. The exception is `auto_sweep.py`, whose blurb promises two features the script does not contain (N10b).
- **Its "Not checked" section is honest** about the files it did not open, which is more than the ship audit offers.

## Not checked

- Whether the merged repo kit (v11 onward) matches the contrib copies behaviourally; only the contrib files and the merge commit message were compared.
- Rendered or in-game outcomes (brightness ratios, floating geometry in practice, Babylon material clone semantics in T18) were not tested by running Blender or the game; verdicts rest on the code as written.
- All recommendations, time estimates (35 to 50 days, minutes per hull), the TRELLIS-at-38k anecdote, and the claim that kit vertex normals are flat were treated as uncheckable opinion or as requiring assets not in the repo, and are excluded from the tally.
