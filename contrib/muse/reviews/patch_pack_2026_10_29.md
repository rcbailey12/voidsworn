# Wave 5 patch pack: six verified defects, patch-shaped diffs (Oct 29, 2026)

Chair-produced for Opus to verify and apply. Every diff is written against the browser code at main 264f441d (the working clone files are byte-identical to that pin for all six files, checked with git diff). Each diff was test-applied to a scratch copy of the pinned file and the result syntax-checked with node --check before this pack was filed. Browser code is under the freeze rule (break fixes only), so treat these as exact implementation specs for the Godot port where a browser fix is not wanted; the section notes say which is which. Five sections carry a diff. Section 6 carries no diff, for a verified reason stated in its section.

## 1. Veteran brace bypass (battle.js:1385-1387)

Defect: when a veteran enemy unit's best plan involves movement, its volley fires mid-move through the onLate callback and the activation returns at line 1387, so the veteran pre-fire brace decision at line 1396 never runs on that path; once the volley has fired, canOrder('brace') is closed anyway (battle.js:1036 requires no weapon fired), so the decision is not merely late, it is lost. NOMIDFIRE, the env flag that disables the mid-move path, is set nowhere in the repo (only read at battle.js:1385, plus its copies in the built page and the two Godot oracle mirrors).

```diff
--- a/battle.js
+++ b/battle.js
@@ -1383,6 +1383,8 @@ async function aiUnit(u){
     }
     let volleyP=null;
     if(best && best.path.length){ const midFire=!u.isSq&&!runner&&!(u.ab==='nova'&&canAbility(u))&&!(typeof animPath==='function'&&typeof process!=='undefined'&&process.env&&process.env.NOMIDFIRE);
+      // the veteran brace decision (the aiVet check after the volley below) must run on this path too: once the onLate volley has fired, canOrder('brace') is closed, so a decision made after moveUnit returns is a decision never made. On a brace call the unit still moves, it just does not fire.
+      if(midFire&&aiVet()&&!u.t.boss&&canOrder(u,'brace')){ const pf=alive('player'), myOff=evalOffense(u,u.weapons.filter(weaponReady),pf), thr=evalThreat(u,pf); if(thr>u.hp*.45&&myOff<thr*.35&&u.hp<u.maxHp*.7){ await moveUnit(u,best,undefined); if(!live()) return; giveOrder(u,'brace'); B.aiActive=null; u.activated=true; return; } }
       await moveUnit(u,best,midFire?{onLate:()=>{ if(boardTargets(u).length) return; volleyP=(async()=>{ if(!await aiAbilities(u,live,'aim')||u.dead) return null; return aiVolley(u,live); })(); return volleyP; }}:undefined); if(!live()) return; }
     if(volleyP){ const fired=await volleyP; if(!live()||B.over) return; if(!await aiAfterFire(u,live,runner)) return; if(!fired && !u.dead && u.hp<u.maxHp*.5 && canOrder(u,'brace') && evalThreat(u,alive('player'))>10){ giveOrder(u,'brace'); } B.aiActive=null; u.activated=true; return; }
     // nova
```

Rationale: the inserted check copies the line 1396 decision verbatim (same thresholds, same exclusions) and runs it at the only point on the mid-move path where bracing is still legal, before any weapon fires.
Risk: threat and offense are evaluated from the pre-move position, where the sibling path at line 1396 evaluates after movement on its own path; a veteran at the margin could therefore brace in a case where the post-move numbers would have said fire. The thresholds are wide (threat above 45% of hull, offense below 35% of threat), so marginal flips should be rare.
Acceptance check: in a headless battle (the wave 1 harness or sim3d), field a veteran non-boss enemy below 70% hull whose expected incoming threat exceeds 45% of its hull and whose offense is weak, with a best plan that moves it; assert it ends the activation braced and never fired, where the unpatched code fires a volley.

## 2. Hive wings invisible to the enemy point-defense adaptation (battle.js:326)

Defect: the carrier count that gates the enemy point-defense adaptation reads template hangars only (HULLS[sh.tpl].hangar), while the game's own derived hangar total (core.js:214, inside derive() at core.js:204) folds in fx.hive, so a fleet whose wings come solely from the hive aspect or hive boons counts as carrier-free and the adaptation never arms against it.

