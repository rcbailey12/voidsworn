# v53-D enemy intent: the enemy fleet's focus target (corner brackets on its hex, Targeted tag on its plate and roster row),
# then a tapped enemy's reach (faint red hexes, rings on your ships inside it). Desktop and phone. OUT=dir TAG=prefix
import os, sys
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.'); TAG=os.environ.get('TAG','A')
MAP=os.environ.get('MAP','planet')
SIZES=[('desk',{'width':1280,'height':800},False),('phone',{'width':412,'height':915},True)]
if os.environ.get('ONLY'): SIZES=[s for s in SIZES if s[0]==os.environ['ONLY']]
SETUP_JS="setQuality('medium'); ACT.c3skirmish(); setupBattle({obj:'rout',shape:'open',map:'%s',pf:'voidsworn',ef:'hegemony'}); ACT.begin(); SPEED=.5; G.cine=false; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on'); try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} 0"%MAP
CLUSTER_JS="""(async()=>{ document.querySelectorAll('.tipcard').forEach(e=>e.remove()); for(const v of G.views.values()){ v.arrive=null; if(v.ring) v.ring.node.setEnabled(true); if(v.root) v.root.setEnabled(true); if(v.plate) v.plate.el.style.visibility=''; }
  const P=caps('player'), E=caps('enemy'); const occ=()=>occMap(); const snap=u=>{ const v=G.views.get(u.id); if(v){ v.ph=null; v.coast=null; } };
  // pull the enemy line in close to the player fleet, two or three hexes off
  E.forEach((e,i)=>{ const p=P[i%P.length], o=occ(); let best=null,bd=1e9; for(const h of boardHexes()){ if(o.has(hkey(h.q,h.r))||blocks(terr(h.q,h.r))) continue; const d=hdist(h,p); const sc=Math.abs(d-3)*10+hdist(h,P[0])*.1; if(sc<bd){ bd=sc; best=h; } } if(best){ e.q=best.q; e.r=best.r; e.facing=(p.q<e.q)?3:0; snap(e); } });
  // two real moves so ships end a burn and coast as they would in play
  for(const s of P.slice(0,2)){ const R=computeReach(s); let best=null; for(const st of R.states){ if(occ().has(hkey(st.q,st.r))) continue; const n=(st.path||[]).filter(p=>!p.rot).length; if(n>=2&&(!best||n>(best.path||[]).filter(p=>!p.rot).length)) best=st; } if(best) await moveUnit(s,best); }
  for(let k=0;k<180;k++) updateWorld(1/30);
  let x=0,z=0; const all=P.concat(E); for(const u of all){ const p=hexWorld(u.q,u.r,0); x+=p.x; z+=p.z; } G.ctl.reset(); G.ctl.t=new V3(x/all.length,0,z/all.length); G.ctl.r=Math.min(G.ctl.r,230); G.ctl.attract=false; G.ctl.estab=null;
  const out=[]; for(const u of all){ const v=G.views.get(u.id), h=hexWorld(u.q,u.r,0), rp=v.root.position; out.push(Math.hypot(rp.x-h.x,rp.z-h.z)/HW); }
  return 'drift(hex) max '+Math.max(...out).toFixed(3)+' mean '+(out.reduce((a,b)=>a+b,0)/out.length).toFixed(3); })()"""
FOCUS_JS="""(()=>{ B.sel=null; B.inspect=null; B.reach=null; const f=aiRefreshFocus(); document.body.classList.add('showroster'); bRefresh(); for(let k=0;k<4;k++) updateWorld(1/30); const v=f&&G.views.get(f.id); return 'focus '+(f?f.name:'none')+', ret '+!!(OV.focusRet&&OV.focusRet.isEnabled())+', plate tag '+!!(v&&v.plate.el.classList.contains('tgt'))+', roster tag '+!!document.querySelector('#roster .tgtTag'); })()"""
TAP_JS="""(()=>{ document.body.classList.remove('showroster'); const P=caps('player'); const e=caps('enemy').map(e=>({e,n:P.filter(p=>inspThreat(e).has(hkey(p.q,p.r))).length})).sort((a,b)=>b.n-a.n)[0].e; B.sel=null; B.inspect=e; bRefresh(); const t0=performance.now(); B.inspThr=null; inspThreat(e); const ms=performance.now()-t0; return 'inspect '+e.name+' reach hexes '+inspThreat(e).size+' ('+ms.toFixed(0)+' ms), panel: '+(document.getElementById('panel').innerText.match(/(Its next move|Next round it)[^.]*\\./)||[''])[0]; })()"""
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    for name,vp,mob in SIZES:
        ctx=b.new_context(viewport=vp,is_mobile=mob,has_touch=mob); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
        pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
        pg.evaluate(SETUP_JS)
        pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=120000, polling=500)
        pg.wait_for_function("(()=>{const l=document.getElementById('loading'); return !l||getComputedStyle(l).display==='none'||l.classList.contains('hide')||+getComputedStyle(l).opacity<.05;})()", timeout=120000, polling=500)
        pg.wait_for_timeout(1500)
        print(name, pg.evaluate(CLUSTER_JS)); sys.stdout.flush()
        print(name, pg.evaluate(FOCUS_JS)); sys.stdout.flush()
        pg.wait_for_timeout(2500); pg.screenshot(path=f'{OUT}/{TAG}_{name}_focus.png', timeout=240000)
        print(name, pg.evaluate(TAP_JS)); sys.stdout.flush()
        pg.wait_for_timeout(2500); pg.screenshot(path=f'{OUT}/{TAG}_{name}_tap.png', timeout=240000)
        print(name,'errors',errs); ctx.close()
