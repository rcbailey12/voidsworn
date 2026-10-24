# Voidsworn Council Audit: QA Lens (bugs and code issues)

Basis commit: `4fa29bd Add files via upload` (HEAD of ~/workspace/voidsworn-repo, checked 2026-10-23).
Scope: the least-reviewed files (sfx.js 364 lines, gfx3d.js 479, meshopt3d.js 196, perf3d.js 113, tbot3.js 21, all read in full) plus the seams between systems: settings save/restore, Persist cloud/local conflicts, migrateMeta backfill math, campaign state edges, error paths, timers, and stale-id coverage. Method: grep-driven; every function and setting named below was confirmed to exist by search before being cited. Findings are marked OBSERVED (defect visible in the code) or INFERRED (reasoned, with the reasoning stated).

## Verdict

GO WITH CONDITIONS. The assigned files are unusually defensive: voice stealing, pool guards, disposal checks and one-time latches are everywhere, and I found no new crash-on-launch defect in sfx.js, gfx3d.js, meshopt3d.js, perf3d.js or tbot3.js themselves. The real risk sits in the seams. One finding (N1) is a save-bricking class that will fire the next time any hull or admiral id is renamed, and it should be fixed before that rename ships. Two medium findings (N2, N3) silently break the aspect system and cross-device settings. Of the six prior headline findings I spot-verified, four are still present, one is partially fixed, and one is fixed.

## Prior findings: verification

| # | Prior finding (source) | Status at 4fa29bd | Evidence |
|---|---|---|---|
| 1 | Intercept ends as a player win when the second of three transports escapes (battle_rules.md) | STILL PRESENT | battle.js:722 still sets `o.need=Math.max(1,tr.length-1)`, and battle.js:778 still reads `if(o.esc>o.total-o.need){ B.over='win'; B.partial=true;` |
| 2 | Veteran threat scoring is blind to line of sight (enemy_ai.md) | PARTIALLY FIXED | battle.js:996: the after-move term now gates on `los(p,v)`, but the in-range term still reads `if(d<=w.r&&inArc(p,v,w.arc)){ const e=expectedVs(p,w,v); tot+=e.hull+e.shield*.2; }` with no los check, and the standard evalThreat at battle.js:1027 has no los check either. A gun parked behind an asteroid still scores as if it can fire. |
| 3 | AI hull paint and kit textures are never released (ship_loading.md) | FIXED | ships3d.js:963 now defines `function aiTexReleaseAll(){ for(const e of Object.values(AI_TEX)){` which disposes paint, normal, detail and fin textures, bumps the generation guard, and is called from disposeAllViews in fx3d.js. |
| 4 | endActivation never latches B.busy, so a double tap can end two activations (ui.md) | STILL PRESENT | ui3d.js:549: `if(!B||B.over||B.side!=='player'||(B.busy&&manual)) return;` Non-manual calls ignore B.busy entirely, and nothing sets B.busy synchronously before `await aiStep()`. aiStep only sets busy when enemy units are pending, so the double-advance window the review described is intact. |
| 5 | Retreat modal keyboard hole: c3retreatYes does not recheck battle state (independent_audit.md) | STILL PRESENT | campaign3d.js:95: `ACT.c3retreatYes=()=>{ closeModal(); if(B&&B.campaign) finishBattle('retreat'); };` finishBattle's own B.finished latch (campaign3d.js:65) helps only after a finish already happened; a battle that has ended with B.over set but not yet finished can still be converted to a retreat, and onKey (ui3d.js:484) still has no open-modal check. |
| 6 | navLights forces a full world-matrix recompute per ship per frame (effects_world.md) | STILL PRESENT | vfx3d.js:147: `v.root.computeWorldMatrix(true); const M=v.root.getWorldMatrix(), t=G.time,` in the per-frame nav light path, unchanged. |

Also rechecked in passing: the end-card `min-width:420px` rule (ui.md) is still at head.html:115, unchanged.

## New findings

### N1. HIGH, OBSERVED. A renamed hull or admiral id bricks the campaign save permanently

unknownId (core.js:73) gives renamed ids a soft landing, but only for relics, modules and perks. The lookups a save depends on most are unguarded:

