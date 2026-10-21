# v53-G close-up studio: every hull alone on the board, camera in close (served over http so the concept meshes load).
# OUT=dir TAG=prefix TPLS=warden,c_boss,... (default: all capital hulls + squadrons) ONLY=desk|phone ZOOM=1.3,2.6 Q=high|medium STATS=1
import os, sys, threading, http.server, socketserver, functools
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); OUT=os.environ.get('OUT','.'); TAG=os.environ.get('TAG','G')
ALL='warden,harrow,penitent,reliquary,cathedral,ascendant,h_picket,h_interdictor,h_vanguard,h_dominion,h_boss,c_raider,c_reaver,c_marauder,c_hulk,c_boss,b_drone,b_spitter,b_razor,b_brood,b_boss,i_wisp,i_blade,i_song,i_carrier,i_boss,d_scythe,d_jackal,d_harvester,d_boss'
TPLS=(os.environ.get('TPLS') or ALL).split(',')
ZOOMS=[float(z) for z in (os.environ.get('ZOOM') or '0.7,1.25').split(',')] # 0.7: the hull fills ~60% of the frame (surface detail); 1.25: whole ship
SIZES=[('desk',{'width':1600,'height':900},False),('phone',{'width':412,'height':915},True)]
if os.environ.get('ONLY'): SIZES=[s for s in SIZES if s[0]==os.environ['ONLY']]
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
srv=socketserver.TCPServer(('127.0.0.1',0),functools.partial(Q,directory=HERE)); threading.Thread(target=srv.serve_forever,daemon=True).start()
PAGE='http://127.0.0.1:%d/'%srv.server_address[1]+os.environ.get('PAGEFILE','index_test.html')+'?shots'
HIDE="try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); document.querySelectorAll('.tipcard,#panel,#roster,#log,#btop,.plate,#terrlegend').forEach(e=>e.style.visibility='hidden');"
# put one hull (tpl, or 'sq:fac:kind' for a wing) alone near the board centre
PLACE="""(tpl=>{ for(const u of B.units.slice()){ const v=G.views.get(u.id); if(v){ disposeView(v); G.views.delete(u.id); } } B.units.length=0;
  const free=h=>onBoard(h.q,h.r)&&!blocks(terr(h.q,h.r)); const hs=boardHexes(), mid=hs.reduce((a,h)=>(a.q+=h.q/hs.length,a.r+=h.r/hs.length,a),{q:0,r:0}); let c=null,bd=1e9; for(const h of hs){ if(!free(h)) continue; const d=hdist(h,{q:Math.round(mid.q),r:Math.round(mid.r)}); if(d<bd){ bd=d; c=h; } }
  if(tpl==='beacon'){ buildBeacon(c); window.__v={root:{position:hexWorld(c.q,c.r,0)},L:22}; return 'beacon'; }
  if(tpl==='station'){ buildMeshStation(hexWorld(c.q,c.r),Math.random); window.__v={root:G.station.root,L:46}; return 'station'; }
  let u; if(tpl.startsWith('tr:')){ const fac=tpl.split(':')[1]; u=makeUnit('enemy',FACTIONS[fac].roster[0]); u.transport=true; } else if(tpl.startsWith('sq:')){ const [,fac,kind]=tpl.split(':'); u=makeUnit('player',kind==='spore'?'spore':kind); u.fac=fac; u.launched=true; } else u=makeUnit('enemy',tpl);
  u.q=c.q; u.r=c.r; u.facing=0; if(window.__dmg) u.hp=Math.max(1,Math.round(u.maxHp*window.__dmg)); B.units.push(u); updateWorld(1/30); const v=G.views.get(u.id); v.arrive=null; if(v.root) v.root.setEnabled(true); if(v.ring) v.ring.node.setEnabled(true); if(v.plate) v.plate.el.style.visibility='hidden'; for(let k=0;k<20;k++) updateWorld(1/30); if(v.root) v.root.setEnabled(true); window.__v=v; return u.name+' L='+v.L; })"""
CAM="""((zf,a,b)=>{ const v=window.__v, c=G.ctl; c.estab=null; c.slowUntil=0; c.follow=null; const p=v.wing?v.wing.getAbsolutePosition():v.root.position, r=v.wing?12*zf:Math.max(9,v.L*zf);
  c.focus(p,r); c.b=b; c.a=a; c.attract=false; G.cam.alpha=a; G.cam.beta=b; G.cam.radius=r; G.cam.target=new V3(p.x,0,p.z); })"""
