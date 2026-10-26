// ======================= CAMPAIGN IN 3D =======================
const appEl=document.getElementById('app');
let AI_LEVEL='standard'; // B1 onboarding fix 1 (F25): a fresh profile starts on Standard; main3d.js keeps Veteran for anyone who already played
// global error reporter: a calm notice instead of silent failure, logged for review
let ERRS=0; function reportError(msg,stack){ if(++ERRS>5) return; try{ tel('error',{msg:String(msg||'').slice(0,160),at:String(stack||'').split('\n').slice(1,3).join(' | ').trim().slice(0,240),round:B&&B.round,side:B&&B.side,busy:B&&B.busy}); Persist.saveLocal(); }catch(e){} /* v53: local only, no stamp: an error report must never win a cloud conflict */ try{ toast('Something went wrong. Your campaign is saved at the last node; reload if anything looks stuck.'); }catch(e){} }
window.addEventListener('error',e=>{ if(e.message) reportError(e.message,e.error&&e.error.stack); });
window.addEventListener('unhandledrejection',e=>reportError(e.reason&&(e.reason.message||e.reason),e.reason&&e.reason.stack));
function showApp(){ appEl.classList.remove('hidden'); document.body.classList.add('app-on'); hideEnd(); const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); G.ctl.attract=true; }
function hideApp(){ appEl.classList.add('hidden'); document.body.classList.remove('app-on'); }
const _show=show; show=function(html){ showApp(); appEl.classList.remove('see3d'); _show(html); if(typeof html==='string'&&html.includes('mapmain')){ appEl.classList.add('see3d'); try{ setupFleetShowcase(); }catch(e){} } }; // every route to the map shows your fleet

// telemetry: a rolling log of how runs actually go, saved with the profile
// telemetry: every event is also written to this device's storage the moment it happens, so a battle that freezes
// and gets reloaded out of still leaves its record; the next launch merges it back
const TEL_KEY='voidsworn.tel.v1';
function tel(ev,d={}){ try{ if(!META.tel) META.tel=[]; META.tel.push(Object.assign({t:Date.now(),ev,sector:RUN?RUN.sector:0,build:(typeof BUILD_ID!=='undefined'?BUILD_ID:'dev')},d)); if(META.tel.length>600) META.tel=META.tel.slice(-600);
  try{ localStorage.setItem(TEL_KEY,JSON.stringify(META.tel)); }catch(e){} }catch(e){} }
function mergeLocalTel(){ try{ const loc=JSON.parse(localStorage.getItem(TEL_KEY)||'[]'); if(!Array.isArray(loc)||!loc.length) return; const seen=new Set((META.tel||[]).map(e=>e.t+'|'+e.ev)); const add=loc.filter(e=>e&&!seen.has(e.t+'|'+e.ev));
  if(add.length){ META.tel=(META.tel||[]).concat(add).sort((a,b)=>a.t-b.t).slice(-600); } }catch(e){} }
// one tap: build, settings and the last 200 events as JSON, for pasting to Claude
ACT.copyReport=()=>{ let txt=''; try{ txt=JSON.stringify({build:typeof BUILD_ID!=='undefined'?BUILD_ID:'dev',at:new Date().toISOString(),ua:navigator.userAgent,opts:META.opts,run:RUN?{fac:RUN.fac,admiral:RUN.admiral,sector:RUN.sector,fleet:RUN.fleet.map(s=>s.tpl+':'+s.hp)}:null,
    battle:B&&!B.showcase?{round:B.round,side:B.side,busy:B.busy,over:B.over,obj:B.obj&&B.obj.type,log:B.log.slice(-15).map(x=>x.m)}:null,events:(META.tel||[]).slice(-200)}); }catch(e){ txt='{"error":"'+String(e.message)+'"}'; }
  const done=()=>toast('Report copied. Paste it into your chat with Claude.');
  const manual=()=>modal(`<h2>Copy report</h2><p class="muted">Select all and copy:</p><textarea readonly style="width:100%;height:240px;font-size:11px" onclick="this.select()">${esc(txt)}</textarea><div class="row" style="margin-top:10px"><button class="primary" data-act="c3optClose">Done</button></div>`);
  const legacy=()=>{ try{ const ta=document.createElement('textarea'); ta.value=txt; ta.style.position='fixed'; ta.style.opacity='0'; document.body.appendChild(ta); ta.select(); const ok=document.execCommand('copy'); ta.remove(); if(ok) done(); else manual(); }catch(e){ manual(); } };
  try{ if(navigator.clipboard&&navigator.clipboard.writeText) navigator.clipboard.writeText(txt).then(done,legacy); else legacy(); }catch(e){ legacy(); } };
