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
const MAP_NAME={belt:'asteroid belt',station:'orbital station',planet:'planet edge',storm:'ion storm',graveyard:'ship graveyard'};
function mapScreen(){
  B=null;
  const m=RUN.map, avail=new Set(availableNodes()), F=FACTIONS[m.fac];
  const port=innerWidth<720&&innerHeight>innerWidth;
  const PX=n=>port?34+n.y*380:60+n.col*130, PY=n=>port?60+n.col*130:34+n.y*380;
  const byId={}; for(const c of m.cols) for(const n of c) byId[n.id]=n;
  for(const n of Object.values(byId)) if(!n.done&&!n.enc&&(n.type==='battle'||n.type==='elite')) Object.assign(n,rollEncounter(n.type,n.col)); // older saves
  if(!m.region&&typeof pickRegion==='function'){ try{ m.region=pickRegion(m.fac); m.biome=rollBiome(m.region); for(const n of Object.values(byId)) if(!n.done){ n.map=regionMap(m.region,n.col,m.cols.length); fitEncounter(n); } saveRun(); }catch(e){} } // v47: runs started before regions
  ensureNemesis(); ensurePatrons(); for(const n of Object.values(byId)) if(!n.done&&!n.rw&&(n.type==='battle'||n.type==='elite'||n.type==='boss')) n.rw=rollNodeReward(n.type);
  if(nodeSeeds(Object.values(byId))) saveRun(); // v53: each fight node carries its battle seed in the save, so a mid-battle reload replays the same fight
  const edges=m.edges.map(([a,b])=>{ const A=byId[a],Bn=byId[b]; const trav=A.done&&(Bn.done||RUN.pos===b);
    return `<line x1="${PX(A)}" y1="${PY(A)}" x2="${PX(Bn)}" y2="${PY(Bn)}" stroke="${trav?'#d0a64b':RUN.pos===a&&avail.has(b)?'rgba(208,166,75,.55)':'rgba(230,220,196,.13)'}" stroke-width="${trav?3:2}" ${RUN.pos===a&&avail.has(b)?'stroke-dasharray="6 5"':''}/>`; }).join('');
  const nodes=Object.values(byId).map(n=>{ const x=PX(n), y=PY(n), av=avail.has(n.id), cur=RUN.pos===n.id, r=n.type==='boss'?26:19;
    const col = n.done?'#7d7768': n.type==='elite'||n.type==='boss'?'#e07a70': av?'#e6dcc4':'#8a8474';
    return `<g class="node ${av?'avail':''}" ${av?`data-act="enterNode" data-arg="${n.id}" tabindex="0" role="button" aria-label="${NODE_INFO[n.type].n}"`:''}>
      <title>${NODE_INFO[n.type].n}${n.map&&MAP_NAME[n.map]&&(n.type==='battle'||n.type==='elite'||n.type==='boss')?' ('+MAP_NAME[n.map]+')':''}: ${n.enc&&ENCOUNTERS[n.enc]?ENCOUNTERS[n.enc].n+'. '+ENCOUNTERS[n.enc].d:NODE_INFO[n.type].d}${archLabel(n,(typeof nodeFaction==="function"?nodeFaction(n):m.fac))?' '+archLabel(n,(typeof nodeFaction==="function"?nodeFaction(n):m.fac))+'.':''}${n.mod&&NODE_MODS[n.mod]?' '+NODE_MODS[n.mod].n+': '+NODE_MODS[n.mod].d:''}</title>
      <circle cx="${x}" cy="${y}" r="${r}" fill="${n.done?'#1b2436':'#182133'}" class="ring" stroke="${cur?'#d0a64b':av?'rgba(208,166,75,.8)':'rgba(230,220,196,.18)'}" stroke-width="${cur||av?2.5:1.5}"/>
      ${av?`<circle cx="${x}" cy="${y}" r="${r+6}" fill="none" stroke="rgba(208,166,75,.35)" stroke-width="1"><animate attributeName="r" values="${r+3};${r+9};${r+3}" dur="2.4s" repeatCount="indefinite"/></circle>`:''}
      ${nodeIcon(n.type,x,y,col)}${n.enc&&ENCOUNTERS[n.enc]&&!n.done?`<text x="${x}" y="${y+r+15}" text-anchor="middle" font-size="12.5" fill="${av?'#e6dcc4':'#8a8474'}" font-family="var(--ui)">${ENCOUNTERS[n.enc].n}${n.mod&&NODE_MODS[n.mod]?' \u00b7 '+NODE_MODS[n.mod].short:''}</text>`:''}${n.map&&MAP_NAME[n.map]&&!n.done&&(n.type==='battle'||n.type==='elite'||n.type==='boss')?`<text x="${x}" y="${y-r-7}" text-anchor="middle" font-size="10.5" fill="#7f8fa6" font-family="var(--ui)">${MAP_NAME[n.map]}</text>`:''}${rewardBadge(n,x,y,r,av)}${!n.done&&nemNodeIs(n)?`<text x="${x}" y="${y-r-20}" text-anchor="middle" font-size="12" font-weight="700" fill="#ff6b5a" font-family="var(--ui)">Nemesis</text>`:''}</g>`; }).join('');
  const fleet=RUN.fleet.map(s=>{ const d=derive(s); return `<div class="shiprow"><span>${esc(s.name)}</span><span class="dim num">${s.hp}/${d.maxHp}</span>
    <span class="dim" style="grid-column:1/-1;font-size:13px">${HULLS[s.tpl].cls} Mk ${roman(s.mk)}, ${rankName(s.cap)} ${esc(s.cap.name)}${s.cap.pending?' <span class="gilt">(promotion ready)</span>':''}</span>${hpBar(s.hp,d.maxHp)}</div>`; }).join('');
  const relics=RUN.relics.length?RUN.relics.map(r=>`<div style="margin-bottom:6px"><b>${esc(relicName(r))}</b><div class="muted" style="font-size:14px">${esc(RELICS[r].d)}</div></div>`).join(''):'<p class="dim">None yet. Elite fleets and flagships carry them.</p>';
  const pend=RUN.fleet.some(s=>s.cap.pending);
  show(`<div class="mapwrap">
    <div class="mapmain">
      <div class="row wrap"><h2>Sector ${roman(RUN.sector)}${m.region&&REGIONS[m.region]?`: ${esc(REGIONS[m.region].n)}`:''}</h2><span class="spacer"></span><button data-act="saveQuit">Save and quit</button></div>
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
      ${nemPanel()}${verbPanel()}
      <h3>Fleet</h3>${fleet}
      <button class="${pend?'primary':''}" style="width:100%;margin-top:12px" data-act="fleetScreen">${pend?'Promote captains and refit':'Manage fleet and refits'}</button>
      ${RUN.inventory.length?`<p class="dim" style="font-size:14px">${RUN.inventory.length} refit${RUN.inventory.length>1?'s':''} in the hold.</p>`:''}
      ${RUN.aspect&&ASPECTS[RUN.aspect]?`<h3>Flagship</h3><p style="margin:0 0 4px"><b>${esc((flagshipOf()||{}).name||'')}</b> <span class="gilt">${esc(ASPECTS[RUN.aspect].n)}</span></p><p class="muted" style="font-size:14px;margin:0">${esc(ASPECTS[RUN.aspect].d)}</p>`:''}
      <h3>Boons</h3>${(RUN.boons||[]).length?RUN.boons.map(b=>boonLine(b,true)).join(''):'<p class="dim">None yet. Win at a node with a patron\u2019s sigil to earn one.</p>'}
      <p class="dim" style="font-size:13px">Patrons this run: ${RUN.patrons.map(p=>`<span style="color:${PATRONS[p].col}">${esc(PATRONS[p].short)}</span>`).join(', ')}</p>
      <h3>Relics</h3>${relics}
    </aside></div>`);
}
// B4: the Nemesis card on the map (clock, known weaknesses, adaptations) and the faction verb button
function nemPanel(){ const N=RUN.nem; if(!N||!N.persona) return ''; const F=FACTIONS[N.fac], NF=NEM_FAC[N.fac], P=NEM_PERSONA[N.persona];
  if(N.dead) return `<h3>Nemesis</h3><p class="muted" style="font-size:14px">${esc(nemFull())} is dead.</p>`;
  const dots='●'.repeat(Math.floor(N.clock))+(N.clock%1?'◐':'')+'○'.repeat(Math.max(0,NEM_CLOCK-Math.ceil(N.clock))), met=N.met>=RUN.sector;
  return `<h3>Nemesis</h3><div class="nemcard" data-portrait="${esc(N.portrait)}" data-scars="${esc((N.scarKinds||[]).join(','))}"><p style="margin:0 0 4px"><b class="blood">${esc(nemFull())}</b> <span class="dim">${esc(F?F.n:'')}${N.scars?`, scarred ${N.scars}x`:''}</span></p>
    <p style="margin:0;font-size:13.5px"><span class="gilt">${esc(P.n)}:</span> <span class="muted">${esc(P.d)}</span></p>
    <p style="margin:2px 0 0;font-size:13.5px">Strengths: ${N.traits.map(t=>`<span class="blood" title="${esc(NEM_TRAITS[t].d)}">${esc(NEM_TRAITS[t].n)}</span>`).join(', ')}</p>
    <p class="muted" style="font-size:13px;margin:4px 0 0">${esc(nemSay(NF.beh.d,N))}</p>${nemWarnLine(N)}
    ${NF.beh.feeds?`<p style="font-size:13px;margin:2px 0 0">Fed on your losses: <span class="blood">${N.fed||0} of 8</span>${N.fed?` (+${Math.round(Math.min(.32,.04*N.fed)*100)}% hull)`:''}</p>`:''}${(N.loot||N.held)?`<p style="font-size:13px;margin:2px 0 0">${nemPr(N).He} holds <span class="gilt">${[N.loot?N.loot+' of your credits':'',N.held?'the '+esc(N.held.name):''].filter(Boolean).join(' and ')}</span>: it all comes back when ${nemPr(N).he} dies.</p>`:''}
    <p class="num" style="margin:4px 0 0;font-size:14px">Hunting you: <span class="blood">${dots}</span>${N.strike?' <b class="blood">His fleet is coming: your next fight is his.</b>':met?' <span class="dim">(met this sector)</span>':''}</p>
    <p class="muted" style="font-size:13px;margin:4px 0 0">${esc(nemSay('Every fight you win moves the clock on; when it fills, your next fight is against him. You meet him once each sector at the latest before the rest stop.',N))}</p>
    <div style="font-size:13.5px;margin-top:4px">Weaknesses: ${N.weak.map(w=>N.revealed.includes(w)?`<span class="gilt" title="${esc(NEM_WEAK[w].d)}">${esc(NEM_WEAK[w].n)}</span>`:'<span class="dim">unknown</span>').join(', ')}</div>
    ${N.adapt.length?`<div style="font-size:13.5px;margin-top:2px">Adapted: ${N.adapt.map(a=>`<span class="blood" title="${esc(nemAdaptDesc(a,N.fac))}">${esc(nemAdaptName(a,N.fac))}</span>`).join(', ')}</div>`:''}
    ${N.last_beat?`<div class="muted" style="font-size:13px;margin-top:2px">${nemPr(N).He} remembers losing to your ${esc(NEM_BEAT_WORD[N.last_beat]||N.last_beat)}.</div>`:''}</div>`; }
