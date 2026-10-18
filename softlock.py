import sys, time
from playwright.sync_api import sync_playwright
PAGE=sys.argv[1]
SETUP={'throwrefresh':"""SETUP.obj='rout'; setupBattle({small:true}); ACT.begin();""",'relay':"""SETUP.obj='hold'; setupBattle({small:true}); ACT.begin();""",'squadron':"""SETUP.obj='rout'; setupBattle({small:true}); ACT.begin();"""}
STAGE={'throwrefresh':"""(()=>{ const k=camKeep; let n=0; camKeep=function(){ if(!n++){ camKeep=k; throw new Error('injected refresh failure'); } return k.apply(this,arguments); }; for(const u of caps('player')) u.activated=true; B.activeUnit=null; B.side='player'; B.busy=false; return 'refresh will throw once during the enemy step'; })()""",'relay':"""(()=>{ const p=caps('player')[0]; const h=B.obj.hex; p.q=h.q; p.r=h.r; for(const e of alive('enemy')){ e.q=Math.min(BW-2,h.q+7); } B.obj.score=2; B.obj.escore=0;
   for(const u of B.units) u.activated=true; B.activeUnit=null; B.side='player'; B.busy=false; return 'relay staged, score '+B.obj.score; })()""",
 'squadron':"""(()=>{ const es=alive('enemy'); const t=es[0]; for(const e of es.slice(1)){ e.hp=0; e.dead=true; } t.hp=1; t.sh=[0,0,0,0]; t.weapons=t.weapons.filter(w=>w.k!=='flak'); t.ev=0; B.cp0.enemy=99;
   const c=caps('player')[0]; const sq=makeUnit('player','bomber',{fac:c.fac}); sq.parent=null; sq.q=t.q-1; sq.r=t.r; sq.facing=0; sq.weapons.forEach(w=>{w.acc=300;w.shots=6;w.dmg=999;w.fired=false;w.cdLeft=0;}); t.armor=0; B.units.push(sq);
   for(const u of B.units) u.activated=true; sq.activated=true; B.activeUnit=null; B.side='player'; B.busy=false; B.over=false; const pl=sqPlan(sq); return 'squadron staged vs '+t.name+' plan '+(pl?(pl.attack+' on '+(pl.t&&pl.t.name)):'none'); })()"""}
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    for case in ['throwrefresh','relay','squadron']:
        ctx=b.new_context(viewport={'width':443,'height':790},is_mobile=True,has_touch=True); pg=ctx.new_page(); errs=[]; pg.on('pageerror',lambda e: errs.append(str(e)[:150]))
        pg.goto('file://'+PAGE, wait_until='commit'); pg.wait_for_function("!!document.querySelector('.title .menu')", timeout=150000, polling=1000)
        pg.evaluate("G.engine.setHardwareScalingLevel(4); ACT.c3skirmish(); "+SETUP[case]); pg.wait_for_function("!!B&&B.side==='player'&&!B.busy", timeout=60000, polling=500)
        pg.evaluate("SPEED=.05; const i=document.querySelector('.intro'); if(i) i.remove(); document.body.classList.remove('intro-on');")
        print('  ',pg.evaluate(STAGE[case])); pg.evaluate("ACT.endTurn()")
        try:
            if case=='throwrefresh': pg.wait_for_function("!!B&&(B.over||(B.side==='player'&&!B.busy&&B.round>1))", timeout=45000, polling=500); res='RECOVERED'
            else: pg.wait_for_function("!!document.getElementById('endcard')", timeout=45000, polling=500); res='END CARD SHOWN'
        except Exception: res='SOFT-LOCK'
        over=pg.evaluate("B&&B.over"); lbl=pg.evaluate("(document.getElementById('turnlbl')||{}).textContent"); strip=pg.evaluate("!!document.querySelector('#panel .actstrip')")
        print(case.ljust(9),'->',res,'| over =',over,"| turn label = '"+str(lbl)+"' | strip shown =",strip,'| errors =',errs[:2])
        ctx.close()
    b.close()
