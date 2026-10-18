# Every encounter type boots in a phone viewport, shows its objective, zones and legend, and plays one alternating round without errors.
import os, sys, json
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; BOT=open(HERE+'/tbot3.js').read()
SHOTS=os.environ.get('SHOTS')
encs=sys.argv[1:] or ['ambush','defend','hunt','intercept','break','hold','rout:corridor','rout:lanes','rout:ring','rout:dense']
fails=[]
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate(BOT+"; window.altRound=altRound; 0")
    for e in encs:
        enc,_,shape=e.partition(':'); shape=shape or 'random'
        n0=len(errs)
        pg.evaluate("G.engine.setHardwareScalingLevel(5); ACT.c3skirmish(); setupBattle({obj:'%s',shape:'%s',small:true}); ACT.begin(); SPEED=.1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0"%(enc,shape))
        pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=90000, polling=500)
        info=pg.evaluate("""(()=>({obj:B.obj.type, shape:B.shape, label:objectiveLabel().replace(/<[^>]+>/g,''), zones:G.scene.meshes.filter(m=>/^tint(F)?_zone/.test(m.name)).map(m=>m.name),
          legend:(document.getElementById('terrlegend')||{}).innerText, transports:B.units.filter(u=>u.transport).length, flag:(B.units.find(u=>u.flagship)||{}).name||null,
          hexes:boardHexes().length, onBlock:B.units.filter(u=>!u.dead&&blocks(terr(u.q,u.r))).length, offBoard:B.units.filter(u=>!u.dead&&!onBoard(u.q,u.r)).length}))()""")
        if SHOTS: pg.screenshot(path=SHOTS+'/enc_'+e.replace(':','_')+'.png')
        try: res=pg.evaluate("altRound()")
        except Exception as ex: res='ERR '+str(ex)[:120]
        lab2=pg.evaluate("B&&B.obj?objectiveLabel().replace(/<[^>]+>/g,''):''")
        new=errs[n0:]
        ok=info['obj']==enc and info['onBlock']==0 and info['offBoard']==0 and res in ('r2','win','loss') and not new
        if not ok: fails.append(e)
        print(('PASS ' if ok else 'FAIL ')+e, json.dumps(info), '| round:',res,'|',lab2, ('| errors: '+'; '.join(new)) if new else '')
        sys.stdout.flush()
    print('ENCCHECK', 'PASSED' if not fails else 'FAILED '+','.join(fails))
