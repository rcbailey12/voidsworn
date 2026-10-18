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
function vfxLife(mesh,mat,dur,fn){ const t0=G.time, D=dur*Math.max(.3,SPEED); const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/D; if(k>=1||mesh.isDisposed()){ G.scene.onBeforeRenderObservable.remove(obs); if(!mesh.isDisposed()) mesh.dispose(); mat.dispose(); return; } fn(k); }); }
// a camera-facing sprite: stars, glows
function fxSprite(pos,size,col,tex,dur,{grow=.9,spin=0,alpha=1}={}){ try{ if(G.fxReduced){ size*=.6; col=col.scale(.6); }
    const pl=MB.CreatePlane('fxs',{size:1},G.scene); pl.position.copyFrom(pos); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; pl.isPickable=false; pl.rotation.z=Math.random()*6.28;
    const m=vfxMat('fxsM',col,tex,alpha); pl.material=m; try{ G.glow.addExcludedMesh(pl); }catch(e){}
    vfxLife(pl,m,dur,k=>{ pl.scaling.setAll(size*(.45+k*grow)); m.alpha=alpha*(1-k)*(1-k); if(spin) pl.rotation.z+=spin*.016; }); }catch(e){} }
// a quad stretched along a direction and turned to face the camera: muzzle flames, streaks
function fxStreak(pos,dir,len,wid,col,tex,dur){ try{ const pl=MB.CreatePlane('fxk',{width:1,height:1,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene); pl.bakeTransformIntoVertices(BABYLON.Matrix.Translation(.5,0,0)); pl.isPickable=false; pl.position.copyFrom(pos);
    const X=dir.normalize(), cd=G.cam.position.subtract(pos).normalize(); let Z=cd.subtract(X.scale(V3.Dot(cd,X))); if(Z.lengthSquared()<1e-4) Z=new V3(0,1,0); Z.normalize(); const Y=V3.Cross(Z,X).normalize();
    pl.rotationQuaternion=BABYLON.Quaternion.RotationQuaternionFromAxis(X,Y,Z); const m=vfxMat('fxkM',col,tex,1); pl.material=m; try{ G.glow.addExcludedMesh(pl); }catch(e){}
    vfxLife(pl,m,dur,k=>{ const e=1-Math.pow(1-k,3); pl.scaling.set(len*(.55+.6*e),wid*(.7+.5*e),1); m.alpha=Math.pow(1-k,1.6); }); }catch(e){} }

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
    const pl=MB.CreatePlane('shock',{size:2,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene); pl.isPickable=false; pl.position.copyFrom(pos);
    if(flat){ pl.rotation.x=Math.PI/2+(Math.random()-.5)*tilt; pl.rotation.z=(Math.random()-.5)*tilt; } else pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL;
    const m=new BABYLON.ShaderMaterial('shockM',G.scene,{vertex:'vsShock',fragment:'vsShock'},{attributes:['position','uv'],uniforms:['worldViewProjection','col','t','seed','thick'],needAlphaBlending:true});
    m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; m.setColor3('col',col); m.setFloat('seed',Math.random()*40); m.setFloat('thick',thick); m.setFloat('t',0); pl.material=m; try{ G.glow.addExcludedMesh(pl); }catch(e){}
    vfxLife(pl,m,dur,k=>{ m.setFloat('t',k); pl.scaling.setAll(size*(.12+Math.pow(k,.55))); }); }catch(e){ console.warn('shock',e); } }

// converging energy before a lance fires
function chargeFx(pos,col,dur=.28){ try{ if(G.fxReduced) return; const ps=new BABYLON.ParticleSystem('charge',G.quality==='medium'?24:60,G.scene); ps.particleTexture=G.tex.soft; ps.emitter=pos.clone(); ps.createSphereEmitter(4.5,0);
    ps.minEmitPower=-14; ps.maxEmitPower=-9; ps.minLifeTime=.22; ps.maxLifeTime=.32; ps.minSize=.15; ps.maxSize=.45; ps.color1=new C4(col.r,col.g,col.b,1); ps.color2=new C4(1,1,1,1); ps.colorDead=new C4(col.r,col.g,col.b,0);
    ps.blendMode=BABYLON.ParticleSystem.BLENDMODE_ONEONE; ps.emitRate=260; ps.targetStopDuration=dur; ps.disposeOnStop=true; ps.updateSpeed=.016/Math.max(.35,SPEED); ps.start();
    fxSprite(pos,4,col.scale(1.4),G.tex.flare,dur+.1,{grow:-.3}); }catch(e){} }

// debris that burns: a few chunks trail fire and smoke as they tumble away
function debrisTrail(mesh,life){ try{ const ps=new BABYLON.ParticleSystem('dtr',90,G.scene); ps.particleTexture=G.tex.smoke; ps.emitter=mesh; ps.minEmitBox=V3.Zero(); ps.maxEmitBox=V3.Zero();
    ps.color1=new C4(1,.62,.25,.9); ps.color2=new C4(.9,.35,.12,.7); ps.colorDead=new C4(.08,.07,.07,0); ps.minSize=.35; ps.maxSize=.9; ps.addSizeGradient(0,.5); ps.addSizeGradient(1,2.4);
    ps.minLifeTime=.5; ps.maxLifeTime=1.1; ps.emitRate=45; ps.minEmitPower=.1; ps.maxEmitPower=.5; ps.direction1=new V3(-.2,-.2,-.2); ps.direction2=new V3(.2,.2,.2); ps.blendMode=BABYLON.ParticleSystem.BLENDMODE_STANDARD; ps.start();
    setTimeout(()=>{ try{ ps.stop(); setTimeout(()=>ps.dispose(),1400); }catch(e){} },life*1000); return ps; }catch(e){ return null; } }

