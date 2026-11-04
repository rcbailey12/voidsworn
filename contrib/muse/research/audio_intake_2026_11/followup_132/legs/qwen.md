Qwen leg (writer), issue #132. Model gates: GATE 1 passed (selector showed Qwen3.8-Max before sending), GATE 2 passed (chat header still showed Qwen3.8-Max after generation started). Single complete response, no preference picker, no verification slider.

Qwen leg (writer) - issue #132, audio follow-up

1. Entry-by-entry verification of the chair's target MAP against the render transform

The render transform at render_synth.js:32 is:
MAP layer WITH an s key renders as {s, g (default 1), r (default 1), d (default 0), pj (default null)}.
MAP layer WITHOUT an s key renders as {syn: 1, g}.
MAP source style: g written only when not 1, r only when not 1, d only when not 0, pj never written.
I recompute the rendered output of each target entry and compare it to the cues.json layers quoted in the pack.

The 21 hybrid append cases

Cue | Target MAP | Rendered layers | Pack-quoted today's layers | Verdict
gun_shell | [{s:'boomLow',g:.5,r:1.3},{s:'shellBang',g:.45}] | [{s:'boomLow',g:.5,r:1.3,d:0,pj:null},{s:'shellBang',g:.45,r:1,d:0,pj:null}] | Original [{s:'boomLow',g:.5,r:1.3}] minus syn, plus shellBang(g:.45) | MATCH
gun_las | [{s:'laserLarge',r:.9},{s:'laserLR',g:.4}] | [{s:'laserLarge',g:1,r:.9,d:0,pj:null},{s:'laserLR',g:.4,r:1,d:0,pj:null}] | Original minus syn, plus laserLR(g:.4) | MATCH
gun_needle | [{s:'laserSmall',r:1.3},{s:'needleTick',g:.4,r:1.15}] | [{s:'laserSmall',g:1,r:1.3,d:0,pj:null},{s:'needleTick',g:.4,r:1.15,d:0,pj:null}] | Original minus syn, plus needleTick(g:.4,r:1.15) | MATCH
gun_plasma | [{s:'laserLarge',g:.35,r:.62},{s:'plasmaShot',g:.38}] | [{s:'laserLarge',g:.35,r:.62,d:0,pj:null},{s:'plasmaShot',g:.38,r:1,d:0,pj:null}] | Original minus syn, plus plasmaShot(g:.38) | MATCH
gun_rail | [{s:'boomLow',g:.4,r:1.1},{s:'railStrike',g:.5}] | [{s:'boomLow',g:.4,r:1.1,d:0,pj:null},{s:'railStrike',g:.5,r:1,d:0,pj:null}] | Original minus syn, plus railStrike(g:.5) | MATCH
salvo_tail | [{s:'boomLow',g:.45,r:.75,d:.05},{s:'salvoBoom',g:.45}] | [{s:'boomLow',g:.45,r:.75,d:.05,pj:null},{s:'salvoBoom',g:.45,r:1,d:0,pj:null}] | Original minus syn, plus salvoBoom(g:.45) | MATCH
lance | [{s:'laserLarge',g:.75,r:.55},{s:'lanceLR',g:.32}] | [{s:'laserLarge',g:.75,r:.55,d:0,pj:null},{s:'lanceLR',g:.32,r:1,d:0,pj:null}] | Original minus syn, plus lanceLR(g:.32) | MATCH
lance_ion | [{s:'arc',g:.7},{s:'ionField',g:.3,r:1.1}] | [{s:'arc',g:.7,r:1,d:0,pj:null},{s:'ionField',g:.3,r:1.1,d:0,pj:null}] | Original minus syn, plus ionField(g:.3,r:1.1) | MATCH
lance_dark | [{s:'laserLarge',g:.35,r:.42},{s:'darkLance',g:.28}] | [{s:'laserLarge',g:.35,r:.42,d:0,pj:null},{s:'darkLance',g:.28,r:1,d:0,pj:null}] | Original minus syn, plus darkLance(g:.28) | MATCH
lance_choir | [{s:'laserSmall',g:.35,r:1.5},{s:'choirBell',g:.3}] | [{s:'laserSmall',g:.35,r:1.5,d:0,pj:null},{s:'choirBell',g:.3,r:1,d:0,pj:null}] | Original minus syn, plus choirBell(g:.3) | MATCH
torp | [{s:'whoosh',g:.75,r:1.1},{s:'torpLaunch',g:.35}] | [{s:'whoosh',g:.75,r:1.1,d:0,pj:null},{s:'torpLaunch',g:.35,r:1,d:0,pj:null}] | Original minus syn, plus torpLaunch(g:.35) | MATCH
torp_heavy | [{s:'whoosh',g:.7,r:.85},{s:'heavyPlate',g:.45,r:.85}] | [{s:'whoosh',g:.7,r:.85,d:0,pj:null},{s:'heavyPlate',g:.45,r:.85,d:0,pj:null}] | Original minus syn, plus heavyPlate(g:.45,r:.85) | MATCH
torp_star | [{s:'whoosh',g:.45,r:1.5},{s:'starShimmer',g:.32}] | [{s:'whoosh',g:.45,r:1.5,d:0,pj:null},{s:'starShimmer',g:.32,r:1,d:0,pj:null}] | Original minus syn, plus starShimmer(g:.32) | MATCH
hit | [{s:'hullHit'},{s:'hullTick',g:.5}] | [{s:'hullHit',g:1,r:1,d:0,pj:null},{s:'hullTick',g:.5,r:1,d:0,pj:null}] | Original minus syn, plus hullTick(g:.5) | MATCH
hit_las | [{s:'hullHit',g:.45,r:1.3},{s:'lasSear',g:.4}] | [{s:'hullHit',g:.45,r:1.3,d:0,pj:null},{s:'lasSear',g:.4,r:1,d:0,pj:null}] | Original minus syn, plus lasSear(g:.4) | MATCH
hit_plasma | [{s:'hullHitBig',g:.55,r:.78},{s:'plasmaHit',g:.5}] | [{s:'hullHitBig',g:.55,r:.78,d:0,pj:null},{s:'plasmaHit',g:.5,r:1,d:0,pj:null}] | Original minus syn, plus plasmaHit(g:.5) | MATCH
hit_rail | [{s:'hullHitBig',g:.6,r:1.12},{s:'railHit',g:.5}] | [{s:'hullHitBig',g:.6,r:1.12,d:0,pj:null},{s:'railHit',g:.5,r:1,d:0,pj:null}] | Original minus syn, plus railHit(g:.5) | MATCH
hit_ion | [{s:'arc',g:.6,r:1.2},{s:'ionZap',g:.38}] | [{s:'arc',g:.6,r:1.2,d:0,pj:null},{s:'ionZap',g:.38,r:1,d:0,pj:null}] | Original minus syn, plus ionZap(g:.38) | MATCH
shield | [{s:'shieldHit'},{s:'shieldShimmer',g:.3,r:.9}] | [{s:'shieldHit',g:1,r:1,d:0,pj:null},{s:'shieldShimmer',g:.3,r:.9,d:0,pj:null}] | Original minus syn, plus shieldShimmer(g:.3,r:.9) | MATCH
shield_break | [{s:'shieldBig'},{s:'shieldHit',g:.5,r:.8},{s:'shieldShatter',g:.45}] | [{s:'shieldBig',g:1,r:1,d:0,pj:null},{s:'shieldHit',g:.5,r:.8,d:0,pj:null},{s:'shieldShatter',g:.45,r:1,d:0,pj:null}] | Original minus syn, plus shieldShatter(g:.45) | MATCH
boom_s | [{s:'boomSmall'},{s:'boomCrunch',g:.42}] | [{s:'boomSmall',g:1,r:1,d:0,pj:null},{s:'boomCrunch',g:.42,r:1,d:0,pj:null}] | Original minus syn, plus boomCrunch(g:.42) | MATCH

