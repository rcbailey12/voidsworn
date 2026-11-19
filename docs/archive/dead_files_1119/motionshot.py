# Screenshots of the hyperspace arrival and of a ship mid-burn, camera on the action.
import os
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(1.4); ACT.c3skirmish(); setupBattle({small:true,obj:'rout',shape:'open',map:'storm'}); ACT.begin(); 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy&&!document.getElementById('loading')", timeout=120000, polling=500)
    pg.evaluate("document.querySelectorAll('.intro,.tipcard').forEach(e=>e.remove()); document.body.classList.remove('intro-on'); try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} G.cine=false; 0")
    # replay the arrival with the camera on the player fleet
    pg.evaluate("(()=>{ const ps=caps('player'); const c=ps.reduce((a,u)=>a.add(hexWorld(u.q,u.r,0)),new V3(0,0,0)).scale(1/ps.length); G.ctl.focus(c,150); G.ctl.b=.9; disposeAllViews(); for(const u of B.units) u.arrived=false; G.jumpUntil=G.time+.6; })()")
    for i,ms in enumerate([350,500,900]):
        pg.wait_for_timeout(ms); pg.screenshot(path=OUT+f'/mo_arrive{i}.png')
    pg.wait_for_timeout(1500)
    pg.evaluate("""(()=>{ const s=pendingP().find(u=>!u.isSq&&u.size>.6)||pendingP().find(u=>!u.isSq); const {states}=computeReach(s); const st=states.filter(x=>x.path.length>=3).sort((a,b)=>b.path.length-a.path.length)[0]||states[0];
      const P=hexWorld(s.q,s.r,0), Q=hexWorld(st.q,st.r,0); G.ctl.focus(P.add(Q.subtract(P).scale(.5)),95); G.ctl.b=.75; SPEED=2.5; selectUnit(s); moveUnit(s,st); })()""")
    for i,ms in enumerate([700,700,700]):
        pg.wait_for_timeout(ms); pg.screenshot(path=OUT+f'/mo_burn{i}.png')
    print('errors',errs)
