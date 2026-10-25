// ======================= VIEWS, ANIMATION, EFFECTS, SOUND =======================
// one visual language: cyan bars are shields, amber is hull; green marks your ships and violet marks the enemy (B1: violet is the colour furthest from all six faction shield colours and the gold selection ring, in normal and colour-blind vision; enemy marks also differ by shape)
function shCol(v){ const f=v&&(v.fac||(v.u&&v.u.fac)); return ((FAC3D[f]||{}).shield)||SHIELD_C; } // v45: shields wear their faction's colour
const SHIELD_C=new C3(.38,.82,1), SHIELD_HEX='#62ccff', HULL_HEX='#ffae42', HULL_LOW_HEX='#ff5a3c', FRIEND_C=new C3(.42,1,.55), FOE_C=new C3(.62,.22,1);
const HOVER_Y=3.4;
function unitVis(u){ return u.vis || {q:u.q, r:u.r, a:u.facing*60}; }
function tween(dur,fn){ return new Promise(res=>{ const t0=performance.now(), D=Math.max(1,dur*SPEED); G.tweens=(G.tweens||0)+1; /* v53: phones draw every frame while any tween runs */ const step=now=>{ const p=Math.min(1,(now-t0)/D); if(p>=1) G.tweens=Math.max(0,G.tweens-1); fn(p<.5?2*p*p:1-Math.pow(-2*p+2,2)/2,p); if(p<1) requestAnimationFrame(step); else res(); }; requestAnimationFrame(step); }); }
function shortAng(a0,a1){ let d=((a1-a0)%360+540)%360-180; return a0+d; }
function uWorld(u){ const v=G.views.get(u.id); if(v&&v.root&&!v.arrive) return v.root.getAbsolutePosition().clone(); const vis=unitVis(u); return hexWorld(vis.q,vis.r,HOVER_Y); }
// A1 step 4: Corsair engines cough: the plume drops to a stub for a moment and spits a puff of soot. Per ship, so a fleet never coughs in step; the barge (c_boss) coughs most.
function corsairCough(v,u,dt){ const cg=v.cough||(v.cough={until:0,k:1}); if(G.time<cg.until) return cg.k;
  if(Math.random()<(u.tpl==='c_boss'?.7:.3)*dt){ cg.until=G.time+.07+Math.random()*.16; cg.k=.18+Math.random()*.3; try{ const pl=v.model.plumes[Math.floor(Math.random()*v.model.plumes.length)]; if(pl&&!pl.isDisposed()&&typeof fxp==='function'){ const bb=pl.getBoundingInfo().boundingBox, p=bb.centerWorld.add(new V3((Math.random()-.5)*bb.extendSizeWorld.x,(Math.random()-.5)*bb.extendSizeWorld.y,(Math.random()-.5)*bb.extendSizeWorld.z));
      for(let i=0;i<(G.quality==='medium'?1:2);i++) fxp(p,{smoke:true,size:.8+Math.random()*.9,col:new C3(.14,.12,.11),alpha:.6,dur:.9+Math.random()*.8,grow:2.2,vel:new V3((Math.random()-.5)*1.2,.3+Math.random()*.8,(Math.random()-.5)*1.2),drag:.6,spin:(Math.random()-.5)*2,fade:1.2}); } }catch(e){} return cg.k; }
  return 1; }
function toWorld(v,local){ v.root.computeWorldMatrix(true); return V3.TransformCoordinates(local,v.root.getWorldMatrix()); }

// ---------- views ----------
// v53: one draw per ring. The four shield arcs, the IFF circle and the prow chevron are merged once per ring size into a shared template
// (uv.x carries the part), and each ship's ring is a clone with a small shader whose uniforms hold every part's colour, alpha and pulse scale.
// segs[] keeps its old shape (s.mat.alpha, s.m.scaling, s.pulse) so the per-frame update and the shield hit effects are unchanged.
// Was six meshes and six materials per ship: six draws, six sorts, six material binds.
const RING_GEO={};
const RING_GLSL={vert:`precision highp float; attribute vec3 position; attribute vec2 uv; uniform mat4 worldViewProjection; uniform float sc[6]; varying float vP;
void main(){ float s=1.0; for(int i=0;i<6;i++){ if(abs(uv.x-float(i))<0.5) s=sc[i]; } vP=uv.x; gl_Position=worldViewProjection*vec4(position*s,1.0); }`,
  frag:`precision highp float; uniform vec3 col[6]; uniform float al[6]; uniform float fd; varying float vP;
void main(){ vec3 c=vec3(0.0); float a=0.0; for(int i=0;i<6;i++){ if(abs(vP-float(i))<0.5){ c=col[i]; a=al[i]; } } gl_FragColor=vec4(c,a*fd); }`}; // fd: v53.7 close-up fade (ovFadeTick)
function ringTemplate(kind,R){ const key=kind+'|'+R; let t=RING_GEO[key]; if(t&&!t.isDisposed()) return t; const parts=[], spans=[[-50,50],[50,130],[130,230],[230,310]];
  const add=(m,part,twoSided)=>{ m.computeWorldMatrix(true); const vd=BABYLON.VertexData.ExtractFromMesh(m,true,true); vd.transform(m.getWorldMatrix()); const n=vd.positions.length/3, uv=new Float32Array(n*2); for(let i=0;i<n;i++) uv[i*2]=part; vd.uvs=uv; vd.normals=null; vd.colors=null;
    if(twoSided){ const I=Array.from(vd.indices), J=I.slice(); for(let i=0;i<I.length;i+=3) J.push(I[i],I[i+2],I[i+1]); vd.indices=J; } parts.push(vd); m.dispose(false,false); };
  if(kind==='S') for(let q=0;q<4;q++){ const pts=[]; for(let a=spans[q][0]+4;a<=spans[q][1]-4;a+=4){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*R,0,-Math.sin(r)*R)); } add(MB.CreateTube('seg',{path:pts,radius:.09,tessellation:5,cap:BABYLON.Mesh.CAP_ALL},G.scene),q); }
  if(kind==='B'){ const pts=[]; for(let a=0;a<=360;a+=6){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*R,0,Math.sin(r)*R)); } add(MB.CreateTube('seg',{path:pts,radius:.08,tessellation:4},G.scene),0); }
  { const pts=[]; for(let a=0;a<=360;a+=8){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*R*.8,0,Math.sin(r)*R*.8)); } add(MB.CreateTube('iff',{path:pts,radius:.07,tessellation:4},G.scene),4); }
  if(kind!=='Q'){ const d=MB.CreateDisc('prowMark',{radius:Math.max(1.1,R*.17),tessellation:3},G.scene); d.rotation.x=Math.PI/2; d.scaling.y=.75; d.position.set(R*1.08,.05,0); add(d,5,true); } // v52 prow chevron, both faces (it was unculled)
  const vd=parts[0]; if(parts.length>1) vd.merge(parts.slice(1),true); t=new BABYLON.Mesh('ringT_'+key,G.scene); vd.applyToMesh(t); t.setEnabled(false); t.isPickable=false; t.refreshBoundingInfo(); RING_GEO[key]=t; return t; }
function makeShieldRing(u,v){
  const node=new BABYLON.TransformNode('ring',G.scene); const R=Math.max(5.2,v.L*.56);
  const col=((FAC3D[u.fac]||{}).shield)||SHIELD_C, iff=u.side==='player'?FRIEND_C:FOE_C, segs=[], kind=u.isSq?'Q':u.shMax>0?'S':'B';
  const S=BABYLON.Effect.ShadersStore; if(!S.vsRingVertexShader){ S.vsRingVertexShader=RING_GLSL.vert; S.vsRingFragmentShader=RING_GLSL.frag; }
  const al=[0,0,0,0,.55,.85], sc=[1,1,1,1,1,1], cols=[]; for(let i=0;i<6;i++){ const c=i<4?(kind==='B'?new C3(.5,.3,.3):col):i===4?iff:iff.scale(1.5); cols.push(c.r,c.g,c.b); } if(kind==='B') al[0]=.35;
  const mat=new BABYLON.ShaderMaterial('ringM',G.scene,{vertex:'vsRing',fragment:'vsRing'},{attributes:['position','uv'],uniforms:['worldViewProjection','sc','col','al','fd'],needAlphaBlending:true});
  mat.alphaMode=BABYLON.Engine.ALPHA_ADD; mat.backFaceCulling=true; mat.setFloats('sc',sc); mat.setFloats('al',al); mat.setArray3('col',cols); mat.setFloat('fd',G.ovFade??1);
  const m=ringTemplate(kind,R).clone('ring',null); m.setEnabled(true); m.isPickable=false; m.material=mat; m.parent=node; G.glow.addExcludedMesh(m);
  if(kind==='S') for(let q=0;q<4;q++) segs.push({pulse:0,mat:{get alpha(){ return al[q]; },set alpha(x){ al[q]=x; }},m:{scaling:{get x(){ return sc[q]; },setAll(x){ sc[q]=x; }}}});
  return {node,segs,R,mesh:m};
}
function makePlate(u){ const el=document.createElement('div'); el.className='plate '+(u.side==='player'?'friend':'foe'); el.innerHTML=`<div class="nm"></div>${u.shMax&&!u.isSq?'<div class="sp" title="Shields: port, prow, starboard, rear"><b></b><b></b><b></b><b></b></div>':''}<div class="hb" title="Hull"><i></i></div>`;
  el.querySelector('.nm').textContent=u.isSq?u.t.n:u.name; document.getElementById('plates').appendChild(el); return {el,hb:el.querySelector('.hb i'),sp:[...el.querySelectorAll('.sp b')],key:''}; }
// v53 status display. Every ship's status stays inside its own hex: shields on the ring around the hull (makeShieldRing), and a damaged ship gets a
// hull gauge drawn on its own hex footprint (one mesh for the whole board, rebuilt only when hull values, positions or the camera quarter change).
// The DOM label (name and full bars) shows only for the ship in hand (selected, hovered, inspected), so a hovered target shows its own, and it sits
// above that ship's hull; valid targets are already marked by their brighter footprints. Hidden labels cost nothing per frame; a shown one writes one transform, and only when it moves a pixel.
function plateLevel(u){ if(typeof fpLevel==='function') return fpLevel(u); const h=B.hover; return u===B.sel||u===B.inspect||(h&&h.q===u.q&&h.r===u.r)?2:0; }
function hullArcs(){ const A=G._ha||(G._ha={hash:0,mesh:null}); if(!B||B.showcase||!G.scene){ if(A.mesh&&!A.mesh.isDisposed()) A.mesh.dispose(false,false); A.mesh=null; A.hash=0; return; } const hide=!!G.cineHidePlates, qa=Math.round(((G.cam&&G.cam.alpha)||0)/(Math.PI/6));
  let h=hide?7:qa*131+3, n=0; const list=[];
  for(const u of B.units){ if(u.dead||u.isSq) continue; const v=G.views.get(u.id); if(!v||v.state!=='alive'||v.arrive||v.phased||u.vis) continue; const hr=clamp(u.hp/u.maxHp,0,1); if(hr>.995||hide) continue;
    const k=Math.round(hr*60); list.push([u,k/60]); h=(Math.imul(h,31)+(u.q+64)*977+(u.r+64)*29+k*7+(u.side==='player'?1:2))|0; n++; }
  if(h===A.hash&&A.mesh&&!A.mesh.isDisposed()) return; A.hash=h; if(A.mesh&&!A.mesh.isDisposed()) A.mesh.dispose(false,false); A.mesh=null; if(!n) return;
  const pos=[], col=[], ind=[], c0=-Math.PI/2-qa*Math.PI/6, span=Math.PI*4/3, NS=28, r0=HS*.7, r1=HS*.79, tr=[.03,.05,.08,.62]; // centred on the side nearest the camera
  const band=(cx,cz,a0,a1,c)=>{ const b=pos.length/3, ns=Math.max(2,Math.round(NS*(a1-a0)/span)); for(let i=0;i<=ns;i++){ const a=a0+(a1-a0)*i/ns, ca=Math.cos(a), sa=Math.sin(a); pos.push(cx+ca*r0,.16,cz+sa*r0,cx+ca*r1,.16,cz+sa*r1); col.push(...c,...c); if(i) ind.push(b+2*i-2,b+2*i-1,b+2*i+1,b+2*i-2,b+2*i+1,b+2*i); } };
  for(const [u,hr] of list){ const p=hexWorld(u.q,u.r), lo=hr<=.3, c=lo?[1,.36,.24,.95]:[1,.68,.26,.92], a0=c0-span/2, am=a0+span*hr; band(p.x,p.z,am,a0+span,tr); if(hr>.01) band(p.x,p.z,a0,am,c); }
  const m=new BABYLON.Mesh('hullArcs',G.scene), vd=new BABYLON.VertexData(); vd.positions=pos; vd.colors=col; vd.indices=ind; vd.applyToMesh(m); m.hasVertexAlpha=true; m.isPickable=false;
  const mt=G._haMat&&G.scene.materials.includes(G._haMat)?G._haMat:(G._haMat=emMat('hullArcM',new C3(1,1,1),1)); mt.disableLighting=true; mt.backFaceCulling=false; mt.disableDepthWrite=true; m.material=mt; m.alphaIndex=40; try{ G.glow.addExcludedMesh(m); }catch(e){} A.mesh=m; }
