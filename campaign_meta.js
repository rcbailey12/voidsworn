// ======================= UI: shell, title, meta =======================
const app=document.getElementById('app');
const tipEl=document.getElementById('tip');
const ACT={};
let heirDebrief=null;
app.addEventListener('click',e=>{ const el=e.target.closest('[data-act]'); if(!el||el.disabled) return; const fn=ACT[el.dataset.act]; if(fn) fn(el.dataset.arg,el,e); });
function show(html){ hideTip(); closeModal(); app.innerHTML=html; }
function modal(html){ closeModal(); const m=document.createElement('div'); m.className='modal'; m.id='modal'; m.innerHTML=`<div class="box" role="dialog" aria-modal="true">${html}</div>`;
  m.addEventListener('click',e=>{ const el=e.target.closest('[data-act]'); if(!el||el.disabled) return; const fn=ACT[el.dataset.act]; if(fn) fn(el.dataset.arg,el,e); });
  document.body.appendChild(m); const b=m.querySelector('button'); if(b) b.focus(); }
function closeModal(){ const m=document.getElementById('modal'); if(m) m.remove(); }
function toast(msg){ const t=document.createElement('div'); t.className='toast'; t.textContent=msg; document.body.appendChild(t); setTimeout(()=>t.remove(),Math.min(9000,Math.max(2200,String(msg).length*60))); } // long messages stay long enough to read
// touch screens: say tap, not click or hover
function touchWords(h){ if(!(typeof G!=='undefined'&&G.mobile)||typeof h!=='string') return h;
  return h.replace(/Right-click to cancel/g,'Tap elsewhere to cancel').replace(/\b[Rr]ight-click(ing)?\b/g,'tapping elsewhere').replace(/Click to fire/g,'Tap again to fire').replace(/Tap a gold hex to move/g,'Tap a gold hex twice to move').replace(/a red-ringed enemy to fire/g,'a red-ringed enemy twice to fire').replace(/\bClick\b/g,'Tap').replace(/\bclick\b/g,'tap').replace(/\bHover\b/g,'Tap').replace(/\bhover\b/g,'tap'); }
function showTip(html,x,y){ tipEl.innerHTML=touchWords(html); tipEl.style.display='block';
  if(typeof G!=='undefined'&&G.mobile){ // phone: a fixed card just above the bottom panel, never under the finger
    tipEl.style.left='8px'; tipEl.style.maxWidth=(innerWidth-16)+'px'; const r=tipEl.getBoundingClientRect(), pn=document.getElementById('panel'), pt=pn&&pn.offsetParent?pn.getBoundingClientRect().top:innerHeight;
    tipEl.style.top=Math.max(8,pt-r.height-8)+'px'; return; }
  tipEl.style.maxWidth=''; const r=tipEl.getBoundingClientRect();
  let lx=x+18, ly=y+14; if(lx+r.width>innerWidth-8) lx=x-r.width-14; if(ly+r.height>innerHeight-8) ly=innerHeight-r.height-8; tipEl.style.left=lx+'px'; tipEl.style.top=ly+'px'; }
function hideTip(){ tipEl.style.display='none'; }
const roman=n=>['','I','II','III','IV'][n]||n;
function pct(n){ return Math.round(n*100)+'%'; }
function hpBar(hp,max){ const f=clamp(hp/max,0,1); return `<div class="bar${f<.35?' low':''}"><i style="width:${f*100}%"></i></div>`; }

// ---------- title ----------
function titleScreen(){
  heirDebrief=null;
  RUN=null; B=null;
  show(`<div class="screen title"><div class="inner">
    <h1>Embers of the Hollow Sun</h1>
    <p class="sub">Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain.</p>
    <div class="menu">
      ${SAVED_RUN?`<button class="primary" data-act="continueRun">Continue run</button>`:''}
      <button class="${SAVED_RUN?'':'primary'}" data-act="newRunScreen">New run</button>
      <button data-act="legacy">Progression${(META.renown||0)>=15?' <span class="gilt num">\u25cf</span>':''}</button>
      <button data-act="help">How to play</button>
    </div>
    <div class="renown num">${META.stats.best?`Best: sector ${roman(Math.min(3,META.stats.best))}${META.stats.wins?` \u00b7 ${META.stats.wins} full victor${META.stats.wins>1?'ies':'y'}`:''}`:''}</div>
  </div></div>`);
}
ACT.title=()=>titleScreen();
ACT.continueRun=()=>{ RUN=JSON.parse(JSON.stringify(SAVED_RUN));
  try{ ensureFlagship(); mapScreen(); if(RUN.reward) resumeReward(); else resumeServiceStop(); }catch(e){ console.error('Continue failed',e); RUN=null; // B1: a save the game can no longer open gets a way out instead of a dead title screen
    modal(`<h2>This run could not be opened</h2><p class="muted">Something in the save no longer matches this version of the game. A copy of the save is kept on this device. Your progression and unlocks are safe either way.</p>
    <div class="row"><button class="primary" data-act="discardBrokenRun">Start fresh (keep a copy)</button><button data-act="closeModal">Back</button></div>`); return; }
  const rep=(RUN._repairs||[]).length, lost=RUN._shipsDropped||0;
  if(rep){ toast(`Your save came from an older version: ${lost?`${lost} ship${lost>1?'s':''} and `:''}${rep-lost>0?`${rep-lost} item${rep-lost>1?'s':''} `:''}no longer in the game ${lost||rep>1?'were':'was'} removed. A copy of the old save is kept.`);
    delete RUN._repairs; delete RUN._shipsDropped; saveRun(); } };
ACT.discardBrokenRun=()=>{ try{ localStorage.setItem(STORE_KEY+'.repaired',JSON.stringify({meta:META,run:SAVED_RUN})); }catch(e){} SAVED_RUN=null; RUN=null; closeModal(); Persist.save(); titleScreen(); };
ACT.newRunScreen=()=>{
  if(SAVED_RUN){ modal(`<h2>Abandon the current run?</h2><p class="muted">Starting over ends your saved run. Your best result so far is kept either way.</p>
    <div class="row"><button class="primary" data-act="abandonRun">Abandon and start over</button><button data-act="closeModal">Keep it</button></div>`); return; }
  admiralScreen();
};
ACT.closeModal=()=>closeModal();
ACT.abandonRun=()=>{ RUN=JSON.parse(JSON.stringify(SAVED_RUN)); endRun(false,true); };

let pickedAdmiral='vex';
// R1 (PROG-6): an admiral is yours when bought or when it costs nothing (each faction's first admiral); only yours can be picked or launched
function admiralOwned(id){ const a=ADMIRALS[id]; return !!a&&(!!META.admirals[id]||!(a.cost>0)); }
function admiralScreen(){
  heirDebrief=null;
  const mine=Object.entries(ADMIRALS).filter(([id,a])=>(a.fac||'voidsworn')===pickedFaction);
  if(!mine.some(([id])=>id===pickedAdmiral)||!admiralOwned(pickedAdmiral)) pickedAdmiral=(mine.find(([id])=>admiralOwned(id))||mine[0])[0];
  const cards=mine.map(([id,a])=>{ const un=admiralOwned(id);
    const fleet=a.start.map(t=>HULLS[equivHull(t,pickedFaction)].n).join(', ');
    return `<div class="card ${pickedAdmiral===id?'sel':''} ${un?'':'locked'}">
      <h3>${esc(a.n)}</h3><p class="gilt">${esc(a.doc)}</p><p>${esc(a.d)}</p>
      ${masteryBar(id)}<p class="dim">${META.heirs[a.fac||'voidsworn']===id?'Heir: 50%':'Shadow: 25%'} XP while benched</p>${LINEAGE_TREES[id]?`<button data-act="lineage" data-arg="${id}">View lineage tree</button>`:''}
      <p><span class="dim">Starting fleet:</span> ${esc(fleet)}</p>${a.cmd?`<p><span class="dim">Command:</span> <b class="gilt">${esc(a.cmd.n)}</b>. ${esc(cmdDesc(a.cmd,0,pickedFaction))} <span class="dim">Gets stronger each round you hold it.</span></p>`:''}
      <div class="foot">${un?`<button class="${pickedAdmiral===id?'primary':''}" data-act="pickAdmiral" data-arg="${id}">${pickedAdmiral===id?'Selected':'Select'}</button>`:`<button ${(META.renown||0)>=a.cost?'':'disabled'} data-act="buyAdmiral" data-arg="${id}">Unlock for ${a.cost} renown</button>`}</div></div>`; }).join('');
  show(`<div class="screen"><div class="page">
    <h2 class="gothic">Choose your faction</h2>
    <p class="lede">Your faction sets your ships and shipyards. Each run you face three of the other five, in a random order, with rival raiders along the way.</p>
    <div class="facs" style="display:flex;flex-wrap:wrap;gap:8px;margin-bottom:18px">${RUN_FACTIONS.map(f=>`<button class="facpick${pickedFaction===f?' on':''}" data-act="pickFaction" data-arg="${f}">${esc(FACTIONS[f].n)}</button>`).join('')}</div>
    <h2 class="gothic">Choose your admiral</h2>
    <p class="lede">Your admiral sets the fleet you start with and a doctrine that shapes every battle.</p>
    <div class="cards">${cards}</div>
    ${runOptionsHtml()}
    <div class="row" style="margin-top:22px"><button class="primary" ${admiralOwned(pickedAdmiral)?'':'disabled'} data-act="startRun">Launch the ${runWord(pickedFaction)}</button><button data-act="title">Back</button></div>
  </div></div>`);
}
ACT.pickAdmiral=a=>{ if(!admiralOwned(a)) return; if(pickedAdmiral!==a){ runOpt.alt=false; runOpt.cmdAlt=false; } pickedAdmiral=a; admiralScreen(); };
let pickedFaction=(META.opts&&META.opts.lastFac)||'voidsworn';
ACT.pickFaction=f=>{ pickedFaction=f; META.opts=META.opts||{}; META.opts.lastFac=f; admiralScreen(); };
// Issue 1217 phase 4: a Launch after Back reuses the random state the dropped run started from, so Back then Launch cannot
// reroll patrons, founder relic, map or the aspect offer. Twin: ACT_startRun in godot/campaign/campaign.gd.
let launchRng=-1;
ACT.startRun=()=>{ if(!admiralOwned(pickedAdmiral)) return; const ml=masteryLevel(pickedAdmiral); if(META.parkedRng!=null){ rndSeed(META.parkedRng); delete META.parkedRng; } launchRng=RNG_S>>>0; newRun(pickedAdmiral,pickedFaction,{alt:runOpt.alt&&ml>=1,cmdAlt:runOpt.cmdAlt&&ml>=3,heat:heatUnlocked()?runOpt.heat.slice():[]});
  try{ tel('run_start',{fac:RUN.fac,foes:RUN.foes,admiral:pickedAdmiral,patrons:RUN.patrons,mastery:RUN.mastery,alt:!!RUN.altFleet,cmd:RUN.cmdOverride?RUN.cmdOverride.id:null,heat:RUN.heat,gift:RUN.giftBoon||null}); }catch(e){} aspectScreen(); };
