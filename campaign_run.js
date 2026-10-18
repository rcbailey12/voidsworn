// ======================= UI: run (map, fleet, shipyard, events, rewards) =======================
const NODE_INFO={battle:{n:'Battle',d:'A standard engagement.'},elite:{n:'Elite fleet',d:'Tougher enemies with veteran captains. Drops a relic.'},
  shipyard:{n:'Shipyard',d:'Buy hulls and refits, repair, upgrade Marks.'},drydock:{n:'Drydock',d:'Free repairs for the whole fleet.'},field:{n:'Field repairs',d:'Every ship patches 20% of its hull, no cost.'},
  event:{n:'Unknown signal',d:'Something is out there. Could be anything.'},boss:{n:'Sector flagship',d:'The sector\u2019s command ship and its escort.'}};
function nodeIcon(type,x,y,col){
  const s=`stroke="${col}" stroke-width="2.2" fill="none" stroke-linecap="round"`;
  if(type==='battle') return `<path d="M${x-7} ${y-7}L${x+7} ${y+7}M${x+7} ${y-7}L${x-7} ${y+7}M${x-8} ${y+3}l5 5M${x+8} ${y+3}l-5 5" ${s}/>`;
  if(type==='elite') return `<path d="M${x-7} ${y-7}L${x+7} ${y+7}M${x+7} ${y-7}L${x-7} ${y+7}" ${s}/><path d="M${x} ${y-12}l3 4h-6z" fill="${col}"/>`;
  if(type==='shipyard') return `<path d="M${x-8} ${y-2}h10v-4h4v12h-4v-4h-10z M${x-2} ${y+6}v4" ${s}/>`;
  if(type==='drydock') return `<path d="M${x} ${y-8}v16M${x-8} ${y}h16" ${s}/>`;
  if(type==='event') return `<text x="${x}" y="${y+6}" text-anchor="middle" font-size="18" font-weight="700" fill="${col}" font-family="var(--ui)">?</text>`;
  if(type==='field') return `<path d="M${x-7} ${y+7}L${x+2} ${y-2}M${x+1} ${y-8}a5.5 5.5 0 1 0 7 7l-3.5-.5-3-3z" ${s}/>`;
  if(type==='boss') return `<path d="M${x-11} ${y+6}l-2-12 7 6 6-9 6 9 7-6-2 12z" ${s} fill="${col}" fill-opacity=".25"/>`;
  return '';
}
// a node's payout, shown on the map: a patron's sigil for a boon, a small tag otherwise
function archLabel(n,fac){ const A=n&&n.arch&&ARCHETYPES[effArch(n.arch,fac)]; return A?(A.names[fac]||A.names.hegemony):''; }
function rewardLabel(rw){ if(!rw) return ''; if(rw.k==='boon'&&PATRONS[rw.p]) return 'Boon of '+PATRONS[rw.p].short; return rw.k==='mod'?'Refit':rw.k==='cred'?'Credits':rw.k==='repair'?'Repairs':''; }
function rewardBadge(n,x,y,r,av){ const rw=n.rw; if(!rw||n.done) return ''; const bx=x+r*.78, by=y-r*.78, ty=n.enc&&ENCOUNTERS[n.enc]?y+r+29:y+r+15;
  if(rw.k==='boon'&&PATRONS[rw.p]){ const P=PATRONS[rw.p]; return `<circle cx="${bx}" cy="${by}" r="10" fill="${P.col}" stroke="#0f1626" stroke-width="2"/><text x="${bx}" y="${by+4.5}" text-anchor="middle" font-size="12.5" font-weight="700" fill="#0f1626" font-family="var(--ui)">${P.glyph}</text><text x="${x}" y="${ty}" text-anchor="middle" font-size="11.5" fill="${av?P.col:'#8a8474'}" font-family="var(--ui)">${esc(P.short)}${rw.min?' \u2605':''}</text>`; }
  const lab=rewardLabel(rw); return lab?`<text x="${x}" y="${ty}" text-anchor="middle" font-size="11.5" fill="${av?'#bfb6a0':'#6f6a5e'}" font-family="var(--ui)">${lab}</text>`:''; }
function boonLine(b,small){ const B0=BOONS[b.id]; if(!B0) return ''; const P=B0.p?PATRONS[B0.p]:null, R=RARITY[b.r||0], col=P?P.col:'#f0b35a';
  return `<div style="margin-bottom:6px;border-left:3px solid ${col};padding-left:8px"><b>${esc(B0.n)}</b> <span style="color:${R.col};font-size:12px">${B0.duo?'Duo':R.n}</span><div class="muted" style="font-size:${small?13:14}px">${esc(B0.d(R.m))}</div></div>`; }
