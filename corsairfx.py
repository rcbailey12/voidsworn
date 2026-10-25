# A1 step 4 probe: the Pyre-Barge (c_boss, Corsair) effects, staged and captured like fxshot.py (same page, server, seeding and clock).
# Shows: dirty engines (coughs and soot), ragged muzzle flashes (whole ship and near the barrels) next to a non-Corsair ship firing the same
# weapon or weapon kind (the regression check), the light (under 66%) and heavy (under 33%)
# damage looks with the donor panel, and the break-up on death.
#
# Run:  python3 corsairfx.py             (writes corsairfx/CFX_<scene>_<n>_t<ms>.png and corsairfx/index.html)
# Env:  OUT=dir  ONLY=engines,muzzle,muzzle_barrel,clean,light,heavy,death   Q=ultra|high|medium   GPU=auto|1|0   SEED=7   HEADLESS=0 to watch
#       (W, H, SCALE, PAGEFILE, REDUCE work as in fxshot.py)
import os, sys, json, time, html, datetime
os.environ.setdefault('OUT', 'corsairfx')
import fxshot as F
from playwright.sync_api import sync_playwright

OUT = F.OUT; ONLY = F.ONLY
def want(n): return not ONLY or n in ONLY

PROBE = r"""
window.CFX=(()=>{ const S=FXS, C={};
  // frame a ship by its real extent: dirLocal is where the camera sits in the ship's own frame (bow is +x, up is +y), fill is the share of the
  // frame height the ship's bounding sphere takes, focusLocal (optional) shifts the aim point along the hull
  C.frame=(id,dirLocal,fill,focusLocal,radius)=>{ const v=S.V(id); if(!v||!v.root) return {err:'no view'}; v.root.computeWorldMatrix(true);
    let mn=new V3(1e9,1e9,1e9), mx=new V3(-1e9,-1e9,-1e9); for(const m of (v.model&&v.model.meshes)||[]){ if(!m.isEnabled()) continue; m.computeWorldMatrix(true); const bb=m.getBoundingInfo().boundingBox; mn=V3.Minimize(mn,bb.minimumWorld); mx=V3.Maximize(mx,bb.maximumWorld); }
    if(mn.x>1e8){ const p=v.root.getAbsolutePosition(); mn=p.subtract(new V3(v.L/2,v.H,v.L/2)); mx=p.add(new V3(v.L/2,v.H,v.L/2)); }
    const ctr=mn.add(mx).scale(.5), R=V3.Distance(mn,mx)/2, tgt=focusLocal?toWorld(v,new V3(focusLocal[0],focusLocal[1],focusLocal[2])):ctr;
    const d=(dirLocal instanceof V3?dirLocal.clone():V3.TransformNormal(new V3(dirLocal[0],dirLocal[1],dirLocal[2]),v.root.getWorldMatrix())).normalize(), fov=G.cam.fov||.8, r=radius||R/(fill*Math.tan(fov/2));
    S.cam(tgt,r,Math.atan2(d.z,d.x),Math.acos(Math.max(-1,Math.min(1,d.y)))); return {R:+R.toFixed(1),r:+r.toFixed(1)}; };
  const gunIx=u=>{ const i=u.weapons.findIndex(w=>w.k==='battery'); return i>=0?i:u.weapons.findIndex(w=>w.k!=='torp'&&w.k!=='flak'&&w.k!=='lance'); };
  const arcTurn=w=>w.arc==='P'?90:w.arc==='S'?-90:0; // broadside guns: turn the ship side-on to the target, as fxshot.py does
  C.stage=(view,atk)=>{ S.clear(); const A=atk||{tpl:'c_boss',fac:'corsair'}, [ha,hb]=S.pair(5), a=S.place(A.tpl,A.fac,ha,'player'), t=S.place('h_vanguard',A.fac==='hegemony'?'voidsworn':'hegemony',hb,'enemy');
    const wi0=A.wi!=null?A.wi:gunIx(a), wi=wi0<0?0:wi0; S.face(a,S.angTo(a,t)+arcTurn(a.weapons[wi])); S.face(t,S.angTo(t,a)+90); S.settle(14); a.hp=a.maxHp; t.hp=t.maxHp; t.sh=[0,0,0,0];
    window.__st={a:a.id,t:t.id,wi}; S.calm(); const L=S.V(a.id).L; let cam;
    if(view==='stern') cam=C.frame(a.id,[-.8,.55,.45],.6,[-L*.3,0,0]); // behind and above, on the engines
    else if(view==='barrel'){ const v=S.V(a.id), w=a.weapons[window.__st.wi], tp=S.V(t.id).root.getAbsolutePosition(), mz=muzzles(v,w.arc,tp).sort((p1,p2)=>V3.Distance(p1,tp)-V3.Distance(p2,tp))[0]||v.root.getAbsolutePosition(); const fd=tp.subtract(mz).normalize(), side=V3.Cross(fd,V3.Up()).normalize(), dir=side.scale(.85).add(V3.Up().scale(.55)).add(fd.scale(.25)).normalize(); S.cam(mz.add(fd.scale(3)),14,Math.atan2(dir.z,dir.x),Math.acos(dir.y)); cam={r:14}; }
    else if(view==='pair'){ const pa=S.V(a.id).root.getAbsolutePosition(), pb=S.V(t.id).root.getAbsolutePosition(), m=pa.add(pb).scale(.5), ang=Math.atan2(pb.z-pa.z,pb.x-pa.x); S.cam(m,V3.Distance(pa,pb)+26,-ang-Math.PI/2+.35,1.02); cam={pair:true}; }
    else { const v=S.V(a.id), w=a.weapons[wi], ctr=v.root.getAbsolutePosition(), mz=muzzles(v,w.arc,S.V(t.id).root.getAbsolutePosition()), avg=mz.reduce((q,p)=>q.add(p),new V3(0,0,0)).scale(1/Math.max(1,mz.length)), out=avg.subtract(ctr); out.y=0;
      const fwd=V3.TransformNormal(new V3(1,0,0),v.root.getWorldMatrix()); fwd.y=0; const dir=(out.length()>.5?out.normalize():V3.Cross(fwd.normalize(),V3.Up())).add(V3.Up().scale(.6)).add(fwd.normalize().scale(.35)); cam=C.frame(a.id,dir,.62); } // three-quarter view from the side the guns are on: the whole ship and its flashes
    return {atk:A.tpl,L:Math.round(L),gun:a.weapons[window.__st.wi].id,cam}; };
  // the regression check: a non-Corsair ship firing the same weapon (or the same weapon kind), framed the same way
  C.stageClean=()=>{ const bu=makeUnit('player','c_boss',{fac:'corsair'}); bu.fac='corsair'; const bw=bu.weapons[gunIx(bu)]; const tries=[];
    for(const pref of ['hegemony','voidsworn','ithar','chorus','deathless']) for(const [id,h] of Object.entries(HULLS)){ if((h.fac||'voidsworn')!==pref||h.boss||h.cls==='Squadron') continue; let u; try{ u=makeUnit('player',id,{fac:pref}); u.fac=pref; }catch(e){ continue; }
      const same=u.weapons.findIndex(w=>w.id===bw.id), kind=u.weapons.findIndex(w=>w.k===bw.k); if(same>=0) tries.push({id,pref,wi:same,score:0}); else if(kind>=0) tries.push({id,pref,wi:kind,score:pref==='hegemony'?1:2}); }
    tries.sort((a,b)=>a.score-b.score); const pick=tries[0]; if(!pick) return {err:'no non-Corsair ship carries a '+bw.k+' weapon'};
    const r=C.stage('side',{tpl:pick.id,fac:pick.pref,wi:pick.wi}); return Object.assign(r,{clean:pick.id,cleanFac:pick.pref,match:pick.score===0?'same weapon':'same kind',bargeGun:bw.id}); };
  C.fire=()=>{ const st=window.__st, u=S.U(st.a), t=S.U(st.t), w=u.weapons[st.wi]; window.__fx=(async()=>{ try{ await animWeapon(u,w,t,[true,true,true]); }catch(e){ window.__fxErr=String(e&&e.stack||e); } })(); return w.id; };
  C.hurt=frac=>{ const u=S.U(window.__st.a); u.hp=Math.max(1,Math.round(u.maxHp*frac)); return u.hp; };
  C.kill=()=>{ const u=S.U(window.__st.a); u.killCause='blast'; u.dead=true; window.__fx=(async()=>{ try{ await animExplode(u); }catch(e){ window.__fxErr=String(e&&e.stack||e); } })(); return true; };
  C.idle=()=>true;
  C.coughs=()=>{ const v=S.V(window.__st.a); return v&&v.cough?{until:+v.cough.until.toFixed(2),k:+v.cough.k.toFixed(2),now:+G.time.toFixed(2)}:null; };
  C.panels=()=>{ const b=G.debBatches||{}; return Object.entries(b).filter(([k])=>/panel|flake/.test(k)).map(([k,x])=>k+':'+x.items.length).join(' '); };
  return C; })();
"""