// ---------- run options: mastery unlocks and Heat ----------
const runOpt={alt:false,cmdAlt:false,heat:[]};
// Heat opens after the first loss; a winner from an older profile keeps it open too.
function heatUnlocked(){ const s=META.stats||{}; return (s.losses||0)>0||(s.wins||0)>0; }
function masteryBar(id){ const l=masteryLevel(id), x=masteryXP(id), thresholds=masteryThresholds(id), nx=thresholds[l+1];
  const tree=!!LINEAGE_TREES[id], build=tree?lineageBuild(id):null, hasCap=!!build&&build.capstone!=null; let label, right, f;
  if(hasCap){ const cm=capstoneMasteryLevel(id), cmNext=capstoneMasteryNext(id), base=cm>0?CAPSTONE_MASTERY_XP[cm-1]:thresholds[thresholds.length-1];
    label=`Capstone mastery ${cm}/${CAPSTONE_MASTERY_XP.length}`;
    right=cmNext?`${x}/${cmNext}: next ${esc(capstoneMasteryPerk(cm+1).n.toLowerCase())}`:'fully mastered';
    f=cmNext?Math.min(1,(x-base)/(cmNext-base)):1; }
  else { label=`Mastery ${l}/${thresholds.length-1}`;
    right=nx?`${x}/${nx}: next ${esc(masteryPerk(l+1).n.toLowerCase())}`:(tree?'Level 8 reached: choose a Command evolution':'mastered');
    f=nx?Math.min(1,(x-thresholds[l])/(nx-thresholds[l])):1; }
  return `<div style="margin:6px 0 2px;font-size:13px"><span class="gilt">${label}</span> <span class="dim num">${right}</span><div class="bar" style="margin-top:3px"><i style="width:${Math.round(f*100)}%;background:var(--gilt)"></i></div></div>`; }
// Job 7 step 14: the mastery levels on the chosen capstone evolution, in the same block as the evolution choice.
function capstoneMasteryHtml(id){
  const tree=LINEAGE_TREES[id]; if(!tree) return '';
  const build=lineageBuild(id);
  if(build.capstone==null) return `<p class="dim">Choose a Command evolution to open capstone mastery at 320, 440 and 600 XP.</p>`;
  const chosen=tree.capstones[build.capstone], xp=masteryXP(id), l=capstoneMasteryLevel(id), next=capstoneMasteryNext(id);
  const rows=CAPSTONE_MASTERY_PERKS.map((p,i)=>`<div class="card ${l>i?'sel':''}" style="margin-bottom:10px;${l<=i?'opacity:.55;':''}"><h3>Mastery ${roman(i+1)}${l>i?' (earned)':''}</h3><p>${esc(p.d)}</p><p class="dim num">${CAPSTONE_MASTERY_XP[i]} XP</p></div>`).join('');
  return `<h3 style="margin-top:18px">Capstone mastery: ${esc(chosen.n)}</h3><p class="dim">${next==null?`${xp} XP. This evolution is at full mastery.`:`${xp} / ${next} XP. ${next-xp} XP to capstone mastery ${roman(l+1)}.`}</p><div class="cards">${rows}</div>`;
}
function runOptionsHtml(){ const id=pickedAdmiral, a=ADMIRALS[id], ml=masteryLevel(id), parts=[];
  if(ml>=1){ const ap=altFleetPlan(id,pickedFaction), alt=ap.fleet.map(t=>HULLS[t].n).join(', ')+(ap.mod?` (the carrier starts with a ${MODULES[ap.mod].n.toLowerCase()})`:''), std=a.start.map(t=>HULLS[equivHull(t,pickedFaction)].n).join(', ');
    parts.push(`<div class="card"><h3>Starting fleet</h3><button class="choice ${!runOpt.alt?'sel':''}" data-act="optAlt" data-arg="0"><b>Standard</b><small>${esc(std)}</small></button><button class="choice ${runOpt.alt?'sel':''}" data-act="optAlt" data-arg="1"><b>Alternate</b><small>${esc(alt)}</small></button></div>`); }
  if(ml>=3&&a.cmd){ const c2=altCommand(id); if(c2) parts.push(`<div class="card"><h3>Command</h3><button class="choice ${!runOpt.cmdAlt?'sel':''}" data-act="optCmd" data-arg="0"><b>${esc(a.cmd.n)}</b><small>${esc(cmdDesc(a.cmd,0,pickedFaction))}</small></button><button class="choice ${runOpt.cmdAlt?'sel':''}" data-act="optCmd" data-arg="1"><b>${esc(c2.n)}</b><small>${esc(cmdDesc(c2,0,pickedFaction))}</small></button></div>`); }
  if(heatUnlocked()){ const hl=heatLevel(runOpt.heat), best=(META.heatBest||{})[pickedFaction]||0;
    parts.push(`<div class="card"><h3>Heat <span class="gilt num">${hl}</span> <span class="dim" style="font-size:14px">+${hl*10}% renown${best?` \u00b7 best win with this faction: Heat ${best}`:''}</span></h3><p class="dim" style="font-size:13.5px">Optional rules that make the run harder. Pick any.</p>${Object.entries(HEAT).map(([k,h])=>`<button class="choice ${runOpt.heat.includes(k)?'sel':''}" data-act="optHeat" data-arg="${k}"><b>${esc(h.n)} <span class="dim">+${h.w}</span></b><small>${esc(h.d)}</small></button>`).join('')}</div>`); }
  else parts.push(`<div class="card locked"><h3>Heat</h3><p class="dim">Lose a run to unlock Heat: optional rules that make runs harder and pay more renown.</p></div>`);
  return `<h2 class="gothic" style="margin-top:22px">Run options</h2><div class="cards">${parts.join('')}</div>`; }
