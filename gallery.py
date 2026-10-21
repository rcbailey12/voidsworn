# v53-H asset gallery: renders every visual asset the game generates or loads at three zooms (close: the asset fills the frame,
# mid: a few hexes around it, board: the normal battle camera) at 1600x900, plus a phone (412x915) mid shot of every faction,
# and writes OUT/<group>_<asset>_<zoom>.png and an OUT/index.html contact sheet with what each asset is built from.
#
# Run:  OUT=gallery python3 gallery.py            (OUT is relative to the working directory; default ./gallery_out)
# Env:  ONLY=ships_voidsworn,fx_death   comma list of name prefixes (group, group_asset or full name) to render a subset
#       ZOOMS=close,mid,board   SEED=7   Q=ultra|high|medium   PHONE=0 to skip the phone pass   LIMIT=n (first n assets)
#       GPU=auto|1|0  (auto: real GPU on Windows/macOS, SwiftShader on Linux)   SCALE=n  render scale divisor (2 = half res, for slow machines)
#       PAGEFILE=index_test.html (built with `python3 build.py test` if missing)   HEADLESS=0 to watch it
# The page is served over http from this folder so the concept-art hulls (hulls/, hulls_hi/) load as they do in the published game.
# Deterministic: Math.random and the rules RNG are seeded, so the same SEED gives the same fleets, boards and set pieces.
import os, sys, json, time, html, platform, threading, subprocess, functools, http.server, socketserver, traceback
from playwright.sync_api import sync_playwright

HERE=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.abspath(os.environ.get('OUT','gallery_out')); os.makedirs(OUT,exist_ok=True)
SEED=int(os.environ.get('SEED','7'))
ONLY=[s.strip() for s in os.environ.get('ONLY','').split(',') if s.strip()]
ZOOMS=[z.strip() for z in os.environ.get('ZOOMS','close,mid,board').split(',') if z.strip()]
LIMIT=int(os.environ.get('LIMIT','0') or 0)
GPU=os.environ.get('GPU','auto'); GPU=(platform.system()!='Linux') if GPU=='auto' else GPU=='1'
Q=os.environ.get('Q','ultra' if GPU else 'high')
SCALE=float(os.environ.get('SCALE','1') or 1)
PHONE=os.environ.get('PHONE','1')!='0'
HEADLESS=os.environ.get('HEADLESS','1')!='0'
PAGEFILE=os.environ.get('PAGEFILE','index_test.html')
W,H=1600,900
T0=time.time()

if not os.path.exists(os.path.join(HERE,PAGEFILE)) and PAGEFILE=='index_test.html':
    subprocess.run([sys.executable,'build.py','test'],cwd=HERE,check=False)

class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
srv=socketserver.ThreadingTCPServer(('127.0.0.1',0),functools.partial(Quiet,directory=HERE)); srv.daemon_threads=True
threading.Thread(target=srv.serve_forever,daemon=True).start()
PAGE='http://127.0.0.1:%d/%s?shots=1'%(srv.server_address[1],PAGEFILE)

def wanted(name):
    if not ONLY: return True
    return any(name.startswith(p) for p in ONLY)
def cname(cls): return cls.replace(' ','').replace('-','')

# seeded Math.random before any page script runs (mulberry32)
SEED_JS="""(()=>{ let s=%d>>>0; Math.random=function(){ s=(s+0x6D2B79F5)>>>0; let t=s; t=Math.imul(t^(t>>>15),t|1); t^=t+Math.imul(t^(t>>>7),t|61); return ((t^(t>>>14))>>>0)/4294967296; }; })();"""%SEED

