// ======================= UI: shell, title, meta =======================
const app=document.getElementById('app');
const tipEl=document.getElementById('tip');
const ACT={};
app.addEventListener('click',e=>{ const el=e.target.closest('[data-act]'); if(!el||el.disabled) return; const fn=ACT[el.dataset.act]; if(fn) fn(el.dataset.arg,el,e); });
function show(html){ hideTip(); closeModal(); app.innerHTML=html; }
function modal(html){ closeModal(); const m=document.createElement('div'); m.className='modal'; m.id='modal'; m.innerHTML=`<div class="box" role="dialog" aria-modal="true">${html}</div>`;
  m.addEventListener('click',e=>{ const el=e.target.closest('[data-act]'); if(!el||el.disabled) return; const fn=ACT[el.dataset.act]; if(fn) fn(el.dataset.arg,el,e); });
  document.body.appendChild(m); const b=m.querySelector('button'); if(b) b.focus(); }
function closeModal(){ const m=document.getElementById('modal'); if(m) m.remove(); }
function toast(msg){ const t=document.createElement('div'); t.className='toast'; t.textContent=msg; document.body.appendChild(t); setTimeout(()=>t.remove(),Math.min(9000,Math.max(2200,String(msg).length*60))); } // long messages stay long enough to read
// touch screens: say tap, not click or hover
function touchWords(h){ if(!(typeof G!=='undefined'&&G.mobile)||typeof h!=='string') return h;
  return h.replace(/Right-click to cancel/g,'Tap elsewhere to cancel').replace(/\b[Rr]ight-click(ing)?\b/g,'tapping elsewhere').replace(/Click to fire/g,'Tap again to fire').replace(/\bClick\b/g,'Tap').replace(/\bclick\b/g,'tap').replace(/\bHover\b/g,'Tap').replace(/\bhover\b/g,'tap'); }
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
let titleRaf=0;
function titleScreen(){
  RUN=null; B=null;
  show(`<div class="screen title"><canvas id="titlecv" aria-hidden="true"></canvas><div class="inner">
    <h1>Voidsworn</h1>
    <p class="sub">Command a crusade of gothic capital ships through three hostile sectors. Every hull you lose stays lost, and so does its captain.</p>
    <div class="menu">
      ${SAVED_RUN?`<button class="primary" data-act="continueRun">Continue run</button>`:''}
      <button class="${SAVED_RUN?'':'primary'}" data-act="newRunScreen">New run</button>
      <button data-act="legacy">Progression${(META.renown||0)>=15?' <span class="gilt num">\u25cf</span>':''}</button>
      <button data-act="help">How to play</button>
    </div>
    <div class="renown num">${META.stats.best?`Best: sector ${roman(Math.min(3,META.stats.best))}${META.stats.wins?` \u00b7 ${META.stats.wins} full victor${META.stats.wins>1?'ies':'y'}`:''}`:''}</div>
  </div></div>`);
  const cv=document.getElementById('titlecv'), g=cv.getContext('2d');
  const stars=[...Array(260)].map(()=>({x:rnd(),y:rnd(),z:rnd()*.8+.2}));
  const t0=performance.now();
  cancelAnimationFrame(titleRaf);
  const loop=now=>{ if(!document.body.contains(cv)) return;
    const dpr=Math.min(2,devicePixelRatio||1), w=cv.clientWidth, h=cv.clientHeight;
    if(cv.width!==Math.round(w*dpr)){ cv.width=Math.round(w*dpr); cv.height=Math.round(h*dpr); }
    g.setTransform(dpr,0,0,dpr,0,0);
    const bg=g.createRadialGradient(w*.7,h*.2,0,w*.7,h*.2,Math.max(w,h)); bg.addColorStop(0,'#17233d'); bg.addColorStop(1,'#070b15'); g.fillStyle=bg; g.fillRect(0,0,w,h);
    const t=(now-t0)/1000;
    for(const s of stars){ const x=((s.x*w - t*6*s.z)%w+w)%w; g.fillStyle=`rgba(230,220,196,${s.z*.8})`; g.fillRect(x,s.y*h,s.z*1.6,s.z*1.6); }
    const L=Math.min(w*.5,h*.7), span=w+L*1.2;
    const drift=(speed,start,len)=>{ const s=w+len*.6; return s-((t*speed+(s-start))%(w+len*1.2)); };
    const x=drift(9,w*.74,L), y=h*.8;
    g.save(); g.translate(x,y); g.rotate(Math.PI); g.globalAlpha=.92; drawShipShape(g,'gothic',L,FACTIONS.voidsworn,'player',null,false); g.restore();
    const x2=drift(16,w*.2,L*.3); g.save(); g.translate(x2,h*.63); g.rotate(Math.PI); g.globalAlpha=.6; drawShipShape(g,'gothic',L*.3,FACTIONS.voidsworn,'player',null,false); g.restore();
    const x3=drift(12,w*.9,L*.22); g.save(); g.translate(x3,h*.18); g.rotate(Math.PI); g.globalAlpha=.45; drawShipShape(g,'gothic',L*.22,FACTIONS.voidsworn,'player',null,false); g.restore();
    const vg=g.createLinearGradient(0,0,0,h); vg.addColorStop(0,'rgba(15,22,38,0)'); vg.addColorStop(1,'rgba(15,22,38,.55)'); g.fillStyle=vg; g.fillRect(0,0,w,h);
    titleRaf=requestAnimationFrame(loop); };
  titleRaf=requestAnimationFrame(loop);
}
ACT.title=()=>titleScreen();
ACT.continueRun=()=>{ RUN=JSON.parse(JSON.stringify(SAVED_RUN)); mapScreen(); };
ACT.newRunScreen=()=>{
  if(SAVED_RUN){ modal(`<h2>Abandon the current run?</h2><p class="muted">Starting over ends your saved run. Your best result so far is kept either way.</p>
    <div class="row"><button class="primary" data-act="abandonRun">Abandon and start over</button><button data-act="closeModal">Keep it</button></div>`); return; }
  admiralScreen();
};
ACT.closeModal=()=>closeModal();
ACT.abandonRun=()=>{ RUN=JSON.parse(JSON.stringify(SAVED_RUN)); endRun(false,true); };

