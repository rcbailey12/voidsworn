# One volley per faction, screenshotted mid-flight, to judge weapon looks.
import os, sys
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
FACS=(os.environ.get('FACS') or 'hegemony,chorus,deathless,ithar,corsair,voidsworn').split(',')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':600},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    for f in FACS:
        pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(1.2); ACT.c3skirmish(); setupBattle({small:true,obj:'rout',shape:'open',map:'storm',pf:'%s',ef:'%s'}); ACT.begin(); SPEED=1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} document.querySelectorAll('.tipcard,#panel,#btop,#terrlegend').forEach(e=>e.style.display='none'); 0"%(f,'voidsworn' if f!='voidsworn' else 'hegemony'))
        pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500)
        pg.evaluate("""(()=>{ const u=caps('player').find(x=>x.weapons.some(w=>w.k!=='flak'&&w.k!=='lance'&&w.k!=='torp'))||caps('player')[0], e=caps('enemy')[0]; const occ=occMap(); let best=null; for(const h of boardHexes()){ if(occ.has(hkey(h.q,h.r))||blocks(terr(h.q,h.r))) continue; const d=hdist(h,u); if(d===4){ best=h; break; } } e.q=best.q; e.r=best.r; const ve=G.views.get(e.id); ve.root.position.copyFrom(hexWorld(e.q,e.r,0));
          const P=hexWorld(u.q,u.r,0), Q=hexWorld(e.q,e.r,0), d=Q.subtract(P); G.ctl.focus(P.add(d.scale(.5)),62); G.ctl.a=Math.atan2(-d.z,-d.x)+1.2; G.ctl.b=1.05;
          window.__go=()=>{ const ws=u.weapons.map((w,i)=>i).filter(i=>u.weapons[i].k!=='flak'&&u.weapons[i].k!=='lance'&&u.weapons[i].k!=='torp'); const w=u.weapons[ws[0]||0]; animWeapon(u,w,e,[true,true,true,false].slice(0,Math.max(2,w.shots))); }; })(); 0""")
        pg.wait_for_timeout(2500); pg.evaluate("__go(); 0"); pg.wait_for_timeout(int(os.environ.get('DELAY','350')))
        pg.screenshot(path=f'{OUT}/w_{f}.png', timeout=240000); print(f, 'ok'); sys.stdout.flush()
    print('errors',errs)
