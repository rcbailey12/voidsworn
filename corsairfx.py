# A1 step 4 probe: the Pyre-Barge (c_boss, Corsair) effects, staged and captured like fxshot.py (same page, server, seeding and clock).
# Shows: dirty engines (coughs and soot), ragged muzzle flashes next to a clean Hegemony gun, the light (under 66%) and heavy (under 33%)
# damage looks with the donor panel, and the break-up on death.
#
# Run:  python3 corsairfx.py             (writes corsairfx/CFX_<scene>_<n>_t<ms>.png and corsairfx/index.html)
# Env:  OUT=dir  ONLY=engines,muzzle,clean,light,heavy,death   Q=ultra|high|medium   GPU=auto|1|0   SEED=7   HEADLESS=0 to watch
#       (W, H, SCALE, PAGEFILE, REDUCE work as in fxshot.py)
import os, sys, json, time, html, datetime
os.environ.setdefault('OUT', 'corsairfx')
import fxshot as F
from playwright.sync_api import sync_playwright

OUT = F.OUT; ONLY = F.ONLY
def want(n): return not ONLY or n in ONLY

PROBE = r"""
window.CFX=(()=>{ const S=FXS, C={};
  // the barge with a Hegemony ship to shoot at; the camera sits off the barge's stern quarter (view 'stern') or frames both ships ('pair')
  const gunIx=u=>{ const i=u.weapons.findIndex(w=>w.k!=='torp'&&w.k!=='flak'&&w.k!=='lance'&&(w.arc==='F'||w.arc==='T')); return i<0?u.weapons.findIndex(w=>w.k!=='torp'&&w.k!=='flak'&&w.k!=='lance'):i; };
  C.stage=(view,tgtTpl,atk)=>{ S.clear(); const A=atk||{tpl:'c_boss',fac:'corsair'}, [ha,hb]=S.pair(5), a=S.place(A.tpl,A.fac,ha,'player'), t=S.place(tgtTpl||'h_vanguard',A.fac==='hegemony'?'voidsworn':'hegemony',hb,'enemy');
    S.face(a,S.angTo(a,t)); S.face(t,S.angTo(t,a)+90); S.settle(14); a.hp=a.maxHp; t.hp=t.maxHp; t.sh=[0,0,0,0];
    const wi=A.wi!=null?A.wi:gunIx(a); window.__st={a:a.id,t:t.id,wi:wi<0?0:wi};
    const pa=S.V(a.id).root.getAbsolutePosition(), pb=S.V(t.id).root.getAbsolutePosition(), L=S.V(a.id).L, ang=Math.atan2(pb.z-pa.z,pb.x-pa.x);
    S.calm(); if(view==='stern') S.cam(pa,L*1.25+10,-ang+Math.PI/2+.55,1.05); else if(view==='close') S.cam(pa,L*1.1+12,-ang-Math.PI/2+.7,1.0); else { const m=pa.add(pb).scale(.5); S.cam(m,V3.Distance(pa,pb)+26,-ang-Math.PI/2+.35,1.02); }
    return {barge:a.id,L:Math.round(L),gun:a.weapons[window.__st.wi].id}; };
  // the same gun family fired by a Hegemony ship, for a clean side-by-side
  C.stageClean=()=>{ const bu=makeUnit('player','c_boss',{fac:'corsair'}); bu.fac='corsair'; const fam=wFamily(bu,bu.weapons[gunIx(bu)],'corsair');
    for(const [id,h] of Object.entries(HULLS)){ if(h.fac!=='hegemony'||h.boss||h.cls==='Squadron') continue; let u; try{ u=makeUnit('player',id,{fac:'hegemony'}); u.fac='hegemony'; }catch(e){ continue; }
      const wi=u.weapons.findIndex(w=>wFamily(u,w,'hegemony')===fam&&(w.arc==='F'||w.arc==='T')); if(wi>=0) return Object.assign({fam,clean:id},C.stage('close',null,{tpl:id,fac:'hegemony',wi})); }
    return {err:'no Hegemony hull carries '+fam}; };
  C.fire=()=>{ const st=window.__st, u=S.U(st.a), t=S.U(st.t), w=u.weapons[st.wi]; window.__fx=(async()=>{ try{ await animWeapon(u,w,t,[true,true,true]); }catch(e){ window.__fxErr=String(e&&e.stack||e); } })(); return w.id; };
  C.hurt=frac=>{ const u=S.U(window.__st.a); u.hp=Math.max(1,Math.round(u.maxHp*frac)); return u.hp; };
  C.kill=()=>{ const u=S.U(window.__st.a); u.killCause='blast'; u.dead=true; window.__fx=(async()=>{ try{ await animExplode(u); }catch(e){ window.__fxErr=String(e&&e.stack||e); } })(); return true; };
  C.idle=()=>true;
  C.coughs=()=>{ const v=S.V(window.__st.a); return v&&v.cough?{until:+v.cough.until.toFixed(2),k:+v.cough.k.toFixed(2),now:+G.time.toFixed(2)}:null; };
  return C; })();
"""