function mapScreen(){
  B=null;
  const m=RUN.map, avail=new Set(availableNodes()), F=FACTIONS[m.fac];
  const port=innerWidth<720&&innerHeight>innerWidth;
  const PX=n=>port?34+n.y*380:60+n.col*130, PY=n=>port?60+n.col*130:34+n.y*380;
  const byId={}; for(const c of m.cols) for(const n of c) byId[n.id]=n;
  for(const n of Object.values(byId)) if(!n.done&&!n.enc&&(n.type==='battle'||n.type==='elite')) Object.assign(n,rollEncounter(n.type,n.col)); // older saves
  ensurePatrons(); for(const n of Object.values(byId)) if(!n.done&&!n.rw&&(n.type==='battle'||n.type==='elite'||n.type==='boss')) n.rw=rollNodeReward(n.type);
  const edges=m.edges.map(([a,b])=>{ const A=byId[a],Bn=byId[b]; const trav=A.done&&(Bn.done||RUN.pos===b);
    return `<line x1="${PX(A)}" y1="${PY(A)}" x2="${PX(Bn)}" y2="${PY(Bn)}" stroke="${trav?'#d0a64b':RUN.pos===a&&avail.has(b)?'rgba(208,166,75,.55)':'rgba(230,220,196,.13)'}" stroke-width="${trav?3:2}" ${RUN.pos===a&&avail.has(b)?'stroke-dasharray="6 5"':''}/>`; }).join('');
  const nodes=Object.values(byId).map(n=>{ const x=PX(n), y=PY(n), av=avail.has(n.id), cur=RUN.pos===n.id, r=n.type==='boss'?26:19;
    const col = n.done?'#7d7768': n.type==='elite'||n.type==='boss'?'#e07a70': av?'#e6dcc4':'#8a8474';
    return `<g class="node ${av?'avail':''}" ${av?`data-act="enterNode" data-arg="${n.id}" tabindex="0" role="button" aria-label="${NODE_INFO[n.type].n}"`:''}>
      <title>${NODE_INFO[n.type].n}: ${n.enc&&ENCOUNTERS[n.enc]?ENCOUNTERS[n.enc].n+'. '+ENCOUNTERS[n.enc].d:NODE_INFO[n.type].d}${archLabel(n,(typeof nodeFaction==="function"?nodeFaction(n):m.fac))?' '+archLabel(n,(typeof nodeFaction==="function"?nodeFaction(n):m.fac))+'.':''}${n.mod&&NODE_MODS[n.mod]?' '+NODE_MODS[n.mod].n+': '+NODE_MODS[n.mod].d:''}</title>
      <circle cx="${x}" cy="${y}" r="${r}" fill="${n.done?'#1b2436':'#182133'}" class="ring" stroke="${cur?'#d0a64b':av?'rgba(208,166,75,.8)':'rgba(230,220,196,.18)'}" stroke-width="${cur||av?2.5:1.5}"/>
      ${av?`<circle cx="${x}" cy="${y}" r="${r+6}" fill="none" stroke="rgba(208,166,75,.35)" stroke-width="1"><animate attributeName="r" values="${r+3};${r+9};${r+3}" dur="2.4s" repeatCount="indefinite"/></circle>`:''}
      ${nodeIcon(n.type,x,y,col)}${n.enc&&ENCOUNTERS[n.enc]&&!n.done?`<text x="${x}" y="${y+r+15}" text-anchor="middle" font-size="12.5" fill="${av?'#e6dcc4':'#8a8474'}" font-family="var(--ui)">${ENCOUNTERS[n.enc].n}${n.mod&&NODE_MODS[n.mod]?' \u00b7 '+NODE_MODS[n.mod].short:''}</text>`:''}${rewardBadge(n,x,y,r,av)}</g>`; }).join('');
  const fleet=RUN.fleet.map(s=>{ const d=derive(s); return `<div class="shiprow"><span>${esc(s.name)}</span><span class="dim num">${s.hp}/${d.maxHp}</span>
    <span class="dim" style="grid-column:1/-1;font-size:13px">${HULLS[s.tpl].cls} Mk ${roman(s.mk)}, ${rankName(s.cap)} ${esc(s.cap.name)}${s.cap.pending?' <span class="gilt">(promotion ready)</span>':''}</span>${hpBar(s.hp,d.maxHp)}</div>`; }).join('');
  const relics=RUN.relics.length?RUN.relics.map(r=>`<div style="margin-bottom:6px"><b>${esc(relicName(r))}</b><div class="muted" style="font-size:14px">${esc(RELICS[r].d)}</div></div>`).join(''):'<p class="dim">None yet. Elite fleets and flagships carry them.</p>';
  const pend=RUN.fleet.some(s=>s.cap.pending);
  show(`<div class="mapwrap">
    <div class="mapmain">
      <div class="row wrap"><h2>Sector ${roman(RUN.sector)}</h2><span class="spacer"></span><button data-act="saveQuit">Save and quit</button></div>
      <p class="muted" style="margin:6px 0 0;max-width:75ch">Hostile presence: <b class="blood">${esc(F.n)}</b>. ${esc(F.blurb)}</p>${(()=>{ const c=sectorCond(); return c?`<p style="margin:6px 0 0;max-width:75ch"><span class="gilt">Sector condition: <b>${esc(c.n)}</b>.</span> <span class="muted">${esc(c.d)}</span></p>`:''; })()}
      <svg viewBox="0 0 ${port?450:900} ${port?900:450}" style="width:100%;max-width:1400px;max-height:calc(100vh - 230px)" role="img" aria-label="Sector map">${edges}${nodes}</svg>
      <div class="legend">${Object.entries(NODE_INFO).map(([k,v])=>`<span class="row" style="gap:6px"><svg width="26" height="26" viewBox="0 0 30 30" aria-hidden="true">${nodeIcon(k,15,15,k==='elite'||k==='boss'?'#e07a70':'#e6dcc4')}</svg>${v.n}</span>`).join('')}</div>
      ${(()=>{ const nx=[...avail].map(id=>byId[id]).filter(n=>n&&n.enc&&ENCOUNTERS[n.enc]); const seen=new Set(); const rows=nx.filter(n=>{ const k=n.enc+'|'+rewardLabel(n.rw)+'|'+n.type+'|'+(n.arch||'')+'|'+(n.mod||''); return !seen.has(k)&&seen.add(k); });
        return rows.length?`<div class="encprev">${rows.map(n=>`<div><b class="gilt">${ENCOUNTERS[n.enc].n}</b>${archLabel(n,(typeof nodeFaction==="function"?nodeFaction(n):m.fac))?` <span class="blood">\u00b7 ${esc(archLabel(n,(typeof nodeFaction==="function"?nodeFaction(n):m.fac)))}</span>`:''}${n.mod&&NODE_MODS[n.mod]?` <span class="gilt">\u00b7 ${esc(NODE_MODS[n.mod].n)}</span>`:''}${n.type==='elite'?' <span class="blood">(elite)</span>':''}${n.shape&&n.shape!=='open'?` <span class="dim">\u00b7 ${SHAPES[n.shape].toLowerCase()}</span>`:''}<div class="muted">${ENCOUNTERS[n.enc].d}</div>${n.arch&&ARCHETYPES[n.arch]?`<div class="muted" style="font-size:13px">${esc(ARCHETYPES[effArch(n.arch,(typeof nodeFaction==="function"?nodeFaction(n):m.fac))].d)}</div>`:''}${n.mod&&NODE_MODS[n.mod]?`<div class="gilt" style="font-size:13px">${esc(NODE_MODS[n.mod].d)}</div>`:''}${n.rw?`<div style="font-size:13px;margin-top:2px;color:${n.rw.k==='boon'&&PATRONS[n.rw.p]?PATRONS[n.rw.p].col:'#bfb6a0'}">Reward: ${rewardLabel(n.rw)}${n.rw.min?' (rare or better)':''}</div>`:''}</div>`).join('')}</div>`:''; })()}      <p class="dim" style="margin-top:10px">Choose a pulsing node to jump there. You can only move forward along the lines.</p>
    </div>
    <aside class="side">
      <div class="row"><div><div class="dim" style="font-size:13px">Credits</div><div class="gilt num" style="font-size:24px">${RUN.credits}</div></div><span class="spacer"></span>
      <div style="text-align:right"><div class="dim" style="font-size:13px">Command points</div><div class="num" style="font-size:24px">${fleetCP()}<span class="dim">/${RUN.cpCap}</span></div></div></div>
      <p class="dim" style="font-size:14px;margin:6px 0 0">Admiral: ${esc(ADMIRALS[RUN.admiral].n)}, ${esc(ADMIRALS[RUN.admiral].doc.toLowerCase())}</p>
      <h3>Fleet</h3>${fleet}
      <button class="${pend?'primary':''}" style="width:100%;margin-top:12px" data-act="fleetScreen">${pend?'Promote captains and refit':'Manage fleet and refits'}</button>
      ${RUN.inventory.length?`<p class="dim" style="font-size:14px">${RUN.inventory.length} refit${RUN.inventory.length>1?'s':''} in the hold.</p>`:''}
      ${RUN.aspect&&ASPECTS[RUN.aspect]?`<h3>Flagship</h3><p style="margin:0 0 4px"><b>${esc((flagshipOf()||{}).name||'')}</b> <span class="gilt">${esc(ASPECTS[RUN.aspect].n)}</span></p><p class="muted" style="font-size:14px;margin:0">${esc(ASPECTS[RUN.aspect].d)}</p>`:''}
      <h3>Boons</h3>${(RUN.boons||[]).length?RUN.boons.map(b=>boonLine(b,true)).join(''):'<p class="dim">None yet. Win at a node with a patron\u2019s sigil to earn one.</p>'}
      <p class="dim" style="font-size:13px">Patrons this run: ${RUN.patrons.map(p=>`<span style="color:${PATRONS[p].col}">${esc(PATRONS[p].short)}</span>`).join(', ')}</p>
      <h3>Relics</h3>${relics}
    </aside></div>`);
}
ACT.saveQuit=()=>{ saveRun(); titleScreen(); };
ACT.enterNode=id=>{
  if(!availableNodes().includes(id)) return;
  const n=findNode(id); RUN.pos=id; RUN.curNode=id;
  tel('node',{type:n.type,col:n.col});
  if(n.type==='battle'||n.type==='elite'||n.type==='boss'){
    let kind=n.type, fac=nodeFaction(n);
    if(RUN.ambush && kind==='battle'){ kind='elite'; fac=RUN.fac==='hegemony'?RUN.map.fac:'hegemony'; RUN.ambush=false; toast('The Hegemony escort you robbed has found you.'); }
    battleScreen({kind,fac,col:n.col,node:id});
  }
  else if(n.type==='event') eventScreen(n);
  else if(n.type==='shipyard') shipyardScreen(n);
  else if(n.type==='drydock') drydockScreen(n);
  else if(n.type==='field') fieldRepairs(n);
};
function completeNode(){ const n=findNode(RUN.curNode); if(n) n.done=true; RUN.curNode=null; saveRun(); }