All 21 append cases verify. No entry produces an unexpected field value.

The 2 hybrid no-upgrade cases

Cue | Target MAP | Rendered layers | Pack-quoted today's layers | Verdict
sting_win | [{s:'victory'}] | [{s:'victory',g:1,r:1,d:0,pj:null}] | MAP minus syn, no upgrade | MATCH
sting_loss | [{s:'enemyTurn',r:.8}] | [{s:'enemyTurn',g:1,r:.8,d:0,pj:null}] | MAP minus syn, no upgrade | MATCH

The REPLACE case

Cue | Target MAP | Rendered layers | Pack-quoted today's layers | Verdict
hit_glass | [{s:'hitGlass',g:.35}] | [{s:'hitGlass',g:.35,r:1,d:0,pj:null}] | [{s:'hitGlass',g:.35,r:1}] (single layer, replaced) | MATCH

The original MAP was [{s:'shieldHit',g:.35,r:1.6},{syn:1,g:.8}]. The #101 chair rules replaced the entire layer set with the new recorded set. The target correctly encodes only the replacement layer. r defaults to 1, matching the cues.json r:1.

The same-class completion (wreck)

Cue | Target MAP | Rendered layers | Pack-quoted today's layers | Verdict
wreck | [{s:'scrape'},{s:'wreckSettle',g:.25}] | [{s:'scrape',g:1,r:1,d:0,pj:null},{s:'wreckSettle',g:.25,r:1,d:0,pj:null}] | MAP [{s:'scrape'}] plus wreckSettle(g:.25) | MATCH

