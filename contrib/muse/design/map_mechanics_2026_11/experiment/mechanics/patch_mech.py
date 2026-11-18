#!/usr/bin/env python3
# Flag-driven mechanics patches for the mech test copy ONLY (simtest/mech).
# Every change is gated on globalThis.MECHCFG so base behavior is untouched when unset.
import sys

def patch(path, pairs):
    src = open(path).read()
    for old, new, cnt in pairs:
        n = src.count(old)
        assert n == cnt, f"{path}: anchor count {n} != {cnt} for: {old[:90]!r}"
        src = src.replace(old, new)
    open(path, 'w').write(src)
    print(f"{path}: {len(pairs)} patches ok")

B = 'battle.js'
patch(B, [
    # B1: moveRules reads MECHCFG.moveRules overrides (evasion strength tests)
    ("function moveRules(u){ return Object.assign({},MOVE_BASE,(u&&!u.isSq&&MOVE_RULES[u.fac])||{}); }",
     "function moveRules(u){ const b=Object.assign({},MOVE_BASE,(u&&!u.isSq&&MOVE_RULES[u.fac])||{}); if(globalThis.MECHCFG&&MECHCFG.moveRules) Object.assign(b,MECHCFG.moveRules); return b; }",
     1),
    # B2: helpers before torpThreat
    ("function torpThreat(u,v){",
     """function mechChosen(u){ if(!globalThis._MCH||globalThis._MCH.round!==B.round||globalThis._MCH.side!==u.side) globalThis._MCH={round:B.round, side:u.side, hexes:[]}; return globalThis._MCH.hexes; }
function mechField(u,v,foes){ let opp=0, thr=0; const mr=Math.max(0,...u.weapons.map(w=>w.r||0)); for(const f of foes){ if(f.isSq) continue; const d=hdist(v,f); const fr=Math.max(0,...f.weapons.map(w=>w.r||0)); if(d<=fr+(f.speed||2)) thr++; if(d<=mr) opp++; } return opp-thr; }
function mechStraight(u,path){ if(!path) return false; const steps=path.filter(p=>!p.rot); if(steps.length<4) return false; const pts=[{q:u.q,r:u.r}].concat(steps); const d0=(pts[1].q-pts[0].q)+','+(pts[1].r-pts[0].r); for(let i=2;i<pts.length;i++){ if((pts[i].q-pts[i-1].q)+','+(pts[i].r-pts[i-1].r)!==d0) return false; } return true; }
function torpThreat(u,v){""",
     1),
    # B3: torpThreat predictive lane term
    ("if(s.tid===u.id){ if(d<=2) tot+=s.w.dmg*s.w.shots*[.62,.52,.38][d]; } else if(d===0) tot+=s.w.dmg*s.w.shots*.5; } return tot; }",
     "if(s.tid===u.id){ if(d<=2) tot+=s.w.dmg*s.w.shots*[.62,.52,.38][d]; } else if(d===0) tot+=s.w.dmg*s.w.shots*.5; if(globalThis.MECHCFG&&MECHCFG.torpPred&&s.from){ const lane=hexLine(s.from,s.aim); if(lane.some(h=>h.q===v.q&&h.r===v.r)) tot+=s.w.dmg*s.w.shots*.25; } } return tot; }",
     1),
    # B4: inReach spinal-arc test for long turret guns
    ("if(!inArc(u,t,w.arc)) return false; return los(u,t); }",
     "const _arc=(globalThis.MECHCFG&&MECHCFG.arcs&&w.arc==='T'&&(w.r||0)>=6)?'F':w.arc; if(!inArc(u,t,_arc)) return false; return los(u,t); }",
     1),
    # B5a: hitChance falloff swap (accuracy falloff off when fallSwap)
    ("-(noFall?0:over*w.fall)",
     "-((noFall||(globalThis.MECHCFG&&MECHCFG.fallSwap))?0:over*w.fall)",
     1),
    # B5b: rearHit and longGun inserts
    ("  c+=motionHit(t);",
     """  c+=motionHit(t);
  if(globalThis.MECHCFG&&MECHCFG.rearHit&&treeIsRear(u,t,shieldQuad(t,u))) c+=10;
  if(globalThis.MECHCFG&&MECHCFG.longGun&&w.r>=5&&d<=2) c-=20;""",
     1),
    # B6: dmgMult damage-band taper (fallSwap) and momentum bonus
    ("  m+=rakeBonus(u,w);\n  let base=w.dmg*m;",
     """  m+=rakeBonus(u,w);
  if(globalThis.MECHCFG&&MECHCFG.fallSwap){ const dd=hdist(u,t); if(dd>w.opt&&w.r>w.opt) m*=1-0.4*((dd-w.opt)/(w.r-w.opt)); }
  if(globalThis.MECHCFG&&MECHCFG.momentum&&u._mom) m*=1.15;
  let base=w.dmg*m;""",
     1),
    # B7: moveUnit stamps momentum eligibility
    ("u.hexMoved=(u.hexMoved||0)+path.filter(p=>!p.rot).length;",
     "u.hexMoved=(u.hexMoved||0)+path.filter(p=>!p.rot).length; if(globalThis.MECHCFG&&MECHCFG.momentum) u._mom=mechStraight(u,path)?1:0;",
     1),
    # B8a: aiUnit multiplicative scoring option
    ("let score=off-threat*tw;",
     "let score=off-threat*tw; if(globalThis.MECHCFG&&MECHCFG.mult) score=Math.pow(Math.max(0,off)+1,.55)*Math.pow(1/(1+Math.max(0,threat)/10),.45)*40;",
     1),
    # B8b: aiUnit loop head: candidate collection, turn limit, momentum view stamp
    ("    for(const s of states){\n      const v=stateView(u,s);\n      const vet=vet0, focus=focus0;",
     """    const CANDM=[];
    for(const s of states){
      const v=stateView(u,s);
      if(globalThis.MECHCFG&&MECHCFG.turnLimit){ const df=Math.abs(s.f-u.facing)%6; if(Math.min(df,6-df)>1) continue; }
      if(globalThis.MECHCFG&&MECHCFG.momentum) v._mom=mechStraight(u,s.path)?1:0;
      const vet=vet0, focus=focus0;""",
     1),
    # B8c: aiUnit loop tail: flag adjustments + candidate record
    ("      if(score>bestScore){ bestScore=score; best=s; }",
     """      if(globalThis.MECHCFG){ if(MECHCFG.deconf){ for(const h of mechChosen(u)){ const dd=hdist(v,h); if(dd===1) score-=4; else if(dd===2) score-=1.5; } } if(MECHCFG.course&&u._courseDest&&hdist(v,u._courseDest)<=2) score+=3; if(MECHCFG.fieldW) score+=MECHCFG.fieldW*mechField(u,v,foes); CANDM.push({s:s, score:score, off:off, disp:hdist(u,v)}); }
      if(score>bestScore){ bestScore=score; best=s; }""",
     1),
    # B8d: aiUnit after loop: two-pass resolution + chosen/course recording
    ("    }\n    let volleyP=null, braceMid=false;",
     """    }
    if(globalThis.MECHCFG&&MECHCFG.twopass&&CANDM.length){ let mo=0; for(const c of CANDM) if(c.off>mo) mo=c.off; const bud=bestScore-0.10*Math.max(1,mo); let bp=null; for(const c of CANDM){ if(c.score<bud) continue; if(!bp||c.disp>bp.disp||(c.disp===bp.disp&&c.score>bp.score)) bp=c; } if(bp){ best=bp.s; bestScore=bp.score; } }
    if(globalThis.MECHCFG&&(MECHCFG.deconf||MECHCFG.course)&&best){ if(MECHCFG.deconf) mechChosen(u).push({q:best.q, r:best.r}); if(MECHCFG.course) u._courseDest={q:best.q, r:best.r}; }
    let volleyP=null, braceMid=false;""",
     1),
])

