# v53-E world probe: asteroid fields at the battle camera, Ithar hulls (concept meshes, so the page is served over http),
# ship clusters for nameplate clutter, and the smoke scene budget. OUT=dir TAG=prefix MODE=rocks,ithar,cluster,budget ONLY=desk|phone
import os, sys, threading, http.server, socketserver, functools
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); OUT=os.environ.get('OUT','.'); TAG=os.environ.get('TAG','E')
MODES=(os.environ.get('MODE') or 'rocks,ithar,cluster,budget').split(',')
SIZES=[('desk',{'width':1280,'height':800},False),('phone',{'width':412,'height':915},True)]
if os.environ.get('ONLY'): SIZES=[s for s in SIZES if s[0]==os.environ['ONLY']]
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
socketserver.ThreadingTCPServer.daemon_threads=True
srv=socketserver.ThreadingTCPServer(('127.0.0.1',0),functools.partial(Q,directory=HERE)); threading.Thread(target=srv.serve_forever,daemon=True).start()
PAGE='http://127.0.0.1:%d/'%srv.server_address[1]+os.environ.get('PAGEFILE','index_test.html')
HIDE="try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); document.querySelectorAll('.tipcard').forEach(e=>e.remove());"
def battle(pg,cfg,q='medium'):
    pg.evaluate("setQuality('%s'); ACT.c3skirmish(); setupBattle(%s); ACT.begin(); SPEED=.5; G.cine=false; %s 0"%(q,cfg,HIDE))
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=300000, polling=500)
    pg.wait_for_timeout(1500); pg.evaluate(HIDE+"for(const v of G.views.values()){ v.arrive=null; if(v.ring) v.ring.node.setEnabled(true); if(v.root) v.root.setEnabled(true); if(v.plate) v.plate.el.style.visibility=''; } 0")
SNAP="const c=G.cam, k=G.ctl; k.estab=null; k.slowUntil=0; c.target.copyFrom(k.t); c.radius=k.r; c.alpha=k.a; c.beta=k.b; 0"
def cam(pg,js):
    for _ in range(2): pg.evaluate(js); pg.evaluate(SNAP); pg.wait_for_timeout(700)
def shot(pg,name,wait=3000):
    pg.wait_for_timeout(wait); pg.screenshot(path=f'{OUT}/{TAG}_{name}.png', timeout=240000); print('shot',name); sys.stdout.flush()
