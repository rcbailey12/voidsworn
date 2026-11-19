# Visual check of merged ships: close-up screenshot, then kill one and screenshot the break-apart; graveyard wrecks.
import os, time
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':900,'height':600}); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(1.5); ACT.c3skirmish(); setupBattle({small:true,obj:'rout',shape:'open',map:'graveyard'}); ACT.begin(); SPEED=.3; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); document.querySelectorAll('.tipcard,#panel,#roster,#log,#btop').forEach(e=>e.style.display='none'); 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500)
    pg.evaluate("const u=alive('player')[0], v=G.views.get(u.id); G.ctl.focusOn? G.ctl.focusOn(v.root.position): 0; G.ctl.target&&G.ctl.target.copyFrom(v.root.position); G.ctl.r=v.L*2.2; G.ctl.b=.75; 0"); pg.wait_for_timeout(4000)
    pg.screenshot(path=OUT+'/ship_close.png', timeout=180000)
    pg.evaluate("G.ctl.r=260; G.ctl.b=.95; 0"); pg.wait_for_timeout(3000); pg.screenshot(path=OUT+'/ship_wide.png', timeout=180000)
    pg.evaluate("window.__k=(async()=>{ const u=alive('enemy')[0]; const v=G.views.get(u.id); G.ctl.target&&G.ctl.target.copyFrom(v.root.position); G.ctl.r=v.L*3; await new Promise(r=>setTimeout(r,1500)); u.hp=0; await killUnit(u,null); return 'killed'; })(); 0")
    pg.wait_for_timeout(6000); pg.screenshot(path=OUT+'/ship_death.png', timeout=180000)
    print('hulks',pg.evaluate("G.hulks.length"),'errors',errs)
