// ======================= VIEWS, ANIMATION, EFFECTS, SOUND =======================
// one visual language: cyan is always shields, amber is always hull; green/red only marks friend or foe
const SHIELD_C=new C3(.38,.82,1), SHIELD_HEX='#62ccff', HULL_HEX='#ffae42', HULL_LOW_HEX='#ff5a3c', FRIEND_C=new C3(.42,1,.55), FOE_C=new C3(1,.3,.28);
const HOVER_Y=3.4;
function unitVis(u){ return u.vis || {q:u.q, r:u.r, a:u.facing*60}; }
function tween(dur,fn){ return new Promise(res=>{ const t0=performance.now(), D=Math.max(1,dur*SPEED); const step=now=>{ const p=Math.min(1,(now-t0)/D); fn(p<.5?2*p*p:1-Math.pow(-2*p+2,2)/2,p); if(p<1) requestAnimationFrame(step); else res(); }; requestAnimationFrame(step); }); }
function shortAng(a0,a1){ let d=((a1-a0)%360+540)%360-180; return a0+d; }
function uWorld(u){ const v=G.views.get(u.id); if(v&&v.root&&!v.arrive) return v.root.getAbsolutePosition().clone(); const vis=unitVis(u); return hexWorld(vis.q,vis.r,HOVER_Y); }
function toWorld(v,local){ v.root.computeWorldMatrix(true); return V3.TransformCoordinates(local,v.root.getWorldMatrix()); }

// ---------- views ----------
function makeShieldRing(u,v){
  const node=new BABYLON.TransformNode('ring',G.scene); const R=Math.max(5.2,v.L*.56);
  const col=SHIELD_C;
  const spans=[[-50,50],[50,130],[130,230],[230,310]], segs=[];
  if(u.shMax>0 && !u.isSq){ for(let q=0;q<4;q++){ const pts=[]; for(let a=spans[q][0]+4;a<=spans[q][1]-4;a+=4){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*R,0,-Math.sin(r)*R)); }
      const m=MB.CreateTube('seg',{path:pts,radius:.16,tessellation:6,cap:BABYLON.Mesh.CAP_ALL},G.scene); G.glow.addExcludedMesh(m); const mat=emMat('segM',col,.8); mat.alphaMode=BABYLON.Engine.ALPHA_ADD; m.material=mat; m.parent=node; m.isPickable=false; segs.push({m,mat,pulse:0}); } }
  else if(!u.isSq){ const pts=[]; for(let a=0;a<=360;a+=6){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*R,0,Math.sin(r)*R)); } const m=MB.CreateTube('seg',{path:pts,radius:.08,tessellation:4},G.scene); const mat=emMat('segM',new C3(.5,.3,.3),.35); mat.alphaMode=BABYLON.Engine.ALPHA_ADD; m.material=mat; m.parent=node; m.isPickable=false; }
  { const pts=[]; for(let a=0;a<=360;a+=8){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*R*.8,0,Math.sin(r)*R*.8)); } const m=MB.CreateTube('iff',{path:pts,radius:.07,tessellation:4},G.scene); const mat=emMat('iffM',u.side==='player'?FRIEND_C:FOE_C,.55); mat.alphaMode=BABYLON.Engine.ALPHA_ADD; m.material=mat; m.parent=node; m.isPickable=false; G.glow.addExcludedMesh(m); }
  return {node,segs,R};
}
function makePlate(u){ const el=document.createElement('div'); el.className='plate '+(u.side==='player'?'friend':'foe'); el.innerHTML=`<div class="nm"></div>${u.shMax&&!u.isSq?'<div class="sp" title="Shields: port, prow, starboard, rear"><b></b><b></b><b></b><b></b></div>':''}<div class="hb" title="Hull"><i></i></div>`;
  el.querySelector('.nm').textContent=u.isSq?u.t.n:u.name; document.getElementById('plates').appendChild(el); return {el,hb:el.querySelector('.hb i'),sp:[...el.querySelectorAll('.sp b')],key:''}; }
function createView(u){
  const fac=u.fac||'voidsworn';
  const v={u,fac,bob:Math.random()*6.28,bank:0,lastA:null,fires:[],state:'alive'};
  if(u.isSq){ v.root=new BABYLON.TransformNode('sq',G.scene); v.crafts=[]; v.L=5; v.H=2;
    for(let i=0;i<3;i++){ const c=craftInstance(fac,u.sqKind)||buildCraft(fac,u.sqKind); c.root.parent=v.root; c.root.scaling.setAll(1.35); c.meshes.forEach(m=>m.metadata={unit:u.id}); v.crafts.push({c,ph:i*2.09,rad:2+i*.7,h:(i-1)*.5}); }
    if(typeof craftTrails==='function') craftTrails(v,fac);
    const pv=u.parent&&G.views.get(u.parent);
    if(pv&&pv.model&&!u.launched){ u.launched=true; const bay=pv.model.bays.length?pv.model.bays[Math.floor(Math.random()*pv.model.bays.length)]:new V3(0,0,0); v.launch={from:toWorld(pv,bay),t0:G.time}; SFX.launch(); }
  } else { const mdl=buildShipModel(u); v.model=mdl; v.root=mdl.root; v.L=mdl.L; v.H=mdl.H; mdl.meshes.forEach(m=>m.metadata={unit:u.id}); }
  v.ring=makeShieldRing(u,v); v.plate=makePlate(u);
  if(v.model&&G.quality!=='medium'&&u.size>=.6){ const el=new BABYLON.PointLight('engLight',new V3(-v.L*.56,0,0),G.scene); el.parent=v.root; el.diffuse=(FAC3D[fac]||FAC3D.hegemony).eng; el.specular=el.diffuse; el.intensity=1.6; el.range=v.L*.8; el.includedOnlyMeshes=v.model.meshes.slice(); v.engLight=el; }
  if((u.flagship||u.transport||u.pflag)&&!u.isSq){ const cr=MB.CreateTorus('flagRing',{diameter:Math.max(3,v.L*.25),thickness:.2,tessellation:32},G.scene); cr.parent=v.root; cr.position.y=v.H+2.2; cr.material=emMat('flagM',new C3(1.5,1.15,.45)); cr.isPickable=false; v.flagRing=cr; }
  // hyperspace arrival: the fleet drops in when the battle opens, reinforcements when they jump in
  if(B&&(u.reinf&&!u.arrived||G.jumpUntil&&G.time<G.jumpUntil)){ u.arrived=true; v.arrive={t0:G.time+(u.reinf?0:(u.side==='player'?.05:.4)+Math.random()*.55+(u.isSq?.55:0))}; }
  G.views.set(u.id,v); return v;
}
function disposeView(v){ if(v.navSp){ try{ v.navSp.forEach(sp=>sp.dispose()); }catch(e){} v.navSp=null; } if(v.dmgMats&&typeof disposeDamageMats==='function') disposeDamageMats(v); if(v.arrive&&v.arrive.streak){ try{ v.arrive.streak.material.dispose(); v.arrive.streak.dispose(); }catch(e){} } (v.extras||[]).forEach(p=>p.dispose()); (v.stackFx||[]).forEach(ps=>ps.dispose()); if(v.root) v.root.dispose(false,false); if(v.ring) v.ring.node.dispose(false,true); if(v.plate) v.plate.el.remove(); for(const f of v.fires) f.dispose(); v.fires=[]; }
function disposeAllViews(){ for(const v of G.views.values()){ disposeView(v); } G.views.clear(); for(const h of G.hulks||[]) h.nodes.forEach(n=>{ if(n.ps) n.ps.dispose(); n.dispose(); }); G.hulks=[]; for(const p of PROJ){ p.m.dispose(); if(!p.arrived&&p.settle) p.settle(); } PROJ.length=0; for(const r of TORPS){ G.scene.onBeforeRenderObservable.remove(r.obs); r.tr.dispose(); r.m.dispose(); r.res(); } TORPS.clear(); document.getElementById('plates').innerHTML=''; }

function addFire(v){
  const node=new BABYLON.TransformNode('fire',G.scene); node.parent=v.root; node.position=new V3((Math.random()-.5)*v.L*.6,v.H*.35,(Math.random()-.5)*v.L*.12);
  const ps=new BABYLON.ParticleSystem('fire',160,G.scene,null,true); ps.particleTexture=fireSheet(); ps.spriteCellWidth=128; ps.spriteCellHeight=128; ps.startSpriteCellID=8; ps.endSpriteCellID=63; ps.spriteCellLoop=false; ps.emitter=node; ps.minEmitBox=new V3(-.4,0,-.4); ps.maxEmitBox=new V3(.4,.2,.4);
  ps.color1=new C4(1,1,1,1); ps.color2=new C4(1,.9,.8,.9); ps.colorDead=new C4(1,1,1,0); ps.minSize=.7; ps.maxSize=2; ps.minLifeTime=.6; ps.maxLifeTime=1.3; ps.emitRate=30;
  ps.direction1=new V3(-.3,1,-.3); ps.direction2=new V3(.3,1.6,.3); ps.minEmitPower=1; ps.maxEmitPower=2.2; ps.blendMode=BABYLON.ParticleSystem.BLENDMODE_STANDARD; ps.addSizeGradient(0,.6); ps.addSizeGradient(1,2.2); ps.start(); v.fires.push(ps);
  if(v.fires.length===2){ const vn=new BABYLON.TransformNode('vent',G.scene); vn.parent=v.root; const side=Math.random()<.5?1:-1; vn.position=new V3((Math.random()-.5)*v.L*.5,v.H*.2,side*v.L*.07);
    const g=new BABYLON.ParticleSystem('vent',120,G.scene); g.particleTexture=G.tex.smoke; g.emitter=vn; g.direction1=new V3(-.2,.1,side); g.direction2=new V3(.2,.4,side*1.4); g.color1=new C4(.85,.9,1,.35); g.color2=new C4(.7,.75,.85,.25); g.colorDead=new C4(.5,.5,.6,0);
    g.minSize=.3; g.maxSize=.8; g.addSizeGradient(0,.4); g.addSizeGradient(1,3); g.minLifeTime=.6; g.maxLifeTime=1.4; g.emitRate=45; g.minEmitPower=3; g.maxEmitPower=6; g.blendMode=BABYLON.ParticleSystem.BLENDMODE_STANDARD; g.start(); v.fires.push(g); }
}

// ---------- faction art direction: living materials ----------
function animateFactionMats(t){ for(const [fac,M] of Object.entries(MATS)){ if(!M._base) M._base={win:M.win.emissiveColor.clone(),tip:M.tip.emissiveColor.clone(),hull:M.hull.emissiveColor?M.hull.emissiveColor.clone():null,sail:M.sail.alpha};
    const b=M._base; let kw=1,kt=1,kh=1;
    if(fac==='chorus'){ kw=.6+.5*Math.sin(t*1.5); kh=.45+.65*Math.sin(t*1.5+.7); }
    else if(fac==='deathless'){ kw=.7+.35*Math.sin(t*2.3); kh=.55+.55*Math.sin(t*1.05); if(M.hull.emissiveTexture) M.hull.emissiveTexture.uOffset=(t*.06)%1; }
    else if(fac==='corsair'){ kw=G.fxReduced?.95:.82+.22*Math.sin(t*23)*Math.sin(t*7.3)-(Math.sin(t*3.1)>.97?.5:0); }
    else if(fac==='voidsworn'){ kw=.93+.07*Math.sin(t*9)*Math.sin(t*3.7); kt=G.fxReduced?.8:(Math.sin(t*2)>0?1.3:.2); }
    else if(fac==='hegemony'){ kt=G.fxReduced?.8:((t*1.1%1)<.12?1.7:.15); }
    else if(fac==='ithar'){ kw=.85+.2*Math.sin(t*1.3); M.sail.alpha=b.sail*(.8+.35*Math.sin(t*1.7)); }
    M.win.emissiveColor.copyFrom(b.win.scale(kw)); M.tip.emissiveColor.copyFrom(b.tip.scale(kt)); if(b.hull) M.hull.emissiveColor.copyFrom(b.hull.scale(kh)); } }
function arcBolt(a,b,col){ const pts=[a.clone()], n=7; for(let i=1;i<n;i++){ const p=V3.Lerp(a,b,i/n); p.addInPlace(new V3((Math.random()-.5)*1.4,(Math.random()-.5)*1.4,(Math.random()-.5)*1.4)); pts.push(p); } pts.push(b.clone());
  if(G.fxReduced&&Math.random()<.6) return; const t=MB.CreateTube('arc',{path:pts,radius:.08,tessellation:4},G.scene); const m=emMat('arcM',col.scale(G.fxReduced?.5:1)); t.material=m; t.isPickable=false; if(!G.fxReduced) flash(b,2.5,col,.2); setTimeout(()=>{ t.dispose(); m.dispose(); },130); }

