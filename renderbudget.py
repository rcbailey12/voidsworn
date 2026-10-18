# Phone render budget: draw calls, active meshes, vertices and textures in a full-size battle at the phone profile.
import os, json, sys
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'
Q=os.environ.get('Q','medium'); SMALLJS='true' if os.environ.get('SMALL')=='1' else 'false'
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':915},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("setQuality('%s'); G.engine.setHardwareScalingLevel(4); ACT.c3skirmish(); setupBattle({small:%s,obj:'%s',shape:'open',map:'%s'}); ACT.begin(); SPEED=.1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0"%(Q,SMALLJS,os.environ.get('ENC','rout'),os.environ.get('MAP','graveyard')))
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500); pg.wait_for_timeout(2000)
    def measure():
        pg.evaluate("window.__si&&__si.dispose(); window.__si=new BABYLON.SceneInstrumentation(G.scene); 0"); pg.wait_for_timeout(3000)
        return pg.evaluate("({dc:__si.drawCallsCounter.current, act:G.scene.getActiveMeshes().length})")
    base=measure(); print("BASE",base); import sys; sys.stdout.flush()
    for name,expr in [('nosel',"B.sel=null; B.inspect=null; refreshOverlays()"),('noglow',"G.glow.isEnabled=false"),('glow_back',"G.glow.isEnabled=true"),('noplates_grid',"G.scene.meshes.filter(m=>/^grid/.test(m.name)).forEach(m=>m.setEnabled(false))"),('grid_back',"G.scene.meshes.filter(m=>/^grid/.test(m.name)).forEach(m=>m.setEnabled(true))"),('noships',"G.views.forEach(v=>v.root&&v.root.setEnabled(false))"),('ships_back',"G.views.forEach(v=>v.root&&v.root.setEnabled(true))"),('noenv',"G.env.forEach(m=>m&&m.setEnabled&&m.setEnabled(false))"),('env_back',"G.env.forEach(m=>m&&m.setEnabled&&m.setEnabled(true))")]:
        pg.evaluate(expr+"; 0"); print(name, measure())
    r=pg.evaluate("""(()=>{ const s=G.scene, act=s.getActiveMeshes(); let v=0; for(let i=0;i<act.length;i++){ const m=act.data[i]; v+=m.getTotalVertices?m.getTotalVertices():0; }
      const big=s.textures.filter(t=>t.getSize&&t.getSize().width>=2048).map(t=>t.name+' '+t.getSize().width+'x'+t.getSize().height);
      const byName={}; for(let i=0;i<act.length;i++){ const n=act.data[i].name.replace(/[0-9_.-]+$/,''); byName[n]=(byName[n]||0)+1; }
      const top=Object.entries(byName).sort((a,b)=>b[1]-a[1]).slice(0,14);
      return {quality:G.quality, drawCalls:__si.drawCallsCounter.current, drawAvg:Math.round(__si.drawCallsCounter.average), activeMeshes:act.length, meshes:s.meshes.length, activeVerts:v, totalVerts:s.getTotalVertices(), textures:s.textures.length, bigTextures:big, particles:s.particleSystems.length, post:(s.postProcesses||[]).length, shadows:!!(G.sun&&G.sun.shadowEnabled), topActive:top}; })()""")
    r['perShip']=pg.evaluate("[...G.views.values()].filter(v=>v.root).map(v=>v.root.getChildMeshes(false).filter(m=>m.isEnabled()&&m.isVisible).length)")
    r['envActive']=pg.evaluate("(()=>{ const a=G.scene.getActiveMeshes(); const env=new Set(); G.env.forEach(m=>{ if(!m) return; env.add(m); (m.getChildMeshes?m.getChildMeshes(false):[]).forEach(c=>env.add(c)); }); let n=0; const by={}; for(let i=0;i<a.length;i++){ const m=a.data[i]; if(env.has(m)&&!(m instanceof BABYLON.InstancedMesh)){ n++; const k=m.name.replace(/[0-9_.-]+$/,''); by[k]=(by[k]||0)+1; } } return [n,Object.entries(by).sort((x,y)=>y[1]-x[1]).slice(0,12)]; })()")
    r['ship0']=pg.evaluate("(()=>{ const vs=[...G.views.values()].filter(v=>v.root&&v.model); return vs.filter(v=>v.root.getChildMeshes(false).filter(m=>m.isEnabled()&&m.isVisible).length>9).slice(0,1).map(v=>v.root.getChildMeshes(false).filter(m=>m.isEnabled()&&m.isVisible).map(m=>m.name+':'+m.getTotalVertices()+(G.glow.hasMesh&&G.glow.hasMesh(m)?'G':''))); })()")
    r['nonShip']=pg.evaluate("(()=>{ const a=G.scene.getActiveMeshes(); const ship=new Set(); for(const v of G.views.values()) if(v.root) v.root.getChildMeshes(false).forEach(m=>ship.add(m)); const by={}; for(let i=0;i<a.length;i++){ const m=a.data[i]; if(ship.has(m)) continue; const src=m instanceof BABYLON.InstancedMesh?m.sourceMesh:m; const k=src.name.replace(/[0-9_.-]+$/,'')+(G.glow.hasMesh(src)?'*':''); by[k]=by[k]||new Set(); by[k].add(src.uniqueId); } return Object.entries(by).map(([k,v])=>[k,v.size]).sort((x,y)=>y[1]-x[1]).slice(0,40); })()")
    del r['topActive']; print(json.dumps(r)); print('errors',errs)