# the in-page helper library: camera snapping, a studio (an emptied battle you place ships into), set-piece builds and effect triggers
LIB=r"""
window.GAL=(()=>{ const S={made:[]};
  const raf=()=>new Promise(r=>requestAnimationFrame(()=>r()));
  S.frames=async n=>{ for(let i=0;i<(n||2);i++) await raf(); };
  S.sleep=ms=>new Promise(r=>setTimeout(r,ms));
  S.css=()=>{ if(document.getElementById('galcss')) return; const st=document.createElement('style'); st.id='galcss';
    st.textContent='body.galhud .hud,body.galhud #plates,body.galhud #banner,body.galhud .tip,body.galhud #tip,body.galhud .tipcard,body.galhud #app,body.galhud .intro,body.galhud #loading,body.galhud .toast,body.galhud #terrlegend,body.galhud .lb,body.galhud #cineSkip,body.galhud .ftxt{display:none!important}';
    document.head.appendChild(st); document.body.classList.add('galhud'); };
  // camera: set the controller and the camera together, so nothing eases between frames
  S.cam=(t,r,a,b)=>{ const c=G.ctl; c.attract=false; c.estab=null; c.saved=null; c.slowUntil=0; c.t=new V3(t.x,t.y||0,t.z); c.r=r; c.a=a; c.b=b;
    G.cam.alpha=a; G.cam.beta=b; G.cam.radius=r; G.cam.target.copyFrom(c.t); G.shake=0; };
  S.boardCam=t=>S.cam({x:t.x,y:0,z:t.z},215,-Math.PI/2,.86);
  S.zoomCam=(zoom,p,close,mid,a,b,home)=>{ if(zoom==='close') S.cam(p,close,a,b); else if(zoom==='mid') S.cam(p,mid,a,Math.min(b,.95)); else if(home) S.homeCam(); else S.boardCam(p); };
  S.settle=n=>{ for(let k=0;k<(n||8);k++) updateWorld(1/30); for(const v of G.views.values()){ v.arrive=null; if(v.ring) v.ring.node.setEnabled(true); if(v.root) v.root.setEnabled(true); } G.jumpUntil=0; };
  S.battle=async cfg=>{ rndSeed(cfg.seed); try{ hideApp(); }catch(e){} setupBattle(Object.assign({alt:false,small:false,obj:'rout',shape:'open',dep:'line',arena:'strip'},cfg.setup));
    try{ showIntro(); }catch(e){} try{ ACT.begin(); }catch(e){} try{ ACT.tipOff&&ACT.tipOff(); }catch(e){}
    SPEED=1; G.cine=false; G.follow=false; G.fxReduced=false; document.querySelectorAll('.tipcard,.intro').forEach(e=>e.remove()); document.body.classList.remove('intro-on');
    S.settle(3); B.sel=null; B.inspect=null; B.hover=null; try{ clearOverlays(); refreshOverlays(); }catch(e){} await S.frames(3);
    const t=Object.values(B.terrain||{}).reduce((a,k)=>(a[k]=(a[k]||0)+1,a),{});
    return {map:B.map&&B.map.map, shape:B.map&&B.map.shape, terrain:t, biome:B.biome, units:B.units.length}; };
  // studio: the battle's environment stays, its ships go; assets are placed on clear hexes
  S.clear=()=>{ try{ disposeAllViews(); }catch(e){} B.units=[]; B.sel=null; B.inspect=null; B.hover=null; B.reach=null; B.aiFocus=null; B.showThreat=false; try{ clearOverlays(); refreshOverlays(); }catch(e){} };
  S.free=h=>onBoard(h.q,h.r)&&!terr(h.q,h.r);
  // n clear hexes in one row near the middle, gap hexes apart (closer if the board is crowded)
  S.row=(n,gap)=>{ const rows={}; for(const h of boardHexes()) (rows[h.r]=rows[h.r]||[]).push(h); const mid=Math.round(BH/2);
    const order=Object.keys(rows).map(Number).sort((a,b)=>Math.abs(a-mid)-Math.abs(b-mid));
    for(let g=gap;g>=1;g--) for(const strict of [true,false]) for(const r of order){ const line=rows[r].filter(h=>S.free(h)&&(!strict||S.free({q:h.q,r:h.r-1})&&S.free({q:h.q,r:h.r+1}))).sort((a,b)=>a.q-b.q); const pick=[];
      for(const h of line) if(!pick.length||h.q-pick[pick.length-1].q>=g) pick.push(h); if(pick.length>=n){ const s=Math.floor((pick.length-n)/2); return pick.slice(s,s+n); } }
    return boardHexes().filter(S.free).slice(0,n); };
  S.place=(tpl,fac,h,side,facing)=>{ const u=makeUnit(side||'player',tpl,{fac}); if(fac) u.fac=fac; u.q=h.q; u.r=h.r; u.facing=facing==null?(side==='enemy'?3:0):facing; B.units.push(u); G.jumpUntil=0; updateWorld(1/60);
    const v=G.views.get(u.id); if(v){ v.arrive=null; v.ph=null; v.coast=null; } return u; };
  S.U=id=>B.units.find(u=>u.id===id);
  S.V=id=>G.views.get(id);
  S.face=(u,deg)=>{ u.facing=((Math.round(deg/60)%6)+6)%6; const v=G.views.get(u.id); if(v){ v.ph=null; v.lastA=null; } };
  S.angTo=(a,b)=>{ const p=hexWorld(a.q,a.r), q=hexWorld(b.q,b.r); return Math.atan2(-(q.z-p.z),q.x-p.x)*180/Math.PI; };
  // which classes exist: the first template of every faction|class (squadrons separately)
  S.manifest=()=>{ const ships={}, facs=Object.keys(FAC3D); for(const [id,h] of Object.entries(HULLS)){ const f=h.fac||'voidsworn'; if(h.cls==='Squadron') continue; const k=f+'|'+h.cls; if(!ships[k]) ships[k]={tpl:id,fac:f,cls:h.cls,len:CLS_LEN[h.cls]||14,boss:!!h.boss,concept:(typeof AI_HULLS!=='undefined'&&AI_HULLS[k])||null}; }
    const order=Object.values(ships).sort((a,b)=>facs.indexOf(a.fac)-facs.indexOf(b.fac)||a.len-b.len);
    const sq={}; for(const [id,h] of Object.entries(HULLS)) if(h.cls==='Squadron') sq[h.sq||id]=id;
    return {facs,ships:order,sq,hullsLoaded:typeof AI_HULL_DATA!=='undefined'?Object.keys(AI_HULL_DATA).length:0,hullsWanted:typeof AI_HULLS!=='undefined'?Object.keys(AI_HULLS).length:0,
      renderer:(()=>{ try{ const gl=G.engine._gl, x=gl.getExtension('WEBGL_debug_renderer_info'); return x?gl.getParameter(x.UNMASKED_RENDERER_WEBGL):gl.getParameter(gl.RENDERER); }catch(e){ return '?'; } })(), webgl:G.engine.webGLVersion, build:typeof BUILD_ID!=='undefined'?BUILD_ID:'?', quality:G.quality, mobile:!!G.mobile}; };
  S.meta=u=>{ const v=G.views.get(u.id); if(!v) return {}; const k=u.fac+'|'+u.cls, p=typeof MODEL_CACHE!=='undefined'?MODEL_CACHE[k]:null, all=v.root.getChildMeshes(false);
    return {key:k,tpl:u.tpl,concept:!!((p&&p.aiHull)||(v.model&&v.model.aiHull)),conceptId:(typeof AI_HULLS!=='undefined'&&AI_HULLS[k])||null,meshes:all.length,verts:all.reduce((a,m)=>a+(m.getTotalVertices?m.getTotalVertices():0),0),
      parts:[...new Set(all.map(m=>m.name.replace(/[0-9_.-]+$/,'')))].slice(0,16),mats:[...new Set(all.map(m=>m.material&&m.material.name).filter(Boolean))].slice(0,12),turrets:(v.model&&v.model.turrets||[]).length,L:v.L}; };
  S.fleetRow=(fac,list,sq)=>{ S.clear(); const n=list.length+sq.length, hs=S.row(n,3), ids={}; let i=0;
    for(const s of list) ids[s.cls]=S.place(s.tpl,fac,hs[i++],'player',0).id;
    for(const [kind,tpl] of sq) ids['sq_'+kind]=S.place(tpl,fac,hs[i++],'player',0).id;
    S.settle(12); return ids; };
  S.shipCam=(id,zoom,view)=>{ const u=S.U(id), v=S.V(id); if(!u||!v) return false; const p=v.root.getAbsolutePosition(), L=u.isSq?5:(v.L||8), head=-(u.facing||0)*Math.PI/3;
    const a=(view==='stern'?Math.PI+.85:.9)+head; S.zoomCam(zoom,p,u.isSq?13:Math.max(8,L*1.2),L*2.4+48,a,u.isSq?1.0:1.08); return true; };
  // set pieces built straight into the scene, out past the rim, then removed again
  S.spot=i=>new V3(-150,0,-G.bz-170);
  S.homeCam=()=>S.cam(G.home||new V3(0,0,0),215,-Math.PI/2,.86);
  S.build=(kind,i)=>{ const n0=G.env.length, rr=seeded(%SEED%*31+i*7+3), c=S.spot(i), R=HS*2.6; let size=R;
    if(kind==='station_ring') buildRingStation(c,rr), size=18; else if(kind==='station_rig') buildRigStation(c,rr), size=18; else if(kind==='station_spire') buildSpireStation(c,rr), size=20;
    else if(kind==='beacon'){ const h=worldHex(c.x,c.z); buildBeacon(h); size=10; }
    else if(kind==='deadstar'){ buildDeadStar(c); size=44; }
    else if(HOLE_BUILD[kind.replace('hole_','')]) HOLE_BUILD[kind.replace('hole_','')](c,R,rr);
    S.made=G.env.slice(n0); return {p:{x:c.x,y:kind==='beacon'?8:0,z:c.z},size,meshes:S.made.length}; };
  S.unbuild=()=>{ for(const m of S.made){ try{ if(m&&m.dispose) m.dispose(); }catch(e){} } G.env=G.env.filter(m=>!S.made.includes(m)); S.made=[]; if(G.rocks) G.rocks=G.rocks.filter(r=>!r.isDisposed||!r.isDisposed()); G.beacon=null; };
  // effects: weapons fire, deaths, shields
  S.fire=(aid,tid,wi,hit,shield)=>{ const u=S.U(aid), t=S.U(tid); const w=u.weapons[wi]; t.sh=shield?[t.shMax,t.shMax,t.shMax,t.shMax]:[0,0,0,0]; for(const x of [u,t]) x.hp=x.maxHp;
    const want=w.arc==='F'?0:w.arc==='P'?90:w.arc==='S'?-90:null; if(want!=null) S.face(u,S.angTo(u,t)+want); S.face(t,S.angTo(t,u)+90); S.settle(10);
    const shots=[]; for(let i=0;i<Math.max(2,Math.min(4,w.shots||3));i++) shots.push(hit!==false||i%2===0);
    window.__fx=(async()=>{ try{ await animWeapon(u,w,t,shots); }catch(e){ console.warn('gal fire',e); } })(); return {k:w.k,id:w.id,arc:w.arc}; };
  S.kill=(id,cause)=>{ const u=S.U(id); if(!u) return false; u.killCause=cause; u.dead=true; window.__fx=(async()=>{ try{ await animExplode(u); }catch(e){ console.warn('gal kill',e); } })(); return true; };
  S.midCam=(aid,tid,zoom)=>{ const a=S.V(aid).root.getAbsolutePosition(), b=S.V(tid).root.getAbsolutePosition(), m=a.add(b).scale(.5), d=V3.Distance(a,b), ang=Math.atan2(b.z-a.z,b.x-a.x);
    S.zoomCam(zoom,m,d*1.05+18,d*1.9+70,ang-Math.PI/2-.5,1.0); };
  S.objCam=(p,size,zoom,a,b,home)=>S.zoomCam(zoom,p,size*2.3+6,size*5+70,a==null?Math.PI/2-.45:a,b==null?1.08:b,home);
  return S; })();
"""

