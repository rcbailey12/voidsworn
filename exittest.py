# Breakthrough: ships that reach the exit leave the board, the battle is won once enough are out,
# and the campaign keeps those ships (they are survivors, not losses).
import os, json
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(5); ACT.c3skirmish(); setupBattle({obj:'break',shape:'open',small:true}); ACT.begin(); SPEED=.1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=90000, polling=500)
    n0=pg.evaluate("RUN.fleet.length"); need=pg.evaluate("B.obj.need")
    for k in range(need):
        pg.wait_for_function("!!B&&B.side==='player'&&!B.busy&&pendingP().length>0", timeout=120000, polling=500)
        r=pg.evaluate("""(async()=>{ const u=pendingP()[0]; const occ=occMap();
          const spot=boardHexes().find(h=>h.q+Math.floor(h.r/2)===B.obj.exitC-2&&!blocks(terr(h.q,h.r))&&!occ.has(hkey(h.q,h.r)));
          u.q=spot.q; u.r=spot.r; u.mp=Math.max(u.mp,2); selectUnit(u);
          const st=computeReach(u).states.find(s=>objZone(s.q,s.r)==='exit'&&!occMap().has(hkey(s.q,s.r)));
          if(!st) return 'no exit state'; guard(u); await act(()=>moveUnit(u,st)); return {name:u.name, exited:!!u.exited, out:B.obj.out, over:B.over}; })()""")
        print('move',k,r)
    pg.wait_for_function("!!document.getElementById('endcard')", timeout=120000, polling=500)
    card=pg.evaluate("document.getElementById('endcard').innerText.replace(/\\s+/g,' ')")
    print('endcard:',card)
    pg.evaluate("ACT.c3continue(); 0"); pg.wait_for_timeout(1500)
    n1=pg.evaluate("RUN.fleet.length")
    print('fleet before',n0,'after',n1,'| errors',errs)
    ok=n1==n0 and 'Victory' in card and 'Lost' not in card and not errs
    print('EXITTEST','PASSED' if ok else 'FAILED')
