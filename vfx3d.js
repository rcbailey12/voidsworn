// ---------- v44 combat effects: muzzle blasts, glowing bolts, shock rings, plasma rings, burning debris, engine plumes ----------
// All generated in code. fx3d.js calls these when they exist; every one has a cheaper path on Medium and respects Reduced flashes.

// a many-pointed star burst, for muzzle blasts and impacts
function starTex(){ if(G.tex.star) return G.tex.star; G.tex.star=dynTex('starT3',256,256,(g,w)=>{ const c=w/2, img=g.createImageData(w,w), d=img.data, r=seeded(91);
    const sp=[...Array(11)].map(()=>({a:r()*6.283,l:.4+r()*.6,wd:.035+r()*.05}));
    for(let y=0;y<w;y++) for(let x=0;x<w;x++){ const dx=(x-c)/c, dy=(y-c)/c, rr=Math.hypot(dx,dy), a=Math.atan2(dy,dx); let v=Math.exp(-rr*rr*16)+Math.exp(-rr*5)*.3;
      for(const s of sp){ const da=Math.abs(((a-s.a)%6.283+9.425)%6.283-3.1416); v+=Math.exp(-da*da/(s.wd*s.wd))*Math.max(0,1-rr/s.l)*.85; }
      const o=(y*w+x)*4; d[o]=d[o+1]=d[o+2]=255; d[o+3]=Math.min(255,v*255); } g.putImageData(img,0,0); }); return G.tex.star; }
// a flame tongue that narrows at the muzzle and fans out as it fades
function coneTex(){ if(G.tex.cone) return G.tex.cone; G.tex.cone=dynTex('coneT2',256,64,(g,w,h)=>{ const img=g.createImageData(w,h), d=img.data;
    for(let y=0;y<h;y++) for(let x=0;x<w;x++){ const u=x/(w-1), v=(y-h/2)/(h/2), wd=.12+.75*Math.pow(u,.8), a=Math.pow(1-u,1.3)*Math.exp(-(v*v)/(wd*wd)*2.2)*Math.min(1,u*14);
      const o=(y*w+x)*4; d[o]=d[o+1]=d[o+2]=255; d[o+3]=Math.min(255,a*255); } g.putImageData(img,0,0); }); return G.tex.cone; }
function vfxMat(name,col,tex,alpha){ const m=new BABYLON.StandardMaterial(name,G.scene); m.disableLighting=true; m.diffuseColor=C3.Black(); m.specularColor=C3.Black(); m.emissiveColor=col; m.opacityTexture=tex; m.alpha=alpha==null?1:alpha; m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; return m; }
function vfxLife(mesh,mat,dur,fn,release){ const t0=G.time, D=dur*Math.max(.3,SPEED); const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/D; if(k>=1||mesh.isDisposed()){ G.scene.onBeforeRenderObservable.remove(obs); if(release&&!mesh.isDisposed()){ release(); return; } if(!mesh.isDisposed()) mesh.dispose(); mat.dispose(); return; } fn(k); }); }
// v45: small reuse pools for shader-material effects (mesh + material kept, hidden between uses)
function fxShPool(key,make){ const P=G.shPools||(G.shPools={}); const L=P[key]=(P[key]||[]).filter(e=>!e.mesh.isDisposed()); let e=L.find(x=>!x.busy); if(!e){ e=make(); e.busy=false; if(L.length<12) L.push(e); else e.temp=true; } e.busy=true; e.mesh.setEnabled(true);
  e.release=()=>{ if(e.temp){ e.mesh.dispose(); e.mat.dispose(); return; } e.mesh.setEnabled(false); e.busy=false; }; return e; }
// a camera-facing sprite: stars, glows
function fxSprite(pos,size,col,tex,dur,{grow=.9,spin=0,alpha=1}={}){ try{ if(G.fxReduced){ size*=.6; col=col.scale(.6); } if(G.mobile) size*=.8; fxp(pos,{cell:tex===G.tex.star?1:0,size,col,dur,grow,spin:spin*60,alpha,fade:2}); }catch(e){} }
// a flame or streak stretched along a direction (pooled sprite; v53-I: was a plane and a material per call)
function fxStreak(pos,dir,len,wid,col,tex,dur){ try{ const d=dir.clone().normalize(), e=fxp(pos,{cell:tex===G.tex.cone?10:3,size:1,col,dur,grow:.5,fade:1.6}); if(e){ alignSprite(e,pos,pos.add(d.scale(len)),wid); e.grow=.5; } }catch(e){} }

// muzzle blast: a star, a flame tongue along the barrel, a puff of smoke and a few hot fragments
function muzzleBlast(pos,out,col,big){ const s=big?1.5:1; fxSprite(pos,3.2*s,C3.Lerp(col,new C3(1,1,1),.35).scale(1.6),starTex(),.16,{grow:.6});
  fxStreak(pos,out,5.5*s,2.1*s,C3.Lerp(col,new C3(1,.85,.6),.4).scale(1.7),coneTex(),.18);
  if(G.quality!=='medium'&&!G.fxReduced) sparks(pos.add(out.scale(.6)),6,9,new C4(1,.85,.55,1));
  burst(pos.add(out.scale(1.2)),{n:5,tex:G.tex.smoke,c1:new C4(.55,.52,.5,.45),c2:new C4(.32,.3,.29,.3),size:[.6,1.2],life:[.9,1.7],power:[.6,1.8],blend:BABYLON.ParticleSystem.BLENDMODE_STANDARD,sizeGrow:true}); }

