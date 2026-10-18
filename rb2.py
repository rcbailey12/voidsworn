import os, json
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':915},is_mobile=True,has_touch=True); pg=ctx.new_page()
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(4); ACT.c3skirmish(); setupBattle({small:false,obj:'rout',shape:'open',map:'%s'}); ACT.begin(); SPEED=.1; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); 0"%os.environ.get('MAP','graveyard'))
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500); pg.wait_for_timeout(2500)
    r=pg.evaluate("""(()=>{ const act=new Set(); const a=G.scene.getActiveMeshes(); for(let i=0;i<a.length;i++) act.add(a.data[i]);
      const inEnv=new Set(); const walk=m=>{ if(!m||inEnv.has(m)) return; inEnv.add(m); (m.getChildMeshes?m.getChildMeshes(false):[]).forEach(c=>inEnv.add(c)); }; G.env.forEach(walk);
      const g={}; for(const m of act){ const env=inEnv.has(m); const inst=m instanceof BABYLON.InstancedMesh; const src=inst?m.sourceMesh:m; const key=(env?'ENV ':'')+src.name.replace(/[0-9_.-]+$/,'');
        const o=g[key]=g[key]||{n:0,inst:0,v:0,srcs:new Set()}; o.n++; if(inst) o.inst++; o.v+=m.getTotalVertices(); o.srcs.add(src.uniqueId); }
      const rows=Object.entries(g).map(([k,o])=>[k,o.n,o.inst,o.srcs.size,o.v]).sort((x,y)=>y[3]-x[3]); 
      const ships=[...G.views.values()].map(v=>{ const ms=v.root?v.root.getChildMeshes(false):[]; return ms.filter(m=>m.isEnabled()&&m.isVisible).length; });
      return {rows:rows.filter(r=>r[0].startsWith('ENV')||!r[0].startsWith('ship')).slice(0,40), perShip:ships, nShips:ships.length}; })()""")
    print('ships',r['nShips'],'meshes per ship',r['perShip'])
    print('name | active | instances | distinct sources (~draws) | verts')
    for row in r['rows']: print(row)
