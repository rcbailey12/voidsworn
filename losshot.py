# Blocking terrain markers and line-of-sight previews at phone size.
import os
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(1.3); ACT.c3skirmish(); setupBattle({small:true,obj:'rout',shape:'dense',map:'belt'}); ACT.begin(); SPEED=.3; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} 0")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500)
    pg.wait_for_function("(()=>{const l=document.getElementById('loading'); return !l||getComputedStyle(l).display==='none'||l.classList.contains('hide')||+getComputedStyle(l).opacity<.05;})()", timeout=120000, polling=500)
    r=pg.evaluate("""(()=>{ document.querySelectorAll('.tipcard').forEach(e=>e.remove()); const occ=occMap();
      // put an enemy behind the nearest asteroid from the first ship
      const s=caps('player')[0], e=caps('enemy')[0]; let spot=null;
      for(const h of boardHexes()){ if(occ.has(hkey(h.q,h.r))||blocks(terr(h.q,h.r))) continue; const d=hdist(h,s); if(d<3||d>6) continue; if(!los(s,h)){ spot=h; break; } }
      if(!spot) return 'no blocked spot'; e.q=spot.q; e.r=spot.r; const v=G.views.get(e.id); v.root.position.copyFrom(hexWorld(e.q,e.r,0));
      selectUnit(s); const P=hexWorld(s.q,s.r,0), Q=hexWorld(e.q,e.r,0), d=Q.subtract(P); G.ctl.focus(P.add(d.scale(.5)),95); G.ctl.a=Math.atan2(-d.z,-d.x)+.6; G.ctl.b=.85;
      B.hover={q:e.q,r:e.r}; refreshHover(); return 'ok '+hdist(s,e); })()""")
    print(r); pg.wait_for_timeout(2500); print(pg.evaluate("JSON.stringify({ov:OV.hover.map(m=>m.name),hv:B.hover,t:G.ctl.t,r:G.ctl.r,sel:B.sel&&[B.sel.q,B.sel.r]})")); pg.screenshot(path=OUT+'/los_aim.png', timeout=240000)
    r2=pg.evaluate("""(()=>{ const s=B.sel; const sts=[...B.reach.map.values()]; for(const st of sts){ const bl=blockedFrom(s,st); if(bl.length){ B.hover={q:st.q,r:st.r}; refreshHover(); showTip(boardTip(),200,400); return 'tip: '+tipEl.innerText.replace(/\\s+/g,' ').slice(0,200); } } return 'no blocked move'; })()""")
    print(r2); pg.wait_for_timeout(1500); pg.screenshot(path=OUT+'/los_move.png', timeout=240000)
    print('errors',errs)