// glowing bolt material: a white-hot centre fading to the faction colour at the edges, soft-edged, additive
function boltMat(name,col){ const m=new BABYLON.StandardMaterial(name,G.scene); m.disableLighting=true; m.diffuseColor=C3.Black(); m.specularColor=C3.Black(); m.emissiveColor=col.scale(1.4);
  try{ m.emissiveFresnelParameters=new BABYLON.FresnelParameters(); m.emissiveFresnelParameters.leftColor=col.scale(.55); m.emissiveFresnelParameters.rightColor=C3.Lerp(col,new C3(1,1,1),.65).scale(2.4); m.emissiveFresnelParameters.power=1.5; m.emissiveFresnelParameters.bias=0;
    m.opacityFresnelParameters=new BABYLON.FresnelParameters(); m.opacityFresnelParameters.leftColor=C3.Black(); m.opacityFresnelParameters.rightColor=new C3(1,1,1); m.opacityFresnelParameters.power=1.1; m.opacityFresnelParameters.bias=0; }catch(e){}
  m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; return m; }

// shock ring: a thin, noisy, bright ring that races outward; flat for blasts in the battle plane, camera-facing for spherical shocks
const SHOCK_GLSL={vert:`precision highp float; attribute vec3 position; attribute vec2 uv; uniform mat4 worldViewProjection; varying vec2 vUV; void main(){ vUV=uv; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  frag:`precision highp float; varying vec2 vUV; uniform vec3 col; uniform float t; uniform float seed; uniform float thick;
    NOISE
    void main(){ vec2 p=vUV-0.5; float r=length(p)*2.0; float ang=atan(p.y,p.x); float n=fbm(vec3(cos(ang)*3.0,sin(ang)*3.0,seed+t*2.0),4);
      float w=thick*(1.0+t*1.5); float ring=exp(-pow((r-0.86+(n-0.5)*0.08)/w,2.0)); float inner=smoothstep(0.86,0.2,r)*0.18*(0.5+n);
      float fade=pow(1.0-t,1.6); float a=(ring*(0.6+0.8*n)+inner)*fade; if(r>1.0) a=0.0;
      gl_FragColor=vec4(col*a*1.5+vec3(1.0)*ring*fade*0.35*(1.0-t),a); }`};
function shockRing(pos,size,col,{flat=true,dur=1.1,thick=.05,tilt=.25}={}){ try{ if(G.fxReduced){ col=col.scale(.55); } const S=BABYLON.Effect.ShadersStore; if(!S.vsShockVertexShader){ S.vsShockVertexShader=SHOCK_GLSL.vert; S.vsShockFragmentShader=SHOCK_GLSL.frag.replace('NOISE',PLANET_GLSL.noise); }
    if(G.mobile&&G.cam){ const d=V3.Distance(G.cam.position,pos); size=Math.min(size,d*.55); } // v45: a phone never gets a half-screen ring
    const e=fxShPool('shock',()=>{ const pl=MB.CreatePlane('shock',{size:2,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene); pl.isPickable=false;
      const m=new BABYLON.ShaderMaterial('shockM',G.scene,{vertex:'vsShock',fragment:'vsShock'},{attributes:['position','uv'],uniforms:['worldViewProjection','col','t','seed','thick'],needAlphaBlending:true});
      m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; pl.material=m; try{ G.glow.addExcludedMesh(pl); }catch(e){} return {mesh:pl,mat:m}; });
    const pl=e.mesh, m=e.mat; pl.position.copyFrom(pos); pl.rotation.set(0,0,0); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_NONE;
    if(flat){ pl.rotation.x=Math.PI/2; } /* v53-I: blast rings lie flat on the board plane (tilted rings read as misaligned spirals) */ else pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL;
    m.setColor3('col',col); m.setFloat('seed',Math.random()*40); m.setFloat('thick',thick); m.setFloat('t',0); pl.scaling.setAll(size*.12);
    vfxLife(pl,m,dur,k=>{ m.setFloat('t',k); pl.scaling.setAll(size*(.12+Math.pow(k,.55))); },e.release); }catch(e){ console.warn('shock',e); } }

// converging energy before a lance fires: wfx3d chargeUp (pooled sprites)

// debris that burns: a few chunks trail fire and smoke as they tumble away
function debrisTrail(mesh,life){ try{
    if(typeof fxp==='function'&&fxPool().mgr){ const st={on:true,acc:0,t0:G.time,last:G.time}, rate=G.mobile?14:30; // v44.1: pooled smoke and embers instead of a particle system per chunk
      const obs=G.scene.onBeforeRenderObservable.add(()=>{ if(!st.on||mesh.isDisposed()||G.time-st.t0>life){ G.scene.onBeforeRenderObservable.remove(obs); return; } st.acc+=rate*Math.max(0,G.time-st.last); st.last=G.time; /* game time, like the sprite lifetimes, so a slow frame can't flood the pool */
        while(st.acc>=1){ st.acc-=1; const p=mesh.getAbsolutePosition(); fxp(p,{smoke:true,size:.7+Math.random()*.6,col:new C3(.34,.28,.24),alpha:.55,dur:.7+Math.random()*.5,grow:1.8,drag:.5,fade:1.2});
          if(Math.random()<.5) fxp(p,{cell:0,size:.9,col:new C3(1,.55,.2).scale(1.4),dur:.3,grow:.3}); } });
      return {stop(){ st.on=false; },dispose(){ st.on=false; }}; }
    return null; }catch(e){ return null; } }

// engine plumes: white-hot core, faction-coloured sheath, shock diamonds near the nozzle, flicker
const PLUME_GLSL={vert:`precision highp float; attribute vec3 position; attribute vec3 normal; attribute vec2 uv; uniform mat4 world; uniform mat4 worldViewProjection; varying vec2 vUV; varying vec3 vN; varying vec3 vP;
    void main(){ vUV=uv; vN=normalize((world*vec4(normal,0.0)).xyz); vP=(world*vec4(position,1.0)).xyz; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  frag:`precision highp float; varying vec2 vUV; varying vec3 vN; varying vec3 vP; uniform vec3 col; uniform vec3 camPos; uniform float t; uniform float flip; uniform float dirty;
    void main(){ float v=mix(vUV.y,1.0-vUV.y,flip); vec3 V=normalize(camPos-vP); float f=abs(dot(normalize(vN),V)); float core=pow(f,2.6);
      float along=pow(v,1.5); float dia=0.5+0.5*cos((1.0-v)*34.0-t*6.0); dia=mix(1.0,0.55+0.45*dia,smoothstep(0.45,0.96,v));
      float fl=0.86+0.14*sin(t*41.0+vUV.x*25.0)*sin(t*17.0+vUV.x*9.0);
      vec3 c=mix(col,vec3(1.0,0.97,0.93),core*smoothstep(0.55,1.0,v)*0.85);
      float a=along*(0.2+0.8*core)*dia*fl;
      if(dirty>0.0){ float sd=dot(vP.xz,vec2(0.071,0.053)); float sp=sin(t*9.0+sd*13.0)*sin(t*23.0+sd*7.0)*sin(t*3.7+sd*3.0);
        a*=0.35+0.65*smoothstep(-0.35,0.15,sp); a*=0.72+0.28*sin(vUV.x*18.85+t*5.0+sd*9.0); c=mix(c,c*vec3(0.55,0.33,0.28),1.0-smoothstep(0.0,0.45,v)); } // B1 A1 step 4: Corsair engines burn dirty: sputter, uneven lobes, a sooty tail
      gl_FragColor=vec4(c*a*1.9,a); }`};
function plumeShaderMat(fac,col){ try{ const S=BABYLON.Effect.ShadersStore; if(!S.vsPlumeVertexShader){ S.vsPlumeVertexShader=PLUME_GLSL.vert; S.vsPlumeFragmentShader=PLUME_GLSL.frag; }
    const m=new BABYLON.ShaderMaterial(fac+'plumeS',G.scene,{vertex:'vsPlume',fragment:'vsPlume'},{attributes:['position','normal','uv'],uniforms:['world','worldViewProjection','col','camPos','t','flip','dirty'],needAlphaBlending:true});
    m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; m.setColor3('col',col); m.setFloat('t',0); m.setFloat('flip',0); m.setFloat('dirty',fac==='corsair'?1:0); m.setVector3('camPos',V3.Zero()); (G.plumeMats=G.plumeMats||[]).push(m); return m; }catch(e){ console.warn('plume shader',e); return null; } }
function vfxTick(){ try{ fxPoolTick(); }catch(e){} if(G.plumeMats&&G.cam) for(const m of G.plumeMats){ m.setFloat('t',(G.time||0)%100); m.setVector3('camPos',G.cam.position); } }

// wrecks keep cooking off: small secondary explosions on fresh hulks
function hulkCookOff(h,dt){ try{ const age=G.time-h.t0; if(age>7||G.fxReduced) return; const rate=(age<2?1.6:.7)*(G.quality==='medium'?.5:1); if(Math.random()>rate*dt) return;
    const n=h.nodes[Math.floor(Math.random()*h.nodes.length)]; if(!n||n.isDisposed()) return; const L=h.L||14, p=n.getAbsolutePosition().add(new V3((Math.random()-.5)*L*.35,(Math.random()-.2)*L*.08,(Math.random()-.5)*L*.12));
    explode(p,.9+L*.04,{light:Math.random()<.3}); if(Math.random()<.4) fxSprite(p,5+L*.15,new C3(1,.7,.4),starTex(),.25); }catch(e){} }
function vfxFadeDispose(mesh,mat,dur){ try{ const a0=mat.alpha; const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(dur*Math.max(.3,SPEED)); if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); try{ mesh.dispose(); mat.dispose(); }catch(e){} return; } mat.alpha=a0*(1-k); }); }catch(e){ try{ mesh.dispose(); }catch(_){} } }