/* run_end telemetry is recorded in endRun */

// renown earned so far this run, shown on the map
function runRenown(){ if(!RUN) return 0; const s=RUN.stats; return s.battles*2+s.elites*4+s.bosses*15+Math.floor(s.kills/4)+(RUN.sector-1)*5; }
const _map=mapScreen; mapScreen=function(){ _map(); appEl.classList.add('see3d'); setupFleetShowcase(); try{ hullMapPrefetch(); }catch(e){} try{ const hp=[...appEl.querySelectorAll('.mapmain p')].find(p=>p.textContent.includes('Hostile presence')); if(hp&&RUN.foes&&RUN.foes.length>=5) hp.insertAdjacentHTML('beforeend',` <span class="dim">Rival raiders from the ${esc(FACTIONS[RUN.foes[3]].n.replace(/^The /,''))} and the ${esc(FACTIONS[RUN.foes[4]].n.replace(/^The /,''))} may also strike.</span>`); }catch(e){}  };

// title screen: live 3D showcase battle behind the menu, plus the skirmish mode
const _title=titleScreen; titleScreen=function(){ disposeAllViews(); clearOverlays(); B=null; _title(); const menu=appEl.querySelector('.title .menu'); if(menu) menu.insertAdjacentHTML('beforeend','<button data-act="c3skirmish">3D skirmish</button><button data-act="c3settings">Settings</button>'); setupShowcase(); };
function setupShowcase(){ const f=PLAYABLE; const pf=f[Math.floor(Math.random()*f.length)], ef=f[Math.floor(Math.random()*f.length)];
  const saved=RUN, rs=RNG_S; setupBattle({pf,ef,map:'random',dep:'line',small:G.mobile}); RUN=saved; RNG_S=rs; B.showcase=true; /* G3 finding (Oct 26): the decorative battle no longer moves the rules random numbers */ B.showArcs=false; bRefresh(); G.ctl.attract=true; G.ctl.reset(); G.ctl.r=330; G.ctl.b=.9; }
ACT.c3skirmish=()=>{ hideApp(); setupBattle({small:false}); showIntro(); G.ctl.attract=true; };
ACT.c3title=()=>{ const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); hideEnd(); titleScreen(); };

// field repairs node
function fieldRepairs(n){ for(const sh of RUN.fleet){ const mx=derive(sh).maxHp; sh.hp=Math.min(mx,sh.hp+Math.round(mx*.2*repairMult())); } tel('field_repairs',{}); completeNode(); mapScreen(); toast('Field repairs: every ship recovers 20% of its hull.'); }

