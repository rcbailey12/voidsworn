# Phone screenshots: move outline, ram lane and ram spots, and every hole set piece.
import os
from playwright.sync_api import sync_playwright
HERE=os.path.dirname(os.path.abspath(__file__)); PAGE='file://'+HERE+'/index_test.html'; OUT=os.environ.get('OUT','.')
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    ctx=b.new_context(viewport={'width':412,'height':860},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:200]))
    pg.goto(PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
    def begin(opts):
        pg.evaluate(f"setQuality('medium'); G.engine.setHardwareScalingLevel(1.4); ACT.c3skirmish(); setupBattle({opts}); ACT.begin(); 0")
        pg.wait_for_function("!!B&&B.side==='player'&&!B.busy&&!document.getElementById('loading')", timeout=120000, polling=500)
        pg.evaluate("document.querySelectorAll('.intro,.tipcard').forEach(e=>e.remove()); document.body.classList.remove('intro-on'); try{ ACT.tipOff&&ACT.tipOff(); }catch(e){} G.cine=false; 0"); pg.wait_for_timeout(1800)
    begin("{small:true,obj:'rout',shape:'open',map:'belt'}")
    r=pg.evaluate("""(()=>{ const s=pendingP().find(u=>!u.isSq); selectUnit(s); G.ctl.focus(hexWorld(s.q,s.r,0),120); G.ctl.b=.75; const spots=[...B.reach.map.values()].filter(x=>x.ram).length; return 'reach '+B.reach.map.size+' ramSpots '+spots; })()""")
    print(r); pg.wait_for_timeout(1500); pg.screenshot(path=OUT+'/ux_move.png')
    r=pg.evaluate("""(()=>{ const s=B.sel, e=caps('enemy')[0]; let ok=null;
      for(let f=0;f<6&&!ok;f++){ const d=DIRS[f], q=s.q+d[0]*3, rr=s.r+d[1]*3; if(!onBoard(q,rr)||!onBoard(s.q+d[0],s.r+d[1])||!onBoard(s.q+d[0]*2,s.r+d[1]*2)) continue; if(unitAt(s.q+d[0],s.r+d[1])||unitAt(s.q+d[0]*2,s.r+d[1]*2)) continue;
        for(const k of [1,2,3]) delete B.terrain[hkey(s.q+d[0]*k,s.r+d[1]*k)]; s.facing=f; e.q=q; e.r=rr; ok=d; }
      if(!ok) return 'no lane'; const v=G.views.get(e.id); if(v) v.root.position.copyFrom(hexWorld(e.q,e.r,0)); s.mp=s.speed; selectUnit(s); const ri=ramInfo(s); G.ctl.focus(hexWorld(s.q+ok[0],s.r+ok[1],0),110);
      RUN.boons=[{id:'e_kindle',r:2},{id:'e_chain',r:1}]; e.st.fire=0; e.sh=[0,0,0,0]; const f0=s.fx.igniteCh; s.fx.igniteCh=1; applyHit(s,s.weapons[0],e,20,0); s.fx.igniteCh=f0;
      return ri?('ram ready on '+ri.t.name+' run '+ri.path.length):'no ram'; })()""")
    print(r); pg.wait_for_timeout(700); pg.screenshot(path=OUT+'/ux_ram.png'); print('strip:',pg.evaluate("(document.querySelector('.striphint')||{}).innerText"))
    for kind in ['asteroid','station','moon','hulk','comet']:
        begin("{obj:'rout',shape:'colossus',map:'random'}")
        r=pg.evaluate(f"""(()=>{{ const H=B.map.holes||[]; if(!H.length) return 'no holes'; H.forEach(h=>h.kind='{kind}'); buildBattleEnv(); const h=H[0]; let x=0,z=0; for(const [q,r] of h.cells){{ const p=hexWorld(q,r,0); x+=p.x; z+=p.z; }} G.ctl.focus(new V3(x/h.cells.length,0,z/h.cells.length),200); G.ctl.b=.7; return '{kind} holes '+H.length+' cells '+h.cells.length+' solid '+(SOLID?SOLID.size:0); }})()""")
        print(r); pg.wait_for_timeout(2200); pg.screenshot(path=OUT+f'/ux_hole_{kind}.png')
    print('errors',errs)