// damaged ships spit sparks and short electrical arcs from breached plating
function damageSparks(v,hr,dt){ try{ if(hr>.55||G.fxReduced||!v.model||!v.root) return; const rate=(hr<.3?2.2:1.1)*(G.quality==='medium'?.5:1); if(Math.random()>rate*dt) return;
    const L=v.L, sk=typeof skinPoint==='function'?skinPoint(v,null):null, p=toWorld(v,sk?sk.p:new V3((Math.random()-.5)*L*.7,Math.random()*v.H*.5,(Math.random()-.5)*L*.12)); // v53-G: sparks leave the real hull surface
    sparks(p,G.quality==='medium'?8:16,5+Math.random()*5,new C4(1,.85,.55,1)); if(Math.random()<.45){ const q=p.add(new V3((Math.random()-.5)*3,(Math.random()-.2)*2,(Math.random()-.5)*3)); arcBolt(p,q,new C3(.6,.8,1.6)); }
    if(Math.random()<.5) fxSprite(p,2.2,new C3(1,.8,.55),starTex(),.18,{grow:.4}); }catch(e){} }
// A1 step 4 (Corsair damage looks, art direction: "Corsairs shed rust and a donor panel"): on top of the shared scorch, fires and sparks,
// a Corsair hull sheds rust flakes and a panel glint below 66% hull, and a whole donor panel drifts off below 33%. One-shot bursts plus a low
// pooled trickle, so nothing builds up; panels are items in the shared debris batch (capped, gone after 9 s).
const RUST=[new C3(.42,.2,.1),new C3(.55,.3,.16),new C3(.3,.16,.1)];
function rustShed(v,n,big){ try{ const L=v.L, fb=typeof debBatch==='function'?debBatch(v.fac,'flake'):null; for(let i=0;i<n;i++){ const sk=typeof skinPoint==='function'?skinPoint(v,null):null, p=toWorld(v,sk?sk.p:new V3((Math.random()-.5)*L*.6,v.H*.3,(Math.random()-.5)*L*.12));
    if(fb&&i%2===0){ if(fb.items.length>=fb.cap) fb.items.shift(); fb.items.push({pos:p.clone(),vel:new V3((Math.random()-.5)*2.2,-.3-Math.random()*1.4,(Math.random()-.5)*2.2),rot:new V3(Math.random()*6,Math.random()*6,Math.random()*6),spin:new V3((Math.random()-.5)*9,(Math.random()-.5)*9,(Math.random()-.5)*9),s:(big?.35:.22)+Math.random()*.2,sc:1,age:3}); } /* tiny flat flakes that tumble and catch the light */
    else fxp(p,{smoke:true,size:(big?.6:.4)+Math.random()*.3,col:RUST[i%3],alpha:.5,dur:.8+Math.random()*.8,grow:.8,vel:new V3((Math.random()-.5)*1.4,-.3-Math.random()*.9,(Math.random()-.5)*1.4),drag:.4,fade:1.4}); } }catch(e){} }
