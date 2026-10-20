import sys, time, json, functools
print=functools.partial(print,flush=True)
# v53 smoke: (1) a mid-battle reload replays the same node and enemy fleet; (2) a sector boss win runs through the rewards into the next sector intro (the v51 m.region crash class)
from playwright.sync_api import sync_playwright
PAGE=sys.argv[1]
FP="JSON.stringify({seed:B.seed,node:findNode(RUN.curNode)&&findNode(RUN.curNode).seed,shape:B.shape,obj:B.obj&&B.obj.type,terr:Object.keys(B.terrain).length,enemy:B.units.filter(u=>u.side==='enemy').map(u=>u.tpl+'@'+u.q+','+u.r)})"
def waitfor(pg,cond,secs):
    for _ in range(secs):
        if pg.evaluate(cond): return True
        time.sleep(1)
    return False
def title(pg): waitfor(pg,"!document.getElementById('loading')&&!!document.querySelector('.title .menu')",200)
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':1280,'height':720}); pg=ctx.new_page(); pg.set_default_timeout(200000); errs=[]
    pg.on('pageerror',lambda e: errs.append('PAGEERR '+str(e)[:200]))
    pg.goto('file://'+PAGE); title(pg); print('  title')
    pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(6); G.scene.postProcessesEnabled=false;")
    pg.click('#app [data-act=newRunScreen]'); time.sleep(1); pg.click('#app [data-act=startRun]'); time.sleep(2)
    pg.evaluate("(()=>{ const a=document.querySelector('[data-act=pickAspect]'); if(a) a.click(); })()"); time.sleep(1); pg.evaluate("closeModal()")
    nid=pg.evaluate("(()=>{ const ids=availableNodes(); return ids.find(id=>['battle','elite'].includes(findNode(id).type))||null; })()")
    if not nid:
        print('replay -> SKIPPED (no fight node in the first column)'); fp1=fp2=None
    else:
        pg.evaluate(f"ACT.enterNode('{nid}')"); waitfor(pg,"!!(B&&B.campaign)",60); time.sleep(2); fp1=pg.evaluate(FP); print('  first entry',fp1[:120])
        pg.reload(); title(pg); pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(6); G.scene.postProcessesEnabled=false;")
        pg.evaluate("ACT.continueRun()"); time.sleep(1); pg.evaluate("closeModal()")
        pg.evaluate(f"ACT.enterNode('{nid}')"); waitfor(pg,"!!(B&&B.campaign)",60); time.sleep(2); fp2=pg.evaluate(FP)
        a,c=json.loads(fp1),json.loads(fp2)
        same=fp1==fp2 and a['seed']==a['node'] and len(a['enemy'])>0
        print('replay ->','SAME FIGHT' if same else 'DIFFERENT', '| seed',a['seed'],'node seed',a['node'],'|',len(a['enemy']),'enemies',('' if fp1==fp2 else '| after reload: '+fp2[:200]))
    # straight to the sector boss, win it, and click through every reward screen to the next sector's intro
    pg.evaluate("(()=>{ const n=RUN.map.cols.flat().find(x=>x.type==='boss'); RUN.pos=n.id; RUN.curNode=n.id; battleScreen({kind:'boss',fac:RUN.map.fac,col:n.col,node:n.id}); })()")
    waitfor(pg,"!!(B&&B.campaign&&B.cfg.kind==='boss')",60); time.sleep(2)
    pg.evaluate("void (async()=>{ SPEED=.05; for(const u of alive('enemy')){ u.hp=0; await killUnit(u,alive('player')[0]); } })()"); print('  boss fleet destroyed, waiting for the end card')
    card=waitfor(pg,"!!document.querySelector('[data-act=c3continue]')",90)
    if card: pg.click('[data-act=c3continue]'); time.sleep(2)
    intro=None; steps=[]
    for _ in range(25):
        h=pg.evaluate("(()=>{ const m=document.getElementById('modal'); return m?(m.querySelector('h2')||{}).textContent||'':''; })()")
        if h.startswith('Sector II'): intro=h; break
        act=pg.evaluate("""(()=>{ const m=document.getElementById('modal'); if(!m) return ''; const c=m.querySelector('button.choice[data-act]:not([disabled]), .choice button[data-act]:not([disabled])')||m.querySelector('.primary[data-act]'); if(!c) return ''; const a=c.dataset.act; c.click(); return a; })()""")
        steps.append(act or '-'); time.sleep(1)
    sec=pg.evaluate("RUN&&RUN.sector"); reg=pg.evaluate("RUN&&RUN.map&&RUN.map.region")
    bad=pg.evaluate("(META.tel||[]).filter(e=>['error','action_error'].includes(e.ev)).map(e=>e.ev+': '+(e.msg||'')).join('; ')")
    ok=card and intro and sec==2 and not errs and not bad
    print('bossintro ->','NEXT SECTOR INTRO' if ok else 'FAILED','| end card',card,'| intro',repr(intro),'| sector',sec,'| region',reg,'| steps',','.join(steps)[:160],'| errors',(errs+[bad] if bad else errs)[:2])
    b.close()
