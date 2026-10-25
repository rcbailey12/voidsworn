# A1: bug verification at HEAD d5d0227

Read-only. Game code last changed Oct 21 (777dc1d), so every review below was written against the code that is live now; a review being wrong means it misread, not that the code moved. Node proofs: scratchpad/a1/probe.js (evals data.js, core.js, battle.js like sim3d.js). Run: `node probe.js /home/claude/rcbailey12/voidsworn`.

Status key: PRESENT (defect in code now), FIXED (claim no longer holds), LATENT (code fact true, not reachable as described), UNCLEAR.

| # | Item | Where described | Status | file:line | Quote (exact) | Note |
|---|---|---|---|---|---|---|
| 1a | Renamed hull crashes fleetCP | deepseek/reviews/qa.md #1; council_reconciliation.md consensus 1; packFGHI_screening.md (Pack F) | PRESENT (node-proved) | core.js:180 | `RUN.fleet.reduce((a,s)=>a+HULLS[s.tpl].cp,0)` | probe: saneRun accepts tpl 'warden_renamed'; fleetCP throws "reading 'cp'" |
| 1b | Renamed hull crashes derive | council/qa.md N1; council_audit.md C5 N1 | PRESENT (node-proved) | core.js:164, 168 | `const t=HULLS[ship.tpl];` | derive throws "reading 'hp'". saneRun (core.js:70) checks only fleet array and map.cols |
| 1c | Unknown relic id crashes map screen | deepseek/reviews/qa.md #4 | PRESENT (node-proved pattern) | campaign_run.js:46 | `esc(RELICS[r].d)` | normalizeRun keeps unknown relic ids; unknownId (core.js:73) only covers derive-time effects |
| 1d | Captain with no name crashes ship creation | deepseek/reviews/qa.md #5 | PRESENT (node-proved) | core.js:126 | `s.cap&&s.cap.name.split(' ')[0]` | normalizeRun (core.js:66) builds cap only when absent; cap:{} passes, newShip throws "reading 'split'" |
| 1e | Stale admiral id crashes run summary | council/qa.md N1 | PRESENT (node-proved pattern) | campaign_meta.js:196 | `esc(ADMIRALS[RUN.admiral].n)` | normalizeRun keeps 'adm_renamed' (defaults only when null) |
| 1f | v1 meta migration never initializes m.stats | qwen/council_audit.txt QA 3 | MOSTLY FIXED; null variant PRESENT | core.js:83, 103, 69 | `META=migrateMeta(Object.assign(defaultMeta(),o.meta))` | Missing key is filled by defaultMeta (probe: stats {runs,best,wins}). But saneMeta allows `stats:null`, Object.assign copies null, campaign_meta.js:38 `META.stats.best` throws (probe) |
| 2 | Alternating guard bypass, direct fire | qwen/council_audit.txt QA 1; council_reconciliation.md; packFGHI_screening_round2.md (downgraded) | LATENT | ui3d.js:410 (guard at 382-383) | `if(s&&s.side==='player'&&canUse(s)){ const set=firingSet(s,u); if(set.length){ guard(s);` | Return is discarded, but canUse(s) is checked one level up and guard returns exactly canUse for player ships. Not exploitable now; make it `if(guard(s))` for safety |
| 3 | Blink commits position before animation | qwen/council_audit.txt QA 4; council_reconciliation.md | PRESENT | battle.js:944 | `u.q=h.q; u.r=h.r; u.vis=null;` | On stall `if(!live()) return false;` skips the cooldown (set only at battle.js:966) and objAfterMove: free, repeatable teleport. Needs a 20s stall to trigger |
| 4 | Watchdog clears busy, leaves activeUnit | qwen/council_audit.txt QA 5; council_reconciliation.md | LATENT (code fact true, softlock claim does not hold) | ui3d.js:667-668 | `B.epoch=(B.epoch||0)+1; B.busy=false; const side0=B.side;` | activeUnit untouched, but canUse (ui3d.js:8) still allows the active ship, and act() tail (ui3d.js:391) calls endActivation when it is dead or done. Player keeps the stalled ship, which is the normal alternating rule |
| 5 | Captured boss joins fleet, NaN sell, CP past cap | deepseek/reviews/qa.md #3; council_reconciliation.md; packDE_screening.md | PRESENT (data node-proved; capture reachability inferred) | campaign3d.js:81; campaign_run.js:180-181; battle.js:652-653 | `const sh=newShip(u.tpl); sh.name=u.name;` | No boss or CP check on the prize push. Probe: all 5 boss hulls have cost=undefined, slots=undefined, cp 10-12 (cap starts 10), sell=NaN. sellConfirm `RUN.credits+=Math.round(HULLS[s.tpl].cost*.35)` makes credits NaN for the run. boardTargets has no boss exclusion. Also contradicts the Oct 24 fleet-cap capture ruling |
| 6a | Zero-fleet win recorded as loss | deepseek/reviews/qa.md #6 | PRESENT | battle.js:771; campaign3d.js:88 | `if(caps('enemy').length===0){ B.over='win'; return; }` | Enemy wipe is checked before player wipe; then `if(result==='loss' \|\| RUN.fleet.length===0){ endRun(false)` |
| 6b | Towing salvage ignores CP cap | deepseek/reviews/qa.md #7 | PRESENT | campaign_run.js:272 | `const sh=newShip(w.tpl); sh.name=w.name;` ... `RUN.fleet.push(sh);` | No fleetCP check, unlike buyHull (campaign_run.js:174) and the merc event (215). Tow also consumes a reserve captain (see 6d) |
| 6c | Nova cooldown spent by abandoned cast | deepseek/reviews/qa.md #8 | PRESENT | battle.js:953, 955 | `const c=arg.hex; u.abCd=abilityCd(u);` | Cooldown set before `await animNova`; stall returns false with no blast |
| 6d | Reserve captain overrides event mercenary | deepseek/reviews/qa.md #10 | PRESENT | campaign3d.js:99; campaign_run.js:215 | `const r=RUN.reserve.shift(); sh.cap=r.cap;` | Patch fires for any newShip while !B, so the hired veteran is replaced. Also sh.hp is not re-derived for the new captain's perks |
| 7 | LEGACY upgrades unreachable | deepseek/reviews/qa.md #9; packDE_screening.md; council_reconciliation.md pairs | PRESENT as dead UI; "unreachable" is wrong | campaign_meta.js:113, 136; main3d.js:11 | `if(o.unlockAll!==false){ for(const k in LEGACY) META.unlocked[k]=true;` | No render site for buyLegacy or buyAdmiral, but every boot grants all LEGACY and all admirals unless opts.unlockAll===false, and Settings has no 'unlock' row (campaign3d.js:102). So the upgrades are always on and free. PROGRESS.md:54 "everything unlocked by default" |
| 8a | Retreat modal keyboard hole and stale "Jump out" | independent_audit.md Part 1 #1; council/qa.md prior #5; OPUS_HANDOFF.md:41 | PRESENT | ui3d.js:483-485; campaign3d.js:95 | `ACT.c3retreatYes=()=>{ closeModal(); if(B&&B.campaign) finishBattle('retreat'); };` | onKey has no modal check; c3retreatYes does not check B.over/B.busy; endBattleFlow never closes the modal. finishBattle now latches B.finished at entry (campaign3d.js:66), which stops a double finish but not win-to-retreat |
| 8b | Reload bug 1: mid-battle reload eats the node | independent_audit.md Part 1 #2 | FIXED / not reproducible by code reading | campaign_run.js:73; campaign_meta.js:42; core.js:296 | `const n=findNode(id); RUN.pos=id; RUN.curNode=id;` | enterNode changes RUN only in memory; nothing calls saveRun during battle (pagehide, error, watchdog all use saveLocal of the old snapshot). continueRun restores the pre-node save, and the node seed replays. Matches PROGRESS.md:471. Not run in a browser |
| 8c | Reload bug 2: reload during reward chain banks part of the reward, node never completes | independent_audit.md Part 1 #2 | PRESENT | campaign_run.js:274, 309 | `window._wrecks=[]; saveRun&&saveRun(); closeModal(); ACT.rewardNext();` | Salvage pick saves with RUN.pos on the node, credits and salvage banked, done=false; completeNode only runs in afterBattle (309). Reload then skips the boon/refit/relic. Event fights are also unseeded (campaign3d.js:50 `!cfg.eventRelic`) |
| 9 | Crit effects vs ruling | OPUS_HANDOFF.md:22 | Ruling partly WRONG about the code | battle.js:554-565, 362-368 | `t.st.engine=Math.min(t.speed-1,t.st.engine+1)` | See section 9 below |
| 10 | Chair's top 10 | council_audit.md:69-80 | 0 of 10 done in code | various | see section 10 | |