The new entry (ui_enemy)

Cue | Target MAP | Rendered layers | Pack-quoted today's layers | Verdict
ui_enemy | [{s:'enemyTurn',g:.6}] | [{s:'enemyTurn',g:.6,r:1,d:0,pj:null}] | [{s:'enemyTurn',g:.6,r:1,d:0,pj:null}] | MATCH

Verification summary
All 26 entries in the chair's target MAP render to exactly the layers present in today's cues.json. No transcription error found. No entry requires correction.

2. Ruling on options A / B / C

Pick: Option A (pure MAP transcription).
Reasons:
Frozen-browser rule. The standing project rule freezes the browser build to break-fixes only. Option A changes only sfx.js MAP entries; it does not touch sfx_data.js, the playback code path, or the browser bundle format. Options B and C both expand the browser-side surface (B adds 23 new base64 sets and a transcode pipeline; C adds a new render convention the browser playback code at sfx.js:120-124 must interpret).
#101 intent. Issue #101 stripped synth layers to make the cues recorded-only. Option A makes the browser source (MAP) agree with that intent: every hybrid cue is now recorded-only in MAP. The browser will not mix in a synth take for these cues because no {syn:1} layer remains. The fact that the 23 new sets are absent from sfx_data.js means those specific layers are silent no-ops in the browser, but this is consistent with the freeze: the browser already cannot play them, and the Godot side (the active target) is exact.
Maintenance cost for Opus. Option A introduces no new conventions, no new files, no format changes. Option B requires reproducing the tools/pc/sfx_dl.bat generator format exactly (JSON-style quoted keys, one line per set) and a transcode step (ffmpeg libopus, 128 files) whose output must be byte-stable across regenerations - a recurring maintenance tax. Option C requires Opus to understand a marker convention in render_synth.js that has no other precedent in the codebase, and it makes MAP no longer a plain transcription of cues.json layers, increasing cognitive load for every future edit.
Risk. Option B's transcode introduces a format-conversion step (Ogg Vorbis 44.1 kHz to Ogg Opus) whose output must be validated per-file; a single mis-encoded set silently breaks browser playback for that cue. Option C's marker, if mis-applied to a future cue, would silently drop a layer from cues.json. Option A has no such failure modes: the edit is a static data table, verified by the render diff.
Option B is the correct long-term target if the browser is ever unfrozen, but under the current rules it is out of scope and adds risk without a consumer. Option C solves a problem (preserving the browser synth blend) that the frozen-browser rule and #101 intent both say we should not preserve.

