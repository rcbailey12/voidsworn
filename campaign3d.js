// ======================= CAMPAIGN IN 3D =======================
const appEl=document.getElementById('app');
let AI_LEVEL='veteran';
// global error reporter: a calm notice instead of silent failure, logged for review
let ERRS=0; function reportError(msg,stack){ if(++ERRS>5) return; try{ tel('error',{msg:String(msg||'').slice(0,160),at:String(stack||'').split('\n').slice(1,3).join(' | ').trim().slice(0,240),round:B&&B.round,side:B&&B.side,busy:B&&B.busy}); Persist.saveLocal(); if(Persist.save) Persist.save(); }catch(e){} try{ toast('Something went wrong. Your campaign is saved at the last node; reload if anything looks stuck.'); }catch(e){} }
window.addEventListener('error',e=>{ if(e.message) reportError(e.message,e.error&&e.error.stack); });
window.addEventListener('unhandledrejection',e=>reportError(e.reason&&(e.reason.message||e.reason),e.reason&&e.reason.stack));
function drawShipShape(){} // the old 2D title animation is hidden behind the live 3D backdrop
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
const _map=mapScreen; mapScreen=function(){ _map(); appEl.classList.add('see3d'); setupFleetShowcase(); try{ const hp=[...appEl.querySelectorAll('.mapmain p')].find(p=>p.textContent.includes('Hostile presence')); if(hp&&RUN.foes&&RUN.foes.length>=5) hp.insertAdjacentHTML('beforeend',` <span class="dim">Rival raiders from the ${esc(FACTIONS[RUN.foes[3]].n.replace(/^The /,''))} and the ${esc(FACTIONS[RUN.foes[4]].n.replace(/^The /,''))} may also strike.</span>`); }catch(e){}  };

// title screen: live 3D showcase battle behind the menu, plus the skirmish mode
const _title=titleScreen; titleScreen=function(){ disposeAllViews(); clearOverlays(); B=null; _title(); const menu=appEl.querySelector('.title .menu'); if(menu) menu.insertAdjacentHTML('beforeend','<button data-act="c3skirmish">3D skirmish</button><button data-act="c3settings">Settings</button>'); setupShowcase(); };
function setupShowcase(){ const f=PLAYABLE; const pf=f[Math.floor(Math.random()*f.length)], ef=f[Math.floor(Math.random()*f.length)];
  const saved=RUN; setupBattle({pf,ef,map:'random',dep:'line',small:G.mobile}); RUN=saved; B.showcase=true; B.showArcs=false; bRefresh(); G.ctl.attract=true; G.ctl.reset(); G.ctl.r=330; G.ctl.b=.9; }
ACT.c3skirmish=()=>{ hideApp(); setupBattle({small:false}); showIntro(); G.ctl.attract=true; };
ACT.c3title=()=>{ const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); hideEnd(); titleScreen(); };

// field repairs node
function fieldRepairs(n){ for(const sh of RUN.fleet){ const mx=derive(sh).maxHp; sh.hp=Math.min(mx,sh.hp+Math.round(mx*.2*repairMult())); } tel('field_repairs',{}); completeNode(); mapScreen(); toast('Field repairs: every ship recovers 20% of its hull.'); }

