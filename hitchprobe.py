# B-17 hitch probe: plays a sector 1 and a sector 3 campaign battle in a real browser on the GPU with BOTH sides acting (your side runs the
# sim's bot: move to the best spot, fire every gun at the best target), and records every frame longer than 25 ms with what was happening:
#   - shader work: WebGL compileShader / linkProgram / getProgramParameter time (a link-status read is where a compile stall lands)
#   - texture uploads: texImage2D / texSubImage2D / compressedTexImage2D / generateMipmap time and size
#   - garbage collection: a drop in the JS heap (Chrome's performance.memory, precise with --enable-precise-memory-info)
#   - long tasks (PerformanceObserver 'longtask') and slow game functions (ship view builds, damage clones, wreck splits, HUD rebuilds)
#   - the phase the battle was in: move, volley, death, enemy turn, wing phase, banner, round change
# Each battle runs twice in fresh browser pages with the shader disk cache off (a cold first play): FIX=off puts the B-17 pre-warm out of the
# way (window.VS_NOWARM17), FIX=on is the shipped game. Prints a ranked table of hitch causes and writes hitchprobe.json.
#
# Run:  python3 hitchprobe.py                       (about 6 to 12 minutes per resolution on the PC)
# Env:  W=2560 H=1440 (or 3840 2160)  HEADLESS=0 to draw on screen (closest to play)  ROUNDS=6  SECTORS=1,3  FIX=off,on  Q=ultra
#       HITCH=25 (ms)  WARMCACHE=1 keeps the browser's shader cache (a second play)  SEED=7
import os, sys, json, time
os.environ.setdefault('OUT', 'hitchprobe')
import fxshot as F
from playwright.sync_api import sync_playwright

ROUNDS = int(os.environ.get('ROUNDS', '6'))
SECTORS = [int(x) for x in os.environ.get('SECTORS', '1,3').split(',')]
FIXES = os.environ.get('FIX', 'off,on').split(',')
HITCH = float(os.environ.get('HITCH', '25'))
WARMCACHE = os.environ.get('WARMCACHE', '0') == '1'

