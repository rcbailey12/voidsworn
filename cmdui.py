import time, os
from playwright.sync_api import sync_playwright
PAGE='file://'+os.path.dirname(os.path.abspath(__file__))+'/index_test.html'
STATE="""(()=>{ const b=[...document.querySelectorAll('#panel .actstrip button.cmd')][0]; return JSON.stringify({round:B.round,top:document.getElementById('resolvelbl').textContent,btn:b?b.textContent.trim():'(none)',enabled:b?!b.disabled:false,
  targeting:!!document.querySelector('#panel .sect h4')&&[...document.querySelectorAll('#panel .sect h4')].some(h=>/Targeting|^Order/.test(h.textContent))}); })()"""
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:120]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.cmdConfirmMs=120000; G.engine.setHardwareScalingLevel(5); document.querySelector('#app [data-act=newRunScreen]').click()"); time.sleep(1); pg.evaluate("document.querySelector('#app [data-act=startRun]').click()"); time.sleep(3); pg.evaluate("(()=>{ const a=document.querySelector('[data-act=pickAspect]'); if(a) a.click(); })()"); time.sleep(1); pg.evaluate("closeModal&&closeModal(); 0")
    pg.evaluate("(()=>{ const el=document.querySelector('#app .node.avail'); (el.closest('[data-act]')||el).dispatchEvent(new MouseEvent('click',{bubbles:true})); })()")
    pg.wait_for_function("!!(B&&B.campaign)&&B.side==='player'&&!B.busy", timeout=90000, polling=1000); time.sleep(2)
    pg.evaluate("(()=>{ B.units.forEach(u=>{ if(u.fx) u.fx.cmdTier=0; }); const s=pendingP()[0]; selectUnit(s); document.body.classList.remove('sheetmin'); bRefresh(); })()"); time.sleep(.5)
    print('round 1 :',pg.evaluate(STATE))
    pg.evaluate("B.round=2; bRefresh(); 0"); time.sleep(.5); print('round 2 :',pg.evaluate(STATE))
    pg.evaluate("B.round=3; bRefresh(); 0"); time.sleep(.5); print('round 3 :',pg.evaluate(STATE))
    pg.locator('#panel .actstrip button.cmd').first.tap(); time.sleep(.6); print('armed   :',pg.evaluate(STATE),'used after one tap =',pg.evaluate("!!B.cmdUsed"))
    pg.locator('#panel .actstrip button.cmd').first.tap(); pg.wait_for_function("B.cmdUsed&&!B.busy", timeout=90000, polling=500); time.sleep(1)
    pg.evaluate("(()=>{ const s=alive('player').find(u=>!u.isSq); if(s) selectUnit(s); bRefresh(); })()"); print('after use:',pg.evaluate(STATE))
    print('errors:',errs[:3]); b.close()