// campaign battles run in the 3D engine
// v53: owner's rule, a reload replays the same node and enemy fleet. Every fight node gets a seed when the map first shows it (saved with the run);
// battleScreen seeds the pre-battle rolls from it and hands it to startBattle, so the same saved run always rebuilds the same battle
function nodeSeeds(nodes){ let n=0; for(const nd of nodes) if(nd&&!nd.done&&nd.seed==null&&(nd.type==='battle'||nd.type==='elite'||nd.type==='boss'||nd.type==='event')){ nd.seed=Math.floor(rnd()*4294967296)>>>0; n++; } return n; }
function battleScreen(cfg){
  closeModal(); hideTip(); hideApp(); hideEnd(); const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on');
  disposeAllViews(); clearOverlays();
  { const sn=cfg.node&&findNode(cfg.node); if(sn){ nodeSeeds([sn]); if(sn.seed!=null&&cfg.seed==null){ const sd=cfg.eventRelic?((sn.seed^0x27d4eb2f)>>>0):sn.seed; cfg=Object.assign({},cfg,{seed:sd}); rndSeed((sd^0x5bd1e995)>>>0); } } } // v53: seeded before any pre-battle roll; B1: event fights are seeded too (own salt), so a reload replays the same fight // v53: seeded before any pre-battle roll
  if(RUN.fleet.length<=1&&(RUN.reinf||0)<RUN.sector){ RUN.reinf=RUN.sector; const sh=newShip('warden'); RUN.fleet.push(sh); setTimeout(()=>toast(`The sector garrison sends the ${sh.name} to reinforce you.`),600); tel('reinforced',{}); }
  const nd=cfg.node&&findNode(cfg.node); if(nd&&!nd.enc&&cfg.kind!=='boss'){ Object.assign(nd,rollEncounter(nd.type,nd.col)); if(!nd.map&&RUN.map&&RUN.map.region) nd.map=regionMap(RUN.map.region,nd.col,7); fitEncounter(nd); }
  const ro=cfg.kind==='boss'?bossEncounter():nd&&nd.enc?{enc:nd.enc,shape:nd.shape}:rollEncounter(cfg.kind,cfg.col||1);
  const c=Object.assign({map:(nd&&nd.map)||(RUN.map&&RUN.map.region&&regionMap(RUN.map.region,cfg.kind==='boss'?6:(nd?nd.col:3),7))||(cfg.kind==='boss'&&FAC_MAP[cfg.fac]?FAC_MAP[cfg.fac][0]:'random'),dep:cfg.kind==='boss'?'line':pick(['line','line','flank']),obj:ro.enc,shape:ro.shape,arch:cfg.kind!=='boss'&&nd?nd.arch:null,mod:cfg.kind!=='boss'&&nd?nd.mod:null},cfg); // bosses fight on their faction's home ground
  if(RUN.verbNext&&!c.verb) c.verb=RUN.verbNext; // B4: a next-battle faction verb
  const setupT0=performance.now(); startBattle(c); B.campaign=true; B.event=c.nemesis&&NEM_FAC[c.nemesis.fac]&&NEM_FAC[c.nemesis.fac].beh.strike==='reinforce'?(nemSignature('reinforce'),Object.assign(rollBattleEvent(c,'reinf_enemy'),{r:3})):rollBattleEvent(c,(sectorCond()||{}).war&&c.kind!=='boss'?(rnd()<.6?'reinf_enemy':'reinf_ally'):null); // R42: a Hegemony Nemesis always brings reinforcements in round 3 prepBattle(); const setupMs=Math.round(performance.now()-setupT0);
  const E=ENCOUNTERS[B.obj.type]||ENCOUNTERS.rout; document.getElementById('scenName').textContent=`Sector ${roman(RUN.sector)}: ${cfg.kind==='boss'?'flagship battle':(cfg.kind==='elite'?'elite ':'')+E.n.toLowerCase()} against ${FACTIONS[cfg.fac].n}`;
  G.ctl.attract=false; G.ctl.establish(); const f=caps('player')[0]; if(f) selectUnit(f); banner(cfg.kind==='boss'?'Sector flagship':E.n); { const bn=(RUN.boons||[]).map(b=>BOONS[b.id]&&BOONS[b.id].n).filter(Boolean), bt=bn.length?` Boons active: ${bn.slice(0,4).join(', ')}${bn.length>4?` and ${bn.length-4} more`:''}.`:''; setTimeout(()=>{ try{ if(B&&!B.over) toast((cfg.kind!=='boss'?E.d:'The sector flagship and its escort.')+(sectorCond()?' '+sectorCond().n+' in effect.':'')+bt); }catch(e){} },1400); }
  try{ FRAMES.reset(); fxMark('setup'); }catch(e){} tel('battle_start',{cond:B.cond||null,arch:c.arch||null,mod:c.mod||null,setupMs,seed:B.seed,obj:B.obj.type,shape:B.shape,kind:cfg.kind,fac:cfg.fac,map:B.map.map,dep:B.deployMode,alt:B.alt,fleet:RUN.fleet.map(s=>s.tpl)});
}
// v46.1: what the scene holds at the end of each battle, so a slow build-up across a run shows up in telemetry
function sceneCensus(){ try{ const s=G.scene, a=s.getActiveMeshes(), act={}, all={}; for(let i=0;i<a.length;i++){ const k=a.data[i].name.replace(/[0-9_.-]+$/,''); act[k]=(act[k]||0)+1; }
    for(const m of s.meshes){ if(!m.isEnabled()) continue; const k=m.name.replace(/[0-9_.-]+$/,''); all[k]=(all[k]||0)+1; }
    const top=o=>Object.entries(o).sort((x,y)=>y[1]-x[1]).slice(0,10).map(e=>e[0]+':'+e[1]).join(',');
    return {meshes:s.meshes.length,on:Object.values(all).reduce((x,y)=>x+y,0),act:a.length,mats:s.materials.length,tex:s.textures.length,ps:s.particleSystems.length,lights:s.lights.length,obs:s.onBeforeRenderObservable.observers.length,topAct:top(act),topOn:top(all)}; }catch(e){ return null; } }