// ---------- per-frame world update ----------
function updateWorld(dt){
  try{ gfxTick(); }catch(e){} try{ if(typeof vfxTick==='function') vfxTick(); }catch(e){}
  if(!B) return;
  const t=G.time, cw=G.engine.getRenderingCanvas().clientWidth, ch=G.engine.getRenderingCanvas().clientHeight;
  const tm=G.scene.getTransformMatrix(), vp=G.cam.viewport.toGlobal(cw,ch);
  if(MATS.chorus){ const k=Math.sin(G.time*2.2); MATS.chorus.win.emissiveColor=MATS.chorus.P.win.scale(.8+.35*k); MATS.chorus.flesh.emissiveColor=MATS.chorus.P.win.scale(.32+.22*k); }
  if(MATS.deathless) MATS.deathless.win.emissiveColor=MATS.deathless.P.win.scale(.72+.35*Math.sin(G.time*1.3));
  if(MATS.ithar) MATS.ithar.sail.alpha=.26+.07*Math.sin(G.time*1.7);
  for(const u of B.units){
    let v=G.views.get(u.id);
    if(!v){ if(u.dead) continue; v=createView(u); }
    if(v.state!=='alive') continue;
    const vis=unitVis(u), p=hexWorld(vis.q,vis.r), a=vis.a*Math.PI/180;
    if(v.lastA==null) v.lastA=a;
    const da=a-v.lastA; v.lastA=a; const bk=u.isSq?.2:u.size>.8?.07:u.size>.6?.1:.14, bankT=clamp(-da/Math.max(dt,.001)*bk,-.38,.38); v.bank+=(bankT-v.bank)*Math.min(1,dt*3.2);
    let y=HOVER_Y+Math.sin(t*.8+v.bob)*.22+((u.vis&&u.vis.lift)||0);
    let px=p.x, pz=p.z, stretch=1;
    if(v.arrive){ const k=(G.time-v.arrive.t0)/(.95*Math.max(.4,SPEED)); if(k<0){ v.root.setEnabled(false); v.ring.node.setEnabled(false); v.plate.el.style.visibility='hidden'; continue; }
      v.root.setEnabled(true); const e=1-Math.pow(1-Math.min(1,k),4), f=fwdOf(vis.a), back=(1-e)*150; px-=f.x*back; pz-=f.z*back; stretch=1+(1-e)*6;
      if(!u.isSq&&k<.75){ if(!v.arrive.streak){ const P=FAC3D[v.fac]||FAC3D.hegemony, m=MB.CreateBox('jumpStreak',{width:1,height:.35,depth:.35},G.scene), mt=emMat('jumpM',P.eng.scale(1.6),.8); mt.alphaMode=BABYLON.Engine.ALPHA_ADD; mt.disableDepthWrite=true; m.material=mt; m.isPickable=false; v.arrive.streak=m; }
        const sm=v.arrive.streak, len=Math.max(4,back+v.L*.5); sm.position.set(px-f.x*len/2,y,pz-f.z*len/2); sm.rotation.y=vis.a*Math.PI/180; sm.scaling.set(len,1+v.L*.02,1+v.L*.02); sm.material.alpha=.8*(1-k/.75); }
      else if(v.arrive.streak){ v.arrive.streak.material.dispose(); v.arrive.streak.dispose(); v.arrive.streak=null; }
      if(!v.arrive.rift&&!u.isSq&&typeof warpRift==='function'){ v.arrive.rift=true; warpRift(new V3(p.x,y,p.z).subtract(f.scale(v.L*.35)),f,Math.max(14,v.L*1.3),(FAC3D[v.fac]||FAC3D.hegemony).eng.scale(1.2)); }
      if(!v.arrive.flashed&&k>.55){ v.arrive.flashed=true; try{ flash(new V3(px,y,pz),u.isSq?5:6+v.L*.25,(FAC3D[v.fac]||FAC3D.hegemony).eng.scale(1.4),.3); }catch(e){} }
      if(k>=1){ if(v.arrive.streak){ v.arrive.streak.material.dispose(); v.arrive.streak.dispose(); } v.arrive=null; v.ring.node.setEnabled(true); v.plate.el.style.visibility=''; } }
    if(v.launch){ const k=clamp((G.time-v.launch.t0)/(.9*SPEED),0,1), e=1-Math.pow(1-k,3); px=v.launch.from.x+(p.x-v.launch.from.x)*e; pz=v.launch.from.z+(p.z-v.launch.from.z)*e; y=v.launch.from.y+(y-v.launch.from.y)*e; if(k>=1) v.launch=null; }
    if(v.jolt){ const k=(G.time-v.jolt.t0)/.6; if(k>=1) v.jolt=null; else { const e=Math.sin(k*Math.PI)*(1-k); px+=v.jolt.d.x*e; pz+=v.jolt.d.z*e; } }
    v.root.position.set(px,y,pz); v.root.rotation.set(v.bank,a,0); { const ts=u.isSq?1+((G.tacScale||1)-1)*.6:(G.tacScale||1); if(stretch!==1||v.stretched||ts!==1||v.tsc!==ts){ v.root.scaling.set(stretch*ts,ts/Math.sqrt(stretch),ts/Math.sqrt(stretch)); v.stretched=stretch!==1; v.tsc=ts; } } // v42: ships grow a little as the camera pulls back
    if(v.model){ const moving=!!u.vis, thr=moving?1+((u.vis.thr==null?.7:u.vis.thr))*1.4:1; v.model.plumes.forEach((pl,i)=>{ const f=thr*(.82+.18*Math.sin(t*31+i*1.7)+.06*Math.sin(t*7.3+i)); pl.scaling.x=f; }); (v.model.flares||[]).forEach((fl,i)=>{ fl.scaling.setAll((moving?1.35:1)*(.85+.15*Math.sin(t*23+i*2.1))); });
      for(const an of (v.model.anim||[])) an.node.rotation[an.axis]+=an.speed*dt; if(v.model.turrets&&typeof updateTurrets==='function') updateTurrets(v,dt);
      if(v.model.stacks&&v.model.stacks.length&&!v.stackFx){ v.stackFx=v.model.stacks.map(sp=>{ const n=new BABYLON.TransformNode('stk',G.scene); n.parent=v.root; n.position=sp.clone(); const ps=new BABYLON.ParticleSystem('stack',90,G.scene); ps.particleTexture=G.tex.smoke; ps.emitter=n; ps.direction1=new V3(-.2,1,-.2); ps.direction2=new V3(.2,1.5,.2); ps.color1=new C4(.32,.28,.25,.5); ps.color2=new C4(.2,.18,.17,.4); ps.colorDead=new C4(.1,.1,.1,0); ps.minSize=.3; ps.maxSize=.7; ps.addSizeGradient(0,.5); ps.addSizeGradient(1,3.2); ps.minLifeTime=1.5; ps.maxLifeTime=3; ps.emitRate=10; ps.minEmitPower=.6; ps.maxEmitPower=1.2; ps.blendMode=BABYLON.ParticleSystem.BLENDMODE_STANDARD; ps.start(); return ps; }); } }
    if(v.crafts){ for(const c of v.crafts){ const ang=t*1.4+c.ph; c.c.root.position.set(Math.cos(ang)*c.rad,c.h+Math.sin(t*2.2+c.ph)*.35,-Math.sin(ang)*c.rad); c.c.root.rotation.y=ang+Math.PI/2; c.c.root.rotation.x=.35; } }
    v.ring.node.position.set(px,.3,pz); v.ring.node.rotation.y=a;
    v.ring.segs.forEach((s,q)=>{ const f=u.shMax?u.sh[q]/u.shMax:0; s.pulse=Math.max(0,s.pulse-dt*2.2); s.mat.alpha=(f>.01?.12+.55*f:0)+s.pulse*.9; s.m.scaling.setAll(1+s.pulse*.08); });
    // damage fires
    if(!u.isSq){ const hr=u.hp/u.maxHp, want=hr<.3?2:hr<.6?1:0; while(v.fires.length<want) addFire(v); while(v.fires.length>want){ v.fires.pop().stop(); } if(typeof shipDamageFx==='function') shipDamageFx(v,hr); if(typeof damageSparks==='function') damageSparks(v,hr,dt); }
    // nameplate
    const top=new V3(px,y+Math.max(v.H,2)+2.4,pz), sp=V3.Project(top,BABYLON.Matrix.Identity(),tm,vp);
    const pe=v.plate.el; if(sp.z<0||sp.z>1){ pe.style.display='none'; } else { pe.style.display=''; pe.style.transform=`translate(${sp.x}px,${sp.y}px) translate(-50%,-100%)`; }
    const hr=clamp(u.hp/u.maxHp,0,1), key=Math.round(hr*100)+'|'+u.sh.map(x=>Math.round(x)).join(',')+'|'+(B.sel===u||B.inspect===u||B.hover&&B.hover.q===u.q&&B.hover.r===u.r?1:0)+(B.side==='player'&&u.side==='player'&&isDone(u)?'d':'');
    if(key!==v.plate.key){ v.plate.key=key; v.plate.hb.style.width=(hr*100)+'%'; v.plate.hb.style.background=hr>.3?HULL_HEX:HULL_LOW_HEX;
      v.plate.sp.forEach((b,i)=>{ const q=[3,0,1,2][i]; const f=u.shMax?u.sh[q]/u.shMax:0; b.style.background=f>.66?SHIELD_HEX:f>.01?'#2c6f93':'rgba(45,58,86,.9)'; });
      pe.classList.toggle('hi',key.split('|')[2][0]==='1'||!!u.flagship||!!u.transport||!!u.pflag||(!!u.elite&&u.side==='enemy')); pe.classList.toggle('flag',!!u.flagship||!!u.transport||!!u.pflag); pe.classList.toggle('elite',!!u.elite&&u.side==='enemy'); pe.classList.toggle('done',key.endsWith('d')); }
  }
  G.arcT=(G.arcT||0)-dt; if(G.arcT<=0){ G.arcT=.1+Math.random()*.18; const cands=[]; for(const v of G.views.values()) if(v.state==='alive'&&v.model&&v.model.arcs&&v.model.arcs.length>1) cands.push(v);
    if(cands.length){ const v=cands[Math.floor(Math.random()*cands.length)], A=v.model.arcs, i=Math.floor(Math.random()*A.length), j=(i+1)%A.length, a=toWorld(v,A[i]), c=toWorld(v,A[j]), pts=[];
      for(let k=0;k<=8;k++){ const p=V3.Lerp(a,c,k/8); if(k&&k<8){ p.x+=(Math.random()-.5)*1.1; p.y+=(Math.random()-.2)*1.2+Math.sin(k/8*Math.PI)*1.4; p.z+=(Math.random()-.5)*1.1; } pts.push(p); }
      const tb=MB.CreateTube('arc',{path:pts,radius:.07,tessellation:4},G.scene); tb.material=G.arcMat||(G.arcMat=emMat('arcM',new C3(.5,2.2,.9))); tb.isPickable=false; setTimeout(()=>tb.dispose(),110); } }
  animateFactionMats(t); updateBeacon(); updateProjectiles(dt); updateHulks(dt); updateOverlays(dt);
  if(G.rocks) for(const r of G.rocks){ r.rotation.x+=r.spin.x*dt; r.rotation.y+=r.spin.y*dt; r.rotation.z+=r.spin.z*dt; }
}