## 9. Critical hits, exact (systemDamage, battle.js:554)

Roll: pick of engine, shields, weapon, fire (shields becomes fire if no shields; weapon becomes fire if no weapons). Called shots map sections (prow to weapon, mid to shields, eng to engine).

- Engine: `t.st.engine=Math.min(t.speed-1,t.st.engine+1)` (561). Minus 1 movement per hit, stacking to speed-1. Nothing counts it down: the turn tick uses it (`u.mp=Math.max(1,u.speed-u.st.engine)`, 362) and only repairSection('eng') resets it (541). **Permanent for the rest of the battle, and cumulative.** The ruling's "engine slows" (listed as temporary) does not match.
- Shields: `t.st.shieldOff=2` (562). Turn tick (365) decrements it and skips regen while it is above 0, so 2 own turns with no regen. Current shield points are not zeroed and still absorb hits. "Shields off" really means "regen off".
- Weapon: `w.off=2` on a random gun (563); a called prow hit picks the strongest live gun (560). weaponReady needs off===0 (454); tick decrements (363). Hit on the enemy turn: out for 1 own turn; hit on the own turn: rest of it plus the next.
- Fire: `t.st.fire=2` (564). 2 ticks of `st.fireDmg||6`, so 12 hull by default. It overwrites, so it can shorten a longer boon fire (fireLong).
- Bug found here (node-proved): systemDamage does not skip disabled systems. A weapon crit on a gun killed by a destroyed section (off=999) sets it to 2, and a shield crit on a destroyed mid section (shieldOff=999) sets it to 2. A crit can bring back a destroyed weapon or shield generator.
- Permanent destruction does exist, outside crits: damageSection (548-549) sets `w.off=999`, `t.st.shieldOff=999` and engines to speed-1 when a section breaks. It lasts until a Restore repair. If "no permanent system destruction" covers sections too, that also conflicts with the code.
- Sources: hit crits (603, 40% chance per crit unless called or critSys), rams (648, 35%), boarding overrun of a player ship (674, two rolls), failed-capture saboteurs (680).