// campaign battles run in the 3D engine
function battleScreen(cfg){
  closeModal(); hideTip(); hideApp(); hideEnd(); const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on');
  disposeAllViews(); clearOverlays();
  if(RUN.fleet.length<=1&&(RUN.reinf||0)<RUN.sector){ RUN.reinf=RUN.sector; const sh=newShip('warden'); RUN.fleet.push(sh); setTimeout(()=>toast(`The sector garrison sends the ${sh.name} to reinforce you.`),600); tel('reinforced',{}); }
  const nd=cfg.node&&findNode(cfg.node); if(nd&&!nd.enc&&cfg.kind!=='boss') Object.assign(nd,rollEncounter(nd.type,nd.col));
  const ro=cfg.kind==='boss'?bossEncounter():nd&&nd.enc?{enc:nd.enc,shape:nd.shape}:rollEncounter(cfg.kind,cfg.col||1);
  const c=Object.assign({map:cfg.kind==='boss'&&FAC_MAP[cfg.fac]?FAC_MAP[cfg.fac][0]:'random',dep:cfg.kind==='boss'?'line':pick(['line','line','flank']),obj:ro.enc,shape:ro.shape},cfg); // bosses fight on their faction's home ground
  const setupT0=performance.now(); startBattle(c); B.campaign=true; B.event=rollBattleEvent(c); prepBattle(); const setupMs=Math.round(performance.now()-setupT0);
  const E=ENCOUNTERS[B.obj.type]||ENCOUNTERS.rout; document.getElementById('scenName').textContent=`Sector ${roman(RUN.sector)}: ${cfg.kind==='boss'?'flagship battle':(cfg.kind==='elite'?'elite ':'')+E.n.toLowerCase()} against ${FACTIONS[cfg.fac].n}`;
  G.ctl.attract=false; G.ctl.establish(); const f=caps('player')[0]; if(f) selectUnit(f); banner(cfg.kind==='boss'?'Sector flagship':E.n); { const bn=(RUN.boons||[]).map(b=>BOONS[b.id]&&BOONS[b.id].n).filter(Boolean), bt=bn.length?` Boons active: ${bn.slice(0,4).join(', ')}${bn.length>4?` and ${bn.length-4} more`:''}.`:''; setTimeout(()=>{ try{ if(B&&!B.over) toast((cfg.kind!=='boss'?E.d:'The sector flagship and its escort.')+bt); }catch(e){} },1400); }
  try{ FRAMES.reset(); }catch(e){} tel('battle_start',{setupMs,seed:B.seed,obj:B.obj.type,shape:B.shape,kind:cfg.kind,fac:cfg.fac,map:B.map.map,dep:B.deployMode,alt:B.alt,fleet:RUN.fleet.map(s=>s.tpl)});
}
function finishBattle(result){
  if(result==='loss'&&B.withdraw&&survivorsP()) result='retreat';
  const cfg=B.cfg; const summary={cfg,xp:[],lost:[],kills:0,rounds:B.round,prizes:[],partial:!!B.partial,boonStats:Object.assign({},B.boonStats||{})}; const r0=runRenown();
  for(const u of B.units) if(u.parent){ const p=B.units.find(x=>x.id===u.parent); if(p){ p.dealt+=u.dealt; p.kills+=u.kills; } }
  summary.kills=B.units.filter(u=>u.side==='enemy'&&u.dead&&!u.fled&&!u.isSq&&!u.ship).length;
  RUN.stats.kills+=summary.kills;
  for(const u of B.units){
    if(!u.ship) continue; const ship=u.ship; if(u.side==='player'){ const c=ship.car=ship.car||{dealt:0,kills:0,battles:0}; c.dealt+=Math.round(u.dealt||0); c.kills+=u.kills||0; c.battles++; }
    if((u.dead&&!u.exited)||u.side!=='player'){ summary.lost.push({ship:ship.name,cap:ship.cap.name}); RUN.stats.lost=(RUN.stats.lost||0)+1; RUN.fleet=RUN.fleet.filter(x=>x!==ship);
      if(Math.random()<.6){ (RUN.reserve=RUN.reserve||[]).push({cap:ship.cap,from:ship.name}); (summary.escaped=summary.escaped||[]).push(ship.cap.name); } else RUN.fallen.push({name:ship.cap.name,rank:ship.cap.rank,fac:ship.cap.fac,ship:ship.name,sector:RUN.sector}); continue; }
    ship.hp=clamp(Math.round(u.hp),1,derive(ship).maxHp);
    if(result==='retreat'){ ship.hp=Math.max(1,ship.hp-Math.round(u.maxHp*.1)); continue; }
    if(result==='win'){ const xp=Math.min(60,Math.round(8+u.dealt/4+u.kills*12)); const rk=ship.cap.rank; addXp(ship,xp); summary.xp.push({ship:ship.name,cap:ship.cap.name,xp,up:ship.cap.rank>rk,rank:ship.cap.rank}); }
  }
  if(result==='win'){ for(const sh of RUN.fleet){ const mx=derive(sh).maxHp; sh.hp=Math.min(mx,sh.hp+Math.round(mx*.15)); } summary.patched=true; }
  if(result==='win') for(const u of B.units) if(u.captured&&u.side==='player'&&(!u.dead||u.exited)&&!u.ship&&!u.isSq){ const sh=newShip(u.tpl); sh.name=u.name; sh.hp=clamp(Math.round(u.hp),1,derive(sh).maxHp); RUN.fleet.push(sh); summary.prizes.push(u.name); }
  if(summary.escaped) setTimeout(()=>toast(`${summary.escaped.join(' and ')} escaped in a lifepod, wounded, and will take command of your next hull.`),1800);
  tel('battle_end',{perf:(()=>{ try{ return FRAMES.summary(); }catch(e){ return null; } })(),boons:B.boonStats||{},ecp:B.cp0&&B.cp0.enemy,pcp:B.cp0&&B.cp0.player,usage:B.usage,obj:B.obj?B.obj.type:'rout',shape:B.shape,adapt:(B.adapt||0)+(B.adaptWings?'w'+B.adaptWings:''),event:B.event?B.event.k:null,partial:!!B.partial,escaped:(summary.escaped||[]).length,result,kind:cfg.kind,fac:cfg.fac,rounds:B.round,kills:summary.kills,lost:summary.lost.length,prizes:summary.prizes.length,
    rams:(B.usage&&B.usage.ram)||0,boardings:(B.usage&&B.usage.board)||0,captures:(B.usage&&B.usage.cap)||0,cmdRound:B.cmd?B.cmd.round:null});
  disposeAllViews(); clearOverlays(); B=null; hideTip(); hideEnd();
  if(result==='loss' || RUN.fleet.length===0){ endRun(false); return; }
  if(result==='retreat'){ completeNode(); mapScreen(); toast('The fleet jumps clear.'); return; }
  rewardFlow(summary);
  const gained=runRenown()-r0; if(summary.prizes.length) setTimeout(()=>toast(`Prize ship${summary.prizes.length>1?'s':''} join the fleet: ${summary.prizes.join(', ')}.`),300);
}
ACT.c3continue=()=>{ if(B&&B.over) finishBattle(B.over); };
ACT.c3retreat=()=>{ if(!B||B.busy||B.over||!B.campaign||B.cfg.kind==='boss') return; modal(`<h2>Retreat?</h2><p>The fleet jumps out. Every surviving ship loses 10% of its hull, and this node counts as passed.</p><div class="row" style="margin-top:14px"><button class="primary" data-act="c3retreatYes">Jump out</button><button data-act="c3retreatNo">Stay and fight</button></div>`); };
ACT.c3retreatYes=()=>{ closeModal(); if(B&&B.campaign) finishBattle('retreat'); };
ACT.c3retreatNo=()=>closeModal();