function donorPanel(v,size,sp,stolen){ try{ if(typeof debBatch!=='function') return; const b=debBatch(stolen?'hegemony':v.fac,'panel'); if(b.items.length>=b.cap) b.items.shift(); /* a stolen grey plate or a rust-red one */
    const cam=G.cam&&G.cam.position, rp=v.root.getAbsolutePosition(); let sk=null; if(typeof skinPoint==='function'){ for(let k=0;k<6;k++){ const s=skinPoint(v,null); if(!s) break; const wp=toWorld(v,s.p); if(!sk||(cam&&V3.Distance(wp,cam)<V3.Distance(sk.w,cam))) sk={p:s.p,w:wp}; } } /* the shed panel leaves from the side facing the camera */
    const c=sk?sk.w:toWorld(v,new V3(0,v.H*.3,0)), out=c.subtract(rp); out.y=Math.abs(out.y)+.3;
    b.items.push({pos:c,vel:out.normalize().scale(sp||(1.5+Math.random()*2)),rot:new V3(Math.random()*6,Math.random()*6,Math.random()*6),spin:new V3((Math.random()-.5)*1.4,(Math.random()-.5)*1.4,(Math.random()-.5)*1.4),s:size,sc:1,age:0});
    if(typeof fxSprite==='function'&&!G.fxReduced) fxSprite(c,2.4,new C3(1,.85,.6),starTex(),.22,{grow:.4}); }catch(e){} }
function corsairWear(v,hr,dt){ try{ if(!v||v.fac!=='corsair'||!v.model||!v.root||v.state!=='alive') return; if(hr>.8) v.cwStage=0; const st=hr<.33?2:hr<.66?1:0; v.cwStage=v.cwStage||0;
    if(st>v.cwStage){ v.cwStage=st; if(st===1){ rustShed(v,G.quality==='medium'?8:16,false); donorPanel(v,.6+v.L*.05,1.4); } else { rustShed(v,G.quality==='medium'?12:24,true); donorPanel(v,1+v.L*.11,1.2+Math.random(),true); donorPanel(v,.6+v.L*.05,2); try{ SFX.hit(v.root.getAbsolutePosition(),false); }catch(e){} } }
    if(st>0&&Math.random()<(st===2?.9:.4)*dt) rustShed(v,1,st===2); }catch(e){} }
function corsairBreakup(v,c,L){ try{ if(v.fac!=='corsair') return; const n=G.mobile?2:3; for(let i=0;i<n;i++) donorPanel(v,.8+L*(.12+Math.random()*.06),2+Math.random()*3,i%2===0); rustShed(v,G.quality==='medium'?10:24,true); }catch(e){} } // "come apart at the welds, donor sections spinning away intact"
// fighter wings leave short glowing trails as they wheel around their carrier (High and Ultra)
function craftTrails(v,fac){ try{ if(G.quality==='medium'||!v.crafts||v.crafts.some(c=>c.c.trail)) return; /* v53-G: craft carry instanced engine trails */ const P=FAC3D[fac]||FAC3D.hegemony; const m=emMat('ctrM',P.eng.scale(1.3),.5); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false;
    v.extras=v.extras||[]; for(const c of v.crafts){ const t=new BABYLON.TrailMesh('ctr',c.c.root,G.scene,.22,16,true); t.material=m; t.isPickable=false; try{ G.glow.addExcludedMesh(t); }catch(e){} v.extras.push(t); } v.extras.push({dispose:()=>m.dispose(),stop:()=>{}}); }catch(e){} }

// ---------- turrets that track their targets (High and Ultra) ----------
// One turret mesh per faction drawn as instances (one draw call per faction), parented to each capital ship's turret hardpoints.
const TURRET_PROTO={};
function turretProto(fac){ let p=TURRET_PROTO[fac]; if(p&&!p.isDisposed()) return p; const M=facMats(fac), sc=G.scene;
  const base=MB.CreateCylinder('tb',{height:.35,diameterTop:.9,diameterBottom:1.15,tessellation:10},sc);
  const hood=MB.CreateBox('th',{width:.8,height:.4,depth:.95},sc); hood.position.set(0,.32,-.05);
  const b1=MB.CreateCylinder('tbr',{height:1.5,diameter:.13,tessellation:6},sc); b1.rotation.x=Math.PI/2; b1.position.set(.18,.34,.95);
  const b2=b1.clone('tbr2'); b2.position.x=-.18;
  p=BABYLON.Mesh.MergeMeshes([base,hood,b1,b2],true,true); p.name='turretProto_'+fac; p.material=M.dark; p.isVisible=false; p.isPickable=false; p.position.y=-9000; try{ G.glow.addExcludedMesh(p); }catch(e){} return TURRET_PROTO[fac]=p; }