SCENES = [  # name, stage call, trigger, capture times (ms after the trigger)
    ('engines', "CFX.stage('stern')", "CFX.idle()", [0, 200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2400, 2800, 3200, 3600, 4000]),
    ('muzzle', "CFX.stage('side')", "CFX.fire()", [20, 60, 110, 170, 260, 450, 900]),
    ('muzzle_barrel', "CFX.stage('barrel')", "CFX.fire()", [20, 40, 60, 90, 120, 170]),
    ('clean', "CFX.stageClean()", "CFX.fire()", [20, 60, 110, 170, 260, 450, 900]),
    ('light', "CFX.stage('side')", "CFX.hurt(.6)", [0, 150, 400, 900, 1600, 2600]),
    ('heavy', "CFX.stage('side')", "CFX.hurt(.6)", None),  # steps to 60%, then 30% (see below)
    ('death', "CFX.stage('pair')", "CFX.kill()", [150, 500, 1000, 1500, 2200, 3400, 5000]),
]

def main():
    results = []; errors = []; T0 = time.time()
    with sync_playwright() as p:
        args = ['--ignore-gpu-blocklist'] + (['--enable-gpu-rasterization', '--use-angle=default'] if F.GPU else ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        b = p.chromium.launch(headless=F.HEADLESS, args=args)
        ctx = b.new_context(viewport={'width': F.W, 'height': F.H}, device_scale_factor=1); ctx.add_init_script(F.SEED_JS)
        pg = ctx.new_page(); stage = ['boot']
        pg.on('pageerror', lambda e: errors.append('[%s] pageerror: %s' % (stage[0], str(e)[:300])))
        pg.on('console', lambda m: errors.append('[%s] console.error: %s' % (stage[0], m.text[:300])) if m.type == 'error' and 'Failed to load resource' not in m.text else None)
        clock = getattr(pg, 'clock', None)
        try: clock.install()
        except Exception: clock = None
        pg.goto(F.PAGE, wait_until='commit')
        pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=400000, polling=500)
        try: pg.wait_for_function("typeof AI_HULLS==='undefined'||Object.keys(AI_HULL_DATA).length>=Object.keys(AI_HULLS).length", timeout=180000, polling=500)
        except Exception: print('warning: not every concept hull loaded')
        pg.evaluate(F.LIB); pg.evaluate(PROBE); pg.evaluate("FXS.css(); setQuality(%s); 0" % json.dumps(F.Q))
        pg.evaluate("FXS.battle(%s)" % json.dumps({'seed': F.SEED * 101, 'reduce': os.environ.get('REDUCE') == '1'}))
        pg.wait_for_function("!!B&&B.side==='player'", timeout=120000, polling=250); pg.wait_for_timeout(1200); pg.mouse.move(2, F.H - 2)
        def step(ms):
            if clock is not None: clock.run_for(int(ms))
            else: pg.wait_for_timeout(int(ms))
        def shoot(name, times, trigger=None, meta=None):
            stage[0] = name
            if clock is not None: clock.pause_at(datetime.datetime.fromtimestamp((pg.evaluate('Date.now()') + 50) / 1000.0)); step(60)
            if trigger: pg.evaluate(trigger)
            last = 0
            for i, ms in enumerate(times):
                step(ms - last); last = ms; fn = 'CFX_%s_%d_t%d.png' % (name, i, ms)
                pg.screenshot(path=os.path.join(OUT, fn), timeout=240000); results.append({'name': name, 'ms': ms, 'file': fn, 'meta': meta, 'cough': pg.evaluate('CFX.coughs()'), 'debris': pg.evaluate('CFX.panels()')}); print('  shot', fn); sys.stdout.flush()
            step(600)
            if clock is not None: clock.resume()
            fe = pg.evaluate('window.__fxErr')
            if fe: errors.append(name + ': ' + fe[:300]); pg.evaluate('window.__fxErr=null')
        for name, st, trig, times in SCENES:
            if not want(name): continue
            stage[0] = name + ' stage'; meta = pg.evaluate(st); print(name, meta); sys.stdout.flush(); pg.wait_for_timeout(500)
            if meta.get('err'): errors.append(name + ': ' + meta['err']); continue
            if name == 'heavy':
                pg.evaluate(trig); pg.wait_for_timeout(1500)
                shoot(name, [0, 150, 500, 1000, 1800, 3000, 4500], "CFX.hurt(.3)", meta)
            else:
                shoot(name, times, trig, meta)
            pg.wait_for_timeout(800)
        st = pg.evaluate("FXS.stats()"); print('pool after all scenes', st)
        ctx.close(); b.close()
    F.srv.shutdown()
    rows = ''.join('<figure><img src="%s" loading="lazy"><figcaption>%s +%dms%s %s</figcaption></figure>' % (r['file'], html.escape(r['name']), r['ms'], ' cough' if r['cough'] and r['cough']['until'] > r['cough']['now'] else '', html.escape(r.get('debris') or '')) for r in results)
    open(os.path.join(OUT, 'index.html'), 'w').write('<!doctype html><meta charset="utf-8"><title>Corsair FX</title><style>body{background:#111;color:#ccc;font:13px system-ui}figure{display:inline-block;margin:6px}img{width:520px;display:block}</style>' + rows)
    json.dump({'results': results, 'errors': errors, 'secs': round(time.time() - T0)}, open(os.path.join(OUT, 'corsairfx.json'), 'w'), indent=1)
    print('%d shots in %.0fs -> %s' % (len(results), time.time() - T0, OUT))
    if errors: print('ERRORS (%d):' % len(errors)); [print('  ' + e) for e in errors]; sys.exit(1)
    print('no console errors')

if __name__ == '__main__': main()