// ---------- movement animations (called by the rules engine) ----------
// a whole move is one continuous burn: a smooth curve through the hexes, accelerating, cruising and braking,
// with the nose easing round on turns (the view banks from the turn rate) and the engines flaring with thrust
function fwdOf(a){ const r=a*Math.PI/180; return new V3(Math.cos(r),0,-Math.sin(r)); }
async function animPath(u,path,opt){ opt=opt||{}; if(!path||!path.length) return; const v0=unitVis(u);
  const pk=[{q:v0.q,r:v0.r,s:0}], ak=[{a:v0.a,s:0}], rotS=[]; let s=0, la=v0.a; const rc=u.isSq?.3:.75;
  for(const st of path){ const a=shortAng(la,st.f*60); if(st.rot){ rotS.push({s,dir:Math.sign(a-la)}); s+=rc; ak.push({a,s}); } else { s+=1; pk.push({q:st.q,r:st.r,s}); ak.push({a,s}); } la=a; }
  const S=Math.max(s,.001); if(pk.at(-1).s<S) pk.push({q:pk.at(-1).q,r:pk.at(-1).r,s:S});
  // Hermite tangents over the path length, so corners round off instead of snapping
  const tan=pk.map((p,i)=>{ const a=pk.at(Math.max(0,i-1)), b=pk.at(Math.min(pk.length-1,i+1)), ds=Math.max(.001,b.s-a.s); return {q:(b.q-a.q)/ds,r:(b.r-a.r)/ds}; });
  const same=(a,b)=>!!a&&!!b&&Math.abs(a.q-b.q)+Math.abs(a.r-b.r)<1e-6;
  pk.forEach((p,i)=>{ if(i===0||i===pk.length-1||same(p,pk.at(i+1))||(i>0&&same(p,pk.at(i-1)))) tan[i]={q:0,r:0}; }); // come to rest where the ship holds position
  const posAt=x=>{ let i=0; while(i<pk.length-2&&x>pk.at(i+1).s) i++; const A=pk.at(i), Bk=pk.at(i+1), ds=Math.max(.001,Bk.s-A.s), t=clamp((x-A.s)/ds,0,1);
    if(Math.abs(Bk.q-A.q)+Math.abs(Bk.r-A.r)<1e-6) return {q:A.q,r:A.r};
    const t2=t*t, t3=t2*t, h00=2*t3-3*t2+1, h10=t3-2*t2+t, h01=-2*t3+3*t2, h11=t3-t2, mA=tan.at(i), mB=tan.at(i+1);
    return {q:h00*A.q+h10*ds*mA.q+h01*Bk.q+h11*ds*mB.q, r:h00*A.r+h10*ds*mA.r+h01*Bk.r+h11*ds*mB.r}; };
  const angAt=x=>{ let i=0; while(i<ak.length-2&&x>ak.at(i+1).s) i++; const A=ak.at(i), Bk=ak.at(Math.min(ak.length-1,i+1)); if(Bk===A) return A.a; const t=clamp((x-A.s)/Math.max(.001,Bk.s-A.s),0,1), e=t*t*(3-2*t); return A.a+(Bk.a-A.a)*e; };
  // a trapezoid speed profile: spool up, cruise, brake; big hulls take longer to get going
  const per=u.isSq?110:u.size>.8?430:u.size>.6?350:280, dur=Math.min((per*S+(u.isSq?60:260))*(opt.charge?.72:1), u.isSq?900:3600);
  const ta=u.isSq?.12:opt.charge?.45:u.size>.8?.32:.25, td=opt.charge?.05:u.isSq?.15:.3, vmax=1/(1-ta/2-td/2);
  const prog=p=>p<ta?vmax*p*p/(2*ta):p<1-td?vmax*(ta/2+(p-ta)):1-vmax*(1-p)*(1-p)/(2*td);
  const thrAt=p=>p<ta?1:p<1-td?.65:.15;
  if(!u.isSq&&G.views.get(u.id)) SFX.engine(u.size);
  const v=G.views.get(u.id); let trail=null; if(v&&!u.isSq&&v.root&&S>=1&&!(typeof process!=='undefined'&&process.env)) trail=startTrail(v); let ri=0, lastKey=0;
  await tween(dur,(e,p)=>{ const x=S*clamp(prog(p),0,1), ps=posAt(x);
    while(ri<rotS.length&&x>=rotS.at(ri).s){ if(v) rcsPuff(v,rotS.at(ri).dir); ri++; }
    const k=Math.floor(x); if(k!==lastKey){ lastKey=k; if(B) B.prog=(B.prog||0)+1; }
    u.vis={q:ps.q,r:ps.r,a:angAt(x),thr:thrAt(p),lift:u.isSq?Math.sin(p*Math.PI)*1.6:0}; }, true);
  const L=path.at(-1); for(const st of path) if(!st.rot){ u.q=st.q; u.r=st.r; } u.facing=L.f; u.vis=null; if(trail) endTrail(trail);
}
async function animMove(u,q,r,f){ return animPath(u,[{q,r,f}]); }
async function animRotate(u,f){ return animPath(u,[{rot:true,f}]); }
// engine wake: a ribbon that follows the stern and collapses once the ship stops
function startTrail(v){ try{ if(G.quality==='low') return null; const P=FAC3D[v.fac]||FAC3D.hegemony, n=new BABYLON.TransformNode('wakeN',G.scene); n.parent=v.root; n.position.set(-v.L*.5,0,0);
    const tm=new BABYLON.TrailMesh('wake',n,G.scene,Math.max(.6,v.L*.07),48,true), m=emMat('wakeM',P.eng.scale(.9),.42); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; tm.material=m; tm.isPickable=false; try{ G.glow.addExcludedMesh(tm); }catch(e){}
    return {tm,n,m}; }catch(e){ return null; } }
function endTrail(tr){ const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/1.4; tr.m.alpha=.42*Math.max(0,1-k); if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); try{ tr.tm.dispose(); tr.n.dispose(); tr.m.dispose(); }catch(e){} } }); }
// manoeuvring thrusters: small cold-gas puffs at the bow when a ship swings its nose round
function rcsPuff(v,dir){ try{ if(!v.root||G.fxReduced&&G.mobile) return; const a=v.root.rotation.y, f=fwdOf(a*180/Math.PI), side=new V3(-f.z,0,f.x).scale(dir>=0?1:-1), p=v.root.getAbsolutePosition().add(f.scale(v.L*.38)).add(side.scale(v.L*.06));
    burst(p,{n:10,c1:new C4(.85,.92,1,.7),c2:new C4(.6,.7,.8,.4),size:[.25,.7],life:[.25,.55],power:[3,7],tex:G.tex.soft,blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }catch(e){} }

// ---------- projectiles ----------
const PROJ=[]; const TORPS=new Set(); G.boltBases={};
function boltBase(col,thick,shape){ const k=col.toHexString()+thick+(shape||''); if(G.boltBases[k]) return G.boltBases[k];
  const m=MB.CreateSphere('bolt',{diameter:thick,segments:G.quality==='medium'?6:10},G.scene); m.material=typeof boltMat==='function'?boltMat('boltM'+k,col):emMat('boltM'+k,col.scale(1.35)); m.isVisible=false; m.isPickable=false; try{ G.glow.addExcludedMesh(m); }catch(e){} return G.boltBases[k]=m; } // v44: soft glowing bolts, white-hot at the core
function shoot(from,to,col,{speed=140,len=3.2,thick=.28,onArrive,overshoot=0,settle,shape}={}){
  const m=boltBase(col,thick,shape).createInstance('b'); m.isPickable=false; m.position.copyFrom(from); m.scaling.z=len/thick;
  const dir=to.subtract(from), dist=dir.length(); dir.normalize(); m.lookAt(to);
  const rec={m,dir,dist:dist+overshoot,go:0,speed,onArrive,settle,arriveAt:dist,arrived:false}; PROJ.push(rec);
  if(typeof fxp==='function'&&!G.fxReduced&&(!G.mobile||onArrive)){ const hc=C3.Lerp(col,new C3(1,1,1),.15).scale(.85); rec.halo=fxp(from,{cell:0,size:Math.min(5,thick*7+1.4),col:hc,dur:.14,grow:0,fade:1}); rec.hg=rec.halo&&rec.halo.gen; } // v44: a soft glow rides every bolt
  const tl=boltBase(col.scale(.45),thick*.55).createInstance('bt'); tl.isPickable=false; tl.scaling.z=len*4/(thick*.55); tl.position.copyFrom(from.subtract(dir.scale(len*2))); tl.lookAt(to);
  PROJ.push({m:tl,dir,dist:dist+overshoot,go:-len*2,speed,onArrive:null,arriveAt:1e9,arrived:true});
}
function updateProjectiles(dt){
  for(let i=PROJ.length-1;i>=0;i--){ const p=PROJ[i]; const step=p.speed*dt/Math.max(.2,SPEED); p.go+=step; p.m.position.addInPlace(p.dir.scale(step)); if(p.halo&&p.halo.gen===p.hg){ p.halo.sp.position.copyFrom(p.m.position); p.halo.t0=G.time; }
    if(!p.arrived && p.go>=p.arriveAt){ p.arrived=true; if(p.onArrive){ try{ p.onArrive(); }catch(e){ frameError(e); } } }
    if(p.go>=p.dist){ p.m.dispose(); PROJ.splice(i,1); } }
}
function flash(pos,size,col,dur=.35){ if(G.fxReduced){ size*=.55; col=col.scale(.6); }
  const pl=MB.CreatePlane('fl',{size:1},G.scene); pl.position.copyFrom(pos); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; pl.isPickable=false;
  const m=emMat('flM',col.scale(1.8),1); m.opacityTexture=G.tex.flare; m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; pl.material=m; pl.rotation.z=Math.random()*6;
  const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(dur*Math.max(.3,SPEED)); if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); pl.dispose(); m.dispose(); return; } pl.scaling.setAll(size*(.4+k*.9)); m.alpha=1-k*k; });
}
function burst(pos,{n=24,c1=new C4(1,.8,.4,1),c2=new C4(1,.45,.1,1),size=[.15,.5],life=[.2,.6],power=[4,14],tex=G.tex.soft,blend=BABYLON.ParticleSystem.BLENDMODE_ONEONE,grav=0,sizeGrow=false}={}){
  const ps=new BABYLON.ParticleSystem('bs',n,G.scene); ps.particleTexture=tex; ps.emitter=pos.clone(); ps.minEmitBox=V3.Zero(); ps.maxEmitBox=V3.Zero();
  ps.color1=c1; ps.color2=c2; ps.colorDead=new C4(c2.r*.2,c2.g*.2,c2.b*.2,0); ps.minSize=size[0]; ps.maxSize=size[1]; ps.minLifeTime=life[0]; ps.maxLifeTime=life[1];
  ps.minEmitPower=power[0]; ps.maxEmitPower=power[1]; ps.direction1=new V3(-1,-1,-1); ps.direction2=new V3(1,1,1); ps.gravity=new V3(0,grav,0); ps.blendMode=blend;
  if(sizeGrow){ ps.addSizeGradient(0,.5); ps.addSizeGradient(1,2.4); }
  ps.manualEmitCount=n; ps.targetStopDuration=.1; ps.disposeOnStop=true; ps.updateSpeed=.016/Math.max(.35,SPEED); ps.start();
}
function shieldDome(v,dirToAtt,col){
  if(!BABYLON.Effect.ShadersStore.shRipVertexShader){
    BABYLON.Effect.ShadersStore.shRipVertexShader=`precision highp float; attribute vec3 position; attribute vec3 normal; uniform mat4 world; uniform mat4 worldViewProjection; varying vec3 vL; varying vec3 vNW; varying vec3 vPW;
      void main(){ vL=normalize(position); vNW=normalize((world*vec4(normal,0.0)).xyz); vPW=(world*vec4(position,1.0)).xyz; gl_Position=worldViewProjection*vec4(position,1.0); }`;
    BABYLON.Effect.ShadersStore.shRipFragmentShader=`precision highp float; varying vec3 vL; varying vec3 vNW; varying vec3 vPW; uniform vec3 impact; uniform vec3 col; uniform float t; uniform vec3 camPos;
      float hexl(vec2 p){ p*=vec2(14.0,9.0); vec2 q=vec2(p.x+p.y*0.577,p.y*1.155); vec2 f=fract(q)-0.5; return smoothstep(0.42,0.5,max(abs(f.x),abs(f.y))); }
      void main(){ float ang=acos(clamp(dot(vL,impact),-1.0,1.0)); float w=exp(-pow((ang-t*2.4)*6.0,2.0))*(1.0-t); float core=exp(-ang*ang*10.0)*(1.0-t)*1.4;
        vec2 uv=vec2(atan(vL.z,vL.x),asin(clamp(vL.y,-1.0,1.0))); float hx=hexl(uv); float fr=pow(1.0-abs(dot(normalize(vNW),normalize(camPos-vPW))),2.5);
        float a=(w+core)*(0.35+0.85*hx)+fr*0.12*(1.0-t); gl_FragColor=vec4(col*a*1.7,a); }`; }
  const R=Math.max(4.2,v.L*.5); const sp=MB.CreateSphere('shRip',{diameter:2,segments:24},G.scene); sp.isPickable=false; sp.parent=v.root; sp.position.y=.5; sp.scaling=new V3(R*1.1,Math.max(2.4,v.H*.75),Math.max(3,R*.42));
  const mat=new BABYLON.ShaderMaterial('shRipM',G.scene,{vertex:'shRip',fragment:'shRip'},{attributes:['position','normal'],uniforms:['world','worldViewProjection','impact','col','t','camPos'],needAlphaBlending:true});
  mat.alphaMode=BABYLON.Engine.ALPHA_ADD; mat.backFaceCulling=false; mat.disableDepthWrite=true; sp.material=mat; G.glow.addExcludedMesh(sp);
  v.root.computeWorldMatrix(true); const inv=BABYLON.Matrix.Invert(v.root.getWorldMatrix()); const li=V3.TransformNormal(dirToAtt,inv); li.y*=.4;
  mat.setVector3('impact',li.normalize()); mat.setColor3('col',col);
  const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(.8*Math.max(.3,SPEED)); if(k>=1||sp.isDisposed()){ G.scene.onBeforeRenderObservable.remove(obs); if(!sp.isDisposed()) sp.dispose(); mat.dispose(); return; } mat.setFloat('t',k); mat.setVector3('camPos',G.cam.position); }); }

