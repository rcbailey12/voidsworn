import os
# Pre-publish smoke test: run before every publish; exits non-zero on any failure.
import re, sys, time, subprocess, functools, json
from playwright.sync_api import sync_playwright
print=functools.partial(print,flush=True)
FILES=['data.js','core.js','battle.js','scene3d.js','ships3d.js','fx3d.js','sfx_data.js','sfx.js','campaign_meta.js','campaign_run.js','ui3d.js','campaign3d.js','perf3d.js','main3d.js']
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
    errs=[]; pg.on('pageerror',lambda e: errs.append('PAGEERR '+str(e)[:200])); pg.on('console',lambda m: errs.append(m.text[:160]) if m.type=='error' and '403' not in m.text and 'Failed to load resource' not in m.text else None)
    t0=time.time(); pg.goto('file://'+__import__('os').path.dirname(__import__('os').path.abspath(__file__))+'/index_test.html')
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
        if i==0: pg.evaluate("disposeAllViews(); for(const k in MODEL_CACHE){ MODEL_CACHE[k].root.dispose(); delete MODEL_CACHE[k]; } for(const f of Object.keys(FAC3D)) facMats(f); 0") # v53-G: every faction's material set (a one-time cache; a rig station brings the corsair set) exists before counting, so only real growth shows
        ms=pg.evaluate("(()=>{ const t=performance.now(); setupBattle({pf:'voidsworn',ef:'hegemony',map:'station'}); return Math.round(performance.now()-t); })()"); t.append(ms); tex.append(pg.evaluate("G.scene.textures.length"))
    check('no texture leak across battles',max(tex)-min(tex)<=3,f'textures {tex}')
    check('ship cache speeds rebuilds',t[1]<t[0]*.8,f'build ms {t}')
    # v45 gates: scene budget on the standard station battle, and every effect shader warmed before the first shot
    bud=pg.evaluate("""(async()=>{ const ins=new BABYLON.SceneInstrumentation(G.scene); ins.captureFrameTime=false; for(let i=0;i<6;i++){ G.scene.render(); await new Promise(r=>setTimeout(r,30)); }
      try{ warmFx(); }catch(e){} for(let i=0;i<8;i++){ G.scene.render(); await new Promise(r=>setTimeout(r,40)); }
      const names=Object.keys(G.engine._compiledEffects||{}).join('|'); const need=['vsFire','vsShock','vsBeam','shRip','vsPlume'];
      return {act:G.scene.getActiveMeshes().length, draws:ins.drawCallsCounter.current, missing:need.filter(n=>!names.includes(n))}; })()""")
    check('scene budget: active meshes and draw calls',bud['act']<=int(os.environ.get('MAX_ACT','420')) and bud['draws']<=int(os.environ.get('MAX_DRAWS','420')),f"active {bud['act']}, draws {bud['draws']}")
    check('every effect shader is warmed before the first shot',not bud['missing'],'missing '+','.join(bud['missing']) if bud['missing'] else 'fire, shock, beam, shield dome, plume')
    pg.evaluate("ACT.c3title();"); time.sleep(2); pg.click('#app [data-act=newRunScreen]'); time.sleep(1); pg.click('#app [data-act=startRun]'); time.sleep(2); pg.evaluate("(()=>{ const a=document.querySelector('[data-act=pickAspect]'); if(a) a.click(); })()"); time.sleep(1)
    pg.evaluate("closeModal(); (()=>{ const el=document.querySelector('#app .node.avail'); (el.closest('[data-act]')||el).dispatchEvent(new MouseEvent('click',{bubbles:true})); })()"); time.sleep(6)
    inb=pg.evaluate("!!(B&&B.campaign)")
    pg.evaluate("""window.__dbg=[]; const _fb=finishBattle; finishBattle=function(r){ window.__dbg.push('finishBattle('+r+')'); try{ const x=_fb(r); window.__dbg.push('returned'); return x; }catch(e){ window.__dbg.push('THREW '+e.message+' @ '+String(e.stack||'').split('\\n')[1]); throw e; } }; 0""")
    pg.evaluate("(async()=>{ SPEED=.05; for(const u of alive('enemy')){ u.hp=0; await killUnit(u,alive('player')[0]); } await endBattleFlow(); })()"); time.sleep(8)
    print('DBG before continue:',pg.evaluate("JSON.stringify({over:B&&B.over,ending:B&&B.ending,campaign:!!(B&&B.campaign),showcase:B&&B.showcase,busy:B&&B.busy,endcard:!!document.getElementById('endcard'),cont:!!document.querySelector('[data-act=c3continue]'),tail:(META.tel||[]).slice(-4).map(e=>e.ev)})"))
    pg.evaluate("(async()=>{ SPEED=.05; for(const u of alive('enemy')){ u.hp=0; await killUnit(u,alive('player')[0]); } await endBattleFlow(); })()"); time.sleep(8)
    pg.click('[data-act=c3continue]'); time.sleep(3)
    print('DBG after continue:',pg.evaluate("JSON.stringify({dbg:window.__dbg,B:!!B,tail:(META.tel||[]).slice(-4).map(e=>e.ev)})"))
    for _ in range(3):
        if pg.evaluate("!!document.querySelector('#app [data-act^=takeLoot]')"): pg.evaluate("document.querySelector('#app [data-act^=takeLoot]').click()"); time.sleep(1)
    onmap=pg.evaluate("!!document.querySelector('.mapmain')"); tel=pg.evaluate("(META.tel||[]).map(x=>x.ev).join(',')")
    check('campaign: run, 3D battle, rewards, map',inb and onmap and not errs,f'battle {inb}, map {onmap}; '+'; '.join(errs[:3]))
    ps=pg.evaluate("G.scene.particleSystems.filter(p=>!p.disposeOnStop).length"); tr=pg.evaluate("G.scene.particleSystems.filter(p=>p.disposeOnStop).length"); check('no persistent effect build-up after a battle',ps<25,f'{ps} persistent effect systems on the map (+{tr} short-lived, self-cleaning)')
    print('DBG stalls:', pg.evaluate("JSON.stringify((META.tel||[]).filter(e=>/stall|busy/.test(e.ev)).map(e=>{ const o=Object.assign({},e); delete o.build; delete o.t; return o; }))")[:1500])
    check('telemetry recorded',all(k in tel for k in ['session','node','battle_start','battle_end']),tel)
    bad=pg.evaluate("(META.tel||[]).filter(e=>['error','action_error'].includes(e.ev)).map(e=>e.ev+': '+(e.msg||'')).join('; ')"); check('no errors logged to telemetry',not bad,bad)
    check('save carries a version',pg.evaluate("META.v===SAVE_VERSION"))
    b.close()
