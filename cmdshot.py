# Command panel wording at phone size, round 3 (power 2 of 3).
import os
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(4); newRun('reyes','hegemony'); RUN.fleet=['h_vanguard','h_dominion'].map(t=>newShip(t,true)); battleScreen({kind:'battle',fac:'corsair',col:2}); 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500)
    pg.evaluate("document.querySelectorAll('.intro,.tipcard').forEach(e=>e.remove()); document.body.classList.remove('intro-on','sheetmin'); B.round=3; selectUnit(pendingP()[0]); bRefresh(); 0")
    pg.wait_for_timeout(800); el=pg.locator('#panel .sect [data-act=command]').first; el.scroll_into_view_if_needed(); pg.wait_for_timeout(300)
    print(el.inner_text()); pg.screenshot(path=OUT+'/cmdpanel.png'); print('errors',errs)