```diff
--- a/battle.js
+++ b/battle.js
@@ -323,7 +323,7 @@ function startBattle(cfg){
   eList.forEach((e,ei)=>B.units.push(makeUnit('enemy', e.tpl, {scale:sc*(HULLS[e.tpl].boss?BOSS_SCALE[s]*bossFit*(BOSS_FAC[cfg.fac]||1)*(heatOn('h_flag')?1.2:1):thin), dmg:dm*(HULLS[e.tpl].boss?BOSS_DMG[s]:thin), elite:!!(eliteIdx&&eliteIdx.has(ei))||cfg.kind==='boss'&&!HULLS[e.tpl].boss&&rnd()<.3||heatOn('h_elite')&&ei===(HULLS[eList[0].tpl].boss&&eList.length>1?1:0)||cfg.mod==='veteran'&&ei===eList.map((x,i)=>[i,HULLS[x.tpl].cp||1]).sort((x,y)=>y[1]-x[1])[0][0], fac:cfg.fac})));
   if(heatOn('h_undying')) for(const u of B.units) if(u.side==='enemy'&&!u.isSq&&!u.t.boss) u.reanimate=true;
   // enemies adapt to carrier-heavy fleets: escorts bolt on point defense
-  { const nCar0=RUN.fleet.filter(sh=>sh.hp>0&&HULLS[sh.tpl]&&HULLS[sh.tpl].hangar).length, carDoc=(ADMIRALS[RUN.admiral]&&ADMIRALS[RUN.admiral].cmd&&ADMIRALS[RUN.admiral].cmd.id==='scramble')||RUN.aspect==='hive';
+  { const nCar0=RUN.fleet.filter(sh=>sh.hp>0&&HULLS[sh.tpl]&&derive(sh).hangar>0).length, carDoc=(ADMIRALS[RUN.admiral]&&ADMIRALS[RUN.admiral].cmd&&ADMIRALS[RUN.admiral].cmd.id==='scramble')||RUN.aspect==='hive';
     const nCar=nCar0+(carDoc&&nCar0>=1?1:0); /* a carrier admiral or a hive flagship counts as a second carrier: one hull with doctrine still draws a response */
     if(nCar>=2&&(!cfg.enemies||process_env('ADAPT')==='1')&&process_env('NOADAPT')!=='1'){ const pd=cfg.fac==='chorus'?'spores':'flak', cand=B.units.filter(u=>u.side==='enemy'&&!u.t.boss&&!u.isSq&&!u.weapons.some(w=>w.k==='flak')).sort((x,y)=>(y.t.cp||1)-(x.t.cp||1));
       const n=Math.min(cand.length,nCar>=3?cand.length:Math.ceil(cand.length/2)); for(const u of cand.slice(0,n)){ u.weapons.push(Object.assign(nameWeapons(u.fac,[mkWeapon(pd,'T',u.fx||{})])[0],{fired:false,cdLeft:0,off:0})); u.pdRefit=true; } // B-21 (Oct 26): the refit gun gets the per-battle fields every other gun has, so it fires and intercepts wings
```

Rationale: derive() is the same source of truth makeUnit builds the player's units from, so the adaptation now counts exactly the hulls that will actually launch wings, hive-derived and module-derived hangars included.
Risk: derive() runs once per living fleet ship at battle setup; it is the same call unit creation makes moments later, so the cost is negligible. One behavior note: a hull whose only hangar comes from the fitted hangar module now also counts, which is consistent (it does launch wings).
Acceptance check: start a battle with a fleet of two or more non-carrier hulls carrying the hive aspect (fx.hive) and no template hangar; assert B.adapt is set and enemy escorts receive the point-defense refit, where the unpatched code sets neither.

## 3. Module kind-fit guard (campaign_run.js:128)

Defect: the fleet screen's fit filter checks only the ability gate (MODULES[m].only against the hull's ability), so the kind-keyed refits in MOD_NEED (data.js:259: loaders needs batteries, crystal needs a lance, magazine needs torpedoes, flakplus needs flak, capacitor and regen need shields) can be fitted to hulls with no weapon of that kind, or no shields, and silently do nothing; the equip handler (campaign_run.js:140) performs no check of its own and trusts this filter, so line 128 is the only enforcement point.

```diff
--- a/campaign_run.js
+++ b/campaign_run.js
@@ -124,8 +124,10 @@ function shipCard(s, opts={}){
     <div class="sect"><h4>Refits</h4>${slots.join('')}</div>
     ${opts.extra||''}</div>`;
 }