function createView(u){
  const fac=u.fac||'voidsworn';
  const v={u,fac,bob:Math.random()*6.28,bank:0,lastA:null,fires:[],state:'alive'};
  if(u.isSq){ v.root=new BABYLON.TransformNode('sq',G.scene); v.crafts=[]; v.L=5; v.H=2;
    const fm=typeof craftFormation==='function'?craftFormation(fac,u.sqKind):{s:1.35,pts:[[0,0,0],[-1.6,0,1.7],[-1.6,0,-1.7]]}; v.wing=new BABYLON.TransformNode('wing',G.scene); v.wing.parent=v.root; v.wingPh=Math.random()*6.28; // v53-G: the wing flies as one formation
    fm.pts.forEach(([x,y,z],i)=>{ const c=craftInstance(fac,u.sqKind)||buildCraft(fac,u.sqKind); c.root.parent=v.wing; c.root.scaling.setAll(fm.s); c.root.position.set(x,y,z); c.meshes.forEach(m=>m.metadata={unit:u.id}); v.crafts.push({c,ph:i*1.7,y}); });
    if(typeof craftTrails==='function') craftTrails(v,fac);
    const pv=u.parent&&G.views.get(u.parent);
    if(pv&&pv.model&&!u.launched){ u.launched=true; const bay=pv.model.bays.length?pv.model.bays[Math.floor(Math.random()*pv.model.bays.length)]:new V3(0,0,0); v.launch={from:toWorld(pv,bay),t0:G.time}; SFX.launch(v.launch.from); }
  } else { const mdl=buildShipModel(u); v.model=mdl; v.root=mdl.root; v.L=mdl.L; v.H=mdl.H; mdl.meshes.forEach(m=>m.metadata={unit:u.id}); }
  v.ring=makeShieldRing(u,v); v.plate=makePlate(u);
  if(v.model&&G.quality!=='medium'&&u.size>=.6&&!(B&&B._warm)){ /* v45: engine lights only for the opening fleets; a light added mid-battle recompiles every hull material */ const el=new BABYLON.PointLight('engLight',new V3(-v.L*.56,0,0),G.scene); el.parent=v.root; el.diffuse=(FAC3D[fac]||FAC3D.hegemony).eng; el.specular=el.diffuse; el.intensity=1.6; el.range=v.L*.8; el.includedOnlyMeshes=v.model.meshes.slice(); v.engLight=el; }
  if((u.flagship||u.transport||u.pflag)&&!u.isSq){ const cr=MB.CreateTorus('flagRing',{diameter:Math.max(3,v.L*.25),thickness:.2,tessellation:32},G.scene); cr.parent=v.root; cr.position.y=v.H+2.2; cr.material=emMat('flagM',new C3(1.5,1.15,.45)); cr.isPickable=false; v.flagRing=cr; }
  // hyperspace arrival: the fleet drops in when the battle opens, reinforcements when they jump in
  if(B&&(u.reinf&&!u.arrived||G.jumpUntil&&G.time<G.jumpUntil)){ u.arrived=true; v.arrive={t0:G.time+(u.reinf?0:(u.side==='player'?.05:.4)+Math.random()*.55+(u.isSq?.55:0))}; }
  G.views.set(u.id,v); return v;
}
function disposeView(v){ if(v.navSp){ try{ v.navSp.forEach(sp=>sp.dispose()); }catch(e){} v.navSp=null; } if(v.dmgMats&&typeof disposeDamageMats==='function') disposeDamageMats(v); if(v.arrive&&v.arrive.streak){ const e=v.arrive.streak; if(e.gen===v.arrive.sg){ e.hold=false; e.dur=.05; e.t0=G.time; } } (v.extras||[]).forEach(p=>p.dispose()); (v.stackFx||[]).forEach(ps=>ps.dispose()); if(v.flagRing&&v.flagRing.material){ try{ v.flagRing.material.dispose(); }catch(e){} } if(v.root) v.root.dispose(false,false); if(v.ring) v.ring.node.dispose(false,true); if(v.plate) v.plate.el.remove(); for(const f of v.fires) f.dispose(); v.fires=[]; }
function disposeAllViews(){ try{ if(typeof aiTexReleaseAll==='function') aiTexReleaseAll(); }catch(e){} try{ const ids=new Set(G.scene.meshes.map(m=>m.uniqueId)); if(G.glow&&G.glow._excludedMeshes) G.glow._excludedMeshes=G.glow._excludedMeshes.filter(id=>ids.has(id)); if(G.glow&&G.glow._includedOnlyMeshes&&G.glow._includedOnlyMeshes.length) G.glow._includedOnlyMeshes=G.glow._includedOnlyMeshes.filter(id=>ids.has(id)); }catch(e){} /* v49: the glow layer kept every excluded mesh id ever added */ if(G.trails){ for(const tr of [...G.trails]) try{ if(tr.release&&!tr.temp) tr.release(); else { tr.tm.dispose(); tr.n.dispose(); tr.m.dispose(); } }catch(e){} G.trails.clear(); } /* v46.1: wakes from moves cut short by the battle ending */ (G.deadLights||[]).forEach(l=>{ try{ l.dispose(); }catch(e){} }); G.deadLights=[]; debrisClear(); for(const v of G.views.values()){ disposeView(v); } G.views.clear(); for(const h of G.hulks||[]) h.nodes.forEach(n=>{ if(n.ps) n.ps.dispose(); n.dispose(); }); G.hulks=[]; for(const p of PROJ){ p.m.dispose(); if(!p.arrived&&p.settle) p.settle(); } PROJ.length=0; if(typeof wbClear==='function') wbClear(); if(typeof EMIT!=='undefined') EMIT.clear(); G.trauma=0; G.hitStop=null; try{ for(const p of Object.values(G.torpProto||{})) for(const r of p.rigs) if(r.busy) r.release(); }catch(e){} for(const r of TORPS){ G.scene.onBeforeRenderObservable.remove(r.obs); r.tr.dispose(); r.m.dispose(); r.res(); } TORPS.clear(); document.getElementById('plates').innerHTML=''; trimModelCache(); }

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
function arcBolt(a,b,col){ if(G.fxReduced&&Math.random()<.6) return; arcLine(a,b,col.scale(G.fxReduced?.6:1.2),{n:7,jag:1,thick:.2,dur:.13}); if(!G.fxReduced) flash(b,2.5,col,.2); } // v53-I: pooled sprite segments

// ---------- per-frame world update ----------
// v49: push a ship's visible hull (hits rock it, broadsides kick it); mag in world units per second
function physKick(u,dir,mag,roll){ const v=u&&G.views.get(u.id); if(!v||!v.ph||u.isSq) return; const m=u.size>.8?2.2:u.size>.6?1.4:1; const l=Math.hypot(dir.x,dir.z)||1; v.ph.vx+=dir.x/l*mag/m; v.ph.vz+=dir.z/l*mag/m; if(roll) v.ph.vr+=roll/m; }
// v51 coast: after a burn the hull keeps the velocity it ended with and runs on along that vector, easing to a stop a little way
// past its hex (critically damped, so it never drifts back). Ships that have not moved hold station with a slow surge and sway.
function coastStart(v,u,dx,dz,sp,FE){ const w=u.size>.8?.38:u.size>.6?.48:.6, cap=HW*((FE&&FE.coastCap!=null)?FE.coastCap:.05)*(u.size>.8?1.15:1);
  const T=Math.min(cap,sp/w); v.coast={dx,dz,c:0,vc:Math.min(sp,w*T),w,T}; } // v53: the hull stays on its hex (within ~0.1 hex): drift capped and the start speed trimmed so the spring can't overshoot the cap
function coastTick(v,u,a,dt,t){ const C=v.coast; let ox=0,oz=0;
  if(C&&(C.c||C.vc)){ const ac=C.w*C.w*(C.T-C.c)-2*C.w*C.vc; C.vc+=ac*dt; C.c+=C.vc*dt; if(C.vc<0) C.vc=0; ox=C.dx*C.c; oz=C.dz*C.c; }
  if(!u.vis){ const ph=(v.bob||0)*3.1, per=u.size>.8?11:u.size>.6?9:7, k=2*Math.PI/per, f=Math.cos(a), g=-Math.sin(a), sv=HW*.035*Math.sin(t*k+ph), sw=HW*.02*Math.sin(t*k*.5+ph*1.7);
    ox+=f*sv-g*sw; oz+=g*sv+f*sw; }
  return {x:ox,z:oz}; }
function updateWorld(dt){
  try{ gfxTick(); }catch(e){} try{ if(typeof vfxTick==='function') vfxTick(); }catch(e){}
  if(!B) return;
  const t=G.time, hsl=G.engine.getHardwareScalingLevel(), cw=Math.round(G.engine.getRenderWidth()*hsl), ch=Math.round(G.engine.getRenderHeight()*hsl); // v53: from the engine, not clientWidth (a layout read every frame after the plate transforms were written)
  const tm=G.scene.getTransformMatrix(), vp=G.cam.viewport.toGlobal(cw,ch);
  if(MATS.chorus){ const k=Math.sin(G.time*2.2); MATS.chorus.P.win.scaleToRef(.8+.35*k,MATS.chorus.win.emissiveColor); MATS.chorus.P.win.scaleToRef(.32+.22*k,MATS.chorus.flesh.emissiveColor); } // v53: written in place; assigning a new colour went through the material setter and marked every submesh in the scene dirty each frame
  if(MATS.deathless) MATS.deathless.P.win.scaleToRef(.72+.35*Math.sin(G.time*1.3),MATS.deathless.win.emissiveColor);
  if(MATS.ithar) MATS.ithar.sail.alpha=.26+.07*Math.sin(G.time*1.7);
  if(!B._warm&&G.views.size&&typeof warmFx==='function'){ B._warm=1; const b0=B; setTimeout(()=>{ if(B===b0&&!B.over) warmFx(); },50); } /* v45: never warms into a different battle */ // v44.1: build the explosion shaders while the fleets arrive
  try{ hullArcs(); }catch(e){ console.warn('hull arcs',e); }
  for(const u of B.units){
    let v=G.views.get(u.id);
    if(!v){ if(u.dead) continue; v=createView(u); }
    if(v.state!=='alive') continue;
    const vis=unitVis(u), p=hexWorld(vis.q,vis.r), a=vis.a*Math.PI/180;
    if(v.lastA==null) v.lastA=a;
    const da=a-v.lastA; v.lastA=a; const bk=(u.isSq?.2:u.size>.8?.07:u.size>.6?.1:.14)*((!u.isSq&&typeof MOVE_FEEL!=='undefined'&&MOVE_FEEL[u.fac]&&MOVE_FEEL[u.fac].bank)||1), bankT=clamp(-da/Math.max(dt,.001)*bk,-.38,.38); v.bank+=(bankT-v.bank)*Math.min(1,dt*3.2);
    let y=HOVER_Y+Math.sin(t*.8+v.bob)*.22+((u.vis&&u.vis.lift)||0);
    let px=p.x, pz=p.z, stretch=1;
    if(v.arrive){ const k=(G.time-v.arrive.t0)/(.95*Math.max(.4,SPEED)); if(k<0){ v.root.setEnabled(false); v.ring.node.setEnabled(false); v.plate.el.style.visibility='hidden'; continue; }
      v.root.setEnabled(true); const e=1-Math.pow(1-Math.min(1,k),4), f=fwdOf(vis.a), back=(1-e)*150; px-=f.x*back; pz-=f.z*back; stretch=1+(1-e)*6;
      if(!u.isSq&&k<.75){ const P=FAC3D[v.fac]||FAC3D.hegemony, len=Math.max(4,back+v.L*.5); let e=v.arrive.streak; if(!e||e.gen!==v.arrive.sg){ e=v.arrive.streak=fxp(new V3(px,y,pz),{cell:4,size:1,col:P.eng.scale(1.6),dur:5,grow:0,fade:.01}); if(e){ e.hold=true; v.arrive.sg=e.gen; } } /* v53-I: a pooled sprite, not a box and material per arrival */
        if(e){ e.alpha=.85*(1-k/.75); alignSprite(e,new V3(px-f.x*len,y,pz-f.z*len),new V3(px,y,pz),1.2+v.L*.06); } }
      else if(v.arrive.streak){ const e=v.arrive.streak; if(e.gen===v.arrive.sg){ e.hold=false; e.dur=.05; e.t0=G.time; } v.arrive.streak=null; }
      if(!v.arrive.rift&&!u.isSq&&typeof warpRift==='function'){ v.arrive.rift=true; fxMark('arrive'); warpRift(new V3(p.x,y,p.z).subtract(f.scale(v.L*.35)),f,Math.max(14,v.L*1.3),(FAC3D[v.fac]||FAC3D.hegemony).eng.scale(1.2)); }
      if(!v.arrive.flashed&&k>.55){ v.arrive.flashed=true; try{ flash(new V3(px,y,pz),u.isSq?5:6+v.L*.25,(FAC3D[v.fac]||FAC3D.hegemony).eng.scale(1.4),.3); }catch(e){} }
      if(k>=1){ const e=v.arrive.streak; if(e&&e.gen===v.arrive.sg){ e.hold=false; e.dur=.05; e.t0=G.time; } v.arrive=null; v.ring.node.setEnabled(true); v.plate.el.style.visibility=''; } }
    if(v.launch){ const k=clamp((G.time-v.launch.t0)/(.9*SPEED),0,1), e=1-Math.pow(1-k,3); px=v.launch.from.x+(p.x-v.launch.from.x)*e; pz=v.launch.from.z+(p.z-v.launch.from.z)*e; y=v.launch.from.y+(y-v.launch.from.y)*e; if(k>=1) v.launch=null; }
    if(v.slide){ const k=(G.time-v.slide.t0)/(.9*Math.max(.4,SPEED)); if(k>=1) v.slide=null; else { const e=1-Math.pow(1-k,3); px=v.slide.x+(px-v.slide.x)*e; pz=v.slide.z+(pz-v.slide.z)*e; } }
    if(!u.isSq){ if(v.arrive||v.launch||v.slide){ if(v.coast) v.coast.c=v.coast.vc=0; } else { const o=coastTick(v,u,a,dt,t); px+=o.x; pz+=o.z; } }
    // v49 weight: the visible hull follows its path through a mass-spring, so capitals lag, overshoot and settle, hits and recoil push it around,
    // and pitch and bank come from real acceleration (the rules still use the exact hex)
    let physPitch=0, physRoll=0, physYaw=0;
    if(!u.isSq){ const P=v.ph||(v.ph={x:px,z:pz,vx:0,vz:0,a:a,va:0,r:0,vr:0,ax:0,az:0});
      const snap=!!(v.arrive||v.launch||v.slide||v.phased||(!v.root.isEnabled())||Math.hypot(px-P.x,pz-P.z)>HW*4);
      if(snap){ P.x=px; P.z=pz; P.vx=0; P.vz=0; P.a=a; P.va=0; }
      else { const w=u.size>.8?3.1:u.size>.6?4.2:5.6, zt=1, /* v51: critically damped, the hull lags but never swings back */ h=Math.min(dt,1/20), n=Math.max(1,Math.ceil(dt/h)), hs=dt/n; let ax=0,az=0;
        for(let i=0;i<n;i++){ ax=w*w*(px-P.x)-2*zt*w*P.vx; az=w*w*(pz-P.z)-2*zt*w*P.vz; P.vx+=ax*hs; P.vz+=az*hs; P.x+=P.vx*hs; P.z+=P.vz*hs;
          let da=((a-P.a+Math.PI*3)%(Math.PI*2))-Math.PI; const ww=w*1.15; const aa=ww*ww*da-2*1*ww*P.va; P.va+=aa*hs; P.a+=P.va*hs;
          const ar=-(36)*P.r-2*.35*6*P.vr; P.vr+=ar*hs; P.r+=P.vr*hs; }
        P.ax+=(ax-P.ax)*Math.min(1,dt*8); P.az+=(az-P.az)*Math.min(1,dt*8); // smoothed acceleration
        const fw=Math.cos(P.a), fz=-Math.sin(P.a), af=P.ax*fw+P.az*fz, al=-P.ax*fz+P.az*fw, sm=u.size>.8?.0022:u.size>.6?.003:.0038;
        physPitch=clamp(-af*sm,-.14,.14); physRoll=clamp(-al*sm*1.4,-.32,.32)+P.r; physYaw=P.a-a; px=P.x; pz=P.z; } }
    if(v.jolt){ const k=(G.time-v.jolt.t0)/.6; if(k>=1) v.jolt=null; else { const e=Math.sin(k*Math.PI)*(1-k); px+=v.jolt.d.x*e; pz+=v.jolt.d.z*e; } }
    const uv=u.vis; v.root.position.set(px,y,pz); v.root.rotation.set(v.bank+((uv&&uv.roll)||0)+physRoll,a+physYaw,((uv&&uv.pitch)||0)+physPitch); { const ts=u.isSq?1+((G.tacScale||1)-1)*.6:(G.tacScale||1), sc=uv&&uv.sc; if(sc||stretch!==1||v.stretched||ts!==1||v.tsc!==ts){ v.root.scaling.set(stretch*ts*(sc?sc[0]:1),ts/Math.sqrt(stretch)*(sc?sc[1]:1),ts/Math.sqrt(stretch)*(sc?sc[2]:1)); v.stretched=stretch!==1||!!sc; v.tsc=ts; } } // v46.1: roll, pitch and squash from the faction's movement // v42: ships grow a little as the camera pulls back
    if(v.model){ const moving=!!u.vis, thr=moving?1+((u.vis.thr==null?.7:u.vis.thr))*1.4:1.35; /* v51: always under way, engines at cruise */ const ck=v.fac==='corsair'&&!u.isSq?corsairCough(v,u,dt):1; v.model.plumes.forEach((pl,i)=>{ const f=thr*ck*(.82+.18*Math.sin(t*31+i*1.7)+.06*Math.sin(t*7.3+i)); pl.scaling.x=f; }); (v.model.flares||[]).forEach((fl,i)=>{ fl.scaling.setAll((moving?1.35:1)*(.85+.15*Math.sin(t*23+i*2.1))); });
      for(const an of (v.model.anim||[])) an.node.rotation[an.axis]+=an.speed*dt; if(v.model.turrets&&typeof updateTurrets==='function') updateTurrets(v,dt);
      if(v.model.stacks&&v.model.stacks.length&&!v.stackFx) v.stackFx=stackSmoke(v); }
    if(v.crafts){ if(v.wing){ const ang=t*.95+v.wingPh, R=3.4; v.wing.position.set(Math.cos(ang)*R,Math.sin(t*.8+v.wingPh)*.4,-Math.sin(ang)*R); v.wing.rotation.set(.3,ang+Math.PI/2,0); for(const c of v.crafts) c.c.root.position.y=c.y+Math.sin(t*2.1+c.ph)*.16; }
      else for(const c of v.crafts){ const ang=t*1.4+c.ph; c.c.root.position.set(Math.cos(ang)*c.rad,c.h+Math.sin(t*2.2+c.ph)*.35,-Math.sin(ang)*c.rad); c.c.root.rotation.y=ang+Math.PI/2; c.c.root.rotation.x=.35; } }
    v.ring.node.position.set(px,.3,pz); v.ring.node.rotation.y=a;
    v.ring.segs.forEach((s,q)=>{ const f=u.shMax?u.sh[q]/u.shMax:0; s.pulse=Math.max(0,s.pulse-dt*2.2); s.mat.alpha=(f>.01?.07+.3*f:0)+s.pulse*.9; const sk=1+s.pulse*.08; if(s.m.scaling.x!==sk) s.m.scaling.setAll(sk); }); /* v53: an unchanged scale is not rewritten (a write forces a world matrix rebuild) */
    // damage fires
    if(!u.isSq){ const hr=u.hp/u.maxHp, want=hr<.3?2:hr<.6?1:0; while(v.fires.length<want) addFire(v); while(v.fires.length>want){ v.fires.pop().stop(); } if(typeof shipDamageFx==='function') shipDamageFx(v,hr); if(v.fac==='corsair'&&typeof corsairWear==='function') corsairWear(v,hr,dt); if(typeof damageSparks==='function') damageSparks(v,hr,dt); }
    // nameplate
    // v53: shown only for the ship in hand (selected, hovered, inspected; hovering a target shows it), above that ship's own hull (v52 hung every plate under the ring, which with the angled camera
    // put it over the neighbouring hex toward the camera, so adjacent ships seemed to own each other's bars)
    const lv=plateLevel(u), pe=v.plate.el; let sp=null; if(lv===2&&!G.cineHidePlates){ const rp=v.root.position; sp=V3.Project(new V3(rp.x,rp.y+(v.H||2)*.6+1.2,rp.z),BABYLON.Matrix.Identity(),tm,vp); if(sp.z<0||sp.z>1) sp=null; }
    if(!sp){ if(v.plate.vis!==0){ pe.style.display='none'; v.plate.vis=0; } } else { if(v.plate.vis!==1){ pe.style.display=''; v.plate.vis=1; } const tx=Math.round(sp.x), ty=Math.round(sp.y); if(tx!==v.plate.tx||ty!==v.plate.ty){ v.plate.tx=tx; v.plate.ty=ty; pe.style.transform=`translate(${tx}px,${ty}px) translate(-50%,-100%)`; } } /* v45: DOM written only when a plate actually moves */
    const hr=clamp(u.hp/u.maxHp,0,1), key=Math.round(hr*100)+'|'+u.sh.map(x=>Math.round(x)).join(',')+'|'+(lv===2?1:0)+(lv===1?'t':'')+(B.side==='player'&&u.side==='player'&&isDone(u)?'d':'');
    if(key!==v.plate.key){ v.plate.key=key; v.plate.hb.style.width=(hr*100)+'%'; v.plate.hb.style.background=hr>.3?HULL_HEX:HULL_LOW_HEX;
      v.plate.sp.forEach((b,i)=>{ const q=[3,0,1,2][i]; const f=u.shMax?u.sh[q]/u.shMax:0; b.style.background=f>.66?SHIELD_HEX:f>.01?'#2c6f93':'rgba(45,58,86,.9)'; });
      pe.classList.toggle('hi',lv===2); /* v53: the label only shows for the ship in hand, so the name always comes with it */ pe.classList.toggle('flag',!!u.flagship||!!u.transport||!!u.pflag); pe.classList.toggle('elite',!!u.elite&&u.side==='enemy'); pe.classList.toggle('done',key.endsWith('d')); }
  }
  G.arcT=(G.arcT||0)-dt; if(G.arcT<=0){ G.arcT=.1+Math.random()*.18; const cands=[]; for(const v of G.views.values()) if(v.state==='alive'&&v.model&&v.model.arcs&&v.model.arcs.length>1) cands.push(v);
    if(cands.length){ const v=cands[Math.floor(Math.random()*cands.length)], A=v.model.arcs, i=Math.floor(Math.random()*A.length), j=(i+1)%A.length, a=toWorld(v,A[i]), c=toWorld(v,A[j]), pts=[];
      for(let k=0;k<=8;k++){ const p=V3.Lerp(a,c,k/8); if(k&&k<8){ p.x+=(Math.random()-.5)*1.1; p.y+=(Math.random()-.2)*1.2+Math.sin(k/8*Math.PI)*1.4; p.z+=(Math.random()-.5)*1.1; } pts.push(p); }
      for(let k=0;k<pts.length-1;k++) lineSprite(pts[k],pts[k+1],.16,new C3(.5,2.2,.9),{dur:.11,fade:1.2}); } } /* v53-I: pooled sprite segments, not a tube per arc */
  animateFactionMats(t); updateBeacon(); updateProjectiles(dt); if(typeof wfxTick==='function') wfxTick(dt); updateHulks(dt); updateOverlays(dt);
  if(G.rocks) for(const r of G.rocks){ r.rotation.x+=r.spin.x*dt; r.rotation.y+=r.spin.y*dt; r.rotation.z+=r.spin.z*dt; }
  if(G.debThin&&G.debThin.length&&!(G.mobile&&(G.fskip&1))) for(const rec of G.debThin) debThinUpdate(rec,G.mobile?dt*2:dt);
  debrisUpdate(dt);
}