function addTurrets(model,fore,fac){ try{ if(G.mobile||!fore||!model.hard||!model.hard.T||!model.hard.T.length||model.L<12) return; const P=turretProto(fac), s=Math.max(1.4,model.L*.075);
    model.turrets=model.hard.T.slice(0,3).map((pt,i)=>{ const yaw=new BABYLON.TransformNode('tyaw',G.scene); yaw.parent=fore; yaw.position=pt.clone(); yaw.position.y-=s*.25; yaw.rotation.y=Math.PI/2+(i%2?.4:-.4);
      const inst=P.createInstance('turret'); inst.parent=yaw; inst.scaling.setAll(s); inst.isPickable=false; return {yaw,inst,target:yaw.rotation.y}; }); }catch(e){ console.warn('turrets',e); } }
function aimTurrets(v,worldTarget){ try{ const T=v&&v.model&&v.model.turrets; if(!T) return; for(const t of T){ const par=t.yaw.parent; if(!par) continue; par.computeWorldMatrix(true);
      const l=V3.TransformCoordinates(worldTarget,BABYLON.Matrix.Invert(par.getWorldMatrix())).subtract(t.yaw.position); t.target=Math.atan2(l.x,l.z); } }catch(e){} }
function updateTurrets(v,dt){ const T=v&&v.model&&v.model.turrets; if(!T) return; for(const t of T){ let d=((t.target-t.yaw.rotation.y)%6.283+9.425)%6.283-3.1416; const st=Math.min(Math.abs(d),dt*2.6); t.yaw.rotation.y+=Math.sign(d)*st; } }

// ---------- v44 GPU sprite pool: hundreds of flashes, sparks and streaks in a single draw call ----------
// v53-I: four pools, each one SpriteManager (one draw), all textures generated once (cached in IndexedDB by TexCache):
//   add   additive misc atlas, 4x4 cells (wfx3d fxAtlasCanvas): 0 glow, 1 star, 2 ring, 3 streak, 4 beam line, 5 molten core, 6 corona, 7 shard,
//         8 ember, 9 arc, 10 flame tongue, 11 droplet, 12 shock ring, 13 hex static, 14 splash, 15 slag
//   fire  additive flame flipbook (the R channel of an R=flame/G=smoke atlas), played over a sprite's life
//   smoke alpha-blended smoke flipbook (the G channel, lit from its own gradient), so smoke darkens what is behind it
//   chunk alpha-blended debris silhouettes (4 cells)
// The flipbook comes from fxBookCanvas (procedural) until a rendered atlas is dropped in with fxBookLoad(url,cols,rows): same layout, same code path.
function mkPool(kind,url,cell){ const caps={add:G.mobile?700:1800,fire:G.mobile?160:420,smoke:G.mobile?240:640,chunk:G.mobile?60:180}, cap=caps[kind];
  const mgr=new BABYLON.SpriteManager('fx_'+kind,url,cap,{width:cell,height:cell},G.scene);
  mgr.blendMode=(kind==='smoke'||kind==='chunk')?BABYLON.Constants.ALPHA_COMBINE:BABYLON.Constants.ALPHA_ADD; mgr.disableDepthWrite=true; mgr.isPickable=false; mgr.renderingGroupId=1; return {mgr,cap,live:[],free:[],kind,smoke:kind==='smoke'||kind==='chunk'}; }
function fxPool(){ const P=G.fxPool; if(P&&P.scene===G.scene) return P;
  try{ try{ G.scene.setRenderingAutoClearDepthStencil(1,false,false,false); }catch(e){} /* v53-I: effect sprites draw after every transparent mesh (board plate, grid lines, rings), still depth-tested against hulls */ const A=fxAtlases(); const mk=(k,u,c)=>{ try{ return mkPool(k,u,c); }catch(e){ console.warn('fx pool '+k,e); return null; } };
    const sm=mk('smoke',A.smoke,A.cell), ch=mk('chunk',A.chunk,64), fi=mk('fire',A.fire,A.cell), add=mk('add',A.add,128); // render order: smoke, chunks, then additive fire and glow on top
    G.fxPool={scene:G.scene,mgr:add&&add.mgr,cap:add?add.cap:0,live:add?add.live:[],free:add?add.free:[],pools:[sm,ch,fi,add].filter(Boolean),add,sm,fire:fi,chunk:ch,nF:A.nF,last:G.time||0,amb:0}; return G.fxPool;
  }catch(e){ console.warn('fxPool',e); G.fxPool={scene:G.scene,mgr:null,live:[],free:[],pools:[]}; return G.fxPool; } }