# battles that end at the start of a round (relay score, squadron kill) must show the end card, driven through the real turn flow
import subprocess, os
sl=subprocess.run(['python3',os.path.join(os.path.dirname(os.path.abspath(__file__)),'softlock.py'),os.path.join(os.path.dirname(os.path.abspath(__file__)),'index_test.html')],capture_output=True,text=True,timeout=600)
for case in ['relay','squadron']:
    line=next((l for l in sl.stdout.splitlines() if l.startswith(case)),'no output: '+sl.stderr[-200:])
    check(f'battle ending at round start shows end card ({case})','END CARD SHOWN' in line,line.strip()[:160])
line=next((l for l in sl.stdout.splitlines() if l.startswith('throwrefresh')),'no output: '+sl.stderr[-200:])
check('a failed refresh in the enemy step hands the turn back','RECOVERED' in line,line.strip()[:160])
# freeze-cause regressions (frame error, phone lock mid enemy turn, hung volley) and real-tap strip buttons
here=os.path.dirname(os.path.abspath(__file__))
s2=subprocess.run(['python3',os.path.join(here,'step2test.py')],capture_output=True,text=True,timeout=900).stdout
check('frame error does not stop rendering','rendering continued = True | error reports = 1' in s2,next((l for l in s2.splitlines() if l.startswith('1 ')),'no output')[:140])
check('phone lock mid enemy turn: no stall, turn completes','stalls while hidden = 0 | turn completed after return = True' in s2,next((l for l in s2.splitlines() if l.startswith('2 ')),'no output')[:140])
check('hung volley is abandoned and never lands','target hp unchanged after late release = True' in s2,next((l for l in s2.splitlines() if l.startswith('3 hung')),'no output')[:140])
st=subprocess.run(['python3',os.path.join(here,'striptap.py')],capture_output=True,text=True,timeout=400).stdout
check('strip buttons act on real taps (Center, Brace, Done)',st.count(': True')>=3,' / '.join(st.splitlines()[:3])[:160])
cu=subprocess.run(['python3',os.path.join(here,'cmdui.py')],capture_output=True,text=True,timeout=400).stdout
check('Command: ready in round 1, full power by round 3, gone after use','"enabled":true' in (cu.splitlines()[0] if cu else '') and 'Command \u25cf\u25cb\u25cb' in cu and 'Command \u25cf\u25cf\u25cf' in cu and 'Tap again' in cu and 'used after one tap = False' in cu and 'Command used' in cu,' / '.join(l[:70] for l in cu.splitlines()[:3]))
yc=subprocess.run(['python3',os.path.join(here,'yardcheck.py')],capture_output=True,text=True,timeout=400).stdout
check('shipyard and refits work for every faction','YARDCHECK PASSED' in yc,(yc.splitlines()[-1] if yc else 'no output')[:120])
hc=subprocess.run(['python3',os.path.join(here,'healtest.py')],capture_output=True,text=True,timeout=400).stdout
check('a broken mesh cannot freeze the screen',('HEALTEST PASSED' in hc),(hc.splitlines()[-2] if hc and len(hc.splitlines())>1 else 'no output')[:120])
# v53: a mid-battle reload replays the same fight (owner's rule), and a sector boss win reaches the next sector intro (v51 m.region crash class)
bc=subprocess.run(['python3',os.path.join(here,'bosscheck.py'),os.path.join(here,'index_test.html')],capture_output=True,text=True,timeout=1200)
line=next((l for l in bc.stdout.splitlines() if l.startswith('replay')),'no output: '+bc.stderr[-200:])
check('mid-battle reload replays the same node and enemy fleet','SAME FIGHT' in line,line.strip()[:160])
line=next((l for l in bc.stdout.splitlines() if l.startswith('bossintro')),'no output: '+bc.stderr[-200:])
check('sector boss win runs through rewards into the next sector intro','NEXT SECTOR INTRO' in line,line.strip()[:200])
fails=[n for n,ok in results if not ok]; print('SMOKE', 'PASSED' if not fails else 'FAILED: '+', '.join(fails)); sys.exit(1 if fails else 0)
