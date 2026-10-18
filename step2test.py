import time, os
from playwright.sync_api import sync_playwright
PAGE='file://'+os.path.dirname(os.path.abspath(__file__))+'/index_test.html'
def boot(b):
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:120]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(5); ACT.c3skirmish(); SETUP.obj='rout'; setupBattle({small:true}); ACT.begin(); SPEED=.1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on');")
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=60000, polling=500); return pg,errs
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    # 1. a frame error must not stop rendering
    pg,errs=boot(b)
    pg.evaluate("window.__t0=G.time; const _u=updateWorld; let once=true; updateWorld=function(dt){ if(once){ once=false; throw new Error('test frame error'); } return _u(dt); }; 0")
    try: pg.wait_for_function("G.time>window.__t0+0.05", timeout=30000, polling=500); cont=True
    except Exception: cont=False
    print('1 frame error: rendering continued =',cont,'| error reports =',pg.evaluate("(META.tel||[]).filter(e=>e.ev==='error'&&/test frame error/.test(e.msg||'')).length"))
    # 2. phone locked mid enemy turn: no stall, turn completes on return
    pg.evaluate("window.__s0=(META.tel||[]).filter(e=>e.ev==='stall').length; ACT.endTurn();")
    pg.wait_for_function("B.side==='enemy'", timeout=30000, polling=200)
    pg.evaluate("Object.defineProperty(document,'visibilityState',{configurable:true,get:()=>'hidden'}); G.engine.stopRenderLoop();")
    time.sleep(40)
    stalls=pg.evaluate("(META.tel||[]).filter(e=>e.ev==='stall').length-window.__s0")
    pg.evaluate("delete document.visibilityState; G.engine.runRenderLoop(()=>G.scene.render());")
    try: pg.wait_for_function("B.side==='player'&&!B.busy", timeout=90000, polling=500); back=True
    except Exception: back=False
    print('2 hidden 40 s mid enemy turn: stalls while hidden =',stalls,'| turn completed after return =',back)
    # 3. a hung volley is abandoned and can never land later
    r=pg.evaluate("""(()=>{ let s=null,t=null,wi=-1; for(const s0 of caps('player')) for(const t0 of alive('enemy').filter(e=>!e.isSq)){ if(wi>=0) break; for(const [dq,f] of [[-2,0],[2,3],[-1,0],[1,3]]){ const q=t0.q+dq, r=t0.r, o=unitAt(q,r); if(!onBoard(q,r)||blocks(terr(q,r))||(o&&o!==s0)) continue; const oq=s0.q, or_=s0.r, of=s0.facing; s0.q=q; s0.r=r; s0.facing=f; const w0=s0.weapons.findIndex(w=>w.k!=='flak'&&weaponReady(w)&&inReach(s0,w,t0)); if(w0>=0){ s=s0; t=t0; wi=w0; break; } s0.q=oq; s0.r=or_; s0.facing=of; } }
      if(wi<0) return 'no legal shot'; t.sh=[0,0,0,0]; selectUnit(s); window.__t=t; window.__hp=t.hp; window.__s1=(META.tel||[]).filter(e=>e.ev==='stall').length;
      window.__aw=animWeapon; animWeapon=()=>new Promise(res=>{ window.__rel=res; }); act(()=>fireWeapon(s,wi,t)); return 'firing '+s.weapons[wi].n+' at '+t.name; })()""")
    print('3',r)
    try: pg.wait_for_function("(META.tel||[]).filter(e=>e.ev==='stall').length>window.__s1", timeout=240000, polling=1000)
    except Exception: pass
    stalled=pg.evaluate("(META.tel||[]).filter(e=>e.ev==='stall').length-window.__s1")
    pg.evaluate("animWeapon=window.__aw; window.__rel&&window.__rel();"); time.sleep(2)
    print('3 hung volley: stall fired =',stalled,'| busy cleared =',pg.evaluate("!B.busy"),'| target hp unchanged after late release =',pg.evaluate("window.__t.hp===window.__hp"))
    print('page errors:',errs[:3]); b.close()