ACT.optAlt=v=>{ runOpt.alt=v==='1'; admiralScreen(); };
ACT.optCmd=v=>{ runOpt.cmdAlt=v==='1'; admiralScreen(); };
ACT.optHeat=k=>{ const i=runOpt.heat.indexOf(k); if(i>=0) runOpt.heat.splice(i,1); else runOpt.heat.push(k); admiralScreen(); };
// like choosing a weapon aspect: three random aspects for the flagship, and the pick shapes the whole run
function aspectScreen(){ const f=ensureFlagship(), opts=shuffle(Object.keys(ASPECTS)).slice(0,(RUN.mastery||0)>=2?4:3); window._aspOffer=opts;
  show(`<div class="screen"><div class="page"><h2 class="gothic">Choose your flagship's aspect</h2>
    <p class="lede">The <b>${esc(f.name)}</b> (${esc(HULLS[f.tpl].n)}) carries your flag. Pick one aspect for it; it lasts the whole run, and passes to your next-largest ship if the flagship falls.</p>
    <div class="cards">${opts.map(k=>`<div class="card"><h3>${esc(ASPECTS[k].n)}</h3><p>${esc(ASPECTS[k].d)}</p><div class="foot"><button class="primary" data-act="pickAspect" data-arg="${k}">Take this aspect</button></div></div>`).join('')}</div>
    <div class="row" style="margin-top:14px"><button data-act="backToSetup">Back</button></div>
    ${RUN.giftBoon?`<p class="gilt" style="margin-top:14px">A gift from ${esc(PATRONS[BOONS[RUN.giftBoon].p].n)}, now Synced with you: <b>${esc(BOONS[RUN.giftBoon].n)}</b>.</p>`:''}${RUN.heat&&RUN.heat.length?`<p class="blood" style="margin-top:8px">Heat ${heatLevel(RUN.heat)}: ${RUN.heat.map(k=>esc(HEAT[k].n)).join(', ')}.</p>`:''}
    <p class="dim" style="margin-top:16px">Cores in range of this ${runWord()}: ${RUN.patrons.map(p=>`<b style="color:${PATRONS[p].col}">${esc(PATRONS[p].n)}</b> (${esc(PATRONS[p].theme.toLowerCase())})`).join('; ')}. Win battles carrying their signal to earn their protocols.</p>
  </div></div>`); }
// Issue 1217 phase 4: Back from the flagship page drops the unplayed new run, its save and its count (its starting random state stays parked for the next Launch), and returns to the
// faction and admiral page with every pick kept. Twin: ACT_backToSetup in godot/campaign/campaign.gd.
ACT.backToSetup=()=>{ if(!RUN||RUN.aspect) return; if(launchRng>=0) META.parkedRng=launchRng; META.stats.runs=Math.max(0,(META.stats.runs||0)-1); RUN=null; SAVED_RUN=null; Persist.save(); admiralScreen(); };
ACT.pickAspect=k=>{ if(!ASPECTS[k]||!RUN) return; changeFleet(()=>{ RUN.aspect=k; ensureFlagship(); }); try{ tel('aspect_pick',{id:k,offered:window._aspOffer,fac:RUN.fac}); }catch(e){} saveRun(); introModal(); };
function introModal(){
  mapScreen();
  const F=FACTIONS[RUN.map.fac];
  modal(`<h2>Sector I</h2><p>The ${runWord()} crosses into contested space. Long-range scans confirm <b>${esc(F.n)}</b> activity along every jump route.</p><p class="muted">${esc(F.blurb)}</p>${(()=>{ const c=sectorCond(); return c?`<p class="gilt">Sector condition: <b>${esc(c.n)}</b>. <span class="muted">${esc(c.d)}</span></p>`:''; })()}
    <p class="muted">Pick a route across the sector map. Battles carrying a core’s signal pay out that core’s protocols, so the route you choose shapes your build. The flagship of the sector waits at the far end.</p><button class="primary" data-act="closeModal">Plot a course</button>`);
}

// ---------- progression: what carries between runs ----------
let progTab='variants';
function favFirst(){ const lf=(META.opts&&META.opts.lastFac)||'voidsworn'; return [lf,...RUN_FACTIONS.filter(f=>f!==lf)]; } // your current faction first
function legacyScreen(){
  const tabs=[['variants','Hull variants'],['legacy','Legacy'],['mastery','Admiral mastery'],['favour','Core sync'],['heat','Heat'],['fallen','Hall of the fallen']];
  let body='';
  if(progTab==='variants'){ body=`<p class="lede">Spend renown to add a variant hull to your faction's shipyards. It sits beside the standard hull whenever that hull is in stock. <span class="gilt num">You have ${META.renown||0} renown.</span> Renown comes from every run: battles, elites, flagships and sectors reached, plus 10% per Heat level.</p>`+
      favFirst().map(f=>{ const vs=Object.entries(HULL_VARIANTS).filter(([vid,v])=>HULLS[v.base].fac===f); return `<h3 style="margin:20px 0 8px">${esc(FACTIONS[f].n)}</h3><div class="cards">${vs.map(([vid,v])=>{ const own=!!(META.variants||{})[vid], t=HULLS[vid];
        return `<div class="card ${own?'sel':''}"><h3>${esc(v.n)}</h3><p class="dim" style="font-size:13.5px">Variant of the ${esc(HULLS[v.base].n)}</p><p>${esc(v.d)}</p><p class="num" style="font-size:13.5px">${t.cp} CP. Hull ${t.hp}, shields ${t.sh}, speed ${t.sp}. ${t.w.map(([id,a])=>W[id].n+' ('+(a==='T'?'turret':ARC_NAME[a].toLowerCase())+')').join(', ')}.</p><div class="foot">${own?'<span class="verd">In your shipyards</span>':v.arc?`<span class="dim">Finish the ${esc(FACTIONS[v.arc].n)} story to unlock</span>`:`<button ${(META.renown||0)>=v.cost?'':'disabled'} data-act="buyVariant" data-arg="${vid}">Unlock for ${v.cost} renown</button>`}</div></div>`; }).join('')}</div>`; }).join(''); }
  // R1 (PROG-2): the Legacy unlocks get a screen again (the purchase handler had no button since the screen was folded into Progression)
  if(progTab==='legacy'){ body=`<p class="lede">Spend renown on lasting advantages for every later run. <span class="gilt num">You have ${META.renown||0} renown.</span></p><div class="cards">${Object.entries(LEGACY).map(([id,u])=>{ const own=!!META.unlocked[id], lock=u.req&&!META.unlocked[u.req];
      return `<div class="card ${own?'sel':''}"><h3>${esc(u.n)}</h3><p class="dim" style="font-size:13.5px">${esc(u.group)}</p><p>${esc(u.d)}</p><div class="foot">${own?'<span class="verd">Unlocked</span>':lock?`<span class="dim">Needs ${esc(LEGACY[u.req].n)} first</span>`:`<button ${(META.renown||0)>=u.cost?'':'disabled'} data-act="buyLegacy" data-arg="${id}">Unlock for ${u.cost} renown</button>`}</div></div>`; }).join('')}</div>`; }
  if(progTab==='mastery'){ body=`<p class="lede">Every run levels up the admiral who led it: 1 per battle won, 2 per elite, 5 per flagship and 10 for a victory.</p><div class="cards">${MASTERY_PERKS.slice(1).map((m,i)=>`<div class="card"><h3>Level ${i+1}: ${esc(m.n)}</h3><p>${esc(m.d)}</p><p class="dim num">${MASTERY_XP[i+1]} mastery</p></div>`).join('')}<div class="card"><h3>Capstone mastery</h3><p>Choose a Command evolution at level 8 (230 XP), then keep deepening it at 320, 440 and 600 XP.</p></div></div>`+
      favFirst().map(f=>`<h3 style="margin:20px 0 8px">${esc(FACTIONS[f].n)}</h3><div class="cards">${Object.entries(ADMIRALS).filter(([id,a])=>(a.fac||'voidsworn')===f).map(([id,a])=>`<div class="card"><h3>${esc(a.n)}</h3><p class="gilt" style="font-size:14px">${esc(a.doc)}</p>${masteryBar(id)}<p class="dim">${META.heirs[a.fac||'voidsworn']===id?'Heir: 50%':'Shadow: 25%'} XP while benched</p>${LINEAGE_TREES[id]?`<button data-act="lineage" data-arg="${id}">View lineage tree</button>`:''}</div>`).join('')}</div>`).join(''); }
  if(progTab==='favour'){ body=`<p class="lede">Every protocol you take raises your sync with that core (rare protocols count double, epic triple).</p><div class="cards">${FAVOUR_TIERS.slice(1).map(t=>`<div class="card"><h3>${esc(t.n)} <span class="dim num">${t.at}+</span></h3><p>${esc(t.d)}</p></div>`).join('')}</div><div style="margin-top:14px">`+
      Object.entries(PATRONS).map(([p,P])=>{ const f=favourOf(p), t=favourTier(p), nx=FAVOUR_TIERS[t+1]; return `<div class="favrow"><div class="sg" style="background:${P.col}">${P.glyph}</div><div><b>${esc(P.n)}</b><div class="dim" style="font-size:13px">${esc(P.theme)}</div></div><div class="num" style="text-align:right"><b style="color:${P.col}">${esc(FAVOUR_TIERS[t].n)}</b><div class="dim" style="font-size:12.5px">${f}${nx?` / ${nx.at}`:''}</div></div></div>`; }).join('')+'</div>'; }
  if(progTab==='heat'){ const open=heatUnlocked(); body=`<p class="lede">${open?'Heat is open. Pick rules on the admiral screen before a run; each level adds 10% renown.':'Lose a run to open Heat.'}</p><div class="cards">${Object.entries(HEAT).map(([k,h])=>`<div class="card"><h3>${esc(h.n)} <span class="dim">+${h.w}</span></h3><p>${esc(h.d)}</p></div>`).join('')}</div>
      <h3 style="margin:20px 0 8px">Best Heat won</h3><div class="cards">${RUN_FACTIONS.map(f=>`<div class="card"><h3>${esc(FACTIONS[f].n)}</h3><p class="num ${(META.heatBest||{})[f]?'gilt':'dim'}">${(META.heatBest||{})[f]?'Heat '+META.heatBest[f]:((META.stats.wonFacs||[]).includes(f)?'Won at Heat 0':'Not yet won')}</p></div>`).join('')}</div>`; }
  if(progTab==='fallen'){ const fallen=(META.fallen||[]).slice(-40).reverse(); body=fallen.length?`<div class="cards">${fallen.map(f=>`<div class="card"><h3>${esc(f.name)}</h3><p>${esc(rankName(f))} of the ${esc(f.ship)}</p><p class="dim">Lost in sector ${roman(f.sector)}</p></div>`).join('')}</div>`:'<p class="muted">No captain has died yet.</p>'; }
  show(`<div class="screen"><div class="page">
    <h2 class="gothic">Progression</h2>
    <p class="muted num">Runs launched: ${META.stats.runs}. Deepest sector reached: ${META.stats.best||0}. Runs won: ${META.stats.wins}. Renown: <span class="gilt">${META.renown||0}</span>.</p>
    <div class="progtabs">${tabs.map(([k,n])=>`<button class="${progTab===k?'on':''}" data-act="progTab" data-arg="${k}">${n}</button>`).join('')}</div>
    ${body}
    <div class="row" style="margin-top:24px"><button class="primary" data-act="title">Back to title</button></div>
  </div></div>`);
}
ACT.legacy=()=>legacyScreen();
ACT.progTab=k=>{ progTab=k; legacyScreen(); };
ACT.buyVariant=id=>{ const v=HULL_VARIANTS[id]; META.variants=META.variants||{}; if(!v||v.arc||META.variants[id]||(META.renown||0)<v.cost) return; /* R41: arc variants are earned, never bought */ META.renown-=v.cost; META.variants[id]=true; try{ tel('variant_buy',{id,cost:v.cost}); }catch(e){} Persist.save({meta:true}); legacyScreen(); };
ACT.buyLegacy=id=>{ const u=LEGACY[id]; if(!u||META.unlocked[id]||(u.req&&!META.unlocked[u.req])||(META.renown||0)<u.cost) return; META.renown-=u.cost; META.unlocked[id]=true; Persist.save({meta:true}); legacyScreen(); };
ACT.buyAdmiral=id=>{ const a=ADMIRALS[id]; if(!a||admiralOwned(id)||(META.renown||0)<a.cost) return; META.renown-=a.cost; META.admirals[id]=true; try{ tel('admiral_buy',{id,cost:a.cost}); }catch(e){} Persist.save({meta:true}); ACT.pickAdmiral(id); }; // R1 (PROG-2): bought on the admiral screen, where locked admirals show

