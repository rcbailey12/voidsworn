// ======================= UI: HUD, overlays, input =======================
document.addEventListener('click',e=>{ const path=e.composedPath(); if(path.some(n=>n.id==='app'||(n.classList&&n.classList.contains('modal')))) return; const el=e.target.closest('[data-act]'); if(!el||el.disabled) return; const fn=ACT[el.dataset.act]; if(fn){ try{ if(G&&G.actLog){ G.actLog.push({t:Math.round(performance.now()/100)/10,act:el.dataset.act}); if(G.actLog.length>12) G.actLog.shift(); } }catch(_){} try{ SFX.click(); }catch(_){} fn(el.dataset.arg,el,e); } }); // a sound failure must never swallow a command
function logHtml(m){ return esc(m).replace(/(\d+) to (\w+) shields/g,'<span class="shv">$1 to $2 shields</span>').replace(/(\d+) hull/g,'<span class="hlv">$1 hull</span>'); }
function log(m,c){ if(!B) return; B.log.push({m,c}); const el=document.getElementById('log'); if(el){ const d=document.createElement('div'); d.className=c||''; d.innerHTML=logHtml(m); el.appendChild(d); while(el.childNodes.length>200) el.firstChild.remove(); el.scrollTop=el.scrollHeight; } }
function pendingP(){ return B?alive('player').filter(u=>!u.isSq&&!u.activated&&u!==B.activeUnit):[]; }
function pendingE(){ return B?alive('enemy').filter(u=>!u.isSq&&!u.activated):[]; }
function canUse(u){ if(!B.alt||u.isSq) return true; if(u.activated) return false; return !B.activeUnit||B.activeUnit===u; }
function isDone(u){ if(u.dead||u.braced) return true; if(B.alt&&!u.isSq&&u.side==='player'&&(u.activated||(B.activeUnit&&B.activeUnit!==u))) return true; return !(u.mp>0) && !u.weapons.some(w=>weaponReady(w)&&alive('enemy').some(t=>canFire(u,w,t))); }

// ---------- skirmish setup ----------
const PLAYABLE=['voidsworn','hegemony','corsair','chorus','ithar','deathless'];
let SETUP={pf:'voidsworn',ef:'hegemony',mode:'sk',alt:true,map:'random',dep:'line',obj:'rout',shape:'random',arena:'random'};
const OBJS=[['rout','Engagement'],['ambush','Ambush'],['defend','Hold the station'],['hunt','Hunt'],['intercept','Intercept'],['break','Breakthrough'],['hold','Relay'],['flagship','Decapitation']];
const SHAPE_OPTS=[['random','Random'],['open','Open void'],['corridor','Corridor'],['lanes','Split lanes'],['ring','Ring'],['dense','Dense field'],['deadstar','Dead star']];
const ARENA_OPTS=[['random','Random'],['strip','Classic strip'],['square','Square (diagonal or crossing)'],['round','Round (any angle, pincers)']];
const MAPS=[['random','Random'],['belt','Asteroid belt'],['station','Derelict station'],['planet','Planet edge'],['storm','Ion storm'],['graveyard','Ship graveyard']], DEPS=[['line','Line'],['flank','Flank'],['ambush','Ambush']];
const SEC_LBL={prow:'Prow',mid:'Midships',eng:'Engines'};
const FNAMES={hegemony:['HNS Dominator','HNS Relentless','HNS Sovereign','HNS Executor','HNS Imperious','HNS Harbinger','HNS Adjudicator','HNS Vigilance','HNS Tyrant','HNS Resolute'],
  corsair:['Rust Maw','Gutter Queen','Red Tithe','Scrapjaw','Ashen Grin','Last Laugh','Cinder Wolf','Bad Omen','Salvage Right','Hollow Crown'],
  chorus:['Hive-node Ashk','Brood Vessel Ul','Shrieker','Mawling','Gorefeather','Sac-mother','Thornback','Tidehunger','Wet Choir','Crawling Hymn'],
  ithar:['Silverthorn','Dawnwhisper','Lament of Stars','Glass Heron','Moonveil','Farsinger','Pale Current','Starfall','Quiet Blade','Evening Tide'],
  deathless:['Eternal Vigil','The Unbroken','Sepulchre','Tomb of Ashes','Grave Sovereign','Ossuary','Never-Ending','Obelisk','Dust Throne','Silent Heir']};
// hand-built fleets: fixed composition per faction, so tuning moves smoothly instead of jumping when a points budget tips over
const FLEET_LISTS={
  voidsworn:{sk:['cathedral','penitent','reliquary','harrow','warden','warden'],fl:['ascendant','cathedral','penitent','harrow','warden']},
  hegemony:{sk:['h_dominion','h_vanguard','h_interdictor','h_picket','h_picket','h_picket','h_picket'],fl:['h_boss','h_vanguard','h_interdictor','h_picket','h_picket']},
  corsair:{sk:['c_hulk','c_marauder','c_marauder','c_reaver','c_reaver','c_raider','c_raider','c_raider','c_raider','c_raider','c_raider'],fl:['c_boss','c_marauder','c_reaver','c_raider','c_raider','c_raider']},
  chorus:{sk:['b_brood','b_razor','b_razor','b_spitter','b_spitter','b_drone','b_drone','b_drone','b_drone'],fl:['b_boss','b_razor','b_spitter','b_drone','b_drone']},
  ithar:{sk:['i_carrier','i_song','i_song','i_blade','i_blade','i_wisp','i_wisp','i_wisp'],fl:['i_boss','i_song','i_blade','i_wisp','i_wisp']},
  deathless:{sk:['d_harvester','d_harvester','d_jackal','d_jackal','d_scythe','d_scythe','d_scythe','d_scythe'],fl:['d_boss','d_harvester','d_jackal','d_scythe']},
};
function genFleet(fac,mode){ const L=FLEET_LISTS[fac]||FLEET_LISTS.hegemony; return (mode==='fl'?L.fl:L.sk).slice(); }
function setupBattle(cfg){
  SETUP=Object.assign({},SETUP,cfg||{});
  disposeAllViews(); clearOverlays(); hideEnd();
  RUN={admiral:'vex',credits:0,cpCap:40,sector:SETUP.mode==='fl'?3:1,relics:[],inventory:[],fleet:[],stats:{battles:0,elites:0,bosses:0,kills:0},fallen:[]};
  const names=(FNAMES[SETUP.pf]||[]).slice().sort(()=>Math.random()-.5);
  for(const t of genFleet(SETUP.pf,SETUP.mode).slice(0,SETUP.small?3:99)){ const sh=newShip(t,true); if(names.length) sh.name=names.pop(); RUN.fleet.push(sh); }
  startBattle({kind:SETUP.mode==='fl'?'boss':'battle',fac:SETUP.ef,col:3,enemies:genFleet(SETUP.ef,SETUP.mode).slice(0,SETUP.small?3:99).map(tpl=>({tpl})),map:SETUP.map,dep:SETUP.dep,obj:SETUP.obj,arena:SETUP.arena==='random'?null:SETUP.arena,shape:SETUP.shape==='random'||!SETUP.shape?pick((ENCOUNTERS[SETUP.obj]||ENCOUNTERS.rout).shapes):SETUP.shape});
  { const ps=alive('player').map(x=>hexWorld(x.q,x.r)); const c=ps.reduce((a,p)=>a.add(p),V3.Zero()).scale(1/Math.max(1,ps.length)); G.home=V3.Lerp(c,V3.Zero(),.32); G.home.y=0; }
  prepBattle();
  document.getElementById('scenName').textContent=`${FACTIONS[SETUP.pf].n} vs ${FACTIONS[SETUP.ef].n}, ${(MAPS.find(m=>m[0]===B.map.map)||['',''])[1].toLowerCase()}${SETUP.mode==='fl'?', flagships':''}`;
  B.sel=null; bRefresh();
}
function prepBattle(){
  try{ FRAMES.reset(); }catch(e){}
  B.alt=!!SETUP.alt; // v53: B.seed is the one startBattle seeded the rules with (no overwrite), and the other UI fields start in the startBattle literal
  for(const x of B.units) x.activated=false;
  if(B.alt) startSideTurn('enemy');
  buildBattleEnv(); if(B.obj&&B.obj.type==='hold') buildBeacon(B.obj.hex); G.jumpUntil=G.time+.6; for(const u of B.units) u.arrived=false;
  if(G.mobile) document.body.classList.add('sheetmin');
  const lg=document.getElementById('log'); lg.innerHTML=''; for(const l of B.log){ const d=document.createElement('div'); d.className=l.c||''; d.textContent=l.m; lg.appendChild(d); }
  B.sel=null; bRefresh();
}

// ---------- HUD ----------
function buildHud(){
  const st=document.getElementById('stage');
  st.insertAdjacentHTML('beforeend',`
  <div class="hud" id="btop"><span class="t">Voidsworn</span><span class="muted" id="scenName"></span><span class="num" id="roundlbl"></span><span class="gilt" id="turnlbl"></span><span class="num" id="resolvelbl" title="Admiral\u2019s Command: a fleet-wide signature move, once per battle, growing each round you hold it"></span><span class="spacer"></span>
    <span class="num" id="objlbl"></span><button data-act="threat" id="b_threat2" title="Where the enemy can hit next turn (R)">Threat</button><button data-act="fleetToggle" id="b_fleet">Fleet</button><button data-act="settings" id="b_set" title="Display, camera and sound options"><span class="sl">Settings</span><span class="si">\u2699</span></button><div class="hud setpanel hidden" id="setpanel"><div class="dim" style="font-size:12.5px;margin-bottom:6px">Battle view</div><button data-act="arcs" id="b_arcs" title="Toggle firing arcs (V)"></button><button data-act="threat" id="b_threat" title="Where the enemy can hit next turn (R)"></button><button data-act="cine" id="b_cine" title="Camera swings in on big attacks"></button><button data-act="aihull" id="b_aihull" title="Test hulls made from the concept art (Hegemony dreadnought for now)"></button><button data-act="top" id="b_top" title="Top-down planning view (T)"></button>
    <button data-act="quality" id="b_quality" title="Ultra: supersampling, ambient occlusion, god rays, planet relief. High: shadows, live nebulae, full hull shading. Medium: tuned for phones"></button><button data-act="fxmode" id="b_fx" title="Reduce flashes, strobing lights and camera shake"></button><button data-act="follow" id="b_follow" title="Camera moves to each ship as it activates"></button><button data-act="aiLevel" id="b_ai" title="How cleverly the enemy fights"></button><button data-act="taa" id="b_taa" title="Temporal anti-aliasing: smoother fine detail, may ghost on fast effects (Ultra only)"></button><button data-act="sound" id="b_sound"></button><button data-act="speed" id="b_speed" title="Animation speed (Space)"></button><button data-act="logToggle" id="b_log" title="Show the battle log over the board (phones)">Battle log</button><button data-act="restart" id="b_restart">Restart battle</button><button data-act="reportProblem" title="Save a snapshot of the game state for debugging">Report a problem</button><button data-act="copyReport" title="Copy your recent play data to paste to Claude">Copy report</button><button data-act="diag" title="Render diagnostics (Shift+D)">Diagnostics</button></div><button data-act="c3retreat" id="b_retreat" title="Jump the fleet out. Every surviving ship loses 10% hull.">Retreat</button><button class="primary" data-act="endTurn" id="endbtn">End turn</button></div>
  <div class="hud" id="roster"></div><div class="hud" id="panel"></div><div class="hud" id="log" aria-live="polite"></div>
  <div class="hud" id="camhint"><span><kbd>Right-drag</kbd> orbit</span><span><kbd>Left-drag</kbd> or <kbd>WASD</kbd> pan</span><span><kbd>Wheel</kbd> zoom</span><span><kbd>F</kbd> focus ship</span><span><kbd>T</kbd> top-down</span></div>`);
}
function bRefresh(){ if(!B) return; refreshTop(); refreshRoster(); refreshPanel(); refreshOverlays(); refreshLegend(); tutorialCheck(); }
function refreshTop(){
  if(!B) return;
  const $=id=>document.getElementById(id);
  $('roundlbl').textContent=`Round ${B.round}`; $('turnlbl').textContent=B.over?'':B.side==='player'?'Your turn':'Enemy turn';
  $('b_arcs').textContent=B.showArcs?'Arcs: on':'Arcs: off'; $('b_arcs').classList.toggle('on',B.showArcs);
  { const ab=$('b_aihull'); if(ab){ ab.textContent='Concept-art hulls: '+(G.aiHulls!==false?'on':'off'); ab.classList.toggle('on',G.aiHulls!==false); } }
  $('b_cine').textContent=!G.cine?'Cut-ins: off':G.cineMode==='all'?'Cut-ins: every attack':'Cut-ins: key moments'; $('b_cine').classList.toggle('on',G.cine);
  $('b_top').textContent=G.ctl.topdown?'Top-down: on':'Top-down: off'; $('b_top').classList.toggle('on',G.ctl.topdown);
  $('b_sound').textContent=G.sfxOn?'Sound: on':'Sound: off'; $('b_sound').classList.toggle('on',G.sfxOn);
  $('b_speed').textContent=SPEED<1?'Speed: fast':'Speed: normal';
  $('resolvelbl').innerHTML=!commandFor('player')?'':B.cmdUsed?'<span class="dim">Command used</span>':canCommand('player')?`<span class="gilt">Command ${'\u25CF'.repeat(cmdTier()+1)}${'\u25CB'.repeat(2-cmdTier())}</span>`:'<span class="dim">Command</span>';
  $('b_quality').textContent='Graphics: '+G.quality[0].toUpperCase()+G.quality.slice(1);
  $('b_taa').textContent='Temporal AA: '+(G.taaOn?'on':'off'); $('b_taa').classList.toggle('on',!!G.taaOn);
  $('b_follow').textContent='Follow activations: '+(G.follow?'on':'off'); $('b_follow').classList.toggle('on',G.follow);
  $('b_ai').textContent='Enemy AI: '+(AI_LEVEL==='veteran'?'Veteran':'Standard'); $('b_ai').classList.toggle('on',AI_LEVEL==='veteran');
  $('b_fx').textContent=G.fxReduced?'Flashes: reduced':'Flashes: full'; $('b_fx').classList.toggle('on',G.fxReduced);
  $('b_threat').textContent=B.showThreat?'Threat: on':'Threat: off'; $('b_threat').classList.toggle('on',B.showThreat); if($('b_threat2')) $('b_threat2').classList.toggle('on',!!B.showThreat);
  $('endbtn').textContent=B.alt?(B.activeUnit?'End activation':pendingP().length?'Pass':'Continue'):'End turn';
  $('turnlbl').textContent=B.over?'Battle over':B.side==='player'?(B.alt?(G.mobile?`Your move (${pendingP().length})`:`Your activation (${pendingP().length} ready)`):'Your turn'):(B.alt?(G.mobile?'Enemy move':'Enemy activation'):'Enemy turn');
  { const theirs=!B.over&&(B.side!=='player'||(B.busy&&B.aiActive)); document.body.classList.toggle('enemyturn',!!theirs); } /* phones: the ship sheet tucks away while the enemy moves */
  $('endbtn').disabled=B.side!=='player'||B.busy||!!B.over;
  $('b_restart').style.display=B.campaign?'none':''; $('objlbl').innerHTML=objectiveLabel();
  $('b_retreat').style.display=B.campaign&&B.cfg.kind!=='boss'?'':'none'; $('b_retreat').disabled=B.busy||!!B.over;
}
function objectiveLabel(){ const o=B&&B.obj, D='<span class="dim objpre">Objective:</span> ';
  if(!o||o.type==='rout'||o.type==='ambush') return D+'break their fleet';
  if(o.type==='flagship') return D+`destroy the flagship <span class="blood">${esc((B.units.find(x=>x.flagship)||{}).name||'')}</span>`;
  if(o.type==='hunt') return D+`catch <span class="blood">${esc((B.units.find(x=>x.flagship)||{}).name||'')}</span> before it jumps <span class="gilt">round ${Math.min(B.round,o.rounds)}/${o.rounds}</span>`;
  if(o.type==='defend') return D+`hold the station <span class="gilt">round ${Math.min(B.round,o.rounds)}/${o.rounds}</span> <span class="${o.hp<=2?'blood':'dim'}">integrity ${o.hp}/${o.hpMax}</span>`;
  if(o.type==='intercept') return D+`destroy ${o.need} of ${o.total} transports <span class="gilt">${o.kill||0}/${o.need}</span>${o.esc?` <span class="blood">${o.esc} through</span>`:''}`;
  if(o.type==='break') return D+`get ${o.need} ship${o.need>1?'s':''} off the far edge <span class="gilt">${o.out||0}/${o.need}</span>`;
  return D+`hold the relay <span class="gilt">${o.score}/3</span> <span class="dim">(them ${o.escore}/3)</span>`; }