function verbPanel(){ const V=verbFor(); if(!V) return ''; const used=(RUN.verbUsed||0)>=RUN.sector, ok=verbCanUse();
  return `<h3>Faction action</h3><button style="width:100%" ${ok?'':'disabled'} data-act="factionVerb"><b>${esc(V.n)}</b><small style="display:block">${esc(V.d)}</small><small style="display:block" class="dim">${used?'Used this sector':esc(verbCostText(V))}</small></button>${RUN.verbNext?'<p class="gilt" style="font-size:13px;margin:4px 0 0">Ready for your next battle.</p>':''}`; }
ACT.factionVerb=()=>{ const lines=useVerb(); if(!lines) return; saveRun(); mapScreen(); toast(lines.join(' ')); };
ACT.saveQuit=()=>{ saveRun(); titleScreen(); };
ACT.enterNode=id=>{
  if(!availableNodes().includes(id)) return;
  const n=findNode(id); RUN.pos=id; RUN.curNode=id;
  tel('node',{type:n.type,col:n.col});
  if(n.type==='battle'||n.type==='elite'||n.type==='boss'){
    let kind=n.type, fac=nodeFaction(n);
    if(nemNodeIs(n)){ ensureNemesis(); const fa=nemBeh().fleet; battleScreen(Object.assign({kind:'elite',fac:RUN.nem.fac,col:n.col,node:id,nemesis:nemBattleCfg()},ARCHETYPES[fa]?{arch:fa}:{})); return; } // B4: the Nemesis fight (marked on the map beforehand)
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
  modal(`<h2>Promotion</h2><p>${esc(s.cap.name)} of the <i>${esc(s.name)}</i> is now ${rankName(s.cap)}. Choose one perk.</p>${rewardDef('promotion')}
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
    <h3 style="margin:26px 0 10px">Class refits</h3><p class="muted" style="margin:0 0 8px">A class refit upgrades every ship of that class you own now or later: +6% hull and +6% damage per level, up to ${CLASS_TRACK_MAX}.</p>
    <div class="row wrap">${[...new Set(RUN.fleet.map(s=>HULLS[s.tpl].cls))].map(cls=>{ const lv=classTrack(cls), c=classTrackCost(cls), max=lv>=CLASS_TRACK_MAX; return `<button ${!max&&RUN.credits>=c?'':'disabled'} data-act="buyTrack" data-arg="${esc(cls)}">${esc(cls)} ${'●'.repeat(lv)}${'○'.repeat(CLASS_TRACK_MAX-lv)} ${max?'(full)':`for ${c}`}</button>`; }).join('')}</div>
  </div></div>`);
}
ACT.buyTrack=cls=>{ if(!buyClassTrack(cls)) return; try{ tel('shop',{k:'track',id:cls,lv:classTrack(cls)}); }catch(e){} toast(`${cls} refit level ${classTrack(cls)}: every ${cls.toLowerCase()} gains.`); shipyardScreen(yardNode); };
ACT.yardFleet=()=>fleetScreen('shipyard');
ACT.backShipyard=()=>shipyardScreen(yardNode);
ACT.leaveYard=()=>{ completeNode(); mapScreen(); };
ACT.buyHull=h=>{ const t=HULLS[h], cost=Math.round(t.cost*priceMult()); if(RUN.credits<cost||fleetCP()+t.cp>RUN.cpCap) return; RUN.credits-=cost; try{ tel('shop',{k:'hull',id:h,cost}); }catch(e){} const s=newShip(h); RUN.fleet.push(s); toast(`The ${s.name} joins the fleet.`); shipyardScreen(yardNode); };
ACT.buyMod=i=>{ const st=yardNode.stock, m=st.mods[+i], cost=Math.round(MODULES[m].cost*priceMult()); if(st.sold.includes(+i)||RUN.credits<cost) return; RUN.credits-=cost; try{ tel('shop',{k:'mod',id:m,cost}); }catch(e){} st.sold.push(+i); RUN.inventory.push(m); toast(`${modName(m)} is in the hold. Fit it from Refits.`); shipyardScreen(yardNode); };
ACT.repair=uid=>{ const s=RUN.fleet.find(x=>x.uid===uid), d=derive(s), miss=d.maxHp-s.hp, c=Math.ceil(miss/2*priceMult()); if(RUN.credits<c) return; RUN.credits-=c; s.hp=d.maxHp; shipyardScreen(yardNode); };
ACT.repairAll=()=>{ const pm=priceMult(); const miss=RUN.fleet.reduce((a,s)=>a+derive(s).maxHp-s.hp,0), c=Math.ceil(miss/2*pm); if(RUN.credits<c) return; RUN.credits-=c; RUN.fleet.forEach(s=>s.hp=derive(s).maxHp); shipyardScreen(yardNode); };
ACT.upgradeMk=uid=>{ const s=RUN.fleet.find(x=>x.uid===uid), c=mkCost(s); if(s.mk>=3||RUN.credits<c) return; RUN.credits-=c; try{ tel('shop',{k:'mk',id:s.tpl,cost:c}); }catch(e){} changeShip(s,sh=>sh.mk++); toast(`${s.name} refitted to Mk ${roman(s.mk)}.`); shipyardScreen(yardNode); };
ACT.sellShip=uid=>{ if(RUN.fleet.length<=1) return; const s=RUN.fleet.find(x=>x.uid===uid);
  modal(`<h2>Decommission the ${esc(s.name)}?</h2><p class="muted">Its captain retires and its refits return to the hold. You receive ${prizeScrap(s.tpl)} credits.</p><div class="row"><button class="primary danger" data-act="sellConfirm" data-arg="${uid}">Decommission</button><button data-act="closeModal">Keep it</button></div>`); };
ACT.sellConfirm=uid=>{ const i=RUN.fleet.findIndex(x=>x.uid===uid); if(i<0) return; const s=RUN.fleet[i]; RUN.inventory.push(...s.mods); RUN.credits+=prizeScrap(s.tpl); RUN.fleet.splice(i,1); closeModal(); shipyardScreen(yardNode); };

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
// B4: blue options. needMet says whether the fleet meets a requirement; needText says it in plain words (shown on the option either way)
const KIND_WORD={torp:'torpedoes',lance:'lances',flak:'point defense',batt:'batteries'};
function needMet(nd){ if(!nd) return true; const kit=fleetKit();
  if(nd.fac&&!(Array.isArray(nd.fac)?nd.fac.includes(RUN.fac):nd.fac===RUN.fac)) return false;
  if(nd.kind&&!kit[nd.kind]) return false; if(nd.carrier&&!kit.carrier) return false; if(nd.shields&&!kit.shields) return false;
  if(nd.relic&&!(nd.relic===1?RUN.relics.length>0:RUN.relics.includes(nd.relic))) return false; if(nd.mod&&!RUN.inventory.length) return false;
  if(nd.cred&&RUN.credits<nd.cred) return false; if(nd.vet&&!RUN.fleet.some(s=>(s.cap.rank||0)>=nd.vet)) return false;
  if(nd.flag&&!(RUN.flags&&RUN.flags[nd.flag]!=null)) return false; if(nd.intel&&((RUN.nem&&RUN.nem.revealed)||[]).length<nd.intel) return false; return true; }
function needText(nd){ if(!nd) return ''; const p=[];
  if(nd.fac){ const fs=Array.isArray(nd.fac)?nd.fac:[nd.fac]; p.push(fs.map(f=>FACTIONS[f]?FACTIONS[f].n:f).join(' or ')); }
  if(nd.kind) p.push((KIND_WORD[nd.kind]||nd.kind)+' in the fleet'); if(nd.carrier) p.push('a carrier'); if(nd.shields) p.push('a shielded ship'); if(nd.relic) p.push(nd.relic===1?'a relic':relicName(nd.relic));
  if(nd.mod) p.push('a refit in the hold'); if(nd.cred) p.push(nd.cred+' credits'); if(nd.vet) p.push('a '+RANKS[nd.vet]+' or better'); if(nd.flag) p.push('an earlier choice'); if(nd.intel) p.push(nd.intel+' Nemesis weakness'+(nd.intel>1?'es':'')+' known');
  return 'Needs '+p.join(', '); }
// the next event at an event node: never one already seen this run (B4), never one barred for your faction; a quiet stretch once all are seen
function nextEvent(){ RUN.seenEvents=RUN.seenEvents||[]; const fits=e=>!(e.not&&e.not.includes(RUN.fac))&&e.id!==EVENT_FALLBACK;
  const pool=EVENTS.filter(e=>fits(e)&&!RUN.seenEvents.includes(e.id)); const ev=pool.length?pick(pool):EVENTS.find(e=>e.id===EVENT_FALLBACK); RUN.seenEvents.push(ev.id); return ev; }
function eventOptOk(o){ const cost=o.r&&o.r.cost; return (!cost||RUN.credits>=cost)&&needMet(o.need); }
function eventScreen(n){
  const ev=nextEvent(); curEvent=Object.assign({},ev,(ev.v&&ev.v[RUN.fac])||{}); /* each faction tells it in its own words */
  mapScreen();
  modal(`<h2>${esc(curEvent.t)}</h2><p>${esc(curEvent.b)}</p>${curEvent.o.map((o,i)=>{ const cost=o.r&&o.r.cost, ok=eventOptOk(o), blue=!!o.need;
    return `<button class="choice" ${ok?'':'disabled'} ${blue?'style="border-color:#62a8ff;color:#9fcbff"':''} data-act="eventChoice" data-arg="${i}"><b>${esc(o.l)}</b><small>${blue?`<span style="color:#62a8ff">[${esc(needText(o.need))}]</span> `:''}${esc(o.s)}${cost&&RUN.credits<cost?' (not enough credits)':''}</small></button>`; }).join('')}`);
}
// B4: every event choice writes a flag later systems read (faction verbs, the Nemesis): RUN.flags[event id] = the option's key, plus any counters
function eventFlags(ev,o,i){ RUN.flags=RUN.flags||{}; RUN.flags[ev.id]=o.k||String(i); for(const [k,v] of Object.entries(o.fl||{})) RUN.flags[k]=(RUN.flags[k]||0)+v; }
// ---------- B4 the Nemesis (campaign rules; battle.js applyNemesis applies his weaknesses and adaptations in the fight) ----------
// He commands a rival faction that is not your own (the first of the two sector-outsiders, RUN.foes[3]). One meeting per sector: when the
// clock fills, or at the latest at the fight before the rest stop. Beaten in sectors 1 and 2 he escapes; in sector 3 his flagship's death ends him.
// R42 (Oct 26): a fresh identity every run from the faction's own pools (never a CAPTAINS or ADMIRALS name), a personality, two strength
// traits, a portrait id (nem_<faction>_1..6) with scar overlays, and faction behaviour (NEM_FAC[fac].beh) on the map and in battle.
function nemName(fac){ const F=NEM_FAC[fac]; for(let k=0;k<12;k++){ const a=pick(F.pre), b=pick(F.post), n=/^[a-z]/.test(b)?a+b:a+' '+b; if(!Object.values(ADMIRALS).some(x=>x.n.includes(n))) return n; } return pick(F.pre)+' '+pick(F.post); }
function newNemesis(){ const fac=(RUN.foes&&RUN.foes[3])||pick(RUN_FACTIONS.filter(f=>f!==RUN.fac)), F=NEM_FAC[fac];
  const beh=F.beh, name=nemName(fac), title=pick(F.titles), persona=pick(F.personas), traits=shuffle(F.traits.slice()).slice(0,2), portrait='nem_'+fac+'_'+(1+Math.floor(rnd()*6));
  const clash={slow:'swift',board:'boarders',ion:'shielded'}, weakPool=Object.keys(NEM_WEAK).filter(k=>!(k==='anchor'&&(beh.noFlee||beh.revive))&&!traits.includes(clash[k])); // zealots and the Deathless never break; no strength and weakness that cancel out
  return {fac,name,g:nemGender(fac,name),title,persona,traits,portrait,
    weak:shuffle(weakPool).slice(0,2),revealed:[],adapt:[],clock:0,met:0,beaten:0,scars:0,scarKinds:[],epithets:[],epithet:null,last_beat:null,fed:0,riches:0,loot:0,held:null,gloat:null,honed:0,revived:false,dead:false,strike:false,seen:{},signatures:[]}; }
function ensureNemesis(){ if(RUN&&RUN.fleet&&(!RUN.nem||!RUN.nem.persona)){ const old=RUN.nem; RUN.nem=newNemesis(); if(old){ for(const k of ['weak','revealed','adapt','clock','met','beaten','scars','dead','strike','seen']) if(old[k]!=null) RUN.nem[k]=old[k]; if(old.beat) RUN.nem.last_beat=old.beat; RUN.nem.adapt=RUN.nem.adapt.filter(a=>NEM_ADAPT[a]); } }
  const N=RUN&&RUN.nem; if(N&&N.persona){ // older R42 saves: story-helper field names (last_beat, g, scarKinds)
    if(N.beat&&!N.last_beat){ N.last_beat=N.beat==='ion'?'battery':N.beat; } delete N.beat;
    if(!N.g) N.g=nemGender(N.fac,N.name||''); delete N.pronoun;
    if(N.scarList&&!N.scarKinds){ N.scarKinds=N.scarList.filter(x=>!x.startsWith('ep:')); N.epithets=N.scarList.filter(x=>x.startsWith('ep:')).map(x=>x.slice(3)); } delete N.scarList;
    N.scarKinds=N.scarKinds||[]; N.epithets=N.epithets||(N.epithet?[N.epithet]:[]); N.signatures=N.signatures||[]; }
  return N; } // B4 saves get an R42 identity
// R42 gender for the story layer's pronouns: 'n' (it) for the Chorus, 'f' when his first name part is a feminine one, else 'm'. No random draw.
function nemGender(fac,name){ const F=NEM_FAC[fac]||{}; if(F.g) return F.g; return (F.fem||[]).some(p=>name.startsWith(p))?'f':'m'; }
function nemPr(N){ const g=N&&N.g; return g==='n'?{he:'it',He:'It',his:'its',His:'Its',him:'it'}:g==='f'?{he:'she',He:'She',his:'her',His:'Her',him:'her'}:{he:'he',He:'He',his:'his',His:'His',him:'him'}; }
function nemSay(t,N){ const g=N&&N.g; if(!t||g==='m'||!g) return t; const P=nemPr(N); return t.replace(/\b(he|his|him|He|His)\b/g,w=>({he:P.he,his:P.his,him:P.him,He:P.He,His:P.His})[w]); }
function nemFull(){ const N=RUN&&RUN.nem; return N?`${N.title} ${N.name}${N.epithet?' '+N.epithet:''}`:''; }
function nemReveal(){ const N=ensureNemesis(); if(!N) return null; const w=N.weak.find(x=>!N.revealed.includes(x)); if(w) N.revealed.push(w); return w||null; }
// R42: his faction behaviour firing (raid, tithe, flee, revive, feed, fast_adapt, reinforce, duel, challenge) is logged as a 'nem_signature' event
function nemSignature(kind){ const N=RUN&&RUN.nem; if(!N) return; (N.signatures=N.signatures||[]).push(kind); if(N.signatures.length>40) N.signatures.shift(); try{ tel('nem_signature',{fac:N.fac,kind,sector:RUN.sector}); }catch(e){} }
function nemWarnLine(N){ const s=nemBeh().strike; if(N.strike||N.met>=RUN.sector||N.clock+(nemBeh().clock||1)<NEM_CLOCK) return '';
  if(s==='raid'){ const crip=RUN.fleet.length>=3&&RUN.fleet.some(x=>x.uid!==RUN.flagUid&&x.hp<derive(x).maxHp*.25); return `<p class="blood" style="font-size:13px;margin:2px 0 0">${esc(nemSay('Your next win fills his clock: he will raid',N))} ${RUN.credits>=30?Math.round(RUN.credits*.25)+' credits':crip?'your most damaged ship (repair it above 25% hull, or keep 30 credits, to stop it)':'and find nothing to take'}.</p>`; }
  if(s==='tithe') return `<p class="blood" style="font-size:13px;margin:2px 0 0">Your next win fills the clock: every ship will lose 6% of its hull (never below 1).</p>`;
  return `<p class="blood" style="font-size:13px;margin:2px 0 0">${esc(nemSay('Your next win fills the clock: your next fight will be his.',N))}</p>`; }
function nemBeh(){ const N=RUN&&RUN.nem; return (N&&NEM_FAC[N.fac]&&NEM_FAC[N.fac].beh)||{}; }
// the clock: returns a line to show when it fills (the next fight becomes his); his faction sets the pace (Deathless patient, Voidsworn zealous)
function nemClockAdd(n){ const N=ensureNemesis(); if(!N||N.dead) return ''; const step=n>0?n*(nemBeh().clock||1):n; N.clock=clamp(Math.round((N.clock+step)*2)/2,0,NEM_CLOCK);
  if(N.clock>=NEM_CLOCK&&N.met<RUN.sector&&!N.strike){ N.strike=true; const extra=nemStrike(); return `${nemFull()} has found your trail. Your next fight will be against his fleet.${extra?' '+extra:''}`; } return ''; }
// what a full clock does on the map, by faction (always written on his card beforehand)
function nemStrike(){ const N=RUN.nem, s=nemBeh().strike;
  if(s==='raid'||s==='tithe') nemSignature(s);
  if(s==='raid'){ if(RUN.credits>=30){ const c=Math.round(RUN.credits*.25); RUN.credits-=c; N.loot=(N.loot||0)+c; return `His raiders hit your supply line: -${c} credits. He holds them; kill him to take them back.`; }
    const cand=RUN.fleet.length>=3?RUN.fleet.filter(x=>x.uid!==RUN.flagUid&&x.hp<derive(x).maxHp*.25).sort((a,b)=>a.hp-b.hp)[0]:null; if(cand&&!N.held){ RUN.fleet=RUN.fleet.filter(x=>x!==cand); N.held=cand; N.riches++; return `With your coffers empty, his raiders cut out the crippled ${cand.name} and tow her away. Kill him and you take her back.`; } return 'His raiders find nothing worth taking.'; }
  if(s==='tithe'){ RUN.fleet.forEach(x=>{ x.hp=Math.max(1,x.hp-Math.round(derive(x).maxHp*.06)); }); return 'The hunt wears on your fleet: every ship loses 6% of its hull.'; }
  return ''; }
// is this battle node his? (strike pending, or the last fight before the rest stop when he has not been met this sector)
function nemNodeIs(n){ const N=RUN&&RUN.nem; if(!N||N.dead||N.met>=RUN.sector||!n||(n.type!=='battle'&&n.type!=='elite')) return false; return N.strike||n.col>=(RUN.map.cols.length-3); }
function nemBattleCfg(){ const N=ensureNemesis(); return {gloat:N.gloat||null,honed:N.honed||0,beaten:N.beaten||0,name:nemFull().replace(N.title+' ',''),title:N.title,fac:N.fac,persona:N.persona,traits:N.traits.slice(),weak:N.weak.slice(),revealed:N.revealed.slice(),adapt:N.adapt.slice(),scars:N.scars,fed:N.fed,riches:N.riches,last_beat:N.last_beat,g:N.g,met:N.beaten+N.scars>0}; }
// adaptation: once per sector (Chorus also after every meeting), read from how you fought (RUN.nem.seen); his faction names it, and when nothing
// stood out he takes his faction's own special adaptation
function nemAdapt(force){ const N=RUN&&RUN.nem; if(!N||N.dead) return null; const fast=nemBeh().adaptFast, cap=Math.max(0,RUN.sector-1)+(fast?N.beaten+N.scars:0);
  if(N.adapt.length>=Math.min(cap,6)&&!force) return null; const s=N.seen||{}, sp=NEM_ADAPT_FAC[N.fac]&&NEM_ADAPT_FAC[N.fac].special;
  const score={shields:(s.lance||0)*2+(s.ion||0)*2,pd:(s.torp||0)*2+(s.sq||0),armor:(s.ram||0)*4+(s.board||0)*4,evasion:(s.battery||0)+(s.broad||0),aim:(s.evaded||0)*3};
  let pickA=Object.keys(score).filter(k=>!N.adapt.includes(k)&&score[k]>0).sort((a,b)=>score[b]-score[a])[0];
  if(!pickA&&sp&&!N.adapt.includes(sp.id)) pickA=sp.id; if(!pickA) pickA=Object.keys(score).filter(k=>!N.adapt.includes(k))[0]; if(!pickA) return null; N.adapt.push(pickA); N.seen={}; return pickA; }
function nemAdaptName(a,fac){ const T=NEM_ADAPT_FAC[fac]||{}; if(T.special&&T.special.id===a) return T.special.n; return T[a]||(NEM_ADAPT[a]&&NEM_ADAPT[a].n)||a; }
function nemAdaptDesc(a,fac){ const T=NEM_ADAPT_FAC[fac]||{}; if(T.special&&T.special.id===a) return T.special.d; return (NEM_ADAPT[a]&&NEM_ADAPT[a].d)||''; }
function nemAdaptWhy(a,fac){ const T=NEM_ADAPT_FAC[fac]||{}; if(T.special&&T.special.id===a) return 'his own way of war'; return (NEM_ADAPT[a]&&NEM_ADAPT[a].why)||''; }
// each survival adds a scar (a portrait overlay keyed by how he was hurt) and a new epithet
function nemScar(cause){ const N=RUN.nem, F=NEM_FAC[N.fac]; N.scars++; N.scarKinds=N.scarKinds||[]; N.epithets=N.epithets||[]; N.scarKinds.push(cause||'blast'); const tag=cause==='fled'?'fled':['melt','flay','tidal'].includes(cause)?'burn':'wound', byC=((F.scarBy||{})[tag]||[]).filter(x=>!N.epithets.includes(x)), left=byC.length?byC:F.scars.filter(x=>!N.epithets.includes(x)); if(left.length){ N.epithet=pick(left); N.epithets.push(N.epithet); } } // scarKinds: how each scar was made (fled, big, cut, flay, melt, dark, blast, tidal), for the portrait overlays
// after his battle: returns plain lines for the reward summary. fled = he withdrew (Corsair, Ithar); flagDead = his flagship was destroyed
function nemAfterBattle(result,flagDead,o){ const N=RUN.nem; if(!N) return []; o=o||{}; const out=[], beh=nemBeh(), P=nemPr(N), say=t=>nemSay(t,N); N.met=RUN.sector; N.strike=false; N.clock=0; let back=false;
  if(result==='win'){ N.beaten++; N.gloat=null; if(o.beat){ N.last_beat=o.beat; nemBeatTeach(o.beat); } const w=nemReveal(); if(w) out.push(say(`His captured logs reveal a weakness: ${NEM_WEAK[w].n}.`));
    if(o.fled){ if(beh.strike==='raid') N.riches++; if(beh.strike==='duel') N.honed=(N.honed||0)+1; nemScar('fled'); nemSignature('flee'); out.push(say(`${nemFull()} breaks off and runs before you can finish him.${beh.strike==='raid'?' He will come back richer.':beh.strike==='duel'?' He will be back with the same few ships, honed sharper.':' He will be back.'}`)); }
    else if(flagDead&&RUN.sector>=3&&beh.revive&&!N.revived){ N.revived=true; back=true; nemScar(o.cause||'big'); nemSignature('revive'); N.met=RUN.sector-1; out.push(say(`${nemFull()}'s flagship is destroyed, and then the wreck begins to move. He is reassembling for one last fight.`)); }
    else if(flagDead&&RUN.sector>=3){ N.dead=true; out.push(say(`${nemFull()} is dead. The feud is over.`)); }
    else if(flagDead){ nemScar(o.cause||'big'); out.push(say(`${nemFull()}'s flagship breaks apart, but he escapes, scarred and furious. He will be back.`)); } // R49: before the last sector every rival, the Deathless one too, withdraws like this
    else out.push(say(`${nemFull()} withdraws to fight another day.`));
    // R49 fairness: what a Corsair raid took (credits and a towed ship) comes back when he dies
    if(N.dead&&N.loot){ RUN.credits+=N.loot; out.push(`You take back ${N.loot} credits from his hold.`); N.loot=0; }
    if(N.dead&&N.held){ RUN.fleet.push(N.held); out.push(`You take back the ${N.held.name}.`); N.held=null; }
    if(RUN.sector>=3&&!back){ const u=arcComplete(RUN.fac); if(u) out.push(u); } } // R41: the last meeting won (dead, fled or withdrawn) ends the arc
  else { N.clock=1; N.gloat=o.myFlagDead?'flagship':result==='retreat'?'retreat':'loss'; out.push(say(`${nemFull()} drove you off. He will remember this.`)); }
  if(beh.adaptFast){ const a=nemAdapt(); if(a){ nemSignature('fast_adapt'); out.push(`${P.He} learns from it at once: ${nemAdaptName(a,N.fac)} (${say(nemAdaptWhy(a,N.fac))}).`); } }
  return out; }
// R42: when you beat him with something, his next adaptation counters it (so "it will not work twice" is true when he says it)
const NEM_BEAT_SEEN={lance:'lance',torp:'torp',sq:'sq',ram:'ram',board:'board',battery:'battery',evasive:'evaded'};
function nemBeatTeach(beat){ const N=RUN.nem, k=NEM_BEAT_SEEN[beat]; if(!N||!k) return; N.seen=N.seen||{}; N.seen[k]=(N.seen[k]||0)+8; }
// weaknesses you found in battle by triggering them (B.nemFound) are known from then on
function nemFoundMerge(list){ const N=RUN&&RUN.nem; if(!N||!list||!list.length) return []; const out=[]; for(const k of list) if(N.weak.includes(k)&&!N.revealed.includes(k)){ N.revealed.push(k); out.push(k); } return out; }
// the Chorus Nemesis grows from every ship you lose, anywhere
function nemFeedLosses(n){ const N=RUN&&RUN.nem; if(!N||N.dead||!n||!nemBeh().feeds) return ''; const f0=N.fed||0; N.fed=Math.min(8,f0+n); if(N.fed===f0) return ''; nemSignature('feed');
  return `${nemFull()} feeds on your losses: ${nemPr(N).his} fleet is now ${Math.round(Math.min(.32,.04*N.fed)*100)}% tougher (fed ${N.fed} of 8).`; }
// R41: finishing a faction's story arc (its Nemesis's last fight, beat 3) unlocks that faction's arc hull variant for every later run
function arcComplete(fac){ const id=ARC_VARIANT[fac]; if(!id) return ''; META.variants=META.variants||{}; if(META.variants[id]) return ''; META.variants[id]=true; try{ tel('arc_unlock',{fac,id}); Persist.save({meta:true}); }catch(e){} return `Story complete: the ${HULL_VARIANTS[id].n} is now sold in your shipyards.`; }
// the way you beat him last time, from that battle's usage (what he remembers and says)
function nemBeatOf(usage,evasive){ if(!usage) return null; const k=usage.kind||{}, c={lance:k.lance||0,torp:(k.torp||0)*2,sq:k.sq||0,battery:k.battery||0,ram:(usage.ram||0)*3,board:(usage.board||0)*3,evasive:evasive?8:0}; const top=Object.keys(c).sort((a,b)=>c[b]-c[a])[0]; return c[top]>0?top:null; } // ids match the story helper's last_beat: lance, torp, sq, ram, board, battery, evasive
// what a finished battle teaches him (counted into RUN.nem.seen; read at the next sector)
function nemLearn(usage,evadedShare){ const N=RUN&&RUN.nem; if(!N||!usage) return; const s=N.seen=N.seen||{}; const k=usage.kind||{};
  for(const x of ['lance','torp','battery']) s[x]=(s[x]||0)+(k[x]||0); s.ion=(s.ion||0)+(usage.ion||0); s.sq=(s.sq||0)+(k.sq||0); s.ram=(s.ram||0)+(usage.ram||0); s.board=(s.board||0)+(usage.board||0);
  s.broad=(s.broad||0)+((usage.fire&&((usage.fire['Port broadside']||0)+(usage.fire['Starboard broadside']||0)))||0); s.evaded=(s.evaded||0)+(evadedShare||0); }
// ---------- B4 faction campaign verbs ----------
function verbFor(){ return RUN&&FAC_VERBS[RUN.fac]||null; }
function verbFree(V){ return !!(V&&V.free&&RUN.flags&&RUN.flags[V.free]!=null); }
function verbCanUse(){ const V=verbFor(); if(!V||(RUN.verbUsed||0)>=RUN.sector) return false; if(verbFree(V)) return true; const c=V.cost||{};
  if(c.cred&&RUN.credits<c.cred) return false; if(c.mod&&!RUN.inventory.length) return false; if(c.xp){ const f=flagshipOf()||RUN.fleet[0]; if(!f||f.cap.xp<c.xp) return false; } return true; }
function verbCostText(V){ if(verbFree(V)) return 'Free ('+V.freeD+')'; const c=V.cost||{}, p=[]; if(c.cred) p.push(c.cred+' credits'); if(c.mod) p.push('a refit from the hold'); if(c.xp) p.push(c.xp+' experience from your flagship captain'); return p.length?'Costs '+p.join(', '):'No cost'; }
// apply the verb now; next-battle verbs wait in RUN.verbNext until battleScreen hands them to the fight
function useVerb(){ const V=verbFor(); if(!verbCanUse()) return null; const free=verbFree(V), c=V.cost||{}, out=[];
  if(!free){ if(c.cred) RUN.credits-=c.cred; if(c.mod) out.push(`The ${modName(RUN.inventory.splice(0,1)[0])} is consumed.`); if(c.xp){ const f=flagshipOf()||RUN.fleet[0]; f.cap.xp=Math.max(RANK_XP[f.cap.rank]||0,f.cap.xp-c.xp); } }
  RUN.verbUsed=RUN.sector; RUN.flags=RUN.flags||{}; RUN.flags['verb_'+V.id]=(RUN.flags['verb_'+V.id]||0)+1;
  if(V.next){ RUN.verbNext=V.id; out.push(`${V.n}: ${V.d}`); }
  if(V.id==='shake'){ const g=30+10*((RUN.flags&&RUN.flags.greed)||0); RUN.credits+=g; out.push(`+${g} credits.`); const m=nemClockAdd(1); if(m) out.push(m); RUN.flags.greed=(RUN.flags.greed||0)+1; }
  if(V.id==='gorge'){ const f=RUN.flags&&RUN.flags.spawn==='feed'?.3:.2; RUN.fleet.forEach(s=>{ const d=derive(s); s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*f)); }); out.push(`Every ship regrows ${pct(f)} of its hull.`); }
  return out; }