function finishBattle(result){
  if(!B||B.finished) return; B.finished=true; hideEnd(); // v53: once per battle, and the end card goes first so it can never be tapped twice
  if(result==='loss'&&B.withdraw&&survivorsP()) result='retreat';
  const cfg=B.cfg; const summary={cfg,xp:[],lost:[],kills:0,rounds:B.round,prizes:[],partial:!!B.partial,boonStats:Object.assign({},B.boonStats||{})}; const r0=runRenown();
  const wingK={}; for(const u of B.units) if(u.parent){ const p=B.units.find(x=>x.id===u.parent); if(p){ p.dealt+=u.dealt; p.kills+=u.kills; if(p.ship) wingK[p.ship.uid]=(wingK[p.ship.uid]||0)+(u.kills||0); } }
  // B4: the Nemesis learns from how you fought; a used faction verb is spent; his own fight settles here
  try{ const pl=B.units.filter(u=>u.side==='player'&&!u.isSq), ev=pl.reduce((a,u)=>a+(u.ev||0),0)/Math.max(1,pl.length); nemLearn(B.usage,ev>=20?1:0); }catch(e){}
  if(B.cfg&&B.cfg.verb) RUN.verbNext=null;
  if(cfg.nemesis){ const fl=B.units.find(u=>u.nemFlag); summary.nem=nemAfterBattle(result,!!(fl&&fl.dead&&!fl.fled),{fled:!!B.nemFled,beat:nemBeatOf(B.usage,(B.units.filter(u=>u.side==='player'&&!u.isSq).reduce((a,u)=>a+(u.ev||0),0)/Math.max(1,B.units.filter(u=>u.side==='player'&&!u.isSq).length))>=20),cause:fl&&fl.killCause}); } else if(result==='win'&&RUN.nem){ const m=nemClockAdd(1); if(m) summary.nemWarn=m; }
  { const lostN=B.units.filter(u=>u.side==='player'&&u.ship&&u.dead&&!u.exited).length; if(lostN) nemFeedLosses(lostN); } // R42: a Chorus Nemesis grows from your losses
  for(const sh of RUN.fleet){ const k=wingK[sh.uid]; if(k){ const g=wingVetAfter(sh,k); if(g.length) (summary.wingPerks=summary.wingPerks||[]).push({ship:sh.name,perks:g}); } }
  summary.kills=B.units.filter(u=>u.side==='enemy'&&u.dead&&!u.fled&&!u.isSq&&!u.ship).length;
  RUN.stats.kills+=summary.kills;
  for(const u of B.units){
    if(!u.ship) continue; const ship=u.ship; if(u.side==='player'){ const c=ship.car=ship.car||{dealt:0,kills:0,battles:0}; c.dealt+=Math.round(u.dealt||0); c.kills+=u.kills||0; c.battles++; }
    if(u.dead&&!u.exited){ summary.lost.push({ship:ship.name,cap:ship.cap.name}); RUN.stats.lost=(RUN.stats.lost||0)+1; RUN.fleet=RUN.fleet.filter(x=>x!==ship);
      if(rnd()<.6){ (RUN.reserve=RUN.reserve||[]).push({cap:ship.cap,from:ship.name}); (summary.escaped=summary.escaped||[]).push(ship.cap.name); } else RUN.fallen.push({name:ship.cap.name,rank:ship.cap.rank,fac:ship.cap.fac,ship:ship.name,sector:RUN.sector}); continue; }
    ship.hp=clamp(Math.round(u.hp),1,derive(ship).maxHp);
    if(result==='retreat'){ ship.hp=Math.max(1,ship.hp-Math.round(u.maxHp*.1)); continue; }
    if(result==='win'){ const xp=Math.min(60,Math.round(8+u.dealt/4+u.kills*12)); const rk=ship.cap.rank; addXp(ship,xp); summary.xp.push({ship:ship.name,cap:ship.cap.name,xp,up:ship.cap.rank>rk,rank:ship.cap.rank}); }
  }
  if(result==='win'){ for(const sh of RUN.fleet){ const mx=derive(sh).maxHp; sh.hp=Math.min(mx,sh.hp+Math.round(mx*.15)); } summary.patched=true; }
  if(result==='win') for(const u of B.units) if(u.captured&&u.side==='player'&&(!u.dead||u.exited)&&!u.ship&&!u.isSq){ const H=HULLS[u.tpl]; if(!H||H.boss||u.boss) continue; // B1 (B-5): no sector flagship ever joins the fleet
    if(fleetCP()+(H.cp||1)>RUN.cpCap){ const v=prizeScrap(u.tpl); RUN.credits+=v; (summary.scrapped=summary.scrapped||[]).push({name:u.name,cred:v}); continue; } // full fleet: the prize is scrapped for credits (R4)
    summary.prizes.push({tpl:u.tpl,name:u.name,hpf:clamp(u.hp/Math.max(1,u.maxHp),.05,1),fac:u.fac,wk:[...new Set(u.weapons.map(w=>w.k))],ab:u.ab||null,regen:!!(u.hullRegen||u.regen&&!u.shMax),sh:u.shMax||0,cp:H.cp||1}); } // B2 (R4): add, strip or ransom is chosen on the reward screens
  // v54 doctrine (decided): a Corsair capture pays a bonus refit and 20 credits on top of the normal rewards, for one prize per battle (flagships are never prizes)
  if(result==='win'&&RUN.fac==='corsair'&&summary.prizes.length){ const p=summary.prizes[0], y=salvageYield(Object.assign({},p,{cause:'board'})), m=y.mod||randomModule(); RUN.inventory.push(m); RUN.credits+=20; summary.corsairBonus=m; setTimeout(()=>toast(`Prize money: the crews strip a ${modName(m)} and 20 credits from the ${p.name} before anyone signs for her.`),3000); }
  // v52 salvage: the field remembers what died and how, and the best wrecks are offered as salvage (Starsector / Pirates! style)
  if(result==='win') summary.wrecks=B.units.filter(u=>u.side==='enemy'&&u.dead&&!u.fled&&!u.isSq&&!u.ship&&!u.captured).sort((a,b)=>(b.t.cp||0)-(a.t.cp||0)).slice(0,3).map(u=>({name:u.name,tpl:u.tpl,cls:u.t.cls,fac:u.fac,cp:u.t.cp||1,wk:[...new Set(u.weapons.map(w=>w.k))],ab:u.ab||null,regen:!!(u.hullRegen||u.regen&&!u.shMax),sh:u.shMax||0,cause:u.killCause||'blast',by:u.killedBy||null}));
  if(summary.escaped) setTimeout(()=>toast(`${summary.escaped.join(' and ')} escaped in a lifepod, wounded, and will take command of your next hull.`),1800);
  { const msg=[...(summary.nem||[]),summary.nemWarn,...(summary.wingPerks||[]).map(w=>`The ${w.ship}'s wings earn ${w.perks.map(p=>WING_PERKS[p].n).join(' and ')}.`)].filter(Boolean); if(msg.length) setTimeout(()=>toast(msg.join(' ')),2400); }
  tel('battle_end',{perf:(()=>{ try{ return FRAMES.summary(); }catch(e){ return null; } })(),scene:sceneCensus(),boons:B.boonStats||{},ecp:B.cp0&&B.cp0.enemy,pcp:B.cp0&&B.cp0.player,usage:B.usage,obj:B.obj?B.obj.type:'rout',shape:B.shape,adapt:(B.adapt||0)+(B.adaptWings?'w'+B.adaptWings:''),event:B.event?B.event.k:null,partial:!!B.partial,escaped:(summary.escaped||[]).length,result,kind:cfg.kind,fac:cfg.fac,rounds:B.round,kills:summary.kills,lost:summary.lost.length,prizes:summary.prizes.length,
    rams:(B.usage&&B.usage.ram)||0,boardings:(B.usage&&B.usage.board)||0,captures:(B.usage&&B.usage.cap)||0,cmdRound:B.cmd?B.cmd.round:null});
  disposeAllViews(); clearOverlays(); B=null; hideTip(); hideEnd();
  if(result==='win'&&RUN.fleet.length===0){ const sh=newShip(cheapHull(RUN.fac)); RUN.fleet.push(sh); ensureFlagship(); setTimeout(()=>toast(`The last ships traded themselves for the win. The sector garrison sends the ${sh.name} to carry the flag.`),900); tel('reinforced',{why:'pyrrhic'}); } // B1 (B-9): a win that cost every ship is still a win
  if(result==='loss' || RUN.fleet.length===0){ endRun(false); return; }
  if(result==='retreat'){ completeNode(); mapScreen(); toast('The fleet jumps clear.'); return; }
  rewardFlow(summary);
  const gained=runRenown()-r0; if(summary.scrapped&&summary.scrapped.length) setTimeout(()=>toast(`No command points to crew ${summary.scrapped.map(x=>x.name).join(', ')}: scrapped for ${summary.scrapped.reduce((t,x)=>t+x.cred,0)} credits.`),700);
}
ACT.c3continue=()=>{ if(!B||B.busy||!B.over||!B.campaign||B.finished) return; finishBattle(B.over); }; // v53: same gate as c3retreat
ACT.c3retreat=()=>{ if(!B||B.busy||B.over||!B.campaign||B.cfg.kind==='boss') return; modal(`<h2 id="retreatAsk">Retreat?</h2><p>The fleet jumps out. Every surviving ship loses 10% of its hull, and this node counts as passed.</p><div class="row" style="margin-top:14px"><button class="primary" data-act="c3retreatYes">Jump out</button><button data-act="c3retreatNo">Stay and fight</button></div>`); };
ACT.c3retreatYes=()=>{ closeModal(); if(B&&B.campaign&&!B.over&&!B.busy&&!B.finished&&!B.ending) finishBattle('retreat'); }; // B1: a battle that already ended (or is mid-animation) is never turned into a retreat
ACT.c3retreatNo=()=>closeModal();

