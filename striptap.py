import time, os
from playwright.sync_api import sync_playwright
PAGE='file://'+os.path.dirname(os.path.abspath(__file__))+'/index_test.html'
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:120]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(5); ACT.c3skirmish(); SETUP.obj='rout'; setupBattle({small:true}); ACT.begin(); SPEED=.1; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy&&!document.getElementById('loading')", timeout=60000, polling=500)
    pg.evaluate("(()=>{ const s=pendingP().find(u=>!u.isSq); selectUnit(s); window.__s=s; G.ctl.t=G.ctl.t.add(new BABYLON.Vector3(90,0,90)); bRefresh(); })()"); time.sleep(.5)
    def tap(label):
        el=pg.locator('#panel .actstrip button',has_text=label).first; el.tap(); time.sleep(1.2)
    tap('Center'); print('Center tap refocuses camera:',pg.evaluate("(()=>{ const w=uWorld(window.__s); return Math.hypot(G.ctl.t.x-w.x,G.ctl.t.z-w.z)<15; })()"))
    tap('Brace'); time.sleep(1); print('Brace tap braces ship:',pg.evaluate("!!window.__s.braced"))
    pg.wait_for_function("B.side==='player'&&!B.busy&&pendingP().some(u=>!u.isSq)", timeout=300000, polling=500) # the enemy answers the brace first; with wings in flight that takes a while on a software renderer
    pg.evaluate("(()=>{ const s=pendingP().find(u=>!u.isSq); if(s){ selectUnit(s); window.__s2=s; } bRefresh(); })()"); time.sleep(.5)
    n0=pg.evaluate("pendingP().length"); tap('Done with ship'); time.sleep(2)
    print('Done tap ends activation:',pg.evaluate("window.__s2.activated||B.side==='enemy'"),'(ready before',n0,')')
    print('errors:',errs[:3]); b.close()