// ---------- B4 wing veterancy (kept on the carrier ship between battles) ----------
function wingPerkGrant(ship,id){ const v=ship.wingVet=ship.wingVet||{kills:0,perks:[]}; if(v.perks.length>=3) return null; const pool=Object.keys(WING_PERKS).filter(k=>!v.perks.includes(k)); const got=id&&pool.includes(id)?id:pick(pool); v.perks.push(got); return got; }
// wing kills earn perks at WING_XP thresholds; returns the perks gained
function wingVetAfter(ship,kills){ const v=ship.wingVet=ship.wingVet||{kills:0,perks:[]}; v.kills+=kills; const out=[]; while(v.perks.length<3&&v.kills>=WING_XP[v.perks.length]){ const g=wingPerkGrant(ship); if(!g) break; out.push(g); } return out; }
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
  if(r.healAll){ RUN.fleet.forEach(s=>{ const d=derive(s); s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*r.healAll)); }); out.push(r.healAll>=1?'Every ship is fully repaired.':`Every ship repairs ${pct(r.healAll)} of its hull.`); }
  if(r.gamble){ if(rnd()<.5){ RUN.fleet.forEach(s=>{ const d=derive(s); s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*.3)); }); out.push('The saint answers. Every ship repairs 30% of its hull.'); } else out.push('Silence. The void keeps its own counsel.'); }
  if(r.mod){ const m=randomModule(); RUN.inventory.push(m); out.push(`Found: ${modName(m)}. It\u2019s in the hold.`); }
  if(r.ambush){ RUN.ambush=true; }
  // B4 outcome kinds: more currencies and the Nemesis
  if(r.payMod){ if(RUN.inventory.length){ const m=RUN.inventory.splice(0,1)[0]; out.push(`The ${modName(m)} from the hold is used up.`); } }
  if(r.payXp){ const f=flagshipOf()||RUN.fleet[0]; if(f){ f.cap.xp=Math.max(RANK_XP[f.cap.rank]||0,f.cap.xp-r.payXp); out.push(`${f.cap.name} loses ${r.payXp} experience.`); } }
  if(r.payRelic){ if(RUN.relics.length){ const rl=RUN.relics.splice(RUN.relics.length-1,1)[0]; changeFleet(()=>{}); out.push(`You give up ${relicName(rl)}.`); } }
  if(r.repairOne){ const s=[...RUN.fleet].sort((a,b)=>(a.hp/derive(a).maxHp)-(b.hp/derive(b).maxHp))[r.upgradeOne&&RUN.fleet.length>1?1:0]; if(s){ s.hp=derive(s).maxHp; out.push(`The ${s.name} is fully repaired.`); } }
  if(r.dmgBig){ const s=[...RUN.fleet].sort((a,b)=>(HULLS[b.tpl].cp||1)-(HULLS[a.tpl].cp||1))[0]; if(s){ const dm=Math.round(derive(s).maxHp*r.dmgBig); s.hp=Math.max(1,s.hp-dm); out.push(`The ${s.name} takes ${dm} hull damage.`); } }
  if(r.xpTop){ const s=[...RUN.fleet].sort((a,b)=>b.cap.xp-a.cap.xp)[0]; if(s){ addXp(s,r.xpTop); out.push(`${s.cap.name} of the ${s.name} gains ${r.xpTop} experience.`); } }
  if(r.modId&&MODULES[r.modId]){ RUN.inventory.push(r.modId); out.push(`Found: ${modName(r.modId)}. It’s in the hold.`); }
  if(r.shipRaw&&HULLS[r.shipRaw]){ if(fleetCP()+(HULLS[r.shipRaw].cp||1)<=RUN.cpCap){ const s=newShip(r.shipRaw,r.vet); RUN.fleet.push(s); out.push(`The ${s.name} joins the fleet under ${rankName(s.cap)} ${s.cap.name}.`); } else { RUN.credits+=40; out.push('No command points to crew her. You sell the berth for 40 credits.'); } }
  if(r.wingPerk){ const c=[...RUN.fleet].filter(s=>HULLS[s.tpl].hangar).sort((a,b)=>(HULLS[b.tpl].cp||1)-(HULLS[a.tpl].cp||1))[0]; if(c){ const got=wingPerkGrant(c); out.push(got?`The ${c.name}’s wings gain a veteran perk: ${WING_PERKS[got].n}.`:`The ${c.name}’s wings already hold every perk they can.`); } }
  if(r.nemIntel){ const w=nemReveal(); out.push(w?`Nemesis weakness revealed: ${NEM_WEAK[w].n}. ${NEM_WEAK[w].d}`:'You learn nothing new about the enemy commander.'); }
  if(r.nemClock){ const m=nemClockAdd(r.nemClock); if(m) out.push(m); }
  if(!out.length && !r.fight) out.push('You move on.');
  return out;
}
ACT.eventChoice=i=>{
  const o=curEvent.o[+i]; if(!o||!eventOptOk(o)) return; eventFlags(curEvent,o,+i);
  if(o.r&&o.r.fight){ closeModal(); battleScreen({kind:'elite',fac:o.r.fight,col:findNode(RUN.curNode).col+1,node:RUN.curNode,eventRelic:true}); return; }
  const lines=applyOutcome(o.r);
  completeNode(); mapScreen();
  modal(`<h2>${esc(curEvent.t)}</h2>${lines.map(l=>`<p>${esc(l)}</p>`).join('')}<button class="primary" data-act="closeModal">Continue</button>`);
};