// ---------- fleet management ----------
function shipCard(s, opts={}){
  const t=HULLS[s.tpl], d=derive(s), c=s.cap;
  const nextXp=RANK_XP[c.rank+1];
  const weap=d.weapons.map(w=>`<div class="dim" style="font-size:14px">${esc(w.n)} <span class="pill">${w.arc==='T'?'Turret':ARC_NAME[w.arc]}</span> ${w.shots}\u00d7${w.dmg}, range ${w.r}${w.cd?`, reload ${w.cd}`:''}</div>`).join('');
  const slots=[]; for(let i=0;i<t.slots;i++){ const m=s.mods[i];
    slots.push(m?`<div class="row" style="justify-content:space-between;font-size:14px;margin:3px 0"><span><b>${esc(modName(m))}</b> <span class="dim">${esc(MODULES[m].d)}</span></span>${opts.refit?`<button class="small" data-act="unequip" data-arg="${s.uid}:${i}">Remove</button>`:''}</div>`:`<div class="dim" style="font-size:14px;margin:3px 0">Empty refit slot</div>`); }
  return `<div class="card"><div class="row"><h3>${esc(s.name)}</h3><span class="spacer"></span><span class="pill g">Mk ${roman(s.mk)}</span></div>
    <p style="margin:0">${t.n}</p>
    <div class="row num" style="font-size:14px;margin-top:6px"><span>Hull ${s.hp}/${d.maxHp}</span><span class="spacer"></span><span class="dim">${t.cp} CP</span></div>${hpBar(s.hp,d.maxHp)}
    <div class="stats num" style="grid-template-columns:auto 1fr auto 1fr"><b>Shields</b><span style="white-space:nowrap">${d.shMax}, +${d.regen}/turn</span><b>Armor</b><span>${pct(d.armor)}</span><b>Speed</b><span>${d.speed}</span><b>Turns</b><span>${d.turns}</span><b>Evasion</b><span>${d.ev}</span></div>
    ${t.ab?`<p style="margin:0 0 6px;font-size:14px"><span class="gilt">${ABILITIES[t.ab].n}.</span> <span class="dim">${esc(ABILITIES[t.ab].d)}</span></p>`:''}
    ${weap}
    <div class="sect"><h4>${rankName(c)} ${esc(c.name)}</h4>
      <div class="dim num" style="font-size:13px">${nextXp?`${c.xp}/${nextXp} experience to ${rankName(Object.assign({},c,{rank:c.rank+1}))}`:`${c.xp} experience, highest rank`}</div>
      <div>${c.perks.map(p=>`<span class="pill v" title="${esc(PERKS[p].d)}">${esc(PERKS[p].n)}</span>`).join('')||'<span class="dim" style="font-size:14px">No perks yet.</span>'}</div>
      ${c.pending?`<button class="primary small" style="margin-top:6px" data-act="promote" data-arg="${s.uid}">Choose promotion perk</button>`:''}
    </div>
    <div class="sect"><h4>Refits</h4>${slots.join('')}</div>
    ${opts.extra||''}</div>`;
}
function fleetScreen(back){
  const inv=RUN.inventory.map((m,i)=>{ const opts=RUN.fleet.filter(s=>s.mods.length<HULLS[s.tpl].slots && (!MODULES[m].only||HULLS[s.tpl].ab===MODULES[m].only));
    return `<div class="card"><h3>${esc(modName(m))}</h3><p>${esc(MODULES[m].d)}</p><div class="foot row wrap">${opts.length?opts.map(s=>`<button class="small" data-act="equip" data-arg="${i}:${s.uid}">Fit to ${esc(s.name)}</button>`).join(''):'<span class="dim">No free compatible slot. Remove a refit first.</span>'}</div></div>`; }).join('');
  show(`<div class="screen"><div class="page">
    <div class="row"><h2 class="gothic">Fleet</h2><span class="spacer"></span><button class="primary" data-act="${back==='shipyard'?'backShipyard':'backMap'}">Done</button></div>
    <p class="lede">Refits can be moved between ships freely. Mark upgrades and repairs happen at shipyards and drydocks.</p>
    ${inv?`<h3 style="margin:0 0 10px">In the hold</h3><div class="cards" style="margin-bottom:22px">${inv}</div>`:''}
    <div class="cards">${RUN.fleet.map(s=>shipCard(s,{refit:true})).join('')}</div>
  </div></div>`);
  RUN._fleetBack=back;
}
ACT.fleetScreen=()=>fleetScreen('map');
ACT.backMap=()=>{ saveRun(); mapScreen(); };
ACT.equip=arg=>{ const [i,uid]=arg.split(':'); const s=RUN.fleet.find(x=>x.uid===uid); const m=RUN.inventory[+i]; if(!s||!m) return;
  changeShip(s,sh=>sh.mods.push(m)); RUN.inventory.splice(+i,1); fleetScreen(RUN._fleetBack); };