// wounded captains take the next hull bought at a shipyard
const _newShip=newShip; newShip=function(t,vet){ const sh=_newShip(t,vet); if(!B&&RUN&&RUN.reserve&&RUN.reserve.length){ const r=RUN.reserve.shift(); sh.cap=r.cap; setTimeout(()=>toast(`${r.cap.name} recovers and takes command of the ${sh.name}.`),200); } return sh; };
// settings from the title screen
function settingsHtml(){ const row=(k,label,val)=>`<div class="row" style="margin:6px 0"><span style="flex:1">${label}</span><button data-act="c3opt" data-arg="${k}">${val}</button></div>`;
  return `<h2>Settings</h2>${row('quality','Graphics',G.quality[0].toUpperCase()+G.quality.slice(1))}${row('fx','Flashes and camera shake',G.fxReduced?'Reduced':'Full')}${row('sound','Sound',G.sfxOn?'On':'Off')}${row('speed','Animation speed',SPEED<1?'Fast':'Normal')}${row('cine','Action camera',G.cine?'On':'Off')}${row('alt','Turn order',SETUP.alt?'Alternating':'Classic')}${row('copy','Copy report for Claude','Copy')}${row('follow','Camera follows activations',G.follow?'On':'Off')}${row('ai','Enemy AI',AI_LEVEL==='veteran'?'Veteran':'Standard')}${row('tips','Battle tips',(META.opts&&META.opts.tipsOff)?'Off':'On')}
    <div class="row" style="margin-top:14px"><button class="primary" data-act="c3optClose">Done</button></div>`; }