// ---------- rewards ----------
// B1 onboarding fix 4: one plain line on each reward screen saying what the reward is
const REWARD_DEF={salvage:'Salvage: work one wreck from this fight. Strip it for a refit, scrap it for credits, or (Corsairs) tow a small hull home.',
  boon:'A boon is a bonus from a patron that lasts for the rest of this run. Rarity sets how strong it is.',
  refit:'A refit is a module you fit to one ship for a lasting upgrade. It waits in the hold until you fit it.',
  relic:'A relic is a fleet-wide effect that lasts for the rest of this run.',
  promotion:'A promotion lets a captain with enough experience pick a perk. Perks stay with the captain, even on a new ship.'};
function rewardDef(k){ return REWARD_DEF[k]?`<p class="dim rdef" style="font-size:13.5px;margin:2px 0 10px">${REWARD_DEF[k]}</p>`:''; }
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
  window._wrecks=(summary.wrecks||[]).map(w=>Object.assign(w,{yield:salvageYield(w)}));
  // B1 (reload during rewards): the node completes the moment the rewards are banked, and the picks still to make (with their offers fixed) ride in the save.
  // A reload then resumes the chain (resumeReward) instead of losing the boon, refit or relic, or replaying the node for double pay.
  const prizes=(summary.prizes||[]).filter(p=>p&&HULLS[p.tpl]);
  RUN.reward={kind:cfg.kind,node:cfg.node||null,rw,relics:window._relicChoice,wrecks:window._wrecks,prizes,stage:prizes.length?'prize':window._wrecks.length?'salvage':'pick',boonOffer:null,modOffer:null}; completeNode();
  const next=RUN.reward.prizes.length?`<button class="primary" data-act="prizeStep">Decide on the prize ship${RUN.reward.prizes.length>1?'s':''}</button>`:window._wrecks.length?'<button class="primary" data-act="salvageStep">Salvage the field</button>':rw.k==='boon'&&PATRONS[rw.p]?`<button class="primary" data-act="rewardNext" style="background:${PATRONS[rw.p].col};border-color:${PATRONS[rw.p].col};color:#0f1626">${esc(PATRONS[rw.p].short)} offers a boon</button>`:rw.k==='mod'?'<button class="primary" data-act="rewardNext">Choose a refit</button>':'<button class="primary" data-act="rewardNext">Continue</button>';
  modal(`<h2>${cfg.kind==='boss'?'Flagship destroyed':'Victory'}</h2>
    <p class="num">${summary.kills} enemy ship${summary.kills===1?'':'s'} destroyed in ${summary.rounds} round${summary.rounds===1?'':'s'}. <span class="gilt">+${credits} credits.</span></p>${lost}${extra}
    ${(()=>{ const st=summary.boonStats||{}, ks=Object.keys(st).filter(k=>BOONS[k]); return ks.length?`<p style="font-size:14px;margin:6px 0">Boons in action: ${ks.map(k=>{ const b=BOONS[k], P=b.p?PATRONS[b.p]:PATRONS[b.duo[0]]; return `<span style="color:${P.col}">${esc(b.n)}</span> \u00d7${st[k]}`; }).join(', ')}.</p>`:(RUN.boons||[]).length?'<p class="dim" style="font-size:13.5px">No boon triggered this battle. Check the Fleet boons section on a ship to see what sets each one off.</p>':''; })()}
    ${flagMoved?`<p class="gilt">The admiral transfers the flag to the ${esc(flagMoved.name)}. Its aspect goes with it.</p>`:''}
    ${xpLines?`<ul class="num" style="padding-left:18px">${xpLines}</ul>`:''}${next}`);
}
// v52 salvage: pick one wreck from the ships you actually destroyed. What it yields depends on what it carried; Corsairs can tow small hulls home as prizes.
const CAUSE_WORD=Object.fromEntries(Object.entries(KILL_CAUSES).map(([k,c])=>[k,c.w])); // v53: words come from the shared KILL_CAUSES list (battle.js)
function salvageYield(w){ const pool=modulePool(), has=m=>pool.includes(m)&&MODULES[m], wk=w.wk||[];
  const pickM=[wk.includes('lance')&&'crystal',(wk.includes('torp')||wk.includes('htorp')||wk.includes('startorp'))&&'magazine',(wk.includes('battery')||wk.includes('hbattery'))&&'loaders',wk.includes('flak')&&'flakplus',w.ab==='launch'&&'hangar',(wk.includes('gauss')||wk.includes('needle')||wk.includes('shard'))&&'cogitator',w.regen&&'damcon',w.sh>=20&&'capacitor',(wk.includes('turret')||wk.includes('autocannon'))&&'auspex'].filter(Boolean).filter(has);
  // a wreck that was flayed or dissolved has little left to strip
  const intact=!(KILL_CAUSES[w.cause]&&KILL_CAUSES[w.cause].scrap), m=intact&&pickM.length?pickM[0]:null, cred=Math.round((10+9*w.cp)*(intact?1:1.3));
  const tow=RUN&&RUN.fac==='corsair'&&w.cp<=2&&intact&&w.cause!=='dark'&&!!HULLS[w.tpl]&&!factionGate(RUN.fac,w.tpl)&&fleetCP()+(HULLS[w.tpl].cp||1)<=RUN.cpCap?true:false; // B1 (B-8): only offered when the command points are there
  return {mod:m,cred,tow}; }
