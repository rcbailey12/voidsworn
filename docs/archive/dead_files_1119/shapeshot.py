# Organic battlefields from the default phone camera: one shot per new board shape.
import os
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
SH=os.environ.get('SHAPES','deadstar,rift,shoals,hourglass,archipelago,open').split(',')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    for i,sh in enumerate(SH):
        pg.evaluate(f"setQuality('medium'); G.engine.setHardwareScalingLevel(1.4); ACT.c3skirmish(); setupBattle({{obj:'rout',shape:'{sh}',map:'random'}}); ACT.begin(); 0")
        pg.wait_for_function("!!B&&B.side==='player'&&!B.busy&&!document.getElementById('loading')", timeout=120000, polling=500)
        pg.evaluate("document.querySelectorAll('.intro,.tipcard').forEach(e=>e.remove()); document.body.classList.remove('intro-on'); try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} G.cine=false; G.ctl.reset(); 0")
        pg.wait_for_timeout(1500); pg.evaluate("G.ctl.establish(); 0"); pg.wait_for_timeout(700); pg.screenshot(path=OUT+f'/shape_{sh}_wide.png'); pg.wait_for_timeout(3500); pg.screenshot(path=OUT+f'/shape_{sh}.png'); print(sh, pg.evaluate("B.shape+' '+B.map.map+' hexes '+boardHexes().length"))
    print('errors',errs)