ACT.unequip=arg=>{ const [uid,i]=arg.split(':'); const s=RUN.fleet.find(x=>x.uid===uid); if(!s) return; let m; changeShip(s,sh=>{ m=sh.mods.splice(+i,1)[0]; }); if(m) RUN.inventory.push(m); fleetScreen(RUN._fleetBack); };
ACT.promote=uid=>promoteModal(uid, ()=>fleetScreen(RUN._fleetBack));
function promoteModal(uid, after){
  const s=RUN.fleet.find(x=>x.uid===uid); if(!s||!s.cap.pending){ after(); return; }
  if(!s.cap.offer) s.cap.offer=shuffle(Object.keys(PERKS).filter(p=>!s.cap.perks.includes(p) && (p!=='wing'||HULLS[s.tpl].ab==='launch'))).slice(0,2);
  window._promoteAfter=after;
  modal(`<h2>Promotion</h2><p>${esc(s.cap.name)} of the <i>${esc(s.name)}</i> is now ${rankName(s.cap)}. Choose one perk.</p>
    ${s.cap.offer.map(p=>`<button class="choice" data-act="takePerk" data-arg="${uid}:${p}"><b>${esc(PERKS[p].n)}</b><small>${esc(PERKS[p].d)}</small></button>`).join('')}`);
}
ACT.takePerk=arg=>{ const [uid,p]=arg.split(':'); const s=RUN.fleet.find(x=>x.uid===uid); if(!s) return;
  changeShip(s,sh=>{ sh.cap.perks.push(p); sh.cap.pending--; sh.cap.offer=null; }); closeModal();
  if(s.cap.pending>0) promoteModal(uid, window._promoteAfter); else window._promoteAfter(); };