// B2 capture rework (R4): each prize ship that survives a win gets one choice. Add it (only if command points allow), strip it for a refit
// plus scrap (its weapons decide which refit, as in salvage), or ransom it for credits. A prize that cannot fit at all was already scrapped
// at the end of the battle (campaign3d.js). Values: ship value = shop price (or 40 per command point for hulls with no price, shipValue);
// ransom = 55% of that, scaled 60 to 100% by the hull left, and 15% less for each ransom already taken this run (never below 40%: owners
// learn; outside review, Oct 25); strip = the refit plus 15%; scrap (full fleet) = 35%. No upkeep for kept prizes (Ryan, R23).
// R23 (Oct 25): ONE screen for every prize of the battle, values side by side, a default per prize, one confirm. Only the player's own
// picks are saved (RUN.reward.prizeSel), so a reload shows the same screen with the same picks; defaults are worked out fresh each time.
function prizeRansom(p,n){ return Math.round(shipValue(p.tpl)*.55*(.6+.4*(p.hpf||1))*Math.max(.4,Math.pow(.85,n||0))); }
function prizeOffer(p,nR){ const v=shipValue(p.tpl), y=salvageYield({wk:p.wk||[],ab:p.ab,regen:p.regen,sh:p.sh,cp:p.cp,tpl:p.tpl,cause:'board'});
  const pool=modulePool(), mod=y.mod||(pool.length?pool[Math.floor((v*7+(p.cp||1)*13)%pool.length)]:null);
  return {fits:fleetCP()+(p.cp||1)<=RUN.cpCap,ransom:prizeRansom(p,nR==null?RUN.ransoms:nR),strip:{mod,cred:Math.round(v*.15)}}; }