results=[]; errors=[]; phone=[]
def rec(group,asset,zoom,path,meta=None,note=''):
    results.append({'group':group,'asset':asset,'zoom':zoom,'file':os.path.basename(path) if path else None,'meta':meta or {},'note':note})

def launch(p):
    args=['--ignore-gpu-blocklist']
    if GPU: args+=['--enable-gpu-rasterization','--enable-zero-copy','--use-angle=default']
    else: args+=['--use-angle=swiftshader','--enable-unsafe-swiftshader']
    if GPU:
        try: return p.chromium.launch(headless=HEADLESS,channel='chromium',args=args)  # new headless mode keeps the real GPU
        except Exception as e: print('chromium channel unavailable, plain launch:',str(e)[:120])
    return p.chromium.launch(headless=HEADLESS,args=args)

def boot(b,vp,mob):
    ctx=b.new_context(viewport=vp,is_mobile=mob,has_touch=mob,device_scale_factor=1)
    ctx.add_init_script(SEED_JS)
    pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:220]))
    pg.goto(PAGE,wait_until='commit')
    pg.wait_for_function("!!document.querySelector('.title .menu')",timeout=240000,polling=500)
    try: pg.wait_for_function("typeof AI_HULLS==='undefined'||Object.keys(AI_HULL_DATA).length>=Object.keys(AI_HULLS).length",timeout=120000,polling=500)
    except Exception: print('warning: not every concept hull loaded')
    try: pg.wait_for_function("!document.getElementById('loading')",timeout=60000,polling=500)
    except Exception: pass
    pg.evaluate(LIB.replace('%SEED%',str(SEED)))
    pg.evaluate("GAL.css(); setQuality(%s); %s 0"%(json.dumps(Q if not mob else 'medium'),("G.engine.setHardwareScalingLevel(G.engine.getHardwareScalingLevel()*%g);"%SCALE) if SCALE!=1 else ''))
    return ctx,pg,errs

def shot(pg,name):
    path=os.path.join(OUT,name+'.png'); pg.screenshot(path=path,timeout=240000); return path

def snap(pg,js,frames=3,wait=0):
    pg.evaluate("(async()=>{ %s; await GAL.frames(%d); })()"%(js,frames))
    if wait: pg.wait_for_timeout(wait)

def run_static(pg,group,asset,cam_js,meta=None,note='',frames=4,wait=150):
    """three zooms of something that holds still; cam_js(zoom) returns the camera call"""
    name0=group+'_'+asset
    for z in ZOOMS:
        name=name0+'_'+z
        try:
            snap(pg,cam_js(z),frames,wait); rec(group,asset,z,shot(pg,name),meta,note)
        except Exception as e: errors.append(name+': '+str(e)[:200]); rec(group,asset,z,None,meta,'failed: '+str(e)[:120])

