# v53-I effects studio: stages every weapon family firing at a target ship, catches muzzle / mid-flight / impact / aftermath, plus a capital
# death sequence, at 1600x900, and fails loudly on any console error. Served over http (concept hulls load), seeded, deterministic.
#
# Run:  python3 fxshot.py                 (writes fxshots/FX_<family>_<n>_<phase>.png and fxshots/index.html; about 1-2 min on a real GPU)
# Env:  OUT=dir  TAG=FX  ONLY=plasma,las,death   W=1600 H=900   Q=ultra|high|medium   GPU=auto|1|0   SEED=7   SCALE=n (render scale divisor)
#       VIEWS=board,close (board: the battle camera distance; close: attacker and target fill ~60% of the frame)
#       PAGEFILE=index_test.html (built with `python3 build.py test` if missing)   HEADLESS=0 to watch   REDUCE=1 (reduce flashing + shake on)
# Game time is driven by Playwright's clock (paused, then stepped), so each frame lands at the same moment on a fast or a slow machine.
import os, sys, json, time, html, platform, threading, subprocess, functools, http.server, socketserver, datetime
from playwright.sync_api import sync_playwright

HERE=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.abspath(os.environ.get('OUT','fxshots')); os.makedirs(OUT,exist_ok=True)
TAG=os.environ.get('TAG','FX'); SEED=int(os.environ.get('SEED','7'))
W=int(os.environ.get('W','1600')); H=int(os.environ.get('H','900'))
GPU=os.environ.get('GPU','auto'); GPU=(platform.system()!='Linux') if GPU=='auto' else GPU=='1'
Q=os.environ.get('Q','ultra' if GPU else 'high'); SCALE=float(os.environ.get('SCALE','1') or 1)
ONLY=[s.strip() for s in os.environ.get('ONLY','').split(',') if s.strip()]
PAGEFILE=os.environ.get('PAGEFILE','index_test.html'); HEADLESS=os.environ.get('HEADLESS','1')!='0'
T0=time.time()
if not os.path.exists(os.path.join(HERE,PAGEFILE)) and PAGEFILE=='index_test.html': subprocess.run([sys.executable,'build.py','test'],cwd=HERE,check=False)

class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
srv=socketserver.ThreadingTCPServer(('127.0.0.1',0),functools.partial(Quiet,directory=HERE)); srv.daemon_threads=True
threading.Thread(target=srv.serve_forever,daemon=True).start()
PAGE='http://127.0.0.1:%d/%s?shots=1'%(srv.server_address[1],PAGEFILE)
SEED_JS="""(()=>{ let s=%d>>>0; Math.random=function(){ s=(s+0x6D2B79F5)>>>0; let t=s; t=Math.imul(t^(t>>>15),t|1); t^=t+Math.imul(t^(t>>>7),t|61); return ((t^(t>>>14))>>>0)/4294967296; }; })();"""%SEED

# family -> capture times in ms after the trigger: muzzle, mid-flight, impact, aftermath
FAMS=[('las',[30,90,170,650]),('plasma',[70,330,700,1500]),('tracer',[50,160,330,900]),('rail',[25,70,160,800]),('needle',[45,150,290,800]),
      ('spine',[70,380,780,1500]),('flak',[40,150,300,900]),('lance',[250,400,560,1500]),('ion',[300,470,640,1600]),('torp',[100,450,900,1700])]
EXTRA=[('plasma_shield','plasma',True,[70,330,700,1300])]
DEATH=[150,500,1000,1500,2200,3400]
PH=['muzzle','flight','impact','after']
VIEWS=[v.strip() for v in os.environ.get('VIEWS','board,close').split(',') if v.strip()]
STAGE=['boot']
def want(n): return not ONLY or any(n.startswith(o) for o in ONLY)

