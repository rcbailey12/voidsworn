import sys, pathlib

def patch(path, pairs):
    t = pathlib.Path(path).read_text()
    for old, new in pairs:
        n = t.count(old)
        assert n == 1, f"{path}: expected 1 match, got {n} for: {old[:70]!r}"
        t = t.replace(old, new)
    pathlib.Path(path).write_text(t)
    print("patched", path)

HOLD_SETUP_OLD = """  if(o.type==='hold'){ const c=offToAx(Math.floor(BW/2),Math.floor(BH/2)); let best=null,bd=1e9; for(const h of boardHexes()){ if(blocks(terr(h.q,h.r))||unitAt(h.q,h.r)) continue; const d=hdist(h,c); if(d<bd){bd=d;best=h;} }
    o.hex={q:best.q,r:best.r}; for(const h of boardHexes()) if(hdist(h,o.hex)<=1&&blocks(terr(h.q,h.r))) delete B.terrain[hkey(h.q,h.r)]; }"""

HOLD_SETUP_NEW = """  if(o.type==='hold'){ if(global.__SITES3){ const bb=boardBounds(), snap=(fx,fy)=>{ const tg=offToAx(Math.round(bb.c0+(bb.c1-bb.c0)*fx),Math.round(bb.r0+(bb.r1-bb.r0)*fy)); let bst=null,bdd=1e9; for(const h of boardHexes()){ if(blocks(terr(h.q,h.r))||unitAt(h.q,h.r)) continue; const d=hdist(h,tg); if(d<bdd){bdd=d;bst=h;} } return {q:bst.q,r:bst.r}; };
      o.sites=[snap(.5,.5),snap(.27,.30),snap(.73,.70)]; o.hex=o.sites[0]; for(const s of o.sites) for(const h of boardHexes()) if(hdist(h,s)<=1&&blocks(terr(h.q,h.r))) delete B.terrain[hkey(h.q,h.r)]; }
    else { const c=offToAx(Math.floor(BW/2),Math.floor(BH/2)); let best=null,bd=1e9; for(const h of boardHexes()){ if(blocks(terr(h.q,h.r))||unitAt(h.q,h.r)) continue; const d=hdist(h,c); if(d<bd){bd=d;best=h;} }
      o.hex={q:best.q,r:best.r}; for(const h of boardHexes()) if(hdist(h,o.hex)<=1&&blocks(terr(h.q,h.r))) delete B.terrain[hkey(h.q,h.r)]; } }"""

TICK_OLD = """  if(o.type!=='hold') return; const near=s=>alive(s).some(u=>!u.isSq&&hdist(u,o.hex)<=1); const p=near('player'), e=near('enemy');
  if(p&&!e){ o.score++; log(`You hold the relay (${o.score}/3).`,'p'); } else if(e&&!p){ o.escore++; log(`The enemy holds the relay (${o.escore}/3).`,'e'); } else if(p&&e) log('The relay is contested.','x'); checkEnd(); }"""

TICK_NEW = """  if(o.type!=='hold') return; const ss=o.sites||[o.hex]; const holds=s=>ss.some(h=>alive(s).some(u=>!u.isSq&&hdist(u,h)<=1)&&!alive(s==='player'?'enemy':'player').some(u=>!u.isSq&&hdist(u,h)<=1)); const p=holds('player'), e=holds('enemy');
  if(p&&e){ o.score++; o.escore++; log('Both sides hold a relay.','x'); } else if(p){ o.score++; log(`You hold a relay (${o.score}/3).`,'p'); } else if(e){ o.escore++; log(`The enemy holds a relay (${o.escore}/3).`,'e'); } else if(ss.some(h=>alive('player').some(u=>!u.isSq&&hdist(u,h)<=1)&&alive('enemy').some(u=>!u.isSq&&hdist(u,h)<=1))) log('The relays are contested.','x'); checkEnd(); }"""

AIOBJ_OLD = """  if(vet&&o.type==='hold'){ // the relay pulls only the two enemy ships nearest it; the rest fight nearby. A ship already holding it uncontested is paid to stay
    const mine=caps('enemy').filter(x=>!x.transport).sort((a,b)=>hdist(a,o.hex)-hdist(b,o.hex)||(a.id<b.id?-1:1)), k=mine.indexOf(u), d=hdist(v,o.hex);
    if(k<0||k>1) return -Math.max(0,d-5)*.4;
    const held=hdist(u,o.hex)<=1&&!caps('player').some(p=>hdist(p,o.hex)<=1); return -d*1.6*urg+(held&&d<=1?4:0); }"""