// wounded captains take the next hull bought at a shipyard
const _newShip=newShip; newShip=function(t,vet){ const sh=_newShip(t,vet); if((!B||B.showcase)&&!vet&&RUN&&RUN.reserve&&RUN.reserve.length){ const r=RUN.reserve.shift(), f=sh.hp/Math.max(1,derive(sh).maxHp); sh.cap=r.cap; sh.hp=Math.max(1,Math.round(derive(sh).maxHp*f)); /* B1 (B-10): a hired veteran keeps his ship; hull is re-derived for the new captain's perks */ setTimeout(()=>toast(`${r.cap.name} recovers and takes command of the ${sh.name}.`),200); } return sh; };
// settings from the title screen
function settingsHtml(){ const row=(k,label,val)=>`<div class="row" style="margin:6px 0"><span style="flex:1">${label}</span><button data-act="c3opt" data-arg="${k}">${val}</button></div>`;
  return `<h2>Settings</h2>${row('quality','Graphics',G.quality[0].toUpperCase()+G.quality.slice(1))}${row('fx','Reduce flashing',G.fxReduced?'On':'Off')}${row('shake','Reduce screen shake',G.shakeRed?'On':'Off')}${row('sound','Sound',G.sfxOn?'On':'Off')}<div class="row" style="margin:6px 0"><span style="flex:1">Sound volume</span><input type="range" min="0" max="100" value="${Math.round(SFX.getVol()*100)}" aria-label="Sound volume" oninput="SFX.setVol(this.value/100)" onchange="SFX.setVol(this.value/100,true)" style="width:140px;max-width:45vw"></div>${row('speed','Animation speed',SPEED<1?'Fast':'Normal')}${row('cine','Action camera',G.cine?'On':'Off')}${row('alt','Turn order',SETUP.alt?'Alternating':'Classic')}${row('copy','Copy report for Claude','Copy')}${row('follow','Camera follows activations',G.follow?'On':'Off')}${row('ai','Enemy AI',AI_LEVEL==='veteran'?'Veteran':'Standard')}${row('tips','Battle tips',(META.opts&&META.opts.tipsOff)?'Off':'On')}
    <div class="row" style="margin-top:14px"><button class="primary" data-act="c3optClose">Done</button></div>`; }