LIB=r"""
window.FXS=(()=>{ const S={};
  S.css=()=>{ const st=document.createElement('style'); st.textContent='body.galhud .hud,body.galhud #plates,body.galhud #banner,body.galhud .tip,body.galhud #tip,body.galhud .tipcard,body.galhud #app,body.galhud .intro,body.galhud #loading,body.galhud .toast,body.galhud #terrlegend,body.galhud .lb,body.galhud #cineSkip,body.galhud .ftxt{display:none!important}'; document.head.appendChild(st); document.body.classList.add('galhud'); };
  S.cam=(t,r,a,b)=>{ const c=G.ctl; c.attract=false; c.estab=null; c.saved=null; c.slowUntil=0; c._sh=null; c.t=new V3(t.x,t.y||0,t.z); c.r=r; c.a=a; c.b=b; G.cam.alpha=a; G.cam.beta=b; G.cam.radius=r; G.cam.target.copyFrom(c.t); G.trauma=0; G.shake=0; };
  S.settle=n=>{ for(let k=0;k<(n||8);k++) updateWorld(1/30); for(const v of G.views.values()){ v.arrive=null; if(v.ring) v.ring.node.setEnabled(true); if(v.root) v.root.setEnabled(true); } G.jumpUntil=0; };
  S.battle=cfg=>{ rndSeed(cfg.seed); try{ hideApp(); }catch(e){} setupBattle(Object.assign({alt:false,small:true,obj:'rout',shape:'open',map:'open',dep:'line',arena:'strip',pf:'voidsworn',ef:'hegemony'},cfg.setup||{}));
    try{ showIntro(); }catch(e){} try{ ACT.begin(); }catch(e){} try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} SPEED=1; G.cine=false; G.cineMode='off'; G.follow=false; G.fxReduced=!!cfg.reduce; G.shakeRed=!!cfg.reduce;
    document.querySelectorAll('.tipcard,.intro').forEach(e=>e.remove()); document.body.classList.remove('intro-on'); S.settle(3); return {units:B.units.length,renderer:(()=>{ try{ const gl=G.engine._gl, x=gl.getExtension('WEBGL_debug_renderer_info'); return x?gl.getParameter(x.UNMASKED_RENDERER_WEBGL):'?'; }catch(e){ return '?'; } })()}; };
  S.clear=()=>{ try{ disposeAllViews(); }catch(e){} B.units=[]; B.sel=null; B.inspect=null; B.hover=null; B.reach=null; try{ clearOverlays(); refreshOverlays(); }catch(e){} };
  S.free=h=>onBoard(h.q,h.r)&&!terr(h.q,h.r);
  S.pair=gap=>{ const hs=boardHexes().filter(S.free), mid=Math.round(BH/2); let best=null,bd=1e9; for(const a of hs){ const b=hs.find(h=>h.r===a.r&&h.q===a.q+gap); if(!b) continue; const d=Math.abs(a.r-mid)+Math.abs(a.q+gap/2-BW/2); if(d<bd){ bd=d; best=[a,b]; } } return best||[hs[0],hs[hs.length-1]]; };
  S.place=(tpl,fac,h,side)=>{ const u=makeUnit(side||'player',tpl,{fac}); if(fac) u.fac=fac; u.q=h.q; u.r=h.r; u.facing=0; B.units.push(u); G.jumpUntil=0; updateWorld(1/60); const v=G.views.get(u.id); if(v){ v.arrive=null; v.ph=null; v.coast=null; } return u; };
  S.U=id=>B.units.find(u=>u.id===id); S.V=id=>G.views.get(id);
  S.face=(u,deg)=>{ u.facing=((Math.round(deg/60)%6)+6)%6; const v=G.views.get(u.id); if(v){ v.ph=null; v.lastA=null; } };
  S.angTo=(a,b)=>{ const p=hexWorld(a.q,a.r), q=hexWorld(b.q,b.r); return Math.atan2(-(q.z-p.z),q.x-p.x)*180/Math.PI; };
  // the first template (non-boss, mid-sized first) that carries a weapon of this family
  S.find=fam=>{ const c=[]; for(const [id,h] of Object.entries(HULLS)){ if(h.cls==='Squadron'||h.boss) continue; let u; try{ u=makeUnit('player',id,{fac:h.fac}); if(h.fac) u.fac=h.fac; }catch(e){ continue; } const wi=u.weapons.findIndex(w=>wFamily(u,w,u.fac||'voidsworn')===fam); if(wi>=0) c.push({id,fac:u.fac||'voidsworn',wi,L:CLS_LEN[h.cls]||14}); }
    c.sort((a,b)=>Math.abs(a.L-14.5)-Math.abs(b.L-14.5)); return c[0]||null; };
  S.stage=(fam,shield,view)=>{ S.clear(); const f=S.find(fam); if(!f) return {err:'no ship carries '+fam}; const gap=fam==='spine'||fam==='flak'?3:4, [ha,hb]=S.pair(gap);
    const tt=S.find('plasma')||f, a=S.place(f.id,f.fac,ha,'player'), t=S.place(fam==='plasma'?(S.find('las')||f).id:tt.id,fam==='plasma'?'voidsworn':'hegemony',hb,'enemy');
    const w=a.weapons[f.wi], want=w.arc==='F'?0:w.arc==='P'?90:w.arc==='S'?-90:0; S.face(a,S.angTo(a,t)+want); S.face(t,S.angTo(t,a)+90); S.settle(14);
    t.sh=shield?[t.shMax,t.shMax,t.shMax,t.shMax]:[0,0,0,0]; a.hp=a.maxHp; t.hp=t.maxHp; window.__st={a:a.id,t:t.id,wi:f.wi};
    const pa=S.V(a.id).root.getAbsolutePosition(), pb=S.V(t.id).root.getAbsolutePosition(), m=pa.add(pb).scale(.5), d=V3.Distance(pa,pb), ang=Math.atan2(pb.z-pa.z,pb.x-pa.x);
    if(view==='close') S.cam(m,d*.58+6,-ang-Math.PI/2+.5,1.08); else S.cam(m,d*1.0+22,-ang-Math.PI/2+.35,1.02); return {tpl:f.id,fac:f.fac,w:w.id,k:w.k,arc:w.arc,target:t.tpl,dist:Math.round(d)}; };
  S.fire=()=>{ const st=window.__st, u=S.U(st.a), t=S.U(st.t), w=u.weapons[st.wi], n=Math.max(2,Math.min(3,w.shots||2)), shots=[]; for(let i=0;i<n;i++) shots.push(true);
    window.__fxErr=null; window.__fx=(async()=>{ try{ await animWeapon(u,w,t,shots); }catch(e){ window.__fxErr=String(e&&e.stack||e); console.error('fxshot fire',e); } })(); return true; };
  S.deathStage=view=>{ S.clear(); const big=Object.entries(HULLS).filter(([id,h])=>h.cls!=='Squadron'&&!h.boss).map(([id,h])=>({id,fac:h.fac||'voidsworn',L:CLS_LEN[h.cls]||14})).sort((a,b)=>b.L-a.L)[0];
    const [h]=S.pair(1), u=S.place(big.id,big.fac,h,'enemy'); S.face(u,0); S.settle(14); u.hp=Math.round(u.maxHp*.25); S.settle(4); window.__st={t:u.id}; const p=S.V(u.id).root.getAbsolutePosition(), L=S.V(u.id).L;
    if(view==='close') S.cam(p,L*1.15+14,-Math.PI/2+.7,1.05); else S.cam(p,L*2.1+40,-Math.PI/2+.6,1.0); return {tpl:big.id,fac:big.fac,L:Math.round(L)}; };
  S.kill=()=>{ const u=S.U(window.__st.t); u.killCause='blast'; u.dead=true; window.__fx=(async()=>{ try{ await animExplode(u); }catch(e){ console.error('fxshot kill',e); } })(); return true; };
  S.stats=()=>{ const P=G.fxPool||{pools:[]}; return {sprites:P.pools.map(q=>q.kind+':'+q.live.length).join(' '),meshes:G.scene.meshes.length,mats:G.scene.materials.length,ps:G.scene.particleSystems.length,atlasMs:G.fxAtlasMs,top:(()=>{ const h={}; for(const m of G.scene.meshes){ const k=m.name.replace(/[0-9_.\-]+$/,''); h[k]=(h[k]||0)+1; } return Object.entries(h).sort((a,b)=>b[1]-a[1]).slice(0,6).map(e=>e.join(':')).join(' '); })()}; };
  return S; })();
"""