- core.js:164: `const t=HULLS[ship.tpl];` and core.js:168 immediately dereferences it: `const maxHp=Math.round(t.hp*mm*(1+(fx.hpPct||0)));`. A fleet entry whose tpl no longer exists throws a TypeError inside derive(), which is called by the map screen, the shipyard, battle setup and the post-battle hull clamp.
- core.js:136: boons get no unknownId treatment at all: `for(const b of (RUN.boons||[])) if(BOONS[b.id]) l.push(BOONS[b.id].fx(RARITY[b.r||0].m));`. A renamed boon silently stops applying its effect forever, with no log and no telemetry.
- campaign_meta.js:196 renders the end-of-run summary with `esc(ADMIRALS[RUN.admiral].n)` unguarded, while line 201 of the same function guards the identical lookup: `ADMIRALS[RUN.admiral]?ADMIRALS[RUN.admiral].n:'Your admiral'`. The author knew the pattern; it is just not applied consistently.

Failure scenario: saneRun and normalizeRun validate structure only (fleet entries are objects, captain exists), never id membership, so a save carrying a stale id passes every check and the .bak fallback in loadLocal never triggers. This codebase renames content between versions constantly (v53 and v55 markers throughout). The first build that renames or removes a hull or admiral id turns every in-progress campaign containing it into a boot loop: Continue loads, derive() or the summary screen throws, reportError toasts, reload repeats. The only recovery is wiping the save.

### N2. MEDIUM, OBSERVED. The aspect silently stops working when the flagship is lost outside a victory

The aspect is not stored on a ship; derive() applies it by identity match, core.js:165: `const asp=RUN&&RUN.aspect&&ship.uid===RUN.flagUid&&ASPECTS[RUN.aspect]?[ASPECTS[RUN.aspect].fx]:[];`. Anything that removes the flagship without reassigning RUN.flagUid leaves the aspect attached to a ship that no longer exists.

ensureFlagship() is called from rewardFlow (wins only, campaign_run.js:243), newRun, pickAspect and aspectScreen. It is not called on the two other flagship-removal paths:

- finishBattle (campaign3d.js:65) filters dead ships out of RUN.fleet, and the retreat branch at campaign3d.js:89 goes straight out: `if(result==='retreat'){ completeNode(); mapScreen(); toast('The fleet jumps clear.'); return; }`. A flagship lost in a battle the player then retreats from is never replaced.
- Selling at the shipyard, campaign_run.js:181: `RUN.fleet.splice(i,1); closeModal(); shipyardScreen(yardNode);` with no flagUid handling and no warning that the ship being sold carries the aspect.

Failure scenario: flagship dies, player retreats (or sells the flagship between nodes). Every subsequent battle runs with no ship matching flagUid, so the aspect contributes nothing, in battle and in derive-based screens, until the next victory's rewardFlow happens to repair it. flagshipOf() returning null does re-offer the set-flagship button on the map, but nothing tells the player the aspect went inert, and a player who does not re-flag plays the rest of the sector unknowingly weakened.

### N3. MEDIUM, OBSERVED. Settings are never cloud-stamped, so a second device silently reverts them

Persist.save (core.js:121) is the only path that stamps and pushes: `save(opt){ const now=Date.now(); META.updated=now; if(!(opt&&opt.meta)) META.runAt=now; this.saveLocal(); this.push(); }`. Every settings write bypasses it and calls Persist.saveLocal() only: saveOpts (ui3d.js:523), ACT.fxmode and ACT.shakemode, SFX.setVol in sfx.js, the tip toggles, and the profiler toggle in perf3d.js. connect() then resolves meta wholesale on the updated stamp (takeMeta, core.js:103).

Failure scenario: play on the phone, which stamps and pushes its meta. Change quality, volume, camera or the accessibility toggles (fxReduced, shakeRed) on the desktop; those changes exist only in desktop localStorage. Play one battle back on the phone and its next stamped save pushes the phone's older opts. The desktop's next boot takes the cloud meta and every desktop setting quietly reverts. On a single device this can never fire, because equal stamps never overwrite, which is exactly why it hides. The split-axis stamp design in connect() is genuinely good for runs and purchases; settings just never got a stamp of their own.

### N4. MEDIUM, OBSERVED. reportError spends its whole budget on the first five errors of a session

