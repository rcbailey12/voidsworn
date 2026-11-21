import time, json, os
from playwright.sync_api import sync_playwright
PAGE='file://'+os.path.dirname(os.path.abspath(__file__))+'/index_test.html'
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); ctx.grant_permissions(['clipboard-read','clipboard-write']); pg=ctx.new_page(); errs=[]
    pg.on('pageerror',lambda e: errs.append(str(e)[:160]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    print('session:',pg.evaluate("JSON.stringify((META.tel||[]).filter(e=>e.ev==='session').slice(-1)[0])"))
    pg.evaluate("G.engine.setHardwareScalingLevel(4); document.querySelector('#app [data-act=newRunScreen]').click()"); time.sleep(1); pg.evaluate("document.querySelector('#app [data-act=startRun]').click()"); time.sleep(3); pg.evaluate("(()=>{ const a=document.querySelector('[data-act=pickAspect]'); if(a) a.click(); })()"); time.sleep(1); pg.evaluate("closeModal&&closeModal()")
    pg.evaluate("(()=>{ const el=document.querySelector('#app .node.avail'); (el.closest('[data-act]')||el).dispatchEvent(new MouseEvent('click',{bubbles:true})); })()")
    pg.wait_for_function("!!(B&&B.campaign)", timeout=90000, polling=1000)
    start=pg.evaluate("JSON.stringify((META.tel||[]).filter(e=>e.ev==='battle_start').slice(-1)[0])"); print('battle_start before reload:',start[:220])
    t0=json.loads(start)['t']
    pg.reload(wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    print('battle_start survives a mid-battle reload:',pg.evaluate(f"(META.tel||[]).some(e=>e.ev==='battle_start'&&e.t==={t0})"))
    pg.evaluate("ACT.copyReport()"); time.sleep(1.5)
    try: txt=pg.evaluate("navigator.clipboard.readText()")
    except Exception: txt=''
    if not txt.startswith('{'): txt=pg.evaluate("(document.querySelector('.modal textarea')||{}).value||''")
    r=json.loads(txt); print('copy report: valid JSON,',round(len(txt)/1024,1),'KB, build',r['build'],', events',len(r['events']))
    print('errors:',errs[:3]); b.close()