// ---------- shipyard ----------
function shipyardStock(n){
  if(n.stock) return n.stock;
  const hulls=['warden','harrow','penitent']; if(META.unlocked.u_carrier) hulls.push('reliquary'); if(META.unlocked.u_battleship) hulls.push('cathedral'); if(META.unlocked.u_dread) hulls.push('ascendant');
  const own=[...new Set(hulls.map(h=>equivHull(h,RUN.fac)))]; hulls.length=0; hulls.push(...own);
  const pickH=shuffle(hulls.slice()).slice(0,3).sort((a,b)=>(HULLS[a].cp||1)-(HULLS[b].cp||1)); // each yard has its own few hulls
  /* hull variants you've unlocked are sold beside their standard hull */ for(const h of pickH.slice()){ for(const [vid,v] of Object.entries(HULL_VARIANTS)) if(v.base===h&&META.variants&&META.variants[vid]) pickH.splice(pickH.indexOf(h)+1,0,vid); }
  n.stock={hulls:pickH, mods:shuffle(modulePool()).slice(0,3), sold:[]};
  return n.stock;
}
let yardNode=null;
function shipyardScreen(n){
  yardNode=n; const st=shipyardStock(n), pm=priceMult();
  const cp=fleetCP();
  const hulls=st.hulls.map(h=>{ const t=HULLS[h], cost=Math.round(t.cost*pm); const fits=cp+t.cp<=RUN.cpCap; const uniq=t.unique&&RUN.fleet.some(s=>s.tpl===h);
    return `<div class="card"><h3>${t.n}${t.variant?' <span class="pill g">Variant</span>':''}</h3>${t.variant?`<p class="gilt" style="font-size:14px">${esc(HULL_VARIANTS[t.variant].d)}</p>`:''}<p class="num">${t.cp} CP. Hull ${t.hp}, shields ${t.sh}, speed ${t.sp}, turns ${t.tn}.</p><p>${t.w.map(([id,a])=>W[id].n+' ('+(a==='T'?'turret':ARC_NAME[a].toLowerCase())+')').join(', ')}.</p><p class="dim">Ability: ${t.ab?ABILITIES[t.ab].n:'none'}</p>
      <div class="foot"><button ${RUN.credits>=cost&&fits&&!uniq?'':'disabled'} data-act="buyHull" data-arg="${h}">Buy for ${cost}</button> ${!fits?'<span class="dim">Not enough command points</span>':uniq?'<span class="dim">Only one allowed</span>':''}</div></div>`; }).join('');
  const mods=st.mods.map((m,i)=>{ const sold=st.sold.includes(i), cost=Math.round(MODULES[m].cost*pm);
    return `<div class="card"><h3>${esc(modName(m))}</h3><p>${esc(MODULES[m].d)}</p><div class="foot">${sold?'<span class="verd">Bought</span>':`<button ${RUN.credits>=cost?'':'disabled'} data-act="buyMod" data-arg="${i}">Buy for ${cost}</button>`}</div></div>`; }).join('');
  const ships=RUN.fleet.map(s=>{ const d=derive(s), miss=d.maxHp-s.hp, rc=Math.ceil(miss/2*pm), mc=mkCost(s), sell=Math.round(HULLS[s.tpl].cost*.35);
    return shipCard(s,{extra:`<div class="sect row wrap">
      <button class="small" ${miss>0&&RUN.credits>=rc?'':'disabled'} data-act="repair" data-arg="${s.uid}">${miss>0?`Repair ${miss} for ${rc}`:'Fully repaired'}</button>
      <button class="small" ${s.mk<3&&RUN.credits>=mc?'':'disabled'} data-act="upgradeMk" data-arg="${s.uid}">${s.mk<3?`Mk ${roman(s.mk+1)} for ${mc}`:'Max Mark'}</button>
      <button class="small danger" ${RUN.fleet.length>1?'':'disabled'} data-act="sellShip" data-arg="${s.uid}">Decommission (+${sell})</button></div>`}); }).join('');
  const allMiss=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp-s.hp,0), allCost=Math.ceil(allMiss/2*pm);
  show(`<div class="screen"><div class="page">
    <div class="row wrap"><h2 class="gothic">Shipyard</h2><span class="spacer"></span><span class="gilt num" style="font-size:22px">${RUN.credits} credits</span>
      <span class="num">${cp}/${RUN.cpCap} CP</span><button data-act="yardFleet">Refits</button><button class="primary" data-act="leaveYard">Leave shipyard</button></div>
    <p class="lede">Repairs cost 1 credit per 2 hull. A Mark upgrade adds 20% hull and shields and 15% damage. New hulls come with a fresh lieutenant.</p>
    <div class="row" style="margin-bottom:14px"><button ${allMiss>0&&RUN.credits>=allCost?'':'disabled'} data-act="repairAll">${allMiss>0?`Repair entire fleet for ${allCost}`:'Fleet fully repaired'}</button></div>
    <div class="cards">${ships}</div>
    <h3 style="margin:26px 0 10px">Hulls for sale</h3><div class="cards">${hulls}</div>
    <h3 style="margin:26px 0 10px">Refits for sale</h3><div class="cards">${mods}</div>
  </div></div>`);
}
ACT.yardFleet=()=>fleetScreen('shipyard');
ACT.backShipyard=()=>shipyardScreen(yardNode);
ACT.leaveYard=()=>{ completeNode(); mapScreen(); };
ACT.buyHull=h=>{ const t=HULLS[h], cost=Math.round(t.cost*priceMult()); if(RUN.credits<cost||fleetCP()+t.cp>RUN.cpCap) return; RUN.credits-=cost; try{ tel('shop',{k:'hull',id:h,cost}); }catch(e){} const s=newShip(h); RUN.fleet.push(s); toast(`The ${s.name} joins the fleet.`); shipyardScreen(yardNode); };
ACT.buyMod=i=>{ const st=yardNode.stock, m=st.mods[+i], cost=Math.round(MODULES[m].cost*priceMult()); if(st.sold.includes(+i)||RUN.credits<cost) return; RUN.credits-=cost; try{ tel('shop',{k:'mod',id:m,cost}); }catch(e){} st.sold.push(+i); RUN.inventory.push(m); toast(`${modName(m)} is in the hold. Fit it from Refits.`); shipyardScreen(yardNode); };
ACT.repair=uid=>{ const s=RUN.fleet.find(x=>x.uid===uid), d=derive(s), miss=d.maxHp-s.hp, c=Math.ceil(miss/2*priceMult()); if(RUN.credits<c) return; RUN.credits-=c; s.hp=d.maxHp; shipyardScreen(yardNode); };
ACT.repairAll=()=>{ const pm=priceMult(); const miss=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp-s.hp,0), c=Math.ceil(miss/2*pm); if(RUN.credits<c) return; RUN.credits-=c; RUN.fleet.forEach(s=>s.hp=derive(s).maxHp); shipyardScreen(yardNode); };
ACT.upgradeMk=uid=>{ const s=RUN.fleet.find(x=>x.uid===uid), c=mkCost(s); if(s.mk>=3||RUN.credits<c) return; RUN.credits-=c; try{ tel('shop',{k:'mk',id:s.tpl,cost:c}); }catch(e){} changeShip(s,sh=>sh.mk++); toast(`${s.name} refitted to Mk ${roman(s.mk)}.`); shipyardScreen(yardNode); };
ACT.sellShip=uid=>{ if(RUN.fleet.length<=1) return; const s=RUN.fleet.find(x=>x.uid===uid);
  modal(`<h2>Decommission the ${esc(s.name)}?</h2><p class="muted">Its captain retires and its refits return to the hold. You receive ${Math.round(HULLS[s.tpl].cost*.35)} credits.</p><div class="row"><button class="primary danger" data-act="sellConfirm" data-arg="${uid}">Decommission</button><button data-act="closeModal">Keep it</button></div>`); };