// Walks the prizes in battle order: an Add only counts if the command points left after the earlier Adds still hold it, and each Ransom
// lowers the next one. Default: Add a ship that fits with at least 40% hull, otherwise whichever of Strip or Ransom is worth more (a refit
// counted at half its shop price).
function prizePlan(R){ const sel=R.prizeSel||[]; let cp=fleetCP(), nR=RUN.ransoms||0;
  return R.prizes.map((p,i)=>{ const o=prizeOffer(p,nR), c=p.cp||1, gate=factionGate(RUN.fac,p.tpl), room=cp+c<=RUN.cpCap&&!gate; // B3: a prize your faction cannot field (Corsairs and lances) can only be stripped or ransomed
    const sv=o.strip.cred+(o.strip.mod?Math.round(MODULES[o.strip.mod].cost*.5):0), dk=room&&(p.hpf||1)>=.4?'add':sv>=o.ransom?'strip':'ransom';
    let k=sel[i]||dk; if(k==='add'&&!room) k=dk==='add'?(sv>=o.ransom?'strip':'ransom'):dk;
    if(k==='add') cp+=c; if(k==='ransom') nR++; return {p,o,room,gate,k,mine:!!sel[i]&&sel[i]===k}; }); }
ACT.prizeStep=()=>{ closeModal(); const R=RUN.reward; if(!R||!(R.prizes||[]).length){ if(R) R.stage=(window._wrecks||[]).length?'salvage':'pick'; return (window._wrecks||[]).length?ACT.salvageStep():ACT.rewardNext(); }
  const rows=prizePlan(R), n=rows.length, cpAfter=fleetCP()+rows.reduce((t,r)=>t+(r.k==='add'?(r.p.cp||1):0),0);
  const cred=rows.reduce((t,r)=>t+(r.k==='ransom'?r.o.ransom:r.k==='strip'?r.o.strip.cred:0),0), refits=rows.filter(r=>r.k==='strip'&&r.o.strip.mod).length, joins=rows.filter(r=>r.k==='add').length;
  const sum=[joins?`${joins} ship${joins>1?'s':''} join${joins>1?'':'s'}`:'',refits?`${refits} refit${refits>1?'s':''} for the hold`:'',cred?`+${cred} credits`:''].filter(Boolean).join(', ')||'Nothing';
  modal(`<h2>Prize ship${n>1?'s':''}</h2><p class="dim rdef" style="font-size:13.5px;margin:2px 0 10px">Your boarders took ${n>1?`${n} enemy ships`:'an enemy ship'}. Keep, strip or sell back each one, then confirm once.</p>
    <p class="muted">Command points: ${fleetCP()} of ${RUN.cpCap} used${joins?`, ${cpAfter} after these join`:''}.${RUN.ransoms||rows.some(r=>r.k==='ransom')?' Owners pay less for each ship you sell back to them.':''}</p>
    ${rows.map((r,i)=>{ const H=HULLS[r.p.tpl], hp=Math.round((r.p.hpf||1)*100), b=(k,t,sm,dis)=>`<button class="${r.k===k?'sel':''}" data-act="prizeSet" data-arg="${i}:${k}" ${dis?'disabled':''}><b>${t}</b><small>${sm}</small></button>`;
      return `<div class="choice" style="cursor:default;margin:6px 0 12px"><b>${esc(r.p.name)}</b> <span class="dim">${esc(H.n)}, ${H.cp||1} command point${(H.cp||1)>1?'s':''}, ${hp}% hull</span>
      <div class="orders" style="grid-template-columns:1fr 1fr 1fr;margin-top:6px">${b('add','Add',r.room?`Joins at ${hp}% hull`:r.gate?'Your faction cannot field it':'No command points left',!r.room)}${b('strip','Strip',`${r.o.strip.mod?esc(modName(r.o.strip.mod))+' + ':''}${r.o.strip.cred} credits`)}${b('ransom','Ransom',`${r.o.ransom} credits`)}</div></div>`; }).join('')}
    <p class="muted" style="margin-top:10px">You get: ${sum}.</p><button class="primary" data-act="prizeConfirm">Confirm</button>`); };