// engine plumes: white-hot core, faction-coloured sheath, shock diamonds near the nozzle, flicker
const PLUME_GLSL={vert:`precision highp float; attribute vec3 position; attribute vec3 normal; attribute vec2 uv; uniform mat4 world; uniform mat4 worldViewProjection; varying vec2 vUV; varying vec3 vN; varying vec3 vP;
    void main(){ vUV=uv; vN=normalize((world*vec4(normal,0.0)).xyz); vP=(world*vec4(position,1.0)).xyz; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  frag:`precision highp float; varying vec2 vUV; varying vec3 vN; varying vec3 vP; uniform vec3 col; uniform vec3 camPos; uniform float t; uniform float flip;
    void main(){ float v=mix(vUV.y,1.0-vUV.y,flip); vec3 V=normalize(camPos-vP); float f=abs(dot(normalize(vN),V)); float core=pow(f,2.6);
      float along=pow(v,1.5); float dia=0.5+0.5*cos((1.0-v)*34.0-t*6.0); dia=mix(1.0,0.55+0.45*dia,smoothstep(0.45,0.96,v));
      float fl=0.86+0.14*sin(t*41.0+vUV.x*25.0)*sin(t*17.0+vUV.x*9.0);
      vec3 c=mix(col,vec3(1.0,0.97,0.93),core*smoothstep(0.55,1.0,v)*0.85);
      float a=along*(0.2+0.8*core)*dia*fl;
      gl_FragColor=vec4(c*a*1.9,a); }`};
function plumeShaderMat(fac,col){ try{ const S=BABYLON.Effect.ShadersStore; if(!S.vsPlumeVertexShader){ S.vsPlumeVertexShader=PLUME_GLSL.vert; S.vsPlumeFragmentShader=PLUME_GLSL.frag; }
    const m=new BABYLON.ShaderMaterial(fac+'plumeS',G.scene,{vertex:'vsPlume',fragment:'vsPlume'},{attributes:['position','normal','uv'],uniforms:['world','worldViewProjection','col','camPos','t','flip'],needAlphaBlending:true});
    m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; m.setColor3('col',col); m.setFloat('t',0); m.setFloat('flip',0); m.setVector3('camPos',V3.Zero()); (G.plumeMats=G.plumeMats||[]).push(m); return m; }catch(e){ console.warn('plume shader',e); return null; } }
function vfxTick(){ if(G.plumeMats&&G.cam) for(const m of G.plumeMats){ m.setFloat('t',(G.time||0)%100); m.setVector3('camPos',G.cam.position); } }

// wrecks keep cooking off: small secondary explosions on fresh hulks
function hulkCookOff(h,dt){ try{ const age=G.time-h.t0; if(age>7||G.fxReduced) return; const rate=(age<2?1.6:.7)*(G.quality==='medium'?.5:1); if(Math.random()>rate*dt) return;
    const n=h.nodes[Math.floor(Math.random()*h.nodes.length)]; if(!n||n.isDisposed()) return; const L=h.L||14, p=n.getAbsolutePosition().add(new V3((Math.random()-.5)*L*.35,(Math.random()-.2)*L*.08,(Math.random()-.5)*L*.12));
    explode(p,.9+L*.04,{light:Math.random()<.3}); if(Math.random()<.4) fxSprite(p,5+L*.15,new C3(1,.7,.4),starTex(),.25); }catch(e){} }
function vfxFadeDispose(mesh,mat,dur){ try{ const a0=mat.alpha; const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/(dur*Math.max(.3,SPEED)); if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); try{ mesh.dispose(); mat.dispose(); }catch(e){} return; } mat.alpha=a0*(1-k); }); }catch(e){ try{ mesh.dispose(); }catch(_){} } }

// damaged ships spit sparks and short electrical arcs from breached plating
function damageSparks(v,hr,dt){ try{ if(hr>.55||G.fxReduced||!v.model||!v.root) return; const rate=(hr<.3?2.2:1.1)*(G.quality==='medium'?.5:1); if(Math.random()>rate*dt) return;
    const L=v.L, p=toWorld(v,new V3((Math.random()-.5)*L*.7,Math.random()*v.H*.5,(Math.random()-.5)*L*.12));
    sparks(p,G.quality==='medium'?8:16,5+Math.random()*5,new C4(1,.85,.55,1)); if(Math.random()<.45){ const q=p.add(new V3((Math.random()-.5)*3,(Math.random()-.2)*2,(Math.random()-.5)*3)); arcBolt(p,q,new C3(.6,.8,1.6)); }
    if(Math.random()<.5) fxSprite(p,2.2,new C3(1,.8,.55),starTex(),.18,{grow:.4}); }catch(e){} }
// fighter wings leave short glowing trails as they wheel around their carrier (High and Ultra)
function craftTrails(v,fac){ try{ if(G.quality==='medium'||!v.crafts) return; const P=FAC3D[fac]||FAC3D.hegemony; const m=emMat('ctrM',P.eng.scale(1.3),.5); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false;
    v.extras=v.extras||[]; for(const c of v.crafts){ const t=new BABYLON.TrailMesh('ctr',c.c.root,G.scene,.22,16,true); t.material=m; t.isPickable=false; try{ G.glow.addExcludedMesh(t); }catch(e){} v.extras.push(t); } v.extras.push({dispose:()=>m.dispose(),stop:()=>{}}); }catch(e){} }