ACT.sellConfirm=uid=>{ const i=RUN.fleet.findIndex(x=>x.uid===uid); if(i<0) return; const s=RUN.fleet[i]; RUN.inventory.push(...s.mods); RUN.credits+=Math.round(HULLS[s.tpl].cost*.35); RUN.fleet.splice(i,1); closeModal(); shipyardScreen(yardNode); };

// ---------- drydock ----------
function drydockScreen(n){
  const lines=RUN.fleet.map(s=>{ const d=derive(s), miss=d.maxHp-s.hp, fix=Math.ceil(miss*.6*repairMult()); s.hp+=fix; return fix?`<li>${esc(s.name)}: +${fix} hull</li>`:''; }).join('');
  completeNode(); mapScreen();
  modal(`<h2>Drydock</h2><p>Your crews work around the clock under a friendly station\u2019s floodlights. Repair teams restore 60% of every ship\u2019s missing hull.</p>
    ${lines?`<ul class="num">${lines}</ul>`:'<p class="muted">The fleet was already in good order.</p>'}<div class="row"><button class="primary" data-act="closeModal">Continue</button><button data-act="fleetFromModal">Manage fleet</button></div>`);
}
ACT.fleetFromModal=()=>{ closeModal(); fleetScreen('map'); };

// ---------- events ----------
let curEvent=null;
function eventScreen(n){
  RUN.seenEvents=RUN.seenEvents||[];
  const fits=e=>!(e.not&&e.not.includes(RUN.fac)); let pool=EVENTS.filter(e=>fits(e)&&!RUN.seenEvents.includes(e.id)); if(!pool.length){ RUN.seenEvents=[]; pool=EVENTS.filter(fits); }
  const ev=pick(pool); RUN.seenEvents.push(ev.id); curEvent=Object.assign({},ev,(ev.v&&ev.v[RUN.fac])||{}); /* each faction tells it in its own words */
  mapScreen();
  modal(`<h2>${esc(curEvent.t)}</h2><p>${esc(curEvent.b)}</p>${curEvent.o.map((o,i)=>{ const cost=o.r&&o.r.cost; const ok=!cost||RUN.credits>=cost;
    return `<button class="choice" ${ok?'':'disabled'} data-act="eventChoice" data-arg="${i}"><b>${esc(o.l)}</b><small>${esc(o.s)}${!ok?' (not enough credits)':''}</small></button>`; }).join('')}`);
}
function randShip(){ return pick(RUN.fleet); }
function applyOutcome(r){
  const out=[];
  if(r==='derelictBoard'){ if(rnd()<.6){ const m=randomModule(); RUN.inventory.push(m); RUN.credits+=40; out.push(`Your boarding parties return with a ${modName(m)} and 40 credits of salvage.`); }
    else { const s=randShip(), d=derive(s), dm=Math.round(d.maxHp*.25); s.hp=Math.max(1,s.hp-dm); RUN.credits+=20; out.push(`Something was awake. The ${s.name} takes ${dm} hull damage covering the retreat. You salvage 20 credits.`); } return out; }
  if(r.cost){ RUN.credits-=r.cost; }
  if(r.cred){ RUN.credits+=r.cred; out.push(`+${r.cred} credits.`); }
  if(r.xp){ RUN.fleet.forEach(s=>addXp(s,r.xp)); out.push(`Every captain gains ${r.xp} experience.`); }
  if(r.xpLow){ const s=[...RUN.fleet].sort((a,b)=>a.cap.xp-b.cap.xp)[0]; addXp(s,r.xpLow); out.push(`${s.cap.name} of the ${s.name} gains ${r.xpLow} experience.`); }
  if(r.loseMod){ const withMod=RUN.fleet.filter(s=>s.mods.length); if(withMod.length){ const s=pick(withMod); let m; changeShip(s,sh=>{ m=sh.mods.splice(Math.floor(rnd()*sh.mods.length),1)[0]; }); out.push(`The ${s.name} gives up its ${modName(m)}.`); } else if(RUN.inventory.length){ const m=RUN.inventory.splice(0,1)[0]; out.push(`You hand over the ${modName(m)} from the hold.`); } else out.push('You have no refits to give. The seer smiles and gives anyway.'); }
  if(r.relic){ const rl=randomRelic(); if(rl){ RUN.relics.push(rl); changeFleet(()=>{}); out.push(`Relic gained: ${relicName(rl)}. ${RELICS[rl].d}`); } else { RUN.credits+=80; out.push('No relics left to find. +80 credits instead.'); } }
  if(r.dmgOne){ const s=randShip(), d=derive(s), dm=Math.round(d.maxHp*r.dmgOne); s.hp=Math.max(1,s.hp-dm); out.push(`The ${s.name} takes ${dm} hull damage.`); }
  if(r.dmgAll){ RUN.fleet.forEach(s=>{ s.hp=Math.max(1,s.hp-Math.round(derive(s).maxHp*r.dmgAll)); }); out.push(`Every ship takes ${pct(r.dmgAll)} hull damage.`); }
  if(r.ship){ const tp=equivHull(r.ship,RUN.fac); if(fleetCP()+HULLS[tp].cp<=RUN.cpCap){ const s=newShip(tp,r.vet); RUN.fleet.push(s); out.push(`The ${s.name} joins the fleet under ${rankName(s.cap)} ${s.cap.name}.`); } else { RUN.credits+=r.cost||0; out.push('You don\u2019t have the command points to take her on. Your credits are returned.'); } }
  if(r.upgradeOne){ const s=[...RUN.fleet].sort((a,b)=>(a.hp/derive(a).maxHp)-(b.hp/derive(b).maxHp))[0]; changeShip(s,sh=>{ if(sh.mk<3) sh.mk++; }); s.hp=derive(s).maxHp; out.push(`The ${s.name} leaves the forge fully repaired at Mk ${roman(s.mk)}.`); }
  if(r.healAll){ RUN.fleet.forEach(s=>{ const d=derive(s); s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*r.healAll)); }); out.push(`Every ship repairs ${pct(r.healAll)} of its hull.`); }
  if(r.gamble){ if(rnd()<.5){ RUN.fleet.forEach(s=>{ const d=derive(s); s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*.3)); }); out.push('The saint answers. Every ship repairs 30% of its hull.'); } else out.push('Silence. The void keeps its own counsel.'); }
  if(r.mod){ const m=randomModule(); RUN.inventory.push(m); out.push(`Found: ${modName(m)}. It\u2019s in the hold.`); }
  if(r.ambush){ RUN.ambush=true; }
  if(!out.length && !r.fight) out.push('You move on.');
  return out;
}
ACT.eventChoice=i=>{
  const o=curEvent.o[+i]; if(o.r&&o.r.cost&&RUN.credits<o.r.cost) return;
  if(o.r&&o.r.fight){ closeModal(); battleScreen({kind:'elite',fac:o.r.fight,col:findNode(RUN.curNode).col+1,node:RUN.curNode,eventRelic:true}); return; }
  const lines=applyOutcome(o.r);
  completeNode(); mapScreen();
  modal(`<h2>${esc(curEvent.t)}</h2>${lines.map(l=>`<p>${esc(l)}</p>`).join('')}<button class="primary" data-act="closeModal">Continue</button>`);
};