results=[]; errors=[]
def main():
    with sync_playwright() as p:
        args=['--ignore-gpu-blocklist']+(['--enable-gpu-rasterization','--use-angle=default'] if GPU else ['--use-angle=swiftshader','--enable-unsafe-swiftshader'])
        b=None
        if GPU:
            try: b=p.chromium.launch(headless=HEADLESS,channel='chromium',args=args)
            except Exception as e: print('chromium channel unavailable, plain launch:',str(e)[:120])
        if b is None: b=p.chromium.launch(headless=HEADLESS,args=args)
        ctx=b.new_context(viewport={'width':W,'height':H},device_scale_factor=1); ctx.add_init_script(SEED_JS)
        pg=ctx.new_page()
        pg.on('pageerror',lambda e: errors.append('[%s] pageerror: %s'%(STAGE[0],str(e)[:300])))
        host='127.0.0.1:%d'%srv.server_address[1]
        def oncon(m):
            if m.type!='error': return
            url=(m.location or {}).get('url','') if isinstance(m.location,dict) else ''
            if 'Failed to load resource' in m.text and (host not in url or url.endswith('favicon.ico') or url.endswith('rocks/index.json')): print('  (ignored: %s %s)'%(m.text[:80],url[:80])); return # fonts/CDN offline, favicon, the optional rock library (not shipped yet)
            errors.append('[%s] console.%s: %s %s'%(STAGE[0],m.type,m.text[:300],url[:120]))
        pg.on('console',oncon)
        clock=None if os.environ.get('NOCLOCK')=='1' else getattr(pg,'clock',None)
        if clock is not None:
            try: clock.install()
            except Exception as e: print('clock unavailable, real-time capture:',str(e)[:120]); clock=None
        pg.goto(PAGE,wait_until='commit')
        pg.wait_for_function("!!document.querySelector('.title .menu')",timeout=240000,polling=500)
        try: pg.wait_for_function("typeof AI_HULLS==='undefined'||Object.keys(AI_HULL_DATA).length>=Object.keys(AI_HULLS).length",timeout=120000,polling=500)
        except Exception: print('warning: not every concept hull loaded')
        pg.evaluate(LIB); pg.evaluate("FXS.css(); setQuality(%s); %s 0"%(json.dumps(Q),("G.engine.setHardwareScalingLevel(G.engine.getHardwareScalingLevel()*%g);"%SCALE) if SCALE!=1 else ''))
        info=pg.evaluate("FXS.battle(%s)"%json.dumps({'seed':SEED*101,'reduce':os.environ.get('REDUCE')=='1'}))
        pg.wait_for_function("!!B&&B.side==='player'",timeout=120000,polling=250); print('battle',info,'boot %.0fs'%(time.time()-T0)); sys.stdout.flush()
        pg.wait_for_timeout(1500)
        def step(ms):
            if clock is not None: clock.run_for(int(ms))
            else: pg.wait_for_timeout(int(ms))
        def sequence(name,trigger,times,meta):
            STAGE[0]=name
            if clock is not None: clock.pause_at(datetime.datetime.fromtimestamp((pg.evaluate('Date.now()')+50)/1000.0)); step(60) # a datetime: Python Playwright reads a bare number as seconds
            pg.evaluate(trigger); last=0
            for i,ms in enumerate(times):
                step(ms-last); last=ms; ph=PH[i] if len(times)==4 else 't%d'%ms
                fn='%s_%s_%d_%s.png'%(TAG,name,i,ph); pg.screenshot(path=os.path.join(OUT,fn),timeout=240000)
                results.append({'name':name,'phase':ph,'ms':ms,'file':fn,'meta':meta}); print('  shot',fn); sys.stdout.flush()
            step(900)
            if clock is not None: clock.resume()
            try: pg.wait_for_function("!window.__fx||window.__fxDone",timeout=100)
            except Exception: pass
            st=pg.evaluate("FXS.stats()"); print('  stats',st)
            fe=pg.evaluate("window.__fxErr")
            if fe: errors.append(name+': '+fe[:300])
        for view in VIEWS:
            for fam,times in FAMS:
                nm='%s_%s'%(fam,view)
                if not want(fam): continue
                STAGE[0]=nm+' stage'; meta=pg.evaluate("FXS.stage(%s,false,%s)"%(json.dumps(fam),json.dumps(view))); print(nm,meta); sys.stdout.flush()
                if meta.get('err'): errors.append(fam+': '+meta['err']); continue
                pg.wait_for_timeout(400); sequence(nm,"FXS.fire()",times,meta); pg.wait_for_timeout(1200)
            for name,fam,sh,times in EXTRA:
                nm='%s_%s'%(name,view)
                if not want(name): continue
                STAGE[0]=nm+' stage'; meta=pg.evaluate("FXS.stage(%s,%s,%s)"%(json.dumps(fam),'true' if sh else 'false',json.dumps(view))); print(nm,meta)
                if meta.get('err'): errors.append(name+': '+meta['err']); continue
                pg.wait_for_timeout(400); sequence(nm,"FXS.fire()",times,meta); pg.wait_for_timeout(1200)
            if want('death'):
                STAGE[0]='death_'+view+' stage'; meta=pg.evaluate("FXS.deathStage(%s)"%json.dumps(view)); print('death',view,meta); pg.wait_for_timeout(500)
                sequence('death_'+view,"FXS.kill()",DEATH,meta)
        ctx.close(); b.close()
    srv.shutdown()
    rows=''.join('<figure><img src="%s" loading="lazy"><figcaption>%s %s +%dms</figcaption></figure>'%(r['file'],html.escape(r['name']),r['phase'],r['ms']) for r in results)
    open(os.path.join(OUT,'index.html'),'w').write('<!doctype html><meta charset="utf-8"><title>FX shots</title><style>body{background:#111;color:#ccc;font:13px system-ui}figure{display:inline-block;margin:4px;width:400px}img{width:400px}</style><h3>%d shots, %d errors</h3><pre>%s</pre>%s'%(len(results),len(errors),html.escape('\n'.join(errors)),rows))
    json.dump({'results':results,'errors':errors,'secs':round(time.time()-T0)},open(os.path.join(OUT,'fxshot.json'),'w'),indent=1)
    print('%d shots in %.0fs -> %s'%(len(results),time.time()-T0,OUT))
    if errors:
        print('ERRORS (%d):'%len(errors)); [print('  '+e) for e in errors]; sys.exit(1)
    print('no console errors')

if __name__=='__main__': main()
