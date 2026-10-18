# Phone camera: the game never zooms on its own, and hands your view back after each enemy move
import time,json
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    pg=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True).new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto('file:///home/claude/v3d/index_test.html', wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(4); G.cine=false; G.follow=true; ACT.c3skirmish(); setupBattle({obj:'rout',shape:'open',map:'belt',alt:true}); ACT.begin(); 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy&&!document.getElementById('loading')", timeout=120000, polling=500)
    pg.evaluate("document.querySelectorAll('.intro,.tipcard').forEach(e=>e.remove()); 0"); time.sleep(2)
    res=[]
    for i in range(3):
        before=pg.evaluate("(()=>{ G.ctl.r=320; return JSON.stringify({r:G.ctl.r,t:[Math.round(G.ctl.t.x),Math.round(G.ctl.t.z)]}); })()")
        pg.evaluate("ACT.endTurn(); 0"); time.sleep(1)
        pg.wait_for_function("!!B&&(B.over||(B.side==='player'&&!B.busy))", timeout=120000, polling=300); time.sleep(.6)
        after=pg.evaluate("JSON.stringify({r:Math.round(G.ctl.r),t:[Math.round(G.ctl.t.x),Math.round(G.ctl.t.z)],alt:B.alt,round:B.round})")
        res.append((json.loads(before),json.loads(after)))
    ok=all(a['r']==320 for _,a in res)
    print('zoom kept at 320 after every enemy move:',ok, res)
    print('errors',errs[:3])
