# Pre-publish smoke test: run before every publish; exits non-zero on any failure.
import re, sys, time, subprocess, functools, json
from playwright.sync_api import sync_playwright
print=functools.partial(print,flush=True)
FILES=['data.js','core.js','battle.js','scene3d.js','ships3d.js','fx3d.js','campaign_meta.js','campaign_run.js','ui3d.js','campaign3d.js','main3d.js']
results=[]
def check(name,ok,detail=''): results.append((name,ok)); print(('PASS ' if ok else 'FAIL ')+name+(' | '+detail if detail else ''))
subprocess.run(['python3','build.py','test'],check=True,capture_output=True)
s=open('index_test.html').read(); js=s[s.index('<script>\n')+9:s.rindex('</script>')]; open('/tmp/smoke.js','w').write(js)
r=subprocess.run(['node','--check','/tmp/smoke.js'],capture_output=True,text=True); check('bundle parses',r.returncode==0,r.stderr[:200])
seen={}; dups=[]
for f in FILES:
    src=open(f).read()
    for n in re.findall(r'^(?:async\s+)?function\s+(\w+)',src,re.M)+re.findall(r'^(?:const|let|var|class)\s+(\w+)',src,re.M):
        if n in seen and seen[n]!=f: dups.append(f'{n} ({seen[n]} & {f})')
        seen.setdefault(n,f)
check('no duplicate globals',not dups,', '.join(dups[:8]))
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    pg=b.new_page(viewport={'width':1280,'height':720}); pg.set_default_timeout(300000)
    errs=[]; pg.on('pageerror',lambda e: errs.append('PAGEERR '+str(e)[:200])); pg.on('console',lambda m: errs.append(m.text[:160]) if m.type=='error' and '403' not in m.text else None)
    t0=time.time(); pg.goto('file:///home/claude/v3d/index_test.html')
    for _ in range(200):
        if pg.evaluate("!document.getElementById('loading')&&!!document.querySelector('.title .menu')"): break
        time.sleep(1)
    boot=round(time.time()-t0)
    check('boots to title with zero errors',not errs and pg.evaluate("!!document.querySelector('.title .menu')"),f'{boot}s on software GPU; '+'; '.join(errs[:3]))
    pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(6); G.scene.postProcessesEnabled=false;")
    check('title has live showcase',pg.evaluate("!!B&&B.units.length>0"))
    pg.add_script_tag(path='tbot3.js')
    pg.evaluate("ACT.c3skirmish(); setupBattle({small:true}); ACT.begin(); SPEED=.03; G.cine=false;"); st=pg.evaluate("altRound()")
    check('skirmish plays an alternating round',not errs and st in ('r2','win','loss'),f'{st}; '+'; '.join(errs[:3]))
    t=[]; tex=[]
    for i in range(3):
        if i==0: pg.evaluate("disposeAllViews(); for(const k in MODEL_CACHE){ MODEL_CACHE[k].root.dispose(); delete MODEL_CACHE[k]; }")
        ms=pg.evaluate("(()=>{ const t=performance.now(); setupBattle({pf:'voidsworn',ef:'hegemony',map:'station'}); return Math.round(performance.now()-t); })()"); t.append(ms); tex.append(pg.evaluate("G.scene.textures.length"))
    check('no texture leak across battles',max(tex)-min(tex)<=3,f'textures {tex}')
    check('ship cache speeds rebuilds',t[1]<t[0]*.8,f'build ms {t}')
    pg.evaluate("ACT.c3title();"); time.sleep(2); pg.click('#app [data-act=newRunScreen]'); time.sleep(1); pg.click('#app [data-act=startRun]'); time.sleep(2)
    pg.evaluate("closeModal(); (()=>{ const el=document.querySelector('#app .node.avail'); (el.closest('[data-act]')||el).dispatchEvent(new MouseEvent('click',{bubbles:true})); })()"); time.sleep(6)
    inb=pg.evaluate("!!(B&&B.campaign)")
    pg.evaluate("""window.__dbg=[]; const _fb=finishBattle; finishBattle=function(r){ window.__dbg.push('finishBattle('+r+') campaign='+!!(B&&B.campaign)); try{ const x=_fb(r); window.__dbg.push('finishBattle returned'); return x; }catch(e){ window.__dbg.push('THREW '+e.message+' @ '+String(e.stack||'').split('\\n')[1]); throw e; } };
      const _ai=aiStep; aiStep=async function(){ window.__dbg.push('aiStep on campaign='+!!(B&&B.campaign)+' round='+(B&&B.round)); return _ai(); };
      const _nr=nextRound; nextRound=async function(){ window.__dbg.push('nextRound on campaign='+!!(B&&B.campaign)); return _nr(); };""")
    pg.evaluate("(async()=>{ SPEED=.05; for(const u of alive('enemy')){ u.hp=0; await killUnit(u,alive('player')[0]); } await endBattleFlow(); })()"); time.sleep(8)
    print('  debug before continue:',pg.evaluate("JSON.stringify({over:B&&B.over,ending:B&&B.ending,campaign:!!(B&&B.campaign),cont:!!document.querySelector('[data-act=c3continue]'),dbg:window.__dbg})"))
    pg.click('[data-act=c3continue]'); time.sleep(3)
    print('  debug after continue:',pg.evaluate("JSON.stringify({dbg:window.__dbg,tail:(META.tel||[]).slice(-4).map(e=>e.ev)})"))
    for _ in range(3):
        if pg.evaluate("!!document.querySelector('#app [data-act^=takeLoot]')"): pg.evaluate("document.querySelector('#app [data-act^=takeLoot]').click()"); time.sleep(1)
    onmap=pg.evaluate("!!document.querySelector('.mapmain')"); tel=pg.evaluate("(META.tel||[]).map(x=>x.ev).join(',')")
    check('campaign: run, 3D battle, rewards, map',inb and onmap and not errs,f'battle {inb}, map {onmap}; '+'; '.join(errs[:3]))
    ps=pg.evaluate("G.scene.particleSystems.filter(p=>!p.disposeOnStop).length"); tr=pg.evaluate("G.scene.particleSystems.filter(p=>p.disposeOnStop).length"); check('no persistent effect build-up after a battle',ps<25,f'{ps} persistent effect systems on the map (+{tr} short-lived, self-cleaning)')
    check('telemetry recorded',all(k in tel for k in ['session','node','battle_start','battle_end']),tel)
    check('save carries a version',pg.evaluate("META.v===SAVE_VERSION"))
    b.close()
fails=[n for n,ok in results if not ok]; print('SMOKE', 'PASSED' if not fails else 'FAILED: '+', '.join(fails)); sys.exit(1 if fails else 0)