// spawn one pooled sprite. size is in world units; vel moves it (grav pulls it down); ang rotates in screen space; w/h stretch it.
// pool: 'add' (default), 'fire', 'smoke', 'chunk' (smoke:true = 'smoke'); anim:[a,b] plays cells a..b over the life (flipbook pools default to the whole book);
// c2: colour at the end of life (cooling slag, embers); stick:{v,p}: rides a ship view at local point p (slag, burns, static on a hull)
function fxp(pos,{cell=0,size=1,col=WHITE3,dur=.3,grow=.8,vel=null,drag=0,spin=0,alpha=1,ang=null,w=1,h=1,fade=2,grav=0,smoke=false,pool=null,anim=null,c2=null,stick=null}={}){ const P0=fxPool(); const pk=pool||(smoke?'smoke':'add'); const P=P0[pk==='add'?'add':pk==='smoke'?'sm':pk]; if(!P||!P.mgr) return null;
  let e; if(P.live.length>=P.cap-2){ e=P.live.shift(); } else if(P.free.length) e=P.free.pop(); else e={sp:new BABYLON.Sprite('fxp',P.mgr),vel:new V3(0,0,0),c:new C4(1,1,1,1)};
  e.gen=(e.gen||0)+1; const sp=e.sp; sp.isVisible=true; const book=pk==='fire'||pk==='smoke'; e.anim=anim||(book?(pk==='smoke'?[Math.min(2,P0.nF-1),P0.nF-1]:[0,P0.nF-1]):null); sp.cellIndex=e.anim?e.anim[0]:cell;
  sp.position.copyFrom(pos); sp.angle=ang==null?Math.random()*6.283:ang; e.c.set(col.r,col.g,col.b,alpha); sp.color=e.c;
  e.t0=G.time; e.dur=Math.max(.02,dur)*Math.max(.3,SPEED); e.s0=size; e.grow=grow; e.mv=!!vel; if(vel) e.vel.copyFrom(vel); e.drag=drag; e.spin=spin; e.r=col.r; e.g=col.g; e.b=col.b; e.alpha=alpha; e.w=w; e.h=h; e.fade=fade; e.grav=grav; e.smoke=P.kind==='smoke'?2:P.kind==='chunk'?1:0; e.c2=c2; e.stick=stick; e.hold=false;
  sp.width=size*w*.45; sp.height=size*h*.45; P.live.push(e); return e; }
function fxPoolTick(){ const P=G.fxPool; if(!P||!P.mgr||P.scene!==G.scene) return; const now=G.time, dt=Math.min(.1,Math.max(0,now-P.last)); P.last=now; const sc=dt/Math.max(.3,SPEED);
  for(const Q of P.pools){ const L=Q.live; for(let i=L.length-1;i>=0;i--){ const e=L[i], sp=e.sp; if(e.hold) e.t0=now; const k=(now-e.t0)/e.dur; if(k>=1){ sp.isVisible=false; e.stick=null; L.splice(i,1); Q.free.push(e); continue; }
      const s=e.s0*(.45+k*e.grow); sp.width=s*e.w; sp.height=s*e.h; const a=e.alpha*Math.pow(1-k,e.fade); let r=e.r,g=e.g,b=e.b; if(e.c2){ r+=(e.c2.r-r)*k; g+=(e.c2.g-g)*k; b+=(e.c2.b-b)*k; }
      if(e.smoke){ e.c.r=r; e.c.g=g; e.c.b=b; e.c.a=e.smoke===2?a*Math.min(1,k*6):a; } else { e.c.r=r*a; e.c.g=g*a; e.c.b=b*a; e.c.a=a; }
      if(e.anim){ const A=e.anim, n=A[1]-A[0]; sp.cellIndex=A[0]+Math.min(n,Math.floor(Math.pow(k,.8)*(n+1))); }
      if(e.stick){ const st=e.stick, rt=st.v&&st.v.root; if(rt&&!rt.isDisposed()&&st.v.state==='alive') V3.TransformCoordinatesToRef(st.p,rt.getWorldMatrix(),sp.position); else e.stick=null; }
      else if(e.mv){ const v=e.vel; if(e.grav) v.y-=e.grav*dt; sp.position.x+=v.x*sc; sp.position.y+=v.y*sc; sp.position.z+=v.z*sc; if(e.drag){ const f=Math.max(0,1-e.drag*dt); v.x*=f; v.y*=f; v.z*=f; } } if(e.spin) sp.angle+=e.spin*dt; } }
  if(G.views) for(const v of G.views.values()) navLights(v,P);
  ambientBattle(dt); }
function navLights(v,P){ const md=v.model; if(!md||!md.nav||v.crafts) return; const dead=!v.root||v.root.isDisposed()||v.state!=='alive';
  if(!v.navSp){ if(dead) return; v.navSp=md.nav.map(n=>{ const sp=new BABYLON.Sprite('nav',P.mgr); sp.cellIndex=n.k?1:0; sp.angle=n.k?0:Math.random()*6; sp.color=new C4(0,0,0,0); return sp; }); }
  if(dead){ for(const sp of v.navSp) sp.dispose(); v.navSp=null; return; } v.root.computeWorldMatrix(true); const M=v.root.getWorldMatrix(), t=G.time, L=v.L||10, ph0=(v.bob||0);
  md.nav.forEach((n,i)=>{ const sp=v.navSp[i]; V3.TransformCoordinatesToRef(n.p,M,sp.position); let a,s;
    if(n.k){ const c=((t*.7+ph0+n.ph)%1+1)%1; a=c<.05?1:c<.1?.25:c<.15?.9:0; s=(L*.09+2.2)*(a>.5?1:.6); } else { a=.55+.25*Math.sin(t*2+i); s=L*.035+1.1; }
    sp.width=sp.height=s; sp.color.r=n.c.r*a*1.6; sp.color.g=n.c.g*a*1.6; sp.color.b=n.c.b*a*1.6; sp.color.a=a; }); }