// ---------- movement animations (called by the rules engine) ----------
// a whole move is one continuous burn: a smooth curve through the hexes, accelerating, cruising and braking,
// with the nose easing round on turns (the view banks from the turn rate) and the engines flaring with thrust
function fwdOf(a){ const r=a*Math.PI/180; return new V3(Math.cos(r),0,-Math.sin(r)); }
async function animPath(u,path,opt){ opt=opt||{}; if(!path||!path.length) return; const v0=unitVis(u);
  const pk=[{q:v0.q,r:v0.r,s:0}], ak=[{a:v0.a,s:0}], rotS=[]; let s=0, la=v0.a; const rc=u.isSq?.3:PACE.rot; /* B2: turns are quicker */
  const altK=[{s:0,y:0}], thrS=[]; // v50: altitude keys for climbing over rocks / diving under ships, and thruster hops
  for(const st of path){ const a=shortAng(la,st.f*60); if(st.rot){ rotS.push({s,dir:Math.sign(a-la)}); s+=rc; ak.push({a,s}); } else { if(st.slip||st.rev) thrS.push({s,slip:st.slip?st.side||1:0,rev:!!st.rev}); s+=1; pk.push({q:st.q,r:st.r,s}); ak.push({a,s}); altK.push({s,y:st.over?(st.over>0?9:-7.5)*(u.isSq?.5:1):0}); } la=a; }
  const S=Math.max(s,.001);
  { const vv=!u.isSq&&G.views.get(u.id); if(vv&&vv.coast&&pk.length>1&&Math.abs(vv.coast.c)>.01){ const C=vv.coast, rr=-(C.dz*C.c)/(1.5*HS); pk[0]={q:pk[0].q+(C.dx*C.c)/HW-rr/2,r:pk[0].r+rr,s:0}; C.c=0; C.vc=0; } }
  if(pk.at(-1).s<S) pk.push({q:pk.at(-1).q,r:pk.at(-1).r,s:S});
  // Hermite tangents over the path length, so corners round off instead of snapping
  const tan=pk.map((p,i)=>{ const a=pk.at(Math.max(0,i-1)), b=pk.at(Math.min(pk.length-1,i+1)), ds=Math.max(.001,b.s-a.s); return {q:(b.q-a.q)/ds,r:(b.r-a.r)/ds}; });
  const same=(a,b)=>!!a&&!!b&&Math.abs(a.q-b.q)+Math.abs(a.r-b.r)<1e-6;
  pk.forEach((p,i)=>{ if(i===0||i===pk.length-1||same(p,pk.at(i+1))||(i>0&&same(p,pk.at(i-1)))) tan[i]={q:0,r:0}; }); // come to rest where the ship holds position
  const posAt=x=>{ let i=0; while(i<pk.length-2&&x>pk.at(i+1).s) i++; const A=pk.at(i), Bk=pk.at(i+1), ds=Math.max(.001,Bk.s-A.s), t=clamp((x-A.s)/ds,0,1);
    if(Math.abs(Bk.q-A.q)+Math.abs(Bk.r-A.r)<1e-6) return {q:A.q,r:A.r};
    const t2=t*t, t3=t2*t, h00=2*t3-3*t2+1, h10=t3-2*t2+t, h01=-2*t3+3*t2, h11=t3-t2, mA=tan.at(i), mB=tan.at(i+1);
    return {q:h00*A.q+h10*ds*mA.q+h01*Bk.q+h11*ds*mB.q, r:h00*A.r+h10*ds*mA.r+h01*Bk.r+h11*ds*mB.r}; };
  const angAt=x=>{ let i=0; while(i<ak.length-2&&x>ak.at(i+1).s) i++; const A=ak.at(i), Bk=ak.at(Math.min(ak.length-1,i+1)); if(Bk===A) return A.a; const t=clamp((x-A.s)/Math.max(.001,Bk.s-A.s),0,1), e=t*t*(3-2*t); return A.a+(Bk.a-A.a)*e; };
  const hasAlt=altK.some(k=>k.y), altAt=x=>{ if(!hasAlt) return 0; let i=0; while(i<altK.length-2&&x>altK[i+1].s) i++; const A=altK[i], Bk=altK[Math.min(altK.length-1,i+1)]; if(Bk===A) return A.y;
    // ease out of the old height early and into the new one late, so the hull clears the obstacle hex at full height
    const t=clamp((x-A.s)/Math.max(.001,Bk.s-A.s)*1.35,0,1), e=t*t*(3-2*t); return A.y+(Bk.y-A.y)*e; };
  const slipAt=x=>{ for(const h of thrS) if(h.slip&&x>=h.s&&x<h.s+1) return h.slip*Math.sin(Math.PI*(x-h.s)); return 0; };
  // a trapezoid speed profile: spool up, cruise, brake; big hulls take longer to get going
  const FE=(!u.isSq&&typeof MOVE_FEEL!=='undefined'&&MOVE_FEEL[u.fac])||{};
  const per=(u.isSq?110:u.size>.8?430:u.size>.6?350:280)*(FE.per||1), dur=Math.min((per*S+(u.isSq?60:260))*(opt.charge?.72:1)*(u.isSq?1:PACE.move), u.isSq?900:3600); /* B2: shorter moves */
  const ta=u.isSq?.12:opt.charge?.45:(FE.ta!=null?FE.ta*(u.size>.8?1.15:1):u.size>.8?.32:.25), td=opt.charge?.05:u.isSq?.15:(FE.td!=null?FE.td:.3);
  // v51 underway: hulls never come to a dead stop. A burn starts from the cruise the ship was already holding and eases back to cruise,
  // then the ship coasts on (see coastTick), so the next order picks up a moving ship instead of a parked one.
  const cr=(u.isSq||opt.charge)?0:(FE.cruise!=null?FE.cruise:.22), vmax=1/(ta*(1+cr)/2+(1-ta-td)+td*(1+cr)/2);
  const prog=p=>{ if(p<ta) return vmax*(cr*p+(1-cr)*p*p/(2*ta)); if(p<1-td) return vmax*(ta*(1+cr)/2+p-ta); const q=p-(1-td); return vmax*(ta*(1+cr)/2+1-ta-td)+vmax*q-vmax*(1-cr)*q*q/(2*td); };
  const thrAt=p=>p<ta?1:p<1-td?.65:.15;
  if(!u.isSq&&G.views.get(u.id)) SFX.engine(u.size,u);
  const v=G.views.get(u.id); let trail=null; if(v&&!u.isSq&&v.root&&S>=1&&!FE.phase&&!(typeof process!=='undefined'&&process.env)) trail=startTrail(v); let ri=0, ti=0, lastKey=0;
  // v46.1 movement signatures, strong enough to read at battle zoom (Ryan: "I didn't see or feel any real differences")
  const sd=String(u.id).split('').reduce((h,c)=>h*31+c.charCodeAt(0)|0,7), side=(sd&1)?1:-1, ph=(Math.abs(sd)%100)*.0628;
  const P0=pk[0], P1=pk.at(-1), W0=hexWorld(P0.q,P0.r), W1=hexWorld(P1.q,P1.r), span=Math.hypot(W1.x-W0.x,W1.z-W0.z), travels=span>.5&&!opt.charge;
  const perp=travels?{x:-(W1.z-W0.z)/span,z:(W1.x-W0.x)/span}:{x:0,z:0}, w2h=(dx,dz)=>{ const rr=-dz/(1.5*HS); return {q:dx/HW-rr/2,r:rr}; };
  const linPos=x=>{ let i=0; while(i<pk.length-2&&x>pk.at(i+1).s) i++; const A=pk.at(i), Bk=pk.at(i+1)||A, t=clamp((x-A.s)/Math.max(.001,Bk.s-A.s),0,1); return {q:A.q+(Bk.q-A.q)*t,r:A.r+(Bk.r-A.r)*t}; };
  const base=FE.linear?linPos:posAt, posX=x=>{ if(x<=S) return base(x); const e0=base(S), e1=base(Math.max(0,S-.3)), dq=e0.q-e1.q, dr=e0.r-e1.r, n=Math.hypot(dq,dr)||1; return {q:e0.q+dq/n*(x-S),r:e0.r+dr/n*(x-S)}; };
  const latOff=(x,p)=>{ if(!travels) return 0; const f=x/S, env=Math.sin(clamp(f,0,1)*Math.PI); // sideways offset, in hexes
    if(FE.arc) return FE.arc*side*Math.sin(clamp(f,0,1)*Math.PI); // Ithar: one wide, graceful curve
    if(FE.sway) return FE.sway*Math.sin(f*Math.PI*2*(FE.cyc||1.5)+ph)*env; // Chorus: swims, side to side
    if(FE.jit) return FE.jit*(Math.sin(x*5.3+ph)*.6+Math.sin(x*11.7+ph*2.3)*.4)*env; // Corsair: drifts and corrects
    return 0; };
  const at=(x,p)=>{ const b0=posX(x), o=latOff(x,p); if(!o) return b0; const h=w2h(perp.x*o*HW,perp.z*o*HW); return {q:b0.q+h.q,r:b0.r+h.r}; };
  const headDelta=(x,p)=>{ if(!travels||!(FE.arc||FE.sway||FE.jit)) return 0; const x2=Math.min(S,x+.06), x1=Math.max(0,x2-.12); if(x2-x1<.01) return 0;
    const A0=hexWorld(posX(x1).q,posX(x1).r), A1=hexWorld(posX(x2).q,posX(x2).r), O0=at(x1,p), O1=at(x2,p), B0=hexWorld(O0.q,O0.r), B1=hexWorld(O1.q,O1.r);
    let d=(Math.atan2(-(B1.z-B0.z),B1.x-B0.x)-Math.atan2(-(A1.z-A0.z),A1.x-A0.x))*180/Math.PI; d=((d+540)%360)-180; return clamp(d,-40,40); };
  const fxAt=(q,r,y)=>{ const w=hexWorld(q,r); return new V3(w.x,y==null?HOVER_Y:y,w.z); };
  const P=FAC3D[u.fac]||FAC3D.hegemony; let retroDone=false, coughT=0, phased=false;
  const phaseFx=(q,r,out)=>{ try{ SFX.phase({q,r}); const c=fxAt(q,r), L=(v&&v.L)||8; flash(c,6+L*.5,P.eng.scale(1.8),.3); if(typeof shockRing==='function') shockRing(c,L*1.1,P.eng,{flat:true,dur:.5});
      lineSprite(c,c.add(new V3(0,26,0)),Math.max(1.2,L*.12),P.eng.scale(1.6),{dur:.55*Math.max(.4,SPEED),fade:1.3}); lineSprite(c,c.add(new V3(0,18,0)),L*.45,P.eng.scale(.5),{dur:.5*Math.max(.4,SPEED),fade:1.6,alpha:.6}); /* v53-I: pooled sprites, not a cylinder and material per jump */
      if(typeof sparks==='function') sparks(c,18,9,new C4(P.eng.r,P.eng.g,P.eng.b,1)); }catch(e){} };
  let lateDone=!opt.onLate; const fireLate=()=>{ if(lateDone) return; lateDone=true; try{ opt.onLate(); }catch(err){ console.error(err); } };
  await tween(dur,(e,p)=>{ let x=S*clamp(prog(p),0,1); if(!lateDone&&p>=.62) fireLate();
    if(FE.str&&travels){ x=clamp(x+.06*Math.sin(2*Math.PI*FE.str*p)*Math.sin(Math.PI*p),0,S); } // Chorus: surges with each stroke
    const ps=at(x,p);
    while(ri<rotS.length&&x>=rotS.at(ri).s){ if(v) rcsPuff(v,rotS.at(ri).dir); ri++; }
    while(ti<thrS.length&&x>=thrS[ti].s){ const h=thrS[ti]; if(v&&v.root){ if(h.slip) slipPuff(v,h.slip); else if(h.rev) revPuff(v); } ti++; }
    const k=Math.floor(x); if(k!==lastKey){ lastKey=k; if(B) B.prog=(B.prog||0)+1; }
    let lift=u.isSq?Math.sin(p*Math.PI)*1.6:0, thr=thrAt(p), roll=0, pitch=0, sc=null;
    if(FE.bob&&travels) lift+=FE.bob*Math.sin(clamp(p,0,1)*Math.PI); // Ithar: rises into a glide
    if(FE.arc&&travels) roll=-side*(FE.roll||.3)*Math.sin(clamp(x/S,0,1)*Math.PI); // banks into the curve
    if(FE.over&&travels){ pitch=(p<ta?-1:0)*(FE.pitch||.07)*Math.sin(Math.PI*clamp(p/ta,0,1)); thr=p<ta?2.4:thr; } // Voidsworn: the nose digs in as the heavy drive lights
    if(FE.squash&&travels){ const w=Math.sin(2*Math.PI*(FE.str||3)*p); sc=[1+FE.squash*w,1/Math.sqrt(1+FE.squash*w),1/Math.sqrt(1+FE.squash*w)]; thr=.5+.9*Math.max(0,w); }
    if(FE.jit&&travels){ roll=(FE.roll||.2)*Math.sin(x*7.1+ph)*Math.sin(Math.PI*p); if(p>ta&&p<1-td){ const c=Math.sin(G.time*23+ph)>.55; thr=c?2:.35; if(v&&v.root&&G.time-coughT>.16&&Math.random()<.35){ coughT=G.time; try{ SFX.cough(v); const st=toWorld(v,new V3(-v.L*.55,0,0)); burst(st,{n:8,c1:new C4(.3,.27,.25,.75),c2:new C4(.15,.13,.12,.5),size:[.5,1.3],life:[.5,1.1],power:[1,3],tex:G.tex.smoke,blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }catch(err){} } } } // patched engines cough smoke
    if(FE.linear&&travels){ if(p<ta) thr=2.2; if(FE.retro&&!retroDone&&p>=1-td){ retroDone=true; try{ if(v&&v.root){ const bow=toWorld(v,new V3(v.L*.5,0,0)); flash(bow,3+v.L*.18,P.eng.scale(1.6),.22); rcsPuff(v,1); rcsPuff(v,-1); } }catch(err){} } } // Hegemony: hard burn, dead-straight, retro-thrust stop
    if(FE.phase&&v&&v.root&&travels){ // Deathless: the hull dissolves, and is simply elsewhere
      const k1=clamp((p-.02)/.1,0,1), k2=clamp((.98-p)/.1,0,1); const hide=p>.12&&p<.88;
      if(!hide){ const s=p<.5?1-k1*.95:1-k2*.95; sc=[1+(1-s)*.6,Math.max(.05,s),Math.max(.05,s)]; }
      if(hide!==phased){ phased=hide; v.phased=hide; v.root.setEnabled(!hide); if(v.ring&&v.ring.node) v.ring.node.setEnabled(!hide); if(v.plate) v.plate.el.style.visibility=hide?'hidden':''; const at0=hide?pk[0]:P1; phaseFx(at0.q,at0.r,hide); } }
    if(hasAlt){ const xc=Math.min(x,S), y0=altAt(xc), y1=altAt(Math.min(S,xc+.08)); lift+=y0; pitch+=clamp((y1-y0)*.1,-.3,.3); }
    if(thrS.length){ const sl=slipAt(Math.min(x,S)); if(sl) roll+=-sl*.16; }
    u.vis={q:ps.q,r:ps.r,a:angAt(Math.min(x,S))+headDelta(Math.min(x,S),p),thr,lift,roll,pitch,sc}; }, true);
  fireLate();
  if(v&&v.phased){ v.phased=false; if(v.root) v.root.setEnabled(true); if(v.ring&&v.ring.node) v.ring.node.setEnabled(true); if(v.plate) v.plate.el.style.visibility=''; }
  u.vis=null; if(trail) endTrail(trail); // v53: presentation only; the caller commits u.q/u.r/facing after its live() check (moveUnit commit, ramUnit, rotateUnit)
  if(v&&!u.isSq&&travels&&!opt.charge&&cr>0){ let ia=pk.length-2; while(ia>0&&Math.abs(pk[ia].q-P1.q)+Math.abs(pk[ia].r-P1.r)<1e-6) ia--; const A=hexWorld(pk[ia].q,pk[ia].r), Bw=hexWorld(P1.q,P1.r), dx=Bw.x-A.x, dz=Bw.z-A.z, l=Math.hypot(dx,dz)||1;
    const sp=vmax*cr*S*HW/(dur/1000); coastStart(v,u,dx/l,dz/l,sp,FE); }
}
async function animMove(u,q,r,f){ return animPath(u,[{q,r,f}]); }
async function animRotate(u,f){ return animPath(u,[{rot:true,f}]); }
// engine wake: a ribbon that follows the stern and collapses once the ship stops
// v53-I: wakes are pooled per faction (trail mesh, generator node and material reused; reset onto the new stern)
function startTrail(v){ try{ const P=FAC3D[v.fac]||FAC3D.hegemony, pool=(G.wakePool=G.wakePool||{})[v.fac]||(G.wakePool[v.fac]=[]); for(let i=pool.length-1;i>=0;i--){ const x=pool[i]; if(x.tm.isDisposed()||x.n.isDisposed()){ try{ x.tm.dispose(); x.n.dispose(); x.m.dispose(); }catch(e){} pool.splice(i,1); } } let tr=pool.find(x=>!x.busy);
    if(!tr){ const n=new BABYLON.TransformNode('wakeN',G.scene); n.parent=v.root; n.position.set(-v.L*.5,0,0); n.computeWorldMatrix(true);
      const tm=new BABYLON.TrailMesh('wake',n,G.scene,Math.max(.6,v.L*.07),48,false), m=emMat('wakeM',P.eng.scale(.9),.42); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; tm.material=m; tm.isPickable=false; try{ G.glow.addExcludedMesh(tm); }catch(e){}
      tr={tm,n,m,busy:false}; tr.release=()=>{ try{ if(tr.n.isDisposed()){ tr.tm.dispose(); tr.m.dispose(); } else { tr.tm.stop(); tr.tm.setEnabled(false); tr.n.parent=null; } }catch(e){} tr.busy=false; tr.fading=0; if(G.trails) G.trails.delete(tr); }; if(pool.length<8) pool.push(tr); else tr.temp=true; }
    tr.busy=true; tr.fading=0; tr.n.parent=v.root; tr.n.position.set(-v.L*.5,0,0); tr.n.computeWorldMatrix(true); tr.tm.diameter=Math.max(.6,v.L*.07); try{ tr.tm.reset(); }catch(e){} tr.tm.setEnabled(true); tr.tm.start(); tr.m.alpha=.42;
    (G.trails=G.trails||new Set()).add(tr); return tr; }catch(e){ return null; } }
function endTrail(tr){ const t0=G.time, f=tr.fading=(tr.fading||0)+1; const obs=G.scene.onBeforeRenderObservable.add(()=>{ if(tr.fading!==f||!tr.busy){ G.scene.onBeforeRenderObservable.remove(obs); return; } const k=(G.time-t0)/1.4; tr.m.alpha=.42*Math.max(0,1-k);
    if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); if(tr.temp){ try{ tr.tm.dispose(); tr.n.dispose(); tr.m.dispose(); }catch(e){} if(G.trails) G.trails.delete(tr); } else tr.release(); } }); }
