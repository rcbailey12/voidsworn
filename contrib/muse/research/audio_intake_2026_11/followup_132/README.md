# Audio follow-up, issue 132: chair record

Closes the step 1 propagation flag from the #101 intake (README.md in this folder): the synth strip is now in the source table, not only in godot/audio/cues.json. Models per the issue block: DeepSeek and Qwen wrote, Rey chaired, Argon reviewed only, plus a blind Rey leg first (standing rule R89). Legs are in legs/.

## The change (sfx.js, SFX.MAP only)

26 MAP entries changed or added; everything else in MAP byte-identical; no SFX.CUES changes; no changes to render_synth.js or sfx_data.js.

- 21 hybrid cues: the {syn:1} layer removed and the #101 per-cue upgrade layer transcribed in (shellBang, laserLR, needleTick, plasmaShot, railStrike, salvoBoom, lanceLR, ionField, darkLance, choirBell, torpLaunch, heavyPlate, starShimmer, hullTick, lasSear, plasmaHit, railHit, ionZap, shieldShimmer, shieldShatter, boomCrunch on gun_shell, gun_las, gun_needle, gun_plasma, gun_rail, salvo_tail, lance, lance_ion, lance_dark, lance_choir, torp, torp_heavy, torp_star, hit, hit_las, hit_plasma, hit_rail, hit_ion, shield, shield_break, boom_s).
- sting_win, sting_loss: syn layer removed, no upgrade layer (matches today's cues.json exactly).
- hit_glass: REPLACE transcribed as shipped in #101: MAP is now [{s:'hitGlass',g:.35}]; the old shieldHit layer is gone, as in cues.json.
- ui_enemy: NEW entry ui_enemy:[{s:'enemyTurn',g:.6}], placed with the other ui_ entries. It had no MAP entry at all, so a re-render would have emptied its layers.
- wreck: [{s:'scrape'},{s:'wreckSettle',g:.25}]. Scope note: the issue does not name wreck. It is the same defect class in the same table (a MAP cue whose cues.json layers a re-render would silently shrink), found by the same measurement, so the chair included it and flags it here.

## Decision: Option A, pure MAP transcription (unanimous)

The one design choice was how to treat the browser build, which reads the same MAP (sfx.js:120-124) but whose sample data (sfx_data.js) holds only the 27 incumbent sets, none of the 23 new #101 sets. All three writer legs picked A independently; the Argon review concurs on the convergence and names the cost, which the chair accepts and states here:

- Option B (also regenerate sfx_data.js with the 23 new sets) rejected: a 128-file Vorbis-to-Opus transcode plus exact reproduction of the PC-side generator format, spent on a build that is frozen to break-fixes.
- Option C (a render-only marker so MAP keeps a syn layer the render drops) rejected: MAP would permanently misdescribe cues.json, plus a new convention for Opus to know about.
- Accepted browser costs under A: the 24 hybrids lose the synth blend they currently mix in the browser (the new layers are silent no-ops there); hit_glass becomes synth-only in the browser, the sharpest delta, because its hitGlass set is not in sfx_data.js; sting_win, sting_loss and ui_enemy stop having a synth bank rendered in the browser (sfx.js:81), playback unaffected (they play their recorded sets; ui_alert is the live precedent). The Godot side, the active target, is exact.

## death_crack ithar variant

Satisfied by carry-over, no source change exists or is needed: death_crack is in neither SFX.CUES nor SFX.MAP, and render_synth.js:52-53 carries any cue not in its table over whole from the previous cues.json. Verified in the render run below: the death_crack entry, variants.ithar included, came through byte-identical.

## Verification (chair-run, Nov 4, 2026, against main 36606e10)

1. node --check on the edited sfx.js: pass.
2. Render-transform diff over the edited MAP against today's cues.json layers: 0 differences across all 44 MAP entries.
3. The real render, run in a scratch tree with node-web-audio-api and ffmpeg: node godot/audio/build/render_synth.js completed, "cues 67 synth files 136". Parsed-JSON diff of the produced cues.json against today's file: layers identical for every MAP cue; full-entry diff apart from the synth take lists: NONE (the gun_ defer values in today's file already equal the render's raised values); death_crack and board_grapple identical whole entries; cue count 67 in and 67 out; zero cues with a syn layer after the render.
4. Set-name check: every set the edited MAP references exists in godot/audio/clips/index.json (67 sets), including all 23 new #101 sets.
5. Not run locally: the Godot audio checks (audio_check.gd, salvo_check.gd) need a Godot binary, which this environment does not have; they run in the PR checks.

## Finding for Opus (not fixed here)

Thirteen further cues sit in SFX.CUES with no MAP entry and exactly one recorded layer each in today's cues.json: gun_flak (gunFlak g:.35), gun_tracer (gunTracer g:.3), gun_spine (gunSpine g:.32), gun_glob (gunGlob g:.35), torp_rocket (torpRocket g:.34), torp_sac (torpSac g:.36), hit_wet (hitWet g:.4), patter_hull (patterHull g:.15), patter_shield (patterShield g:.12), engine (engineLoop g:.3), cough (cough g:.2), puff (puff g:.3), ui_round (uiRound g:.2, r:.95). A re-render empties their layers, because the render builds them from CUES with layers [] and the carry-over only covers cues absent from the table. This is pre-existing on unedited main (verified: the same 13, plus ui_enemy, lack MAP entries there) and this fix neither causes nor worsens it; ui_enemy was the fourteenth and is fixed because #101 named it. The transcriptions above are ready to paste (gains from today's cues.json; all 13 sets verified present in clips/index.json; browser-neutral today because none of the 13 sets are in sfx_data.js, so browser playback keeps falling back to the synth bank). If Opus wants a fully lossless re-render, a small follow-up adding these 13 entries closes it. Related pre-existing note: a render run in a tree with no previous cues.json drops the Godot-only cues (death_crack, board_grapple and kin) entirely; unchanged by this fix.

## Screening notes

Unanimous legs are rare; the disagreements were about wording, not substance. The Argon review is used in large part: its cuts are adopted (the writer legs verified the chair target's internal consistency against the pack's classification, not against independently quoted cues.json layers for 23 of the entries; the binding numeric check is the chair's real render in Verification; Qwen's Option C mechanism claim and its sfx.js:333 speculation are cut; the synth-bank correction for sting_win, sting_loss and ui_enemy was found first by the blind Rey leg). The sfx.js:333 question the legs flagged is settled by reading the line: it assigns spj on SFX.CUES entries (ui_enemy included) after MAP is defined, independent of MAP layers, and the rendered ui_enemy entry (spj 0.02) matches today's cues.json, as the full-entry diff confirms. DeepSeek's formatting note (spaces after key colons in its deliverable block) is moot: the applied edit replaced only the array text inside the file's own entries.