PROBE="""(()=>{ const v=window.__v, c=v.root.position, out=[]; const own=new Set(v.root.getChildMeshes?v.root.getChildMeshes(false):[]);
  for(const m of G.scene.meshes){ if(own.has(m)||!m.isEnabled()||!m.isVisible||/^(rock|storm|grid|frame|boardUnder|fe|fan|tint|rockBase)/.test(m.name)) continue; let p; try{ p=m.getBoundingInfo().boundingSphere.centerWorld; }catch(e){ continue; } const d=V3.Distance(p,c); if(d<70&&d>3) out.push(m.name+'|'+(m.material&&m.material.name)+'|'+d.toFixed(1)+'|y'+p.y.toFixed(1)); }
  for(const sm of G.scene.spriteManagers||[]) for(const sp of sm.sprites){ if(!sp.isVisible) continue; const d=V3.Distance(sp.position,c); if(d<70) out.push('sprite:'+sm.name+'|'+sp.name+'|'+d.toFixed(1)+'|w'+sp.width.toFixed(1)+'|c'+[sp.color.r,sp.color.g,sp.color.b].map(x=>x.toFixed(2))); }
  for(const ps of G.scene.particleSystems){ const e=ps.emitter; const p=e&&e.position?e.getAbsolutePosition?e.getAbsolutePosition():e:e; if(p&&p.x!==undefined&&V3.Distance(p,c)<70) out.push('ps:'+ps.name); }
  return out.slice(0,90).join('  ;  '); })()"""
STATS="""(async()=>{ const ins=new BABYLON.SceneInstrumentation(G.scene); for(let i=0;i<4;i++){ G.scene.render(); await new Promise(r=>setTimeout(r,30)); } const r={act:G.scene.getActiveMeshes().length, draws:ins.drawCallsCounter.current, meshes:G.scene.meshes.length, mats:G.scene.materials.length}; ins.dispose(); return r; })()"""
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    for name,vp,mob in SIZES:
        ctx=b.new_context(viewport=vp,is_mobile=mob,has_touch=mob); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
        pg.on('console',lambda m: errs.append('console:'+m.text[:200]) if m.type in ('error','warning') and 'AI hull' in m.text else None)
        pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
        pg.wait_for_function("Object.keys(AI_HULL_DATA).length>=25", timeout=150000, polling=1000)
        q=os.environ.get('Q') or ('medium' if mob else 'high')
        pg.evaluate("setQuality('%s'); ACT.c3skirmish(); setupBattle({obj:'rout',shape:'open',map:'storm',pf:'voidsworn',ef:'hegemony',small:true}); ACT.begin(); SPEED=.5; G.cine=false; %s 0"%(q,HIDE))
        pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500); pg.wait_for_timeout(1500); pg.evaluate(HIDE+'0')
        if os.environ.get('DMG'): pg.evaluate('window.__dmg=%s'%os.environ['DMG'])
        for tpl in TPLS:
            print(tpl, pg.evaluate(PLACE+"('%s')"%tpl)); sys.stdout.flush()
            for zf in ZOOMS:
                pg.evaluate(CAM+"(%s,%s,%s)"%(zf,os.environ.get('CA','-Math.PI/2+.75'),os.environ.get('CB','.95'))); pg.evaluate(HIDE+'0'); pg.wait_for_timeout(2500)
                if os.environ.get('STATS'): print('  stats',pg.evaluate(STATS))
                if tpl.startswith('sq:'): pg.evaluate(CAM+"(%s,%s,%s)"%(zf,os.environ.get('CA','-Math.PI/2+.75'),os.environ.get('CB','.95'))); pg.wait_for_timeout(200)
                if os.environ.get('PROBE'): print('  probe',pg.evaluate(PROBE))
                fn=f'{OUT}/{TAG}_{name}_{tpl.replace(":","-")}_{zf}.png'; pg.screenshot(path=fn, timeout=240000); print('  shot',fn); sys.stdout.flush()
        print(name,'errors',errs); ctx.close()
    srv.shutdown()