// ---------- rewards ----------
function rewardFlow(summary){
  const cfg=summary.cfg, s=RUN.sector, rf=runFx();
  RUN.stats.battles++; if(cfg.kind==='elite') RUN.stats.elites++; if(cfg.kind==='boss') RUN.stats.bosses++;
  const kindMult=cfg.kind==='boss'?3:cfg.kind==='elite'?1.6:1;
  const scnd=sectorCond(); let credits=Math.round((25+12*s+3*(cfg.col||0))*kindMult*(1+(rf.credPct||0)+((scnd&&scnd.cred)||0))); if(cfg.mod==='bounty') credits=Math.round(credits*1.5);
  if(summary.partial) credits=Math.round(credits/2); // the objective got away: half pay
  if(rf.salvage){ credits+=15; RUN.fleet.forEach(sh=>{ const d=derive(sh); sh.hp=Math.min(d.maxHp,sh.hp+Math.round(d.maxHp*.08)); }); }
  RUN.credits+=credits;
  // the node's payout: a patron's boon (pick 1 of 3), a refit (pick 1 of 3), or credits or repairs
  const node=cfg.node&&findNode(cfg.node); ensurePatrons(); const rw=(node&&node.rw)||(cfg.kind==='battle'?{k:'boon',p:pick(RUN.patrons)}:{k:'boon',p:pick(RUN.patrons),min:1});
  const fl0=RUN.flagUid; ensureFlagship(); const flagMoved=fl0&&RUN.flagUid!==fl0&&flagshipOf();
  let extra=''; if(rw.k==='cred'){ const v=35+10*s; RUN.credits+=v; extra=`<p class="gilt">Salvage: +${v} credits.</p>`; }
  if(rw.k==='repair'){ RUN.fleet.forEach(sh=>{ const d=derive(sh); sh.hp=Math.min(d.maxHp,sh.hp+Math.round(d.maxHp*.25*repairMult())); }); extra='<p class="verd">Field repairs: every ship repairs 25% of its hull.</p>'; }
  window._rewardCfg=cfg; window._rw=rw; window._boonOffer=null; window._modOffer=null;
  window._relicChoice=(cfg.kind==='elite'||cfg.kind==='boss')?shuffle(Object.keys(RELICS).filter(r=>!RUN.relics.includes(r)&&relicUseful(r))).slice(0,cfg.kind==='boss'?3:2):[];
  const xpLines=summary.xp.map(x=>`<li>${esc(x.cap)} of the ${esc(x.ship)}: +${x.xp} experience${x.up?` <span class="gilt">promoted to ${RANKS[x.rank]}</span>`:''}</li>`).join('');
  const lost=summary.lost.length?`<p class="blood">Lost: ${summary.lost.map(l=>`the ${esc(l.ship)} and ${esc(l.cap)}`).join(', ')}.</p>`:'';
  const next=rw.k==='boon'&&PATRONS[rw.p]?`<button class="primary" data-act="rewardNext" style="background:${PATRONS[rw.p].col};border-color:${PATRONS[rw.p].col};color:#0f1626">${esc(PATRONS[rw.p].short)} offers a boon</button>`:rw.k==='mod'?'<button class="primary" data-act="rewardNext">Choose a refit</button>':'<button class="primary" data-act="rewardNext">Continue</button>';
  modal(`<h2>${cfg.kind==='boss'?'Flagship destroyed':'Victory'}</h2>
    <p class="num">${summary.kills} enemy ship${summary.kills===1?'':'s'} destroyed in ${summary.rounds} round${summary.rounds===1?'':'s'}. <span class="gilt">+${credits} credits.</span></p>${lost}${extra}
    ${(()=>{ const st=summary.boonStats||{}, ks=Object.keys(st).filter(k=>BOONS[k]); return ks.length?`<p style="font-size:14px;margin:6px 0">Boons in action: ${ks.map(k=>{ const b=BOONS[k], P=b.p?PATRONS[b.p]:PATRONS[b.duo[0]]; return `<span style="color:${P.col}">${esc(b.n)}</span> \u00d7${st[k]}`; }).join(', ')}.</p>`:(RUN.boons||[]).length?'<p class="dim" style="font-size:13.5px">No boon triggered this battle. Check the Fleet boons section on a ship to see what sets each one off.</p>':''; })()}
    ${flagMoved?`<p class="gilt">The admiral transfers the flag to the ${esc(flagMoved.name)}. Its aspect goes with it.</p>`:''}
    ${xpLines?`<ul class="num" style="padding-left:18px">${xpLines}</ul>`:''}${next}`);
}
ACT.rewardNext=()=>{ const rw=window._rw||{}; closeModal();
  if(rw.k==='boon') return boonStep(rw.p,rw.min||0);
  if(rw.k==='mod'){ const opts=shuffle(modulePool()).slice(0,3); window._modOffer=opts;
    modal(`<h2>Salvaged refits</h2><p>Take one. It goes in the hold; fit it at a shipyard or from the fleet screen.</p>${opts.map(m=>`<button class="choice" data-act="takeMod" data-arg="${m}"><b>${esc(modName(m))}</b><small>${esc(MODULES[m].d)}</small></button>`).join('')}`); return; }
  relicStep(); };