def run_fx(pg,group,asset,trigger_js,cam_js,t0,meta=None,note='',gap=0,tail=900):
    """an effect is triggered once and caught at the three zooms in quick succession (t0 ms after the trigger)"""
    name0=group+'_'+asset
    try: info=pg.evaluate(trigger_js)
    except Exception as e: errors.append(name0+' trigger: '+str(e)[:200]); return
    if isinstance(info,dict): meta=dict(meta or {},**info)
    pg.wait_for_timeout(t0)
    for z in ZOOMS:
        name=name0+'_'+z
        try:
            snap(pg,cam_js(z),1,gap); rec(group,asset,z,shot(pg,name),meta,note)
        except Exception as e: errors.append(name+': '+str(e)[:200]); rec(group,asset,z,None,meta,'failed: '+str(e)[:120])
    pg.wait_for_timeout(tail)

def battle(pg,setup,seed_off=0):
    info=pg.evaluate("GAL.battle(%s)"%json.dumps({'seed':SEED*101+seed_off,'setup':setup}))
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy",timeout=120000,polling=250)
    return info

TECH={ # how each group is built, for the contact sheet
 'ships':'Concept mesh (FLUX -> Hunyuan3D -> hulls/*.json, baked AO) over a procedural builder that still runs for anchors (guns, engines, nav lights, turrets); procedural only where no mesh exists',
 'squad':'Procedural craft (SB builder), merged once per faction and kind, drawn as instances; three craft orbit the wing root',
 'engines':'Shader plume cones (PLUME_GLSL) + billboard flare + engine point light (High/Ultra, opening fleet only)',
 'damage':'Per-ship cloned hull materials with burn and crack shader (HullFxPlugin dmg), ParticleSystem fires and vents, pooled sparks, scorch decal planes',
 'fx_weapon':'Instanced bolt spheres + pooled sprites (muzzle, impact, sparks), fxStreak planes, shader lance beams, torpedo meshes with ParticleSystem + TrailMesh',
 'fx_shield':'Pooled shield dome ShaderMaterial (hex ripple), shard instances, tube ring segments',
 'fx_death':'Staged pre-blasts, shader fireballs (FIRE_GLSL), pooled sprite fireball/smoke, shock ring shader, fragmentHull jagged sections, thin-instance debris',
 'board':'Line-system hex grid + merged smoked-glass plate, thin-instanced side footprints and contact shadows, hull gauge mesh',
 'ui':'Overlay tiles (instanced discs/tori), reach outline mesh, arc fans, aim tubes, ghost clone, focus brackets',
 'setpiece':'Procedural SB kit (stations, derelicts), HOLE_BUILD set pieces (lumpy icosphere rocks, moonlet, comet), beacon primitives, dead star discs',
 'world':'Battle environment as generated for that map: rocks (icosphere noise bodies, thin instances), rim fill, belt, storms, nebula cards, near planet shader, dead star, wrecks',
 'backdrop':'Sky ShaderMaterial (domain-warped fbm), point-sprite stars, billboard sun/halo/galaxy, lens flare, procedural planet shader, nebula bank cards',
 'phone':'Medium quality, phone viewport (412x915), the faction fleet from behind as the portrait camera frames it'}

