# Mid-battle event in the browser: warned in round 2, enemy reinforcement arrives in round 3 with a 3D view; faction sky tint applied.
import os, json
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; BOT=open(HERE+'/tbot3.js').read(); SHOT=os.environ.get('SHOT')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':915},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate(BOT+"; window.altRound=altRound; 0")
    pg.evaluate("G.engine.setHardwareScalingLevel(5); ACT.c3skirmish(); setupBattle({small:true,obj:'rout',shape:'open',ef:'corsair'}); ACT.begin(); SPEED=.1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); B.event=rollBattleEvent(B.cfg,'reinf_enemy'); B.event.r=3; 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=90000, polling=500)
    sky=pg.evaluate("(()=>{ const c=G.skyMat._colors3&&G.skyMat._colors3.c1; return c?[+c.r.toFixed(2),+c.g.toFixed(2),+c.b.toFixed(2)]:null; })()")
    res=[]
    for k in range(2):
        res.append(pg.evaluate("altRound()"))
        if res[-1]!='r2': break
    st=pg.evaluate("(()=>{ const u=B&&B.units.find(x=>x.reinf); return {round:B&&B.round, warned:!!(B&&B.event&&B.event.warned), done:!!(B&&B.event&&B.event.done), reinf:u?{name:u.name,dead:u.dead,view:G.views.has(u.id)||u.dead}:null, log:B?B.log.slice(-12).map(l=>l.m).filter(m=>/reinforcement|warp/i.test(m)):[]}; })()")
    if SHOT: pg.screenshot(path=SHOT)
    print('sky c1 (corsair biome):',sky); print('rounds',res); print(json.dumps(st))
    exp=pg.evaluate('BIOMES.corsair[0][0]*1.45'); ok=st['warned'] and st['done'] and st['reinf'] and st['reinf']['view'] and not errs and sky and abs(sky[0]-exp)<.01
    print('EVTEST','PASSED' if ok else 'FAILED', errs)