+// kind-keyed refits (MOD_NEED, data.js) do nothing on a hull with no weapon of that kind, or no shields: never offer the fit (ACT.equip trusts this filter and checks nothing itself)
+function modFitsKind(m,s){ const need=(typeof MOD_NEED!=='undefined')?MOD_NEED[m]:null; if(!need||need==='carrier') return true; if(need==='shields') return (HULLS[s.tpl].sh||0)>0; const kind=need==='batt'?'battery':need; return (HULLS[s.tpl].w||[]).some(pair=>W[pair[0]]&&W[pair[0]].k===kind); }
 function fleetScreen(back){
-  const inv=RUN.inventory.map((m,i)=>{ const opts=RUN.fleet.filter(s=>s.mods.length<HULLS[s.tpl].slots && (!MODULES[m].only||HULLS[s.tpl].ab===MODULES[m].only));
+  const inv=RUN.inventory.map((m,i)=>{ const opts=RUN.fleet.filter(s=>s.mods.length<HULLS[s.tpl].slots && (!MODULES[m].only||HULLS[s.tpl].ab===MODULES[m].only) && modFitsKind(m,s));
     return `<div class="card"><h3>${esc(modName(m))}</h3><p>${esc(MODULES[m].d)}</p><div class="foot row wrap">${opts.length?opts.map(s=>`<button class="small" data-act="equip" data-arg="${i}:${s.uid}">Fit to ${esc(s.name)}</button>`).join(''):'<span class="dim">No free compatible slot. Remove a refit first.</span>'}</div></div>`; }).join('');
   show(`<div class="screen"><div class="page">
     <div class="row"><h2 class="gothic">Fleet</h2><span class="spacer"></span><button class="primary" data-act="${back==='shipyard'?'backShipyard':'backMap'}">Done</button></div>
```

Rationale: the check reuses the game's existing MOD_NEED table (the same one core.js:234 uses to filter the shop module pool by fleet kit) and the kind vocabulary fleetKit uses (core.js:179, where weapon kind 'battery' maps to the MOD_NEED key 'batt'); the hangar module is exempted here because its ability gate (only:'launch') already covers it.
Risk: a hull whose weapons come only from a refit track or variant merge could be misjudged if HULLS[s.tpl].w is not the final weapon list; at the pin, variants are merged into HULLS before this screen runs, so the template list is the fitted list. The guard only removes fit options the module could never affect, so a false negative costs a legitimate fit, which is why the acceptance check includes one.
Acceptance check: put a Lance focusing crystal in the hold with a fleet whose only lance is on one hull; assert the fleet screen offers the crystal for that hull only, and offers a Screen capacitor for no hull in a shieldless fleet.

## 4. Elite guarantee fails on an all-rest column 4 (core.js:268)

Defect: the pre-boss elite guarantee looks for a battle or event node in column 4 to convert and silently does nothing when the column rolled only rest nodes (shipyard, drydock), so about 1.9% of generated sector maps break the guarantee the code comment states (measured by the wave 3 sweep: 84 of 4,500 maps, all this one kind, mechanism instrumented on seed 151 sector 1).

```diff
--- a/core.js
+++ b/core.js
@@ -265,7 +265,7 @@ function genSector(s){
     cols.push(col);
   }
   // the column before the rest stop always offers an elite: a step up before the flagship, for those who want it
-  { const c4=cols[COLS-3]; if(!c4.some(n=>n.type==='elite')){ const b=c4.find(n=>n.type==='battle')||c4.find(n=>n.type==='event'); if(b) b.type='elite'; } }
+  { const c4=cols[COLS-3]; if(!c4.some(n=>n.type==='elite')){ const b=c4.find(n=>n.type==='battle')||c4.find(n=>n.type==='event')||c4.find(n=>n.type==='shipyard'||n.type==='drydock'); if(b) b.type='elite'; } }
   // guarantee a shipyard in the middle and a rest stop before the boss
   if(!cols[3].some(n=>n.type==='shipyard')) pick(cols[3]).type='shipyard';
   if(!cols[COLS-2].some(n=>n.type==='drydock'||n.type==='shipyard')) cols[COLS-2][0].type='drydock';
```

Rationale: battle and event conversions are still preferred; a rest node is converted only when the column has nothing convertible, which is exactly the failing case, and the pre-boss rest column (COLS-2) is a different column and keeps its own guarantee.
Risk: in the failing case the column can lose its only shipyard; the column still offers a fight and the following column is always a rest stop, so no route loses rest access entirely. The budgets loop that runs after this block does not convert elite nodes back, and the later field conversion only targets battle or event nodes, so the new elite survives generation (both verified by reading the rest of genSector).
Acceptance check: rerun the sector map sweep (softlock_sweep.js, seeds 1 to 1500 across sectors 1 to 3) and assert zero "column 4 offers no elite" failures, down from 84, with boss reachability still 4,500 of 4,500.

## 5. Mobile layer can claim a real desktop (scene3d.js:4)

Defect: G.mobile is set from a coarse-pointer media query plus the smaller window dimension under 900px, so a desktop with a touchscreen (coarse pointer) and a resized or small window is classified as a phone at boot, after which main3d.js:11 forces medium quality and resets fxReduced to false, and the render loop frame-skips; under the PC-only ruling this branch's only remaining function is misclassifying desktops.

```diff
--- a/scene3d.js
+++ b/scene3d.js
@@ -1,7 +1,7 @@
 // ======================= 3D SCENE =======================
 const V3=BABYLON.Vector3, C3=BABYLON.Color3, C4=BABYLON.Color4, MB=BABYLON.MeshBuilder;
 const HS=10, HW=HS*Math.sqrt(3);
-const G={mobile:!!(window.matchMedia&&matchMedia('(pointer: coarse)').matches&&Math.min(innerWidth,innerHeight)<900),lastInput:0,fxReduced:!!(window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches),engine:null,scene:null,cam:null,glow:null,pipe:null,views:new Map(),env:[],ox:-HW*((BW-1)/2+.25),oz:1.5*HS*(BH-1)/2,bx:HW*BW/2+30,bz:1.5*HS*BH/2+30,home:new V3(-90,0,-10),quality:'ultra',
+const G={mobile:!!(window.matchMedia&&matchMedia('(pointer: coarse)').matches&&Math.min(screen.width,screen.height)<900),lastInput:0,fxReduced:!!(window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches),engine:null,scene:null,cam:null,glow:null,pipe:null,views:new Map(),env:[],ox:-HW*((BW-1)/2+.25),oz:1.5*HS*(BH-1)/2,bx:HW*BW/2+30,bz:1.5*HS*BH/2+30,home:new V3(-90,0,-10),quality:'ultra',
   
   ctl:null,time:0,shake:0,tex:{},overlay:{},sfxOn:true,cine:false,follow:false,fast:false};
 function hexWorld(q,r,y=0){ return new V3(HW*(q+r/2)+G.ox, y, -1.5*HS*r+G.oz); }
```

Rationale: the failing ingredient is the window size, which a desktop user controls by resizing; the physical screen's smaller dimension is not changed by resizing, so a desktop can no longer talk itself into the phone profile, while a real phone (small screen, coarse pointer) still can. main3d.js needs no change: once detection stops claiming desktops, its forced medium quality and fxReduced reset stop firing on PCs.
Risk: on a multi-monitor setup screen reports the primary display, and a desktop-mode tablet or a small-screen touch laptop can still classify as mobile; both are acceptable under the PC-only ruling, and the settings screen still lets the player override quality. Alternative for Opus, one line: hard-set mobile:false in this literal and delete the G.mobile branches later, since the phone target is ruled out entirely; the diff above is the minimal version that keeps the layer working for genuine small-screen devices.
Acceptance check: load the game in a desktop browser with a touchscreen (or emulate a coarse pointer) and the window sized under 900px on its smaller side; assert G.mobile is false at boot, quality stays at the saved or ultra default, and fxReduced keeps its saved value.

## 6. Eclipse carrier preview naming: NO DIFF, defect does not reproduce at the pin

Defect as commissioned: effArch (battle.js:138) remaps a carrier archetype roll to heavy for factions with no launch hull, but the node preview was said to still name the carrier archetype, advising fighters and flak against wings that do not exist (fights synthesis item 6, which named the Deathless preview "Repair host").

What verification found instead: at the pin, both preview surfaces already use the effective archetype. archLabel (campaign_run.js:17) looks up ARCHETYPES[effArch(n.arch,fac)], and it feeds both the map node tooltip (campaign_run.js:40) and the encounter preview panel (campaign_run.js:55); the panel's advice line also reads ARCHETYPES[effArch(n.arch, fac)].d directly. A runtime check through the wave 1 harness confirms effArch('carrier','deathless') returns 'heavy', and the deathless roster carries no launch hull (d_scythe and d_jackal are 'phase', d_harvester is 'reclaim', FACTIONS.deathless.sq is null), so a Deathless carrier roll previews as "Phalanx" with the heavy advice text ("Few, big hulls. Bring lances, torpedoes and a flank."). The fights synthesis itself listed the shipped UI's preview text beyond its pack slices under Not checked; the pack showed the raw archetype table, and the mismatch lives in the pack, not in the shipped preview code.

Accordingly there is no diff in this section: producing one would patch code that already does what the fix requires. If Opus wants the belt-and-braces version anyway, the one remaining soft spot is that the guarantee rests on every future preview surface remembering to call effArch; a comment at the archetype roll (core.js:291) saying previews and generation both consume effArch would pin it, but that is documentation, not a fix.

Acceptance check (one read): generate a sector map against a Deathless sector foe until a battle or elite node rolls the carrier archetype, and confirm the tooltip and preview panel show the heavy name and heavy advice; on the pinned code they do.

## Provenance and limits

- All line numbers are against the pinned files as read in the working clone on Oct 29, 2026; the clone's six files are byte-identical to main 264f441d.
- Diffs 1 to 5 were each applied with git apply to a scratch copy of the pinned file and the patched file passed node --check. Diff application proves the context text is exact; it does not prove runtime behavior, which is what the acceptance checks are for.
- Nothing in this pack edits the clone, the built page (voidsworn-3d.html), or the Godot oracle copies. If a fix is applied to the browser sources, the built page and the oracle copies at godot/rules/test/oracle/ and godot/campaign/test/oracle/ need their normal regeneration, which is Opus's process.