function beamTex(){ if(G.tex.beam) return G.tex.beam; G.tex.beam=dynTex('beamT',64,256,(g,w,h)=>{ g.fillStyle='#000'; g.fillRect(0,0,w,h); const r=seeded(21); for(let i=0;i<70;i++){ const y=r()*h, l=8+r()*40; const gr=g.createLinearGradient(0,y,0,y+l); gr.addColorStop(0,'rgba(255,255,255,0)'); gr.addColorStop(.5,`rgba(255,255,255,${.3+r()*.6})`); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,y,w,l); } }); G.tex.beam.hasAlpha=false; G.tex.beam.wrapV=BABYLON.Texture.WRAP_ADDRESSMODE; return G.tex.beam; }
function beam(from,to,col,width,dur){
  const len=V3.Distance(from,to); // v42: a shader beam (white core, coloured sheath, energy crawling along it); the old textured cylinder stays as the fallback
  const mk=(w,c,a,shader)=>{ const m=MB.CreateCylinder('beam',{height:1,diameter:w,tessellation:shader?14:8},G.scene); m.bakeTransformIntoVertices(BABYLON.Matrix.RotationX(Math.PI/2)); m.scaling.z=len; m.position=from.add(to).scale(.5); m.lookAt(to); m.isPickable=false;
    let mat=null; if(shader){ try{ mat=beamMaterial(c); mat.setFloat('len',len); }catch(e){ mat=null; } }
    if(!mat){ mat=emMat('bm',c,a); mat.alphaMode=BABYLON.Engine.ALPHA_ADD; mat.disableDepthWrite=true; const bt=beamTex().clone(); bt.vScale=Math.max(1,len/10); mat.emissiveTexture=bt; }
    m.material=mat; try{ G.glow.addExcludedMesh(m); }catch(e){} return [m,mat]; };
  if(!G.tex.beam){ G.tex.beam=dynTex('beamT',64,256,(g,w,h)=>{ const r=seeded(5); g.fillStyle='#000'; g.fillRect(0,0,w,h); for(let i=0;i<60;i++){ g.fillStyle=`rgba(255,255,255,${.15+r()*.4})`; g.fillRect(0,r()*h,w,2+r()*10); } }); G.tex.beam.vScale=3; }
  const sh=typeof beamMaterial==='function'; const parts=sh?[mk(width*1.15,col.scale(1.15),1,true)]:[mk(width,col.scale(1.6),.9),mk(width*.35,new C3(1,1,1).scale(1.5),1)]; if(!sh) parts[0][1].emissiveTexture=G.tex.beam;
  const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(dur*Math.max(.3,SPEED)); if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); parts.forEach(([m,mt])=>{m.dispose();mt.dispose();}); return; } G.tex.beam.vOffset=(G.time*4)%1;
    parts.forEach(([m,mt],i)=>{ if(mt.setFloat){ mt.setFloat('t',G.time%100); mt.setFloat('fade',Math.pow(1-k,1.4)); mt.setVector3('camPos',G.cam.position); } else { if(mt.emissiveTexture) mt.emissiveTexture.vOffset-=.04; mt.alpha=(1-k)*(i?1:.9); } m.scaling.x=m.scaling.y=1-k*.55+Math.sin(G.time*80)*.06; }); });
}

// ---------- high-fidelity effect kit ----------
function fireSheet(){ if(G.tex.fire) return G.tex.fire; const N=8,S=128;
  G.tex.fire=dynTex('fireSheet',S*N,S*N,(g)=>{ const img=g.createImageData(S*N,S*N), d=img.data;
    const hs=(x,y)=>{ const v=Math.sin(x*127.1+y*311.7)*43758.5453; return v-Math.floor(v); };
    const ns=(x,y)=>{ const xi=Math.floor(x),yi=Math.floor(y),xf=x-xi,yf=y-yi,u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf); return (hs(xi,yi)*(1-u)+hs(xi+1,yi)*u)*(1-v)+(hs(xi,yi+1)*(1-u)+hs(xi+1,yi+1)*u)*v; };
    const fb=(x,y)=>{ let a=.5,t=0; for(let o=0;o<4;o++){ t+=a*ns(x,y); x*=2.1; y*=2.1; a*=.5; } return t; };
    for(let f=0;f<N*N;f++){ const t=f/(N*N-1), ox=(f%N)*S, oy=Math.floor(f/N)*S;
      for(let y=0;y<S;y++) for(let x=0;x<S;x++){ const dx=(x-S/2)/(S/2), dy=(y-S/2)/(S/2), r=Math.hypot(dx,dy), n=fb(dx*3.2+f*.41+7,dy*3.2-t*2.4+3);
        const rad=.42+.46*t, m=clamp((rad-r+(n-.5)*.55)/.22,0,1), heat=clamp(1.05-t*1.25+(n-.5)*.7-r*.55,0,1);
        let R,Gc,Bc; if(heat>.66){ const k=(heat-.66)*3; R=255; Gc=225+30*k; Bc=150+105*k; } else if(heat>.33){ const k=(heat-.33)*3; R=255; Gc=105+120*k; Bc=25+125*k; } else { const k=heat*3; R=55+200*k; Gc=38+67*k; Bc=30+k*10; }
        const sm=clamp((t-.4)*1.9,0,1)*(1-heat); R=R*(1-sm)+46*sm; Gc=Gc*(1-sm)+42*sm; Bc=Bc*(1-sm)+40*sm;
        const lit=.82+.3*(-dx-dy)*.5*(sm*.8+.2); R*=lit; Gc*=lit; Bc*=lit;
        const o=((oy+y)*S*N+ox+x)*4; d[o]=R; d[o+1]=Gc; d[o+2]=Bc; d[o+3]=m*(1-Math.pow(t,2.5))*255; } }
    g.putImageData(img,0,0); });
  return G.tex.fire; }
function hexTex(){ if(G.tex.hex) return G.tex.hex; G.tex.hex=dynTex('hexT',512,512,(g,w)=>{ g.clearRect(0,0,w,w); g.strokeStyle='rgba(255,255,255,.9)'; g.lineWidth=3; const R=22, H=R*Math.sqrt(3);
    for(let row=-1;row<w/H+1;row++) for(let col=-1;col<w/(R*1.5)+1;col++){ const cx=col*R*1.5, cy=row*H+(col%2?H/2:0); g.beginPath(); for(let i=0;i<=6;i++){ const a=i*Math.PI/3; g.lineTo(cx+R*Math.cos(a),cy+R*Math.sin(a)); } g.stroke(); } }); return G.tex.hex; }
let LIGHTS=0;
function lightFlash(pos,col,intensity,range,dur){ if(LIGHTS>=(G.quality==='ultra'?4:2)||G.quality==='medium'||G.fxReduced) return; LIGHTS++; const l=new BABYLON.PointLight('xl',pos.clone(),G.scene); l.diffuse=col; l.specular=col; l.range=range; l.intensity=intensity; const t0=G.time;
  const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(dur*Math.max(.3,SPEED)); if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); l.dispose(); LIGHTS--; return; } l.intensity=intensity*(1-k)*(1-k); }); }
function fireball(pos,size,n,life=1.2,spread=.35){ const ps=new BABYLON.ParticleSystem('fb',n,G.scene,null,true); ps.particleTexture=fireSheet(); ps.spriteCellWidth=128; ps.spriteCellHeight=128; ps.startSpriteCellID=0; ps.endSpriteCellID=63; ps.spriteCellLoop=false; ps.spriteCellChangeSpeed=1;
  ps.emitter=pos.clone(); ps.createSphereEmitter(size*spread,1); ps.color1=new C4(1,1,1,1); ps.color2=new C4(1,.92,.85,1); ps.colorDead=new C4(1,1,1,0); ps.minSize=size*.55; ps.maxSize=size*1.25;
  ps.minLifeTime=life*.7; ps.maxLifeTime=life*1.2; ps.minEmitPower=size*.08; ps.maxEmitPower=size*.35; ps.minAngularSpeed=-1.2; ps.maxAngularSpeed=1.2; ps.minInitialRotation=0; ps.maxInitialRotation=6.28;
  ps.blendMode=BABYLON.ParticleSystem.BLENDMODE_STANDARD; ps.manualEmitCount=n; ps.targetStopDuration=.15; ps.disposeOnStop=true; ps.updateSpeed=.016/Math.max(.35,SPEED); ps.start(); }
function sparks(pos,n,power,col=new C4(1,.8,.45,1)){ const ps=new BABYLON.ParticleSystem('sp',n,G.scene); ps.particleTexture=G.tex.soft; ps.emitter=pos.clone(); ps.createSphereEmitter(.2,1);
  ps.billboardMode=BABYLON.ParticleSystem.BILLBOARDMODE_STRETCHED; ps.color1=col; ps.color2=new C4(1,.5,.15,1); ps.colorDead=new C4(.4,.1,0,0); ps.minSize=.06; ps.maxSize=.2; ps.minScaleY=3; ps.maxScaleY=7;
  ps.minLifeTime=.3; ps.maxLifeTime=.9; ps.minEmitPower=power*.4; ps.maxEmitPower=power; ps.gravity=new V3(0,-2,0); ps.blendMode=BABYLON.ParticleSystem.BLENDMODE_ONEONE; ps.manualEmitCount=n; ps.targetStopDuration=.1; ps.disposeOnStop=true; ps.updateSpeed=.016/Math.max(.35,SPEED); ps.start(); }