3. Ruling on wreck

Include wreck in the fix.
The gap is identical in mechanism to the 24 hybrids: MAP is [{s:'scrape'}] but today's cues.json has a second layer {s:'wreckSettle',g:.25} that a re-render would silently drop. The done-when criterion ("the browser's cue table matches godot/audio/cues.json") is violated for wreck in exactly the same way. Excluding it would leave a known re-render regression in the same file, requiring a follow-up issue for one line. The chair's scope call is correct; the delivery record should note that wreck was not named in the issue body and was added as a same-class completion.

4. Confirm or refute: death_crack carry-over reading

CONFIRM.
The reasoning:
death_crack does not appear in SFX.CUES and does not appear in SFX.MAP. It is a Godot-only battle-pass cue.
render_synth.js builds its output table exclusively from SFX.CUES and SFX.MAP (render_synth.js:32). A cue with no CUES recipe and no MAP entry is never produced by the render.
render_synth.js:52-53 merges the previous cues.json: any cue NOT in the new table is carried over whole.
Therefore death_crack (and all its variants, including variants.ithar with layers [{s:'crackGlass',g:.35,r:1.6,d:.1,pj:0}]) is carried over byte-for-byte from the previous cues.json.
No syn layer can be injected into a carried-over cue because the render never touches its layers.
The done-when for death_crack is satisfied by this carry-over. No browser-source change exists or is needed.
I cannot identify any code path in the described render that would allow a variant of a carried-over cue to regress. The carry-over is whole (the pack states "carried over whole"). Refutation would require showing that render_synth.js iterates into variants of carried-over cues, which the pack's description of lines 52-53 does not support.

5. Complete corrected MAP block (changed and added entries only)

No corrections are needed. The chair's target is verified as-is. Reproduced here in sfx.js source style for the writer's deliverable:
gun_shell:[{s:'boomLow',g:.5,r:1.3},{s:'shellBang',g:.45}],
gun_las:[{s:'laserLarge',r:.9},{s:'laserLR',g:.4}],
gun_needle:[{s:'laserSmall',r:1.3},{s:'needleTick',g:.4,r:1.15}],
gun_plasma:[{s:'laserLarge',g:.35,r:.62},{s:'plasmaShot',g:.38}],
gun_rail:[{s:'boomLow',g:.4,r:1.1},{s:'railStrike',g:.5}],
salvo_tail:[{s:'boomLow',g:.45,r:.75,d:.05},{s:'salvoBoom',g:.45}],
lance:[{s:'laserLarge',g:.75,r:.55},{s:'lanceLR',g:.32}],
lance_ion:[{s:'arc',g:.7},{s:'ionField',g:.3,r:1.1}],
lance_dark:[{s:'laserLarge',g:.35,r:.42},{s:'darkLance',g:.28}],
lance_choir:[{s:'laserSmall',g:.35,r:1.5},{s:'choirBell',g:.3}],
torp:[{s:'whoosh',g:.75,r:1.1},{s:'torpLaunch',g:.35}],
torp_heavy:[{s:'whoosh',g:.7,r:.85},{s:'heavyPlate',g:.45,r:.85}],
torp_star:[{s:'whoosh',g:.45,r:1.5},{s:'starShimmer',g:.32}],
hit:[{s:'hullHit'},{s:'hullTick',g:.5}],
hit_las:[{s:'hullHit',g:.45,r:1.3},{s:'lasSear',g:.4}],
hit_plasma:[{s:'hullHitBig',g:.55,r:.78},{s:'plasmaHit',g:.5}],
hit_rail:[{s:'hullHitBig',g:.6,r:1.12},{s:'railHit',g:.5}],
hit_glass:[{s:'hitGlass',g:.35}],
hit_ion:[{s:'arc',g:.6,r:1.2},{s:'ionZap',g:.38}],
shield:[{s:'shieldHit'},{s:'shieldShimmer',g:.3,r:.9}],
shield_break:[{s:'shieldBig'},{s:'shieldHit',g:.5,r:.8},{s:'shieldShatter',g:.45}],
boom_s:[{s:'boomSmall'},{s:'boomCrunch',g:.42}],
sting_win:[{s:'victory'}],
sting_loss:[{s:'enemyTurn',r:.8}],
wreck:[{s:'scrape'},{s:'wreckSettle',g:.25}],
ui_enemy:[{s:'enemyTurn',g:.6}],