ACT.c3settings=()=>modal(settingsHtml());
ACT.c3opt=k=>{ if(k==='quality') ACT.quality(); else if(k==='fx') ACT.fxmode(); else if(k==='sound') ACT.sound(); else if(k==='speed') ACT.speed(); else if(k==='cine') ACT.cine(); else if(k==='alt'){ SETUP.alt=!SETUP.alt; saveOpts(); } else if(k==='copy'){ closeModal(); ACT.copyReport(); return; } else if(k==='unlock'){ META.opts=META.opts||{}; META.opts.unlockAll=META.opts.unlockAll===false; if(META.opts.unlockAll){ for(const x in LEGACY) META.unlocked[x]=true; for(const x in ADMIRALS) META.admirals[x]=true; } } else if(k==='follow'){ G.follow=!G.follow; } else if(k==='ai'){ AI_LEVEL=AI_LEVEL==='veteran'?'standard':'veteran'; } else if(k==='tips'){ META.opts=META.opts||{}; META.opts.tipsOff=!META.opts.tipsOff; if(!META.opts.tipsOff) META.opts.tips={}; } saveOpts(); modal(settingsHtml()); };
ACT.c3optClose=()=>closeModal();

// the campaign map floats over your actual fleet, sailing in formation
function fleetSig(){ return RUN?RUN.fleet.map(s=>s.tpl+':'+s.hp).join('|')+'#'+RUN.sector:''; }
function setupFleetShowcase(){ if(!RUN||!RUN.fleet.length) return; if(B&&B.showcase==='fleet'&&B.showSig===fleetSig()) return;
  disposeAllViews(); clearOverlays(); const pool=[(RUN.map&&RUN.map.fac)||'hegemony'];
  startBattle({kind:'battle',fac:pool[Math.floor(Math.random()*pool.length)],col:0,enemies:[],map:'random',dep:'line'});
  B.showcase='fleet'; B.showSig=fleetSig(); B.showArcs=false; B.side='none'; buildBattleEnv();
  const ps=alive('player').map(x=>hexWorld(x.q,x.r)); const cen=ps.reduce((a,p)=>a.add(p),V3.Zero()).scale(1/Math.max(1,ps.length)); cen.y=0;
  G.ctl.t=cen; G.home=cen.clone(); G.ctl.r=95; G.ctl.b=1.2; G.ctl.attract=true; }

// performance readout (P): frame rate, draw calls and errors, visible in screenshots
let PERF=null; document.addEventListener('keydown',e=>{ if((e.key==='p'||e.key==='P')&&e.target.tagName!=='INPUT') perfToggle(); });
function perfToggle(){ { if(PERF){ clearInterval(PERF.t); PERF.el.remove(); PERF=null; return; }
  const el=document.createElement('div'); el.className='hud'; el.style.cssText='position:fixed;left:50%;top:70px;transform:translateX(-50%);z-index:70;padding:6px 12px;font:13px monospace;color:#9fe2ff'; document.body.appendChild(el);
  const ins=new BABYLON.SceneInstrumentation(G.scene); PERF={el,t:setInterval(()=>{ el.textContent=`${G.engine.getFps().toFixed(0)} fps | ${(()=>{ const f=FRAMES.summary(); return 'p50 '+f.p50+' p90 '+f.p90+' ms'; })()} | ${ins.drawCallsCounter.current} draws | ${(G.scene.getTotalVertices()/1e6).toFixed(2)}M verts | ${G.quality} | ${G.engine.getRenderWidth()}x${G.engine.getRenderHeight()} | errors ${ERRS}`; },500)}; } }