ACT.prizeSet=a=>{ const R=RUN.reward; if(!R||!(R.prizes||[]).length) return; const [i,k]=String(a).split(':'); if(!R.prizes[+i]||!['add','strip','ransom'].includes(k)) return;
  R.prizeSel=R.prizeSel||[]; R.prizeSel[+i]=k; saveRun(); ACT.prizeStep(); };
ACT.prizeConfirm=()=>{ const R=RUN.reward; if(!R||!(R.prizes||[]).length) return ACT.prizeStep(); const rows=prizePlan(R), got=[];
  for(const r of rows){ const p=r.p, o=r.o;
    if(r.k==='add'){ const sh=newShip(p.tpl); sh.name=p.name; sh.hp=clamp(Math.round(derive(sh).maxHp*(p.hpf||1)),1,derive(sh).maxHp); RUN.fleet.push(sh); got.push(`the ${p.name} joins`); }
    else if(r.k==='strip'){ if(o.strip.mod) RUN.inventory.push(o.strip.mod); RUN.credits+=o.strip.cred; got.push(`the ${p.name} is stripped (+${o.strip.cred})`); }
    else { RUN.credits+=o.ransom; RUN.ransoms=(RUN.ransoms||0)+1; got.push(`the ${p.name} is ransomed (+${o.ransom})`); }
    try{ tel('prize_pick',{k:r.k,tpl:p.tpl,def:!r.mine}); }catch(e){} }
  R.prizes=[]; R.prizeSel=null; saveRun(); const t=got.join(', '); toast(t.charAt(0).toUpperCase()+t.slice(1)+'.'); ACT.prizeStep(); };
ACT.salvageStep=()=>{ closeModal(); const ws=window._wrecks||[];
  modal(`<h2>Salvage the field</h2><p class="muted">Your crews have time to work one wreck before the fleet moves on.</p>${rewardDef('salvage')}${ws.map((w,i)=>{ const y=w.yield, F=FACTIONS[w.fac];
    return `<div class="choice" style="cursor:default"><b>${esc(w.name)}</b> <span class="dim">${esc(w.cls||'')}${F?', '+esc(F.n):''}</span><small>${esc(CAUSE_WORD[w.cause]||'destroyed')}${w.by?` by the ${esc(w.by)}`:''}.</small>
      <div class="orders" style="margin-top:6px">${y.mod?`<button data-act="takeSalvage" data-arg="${i}:mod">Strip it: <b>${esc(modName(y.mod))}</b><small>${esc(MODULES[y.mod].d)}</small></button>`:''}<button data-act="takeSalvage" data-arg="${i}:cred">Scrap it<small>+${y.cred} credits</small></button>${y.tow?`<button data-act="takeSalvage" data-arg="${i}:tow">Tow it home<small>Joins your fleet at 35% hull</small></button>`:''}</div></div>`; }).join('')}`); };
ACT.takeSalvage=a=>{ const [i,k]=String(a).split(':'), w=(window._wrecks||[])[+i]; if(!w){ closeModal(); if(RUN.reward) RUN.reward.stage='pick'; return ACT.rewardNext(); } const y=w.yield;
  if(k==='mod'&&y.mod){ RUN.inventory.push(y.mod); toast(`${modName(y.mod)} stripped from the ${w.name} and stowed in the hold.`); }
  else if(k==='tow'&&y.tow&&HULLS[w.tpl]&&fleetCP()+(HULLS[w.tpl].cp||1)>RUN.cpCap){ RUN.credits+=y.cred; toast(`No command points to crew the ${w.name}. She is broken up for scrap: +${y.cred} credits.`); }
  else if(k==='tow'&&y.tow){ try{ const sh=newShip(w.tpl); sh.name=w.name; sh.hp=Math.max(1,Math.round(derive(sh).maxHp*.35)); RUN.fleet.push(sh); toast(`The ${w.name} is under tow. Patch her up at a shipyard.`); }catch(e){ RUN.credits+=y.cred; } }
  else { RUN.credits+=y.cred; toast(`The ${w.name} is broken up for scrap: +${y.cred} credits.`); }
  try{ tel('salvage_pick',{k,cause:w.cause,cls:w.cls,mod:y.mod||null}); }catch(e){} window._wrecks=[]; if(RUN.reward){ RUN.reward.wrecks=[]; RUN.reward.stage='pick'; } saveRun&&saveRun(); closeModal(); ACT.rewardNext(); };