// ---------- lineage trees ----------
function lineageScreen(id){
  const tree=LINEAGE_TREES[id]; if(!tree) return;
  const build=lineageBuild(id), nodes=lineageNodes(id), level=masteryLevel(id), pending=Math.max(0,Math.min(3,level-4)-build.picks.length);
  const nodeHtml=n=>`<div class="card ${n.state==='chosen'?'sel':''}" style="margin-bottom:10px;${n.state==='locked'?'opacity:.55;':''}"><h3>${esc(n.n)}</h3><p>${esc(n.d)}</p><button data-act="offerLineage" data-arg="${n.key}" ${lineageCanPick(n.key)?'':'disabled'}>${{chosen:'Recorded',locked:'Locked until reset',available:'Choose this skill',future:'Not yet available'}[n.state]}</button></div>`;
  show(`<div class="screen"><div class="page"><h2 class="gothic">${esc(ADMIRALS[id].n)}</h2><p class="lede">Recorded in the glass. One pick at each of levels 5, 6 and 7. Choose a branch, then one skill at its next tier. Its partner locks until you reset this line.</p>${masteryBar(id)}<p class="gilt">${pending} branch pick${pending===1?'':'s'} ready. Capstone at level 8 (230 XP).</p><p class="dim">Command skills and capstones use ${esc(ADMIRALS[id].cmd.n)}, the primary Command. Fleet and flagship branches open their first tier.</p>${lineageBetweenRuns()?'':'<p class="blood">Finish or abandon your saved run before changing this line.</p>'}
  <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:16px;margin-top:18px"><section><h3>Trunk: levels 1 to 4</h3>${MASTERY_PERKS.slice(1).map((m,i)=>`<div class="card" style="margin-bottom:10px"><h3>${i+1}. ${esc(m.n)}</h3><p>${esc(m.d)}</p><p class="dim">${MASTERY_XP[i+1]} XP: ${level>i?'earned':'not yet earned'}</p></div>`).join('')}</section>${Object.entries(tree.branches).map(([b,branch])=>`<section><h3>${b==='A'?'[+] Command':b==='B'?'[=] Fleet':'[*] Flagship and line'}: ${esc(branch.n)}</h3>${branch.tiers.map((pair,t)=>`<h4>Tier ${t+1}</h4>${nodes.filter(n=>n.branch===b&&n.tier===t+1).map(nodeHtml).join('')}`).join('')}</section>`).join('')}</div>
  <section style="border:2px solid var(--gilt);padding:16px;margin:20px 0"><h3>Level 8: Command evolution</h3><div class="cards">${nodes.filter(n=>n.branch==='cap').map(nodeHtml).join('')}</div>${capstoneMasteryHtml(id)}</section><p class="dim">Reset clears all branch picks and the capstone. XP and trunk perks stay. This line has been reset ${build.respecs} time${build.respecs===1?'':'s'}. You have ${META.renown||0} renown.</p><div class="row"><button data-act="offerRespec" data-arg="${id}" ${lineageCanRespec(id)?'':'disabled'}>Reset line: ${lineageRespecCost(id)} renown</button><button data-act="progTab" data-arg="mastery">Back to Admiral mastery</button></div></div></div>`);
}
ACT.lineage=id=>lineageScreen(id);
ACT.offerLineage=key=>{ if(!lineageCanPick(key)) return; const n=lineageNodes(key.split(':')[0]).find(n=>n.key===key); modal(`<h2>Record ${esc(n.n)}?</h2><p>${esc(n.d)}</p><p class="dim">The other skill at this tier locks until you pay to reset this line.</p><div class="row"><button class="primary" data-act="confirmLineage" data-arg="${key}">Confirm choice</button><button data-act="closeModal">Back</button></div>`); };
ACT.confirmLineage=key=>{ if(!lineagePick(key)) return; Persist.save({meta:true}); lineageScreen(key.split(':')[0]); };
ACT.offerRespec=id=>{ if(!lineageCanRespec(id)) return; modal(`<h2>Reset ${esc(ADMIRALS[id].n)}?</h2><p>Spend ${lineageRespecCost(id)} renown to clear every branch pick and the capstone. Keep all XP and trunk perks.</p><div class="row"><button class="primary" data-act="confirmRespec" data-arg="${id}">Reset for ${lineageRespecCost(id)} renown</button><button data-act="closeModal">Back</button></div>`); };
ACT.confirmRespec=id=>{ if(!lineageRespec(id)) return; Persist.save({meta:true}); lineageScreen(id); };