# Instrumentation, injected once the title screen is up. Everything is timestamped with performance.now(); a hitch is a rAF gap over HITCH ms,
# and the work charged to it is whatever ended inside that gap.
INSTR = r"""
window.HP=(()=>{ const P={on:false,frames:0,hitch:[],ev:[],act:{},heap:[],alloc:0,lastHeap:0,longs:[]}, now=()=>performance.now(), TH=%s;
  const mark=(k,d,x)=>{ if(P.on) P.ev.push({t:now(),k,d:+(d||0).toFixed(2),x}); };
  const tagOn=t=>{ P.act[t]=(P.act[t]||0)+1; }, tagOff=t=>{ if(P.act[t]>0) P.act[t]--; };
  // phases: async game functions, tagged while they run
  for(const [n,t] of [['moveUnit','move'],['fireWeapon','volley'],['animExplode','death'],['banner','banner'],['aiStep','enemy turn'],['nextRound','round change'],['useAbility','ability'],['fxBoard','boarding'],['fxRam','ram'],['killUnit','death']]){
    const f=window[n]; if(typeof f!=='function') continue; window[n]=async function(...a){ tagOn(t); try{ return await f.apply(this,a); } finally{ tagOff(t); } }; }
  // slow sync game functions: charged by name when they take 2 ms or more
  for(const n of ['createView','disposeView','shipDamageFx','shipDamagePrep','fragmentHull','splitModel','buildShipModel','buildShipModelFresh','applyAIHull','explode','blast','fireballFx','debris','shieldDome','fxShieldBreak','shieldShatter','wreckInterior','refreshPanel','refreshRoster','refreshTop','bRefresh','refreshOverlays','updateOverlays','updateReach','boardMarks','fpRebuild','buildHud','aiChip','selectUnit','log','toast','sqAct','addFire','corsairBreakup','hulkCookOff','donorPanel','rustShed','lanceBeam','beam','sparkSpray','flames','chunks','deathPop','debBatch','computeThreat','fxText']){
    const f=window[n]; if(typeof f!=='function'||/^\s*async/.test(String(f))) continue; window[n]=function(...a){ const t=now(); try{ return f.apply(this,a); } finally{ const d=now()-t; if(d>=2) mark('fn '+n,d); } }; }
  // GPU-side work seen from WebGL
  const gl=G.engine._gl; for(const n of ['compileShader','linkProgram','getProgramParameter','getShaderParameter','getUniformLocation','texImage2D','texSubImage2D','compressedTexImage2D','compressedTexSubImage2D','generateMipmap','bufferData','texStorage2D','readPixels','getError','finish']){
    const f=gl[n]; if(typeof f!=='function') continue; gl[n]=function(...a){ const t=now(); try{ return f.apply(gl,a); } finally{ const d=now()-t; if(d>=.5||n==='compileShader'||n==='linkProgram'){ let x; if(/^tex|^compressed/.test(n)){ const w=a.find((v,i)=>i>2&&typeof v==='number'&&v>16); const src=a[a.length-1]; x=src&&src.width?src.width+'x'+src.height:(w||''); } mark('gl '+n,d,x); } } }; }
  try{ new PerformanceObserver(l=>{ for(const e of l.getEntries()) if(P.on) P.longs.push({t:e.startTime+e.duration,s:e.startTime,d:e.duration}); }).observe({type:'longtask',buffered:false}); }catch(e){}
  let last=now(); const loop=()=>{ const t=now(), dt=t-last;
    if(P.on){ P.frames++; const m=performance.memory; if(m){ const h=m.usedJSHeapSize; if(P.lastHeap){ if(h<P.lastHeap-1.5e6) mark('gc',(P.lastHeap-h)/1e6); else if(h>P.lastHeap) P.alloc+=h-P.lastHeap; } P.lastHeap=h; }
      if(dt>TH) P.hitch.push({s:last,t,dt:+dt.toFixed(1),tags:Object.keys(P.act).filter(k=>P.act[k]>0),round:B?B.round:0}); }
    last=t; requestAnimationFrame(loop); }; requestAnimationFrame(loop);
  P.start=()=>{ P.on=true; P.frames=0; P.hitch=[]; P.ev=[]; P.longs=[]; P.alloc=0; P.lastHeap=0; P.t0=now(); };
  // charge every hitch with the work that ended inside it, biggest first
  P.stop=()=>{ P.on=false; const T=now()-P.t0;
    const out=P.hitch.map(h=>{ const w={}; for(const e of P.ev) if(e.t>h.s&&e.t<=h.t){ const k=e.k==='gc'?'gc':e.k; (w[k]=w[k]||{n:0,ms:0,x:[]}); w[k].n++; w[k].ms+=e.d; if(e.x&&w[k].x.length<3) w[k].x.push(e.x); }
      const lt=P.longs.filter(l=>l.t>h.s&&l.s<h.t).reduce((a,l)=>a+l.d,0); return Object.assign(h,{work:w,long:+lt.toFixed(1)}); });
    return {ms:Math.round(T),frames:P.frames,fps:+(P.frames/(T/1000)).toFixed(1),allocMBs:+(P.alloc/1e6/(T/1000)).toFixed(1),hitches:out,warm:G.lastWarm||null,
      renderer:(()=>{ try{ const x=gl.getExtension('WEBGL_debug_renderer_info'); return x?gl.getParameter(x.UNMASKED_RENDERER_WEBGL):'?'; }catch(e){ return '?'; } })()}; };
  return P; })(); 0
""" % HITCH

