# Victory recap screen at phone size.
import os
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    r=pg.evaluate("""(()=>{ newRun('vex','ithar'); RUN.t0=Date.now()-47*60000; RUN.stats={battles:11,elites:2,bosses:3,kills:38,lost:1}; RUN.sector=3;
      RUN.fleet=['i_carrier','i_carrier','i_carrier','warden'].map(t=>newShip(t,true)); RUN.fleet.forEach((s,i)=>s.car={dealt:300+i*120,kills:4+i*3,battles:9}); RUN.fallen=[{name:'Ilyra Vos',rank:1,fac:'ithar',ship:'Dawnsong',sector:2}];
      endRun(true); return document.querySelector('.screen').innerText.replace(/\\s+/g,' ').slice(0,400); })()""")
    print(r); pg.wait_for_timeout(800); pg.screenshot(path=OUT+'/recap.png')
    pg.evaluate("document.querySelector('.recap .inner').scrollTop=9999"); pg.wait_for_timeout(300); pg.screenshot(path=OUT+'/recap2.png')
    pg.click("[data-act=nextFac]"); pg.wait_for_timeout(500); print('after click:', pg.evaluate("document.querySelector('.facpick.on').innerText"))
    print('errors',errs)
