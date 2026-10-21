# v53.8 battle-load probe: phone size, served over http (real hull meshes and maps), real GPU unless SW=1.
# Starts a battle from the title and records every frame gap, long tasks and a CPU profile from the tap until 8 s after the battle shows.
# usage: loadprobe.py [label]   env: PF/EF factions, PAGEFILE, PREP=1 runs prefetchBattle() first (if the build has it), SW=1 software GPU
import os, sys, json, time, threading, http.server, socketserver, functools, collections
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); label=sys.argv[1] if len(sys.argv)>1 else 'load'
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
socketserver.ThreadingTCPServer.daemon_threads=True; socketserver.ThreadingTCPServer.allow_reuse_address=True
srv=socketserver.ThreadingTCPServer(('127.0.0.1',0),functools.partial(Q,directory=HERE)); threading.Thread(target=srv.serve_forever,daemon=True).start()
PAGE='http://127.0.0.1:%d/'%srv.server_address[1]+os.environ.get('PAGEFILE','index_test.html')
PF=os.environ.get('PF','voidsworn'); EF=os.environ.get('EF','hegemony')
args=['--use-angle=swiftshader','--enable-unsafe-swiftshader'] if os.environ.get('SW') else ['--ignore-gpu-blocklist','--enable-gpu-rasterization']
WATCH="""(()=>{ window.__lp={gaps:[],lt:[],t0:0,marks:[]}; const L=window.__lp; let last=performance.now();
  (function f(){ const n=performance.now(); if(L.t0) L.gaps.push([+(n-L.t0).toFixed(0),+(n-last).toFixed(1)]); last=n; requestAnimationFrame(f); })();
  try{ new PerformanceObserver(l=>{ for(const e of l.getEntries()) if(L.t0) L.lt.push([+(e.startTime-L.t0).toFixed(0),+e.duration.toFixed(0)]); }).observe({entryTypes:['longtask']}); }catch(e){}
  const wrap=(o,k)=>{ const f=o[k]; if(typeof f!=='function') return; o[k]=function(...a){ const t=performance.now(); const r=f.apply(this,a); const done=()=>{ if(L.t0) L.marks.push([k,+(t-L.t0).toFixed(0),+(performance.now()-t).toFixed(0)]); }; if(r&&r.then) r.then(done,done); else done(); return r; }; };
  for(const k of ['setupBattle','buildShipModel','makeView','buildTerrainFeatures','buildStation','applyAIHull','seatOnHull','aiHullMatFor','aiTexTouch','prepBattle','buildBoard','fpRebuild']) wrap(window,k);
  return 'ok'; })()"""
with sync_playwright() as p:
    b=p.chromium.launch(args=args)
    ctx=b.new_context(viewport={'width':412,'height':915},is_mobile=True,has_touch=True,device_scale_factor=2.625); pg=ctx.new_page(); errs=[]
    pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE,wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')",timeout=180000,polling=500)
    pg.wait_for_function("typeof HULLS_LOAD!=='undefined'&&HULLS_LOAD.state==='done'",timeout=180000,polling=500); time.sleep(3)
    gpu=pg.evaluate("G.engine.getGlInfo?G.engine.getGlInfo().renderer:''"); print('gpu',gpu,'quality',pg.evaluate("G.quality"),'mobile',pg.evaluate("G.mobile")); sys.stdout.flush()
    pg.evaluate(WATCH)
    if os.environ.get('PREP'): print('prep', pg.evaluate("(async()=>{ const t=performance.now(); if(typeof prefetchBattle==='function') await prefetchBattle({pf:'%s',ef:'%s'}); return Math.round(performance.now()-t); })()"%(PF,EF)))
    cdp=pg.context.new_cdp_session(pg); cdp.send('Profiler.enable'); cdp.send('Profiler.setSamplingInterval',{'interval':250}); cdp.send('Profiler.start')
    pg.evaluate("window.__lp.t0=performance.now(); ACT.c3skirmish(); setupBattle({pf:'%s',ef:'%s'}); ACT.begin(); G.cine=false; 0"%(PF,EF))
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy",timeout=240000,polling=200); tv=pg.evaluate("Math.round(performance.now()-window.__lp.t0)")
    try: pg.wait_for_function("!document.getElementById('bveil')||document.getElementById('bveil').style.opacity==='0'",timeout=int(os.environ.get("VEILWAIT","20000")),polling=100)
    except Exception: pass
    lift=pg.evaluate("(()=>{ const w=G.lastWarm; return w&&w.end?Math.round(w.end-window.__lp.t0):0; })()"); warm=pg.evaluate("JSON.stringify(G.lastWarm||null)")
    time.sleep(8)
    prof=cdp.send('Profiler.stop')['profile']; L=pg.evaluate("window.__lp"); tex=pg.evaluate("Object.values(AI_TEX).map(e=>e.code+':'+(e.n&&e.t?'ok':e.failed?'fail':'wait')).join(' ')")
    b.close()
gaps=sorted(L['gaps'],key=lambda g:-g[1])
post=[g for g in L['gaps'] if g[0]>lift]
print(json.dumps({'label':label,'ready_ms':tv,'lift_ms':lift,'warm':warm,'after_lift_worst':sorted(post,key=lambda g:-g[1])[:8],'after_lift_over_50':sum(1 for g in post if g[1]>50),'worst_gaps':gaps[:12],'gaps_over_50':sum(1 for g in L['gaps'] if g[1]>50),'gaps_over_100':sum(1 for g in L['gaps'] if g[1]>100),'frames':len(L['gaps']),'longtasks':sorted(L['lt'],key=lambda x:-x[1])[:12],'errs':errs[:4]}))
mk=collections.defaultdict(lambda:[0,0,0]);
for k,t,d in L['marks']: m=mk[k]; m[0]+=1; m[1]+=d; m[2]=max(m[2],d)
print('MARKS', json.dumps({k:{'n':v[0],'ms':v[1],'max':v[2]} for k,v in mk.items()}))
print('TEX', tex)
nodes={n['id']:n for n in prof['nodes']}; st=collections.Counter()
for s,d in zip(prof['samples'],prof['timeDeltas']): st[s]+=d
agg=collections.Counter(); tot=sum(st.values())
for nid,t in st.items(): cf=nodes[nid]['callFrame']; agg[(cf['functionName'] or '(anon)')+' :'+str(cf['lineNumber'])]+=t
print('PROFILE total ms',round(tot/1000))
for k,t in agg.most_common(30): print(f'{t/1000:8.1f}ms  {k}')