// ---------- help ----------
function helpScreen(){
  show(touchWords(`<div class="screen"><div class="page" style="max-width:820px">
    <h2 class="gothic">How to play</h2>
    <p class="lede">Embers of the Hollow Sun is a roguelite. Each run crosses three sectors, each ending in a flagship battle. Ships and captains you lose are gone for the run; every faction, admiral and ship is available from the start.</p>
    <p>What carries between runs (Progression, on the title screen): <b>renown</b> buys hull variants for your shipyards; each <b>admiral</b> levels up as you fly with them, unlocking an alternate fleet, a fourth aspect, a second Command and a veteran flag captain; <b>cores</b> sync with you as you take their protocols, offering rarer protocols and eventually a gift at the start of a run; and after your first loss, <b>Heat</b> lets you add harder rules for more renown. After each sector flagship falls, the fleet docks at a shipyard before its next fight.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Your turn</h3>
    <p>Every ship can move, turn and fire each of its weapons once per turn, in any order. Click a ship, then click a highlighted hex to move. Moving forward costs 1 movement. Turning 60\u00b0 also costs 1 movement and uses one of the ship\u2019s turns; big ships only get one turn per round, so plan their heading early. Press <kbd>Q</kbd> and <kbd>E</kbd> to turn in place.</p>
    <p>Thrusters keep you from getting boxed in. A ship can slip into either forward-diagonal hex, or back off one hex, without changing its heading (2 movement each; a slow ship can always spend its whole move on one hop). It can climb over a rock or wreck, or dive under an enemy ship, for +1 movement, but cannot stop there. Each faction bends one of these rules: see the Helm panel.</p>
    <p>Ships fight on the move. Tap an enemy your guns can't reach yet and the ship burns to the best spot and fires as it arrives.</p>
    <p>Moving matters. A ship that did not move last turn gets hit more easily (+10 to hit). One that moved 3+ hexes is harder to hit (\u22125). Port and starboard guns hit 10% harder on a raking pass, after moving 2+ hexes.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Firing arcs</h3>
    <p>Weapons only fire into their arc. Prow weapons cover the 120\u00b0 in front, port and starboard broadsides each cover a wide 120\u00b0 cone to the side, and turrets fire anywhere. The tinted hexes around a selected ship show where its guns reach: amber for the prow, teal for broadsides. Click an enemy to fire everything that can reach it, or press a number key to fire a single weapon.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Shields and flanking</h3>
    <p>Each ship has one shield pool that covers four sides: prow, port, starboard and rear. A hit drains the pool through the side that points at the attacker, and each side catches only its share (the prow the most, the rear the least). A side hit again draws extra power at a loss, and when the pool runs dry every side drops at once. Shields regenerate at the start of each of your turns. Rear hits halve armor and are far more likely to crit, so getting behind a battleship matters. Lances and bombers punch partly or fully through shields. Ion cannons shred shields; null weapons mostly ignore them.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Different fights</h3>
    <p>Each fight on the sector map is labelled with its goal. Engagements and ambushes end when one fleet breaks. In <b>Hold the station</b> you keep enemies off a friendly station until round 6 ends. In a <b>Hunt</b> their flagship runs and jumps out after round 6. In an <b>Intercept</b> you destroy transports before they cross the field. In a <b>Breakthrough</b> you get half your fleet off the far edge. Missing a Hunt or Intercept still pays half; losing the station or a breakthrough means a retreat, not the end of the run. Tap the chip under the top bar in battle for the rules and the coloured hexes.</p>
    <p>Some fights change partway through: reinforcements for either side, or a solar flare that knocks out every shield for a round. You always get a round of warning.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Brace, abilities and Command</h3>
    <p>Brace is the alternative to firing: a ship that hasn\u2019t fired can brace to take 40% less hull damage until your next turn (it can still move first). To ram, point your bow at an enemy ship with at least one clear hex between you and enough movement left to cross the gap: a red lane shows when a ram is ready, and red-ringed move hexes line one up. A longer run-up hits harder; a ram can\u2019t take more than 40% of a healthy ship\u2019s hull without protocols. Boarding an adjacent enemy can capture it for your fleet; enemy boarders can cripple your ships, but never take them. Carriers start every battle with their wings already flying; the wings fight on their own unless you order them: tap a wing, then tap an enemy ship to strike it or one of your ships to guard it. The carrier\u2019s launch only replaces wings you lose. Most hulls have an ability with a cooldown, and each faction has its own: Hegemony ion pulses, Hullbreaker overburn, Chorus regrowth and frenzy, Glasswright phase jumps, Eclipse repair swarms, and the Crusade\u2019s burns, reloads and shield surges. Enemy flagships carry a Command too: they announce it a round ahead, so you can brace or scatter. Once per battle, your admiral\u2019s Command is a fleet-wide signature move. It gets stronger each round you hold it (power 1 in round 1, 2 in round 2, full power from round 3, and losing a ship charges it a level), so the choice is a smaller boost now or a bigger one later, if the fight lasts that long. The ship panel shows exactly what the next level adds.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Cores, protocols and your flagship</h3>
    <p>Each run, four of the six cores are in range. Battles on the map carry a core\u2019s signal: win there and that core offers three protocols, and you take one. Protocols change the rules (fires, chain explosions, rams that shake the whole formation) and come in Common, Rare and Epic strength. Hold protocols from two cores and a duo protocol can appear. At the start of a run you also pick one of three aspects for your flagship, which shapes how it fights for the whole run. Each sector\u2019s enemies have a set strength, so a stronger fleet feels stronger; a battered fleet meets slightly smaller ones.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Between battles</h3>
    <p>Hull damage carries between battles. Shipyards sell hulls, refits and repairs, and can upgrade a ship\u2019s Mark. Captains earn experience and pick a perk at each promotion. Salvage gives fleet-wide bonuses that last for the run.</p>
    <h3 class="gilt keysonly" style="margin:18px 0 6px">Keys</h3>
    <p class="keysonly"><kbd>Tab</kbd> next ship, <kbd>Q</kbd>/<kbd>E</kbd> turn, <kbd>1</kbd>\u2013<kbd>6</kbd> arm a weapon, <kbd>B</kbd> brace, <kbd>A</kbd> toggle arcs, <kbd>Esc</kbd> or right-click to cancel, <kbd>Enter</kbd> end turn.</p>
    <div class="row" style="margin-top:24px"><button class="primary" data-act="title">Back</button></div>
  </div></div>`));
}
ACT.help=()=>helpScreen();

// ---------- run end ----------
const WIN_TITLE={voidsworn:'The crusade endures',hegemony:'The Hegemony stands',corsair:'Strongest keeps it',chorus:'The Chorus swells',ithar:'The light is kept',deathless:'Noon returns'};
function runRecap(victory){ const s=RUN.stats, mins=RUN.t0?Math.max(1,Math.round((Date.now()-RUN.t0)/60000)):null;
  const tile=(n,l)=>`<div class="rtile"><b class="num">${n}</b><span>${l}</span></div>`;
  const tiles=`<div class="rtiles">${tile(s.battles,'battles won')}${tile(s.bosses,'flagships destroyed')}${tile(s.kills,'enemy ships destroyed')}${tile(s.lost||0,'ships lost')}${mins?tile(mins<90?mins+'m':(mins/60).toFixed(1)+'h','played'):''}</div>`;
  const fl=(RUN.fleet||[]).filter(x=>x.hp>0), score=x=>x.car?x.car.dealt+x.car.kills*40:0, best=fl.slice().sort((a,b)=>score(b)-score(a))[0];
  const row=x=>{ const c=x.car||{dealt:0,kills:0,battles:0}; return `<div class="rrow${x===best&&score(x)>0?' star':''}"><div><b>${esc(x.name)}</b> <span class="dim">${esc(HULLS[x.tpl].n)}</span><div class="dim" style="font-size:12px">${esc(rankName(x.cap))} ${esc(x.cap.name)}</div></div><div class="num">${c.kills} kills<br><span class="dim">${c.dealt} dmg</span></div></div>`; };
  const stand=best&&score(best)>0?`<p class="standout">Standout ship: <b class="gilt">${esc(best.name)}</b>, ${best.car.kills} kills and ${best.car.dealt} damage across ${best.car.battles} battle${best.car.battles>1?'s':''}.</p>`:'';
  const fleet=fl.length?`<h3 class="rhead">${victory?'The fleet that finished it':'Still flying'}</h3><div class="rfleet">${fl.sort((a,b)=>score(b)-score(a)).map(row).join('')}</div>`:'';
  return tiles+stand+fleet; }
function facProgress(fac){ let total=0; for(const id of Object.keys(ADMIRALS)) if((ADMIRALS[id].fac||'voidsworn')===fac) total+=masteryXP(id); return total; }
function nextFacPick(){ const won=(META.stats.wonFacs||[]); let pool=RUN_FACTIONS.filter(f=>f!==RUN.fac&&!won.includes(f)); if(!pool.length) pool=RUN_FACTIONS.filter(f=>f!==RUN.fac); if(!pool.length) return null;
  let best=pool[0], bestv=facProgress(best); for(const f of pool){ const v=facProgress(f); if(v>bestv){ best=f; bestv=v; } } return best; }