ROCKCAM="""(()=>{ const ks=Object.entries(B.terrain).filter(([k,t])=>t==='rock').map(([k])=>k.split(',').map(Number)); if(!ks.length) return 'no rocks';
  let best=null,bn=-1; for(const [q,r] of ks){ const n=ks.filter(([a,b])=>hdist({q,r},{q:a,r:b})<=2).length; if(n>bn){ bn=n; best=[q,r]; } }
  const p=hexWorld(best[0],best[1],0); G.ctl.focus(p,%s); G.ctl.b=%s; return 'rock hexes '+ks.length+' focus '+best+' nb '+bn; })()"""
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    for name,vp,mob in SIZES:
        ctx=b.new_context(viewport=vp,is_mobile=mob,has_touch=mob); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200])); pg.on('console',lambda m: errs.append('console: '+m.text[:200]) if m.type=='error' else None)
        pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
        pg.wait_for_function("Object.keys(AI_HULL_DATA).length>=25||(typeof HULLS_LOAD!=='undefined'&&HULLS_LOAD.state==='done')", timeout=400000, polling=1000)
        try: pg.wait_for_function("!document.getElementById('loading')", timeout=20000, polling=500)
        except Exception: pg.evaluate("document.querySelectorAll('#loading,#hullwait').forEach(e=>e.remove()); 0")
        if 'rocks' in MODES:
            for shape in (os.environ.get('SHAPES') or 'dense,split').split(','):
                battle(pg,"{obj:'rout',shape:'%s',map:'belt',pf:'ithar',ef:'hegemony'}"%shape)
                try: pg.wait_for_function("typeof ROCK_LIB==='undefined'||!!ROCK_LIB.sets[ROCK_SET[B.biome&&B.biome.rock]||'RST']", timeout=90000, polling=1000); pg.wait_for_timeout(1500)
                except Exception as e: print('rock library not loaded',str(e)[:80])
                print('facets',pg.evaluate("(B.biome&&B.biome.rock)+' '+G.scene.meshes.filter(m=>/^rockFacet|^rockBaselo|^rockLib/.test(m.name)&&m.isEnabled()).map(m=>m.name+':'+m.thinInstanceCount+':'+m.isVisible+':'+(m.material&&m.material.isReady(m,true))).join(' ')"))
                cam(pg,"G.ctl.reset(); G.ctl.attract=false; G.ctl.estab=null; 0"); shot(pg,f'{name}_rocks_{shape}_wide')
                print(pg.evaluate(ROCKCAM%(90 if not mob else 110,'.86'))); cam(pg,ROCKCAM%(90 if not mob else 110,'.86')); shot(pg,f'{name}_rocks_{shape}_close')
        if 'ithar' in MODES:
            battle(pg,"{obj:'rout',shape:'open',map:'storm',pf:'ithar',ef:'voidsworn'}",'high' if not mob else 'medium')
            cam(pg,"""(()=>{ const u=caps('player').find(x=>x.cls==='Frigate')||caps('player')[0], v=G.views.get(u.id); G.ctl.focus(v.root.position,v.L*2.6); G.ctl.b=.8; G.ctl.a=-Math.PI/2+.7; document.querySelectorAll('#panel,#roster,#log').forEach(e=>e.style.visibility='hidden'); })(); 0"""); shot(pg,f'{name}_ithar_frigate_close')
            cam(pg,"""(()=>{ const u=caps('player').find(x=>x.cls==='Frigate')||caps('player')[0], v=G.views.get(u.id); G.ctl.focus(v.root.position,95); G.ctl.b=.86; G.ctl.a=-Math.PI/2; })(); 0"""); shot(pg,f'{name}_ithar_fleet')
            cam(pg,"""(()=>{ const u=caps('player').find(x=>x.cls==='Cruiser'||x.cls==='Carrier')||caps('player')[0], v=G.views.get(u.id); G.ctl.focus(v.root.position,v.L*2.4); G.ctl.b=.75; G.ctl.a=-Math.PI/2-.6; })(); 0"""); shot(pg,f'{name}_ithar_big_close')
            pg.evaluate("document.querySelectorAll('#panel,#roster,#log').forEach(e=>e.style.visibility=''); 0")
        if 'cluster' in MODES:
            battle(pg,"{obj:'rout',shape:'open',map:'planet',pf:'ithar',ef:'hegemony'}")
            pg.evaluate("""(()=>{ const P=caps('player'), E=caps('enemy'), all=P.concat(E), o=occMap(); let c=null,bd=1e9; const mid=boardHexes().reduce((a,h)=>(a.q+=h.q/boardHexes().length,a.r+=h.r/boardHexes().length,a),{q:0,r:0});
              const free=h=>onBoard(h.q,h.r)&&!blocks(terr(h.q,h.r)); for(const h of boardHexes()){ if(!free(h)||!DIRS.every(D=>free({q:h.q+D[0],r:h.r+D[1]}))) continue; const d=hdist(h,{q:Math.round(mid.q),r:Math.round(mid.r)}); if(d<bd){ bd=d; c=h; } }
              const at=i=>i<0?{q:c.q,r:c.r}:{q:c.q+DIRS[i][0],r:c.r+DIRS[i][1]}; const plan=[[P[0],-1,0],[P[1],0,0],[E[0],2,3],[E[1],1,3],[P[2],4,0],[E[2],3,3]];
              const taken=new Set(plan.map(([w,i])=>hkey(at(i).q,at(i).r))); for(const u of all){ if(plan.some(x=>x[0]===u)||!taken.has(hkey(u.q,u.r))) continue; const occ=occMap(); const h=boardHexes().find(h=>free(h)&&!occ.has(hkey(h.q,h.r))&&hdist(h,c)>4); if(h){ u.q=h.q; u.r=h.r; } }
              for(const [u,i,f] of plan){ if(!u) continue; const h=at(i); u.q=h.q; u.r=h.r; u.facing=f; const v=G.views.get(u.id); if(v){ v.ph=null; v.coast=null; } }
              for(let k=0;k<150;k++) updateWorld(1/30); E[0].hp=Math.round(E[0].hp*.45); E[0].sh=E[0].sh.map(()=>0); if(P[1]) P[1].hp=Math.round(P[1].hp*.7); bRefresh();
              const p=hexWorld(c.q,c.r,0); G.ctl.reset(); G.ctl.t=new V3(p.x,0,p.z); G.ctl.r=Math.min(G.ctl.r,190); G.ctl.attract=false; G.ctl.estab=null; return 'cluster at '+c.q+','+c.r; })()"""); pg.evaluate(SNAP)
            shot(pg,f'{name}_cluster')
            pg.evaluate("selectUnit(caps('player')[0]); bRefresh(); 0"); shot(pg,f'{name}_cluster_sel',2000)
            pg.evaluate("G.ctl.r=G.ctl.r*.62; 0"); shot(pg,f'{name}_cluster_zoom',2500)
        if 'budget' in MODES and name=='desk':
            for mp,sh in (('station',None),('belt','dense')):
                pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(6); G.scene.postProcessesEnabled=false; ACT.c3skirmish(); setupBattle({pf:'voidsworn',ef:'hegemony',map:'%s'%s}); 0"%(mp,(",shape:'%s'"%sh) if sh else ''))
                bud=pg.evaluate("""(async()=>{ const ins=new BABYLON.SceneInstrumentation(G.scene); ins.captureFrameTime=false; for(let i=0;i<6;i++){ G.scene.render(); await new Promise(r=>setTimeout(r,30)); }
                  for(let i=0;i<8;i++){ G.scene.render(); await new Promise(r=>setTimeout(r,40)); } const r={act:G.scene.getActiveMeshes().length, draws:ins.drawCallsCounter.current, meshes:G.scene.meshes.length, rocks:Object.values(B.terrain).filter(t=>t==='rock').length, shape:(B.map||{}).shape}; ins.dispose(); return r; })()""")
                print('budget',mp,sh,bud); sys.stdout.flush()
            pg.evaluate("G.engine.setHardwareScalingLevel(1); G.scene.postProcessesEnabled=true; 0")
        print(name,'errors',errs); ctx.close()
    srv.shutdown()
