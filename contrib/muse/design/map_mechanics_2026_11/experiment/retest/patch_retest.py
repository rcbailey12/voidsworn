import sys

def patch(path, pairs):
    src = open(path, encoding='utf8').read()
    for old, new, want in pairs:
        n = src.count(old)
        if n != want:
            print(f'FAIL {path}: expected {want} of {old[:60]!r}, found {n}')
            sys.exit(1)
        src = src.replace(old, new)
    open(path, 'w', encoding='utf8').write(src)
    print(f'patched {path}: {len(pairs)} edits')

patch('battle.js', [
  # veteran AI (enemy seat): two-pass also enabled by twopassE
  ("if(globalThis.MECHCFG&&MECHCFG.twopass&&CANDM.length){ let mo=0; for(const c of CANDM) if(c.off>mo) mo=c.off; const bud=bestScore-0.10",
   "if(globalThis.MECHCFG&&(MECHCFG.twopass||MECHCFG.twopassE)&&CANDM.length){ let mo=0; for(const c of CANDM) if(c.off>mo) mo=c.off; const bud=bestScore-0.10", 1),
])

patch('measure_map.js', [
  # harness bot (player seat): two-pass also enabled by twopassP
  ("if(globalThis.MECHCFG&&MECHCFG.twopass&&CANDM.length){ let mo=0; for(const c of CANDM) if(c.off>mo) mo=c.off; const bud=bs-0.10",
   "if(globalThis.MECHCFG&&(MECHCFG.twopass||MECHCFG.twopassP)&&CANDM.length){ let mo=0; for(const c of CANDM) if(c.off>mo) mo=c.off; const bud=bs-0.10", 1),
  # per-side accumulators
  ("let postNet = 0, postNetN = 0, multiD = 0, multiN = 0; const LASTPOS1004 = {}; const BEAR1004 = {}; global.__BEAR1004 = BEAR1004;",
   "let postNet = 0, postNetN = 0, multiD = 0, multiN = 0; const LASTPOS1004 = {}; const BEAR1004 = {}; global.__BEAR1004 = BEAR1004; const NETSIDE = {player:[0,0], enemy:[0,0]}; const MULTISIDE = {player:[0,0], enemy:[0,0]}; const SHOTSIDE = {player:{n:0,rsum:0,close:0,kills:0}, enemy:{n:0,rsum:0,close:0,kills:0}}; global.__SHOTSIDE = SHOTSIDE;", 1),
  ("postNet += hdist({q:ACT1004.sq, r:ACT1004.sr}, ACT1004.unit); postNetN++;",
   "postNet += hdist({q:ACT1004.sq, r:ACT1004.sr}, ACT1004.unit); postNetN++; NETSIDE[ACT1004.unit.side][0] += hdist({q:ACT1004.sq, r:ACT1004.sr}, ACT1004.unit); NETSIDE[ACT1004.unit.side][1]++;", 2),
  ("multiD += hdist(_lp.p2, ACT1004.unit); multiN++;",
   "multiD += hdist(_lp.p2, ACT1004.unit); multiN++; MULTISIDE[ACT1004.unit.side][0] += hdist(_lp.p2, ACT1004.unit); MULTISIDE[ACT1004.unit.side][1]++;", 2),
  # fireWeapon wrapper: capture target hp, then per-side shot stats and kill credit
  ("fireWeapon = async function(u, wi, t, opts){\n  const okFire =",
   "fireWeapon = async function(u, wi, t, opts){\n  const _hp0 = (u && t) ? t.hp : null;\n  const okFire =", 1),
  ("  return _fw1004(u, wi, t, opts);\n};",
   "  const _r = await _fw1004(u, wi, t, opts); if (okFire && global.__SHOTSIDE){ const SS = global.__SHOTSIDE[u.side]; if (SS){ const _d = hdist(u, t); SS.n++; SS.rsum += _d; if (_d <= 3) SS.close++; if (_hp0 > 0 && t.hp <= 0) SS.kills++; } } return _r;\n};", 1),
  # row output: per-side fields
  (", startGap: (()=>{",
   ", netDispP: NETSIDE.player[1] ? +(NETSIDE.player[0]/NETSIDE.player[1]).toFixed(2) : null, netDispE: NETSIDE.enemy[1] ? +(NETSIDE.enemy[0]/NETSIDE.enemy[1]).toFixed(2) : null, multiDispP: MULTISIDE.player[1] ? +(MULTISIDE.player[0]/MULTISIDE.player[1]).toFixed(2) : null, multiDispE: MULTISIDE.enemy[1] ? +(MULTISIDE.enemy[0]/MULTISIDE.enemy[1]).toFixed(2) : null, aliveP: B.units.filter(u=>u.side==='player'&&!u.isSq&&u.hp>0).length, aliveE: B.units.filter(u=>u.side==='enemy'&&!u.isSq&&u.hp>0).length, hullP: B.units.filter(u=>u.side==='player'&&!u.isSq).reduce((a,u)=>a+Math.max(0,u.hp),0), hullE: B.units.filter(u=>u.side==='enemy'&&!u.isSq).reduce((a,u)=>a+Math.max(0,u.hp),0), killsP: SHOTSIDE.player.kills, killsE: SHOTSIDE.enemy.kills, meanRangeP: SHOTSIDE.player.n ? +(SHOTSIDE.player.rsum/SHOTSIDE.player.n).toFixed(2) : null, meanRangeE: SHOTSIDE.enemy.n ? +(SHOTSIDE.enemy.rsum/SHOTSIDE.enemy.n).toFixed(2) : null, closeP: SHOTSIDE.player.n ? +(SHOTSIDE.player.close/SHOTSIDE.player.n).toFixed(3) : null, closeE: SHOTSIDE.enemy.n ? +(SHOTSIDE.enemy.close/SHOTSIDE.enemy.n).toFixed(3) : null, dmgP: B.units.filter(u=>u.side==='enemy'&&!u.isSq).reduce((a,u)=>a+(u.maxHp-Math.max(0,u.hp)),0), dmgE: B.units.filter(u=>u.side==='player'&&!u.isSq).reduce((a,u)=>a+(u.maxHp-Math.max(0,u.hp)),0), startGap: (()=>{", 1),
])
print('ALL RETEST PATCHES APPLIED')
