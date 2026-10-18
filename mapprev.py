# Sector map shows encounter names on fight nodes and readable preview cards for the reachable ones (phone viewport).
import os, time
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; SHOT=os.environ.get('SHOT')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(5); 0")
    pg.click('#app [data-act=newRunScreen]'); time.sleep(1); pg.click('#app [data-act=startRun]'); time.sleep(2); pg.evaluate("(()=>{ const a=document.querySelector('[data-act=pickAspect]'); if(a) a.click(); })()"); time.sleep(1)
    # jump past column 0 so the reachable nodes carry varied encounters
    pg.evaluate("RUN.map.cols[0][0].done=true; RUN.pos=RUN.map.cols[0][0].id; mapScreen(); 0"); time.sleep(1)
    r=pg.evaluate("""(()=>({labels:[...document.querySelectorAll('#app svg text')].map(t=>t.textContent).filter(t=>t!=='?'),
       cards:[...document.querySelectorAll('.encprev>div')].map(d=>d.innerText.replace(/\\s+/g,' ').slice(0,90)),
       encs:RUN.map.cols.flat().filter(n=>n.type==='battle'||n.type==='elite').map(n=>n.enc+'/'+n.shape)}))()""")
    print(r)
    if SHOT: pg.screenshot(path=SHOT, full_page=True)
    ok=len(r['cards'])>0 and len(r['labels'])>0 and all(not e.startswith('undefined') for e in r['encs']) and not errs
    print('MAPPREV', 'PASSED' if ok else 'FAILED', errs)