ACT.c3settings=()=>modal(settingsHtml());
ACT.c3opt=k=>{ if(k==='quality') ACT.quality(); else if(k==='fx') ACT.fxmode(); else if(k==='shake') ACT.shakemode(); else if(k==='sound') ACT.sound(); else if(k==='speed') ACT.speed(); else if(k==='cine') ACT.cine(); else if(k==='alt'){ SETUP.alt=!SETUP.alt; saveOpts(); } else if(k==='copy'){ closeModal(); ACT.copyReport(); return; } else if(k==='unlock'){ META.opts=META.opts||{}; META.opts.unlockAll=META.opts.unlockAll===false; if(META.opts.unlockAll){ for(const x in LEGACY) META.unlocked[x]=true; for(const x in ADMIRALS) META.admirals[x]=true; } } else if(k==='follow'){ G.follow=!G.follow; } else if(k==='ai'){ AI_LEVEL=AI_LEVEL==='veteran'?'standard':'veteran'; } else if(k==='tips'){ META.opts=META.opts||{}; META.opts.tipsOff=!META.opts.tipsOff; if(!META.opts.tipsOff) META.opts.tips={}; } saveOpts(); modal(settingsHtml()); };
ACT.c3optClose=()=>closeModal();

// the campaign map floats over your actual fleet, sailing in formation
function fleetSig(){ return RUN?RUN.fleet.map(s=>s.tpl+':'+s.hp).join('|')+'#'+RUN.sector:''; }
function setupFleetShowcase(){ if(!RUN||!RUN.fleet.length) return; if(B&&B.showcase==='fleet'&&B.showSig===fleetSig()) return;
  disposeAllViews(); clearOverlays(); const pool=[(RUN.map&&RUN.map.fac)||'hegemony'];
  { const rs=RNG_S; startBattle({kind:'battle',fac:pool[Math.floor(Math.random()*pool.length)],col:0,enemies:[],map:'random',dep:'line'}); RNG_S=rs; } // G3 finding (Oct 26): the map's decorative battle leaves the rules random numbers as they were
  B.showcase='fleet'; B.showSig=fleetSig(); B.showArcs=false; B.side='none'; buildBattleEnv();
  const ps=alive('player').map(x=>hexWorld(x.q,x.r)); const cen=ps.reduce((a,p)=>a.add(p),V3.Zero()).scale(1/Math.max(1,ps.length)); cen.y=0;
  G.ctl.t=cen; G.home=cen.clone(); G.ctl.r=95; G.ctl.b=1.2; G.ctl.attract=true; }

// performance readout (P): frame rate, draw calls and errors, visible in screenshots
let PERF=null; document.addEventListener('keydown',e=>{ if((e.key==='p'||e.key==='P')&&e.target.tagName!=='INPUT') perfToggle(); });
function perfToggle(){ { if(PERF){ clearInterval(PERF.t); PERF.el.remove(); PERF=null; return; }
  const el=document.createElement('div'); el.className='hud'; el.style.cssText='position:fixed;left:50%;top:70px;transform:translateX(-50%);z-index:70;padding:6px 12px;font:13px monospace;color:#9fe2ff'; document.body.appendChild(el);
  const ins=new BABYLON.SceneInstrumentation(G.scene); PERF={el,t:setInterval(()=>{ el.textContent=`${G.engine.getFps().toFixed(0)} fps | ${(()=>{ const f=FRAMES.summary(); return 'p50 '+f.p50+' p90 '+f.p90+' ms'; })()} | ${ins.drawCallsCounter.current} draws | ${(G.scene.getTotalVertices()/1e6).toFixed(2)}M verts | ${G.quality} | ${G.engine.getRenderWidth()}x${G.engine.getRenderHeight()} | errors ${ERRS}`; },500)}; } }