campaign3d.js:5: `let ERRS=0; function reportError(msg,stack){ if(++ERRS>5) return;`. The counter is global, never resets, and is shared by window error events, unhandled rejections, and scene3d.js frameError, which funnels render-loop exceptions into reportError throttled to one per ten seconds. Fifty seconds of frame hitches on a weak phone therefore exhausts the entire session budget. After that, a genuinely campaign-breaking error produces no telemetry and no toast, so the player loses the one signal that tells them their campaign is saved at the last node and a reload is safe, at exactly the moment it matters. Minor companion issue: the toast text claims a campaign save even when the error happened in a skirmish or on the title screen, where there may be no campaign at all.

### N5. LOW-MEDIUM, OBSERVED. Death-sequence timers fire into whatever scene replaced the battle

fx3d.js:472 and fx3d.js:473 schedule cosmetic follow-up blasts capturing only a position vector, with no battle identity check. The longest, fx3d.js:473: `if(Math.random()<.45&&!G.fxReduced) setTimeout(()=>{ try{ const q=c.add(new V3((Math.random()-.5)*L*.4,1,(Math.random()-.5)*L*.2));` followed by flash, blast, SFX.boom and juice up to about a second later. The guarding pattern exists in the same file: fx3d.js:110 warms effects with `setTimeout(()=>{ if(B===b0&&!B.over) warmFx(); },50);`. Failure scenario: the reactor death is also the killing blow that ends the battle. endBattleFlow disposes the views and the reward screen (or the title showcase) comes up inside the timer window, and then a stray fireball, flash and boom land on the new screen at stale coordinates. No state corrupts, since these effects are cosmetic, but it reads as a bug on the victory screen, and the calls run against a scene mid-teardown.

### N6. LOW, OBSERVED. Settings round-trip residue: one dead key, one overwritten key, one coercion

The full key audit (saveOpts at ui3d.js:523 against the boot restore at main3d.js:11) mostly passes: quality, ai, alt, fast, follow, taa, aiHulls, fxReduced, shakeRed and sfxOn round-trip, and sfxVol, lastFac, tips and prof survive because saveOpts merges into META.opts with Object.assign rather than replacing it. Three defects remain:

- saveOpts writes a key nothing reads: `cineMode:G.cine?(G.cineMode||'key'):'off',cine2:G.cine, follow:G.follow,`. A repo-wide search for cine2 returns exactly one hit, that write. Dead weight in every save, and a trap for anyone who later assumes it is wired to something.
- The boot restore sets G.cine from the saved cine flag, then overwrites it a few tokens later in the same line: `G.cineMode=o.cineMode||'key'; G.cine=G.cineMode!=='off';`. A save carrying cine set to false but no cineMode key (any save written before cineMode existed) boots with cinematic camera on, against the player's saved choice.
- setQuality (scene3d.js:103) coerces unknown values to High: `G.quality=q; const ultra=q==='ultra', hi=q!=='medium';`. A legacy or corrupted quality value in a save silently becomes the High tier on a phone that may not hold it.

### N7. LOW, OBSERVED. One near-planet shader material leaks per battle, and shield shards share one mutable colour

gfx3d.js:307 builds a fresh material on every call and drops the previous reference: `m.setFloat('freq',3.2); G.nearMats=[m]; return m;`. Battles share a single scene, and nothing in gfxTick (gfx3d.js:403) or in teardown disposes the replaced material, so a long session accumulates one dead ShaderMaterial (with its compiled program) per battle fought near a planet. Separately, shieldShatter writes the faction colour into the single shared shard material, gfx3d.js:413: `if(col&&G.shardBase.material&&G.shardBase.material.emissiveColor) G.shardBase.material.emissiveColor=col.scale(1.8);`. Two shatters in flight at once, from ships of different factions, both render in whichever colour was written last. Cosmetic, but it misattributes whose shield just broke.

### N8. LOW, INFERRED. The glow exclusion cache in perf3d.js can go stale because the prune mutates in place