Placement notes:
The 24 existing cues (gun_shell through sting_loss) and wreck replace their current entries in SFX.MAP at sfx.js:321-332, in their existing positions.
ui_enemy is a new entry, placed with the other ui_ entries in MAP.
All other MAP entries remain byte-identical.
No changes to SFX.CUES.

6. Additional edits judged necessary

render_synth.js: no change required. The existing transform (s-key -> recorded layer, no s-key -> synth layer, carry-over for absent cues, gun_ defer) handles every case in the target table without modification.
sfx_data.js: no change required under Option A. The 23 new sets are absent and remain absent; the corresponding MAP layers are silent no-ops in the browser, which is acceptable under the frozen-browser rule. The synth bank continues to render as a whole-cue fallback because sfx.js:81 requires every sample to be present to suppress it, and the missing sets prevent that condition.
sfx.js spj assignment line (sfx.js:333): INFERRED - the pack notes this line touches ui_enemy. With ui_enemy now having a MAP entry, the render will produce a layers array for it. The spj line likely assigns a pj override post-MAP. Since the target MAP renders pj:null for ui_enemy (the default) and today's cues.json also has pj:null for that cue, the spj assignment either (a) does not touch ui_enemy, or (b) assigns null, which is a no-op. I cannot verify the exact code of line 333 from the pack. The chair's verification protocol (running the real render and diffing all 67 cues including variants) will catch any discrepancy here. Flagged for the chair; no edit proposed without seeing the line.
salvo scheduler interaction (sfx.js play() references cue.salvo for salvo_tail): INFERRED - the scheduler looks up the cue by name. The cue name 'salvo_tail' is unchanged; only its layers array content changes. The scheduler's behaviour (play the cue, which resolves its layers) is unaffected by which recorded sets fill those layers. No edit needed.

7. Items labelled INFERRED

The exact content and effect of sfx.js:333 (spj assignment). Not quoted in the pack. Flagged for chair verification; no regression expected based on the pj:null default matching today's cues.json.
The salvo scheduler's internal lookup mechanism. The pack states it references cue.salvo; I infer it resolves by cue name and is insensitive to layer content changes.
The specific behaviour of sfx.js:81 (synth-bank suppression condition). The pack describes it as requiring MAP to be all-recorded AND every sample present; I take this at face value but have not seen the code.

8. Risks and observations the pack did not name

Merge-order sensitivity. render_synth.js:52-53 carries over cues not in the new table. If a future edit accidentally removes a cue from SFX.CUES while leaving it in MAP (or vice versa), the carry-over would silently substitute the stale cues.json version. The current fix does not create this risk (all 26 cues remain in both CUES and MAP), but the verification protocol should confirm the cue count in the rendered output equals the expected 67.
gun_ defer interaction. The render raises defer on gun_ cues (layers untouched). The five gun_ cues in this fix (gun_shell, gun_las, gun_needle, gun_plasma, gun_rail) will receive the defer flag in the rendered output. This is an expected render output excluded per the done-when, but the diff script must explicitly exclude the defer field to avoid a false positive.
No pj written in MAP, but cues.json has pj:null everywhere. The pack confirms this is consistent (render default null matches). If a future cues.json entry ever carries a non-null pj, the MAP source style cannot express it without a convention change. Not a problem for this fix; noted for the record.

End of Qwen leg report.