AIOBJ_NEW = """  if(vet&&o.type==='hold'){ // each relay pulls only the two enemy ships nearest that relay; the rest fight nearby. A ship already holding one uncontested is paid to stay
    const ss=o.sites||[o.hex], nearS=h=>{ let bh=ss[0],bd=1e9; for(const s of ss){ const dd=hdist(h,s); if(dd<bd){bd=dd;bh=s;} } return bh; }, dS=h=>hdist(h,nearS(h));
    const mine=caps('enemy').filter(x=>!x.transport).sort((a,b)=>dS(a)-dS(b)||(a.id<b.id?-1:1)), myS=nearS(u), k=mine.filter(x=>nearS(x)===myS).indexOf(u), d=dS(v);
    if(k<0||k>1) return -Math.max(0,d-5)*.4;
    const held=hdist(u,myS)<=1&&!caps('player').some(p=>hdist(p,myS)<=1); return -d*1.6*urg+(held&&d<=1?4:0); }"""

for d in ["t30", "t34", "t38", "t42"]:
    patch(f"{d}/battle.js", [(HOLD_SETUP_OLD, HOLD_SETUP_NEW), (TICK_OLD, TICK_NEW), (AIOBJ_OLD, AIOBJ_NEW)])

BOTOBJ_OLD = "  if(o.type==='hold') return hdist(v,o.hex)*1.6;"
BOTOBJ_NEW = "  if(o.type==='hold'){ const ss=o.sites||[o.hex]; return Math.min(...ss.map(h=>hdist(v,h)))*1.6; }"

FW_OLD = "      SHOTS1004.n++; SHOTS1004.rsum += d;const mx = w.r || null;"
FW_NEW = "      SHOTS1004.n++; SHOTS1004.rsum += d;const mx = w.r || null;\n      if (SHOTS1004.hexes) SHOTS1004.hexes.push([t.q, t.r]);"

INIT_OLD = "SHOTS1004 = {n:0, rsum:0, wn:0, edge:0, torpFire:0, firstSp:null, firstTpl:null};"
INIT_NEW = "SHOTS1004 = {n:0, rsum:0, wn:0, edge:0, torpFire:0, firstSp:null, firstTpl:null, hexes: []};"

FLAG_OLD = "  startBattle({kind:'battle', fac:'hegemony', col:3, map:cfg.map, shape:cfg.shape, arena:cfg.arena, seed:cfg.seed, enemies, obj: cfg.obj || 'rout'});"
FLAG_NEW = "  global.__SITES3 = cfg.sites3 ? 1 : 0;\n" + FLAG_OLD

CALC_OLD = "  var FIDD = {tl:0, th:0};"
CALC_NEW = """  let CLUS1004 = 0; const _hx = SHOTS1004.hexes || []; if (_hx.length){ const _seen = new Set(_hx.map(h=>h[0]+','+h[1])); for (const k of _seen){ const _p = k.split(','); const _c = {q:+_p[0], r:+_p[1]}; let _n = 0; for (const h of _hx) if (hdist(_c, {q:h[0], r:h[1]}) <= 2) _n++; if (_n > CLUS1004) CLUS1004 = _n; } CLUS1004 = +(_hx.length ? CLUS1004 / _hx.length : 0).toFixed(3); }
  const SITES1004 = B.obj ? (B.obj.sites ? B.obj.sites.length : (B.obj.hex ? 1 : 0)) : 0; let SITESEP1004 = null; if (B.obj && B.obj.sites && B.obj.sites.length > 1){ SITESEP1004 = 1e9; for (let i=0;i<B.obj.sites.length;i++) for (let j=i+1;j<B.obj.sites.length;j++) SITESEP1004 = Math.min(SITESEP1004, hdist(B.obj.sites[i], B.obj.sites[j])); }
  var FIDD = {tl:0, th:0};"""

ROW_OLD = "terrHexes: Object.keys(B.terrain).length,"
ROW_NEW = "terrHexes: Object.keys(B.terrain).length, clus: CLUS1004, sites: SITES1004, siteSep: SITESEP1004,"

ECHO_OLD = "obj: cfg.obj || 'rout', spmP: cfg.spmP || null,"
ECHO_NEW = "obj: cfg.obj || 'rout', sites3: cfg.sites3 ? 1 : 0, spmP: cfg.spmP || null,"

for d in ["t30", "t34", "t38", "t42"]:
    patch(f"{d}/measure_map.js", [(BOTOBJ_OLD, BOTOBJ_NEW), (FW_OLD, FW_NEW), (INIT_OLD, INIT_NEW), (FLAG_OLD, FLAG_NEW), (CALC_OLD, CALC_NEW), (ROW_OLD, ROW_NEW), (ECHO_OLD, ECHO_NEW)])

print("ALL PATCHES OK")