// screen-space angle of a world direction, so streak sprites line up with what they represent
function screenAng(pos,dir){ try{ const vm=G.cam.getViewMatrix(); const a=V3.TransformCoordinates(pos,vm), b=V3.TransformCoordinates(pos.add(dir),vm); return Math.atan2(b.y/Math.max(.1,b.z)-a.y/Math.max(.1,a.z),b.x/Math.max(.1,b.z)-a.x/Math.max(.1,a.z)); }catch(e){ return 0; } }
const WHITE3=new C3(1,1,1);
// small muzzle flash for the extra barrels of a broadside
function volleyMuzzle(pos,out,col){ const hot=C3.Lerp(col,WHITE3,.5).scale(1.8); fxp(pos,{cell:1,size:2.6,col:hot,dur:.13,grow:.5}); fxp(pos.add(out.scale(.5)),{cell:0,size:2.2,col:col.scale(1.3),dur:.16,grow:.4});
  fxp(pos.add(out.scale(1.1)),{cell:3,size:3.4,col:C3.Lerp(col,new C3(1,.85,.6),.4).scale(1.5),dur:.12,grow:.6,ang:screenAng(pos,out),w:1,h:.3,fade:1.5});
  if(!G.mobile&&Math.random()<.45) fxp(pos.add(out.scale(1.6)),{cell:0,size:2.4,col:new C3(.12,.11,.1),dur:.9,grow:1.6,vel:out.scale(2.5),drag:1.5,fade:1}); }
// small hit for extra bolts: a star, a hot glow and a fan of streak sparks; on shields a coloured ring
function volleyImpact(p,col,shielded,from,sc){ const back=from?from.subtract(p).normalize():new V3(0,1,0); sc=sc||SHIELD_C;
  if(shielded){ if(Math.random()<.4) fxp(p,{cell:2,size:2.2,col:sc.scale(.9),dur:.26,grow:1.4,fade:2,alpha:.7}); fxp(p,{cell:0,size:2.8,col:sc.scale(1.1),dur:.25,grow:.6}); fxp(p,{cell:1,size:2.4,col:C3.Lerp(sc,WHITE3,.5).scale(1.6),dur:.12}); return; }
  fxp(p,{cell:1,size:3.2,col:C3.Lerp(col,WHITE3,.55).scale(1.8),dur:.14,grow:.5}); fxp(p,{cell:0,size:2.6,col:new C3(1,.62,.3).scale(1.5),dur:.32,grow:.8}); fxp(p,{cell:0,size:1.6,col:new C3(1,.9,.7).scale(1.6),dur:.08,grow:.3});
  const n=G.mobile?3:6; for(let i=0;i<n;i++){ const v=back.add(new V3(Math.random()-.5,Math.random()-.4,Math.random()-.5).scale(1.6)).normalize().scale(7+Math.random()*14);
    fxp(p,{cell:3,size:1.2+Math.random()*.8,col:new C3(1,.75+Math.random()*.2,.45).scale(1.6),dur:.35+Math.random()*.35,grow:0,vel:v,drag:2.2,ang:screenAng(p,v),w:1,h:.22,fade:1.2}); }
  if(!G.mobile&&Math.random()<.5) fxp(p.add(back.scale(.6)),{cell:0,size:3,col:new C3(.14,.12,.1),dur:1.4,grow:1.4,vel:back.scale(1.2),drag:.8,fade:1}); }
// a far-off fleet action on the skyline: flashes, tracer streaks and the odd big detonation, so the battle feels like part of a war
function ambientBattle(dt){ const P=G.fxPool; if(!P||!B||B.over||G.fxReduced) return; P.amb-=dt; if(P.amb>0) return;
  P.amb=(G.mobile?1.6:.55)*(.4+Math.random()*1.2); if(!P.front||Math.random()<.04){ const a=Math.random()*6.283; P.front={a,y:(Math.random()-.4)*260,d:900+Math.random()*700}; }
  const f=P.front, c=G.ctl?G.ctl.t:V3.Zero(), aa=f.a+(Math.random()-.5)*.5, d=f.d*(.85+Math.random()*.3); const pos=new V3(c.x+Math.cos(aa)*d,f.y+(Math.random()-.5)*90,c.z+Math.sin(aa)*d);
  const pal=[new C3(1,.6,.3),new C3(.5,.8,1),new C3(.4,1,.5),new C3(1,.45,.85)], col=pal[Math.floor(Math.random()*pal.length)];
  const big=Math.random()<.12; fxp(pos,{cell:1,size:big?70:22+Math.random()*20,col:C3.Lerp(col,WHITE3,.4).scale(big?1.1:.6),dur:big?.9:.35,grow:big?1.2:.6});
  if(big) fxp(pos,{cell:0,size:90,col:new C3(1,.55,.25).scale(.5),dur:2.2,grow:1.3,fade:1.5});
  const nT=Math.floor(Math.random()*4); for(let i=0;i<nT;i++){ const v=new V3(Math.random()-.5,(Math.random()-.5)*.3,Math.random()-.5).normalize(); const q=pos.add(v.scale(20+Math.random()*60));
    fxp(q,{cell:3,size:40+Math.random()*40,col:col.scale(.7),dur:.4+Math.random()*.4,grow:0,vel:v.scale(220),ang:screenAng(q,v),w:1,h:.12,fade:1}); } }

// point defence: the target's guns hose tracer streams at an incoming torpedo and flak pops around it
function pdFire(vt,p){ try{ if(!vt||!vt.root||vt.root.isDisposed()||G.fxReduced) return; if(Math.random()>(G.mobile?.18:.5)) return; const gl=vt.model&&vt.model.guns; if(!gl) return;
  const pool=gl.T.length?gl.T:gl.P.concat(gl.S); if(!pool.length) return; vt.root.computeWorldMatrix(true); const g=V3.TransformCoordinates(pool[Math.floor(Math.random()*pool.length)],vt.root.getWorldMatrix());
  const aim=p.add(new V3((Math.random()-.5)*5,(Math.random()-.5)*3,(Math.random()-.5)*5)), v=aim.subtract(g), d=v.length(); v.normalize(); const col=(FAC3D[vt.fac]||FAC3D.hegemony).bolt;
  fxp(g,{cell:1,size:1.6,col:C3.Lerp(col,WHITE3,.5).scale(1.5),dur:.08});
  for(let i=0;i<3;i++){ const q=g.add(v.scale(i*2.2)); fxp(q,{cell:3,size:2.6,col:col.scale(1.5),dur:Math.min(.5,d/240),grow:0,vel:v.scale(240),ang:screenAng(q,v),w:1,h:.16,fade:.6}); }
  if(Math.random()<.55){ const f=p.add(new V3((Math.random()-.5)*6,(Math.random()-.5)*4,(Math.random()-.5)*6)); fxp(f,{cell:0,size:3.2,col:new C3(1,.7,.35).scale(1.4),dur:.22,grow:.9}); fxp(f,{cell:1,size:2.4,col:new C3(1,.95,.8).scale(1.4),dur:.09}); if(!G.mobile) fxp(f,{cell:0,size:3.5,col:new C3(.12,.11,.1),dur:1.2,grow:1.3,fade:1}); } }catch(e){} }

