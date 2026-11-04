Argon review leg: issue #132, browser SFX table synth strip
Model check: Argon High verified (model picker and prompt bar read "Argon High" before sending, prompt bar still read "Argon High" after sending).

CHAIR SCREENING HEADER (read this first): This review was USED in large part, a change from several recent jobs. Its transform table checks out against render_synth.js:32 for all 26 entries. Its cuts are adopted in the chair record with two chair resolutions from source: (1) the sfx.js:333 question is settled by reading the line itself (it assigns spj on SFX.CUES entries, ui_enemy included, independent of MAP layers; the rendered ui_enemy spj of 0.02 matches today's cues.json, and the chair's full-entry render diff found no non-layer differences anywhere); (2) its protocol point 1 (diff full parsed JSON, not layers only) was in fact how the chair ran the real render: apart from synth take lists, the full-entry diff was empty, gun_ defer included. Its circularity cut on the writer legs is correct as far as the pack goes and is answered by the chair's real render, which is the binding numeric check. Its hit_glass collision framing is adopted as the stated cost of Option A.

--- Argon verbatim text follows ---

# Argon Leg (Review Only): Issue #132 Browser SFX Table Synth Strip

## 1. Render Transform Verification (render_synth.js:32)

Under render_synth.js:32, any SFX.MAP layer containing an s key renders to {s, g (default 1), r (default 1), d (default 0), pj (default null)}, while any layer without an s key renders to {syn: 1, g}.

Checking every target entry and claimed render output across rey_blind.md, deepseek.md, and qwen.md against this transform:

| Cue | Chair and Writer Target SFX.MAP Entry | Verified Render Output (render_synth.js:32) | Writer Claims Check |
|---|---|---|---|
| gun_shell | [{s:'boomLow',g:.5,r:1.3},{s:'shellBang',g:.45}] | [{s:'boomLow',g:.5,r:1.3,d:0,pj:null},{s:'shellBang',g:.45,r:1,d:0,pj:null}] | Transform exact. |
| gun_las | [{s:'laserLarge',r:.9},{s:'laserLR',g:.4}] | [{s:'laserLarge',g:1,r:.9,d:0,pj:null},{s:'laserLR',g:.4,r:1,d:0,pj:null}] | Transform exact. |
| gun_needle | [{s:'laserSmall',r:1.3},{s:'needleTick',g:.4,r:1.15}] | [{s:'laserSmall',g:1,r:1.3,d:0,pj:null},{s:'needleTick',g:.4,r:1.15,d:0,pj:null}] | Transform exact. |
| gun_plasma | [{s:'laserLarge',g:.35,r:.62},{s:'plasmaShot',g:.38}] | [{s:'laserLarge',g:.35,r:.62,d:0,pj:null},{s:'plasmaShot',g:.38,r:1,d:0,pj:null}] | Transform exact. |
| gun_rail | [{s:'boomLow',g:.4,r:1.1},{s:'railStrike',g:.5}] | [{s:'boomLow',g:.4,r:1.1,d:0,pj:null},{s:'railStrike',g:.5,r:1,d:0,pj:null}] | Transform exact. |
| salvo_tail | [{s:'boomLow',g:.45,r:.75,d:.05},{s:'salvoBoom',g:.45}] | [{s:'boomLow',g:.45,r:.75,d:.05,pj:null},{s:'salvoBoom',g:.45,r:1,d:0,pj:null}] | Transform exact (d:.05 preserved on layer 1). |
| lance | [{s:'laserLarge',g:.75,r:.55},{s:'lanceLR',g:.32}] | [{s:'laserLarge',g:.75,r:.55,d:0,pj:null},{s:'lanceLR',g:.32,r:1,d:0,pj:null}] | Transform exact. |
| lance_ion | [{s:'arc',g:.7},{s:'ionField',g:.3,r:1.1}] | [{s:'arc',g:.7,r:1,d:0,pj:null},{s:'ionField',g:.3,r:1.1,d:0,pj:null}] | Transform exact. |
| lance_dark | [{s:'laserLarge',g:.35,r:.42},{s:'darkLance',g:.28}] | [{s:'laserLarge',g:.35,r:.42,d:0,pj:null},{s:'darkLance',g:.28,r:1,d:0,pj:null}] | Transform exact. |
| lance_choir | [{s:'laserSmall',g:.35,r:1.5},{s:'choirBell',g:.3}] | [{s:'laserSmall',g:.35,r:1.5,d:0,pj:null},{s:'choirBell',g:.3,r:1,d:0,pj:null}] | Transform exact. |
| torp | [{s:'whoosh',g:.75,r:1.1},{s:'torpLaunch',g:.35}] | [{s:'whoosh',g:.75,r:1.1,d:0,pj:null},{s:'torpLaunch',g:.35,r:1,d:0,pj:null}] | Transform exact. |
| torp_heavy | [{s:'whoosh',g:.7,r:.85},{s:'heavyPlate',g:.45,r:.85}] | [{s:'whoosh',g:.7,r:.85,d:0,pj:null},{s:'heavyPlate',g:.45,r:.85,d:0,pj:null}] | Transform exact. |
| torp_star | [{s:'whoosh',g:.45,r:1.5},{s:'starShimmer',g:.32}] | [{s:'whoosh',g:.45,r:1.5,d:0,pj:null},{s:'starShimmer',g:.32,r:1,d:0,pj:null}] | Transform exact. |
| hit | [{s:'hullHit'},{s:'hullTick',g:.5}] | [{s:'hullHit',g:1,r:1,d:0,pj:null},{s:'hullTick',g:.5,r:1,d:0,pj:null}] | Transform exact. |
| hit_las | [{s:'hullHit',g:.45,r:1.3},{s:'lasSear',g:.4}] | [{s:'hullHit',g:.45,r:1.3,d:0,pj:null},{s:'lasSear',g:.4,r:1,d:0,pj:null}] | Transform exact. |
| hit_plasma | [{s:'hullHitBig',g:.55,r:.78},{s:'plasmaHit',g:.5}] | [{s:'hullHitBig',g:.55,r:.78,d:0,pj:null},{s:'plasmaHit',g:.5,r:1,d:0,pj:null}] | Transform exact. |
| hit_rail | [{s:'hullHitBig',g:.6,r:1.12},{s:'railHit',g:.5}] | [{s:'hullHitBig',g:.6,r:1.12,d:0,pj:null},{s:'railHit',g:.5,r:1,d:0,pj:null}] | Transform exact. |
| hit_glass | [{s:'hitGlass',g:.35}] | [{s:'hitGlass',g:.35,r:1,d:0,pj:null}] | Transform exact; matches pack-quoted [{s:'hitGlass',g:.35,r:1}] + defaults. |
| hit_ion | [{s:'arc',g:.6,r:1.2},{s:'ionZap',g:.38}] | [{s:'arc',g:.6,r:1.2,d:0,pj:null},{s:'ionZap',g:.38,r:1,d:0,pj:null}] | Transform exact. |
| shield | [{s:'shieldHit'},{s:'shieldShimmer',g:.3,r:.9}] | [{s:'shieldHit',g:1,r:1,d:0,pj:null},{s:'shieldShimmer',g:.3,r:.9,d:0,pj:null}] | Transform exact. |
| shield_break | [{s:'shieldBig'},{s:'shieldHit',g:.5,r:.8},{s:'shieldShatter',g:.45}] | [{s:'shieldBig',g:1,r:1,d:0,pj:null},{s:'shieldHit',g:.5,r:.8,d:0,pj:null},{s:'shieldShatter',g:.45,r:1,d:0,pj:null}] | Transform exact. |
| boom_s | [{s:'boomSmall'},{s:'boomCrunch',g:.42}] | [{s:'boomSmall',g:1,r:1,d:0,pj:null},{s:'boomCrunch',g:.42,r:1,d:0,pj:null}] | Transform exact. |
| sting_win | [{s:'victory'}] | [{s:'victory',g:1,r:1,d:0,pj:null}] | Transform exact. |
| sting_loss | [{s:'enemyTurn',r:.8}] | [{s:'enemyTurn',g:1,r:.8,d:0,pj:null}] | Transform exact. |
| wreck | [{s:'scrape'},{s:'wreckSettle',g:.25}] | [{s:'scrape',g:1,r:1,d:0,pj:null},{s:'wreckSettle',g:.25,r:1,d:0,pj:null}] | Transform exact; matches pack-quoted [{s:'scrape'}] + {s:'wreckSettle',g:.25}. |
| ui_enemy | [{s:'enemyTurn',g:.6}] | [{s:'enemyTurn',g:.6,r:1,d:0,pj:null}] | Transform exact; matches full pack quote [{s:'enemyTurn',g:.6,r:1,d:0,pj:null}]. |