## 10. Chair's top 10 (council_audit.md:71-80)

1. Save-brick id class: NOT DONE. All five mechanisms PRESENT (rows 1a to 1e); m.stats only has the null case left.
2. Review-debt sweep: NOT DONE. Intercept escape win PRESENT (battle.js:722, 778); endActivation latch PRESENT (ui3d.js:549 `(B.busy&&manual)`); retreat hole PRESENT (8a); navLights PRESENT (vfx3d.js:147 `computeWorldMatrix(true)`); end card PRESENT (head.html:115 `min-width:420px`). No verified-open list in HANDOFF.md.
3. Difficulty: NOT DONE. Heat still gated on a win (campaign_meta.js:86 `if((META.stats.wins||0)>0)`), no difficulty pick in campaign_meta.js, no sim gate in build.py.
4. Dead systems: NOT DONE. Resolve is only gained (battle.js:348) and spent nowhere; ORDERS still holds only brace (data.js:146-148); flak's only label is KIND_NAME "Point defense" (data.js:30), with no note that it cannot fire on ships.
5. Animation downtime and tail batch: NOT DONE. ui3d.js:562 `const batch=pp.length?[aiPickActivation(...)]:pe;` still runs every remaining enemy in one block.
6. Patron paragraph and borrowed terms: NOT DONE in game text. data.js still has wraithbone 3, cogitator 13, auspex 8, astropath 3, turbolaser 4, durasteel 1.
7. Art direction and one colour source: NOT DONE. ships3d.js:3 Voidsworn trim `#9c3a1c` vs data.js:111 `#c8501f`; fx3d.js:2-3 contradiction unchanged. The brief template still exists at docs/skills/create-game-assets/assets/art-direction-brief.md (contents not checked).
8. Seam fixes: NOT DONE. Retreat path (campaign3d.js:89) and sellConfirm (campaign_run.js:181) never call ensureFlagship; saveOpts (ui3d.js:523) still uses `Persist.saveLocal()` only.
9. BACKLOG 4c: NOT DONE. Wrapper patches still in place (4 in campaign3d.js, 6 in perf3d.js with the counted pattern); no hook registry.
10. Onboarding pass: NOT DONE (no game code change since Oct 21).

## Not checked

- Nothing was run in a browser. Rows 3, 4, 6c, 8a and 8b are from reading the code. Node proofs cover 1a-1f, the boss data in 5, and the crit table in 9.
- Boss capture reachability (row 5): crew math reasoned, not simulated.
- The other 80-plus rows of Pack F (packF_save_integrity.md) beyond the five mechanisms listed.
- Row 4 timing between stallGuard (25s) and the watchdog (20s) was reasoned, not timed.
- packG_guards.md table rows beyond ui3d.js:410; council/*.md lenses other than qa.md and gamer.md; contrib/deepseek/council_audit.txt beyond the QA findings.
- Top-10 items 6 and 7 as docs: only the game code was checked, not whether a patron paragraph or art direction page exists in a doc somewhere.
