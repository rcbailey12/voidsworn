import os, sys
from playwright.sync_api import sync_playwright
PAGE='file://'+os.path.dirname(os.path.abspath(__file__))+'/index_test.html'
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:160]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    for m in ['storm','graveyard']:
        pg.evaluate("G.engine.setHardwareScalingLevel(5); ACT.c3skirmish(); SETUP.obj='rout'; setupBattle({small:true,map:'%s'}); ACT.begin(); SPEED=.1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0"%m)
        pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=60000, polling=500)
        pg.wait_for_timeout(1500)
        r=pg.evaluate("""(()=>{const L=document.getElementById('terrlegend'); const tints=G.scene.meshes.filter(x=>/^tint/.test(x.name)).map(x=>x.name);
          const k=Object.entries(B.terrain).find(([h,t])=>TERRAIN_INFO[t]&&!['rock','hulk','station','planet'].includes(t));
          let tip=''; if(k){ const [q,r]=k[0].split(',').map(Number); const s0=B.sel; B.sel=null; B.hover={q,r}; try{ tip=boardTip()||'' }catch(e){ tip='ERR '+e.message } B.sel=s0; B.hover=null; }
          return {map:B.map.map, present:terrainPresent(), legend:L?L.innerText.slice(0,120):null, legendVis:L?getComputedStyle(L).display:null, tints, hex:k&&k[0], tip:String(tip).replace(/<[^>]+>/g,' ').slice(0,200)};})()""")
        print(r)
        pg.screenshot(path='/tmp/claude-0/-home-claude/a7f9f213-93ba-5f18-ae19-8b902b42faaf/scratchpad/terr_%s.png'%m)
        if pg.evaluate("!!document.getElementById('terrlegend')"):
            pg.evaluate("ACT.legend&&ACT.legend(); 0"); pg.wait_for_timeout(500)
            print('expanded:', pg.evaluate("document.getElementById('terrlegend').innerText.slice(0,300)"))
            pg.screenshot(path='/tmp/claude-0/-home-claude/a7f9f213-93ba-5f18-ae19-8b902b42faaf/scratchpad/terr_%s_open.png'%m)
            pg.evaluate("ACT.legend&&ACT.legend(); 0")
        print('draw', pg.evaluate("G.engine._drawCalls?G.engine._drawCalls.current:(G.scene.getActiveMeshes().length)"))
        pg.evaluate("if(typeof disposeAllViews==='function'){} ; 0")
    print('errors', errs)