M = 'measure_map.js'
patch(M, [
    # M1: botUnit loop, flag-aware
    ("  const {states}=computeReach(u); let best=null,bs=-1e9;\n  for(const s of states){ const v=stateView(u,s); const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const nd=Math.min(...foes.map(f=>hdist(v,f))); const sc=off-th*.3-(off>0?0:nd*3)-botObj(v)-torpThreat(u,v)*.9-syncPull(u,v)*1.5; if(sc>bs){bs=sc;best=s;} }\n  if(best&&best.path.length) await moveUnit(u,best);",
     """  const {states}=computeReach(u); let best=null,bs=-1e9; const CANDM=[];
  for(const s of states){ const v=stateView(u,s); if(globalThis.MECHCFG&&MECHCFG.turnLimit){ const df=Math.abs(s.f-u.facing)%6; if(Math.min(df,6-df)>1) continue; } if(globalThis.MECHCFG&&MECHCFG.momentum) v._mom=mechStraight(u,s.path)?1:0; const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const nd=Math.min(...foes.map(f=>hdist(v,f))); let sc=off-th*.3-(off>0?0:nd*3)-botObj(v)-torpThreat(u,v)*.9-syncPull(u,v)*1.5; if(globalThis.MECHCFG&&MECHCFG.mult) sc=Math.pow(Math.max(0,off)+1,.55)*Math.pow(1/(1+Math.max(0,th)/10),.45)*40-(off>0?0:nd*3)-botObj(v)-torpThreat(u,v)*.9-syncPull(u,v)*1.5; if(globalThis.MECHCFG){ if(MECHCFG.deconf){ for(const h of mechChosen(u)){ const dd=hdist(v,h); if(dd===1) sc-=4; else if(dd===2) sc-=1.5; } } if(MECHCFG.course&&u._courseDest&&hdist(v,u._courseDest)<=2) sc+=3; if(MECHCFG.fieldW) sc+=MECHCFG.fieldW*mechField(u,v,foes); CANDM.push({s:s, sc:sc, off:off, disp:hdist(u,v)}); } if(sc>bs){bs=sc;best=s;} }
  if(globalThis.MECHCFG&&MECHCFG.twopass&&CANDM.length){ let mo=0; for(const c of CANDM) if(c.off>mo) mo=c.off; const bud=bs-0.10*Math.max(1,mo); let bp=null; for(const c of CANDM){ if(c.sc<bud) continue; if(!bp||c.disp>bp.disp||(c.disp===bp.disp&&c.sc>bp.sc)) bp=c; } if(bp){ best=bp.s; bs=bp.sc; } }
  if(best&&best.path.length) await moveUnit(u,best);
  if(globalThis.MECHCFG&&(MECHCFG.deconf||MECHCFG.course)&&best){ if(MECHCFG.deconf) mechChosen(u).push({q:best.q, r:best.r}); if(MECHCFG.course) u._courseDest={q:best.q, r:best.r}; }""",
     1),
    # M2: activation start positions
    ("ACT1004 = {unit: pp[0], fired:false, moved:false}",
     "ACT1004 = {unit: pp[0], fired:false, moved:false, sq: pp[0].q, sr: pp[0].r}",
     1),
    ("ACT1004 = {unit: u, fired:false, moved:false}",
     "ACT1004 = {unit: u, fired:false, moved:false, sq: u.q, sr: u.r}",
     1),
    # M3: tally additions (both activation sites)
    ("postDist += ACT1004.dist || 0; } ACT1004 = null; }",
     "postDist += ACT1004.dist || 0; postNet += hdist({q:ACT1004.sq, r:ACT1004.sr}, ACT1004.unit); postNetN++; } const _lp = LASTPOS1004[ACT1004.unit.id]; if (_lp && FIRSTFIREACT1004 !== null && ACTCOUNT1004 > FIRSTFIREACT1004){ multiD += hdist(_lp, ACT1004.unit); multiN++; } LASTPOS1004[ACT1004.unit.id] = {q: ACT1004.unit.q, r: ACT1004.unit.r}; ACT1004 = null; }",
     2),
    # M4: metric locals
    ("let acts = 0, moveOnly = 0, postActs = 0, postMoved = 0, postMF = 0, postDist = 0;",
     "let acts = 0, moveOnly = 0, postActs = 0, postMoved = 0, postMF = 0, postDist = 0; let postNet = 0, postNetN = 0, multiD = 0, multiN = 0; const LASTPOS1004 = {}; const BEAR1004 = {}; global.__BEAR1004 = BEAR1004;",
     1),
    # M5: mech config plumbing
    ("global.__RENT3 = cfg.rent3 ? 1 : 0;",
     "global.__RENT3 = cfg.rent3 ? 1 : 0; globalThis.MECHCFG = cfg.mech || null;",
     1),
    # M6: new result fields
    ("postDist: postDist,",
     "postDist: postDist, netDisp: postNetN ? +(postNet/postNetN).toFixed(2) : null, multiDisp: multiN ? +(multiD/multiN).toFixed(2) : null, bearDiv: (()=>{ const vs = Object.values(BEAR1004); return vs.length ? +(vs.reduce((a,s)=>a+s.size,0)/vs.length).toFixed(2) : null; })(),",
     1),
    # M7: bearing diversity in the fire wrapper
    ("if (SHOTS1004.hexes) SHOTS1004.hexes.push([t.q, t.r]);",
     """if (SHOTS1004.hexes) SHOTS1004.hexes.push([t.q, t.r]);
      if (global.__BEAR1004){ const dq = u.q - t.q, dr = u.r - t.r; let bs2 = 0, bd2 = -1e18; for (let di = 0; di < 6; di++){ const dv = DIRS[di]; const sc2 = dq*dv[0] + dr*dv[1] + (dq+dr)*(dv[0]+dv[1]); if (sc2 > bd2){ bd2 = sc2; bs2 = di; } } (global.__BEAR1004[t.id] = global.__BEAR1004[t.id] || new Set()).add(bs2); }""",
     1),
    # M8: traceability in output rows
    ("rent3: cfg.rent3 ? 1 : 0,",
     "rent3: cfg.rent3 ? 1 : 0, mech: cfg.mech ? JSON.stringify(cfg.mech) : null,",
     1),
])
print("all patches applied")