function smoke(pos,size,n,life=2.6){ burst(pos,{n,tex:G.tex.smoke,c1:new C4(.34,.31,.29,.7),c2:new C4(.16,.15,.14,.55),size:[size*.5,size*1.1],life:[life*.6,life],power:[size*.1,size*.45],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }
function explode(pos,size,{light=true,shock=false}={}){ flash(pos,size*2.2,new C3(1,.85,.6),.35); if(typeof fxSprite==='function'&&size>=1) fxSprite(pos,size*3.2,new C3(1,.78,.5),starTex(),.22,{grow:.7}); const shFire=typeof fireballFx==='function'&&!G.fxReduced&&(size>=(G.quality==='medium'?3:1.3)); if(shFire) fireballFx(pos,size*1.15,.75+size*.05); fireball(pos,size,Math.round((shFire?3:5)+size*(shFire?.6:1.2))); sparks(pos,Math.round(20+size*8),6+size*2.5); smoke(pos,size*1.2,Math.round(4+size));
  if(light) lightFlash(pos,new C3(1,.62,.3),3+size*.6,size*9,.6); if(shock) shockwave(pos,size*3); }
function muzzleFx(pos,out,col){ if(typeof muzzleBlast==='function'){ muzzleBlast(pos,out,col); return; } flash(pos,2.4,col,.18); const p=pos.add(out.scale(.4)); burst(p,{n:4,tex:G.tex.smoke,c1:new C4(.5,.47,.44,.5),c2:new C4(.3,.28,.27,.35),size:[.5,1],life:[.8,1.5],power:[.5,1.5],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }

// ---------- persistent battle damage ----------
let SCORCH=null;
function scorchMat(){ if(SCORCH) return SCORCH; const t=dynTex('scorchT',128,128,(g,w)=>{ const c=w/2, r=seeded(17); for(let i=0;i<40;i++){ const x=c+(r()-.5)*w*.5,y=c+(r()-.5)*w*.5,rad=w*(.08+r()*.2); const gr=g.createRadialGradient(x,y,0,x,y,rad); gr.addColorStop(0,'rgba(8,6,5,.55)'); gr.addColorStop(1,'rgba(8,6,5,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); }
    g.strokeStyle='rgba(15,10,8,.6)'; g.lineWidth=2; for(let i=0;i<8;i++){ g.beginPath(); g.moveTo(c,c); let x=c,y=c; for(let k=0;k<5;k++){ x+=(r()-.5)*24; y+=(r()-.5)*24; g.lineTo(x,y); } g.stroke(); } });
  const m=new BABYLON.StandardMaterial('scorchM',G.scene); m.diffuseTexture=t; m.diffuseTexture.hasAlpha=true; m.useAlphaFromDiffuseTexture=true; m.specularColor=C3.Black(); m.backFaceCulling=false; m.zOffset=-2; return SCORCH=m; }
function surfAtModel(sf,x){ const st=sf.st; if(x<=st[0].x) return st[0]; for(let i=0;i<st.length-1;i++) if(x>=st[i].x&&x<=st[i+1].x) return interpStation(st[i],st[i+1],x); return st[st.length-1]; }
function hullDecal(vt,from,big){ const md=vt&&vt.model; if(!md||!md.surf||!vt.root||vt.root.isDisposed()) return; const L=vt.L; vt.root.computeWorldMatrix(true);
  const lf=V3.TransformCoordinates(from,BABYLON.Matrix.Invert(vt.root.getWorldMatrix())), side=lf.z>=0?1:-1, x=(Math.random()-.5)*L*.75, st=surfAtModel(md.surf,x); if(!st||st.w<L*.02) return;
  const y=(st.y||0)+(Math.random()-.3)*st.t*.7, node=x>=md.surf.split?md.fore:md.aft; if(!node||node.isDisposed()) return; const sz=(big?2.2:1.1)*(.7+Math.random()*.6)*Math.max(1,L/14);
  const pl=MB.CreatePlane('scorch',{size:sz},G.scene); pl.material=scorchMat(); pl.isPickable=false; G.glow.addExcludedMesh(pl); pl.parent=node; pl.position.set(x,y,side*(st.w+L*.004)); pl.rotation.set(0,side>0?Math.PI:0,Math.random()*6);
  const em=MB.CreatePlane('ember',{size:sz*.45},G.scene), eM=emMat('emberM',new C3(1.4,.55,.15),1); eM.opacityTexture=G.tex.soft; eM.alphaMode=BABYLON.Engine.ALPHA_ADD; eM.disableDepthWrite=true; em.material=eM; em.parent=node; em.position.set(x,y,side*(st.w+L*.006)); em.rotation.copyFrom(pl.rotation); em.isPickable=false;
  const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/9; if(k>=1||em.isDisposed()){ G.scene.onBeforeRenderObservable.remove(obs); if(!em.isDisposed()) em.dispose(); eM.dispose(); return; } eM.alpha=(1-k)*(.7+.3*Math.sin(G.time*13+x)); });
  (vt.decals=vt.decals||[]).push(pl); if(vt.decals.length>28){ const old=vt.decals.shift(); if(!old.isDisposed()) old.dispose(); } }

// ---------- weapon fire (called by the rules engine before damage is applied) ----------
function hitPoint(vt,att,shielded){
  const c=vt.root.getAbsolutePosition(); const toA=att.subtract(c); toA.y=0; toA.normalize();
  if(shielded) return c.add(toA.scale(Math.max(4.2,vt.L*.5)*.85)).add(new V3(0,1,0));
  const local=new V3((Math.random()-.5)*vt.L*.55,Math.random()*vt.H*.6,(Math.random()-.5)*vt.L*.1); return toWorld(vt,local);
}
function missPoint(vt,from){ const c=vt.root.getAbsolutePosition(); const d=c.subtract(from); d.y=0; d.normalize(); const perp=new V3(-d.z,0,d.x).scale((Math.random()<.5?-1:1)*(vt.L*.45+3+Math.random()*4)); return c.add(perp).add(d.scale(10+Math.random()*14)).add(new V3(0,(Math.random()-.3)*4,0)); }
function muzzles(v,arc,tgtPos){
  if(v.crafts) return v.crafts.map(c=>c.c.root.getAbsolutePosition().clone());
  const h=v.model.hard; let list=(arc==='P'?h.P:arc==='S'?h.S:arc==='F'?h.F:h.T); if(!list||!list.length) list=h.T.length?h.T:h.F;
  return list.map(p=>toWorld(v,p));
}
// v44 volleys: every barrel on the engaged side joins in, rippling bow to stern. Purely visual; the lead bolts still carry the dice
function turretTips(v){ const out=[]; const T=v.model&&v.model.turrets; if(!T) return out; for(const t of T){ try{ t.yaw.computeWorldMatrix(true); const s=t.inst.scaling.x, m=t.yaw.getWorldMatrix();
    for(const x of [.18,-.18]) out.push({p:V3.TransformCoordinates(new V3(x*s,.34*s,1.7*s),m),o:V3.TransformNormal(new V3(0,0,1),m).normalize(),x:t.yaw.position.x,tur:t}); }catch(e){} } return out; }
function volleyPlan(va,w,nShots,tgtPos){ const md=va.model; if(!md||!md.guns) return [];
  const cap=G.fxReduced?6:G.mobile?9:G.quality==='ultra'?42:G.quality==='high'?30:14; let src=(md.guns[w.arc]||[]).slice(); if(w.arc==='T') src=src.concat(md.guns.P.filter((_,i)=>i%3===0),md.guns.S.filter((_,i)=>i%3===0));
  const c=va.root.getAbsolutePosition(); va.root.computeWorldMatrix(true); const M=va.root.getWorldMatrix();
  let pts=src.map(lp=>{ const p=V3.TransformCoordinates(lp,M), o=p.subtract(c); o.y*=.2; return {p,o:o.normalize(),x:lp.x}; });
  if(w.arc==='P'||w.arc==='S'||w.arc==='T'){ const tt=turretTips(va); for(const t of tt) pts.push(t); }
  if(tgtPos){ const toT=tgtPos.subtract(c).normalize(); pts=pts.filter(q=>V3.Dot(q.o,toT)>-.25); for(const q of pts) if(!q.tur) q.o=V3.Lerp(q.o,tgtPos.subtract(q.p).normalize(),.6).normalize(); }
  for(let i=pts.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [pts[i],pts[j]]=[pts[j],pts[i]]; } pts=pts.slice(0,Math.max(0,cap-nShots));
  pts.sort((a,b)=>b.x-a.x); return pts; }
async function cineFrame(a,t){
  if(!G.cine||a.isSq||B.over) return;
  if(G.mobile&&!((t.t&&t.t.boss)||(a.t&&a.t.boss)||(t.hp!=null&&t.maxHp&&t.hp<=t.maxHp*.35))) return; // phones: swing in only for likely kills and flagship duels
  clearTimeout(G.cineTimer);
  const pa=uWorld(a), pt=uWorld(t), mid=pa.add(pt).scale(.5); mid.y=0;
  const dx=pt.x-pa.x, dz=pt.z-pa.z, dist=Math.hypot(dx,dz);
  const base=Math.atan2(dz,dx); let al=base+Math.PI/2, al2=base-Math.PI/2; const cur=G.ctl.a;
  const norm=x=>{ while(x-cur>Math.PI) x-=2*Math.PI; while(x-cur<-Math.PI) x+=2*Math.PI; return x; }; al=norm(al); al2=norm(al2);
  const fresh=!G.ctl.saved;
  if(G.quality==='ultra'&&G.pipe&&!G.fxReduced){ try{ G.pipe.depthOfFieldEnabled=true; G.pipe.depthOfFieldBlurLevel=BABYLON.DepthOfFieldEffectBlurLevel.Low; G.pipe.depthOfField.focalLength=90; G.pipe.depthOfField.fStop=2.4; G.pipe.depthOfField.focusDistance=clamp(dist*1.25+34,60,200)*1000; }catch(e){} }
  G.ctl.hold(mid,Math.abs(al-cur)<Math.abs(al2-cur)?al:al2,1.02,clamp(dist*1.25+34,60,200));
  if(fresh) await wait(320);
  G.cineTimer=setTimeout(()=>G.ctl.release(),900*SPEED);
}
// every faction's guns look different: heavy shells, paired turbolasers, scattered tracers, bio-plasma globs, light needles, gauss rails
const WSTYLE={voidsworn:'shell',hegemony:'twin',corsair:'tracer',chorus:'glob',ithar:'needle',deathless:'rail'};
const WOPT={shell:{speed:120,len:2.2,thick:.46},twin:{speed:210,len:5.5,thick:.17},tracer:{speed:170,len:2,thick:.13},glob:{speed:72,len:1.4,thick:1.05,shape:'sphere'},needle:{speed:290,len:8,thick:.1}};
async function animWeapon(u,w,t,shots){
  const va=G.views.get(u.id), vt=G.views.get(t.id); if(!va||!vt) return;
  if(w.k==='lance'||w.k==='torp') await cineFrame(u,t);
  const P=FAC3D[va.fac]||FAC3D.hegemony, quad=shieldQuad(t,u), shielded=(t.sh[quad]||0)>.5&&(w.pierce||0)<1;
  let col=w.ion?new C3(.45,.75,1):w.k==='lance'?P.beam:w.k==='gauss'?FAC3D.deathless.bolt:w.k==='bio'?FAC3D.chorus.bolt:P.bolt;
  if(u.isSq) col=P.bolt;
  const style=(u.isSq||w.k==='flak'||w.k==='lance'||w.k==='torp')?null:(w.k==='gauss'?'rail':w.k==='bio'?'glob':WSTYLE[va.fac]||'shell');
  const tp=vt.root.getAbsolutePosition(), mz=muzzles(va,w.arc,tp).sort((p1,p2)=>V3.Distance(p1,tp)-V3.Distance(p2,tp));
  if(w.arc==='T'&&typeof aimTurrets==='function'&&va.model&&va.model.turrets){ aimTurrets(va,tp); await wait(160); }
  const impact=(hit,from)=>{ if(t.dead&&!vt.root) return; if(!hit){ return; }
    const p=hitPoint(vt,from,shielded);
    if(shielded){ shieldDome(vt,from.subtract(tp).normalize(),SHIELD_C); burst(p,{n:16,c1:new C4(.6,.9,1,1),c2:new C4(.3,.6,1,1),power:[3,9]}); SFX.shield(); if((w.pierce||0)>0) explode(hitPoint(vt,from,false),.8,{light:false}); }
    else { if(Math.random()<(w.k==='torp'||w.k==='lance'?1:.35)) hullDecal(vt,from,w.k==='torp'); if((w.k==='torp'||w.k==='lance')&&!vt.jolt){ const d=tp.subtract(from); d.y=0; d.normalize(); vt.jolt={d:d.scale(w.k==='torp'?1.6:.9),t0:G.time}; } // big hits rock the ship
      if(w.k==='torp'){ explode(p,4.5,{shock:true}); G.shake=Math.min(1,G.shake+.35); if(!G.fxReduced) G.pulse=Math.min(1.2,(G.pulse||0)+.35); SFX.boom(.8); } else if(w.k==='lance'){ explode(p,1.8); sparks(p,40,14,new C4(1,.95,.8,1)); SFX.hit(); } else if(style==='glob'){ explode(p,.8,{light:false}); burst(p,{n:22,c1:new C4(1,.45,.85,1),c2:new C4(.55,1,.4,1),size:[.3,.8],life:[.3,.8],power:[3,8]}); SFX.hit(); }
      else if(style==='needle'){ explode(p,.8,{light:false}); burst(p,{n:14,c1:new C4(.85,1,1,1),c2:new C4(.5,.85,1,1),size:[.1,.35],power:[6,14]}); SFX.hit(); }
      else { explode(p,style==='shell'?1.4:1.1,{light:Math.random()<.3}); SFX.hit(); } } };
  if(w.k==='lance'){
    for(let i=0;i<shots.length;i++){ const from=mz[i%mz.length], h=shots[i], to=h?hitPoint(vt,from,shielded):missPoint(vt,from);
      if(typeof chargeFx==='function') chargeFx(from,col); flash(from,5,col,.35); lightFlash(from,col,2,40,.5); await wait(100); beam(from,to,col,w.ion?1.1:1.6,.7); if(typeof beamMaterial!=='function') beam(from,to,col.scale(.6),w.ion?2.6:3.6,.45); SFX.lance(!!w.ion); if(h){ impact(true,from); if(typeof fxSprite==='function') fxSprite(to,7,C3.Lerp(col,new C3(1,1,1),.4).scale(1.5),starTex(),.6,{grow:.5,spin:2}); } else flash(to,2,col.scale(.6)); await wait(150); }
    await wait(150);
  } else if(w.k==='torp'){
    const arrivals=shots.map((h,i)=>new Promise(res=>{ setTimeout(()=>{ const from=mz[i%mz.length]; const to=h?hitPoint(vt,from,shielded):missPoint(vt,from);
      const m=MB.CreateCylinder('torp',{height:1.4,diameterTop:0,diameterBottom:.45,tessellation:8},G.scene); m.bakeTransformIntoVertices(BABYLON.Matrix.RotationX(Math.PI/2)); m.material=emMat('tm',col.scale(1.8)); m.position.copyFrom(from); m.isPickable=false;
      const tr=new BABYLON.ParticleSystem('trail',240,G.scene); tr.particleTexture=G.tex.smoke; tr.emitter=m; tr.color1=new C4(1,.7,.35,.8); tr.color2=new C4(.6,.5,.45,.5); tr.colorDead=new C4(.1,.1,.1,0); tr.minSize=.4; tr.maxSize=.9; tr.minLifeTime=.4; tr.maxLifeTime=.9; tr.emitRate=160; tr.minEmitPower=.1; tr.maxEmitPower=.4; tr.addSizeGradient(0,.5); tr.addSizeGradient(1,2); tr.blendMode=BABYLON.ParticleSystem.BLENDMODE_STANDARD; tr.start();
      let trl=null, head=null; try{ trl=new BABYLON.TrailMesh('ttr',m,G.scene,.42,G.quality==='medium'?24:44,true); const tmM=emMat('ttrM',col.scale(1.5),.55); tmM.alphaMode=BABYLON.Engine.ALPHA_ADD; tmM.disableDepthWrite=true; tmM.backFaceCulling=false; trl.material=tmM; trl.isPickable=false; try{ G.glow.addExcludedMesh(trl); }catch(e){}
        head=MB.CreatePlane('thead',{size:2.6},G.scene); head.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; head.parent=m; head.isPickable=false; const hm=emMat('theadM',C3.Lerp(col,new C3(1,1,1),.4).scale(1.8),1); hm.opacityTexture=G.tex.flare; hm.alphaMode=BABYLON.Engine.ALPHA_ADD; hm.disableDepthWrite=true; head.material=hm; }catch(e){}
      SFX.torp(); const dur=.75, t0=G.time;
      const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=Math.min(1,(G.time-t0)/(dur*Math.max(.3,SPEED))); const p=V3.Lerp(from,to,k); p.y+=Math.sin(k*Math.PI)*3; m.lookAt(p.add(to.subtract(from).normalize().scale(2))); m.position.copyFrom(p);
        if(head&&head.material) head.material.alpha=.75+.25*Math.sin(G.time*40);
        if(typeof pdFire==='function'&&k>.25&&k<.92) pdFire(vt,p);
        if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); TORPS.delete(rec); tr.stop(); setTimeout(()=>tr.dispose(),1200); if(trl){ const tm=trl.material; trl.stop&&trl.stop(); vfxFadeDispose(trl,tm,.5); } if(head){ head.parent=null; head.material.dispose(); head.dispose(); } m.dispose(); try{ if(h) impact(true,from); else flash(to,3,new C3(1,.6,.3)); } finally{ res(); } } });
      const rec={obs,m,tr,res}; TORPS.add(rec);
    }, i*120*SPEED); }));
    await Promise.all(arrivals); await wait(90);
  } else {
    const gap=w.k==='flak'?45:u.isSq?55:70, speed=w.k==='flak'?170:u.isSq?110:150;
    if(!u.isSq&&typeof fxp==='function'){ try{ const vol=volleyPlan(va,w,shots.length,tp).filter((_,i)=>w.k!=='flak'||i%2===0), span=Math.max(shots.length*gap,300+vol.length*9), anyHit=shots.some(x=>x), o=style?WOPT[style]||WOPT.needle:null;
      vol.forEach((q,j)=>{ setTimeout(()=>{ try{ if(!vt.root||vt.root.isDisposed()) return; const h=anyHit&&Math.random()<.78, to=h?hitPoint(vt,q.p,shielded):missPoint(vt,q.p); if(h&&shielded) to.addInPlace(new V3((Math.random()-.5)*vt.L*.35,(Math.random()-.3)*2.5,(Math.random()-.5)*vt.L*.35)); volleyMuzzle(q.p,q.o,col); if(j%3===0) SFX.gun(w.k,false);
          const opt=w.k==='flak'?{speed:175,len:1.3,thick:.15}:style==='rail'?{speed:420,len:11,thick:.12}:o?{speed:o.speed*(.92+Math.random()*.16),len:o.len,thick:o.thick*.85,shape:o.shape}:{speed,len:3,thick:.26};
          const done=()=>{ if(h){ volleyImpact(to,col,shielded,q.p); if(!shielded&&Math.random()<.06) hullDecal(vt,q.p,false); } };
          if(style==='twin'){ const sd=V3.Cross(to.subtract(q.p),new V3(0,1,0)).normalize().scale(.5); shoot(q.p.add(sd),to.add(sd),col,{...opt,overshoot:h?0:30}); }
          shoot(q.p,to,col,{...opt,overshoot:h?0:30,onArrive:done}); }catch(e){} },(j/Math.max(1,vol.length))*span*SPEED+Math.random()*25); }); }catch(e){ console.warn('volley',e); } }
    const arrivals=shots.map((h,i)=>new Promise(res=>{ setTimeout(()=>{ const from=mz[i%mz.length]; const to=h?hitPoint(vt,from,shielded):missPoint(vt,from);
      if(!u.isSq){ if(w.k==='flak') flash(from,1.2,col); else { const out=from.subtract(va.root.getAbsolutePosition()); out.y=0; muzzleFx(from,out.normalize(),col); } } SFX.gun(w.k,u.isSq);
      if(style==='rail'){ beam(from,to,col,.42,.32); flash(from,2,col,.15); setTimeout(()=>{ try{ if(h) impact(true,from); else flash(to,1.5,col.scale(.6)); }catch(e){ frameError(e); } finally{ res(); } },60*Math.max(.3,SPEED)); return; }
      const o=style?WOPT[style]:null;
      if(style==='twin'){ const sd=V3.Cross(to.subtract(from),new V3(0,1,0)).normalize().scale(.6); shoot(from.add(sd),to.add(sd),col,{speed:o.speed,len:o.len,thick:o.thick,overshoot:h?0:30}); }
      if(style==='tracer') for(let j=0;j<2;j++){ const jt=new V3((Math.random()-.5)*2.4,(Math.random()-.5)*1.2,(Math.random()-.5)*2.4); shoot(from,to.add(jt),col,{speed:o.speed*(.9+Math.random()*.2),len:o.len,thick:o.thick,overshoot:20}); }
      shoot(from,to,col,{speed:o?o.speed:speed,len:o?o.len:w.k==='flak'?1.2:u.isSq?1.6:3.4,thick:o?o.thick:w.k==='flak'?.14:u.isSq?.16:.3,shape:o&&o.shape,overshoot:h?0:30,settle:res,onArrive:()=>{ try{ if(h){ if(w.k==='flak'&&t.isSq){ burst(to,{n:10,tex:G.tex.smoke,c1:new C4(.9,.9,.85,.6),c2:new C4(.5,.5,.5,.4),size:[.5,1.2],power:[1,3],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD}); } else impact(true,from); } } finally{ res(); } }});
    }, i*gap*SPEED); }));
    await Promise.all(arrivals); await wait(90);
  }
}

