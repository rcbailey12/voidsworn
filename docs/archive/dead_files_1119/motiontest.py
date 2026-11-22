# Continuous motion: sample a multi-hex move frame by frame; speed must ramp up and down with no jumps; arrival and mid-burn shots.
import os, json
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    pg.evaluate("setQuality('medium'); G.engine.setHardwareScalingLevel(1.4); ACT.c3skirmish(); setupBattle({small:true,obj:'rout',shape:'open',map:'planet'}); ACT.begin(); SPEED=1; 0")
    pg.wait_for_timeout(700); pg.screenshot(path=OUT+'/mo_arrive.png')
    pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500)
    pg.evaluate("document.querySelectorAll('.intro,.tipcard').forEach(e=>e.remove()); document.body.classList.remove('intro-on'); 0")
    r=pg.evaluate("""(async()=>{ const s=pendingP().find(u=>!u.isSq&&u.size>.6)||pendingP()[0]; const {states}=computeReach(s);
      const st=states.filter(x=>x.path&&x.path.length>=3&&x.path.some(p=>p.rot)).sort((a,b)=>b.path.length-a.path.length)[0]||states.sort((a,b)=>b.path.length-a.path.length)[0];
      const T=tween, sam=[]; let D=0; tween=async(dur,fn)=>{ D=dur; for(let i=0;i<=200;i++){ const p=i/200; fn(p,p); const w=hexWorld(s.vis.q,s.vis.r,0); sam.push([p*dur/1000,w.x,w.z,s.vis.a]); } };
      const q0=s.q,r0=s.r,f0=s.facing; await animPath(s,st.path); tween=T; s.q=q0; s.r=r0; s.facing=f0;
      const sp=[]; for(let i=1;i<sam.length;i++){ const a=sam[i-1], c=sam[i]; sp.push(Math.hypot(c[1]-a[1],c[2]-a[2])/(c[0]-a[0])); }
      const ac=[]; for(let i=1;i<sp.length;i++) ac.push(Math.abs(sp[i]-sp[i-1])/(sam[i+1][0]-sam[i][0]));
      const turn=[]; for(let i=1;i<sam.length;i++) turn.push(Math.abs(sam[i][3]-sam[i-1][3])/(sam[i][0]-sam[i-1][0]));
      const end=hexWorld(st.q,st.r,0), last=sam.at(-1);
      return JSON.stringify({steps:st.path.length,rots:st.path.filter(p=>p.rot).length,durMs:Math.round(D),start:sp.slice(0,2).map(x=>x.toFixed(1)),peak:Math.max(...sp).toFixed(1),end:sp.slice(-2).map(x=>x.toFixed(1)),maxAccel:Math.max(...ac).toFixed(0),medAccel:ac.slice().sort((a,b)=>a-b).at(ac.length>>1).toFixed(0),maxTurnDegS:Math.max(...turn).toFixed(0),endsOnTarget:Math.hypot(last[1]-end.x,last[2]-end.z)<.01}); })()""")
    print(r)
    pg.evaluate("(async()=>{ const s=pendingP().find(u=>!u.isSq); if(!s) return; const {states}=computeReach(s); const st=states.sort((a,b)=>b.path.length-a.path.length)[0]; selectUnit(s); moveUnit(s,st); })()")
    pg.wait_for_timeout(900); pg.screenshot(path=OUT+'/mo_burn.png')
    print('errors',errs)