// preview builds only: a self-running, captioned visual test so screenshots need no input
async function runDemo(){ if(!window.PREVIEW_DEMO) return; const sleep=ms=>new Promise(r=>setTimeout(r,ms));
  const cap=document.createElement('div'); cap.className='hud'; cap.style.cssText='position:fixed;left:16px;bottom:16px;z-index:70;padding:8px 14px;font-size:15px;color:#e6dcc4'; document.body.appendChild(cap);
  const say=t=>cap.textContent=t; const frame=(u,r,b,a)=>{ G.ctl.attract=false; G.ctl.t=uWorld(u); G.ctl.r=r; G.ctl.b=b; G.ctl.a=a; };
  const battle=(pf,ef,map)=>{ hideApp(); setupBattle({pf,ef,map,dep:'line'}); const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); B.sel=null; B.showArcs=false; bRefresh(); G.cine=false; };
  await sleep(4000); perfToggle(); battle('voidsworn','hegemony','belt'); const A=B.units.find(u=>u.tpl==='cathedral'), T=B.units.find(u=>u.tpl==='h_dominion');
  say('Demo 1/11: Voidsworn battleship close-up'); frame(A,28,1.05,-2.25); await sleep(9000);
  say('Demo 2/11: Hegemony star destroyer close-up'); frame(T,30,1.05,-.9); await sleep(9000);
  say('Demo 3/11: battlefield wide shot'); G.ctl.reset(); G.ctl.r=260; G.ctl.b=.95; G.ctl.a=-1.9; await sleep(9000);
  for(const u of B.units){ if(u!==A&&u!==T&&(u.r===7||u.r===8)) u.r=u.side==='player'?14:1; } for(const k of ['9,8','12,8','10,8','11,8','9,7','10,7']) delete B.terrain[k];
  A.q=9;A.r=8;A.facing=5; T.q=12;T.r=8;T.facing=3; say('Demo 4/11: broadside exchange'); G.ctl.t=hexWorld(10.5,7.8); G.ctl.r=80; G.ctl.b=1.05; G.ctl.a=-Math.PI/2;
  (async()=>{ for(let k=0;k<2;k++){ for(const w of A.weapons){ const i=A.weapons.indexOf(w); w.fired=false; w.cdLeft=0; if(canFire(A,w,T)) await fireWeapon(A,i,T); } } })(); await sleep(9000);
  say('Demo 5/11: shield ripple (shots into full shields)'); G.ctl.t=uWorld(T); G.ctl.r=46; G.ctl.b=1.0; G.ctl.a=-Math.PI/2; T.sh=[T.shMax,T.shMax,T.shMax,T.shMax];
  (async()=>{ for(let k=0;k<3;k++){ T.sh=[T.shMax,T.shMax,T.shMax,T.shMax]; for(const w of A.weapons){ const i=A.weapons.indexOf(w); w.fired=false; w.cdLeft=0; if(w.k!=='lance'&&canFire(A,w,T)) await fireWeapon(A,i,T); } } })(); await sleep(9000);
  say('Demo 6/11: action camera with depth of field (lance strike)'); setQuality('ultra'); G.cine=true; (async()=>{ for(let k=0;k<3;k++){ for(const w of A.weapons){ const i=A.weapons.indexOf(w); w.fired=false; w.cdLeft=0; if(w.k==='lance'&&canFire(A,w,T)) await fireWeapon(A,i,T); } await sleep(1200); } })(); await sleep(9000); G.cine=false; G.ctl.release();
  say('Demo 7/11: capital ship death'); T.hp=0; T.dead=true; animExplode(T); await sleep(9000);
  battle('corsair','chorus','station'); say('Demo 8/11: Corsair hulk-carrier close-up'); frame(B.units.find(u=>u.tpl==='c_hulk'),30,1.05,-2.2); await sleep(9000);
  say('Demo 9/11: Chorus brood-ship close-up'); frame(B.units.find(u=>u.tpl==='b_brood'),32,1.05,-1.0); await sleep(9000);
  battle('ithar','deathless','storm'); say('Demo 10/11: Ithar song-ship close-up'); frame(B.units.find(u=>u.tpl==='i_song')||alive('player')[0],30,1.05,-2.2); await sleep(9000);
  say('Demo 11/11: Deathless harvester close-up'); frame(B.units.find(u=>u.tpl==='d_harvester')||alive('enemy')[0],26,1.05,-1.0); await sleep(9000);
  say('Demo complete'); }
setTimeout(()=>runDemo().catch(e=>reportError(e.message,e.stack)),0);