def main():
    with sync_playwright() as p:
        b=launch(p)
        ctx,pg,perrs=boot(b,{'width':W,'height':H},False)
        man=pg.evaluate("GAL.manifest()"); print('renderer',man['renderer'],'hulls',man['hullsLoaded'],'/',man['hullsWanted'],'build',man['build'],'boot',round(time.time()-T0,1),'s'); sys.stdout.flush()
        if GPU and 'swiftshader' in str(man['renderer']).lower():
            errors.append('GPU was requested but the page is on SwiftShader (software); rerun with HEADLESS=0 to use the real GPU')
            print('WARNING:',errors[-1]); sys.stdout.flush()
        if man['hullsLoaded']<man['hullsWanted']: errors.append('only %s of %s concept hulls loaded: missing ones render procedural'%(man['hullsLoaded'],man['hullsWanted']))
        ships=man['ships']; facs=man['facs']; sq=man['sq']
        sqk=[('fighter',sq.get('fighter')),('bomber',sq.get('bomber'))]; sqk=[x for x in sqk if x[1]]
        n_assets=[0]
        def ok(name):
            if not wanted(name): return False
            if LIMIT and n_assets[0]>=LIMIT: return False
            n_assets[0]+=1; return True

        # ---------- studio: one open battle; ships, squadrons, engines, damage, weapons, shields, deaths, board and UI, set pieces, backdrop ----------
        studio_groups=['ships','squad','engines','damage','fx_weapon','fx_shield','fx_death','board','ui','setpiece','backdrop']
        if any(wanted(g) or any(o.startswith(g) for o in ONLY) for g in studio_groups):
            info=battle(pg,{'map':'planet','shape':'open','pf':'voidsworn','ef':'hegemony'})
            print('studio',info); sys.stdout.flush()
            for fac in facs:
                fl=[s for s in ships if s['fac']==fac]
                names=['ships_%s_%s'%(fac,cname(s['cls'])) for s in fl]+['squad_%s_%s'%(fac,k) for k,_ in sqk]+['engines_%s'%fac,'damage_%s'%fac]
                if not any(wanted(n) for n in names): continue
                big=fl[-1] if not fl[-1]['boss'] or len(fl)<2 else fl[-2]
                needbig=wanted('engines_%s'%fac) or wanted('damage_%s'%fac)
                row=[s for s in fl if wanted('ships_%s_%s'%(fac,cname(s['cls']))) or (needbig and s is big)]  # the full run places the whole fleet
                ids=pg.evaluate("GAL.fleetRow(%s,%s,%s)"%(json.dumps(fac),json.dumps(row),json.dumps([x for x in sqk if wanted('squad_%s_%s'%(fac,x[0]))])))
                for s in row:
                    a=cname(s['cls'])
                    if not ok('ships_%s_%s'%(fac,a)): continue
                    uid=ids[s['cls']]; meta=pg.evaluate("GAL.meta(GAL.U(%s))"%json.dumps(uid))
                    run_static(pg,'ships',fac+'_'+a,lambda z,uid=uid:"GAL.shipCam(%s,%s)"%(json.dumps(uid),json.dumps(z)),meta,'concept mesh '+str(meta.get('conceptId')) if meta.get('concept') else 'PROCEDURAL (no concept mesh)')
                for k,_ in sqk:
                    if not ok('squad_%s_%s'%(fac,k)): continue
                    uid=ids['sq_'+k]; meta=pg.evaluate("GAL.meta(GAL.U(%s))"%json.dumps(uid))
                    run_static(pg,'squad',fac+'_'+k,lambda z,uid=uid:"GAL.shipCam(%s,%s)"%(json.dumps(uid),json.dumps(z)),meta,'procedural craft',frames=2,wait=60)
                if ok('engines_%s'%fac):
                    uid=ids[big['cls']]
                    run_static(pg,'engines',fac,lambda z,uid=uid:"GAL.shipCam(%s,%s,'stern')"%(json.dumps(uid),json.dumps(z)),{'ship':big['cls']},'stern view of the '+big['cls'])
                if ok('damage_%s'%fac):
                    uid=ids[big['cls']]
                    pg.evaluate("(()=>{ const u=GAL.U(%s); u.hp=Math.round(u.maxHp*.28); u.sh=[0,u.shMax*.5,0,u.shMax]; for(let i=0;i<40;i++) updateWorld(1/30); })()"%json.dumps(uid))
                    pg.wait_for_timeout(700)
                    run_static(pg,'damage',fac,lambda z,uid=uid:"GAL.shipCam(%s,%s)"%(json.dumps(uid),json.dumps(z)),{'ship':big['cls'],'hull':'28%'},'burning at 28% hull')
            # weapons: every distinct weapon kind the faction fields (largest ship that carries it), fired at a cruiser three hexes off its arc
            for fac in facs:
                fl=[s for s in ships if s['fac']==fac and not s['boss']][::-1]
                if not fl: continue
                tgt_f='hegemony' if fac!='hegemony' else 'voidsworn'
                tgt=[s for s in ships if s['fac']==tgt_f and s['cls']=='Cruiser'][0]
                kinds=pg.evaluate("(L=>{ const seen={}, out=[]; for(const [tpl,cls] of L){ const u=makeUnit('player',tpl,{}); u.weapons.forEach((w,i)=>{ const k=w.k; if(k==='flak'||k==='sq'||seen[k]) return; seen[k]=1; out.push([k,i,w.id,tpl,cls]); }); } return out; })(%s)"%json.dumps([[x['tpl'],x['cls']] for x in fl]))
                names=['fx_weapon_%s_%s'%(fac,k[0]) for k in kinds]+['fx_shield_%s'%fac]
                if not kinds or not any(wanted(n) for n in names): continue
                for k,wi,wid,tpl,cls in kinds+[('shield',kinds[0][1],kinds[0][2],kinds[0][3],kinds[0][4])]:
                    nm=('fx_shield_%s'%fac) if k=='shield' else ('fx_weapon_%s_%s'%(fac,k))
                    if not ok(nm): continue
                    ids=pg.evaluate("(()=>{ GAL.clear(); const h=GAL.row(1,3)[0]; const a=GAL.place(%s,%s,h,'player',0); let th={q:h.q+2,r:h.r-3}; if(!GAL.free(th)) th={q:h.q-1,r:h.r+3}; if(!GAL.free(th)) th=boardHexes().find(x=>GAL.free(x)&&hdist(x,h)===3); const t=GAL.place(%s,%s,th,'enemy',3); GAL.settle(12); return {a:a.id,t:t.id}; })()"%(json.dumps(tpl),json.dumps(fac),json.dumps(tgt['tpl']),json.dumps(tgt_f)))
                    t0={'lance':520,'torp':720,'gauss':260}.get(k,420)
                    run_fx(pg,'fx_shield' if k=='shield' else 'fx_weapon',fac if k=='shield' else '%s_%s'%(fac,k),"GAL.fire(%s,%s,%d,true,%s)"%(json.dumps(ids['a']),json.dumps(ids['t']),wi,'true' if k=='shield' else 'false'),
                           lambda z,ids=ids:"GAL.midCam(%s,%s,%s)"%(json.dumps(ids['a']),json.dumps(ids['t']),json.dumps(z)),t0,{'ship':cls,'weapon':wid},
                           (cls+' fires '+wid+(' into full shields (dome ripple)' if k=='shield' else ' (hull hits)')),tail=1400 if k=='torp' else 900)
            if ok('fx_shield_break'):
                ids=pg.evaluate("(()=>{ GAL.clear(); const h=GAL.row(1,3)[0]; const t=GAL.place(%s,'ithar',h,'enemy',3); GAL.settle(10); return {t:t.id}; })()"%json.dumps([s for s in ships if s['fac']=='ithar' and s['cls']=='Cruiser'][0]['tpl']))
                run_fx(pg,'fx_shield','break',"(()=>{ const u=GAL.U(%s); fxShieldBreak(u,1); return {}; })()"%json.dumps(ids['t']),
                       lambda z,ids=ids:"GAL.shipCam(%s,%s)"%(json.dumps(ids['t']),json.dumps(z)),180,{},'a facing collapses: dome, hex shards, burst')
            # deaths: one per cause
            causes=[('blast','voidsworn','Battleship'),('cut','hegemony','Battleship'),('big','corsair','Cruiser'),('flay','deathless','Cruiser'),('melt','chorus','Cruiser'),('dark','ithar','Cruiser')]
            for cause,fac,cls in causes:
                if not ok('fx_death_%s'%cause): continue
                s=[x for x in ships if x['fac']==fac and x['cls']==cls]
                if not s: continue
                s=s[0]; L=s['len']; pre=(500+L*12) if cause!='blast' and cause!='big' else (700+L*14 if cause=='blast' else 0)
                uid=pg.evaluate("(()=>{ GAL.clear(); const h=GAL.row(1,3)[0]; const u=GAL.place(%s,%s,h,'enemy',3); GAL.settle(10); return u.id; })()"%(json.dumps(s['tpl']),json.dumps(fac)))
                pg.evaluate("(()=>{ const v=GAL.V(%s); window.__dp=v.root.getAbsolutePosition().clone(); window.__dL=v.L; })()"%json.dumps(uid))
                run_fx(pg,'fx_death',cause,"GAL.kill(%s,%s)"%(json.dumps(uid),json.dumps(cause)),
                       lambda z:"GAL.zoomCam(%s,window.__dp,window.__dL*1.7+12,window.__dL*3.4+70,.9,1.0)"%json.dumps(z),int(pre+260),{'ship':fac+' '+cls,'cause':cause},'killCause '+cause,gap=40,tail=1600)
            # board and UI overlays: two of yours against two of theirs, close enough to interact
            ui_names=['board_grid','board_marks','ui_select','ui_aim','ui_inspect','ui_threat','ui_focus','ui_ghost']
            if any(wanted(n) for n in ui_names):
                pf=[s for s in ships if s['fac']=='voidsworn' and not s['boss']]; ef=[s for s in ships if s['fac']=='hegemony' and not s['boss']]
                ids=pg.evaluate("""(()=>{ GAL.clear(); const hs=GAL.row(2,2), P=[], E=[]; P.push(GAL.place(%s,'voidsworn',hs[0],'player',0)); P.push(GAL.place(%s,'voidsworn',hs[1],'player',0));
                   const e1={q:hs[1].q+2,r:hs[1].r-2}, e2={q:hs[1].q+3,r:hs[1].r}; for(const [h,t] of [[e1,%s],[e2,%s]]){ const hh=GAL.free(h)?h:boardHexes().find(x=>GAL.free(x)&&hdist(x,hs[1])>=2&&hdist(x,hs[1])<=4&&!E.some(e=>e.q===x.q&&e.r===x.r)); E.push(GAL.place(t,'hegemony',hh,'enemy',3)); }
                   P[1].hp=Math.round(P[1].maxHp*.55); E[0].hp=Math.round(E[0].maxHp*.3); GAL.settle(12); return {p:P.map(u=>u.id),e:E.map(u=>u.id)}; })()"""%(json.dumps(pf[1]['tpl']),json.dumps(pf[-1]['tpl']),json.dumps(ef[1]['tpl']),json.dumps(ef[-1]['tpl'])))
                cen="GAL.V(%s).root.getAbsolutePosition()"%json.dumps(ids['p'][1])
                cam=lambda z:"GAL.zoomCam(%s,%s,48,120,-Math.PI/2+.25,.95)"%(json.dumps(z),cen)
                steps=[('board','grid',"B.sel=null; B.inspect=null; B.hover=null; clearOverlays(); refreshOverlays();",'grid, smoked-glass plate, footprints, contact shadows, hull gauges'),
                       ('ui','select',"const u=GAL.U(%s); selectUnit(u); B.reach=markRamSpots(u,bestFacingReach(u,computeReach(u))); refreshOverlays();"%json.dumps(ids['p'][1]),'selected ship: move outline, gun hexes, arc fans, target rings'),
                       ('ui','aim',"const e=GAL.U(%s); B.hover={q:e.q,r:e.r}; refreshHover();"%json.dumps(ids['e'][0]),'hovered enemy: aim line / blocked LOS marker'),
                       ('ui','ghost',"const u=GAL.U(%s); B.hover=null; let pick=null; for(const st of B.reach.map.values()){ if(unitAt(st.q,st.r)) continue; if(!pick||hdist(st,u)>hdist(pick,u)) pick=st; } if(pick){ B.hover={q:pick.q,r:pick.r}; refreshHover(); }"%json.dumps(ids['p'][1]),'move preview: ghost hull and dashed path'),
                       ('ui','inspect',"B.sel=null; B.reach=null; B.hover=null; B.inspect=GAL.U(%s); refreshOverlays();"%json.dumps(ids['e'][1]),'tapped enemy: its reach next move'),
                       ('ui','threat',"B.inspect=null; B.showThreat=true; refreshOverlays();",'threat overlay'),
                       ('ui','focus',"B.showThreat=false; B.aiFocus=GAL.U(%s); refreshOverlays(); updateOverlays();"%json.dumps(ids['p'][0]),'enemy focus brackets on your ship')]
                for g,a,js,note in steps:
                    if not ok(g+'_'+a): continue
                    pg.evaluate("(()=>{ try{ %s }catch(e){ console.warn('gal ui',e); } })()"%js)
                    run_static(pg,g,a,cam,{},note,frames=3,wait=120)
                pg.evaluate("B.sel=null; B.inspect=null; B.hover=null; B.showThreat=false; B.aiFocus=null; B.reach=null; clearOverlays(); refreshOverlays(); 0")
            # set pieces, built out past the rim one at a time
            pieces=['station_ring','station_rig','station_spire','hole_station','hole_hulk','hole_asteroid','hole_moon','hole_comet','beacon','deadstar']
            for i,k in enumerate(pieces):
                if not ok('setpiece_'+k): continue
                try:
                    pg.evaluate("GAL.clear()"); bi=pg.evaluate("GAL.build(%s,%d)"%(json.dumps(k),i)); pg.evaluate("GAL.settle(4)")
                    run_static(pg,'setpiece',k,lambda z,bi=bi:"GAL.objCam(%s,%g,%s)"%(json.dumps(bi['p']),bi['size'],json.dumps(z)),{'meshes':bi['meshes']},'built directly (out past the rim)')
                except Exception as e: errors.append('setpiece_'+k+': '+str(e)[:200])
                finally:
                    try: pg.evaluate("GAL.unbuild()")
                    except Exception: pass
            # backdrop: sky and sun, galaxy, every planet look on the backdrop planet, a nebula bank
            if ok('backdrop_sky'):
                pg.evaluate("GAL.clear(); G.cam.upperBetaLimit=3.05;")
                def skycam(z):
                    r={'close':40,'mid':40,'board':215}[z]
                    if z=='board': return "G.cam.upperBetaLimit=1.42; GAL.homeCam()"
                    return "(()=>{ const d=G.sunPosW.normalizeToNew(); const off=d.scale(-1); GAL.cam(new V3(0,0,0),%d,Math.atan2(off.z,off.x)%s,Math.acos(off.y)); })()"%(r,'+.35' if z=='mid' else '')
                run_static(pg,'backdrop','sky',skycam,{},'close: looking at the star; mid: beside it; board: the battle camera')
                pg.evaluate("G.cam.upperBetaLimit=1.42; 0")
            looks=pg.evaluate("PLANET_LOOKS.length") if any(wanted('backdrop_planet%d'%i) for i in range(8)) else 0
            for i in range(looks):
                if not ok('backdrop_planet%d'%i): continue
                pg.evaluate("setPlanetLook(PLANET_LOOKS[%d],%g,PLANET_SPOTS[0]); 0"%(i,1.3+i))
                run_static(pg,'backdrop','planet%d'%i,lambda z:"(()=>{ const p=G.planet, R=1300*p.scaling.x; if(%s==='board') GAL.homeCam(); else GAL.cam(p.position,R*(%s==='close'?3.2:7),Math.atan2(-p.position.z,-p.position.x),1.25); })()"%(json.dumps(z),json.dumps(z)),{'kind':(['gas giant']*3+['rocky']*3+['ice']*2+['?']*8)[i]},'procedural planet shader on the backdrop sphere')
            if ok('backdrop_nebula'):
                run_static(pg,'backdrop','nebula',lambda z:"(()=>{ const c=(G.clouds||[])[0]; if(!c) return; const s=c.scaling?c.getBoundingInfo().boundingSphere.radiusWorld:200; if(%s==='board') GAL.homeCam(); else GAL.cam(c.position,s*(%s==='close'?1.6:3.5),-Math.PI/2,1.2); })()"%(json.dumps(z),json.dumps(z)),{'cards':pg.evaluate("(G.clouds||[]).length")},'nebula bank card (shader on desktop, baked on phones)')

        # ---------- world: battlefields as the generator makes them ----------
        worlds=[('belt',{'map':'belt','shape':'dense','pf':'corsair','ef':'voidsworn'},['asteroids','rim','belt','dust']),
                ('graveyard',{'map':'graveyard','shape':'deadstar','pf':'deathless','ef':'corsair'},['blackhole','well','wreck','debris']),
                ('storm',{'map':'storm','shape':'open','pf':'ithar','ef':'chorus'},['storm','nebula','rimcloud']),
                ('planet',{'map':'planet','shape':'open','pf':'voidsworn','ef':'ithar'},['nearplanet','gasgiant','iceworld']),
                ('station',{'map':'station','shape':'open','obj':'break','pf':'hegemony','ef':'corsair'},['station','zones'])]
        for wi,(wname,setup,assets) in enumerate(worlds):
            todo=[a for a in assets if wanted('world_%s_%s'%(wname,a))]
            if not todo: continue
            info=battle(pg,setup,seed_off=wi+1); print('world',wname,info); sys.stdout.flush()
            pg.evaluate("GAL.clear()")
            for a in todo:
                if not ok('world_%s_%s'%(wname,a)): continue
                spec=pg.evaluate(WORLD_JS%json.dumps(a))
                if not spec or not spec.get('p'): rec('world',wname+'_'+a,'close',None,{},'not present on this board: '+str(spec and spec.get('why'))); continue
                if spec.get('wait'): pg.wait_for_timeout(spec['wait'])
                run_static(pg,'world',wname+'_'+a,lambda z,spec=spec:"GAL.objCam(%s,%g,%s,%s,%s,%s)"%(json.dumps(spec['p']),spec['size'],json.dumps(z),json.dumps(spec.get('a')),json.dumps(spec.get('b')),'true' if spec.get('home') else 'false'),spec.get('meta',{}),spec.get('note',''))
        ctx.close()
        if perrs: errors.extend('page: '+e for e in perrs[:20])

        # ---------- phone: each faction's fleet as a portrait phone frames it ----------
        if PHONE and any(wanted('phone_'+f) for f in facs):
            ctx,pg,perrs=boot(b,{'width':412,'height':915},True)
            battle(pg,{'map':'planet','shape':'open','pf':'voidsworn','ef':'hegemony'})
            for fac in facs:
                if not wanted('phone_'+fac): continue
                fl=[s for s in ships if s['fac']==fac]
                try:
                    ids=pg.evaluate("GAL.fleetRow(%s,%s,%s)"%(json.dumps(fac),json.dumps(fl),json.dumps(sqk[:1])))
                    mid=fl[len(fl)//2]['cls']
                    snap(pg,"(()=>{ const v=GAL.V(%s), p=v.root.getAbsolutePosition(); GAL.cam(p,190,Math.PI-.42,.66); })()"%json.dumps(ids[mid]),4,200)
                    path=shot(pg,'phone_%s_mid'%fac); rec('phone',fac,'mid',path,{},'medium quality, portrait')
                except Exception as e: errors.append('phone_'+fac+': '+str(e)[:200])
            if perrs: errors.extend('phone page: '+e for e in perrs[:10])
            ctx.close()
        b.close()
    srv.shutdown()
    write_index(man)
    print('done',len([r for r in results if r['file']]),'images in',round(time.time()-T0,1),'s;',len(errors),'errors'); [print(' ',e) for e in errors[:20]]

# world asset finder: where each world asset sits on the current board, and how big it is
WORLD_JS=r"""(a=>{ const H=(q,r)=>hexWorld(q,r,0), T=Object.entries(B.terrain||{}).map(([k,t])=>{ const [q,r]=k.split(',').map(Number); return {q,r,t}; }), M=B.map||{};
  const dens=t=>{ const ks=T.filter(x=>x.t===t); let best=null,bn=-1; for(const c of ks){ const n=ks.filter(o=>hdist(c,o)<=2).length; if(n>bn){ bn=n; best=c; } } return best; };
  if(a==='asteroids'){ const c=dens('rock'); return c&&{p:H(c.q,c.r),size:9,note:'board asteroid hex (blocker) and its neighbours',meta:{rockHexes:T.filter(x=>x.t==='rock').length,kind:B.biome&&B.biome.rock}}; }
  if(a==='rim'){ let far=null,fd=-1; const bh=boardHexes(); for(let r=-2;r<BH+2;r++) for(let c=-2;c<BW+2;c++){ const h=offToAx(c,r); if(onBoard(h.q,h.r)) continue; const d=Math.min(...bh.map(b=>hdist(b,h))); if(d===2&&(!far||Math.random()<.02)){ far=h; } } return far&&{p:H(far.q,far.r),size:12,note:'rim fill beside the playable board',meta:{rimCells:G.rimCells,rimPieces:G.rimPieces}}; }
  if(a==='belt') return {p:{x:0,y:-210,z:900},size:120,a:-Math.PI/2,b:1.3,home:true,note:'background belt ring (thin instances) and distant rocks'};
  if(a==='dust') return {p:{x:(G.home||G.ctl.t).x,y:6,z:(G.home||G.ctl.t).z},size:6,home:true,note:'parallax dust particles over the board',meta:{}};
  if(a==='blackhole'||a==='well'){ const d=M.deadstar; if(!d) return {why:'no dead star'}; const p=H(d.q,d.r); return a==='blackhole'?{p:{x:p.x,y:-10,z:p.z},size:30,note:'dead star: black core, photon ring, accretion disc'}:{p,size:60,b:.7,note:'gravity well tints: slingshot, pull and rim bands'}; }
  if(a==='wreck'){ const w=(M.wrecks||[])[0]; return w?{p:H(w.q,w.r),size:9,note:'graveyard wreck (a concept or procedural hull in wreck materials, baked)'}:{why:'no wrecks'}; }
  if(a==='debris'){ const c=dens('debris'); return c?{p:H(c.q,c.r),size:9,note:'debris terrain (thin-instanced plates)'}:{why:'no debris hex'}; }
  if(a==='storm'){ const c=dens('storm'); return c?{p:H(c.q,c.r),size:12,wait:900,note:'ion storm cards and lightning'}:{why:'no storm hex'}; }
  if(a==='nebula'){ const c=dens('neb'); return c?{p:H(c.q,c.r),size:12,note:'nebula hex cards'}:{why:'no nebula hex'}; }
  if(a==='rimcloud'){ const bh=boardHexes(); let h=null; for(let r=-1;r<BH+1&&!h;r++) for(let c=-1;c<BW+1;c++){ const x=offToAx(c,r); if(!onBoard(x.q,x.r)&&bh.some(b=>hdist(b,x)===1)){ h=x; break; } } return h&&{p:H(h.q,h.r),size:14,note:'cloud wall rim fill'}; }
  if(a==='nearplanet'||a==='gasgiant'||a==='iceworld'){ const P=M.planet; if(!P||!G.nearPlanet) return {why:'no near planet'}; const look={nearplanet:null,gasgiant:0,iceworld:6}[a];
    if(look!=null){ try{ const old=G.scene.meshes.filter(m=>/^(nearPlanet|nearAtmo|npRing|npMoon)/.test(m.name)); old.forEach(m=>m.dispose()); G.nearMats=[]; B.biome=Object.assign({},B.biome,{planet:look}); buildNearPlanet(P); }catch(e){ return {why:'rebuild failed '+e.message}; } }
    const c=G.nearPlanet.position, R=G.nearPlanet.getBoundingInfo().boundingSphere.radiusWorld, e=H(P.q,P.r); return {p:{x:e.x,y:0,z:e.z},size:R*.25,b:1.15,note:'near planet shader at the board edge'+(look!=null?' (look '+look+')':''),meta:{R:Math.round(R),look:look==null?(B.biome&&B.biome.planet):look}}; }
  if(a==='station'){ const s=M.station; return s?{p:H(s.q,s.r),size:18,note:'station set piece as the map builds it ('+(B.biome&&B.biome.station)+')'}:{why:'no station'}; }
  if(a==='zones'){ const z=boardHexes().find(h=>objZone(h.q,h.r)); return z?{p:H(z.q,z.r),size:30,b:.8,note:'objective zone tints'}:{why:'no zone'}; }
  return {why:'unknown'}; })(%s)"""

def write_index(man):
    by={}
    for r in results: by.setdefault(r['group'],{}).setdefault(r['asset'],[]).append(r)
    order=['ships','squad','engines','damage','fx_weapon','fx_shield','fx_death','board','ui','setpiece','world','backdrop','phone']
    h=['<!doctype html><meta charset="utf-8"><title>Voidsworn asset gallery</title><meta name="viewport" content="width=device-width,initial-scale=1">',
       '<style>body{background:#0b0f16;color:#dfe6ee;font:13px system-ui;margin:16px}h2{margin:26px 0 4px;color:#f0c070}p.t{color:#9ab;margin:0 0 10px;max-width:1100px}',
       '.row{display:flex;gap:8px;align-items:flex-start;margin:6px 0 14px;flex-wrap:wrap}.lab{width:220px;flex:none}.lab b{display:block;font-size:14px}.lab small{color:#8a9;display:block;white-space:pre-wrap}',
       'figure{margin:0}figure img{width:300px;border:1px solid #234;border-radius:4px;display:block}figure.ph img{width:150px}figcaption{color:#789;font-size:11px}.bad{color:#f77}.proc{color:#ff9a5a;font-weight:700}</style>',
       '<h1>Voidsworn asset gallery</h1><p class="t">build %s &middot; renderer %s (WebGL %s) &middot; quality %s &middot; seed %d &middot; concept hulls loaded %s/%s &middot; %d images in %ds</p>'%(
          html.escape(str(man.get('build'))),html.escape(str(man.get('renderer'))),man.get('webgl'),Q,SEED,man.get('hullsLoaded'),man.get('hullsWanted'),len([r for r in results if r['file']]),int(time.time()-T0))]
    if errors: h.append('<p class="bad">'+'<br>'.join(html.escape(e) for e in errors[:40])+'</p>')
    for g in order+[k for k in by if k not in order]:
        if g not in by: continue
        h.append('<h2>%s</h2><p class="t">%s</p>'%(g,html.escape(TECH.get(g,''))))
        for a,rs in by[g].items():
            m=rs[0]['meta'] or {}; note=rs[0]['note']
            info=[]
            for k in ('conceptId','meshes','verts','turrets','parts','mats','weapon','cause','ship','kind'):
                if k in m and m[k] not in (None,[],''): info.append('%s: %s'%(k,m[k] if not isinstance(m[k],list) else ', '.join(map(str,m[k]))))
            cls='proc' if 'PROCEDURAL' in note else ''
            h.append('<div class="row"><div class="lab"><b>%s</b><span class="%s">%s</span><small>%s</small></div>'%(html.escape(a),cls,html.escape(note),html.escape('\n'.join(info))))
            for r in rs:
                if r['file']: h.append('<figure class="%s"><a href="%s"><img loading="lazy" src="%s"></a><figcaption>%s</figcaption></figure>'%('ph' if g=='phone' else '',r['file'],r['file'],r['zoom']))
                else: h.append('<figure><figcaption class="bad">%s: %s</figcaption></figure>'%(r['zoom'],html.escape(r['note'])))
            h.append('</div>')
    open(os.path.join(OUT,'index.html'),'w',encoding='utf-8').write('\n'.join(h))
    json.dump({'results':results,'errors':errors,'manifest':man},open(os.path.join(OUT,'gallery.json'),'w'),indent=1)

if __name__=='__main__':
    try: main()
    except Exception:
        traceback.print_exc()
        try: write_index({'build':'?','renderer':'?','webgl':'?','hullsLoaded':'?','hullsWanted':'?'})
        except Exception: pass
        sys.exit(1)