Source formatting note on deepseek.md: DeepSeek's deliverable block inserts a space after each key colon (gun_shell: [...]), whereas PACK.md and qwen.md omit the space (gun_shell:[...]). Use the PACK.md/qwen.md no-space formatting to match sfx.js house style. (Chair note: the applied edit replaced only the array text and kept the file's own key formatting, so this is already satisfied.)

## 2. Cuts: Claims Not Backed by PACK.md

Cut DeepSeek's and Qwen's claim that the 21 append cues and sting_win/sting_loss were verified against "Pack-quoted today's layers" (deepseek.md Section 1; qwen.md Section 1 table column 4):

PACK.md explicitly quotes cues.json or original MAP layer parameters only for hit_glass, wreck, ui_enemy, and death_crack. For the other 23 entries, PACK.md provides only the classification (MAP minus syn plus the named upgrade set) and the chair's derived target MAP.

deepseek.md and qwen.md circularly treated the chair's target MAP numbers as "Pack-quoted today's layers". As rey_blind.md properly notes, the forward render transform is proved for all 26 entries, but numeric equality with cues.json for those 23 cues is only confirmed when Verification Protocol Step 2 runs.

Cut Qwen's claim that Option C requires browser playback code (sfx.js:120-124) to interpret a new marker (qwen.md Section 2):

PACK.md specifies that in both browser (sfx.js:120-124) and render (render_synth.js:32), any MAP layer without an s key is already treated as a syn layer. Under Option C, keeping {syn:1, ...} with a render-only drop flag requires a convention in render_synth.js only; sfx.js:120-124 would continue to see a layer without s and play the synth blend unchanged.

Cut Qwen's unbacked claims about sfx.js:333 (qwen.md Section 6):

Qwen claims sfx.js:333 "likely assigns a pj override post-MAP" and "either (a) does not touch ui_enemy, or (b) assigns null".

Possibility (a) directly contradicts PACK.md ("the spj assignment line after MAP, sfx.js:333, touches ui_enemy"), and the claim that spj overrides MAP layer pj to null is fabricated without source evidence in PACK.md.

Cut Rey's unlabelled assertion about what sfx.js:333 modifies (rey_blind.md Section 6.4):

rey_blind.md states as fact that sfx.js:333 "assigns spj on SFX.CUES entries (including ui_enemy) after MAP is defined" and that render_synth.js reads it independently of MAP.

PACK.md does not quote line 333 or state whether it mutates SFX.CUES or SFX.MAP. That claim cannot be backed from PACK.md alone and must be treated as INFERRED until inspected in sfx.js.

Cut Qwen's (and the Pack's) blanket claim that the browser synth fallback bank still renders for all (qwen.md Section 6; PACK.md "The browser playback question"):

PACK.md states sfx.js:81 renders the synth bank for a cue "unless MAP is all-recorded AND every sample is present" in sfx_data.js, and claims "the missing new sets prevent" suppression.

As rey_blind.md Section 6.1 proves from the pack's own facts, sting_win (victory), sting_loss (enemyTurn), and ui_enemy (enemyTurn) have post-edit MAP entries that are all-recorded and use only incumbent sets already present in sfx_data.js. Therefore, sfx.js:81 will stop rendering the browser synth bank for those three cues.