let pickedAdmiral='vex';
function admiralScreen(){
  const mine=Object.entries(ADMIRALS).filter(([id,a])=>(a.fac||'voidsworn')===pickedFaction);
  if(!mine.some(([id])=>id===pickedAdmiral)||!META.admirals[pickedAdmiral]) pickedAdmiral=(mine.find(([id])=>META.admirals[id])||mine[0])[0];
  const cards=mine.map(([id,a])=>{ const un=!!META.admirals[id];
    const fleet=a.start.map(t=>HULLS[equivHull(t,pickedFaction)].n).join(', ');
    return `<div class="card ${pickedAdmiral===id?'sel':''} ${un?'':'locked'}">
      <h3>${esc(a.n)}</h3><p class="gilt">${esc(a.doc)}</p><p>${esc(a.d)}</p>
      ${masteryBar(id)}
      <p><span class="dim">Starting fleet:</span> ${esc(fleet)}</p>${a.cmd?`<p><span class="dim">Command:</span> <b class="gilt">${esc(a.cmd.n)}</b>. ${esc(cmdDesc(a.cmd,0,pickedFaction))} <span class="dim">Gets stronger each round you hold it.</span></p>`:''}
      <div class="foot">${un?`<button class="${pickedAdmiral===id?'primary':''}" data-act="pickAdmiral" data-arg="${id}">${pickedAdmiral===id?'Selected':'Select'}</button>`:`<span class="muted">Unlock for ${a.cost} renown in Legacy</span>`}</div></div>`; }).join('');
  show(`<div class="screen"><div class="page">
    <h2 class="gothic">Choose your faction</h2>
    <p class="lede">Your faction sets your ships and shipyards. Each run you face three of the other five, in a random order, with rival raiders along the way.</p>
    <div class="facs" style="display:flex;flex-wrap:wrap;gap:8px;margin-bottom:18px">${RUN_FACTIONS.map(f=>`<button class="facpick${pickedFaction===f?' on':''}" data-act="pickFaction" data-arg="${f}">${esc(FACTIONS[f].n)}</button>`).join('')}</div>
    <h2 class="gothic">Choose your admiral</h2>
    <p class="lede">Your admiral sets the fleet you start with and a doctrine that shapes every battle.</p>
    <div class="cards">${cards}</div>
    ${runOptionsHtml()}
    <div class="row" style="margin-top:22px"><button class="primary" data-act="startRun">Launch the ${runWord(pickedFaction)}</button><button data-act="title">Back</button></div>
  </div></div>`);
}
ACT.pickAdmiral=a=>{ if(pickedAdmiral!==a){ runOpt.alt=false; runOpt.cmdAlt=false; } pickedAdmiral=a; admiralScreen(); };
let pickedFaction=(META.opts&&META.opts.lastFac)||'voidsworn';
ACT.pickFaction=f=>{ pickedFaction=f; META.opts=META.opts||{}; META.opts.lastFac=f; admiralScreen(); };
ACT.startRun=()=>{ const ml=masteryLevel(pickedAdmiral); newRun(pickedAdmiral,pickedFaction,{alt:runOpt.alt&&ml>=1,cmdAlt:runOpt.cmdAlt&&ml>=3,heat:(META.stats.wins||0)>0?runOpt.heat.slice():[]});
  try{ tel('run_start',{fac:RUN.fac,foes:RUN.foes,admiral:pickedAdmiral,patrons:RUN.patrons,mastery:RUN.mastery,alt:!!RUN.altFleet,cmd:RUN.cmdOverride?RUN.cmdOverride.id:null,heat:RUN.heat,gift:RUN.giftBoon||null}); }catch(e){} aspectScreen(); };
