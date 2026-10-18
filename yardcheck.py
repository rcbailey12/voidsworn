# Shipyard and refits work for every faction: no NaN prices, buy buttons enabled with credits, refit slots on every hull.
import os, json
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    bad=[]
    for fac,adm in [('ithar','aelith'),('chorus','matriarch'),('hegemony','reyes'),('corsair','mott'),('deathless','nekhet'),('voidsworn','vex')]:
        r=pg.evaluate("""(()=>{ newRun('%s','%s'); RUN.credits=2000; const n=RUN.map.cols[3].find(x=>x.type==='shipyard')||RUN.map.cols[3][0]; RUN.curNode=n.id; shipyardScreen(n);
          const t=document.getElementById('app').innerText; const buys=[...document.querySelectorAll('#app button')].filter(x=>/^Buy/.test(x.innerText)); 
          RUN.inventory=['auspex']; fleetScreen(); const t2=document.getElementById('app').innerText; const fits=[...document.querySelectorAll('#app button')].filter(x=>/^Fit to/.test(x.innerText)).length;
          return {nan:/NaN/.test(t)||/NaN/.test(t2), buys:buys.length, buyEnabled:buys.filter(x=>!x.disabled).length, fits, slots:RUN.fleet.map(s=>s.tpl+':'+HULLS[s.tpl].slots)}; })()"""%(adm,fac))
        print(fac, json.dumps(r))
        if r['nan'] or r['buyEnabled']==0 or r['fits']==0: bad.append(fac)
    print('YARDCHECK', 'PASSED' if not bad and not errs else 'FAILED '+','.join(bad), errs[:3])
