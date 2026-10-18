import sys,json,time
from playwright.sync_api import sync_playwright
PAGE='file:///home/claude/v3d/index_test.html'
REPS=int(sys.argv[1]) if len(sys.argv)>1 else 2
PROBE=r"""(()=>{
 const SOLID_NAMES=/^(giantRock|rockChunk|moonlet|cometCore|dsCore|rock|nearPlanet)$/;
 const out={shape:B.map.shape,map:B.map.map,holes:(B.map.holes||[]).map(h=>h.kind),station:!!B.map.station,deadstar:!!B.map.deadstar,inside:[],overlap:[],units:[],stationInCut:false};
 if(B.map.station){ out.stationInCut=!onBoard(B.map.station.q,B.map.station.r); }
 // collect solid objects as XZ circles from their world bounding boxes
 const objs=[];
 const add=(name,m)=>{ try{ m.computeWorldMatrix(true); const bs=m.getBoundingInfo().boundingSphere, c=bs.centerWorld; let R=bs.radiusWorld*(/moonlet|dsCore|nearPlanet/.test(name)?1:.8); const dy=2-c.y; if(dy*dy>=R*R) return; const r=Math.sqrt(R*R-dy*dy); if(r<1) return; objs.push({name,cx:c.x,cz:c.z,r}); }catch(e){} };
 for(const e of G.env){ if(!e||e.isDisposed&&e.isDisposed()) continue;
   if(e instanceof BABYLON.TransformNode && !(e instanceof BABYLON.Mesh)){ const ms=e.getChildMeshes(false).filter(m=>m.isVisible&&m.isEnabled()); if(!ms.length) continue; let mn=null,mx=null; for(const m of ms){ m.computeWorldMatrix(true); const bb=m.getBoundingInfo().boundingBox; mn=mn?BABYLON.Vector3.Minimize(mn,bb.minimumWorld):bb.minimumWorld.clone(); mx=mx?BABYLON.Vector3.Maximize(mx,bb.maximumWorld):bb.maximumWorld.clone(); }
     if(mx.y<-3||mn.y>9) continue; const nm=e.name; if(/tailN|dsTilt|dsSpin|ringNode|Clone of ship/.test(nm)) continue; objs.push({name:'node:'+nm,cx:(mn.x+mx.x)/2,cz:(mn.z+mx.z)/2,r:Math.min(mx.x-mn.x,mx.z-mn.z)/2*.85}); continue; }
   if(e instanceof BABYLON.AbstractMesh){ const nm=e.name; if(SOLID_NAMES.test(nm)&&e.isVisible!==false) add(nm,e); } }
 if(B.map.station){ const p=hexWorld(B.map.station.q,B.map.station.r,0); for(const o of objs) if(o.name.startsWith('node:')&&Math.hypot(o.cx-p.x,o.cz-p.z)<6) o.name='mapStation'; }
 for(const o of objs) if(o.name.startsWith('node:')) o.name='holeNode';
 // replace mesh guesses with the exact footprints the builder used
 for(let i=objs.length-1;i>=0;i--) if(/giantRock|moonlet|cometCore|holeNode|nearPlanet/.test(objs[i].name)) objs.splice(i,1);
 const FP={asteroid:.92,moon:.93,station:1,hulk:.95,comet:.75};
 for(const h of (B.map.holes||[])) if(h.vis) objs.push({name:'fill:'+h.kind,cx:h.vis.x,cz:h.vis.z,r:h.vis.R*(FP[h.kind]||1)});
 if(B.map.planet){ const p=hexWorld(B.map.planet.q,B.map.planet.r,0); objs.push({name:'nearPlanet',cx:p.x,cz:p.z,r:planetEdge(B.map.planet.R)}); }
 // playable hexes whose centre sits inside a solid object
 const H=boardHexes().filter(h=>!blocks(terr(h.q,h.r)));
 for(const h of H){ const p=hexWorld(h.q,h.r,0); for(const o of objs){ if(o.name==='rock') continue; const d=Math.hypot(p.x-o.cx,p.z-o.cz); if(d<o.r-HS*.35){ out.inside.push(o.name); break; } } }
 // units sitting inside a solid object
 for(const u of B.units.filter(x=>!x.dead&&!x.isSq)){ const p=hexWorld(u.q,u.r,0); for(const o of objs){ if(o.name==='rock'&&!blocks(terr(u.q,u.r))) continue; const d=Math.hypot(p.x-o.cx,p.z-o.cz); if(d<o.r-HS*.35) { out.units.push(u.side+':'+o.name); break; } } }
 // big objects overlapping each other (and loose rocks inside big ones)
 const big=objs.filter(o=>o.name!=='rock'&&o.name!=='rockChunk');
 for(let i=0;i<big.length;i++) for(let j=i+1;j<big.length;j++){ const a=big[i],b=big[j]; const d=Math.hypot(a.cx-b.cx,a.cz-b.cz); if(d<(a.r+b.r)*.7) out.overlap.push(a.name+' x '+b.name); }
 for(const o of objs.filter(o=>o.name==='rock')) for(const b of big){ if(Math.hypot(o.cx-b.cx,o.cz-b.cz)<b.r*.8){ out.overlap.push('rock in '+b.name); break; } }
 return out; })()"""
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    pg=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True).new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("G.engine.setHardwareScalingLevel(6); 0")
    shapes=['open','dense','deadstar','shoals','colossus','hourglass','archipelago','rift','ring','lanes']; maps=['belt','station','planet','storm','graveyard']
    tot={}
    for rep in range(REPS):
      for sh in shapes:
        for mp in maps:
          for dep in (['flank','ambush','line'] if rep==0 else ['line']):
            try:
              pg.evaluate(f"ACT.c3skirmish(); setupBattle({{obj:'{'ambush' if dep=='ambush' else 'rout'}',shape:'{sh}',map:'{mp}',dep:'{dep}'}}); 0")
              pg.wait_for_function("!!B&&B.units&&B.map", timeout=60000, polling=300)
              r=pg.evaluate(PROBE)
            except Exception as e:
              print('ERR',sh,mp,str(e)[:120]); continue
            k=sh+'/'+mp; bad=r['inside'] or r['overlap'] or r['units'] or r['stationInCut']
            if bad: print(k,dep,json.dumps({x:r[x] for x in ('holes','stationInCut','inside','units','overlap')}))
            tot[k]=tot.get(k,0)+(1 if bad else 0)
    print('SUMMARY',json.dumps({k:v for k,v in tot.items() if v}))
    print('errors',errs[:3])