// ---------- run options: mastery unlocks and Heat ----------
const runOpt={alt:false,cmdAlt:false,heat:[]};
function masteryBar(id){ const l=masteryLevel(id), x=masteryXP(id), nx=MASTERY_XP[l+1]; const f=nx?Math.min(1,(x-MASTERY_XP[l])/(nx-MASTERY_XP[l])):1;
  return `<div style="margin:6px 0 2px;font-size:13px"><span class="gilt">Mastery ${l}/4</span> <span class="dim num">${nx?`${x}/${nx}: next ${esc(MASTERY_PERKS[l+1].n.toLowerCase())}`:'mastered'}</span><div class="bar" style="margin-top:3px"><i style="width:${Math.round(f*100)}%;background:var(--gilt)"></i></div></div>`; }
function runOptionsHtml(){ const id=pickedAdmiral, a=ADMIRALS[id], ml=masteryLevel(id), parts=[];
  if(ml>=1){ const alt=altFleet(id,pickedFaction).map(t=>HULLS[t].n).join(', '), std=a.start.map(t=>HULLS[equivHull(t,pickedFaction)].n).join(', ');
    parts.push(`<div class="card"><h3>Starting fleet</h3><button class="choice ${!runOpt.alt?'sel':''}" data-act="optAlt" data-arg="0"><b>Standard</b><small>${esc(std)}</small></button><button class="choice ${runOpt.alt?'sel':''}" data-act="optAlt" data-arg="1"><b>Alternate</b><small>${esc(alt)}</small></button></div>`); }
  if(ml>=3&&a.cmd){ const c2=altCommand(id); if(c2) parts.push(`<div class="card"><h3>Command</h3><button class="choice ${!runOpt.cmdAlt?'sel':''}" data-act="optCmd" data-arg="0"><b>${esc(a.cmd.n)}</b><small>${esc(cmdDesc(a.cmd,0,pickedFaction))}</small></button><button class="choice ${runOpt.cmdAlt?'sel':''}" data-act="optCmd" data-arg="1"><b>${esc(c2.n)}</b><small>${esc(cmdDesc(c2,0,pickedFaction))}</small></button></div>`); }
  if((META.stats.wins||0)>0){ const hl=heatLevel(runOpt.heat), best=(META.heatBest||{})[pickedFaction]||0;
    parts.push(`<div class="card"><h3>Heat <span class="gilt num">${hl}</span> <span class="dim" style="font-size:14px">+${hl*10}% renown${best?` \u00b7 best win with this faction: Heat ${best}`:''}</span></h3><p class="dim" style="font-size:13.5px">Optional rules that make the run harder. Pick any.</p>${Object.entries(HEAT).map(([k,h])=>`<button class="choice ${runOpt.heat.includes(k)?'sel':''}" data-act="optHeat" data-arg="${k}"><b>${esc(h.n)} <span class="dim">+${h.w}</span></b><small>${esc(h.d)}</small></button>`).join('')}</div>`); }
  else parts.push(`<div class="card locked"><h3>Heat</h3><p class="dim">Win a run to unlock Heat: optional rules that make runs harder and pay more renown.</p></div>`);
  return `<h2 class="gothic" style="margin-top:22px">Run options</h2><div class="cards">${parts.join('')}</div>`; }