// ---------- floating text and generic hooks ----------
function fxText(u,txt,color,dy=0){
  if(!G.scene) return; const p=uWorld(u); const v=G.views.get(u.id); p.y+=(v?v.H:3)+1;
  const cw=G.engine.getRenderingCanvas().clientWidth, ch=G.engine.getRenderingCanvas().clientHeight;
  const sp=V3.Project(p,BABYLON.Matrix.Identity(),G.scene.getTransformMatrix(),G.cam.viewport.toGlobal(cw,ch)); if(sp.z<0||sp.z>1) return;
  const el=document.createElement('div'); el.className='ftxt'; el.textContent=txt; el.style.color=color; el.style.left=sp.x+'px'; el.style.top=(sp.y+dy)+'px'; document.getElementById('plates').appendChild(el); setTimeout(()=>el.remove(),1300);
}
function fxShield(u,quad){ const v=G.views.get(u.id); if(!v) return; v.ring.segs.forEach((s,i)=>{ if(quad<0||quad===i) s.pulse=1; }); if(quad<0){ const c=v.root.getAbsolutePosition(); shieldDome(v,new V3(0,1,0),SHIELD_C); SFX.shield(); } }
function ripple(p,n){ const r=MB.CreateTorus('rip',{diameter:1,thickness:.08,tessellation:32},G.scene); r.position=p.clone(); r.rotationQuaternion=qFromUp(n); r.isPickable=false; const m=emMat('ripM',SHIELD_C.scale(1.6),1); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; r.material=m;
  const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(.5*Math.max(.3,SPEED)); if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); r.dispose(); m.dispose(); return; } r.scaling.setAll(1+k*7); m.alpha=(1-k); }); }
function fxShieldBreak(u,quad){ const v=G.views.get(u.id); if(!v) return; const c=v.root.getAbsolutePosition(); const a=((quad===0?0:quad===1?90:quad===2?180:270)+unitVis(u).a)*Math.PI/180; const d=new V3(Math.cos(a),0,-Math.sin(a)); const p=c.add(d.scale(Math.max(4.2,v.L*.5)));
  shieldDome(v,d,SHIELD_C.scale(1.6)); if(typeof shieldShatter==='function') shieldShatter(p,d,SHIELD_C); burst(p,{n:40,c1:new C4(.7,.95,1,1),c2:new C4(.2,.5,1,1),size:[.12,.4],power:[6,16]}); flash(p,5,SHIELD_C,.3); const s=v.ring.segs[quad]; if(s) s.pulse=1.6; SFX.shield(); }
function fxFlash(h,color){ const p=hexWorld(h.q,h.r,1); flash(p,8,hexC3(color.length===7?color:'#f0b35a')); }