// v44.1 warm-up: on battle start, a tiny blast far off on the skyline (it reads as the distant war) compiles the explosion, fireball, shock-ring
// and beam shaders, and every faction's wreck materials are compiled against a real hull mesh, so the first kill doesn't stall
function warmFx(){ try{ if(!G.scene||!G.cam||!B) return; fxMark('warmup'); fxPool(); try{ heatHazeOn(); }catch(e){} flashLights(); starTex(); coneTex(); scorchMat(); try{ for(const f of new Set([...G.views.values()].map(v=>v.fac))) wreckInterior(facMats(f)); }catch(e){}
    let far; try{ const eng=G.engine, ray=G.scene.createPickingRay(eng.getRenderWidth()*.62,eng.getRenderHeight()*.12,BABYLON.Matrix.Identity(),G.cam); far=ray.origin.add(ray.direction.scale(520)); }catch(e){ far=null; } // on screen (near the top) so the shaders really draw and compile
    if(!far){ const tg=G.cam.getTarget(), fwd=tg.subtract(G.cam.position); fwd.normalize(); far=G.cam.position.add(fwd.scale(520)); }
    explode(far,3,{light:false}); if(typeof fireballFx==='function') fireballFx(far,6,1);
    try{ const dn=new BABYLON.TransformNode('warmDome',G.scene); dn.position.copyFrom(far); shieldDome({root:dn,L:10,H:3,fac:'hegemony'},new V3(0,0,1),new C3(.5,.8,1)); setTimeout(()=>{ try{ dn.dispose(); }catch(e){} },2500); }catch(e){ console.warn('warm dome',e); } /* v45: shield dome shader too */
    shockRing(far,14,new C3(1,.7,.45),{flat:false,dur:.6}); lanceBeam(far,far.add(new V3(40,0,10)),new C3(.6,.8,1),.6,.3);
    try{ if(typeof beamMaterial==='function'){ const cy=MB.CreateCylinder('warmBeam',{height:1,diameter:1,tessellation:14},G.scene); cy.position.set(0,-9000,0); const bm=beamMaterial(new C3(.6,.8,1)); cy.material=bm; bm.forceCompilation(cy,()=>{ cy.dispose(); bm.dispose(); }); } }catch(e){} // a short beam can expire before its first frame on a slow device
    try{ for(const m of G.scene.meshes){ const mt=m.material; if(mt&&/^(fireM|shRipM|shockM|beamM)/.test(mt.name)&&!m.isDisposed()) mt.forceCompilation(m); } }catch(e){} // compile even if the warm-up blast lands off screen
    // decal and streak materials (scorch, ember glow, flame tongue) on a throwaway plane
    try{ const pl=MB.CreatePlane('warmPl',{size:1},G.scene); pl.position.set(0,-9000,0); pl.scaling.set(2,.5,1); pl.computeWorldMatrix(true); /* streaks are scaled unevenly, which selects a different shader variant */ const em=emMat('emberM',new C3(1.4,.55,.15),1); em.opacityTexture=G.tex.soft; em.alphaMode=BABYLON.Engine.ALPHA_ADD; em.disableDepthWrite=true;
      const vm=vfxMat('fxkM',new C3(1,.7,.4),coneTex(),1); let left=3; const done=()=>{ if(--left<=0){ pl.dispose(); em.dispose(); vm.dispose(); } };
      for(const m of [scorchMat(),em,vm]) m.forceCompilation(pl,done); }catch(e){}
    // wreck materials against both the merged live hull and the split copy a dying ship swaps to (their vertex layouts can differ)
    const facs=new Set(); for(const v of G.views.values()) if(v.model&&v.model.meshes){ facs.add(v.fac); const M=facMats(v.fac); for(const m of v.model.meshes.slice(0,2)) for(const mat of [M.wreck,M.ember]) try{ mat.forceCompilation(m); }catch(e){} }
    if(typeof debBatch==='function') for(const f of facs){ for(const kind of ['wreck','ember']){ try{ const db=debBatch(f,kind); db.buf.fill(0,0,16); db.mesh.thinInstanceCount=1; db.mesh.thinInstanceBufferUpdated('matrix'); db.dirty=true; db.mesh.material.forceCompilation(db.mesh); }catch(e){} } } // v45: the thin-instance debris variant
    if(typeof MODEL_CACHE!=='undefined') for(const [k,p] of Object.entries(MODEL_CACHE)){ const fac=k.split('|')[0]; if(!facs.has(fac)||!p||!p.root) continue; const M=facMats(fac); for(const m of p.root.getChildMeshes(false).filter(x=>x.name.includes('hull_')).slice(0,3)) for(const mat of [M.wreck,M.ember]) try{ mat.forceCompilation(m); }catch(e){} } }catch(e){ console.warn('warmFx',e); } }