ACT.optAlt=v=>{ runOpt.alt=v==='1'; admiralScreen(); };
ACT.optCmd=v=>{ runOpt.cmdAlt=v==='1'; admiralScreen(); };
ACT.optHeat=k=>{ const i=runOpt.heat.indexOf(k); if(i>=0) runOpt.heat.splice(i,1); else runOpt.heat.push(k); admiralScreen(); };
// like choosing a weapon aspect: three random aspects for the flagship, and the pick shapes the whole run
function aspectScreen(){ const f=ensureFlagship(), opts=shuffle(Object.keys(ASPECTS)).slice(0,(RUN.mastery||0)>=2?4:3); window._aspOffer=opts;
  show(`<div class="screen"><div class="page"><h2 class="gothic">Choose your flagship's aspect</h2>
    <p class="lede">The <b>${esc(f.name)}</b> (${esc(HULLS[f.tpl].n)}) carries your flag. Pick one aspect for it; it lasts the whole run, and passes to your next-largest ship if the flagship falls.</p>
    <div class="cards">${opts.map(k=>`<div class="card"><h3>${esc(ASPECTS[k].n)}</h3><p>${esc(ASPECTS[k].d)}</p><div class="foot"><button class="primary" data-act="pickAspect" data-arg="${k}">Take this aspect</button></div></div>`).join('')}</div>
    ${RUN.giftBoon?`<p class="gilt" style="margin-top:14px">A gift from ${esc(PATRONS[BOONS[RUN.giftBoon].p].n)}, who counts you Devoted: <b>${esc(BOONS[RUN.giftBoon].n)}</b>.</p>`:''}${RUN.heat&&RUN.heat.length?`<p class="blood" style="margin-top:8px">Heat ${heatLevel(RUN.heat)}: ${RUN.heat.map(k=>esc(HEAT[k].n)).join(', ')}.</p>`:''}
    <p class="dim" style="margin-top:16px">Patrons watching this ${runWord()}: ${RUN.patrons.map(p=>`<b style="color:${PATRONS[p].col}">${esc(PATRONS[p].n)}</b> (${esc(PATRONS[p].theme.toLowerCase())})`).join('; ')}. Win battles marked with their sigil to earn their boons.</p>
  </div></div>`); }
ACT.pickAspect=k=>{ if(!ASPECTS[k]||!RUN) return; changeFleet(()=>{ RUN.aspect=k; ensureFlagship(); }); try{ tel('aspect_pick',{id:k,offered:window._aspOffer,fac:RUN.fac}); }catch(e){} saveRun(); introModal(); };
function introModal(){
  mapScreen();
  const F=FACTIONS[RUN.map.fac];
  modal(`<h2>Sector I</h2><p>The ${runWord()} crosses into contested space. Long-range auspex confirms <b>${esc(F.n)}</b> activity along every jump route.</p><p class="muted">${esc(F.blurb)}</p>
    <p class="muted">Pick a route across the sector map. Battles marked with a patron’s sigil pay out that patron’s boons, so the route you choose shapes your build. The flagship of the sector waits at the far end.</p><button class="primary" data-act="closeModal">Plot a course</button>`);
}