// ---------- destruction ----------
G.hulks=[];
async function animExplode(u){
  const v=G.views.get(u.id); if(!v||v.state!=='alive') return;
  const c=v.root.getAbsolutePosition().clone();
  if(u.isSq){ v.state='dead'; flash(c,5,new C3(1,.7,.4)); burst(c,{n:30,power:[5,14]}); SFX.pop(); disposeView(v); G.views.delete(u.id); await wait(250); return; }
  v.state='dying'; if(v.engLight){ v.engLight.dispose(); v.engLight=null; } (v.extras||[]).forEach(p=>p.stop()); v.plate.el.remove(); v.ring.node.dispose(false,true); v.fires.forEach(f=>f.stop()); v.fires=[];
  const L=v.L;
  // v44: the death plays out: the hull scorches and splits with glowing cracks, internal blasts tear through it, then the reactor goes
  try{ if(typeof shipDamageFx==='function'){ v.state='alive'; shipDamageFx(v,-1); v.state='dying'; } }catch(e){}
  if(G.cine&&!G.fxReduced&&!B.over){ try{ clearTimeout(G.cineTimer); G.ctl.hold(new V3(c.x,0,c.z),G.ctl.a+.35,1.05,clamp(L*3.4+40,60,190)); G.cineTimer=setTimeout(()=>G.ctl.release(),2300*SPEED); }catch(e){} }
  for(let i=0;i<5;i++){ const p=toWorld(v,new V3((Math.random()-.5)*L*.8,Math.random()*v.H*.6,(Math.random()-.5)*L*.12)); explode(p,1.5+L*.08,{light:i%2===0}); if(typeof fxStreak==='function'&&i%2===0){ const o=p.subtract(c); o.y=Math.abs(o.y)+.5; fxStreak(p,o.normalize(),6+L*.25,3+L*.06,new C3(1,.6,.25).scale(1.6),coneTex(),.35); } if(i%2===0) SFX.hit(); await wait(90); }
  if(typeof fxSprite==='function'){ fxSprite(c,L*2.6,new C3(1,.9,.75).scale(1.5),starTex(),.55,{grow:.8}); shockRing(c,L*3.2,(FAC3D[v.fac]||FAC3D.hegemony).eng.scale(1.3),{flat:true,dur:1.6,thick:.03,tilt:.5}); }
  flash(c,L*1.4,new C3(1,.85,.6),.7); if(!G.fxReduced) G.pulse=Math.min(1.2,(G.pulse||0)+.9); explode(c,L*.45); if(typeof fireballFx==='function'&&!G.fxReduced) fireballFx(c.add(new V3(0,1,0)),L*.42,1.7); fireball(c.add(new V3(0,1,0)),L*.35,10,1.8,.6); lightFlash(c,new C3(1,.7,.4),10,L*14,1.2); sparks(c,160,30);
  burst(c,{n:50,tex:G.tex.smoke,c1:new C4(.5,.42,.36,.8),c2:new C4(.2,.18,.16,.6),size:[2,5],life:[1.2,2.6],power:[2,7],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true});
  shockwave(c,L*2.4); SFX.boom(1.2); G.shake=Math.min(1,G.shake+.6+L/60);
  debris(c,L,v.fac);
  // split the hull and let the wreck drift out of the battle plane
  if(v.model.toSplit){ try{ v.model.toSplit(); }catch(e){ console.error(e); } }
  const M=facMats(v.fac); const dm=v.dmgMats; v.dmgMats=null; for(const m of v.model.meshes){ m.material=(m.material===M.win||m.material===M.eng||m.material===M.tip)?M.ember:M.wreck; m.isPickable=false; } if(dm) setTimeout(()=>{ try{ dm.forEach(m=>m.dispose(false,false)); }catch(e){} },0);
  v.model.plumes.forEach(p=>p.dispose()); (v.model.flares||[]).forEach(p=>p.dispose()); (v.model.anim||[]).forEach(an=>an.node.dispose()); (v.stackFx||[]).forEach(ps=>ps.dispose()); v.stackFx=null; (v.fires||[]).forEach(p=>p.dispose()); v.fires=[];
  const fwd=new V3(Math.cos(v.root.rotation.y),0,-Math.sin(v.root.rotation.y));
  const nodes=[v.model.fore,v.model.aft], persist=!!u.hulk;
  for(const [n,sgn] of [[v.model.fore,1],[v.model.aft,-1]]){ const wp=n.getAbsolutePosition().clone(); const wr=v.root.rotation.clone(); n.parent=null; n.position=wp; n.rotation=wr.clone();
    n.vel=fwd.scale(sgn*(1.2+Math.random())).add(new V3((Math.random()-.5)*.6,persist?0:-.35-Math.random()*.3,(Math.random()-.5)*.6)); n.spin=new V3((Math.random()-.5)*.25,(Math.random()-.5)*.2,sgn*(.12+Math.random()*.2));
    const ps=new BABYLON.ParticleSystem('hf',120,G.scene); ps.particleTexture=G.tex.smoke; ps.emitter=n; ps.color1=new C4(1,.5,.15,.8); ps.color2=new C4(.5,.3,.2,.5); ps.colorDead=new C4(0,0,0,0); ps.minSize=.8; ps.maxSize=2; ps.minLifeTime=.5; ps.maxLifeTime=1.4; ps.emitRate=40; ps.addSizeGradient(0,.6); ps.addSizeGradient(1,2.6); ps.minEmitPower=.5; ps.maxEmitPower=1.5; ps.start(); n.ps=ps; }
  G.hulks.push({nodes,t0:G.time,persist,L}); v.root.dispose(true,false); v.state='hulk'; G.views.delete(u.id);
  await wait(280);
}
function updateHulks(dt){
  for(let i=G.hulks.length-1;i>=0;i--){ const h=G.hulks[i]; const age=G.time-h.t0; if(typeof hulkCookOff==='function') hulkCookOff(h,dt);
    for(const n of h.nodes){ n.position.addInPlace(n.vel.scale(dt)); n.rotation.addInPlace(n.spin.scale(dt));
      if(h.persist){ n.vel.scaleInPlace(Math.max(0,1-dt*.9)); n.spin.scaleInPlace(Math.max(0,1-dt*.6)); if(age>6&&n.ps) n.ps.emitRate=Math.max(8,40-(age-6)*8); }
      else { n.vel.y-=dt*.08; if(age>6&&n.ps) n.ps.emitRate=Math.max(0,40-(age-6)*8); } }
    if(h.persist&&age>25&&!h.burnedOut){ h.burnedOut=true; h.nodes.forEach(n=>n.ps&&n.ps.stop()); } // permanent wrecks stop burning
    if(!h.persist&&age>22){ h.nodes.forEach(n=>{ if(n.ps){ n.ps.dispose(); } n.dispose(); }); G.hulks.splice(i,1); } }
}
function shockwave(c,size){ if(typeof shockRing==='function'){ shockRing(c,size*1.15,new C3(1,.72,.45),{flat:true,dur:1.1,thick:.05}); if(size>30) shockRing(c,size*.6,new C3(1,.9,.8),{flat:false,dur:.7,thick:.06}); return; } const d=MB.CreateDisc('sw',{radius:1,tessellation:48},G.scene); d.rotation.x=Math.PI/2; d.position=c.clone(); d.isPickable=false; const m=emMat('swM',new C3(1,.75,.5),1); m.opacityTexture=G.tex.ring; m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.backFaceCulling=false; m.disableDepthWrite=true; d.material=m;
  const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(1.1*Math.max(.3,SPEED)); if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); d.dispose(); m.dispose(); return; } d.scaling.setAll(size*(.2+Math.sqrt(k))); m.alpha=(1-k)*(1-k)*.5; }); }
function debris(c,L,fac){ const M=facMats(fac); const n=Math.round(10+L*.8); const pieces=[];
  for(let i=0;i<n;i++){ const s=.3+Math.random()*L*.06; const m=MB.CreateBox('deb',{width:s,height:s*.4,depth:s*.7},G.scene); m.material=Math.random()<.3?M.ember:M.wreck; m.position=c.add(new V3((Math.random()-.5)*L*.4,(Math.random()-.5)*2,(Math.random()-.5)*L*.2)); m.isPickable=false;
    pieces.push({m,vel:new V3((Math.random()-.5),(Math.random()-.3)*.6,(Math.random()-.5)).normalize().scale(4+Math.random()*16),spin:new V3(Math.random()*4,Math.random()*4,Math.random()*4)}); }
  if(typeof debrisTrail==='function'&&!G.fxReduced) pieces.slice(0,G.quality==='medium'?3:7).forEach(p=>{ p.m.material=M.ember; p.tr=debrisTrail(p.m,3+Math.random()*2); }); // v44: burning chunks
  const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const age=G.time-t0, dt=G.engine.getDeltaTime()/1000;
    for(const p of pieces){ p.m.position.addInPlace(p.vel.scale(dt)); p.vel.scaleInPlace(1-dt*.25); p.m.rotation.addInPlace(p.spin.scale(dt)); if(age>5) p.m.scaling.scaleInPlace(1-dt*.6); }
    if(age>9){ G.scene.onBeforeRenderObservable.remove(obs); pieces.forEach(p=>{ if(p.tr){ try{ p.tr.dispose(); }catch(e){} } p.m.dispose(); }); } });
}
// Ithar phase jump: a flash where the ship was, then the hyperspace arrival plays at the new hex
async function animBlink(u,from){ const v=G.views.get(u.id); if(!v) return; const P=FAC3D[v.fac]||FAC3D.ithar; try{ flash(hexWorld(from.q,from.r,HOVER_Y),6+v.L*.2,P.eng.scale(1.4),.3); }catch(e){} v.arrive={t0:G.time}; try{ SFX.launch(); }catch(e){} await wait(750*Math.max(.4,SPEED)); }
async function animNova(u,h){
  const va=G.views.get(u.id); if(!va) return;
  await cineFrame(u,{...u,q:h.q,r:h.r,id:'__none'});
  const from=muzzles(va,'F')[0], to=hexWorld(h.q,h.r,HOVER_Y);
  flash(from,8,new C3(1,.9,.6)); SFX.boom(.6); G.shake=Math.min(1,G.shake+.3);
  const m=MB.CreateSphere('shell',{diameter:1.6,segments:10},G.scene); m.material=emMat('shellM',new C3(3,2.4,1.5)); m.isPickable=false;
  await tween(700,(e,k)=>{ const p=V3.Lerp(from,to,k); p.y+=Math.sin(k*Math.PI)*12; m.position.copyFrom(p); });
  m.dispose();
  flash(to,40,new C3(1,.85,.6),.9); flash(to,26,new C3(1,.5,.2),1.2); burst(to,{n:200,size:[.3,1.2],life:[.5,1.5],power:[10,40]}); shockwave(to,HW*2.2); SFX.boom(1.5); G.shake=1;
  await wait(350);
}

// ---------- procedural sound ----------
const SFX={ctx:null,master:null,noise:null,last:{},
  init(){ if(this.ctx) return; try{ const C=window.AudioContext||window.webkitAudioContext; this.ctx=new C(); }catch(e){ return; }
    const c=this.ctx; this.master=c.createGain(); this.master.gain.value=G.sfxOn?.55:0; const comp=c.createDynamicsCompressor(); comp.threshold.value=-18; comp.ratio.value=4; this.master.connect(comp); comp.connect(c.destination);
    const len=c.sampleRate*2, buf=c.createBuffer(1,len,c.sampleRate), d=buf.getChannelData(0); let b=0; for(let i=0;i<len;i++){ const w=Math.random()*2-1; b=(b+.02*w)/1.02; d[i]=w*.6+b*3; } this.noise=buf; this.ambient(); },
  setOn(on){ G.sfxOn=on; if(this.master) this.master.gain.setTargetAtTime(on?.55:0,this.ctx.currentTime,.05); },
  ok(key,gap){ if(!this.ctx||!G.sfxOn) return false; const now=this.ctx.currentTime; if(key&&this.last[key]&&now-this.last[key]<gap) return false; if(key) this.last[key]=now; return true; },
  env(node,t,a,peak,dec){ node.gain.setValueAtTime(0,t); node.gain.linearRampToValueAtTime(peak,t+a); node.gain.exponentialRampToValueAtTime(.0005,t+a+dec); },
  noiseHit({f0=800,f1=120,q=.8,peak=.5,dec=.4,type='lowpass',start=0}={}){ const c=this.ctx,t=c.currentTime+start; const s=c.createBufferSource(); s.buffer=this.noise; s.playbackRate.value=.8+Math.random()*.4; const f=c.createBiquadFilter(); f.type=type; f.Q.value=q; f.frequency.setValueAtTime(f0,t); f.frequency.exponentialRampToValueAtTime(Math.max(30,f1),t+dec); const g=c.createGain(); this.env(g,t,.005,peak,dec); s.connect(f); f.connect(g); g.connect(this.master); s.start(t,Math.random()); s.stop(t+dec+.1); },
  tone({type='sine',f0=60,f1=40,peak=.4,dec=.3,start=0}={}){ const c=this.ctx,t=c.currentTime+start; const o=c.createOscillator(); o.type=type; o.frequency.setValueAtTime(f0,t); o.frequency.exponentialRampToValueAtTime(Math.max(20,f1),t+dec); const g=c.createGain(); this.env(g,t,.004,peak,dec); o.connect(g); g.connect(this.master); o.start(t); o.stop(t+dec+.05); },
  gun(k,sq){ if(!this.ok('gun',.045)) return; if(sq){ this.noiseHit({f0:2500,f1:900,peak:.12,dec:.07,type:'bandpass',q:2}); return; } if(k==='flak'){ this.noiseHit({f0:3000,f1:1200,peak:.14,dec:.06,type:'highpass'}); return; }
    this.noiseHit({f0:1600,f1:140,peak:.32,dec:.28}); this.tone({f0:95+Math.random()*20,f1:38,peak:.35,dec:.25}); },
  lance(ion){ if(!this.ok('lance',.08)) return; this.tone({type:'sawtooth',f0:ion?520:220,f1:ion?140:70,peak:.16,dec:.5}); this.tone({type:'sine',f0:ion?1040:440,f1:ion?300:180,peak:.1,dec:.45}); this.noiseHit({f0:4000,f1:600,peak:.06,dec:.4,type:'bandpass',q:3}); },
  torp(){ if(!this.ok('torp',.1)) return; this.noiseHit({f0:300,f1:2200,peak:.18,dec:.5,type:'bandpass',q:1.5}); },
  hit(){ if(!this.ok('hit',.06)) return; this.noiseHit({f0:1200,f1:200,peak:.22,dec:.22}); },
  shield(){ if(!this.ok('shield',.07)) return; this.tone({type:'triangle',f0:900+Math.random()*200,f1:500,peak:.12,dec:.22}); this.noiseHit({f0:5000,f1:2000,peak:.05,dec:.15,type:'highpass'}); },
  boom(s=1){ if(!this.ok()) return; this.noiseHit({f0:900,f1:40,peak:.55*s,dec:1.2+s*.6}); this.tone({f0:70,f1:22,peak:.6*s,dec:1+s*.5}); },
  pop(){ if(!this.ok('pop',.05)) return; this.noiseHit({f0:2000,f1:300,peak:.2,dec:.2}); },
  launch(){ if(!this.ok('launch',.15)) return; this.noiseHit({f0:500,f1:3000,peak:.12,dec:.6,type:'bandpass',q:2}); },
  engine(size){ if(!this.ok('eng',.4)) return; this.noiseHit({f0:180,f1:90,peak:.12+size*.08,dec:.7,type:'lowpass',q:4}); },
  click(){ if(!this.ok('click',.03)) return; this.tone({type:'sine',f0:1400,f1:900,peak:.05,dec:.05}); },
  sting(win){ if(!this.ok()) return; const notes=win?[220,277,330,440]:[196,233,277,185]; notes.forEach((f,i)=>{ this.tone({type:'triangle',f0:f,f1:f*.995,peak:.12,dec:2.2,start:i*.12}); this.tone({type:'sine',f0:f/2,f1:f/2,peak:.1,dec:2.4,start:i*.12}); }); },
  ambient(){ const c=this.ctx; const g=c.createGain(); g.gain.value=.07; const f=c.createBiquadFilter(); f.type='lowpass'; f.frequency.value=320; f.Q.value=2; f.connect(g); g.connect(this.master);
    for(const fr of [55,55.4,82.5]){ const o=c.createOscillator(); o.type='sine'; o.frequency.value=fr; const og=c.createGain(); og.gain.value=fr>60?.25:.5; o.connect(og); og.connect(f); o.start(); }
    const s=c.createBufferSource(); s.buffer=this.noise; s.loop=true; const ng=c.createGain(); ng.gain.value=.15; s.connect(ng); ng.connect(f); s.start();
    const lfo=c.createOscillator(); lfo.frequency.value=.05; const lg=c.createGain(); lg.gain.value=140; lfo.connect(lg); lg.connect(f.frequency); lfo.start(); },
};