SCENES = [  # name, stage call, trigger, capture times (ms after the trigger)
    ('engines', "CFX.stage('stern')", "CFX.idle()", [0, 200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2400, 2800, 3200, 3600, 4000]),
    ('muzzle', "CFX.stage('close')", "CFX.fire()", [20, 60, 110, 170, 260, 450, 900]),
    ('clean', "CFX.stageClean()", "CFX.fire()", [20, 60, 110, 170, 260, 450, 900]),
    ('light', "CFX.stage('close')", "CFX.hurt(.6)", [0, 150, 400, 900, 1600, 2600]),
    ('heavy', "CFX.stage('close')", "CFX.hurt(.6)", None),  # steps to 60%, then 30% (see below)
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
                pg.screenshot(path=os.path.join(OUT, fn), timeout=240000); results.append({'name': name, 'ms': ms, 'file': fn, 'meta': meta, 'cough': pg.evaluate('CFX.coughs()')}); print('  shot', fn); sys.stdout.flush()
            step(600)
            if clock is not None: clock.resume()
            fe = pg.evaluate('window.__fxErr')
            if fe: errors.append(name + ': ' + fe[:300]); pg.evaluate('window.__fxErr=null')
        for name, st, trig, times in SCENES:
            if not want(name): continue
            stage[0] = name + ' stage'; meta = pg.evaluate(st); print(name, meta); sys.stdout.flush(); pg.wait_for_timeout(500)
            if name == 'heavy':
                pg.evaluate(trig); pg.wait_for_timeout(1500)
                shoot(name, [0, 150, 500, 1000, 1800, 3000, 4500], "CFX.hurt(.3)", meta)
            else:
                shoot(name, times, trig, meta)
            pg.wait_for_timeout(800)
        st = pg.evaluate("FXS.stats()"); print('pool after all scenes', st)
        ctx.close(); b.close()
    F.srv.shutdown()
    rows = ''.join('<figure><img src="%s" loading="lazy"><figcaption>%s +%dms%s</figcaption></figure>' % (r['file'], html.escape(r['name']), r['ms'], ' cough' if r['cough'] and r['cough']['until'] > r['cough']['now'] else '') for r in results)
    open(os.path.join(OUT, 'index.html'), 'w').write('<!doctype html><meta charset="utf-8"><title>Corsair FX</title><style>body{background:#111;color:#ccc;font:13px system-ui}figure{display:inline-block;margin:6px}img{width:520px;display:block}</style>' + rows)
    json.dump({'results': results, 'errors': errors, 'secs': round(time.time() - T0)}, open(os.path.join(OUT, 'corsairfx.json'), 'w'), indent=1)
    print('%d shots in %.0fs -> %s' % (len(results), time.time() - T0, OUT))
    if errors: print('ERRORS (%d):' % len(errors)); [print('  ' + e) for e in errors]; sys.exit(1)
    print('no console errors')

if __name__ == '__main__': main()
