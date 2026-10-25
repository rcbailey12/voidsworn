# B2 real-browser pace check: plays campaign-sized battles (sector 1, 2 and 3 fleets, enemies from the size ramp) with your side passing
# every activation, and times what you wait through each round: enemy activations, wing phases and the round banner. Runs each sector
# at the new pace and at the pre-B2 pace (PACE values put back in the page), so the two are measured on the same machine.
# Your own ships' moves and shots are not in these numbers (sim3d.js's model covers them).
#
# Run:  python3 pacecheck.py          (prints a table and writes pacecheck.json; about 4 to 8 minutes on the PC)
# Env:  ROUNDS=4  SECTORS=1,2,3  PACES=new,old  Q=high   (W, H, GPU, PAGEFILE, HEADLESS as in fxshot.py)
import os, sys, json, time
os.environ.setdefault('OUT', 'pacecheck')
import fxshot as F
from playwright.sync_api import sync_playwright

ROUNDS = int(os.environ.get('ROUNDS', '4'))
SECTORS = [int(x) for x in os.environ.get('SECTORS', '1,2,3').split(',')]
PACES = os.environ.get('PACES', 'new,old').split(',')
OLD = {'move': 1, 'rot': .75, 'enemy': .65, 'tail': .65, 'swarm': 1, 'banner': 520, 'aiGap': 60, 'aiEnd': 120, 'volley': 1, 'bigMin': 1}

JS = r"""
window.PC=(()=>{ const P={}, NEW=Object.assign({},PACE), FLEET={1:['penitent','harrow','warden','warden'],2:['cathedral','penitent','harrow','warden','warden'],3:['ascendant','cathedral','penitent','reliquary','harrow']};
  P.start=(sec,pace)=>{ Object.assign(PACE,pace==='old'?%s:NEW); try{ hideApp(); }catch(e){} setupBattle({alt:true,small:false,obj:'rout',shape:'open',map:'open',dep:'line',arena:'strip',pf:'voidsworn',ef:'hegemony'});
    disposeAllViews(); clearOverlays(); RUN.sector=sec; RUN.cpCap=40; RUN.fleet=FLEET[sec].map(t=>newShip(t,true)); startBattle({kind:'battle',fac:'hegemony',col:3,obj:'rout',dep:'line'}); prepBattle(); B.alt=true;
    try{ showIntro(); }catch(e){} try{ ACT.begin(); }catch(e){} try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} document.querySelectorAll('.tipcard,.intro').forEach(e=>e.remove()); document.body.classList.remove('intro-on');
    return {p:B.units.filter(u=>u.side==='player'&&!u.isSq).length,e:B.units.filter(u=>u.side==='enemy'&&!u.isSq).length}; };
  P.ready=()=>!!B&&!B.over&&B.side==='player'&&!B.busy;
  P.pass=()=>{ endActivation(true); return true; };
  P.state=()=>({round:B?B.round:0,over:B?B.over:true});
  return P; })();
""" % json.dumps(OLD)

def main():
    rows = []; errors = []
    with sync_playwright() as p:
        args = ['--ignore-gpu-blocklist'] + (['--enable-gpu-rasterization', '--use-angle=default'] if F.GPU else ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        b = p.chromium.launch(headless=F.HEADLESS, args=args)
        ctx = b.new_context(viewport={'width': F.W, 'height': F.H}, device_scale_factor=1); ctx.add_init_script(F.SEED_JS)
        pg = ctx.new_page()
        pg.on('pageerror', lambda e: errors.append('pageerror: ' + str(e)[:300]))
        pg.goto(F.PAGE, wait_until='commit')
        pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=400000, polling=500)
        pg.evaluate(F.LIB); pg.evaluate(JS); pg.evaluate("FXS.css(); setQuality(%s); 0" % json.dumps(F.Q))
        for sec in SECTORS:
            for pace in PACES:
                ships = pg.evaluate("PC.start(%d,%s)" % (sec, json.dumps(pace))); pg.wait_for_timeout(2500)
                times = []
                while len(times) < ROUNDS:
                    pg.wait_for_function("PC.ready()||PC.state().over", timeout=180000, polling=50)
                    if pg.evaluate("PC.state().over"): break
                    r0 = pg.evaluate("PC.state().round"); t0 = time.time()
                    while True:  # pass every one of your activations; the clock runs until the next round is yours
                        pg.evaluate("PC.pass()")
                        pg.wait_for_function("PC.ready()||PC.state().over", timeout=180000, polling=50)
                        st = pg.evaluate("PC.state()")
                        if st['over'] or st['round'] > r0: break
                    times.append(round(time.time() - t0, 2))
                avg = round(sum(times) / max(1, len(times)), 2)
                rows.append({'sector': sec, 'pace': pace, 'ships': ships, 'rounds': times, 'avg': avg, 'max': max(times) if times else None})
                print('sector %d %-3s ships %d+%d  enemy-side wait per round: avg %.1fs  max %.1fs  %s' % (sec, pace, ships['p'], ships['e'], avg, max(times) if times else 0, times)); sys.stdout.flush()
        ctx.close(); b.close()
    F.srv.shutdown()
    json.dump({'rows': rows, 'errors': errors}, open('pacecheck.json', 'w'), indent=1)
    if errors: print('ERRORS:', errors[:5]); sys.exit(1)

if __name__ == '__main__': main()
