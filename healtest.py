# A see-through mesh with broken bounding data (the error that froze Ryan's screen) must not stop rendering:
# the renderer finds it, repairs or hides it, records it, and keeps drawing.
import os, time
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page()
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(5); ACT.c3skirmish(); setupBattle({small:true}); ACT.begin(); SPEED=.1; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=90000, polling=500)
    pg.evaluate("""(()=>{ const src=BABYLON.MeshBuilder.CreateBox('brokenSrc',{size:4},G.scene); const m=new BABYLON.StandardMaterial('brokenM',G.scene); m.alpha=.5; src.material=m; src.position.copyFrom(G.ctl.t); src.position.y=3;
        const inst=src.createInstance('brokenInst'); inst.position.copyFrom(src.position); inst.position.x+=6; src.getBoundingInfo=()=>undefined; /* same failure Ryan's phone hit: a see-through mesh with no bounding data, every frame */ window.__e0=(META.tel||[]).filter(e=>e.ev==='error').length; window.__t0=G.time; })(); 0""")
    time.sleep(8)
    pg.evaluate("window.__t1=G.time; 0"); time.sleep(6)
    r=pg.evaluate("({heal:(META.tel||[]).filter(e=>e.ev==='scene_heal').map(e=>e.meshes), errs:(META.tel||[]).filter(e=>e.ev==='error').length-window.__e0, advancing:G.time>window.__t1+0.05, renderOk:(()=>{ try{ G.scene.render(); return true; }catch(e){ return 'still failing: '+e.message; } })()})")
    print(r)
    ok=bool(r['heal']) and r['renderOk'] is True and r['advancing']
    print('HEALTEST','PASSED' if ok else 'FAILED')