Cut Qwen's unlabelled speculation in Section 8 ("Merge-order sensitivity"):

Qwen speculates about a hypothetical future edit removing a cue from SFX.CUES while leaving it in MAP (or vice versa) without labeling the mechanism as INFERRED.

## 3. Ruling Collisions (Frozen-Browser Rule vs. #101 Recorded-Only Intent)

All three legs converge on the same rulings: Option A (pure MAP transcription), include wreck (flagged as a scope completion), and confirm death_crack carry-over via render_synth.js:52-53. However, executing Option A exposes a direct collision between the frozen-browser rule and #101's recorded-only intent:

- hit_glass becomes 100% synth in the browser (direct collision with #101 recorded-only intent):

Under #101's REPLACE rule, hit_glass in SFX.MAP drops its incumbent recorded layer (shieldHit, which IS in sfx_data.js) and replaces both shieldHit and {syn:1} with a single layer {s:'hitGlass',g:.35}.

Because the frozen-browser rule rejects Option B (adding the 23 new sets to sfx_data.js), hitGlass is missing from sfx_data.js.

Per sfx.js:120-124 (_layers), when no recorded layer resolves from sfx_data.js, the browser falls back to playing the synth take. Thus, under Option A, hit_glass in the browser regresses from a hybrid (shieldHit + synth) to synth-only, the exact opposite of #101's recorded-only strip.

- 21 hybrid append cues and wreck play incomplete layers in the browser:

To honor #101's recorded-only intent, Option A strips {syn:1} from the 21 append hybrids in SFX.MAP. Because the frozen-browser rule leaves the 21 new upgrade sets (and wreckSettle) out of sfx_data.js, those appended layers are silent no-ops in the browser; the browser loses the synth layer it previously played.

## 4. What the Chair's Verification Protocol Would Miss

1. Regressions in non-layers fields on the 65 rendered cues:

Protocol Step 2 diffs only the layers arrays across all 67 cues (and Step 3 checks whole carry-over only for death_crack and board_grapple), dismissing other diffs as expected synth take lists and gun_ defer changes.

If running render_synth.js alters any other cue-level property on the 65 rendered cues (such as spj, salvo, defer on non-gun_ cues, or any hand-edited field in cues.json), or if adding ui_enemy to SFX.MAP interacts with sfx.js:333 (spj) during the render, a layers-only diff will not catch it. Step 2 should diff the full parsed JSON of cues.json after explicitly stripping only .synth and gun_*.defer.

2. Raw text diff false positives on layers:

Step 2 does not specify whether "Diff the produced cues.json layers" is a text diff or a parsed JSON structural diff. A raw text diff can fail on float formatting (0.5 vs .5) or key ordering even when parsed layer objects are identical.

3. Browser runtime execution (sfx.js:333, sfx.js:81, and sfx.js:120-124):

Step 1 (node --check sfx.js) checks syntax only, and Step 2 (render_synth.js) only extracts SFX.CUES and SFX.MAP. No step in the protocol runs the browser audio initialization or playback path:

- It will not verify that sfx.js:333 (the spj assignment touching ui_enemy) executes cleanly at browser runtime once SFX.MAP.ui_enemy is defined.
- It will not catch that hit_glass drops shieldHit and falls back to synth-only in the browser.
- It will not verify that sting_win, sting_loss, and ui_enemy remain playable in the browser after sfx.js:81 stops generating their synth fallback banks.

4. Clean-tree (no previous cues.json) carry-over loss:

Step 2 runs render_synth.js against a tree containing today's cues.json as the previous file. Because death_crack (including variants.ithar) and board_grapple exist only in cues.json and not in sfx.js, the protocol masks the fact that a clean rebuild without a prior cues.json silently drops both cues and variants.ithar.

5. Local verification of Godot sample set names before PR CI:

Because no Godot binary runs in the local environment (Step 4), local verification only proves sfx.js matches cues.json; it cannot verify locally that the 23 new sample set names referenced in SFX.MAP resolve cleanly in Godot's audio checks until PR CI runs.