# your side's bot (sim3d.js botTurn without abilities or tactics): best spot by offence minus threat, then every gun at its best target
BOT = r"""
window.PB=(()=>{ const P={}, FLEET={1:['penitent','harrow','warden','warden'],2:['cathedral','penitent','harrow','warden','warden'],3:['ascendant','cathedral','penitent','reliquary','harrow','warden']};
  P.enter=sec=>{ RUN.sector=sec; RUN.cpCap=40; RUN.fleet=FLEET[sec].map(t=>newShip(t,true)); RUN.flagUid=RUN.fleet[0].uid; const n=RUN.map.cols.flat().find(x=>x.type==='battle'&&x.col>=2)||RUN.map.cols.flat().find(x=>x.type==='battle');
    RUN.pos=n.id; RUN.curNode=n.id; battleScreen({kind:'battle',fac:RUN.map.fac,col:n.col,node:n.id}); return {p:B.units.filter(u=>u.side==='player'&&!u.isSq).length,e:B.units.filter(u=>u.side==='enemy'&&!u.isSq).length}; };
  P.warmDone=()=>!document.getElementById('bveil')&&!!G.lastWarm;
  P.ready=()=>!!B&&!B.over&&B.side==='player'&&!B.busy;
  P.act=async()=>{ const u=pendingP()[0]; if(!u){ await endActivation(true); return; } try{
      const foes=alive('enemy'); if(foes.length&&!u.isSq){ const {states}=computeReach(u); let best=null,bs=-1e9; for(const s of states){ const v=stateView(u,s); const off=evalOffense(v,u.weapons.filter(weaponReady),foes); const th=evalThreat(v,foes); const nd=Math.min(...foes.map(f=>hdist(v,f))); const sc=off-th*.3-(off>0?0:nd*3); if(sc>bs){ bs=sc; best=s; } }
        selectUnit(u); if(best&&best.path.length) await moveUnit(u,best);
        for(let i=0;i<u.weapons.length&&!B.over;i++){ let bt=null,bv=0; for(const t of alive('enemy')) if(canFire(u,u.weapons[i],t)){ const e=expectedVs(u,u.weapons[i],t); const v=e.hull+e.shield*.3+(e.hull>=t.hp?20:0); if(v>bv){ bv=v; bt=t; } } if(bt) await fireWeapon(u,i,bt); } }
    }catch(e){ console.warn('probe bot',e); } if(!B.over) await endActivation(true); };
  P.state=()=>({round:B?B.round:0,over:B?B.over:true,alive:B?{p:alive('player').filter(u=>!u.isSq).length,e:alive('enemy').filter(u=>!u.isSq).length}:null});
  return P; })(); 0
"""

def cause(h):
    """One label per hitch: the biggest piece of marked work inside it, else the phase it fell in."""
    w = h['work']
    if w:
        k, v = max(w.items(), key=lambda kv: kv[1]['ms'])
        grp = {'gl compileShader': 'shader compile', 'gl linkProgram': 'shader compile', 'gl getProgramParameter': 'shader compile', 'gl getShaderParameter': 'shader compile', 'gl getUniformLocation': 'shader compile',
               'gl texImage2D': 'texture upload', 'gl texSubImage2D': 'texture upload', 'gl compressedTexImage2D': 'texture upload', 'gl compressedTexSubImage2D': 'texture upload', 'gl generateMipmap': 'texture upload', 'gl texStorage2D': 'texture upload',
               'gc': 'garbage collection', 'gl bufferData': 'buffer upload', 'gl readPixels': 'GPU readback', 'gl getError': 'GPU sync', 'gl finish': 'GPU sync'}.get(k, k)
        if v['ms'] >= h['dt'] * .25: return grp
    tags = [t for t in h['tags'] if t != 'enemy turn'] or h['tags']
    return 'unmarked, during ' + (tags[0] if tags else 'idle') + (' (long task)' if h['long'] > 0 else '')

def battle(pg, sec):
    ships = pg.evaluate("PB.enter(%d)" % sec)
    pg.wait_for_function("PB.warmDone()", timeout=120000, polling=100); pg.wait_for_timeout(300)
    pg.evaluate("HP.start()")
    t0 = time.time()
    while time.time() - t0 < 600:
        pg.wait_for_function("PB.ready()||PB.state().over", timeout=240000, polling=50)
        st = pg.evaluate("PB.state()")
        if st['over'] or st['round'] > ROUNDS: break
        pg.evaluate("PB.act()")  # resolves once the activation and the enemy's answer have played
    pg.wait_for_timeout(1500)
    r = pg.evaluate("HP.stop()"); r['ships'] = ships; r['end'] = pg.evaluate("PB.state()"); return r

