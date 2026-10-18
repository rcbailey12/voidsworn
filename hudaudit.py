# Phone HUD audit: tap targets under 44px, keyboard hints shown on touch, flashes default.
import os, json, sys
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; SHOT=os.environ.get('SHOT')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':915},is_mobile=True,has_touch=True,device_scale_factor=1); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    audit="""(()=>{ const vis=e=>{ const r=e.getBoundingClientRect(), s=getComputedStyle(e); return r.width>0&&r.height>0&&s.visibility!=='hidden'&&s.display!=='none'&&r.bottom>0&&r.top<innerHeight; };
      const small=[...document.querySelectorAll('button,[data-act],a,input,select')].filter(vis).map(e=>{ const r=e.getBoundingClientRect(); return {t:(e.innerText||e.getAttribute('aria-label')||e.dataset.act||e.tagName).trim().replace(/\\s+/g,' ').slice(0,28), w:Math.round(r.width), h:Math.round(r.height), act:e.dataset.act||''}; }).filter(x=>x.h<44||x.w<44);
      const txt=document.body.innerText; const kbd=[...new Set((txt.match(/\\b(Esc|Space|Shift|Ctrl|Enter|Tab)\\b|\\[[A-Z0-9]\\]|\\([A-Z0-9]\\)|press [A-Z]\\b|key [A-Z]\\b|right[- ]click|mouse|hover|scroll wheel/gi)||[]))];
      return {small, kbd, kbdEls:document.querySelectorAll('kbd').length, fxReduced:G.fxReduced, mobile:G.mobile}; })()"""
    out={}
    out['title']=pg.evaluate(audit)
    pg.evaluate("G.engine.setHardwareScalingLevel(5); ACT.c3skirmish(); 0"); pg.wait_for_timeout(1500)
    out['setup']=pg.evaluate(audit)
    pg.evaluate("setupBattle({small:true,obj:'defend'}); ACT.begin(); SPEED=.1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=90000, polling=500); pg.wait_for_timeout(1200)
    out['battle']=pg.evaluate(audit)
    if SHOT: pg.screenshot(path=SHOT)
    pg.evaluate("ACT.legend(); 0"); pg.wait_for_timeout(300); out['legend_open']=pg.evaluate(audit); pg.evaluate("ACT.legend(); 0")
    tip=pg.evaluate("""(()=>{ const s=B.sel||pendingP()[0]; const t=alive('enemy')[0]; showTip(attackTip(s,t),200,500); const r=tipEl.getBoundingClientRect(), pn=document.getElementById('panel').getBoundingClientRect();
      return {text:tipEl.innerText.slice(-60).replace(/\\s+/g,' '), top:Math.round(r.top), bottom:Math.round(r.bottom), left:Math.round(r.left), right:Math.round(r.right), panelTop:Math.round(pn.top), vw:innerWidth}; })()""")
    print('tooltip',tip, 'OK' if tip['bottom']<=tip['panelTop'] and tip['right']<=tip['vw'] and tip['left']>=0 and 'Click' not in tip['text'] else 'BAD')
    for k,v in out.items():
        print('==',k,'| fxReduced',v['fxReduced'],'mobile',v['mobile'],'| kbd',v['kbd'],v['kbdEls'])
        for s in v['small']: print('   small',s)
    print('errors',errs)
