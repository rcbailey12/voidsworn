Verdict per section

1. Entry-by-entry verification of the target MAP

Notation: D = g:1, r:1, d:0, pj:null. Under the pack's render transform, every target layer has an s key, so each renders as a recorded layer with defaults filled. I compared each target entry against the cues.json layers quoted in the pack. No target entry needs correction.

Entry | Target renders to | Verdict
gun_shell | {s:'boomLow',g:.5,r:1.3,d:0,pj:null} + {s:'shellBang',g:.45,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus shellBang.
gun_las | {s:'laserLarge',g:1,r:.9,d:0,pj:null} + {s:'laserLR',g:.4,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus laserLR.
gun_needle | {s:'laserSmall',g:1,r:1.3,d:0,pj:null} + {s:'needleTick',g:.4,r:1.15,d:0,pj:null} | Exact. MAP-minus-syn plus needleTick.
gun_plasma | {s:'laserLarge',g:.35,r:.62,d:0,pj:null} + {s:'plasmaShot',g:.38,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus plasmaShot.
gun_rail | {s:'boomLow',g:.4,r:1.1,d:0,pj:null} + {s:'railStrike',g:.5,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus railStrike.
salvo_tail | {s:'boomLow',g:.45,r:.75,d:.05,pj:null} + {s:'salvoBoom',g:.45,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus salvoBoom, d:.05 preserved.
lance | {s:'laserLarge',g:.75,r:.55,d:0,pj:null} + {s:'lanceLR',g:.32,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus lanceLR.
lance_ion | {s:'arc',g:.7,r:1,d:0,pj:null} + {s:'ionField',g:.3,r:1.1,d:0,pj:null} | Exact. MAP-minus-syn plus ionField.
lance_dark | {s:'laserLarge',g:.35,r:.42,d:0,pj:null} + {s:'darkLance',g:.28,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus darkLance.
lance_choir | {s:'laserSmall',g:.35,r:1.5,d:0,pj:null} + {s:'choirBell',g:.3,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus choirBell.
torp | {s:'whoosh',g:.75,r:1.1,d:0,pj:null} + {s:'torpLaunch',g:.35,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus torpLaunch.
torp_heavy | {s:'whoosh',g:.7,r:.85,d:0,pj:null} + {s:'heavyPlate',g:.45,r:.85,d:0,pj:null} | Exact. MAP-minus-syn plus heavyPlate.
torp_star | {s:'whoosh',g:.45,r:1.5,d:0,pj:null} + {s:'starShimmer',g:.32,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus starShimmer.
hit | {s:'hullHit',g:1,r:1,d:0,pj:null} + {s:'hullTick',g:.5,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus hullTick.
hit_las | {s:'hullHit',g:.45,r:1.3,d:0,pj:null} + {s:'lasSear',g:.4,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus lasSear.
hit_plasma | {s:'hullHitBig',g:.55,r:.78,d:0,pj:null} + {s:'plasmaHit',g:.5,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus plasmaHit.
hit_rail | {s:'hullHitBig',g:.6,r:1.12,d:0,pj:null} + {s:'railHit',g:.5,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus railHit.
hit_glass | {s:'hitGlass',g:.35,r:1,d:0,pj:null} | Exact. REPLACE case: only hitGlass, no shieldHit, no syn layer.
hit_ion | {s:'arc',g:.6,r:1.2,d:0,pj:null} + {s:'ionZap',g:.38,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus ionZap.
shield | {s:'shieldHit',g:1,r:1,d:0,pj:null} + {s:'shieldShimmer',g:.3,r:.9,d:0,pj:null} | Exact. MAP-minus-syn plus shieldShimmer.
shield_break | {s:'shieldBig',g:1,r:1,d:0,pj:null} + {s:'shieldHit',g:.5,r:.8,d:0,pj:null} + {s:'shieldShatter',g:.45,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus shieldShatter.
boom_s | {s:'boomSmall',g:1,r:1,d:0,pj:null} + {s:'boomCrunch',g:.42,r:1,d:0,pj:null} | Exact. MAP-minus-syn plus boomCrunch.
sting_win | {s:'victory',g:1,r:1,d:0,pj:null} | Exact. MAP-minus-syn, no upgrade layer.
sting_loss | {s:'enemyTurn',g:1,r:.8,d:0,pj:null} | Exact. MAP-minus-syn, no upgrade layer.
wreck | {s:'scrape',g:1,r:1,d:0,pj:null} + {s:'wreckSettle',g:.25,r:1,d:0,pj:null} | Exact. scrape plus wreckSettle.
ui_enemy | {s:'enemyTurn',g:.6,r:1,d:0,pj:null} | Exact. Matches #101 cues.json layer.

No entry is flagged as failing to render exactly. No SFX.CUES changes and no cues.json edits are required.

2. Option A/B/C ruling

I pick Option A, pure MAP transcription.

Reasons:

- Option A makes the Godot render exact: the MAP becomes the plain source of today's cues.json layers, apart from expected render outputs such as synth take lists and gun_ defer.
- Option A respects the frozen-browser rule: the browser is frozen to break-fixes only. The browser will lose the current synth blend on the 24 hybrids because no syn layer remains and the new recorded sets are absent from sfx_data.js, but that is a consequence of making the source match #101's recorded-only intent, not a new browser feature.
- Option A matches the #101 intent as far as the browser sample data allows: the source records the recorded-only layers; the missing new sets are silent no-ops in the browser until sfx_data.js is regenerated.
- Option B is rejected: it requires transcoding 128 files from mono Ogg Vorbis 44.1 kHz to mono Ogg Opus base64, reproducing the PC-side generator format exactly, and measuring size growth. That is not justified for a frozen browser and adds substantial maintenance cost.
- Option C is rejected: it adds a new render_synth.js convention so MAP no longer reads as the plain source of cues.json, and Opus must know the marker. The maintenance cost is real and the browser benefit is not worth it under the frozen-browser rule.

3. Wreck ruling

Include wreck in the fix.

Reason: wreck is the same class of gap as the named hybrids. MAP is [{s:'scrape'}], today's cues.json adds {s:'wreckSettle',g:.25}, and a re-render would silently drop wreckSettle. The issue does not name wreck, so the delivery record should flag this as a same-class scope completion. The change is exact and low risk.

4. death_crack ithar carry-over

Confirmed.

death_crack is not in SFX.CUES or SFX.MAP. The render table therefore does not contain it. render_synth.js carries over any cue not in the new table whole at render_synth.js:52-53. The ithar variant's layers are already recorded-only, so a re-render cannot restore a syn layer into the variant. The done-when is satisfied for death_crack by carry-over, and the delivery record should say that plainly. No browser-source change exists for this variant.

Complete corrected MAP block for changed and added entries only

Everything else in MAP stays byte-identical. ui_enemy is placed with the other ui_ entries.

gun_shell: [{s:'boomLow',g:.5,r:1.3},{s:'shellBang',g:.45}],
gun_las: [{s:'laserLarge',r:.9},{s:'laserLR',g:.4}],
gun_needle: [{s:'laserSmall',r:1.3},{s:'needleTick',g:.4,r:1.15}],
gun_plasma: [{s:'laserLarge',g:.35,r:.62},{s:'plasmaShot',g:.38}],
gun_rail: [{s:'boomLow',g:.4,r:1.1},{s:'railStrike',g:.5}],
salvo_tail: [{s:'boomLow',g:.45,r:.75,d:.05},{s:'salvoBoom',g:.45}],
lance: [{s:'laserLarge',g:.75,r:.55},{s:'lanceLR',g:.32}],
lance_ion: [{s:'arc',g:.7},{s:'ionField',g:.3,r:1.1}],
lance_dark: [{s:'laserLarge',g:.35,r:.42},{s:'darkLance',g:.28}],
lance_choir: [{s:'laserSmall',g:.35,r:1.5},{s:'choirBell',g:.3}],
torp: [{s:'whoosh',g:.75,r:1.1},{s:'torpLaunch',g:.35}],
torp_heavy: [{s:'whoosh',g:.7,r:.85},{s:'heavyPlate',g:.45,r:.85}],
torp_star: [{s:'whoosh',g:.45,r:1.5},{s:'starShimmer',g:.32}],
hit: [{s:'hullHit'},{s:'hullTick',g:.5}],
hit_las: [{s:'hullHit',g:.45,r:1.3},{s:'lasSear',g:.4}],
hit_plasma: [{s:'hullHitBig',g:.55,r:.78},{s:'plasmaHit',g:.5}],
hit_rail: [{s:'hullHitBig',g:.6,r:1.12},{s:'railHit',g:.5}],
hit_glass: [{s:'hitGlass',g:.35}],
hit_ion: [{s:'arc',g:.6,r:1.2},{s:'ionZap',g:.38}],
shield: [{s:'shieldHit'},{s:'shieldShimmer',g:.3,r:.9}],
shield_break: [{s:'shieldBig'},{s:'shieldHit',g:.5,r:.8},{s:'shieldShatter',g:.45}],
boom_s: [{s:'boomSmall'},{s:'boomCrunch',g:.42}],
sting_win: [{s:'victory'}],
sting_loss: [{s:'enemyTurn',r:.8}],
wreck: [{s:'scrape'},{s:'wreckSettle',g:.25}],
ui_enemy: [{s:'enemyTurn',g:.6}],

Additional edits

None. I judge no render_synth.js or sfx_data.js edit necessary under Option A.

INFERRED / not verifiable from the pack

- INFERRED: The actual sfx.js:333 spj assignment for ui_enemy is not quoted in the pack. I cannot verify its exact current form. The target MAP adds ui_enemy, so the chair's verification should inspect that line to confirm it still makes sense. No exact edit can be specified from the pack.
- INFERRED: The salvo scheduler risk is not verifiable from the pack text. The target MAP changes only layers and does not rename salvo_tail or alter a salvo property, so it should not affect the scheduler, but this is inferred rather than read directly.
- INFERRED: Exact cues.json field formatting and omission of default fields is taken from the pack's quoted layers and render-transform description. The comparison assumes omitted defaults are equivalent to rendered g:1, r:1, d:0, pj:null.