const ZONE_INFO={exit:{n:'Exit',col:'#7dff9b',fx:'A ship that ends its move here jumps clear of the battle.'},texit:{n:'Transport exit',col:'#e07a70',fx:'An enemy transport that reaches this edge gets through.'},guard:{n:'Station perimeter',col:'#e07a70',fx:'Every enemy ship this close to the station at the start of a round knocks out 1 integrity.'}};
function refreshRoster(){
  const el=document.getElementById('roster');
  const card=u=>{ const q=[3,0,1,2].map(i=>`<span class="${u.shMax&&u.sh[i]>u.shMax*.33?'on':''}"></span>`).join('');
    return `<div class="rcard ${B.sel===u||B.inspect===u?'sel':''} ${u.dead||(B.side==='player'&&u.side==='player'&&isDone(u))?'done':''}" data-act="rosterPick" data-arg="${u.id}">
      <div class="row"><span class="n">${esc(u.isSq?u.t.n:u.name)}</span><span class="spacer"></span><span class="c">${u.dead?'Lost':u.braced?'Braced':B.alt&&!u.isSq?(B.activeUnit===u?'<span class="gilt">Active</span>':u.activated?'Activated':'Ready'):B.side==='player'&&u.side==='player'?(isDone(u)?'Done':'Ready'):''}</span></div>
      <div class="c">${esc(u.isSq?'Squadron':u.cls)}${u.elite?', elite':''}</div>
      ${u.dead?'':`${u.shMax&&!u.isSq?`<div class="row num" style="font-size:12px;gap:6px;margin-top:3px"><div class="sh4" style="flex:1;margin:0" title="Shields: port, prow, starboard, rear">${q}</div><span class="shv">${Math.round(u.sh.reduce((a,x)=>a+x,0))}</span></div>`:''}<div class="row num" style="font-size:12px;gap:6px;margin-top:3px"><span style="flex:1">${hpBar(u.hp,u.maxHp)}</span><span class="hlv">${Math.max(0,u.hp)}</span></div>`}</div>`; };
  const pl=B.units.filter(u=>u.side==='player'&&(!u.dead||!u.isSq)), en=B.units.filter(u=>u.side==='enemy'&&!u.dead);
  el.innerHTML=`<div class="dim" style="font-size:12.5px;margin:2px 4px 6px">Your fleet: ${esc(FACTIONS[SETUP.pf].n)}</div>${pl.map(card).join('')}<div class="dim" style="font-size:12.5px;margin:12px 4px 6px">${esc(FACTIONS[SETUP.ef].n)}</div>${en.map(card).join('')}`;
}
ACT.rosterPick=id=>{ const u=B.units.find(x=>x.id===id); if(!u||u.dead) return; if(u.side==='player'){ if(B.side==='player'&&!B.busy){ selectUnit(u); G.ctl.focus(uWorld(u)); } } else { B.sel=null; B.inspect=u; B.armed=null; B.mode=null; G.ctl.focus(uWorld(u)); bRefresh(); } };
function shieldDial(u){
  const f=i=>u.shMax?Math.round(u.sh[i]):0, a=i=>u.shMax?(.15+.85*u.sh[i]/u.shMax):.1;
  const arc=(i,a0,a1)=>{ const r=26,c=38, p0=[c+r*Math.sin(a0*Math.PI/180),c-r*Math.cos(a0*Math.PI/180)], p1=[c+r*Math.sin(a1*Math.PI/180),c-r*Math.cos(a1*Math.PI/180)]; return `<path d="M${p0[0]} ${p0[1]}A${r} ${r} 0 0 1 ${p1[0]} ${p1[1]}" stroke="#62ccff" stroke-opacity="${a(i)}" stroke-width="5" fill="none"/>`; };
  return `<div class="shielddial"><svg width="76" height="76" viewBox="0 0 76 76" aria-hidden="true">${arc(0,-46,46)}${arc(1,54,126)}${arc(2,134,226)}${arc(3,234,306)}<path d="M38 24l6 16-6 10-6-10z" fill="#d9ccaa"/></svg>
    <div class="num" style="font-size:13.5px;line-height:1.5">${u.shMax?`<span class="shv">Shields</span> <span class="dim">of ${u.shMax} each, +${u.regen}/turn</span><br><span class="shv">Prow ${f(0)}</span><br><span class="shv">Port ${f(3)}, starboard ${f(1)}</span><br><span class="shv">Rear ${f(2)}</span>`:'<span class="dim">No shields</span>'}</div></div><div class="legend"><span class="shv">Cyan</span> is shields: they soak hits on the facing that is struck and recharge each turn. <span class="hlv">Amber</span> is hull: damage that stays.</div>`;
}
function weaponLine(u,w,i,own){
  let status; if(w.off>0) status='<span class="blood">Offline</span>'; else if(w.cdLeft>0) status=`<span class="dim">Reloading, ${w.cdLeft}</span>`; else if(w.fired) status='<span class="dim">Fired</span>'; else status='<span class="verd">Ready</span>';
  const ready=weaponReady(w)&&own&&!u.braced;
  return `<div class="weap ${B.armed===i&&own?'armed':''} ${ready?'':'off'}" ${ready?`data-act="arm" data-arg="${i}"`:''}><span class="wn">${own?`<kbd>${i+1}</kbd> `:''}${esc(w.n)}${(w.evMult||1)>1?` <span class="dim" title="Slow: the target's evasion counts ${w.evMult}x against it">(slow)</span>`:''}</span><span>${status}</span>
    <span class="wd">${w.arc==='T'?'Turret':ARC_NAME[w.arc]}, ${w.shots}\u00d7${Math.round(w.dmg*u.dmg)} damage, range ${w.r}${w.pierce?`, ${pct(w.pierce)} through shields`:''}${w.ion?', shreds shields':''}${w.vsSq>1?', anti-squadron':''}${w.cd?`, reload ${w.cd}`:''}${w.trait&&WTRAITS[w.trait]?`<br><span class="gilt" style="font-size:.92em">${WTRAITS[w.trait].d}</span>`:''}</span></div>`;
}
function refreshPanel(){
  if(G.panelRenders){ G.panelRenders.push(performance.now()); if(G.panelRenders.length>60) G.panelRenders.shift(); }
  const el=document.getElementById('panel'); const u=B.sel||B.inspect;
  if(!u||u.dead){ el.innerHTML=`<button class="sheetbtn" data-act="sheet">\u25be</button><h3>Orders</h3><p class="muted">Select one of your ships to move and fire. Each ship can move, turn and fire every weapon once per turn, in any order.</p><p class="muted">Click an enemy to see its weapons and firing arcs.</p>${keysHelp()}`; el.innerHTML=touchWords(el.innerHTML); return; }
  const own=u.side==='player'&&B.side==='player'&&!B.busy, cap=u.ship?u.ship.cap:null, tr=[];
  if(u.hullRegen) tr.push(`Repairs ${u.hullRegen} hull each turn.`); if(u.st.engine) tr.push(`Engines damaged (\u2212${u.st.engine} speed).`); if(u.st.shieldOff) tr.push('Shield generator offline.'); if(u.st.fire) tr.push('Burning.');
  if(u.ab==='launch'&&!u.isSq){ const ws=squadronsOf(u), nb=ws.filter(x=>x.t.sq!=='fighter').length, nf=ws.length-nb; tr.push(`Wings flying: ${nb} strike (bombers hit ships), ${nf} fighter (guards your wings, hunts enemy craft)${u.spare!=null?`, ${u.spare} spare`:''}. They act on their own each round unless you order them: tap a wing, then a target to strike or a ship to guard.`); }
  if(u.evBuff) tr.push(`Evasive: +${u.evBuff} evasion.`); if(u.lockOn) tr.push('Locked on: +15 aim, +10% crit.'); if(u.focus) tr.push('Concentrated fire: +30% damage.'); if(u.braced) tr.push('Braced: hull damage \u221240%.');
  let h=`<button class="sheetbtn" data-act="sheet" aria-label="Collapse panel">${document.body.classList.contains('sheetmin')?'\u25b4':'\u25be'}</button>${actionStrip(u)}<h3>${esc(u.isSq?u.t.n:u.name)}</h3><div class="cls">${esc(u.t.n)}${u.elite?', elite captain':''}</div>
    ${cap?`<div style="margin-top:4px;font-size:13.5px">${rankName(cap)} ${esc(cap.name)} ${cap.perks.map(p=>`<span class="pill" title="${esc(PERKS[p].d)}">${esc(PERKS[p].n)}</span>`).join('')}</div>`:''}
    <div class="row num" style="margin-top:10px;font-size:13.5px"><span class="hlv">Hull</span><span class="spacer"></span><span class="hlv">${Math.max(0,u.hp)}/${u.maxHp}</span></div>${hpBar(u.hp,u.maxHp)}
    ${u.sec?`<div class="secs">${['prow','mid','eng'].map(k=>`<div><span class="${u.sec[k].hp<=0?'blood':''}">${SEC_LBL[k]}${u.sec[k].hp<=0?' (out)':''}</span>${hpBar(u.sec[k].hp,u.sec[k].max)}</div>`).join('')}</div>
    <div class="row num" style="font-size:13.5px;margin-top:6px"><span>Crew</span><span class="spacer"></span><span class="${u.crew<u.crewMax*.5?'ember':''}">${u.crew}/${u.crewMax}${u.captured?', prize crew':''}</span></div>`:''}
    <div style="margin-top:10px">${u.isSq?'':shieldDial(u)}</div>
    <div class="stats num"><b>Movement</b><span>${u.side==='player'?`${u.mp} left of ${u.speed}`:u.speed}</span>${u.isSq?'':`<b>Turns</b><span>${u.side==='player'?`${u.turnsLeft} left of ${u.turns}`:u.turns}${u.noTurn?' (locked)':''}</span>`}<b>Armor</b><span>${pct(u.armor)}</span><b>Evasion</b><span>${u.ev+(u.evBuff||0)}</span></div>
    ${tr.length?`<div class="muted" style="font-size:13.5px">${tr.join(' ')}</div>`:''}
    <div class="sect"><h4>Weapons</h4>${u.weapons.map((w,i)=>weaponLine(u,w,i,own)).join('')}</div>`;
  if(u.side==='enemy'&&u.t&&u.t.boss&&typeof BOSS_CMD!=='undefined'&&BOSS_CMD[u.fac]){ const c=BOSS_CMD[u.fac]; h+=`<div class="sect"><h4>Flagship Command <span class="dim">(${B.cmdEUsed?'used':B.cmdENext!=null?'strikes next round':'not yet'})</span></h4><div class="${B.cmdENext!=null&&!B.cmdEUsed?'blood':'muted'}" style="font-size:12.5px"><b>${esc(c.n)}.</b> ${esc(bossCmdText(c,u.fac))}</div></div>`; }
  if(u.side==='player'&&!u.isSq){ const c=commandFor('player'); if(c) h+=`<div class="sect"><h4>Admiral's Command <span class="dim">(${B.cmdUsed?'used':canCommand('player')?(cmdTier()>=2?'full power':'power '+(cmdTier()+1)+' of 3'):'not ready'})</span></h4><button style="width:100%;text-align:left" ${own&&canCommand('player')?'':'disabled'} data-act="command"><b class="gilt">${esc(c.n)}</b> <span class="gilt">${'\u25CF'.repeat(cmdTier()+1)}${'\u25CB'.repeat(2-cmdTier())}</span><br><span class="muted" style="font-size:12.5px">${esc(cmdDesc(c,cmdTier(),RUN&&RUN.fac))}</span><br><span class="dim" style="font-size:12px">${B.cmdUsed?'':cmdTier()<2?`Wait a round for ${esc(cmdNext(c,cmdTier(),RUN&&RUN.fac))}${cmdTier()===0?' (full power the round after)':''}. Waiting risks the fight ending first.`:'Full power. It can\u2019t grow any stronger.'}</span></button></div>`; }
  if(u.side==='player'&&!u.isSq){ const ri=ramInfo(u), bts=boardTargets(u), re=ri?ramEstimate(u,ri.t,ri.path.length):null;
    h+=`<div class="sect"><h4>Close action</h4><div class="orders"><button ${own&&ri&&canUse(u)?'':'disabled'} data-act="ram" title="Charge straight ahead into the first enemy ship in line. Needs at least one clear hex of run-up and enough movement left to cover the gap; a longer run hits harder.">Ramming speed<small><kbd>X</kbd> ${ri?`${esc(ri.t.name)}: about ${re.dmg}, you take ${re.recoil}`:'Point your bow at an enemy with clear space between you. Red-ringed move hexes line one up.'}</small></button><button ${own&&bts.length&&canUse(u)&&!B.mode?'':'disabled'} data-act="board" title="Send boarding parties into an adjacent enemy. Uses this ship's attack for the turn.">Boarding action<small><kbd>G</kbd> ${bts.length?`${bts.length} ship${bts.length>1?'s':''} in reach`:'Adjacent enemy, guns unfired'}</small></button></div>${B.mode==='board'?'<p class="gilt" style="font-size:13.5px">Click an adjacent enemy to board it. Right-click to cancel.</p>':''}</div>`;
    if(typeof RUN!=='undefined'&&RUN&&((RUN.boons||[]).length||(RUN.aspect&&u.pflag))){ const st=B.boonStats||{};
      h+=`<div class="sect"><h4>Fleet boons</h4>${u.pflag&&RUN.aspect&&ASPECTS[RUN.aspect]?`<div style="font-size:13px;margin-bottom:5px"><b class="gilt">${esc(ASPECTS[RUN.aspect].n)}</b> <span class="muted">${esc(ASPECTS[RUN.aspect].d)}</span></div>`:''}${(RUN.boons||[]).map(b=>{ const B0=BOONS[b.id]; if(!B0) return ''; const P=B0.p?PATRONS[B0.p]:PATRONS[B0.duo[0]], R=RARITY[b.r||0]; return `<div style="font-size:13px;margin-bottom:4px;border-left:3px solid ${P.col};padding-left:6px"><b>${esc(B0.n)}</b>${st[b.id]?` <span class="gilt">\u00d7${st[b.id]} this battle</span>`:''} <span class="muted">${esc(B0.d(R.m))}</span></div>`; }).join('')}</div>`; } }
  if(u.side==='player'){
    if(!u.isSq) h+=`<div class="sect"><h4>Helm</h4><div class="orders"><button ${own&&canRotate(u)?'':'disabled'} data-act="rot" data-arg="-1">Turn to port<small><kbd>Q</kbd> ${freePivot(u)?'free':'1 movement'}</small></button><button ${own&&canRotate(u)?'':'disabled'} data-act="rot" data-arg="1">Turn to starboard<small><kbd>E</kbd> ${freePivot(u)?'free':'1 movement'}</small></button></div>${driveLine(u)}</div>
`;
    if(u.ab){ const A=ABILITIES[u.ab], extra=u.ab==='launch'?` (${squadronsOf(u).length}/${u.hangar} in flight)`:'';
      h+=`<div class="sect"><h4>Ability</h4><button style="width:100%;text-align:left" ${own&&canAbility(u)&&!B.mode?'':'disabled'} data-act="ability"><b>${esc(A.n)}</b>${extra}<br><span class="muted" style="font-size:12.5px">${esc(A.d)}${u.abCd?` Ready in ${u.abCd} turn${u.abCd>1?'s':''}.`:''}</span></button>
        ${B.mode==='launchPick'?`<div class="orders" style="margin-top:6px"><button data-act="launchKind" data-arg="fighter">Fighter wing<small>Hunts squadrons</small></button><button data-act="launchKind" data-arg="bomber">Bomber wing<small>Ignores shields</small></button></div>`:''}
        ${B.mode==='launch'?'<p class="gilt" style="font-size:13.5px">Click a highlighted hex to launch. Right-click to cancel.</p>':''}${B.mode==='blink'?'<p class="gilt" style="font-size:13.5px">Tap a highlighted hex within 3 to phase-jump there.</p>':''}${B.mode==='nova'?'<p class="gilt" style="font-size:13.5px">Click a hex in the prow arc, 3 to 9 hexes away. Right-click to cancel.</p>':''}</div>`; }
  } else h+=`<div class="sect"><h4>${esc(FACTIONS[u.fac].n)}</h4><p class="muted" style="font-size:13.5px;margin:0">${esc(FACTIONS[u.fac].blurb||'')}</p></div>`;
  el.innerHTML=touchWords(h+keysHelp());
}
function keysHelp(){ return `<div class="keys"><kbd>Tab</kbd> next ship <kbd>Q</kbd><kbd>E</kbd> turn <kbd>1</kbd>\u2013<kbd>6</kbd> pick weapon <kbd>B</kbd> brace <kbd>V</kbd> arcs <kbd>Esc</kbd> cancel <kbd>Space</kbd> speed <kbd>Enter</kbd> end turn</div>`; }