// Shadow learning is per line. A full line sends its excess to the faction's
// shadow balance; distribute it among uncapped benched lines, keeping any rest.
function shadowAdmirals(fac, flown){ return Object.keys(ADMIRALS).filter(id=>(ADMIRALS[id].fac||'voidsworn')===fac&&id!==flown); }
function shadowRate(id){ return META.heirs[(ADMIRALS[id].fac||'voidsworn')]===id?.5:.25; }
// Design 4.5: the heir row names the candidate then their rank. A name that already opens with a
// rank word keeps that word in the rank slot; otherwise the candidate holds their faction's top rank.
let ADMIRAL_RANK_WORDS=null;
function admiralRankWords(){
  if(ADMIRAL_RANK_WORDS) return ADMIRAL_RANK_WORDS;
  const out=[];
  for(const f of Object.keys(CAPTAINS)) for(const r of CAPTAINS[f].ranks) if(!out.includes(r)) out.push(r);
  for(const w of ['High Admiral','First Admiral','Line Admiral','Fleet Marshal','Oath-Captain','Admiral']) if(!out.includes(w)) out.push(w);
  ADMIRAL_RANK_WORDS=out.sort((a,b)=>b.length-a.length); return ADMIRAL_RANK_WORDS;
}
function heirLabel(id){
  const nm=ADMIRALS[id].n;
  for(const w of admiralRankWords()) if(nm.indexOf(w+' ')===0) return nm.slice(w.length+1)+', '+w;
  const ranks=CAPTAINS[ADMIRALS[id].fac||'voidsworn'].ranks;
  return nm+', '+ranks[ranks.length-1];
}
function masteryCredit(id, xp){
  const cap=masteryXPCap(id), old=masteryXP(id), total=old+xp;
  META.mastery[id]=Math.max(old,Math.min(cap,total)); // a reset evolution keeps its earned XP even when the cap drops back to 230
  return {xp:Math.max(0,META.mastery[id]-old),overflow:Math.max(0,total-Math.max(cap,old))};
}
function awardLineageXP(flown, fac, xp){
  const active=masteryCredit(flown,xp), shadow=shadowAdmirals(fac,flown).map(id=>({id,xp:0,rate:shadowRate(id)}));
  let pool=(META.shadowPool[fac]||0)+active.overflow;
  for(const row of shadow){ const gain=masteryCredit(row.id,xp*shadowRate(row.id)); row.xp+=gain.xp; pool+=gain.overflow; }
  while(pool>0){
    const open=shadow.filter(row=>masteryXP(row.id)<masteryXPCap(row.id));
    if(!open.length) break;
    const weight=open.reduce((n,row)=>n+shadowRate(row.id),0), budget=pool; pool=0;
    for(const row of open){ const gain=masteryCredit(row.id,budget*shadowRate(row.id)/weight); row.xp+=gain.xp; pool+=gain.overflow; }
  }
  META.shadowPool[fac]=pool;
  return {mxGain:active.xp,mxOverflow:active.overflow,shadow,shadowBank:pool};
}
let debriefHeirOpen=false, debriefHeirPick='', debriefHeirNamed='';
function heirChoiceHtml(fac, flown){
  const heir=META.heirs[fac], ids=shadowAdmirals(fac,flown), fmt=n=>Math.round(n*100)/100;
  return `<h3>Heir to the line</h3><p>${heir?`${esc(ADMIRALS[heir].n)} is the current heir.`:'No heir named.'}</p>
    ${debriefHeirNamed?`<p>Named: ${esc(ADMIRALS[debriefHeirNamed].n)}. The ${esc(FACTIONS[fac].n)} line earns double shadow until you name another.</p>`:''}
    ${!ids.length?'<p>No benched admirals of this faction to name.</p>':`
    ${heir?`<button onclick="debriefHeirOpen=true;refreshDebriefHeir()">Change heir</button>`:''}
    <div ${heir&&!debriefHeirOpen?'hidden':''}><p>Name an heir to the ${esc(FACTIONS[fac].n)} line?</p>
    ${ids.map(id=>`<button onclick="event.stopPropagation();debriefHeirPick='${id}';refreshDebriefHeir()" data-act="nameHeir" data-arg="${id}" ${heir===id?'disabled':''} aria-pressed="${debriefHeirPick===id}">${esc(heirLabel(id))}. Shadow ${fmt(masteryXP(id))} XP. Double earnings for this line.</button>`).join(' ')}
    <button onclick="debriefHeirPick='';refreshDebriefHeir()">${heir?'Keep current heir.':'No heir this run.'}</button>
    <button onclick="confirmDebriefHeir()">Confirm heir</button></div>`}`;
}
function refreshDebriefHeir(){ if(heirDebrief) document.getElementById('heirChoice').innerHTML=heirChoiceHtml(heirDebrief.fac,heirDebrief.admiral); }
ACT.nameHeir=id=>{
  if(!heirDebrief||RUN||SAVED_RUN||!shadowAdmirals(heirDebrief.fac,heirDebrief.admiral).includes(id)) return;
  META.heirs[heirDebrief.fac]=id; Persist.save({meta:true});
  debriefHeirNamed=id; debriefHeirOpen=false; refreshDebriefHeir();
};
function confirmDebriefHeir(){
  if(!heirDebrief||RUN||SAVED_RUN) return;
  const id=debriefHeirPick;
  if(id&&shadowAdmirals(heirDebrief.fac,heirDebrief.admiral).includes(id)){
    ACT.nameHeir(id);
  }
  debriefHeirOpen=false; refreshDebriefHeir();
}
// Capture the paid profile once. Both debriefs read this receipt, not estimates.
function inheritanceSummary(run){
  const cy=run.carry, balance=META.renown||0, affordable=[];
  for(const [id,u] of Object.entries(LEGACY)) if(!META.unlocked[id]&&(!u.req||META.unlocked[u.req])&&u.cost<=balance)
    affordable.push({id,n:u.n,cost:u.cost,kind:'Doctrine',fresh:u.cost>balance-cy.ren});
  for(const [id,u] of Object.entries(HULL_VARIANTS)) if(!u.arc&&!(META.variants||{})[id]&&u.cost<=balance)
    affordable.push({id,n:u.n,cost:u.cost,kind:FACTIONS[HULLS[u.base].fac].n+' hull',fresh:u.cost>balance-cy.ren});
  const line=id=>{ const level=masteryLevel(id), xp=masteryXP(id), tree=!!LINEAGE_TREES[id], build=tree?lineageBuild(id):null, hasCap=!!build&&build.capstone!=null;
    const capLevel=tree?capstoneMasteryLevel(id):0, capNext=tree?capstoneMasteryNext(id):null;
    const next=hasCap?capNext:masteryThresholds(id)[level+1];
    return {id,xp,level,next:next==null?null:next,remaining:next==null?0:Math.max(0,next-xp),hasCap,capLevel,capNext}; };
  const flown=line(run.admiral), tree=!!LINEAGE_TREES[run.admiral], build=lineageBuild(run.admiral), nodes=tree?lineageNodes(run.admiral):[];
  return {balance,affordable,flown:{...flown,tree,pending:tree?Math.max(0,Math.min(3,flown.level-4)-build.picks.length):0,
    capstoneReady:tree&&nodes.some(n=>n.branch==='cap'&&n.state==='available'),chosen:nodes.filter(n=>n.state==='chosen').map(n=>n.n),earned:MASTERY_PERKS.slice(cy.mx0+1,Math.min(4,cy.mx1)+1)},
    shadow:cy.shadow.map(row=>({...line(row.id),...row,total:masteryXP(row.id)})),
    cores:Object.entries(run.coreSync||{}).filter(([p,before])=>PATRONS[p]&&favourOf(p)>before).map(([id,before])=>{
      const total=favourOf(id), tier=favourTier(id), next=FAVOUR_TIERS[tier+1];
      return {id,before,gain:total-before,total,tier,next:next?next.at:null,remaining:next?next.at-total:0,tierUp:total>=FAVOUR_TIERS[tier].at&&before<FAVOUR_TIERS[tier].at}; }),
    nem:typeof nemDebrief==='function'?nemDebrief(run):{met:0,lessons:[],rows:[]}};
}
// Job 7 step 7 (R85 Q5): the run debrief's Nemesis lesson row, one line per lesson the lost meeting recorded on the
// commander who fought it. Rows never vanish: an empty row keeps the frame and says which empty state it is.
function debriefNemName(entry){
  const title=entry.title||'', full=entry.name||'', name=title&&full.startsWith(title+' ')?full.slice(title.length+1):full;
  return name+(title?', '+title:'');
}
function nemLessonHtml(nz,run={}){
  nz=nz||{met:0,lessons:[]}; const ls=Array.isArray(nz.lessons)?nz.lessons:[], lines=[];
  for(const l of ls){ const w=nemEntry(NEM_WEAK,l.w,l.fac);
    lines.push(`<p>Nemesis lesson: ${l.taught===false?'you broke ':''}<span class="nem" title="${esc(l.name)}">${esc(debriefNemName(l))}</span>${l.taught===false?'. Weakness found: ':' beat you and taught you a weakness: '}${esc(w?w.n:"the hunter's tactics")}.</p>${l.text?`<p class="muted">${esc(l.text)}</p>`:''}`);
  }
  for(const N of Object.values(run.nems||{})){
    if(!(N.met||N.beaten||N.scars)) continue;
    const who=`<span class="nem">${esc(debriefNemName(N))}</span>`;
    for(const w of N.revealed||[]) if(NEM_WEAK[w]&&!ls.some(l=>l.fac===N.fac&&l.w===w)) lines.push(`<p>Nemesis lesson: you broke ${who}. Weakness found: ${esc(nemEntry(NEM_WEAK,w,N.fac).n)}.</p>`);
    for(const ad of N.adapt||[]) lines.push(`<p>Nemesis lesson: ${who} adapted. ${esc(nemAdaptName(ad,N.fac))}: ${esc(nemAdaptWhyLine(ad,N))}.</p>`);
    if(N.loot) lines.push(`<p>Raided: <span class="nem">${esc(N.name)}</span>'s Hullbreakers took ${N.loot} credits this run. One raider line crossed.</p>`);
    if(N.dead) lines.push(`<p>Nemesis lesson: ${who} is dead. What he taught you is yours to keep.</p>`);
  }
  if(!ls.length&&nz.met) lines.unshift('<p class="muted">No weakness was taught this run.</p>');
  return lines.join('')||'<p class="muted">No Nemesis meeting this run.</p>';
}
function debriefAffordability(run){
  const cy=run.carry, balance=cy.inheritance.balance, before=balance-cy.ren, items=[];
  for(const [id,u] of Object.entries(LEGACY)) if(!META.unlocked[id]&&(!u.req||META.unlocked[u.req])) items.push({n:u.n,cost:u.cost,tab:'legacy'});
  for(const [id,u] of Object.entries(HULL_VARIANTS)) if(!u.arc&&!(META.variants||{})[id]) items.push({n:u.n,cost:u.cost,tab:'variants'});
  for(const [id,u] of Object.entries(ADMIRALS)) if(u.cost>0&&!(META.admirals||{})[id]) items.push({n:u.n,cost:u.cost,tab:'admiral',fac:u.fac||'voidsworn'});
  if(LINEAGE_TREES[run.admiral]) items.push({n:ADMIRALS[run.admiral].n+' line reset',cost:lineageRespecCost(run.admiral),tab:'mastery'});
  items.sort((a,b)=>a.cost-b.cost); const fresh=items.filter(u=>u.cost>before&&u.cost<=balance), next=items.find(u=>u.cost>balance)||items[0];
  const target=fresh[0]||next||{tab:'legacy'};
  const text=META.opts&&META.opts.playtestAll?'Playtest: everything unlocked. Earnings recorded.':fresh.length?`Now affordable: ${esc(fresh[0].n)}, ${fresh[0].cost} renown${fresh.length>1?`, and ${fresh.length-1} more within reach.`:'.'}`:next?`Next: ${esc(next.n)} at ${next.cost}. ${Math.max(0,next.cost-balance)} more renown.`:'All rewards owned.';
  return {text,tab:target.tab,fac:target.fac};
}