// ---------- close action ----------
async function fxRam(u,t){ const va=G.views.get(u.id), vt=G.views.get(t.id); if(!va||!vt) return;
  const a=va.root.getAbsolutePosition(), b=vt.root.getAbsolutePosition(), p=V3.Lerp(a,b,.55); p.y+=1;
  flash(p,18,new C3(1,.8,.55),.6); explode(p,6); sparks(p,140,26);
  burst(p,{n:40,tex:G.tex.smoke,c1:new C4(.5,.45,.4,.8),c2:new C4(.2,.18,.16,.6),size:[1.5,4],life:[1,2.2],power:[2,7],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true});
  shockwave(p,24); hullDecal(vt,a,true); SFX.boom(1.1); SFX.hit(); G.shake=1; const d=b.subtract(a); d.y=0; d.normalize(); vt.jolt={d:d.scale(3),t0:G.time}; va.jolt={d:d.scale(-1.2),t0:G.time}; await wait(450); }
async function fxBoard(u,t){ const va=G.views.get(u.id), vt=G.views.get(t.id); if(!va||!vt) return;
  const a=va.root.getAbsolutePosition(), b=vt.root.getAbsolutePosition(), P=FAC3D[va.fac]||FAC3D.hegemony, dir=b.subtract(a).normalize(), pods=[];
  for(let i=0;i<6;i++){ const m=MB.CreateCylinder('pod',{height:1.2,diameterTop:.2,diameterBottom:.5,tessellation:6},G.scene); m.bakeTransformIntoVertices(BABYLON.Matrix.RotationX(Math.PI/2)); m.material=emMat('podM',P.eng.scale(1.6)); m.isPickable=false; pods.push({m,off:new V3((Math.random()-.5)*6,Math.random()*3,(Math.random()-.5)*6),delay:i*.08}); }
  SFX.launch(); const t0=G.time;
  await new Promise(res=>{ const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/Math.max(.3,SPEED); let done=true;
    for(const p of pods){ const kk=clamp((k-p.delay)/.8,0,1); if(kk<1) done=false; const pos=V3.Lerp(a.add(p.off.scale(.3)),b.add(p.off.scale(.35)),kk); pos.y+=Math.sin(kk*Math.PI)*5; p.m.position.copyFrom(pos); p.m.lookAt(pos.add(dir));
      if(kk>=1&&!p.hit){ p.hit=true; flash(pos,2.5,new C3(1,.7,.4)); burst(pos,{n:12,power:[3,8]}); SFX.pop(); } }
    if(done||k>2.5){ G.scene.onBeforeRenderObservable.remove(obs); pods.forEach(p=>{ p.m.material.dispose(); p.m.dispose(); }); res(); } }); });
  await wait(250); }
function onCapture(t){ const v=G.views.get(t.id); if(v){ disposeView(v); G.views.delete(t.id); } }

// ---------- objective markers ----------
function buildBeacon(h){ const c=hexWorld(h.q,h.r,0), sc=G.scene, parts=[];
  const base=MB.CreateCylinder('bcnBase',{height:1.2,diameterTop:5,diameterBottom:7,tessellation:6},sc); base.position=c.add(new V3(0,.6,0)); base.material=facMats('hegemony').dark; parts.push(base);
  const mast=MB.CreateCylinder('bcnMast',{height:16,diameterTop:.4,diameterBottom:1.4,tessellation:6},sc); mast.position=c.add(new V3(0,8,0)); mast.material=facMats('hegemony').steel; parts.push(mast);
  const coreM=emMat('bcnCoreM',new C3(1.4,1.2,.8)); const core=MB.CreateSphere('bcnCore',{diameter:2.2,segments:12},sc); core.position=c.add(new V3(0,16.5,0)); core.material=coreM; parts.push(core,coreM);
  const rings=[0,1].map(i=>{ const r=MB.CreateTorus('bcnRing',{diameter:5+i*3,thickness:.18,tessellation:40},sc); r.position=c.add(new V3(0,12+i*2.5,0)); const m=emMat('bcnRingM',new C3(1,.85,.5)); r.material=m; parts.push(r,m); return {r,m}; });
  const zm=emMat('bcnZoneM',new C3(1,.85,.5),.5); zm.alphaMode=BABYLON.Engine.ALPHA_ADD; zm.disableDepthWrite=true; zm.backFaceCulling=false;
  const zone=MB.CreateTorus('bcnZone',{diameter:HW*3.1,thickness:.45,tessellation:6},sc); zone.rotation.y=Math.PI/6; zone.position=c.add(new V3(0,.2,0)); zone.material=zm; G.glow.addExcludedMesh(zone); parts.push(zone,zm);
  const pips=[0,1,2].map(i=>{ const m=emMat('bcnPipM',new C3(.3,.3,.3)); const s=MB.CreateSphere('bcnPip',{diameter:.9,segments:8},sc); s.position=c.add(new V3(Math.cos(i*2.09)*2.4,14.5,Math.sin(i*2.09)*2.4)); s.material=m; parts.push(s,m); return m; });
  for(const p of parts) if(p.isPickable!==undefined) p.isPickable=false;
  G.env.push(...parts); G.beacon={rings,coreM,zm,pips};
}
function updateBeacon(){ const bc=G.beacon; if(!bc||!B||!B.obj||B.obj.type!=='hold'||bc.rings[0].r.isDisposed()) return; const o=B.obj, t=G.time;
  const near=s=>alive(s).some(u=>!u.isSq&&hdist(u,o.hex)<=1), p=near('player'), e=near('enemy');
  const col=p&&!e?FRIEND_C:e&&!p?FOE_C:p&&e?new C3(1,.7,.25):new C3(1,.85,.5);
  bc.rings.forEach((x,i)=>{ x.r.rotation.y=t*(i?-.8:.6); x.r.rotation.x=.3*Math.sin(t*.7+i); x.m.emissiveColor=col.scale(1.3); });
  bc.coreM.emissiveColor=col.scale(1.2+.4*Math.sin(t*3)); bc.zm.emissiveColor=col; bc.zm.alpha=.4+.2*Math.sin(t*2);
  bc.pips.forEach((m,i)=>{ m.emissiveColor=o.score>i?FRIEND_C.scale(1.6):o.escore>i?FOE_C.scale(1.6):new C3(.25,.25,.25); });
}

// escorts that break off: burn engines and leave the battle
function fxWithdraw(u){ const v=G.views.get(u.id); if(!v||v.state!=='alive') return; v.state='fled'; v.plate.el.remove(); v.ring.node.dispose(false,true); (v.extras||[]).forEach(p=>p.stop()); v.fires.forEach(p=>p.stop());
  const a=v.root.rotation.y, dir=new V3(Math.cos(a),.15,-Math.sin(a)), t0=G.time, p0=v.root.position.clone(); fxText(u,'Withdraws','#c9c2b0',-20);
  let fl=false; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/1.6; if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); disposeView(v); G.views.delete(u.id); return; }
    const j=Math.max(0,(k-.45)/.55); v.root.position=p0.add(dir.scale(k*k*14+j*j*j*420)); const st=1+j*9; v.root.scaling.set(st,1/Math.sqrt(st),1/Math.sqrt(st)); if(v.model) v.model.plumes.forEach(pl=>pl.scaling.x=2.4+k*2);
    if(!fl&&k>.46){ fl=true; try{ flash(v.root.getAbsolutePosition(),8+v.L*.3,(FAC3D[v.fac]||FAC3D.hegemony).eng.scale(1.5),.35); }catch(e){} } }); }

// a knocked-out section becomes a burning breach
function fxSectionDown(t,sec){ const v=G.views.get(t.id); if(!v||!v.model||v.state!=='alive') return; const x=sec==='prow'?.3:sec==='eng'?-.36:0;
  const c=toWorld(v,new V3(x*v.L,v.H*.3,0)); for(let i=0;i<3;i++) hullDecal(v,c.add(new V3((Math.random()-.5)*20,10,(Math.random()<.5?-1:1)*30)),true);
  explode(c,2+v.L*.07,{light:true}); if(v.fires.length<3) addFire(v); SFX.boom(.6); G.shake=Math.min(1,G.shake+.25); }

// terrain tints: each terrain hex gets an outline and a faint fill in its legend colour (one mesh per type)
function tintHexes(name,hs,col,blk,fill){
  const lines=hs.map(([q,r])=>{ const c=hexWorld(q,r,.25), pts=[]; for(let i=0;i<=6;i++){ const a=Math.PI/6+i*Math.PI/3; pts.push(new V3(c.x+Math.cos(a)*HS*.94,c.y,c.z+Math.sin(a)*HS*.94)); } return pts; });
  const ls=MB.CreateLineSystem('tint_'+name,{lines},G.scene); ls.color=col.scale(blk?.7:1.1); ls.alpha=blk?.22:.45; ls.isPickable=false; G.env.push(ls);
  if(!blk){ const discs=hs.map(([q,r])=>{ const d=MB.CreateDisc('tf',{radius:HS*.92,tessellation:6},G.scene); d.rotation.x=Math.PI/2; d.rotation.y=Math.PI/6; d.position=hexWorld(q,r,.2); d.bakeCurrentTransformIntoVertices(); return d; });
    const m=BABYLON.Mesh.MergeMeshes(discs,true,true); if(m){ m.name='tintF_'+name; const mat=emMat('tintM_'+name,col,fill||.13); mat.alphaMode=BABYLON.Engine.ALPHA_ADD; mat.disableDepthWrite=true; mat.backFaceCulling=false; m.material=mat; m.isPickable=false; G.glow.addExcludedMesh(m); G.env.push(m,mat); } } }
// asteroids and wrecks block movement and fire but are hard to read on a phone: give every such hex a red no-go marker,
// rebuilt whenever a destroyed ship leaves a new wreck
function refreshBlockTint(){ try{ (G.blockTint||[]).forEach(m=>{ try{ m.dispose(); }catch(e){} }); G.blockTint=[]; if(!B||!B.terrain||!G.scene) return;
  const hs=[]; for(const [k,t] of Object.entries(B.terrain)) if(t==='rock'||t==='hulk') hs.push(k.split(',').map(Number)); if(!hs.length) return;
  const n0=G.env.length; tintHexes('blocked',hs,new C3(1,.32,.26),false,.11); const made=G.env.splice(n0); for(const m of made){ if(m instanceof BABYLON.LinesMesh){ m.alpha=.85; m.color=new C3(1,.42,.34); } } G.blockTint=made; }catch(e){ console.warn(e); } }
function buildTerrainTints(){ if(!B||!B.terrain) return; const byType={}; for(const [k,t] of Object.entries(B.terrain)){ if(!TERRAIN_INFO[t]) continue; (byType[t]=byType[t]||[]).push(k.split(',').map(Number)); }
  for(const [t,hs] of Object.entries(byType)){ if(t==='rock'||t==='hulk') continue; tintHexes(t,hs,C3.FromHexString(TERRAIN_INFO[t].col),!!BLOCKING[t],.045); }
  G.blockTint=null; refreshBlockTint();
  // objective zones: breakthrough exit, transport exit, station perimeter
  const zones={}; for(const h of boardHexes()){ const z=objZone(h.q,h.r); if(z&&!blocks(terr(h.q,h.r))) (zones[z]=zones[z]||[]).push([h.q,h.r]); }
  for(const [z,hs] of Object.entries(zones)) tintHexes('zone_'+z,hs,C3.FromHexString(ZONE_INFO[z].col),false,.2); }