glowFastHasMesh (perf3d.js:85) memoizes the exclusion list as a Set keyed on identity plus length: `if(ex!==arr||ex.length!==len){ arr=ex; len=ex.length; set=new Set(ex); }`. prunePassLists (perf3d.js:90) prunes that same list in place: `const keep=L._excludedMeshes.filter(id=>ids.has(id)); L._excludedMeshes.length=0; L._excludedMeshes.push(...keep);`. Reasoning: the array identity never changes, so the cache only rebuilds when the length changes. A prune that removes dead ids followed by new exclusions landing back on the same length (plausible across battles, which exclude a similar count of meshes each time) leaves the Set holding disposed meshes' ids and missing current ones. The visible outcome is a mesh glowing that should be excluded, or the reverse. Visual only, and it needs the same-length coincidence, hence INFERRED.

### N9. LOW, OBSERVED. Telemetry merge dedups on timestamp plus event name, ignoring the payload

mergeLocalTel (campaign3d.js:18) decides what the local TEL_KEY copy adds back into META.tel with `const seen=new Set((META.tel||[]).map(e=>e.t+'|'+e.ev));`. Two distinct events that share an event name within the same millisecond collapse into one; the second is dropped from the merged history. Telemetry events carry their distinguishing data in the payload (ids, kinds), which the key ignores. Impact is limited to telemetry completeness, which in turn feeds the profiler summary and any future backfill, but the merge is the one place tel entries are supposed to be recovered, and it can silently lose the entries it exists to save.

## Seams checked and cleared

- migrateMeta backfill math vs live grants: no double counting. The backfill in core.js uses the same coefficients as the live path (runRenown in campaign3d.js and endRun in campaign_meta.js: battles times 2, elites times 4, bosses times 15, floor(kills/4), (sector minus 1) times 5; mastery battles plus elites times 2 plus bosses times 5 plus 10 on victory). It is guarded one-time by m.backfilled, and the renown credit is capped at 60. The one skew: if a save's tel array was already trimmed at the 600 cap, history is undercounted, never overcredited.
- sfx.js: read in full. Voice caps steal the oldest voice with a fade, per-cue gaps stagger repeats, setOn(false) rechecks G.sfxOn before suspending, and _slice discards NaN-peak variants. No standalone defect found beyond the saveLocal seam reported as N3.
- meshopt3d.js: vendored meshoptimizer 1.3, upstream code. Its decode helper writes into the target buffer before checking the result code, but the only game call path awaits MeshoptDecoder.ready and checks typeof first (ships3d.js:801), so there is no reachable integration bug to report here.
- tbot3.js: test harness only. altRound re-reads the global battle state every iteration and caps at 40 loops, so a hung battle returns a stuck verdict instead of looping forever. No production impact.
- Timer inventory: the stall watchdog interval in ui3d.js, the PERF and DIAG intervals, and the command-arm interval all either self-clear on expiry or are session-scoped by design. The battle-scoped timeouts in fx3d.js and campaign3d.js mostly check disposal or battle identity; N5 is the exception.
- Reserve captains and skirmish setup: the newShip reserve override in campaign3d.js is guarded on RUN.reserve existing, so the skirmish dummy run cannot consume real captains, and finishBattle's lifepod roll and reserve push are consistent. The flagship interaction is the hole, reported as N2.

## Not checked

- fxShPool entry lifecycle in vfx3d.js when a scene teardown lands while a pooled fireball or warp rift observer is still pending; the pool release path was not traced end to end.
- Live two-device Firestore behaviour. N3 is established from the stamp logic in code; no second account was used to reproduce the revert against the real backend.
- Whether Babylon disposes scene materials on the quality-change pipeline rebuild, which would shrink the N7 leak; the grep evidence shows no game-side dispose, and engine behaviour was not tested live.
- AUDIT_v53H.md sections past 5b in full; the file was read to its cap for deduplication, and none of the findings above overlap its headline list.
- The nested whenHullsReady path (skirmish wrapper wrapping battleScreen's wrapper). A skip or timeout on the hull wait may stack a second wait overlay when the inner call re-enters; not traced to a wrong end state, so not reported as a finding.
- Balance or feel consequences of any finding, and audio quality of the synthesized cues. This lens was code correctness only.

## Recommended next step

Fix N1 before the next content rename: route hull tpl, boon and admiral lookups through unknownId (deriving a dead ship to a safe skip, and dropping a dead boon with a log), and add an id-membership sweep to saneRun so a save containing a removed id falls back to its .bak instead of crash-looping. It is the only finding here that can permanently cost a player their campaign.