// ---------- progression: what carries between runs ----------
let progTab='variants';
function favFirst(){ const lf=(META.opts&&META.opts.lastFac)||'voidsworn'; return [lf,...RUN_FACTIONS.filter(f=>f!==lf)]; } // your current faction first
function legacyScreen(){
  const tabs=[['variants','Hull variants'],['mastery','Admiral mastery'],['favour','Patron favour'],['heat','Heat'],['fallen','Hall of the fallen']];
  let body='';
  if(progTab==='variants'){ body=`<p class="lede">Spend renown to add a variant hull to your faction's shipyards. It sits beside the standard hull whenever that hull is in stock. <span class="gilt num">You have ${META.renown||0} renown.</span> Renown comes from every run: battles, elites, flagships and sectors reached, plus 10% per Heat level.</p>`+
      favFirst().map(f=>{ const vs=Object.entries(HULL_VARIANTS).filter(([vid,v])=>HULLS[v.base].fac===f); return `<h3 style="margin:20px 0 8px">${esc(FACTIONS[f].n)}</h3><div class="cards">${vs.map(([vid,v])=>{ const own=!!(META.variants||{})[vid], t=HULLS[vid];
        return `<div class="card ${own?'sel':''}"><h3>${esc(v.n)}</h3><p class="dim" style="font-size:13.5px">Variant of the ${esc(HULLS[v.base].n)}</p><p>${esc(v.d)}</p><p class="num" style="font-size:13.5px">${t.cp} CP. Hull ${t.hp}, shields ${t.sh}, speed ${t.sp}. ${t.w.map(([id,a])=>W[id].n+' ('+(a==='T'?'turret':ARC_NAME[a].toLowerCase())+')').join(', ')}.</p><div class="foot">${own?'<span class="verd">In your shipyards</span>':`<button ${(META.renown||0)>=v.cost?'':'disabled'} data-act="buyVariant" data-arg="${vid}">Unlock for ${v.cost} renown</button>`}</div></div>`; }).join('')}</div>`; }).join(''); }
  if(progTab==='mastery'){ body=`<p class="lede">Every run levels up the admiral who led it: 1 per battle won, 2 per elite, 5 per flagship and 10 for a victory.</p><div class="cards">${MASTERY_PERKS.slice(1).map((m,i)=>`<div class="card"><h3>Level ${i+1}: ${esc(m.n)}</h3><p>${esc(m.d)}</p><p class="dim num">${MASTERY_XP[i+1]} mastery</p></div>`).join('')}</div>`+
      favFirst().map(f=>`<h3 style="margin:20px 0 8px">${esc(FACTIONS[f].n)}</h3><div class="cards">${Object.entries(ADMIRALS).filter(([id,a])=>(a.fac||'voidsworn')===f).map(([id,a])=>`<div class="card"><h3>${esc(a.n)}</h3><p class="gilt" style="font-size:14px">${esc(a.doc)}</p>${masteryBar(id)}</div>`).join('')}</div>`).join(''); }
  if(progTab==='favour'){ body=`<p class="lede">Every boon you take raises that patron's favour (rare boons count double, epic triple).</p><div class="cards">${FAVOUR_TIERS.slice(1).map(t=>`<div class="card"><h3>${esc(t.n)} <span class="dim num">${t.at}+</span></h3><p>${esc(t.d)}</p></div>`).join('')}</div><div style="margin-top:14px">`+
      Object.entries(PATRONS).map(([p,P])=>{ const f=favourOf(p), t=favourTier(p), nx=FAVOUR_TIERS[t+1]; return `<div class="favrow"><div class="sg" style="background:${P.col}">${P.glyph}</div><div><b>${esc(P.n)}</b><div class="dim" style="font-size:13px">${esc(P.theme)}</div></div><div class="num" style="text-align:right"><b style="color:${P.col}">${esc(FAVOUR_TIERS[t].n)}</b><div class="dim" style="font-size:12.5px">${f}${nx?` / ${nx.at}`:''}</div></div></div>`; }).join('')+'</div>'; }
  if(progTab==='heat'){ const wins=META.stats.wins||0; body=`<p class="lede">${wins?'Heat is open. Pick rules on the admiral screen before a run; each level adds 10% renown.':'Win a run to open Heat.'}</p><div class="cards">${Object.entries(HEAT).map(([k,h])=>`<div class="card"><h3>${esc(h.n)} <span class="dim">+${h.w}</span></h3><p>${esc(h.d)}</p></div>`).join('')}</div>
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
ACT.buyVariant=id=>{ const v=HULL_VARIANTS[id]; META.variants=META.variants||{}; if(!v||META.variants[id]||(META.renown||0)<v.cost) return; META.renown-=v.cost; META.variants[id]=true; try{ tel('variant_buy',{id,cost:v.cost}); }catch(e){} Persist.save(); legacyScreen(); };
ACT.buyLegacy=id=>{ const u=LEGACY[id]; if(META.unlocked[id]||META.renown<u.cost) return; META.renown-=u.cost; META.unlocked[id]=true; Persist.save(); legacyScreen(); };
ACT.buyAdmiral=id=>{ const a=ADMIRALS[id]; if(META.admirals[id]||META.renown<a.cost) return; META.renown-=a.cost; META.admirals[id]=true; Persist.save(); legacyScreen(); };

// ---------- help ----------
function helpScreen(){
  show(touchWords(`<div class="screen"><div class="page" style="max-width:820px">
    <h2 class="gothic">How to play</h2>
    <p class="lede">Voidsworn is a roguelite. Each run crosses three sectors, each ending in a flagship battle. Ships and captains you lose are gone for the run; every faction, admiral and ship is available from the start.</p>
    <p>What carries between runs (Progression, on the title screen): <b>renown</b> buys hull variants for your shipyards; each <b>admiral</b> levels up as you fly with them, unlocking an alternate fleet, a fourth aspect, a second Command and a veteran flag captain; <b>patrons</b> grow fond of you as you take their boons, offering rarer boons and eventually a gift at the start of a run; and after your first victory, <b>Heat</b> lets you add harder rules for more renown. After each sector flagship falls, the fleet docks at a shipyard before its next fight.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Your turn</h3>
    <p>Every ship can move, turn and fire each of its weapons once per turn, in any order. Click a ship, then click a highlighted hex to move. Moving forward costs 1 movement. Turning 60\u00b0 also costs 1 movement and uses one of the ship\u2019s turns; big ships only get one turn per round, so plan their heading early. Press <kbd>Q</kbd> and <kbd>E</kbd> to turn in place.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Firing arcs</h3>
    <p>Weapons only fire into their arc. Prow weapons cover the 120\u00b0 in front, port and starboard broadsides each cover a wide 120\u00b0 cone to the side, and turrets fire anywhere. The tinted hexes around a selected ship show where its guns reach: amber for the prow, teal for broadsides. Click an enemy to fire everything that can reach it, or press a number key to fire a single weapon.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Shields and flanking</h3>
    <p>Each ship has four shield facings: prow, port, starboard and rear. Damage hits the facing that points at the attacker, and shields regenerate at the start of each of your turns. Rear hits halve armor and are far more likely to crit, so getting behind a battleship matters. Lances and bombers punch partly or fully through shields. Ion cannons shred shields; gauss weapons mostly ignore them.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Different fights</h3>
    <p>Each fight on the sector map is labelled with its goal. Engagements and ambushes end when one fleet breaks. In <b>Hold the station</b> you keep enemies off a friendly station until round 6 ends. In a <b>Hunt</b> their flagship runs and jumps out after round 6. In an <b>Intercept</b> you destroy transports before they cross the field. In a <b>Breakthrough</b> you get half your fleet off the far edge. Missing a Hunt or Intercept still pays half; losing the station or a breakthrough means a retreat, not the end of the run. Tap the chip under the top bar in battle for the rules and the coloured hexes.</p>
    <p>Some fights change partway through: reinforcements for either side, or a solar flare that knocks out every shield for a round. You always get a round of warning.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Brace, abilities and Command</h3>
    <p>Brace is the alternative to firing: a ship that hasn\u2019t fired can brace to take 40% less hull damage until your next turn (it can still move first). To ram, point your bow at an enemy ship with at least one clear hex between you and enough movement left to cross the gap: a red lane shows when a ram is ready, and red-ringed move hexes line one up. A longer run-up hits harder; a ram can\u2019t take more than 40% of a healthy ship\u2019s hull without boons. Boarding an adjacent enemy can capture it for your fleet; enemy boarders can cripple your ships, but never take them. Carriers start every battle with their wings already flying; the wings fight on their own unless you order them: tap a wing, then tap an enemy ship to strike it or one of your ships to guard it. The carrier\u2019s launch only replaces wings you lose. Most hulls have an ability with a cooldown, and each faction has its own: Hegemony ion pulses, Corsair overburn, Chorus regrowth and frenzy, Ithar phase jumps, Deathless reanimation beams, and the Voidsworn\u2019s burns, reloads and shield surges. Enemy flagships carry a Command too: they announce it a round ahead, so you can brace or scatter. Once per battle, your admiral\u2019s Command is a fleet-wide signature move. It gets stronger each round you hold it (power 1 in round 1, 2 in round 2, full power from round 3, and losing a ship charges it a level), so the choice is a smaller boost now or a bigger one later, if the fight lasts that long. The ship panel shows exactly what the next level adds.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Patrons, boons and your flagship</h3>
    <p>Each run, four of six patrons watch your run. Battles on the map carry a patron\u2019s sigil: win there and that patron offers three boons, and you take one. Boons change the rules (fires, chain explosions, rams that shake the whole formation) and come in Common, Rare and Epic strength. Hold boons from two patrons and a duo boon can appear. At the start of a run you also pick one of three aspects for your flagship, which shapes how it fights for the whole run. Enemy fleets grow to match a fleet that has outgrown its sector.</p>
    <h3 class="gilt" style="margin:18px 0 6px">Between battles</h3>
    <p>Hull damage carries between battles. Shipyards sell hulls, refits and repairs, and can upgrade a ship\u2019s Mark. Captains earn experience and pick a perk at each promotion. Relics are fleet-wide bonuses that last for the run.</p>
    <h3 class="gilt keysonly" style="margin:18px 0 6px">Keys</h3>
    <p class="keysonly"><kbd>Tab</kbd> next ship, <kbd>Q</kbd>/<kbd>E</kbd> turn, <kbd>1</kbd>\u2013<kbd>6</kbd> arm a weapon, <kbd>B</kbd> brace, <kbd>A</kbd> toggle arcs, <kbd>Esc</kbd> or right-click to cancel, <kbd>Enter</kbd> end turn.</p>
    <div class="row" style="margin-top:24px"><button class="primary" data-act="title">Back</button></div>
  </div></div>`));
}
ACT.help=()=>helpScreen();

// ---------- run end ----------
const WIN_TITLE={voidsworn:'The crusade endures',hegemony:'The Hegemony stands',corsair:'The loot is yours',chorus:'The Chorus swells',ithar:'The Ithar endure',deathless:'The Dynasty rises'};
function runRecap(victory){ const s=RUN.stats, mins=RUN.t0?Math.max(1,Math.round((Date.now()-RUN.t0)/60000)):null;
  const tile=(n,l)=>`<div class="rtile"><b class="num">${n}</b><span>${l}</span></div>`;
  const tiles=`<div class="rtiles">${tile(s.battles,'battles won')}${tile(s.bosses,'flagships destroyed')}${tile(s.kills,'enemy ships destroyed')}${tile(s.lost||0,'ships lost')}${mins?tile(mins<90?mins+'m':(mins/60).toFixed(1)+'h','played'):''}</div>`;
  const fl=(RUN.fleet||[]).filter(x=>x.hp>0), score=x=>x.car?x.car.dealt+x.car.kills*40:0, best=fl.slice().sort((a,b)=>score(b)-score(a))[0];
  const row=x=>{ const c=x.car||{dealt:0,kills:0,battles:0}; return `<div class="rrow${x===best&&score(x)>0?' star':''}"><div><b>${esc(x.name)}</b> <span class="dim">${esc(HULLS[x.tpl].n)}</span><div class="dim" style="font-size:12px">${esc(rankName(x.cap))} ${esc(x.cap.name)}</div></div><div class="num">${c.kills} kills<br><span class="dim">${c.dealt} dmg</span></div></div>`; };
  const stand=best&&score(best)>0?`<p class="standout">Standout ship: <b class="gilt">${esc(best.name)}</b>, ${best.car.kills} kills and ${best.car.dealt} damage across ${best.car.battles} battle${best.car.battles>1?'s':''}.</p>`:'';
  const fleet=fl.length?`<h3 class="rhead">${victory?'The fleet that finished it':'Still flying'}</h3><div class="rfleet">${fl.sort((a,b)=>score(b)-score(a)).map(row).join('')}</div>`:'';
  return tiles+stand+fleet; }
function nextFacPick(){ const won=(META.stats.wonFacs||[]), pool=RUN_FACTIONS.filter(f=>f!==RUN.fac&&!won.includes(f)); return pick(pool.length?pool:RUN_FACTIONS.filter(f=>f!==RUN.fac)); }
function endRun(victory, abandoned){
  const s=RUN.stats;
  const prevBest=META.stats.best||0; META.stats.best=Math.max(prevBest, RUN.sector); if(victory){ META.stats.wins++; META.stats.wonFacs=META.stats.wonFacs||[]; if(!META.stats.wonFacs.includes(RUN.fac)) META.stats.wonFacs.push(RUN.fac); }
  for(const f of RUN.fallen) META.fallen.push(f); if(META.fallen.length>80) META.fallen=META.fallen.slice(-80);
  try{ tel('run_end',{victory:!!victory,abandoned:!!abandoned,fac:RUN.fac,sector:RUN.sector,stats:s,mins:RUN.t0?Math.round((Date.now()-RUN.t0)/60000):null,fleet:(RUN.fleet||[]).map(x=>x.tpl)}); }catch(e){}
  // what carries forward: renown (more with Heat), admiral mastery, and a Heat record for this faction
  const hl=heatLevel(RUN.heat), ren=Math.round((typeof runRenown==='function'?runRenown():0)*(1+.1*hl)); META.renown=(META.renown||0)+ren;
  const mx0=masteryLevel(RUN.admiral), mxGain=s.battles+s.elites*2+s.bosses*5+(victory?10:0); META.mastery=META.mastery||{}; META.mastery[RUN.admiral]=(META.mastery[RUN.admiral]||0)+mxGain; const mx1=masteryLevel(RUN.admiral);
  if(victory&&hl){ META.heatBest=META.heatBest||{}; META.heatBest[RUN.fac]=Math.max(META.heatBest[RUN.fac]||0,hl); }
  RUN.carry={ren,mxGain,mx0,mx1,hl};
  RUN.over=true; SAVED_RUN=null; Persist.save();
  const nf=victory?nextFacPick():null, NF=nf&&FACTIONS[nf];
  const cy=RUN.carry, nextLv=MASTERY_PERKS[Math.min(4,cy.mx1+1)];
  const carryHtml=`<div class="nextfac" style="border-color:var(--gilt)"><div class="dim" style="font-size:12px;letter-spacing:.08em;text-transform:uppercase">Carried forward</div>
    <p style="margin:4px 0"><b class="gilt num">+${cy.ren} renown</b>${cy.hl?` <span class="dim">(Heat ${cy.hl}: +${cy.hl*10}%)</span>`:''} \u00b7 you now have ${META.renown}. Spend it on hull variants in Progression.</p>
    <p style="margin:4px 0">${esc(ADMIRALS[RUN.admiral].n)}: <b class="num">+${cy.mxGain} mastery</b>${cy.mx1>cy.mx0?` <span class="gilt">Level ${cy.mx1} reached: ${esc(MASTERY_PERKS[cy.mx1].n)}. ${esc(MASTERY_PERKS[cy.mx1].d)}</span>`:cy.mx1<4?` <span class="dim">(${masteryXP(RUN.admiral)}/${MASTERY_XP[cy.mx1+1]} to ${esc(nextLv.n)})</span>`:' <span class="dim">(mastered)</span>'}</p></div>`;
  const lines=`${carryHtml}${runRecap(victory)}
    ${RUN.fallen.length?`<p class="muted">Captains lost this run: ${RUN.fallen.map(f=>esc(f.name)).join(', ')}.</p>`:''}
    ${victory?`<p class="gilt num" style="font-size:18px">${META.stats.wins>1?`Victories so far: ${META.stats.wins}`:'Your first victory.'} Won with: ${(META.stats.wonFacs||[]).map(f=>esc(FACTIONS[f].n)).join(', ')}.</p>`:`<p class="gilt num" style="font-size:20px">${RUN.sector>prevBest?`New best: sector ${roman(RUN.sector)}`:`Best so far: sector ${roman(Math.min(3,META.stats.best))}`}</p>`}
    ${NF?`<div class="nextfac"><div class="dim" style="font-size:12px;letter-spacing:.08em;text-transform:uppercase">Next run</div><b>Try the ${esc(NF.n.replace(/^The /,''))}</b><p class="muted" style="margin:4px 0 0">${esc(NF.blurb||'')}</p></div>`:''}`;
  const sub=victory?`Three sectors broken, three flagships burning behind you. ${esc(ADMIRALS[RUN.admiral]?ADMIRALS[RUN.admiral].n:'Your admiral')} brings the ${esc(FACTIONS[RUN.fac]?FACTIONS[RUN.fac].n.replace(/^The /,''):'fleet')} home.`:abandoned?'The fleet stands down. Its deeds are recorded.':'The last hull goes dark in sector '+roman(RUN.sector)+'. The survivors will tell it differently.';
  show(`<div class="screen title recap"><div class="inner" style="max-width:720px">
    <h1 style="font-size:clamp(44px,8vw,104px)">${victory?(WIN_TITLE[RUN.fac]||'Victory'):abandoned?'Run abandoned':'The fleet is lost'}</h1>
    <div class="sub">${sub}</div>
    ${lines}
    <div class="menu" style="margin-top:22px">${NF?`<button class="primary" data-act="nextFac" data-arg="${nf}">Play as ${esc(NF.n)}</button><button data-act="newRunScreen">Pick a faction</button>`:`<button class="primary" data-act="newRunScreen">New run</button>`}<button data-act="title">Title screen</button></div></div></div>`);
  RUN=null;
}
ACT.nextFac=f=>{ pickedFaction=f; META.opts=META.opts||{}; META.opts.lastFac=f; admiralScreen(); };