ACT.takeMod=m=>{ RUN.inventory.push(m); try{ tel('reward_pick',{k:'mod',id:m,offered:window._modOffer}); }catch(e){} toast(`${modName(m)} stowed in the hold.`); closeModal(); relicStep(); };
// a patron offers three boons; rarity shows how strong each one is
function boonStep(p,minR){ const P=PATRONS[p]; if(!P){ relicStep(); return; } const offer=rollBoonOffer(p,minR); window._boonOffer=offer;
  if(!offer.length){ RUN.credits+=60; toast('Nothing left to offer. +60 credits.'); relicStep(); return; }
  modal(`<div class="boonhead" style="border-color:${P.col}"><span class="sigil" style="background:${P.col}">${P.glyph}</span><div><h2 style="margin:0;color:${P.col}">${esc(P.n)}</h2><div class="muted" style="font-size:14px">${esc(P.theme)}</div></div></div>
    <p class="muted" style="font-style:italic;margin:8px 0 12px">“${esc(P.quote)}”</p>
    ${offer.map((o,i)=>{ const b=BOONS[o.id], R=RARITY[o.r||0], duo=b.duo; return `<button class="choice boon" data-act="takeBoon" data-arg="${i}" style="border-left:4px solid ${duo?PATRONS[duo[0]].col:P.col}">
      <span class="rar" style="color:${duo?'#ffd27a':R.col}">${duo?'Duo: '+duo.map(q=>esc(PATRONS[q].short)).join(' + '):R.n}</span><b>${esc(b.n)}</b><small>${esc(b.d(R.m))}</small></button>`; }).join('')}`); }
ACT.takeBoon=i=>{ const o=(window._boonOffer||[])[+i]; if(!o) return; changeFleet(()=>{ RUN.boons=RUN.boons||[]; RUN.boons.push({id:o.id,r:o.r||0}); });
  { const ps=BOONS[o.id].p?[BOONS[o.id].p]:(BOONS[o.id].duo||[]); META.favour=META.favour||{}; for(const p of ps){ const t0=favourTier(p); META.favour[p]=(META.favour[p]||0)+1+(o.r||0); const t1=favourTier(p); if(t1>t0) setTimeout(()=>toast(`${PATRONS[p].n} now counts you ${FAVOUR_TIERS[t1].n}: ${FAVOUR_TIERS[t1].d}`),900); } }
  try{ tel('boon_pick',{id:o.id,r:o.r||0,p:BOONS[o.id].p||'duo',offered:(window._boonOffer||[]).map(x=>x.id+':'+(x.r||0)),sector:RUN.sector}); }catch(e){}
  toast(`${BOONS[o.id].n} gained.`); closeModal(); relicStep(); };
function relicStep(){
  const rc=window._relicChoice;
  if(rc && rc.length){
    modal(`<h2>${window._rewardCfg.kind==='boss'?'The flagship\u2019s vault':'Spoils of the elite'}</h2><p>Choose a relic. Relics last for the rest of the run.</p>
      ${rc.map(r=>`<button class="choice" data-act="takeRelic" data-arg="${r}"><b>${esc(relicName(r))}</b><small>${esc(RELICS[r].d)}</small></button>`).join('')}`);
    return;
  }
  promotionsStep();
}
ACT.takeRelic=r=>{ changeFleet(()=>RUN.relics.push(r)); window._relicChoice=null; closeModal(); promotionsStep(); };
function promotionsStep(){
  const s=RUN.fleet.find(x=>x.cap.pending>0);
  if(s){ promoteModal(s.uid, promotionsStep); return; }
  afterBattle();
}
function afterBattle(){
  const cfg=window._rewardCfg;
  completeNode();
  if(cfg.kind==='boss'){
    if(RUN.sector>=3){ endRun(true); return; }
    RUN.sector++; RUN.cpCap+=3; RUN.map=genSector(RUN.sector); RUN.pos=null;
    RUN.fleet.forEach(s=>{ const d=derive(s); s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*.4*repairMult())); });
    saveRun(); mapScreen();
    const F=FACTIONS[RUN.map.fac];
    modal(`<h2>Sector ${roman(RUN.sector)}</h2><p>With the flagship broken, the fleet jumps deeper. Fleet command expands: <b class="gilt">+3 command points</b>, and crews patch 40% of every hull during the transit.</p>
      <p>Auspex confirms <b>${esc(F.n)}</b> ahead.</p>${(()=>{ const c=sectorCond(); return c?`<p class="gilt">Sector condition: <b>${esc(c.n)}</b>. <span class="muted">${esc(c.d)}</span></p>`:''; })()}<p class="muted">${esc(F.blurb)}</p><button class="primary" data-act="closeModal">Plot a course</button>`);
    return;
  }
  mapScreen();
}