function inheritanceHtml(run,victory,abandoned){
  const cy=run.carry, receipt=cy.inheritance, f=receipt.flown, s=run.stats, available=debriefAffordability(run), fmt=n=>Math.round(n*100)/100, playtest=META.opts&&META.opts.playtestAll;
  const row=(name,body)=>`<section class="inherit-row"><h3>${name}</h3>${body}</section>`;
  return `<section><h2>${abandoned?'Recorded':'WHAT THIS RUN BOUGHT'}</h2>${abandoned?'':`<p class="muted">What this ${victory?'victory':'death'} bought:</p>`}
    ${row('Doctrine and renown',`<p>Renown: ${cy.ren} earned. ${receipt.balance} in the vault.</p>${cy.ren?'':'<p>No renown earned this run</p>'}
    <p class="muted">${s.battles*2} from battles, ${s.elites*4} from elites, ${s.bosses*15} from flagships, ${Math.floor(s.kills/4)} from kills, ${(run.sector-1)*5} for sectors reached.</p>
    ${cy.hl?`<p class="muted">Heat ${cy.hl}: renown paid at x${fmt(1+.1*cy.hl)}.</p>`:''}<p title="${esc(receipt.affordable.map(u=>u.n+': '+u.cost+' renown').join('\n'))}">${available.text}</p>
    <div class="row"><button data-act="progTab" data-arg="legacy">${!playtest&&available.tab==='legacy'?'Spend renown':'View doctrine'}</button><button data-act="progTab" data-arg="variants">${!playtest&&available.tab==='variants'?'Spend renown':'View hull rewards'}</button>${available.tab==='admiral'?`<button onclick="ACT.newRunScreen();ACT.pickFaction('${available.fac}')">${playtest?'View admirals':'Unlock admirals'}</button>`:''}</div>`)}
    ${row('Lineage',`<p>${esc(ADMIRALS[f.id].n)}: +${fmt(cy.mxGain)} XP. Level ${f.level}.</p><div class="mastery-track"><div style="width:${f.next==null?100:Math.min(100,f.xp/Math.max(1,f.next)*100)}%"></div></div>
    ${cy.mxGain?'':'<p>No mastery earned this run</p>'}<p class="muted">${f.next==null?`${fmt(f.xp)} XP. ${f.hasCap?'This evolution is at full mastery.':'This line is at its current cap.'}`:`${fmt(f.xp)} of ${f.next} XP. ${fmt(f.remaining)} XP to ${f.hasCap?'capstone mastery '+roman(f.capLevel+1):'level '+(f.level+1)}.`}</p>
    <button data-act="${f.tree?'lineage':'progTab'}" data-arg="${f.tree?f.id:'mastery'}" title="${esc('Recorded skills: '+(f.chosen.join(', ')||'None yet')+'. '+f.earned.map(p=>p.n+' earned: '+p.d).join(' '))}">${f.pending?`Choose ${esc(ADMIRALS[f.id].n)}'s level ${5+lineageBuild(f.id).picks.length} skill`:f.capstoneReady?'Choose Command evolution':'View admiral line'}</button>
    ${receipt.shadow.filter(r=>r.xp>0).map(r=>`<p class="muted" title="Total ${fmt(r.total)} XP. ${r.next==null?'Fully mastered.':fmt(r.remaining)+' XP to '+(r.hasCap?'capstone mastery '+roman(r.capLevel+1):'level '+(r.level+1))+'.'}">${esc(ADMIRALS[r.id].n)}: +${fmt(r.xp)} shadow XP (Level ${r.level}).${r.rate===.5?' Heir: double rate.':''}</p>`).join('')}
    ${cy.mxOverflow?`<p class="muted">${fmt(cy.mxOverflow)} XP past this line's cap went to shadow learning.</p>`:''}${cy.shadowBank?`<p class="muted">${fmt(cy.shadowBank)} shadow XP saved for an uncapped benched line.</p>`:''}
    ${cy.hl?`<p class="muted">Heat ${cy.hl} paid ${cy.hl*2} XP to ${esc(ADMIRALS[run.admiral].n)} and ${cy.hl} XP to the faction shadow pool.</p>`:''}`)}
    ${row('Core sync',receipt.cores.length?receipt.cores.slice().sort((a,b)=>+b.tierUp-+a.tierUp).map(r=>`${r.tierUp?`<p><span style="color:${PATRONS[r.id].col}">${esc(PATRONS[r.id].n)}</span>: crossed into ${esc(FAVOUR_TIERS[r.tier].n)} this run at ${r.total} protocols.</p>`:''}<p class="muted"><span style="color:${PATRONS[r.id].col}">${esc(PATRONS[r.id].n)}</span>: ${r.next==null?`Full sync, ${r.total} protocols.`:`${r.total} of ${r.next} to ${esc(FAVOUR_TIERS[r.tier+1].n)}.`}</p>`).join(''):'<p class="muted">No protocols taken this run.</p>')}
    ${row('Nemesis lesson',nemLessonHtml(receipt.nem,run))}
    ${row('The record',`<p>${esc(STORY_BEAT3[run.fac].learning)}</p>${run.eatenCore&&PATRONS[run.eatenCore]?`<p class="muted">The swarm ate ${esc(PATRONS[run.eatenCore].n)}.</p>`:''}`)}</section>
    <section id="heirChoice" class="inherit-row">${heirChoiceHtml(run.fac,run.admiral)}</section>`;
}
function debriefFirstLoss(run,victory,abandoned){
  const first=!victory&&!abandoned&&META.stats.losses===1, crusade=run.fac==='voidsworn';
  return {first,kicker:crusade?'THE FIRST CRUSADE FALLS. THE CHALK REMEMBERS.':'THE FIRST RUN ENDS. THE NEXT INHERITS.',
    sub:`The last hull goes dark in sector ${roman(run.sector)}. `+(crusade?'The survivors will tell it differently, and the next crusade will read it in chalk before it chooses.':'This is not the end of the line. What this run earned is already on its way to the next fleet.'),
    body:crusade?'No crusade wins the first dark. That is the oath working, not failing. What this run bought is already written: renown in the vault, mastery in the bloodline, and the weakness the enemy showed you at cost. The next crusade stands at this same dark and reads what you chose. Do not mourn the fleet. Read the record.':'You will lose runs. That is the design, not a verdict. Every death names what the next generation carries: renown in the vault, mastery in the bloodline, and a lesson the enemy taught you at cost. Read the panel below as an inheritance, not a score.'};
}
const debriefStyle=`<style>
@font-face{font-family:DebriefBody;src:url("godot/ui/theme/fonts/Barlow-Regular.ttf")}
@font-face{font-family:DebriefName;src:url("godot/ui/theme/fonts/BigShouldersDisplay-VF.ttf")}
@font-face{font-family:DebriefNumber;src:url("godot/ui/theme/fonts/AzeretMono-VF.ttf")}
.debrief{--gilt:#f0eade;--blood:#ff6050;--bone:#f0eade;--bone2:#c4beb0;--bone3:#c4beb0;--dk:#080908;--k:clamp(.6,calc(100vh / 1080px),2.2);background:radial-gradient(ellipse at center,#080908 55%,#10110e);color:#f0eade;font-family:DebriefBody,Barlow,sans-serif;font-size:calc(18px * var(--k));overflow-y:auto}
.debrief .inner{width:calc(960px * var(--k));max-width:calc(100vw - 40px);text-align:left;margin:calc(20px * var(--k)) auto;padding:0}
.debrief h1{font-family:DebriefName,Barlow,sans-serif;font-size:calc(62px * var(--k));line-height:1.1;text-align:center;text-transform:uppercase;color:#f0eade;margin:0 0 calc(10px * var(--k));text-shadow:none}
.debrief .sub{font-size:calc(20px * var(--k));text-align:center;color:#c4beb0;margin:0 0 calc(10px * var(--k))}
.debrief .storyline{font-size:calc(18px * var(--k));text-align:center;color:var(--gilt);margin:0 0 calc(10px * var(--k))}
.debrief p{margin:calc(4px * var(--k)) 0;line-height:1.35}.debrief h2{font-size:calc(24px * var(--k));margin:calc(10px * var(--k)) 0}.debrief h3{font-size:calc(17px * var(--k));text-transform:uppercase;color:#c4beb0;margin:0 0 calc(4px * var(--k))}
.debrief .muted,.debrief .dim{color:#c4beb0}.debrief .nem{color:#ff6050}.debrief .inherit-row{border-top:1px solid #48443c;padding-top:calc(10px * var(--k));margin-top:calc(10px * var(--k))}
.debrief button{font-family:DebriefBody,Barlow,sans-serif;font-size:calc(17px * var(--k));border:0;border-radius:0;background:transparent;color:#f0eade;box-shadow:none;padding:calc(10px * var(--k));min-height:calc(40px * var(--k))}.debrief button:hover,.debrief button:focus-visible,.debrief button[aria-pressed=true]{text-decoration:underline;outline:1px solid #c4beb0}.debrief button.primary{border:2px solid #ff8a3a;color:#ff8a3a;min-height:calc(56px * var(--k));background:transparent}.debrief button.primary:hover{background:#ff8a3a;color:#100c08}
.debrief .mastery-track{height:calc(6px * var(--k));background:#48443c}.debrief .mastery-track>div{height:100%;background:#c4beb0}.debrief .rtiles{display:flex;flex-wrap:wrap;gap:calc(8px * var(--k));margin-top:calc(10px * var(--k))}.debrief .rtile{min-width:calc(150px * var(--k));background:none;border:0;padding:calc(8px * var(--k))}.debrief .rtile b{font-family:DebriefNumber,monospace;font-size:calc(26px * var(--k));color:#f0eade}.debrief .rtile span{display:block;max-width:calc(134px * var(--k));overflow-wrap:normal;font-size:calc(17px * var(--k))}.debrief .rrow,.debrief .rrow.star,.debrief .nextfac{background:none;border:0;border-radius:0;color:#f0eade}.debrief .rrow .dim{font-size:calc(17px * var(--k))!important}.debrief .nextfac{padding:calc(12px * var(--k)) 0}.debrief .menu{display:flex;flex-wrap:wrap;justify-content:center}.debrief [hidden]{display:none}
</style>`;
function debriefStoryLine(){ try{ return typeof storyText==='function'?String(storyText()||''):''; }catch(e){ return ''; } }
function endRun(victory, abandoned){
  if(!RUN||RUN.over) return;
  const s=RUN.stats;
  if(META.stats.finishedRuns!=null&&!RUN.over) META.stats.finishedRuns++;
  const prevBest=META.stats.best||0; META.stats.best=Math.max(prevBest, RUN.sector); if(victory){ META.stats.wins++; META.stats.wonFacs=META.stats.wonFacs||[]; if(!META.stats.wonFacs.includes(RUN.fac)) META.stats.wonFacs.push(RUN.fac); }
  else if(!abandoned) META.stats.losses=(META.stats.losses||0)+1;
  for(const f of RUN.fallen) META.fallen.push(f); if(META.fallen.length>80) META.fallen=META.fallen.slice(-80);
  try{ tel('run_end',{victory:!!victory,abandoned:!!abandoned,fac:RUN.fac,sector:RUN.sector,stats:s,mins:RUN.t0?Math.round((Date.now()-RUN.t0)/60000):null,fleet:(RUN.fleet||[]).map(x=>x.tpl),nem:typeof nemTelSummary==='function'?nemTelSummary():null}); }catch(e){} // #122: the run's Nemesis record
  // what carries forward: renown (more with Heat), admiral mastery, and a Heat record for this faction
  const hl=heatLevel(RUN.heat), ren=Math.round((typeof runRenown==='function'?runRenown():0)*(1+.1*hl)); META.renown=(META.renown||0)+ren;
  const mx0=masteryLevel(RUN.admiral), mxEarned=(s.battles-s.elites-s.bosses)+s.elites*2+s.bosses*5+(victory?10:0); /* Keep the shipped combat weights. Heat XP is paid beside them. */
  const earnings=awardLineageXP(RUN.admiral,RUN.fac,mxEarned);
  if(hl>0){ const hx=masteryCredit(RUN.admiral,hl*2); /* R63: +2 XP per Heat point to the flown line, +1 to the faction shadow pool; cap overflow joins the pool */
    earnings.mxGain+=hx.xp; earnings.mxOverflow+=hx.overflow; earnings.shadowBank=(META.shadowPool[RUN.fac]||0)+hx.overflow+hl; META.shadowPool[RUN.fac]=earnings.shadowBank; }
  const mx1=masteryLevel(RUN.admiral);
  if(typeof runXPTel==='function') runXPTel(RUN,earnings,victory); // Job 7 step 11: per run XP by line for the F1 play log report
  if(victory&&hl){ META.heatBest=META.heatBest||{}; META.heatBest[RUN.fac]=Math.max(META.heatBest[RUN.fac]||0,hl); }
  RUN.carry={ren,...earnings,mx0,mx1,hl};
  RUN.carry.inheritance=inheritanceSummary(RUN);
  RUN.over=true; SAVED_RUN=null; Persist.save();
  const nf=victory?nextFacPick():null, NF=nf&&FACTIONS[nf];
  debriefHeirOpen=false; debriefHeirPick=''; debriefHeirNamed='';
  const first=debriefFirstLoss(RUN,victory,abandoned);
  const story=debriefStoryLine(), payoff=STORY_BEAT3[RUN.fac].learning;
  const lines=`${first.first?`<p>${first.body}</p>`:''}${inheritanceHtml(RUN,victory,abandoned)}${runRecap(victory)}
    ${RUN.fallen.length?`<p class="muted">Captains lost this run: ${RUN.fallen.map(f=>esc(f.name)).join(', ')}.</p>`:''}
    ${victory?`<p class="gilt num" style="font-size:18px">${META.stats.wins>1?`Victories so far: ${META.stats.wins}`:'Your first victory.'} Won with: ${(META.stats.wonFacs||[]).map(f=>esc(FACTIONS[f].n)).join(', ')}.</p>`:`<p class="gilt num" style="font-size:20px">${RUN.sector>prevBest?`New best: sector ${roman(RUN.sector)}`:`Best so far: sector ${roman(Math.min(3,META.stats.best))}`}</p>`}
    ${NF?`<div class="nextfac"><h3>Next run</h3><b>Try the ${esc(NF.n.replace(/^The /,''))}</b><p class="muted" style="margin:4px 0 0">${esc(NF.blurb||'')}</p></div>`:''}`;
  const sub=first.first?first.sub:victory?`Three sectors broken, three flagships burning behind you. ${esc(ADMIRALS[RUN.admiral]?ADMIRALS[RUN.admiral].n:'Your admiral')} brings the ${esc(FACTIONS[RUN.fac]?FACTIONS[RUN.fac].n.replace(/^The /,''):'fleet')} home.`:abandoned?'The fleet stands down. Its deeds are recorded.':'The last hull goes dark in sector '+roman(RUN.sector)+'. The survivors will tell it differently.';
  show(`${debriefStyle}<div class="screen title recap debrief"><div class="inner">${first.first?`<p class="sub">${first.kicker}</p>`:''}
    <h1>${victory?(WIN_TITLE[RUN.fac]||'Victory'):abandoned?'Run abandoned':'The fleet is lost'}</h1>
    <div class="sub">${sub}</div>
    ${story&&story!==payoff?`<p class="storyline">${esc(story)}</p>`:''}
    ${lines}
    <div class="menu" style="margin-top:22px">${NF?`<button class="primary" data-act="nextFac" data-arg="${nf}">Play as ${esc(NF.n)}</button><button data-act="newRunScreen">Pick a faction</button>`:`<button class="primary" data-act="newRunScreen">New run</button>`}<button data-act="title">Title screen</button></div></div></div>`);
  heirDebrief={fac:RUN.fac,admiral:RUN.admiral}; RUN=null;
  if(typeof requestAnimationFrame==='function') requestAnimationFrame(()=>{ const exit=document.querySelector('.debrief .menu .primary'); if(exit) exit.focus({preventScroll:true}); });
}
ACT.nextFac=f=>{ pickedFaction=f; META.opts=META.opts||{}; META.opts.lastFac=f; admiralScreen(); };