def summarise(res):
    hs = res['hitches']; res['n25'] = len(hs); res['n50'] = sum(1 for h in hs if h['dt'] > 50); res['n100'] = sum(1 for h in hs if h['dt'] > 100)
    res['worst'] = max([h['dt'] for h in hs] or [0]); tab = {}
    for h in hs:
        c = cause(h); t = tab.setdefault(c, {'n': 0, 'over': 0.0, 'worst': 0.0}); t['n'] += 1; t['over'] += h['dt'] - 16.7; t['worst'] = max(t['worst'], h['dt'])
    res['causes'] = sorted(({'cause': k, **v} for k, v in tab.items()), key=lambda x: (-x['over'], -x['n']))
    return res

def main():
    runs = []; errors = []
    args = ['--ignore-gpu-blocklist', '--enable-precise-memory-info'] + (['--enable-gpu-rasterization', '--use-angle=default'] if F.GPU else ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
    if not WARMCACHE: args += ['--disable-gpu-shader-disk-cache', '--disable-gpu-program-cache']
    with sync_playwright() as p:
        b = p.chromium.launch(headless=F.HEADLESS, args=args)
        for fix in FIXES:
            ctx = b.new_context(viewport={'width': F.W, 'height': F.H}, device_scale_factor=1); ctx.add_init_script(F.SEED_JS)
            if fix == 'off': ctx.add_init_script("window.VS_NOWARM17=1;")
            pg = ctx.new_page(); pg.set_default_timeout(240000)
            pg.on('pageerror', lambda e: errors.append('pageerror: ' + str(e)[:300]))
            pg.goto(F.PAGE.replace('?shots=1', '') if F.GPU else F.PAGE, wait_until='commit')  # the play page (no preserved buffer) on a GPU; software GL needs ?shots to skip its warning
            pg.wait_for_function("!document.getElementById('loading')&&!!document.querySelector('.title .menu')", timeout=400000, polling=500)
            pg.evaluate("setQuality(%s); 0" % json.dumps(F.Q))
            pg.click('#app [data-act=newRunScreen]'); pg.wait_for_timeout(800); pg.click('#app [data-act=startRun]'); pg.wait_for_timeout(1500)
            pg.evaluate("(()=>{ const a=document.querySelector('[data-act=pickAspect]'); if(a) a.click(); })()"); pg.wait_for_timeout(600); pg.evaluate("closeModal(); 0")
            pg.evaluate(INSTR); pg.evaluate(BOT)
            for sec in SECTORS:
                r = summarise(battle(pg, sec)); r.update({'fix': fix, 'sector': sec, 'res': '%dx%d' % (F.W, F.H)}); runs.append(r)
                print('\n%s  sector %d  fix %-3s  ships %d+%d  rounds %s  %.0f fps  %d frames over %g ms (%d over 50, %d over 100, worst %.0f ms)  JS alloc %.1f MB/s  warm %s'
                      % (r['res'], sec, fix, r['ships']['p'], r['ships']['e'], r['end']['round'], r['fps'], r['n25'], HITCH, r['n50'], r['n100'], r['worst'], r['allocMBs'],
                         json.dumps({k: r['warm'].get(k) for k in ('ms', 'late', 'notReady', 'dmgMats', 'dmgLate')}) if r['warm'] else '-'))
                print('   %-44s %6s %10s %9s' % ('cause', 'count', 'extra ms', 'worst'))
                for c in r['causes'][:12]: print('   %-44s %6d %10.0f %9.0f' % (c['cause'][:44], c['n'], c['over'], c['worst']))
                sys.stdout.flush()
            ctx.close()
        b.close()
    F.srv.shutdown()
    json.dump({'runs': runs, 'errors': errors, 'renderer': runs[0]['renderer'] if runs else None}, open('hitchprobe.json', 'w'), indent=1)
    if runs: print('\nrenderer:', runs[0]['renderer'])
    if errors: print('ERRORS:', errors[:5]); sys.exit(1)

if __name__ == '__main__': main()