ACT.rewardNext=()=>{ const rw=window._rw||{}; closeModal();
  if(rw.k==='boon') return boonStep(rw.p,rw.min||0);
  if(rw.k==='mod'){ const opts=(RUN.reward&&RUN.reward.modOffer)||shuffle(modulePool()).slice(0,3); window._modOffer=opts; if(RUN.reward&&!RUN.reward.modOffer){ RUN.reward.modOffer=opts; saveRun(); }
    modal(`<h2>Salvaged refits</h2>${rewardDef('refit')}<p>Take one. It goes in the hold; fit it at a shipyard or from the fleet screen.</p>${opts.map(m=>`<button class="choice" data-act="takeMod" data-arg="${m}"><b>${esc(modName(m))}</b><small>${esc(MODULES[m].d)}</small></button>`).join('')}`); return; }
  relicStep(); };
ACT.takeMod=m=>{ RUN.inventory.push(m); try{ tel('reward_pick',{k:'mod',id:m,offered:window._modOffer}); }catch(e){} toast(`${modName(m)} stowed in the hold.`); closeModal(); relicStep(); };
// a patron offers three boons; rarity shows how strong each one is
function boonStep(p,minR){ const P=PATRONS[p]; if(!P){ relicStep(); return; } const offer=(RUN.reward&&RUN.reward.boonOffer)||rollBoonOffer(p,minR); window._boonOffer=offer; if(RUN.reward&&!RUN.reward.boonOffer){ RUN.reward.boonOffer=offer; saveRun(); }
  if(!offer.length){ RUN.credits+=60; toast('Nothing left to offer. +60 credits.'); relicStep(); return; }
  modal(`<div class="boonhead" style="border-color:${P.col}"><span class="sigil" style="background:${P.col}">${P.glyph}</span><div><h2 style="margin:0;color:${P.col}">${esc(P.n)}</h2><div class="muted" style="font-size:14px">${esc(P.theme)}</div></div></div>
    <p class="muted" style="font-style:italic;margin:8px 0 12px">“${esc(P.quote)}”</p>${rewardDef('boon')}
    ${offer.map((o,i)=>{ const b=BOONS[o.id], R=RARITY[o.r||0], duo=b.duo; return `<button class="choice boon" data-act="takeBoon" data-arg="${i}" style="border-left:4px solid ${duo?PATRONS[duo[0]].col:P.col}">
      <span class="rar" style="color:${duo?'#ffd27a':R.col}">${duo?'Duo: '+duo.map(q=>esc(PATRONS[q].short)).join(' + '):R.n}</span><b>${esc(b.n)}</b><small>${esc(b.d(R.m))}</small></button>`; }).join('')}
    <div class="row" style="margin-top:10px"><button ${boonRerollOk()?'':'disabled'} data-act="boonReroll" data-arg="${p}:${minR||0}">Reroll the offer (${boonRerollCost()} credits, once)</button><button data-act="boonDecline">Decline: take ${boonDeclineCred()} credits</button></div>`); }
// B4 step 3 (v54): decline a boon offer for credits, or reroll it once per reward for a price that grows each time you reroll in a run
function boonDeclineCred(){ return 30+10*((RUN&&RUN.sector)||1); }
function boonRerollCost(){ return 25+15*((RUN&&RUN.boonRerolls)||0); }
function boonRerollOk(){ return !!(RUN&&RUN.reward&&!RUN.reward.rerolled&&RUN.credits>=boonRerollCost()); }
function boonReroll(p,minR){ if(!boonRerollOk()) return null; RUN.credits-=boonRerollCost(); RUN.boonRerolls=(RUN.boonRerolls||0)+1; RUN.reward.rerolled=true; const old=(RUN.reward.boonOffer||[]).map(o=>o.id);
  let off=rollBoonOffer(p,minR); for(let k=0;k<4&&off.length&&off.every(o=>old.includes(o.id));k++) off=rollBoonOffer(p,minR); RUN.reward.boonOffer=off; return off; }
function boonDecline(){ const c=boonDeclineCred(); RUN.credits+=c; return c; }
ACT.boonReroll=a=>{ const [p,m]=String(a).split(':'); if(!boonReroll(p,+m||0)) return; saveRun(); closeModal(); boonStep(p,+m||0); };
ACT.boonDecline=()=>{ const c=boonDecline(); try{ tel('boon_decline',{cred:c}); }catch(e){} toast(`You decline. +${c} credits.`); closeModal(); relicStep(); };
ACT.takeBoon=i=>{ const o=(window._boonOffer||[])[+i]; if(!o) return; changeFleet(()=>{ RUN.boons=RUN.boons||[]; RUN.boons.push({id:o.id,r:o.r||0}); });
  { const ps=BOONS[o.id].p?[BOONS[o.id].p]:(BOONS[o.id].duo||[]); META.favour=META.favour||{}; for(const p of ps){ const t0=favourTier(p); META.favour[p]=(META.favour[p]||0)+1+(o.r||0); const t1=favourTier(p); if(t1>t0) setTimeout(()=>toast(`${PATRONS[p].n} now counts you ${FAVOUR_TIERS[t1].n}: ${FAVOUR_TIERS[t1].d}`),900); } }
  try{ tel('boon_pick',{id:o.id,r:o.r||0,p:BOONS[o.id].p||'duo',offered:(window._boonOffer||[]).map(x=>x.id+':'+(x.r||0)),sector:RUN.sector}); }catch(e){}
  toast(`${BOONS[o.id].n} gained.`); closeModal(); relicStep(); };
function relicStep(){
  if(RUN.reward&&RUN.reward.stage!=='relic'&&RUN.reward.stage!=='promo'){ RUN.reward.stage='relic'; RUN.reward.boonOffer=RUN.reward.modOffer=null; saveRun(); }
  const rc=window._relicChoice;
  if(rc && rc.length){
    modal(`<h2>${window._rewardCfg.kind==='boss'?'The flagship\u2019s vault':'Spoils of the elite'}</h2>${rewardDef('relic')}<p>Choose one.</p>
      ${rc.map(r=>`<button class="choice" data-act="takeRelic" data-arg="${r}"><b>${esc(relicName(r))}</b><small>${esc(RELICS[r].d)}</small></button>`).join('')}`);
    return;
  }
  promotionsStep();
}
ACT.takeRelic=r=>{ if(!(window._relicChoice||[]).includes(r)) return; changeFleet(()=>RUN.relics.push(r)); window._relicChoice=null; if(RUN.reward) RUN.reward.relics=[]; closeModal(); promotionsStep(); };
function promotionsStep(){
  if(RUN.reward){ RUN.reward.stage='promo'; RUN.reward.relics=[]; saveRun(); }
  const s=RUN.fleet.find(x=>x.cap.pending>0);
  if(s){ promoteModal(s.uid, promotionsStep); return; }
  afterBattle();
}
function resumeReward(){ const R=RUN&&RUN.reward; if(!R) return false; // B1: pick up the reward chain where a reload left it
  window._rewardCfg={kind:R.kind,node:R.node}; window._rw=R.rw||{}; window._relicChoice=R.relics||[]; window._wrecks=R.wrecks||[]; window._boonOffer=R.boonOffer||null; window._modOffer=R.modOffer||null;
  toast('Picking up your rewards where you left off.');
  if(R.stage==='prize'&&(R.prizes||[]).length){ ACT.prizeStep(); return true; }
  if(R.stage==='salvage'&&window._wrecks.length){ ACT.salvageStep(); return true; } if(R.stage==='pick'){ ACT.rewardNext(); return true; } if(R.stage==='relic'){ relicStep(); return true; } promotionsStep(); return true; }
function afterBattle(){
  const cfg=window._rewardCfg||{kind:RUN.reward&&RUN.reward.kind}; RUN.reward=null;
  completeNode();
  if(cfg.kind==='boss'){
    if(RUN.sector>=3){ endRun(true); return; }
    RUN.sector++; RUN.cpCap+=3; RUN.map=genSector(RUN.sector); RUN.pos=null; const na=nemAdapt(); // B4: the Nemesis adapts once per sector
    RUN.fleet.forEach(s=>{ const d=derive(s); s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*.4*repairMult())); });
    saveRun(); mapScreen();
    const F=FACTIONS[RUN.map.fac];
    modal(`<h2>Sector ${roman(RUN.sector)}${RUN.map.region&&REGIONS[RUN.map.region]?`: ${esc(REGIONS[RUN.map.region].n)}`:''}</h2><p>With the flagship broken, the fleet jumps deeper. Fleet command expands: <b class="gilt">+3 command points</b>, and crews patch 40% of every hull during the transit.</p>
      <p>Auspex confirms <b>${esc(F.n)}</b> ahead.</p>${na&&RUN.nem?`<p class="blood">Intelligence: ${esc(nemFull())} has adapted to you: <b>${esc(nemAdaptName(na,RUN.nem.fac))}</b> (${esc(nemAdaptWhy(na,RUN.nem.fac))}). ${esc(nemAdaptDesc(na,RUN.nem.fac))}</p>`:''}${(()=>{ const c=sectorCond(); return c?`<p class="gilt">Sector condition: <b>${esc(c.n)}</b>. <span class="muted">${esc(c.d)}</span></p>`:''; })()}<p class="muted">${esc(F.blurb)}</p><button class="primary" data-act="closeModal">Plot a course</button>`);
    return;
  }
  mapScreen();
}