// manoeuvring thrusters: small cold-gas puffs at the bow when a ship swings its nose round
function rcsPuff(v,dir){ try{ if(!v.root||G.fxReduced&&G.mobile) return; const a=v.root.rotation.y, f=fwdOf(a*180/Math.PI), side=new V3(-f.z,0,f.x).scale(dir>=0?1:-1), p=v.root.getAbsolutePosition().add(f.scale(v.L*.38)).add(side.scale(v.L*.06));
    burst(p,{n:10,c1:new C4(.85,.92,1,.7),c2:new C4(.6,.7,.8,.4),size:[.25,.7],life:[.25,.55],power:[3,7],tex:G.tex.soft,blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }catch(e){} }

// v50 lateral thrusters: a broadside of cold-gas jets fore and aft when a hull slips sideways; a bow retro burst when it backs off
function slipPuff(v,dir){ try{ if(!v.root||G.fxReduced&&G.mobile) return; const a=v.root.rotation.y, f=fwdOf(a*180/Math.PI), side=new V3(-f.z,0,f.x).scale(dir>=0?-1:1), c=v.root.getAbsolutePosition();
    for(const k of [.32,-.3]){ const p=c.add(f.scale(v.L*k)).add(side.scale(v.L*.09)); burst(p,{n:9,c1:new C4(.85,.92,1,.7),c2:new C4(.6,.7,.8,.35),size:[.3,.8],life:[.3,.6],power:[4,8],dir:side,tex:G.tex.soft,blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }
    if(typeof SFX!=='undefined'&&SFX.puff) SFX.puff(c); }catch(e){} }
function revPuff(v){ try{ if(!v.root) return; const P=FAC3D[v.fac]||FAC3D.hegemony, a=v.root.rotation.y, f=fwdOf(a*180/Math.PI), bow=v.root.getAbsolutePosition().add(f.scale(v.L*.5));
    flash(bow,2.5+v.L*.15,P.eng.scale(1.4),.2); burst(bow,{n:12,c1:new C4(.85,.92,1,.75),c2:new C4(.6,.7,.8,.35),size:[.3,.9],life:[.3,.6],power:[5,9],dir:f,tex:G.tex.soft,blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }catch(e){} }

// ---------- projectiles ----------
// v53-I: bolts, beams and torpedoes are pooled sprites and pooled meshes (wfx3d: wbFly, lanceBeam, torpRig); PROJ/TORPS stay empty for older callers
const PROJ=[]; const TORPS=new Set();
function updateProjectiles(dt){}
// v44.1: small effects go through the pooled sprite managers (no new mesh, material or particle system per effect); v53-I: the old fallbacks are gone
function fxMark(k){ G.fxLast={k,t:performance.now()}; }
function poolOK(){ try{ return typeof fxp==='function'&&!!fxPool().mgr; }catch(e){ return false; } }
function flash(pos,size,col,dur=.35){ if(G.fxReduced){ size*=.55; col=col.scale(.6); } fxp(pos,{cell:0,size:size*1.15,col:col.scale(1.8),dur,grow:.9,fade:1.4}); }
function burst(pos,{n=24,c1=new C4(1,.8,.4,1),c2=new C4(1,.45,.1,1),size=[.15,.5],life=[.2,.6],power=[4,14],tex=G.tex.soft,blend=BABYLON.ParticleSystem.BLENDMODE_ONEONE,grav=0,sizeGrow=false,dir=null}={}){
  const sm=blend===BABYLON.ParticleSystem.BLENDMODE_STANDARD, N=Math.max(1,Math.round(n*(G.mobile?.4:.7))), R=(a)=>a[0]+Math.random()*(a[1]-a[0]);
  for(let i=0;i<N;i++){ const k=Math.random(), c=new C3(c1.r+(c2.r-c1.r)*k,c1.g+(c2.g-c1.g)*k,c1.b+(c2.b-c1.b)*k), al=c1.a+(c2.a-c1.a)*k, d=dir?coneDir(dir,.7):rdir(), sz=R(size);
    fxp(pos,{smoke:sm,cell:0,size:sz*(sm?1.5:1.7),col:sm?c:c.scale(1.3),alpha:sm?al:Math.min(1,al),dur:R(life),grow:sizeGrow?2:.55,vel:d.scale(R(power)),drag:sm?.9:1.4,grav:-grav,fade:sm?1.3:1.6}); } }
function shieldDome(v,dirToAtt,col,o){ o=o||{};
  if(!BABYLON.Effect.ShadersStore.shRipVertexShader){
    BABYLON.Effect.ShadersStore.shRipVertexShader=`precision highp float; attribute vec3 position; attribute vec3 normal; uniform mat4 world; uniform mat4 worldViewProjection; varying vec3 vL; varying vec3 vNW; varying vec3 vPW;
      void main(){ vL=normalize(position); vNW=normalize((world*vec4(normal,0.0)).xyz); vPW=(world*vec4(position,1.0)).xyz; gl_Position=worldViewProjection*vec4(position,1.0); }`;
    BABYLON.Effect.ShadersStore.shRipFragmentShader=`precision highp float; varying vec3 vL; varying vec3 vNW; varying vec3 vPW; uniform vec3 impact; uniform vec3 col; uniform float t; uniform vec3 camPos; uniform float stat;
      float hexl(vec2 p){ p*=vec2(14.0,9.0); vec2 q=vec2(p.x+p.y*0.577,p.y*1.155); vec2 f=fract(q)-0.5; return smoothstep(0.42,0.5,max(abs(f.x),abs(f.y))); }
      void main(){ float ang=acos(clamp(dot(vL,impact),-1.0,1.0)); float w=exp(-pow((ang-t*2.4)*6.0,2.0))*(1.0-t); float core=exp(-ang*ang*10.0)*(1.0-t)*1.4;
        vec2 uv=vec2(atan(vL.z,vL.x),asin(clamp(vL.y,-1.0,1.0))); float hx=hexl(uv); float fr=pow(1.0-abs(dot(normalize(vNW),normalize(camPos-vPW))),2.5);
        float a=(w+core)*(0.35+0.85*hx)+fr*0.12*(1.0-t);
        float sn=fract(sin(dot(floor(uv*vec2(30.0,18.0))+floor(t*36.0),vec2(12.9898,78.233)))*43758.5453); float wash=stat*smoothstep(1.5,0.2,ang)*(1.0-t)*(0.2*hx+0.75*step(0.8,sn)+0.25); a+=wash; vec3 cc=mix(col,vec3(0.55,0.8,1.0),stat*0.6);
        gl_FragColor=vec4(cc*a*1.7,a); }`; } /* v53-I: stat = ion static crawling over the struck facing */
  const R=Math.max(4.2,v.L*.5); const pool=G.domePool=(G.domePool||[]).filter(e=>!e.sp.isDisposed()); let ent=pool.find(e=>!e.busy&&!e.sp.isDisposed()); // v45: domes are pooled (mesh + material reused), not built per hit
  if(!ent){ const sp=MB.CreateSphere('shRip',{diameter:2,segments:24},G.scene); sp.isPickable=false; const mat=new BABYLON.ShaderMaterial('shRipM',G.scene,{vertex:'shRip',fragment:'shRip'},{attributes:['position','normal'],uniforms:['world','worldViewProjection','impact','col','t','camPos','stat'],needAlphaBlending:true});
    mat.alphaMode=BABYLON.Engine.ALPHA_ADD; mat.backFaceCulling=false; mat.disableDepthWrite=true; sp.material=mat; try{ G.glow.addExcludedMesh(sp); }catch(e){} ent={sp,mat,busy:false}; if(pool.length<8) pool.push(ent); }
  ent.busy=true; const sp=ent.sp, mat=ent.mat, gen=ent.gen=(ent.gen||0)+1; sp.parent=v.root; sp.position.set(0,.5,0); sp.scaling=new V3(R*1.1,Math.max(2.4,v.H*.75),Math.max(3,R*.42)); sp.setEnabled(true); mat.setFloat('t',0);
  v.root.computeWorldMatrix(true); const inv=BABYLON.Matrix.Invert(v.root.getWorldMatrix()); const li=V3.TransformNormal(dirToAtt,inv); li.y*=.4;
  mat.setVector3('impact',li.normalize()); mat.setColor3('col',col); mat.setFloat('stat',o.stat||0);
  const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/((o.dur||.8)*Math.max(.3,SPEED)); if(k>=1||sp.isDisposed()||ent.gen!==gen){ G.scene.onBeforeRenderObservable.remove(obs); if(ent.gen!==gen) return; const inPool=G.domePool.includes(ent); if(sp.isDisposed()||!inPool){ if(!sp.isDisposed()) sp.dispose(); mat.dispose(); if(inPool) G.domePool.splice(G.domePool.indexOf(ent),1); } else { sp.setEnabled(false); sp.parent=null; } ent.busy=false; return; } mat.setFloat('t',k); mat.setVector3('camPos',G.cam.position); }); }

// v44.1: a fixed pool of flash lights, created once and kept at zero intensity, so blasts never change the scene's light count
// (adding or removing a light marks every material dirty and stalls the frame); Medium has no flash lights at all
function flashLights(){ const want=G.fxReduced?0:G.quality==='ultra'?3:G.quality==='high'?2:0; const pool=G.flPool=G.flPool||[];
  if(pool.length&&pool[0].getScene()!==G.scene) pool.length=0;
  while(pool.length<want){ const l=new BABYLON.PointLight('xl',new V3(0,-9000,0),G.scene); l.intensity=0; l.range=1; l.busy=false; pool.push(l); }
  pool.forEach((l,i)=>{ const on=i<want; if(l.isEnabled(false)!==on) l.setEnabled(on); }); return pool.slice(0,want); }
function lightFlash(pos,col,intensity,range,dur){ const l=flashLights().find(x=>!x.busy); if(!l) return; l.busy=true; l.position.copyFrom(pos); l.diffuse.copyFrom(col); l.specular.copyFrom(col); l.range=range; l.intensity=intensity; const t0=G.time;
  const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(dur*Math.max(.3,SPEED)); if(k>=1||l.isDisposed()){ G.scene.onBeforeRenderObservable.remove(obs); l.intensity=0; l.position.set(0,-9000,0); l.busy=false; return; } l.intensity=intensity*(1-k)*(1-k); }); }
// v53-I: fire is the flipbook (wfx3d fxBookCanvas or a rendered atlas): a white-hot core, rolling flame, smoke that outlives it
function fireball(pos,size,n,life=1.2,spread=.35){ const N=nq(n*.8,24); flames(pos,Math.max(2,Math.round(N*.4)),size*.9,new C3(1,.85,.6),{life:life*.45,spread:spread*.5,grow:1.2});
  flames(pos,N,size*1.25,new C3(1,.45,.14),{life:life*.75,spread,grow:1.6,v:1.1,fade:.85}); smokePuff(pos,Math.max(1,Math.round(N*.5)),size*1.5,{l0:life*1.4,l1:life*2.6,v:size*.35}); }
function sparks(pos,n,power,col=new C4(1,.8,.45,1)){ sparkSpray(pos,null,Math.max(2,Math.round(n*(G.mobile?.3:.55))),[power*.4,power],new C3(col.r,col.g,col.b),1,{grav:2,drag:1.1}); }
function smoke(pos,size,n,life=2.6){ smokePuff(pos,Math.max(1,Math.round(n*(G.mobile?.4:.7))),size*1.3,{l0:life*.6,l1:life,v:size*.45}); }
function explode(pos,size,{light=true,shock=false}={}){ blast(pos,size,{light,ring:shock}); }
function muzzleFx(pos,out,col){ muzzleBlast(pos,out,col); }

// ---------- persistent battle damage ----------
let SCORCH=null;
function scorchMat(){ if(SCORCH) return SCORCH; const t=dynTex('scorchT',128,128,(g,w)=>{ const c=w/2, r=seeded(17); for(let i=0;i<40;i++){ const x=c+(r()-.5)*w*.5,y=c+(r()-.5)*w*.5,rad=w*(.08+r()*.2); const gr=g.createRadialGradient(x,y,0,x,y,rad); gr.addColorStop(0,'rgba(8,6,5,.55)'); gr.addColorStop(1,'rgba(8,6,5,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); }
    g.strokeStyle='rgba(15,10,8,.6)'; g.lineWidth=2; for(let i=0;i<8;i++){ g.beginPath(); g.moveTo(c,c); let x=c,y=c; for(let k=0;k<5;k++){ x+=(r()-.5)*24; y+=(r()-.5)*24; g.lineTo(x,y); } g.stroke(); } });
  const m=new BABYLON.StandardMaterial('scorchM',G.scene); m.diffuseTexture=t; m.diffuseTexture.hasAlpha=true; m.useAlphaFromDiffuseTexture=true; m.specularColor=C3.Black(); m.backFaceCulling=false; m.zOffset=-2; return SCORCH=m; }
// v53-I: every scorch is an instance of one plane (shared geometry and material)
function scorchPlane(sz){ let b=G.scorchBase; if(!b||b.isDisposed()){ b=G.scorchBase=MB.CreatePlane('scorchBase',{size:1},G.scene); b.material=scorchMat(); b.isPickable=false; b.isVisible=false; b.position.y=-9000; try{ G.glow.addExcludedMesh(b); }catch(e){} }
  const pl=b.createInstance('scorch'); pl.isPickable=false; pl.scaling.setAll(sz); return pl; }
function surfAtModel(sf,x){ const st=sf.st; if(x<=st[0].x) return st[0]; for(let i=0;i<st.length-1;i++) if(x>=st[i].x&&x<=st[i+1].x) return interpStation(st[i],st[i+1],x); return st[st.length-1]; }
function hullDecal(vt,from,big){ const md=vt&&vt.model; if(!md||!md.surf||!vt.root||vt.root.isDisposed()) return; const L=vt.L; vt.root.computeWorldMatrix(true);
  if(md.skin&&md.skin.length) return skinDecal(vt,from,big);
  const lf=V3.TransformCoordinates(from,BABYLON.Matrix.Invert(vt.root.getWorldMatrix())), side=lf.z>=0?1:-1, x=(Math.random()-.5)*L*.75, st=surfAtModel(md.surf,x); if(!st||st.w<L*.02) return;
  const y=(st.y||0)+(Math.random()-.3)*st.t*.7, node=x>=md.surf.split?md.fore:md.aft; if(!node||node.isDisposed()) return; const sz=(big?2.2:1.1)*(.7+Math.random()*.6)*Math.max(1,L/14);
  const pl=scorchPlane(sz); pl.parent=node; pl.position.set(x,y,side*(st.w+L*.004)); pl.rotation.set(0,side>0?Math.PI:0,Math.random()*6);
  try{ node.computeWorldMatrix(true); hullGlow(vt,V3.TransformCoordinates(pl.position,node.getWorldMatrix()),sz*.5,new C3(1.4,.55,.15),new C3(.25,.03,0),9,8); }catch(e){} /* v53-I: a pooled glow that rides the hull, not a plane, material and observer per hit */
  (vt.decals=vt.decals||[]).push(pl); if(vt.decals.length>28){ const old=vt.decals.shift(); if(!old.isDisposed()) old.dispose(); } }

// v53-G: scorch marks on a concept hull lie flat on a sampled surface point, turned to its normal
function skinDecal(vt,from,big){ const md=vt.model, L=vt.L, c=skinPoint(vt,from.subtract(vt.root.getAbsolutePosition())); if(!c) return; const node=c.p.x>=((md.surf&&md.surf.split)||0)?md.fore:md.aft; if(!node||node.isDisposed()) return;
  const sz=(big?1.8:.9)*(.7+Math.random()*.6)*Math.max(1,L/14), q=BABYLON.Quaternion.FromLookDirectionLH(c.n,Math.abs(c.n.y)>.9?new V3(1,0,0):new V3(0,1,0)).multiply(BABYLON.Quaternion.RotationAxis(new V3(0,0,1),Math.random()*6.28));
  const pl=scorchPlane(sz); pl.parent=node; pl.position=c.p.add(c.n.scale(L*.002)); pl.rotationQuaternion=q;
  try{ hullGlow(vt,toWorld(vt,c.p.add(c.n.scale(L*.004))),sz*.45,new C3(1.4,.55,.15),new C3(.25,.03,0),9,8); }catch(e){}
  (vt.decals=vt.decals||[]).push(pl); if(vt.decals.length>28){ const old=vt.decals.shift(); if(!old.isDisposed()) old.dispose(); } }

// ---------- weapon fire (called by the rules engine before damage is applied) ----------
function hitPoint(vt,att,shielded){
  const c=vt.root.getAbsolutePosition(); const toA=att.subtract(c); toA.y=0; toA.normalize();
  if(shielded) return c.add(toA.scale(Math.max(4.2,vt.L*.5)*.85)).add(new V3(0,1,0));
  const sk=skinPoint(vt,toA); if(sk) return toWorld(vt,sk.p); // v53-G: concept hulls take hits on their real surface, on the side facing the shooter
  const local=new V3((Math.random()-.5)*vt.L*.55,Math.random()*vt.H*.6,(Math.random()-.5)*vt.L*.1); return toWorld(vt,local);
}
function skinPoint(vt,worldDir){ const sk=vt&&vt.model&&vt.model.skin; if(!sk||!sk.length||!vt.root) return null; let ld=null;
  if(worldDir){ vt.root.computeWorldMatrix(true); ld=V3.TransformNormal(worldDir,BABYLON.Matrix.Invert(vt.root.getWorldMatrix())); ld.normalize(); }
  let best=null,bs=-9; for(let i=0;i<6;i++){ const c=sk[Math.floor(Math.random()*sk.length)], sc=(ld?V3.Dot(c.n,ld):0)+Math.random()*.6; if(sc>bs){ bs=sc; best=c; } } return best; }
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
// v45: cinematic cut-ins. Setting: off, key moments (default), every action. Tap anywhere to skip; plates hide and letterbox bars slide in while a cut-in plays.
function cineWants(kind,a,t){ const m=G.cine?(G.cineMode||'key'):'off'; if(m==='off'||G.fxReduced&&kind!=='kill') return false; if(m==='all') return true;
  const big=!!((t&&t.t&&t.t.boss)||(a&&a.t&&a.t.boss)), low=!!(t&&t.maxHp&&t.hp!=null&&t.hp<=t.maxHp*.35);
  if(kind==='kill') return !!(t&&!t.isSq&&(t.size>=.6||t.t&&t.t.boss));
  if(kind==='command') return true;
  if(kind==='lance'||kind==='torp'||kind==='nova') return big||low||!G.mobile;
  if(kind==='volley') return !!(a&&a.size>=.7&&(big||low));
  return false; }
function cineBars(on){ if(typeof document==='undefined') return; let t=document.getElementById('lbTop'), b=document.getElementById('lbBot'), h=document.getElementById('cineSkip');
  if(!t){ const st=document.createElement('style'); st.textContent='.lb{position:fixed;left:0;right:0;height:9vh;background:#000;z-index:40;pointer-events:none;transition:transform .35s ease;}#lbTop{top:0;transform:translateY(-100%)}#lbBot{bottom:0;transform:translateY(100%)}body.cine-on #lbTop,body.cine-on #lbBot{transform:none}#cineSkip{position:fixed;right:12px;bottom:calc(9vh + 10px);z-index:41;font:600 12px system-ui;color:#e8dcc0;background:rgba(0,0,0,.55);border:1px solid rgba(232,220,192,.35);padding:5px 10px;border-radius:12px;opacity:0;transition:opacity .3s;pointer-events:none}body.cine-on #cineSkip{opacity:.9}body.cine-on .plate{opacity:0!important;transition:opacity .25s}.hud{transition:opacity .3s}body.cine-on .hud{opacity:0!important;pointer-events:none}';
    document.head.appendChild(st); t=document.createElement('div'); t.id='lbTop'; t.className='lb'; b=document.createElement('div'); b.id='lbBot'; b.className='lb'; h=document.createElement('div'); h.id='cineSkip'; h.textContent='Tap to skip';
    document.body.append(t,b,h);
    document.addEventListener('pointerdown',()=>{ if(document.body.classList.contains('cine-on')&&G.ctl&&G.ctl.saved){ clearTimeout(G.cineTimer); G.cineSkipAt=performance.now(); G.ctl.release(); } },true); }
  document.body.classList.toggle('cine-on',!!on); G.cineHidePlates=!!on;
  try{ if(G.grid&&!G.grid.isDisposed()) G.grid.setEnabled(!on); if(typeof OV!=='undefined'){ for(const m of OV.items) if(m&&!m.isDisposed()) m.setEnabled(!on); if(OV.fan&&!OV.fan.isDisposed()) OV.fan.setEnabled(!on); } }catch(e){} } // the board overlay hides too, so the shot reads as a film frame
async function cineFrame(a,t,kind='lance'){
  if(a.isSq||B.over||!cineWants(kind,a,t)) return; fxMark('cine');
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
// v53-I: the weapon pass (animWeapon) and the per-family effect table (WFX) live in wfx3d.js

// ---------- floating text and generic hooks ----------
function fxText(u,txt,color,dy=0){
  if(!G.scene) return; const p=uWorld(u); const v=G.views.get(u.id); p.y+=(v?v.H:3)+1;
  const cw=G.engine.getRenderingCanvas().clientWidth, ch=G.engine.getRenderingCanvas().clientHeight;
  const sp=V3.Project(p,BABYLON.Matrix.Identity(),G.scene.getTransformMatrix(),G.cam.viewport.toGlobal(cw,ch)); if(sp.z<0||sp.z>1) return;
  const el=FTXT_POOL.pop()||Object.assign(document.createElement('div'),{className:'ftxt'}); el.textContent=txt; el.style.color=color; { const m=/[\u2212-](\d+)/.exec(txt), n=m?+m[1]:0; el.style.fontSize=n?Math.round(17+Math.min(15,n*.38))+'px':''; el.style.setProperty('--dx',((Math.random()-.5)*40).toFixed(0)+'px'); } /* v53-I: bigger hits pop bigger, stacked numbers fan out */ el.style.left=sp.x+'px'; el.style.top=(sp.y+dy)+'px'; document.getElementById('plates').appendChild(el); /* re-attaching restarts the rise animation */ setTimeout(()=>{ el.remove(); if(FTXT_POOL.length<32) FTXT_POOL.push(el); },1300);
}
const FTXT_POOL=[]; // v53: damage numbers reuse their nodes instead of creating one per hit
function fxShield(u,quad){ const v=G.views.get(u.id); if(!v) return; v.ring.segs.forEach((s,i)=>{ if(quad<0||quad===i) s.pulse=1; }); if(quad<0){ const c=v.root.getAbsolutePosition(); shieldDome(v,new V3(0,1,0),shCol(v)); SFX.shield(v); } }
function fxShieldBreak(u,quad){ const v=G.views.get(u.id); if(!v) return; const c=v.root.getAbsolutePosition(); const a=((quad===0?0:quad===1?90:quad===2?180:270)+unitVis(u).a)*Math.PI/180; const d=new V3(Math.cos(a),0,-Math.sin(a)); const p=c.add(d.scale(Math.max(4.2,v.L*.5)));
  const sc=shCol(v); shieldDome(v,d,sc.scale(1.6)); if(typeof shieldShatter==='function') shieldShatter(p,d,sc); burst(p,{n:40,c1:new C4(Math.min(1,sc.r+.3),Math.min(1,sc.g+.3),Math.min(1,sc.b+.3),1),c2:new C4(sc.r*.5,sc.g*.5,sc.b*.5,1),size:[.12,.4],power:[6,16]}); flash(p,5,sc,.3); const s=v.ring.segs[quad]; if(s) s.pulse=1.6; SFX.shield(p,true); }
function fxFlash(h,color){ const p=hexWorld(h.q,h.r,1); flash(p,8,hexC3(color.length===7?color:'#f0b35a')); }

// ---------- destruction ----------
G.hulks=[];
// v49: cut the dying hull into jagged sections. Triangles go to the nearest of K seed points (with noise, so the cuts are ragged), per material,
// and each section becomes its own node with an outward velocity and tumble. Wreck materials replace the live ones.
function fragmentHull(v,M,persist,opt){ opt=opt||{}; const ms=v.model.meshes.filter(m=>m&&!m.isDisposed()&&m.getTotalVertices&&m.getTotalVertices()>0&&m.getIndices()); if(!ms.length) return null;
  const L=v.L, K=opt.K||Math.max(3,Math.min(7,Math.round(2.5+Math.random()*2.5+L/16))); v.root.computeWorldMatrix(true); const inv=BABYLON.Matrix.Invert(v.root.getWorldMatrix());
  const seeds=[]; if(opt.cut){ const x0=(Math.random()-.5)*L*.3; seeds.push(new V3(x0-L*.25,0,0),new V3(x0+L*.25,0,0)); opt.cutX=x0; } else for(let k=0;k<K;k++){ const t=(k+.5)/K+(Math.random()-.5)*.6/K; seeds.push(new V3((t-.5)*L*.95,(Math.random()-.5)*v.H*.3,(Math.random()-.5)*L*.12)); }
  const nz=(x,y,z)=>Math.sin(x*1.7+y*2.3)*Math.cos(z*2.1-x*.9)+Math.sin(x*.53+z*1.31);
  const groups=[]; for(let k=0;k<K;k++) groups.push(new Map());
  for(const m of ms){ m.computeWorldMatrix(true); const W=m.getWorldMatrix().multiply(inv), P=m.getVerticesData(BABYLON.VertexBuffer.PositionKind), N=m.getVerticesData(BABYLON.VertexBuffer.NormalKind), I=m.getIndices(); if(!P||!I) continue;
    const mat=(m.material===M.win||m.material===M.eng||m.material===M.tip||(m.material&&/aiwin|aitrim/.test(m.material.name)))?M.ember:M.wreck;
    const lp=new Float32Array(P.length), ln=new Float32Array(P.length), tv=new V3(), tn=new V3(); for(let i=0;i<P.length;i+=3){ V3.TransformCoordinatesFromFloatsToRef(P[i],P[i+1],P[i+2],W,tv); lp[i]=tv.x; lp[i+1]=tv.y; lp[i+2]=tv.z; if(N){ V3.TransformNormalFromFloatsToRef(N[i],N[i+1],N[i+2],W,tn); tn.normalize(); ln[i]=tn.x; ln[i+1]=tn.y; ln[i+2]=tn.z; } }
    for(let t=0;t<I.length;t+=3){ const a=I[t]*3,b=I[t+1]*3,c=I[t+2]*3; const cx=(lp[a]+lp[b]+lp[c])/3, cy=(lp[a+1]+lp[b+1]+lp[c+1])/3, cz=(lp[a+2]+lp[b+2]+lp[c+2])/3; const jx=opt.cut?cx:cx+nz(cx*.4,cy*.4,cz*.4)*L*.05; /* a lance cut is clean */
      let best=0,bd=1e9; for(let k=0;k<K;k++){ const s0=seeds[k], d=(jx-s0.x)*(jx-s0.x)+(cy-s0.y)*(cy-s0.y)*.5+(cz-s0.z)*(cz-s0.z)*.5; if(d<bd){ bd=d; best=k; } }
      let g=groups[best].get(mat); if(!g){ g={pos:[],nor:[],idx:[]}; groups[best].set(mat,g); } const base=g.pos.length/3; for(const o of [a,b,c]){ g.pos.push(lp[o]-seeds[best].x,lp[o+1]-seeds[best].y,lp[o+2]-seeds[best].z); g.nor.push(ln[o],ln[o+1],ln[o+2]); } g.idx.push(base,base+1,base+2); } }
  const cen=v.root.getAbsolutePosition(), rot=v.root.rotation.clone(), nodes=[];
  for(let k=0;k<K;k++){ if(!groups[k].size) continue; const node=new BABYLON.TransformNode('wreckPart',G.scene); node.position=V3.TransformCoordinates(seeds[k],v.root.getWorldMatrix()); node.rotation=rot.clone();
    for(const [mat,g] of groups[k]){ if(!g.idx.length) continue; const mm=new BABYLON.Mesh('hull_wreck',G.scene), vd=new BABYLON.VertexData(); vd.positions=g.pos; vd.normals=g.nor; vd.indices=g.idx; if(typeof faceOut==='function'&&!G.diagNoFaceOut) faceOut(vd); vd.applyToMesh(mm); mm.material=mat; mm.parent=node; mm.isPickable=false; try{ castShadows(mm); }catch(e){} }
    const out=node.position.subtract(cen); out.y=0; const ol=out.length()||1; const sp=(1.6+Math.random()*2.6)*(persist?.5:1)*(1+ (K-3)*.12)*(opt.speed||1);
    node.vel=out.scale(sp/ol).add(new V3((Math.random()-.5)*1.4,persist?(Math.random()-.5)*.2:-.3-Math.random()*.6,(Math.random()-.5)*1.4)); const small=1/Math.max(1,groups[k].size);
    node.spin=new V3((Math.random()-.5)*.8,(Math.random()-.5)*.6,(Math.random()-.5)*.9).scale(1+small); nodes.push(node); }
  for(const m of ms) m.dispose(false,false); return nodes.length?nodes:null; }
async function animExplode(u){
  const v=G.views.get(u.id); if(!v||v.state!=='alive') return;
  const c=v.root.getAbsolutePosition().clone();
  if(u.isSq){ v.state='dead'; blast(c,1.2,{light:false,tint:new C3(1,.5,.18)}); juice('s',c); SFX.pop(c); disposeView(v); G.views.delete(u.id); await wait(250); return; }
  fxMark(u.isSq?'craft':'explode'); v.state='dying'; if(v.engLight){ const el=v.engLight; el.intensity=0; el.parent=null; el.position.set(0,-9000,0); (G.deadLights=G.deadLights||[]).push(el); v.engLight=null; } /* v44.1: disposing a light mid-fight re-dirties materials; it goes dark now and is freed at battle end */ (v.extras||[]).forEach(p=>p.stop()); v.plate.el.remove(); v.ring.node.dispose(false,true); v.fires.forEach(f=>f.stop()); v.fires=[];
  const L=v.L, cause=u.killCause||'blast', P3=FAC3D[v.fac]||FAC3D.hegemony;
  // v52 cause-driven deaths: a lance cuts the hull in two, torpedoes and rams blow it apart at once, gauss flays it into dissolving shards,
  // acid and spines make it sag and melt, a burn-out or a lucky battery hit just kills the lights and leaves a dark drifting hulk
  const CZ={cut:{pre:2,reactor:.55,K:0,cut:true,speed:.55},big:{pre:0,reactor:1.45,K:3,speed:1.9},flay:{pre:3,reactor:0,K:6,speed:.7,dissolve:true},melt:{pre:3,reactor:0,K:4,speed:.45,sag:true},dark:{pre:3,reactor:0,K:2,speed:.35,dark:true},blast:{pre:-1,reactor:1,K:0,speed:1}}[cause]||{pre:-1,reactor:1,K:0,speed:1};
  // v49: the hull dies in stages: a run of secondary blasts walks along it (it lurches and lists), then the reactor goes and it breaks apart
  if(CZ.pre!==0){ const pre=CZ.pre>0?CZ.pre:G.fxReduced?2:G.mobile?3:Math.round(4+Math.min(4,L/10)), preDur=(CZ.pre>0?500+L*12:700+L*14)*Math.max(.4,SPEED); const c0=c.clone();
    if(CZ.sag){ const t0=G.time, du=preDur/1000+.4, y0=v.root.position.y, sc0=v.root.scaling.clone(); const ob=G.scene.onBeforeRenderObservable.add(()=>{ if(!v.root||v.root.isDisposed()){ G.scene.onBeforeRenderObservable.remove(ob); return; } const k=clamp((G.time-t0)/du,0,1), e=k*k*(3-2*k); v.root.scaling.set(sc0.x*(1+.08*e),sc0.y*(1-.45*e),sc0.z*(1+.12*e)); v.root.position.y=y0-2.2*e; v.root.rotation.z+=.0015; if(k>=1) G.scene.onBeforeRenderObservable.remove(ob); }); } if(CZ.dark) try{ v.model.meshes.forEach(m=>{ const Mf=facMats(v.fac); if(m.material===Mf.win||m.material===Mf.eng||m.material===Mf.tip||(m.material&&/aiwin|aitrim/.test(m.material.name))) m.material=Mf.wreck; }); v.model.plumes.forEach(p=>p.setEnabled(false)); (v.model.flares||[]).forEach(p=>p.setEnabled(false)); }catch(e){}
    const walk=Math.random()<.5?1:-1; for(let i=0;i<pre;i++){ const delay=preDur*((i+.3)/pre)*(.85+Math.random()*.3); setTimeout(()=>{ try{ if(!v.root||v.root.isDisposed()) return; const hp=hullPointAt(v,walk*(-.42+.84*(i+Math.random()*.6)/pre)), p=hp.p; /* v53-I: blasts walk along the real hull surface */
        if(CZ.dissolve){ try{ arcBolt(p,toWorld(v,new V3((Math.random()-.5)*L*.9,v.H*.4,(Math.random()-.5)*L*.2)),P3.eng.scale(1.6)); sparks(p,G.mobile?8:20,8+L*.2); fxp&&fxp(p,{cell:0,size:2+L*.08,col:P3.eng.scale(1.5),dur:.4,grow:.6}); }catch(e){} v.root.rotation.z+=(Math.random()-.5)*.03; SFX.boom(.15,p); return; }
        if(CZ.sag){ try{ burst(p,{n:G.mobile?10:22,tex:G.tex.smoke,c1:new C4(.62,.72,.25,.75),c2:new C4(.3,.36,.12,.5),size:[1.2,3],life:[.9,1.8],power:[1,4],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }catch(e){} SFX.boom(.12,p); return; }
        if(CZ.dark){ sparks(p,G.mobile?6:14,6+L*.2); try{ flash(p,1.5+L*.04,new C3(1,.75,.5),.15); smokePuff(p,1,1.2+L*.03,{l0:2,l1:3}); }catch(e){} v.root.rotation.x+=(Math.random()-.5)*.05; SFX.boom(.1,p); return; }
        deathPop(v,p,hp.n,L,i,pre);
        try{ hullDecal(v,p.add(p.subtract(c0).normalize().scale(4)),true); }catch(e){}
        v.root.rotation.x+=(Math.random()-.5)*.09; v.root.rotation.z+=(Math.random()-.5)*.05; v.root.position.y-=.25; SFX.boom(.22+Math.min(.3,L/90),p); }catch(e){} },delay); }
    await wait(preDur); if(!v.root||v.root.isDisposed()) return; }
  // v44: the death plays out: the hull scorches and splits with glowing cracks, internal blasts tear through it, then the reactor goes
  try{ if(typeof shipDamageFx==='function'){ v.state='alive'; shipDamageFx(v,-1); v.state='dying'; } }catch(e){}
  if(!B.over&&cineWants('kill',null,u)){ try{ clearTimeout(G.cineTimer); fxMark('cine'); const r0=clamp(L*3.4+40,60,190), tgt=new V3(c.x,0,c.z), a0=G.ctl.a+.35; G.ctl.hold(tgt,a0,1.05,r0*.72); /* v45 kill cam: punch in on the first blasts, then drift out for the reactor */ setTimeout(()=>{ if(G.ctl.saved) G.ctl.hold(tgt,a0+.18,1.0,r0*1.05); },650*SPEED); G.cineTimer=setTimeout(()=>G.ctl.release(),2500*SPEED); }catch(e){} }
  if(CZ.reactor>0){ const nPop=Math.round((G.mobile?3:5)*Math.min(1.4,CZ.reactor)*(L>=24?1.3:1)); for(let i=0;i<nPop;i++){ if(!v.root||v.root.isDisposed()) break; const hp=hullPointAt(v,(Math.random()-.5)*.8); deathPop(v,hp.p,hp.n,L*1.15,i,nPop,true); if(i%2===0) SFX.hit(hp.p,L>=20); await wait(Math.max(45,90-i*8)); }
  } if(CZ.reactor>0&&typeof fxSprite==='function'){ fxSprite(c,L*(G.mobile?1.7:2.6)*CZ.reactor,new C3(1,.9,.75).scale(1.5),starTex(),.55,{grow:.8}); fxp(c,{cell:0,size:L*2.2,col:new C3(1,.85,.6).scale(1.6),dur:.35,grow:1.1,fade:2}); } /* one spherical flash; the flat shock ring comes once, below */
  // v49: no two deaths alike: size, colour (reactor tint per faction), off-centre fireballs and an occasional late second blast
  const VB={voidsworn:new C3(1,.62,.3),hegemony:new C3(.75,.88,1),corsair:new C3(1,.5,.25),chorus:new C3(.85,.95,.4),ithar:new C3(.8,1,.92),deathless:new C3(.45,1,.55)}[v.fac]||new C3(1,.85,.6), bs=(.8+Math.random()*.55)*CZ.reactor;
  if(CZ.reactor>0){
  flash(c,L*1.4*bs,C3.Lerp(new C3(1,.9,.7),VB,.5),.7); juice(L>=26?'xl':L>=16?'l':'m',c,{k:Math.min(1.2,CZ.reactor),col:C3.Lerp(new C3(1,.9,.7),VB,.4)}); blast(c,L*.45*bs,{ring:false,debris:true,hot:C3.Lerp(new C3(1,.88,.65),VB,.3)}); /* v53-I: the final flash goes through the tier presets */ if(typeof fireballFx==='function'&&!G.fxReduced){ fireballFx(c.add(new V3(0,1,0)),L*.42*bs,1.7); const nX=Math.floor(Math.random()*3); for(let i=0;i<nX;i++){ const off=new V3((Math.random()-.5)*L*.7,Math.random()*2,(Math.random()-.5)*L*.3); setTimeout(()=>{ try{ fireballFx(c.add(off),L*(.15+Math.random()*.15),1.2); }catch(e){} },(120+Math.random()*380)*Math.max(.4,SPEED)); } }
  if(Math.random()<.45&&!G.fxReduced) setTimeout(()=>{ try{ const q=c.add(new V3((Math.random()-.5)*L*.4,1,(Math.random()-.5)*L*.2)); flash(q,L*.9,VB.scale(1.3),.45); blast(q,L*.3,{debris:true}); SFX.boom(.8,q); juice('m',q,{noStop:true}); }catch(e){} },(500+Math.random()*500)*Math.max(.4,SPEED));
  fireball(c.add(new V3(0,1,0)),L*.35*bs,10,1.8,.6); lightFlash(c,new C3(1,.7,.4),10,L*14,1.2); sparks(c,160,30); embers(c,nq(10+L*.6,50),VB,{v0:4,v1:10+L*.3,l0:1.5,l1:3.2});
  burst(c,{n:G.mobile?30:50,tex:G.tex.smoke,c1:new C4(.5,.42,.36,.8),c2:new C4(.2,.18,.16,.6),size:[2,5],life:[1.2,2.6],power:[2,7],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true});
  shockwave(c,L*2*CZ.reactor); SFX.boom(CZ.reactor*(.25+L/24),c); /* frigates crack, capitals rumble */
  debris(c,L*Math.max(.5,CZ.reactor),v.fac); if(v.fac==='corsair'&&typeof corsairBreakup==='function') corsairBreakup(v,c,L); }
  else { // quiet deaths: no reactor fireball
    if(CZ.dissolve){ juice('m',c,{col:P3.eng}); flash(c,L*.8,P3.eng.scale(1.3),.4); shockRing(c,L*1.6,P3.eng.scale(1.2),{flat:true,dur:1,thick:.02,tilt:.4}); sparks(c,G.mobile?40:90,18); SFX.phase(c); }
    else if(CZ.sag){ juice('s',c); burst(c,{n:G.mobile?24:46,tex:G.tex.smoke,c1:new C4(.6,.7,.25,.8),c2:new C4(.25,.3,.1,.55),size:[2,5],life:[1.4,2.8],power:[1,5],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); SFX.boom(.4,c); }
    else if(CZ.dark){ sparks(c,G.mobile?20:50,10); SFX.boom(.3,c); juice('s',c); } }
  if(CZ.cut&&typeof fxStreak==='function'){ try{ const f=fwdOf(v.root.rotation.y*180/Math.PI), side=new V3(-f.z,0,f.x); for(let i=0;i<5;i++){ const q=c.add(side.scale((i/4-.5)*v.H*2.2)); fxp(q,{cell:0,size:2+L*.05,col:new C3(1,.85,.55).scale(1.8),dur:.5,grow:.5}); } flash(c,L*.7,new C3(1,.9,.7),.3); }catch(e){} }
  // v49: the hull tears into 3 to 7 jagged sections (different every time), each tumbling away on its own momentum
  const M=facMats(v.fac); wreckInterior(M); const dm=v.dmgMats; v.dmgMats=null; if(dm) setTimeout(()=>{ try{ dm.forEach(m=>m.dispose(false,false)); }catch(e){} },0);
  v.model.plumes.forEach(p=>p.dispose()); (v.model.flares||[]).forEach(p=>p.dispose()); (v.model.anim||[]).forEach(an=>an.node.dispose()); (v.stackFx||[]).forEach(ps=>ps.dispose()); v.stackFx=null; (v.fires||[]).forEach(p=>p.dispose()); v.fires=[];
  const persist=!!u.hulk; let nodes=null;
  try{ nodes=G.quality==='medium'?null:fragmentHull(v,M,persist||CZ.dark,{K:CZ.K||0,cut:CZ.cut,speed:CZ.speed}); /* v53: Medium (phones) takes the two-piece split below: no per-triangle re-cut on the frame a ship dies */ if(nodes&&CZ.dissolve) nodes.forEach(n=>{ n.dissolve={t0:G.time+.3+Math.random()*.5,dur:1.4+Math.random()*.8,col:P3.eng}; }); }catch(e){ console.warn('fragment',e); nodes=null; }
  if(!nodes){ if(v.model.toSplit){ try{ v.model.toSplit(); }catch(e){ console.error(e); } }
    for(const m of v.model.meshes){ m.material=(m.material===M.win||m.material===M.eng||m.material===M.tip||(m.material&&/aiwin|aitrim/.test(m.material.name)))?M.ember:M.wreck; m.isPickable=false; }
    const fwd=new V3(Math.cos(v.root.rotation.y),0,-Math.sin(v.root.rotation.y)); nodes=[v.model.fore,v.model.aft];
    for(const [n,sgn] of [[v.model.fore,1],[v.model.aft,-1]]){ const wp=n.getAbsolutePosition().clone(); const wr=v.root.rotation.clone(); n.parent=null; n.position=wp; n.rotation=wr.clone();
      n.vel=fwd.scale(sgn*(2.2+Math.random()*1.4)*(persist?.6:1)).add(new V3((Math.random()-.5)*1.2,persist?0:-.4-Math.random()*.4,(Math.random()-.5)*1.2)); n.spin=new V3((Math.random()-.5)*.45,(Math.random()-.5)*.35,sgn*(.2+Math.random()*.3)); } }
  for(const n of nodes){ n.ps=null; n.smk={acc:0}; }
  G.hulks.push({nodes,t0:G.time,persist:persist||CZ.dark,L,quiet:CZ.reactor===0}); v.root.dispose(true,false); v.state='hulk'; G.views.delete(u.id);
  await wait(280);
}
function updateHulks(dt){
  for(let i=G.hulks.length-1;i>=0;i--){ const h=G.hulks[i]; const age=G.time-h.t0; if(typeof hulkCookOff==='function') hulkCookOff(h,dt);
    if(age<4.5&&h.nodes.length>=2&&!G.fxReduced&&typeof fxp==='function'){ let cx=0,cy=0,cz=0; for(const n of h.nodes){ const q=n.getAbsolutePosition(); cx+=q.x; cy+=q.y; cz+=q.z; } const ctr=new V3(cx/h.nodes.length,cy/h.nodes.length,cz/h.nodes.length), Lh=h.L||14; h.ventAcc=(h.ventAcc||0)+dt*(G.mobile?18:44)*(1-age/4.5);
      while(h.ventAcc>=1){ h.ventAcc-=1; const from=h.nodes[Math.floor(Math.random()*h.nodes.length)].getAbsolutePosition(), d=ctr.subtract(from); const len=d.length()||1; const p=from.add(d.scale(Math.min(.5,(Lh*.08)/len))); // v49: fire vents from the torn faces
        fxp(p,{cell:0,size:1.2+Math.random()*1.6,col:new C3(1,.5+Math.random()*.2,.16).scale(1.4),dur:.35+Math.random()*.3,grow:.7,vel:d.scale(.5/len).add(new V3((Math.random()-.5)*2,Math.random()*1.5,(Math.random()-.5)*2)),drag:.6}); } }
    for(const n of h.nodes){ n.position.addInPlace(n.vel.scale(dt)); n.rotation.addInPlace(n.spin.scale(dt));
      if(n.dissolve&&!n.isDisposed()){ const k=(G.time-n.dissolve.t0)/n.dissolve.dur; if(k>0){ const sc=Math.max(.02,1-k); n.scaling.setAll(sc); if(typeof fxp==='function'&&Math.random()<(G.mobile?.35:.8)){ const q=n.getAbsolutePosition().add(new V3((Math.random()-.5)*(h.L||14)*.2*sc,(Math.random()-.5)*2,(Math.random()-.5)*(h.L||14)*.08)); fxp(q,{cell:0,size:.5+Math.random()*.8,col:n.dissolve.col.scale(1.6),dur:.6+Math.random()*.5,grow:.3,vel:new V3((Math.random()-.5)*.6,.6+Math.random()*1.2,(Math.random()-.5)*.6),drag:.3}); } if(k>=1){ n.getChildMeshes(false).forEach(m=>m.setEnabled(false)); n.smk=null; } } } // v52 gauss flaying: the shards burn away into motes
      if(n.smk&&!h.burnedOut){ const rate=(age<6?40:h.persist?Math.max(8,40-(age-6)*8):Math.max(0,40-(age-6)*8))*(G.mobile?.35:.7); n.smk.acc+=rate*dt; const L=h.L||14;
        while(n.smk.acc>=1){ n.smk.acc-=1; const p=n.getAbsolutePosition().add(new V3((Math.random()-.5)*L*.25,(Math.random()-.3)*L*.04,(Math.random()-.5)*L*.08)), hot=Math.random()<.35;
          fxp(p,{smoke:true,size:1.6+Math.random()*1.6,col:hot?new C3(.62,.38,.22):new C3(.3,.27,.25),alpha:.6,dur:1+Math.random()*.8,grow:1.6,vel:new V3((Math.random()-.5)*.8,.4+Math.random()*.6,(Math.random()-.5)*.8),drag:.4,fade:1.2});
          if(hot) fxp(p,{cell:0,size:1.4,col:new C3(1,.5,.18).scale(1.3),dur:.4,grow:.4}); } }
      if(h.persist){ n.vel.scaleInPlace(Math.max(0,1-dt*.9)); n.spin.scaleInPlace(Math.max(0,1-dt*.6)); if(age>6&&n.ps) n.ps.emitRate=Math.max(8,40-(age-6)*8); }
      else { n.vel.y-=dt*.08; if(age>6&&n.ps) n.ps.emitRate=Math.max(0,40-(age-6)*8); } }
    if(h.persist&&age>25&&!h.burnedOut){ h.burnedOut=true; h.nodes.forEach(n=>n.ps&&n.ps.stop()); } // permanent wrecks stop burning
    if(!h.persist&&age>22){ h.nodes.forEach(n=>{ if(n.ps){ n.ps.dispose(); } n.dispose(); }); G.hulks.splice(i,1); } }
}
function shockwave(c,size){ shockRing(c,size*1.15,new C3(1,.72,.45),{flat:true,dur:1.1,thick:.05}); }
// v45: capital-death debris lives in two shared thin-instance batches per faction (wreck + ember); no meshes or observers per death
function debBatch(fac,kind){ const B0=G.debBatches||(G.debBatches={}), k=fac+'|'+kind; let b=B0[k];
  if(!b||b.mesh.isDisposed()){ const M=facMats(fac); if(kind==='panel'||kind==='flake'){ /* A1 step 4: flat hull plates (a shed donor panel) and tiny metal flakes (rust), drawn like the other debris */
      const m=MB.CreateBox('debB_'+k,kind==='panel'?{width:1.7,height:.09,depth:1.15}:{width:.9,height:.05,depth:.6},G.scene); { const pm=new BABYLON.PBRMaterial('debPM_'+k,G.scene), grey=fac==='hegemony'; pm.albedoColor=kind==='flake'?new C3(.30,.11,.05):(grey?new C3(.30,.31,.33):new C3(.33,.12,.06)); pm.metallic=kind==='flake'?.3:.55; pm.roughness=.72; m.material=pm; } /* plain plate metal: the ship hull material carried lit window ports onto the shed panels */ m.isPickable=false; m.alwaysSelectAsActiveMesh=true;
      const cap=kind==='panel'?(G.mobile?16:32):(G.mobile?60:140); b={mesh:m,cap,items:[],buf:new Float32Array(cap*16),q:new BABYLON.Quaternion(),mt:new BABYLON.Matrix(),sv:new V3(),zero:new V3(0,0,0)}; m.thinInstanceSetBuffer('matrix',b.buf,16,false); m.thinInstanceCount=0; B0[k]=b; return b; }
    const m=MB.CreateIcoSphere('debB_'+k,{radius:.6,subdivisions:2,flat:true},G.scene); { const pp=m.getVerticesData(BABYLON.VertexBuffer.PositionKind), rr=seeded(fac.length*7+kind.length); for(let i=0;i<pp.length;i+=3){ const j=.55+rr()*.9; pp[i]*=1.5*j; pp[i+1]*=.35*(.6+rr()*.8); pp[i+2]*=1.1*j; } m.setVerticesData(BABYLON.VertexBuffer.PositionKind,pp); const nr=[]; BABYLON.VertexData.ComputeNormals(pp,m.getIndices(),nr); m.setVerticesData(BABYLON.VertexBuffer.NormalKind,nr); } /* v49: torn, jagged hull plates instead of boxes */ m.material=kind==='ember'?M.ember:M.wreck; m.isPickable=false; m.alwaysSelectAsActiveMesh=true;
    const cap=G.mobile?140:320; b={mesh:m,cap,items:[],buf:new Float32Array(cap*16),q:new BABYLON.Quaternion(),mt:new BABYLON.Matrix(),sv:new V3(),zero:new V3(0,0,0)};
    m.thinInstanceSetBuffer('matrix',b.buf,16,false); m.thinInstanceCount=0; B0[k]=b; }
  return b; }
function debrisUpdate(dt){ const B0=G.debBatches; if(!B0) return; for(const b of Object.values(B0)){ if(b.mesh.isDisposed()) continue; const its=b.items; if(!its.length&&!b.dirty) continue;
    for(let i=its.length-1;i>=0;i--){ const p=its[i]; p.age+=dt; if(p.age>9){ if(p.tr) try{ p.tr.dispose(); }catch(e){} p.dead=true; its.splice(i,1); continue; }
      p.pos.addInPlace(p.vel.scale(dt)); p.vel.scaleInPlace(1-dt*.25); p.rot.addInPlace(p.spin.scale(dt)); if(p.age>5) p.sc*=Math.max(0,1-dt*.6); }
    for(let i=0;i<its.length;i++){ const p=its[i]; BABYLON.Quaternion.RotationYawPitchRollToRef(p.rot.y,p.rot.x,p.rot.z,b.q); b.sv.set(p.s*p.sc,p.s*p.sc,p.s*p.sc); BABYLON.Matrix.ComposeToRef(b.sv,b.q,p.pos,b.mt); b.mt.copyToArray(b.buf,i*16); }
    b.mesh.thinInstanceCount=its.length; b.mesh.thinInstanceBufferUpdated('matrix'); b.dirty=its.length>0; } }
function debrisClear(){ const B0=G.debBatches; if(!B0) return; for(const b of Object.values(B0)){ b.items.forEach(p=>{ if(p.tr) try{ p.tr.dispose(); }catch(e){} p.dead=true; }); b.items.length=0; if(!b.mesh.isDisposed()){ b.mesh.thinInstanceCount=0; } } }
function debris(c,L,fac){ const n=Math.round((10+L*.8)*(G.mobile?.6:1)), hero=G.fxReduced?0:(G.quality==='medium'?3:7);
  for(let i=0;i<n;i++){ const ember=i<hero||Math.random()<.25, b=debBatch(fac,ember?'ember':'wreck'); if(b.items.length>=b.cap) b.items.shift();
    const p={pos:c.add(new V3((Math.random()-.5)*L*.4,(Math.random()-.5)*2,(Math.random()-.5)*L*.2)),vel:new V3((Math.random()-.5),(Math.random()-.3)*.6,(Math.random()-.5)).normalize().scale(4+Math.random()*16),
      rot:new V3(Math.random()*6,Math.random()*6,Math.random()*6),spin:new V3(Math.random()*4,Math.random()*4,Math.random()*4),s:.3+Math.random()*L*.06,sc:1,age:0};
    if(i<hero&&typeof debrisTrail==='function') p.tr=debrisTrail({getAbsolutePosition:()=>p.pos,isDisposed:()=>!!p.dead},3+Math.random()*2); // burning chunks trail pooled smoke
    b.items.push(p); } }
// Ithar phase jump: a flash where the ship was, then the hyperspace arrival plays at the new hex
async function animBlink(u,from){ const v=G.views.get(u.id); if(!v) return; const P=FAC3D[v.fac]||FAC3D.ithar; try{ flash(hexWorld(from.q,from.r,HOVER_Y),6+v.L*.2,P.eng.scale(1.4),.3); }catch(e){} v.arrive={t0:G.time}; try{ SFX.launch(v); }catch(e){} await wait(750*Math.max(.4,SPEED)); }
async function animNova(u,h){
  const va=G.views.get(u.id); if(!va) return;
  try{ SFX.charge(va); }catch(e){}
  await cineFrame(u,{...u,q:h.q,r:h.r,id:'__none'},'nova');
  const from=muzzles(va,'F')[0], to=hexWorld(h.q,h.r,HOVER_Y);
  flash(from,8,new C3(1,.9,.6)); SFX.boom(.6,from); addTrauma(.3);
  const core=fxp(from,{cell:5,size:2.4/.45,col:new C3(1,.85,.55).scale(2),dur:5,grow:0,fade:.01}), halo=fxp(from,{cell:0,size:7/.45,col:new C3(1,.6,.25).scale(1.4),dur:5,grow:0,fade:.01}); [core,halo].forEach(e=>{ if(e) e.hold=true; }); /* v53-I: pooled sprites, not a sphere and material */
  await tween(700,(e,k)=>{ const p=V3.Lerp(from,to,k); p.y+=Math.sin(k*Math.PI)*12; for(const x of [core,halo]) if(x) x.sp.position.copyFrom(p); if(Math.random()<.6) fxp(p,{pool:'fire',size:rr(1.4,2.2),col:new C3(1,.55,.2).scale(1.5),dur:.3,grow:.8,anim:[0,8]}); });
  for(const x of [core,halo]) if(x){ x.hold=false; x.dur=.05; x.t0=G.time; }
  flash(to,40,new C3(1,.85,.6),.9); blast(to,9,{ring:true,debris:true}); shockwave(to,HW*2.2); juice('xl',to,{sfx:()=>SFX.boom(1.5,to)});
  await wait(350);
}

// ---------- sound lives in sfx.js (SFX); this file only calls it ----------

// ---------- close action ----------
async function fxRam(u,t){ const va=G.views.get(u.id), vt=G.views.get(t.id); if(!va||!vt) return;
  const a=va.root.getAbsolutePosition(), b=vt.root.getAbsolutePosition(), p=V3.Lerp(a,b,.55); p.y+=1;
  flash(p,18,new C3(1,.8,.55),.6); explode(p,6); sparks(p,140,26);
  burst(p,{n:40,tex:G.tex.smoke,c1:new C4(.5,.45,.4,.8),c2:new C4(.2,.18,.16,.6),size:[1.5,4],life:[1,2.2],power:[2,7],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true});
  shockwave(p,24); hullDecal(vt,a,true); juice('xl',p,{sfx:()=>{ SFX.boom(1.1,p); SFX.hit(p,1); }}); const d=b.subtract(a); d.y=0; d.normalize(); vt.jolt={d:d.scale(3),t0:G.time}; va.jolt={d:d.scale(-1.2),t0:G.time}; await wait(450); }
async function fxBoard(u,t){ const va=G.views.get(u.id), vt=G.views.get(t.id); if(!va||!vt) return;
  const a=va.root.getAbsolutePosition(), b=vt.root.getAbsolutePosition(), P=FAC3D[va.fac]||FAC3D.hegemony, dir=b.subtract(a).normalize(), pods=[];
  for(let i=0;i<6;i++){ const r=torpRig(va.fac,false); r.node.scaling.setAll(.8); pods.push({r,m:r.node,off:new V3((Math.random()-.5)*6,Math.random()*3,(Math.random()-.5)*6),delay:i*.08}); } /* v53-I: pooled torpedo-body instances */
  SFX.launch(a); const t0=G.time;
  await new Promise(res=>{ const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/Math.max(.3,SPEED); let done=true;
    for(const p of pods){ const kk=clamp((k-p.delay)/.8,0,1); if(kk<1) done=false; const pos=V3.Lerp(a.add(p.off.scale(.3)),b.add(p.off.scale(.35)),kk); pos.y+=Math.sin(kk*Math.PI)*5; p.m.position.copyFrom(pos); p.m.lookAt(pos.add(dir));
      if(kk>=1&&!p.hit){ p.hit=true; p.r.node.setEnabled(false); flash(pos,2.5,new C3(1,.7,.4)); sparkSpray(pos,null,nq(8),[3,9],new C3(1,.75,.4),1); SFX.pop(pos); } }
    if(done||k>2.5){ G.scene.onBeforeRenderObservable.remove(obs); pods.forEach(p=>p.r.release()); res(); } }); });
  await wait(250); }
function onCapture(t){ const v=G.views.get(t.id); if(v){ disposeView(v); G.views.delete(t.id); } }

// ---------- objective markers ----------
function buildBeacon(h){ const c=hexWorld(h.q,h.r,0), sc=G.scene, parts=[];
  const H=18, bm=typeof beaconMesh==='function'?beaconMesh(c,H):null, Y=bm?{core:H*.95,coreD:1.7,ring:[H*.6,H*.73],pip:H*.8,pipR:2.7}:{core:16.5,coreD:2.2,ring:[12,14.5],pip:14.5,pipR:2.4}; // v53-G: the concept mast, rings and pips re-seated on it
  if(bm) parts.push(bm); else { const base=MB.CreateCylinder('bcnBase',{height:1.2,diameterTop:5,diameterBottom:7,tessellation:6},sc); base.position=c.add(new V3(0,.6,0)); base.material=facMats('hegemony').dark; parts.push(base);
  const mast=MB.CreateCylinder('bcnMast',{height:16,diameterTop:.4,diameterBottom:1.4,tessellation:6},sc); mast.position=c.add(new V3(0,8,0)); mast.material=facMats('hegemony').steel; parts.push(mast); }
  const coreM=emMat('bcnCoreM',new C3(1.4,1.2,.8)); const core=MB.CreateSphere('bcnCore',{diameter:Y.coreD,segments:12},sc); core.position=c.add(new V3(0,Y.core,0)); core.material=coreM; parts.push(core,coreM);
  const rings=[0,1].map(i=>{ const r=MB.CreateTorus('bcnRing',{diameter:5+i*3,thickness:.18,tessellation:40},sc); r.position=c.add(new V3(0,Y.ring[i],0)); const m=emMat('bcnRingM',new C3(1,.85,.5)); r.material=m; parts.push(r,m); return {r,m}; });
  const zm=emMat('bcnZoneM',new C3(1,.85,.5),.5); zm.alphaMode=BABYLON.Engine.ALPHA_ADD; zm.disableDepthWrite=true; zm.backFaceCulling=false;
  const zone=MB.CreateTorus('bcnZone',{diameter:HW*3.1,thickness:.45,tessellation:6},sc); zone.rotation.y=Math.PI/6; zone.position=c.add(new V3(0,.2,0)); zone.material=zm; G.glow.addExcludedMesh(zone); parts.push(zone,zm);
  const pips=[0,1,2].map(i=>{ const m=emMat('bcnPipM',new C3(.3,.3,.3)); const s=MB.CreateSphere('bcnPip',{diameter:.9,segments:8},sc); s.position=c.add(new V3(Math.cos(i*2.09)*Y.pipR,Y.pip,Math.sin(i*2.09)*Y.pipR)); s.material=m; parts.push(s,m); return m; });
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
  explode(c,2+v.L*.07,{light:true}); if(v.fires.length<3) addFire(v); juice('m',c,{sfx:()=>SFX.boom(.6,c)}); }

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
  const n0=G.env.length; tintHexes('blocked',hs,new C3(.78,.66,.54),true,0); const made=G.env.splice(n0); for(const m of made){ if(m instanceof BABYLON.LinesMesh){ m.alpha=.55; m.color=new C3(.74,.62,.5); } }
  /* v53: blocked hexes read as solid ground: a darker floor (alpha blended, not additive) inside a muted stone edge; the red they used to carry is
     now the enemy footprint colour, so a rock hex no longer looks like an occupied enemy hex */
  const discs=hs.map(([q,r])=>{ const d=MB.CreateDisc('bf',{radius:HS*.97,tessellation:6},G.scene); d.rotation.x=Math.PI/2; d.rotation.y=Math.PI/6; d.position=hexWorld(q,r,.12); d.bakeCurrentTransformIntoVertices(); return d; });
  const fm=BABYLON.Mesh.MergeMeshes(discs,true,true); if(fm){ fm.name='blockFloor'; const mt=new BABYLON.StandardMaterial('blockFloorM',G.scene); mt.disableLighting=true; mt.diffuseColor=C3.Black(); mt.specularColor=C3.Black(); mt.emissiveColor=new C3(.02,.016,.012); mt.alpha=.55; mt.disableDepthWrite=true; fm.material=mt; fm.isPickable=false; fm.alphaIndex=-90; try{ G.glow.addExcludedMesh(fm); }catch(e){} made.push(fm,mt); }
  G.blockTint=made; }catch(e){ console.warn(e); } }
function buildTerrainTints(){ if(!B||!B.terrain) return; const byType={}; for(const [k,t] of Object.entries(B.terrain)){ if(!TERRAIN_INFO[t]) continue; (byType[t]=byType[t]||[]).push(k.split(',').map(Number)); }
  for(const [t,hs] of Object.entries(byType)){ if(t==='rock'||t==='hulk') continue; tintHexes(t,hs,C3.FromHexString(TERRAIN_INFO[t].col),!!BLOCKING[t],.045); }
  G.blockTint=null; refreshBlockTint();
  // objective zones: breakthrough exit, transport exit, station perimeter
  const zones={}; for(const h of boardHexes()){ const z=objZone(h.q,h.r); if(z&&!blocks(terr(h.q,h.r))) (zones[z]=zones[z]||[]).push([h.q,h.r]); }
  for(const [z,hs] of Object.entries(zones)) tintHexes('zone_'+z,hs,C3.FromHexString(ZONE_INFO[z].col),false,.2);
  // v47 gravity well: the slingshot band, the pull band, and the rim that tears hulls
  if(B.well&&typeof WELL_RIM!=='undefined'){ const rim=[],pull=[],sling=[]; for(const h of boardHexes()){ if(blocks(terr(h.q,h.r))) continue; const d=hdist(h,B.well); if(d<=WELL_RIM) rim.push([h.q,h.r]); else if(d<=WELL_PULL) pull.push([h.q,h.r]); else if(d<=WELL_ASSIST) sling.push([h.q,h.r]); }
    if(rim.length) tintHexes('wellRim',rim,new C3(.95,.35,1),false,.1); if(pull.length) tintHexes('wellPull',pull,new C3(.62,.42,1),false,.04); if(sling.length) tintHexes('wellSling',sling,new C3(.45,.6,1),false,.015); } }
// v47: a ship dragged by a gravity well slides into its new hex
function fxGravPull(u,from){ const v=G.views.get(u.id); if(!v||!v.root) return; const p=hexWorld(from.q,from.r); v.slide={x:p.x,z:p.z,t0:G.time}; try{ flash(new V3(p.x,HOVER_Y,p.z),4+(v.L||8)*.3,new C3(.7,.45,1.4),.3); }catch(e){} }
