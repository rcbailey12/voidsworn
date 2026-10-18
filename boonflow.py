# Patrons end to end on a phone: run start -> flagship aspect -> map with patron sigils -> win a boon battle -> boon offer -> pick -> boons listed.
import os, json
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(4); SAVED_RUN=null; ACT.pickFaction('ithar'); 0"); pg.wait_for_timeout(300)
    pg.evaluate("document.querySelector('#app [data-act=startRun]').click()"); pg.wait_for_timeout(600)
    asp=pg.evaluate("[...document.querySelectorAll('[data-act=pickAspect]')].map(b=>b.dataset.arg)"); print('aspects offered',asp)
    pg.screenshot(path=OUT+'/bf_aspect.png', full_page=False)
    pg.evaluate("document.querySelector('[data-act=pickAspect]').click()"); pg.wait_for_timeout(600); pg.evaluate("closeModal&&closeModal(); 0"); pg.wait_for_timeout(400)
    info=pg.evaluate("JSON.stringify({aspect:RUN.aspect,flag:(flagshipOf()||{}).name,patrons:RUN.patrons,rw:RUN.map.cols.flat().filter(n=>n.rw).map(n=>n.type+':'+n.rw.k+(n.rw.p?'/'+n.rw.p:''))})"); print(info)
    pg.screenshot(path=OUT+'/bf_map.png')
    pg.evaluate("window.scrollTo(0,9999)"); pg.wait_for_timeout(200); pg.screenshot(path=OUT+'/bf_map2.png'); pg.evaluate("window.scrollTo(0,0)")
    # force the first node to pay a boon, enter it, win
    pg.evaluate("(()=>{ const id=availableNodes()[0], n=findNode(id); n.rw={k:'boon',p:RUN.patrons[0]}; ACT.enterNode(id); })()")
    pg.wait_for_function("!!B&&B.campaign&&B.side==='player'&&!B.busy", timeout=120000, polling=500)
    pg.evaluate("(()=>{ RUN.boons=[{id:'e_chain',r:0}]; B.boonStats={e_chain:2}; for(const u of B.units) if(u.side==='enemy'){ u.dead=true; u.hp=0; } checkEnd(); })()")
    pg.wait_for_function("!!document.getElementById('endcard')", timeout=120000, polling=500); pg.evaluate("ACT.c3continue(); 0"); pg.wait_for_timeout(1200)
    pg.screenshot(path=OUT+'/bf_victory.png'); print('victory modal:',pg.evaluate("(document.querySelector('.modal')||document.body).innerText.replace(/\\s+/g,' ').slice(0,300)"))
    pg.evaluate("document.querySelector('[data-act=rewardNext]').click()"); pg.wait_for_timeout(600)
    pg.screenshot(path=OUT+'/bf_boon.png'); print('boon modal:',pg.evaluate("(document.querySelector('.modal')||document.body).innerText.replace(/\\s+/g,' ').slice(0,500)"))
    pg.evaluate("document.querySelector('[data-act=takeBoon]').click()"); pg.wait_for_timeout(800)
    # promotions may follow; clear them
    for i in range(4):
        if pg.evaluate("!!document.querySelector('.modal [data-act]')&&!document.querySelector('.mapwrap')"):
            pg.evaluate("(()=>{ const b=document.querySelector('.modal [data-act]'); if(b) b.click(); })()"); pg.wait_for_timeout(500)
    print('boons now',pg.evaluate("JSON.stringify(RUN.boons)"), 'tel', pg.evaluate("JSON.stringify(META.tel.filter(e=>['boon_pick','aspect_pick'].includes(e.ev)).slice(-2))")[:300])
    pg.wait_for_timeout(500); pg.evaluate("window.scrollTo(0,9999)"); pg.wait_for_timeout(200); pg.screenshot(path=OUT+'/bf_after.png')
    print('errors',errs)