// ---------- 3D overlays ----------
const OV={items:[],hover:[],bases:{},fan:null,ghost:null,ghostFor:null,selRing:null,insRing:null,aiRing:null,targets:[]};
function ovMat(name,col,alpha){ const m=emMat('ov_'+name,col,alpha); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.backFaceCulling=false; m.disableDepthWrite=true; m.zOffset=-2; return m; }
function tileBase(key,col,alpha,edge){
  if(OV.bases[key]) return OV.bases[key];
  let m; if(edge){ m=MB.CreateTorus('tb',{diameter:HS*2*.94,thickness:.35,tessellation:6},G.scene); m.bakeTransformIntoVertices(BABYLON.Matrix.RotationY(Math.PI/6)); }
  else { m=MB.CreateDisc('tb',{radius:HS*.9,tessellation:6,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene); m.bakeTransformIntoVertices(BABYLON.Matrix.RotationX(Math.PI/2).multiply(BABYLON.Matrix.RotationY(Math.PI/6))); }
  m.material=ovMat(key,col,alpha); m.material._keep=true; m.isVisible=false; m.isPickable=false; G.glow.addExcludedMesh(m); return OV.bases[key]=m;
}
function tile(key,col,alpha,h,list,edge){ const inst=tileBase(key,col,alpha,edge).createInstance('t'); inst.position=hexWorld(h.q,h.r,.12); inst.isPickable=false; list.push(inst); return inst; }
function ringMesh(col,alpha,R,th=.3){ const m=MB.CreateTorus('rg',{diameter:R*2,thickness:th,tessellation:48},G.scene); m.material=ovMat('ring',col,alpha); m.isPickable=false; G.glow.addExcludedMesh(m); return m; }
function fanMesh(a0,a1,R,col,alpha){
  const pos=[0,0,0], uv=[.5,.5], idx=[]; const n=Math.max(8,Math.round((a1-a0)/3));
  for(let i=0;i<=n;i++){ const a=(a0+(a1-a0)*i/n)*Math.PI/180, x=Math.cos(a)*R, z=-Math.sin(a)*R; pos.push(x,0,z); uv.push(.5+.5*x/R,.5+.5*z/R); if(i) idx.push(0,i,i+1); }
  const m=new BABYLON.Mesh('fan',G.scene); const vd=new BABYLON.VertexData(); vd.positions=pos; vd.indices=idx; vd.uvs=uv; vd.applyToMesh(m);
  const mat=ovMat('fan',col,alpha); mat.opacityTexture=G.tex.fan; m.material=mat; m.isPickable=false; G.glow.addExcludedMesh(m);
  const edge=[]; for(let i=0;i<=n;i++){ const a=(a0+(a1-a0)*i/n)*Math.PI/180; edge.push(new V3(Math.cos(a)*R,.05,-Math.sin(a)*R)); }
  const l1=MB.CreateLines('fe',{points:[new V3(0,.05,0),edge[0]]},G.scene), l2=MB.CreateLines('fe',{points:[new V3(0,.05,0),edge[n]]},G.scene), l3=MB.CreateLines('fe',{points:edge},G.scene);
  for(const l of [l1,l2,l3]){ l.color=col; l.alpha=.6; l.parent=m; l.isPickable=false; }
  return m;
}
// one bright gold line around everywhere the selected ship can move this turn: far easier to read on a phone than per-hex outlines
function reachOutline(u,reach){ try{ const set=new Set([hkey(u.q,u.r)]); for(const s of reach.map.values()) set.add(hkey(s.q,s.r)); const pos=[], idx=[], w=.55;
    for(const k of set){ const [q,r]=k.split(',').map(Number), c=hexWorld(q,r,0);
      for(let i=0;i<6;i++){ const a0=Math.PI/180*(60*i-30), a1=Math.PI/180*(60*(i+1)-30), mx=(Math.cos(a0)+Math.cos(a1))/2, mz=(Math.sin(a0)+Math.sin(a1))/2, nb=worldHex(c.x+mx*HS*1.6,c.z+mz*HS*1.6);
        if(set.has(hkey(nb.q,nb.r))) continue; const R=HS*.97, p0=new V3(c.x+R*Math.cos(a0),.2,c.z+R*Math.sin(a0)), p1=new V3(c.x+R*Math.cos(a1),.2,c.z+R*Math.sin(a1)), n=new V3(-mx,0,-mz).normalize().scale(w), b=pos.length/3;
        pos.push(p0.x,p0.y,p0.z, p1.x,p1.y,p1.z, p1.x+n.x,p1.y,p1.z+n.z, p0.x+n.x,p0.y,p0.z+n.z); idx.push(b,b+1,b+2,b,b+2,b+3); } }
    if(!pos.length) return null; const m=new BABYLON.Mesh('reachLine',G.scene), vd=new BABYLON.VertexData(); vd.positions=pos; vd.indices=idx; vd.applyToMesh(m);
    m.material=OV.reachMat||(OV.reachMat=ovMat('reachLine',new C3(1.15,.86,.42),.95)); m.isPickable=false; G.glow.addExcludedMesh(m); return m; }catch(e){ console.warn(e); return null; } }
// a ram that is ready now: a red charge lane from the bow to the target and a ring on the target
function ramLane(u,ri){ try{ const a=hexWorld(u.q,u.r,.9), b=hexWorld(ri.t.q,ri.t.r,.9), m=OV.ramMat||(OV.ramMat=ovMat('ramLane',new C3(1.3,.35,.25),.85));
    const tb=MB.CreateTube('ramLane',{path:[a,b],radius:HS*.09,tessellation:6,cap:BABYLON.Mesh.CAP_ALL},G.scene); tb.material=m; tb.isPickable=false; G.glow.addExcludedMesh(tb); OV.items.push(tb);
    const d=b.subtract(a); d.y=0; d.normalize(); const side=new V3(-d.z,0,d.x), tip=b.subtract(d.scale(HS*.75)), k=HS*.38;
    const ar=MB.CreateTube('ramArrow',{path:[tip.subtract(d.scale(k)).add(side.scale(k)),tip,tip.subtract(d.scale(k)).subtract(side.scale(k))],radius:HS*.09,tessellation:6},G.scene); ar.material=m; ar.isPickable=false; OV.items.push(ar);
    const v=G.views.get(ri.t.id), rm=ringMesh(new C3(1.3,.35,.25),.9,v?Math.max(6,v.L*.66):6.5,.45); rm.position=hexWorld(ri.t.q,ri.t.r,.3); OV.items.push(rm); }catch(e){ console.warn(e); } }
// v49: overlay meshes own their materials (rings, fans, lines), so free those too; the shared tile templates keep theirs
function ovDispose(m){ if(!m||m.isDisposed&&m.isDisposed()) return; const mats=new Set(); const grab=x=>{ const mt=x&&x.material; if(mt&&!mt._keep&&!(G.aimMats&&Object.values(G.aimMats).includes(mt))) mats.add(mt); }; grab(m); if(m.getChildMeshes) m.getChildMeshes(false).forEach(grab); m.dispose(); mats.forEach(mt=>{ try{ mt.dispose(); }catch(e){} }); }
function clearOverlays(){ for(const m of OV.items) ovDispose(m); OV.items=[]; for(const m of OV.hover) ovDispose(m); OV.hover=[]; if(OV.fan){ ovDispose(OV.fan); OV.fan=null; } if(OV.ghost){ OV.ghost.dispose(); OV.ghost=null; OV.ghostFor=null; } OV.targets=[]; }
function refreshOverlays(){
  for(const m of OV.items) ovDispose(m); OV.items=[]; OV.targets=[];
  if(OV.fan){ ovDispose(OV.fan); OV.fan=null; }
  if(!B||B.over) { refreshHover(); return; }
  const sel=B.sel, playerTurn=B.side==='player'&&!B.busy;
  const arcU=sel||B.inspect;
  try{ gridFocus(arcU&&!arcU.dead?arcU:null, arcU?Math.max(6,...arcU.weapons.map(w=>w.r||0))+1:0); }catch(e){}
  if(arcU&&!arcU.dead&&B.showArcs&&!B.mode){
    const node=new BABYLON.TransformNode('fanNode',G.scene); OV.fan=node; node.metadata={u:arcU};
    const enemy=arcU.side!=='player'; const ws=B.armed!=null&&sel===arcU?[arcU.weapons[B.armed]]:arcU.weapons;
    const byArc={}; for(const w of ws){ if(w.k==='flak'&&ws.length>1) continue; byArc[w.arc]=Math.max(byArc[w.arc]||0,w.r); }
    const spans={F:[-60,60],S:[30,150],P:[-150,-30],R:[120,240]};
    for(const [arc,r] of Object.entries(byArc)){ const R=r*HW+HS*.4;
      if(arc==='T'){ const rm=ringMesh(enemy?new C3(1,.35,.3):new C3(.9,.85,.7),.18,R,.25); rm.parent=node; rm.position.y=.1; continue; }
      const col=enemy?new C3(1,.3,.25):arc==='F'||arc==='R'?new C3(1,.62,.22):new C3(.3,.85,.72);
      const fm=fanMesh(spans[arc][0],spans[arc][1],R,col,enemy?.05:.06); /* holo: outline the arc, barely fill it */ fm.parent=node; fm.position.y=.08; }
  }
  if(B.showThreat){ const th=computeThreat(); for(const [k,v] of th){ const [q,r]=k.split(',').map(Number); const lv=v>=45?3:v>=20?2:1; tile('thr'+lv,new C3(1,.18,.12),[0,.08,.16,.28][lv],{q,r},OV.items); } }
  if(sel&&playerTurn&&sel.side==='player'&&B.reach&&!B.mode&&!B.wingSel){ for(const s of B.reach.map.values()){ tile('reach2',new C3(.95,.7,.28),.075,s,OV.items); tile('reachE2',new C3(1,.8,.4),.42,s,OV.items,true); /* v52: hollow hexes, bright edge and faint fill, so ships inside stay readable */ if(s.ram) tile('ramSpot',new C3(1,.32,.25),.75,s,OV.items,true); }
    const per=reachOutline(sel,B.reach); if(per) OV.items.push(per); }
  if(sel&&playerTurn&&sel.side==='player'&&!B.mode&&!sel.isSq&&canUse(sel)){ const ri=ramInfo(sel); if(ri) ramLane(sel,ri); }
  if(B.wingSel&&!B.wingSel.dead){ tile('wingSel',new C3(1,.8,.35),.55,B.wingSel,OV.items); tile('wingSelE',new C3(1,.85,.45),.8,B.wingSel,OV.items,true); }
  if(B.side==='player') for(const w of alive('player').filter(x=>x.isSq&&x.wingOrder)){ const o=sqOrder(w); if(!o) continue; const v=G.views.get(o.t.id), R=v?Math.max(5,v.L*.6):5.5, rm=ringMesh(o.kind==='strike'?new C3(1,.55,.2):new C3(.35,.9,.75),.6,R,.22); rm.position=hexWorld(o.t.q,o.t.r,.25); OV.items.push(rm); }
  if(B.mode==='nova'&&sel) for(const h of novaTargets(sel)) tile('nova',new C3(1,.55,.2),.1,h,OV.items);
  if(B.mode==='blink'&&sel) for(const h of blinkHexes(sel)) tile('blink',new C3(.55,.9,1),.3,h,OV.items);
  if(B.mode==='board'&&sel) for(const t of boardTargets(sel)) tile('boardT',new C3(1,.55,.2),.4,t,OV.items);
  if(B.mode==='launch'&&sel) for(const h of launchHexes(sel)) tile('launch',new C3(1,.7,.3),.35,h,OV.items);
  if(sel&&playerTurn&&sel.side==='player'&&!B.mode){ for(const t of alive('enemy')){ const ws=B.armed!=null?[sel.weapons[B.armed]]:sel.weapons; if(!ws.some(w=>canFire(sel,w,t))) continue;
      const v=G.views.get(t.id); const R=v?Math.max(5.5,v.L*.62):6; const rm=ringMesh(new C3(1,.3,.25),.8,R,.3); rm.metadata={u:t}; OV.items.push(rm); OV.targets.push(rm); } }
  if(!OV.selRing){ OV.selRing=ringMesh(new C3(1,.75,.3),.75,6,.34); OV.insRing=ringMesh(new C3(1,.3,.25),.7,6,.34); OV.aiRing=ringMesh(new C3(1,.3,.25),.8,6,.34); }
  refreshHover();
}
function refreshHover(){
  for(const m of OV.hover) ovDispose(m); OV.hover=[];
  if(OV.ghost) OV.ghost.setEnabled(false);
  if(!B||B.over||B.busy) return;
  const h=B.hover, sel=B.sel; if(!h) return;
  tile('hov',new C3(.95,.9,.8),.55,h,OV.hover,true);
  { const hu=unitAt(h.q,h.r); if(sel&&sel.side==='player'&&!sel.isSq&&hu&&hu.side==='enemy'&&B.side==='player') aimLine(sel,hu); }
  if(B.mode==='nova'&&sel&&novaTargets(sel).some(x=>x.q===h.q&&x.r===h.r)){ for(const x of boardHexes()) if(hdist(x,h)<=1) tile('blast',new C3(1,.25,.2),.35,x,OV.hover); return; }
  if(sel&&sel.side==='player'&&B.side==='player'&&B.reach&&!B.mode){ const st=B.reach.map.get(hkey(h.q,h.r)); if(st&&!unitAt(st.q,st.r)){
      const pts=[hexWorld(sel.q,sel.r,.6),...st.path.map(p=>hexWorld(p.q,p.r,.6))]; const ln=MB.CreateDashedLines('path',{points:pts,dashSize:2,gapSize:1.2,dashNb:Math.max(8,pts.length*10)},G.scene); ln.color=new C3(1,.75,.35); ln.isPickable=false; OV.hover.push(ln);
      const v=G.views.get(sel.id);
      if(v&&v.model){ if(OV.ghostFor!==sel.id){ if(OV.ghost) OV.ghost.dispose(); OV.ghost=v.model.root.clone('ghost'); const gm=OV.bases.ghostMat||(OV.bases.ghostMat=ovMat('ghost',new C3(1,.72,.35),.28)); OV.ghost.getChildMeshes().forEach(m=>{ m.material=gm; m.isPickable=false; }); OV.ghostFor=sel.id; }
        OV.ghost.setEnabled(true); const p=hexWorld(st.q,st.r,HOVER_Y); OV.ghost.position=p; OV.ghost.rotation.set(0,st.f*Math.PI/3,0); } } }
}
function updateOverlays(){
  if(!B||!OV.selRing) return;
  const place=(ring,u)=>{ if(u&&!u.dead&&G.views.get(u.id)){ const v=G.views.get(u.id); const p=v.root.getAbsolutePosition(); ring.setEnabled(true); ring.position.set(p.x,.2,p.z); const R=Math.max(5.5,v.L*.6)/6; ring.scaling.set(R,1,R); } else ring.setEnabled(false); };
  place(OV.selRing,B.sel); place(OV.insRing,B.inspect); place(OV.aiRing,B.side==='enemy'?B.aiActive:null);
  OV.selRing.rotation.y+=.01; const pulse=.45+.4*Math.sin(G.time*4.5);
  for(const r of OV.targets){ const u=r.metadata.u, v=G.views.get(u.id); if(v){ const p=v.root.getAbsolutePosition(); r.position.set(p.x,.25,p.z); r.material.alpha=pulse; } }
  if(OV.fan){ const u=OV.fan.metadata.u, v=G.views.get(u.id);
    if(OV.ghost&&OV.ghost.isEnabled()&&OV.ghostFor===u.id&&!u.vis){ OV.fan.position.set(OV.ghost.position.x,0,OV.ghost.position.z); OV.fan.rotation.y=OV.ghost.rotation.y; }
    else if(v){ const p=v.root.getAbsolutePosition(); OV.fan.position.set(p.x,0,p.z); OV.fan.rotation.y=unitVis(u).a*Math.PI/180; } }
  if(B.side==='enemy'&&B.aiActive!==G.lastAi){ G.lastAi=B.aiActive; if(B.aiActive&&G.follow&&!G.ctl.saved) camShow(B.aiActive); }
}

function computeThreatAt(h){ if(!B.threatCache||B.threatCache.key!==B.log.length+'|'+B.round) B.threatCache={key:B.log.length+'|'+B.round,map:computeThreat()}; return B.threatCache.map.get(hkey(h.q,h.r))||0; }
function computeThreat(){
  const map=new Map(), hexes=boardHexes();
  for(const e of alive('enemy')){
    const ws=e.weapons.filter(w=>w.off<=1&&w.cdLeft<=1); if(!ws.length) continue;
    const states=[{q:e.q,r:e.r,f:e.facing,cost:0,path:[]}].concat(e.isSq?[]:computeReach(e).states);
    const per=new Map();
    for(const s of states){ const v=stateView(e,s); const tmp=new Map();
      for(const w of ws){ const val=w.shots*w.dmg*(e.dmg||1); for(const h of hexes){ if(hdist(v,h)>w.r||!inArc(v,h,w.arc)||!los(v,h)) continue; const k=hkey(h.q,h.r); tmp.set(k,(tmp.get(k)||0)+val); } }
      for(const [k,val] of tmp) if(val>(per.get(k)||0)) per.set(k,val); }
    for(const [k,val] of per) map.set(k,(map.get(k)||0)+val);
  }
  return map;
}

// ---------- input ----------
function bindInput(canvas){
  canvas.addEventListener('contextmenu',e=>e.preventDefault());
  const pts=new Map(); let pinch=null;
  const pinchState=()=>{ const [a,b]=[...pts.values()]; return {d:Math.hypot(a.x-b.x,a.y-b.y)||1,ang:Math.atan2(b.y-a.y,b.x-a.x),mx:(a.x+b.x)/2,my:(a.y+b.y)/2}; };
  // a fresh primary touch means every earlier finger is gone, even if the browser never told us
  ['pointerup','pointercancel','lostpointercapture'].forEach(ev=>window.addEventListener(ev,e=>{ pts.delete(e.pointerId); if(pts.size<2) pinch=null; },true));
  G.touchState=()=>({fingers:pts.size,pinch:!!pinch,ptr:!!G.ptr});
  canvas.addEventListener('pointerdown',e=>{ if(e.isPrimary&&pts.size){ pts.clear(); pinch=null; } try{ canvas.setPointerCapture(e.pointerId); }catch(err){} pts.set(e.pointerId,{x:e.clientX,y:e.clientY}); G.ctl.attract=false;
    if(pts.size===2){ pinch=pinchState(); G.ptr=null; return; } G.ptr={b:e.button,x:e.clientX,y:e.clientY,lx:e.clientX,ly:e.clientY,moved:false,touch:e.pointerType==='touch'}; });
  canvas.addEventListener('pointercancel',e=>{ pts.delete(e.pointerId); if(pts.size<2) pinch=null; G.ptr=null; });
  canvas.addEventListener('pointermove',e=>{ if(pts.has(e.pointerId)) pts.set(e.pointerId,{x:e.clientX,y:e.clientY});
    if(pts.size===2&&pinch){ G.camMoved=performance.now(); const n=pinchState(); G.ctl.r=clamp(G.ctl.r*pinch.d/n.d,22,900); G.ctl.a-=(n.ang-pinch.ang); G.ctl.panBy(-(n.mx-pinch.mx)*.32,(n.my-pinch.my)*.32); pinch=n; hideTip(); return; }
    const p=G.ptr;
    if(p){ const dx=e.clientX-p.lx, dy=e.clientY-p.ly; p.lx=e.clientX; p.ly=e.clientY; if(Math.abs(e.clientX-p.x)+Math.abs(e.clientY-p.y)>5) p.moved=true;
      if(p.moved){ G.camMoved=performance.now(); if(p.b===2) G.ctl.orbit(dx,dy); else G.ctl.panBy(-dx*.32,dy*.32); hideTip(); return; } }
    onHover(e); });
  canvas.addEventListener('pointerup',e=>{ pts.delete(e.pointerId); if(pts.size<2) pinch=null; const p=G.ptr; G.ptr=null; if(!p||p.moved) return;
    if(p.touch){ onHover(e); const h=B&&B.hover, own=h&&unitAt(h.q,h.r)&&unitAt(h.q,h.r).side==='player';
      if(own||(G.lastTap&&h&&G.lastTap.q===h.q&&G.lastTap.r===h.r&&performance.now()-G.lastTap.t<3000)){ G.lastTap=null; hideTip(); onBoardClick(); } else { G.lastTap=h?{q:h.q,r:h.r,t:performance.now()}:null; }
      return; }
    if(p.b===0) onBoardClick(); else if(p.b===2) cancelAction(); });
  canvas.addEventListener('pointerleave',()=>{ if(B){ B.hover=null; refreshHover(); } hideTip(); });
  document.addEventListener('keydown',onKey);
}
function onHover(e){
  if(!B) return; const rect=G.engine.getRenderingCanvas().getBoundingClientRect(); const x=e.clientX-rect.left, y=e.clientY-rect.top;
  let hex=null; const pk=G.scene.pick(x,y,m=>!!(m.metadata&&m.metadata.unit)&&m.isEnabled()&&m.isVisible);
  if(pk&&pk.hit){ const u=B.units.find(k=>k.id===pk.pickedMesh.metadata.unit); if(u&&!u.dead) hex={q:u.q,r:u.r}; }
  let ground=null; { const ray=G.scene.createPickingRay(x,y,BABYLON.Matrix.Identity(),G.cam); if(ray.direction.y<-1e-4){ const k=-ray.origin.y/ray.direction.y, p=ray.origin.add(ray.direction.scale(k)); const h=worldHex(p.x,p.z); if(onBoard(h.q,h.r)) ground=h; } }
  // a reachable hex beside the selected ship beats the ship's own tall hull
  if(hex&&ground&&B.sel&&B.reach&&B.reach.map.get(hkey(ground.q,ground.r))&&!unitAt(ground.q,ground.r)){ const hu=unitAt(hex.q,hex.r); if(!hu||hu.side==='player') hex=ground; }
  if(!hex) hex=ground;
  const ch=(hex&&hex.q)!==(B.hover&&B.hover.q)||(hex&&hex.r)!==(B.hover&&B.hover.r); B.hover=hex; if(ch) refreshHover();
  const tip=boardTip(); if(tip) showTip(tip,e.clientX,e.clientY); else hideTip();
}
function markRamSpots(u,reach){ if(!reach||!u||u.isSq) return reach; try{ for(const st of reach.map.values()) st.ram=ramFrom(u,st)?1:0; }catch(e){} return reach; }
function selectUnit(u){ try{ if(u&&B&&B.usage&&u.side==='player'&&!u.isSq&&ramInfo(u)){ B.ramSeen=B.ramSeen||new Set(); const k=u.id+':'+B.round; if(!B.ramSeen.has(k)){ B.ramSeen.add(k); B.usage.ramReady=(B.usage.ramReady||0)+1; } } }catch(e){} B.sel=u; B.inspect=null; B.armed=null; B.mode=null; B.reach=(u&&u.side==='player'&&B.side==='player'&&canUse(u))?markRamSpots(u,computeReach(u)):null; bRefresh(); }
// facing helper: for each hex, end on the facing that brings the most ready guns onto an enemy (cheapest on ties)
function bestFacingReach(u,R){ const foes=alive('enemy'), ready=u.weapons.filter(w=>weaponReady(w)&&w.k!=='flak'); if(!R||!ready.length||!foes.length) return R; const best=new Map();
  for(const st of R.states){ const k=hkey(st.q,st.r), v=stateView(u,st); let n=0; const per=new Map();
    for(const w of ready){ let any=false; for(const t of foes) if(inReach(v,w,t)){ any=true; per.set(t,(per.get(t)||0)+1); } if(any) n++; }
    let tgt=null,tv=0; for(const [t,c] of per) if(c>tv){ tv=c; tgt=t; }
    const sc=n*1000-(st.cost||0)*10-(st.t||0); const cur=best.get(k); if(!cur||sc>cur.sc) best.set(k,{st,sc,n,tgt}); }
  for(const [k,b] of best){ b.st.guns=b.n; b.st.gunsOf=ready.length; b.st.gunTarget=b.tgt; R.map.set(k,b.st); } return R; }
function updateReach(){ if(B&&B.sel&&!B.sel.dead&&B.sel.side==='player'&&B.side==='player'&&canUse(B.sel)) B.reach=markRamSpots(B.sel,bestFacingReach(B.sel,computeReach(B.sel))); else if(B) B.reach=null; }
function guard(u){ if(!u||u.side!=='player') return false; if(canUse(u)){ if(B.alt&&!u.isSq&&!B.activeUnit) B.activeUnit=u; return true; }
  fxText(u,u.activated?'Already activated':'Finish the active ship first','#f0b35a'); return false; }
function cancelAction(){ if(!B) return; if(B.mode) B.mode=null; else if(B.armed!=null) B.armed=null; else { B.sel=null; B.inspect=null; B.reach=null; } bRefresh(); }
async function act(fn){
  if(!B||B.busy) return; const b=B; B.busy=true; hideTip(); bRefresh();
  try{ await stallGuard(fn(),25000,'player',{sel:B.sel&&B.sel.name,mode:B.mode}); }catch(e){ console.error(e); }
  if(B!==b) return; // a late finish must never touch a newer battle
  B.busy=false; if(B.sel&&B.sel.dead) B.sel=null; updateReach(); bRefresh();
  if(B.over){ await endBattleFlow(); return; }
  if(B.alt&&B.activeUnit&&(B.activeUnit.dead||isDoneRaw(B.activeUnit))) await endActivation();
}
// v51 attack-move: tap an enemy your guns can't reach yet and the ship burns to the best hex for that shot and opens fire on the way
function attackMovePlan(s,t){ if(!B||!B.reach||!s||s.isSq||s.braced||t.dead) return null; let best=null;
  const idx=(B.armed!=null?[B.armed]:s.weapons.map((w,i)=>i)).filter(i=>{ const w=s.weapons[i]; return w.k!=='flak'&&weaponReady(w); }); if(!idx.length) return null;
  for(const st of B.reach.states){ if(st.q===s.q&&st.r===s.r) continue; const v=stateView(s,st); const n=idx.filter(i=>inReach(v,s.weapons[i],t)).length; if(!n) continue;
    const hx=(st.path||[]).filter(p=>!p.rot).length, sc=n*100-st.cost*3-(st.t||0)+(hx>=2?4:0); if(!best||sc>best.sc) best={st,n,sc,of:idx.length}; }
  return best; }
function firingSet(a,t){ const idx=B.armed!=null?[B.armed]:a.weapons.map((w,i)=>i); return idx.filter(i=>canFire(a,a.weapons[i],t)); }
async function onBoardClick(){
  if(!B||B.busy||B.side!=='player'||B.over||document.querySelector('.intro')) return;
  const h=B.hover; if(!h) return; const u=unitAt(h.q,h.r), s=B.sel;
  if(B.mode==='board'&&s){ if(u&&boardTargets(s).includes(u)&&guard(s)){ B.mode=null; await act(()=>boardUnit(s,u)); } else { B.mode=null; bRefresh(); } return; }
  if(B.mode==='blink'&&s){ if(blinkHexes(s).some(x=>x.q===h.q&&x.r===h.r)&&guard(s)){ B.mode=null; await act(()=>useAbility(s,{hex:h})); } else { B.mode=null; bRefresh(); } return; }
  if(B.mode==='nova'&&s){ if(novaTargets(s).some(x=>x.q===h.q&&x.r===h.r)&&guard(s)){ B.mode=null; await act(()=>useAbility(s,{hex:h})); } else { B.mode=null; bRefresh(); } return; }
  if(B.mode==='launch'&&s){ if(launchHexes(s).some(x=>x.q===h.q&&x.r===h.r)&&guard(s)){ const k=B.launchKind; B.mode=null; await act(()=>useAbility(s,{hex:h,kind:k})); } else { B.mode=null; bRefresh(); } return; }
  if(B.wingSel){ const w=B.wingSel; if(w.dead||!B.units.includes(w)) B.wingSel=null; else if(u&&u!==w&&!(u.side==='player'&&u.isSq)){ w.wingOrder={kind:u.side==='enemy'?'strike':'guard',id:u.id}; B.wingSel=null; try{ toast(u.side==='enemy'?`${w.name} will strike ${u.name} until it is destroyed.`:`${w.name} will guard ${u.name}, hitting anything that comes near it.`); }catch(e){} try{ tel('wing_order',{kind:w.wingOrder.kind,sq:w.t.sq,round:B.round}); }catch(e){} if(B.usage) B.usage.wingOrders=(B.usage.wingOrders||0)+1; bRefresh(); return; } else if(!u){ B.wingSel=null; bRefresh(); return; } }
  if(u&&u.side==='player'&&u.isSq){ B.wingSel=B.wingSel===u?null:u; try{ toast(B.wingSel?(u.wingOrder?'Wing selected (it has orders). Tap an enemy ship to strike, one of your ships to guard, or the wing again to cancel.':'Wing selected. Tap an enemy ship to strike it, or one of your ships to guard it.'):'Wing deselected.'); }catch(e){} bRefresh(); return; }
  if(u&&u.side==='player'){ selectUnit(u); return; }
  if(u&&u.side==='enemy'){ if(s&&s.side==='player'&&canUse(s)){ const set=firingSet(s,u); if(set.length){ guard(s); await act(async()=>{ const live=liveFrom(s); for(const i of set){ if(u.dead||s.dead||B.over||!live()) break; await fireWeapon(s,i,u); await wait(80); } }); if(B) B.armed=null; bRefresh(); return; } }
    if(s&&s.side==='player'&&canUse(s)){ const am=attackMovePlan(s,u); if(am&&guard(s)){ await act(()=>moveUnit(s,am.st,{onLate:async()=>{ const live=liveFrom(s); for(const i of firingSet(s,u)){ if(u.dead||s.dead||B.over||!live()) break; await fireWeapon(s,i,u); await wait(80); } }})); if(B) B.armed=null; bRefresh(); return; } }
    if(s&&s.side==='player'&&canUse(s)&&!(G.lastWhy&&G.lastWhy.id===u.id&&performance.now()-G.lastWhy.t<3000)){ const why=cantFireReason(s,u); G.lastWhy={id:u.id,t:performance.now()}; B.why=why; if(B.usage){ const cat=/braced/.test(why)?'braced':/already fired/.test(why)?'spent':/Out of range/.test(why)?'range':/points at it/.test(why)?'arc':/sight/.test(why)?'sight':'other'; B.usage.cant[cat]=(B.usage.cant[cat]||0)+1; } try{ toast(why); }catch(e){} clearTimeout(G.whyT); G.whyT=setTimeout(()=>{ if(B){ B.why=null; bRefresh(); } },7000); bRefresh(); return; }
    G.lastWhy=null; B.sel=null; B.inspect=u; B.armed=null; B.reach=null; bRefresh(); return; }
  if(s&&s.side==='player'&&B.reach){ const st=B.reach.map.get(hkey(h.q,h.r)); if(st&&guard(s)){ await act(()=>moveUnit(s,st)); return; } }
  if(B.inspect){ B.inspect=null; bRefresh(); }
}
// enemies a ship's guns would reach from a hex if nothing were in the way, but asteroids or wrecks block the shot
function blockedFrom(s,st){ try{ const v=stateView(s,st); return alive('enemy').filter(t=>!t.isSq&&s.weapons.some(w=>w.k!=='flak'&&hdist(v,t)<=w.r&&hdist(v,t)>=1&&inArc(v,t,w.arc))&&!los(v,t)); }catch(e){ return []; } }
// aim line: gold when the shot is clear, red to an X where an asteroid or wreck blocks it
function aimMat(key,col,a){ G.aimMats=G.aimMats||{}; let m=G.aimMats[key]; if(m&&!m.isDisposed?.()) return m; m=new BABYLON.StandardMaterial('aimM'+key,G.scene); m.disableLighting=true; m.emissiveColor=col; m.alpha=a; m.backFaceCulling=false; G.aimMats[key]=m; return m; }
function aimTube(name,pts,mat,rad){ const t=MB.CreateTube(name,{path:pts,radius:rad,tessellation:6,cap:BABYLON.Mesh.CAP_ALL},G.scene); t.material=mat; t.isPickable=false; t.renderingGroupId=1; OV.hover.push(t); return t; }
function aimLine(a,t){ try{ const line=hexLine(a,t); let cut=-1; for(let i=1;i<line.length-1;i++) if(sightBlocked(line[i].q,line[i].r)){ cut=i; break; }
    const R=HS*.07, from=hexWorld(a.q,a.r,1.6), to=hexWorld(t.q,t.r,1.6);
    if(cut<0){ aimTube('aim',[from,to],aimMat('ok',new C3(1,.82,.4),.85),R); return; }
    const red=aimMat('bad',new C3(1,.3,.25),.95), b=hexWorld(line[cut].q,line[cut].r,1.6); aimTube('aim',[from,b],red,R);
    const k=HS*.42; aimTube('aimX1',[b.add(new V3(-k,0,-k)),b.add(new V3(k,0,k))],red,R*1.4); aimTube('aimX2',[b.add(new V3(-k,0,k)),b.add(new V3(k,0,-k))],red,R*1.4);
    const dim=aimMat('dim',new C3(1,.35,.3),.35), d=to.subtract(b), L=d.length(), n=Math.max(2,Math.floor(L/(HS*.7))); for(let i=0;i<n;i+=2){ const p0=b.add(d.scale(i/n)), p1=b.add(d.scale(Math.min(1,(i+1)/n))); aimTube('aimR',[p0,p1],dim,R*.7); } }catch(e){ console.warn(e); } }
function boardTip(){
  const h=B.hover; if(!h||B.busy) return null; const u=unitAt(h.q,h.r), s=B.sel;
  if(B.mode==='nova'&&s){ if(!novaTargets(s).some(x=>x.q===h.q&&x.r===h.r)) return '<div class="h">Out of the nova cannon\u2019s arc</div><div class="muted">Pick a hex in the prow arc, 3 to 9 hexes away.</div>';
    const hit=alive().filter(x=>hdist(x,h)<=1); return `<div class="h">Nova impact</div><div>40 damage here, 20 to every adjacent hex.</div>${hit.length?`<div class="muted" style="margin-top:4px">Caught in the blast: ${hit.map(x=>`<span class="${x.side==='player'?'verd':'blood'}">${esc(x.name)}</span>`).join(', ')}</div>`:''}`; }
  if(B.mode==='board'&&s&&u&&boardTargets(s).includes(u)){ const o=boardOdds(s,u); return `<div class="h">Board ${esc(u.name)}</div><div class="num">Your ${s.crew} crew against their ${u.crew}. Expect to kill about ${o.kill} and lose about ${o.loss}.</div><div class="${o.capture?'ember':'muted'}" style="margin-top:4px">${o.chance>0?`${o.chance}% chance to capture: the ship joins your fleet.${o.chance<100?' Otherwise saboteurs may still knock out a system.':''}`:'No chance to capture this time, but saboteurs may knock out a system.'}</div>`; }
  if(u&&s&&s.side==='player'&&u.side==='enemy'&&B.side==='player') return attackTip(s,u);
  if(u) return unitTip(u);
  if(s&&s.side==='player'&&B.reach&&!B.mode){ const st=B.reach.map.get(hkey(h.q,h.r)); if(st) return `<div class="h">Move here</div><div class="num">${st.cost} movement${st.t?`, ${st.t} turn${st.t>1?'s':''}`:''}. ${s.mp-st.cost} movement left after.</div>${moveNote(st)}${objZone(st.q,st.r)==='exit'?'<div style="margin-top:4px;color:#7dff9b">Exit: this ship jumps clear and counts toward the breakthrough.</div>':''}${(()=>{ const tt=terr(st.q,st.r); return TERRAIN_INFO[tt]&&!blocks(tt)?`<div style="margin-top:4px;color:${TERRAIN_INFO[tt].col}">Ends in ${TERRAIN_INFO[tt].n.toLowerCase()}: ${TERRAIN_INFO[tt].fx}</div>`:''; })()}${st.guns!=null?`<div style="margin-top:4px">From here: <b class="gilt">${st.guns} of ${st.gunsOf}</b> ready guns can fire${st.gunTarget?` (on ${esc(st.gunTarget.isSq?st.gunTarget.t.n:st.gunTarget.name)})`:''}.</div>`:''}${(()=>{ const bl=blockedFrom(s,st); return bl.length?`<div style="margin-top:4px;color:#ff8a7a">Blocked from here by asteroids or wrecks: ${bl.map(x=>esc(x.name)).join(', ')}.</div>`:''; })()}${(()=>{ const rf=st.ram?ramFrom(s,st):null; if(!rf) return ''; const e=ramEstimate(Object.assign({},s,{q:st.q,r:st.r,facing:st.f}),rf.t,rf.path.length); return `<div style="margin-top:4px;color:#ff6b5a"><b>Ram spot:</b> from here your bow points at ${esc(rf.t.name)}. Move, then tap Ram for about ${e.dmg} damage.</div>`; })()}`; }
  if(B.showThreat){ const v=computeThreatAt(h); if(v) return `<div class="h blood">Enemy threat</div><div class="num">Up to about ${Math.round(v)} damage could reach this hex next turn, before shields and armor.</div>`; }
  { const z=objZone(h.q,h.r); if(z&&!terr(h.q,h.r)) return `<div class="h" style="color:${ZONE_INFO[z].col}">${ZONE_INFO[z].n}</div><div class="muted">${ZONE_INFO[z].fx}</div>`; }
  const t=terr(h.q,h.r); if(TERRAIN_INFO[t]) return `<div class="h" style="color:${TERRAIN_INFO[t].col}">${TERRAIN_INFO[t].n}</div><div class="muted">${TERRAIN_INFO[t].fx}</div>`;
  return null;
}
// v50: thruster rules for this hull, and how its last move affects incoming fire
function driveLine(u){ if(!u||u.isSq) return ''; const R=moveRules(u), M=MOVE_RULES[u.fac]; const mv=u.hexMoved==null?'':u.hexMoved===0?` <span class="blood">Has not moved: enemies get +${R.still} to hit.</span>`:u.hexMoved>=R.evadeAt?` <span class="verd">Evasive: enemies get \u2212${R.evade} to hit.</span>`:'';
  return `<div class="muted" style="font-size:12.5px;margin-top:5px">Thrusters: sideslip ${R.slip}, back off ${R.rev}, pass over or under ${R.over?'+'+R.over:'free'}.${M?` <b class="gilt">${esc(M.n)}</b>: ${esc(M.d)}`:''}${mv}</div>`; }
function moveNote(st){ const p=st.path||[], n=k=>p.filter(x=>x[k]).length, bits=[]; const sl=n('slip'), rv=n('rev'), up=p.filter(x=>x.over>0).length, dn=p.filter(x=>x.over<0).length;
  if(sl) bits.push(`sideslips ${sl>1?sl+' times':'once'}`); if(rv) bits.push(`backs off ${rv>1?rv+' hexes':'a hex'}`); if(up) bits.push(`climbs over ${up>1?up+' obstacles':'an obstacle'}`); if(dn) bits.push(`dives under ${dn>1?dn+' ships':'a ship'}`);
  return bits.length?`<div style="margin-top:4px;color:#9fd0ff">Thrusters: ${bits.join(', ')}, heading held.</div>`:''; }
function motionNote(a,t){ const m=motionHit(t), out=[]; if(m>0) out.push(`<span class="ember">Sitting still: +${m} to hit.</span>`); else if(m<0) out.push(`<span class="muted">Burning evasive: \u2212${-m} to hit.</span>`);
  const rk=a.weapons.some(w=>weaponReady(w)&&rakeBonus(a,w)>0); if(rk) out.push(`<span class="gilt">Raking pass: broadsides +${Math.round(moveRules(a).rake*100)}%.</span>`); return out.length?' '+out.join(' '):''; }
function unitTip(u){ return `<div class="h ${u.side==='player'?'verd':'blood'}">${esc(u.isSq?u.t.n:u.name)}</div><div class="muted">${esc(u.t.n)}${u.elite?', elite':''}</div>
  <div class="num">Hull ${Math.max(0,u.hp)}/${u.maxHp}${u.shMax?`. Shields: prow ${Math.round(u.sh[0])}, port ${Math.round(u.sh[3])}, starboard ${Math.round(u.sh[1])}, rear ${Math.round(u.sh[2])}`:''}.</div><div class="dim">Armor ${pct(u.armor)}, evasion ${u.ev+(u.evBuff||0)}, speed ${u.speed}</div>${u.sec?`<div class="dim num">Prow ${u.sec.prow.hp}, midships ${u.sec.mid.hp}, engines ${u.sec.eng.hp}. Crew ${u.crew}/${u.crewMax}.</div>`:''}`; }
// which boons and aspect bonuses apply to this shot, so the player sees them working
function boonMods(a,t){ if(!a||a.side!=='player'||typeof RUN==='undefined'||!RUN) return []; const f=a.fx||{}, out=[], quad=shieldQuad(t,a), ready=a.weapons.filter(weaponReady), pctS=x=>Math.round(x*100)+'%';
  const add=(id,txt)=>{ const b=BOONS[id], P=b&&(b.p?PATRONS[b.p]:PATRONS[b.duo[0]]); out.push(`<span style="color:${P?P.col:'#f0b35a'}">${esc(b?b.n:id)}</span> ${txt}`); };
  if(hasBoon('i_still')&&!a.hexMoved&&ready.some(w=>w.arc==='P'||w.arc==='S'||w.k==='battery')) add('i_still',`+${pctS(f.stillPct)} (held still)`);
  if(hasBoon('r_mom')&&a.hexMoved) add('r_mom',`+${pctS(Math.min(4,a.hexMoved)*f.momPct)} (moved ${a.hexMoved})`);
  if(hasBoon('i_broad')&&ready.some(w=>w.arc==='P'||w.arc==='S')) add('i_broad','broadsides hit harder');
  if(hasBoon('a_lance')&&ready.some(w=>w.k==='lance')) add('a_lance','lances hit harder');
  if(hasBoon('e_war')&&ready.some(w=>w.k==='torp')) add('e_war','torpedoes hit harder');
  if(hasBoon('e_hunt')&&t.hp<t.maxHp/2) add('e_hunt','target below half hull');
  if(hasBoon('a_rear')&&quad===2) add('a_rear','rear-arc shot');
  if(hasBoon('s_ion')&&t.shMax>0&&t.sh[quad]>0) add('s_ion','strips extra shield');
  if(hasBoon('s_arc')&&t.shMax>0&&t.sh[quad]>0) add('s_arc','shorts the generator if this breaks the shield');
  if(hasBoon('e_kindle')) add('e_kindle',`${pctS(f.igniteCh||0)} fire chance per hull hit`);
  if(hasBoon('e_chain')) add('e_chain','a kill blasts its neighbours');
  if(hasBoon('a_crit')) add('a_crit','harder criticals');
  if(RUN.aspect==='lancer'&&a.pflag&&ready.some(w=>w.arc==='F')) out.push(`<span class="gilt">Aspect of the Spear</span> forward guns +50%`);
  return out; }
function attackTip(a,t){
  const quad=shieldQuad(t,a), rear=quad===2, idx=B.armed!=null?[B.armed]:a.weapons.map((w,i)=>i); let rows='',hull=0,sh=0,n=0;
  for(const i of idx){ const w=a.weapons[i]; let right;
    if(w.off>0) right='<span class="blood">offline</span>'; else if(w.cdLeft>0) right='<span class="dim">reloading</span>'; else if(w.fired) right='<span class="dim">fired</span>'; else if(a.braced) right='<span class="dim">braced</span>';
    else { const d=hdist(a,t); if(d>w.r) right=`<span class="dim">out of range (${d}/${w.r})</span>`; else if(!inArc(a,t,w.arc)) right='<span class="dim">out of arc</span>'; else if(!los(a,t)) right='<span class="dim">blocked</span>';
      else { const e=expectedVs(a,w,t); hull+=e.hull; sh+=e.shield; n++; right=`<b>${hitChance(a,w,t)}%</b> <span class="dim">${w.shots}\u00d7${Math.round(dmgMult(a,w,t,rear))}</span>`; } }
    rows+=`<tr><td>${esc(w.n)}${(w.evMult||1)>1?` <span class="dim">(slow: evasion counts ${w.evMult}x)</span>`:''}</td><td class="r">${right}</td></tr>`; }
  return `<div class="h blood">${esc(t.isSq?t.t.n:t.name)}</div><div class="muted num">Hull ${t.hp}/${t.maxHp}, armor ${pct(t.armor)}, evasion ${t.ev+(t.evBuff||0)}</div>
    <div style="margin:4px 0">${t.shMax?`Hits the <b class="shv">${QUAD_NAME[quad]} shield</b> <span class="shv">(${Math.round(t.sh[quad])}/${t.shMax})</span>${t.sh[quad]<1?' <span class="hlv">down, straight to hull</span>':''}.`:'Target is unshielded: <span class="hlv">every hit lands on the hull</span>.'}${rear?' <span class="ember">Rear arc: armor halved, +15% crit.</span>':''}${motionNote(a,t)}${terr(t.q,t.r)==='neb'?' <span class="muted">In nebula, \u221215 to hit.</span>':terr(t.q,t.r)==='debris'?' <span class="muted">In debris, \u221210 to hit.</span>':''}${terr(a.q,a.r)==='storm'?' <span class="muted">You are in an ion storm, \u221210 to hit.</span>':''}</div>
    ${t.sec?`<div class="muted">Hull damage lands on the <b>${SEC_NAME[SEC_OF_QUAD[quad]]}</b>. Crew ${t.crew}/${t.crewMax}.</div>`:''}<table>${rows}</table>${n?`<div style="margin-top:5px" class="num">Expected: about <span class="shv">${Math.round(sh)} shield</span> and <span class="hlv">${Math.round(hull)} hull</span> damage.${hull>=t.hp?' <span class="ember">Likely kill.</span>':''}</div>${(()=>{ const bm=boonMods(a,t); return bm.length?`<div style="margin-top:4px;font-size:12.5px">${bm.join('<br>')}</div>`:''; })()}<div class="gilt" style="margin-top:3px">Click to fire ${n} weapon${n>1?'s':''}.</div>`:(()=>{ const am=a.side==='player'&&canUse(a)?attackMovePlan(a,t):null; return am?`<div class="gilt" style="margin-top:5px">Click to burn ${am.st.cost} movement into position and fire ${am.n} weapon${am.n>1?'s':''} on the way.</div>`:'<div class="dim" style="margin-top:5px">No ready weapon can reach this target.</div>'; })()}`;
}
function onKey(e){
  if(!B||e.target.tagName==='INPUT'||document.body.classList.contains('app-on')) return; const k=e.key.toLowerCase();
  if(document.querySelector('.intro')) return;
  if(k==='v'){ B.showArcs=!B.showArcs; bRefresh(); return; }
  if(k==='r'){ ACT.threat(); return; }
  if(k==='t'){ G.ctl.toggleTop(); refreshTop(); return; }
  if(k==='home'){ G.ctl.reset(); return; }
  if(k===' '){ e.preventDefault(); ACT.speed(); return; }
  if(k==='f'){ const u=B.sel||B.inspect; if(u) G.ctl.focus(uWorld(u),Math.min(G.ctl.r,150)); return; }
  if(B.busy||B.side!=='player'||B.over) return;
  if(k==='tab'){ e.preventDefault(); nextShip(e.shiftKey?-1:1); return; }
  if(k==='enter'){ e.preventDefault(); ACT.endTurn(); return; }
  if(k==='escape'){ cancelAction(); return; }
  const s=B.sel; if(!s||s.side!=='player') return;
  if(k==='x'){ ACT.ram(); return; }
  if(k==='g'){ ACT.board(); return; }
  if(k==='q'){ if(guard(s)) act(()=>rotateUnit(s,-1)); } else if(k==='e'){ if(guard(s)) act(()=>rotateUnit(s,1)); }
  else if(k==='b'){ if(canOrder(s,'brace')&&guard(s)) act(()=>giveOrder(s,'brace')); }
  else if(/^[1-6]$/.test(k)) ACT.arm(+k-1);
}
function nextShip(dir=1){ const list=alive('player'); if(!list.length) return; const ready=list.filter(u=>!isDone(u)); const pool=ready.length?ready:list; let i=pool.indexOf(B.sel); i=(i+dir+pool.length)%pool.length; if(i<0) i=0; selectUnit(pool[i]); G.ctl.focus(uWorld(pool[i])); }
ACT.arm=i=>{ const s=B&&B.sel; if(!s||s.side!=='player'||B.busy) return; const w=s.weapons[+i]; if(!w||!weaponReady(w)) return; B.armed=B.armed===+i?null:+i; B.mode=null; bRefresh(); };
ACT.rot=d=>{ if(B&&B.sel&&guard(B.sel)) act(()=>rotateUnit(B.sel,+d)); };
ACT.ram=()=>{ const s=B&&B.sel; if(!s||B.busy||!ramInfo(s)||!guard(s)) return; act(()=>ramUnit(s)); };
ACT.board=()=>{ const s=B&&B.sel; if(!s||B.busy||!boardTargets(s).length||!canUse(s)) return; B.mode=B.mode==='board'?null:'board'; B.armed=null; bRefresh(); };
ACT.fxmode=()=>{ G.fxReduced=!G.fxReduced; try{ META.opts=META.opts||{}; META.opts.fxReduced=G.fxReduced; META.opts.fxSet=true; Persist.saveLocal(); }catch(e){} setQuality(G.quality); refreshTop(); };
ACT.quality=()=>{ const o=['ultra','high','medium']; setQuality(o[(o.indexOf(G.quality)+1)%3]); refreshTop(); saveOpts(); };
ACT.threat=()=>{ B.showThreat=!B.showThreat; bRefresh(); };
ACT.ability=()=>{ const u=B&&B.sel; if(!u||!canAbility(u)||B.busy||!canUse(u)) return; if(u.ab==='launch'){ if(u.fac!=='voidsworn'){ quickLaunch(u,wingKind(u)); return; } B.mode='launchPick'; B.armed=null; bRefresh(); return; } if(u.ab==='blink'){ B.mode='blink'; B.armed=null; bRefresh(); return; } if(u.ab==='nova'){ B.mode='nova'; B.armed=null; bRefresh(); return; } if(guard(u)) act(()=>useAbility(u)); };
ACT.launchKind=k=>{ const s=B&&B.sel; B.mode=null; if(s) quickLaunch(s,k); };
// one tap: launch from the hex nearest the enemy; the wing acts from next round
function quickLaunch(u,k){ if(!u||!canAbility(u)||B.busy||!canUse(u)) return; const foes=alive('enemy'); const hs=launchHexes(u).sort((a,b)=>Math.min(...foes.map(f=>hdist(a,f)))-Math.min(...foes.map(f=>hdist(b,f)))); if(!hs.length){ try{ toast('No open hex next to the carrier to launch from.'); }catch(e){} return; } if(guard(u)) act(()=>useAbility(u,{hex:hs[0],kind:k})); }
ACT.follow=()=>{ G.follow=!G.follow; refreshTop(); saveOpts(); };
ACT.sheet=()=>{ document.body.classList.toggle('sheetmin'); refreshPanel(); };
ACT.taa=()=>{ G.taaOn=!G.taaOn; setQuality(G.quality); saveOpts(); refreshTop(); };
ACT.aiLevel=()=>{ AI_LEVEL=AI_LEVEL==='veteran'?'standard':'veteran'; saveOpts(); refreshTop(); };
ACT.fleetToggle=()=>document.body.classList.toggle('showroster');
ACT.logToggle=()=>{ const on=document.body.classList.toggle('showlog'); const b=document.getElementById('b_log'); if(b) b.classList.toggle('on',on); const el=document.getElementById('log'); if(el) el.scrollTop=el.scrollHeight; };
ACT.settings=()=>{ document.getElementById('setpanel').classList.toggle('hidden'); };
function saveOpts(){ try{ META.opts=Object.assign(META.opts||{},{aiHulls:G.aiHulls!==false,cineMode:G.cine?(G.cineMode||'key'):'off',cine2:G.cine,follow:G.follow,taa:!!G.taaOn,ai:AI_LEVEL,quality:G.quality,fxReduced:G.fxReduced,sfxOn:G.sfxOn,cine:G.cine,alt:SETUP.alt,fast:SPEED<1}); Persist.saveLocal(); }catch(e){} }
ACT.arcs=()=>{ B.showArcs=!B.showArcs; bRefresh(); };
ACT.aihull=()=>{ G.aiHulls=G.aiHulls===false; for(const k of Object.keys(AI_HULL_DATA)) delete MODEL_CACHE[k]; refreshTop(); saveOpts(); toast(G.aiHulls?'Concept-art hulls on from the next battle':'Concept-art hulls off from the next battle'); };
ACT.cine=()=>{ const order=['key','all','off'], m=G.cine?(G.cineMode||'key'):'off'; G.cineMode=order[(order.indexOf(m)+1)%3]; G.cine=G.cineMode!=='off'; if(!G.cine) G.ctl.release(); refreshTop(); saveOpts(); toast(G.cineMode==='off'?'Cut-ins off':G.cineMode==='all'?'Cut-ins on every attack (tap to skip)':'Cut-ins on key moments (tap to skip)'); };
ACT.top=()=>{ G.ctl.toggleTop(); refreshTop(); };
ACT.sound=()=>{ SFX.init(); SFX.setOn(!G.sfxOn); refreshTop(); saveOpts(); };
ACT.speed=()=>{ SPEED=SPEED<1?1:.45; refreshTop(); saveOpts(); };
ACT.endTurn=()=>{ if(B&&B.alt) endActivation(true); else endTurn(); };
ACT.restart=()=>{ if(B&&B.busy&&!B.over) return; hideEnd(); setupBattle(); G.ctl.reset(); const f=caps('player')[0]; if(f) selectUnit(f); banner(B.alt?'Round 1':'Your turn'); };

// ---------- turn flow ----------
async function banner(text,color){ const el=document.getElementById('banner'); el.textContent=text; el.style.color=color||'var(--bone)'; el.classList.add('show'); await wait(520); el.classList.remove('show'); await wait(140); }
async function endTurn(){
  if(!B||B.busy||B.side!=='player'||B.over) return;
  B.busy=true; B.sel=null; B.armed=null; B.mode=null; B.inspect=null; B.reach=null; hideTip(); G.playerView={a:G.ctl.a,b:G.ctl.b,r:G.ctl.r,t:G.ctl.t.clone(),at:performance.now()};
  B.side='enemy'; const dq=startSideTurn('enemy'); bRefresh(); await Promise.all([dq,banner('Enemy turn','#e07a70')]); // v53: burn-outs and other tick deaths finish before the AI moves
  { const sp=SPEED; SPEED=Math.min(SPEED,.65); try{ if(await stallGuard(aiTurn(),90000,'enemy_turn',{})==='stall') log('Enemy orders lost in interference.','x'); }catch(e){ console.error(e); } SPEED=sp; } // v41: Classic mode gets the same stall net as Alternating
  if(!B) return; B.aiActive=null; G.lastAi=null;
  await wait(150); G.ctl.release();
  if(B.over){ B.busy=false; await endBattleFlow(); return; }
  if(G.playerView&&!((G.camMoved||0)>(G.playerView.at||0))){ G.ctl.t=G.playerView.t.clone(); G.ctl.r=G.playerView.r; G.ctl.a=G.playerView.a; G.ctl.b=G.playerView.b; }
  B.round++; B.side='player'; const dq2=startSideTurn('player'); if(dq2) await dq2; if(!B) return; if(B.over){ B.busy=false; bRefresh(); return; } log(`Round ${B.round}.`,'x'); try{ await swarmGuard('player'); }catch(e){ console.error(e); } finally{ B.busy=false; } bRefresh(); if(!B||B.over) return;
  await banner('Your turn'); if(B&&!B.sel){ const f=caps('player').find(u=>!isDone(u))||caps('player')[0]; if(f) selectUnit(f); }
}
function isDoneRaw(u){ if(u.dead||u.braced) return true; return !(u.mp>0) && !u.weapons.some(w=>weaponReady(w)&&alive('enemy').some(t=>canFire(u,w,t))); }
async function endActivation(manual){
  if(!B||B.over||B.side!=='player'||(B.busy&&manual)) return;
  if(B.activeUnit){ B.activeUnit.activated=true; B.activeUnit=null; }
  else if(manual&&B.sel&&B.sel.side==='player'&&!B.sel.isSq&&!B.sel.activated){ B.sel.activated=true; log(`${B.sel.name} holds position.`,'x'); }
  B.sel=null; B.reach=null; B.armed=null; B.mode=null; hideTip();
  await aiStep();
}
async function aiStep(){
  if(!B||B.over) return; const b=B; // leftover turn logic from an earlier battle must never touch this one
  const pe=pendingE(), pp=pendingP();
  if(pe.length){
    B.busy=true; B.side='enemy'; const sp=SPEED;
    try{ camKeep(); bRefresh(); // v41: a failed refresh here used to leave the enemy side active with nothing to run it
      const sqs=alive('enemy').filter(u=>u.isSq&&!u.activated);
      const batch=pp.length?[aiPickActivation(pe.sort((a,b)=>b.speed-a.speed))]:pe;
      SPEED=Math.min(SPEED,.65);
      for(const u of [...sqs,...batch]){ if(B!==b||B.over) break; if(await stallGuard(aiUnit(u),30000,'enemy',{name:u.name,isSq:!!u.isSq})==='stall'&&B===b) log(`${u.isSq?u.t.n:u.name}: orders lost in interference.`,'x'); u.activated=true; } }catch(e){ console.error(e); }
    finally{ SPEED=sp; }
    if(B!==b) return; B.aiActive=null; G.lastAi=null; await wait(120); if(B!==b) return; G.ctl.release(); camRestore(); B.side='player'; B.busy=false;
    if(B.over){ bRefresh(); await endBattleFlow(); return; }
  }
  if(B!==b) return;
  if(!pendingP().length && !pendingE().length){ await nextRound(); return; }
  if(!pendingP().length){ await aiStep(); return; }
  bRefresh(); const f=pendingP()[0]; if(f&&!B.sel){ selectUnit(f); camShow(f); }
}
// v53: the squadron phase under the same stall net as the AI turn (each wing also has its own guard inside swarmPhase)
async function swarmGuard(side){ if(await stallGuard(swarmPhase(side),60000,'swarm',{side})==='stall') log((side==='player'?'Your':'Enemy')+' squadron orders lost in interference.','x'); }
async function nextRound(){
  if(!B||B.over) return; const b=B;
  B.round++; for(const x of B.units) x.activated=false; B.activeUnit=null;
  B.busy=true; const d1=startSideTurn('player'), d2=B.over?null:startSideTurn('enemy'); if(d1) await d1; if(d2) await d2; if(B!==b) return; if(B.over){ B.busy=false; bRefresh(); return; } // the relay can be decided right here; v53: tick deaths finish first, under busy
  log(`Round ${B.round}.`,'x'); B.busy=true; bRefresh(); try{ await swarmGuard('player'); if(B===b&&!B.over) await swarmGuard('enemy'); }catch(e){ console.error(e); } finally{ if(B===b) B.busy=false; } if(B!==b||B.over) return; bRefresh();
  await banner(`Round ${B.round}`); if(B!==b||B.over) return; const f=pendingP()[0]; if(f) selectUnit(f);
}
async function endBattleFlow(){
  if(!B||B.ending) return; const b=B; B.ending=true; const win=B.over==='win'; clearTimeout(G.cineTimer); G.ctl.release(); bRefresh();
  const ttl=B.partial?'They got away':win?'Victory':B.withdraw&&survivorsP()?'Withdrawal':'Defeat';
  SFX.sting(win); await banner(ttl,win?'#d0a64b':'#e07a70'); if(B!==b) return;
  const caps=B.units.filter(u=>u.captured&&u.side==='player'&&!u.dead).length;
  const lost=B.units.filter(u=>u.side==='player'&&u.dead&&!u.exited&&!u.isSq).map(u=>u.name), kills=B.units.filter(u=>u.side==='enemy'&&u.dead&&!u.fled&&!u.isSq).length;

  const el=document.createElement('div'); el.className='hud endcard'; el.id='endcard';
  el.innerHTML=`<h2>${ttl}</h2>${B.partial?'<p class="muted">Objective missed: half pay for this fight.</p>':''}<p class="muted num">${kills} ${esc(String((FACTIONS[(B.cfg&&B.cfg.fac)||(alive('enemy')[0]||B.units.find(x=>x.side==='enemy')||{}).fac]||{}).n||'enemy').replace(/^The /,''))} ship${kills===1?'':'s'} destroyed in ${B.round} round${B.round===1?'':'s'}.${lost.length?` Lost: ${lost.map(esc).join(', ')}.`:' No ships lost.'}${caps?` Captured ${caps} ship${caps>1?'s':''}.`:''}</p>
    <div class="row" style="justify-content:center;margin-top:16px">${B.campaign?'<button class="primary" data-act="c3continue">Continue the campaign</button>':'<button class="primary" data-act="restart">Fight again</button><button data-act="changeSetup">Change factions</button><button data-act="c3title">Main menu</button>'}</div>`;
  document.getElementById('stage').appendChild(el);
}
function hideEnd(){ const e=document.getElementById('endcard'); if(e) e.remove(); }
ACT.changeSetup=()=>{ hideEnd(); setupBattle(); showIntro(); G.ctl.attract=true; };

// ---------- intro ----------
function showIntro(){
  const old=document.querySelector('.intro'); if(old) old.remove();
  const el=document.createElement('div'); el.className='intro';
  const facBtns=(key)=>PLAYABLE.map(f=>`<button class="${SETUP[key]===f?'sel':''}" data-act="pick" data-arg="${key}:${f}">${esc(FACTIONS[f].n)}</button>`).join('');
  const blurb=f=>esc((FACTIONS[f].blurb||'').split('.')[0]+'.');
  el.innerHTML=`<div class="ibox"><h1>Voidsworn</h1><div class="sub">3D skirmish</div>
    <div class="pickh">Your fleet</div><div class="facs">${facBtns('pf')}</div><p class="fb">${blurb(SETUP.pf)}</p>
    <div class="pickh">Opponent</div><div class="facs">${facBtns('ef')}</div><p class="fb">${blurb(SETUP.ef)}</p>
    <div class="pickh">Engagement</div><div class="facs"><button class="${SETUP.mode==='sk'?'sel':''}" data-act="pick" data-arg="mode:sk">Skirmish<small>Equal fleets of about 16 points</small></button><button class="${SETUP.mode==='fl'?'sel':''}" data-act="pick" data-arg="mode:fl">Flagship battle<small>Both sides bring their titan</small></button></div>
    <div class="pickh">Battlefield</div><div class="facs">${MAPS.map(([k,n])=>`<button class="${SETUP.map===k?'sel':''}" data-act="pick" data-arg="map:${k}">${n}</button>`).join('')}</div>
    <div class="pickh">Deployment</div><div class="facs">${DEPS.map(([k,n])=>`<button class="${SETUP.dep===k?'sel':''}" data-act="pick" data-arg="dep:${k}">${n}</button>`).join('')}</div>
    <div class="pickh">Encounter</div><div class="facs">${OBJS.map(([k,n])=>`<button class="${SETUP.obj===k?'sel':''}" data-act="pick" data-arg="obj:${k}">${n}</button>`).join('')}</div>
    <div class="pickh">Arena</div><div class="facs">${ARENA_OPTS.map(([k,n])=>`<button class="${(SETUP.arena||'random')===k?'sel':''}" data-act="pick" data-arg="arena:${k}">${n}</button>`).join('')}</div>
    <div class="pickh">Board</div><div class="facs">${SHAPE_OPTS.map(([k,n])=>`<button class="${(SETUP.shape||'random')===k?'sel':''}" data-act="pick" data-arg="shape:${k}">${n}</button>`).join('')}</div>
    <div class="pickh">Turn order</div><div class="facs"><button class="${SETUP.alt?'sel':''}" data-act="pick" data-arg="alt:1">Alternating<small>One ship each, back and forth</small></button><button class="${!SETUP.alt?'sel':''}" data-act="pick" data-arg="alt:0">Classic<small>Whole fleet moves, then theirs</small></button></div>
    <div class="row" style="margin-top:16px"><button class="primary" style="font-size:17px;padding:10px 22px" data-act="begin">Begin engagement</button><button data-act="c3title">Back to title</button></div>
    <div class="ctrls"><kbd>Right-drag</kbd> orbit, <kbd>Left-drag</kbd> or <kbd>WASD</kbd> pan, <kbd>Wheel</kbd> zoom, <kbd>T</kbd> top-down, <kbd>R</kbd> threat map, <kbd>X</kbd> ram, <kbd>G</kbd> board.</div></div>`;
  document.getElementById('stage').appendChild(el); document.body.classList.add('intro-on');
}
ACT.pick=arg=>{ const [k,v]=arg.split(':'); const nv=k==='alt'?v==='1':v; if(SETUP[k]===nv) return; setupBattle({[k]:nv}); showIntro(); };
ACT.begin=()=>{ SFX.init(); document.querySelector('.intro').remove(); document.body.classList.remove('intro-on'); G.ctl.attract=false; G.ctl.establish(); const f=caps('player')[0]; if(f) selectUnit(f); refreshTop(); banner(B.alt?'Round 1':'Your turn'); };

// ---------- onboarding: one tip at a time, each shown once ----------
const TIPS=[
  ['start','Your fleet','Select one of your ships: it has a green ring underneath. Gold hexes show where it can move, and the fans show its firing arcs.'],
  ['select','Moving and facing','Hover a gold hex to preview the move: the ghost shows where you will end up and which way you will face. Q and E turn in place.'],
  ['move','Shields and hull','Cyan is shields: four facings that soak hits and recharge each turn. Amber is hull: damage that stays. Keep your strongest shield facing the enemy.'],
  ['target','Firing','Enemies you can hit have a pulsing red ring. Hover one for hit odds and expected damage, then click to fire every weapon that bears. Keys 1 to 6 pick a single weapon.'],
  ['fired','Alternating activations','Each ship acts once per round. When this ship is done, press End activation (Enter) and the enemy moves one of theirs.'],
  ['resolve','Admiral\'s Command','Your admiral\'s signature move is ready: it glows gold on the strip. You get it once per battle. It grows each round you wait and when you lose a ship, so pick your moment.'],
  ['close','Close action','Ramming speed (X) charges the first enemy dead ahead. Boarding (G) sends crews into an adjacent enemy; win and the ship is yours.'],
  ['objective','Objectives','Not every fight is a slugging match. The top bar shows this fight\u2019s goal; tap the map chip under it for the full rules and what the coloured hexes mean.'],
];
function tutorialCheck(){ try{ if(!B||B.showcase||B.over||document.body.classList.contains('app-on')||document.querySelector('.intro')) return; const o=META.opts=META.opts||{}; if(o.tipsOff) return; o.tips=o.tips||{};
  if(document.getElementById('tipcard')) return; const s=B.sel, me=alive('player');
  const cond={start:true, select:!!s, move:me.some(x=>!x.isSq&&x.mp<x.speed), target:OV.targets&&OV.targets.length>0, fired:me.some(x=>x.weapons.some(w=>w.fired)),
    resolve:canCommand('player'), close:!!s&&!s.isSq&&(!!ramInfo(s)||boardTargets(s).length>0), objective:B.obj&&B.obj.type!=='rout'};
  const t=TIPS.find(([id])=>!o.tips[id]&&cond[id]); if(!t) return;
  const el=document.createElement('div'); el.id='tipcard'; el.className='hud tipcard'; el.innerHTML=touchWords(`<h4>${t[1]}</h4><p>${t[2]}</p><div class="row"><button class="primary" data-act="tipOk" data-arg="${t[0]}">Got it</button><button data-act="tipOff">Hide tips</button></div>`);
  document.getElementById('stage').appendChild(el); stackTop(); }catch(e){} }
ACT.tipOk=id=>{ const o=META.opts=META.opts||{}; o.tips=o.tips||{}; o.tips[id]=1; try{ Persist.saveLocal(); }catch(e){} const el=document.getElementById('tipcard'); if(el) el.remove(); setTimeout(tutorialCheck,400); };
ACT.tipOff=()=>{ const o=META.opts=META.opts||{}; o.tipsOff=true; try{ Persist.saveLocal(); }catch(e){} const el=document.getElementById('tipcard'); if(el) el.remove(); };

const AIM_NAME={'':'Anywhere',prow:'Prow',mid:'Midships',eng:'Engines'};
function actionStrip(u){ if(!u||u.dead||u.side!=='player'||u.isSq||!B||B.over||B.side!=='player') return ''; const use=canUse(u)&&!B.busy;
  const btn=(act,arg,label,on,cls='')=>`<button class="${cls}" ${on?'':'disabled'} data-act="${act}" ${arg?`data-arg="${arg}"`:''}>${label}</button>`;
  const res=B.resolve.player||0, ri=ramInfo(u), bt=boardTargets(u), A=u.ab?ABILITIES[u.ab]:null, moved=u.mp<u.speed, canHit=OV.targets&&OV.targets.length>0;
  const ramSpots=!ri&&use&&B.reach?[...B.reach.map.values()].some(s=>s.ram):false;
  const hint=B.wingSel&&!B.wingSel.dead?'Wing selected: tap an enemy ship to strike it, or one of your ships to guard it. Tap the wing again to cancel.':B.why?B.why:B.mode?'Tap a hex to place your ability, or tap the ship again to cancel.':!use?'This ship has acted. Pick another ship, or wait for your turn.':ri?`Ram ready: ${esc(ri.t.name)} is dead ahead (red lane). Tap Ram, or move and fire instead.`:ramSpots?'Red-ringed gold hexes line up a ram. Move there, then tap Ram.':canHit&&!moved?'Tap a gold hex to move, or a red-ringed enemy to fire.':canHit?'Tap a red-ringed enemy to fire.':!moved?'Tap a gold hex to move. Nothing is in range yet.':'Nothing left to do: tap Done with ship.';
  return `<div class="striphint">${touchWords(hint)}</div><div class="actstrip">${btn('endTurn','','Done with ship',use,'primary')}${A&&u.ab==='launch'&&u.fac==='voidsworn'?btn('launchKind','fighter','Launch fighters'+(u.spare!=null?` <span class="dim">(${u.spare} spare)</span>`:''),use&&canAbility(u),'abil')+btn('launchKind','bomber','Launch bombers',use&&canAbility(u),'abil'):A?btn('ability','',(u.ab==='launch'?esc('Launch '+HULLS[wingKind(u)].n.toLowerCase()):esc(A.n))+(u.ab==='launch'&&u.spare!=null?` <span class="dim">(${u.spare} spare)</span>`:''),use&&canAbility(u)&&!B.mode,'abil'):''}${(()=>{ const c=commandFor('player'); return c&&!B.cmdUsed?btn('command','',`${B.cmdArm?`Tap again (${Math.max(1,Math.ceil(((G.cmdConfirmMs||6000)-(performance.now()-B.cmdArm))/1000))}s): `:''}${esc(c.n)}${canCommand('player')?` <span class="gilt">${'\u25CF'.repeat(cmdTier()+1)}${'\u25CB'.repeat(2-cmdTier())}</span>`:' <span class="dim">(used)</span>'}`,use&&canCommand('player'),'cmd'):''; })()}${ri?btn('ram','',`Ram <span class="dim">(~${ramEstimate(u,ri.t,ri.path.length).dmg})</span>`,use,'abil'):''}${bt.length?btn('board','',`Board <span class="dim">(${captureChance(u,bt[0])}% capture)</span>`,use):''}${btn('brace','','Brace',use&&canOrder(u,'brace'))}${btn('center','','Center',true)}${btn('stripHelp','','?',true)}</div>`; }
ACT.command=()=>{ if(!B||B.busy||B.side!=='player'||!canCommand('player')) return; const now=performance.now(), win=G.cmdConfirmMs||6000; if(!(B.cmdArm&&now-B.cmdArm<win)){ B.cmdArm=now; bRefresh(); clearInterval(G.cmdTick); G.cmdTick=setInterval(()=>{ if(!B||B.cmdArm!==now){ clearInterval(G.cmdTick); return; } bRefresh(); },1000); /* v45: visible countdown, 6 s window */ setTimeout(()=>{ if(B&&B.cmdArm===now){ B.cmdArm=0; bRefresh(); } },win); return; } B.cmdArm=0; act(()=>useCommand('player')); }; // v41: once per battle, so it takes a confirming second tap
// strip buttons call actions directly (synthetic key presses went through extra keyboard gates)
ACT.brace=()=>{ const s=B&&B.sel; if(!s||B.busy||B.over||B.side!=='player') return; if(canOrder(s,'brace')&&guard(s)) act(()=>giveOrder(s,'brace')); };
// ---------- a calm camera: never zoom on its own, only pan when something important is off screen, and hand your view back ----------
function onScreenW(p){ try{ const eng=G.engine, w=eng.getRenderWidth(), h=eng.getRenderHeight(), v=BABYLON.Vector3.Project(p,BABYLON.Matrix.Identity(),G.scene.getTransformMatrix(),G.ctl.cam.viewport.toGlobal(w,h));
  const sx=v.x/w, sy=v.y/h, top=G.mobile?.12:.08, bot=G.mobile?(document.body.classList.contains('sheetmin')?.24:.5):.1; return v.z>0&&v.z<1&&sx>.08&&sx<.92&&sy>top&&sy<1-bot; }catch(e){ return true; } }
function camKeep(){ G.camKeepView={a:G.ctl.a,b:G.ctl.b,r:G.ctl.r,t:G.ctl.t.clone(),at:performance.now()}; }
function camRestore(){ const v=G.camKeepView; G.camKeepView=null; if(!v||G.ctl.saved) return; if((G.camMoved||0)>v.at) return; /* you moved the camera yourself while the enemy acted: keep yours */ G.ctl.t=v.t.clone(); G.ctl.r=v.r; G.ctl.a=v.a; G.ctl.b=v.b; }
function camShow(u){ if(!u||G.ctl.saved) return; const p=uWorld(u); if(onScreenW(p)) return; const t=G.ctl.t; G.ctl.t=new V3(t.x+(p.x-t.x)*.75,0,t.z+(p.z-t.z)*.75); G.ctl.attract=false; } // pan most of the way, keep your zoom
ACT.center=()=>{ const u=B&&(B.sel||B.inspect); if(u) G.ctl.focus(uWorld(u),Math.min(G.ctl.r,150)); };
ACT.stripHelp=()=>{ const old=document.getElementById('helpcard'); if(old){ old.remove(); return; } const el=document.createElement('div'); el.id='helpcard'; el.className='hud tipcard';
  el.innerHTML=`<h4>What the buttons do</h4><p><b>Done with ship:</b> ends this ship's turn; the enemy then moves one of theirs.<br><b>Ability:</b> this ship's special power, named on the button (some ask you to tap a hex).<br><b>Command (gold):</b> your admiral\'s signature move. Once per battle; it grows each round you wait, and when you lose a ship.<br><b>Ram / Board:</b> charge the ship dead ahead, or send crews into an adjacent enemy to capture it.<br><b>Brace:</b> instead of firing. Move first if you like, then brace to take 40% less hull damage until your next turn. Once a ship has fired, it can\'t brace. Use it on a ship that can\'t shoot anything useful or is about to take a beating.<br><b>Launch:</b> carriers start with wings flying. Bombers hit ships; fighters guard your wings and shoot down enemy craft. Against a fleet with no carriers or squadrons every wing is a bomber; when the enemy brings craft, the carrier mixes in fighters to protect them. The button launches whichever kind you need, from the carrier\'s spares.<br></p><div class="row"><button class="primary" data-act="stripHelp">Got it</button></div>`;
  document.getElementById('stage').appendChild(el); };

// watchdog: the game must never sit 'busy' forever
// busy watchdog: measures progress, not wall time. Any new log line, acting ship, movement step, shot or round resets it; hidden time doesn't count.
setInterval(()=>{ if(!B||!B.busy){ G.busyIdle=0; G.busySig=''; return; } const sig=B.log.length+'|'+(B.aiActive&&B.aiActive.id)+'|'+B.round+'|'+B.side+'|'+(B.prog||0);
  if(sig!==G.busySig){ G.busySig=sig; G.busyIdle=0; return; } if(document.visibilityState==='hidden') return; G.busyIdle=(G.busyIdle||0)+2000;
  if(G.busyIdle>=20000){ G.busyIdle=0; B.epoch=(B.epoch||0)+1; B.busy=false; const side0=B.side; try{ tel('busy_watchdog',{round:B.round,side:B.side,ai:B.aiActive&&B.aiActive.name,logTail:B.log.slice(-3).map(x=>x.m.slice(0,80))}); Persist.saveLocal(); }catch(e){}
    if(!B.over&&side0==='enemy'){ B.side='player'; B.aiActive=null; try{ G.ctl.release(); }catch(e){} try{ toast('The enemy turn stalled, so it was skipped. Your move.'); }catch(e){} } /* v41: hand the turn back instead of leaving the enemy side active */ try{ bRefresh(); }catch(e){} } },2000);
// one-tap diagnostics: snapshot the game state into telemetry and save immediately
// touch and command history so a report can show where taps actually land
G.tapLog=[]; G.actLog=[]; G.panelRenders=[];
document.addEventListener('pointerdown',e=>{ const t=e.target; G.tapLog.push({t:Math.round(performance.now()/100)/10,x:Math.round(e.clientX),y:Math.round(e.clientY),hit:(t.id?'#'+t.id:'')+(t.className&&t.className.baseVal===undefined?'.'+String(t.className).split(' ')[0]:'')+'<'+t.tagName+'>'+(t.dataset&&t.dataset.act?' act='+t.dataset.act:'')}); if(G.tapLog.length>10) G.tapLog.shift(); },true);
function descAt(x,y){ const el=document.elementFromPoint(x,y); if(!el) return 'nothing'; return (el.id?'#'+el.id:'')+(el.className&&el.className.baseVal===undefined?'.'+String(el.className).split(' ')[0]:'')+'<'+el.tagName+'>'+(el.dataset&&el.dataset.act?' act='+el.dataset.act:''); }
function centerOf(sel){ const el=document.querySelector(sel); if(!el) return null; const r=el.getBoundingClientRect(); return [r.x+r.width/2,r.y+r.height/2]; }
ACT.reportProblem=()=>{ try{ const now=performance.now(); const dn=centerOf('#panel .actstrip button.primary'), en=centerOf('#b_end')||centerOf('[data-act=endTurn]');
  const app=document.getElementById('app'); const s0={underDone:dn?descAt(...dn):'no Done button',underEnd:en?descAt(...en):'no End button',underBoard:descAt(innerWidth/2,innerHeight*.45),
    appClass:app?app.className:'none',appDisplay:app?getComputedStyle(app).display:'none',bodyClass:document.body.className,taps:G.tapLog.slice(-10),acts:G.actLog.slice(-8),panelRenders5s:G.panelRenders.filter(t=>now-t<5000).length};
  const s=Object.assign(s0,{round:B&&B.round,side:B&&B.side,busy:B&&B.busy,over:B&&B.over,mode:B&&B.mode,sel:B&&B.sel&&B.sel.name,active:B&&B.activeUnit&&B.activeUnit.name,ai:B&&B.aiActive&&B.aiActive.name,
    pending:B?pendingP().length:0,touch:G.touchState?G.touchState():null,intro:!!document.querySelector('.intro'),loading:!!document.getElementById('loading'),log:B?B.log.slice(-12).map(x=>x.m.slice(0,90)):[]});
  tel('problem_report',s); console.debug('[report]',JSON.stringify(s)); Persist.saveLocal(); try{ Persist.save&&Persist.save({meta:true}); }catch(e){} toast('Problem report saved. Thanks: tell Claude in chat and it can read exactly what happened.'); }catch(e){ try{ toast('Could not save the report: '+e.message); }catch(_){} } };

// terrain legend: only what is on this battlefield; tap to expand
function refreshLegend(){ let el=document.getElementById('terrlegend'); if(!B||B.showcase||!B.terrain){ if(el) el.remove(); return; } const ks=terrainPresent(); if(!B._zones) B._zones=Object.keys(ZONE_INFO).filter(z=>boardHexes().some(h=>objZone(h.q,h.r)===z)); const zs=B._zones, E=ENCOUNTERS[B.obj&&B.obj.type]; if(!ks.length&&!zs.length&&!E){ if(el) el.remove(); return; }
  if(!el){ el=document.createElement('div'); el.id='terrlegend'; el.className='hud'; el.setAttribute('data-act','legend'); document.getElementById('stage').appendChild(el); }
  const seen=new Set(), rows=ks.filter(k=>{ const key=BLOCKING[k]?'block':k; if(seen.has(key)) return false; seen.add(key); return true; });
  const name=k=>BLOCKING[k]?ks.filter(x=>BLOCKING[x]).map(x=>TERRAIN_INFO[x].n).join(', '):TERRAIN_INFO[k].n, fx=k=>BLOCKING[k]?'Blocks movement and line of fire.':TERRAIN_INFO[k].fx;
  el.innerHTML=G.legendOpen?(E?`<div><b class="gilt">${E.n}</b> <span class="dim">(tap to close)</span></div><div class="muted" style="margin:2px 0 4px">${E.d}${B.shape&&B.shape!=='open'?` Board: ${SHAPES[B.shape].toLowerCase()}.`:''}</div>`:`<b>Terrain</b> <span class="dim">(tap to close)</span>`)
      +zs.map(z=>`<div class="lg"><i style="background:${ZONE_INFO[z].col}"></i><span><b>${ZONE_INFO[z].n}</b> ${ZONE_INFO[z].fx}</span></div>`).join('')
      +rows.map(k=>`<div class="lg"><i style="background:${TERRAIN_INFO[k].col}"></i><span><b>${name(k)}</b> ${fx(k)}</span></div>`).join('')
    :`<span class="dim">${E?E.n:'Terrain'}</span> `+zs.map(z=>`<i style="background:${ZONE_INFO[z].col}" title="${ZONE_INFO[z].n}"></i>`).join('')+rows.map(k=>`<i style="background:${TERRAIN_INFO[k].col}" title="${name(k)}"></i>`).join('')+` <span class="dim">▾</span>`; stackTop(); }
ACT.legend=()=>{ G.legendOpen=!G.legendOpen; refreshLegend(); };
// phone: stack the legend chip under the top bar (which wraps to 2-3 lines) and the tip card under both
function stackTop(){ try{ const bt=document.getElementById('btop'); if(!bt) return; const st=document.getElementById('stage').getBoundingClientRect().top; let y=bt.getBoundingClientRect().bottom-st+6;
  const lg=document.getElementById('terrlegend'); if(lg){ lg.style.top=y+'px'; y=lg.getBoundingClientRect().bottom-st+6; }
  const tc=document.getElementById('tipcard'); if(tc&&innerWidth<=900) tc.style.setProperty('top',y+'px','important'); }catch(e){} }
// v46.1 diagnostics (Shift+D, or Settings > Diagnostics): switch render features off one at a time to track down GPU-specific artifacts, with live render counts.
const DIAG={el:null,t:null,si:null,off:{}};
const DIAG_ITEMS=[
  ['ssao','Ambient occlusion',on=>{ if(!G.ssao) return; const mgr=G.scene.postProcessRenderPipelineManager; try{ if(on&&!G.ssaoOn){ mgr.attachCamerasToRenderPipeline('ssao',G.cam); G.ssaoOn=true; } else if(!on&&G.ssaoOn){ mgr.detachCamerasFromRenderPipeline('ssao',G.cam); G.ssaoOn=false; } const gb=G.scene.geometryBufferRenderer; if(gb) gb.renderList=G.ssaoOn?null:[]; }catch(e){ console.warn(e); } }],
  ['glow','Glow layer',on=>{ G.glow.isEnabled=on; }],
  ['bloom','Bloom',on=>{ G.pipe.bloomEnabled=on; }],
  ['shadows','Shadows',on=>{ if(G.sun) G.sun.shadowEnabled=on; }],
  ['englight','Engine lights',on=>{ for(const l of G.scene.lights) if(l.name==='engLight') l.setEnabled(on); }],
  ['flares','Engine flares',on=>{ for(const m of G.scene.meshes) if(/flare$/.test(m.name)) m.isVisible=on; }],
  ['plumes','Engine plumes',on=>{ for(const m of G.scene.meshes) if(/plume$/.test(m.name)) m.isVisible=on; }],
  ['hullhi','Hull detail shader',on=>{ G.diagNoHullHi=!on; try{ for(const M of Object.values(MATS)) for(const k of ['hull','dark','steel','trim']) if(M[k]) M[k].markAsDirty(BABYLON.Material.AllDirtyFlag); }catch(e){} }],
  ['vls','God rays',on=>{ try{ if(G.vls){ if(on) G.cam.attachPostProcess(G.vls); else G.cam.detachPostProcess(G.vls); } }catch(e){} }],
  ['sharpen','Sharpen',on=>{ G.pipe.sharpenEnabled=on; }],
  ['msaa','MSAA',on=>{ G.pipe.samples=on?4:1; }],
  ['fxaa','FXAA',on=>{ G.pipe.fxaaEnabled=on; }],
  ['ships','Ships',on=>{ for(const v of G.views.values()) if(v.root) v.root.setEnabled(on); }],
  ['env','Terrain',on=>{ for(const m of G.env||[]) if(m&&m.setEnabled) m.setEnabled(on); }]];
function diagStats(){ const s=G.scene; if(!DIAG.si) DIAG.si=new BABYLON.SceneInstrumentation(s); const a=s.getActiveMeshes(), by={}; for(let i=0;i<a.length;i++){ const k=a.data[i].name.replace(/[0-9_.-]+$/,''); by[k]=(by[k]||0)+1; }
  const top=Object.entries(by).sort((x,y)=>y[1]-x[1]).slice(0,8).map(e=>e[0]+' '+e[1]).join(', ');
  const order=(G.cam._postProcesses||[]).filter(Boolean).map(pp=>pp.name).join(' > ');
  return `<span style="opacity:.6">${order}</span><br>draws ${DIAG.si.drawCallsCounter.current} | active ${a.length} | meshes ${s.meshes.length} | mats ${s.materials.length} | tex ${s.textures.length} | lights ${s.lights.length} | particles ${s.particleSystems.length} | ${G.quality}<br><span style="opacity:.7">${top}</span>`; }
function diagRender(){ if(!DIAG.el) return; DIAG.el.innerHTML=`<div style="font-weight:600;margin-bottom:4px">Diagnostics <span style="opacity:.6">(Shift+D closes)</span></div><div id="diagStats" style="margin-bottom:6px"></div>`+DIAG_ITEMS.map(([k,n])=>`<button data-diag="${k}" style="margin:2px;padding:3px 7px;font:12px system-ui;border-radius:6px;border:1px solid #567;background:${DIAG.off[k]?'#3a1414':'#123a24'};color:#e8e8e8">${n}: ${DIAG.off[k]?'off':'on'}</button>`).join('');
  DIAG.el.querySelectorAll('[data-diag]').forEach(b=>b.onclick=e=>{ e.stopPropagation(); const k=b.dataset.diag, it=DIAG_ITEMS.find(x=>x[0]===k); DIAG.off[k]=!DIAG.off[k]; try{ it[2](!DIAG.off[k]); if(typeof orderPostFx==='function') orderPostFx(); }catch(err){ console.warn(err); } diagRender(); });
  const st=document.getElementById('diagStats'); if(st) st.innerHTML=diagStats(); }
function diagToggle(){ if(DIAG.el){ clearInterval(DIAG.t); DIAG.el.remove(); DIAG.el=null; return; }
  const el=document.createElement('div'); el.style.cssText='position:fixed;left:12px;top:64px;z-index:90;max-width:560px;background:rgba(6,10,16,.92);color:#dfe6ee;font:12px system-ui;padding:8px 10px;border:1px solid #345;border-radius:8px'; el.addEventListener('pointerdown',e=>e.stopPropagation());
  document.body.appendChild(el); DIAG.el=el; diagRender(); DIAG.t=setInterval(()=>{ const st=document.getElementById('diagStats'); if(st) try{ st.innerHTML=diagStats(); }catch(e){} },1000); }
ACT.diag=()=>diagToggle();
addEventListener('keydown',e=>{ if(e.shiftKey&&(e.key==='D'||e.key==='d')&&!/INPUT|TEXTAREA/.test((e.target&&e.target.tagName)||'')){ e.preventDefault(); diagToggle(); } });
