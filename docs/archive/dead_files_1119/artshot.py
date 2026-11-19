# Art review shots at phone size and phone quality: default battle view, a closer combat angle mid-volley.
import os, sys
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.'); TAG=os.environ.get('TAG','x')
MAP=os.environ.get('MAP','storm'); EF=os.environ.get('EF','hegemony'); PF=os.environ.get('PF','voidsworn')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True,device_scale_factor=1); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(1); ACT.c3skirmish(); setupBattle({small:true,obj:'rout',shape:'open',map:'%s',pf:'%s',ef:'%s'}); ACT.begin(); SPEED=.6; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0"%(MAP,PF,EF))
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500)
    pg.wait_for_function("!document.getElementById('loading')||getComputedStyle(document.getElementById('loading')).display==='none'||document.getElementById('loading').style.opacity==='0'", timeout=60000, polling=500); pg.evaluate("document.querySelectorAll('.tipcard').forEach(e=>e.remove()); try{ META.opts.tips={}; Object.keys(TIPS||{}).forEach(k=>META.opts.tips[k]=1); }catch(e){} 0"); pg.wait_for_timeout(3500)
    pg.screenshot(path=f'{OUT}/{TAG}_1_overview.png', timeout=240000)
    pg.evaluate('B.sel=null; B.showArcs=false; refreshOverlays(); 0'); pg.wait_for_timeout(1500); pg.screenshot(path=f'{OUT}/{TAG}_1b_noarcs.png', timeout=240000); pg.evaluate('B.showArcs=true; 0')
    # close combat: bring the nearest enemy into range of the first ship and fire a volley
    pg.evaluate("""(()=>{ const u=pendingP()[0], e=alive('enemy').filter(x=>!x.isSq)[0]; const occ=occMap(); let best=null,bd=99; for(const h of boardHexes()){ if(occ.has(hkey(h.q,h.r))||blocks(terr(h.q,h.r))) continue; const d=hdist(h,u); if(d>=3&&d<=4&&d<bd&&hdist(h,{q:u.q+3,r:u.r})<=1){bd=d;best=h;} } if(best){ e.q=best.q; e.r=best.r; e.facing=3; const v=G.views.get(e.id); if(v) v.root.position.copyFrom(hexWorld(e.q,e.r,0)); }
      try{ ACT.tipOff&&ACT.tipOff(); }catch(x){} document.querySelectorAll('.tipcard').forEach(x=>x.remove()); const P=hexWorld(u.q,u.r,0), Q=hexWorld(e.q,e.r,0), d=Q.subtract(P); G.ctl.focus(P.add(d.scale(.5)),Number(window.__R||70)); G.ctl.a=Math.atan2(-d.z,-d.x)+1.05; G.ctl.b=1.0; window.__fire=(async()=>{ for(let i=0;i<u.weapons.length;i++){ if(canFire(u,u.weapons[i],e)) await fireWeapon(u,i,e); } })(); })(); 0""")
    pg.wait_for_timeout(900); pg.screenshot(path=f'{OUT}/{TAG}_2_volley.png', timeout=240000)
    pg.wait_for_timeout(2500); pg.screenshot(path=f'{OUT}/{TAG}_3_after.png', timeout=240000)
    print('errors',errs)
