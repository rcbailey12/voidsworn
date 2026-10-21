// ======================= 3D SCENE =======================
const V3=BABYLON.Vector3, C3=BABYLON.Color3, C4=BABYLON.Color4, MB=BABYLON.MeshBuilder;
const HS=10, HW=HS*Math.sqrt(3);
const G={mobile:!!(window.matchMedia&&matchMedia('(pointer: coarse)').matches&&Math.min(innerWidth,innerHeight)<900),lastInput:0,fxReduced:!!(window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches),engine:null,scene:null,cam:null,glow:null,pipe:null,views:new Map(),env:[],ox:-HW*((BW-1)/2+.25),oz:1.5*HS*(BH-1)/2,bx:HW*BW/2+30,bz:1.5*HS*BH/2+30,home:new V3(-90,0,-10),quality:'ultra',
  
  ctl:null,time:0,shake:0,tex:{},overlay:{},sfxOn:true,cine:false,follow:false,fast:false};
function hexWorld(q,r,y=0){ return new V3(HW*(q+r/2)+G.ox, y, -1.5*HS*r+G.oz); }
function worldHex(x,z){ const r=-(z-G.oz)/(1.5*HS); const q=(x-G.ox)/HW-r/2; return cubeRound(q,r); }
function seeded(seed){ let s=seed>>>0; return ()=>{ s=(s*1664525+1013904223)>>>0; return s/4294967296; }; }
function hexC3(h){ return C3.FromHexString(h); }

function init3D(canvas){
  const engine=new BABYLON.Engine(canvas,true,{stencil:/[?&]shots/.test(location.search),antialias:true,preserveDrawingBuffer:/[?&]shots/.test(location.search)},true); /* v45: no preserved buffer or stencil unless a capture script asks for them */
  const scene=new BABYLON.Scene(engine);
  scene.clearColor=new C4(.01,.015,.03,1);
  scene.ambientColor=new C3(.2,.22,.28);
  scene.skipPointerMovePicking=true;
  const cam=new BABYLON.ArcRotateCamera('cam',-Math.PI/2,.84,290,new V3(-90,0,-10),scene);
  cam.minZ=.5; cam.maxZ=30000; cam.fov=.72; cam.lowerBetaLimit=.04; cam.upperBetaLimit=1.42;
  // lights: warm key from behind the viewer, cool fill from the far side
  const sun=new BABYLON.DirectionalLight('sun',new V3(.55,-.45,-.7).normalize(),scene); sun.intensity=3.2; /* v45: the key light comes from the visible star */ sun.diffuse=new C3(1,.86,.68); sun.specular=new C3(1,.9,.75);
  const fill=new BABYLON.DirectionalLight('fill',new V3(-.55,-.15,.8).normalize(),scene); fill.intensity=.6; /* v45: dim cool fill from the far side, so every hull has a lit side and a dark side */ fill.diffuse=new C3(.42,.72,1); fill.specular=new C3(.5,.8,1); G.rim=fill; /* cool rim against the warm key: ships read as silhouettes */
  const hemi=new BABYLON.HemisphericLight('hemi',new V3(0,1,0),scene); hemi.intensity=.1; hemi.diffuse=new C3(.4,.5,.75); hemi.groundColor=new C3(.08,.06,.12); hemi.specular=C3.Black();
  const glow=new BABYLON.GlowLayer('glow',scene,{mainTextureFixedSize:1024,blurKernelSize:48}); glow.intensity=.6;
  const pipe=new BABYLON.DefaultRenderingPipeline('pipe',true,scene,[cam]);
  pipe.samples=4; pipe.fxaaEnabled=true;
  pipe.bloomEnabled=true; pipe.bloomThreshold=.5; pipe.bloomWeight=.55; pipe.bloomKernel=72; pipe.bloomScale=.5;
  pipe.imageProcessingEnabled=true;
  const ip=pipe.imageProcessing; ip.toneMappingEnabled=true; ip.toneMappingType=BABYLON.ImageProcessingConfiguration.TONEMAPPING_ACES; ip.exposure=1.12; ip.contrast=1.42;
  { const cc=new BABYLON.ColorCurves(); cc.globalSaturation=18; cc.shadowsHue=205; cc.shadowsDensity=45; cc.shadowsSaturation=35; cc.highlightsHue=32; cc.highlightsDensity=28; cc.highlightsSaturation=25; ip.colorCurvesEnabled=true; ip.colorCurves=cc; } // cinematic grade: teal shadows, warm highlights
  ip.vignetteEnabled=true; ip.vignetteWeight=2.0; ip.vignetteColor=new C4(0,0,0,0); ip.vignetteStretch=.2;
  pipe.chromaticAberrationEnabled=false; /* v45: off on every tier */ pipe.chromaticAberration.aberrationAmount=10; pipe.chromaticAberration.radialIntensity=.8;
  pipe.grainEnabled=false; pipe.grain.intensity=5; pipe.grain.animated=true;
  pipe.sharpenEnabled=true; pipe.sharpen.edgeAmount=.22;
  Object.assign(G,{engine,scene,cam,glow,pipe,sun});
  // the shared PBR lighting table must exist before any battlefield is built, so cleanup never mistakes it for a battlefield texture
  try{ scene.environmentBRDFTexture=BABYLON.BRDFTextureTools.GetEnvironmentBRDFTexture(scene); }catch(e){}
  makeSharedTextures();
  makeSky(); makeStars(); makePlanet(); makeSunAndSky(); makeEnvProbe(); makeShadows(); makeSSAO(); setQuality(G.quality);
  G.ctl=new CamCtl(cam,canvas);
  window.addEventListener('resize',()=>engine.resize());
  // graphics context recovery (driver resets, sleep, tab eviction)
  const notice=(txt,reload)=>{ let el=document.getElementById('ctxnotice'); if(!txt){ if(el) el.remove(); return; } if(!el){ el=document.createElement('div'); el.id='ctxnotice'; el.className='hud notice'; document.body.appendChild(el); }
    el.innerHTML=txt+(reload?'<div style="margin-top:12px"><button class="primary" onclick="location.reload()">Reload</button></div>':''); };
  engine.onContextLostObservable.add(()=>{ G.ctxLost=performance.now(); notice('The graphics driver reset. Restoring the battlefield\u2026'); setTimeout(()=>{ if(G.ctxLost) notice('The graphics context could not be restored. Reload to continue; your campaign is saved at the last node.',true); },7000); });
  engine.onContextRestoredObservable.add(()=>{ G.ctxLost=0; notice(null); });
  let last=performance.now();
  scene.onBeforeRenderObservable.add(()=>{ const now=performance.now(); const raw=(now-last)/1000, dt=Math.min(.05,raw); last=now; try{ FRAMES.tick(raw); }catch(e){} const ts=typeof timeScaleNow==='function'?timeScaleNow():1, gdt=dt*ts; G.time+=gdt; /* v53-I hit-stop: game time slows for a few frames; the camera and input run on real time */ try{ G.ctl.update(dt); updateWorld(gdt); updateStorms(gdt); if(G.planet) G.planet.rotation.y+=dt*.0065; if(G.npClouds) G.npClouds.rotation.y+=dt*.016; if(G.ringNode) G.ringNode.rotation.y+=dt*.003; /* v45: one update each (was two per frame) */ if(G.traffic) for(const t of G.traffic) if(!t.root.isDisposed()) t.root.position.addInPlace(t.vel.scale(dt)); if(G.gridFar) G.gridFar.alpha=clamp((G.cam.radius-260)/240,0,1)*.6; }catch(e){ frameError(e); } });
  // phones: full rate while anything animates, ~30 fps when still, ~15 fps when idle, to save battery and heat
  ['pointerdown','pointermove','keydown','wheel'].forEach(ev=>window.addEventListener(ev,()=>{ G.lastInput=performance.now(); },{passive:true}));
  engine.runRenderLoop(()=>{ if(G.mobile){ G.fskip=(G.fskip||0)+1; const anim=typeof sceneAnimating==='function'&&sceneAnimating(); G.fullRate=anim; /* v53: every frame while anything moves; the skip only saves battery when the board is still */ const idle=!anim&&performance.now()-G.lastInput>4000&&!(typeof PROJ!=='undefined'&&PROJ.length)&&!(B&&B.busy)&&scene.particleSystems.length<=1; if(!anim&&G.fskip%(idle?4:2)) return; } try{ scene.render(); }catch(e){ frameError(e); } });
}

function noiseTex(name,size,seed,soft=.55){ return dynTex(name,size,size,(g,w)=>{ const img=g.createImageData(w,w), d=img.data;
    const hs=(x,y)=>{ const v=Math.sin(x*127.1+y*311.7+seed*13.7)*43758.5453; return v-Math.floor(v); };
    const ns=(x,y)=>{ const xi=Math.floor(x),yi=Math.floor(y),xf=x-xi,yf=y-yi,u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf); return (hs(xi,yi)*(1-u)+hs(xi+1,yi)*u)*(1-v)+(hs(xi,yi+1)*(1-u)+hs(xi+1,yi+1)*u)*v; };
    for(let y=0;y<w;y++) for(let x=0;x<w;x++){ const dx=x/w-.5, dy=y/w-.5, r=Math.hypot(dx,dy)*2; let a=.5,t=0,px=x/w*5,py=y/w*5; const wx=ns(px*.7+9,py*.7), wy=ns(px*.7,py*.7+4); px+=wx*2; py+=wy*2; for(let o=0;o<5;o++){ t+=a*ns(px,py); px*=2.05; py*=2.05; a*=.5; }
      const v=clamp((t-.35)*2.2,0,1)*Math.pow(clamp(1-r,0,1),soft); const o=(y*w+x)*4; d[o]=d[o+1]=d[o+2]=255; d[o+3]=v*255; }
    g.putImageData(img,0,0); }); }
function makeSunAndSky(){
  const sc=G.scene, dir=new V3(-.55,.45,.7).normalize(), pos=dir.scale(9000); /* v45: matches the key light */ G.sunPosW=pos.clone();
  const sun=MB.CreatePlane('sun',{size:900},sc); sun.position=pos; sun.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; sun.infiniteDistance=true; sun.isPickable=false;
  sun.material=addMat('sunM',new C3(2.2,1.9,1.5),1,G.tex.flare); G.glow.addExcludedMesh(sun); G.sunMesh=sun;
  const halo=MB.CreatePlane('sunHalo',{size:3400},sc); halo.position=pos.scale(1.001); halo.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; halo.infiniteDistance=true; halo.isPickable=false; halo.material=addMat('haloM',new C3(.55,.38,.22),.55,G.tex.soft); G.glow.addExcludedMesh(halo);
  try{ const emitter=MB.CreateBox('flareEmitter',{size:1},sc); emitter.position=pos; emitter.isVisible=false; emitter.isPickable=false; emitter.infiniteDistance=true;
    const mk=(draw)=>{ const c=document.createElement('canvas'); c.width=c.height=256; const g=c.getContext('2d'); draw(g,256); return c.toDataURL(); };
    const ringT=mk((g,w)=>{ const gr=g.createRadialGradient(w/2,w/2,w*.3,w/2,w/2,w/2); gr.addColorStop(0,'rgba(255,255,255,0)'); gr.addColorStop(.8,'rgba(255,255,255,.35)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); });
    const hexT=mk((g,w)=>{ g.fillStyle='rgba(255,255,255,.28)'; g.beginPath(); for(let i=0;i<6;i++){ const a=i*Math.PI/3; g.lineTo(w/2+Math.cos(a)*w*.45,w/2+Math.sin(a)*w*.45); } g.fill(); });
    const glowT=mk((g,w)=>{ const gr=g.createRadialGradient(w/2,w/2,0,w/2,w/2,w/2); gr.addColorStop(0,'rgba(255,255,255,.9)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); });
    const lfs=new BABYLON.LensFlareSystem('lfs',emitter,sc);
    new BABYLON.LensFlare(.35,0,new C3(1,.85,.6),glowT,lfs); /* v53-G: the small hexagonal ghosts are gone: the orange one sat on the board like a stray glowing orb in every close-up */
    new BABYLON.LensFlare(.22,.7,new C3(.5,.7,1).scale(.6),ringT,lfs); new BABYLON.LensFlare(.4,1.1,new C3(.35,.5,.9).scale(.6),ringT,lfs); G.lfs=lfs; }catch(e){ console.warn('lens flare unavailable',e); }
  const r=seeded(4), base=MB.CreatePlane('bstar',{size:1},sc); base.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; base.material=addMat('bstarM',new C3(1.4,1.4,1.5),1,G.tex.flare); base.isVisible=false; base.infiniteDistance=true; G.glow.addExcludedMesh(base);
  for(let i=0;i<60;i++){ let x,y,z,l; do{ x=r()*2-1; y=r()*2-1; z=r()*2-1; l=Math.hypot(x,y,z); }while(l>1||l<.1); const inst=base.createInstance('bs'+i); inst.position=new V3(x/l*8500,y/l*8500,z/l*8500); inst.scaling.setAll(40+Math.pow(r(),3)*260); inst.isPickable=false; inst.infiniteDistance=true; }
  const gt=dynTex('galaxy',512,512,(g,w)=>{ const c=w/2, rr=seeded(8); for(let i=0;i<9000;i++){ const arm=i%2, t=rr()*4.2, rad=t/4.2*c*.95, ang=t*1.9+arm*Math.PI+(rr()-.5)*(.6-t*.1); const px=c+Math.cos(ang)*rad+(rr()-.5)*14, py=c+Math.sin(ang)*rad*.55+(rr()-.5)*9, b=1-t/4.6;
      g.fillStyle=`rgba(${200+rr()*55|0},${190+rr()*50|0},${220+rr()*35|0},${.05+b*.12})`; g.fillRect(px,py,1+rr()*2,1+rr()*2); }
    const gr=g.createRadialGradient(c,c,0,c,c,c*.25); gr.addColorStop(0,'rgba(255,235,200,.9)'); gr.addColorStop(1,'rgba(255,235,200,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); });
  const gal=MB.CreatePlane('galaxy',{size:1500},sc); gal.position=new V3(.62,.35,-.7).normalize().scale(8800); gal.lookAt(V3.Zero()); gal.rotation.z=.6; gal.infiniteDistance=true; gal.isPickable=false; gal.material=addMat('galM',new C3(.9,.85,1),.8,gt); G.glow.addExcludedMesh(gal);
  const nts=[noiseTex('cloudA',256,1),noiseTex('cloudB',256,2,.8),noiseTex('cloudC',256,3,.4)], cols=[new C3(.35,.2,.6),new C3(.18,.3,.7),new C3(.7,.35,.25),new C3(.5,.22,.45)];
  G.clouds=[]; for(let i=0;i<(G.mobile?14:34);i++){ const a=r()*Math.PI*2, d=250+r()*900, sz=260+r()*520; const pl=MB.CreatePlane('bank',{size:sz},sc); pl.position=new V3(Math.cos(a)*d*1.2,-80-r()*380,Math.sin(a)*d); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; pl.isPickable=false;
    if(!G.mobile){ const nm=nebulaMaterial('nebM'+i,cols[i%4].scale(.9),cols[(i+1)%4].scale(1.15),.12+r()*.14,r()*20); pl.material=nm; (G.nebMats=G.nebMats||[]).push(nm); } // v42: animated emission clouds on desktop
    else { const al=.1+r()*.16; pl.material=(i<6&&typeof bakedNebulaMat==='function'&&bakedNebulaMat(i,cols[i%4].scale(.9),cols[(i+1)%4].scale(1.15),al,r()*20))||addMat('bankM',cols[i%4].scale(.9),al,nts[i%3]); if(pl.material._bake) (G.nebBaked=G.nebBaked||[]).push(pl.material); } pl.rotation.z=r()*6; /* v42: phones bake six of the cloud shaders into textures once */ G.glow.addExcludedMesh(pl); G.clouds.push(pl); }
}

function makeEnvProbe(){
  const probe=new BABYLON.ReflectionProbe('envProbe',512,G.scene,true,true); probe.position=new V3(0,60,0);
  for(const m of [G.sky,G.stars,G.planet,G.atmo,G.pring,...(G.clouds||[])]) if(m) probe.renderList.push(m);
  probe.refreshRate=BABYLON.RenderTargetTexture.REFRESHRATE_RENDER_ONCE; G.scene.environmentTexture=probe.cubeTexture; G.scene.environmentIntensity=1.4; G.probe=probe;
}
function makeShadows(){
  try{ const sg=new BABYLON.CascadedShadowGenerator(G.mobile?1024:2048,G.sun); sg.numCascades=3; sg.lambda=.82; sg.shadowMaxZ=1600; sg.stabilizeCascades=true; sg.usePercentageCloserFiltering=true;
    sg.filteringQuality=BABYLON.ShadowGenerator.QUALITY_MEDIUM; sg.darkness=.12; /* v45: darkness is the light left in shadow, so lower is darker */ sg.bias=.003; sg.normalBias=.015; G.shadow=sg; }catch(e){ console.warn('shadows unavailable',e); G.shadow=null; }
}
function makeSSAO(){
  try{ if(!BABYLON.SSAO2RenderingPipeline.IsSupported) return; const p=new BABYLON.SSAO2RenderingPipeline('ssao',G.scene,{ssaoRatio:.5,blurRatio:.5},[G.cam],true);
    p.radius=2.4; p.totalStrength=1.15; p.base=.12; p.samples=16; p.maxZ=1600; p.minZAspect=.4; p.expensiveBlur=true; G.ssao=p; }catch(e){ console.warn('ssao unavailable',e); G.ssao=null; }
}
function castShadows(mesh){ mesh.receiveShadows=true; if(G.shadow) G.shadow.addShadowCaster(mesh,false); }
// v46.1: the default pipeline (bloom, tone mapping, sharpen, FXAA) must run after ambient occlusion and god rays. Attaching those later appended them
// behind it, so they ran on the tone-mapped image and the bloom blur spread bad pixels into black squares around ships on desktop GPUs.
function orderPostFx(){ try{ const pps=(G.cam&&G.cam._postProcesses||[]).filter(Boolean), ix=n=>pps.findIndex(pp=>pp.name===n), first=pps.findIndex(pp=>pp.name==='highlights'||pp.name==='imageProcessing');
  const late=pps.findIndex((pp,i)=>i>first&&/^(ssao|blurh|blurv|vls|taa)/i.test(pp.name)); if(first>=0&&late>first&&G.pipe&&G.pipe._buildPipeline) G.pipe._buildPipeline(); }catch(e){ console.warn('post order',e); } }
function setQuality(q){
  G.quality=q; const ultra=q==='ultra', hi=q!=='medium';
  const taa=ultra&&!!G.taaOn; if(taa&&!G.taa){ try{ G.taa=new BABYLON.TAARenderingPipeline('taa',G.scene,[G.cam]); G.taa.samples=8; }catch(e){ console.warn('TAA unavailable',e); G.taaOn=false; } } if(G.taa) G.taa.isEnabled=taa;
  if(G.shadow) G.sun.shadowEnabled=hi; try{ if(G.shadow) G.shadow.filteringQuality=ultra?BABYLON.ShadowGenerator.QUALITY_HIGH:BABYLON.ShadowGenerator.QUALITY_MEDIUM; G.pipe.bloomKernel=ultra?96:hi?72:48; }catch(e){} // Ultra: softer shadows, wider bloom, up to four weapon lights
  const mgr=G.scene.postProcessRenderPipelineManager;
  try{ if(ultra&&!G.vls&&G.sunMesh){ G.vls=new BABYLON.VolumetricLightScatteringPostProcess('vls',.5,G.cam,G.sunMesh,70,BABYLON.Texture.BILINEAR_SAMPLINGMODE,G.engine,false,G.scene); G.vls.exposure=.22; G.vls.decay=.965; G.vls.weight=.5; G.vls.density=.9;
    // points and lines break the occlusion pass (no element buffer), so keep them out of it
    const skipVls=m=>{ if(!G.vls) return; if(m instanceof BABYLON.LinesMesh||(m.material&&m.material.pointsCloud)||m===G.stars||m===G.sky) G.vls.excludedMeshes.push(m); };
    G.scene.meshes.forEach(skipVls); if(!G.vlsObs) G.vlsObs=G.scene.onNewMeshAddedObservable.add(m=>setTimeout(()=>skipVls(m),0)); } else if(!ultra&&G.vls){ G.vls.dispose(G.cam); G.vls=null; if(G.vlsObs){ G.scene.onNewMeshAddedObservable.remove(G.vlsObs); G.vlsObs=null; } } /* v45: one observer, removed when god rays go */ }catch(e){ console.warn('god rays unavailable',e); G.vls=null; }
  if(G.ssao){ const want=ultra||(hi&&!G.mobile); /* v44: contact shadows between hull parts on High too (desktop) */ if(G.ssaoOn===undefined) G.ssaoOn=true; if(want&&!G.ssaoOn){ mgr.attachCamerasToRenderPipeline('ssao',G.cam); G.ssaoOn=true; } else if(!want&&G.ssaoOn){ mgr.detachCamerasFromRenderPipeline('ssao',G.cam); G.ssaoOn=false; } try{ const gb=G.scene.geometryBufferRenderer; if(gb) gb.renderList=G.ssaoOn?null:[]; }catch(e){} /* v44.1: a detached SSAO left its geometry buffer rendering every mesh every frame */ try{ G.ssao.samples=ultra?16:8; G.ssao.totalStrength=ultra?1.25:1.05; }catch(e){} }
  G.pipe.samples=hi&&!(ultra&&G.taaOn)?4:1; G.pipe.fxaaEnabled=!(ultra&&G.taaOn); G.pipe.chromaticAberrationEnabled=false; G.pipe.grainEnabled=false; G.glow.intensity=hi?.6:.45; try{ G.glow.blurKernelSize=hi?48:24; }catch(e){} /* v44.1: half the glow blur on Medium (phones) */
  const dpr=window.devicePixelRatio||1; // v42: Medium renders at about 1.5x CSS pixels (was clamped to 1x: 41% of a Pixel's resolution per axis), width capped at 720
  G.engine.setHardwareScalingLevel(q==='medium'?1/Math.max(1,Math.min(dpr,1.5,720/Math.max(320,innerWidth))):ultra&&!G.mobile&&dpr<1.5?1/Math.min(1.25,1.25*dpr):1/Math.min(2,dpr)); // Ultra supersamples 1.25x on screens below 4K
  G.pipe.sharpenEnabled=hi; G.glow.isEnabled=hi; try{ for(const M of Object.values(MATS)) for(const k of ['hull','dark','steel','trim']) if(M[k]) M[k].markAsDirty(BABYLON.Material.AllDirtyFlag); }catch(e){} // hull shading detail follows the quality level // the phone image is sharp enough now, and bloom carries the emissives
  orderPostFx();
}
// procedural normal + occlusion/roughness/metal maps derived from an albedo canvas
function mapsFromCanvas(name,src,{strength=2.4,metal=.5,rough=.55}={}){
  { const MX0=G.mobile?512:1024, W0=Math.min(src.width,MX0), cn=TexCache.get(name+'N',W0,W0), co=TexCache.get(name+'O',W0,W0);
    if(cn&&co&&cn!==true&&co!==true){ const mk=(nm,bm)=>{ const t=new BABYLON.DynamicTexture(nm,{width:W0,height:W0},G.scene,true); t.getContext().drawImage(bm,0,0,W0,W0); t.update(false); t.hasAlpha=false; return t; }; return {normal:mk(name+'N',cn),orm:mk(name+'O',co)}; } }
  const MX=G.mobile?512:1024; if(src.width>MX&&typeof document!=='undefined'){ const c=document.createElement('canvas'); c.width=c.height=MX; c.getContext('2d').drawImage(src,0,0,MX,MX); src=c; }
  const w=src.width,h=src.height, px=src.getContext('2d').getImageData(0,0,w,h).data, L=new Float32Array(w*h);
  for(let i=0;i<w*h;i++) L[i]=(px[i*4]*.3+px[i*4+1]*.59+px[i*4+2]*.11)/255;
  const nt=new BABYLON.DynamicTexture(name+'N',{width:w,height:h},G.scene,true), ot=new BABYLON.DynamicTexture(name+'O',{width:w,height:h},G.scene,true);
  const ng=nt.getContext(), og=ot.getContext(), nd=ng.createImageData(w,h), od=og.createImageData(w,h); const r=seeded(w+h);
  for(let y=0;y<h;y++){ const yu=((y-1+h)%h)*w, yd=((y+1)%h)*w, yr=y*w; for(let x=0;x<w;x++){
    const xl=(x-1+w)%w, xr=(x+1)%w; const gx=(L[yr+xl]-L[yr+xr])*strength, gy=(L[yu+x]-L[yd+x])*strength, l=Math.hypot(gx,gy,1), o=(yr+x)*4, v=L[yr+x];
    nd.data[o]=(gx/l*.5+.5)*255; nd.data[o+1]=(gy/l*.5+.5)*255; nd.data[o+2]=(1/l*.5+.5)*255; nd.data[o+3]=128+v*127;
    const edge=Math.min(1,Math.hypot(gx,gy)*.8);
    od.data[o]=Math.max(40,255*(1-edge*.8)); od.data[o+1]=clamp((rough+(.5-v)*.45+(r()-.5)*.06)*255,20,250); od.data[o+2]=clamp((metal+(v-.5)*.3)*255,0,255); od.data[o+3]=255; } }
  ng.putImageData(nd,0,0); og.putImageData(od,0,0); nt.update(false); ot.update(false); nt.hasAlpha=false; ot.hasAlpha=false; TexCache.save(name+'N',ng.canvas); TexCache.save(name+'O',og.canvas); return {normal:nt,orm:ot};
}

// ---------- shared textures ----------
// ---------- texture cache: generated textures are saved after the first launch and reloaded instantly ----------
const TexCache={ver:'v1',mem:new Map(),db:null,
  async init(){ try{ this.db=await new Promise((res,rej)=>{ const r=indexedDB.open('voidsworn-cache',1); r.onupgradeneeded=()=>r.result.createObjectStore('tex'); r.onsuccess=()=>res(r.result); r.onerror=()=>rej(r.error); r.onblocked=()=>rej(new Error('blocked')); });
      const all=await new Promise((res,rej)=>{ const out=[]; const cur=this.db.transaction('tex','readonly').objectStore('tex').openCursor(); cur.onsuccess=()=>{ const c=cur.result; if(c){ out.push([c.key,c.value]); c.continue(); } else res(out); }; cur.onerror=()=>rej(cur.error); });
      await Promise.all(all.filter(([k])=>String(k).startsWith(this.ver+'|')).map(async([k,blob])=>{ try{ this.mem.set(k,await createImageBitmap(blob)); }catch(e){} }));
    }catch(e){ this.db=null; } },
  key(name,w,h){ return this.ver+'|'+name+'|'+w+'x'+h; },
  get(name,w,h){ return this.mem.get(this.key(name,w,h)); },
  saveMs:0, saves:0, q:null, busy:false,
  // encode one queued texture per idle period, never forced, so the first launch doesn't stutter
  pump(){ if(this.busy||!this.q||!this.q.length) return; this.busy=true; const ric=window.requestIdleCallback||(f=>setTimeout(()=>f({timeRemaining:()=>10}),400));
    ric(d=>{ const job=this.q.shift(); if(!job||(d.timeRemaining&&d.timeRemaining()<6&&this.q.unshift(job))){ this.busy=false; return this.pump(); }
      job[1].toBlob(b=>{ try{ if(b) this.db.transaction('tex','readwrite').objectStore('tex').put(b,job[0]); }catch(e){} this.busy=false; setTimeout(()=>this.pump(),250); },'image/webp',.9); }); },
  save(name,cv){ const t0=performance.now(); try{ if(!this.db||!cv||cv.width<128) return; const k=this.key(name,cv.width,cv.height); if(this.mem.has(k)) return; this.mem.set(k,true);
      const snap=document.createElement('canvas'); snap.width=cv.width; snap.height=cv.height; snap.getContext('2d').drawImage(cv,0,0);
      (this.q=this.q||[]).push([k,snap]); this.pump(); }catch(e){} finally{ this.saveMs+=performance.now()-t0; this.saves++; } } };
function dynTex(name,w,h,draw){ const t=new BABYLON.DynamicTexture(name,{width:w,height:h},G.scene,true); const g=t.getContext(); const hit=TexCache.get(name,w,h);
  if(hit&&hit!==true){ g.clearRect(0,0,w,h); g.drawImage(hit,0,0,w,h); } else { draw(g,w,h); TexCache.save(name,g.canvas); }
  t.update(); t.hasAlpha=true; return t; }
function makeSharedTextures(){
  G.tex.soft=dynTex('soft',128,128,(g,w)=>{ const gr=g.createRadialGradient(w/2,w/2,0,w/2,w/2,w/2); gr.addColorStop(0,'rgba(255,255,255,1)'); gr.addColorStop(.25,'rgba(255,255,255,.55)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); });
  G.tex.flare=dynTex('flare',256,256,(g,w)=>{ const c=w/2; let gr=g.createRadialGradient(c,c,0,c,c,c); gr.addColorStop(0,'rgba(255,255,255,1)'); gr.addColorStop(.08,'rgba(255,240,210,.9)'); gr.addColorStop(.3,'rgba(255,170,80,.28)'); gr.addColorStop(1,'rgba(255,120,40,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w);
    g.globalCompositeOperation='lighter'; g.fillStyle='rgba(255,230,190,.5)'; g.fillRect(0,c-1.5,w,3); g.fillRect(c-1,0,2,w); });
  G.tex.smoke=dynTex('smoke',128,128,(g,w)=>{ const r=seeded(9); for(let i=0;i<14;i++){ const x=w*.3+r()*w*.4, y=w*.3+r()*w*.4, rad=w*(.15+r()*.2); const gr=g.createRadialGradient(x,y,0,x,y,rad); gr.addColorStop(0,'rgba(255,255,255,.35)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); } });
  G.tex.ring=dynTex('ring',256,256,(g,w)=>{ const c=w/2; const gr=g.createRadialGradient(c,c,c*.6,c,c,c); gr.addColorStop(0,'rgba(255,255,255,0)'); gr.addColorStop(.7,'rgba(255,255,255,.9)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); });
  G.tex.fan=dynTex('fan',256,256,(g,w)=>{ const c=w/2; const gr=g.createRadialGradient(c,c,0,c,c,c); gr.addColorStop(0,'rgba(255,255,255,.05)'); gr.addColorStop(.85,'rgba(255,255,255,.55)'); gr.addColorStop(.97,'rgba(255,255,255,.95)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); });
  G.tex.neb=dynTex('neb',256,256,(g,w)=>{ const r=seeded(3); for(let i=0;i<22;i++){ const x=w*.2+r()*w*.6, y=w*.2+r()*w*.6, rad=w*(.12+r()*.25); const gr=g.createRadialGradient(x,y,0,x,y,rad); gr.addColorStop(0,'rgba(255,255,255,.22)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w);} });
}
function addMat(name,color,alpha=1,tex){ const m=new BABYLON.StandardMaterial(name,G.scene); m.disableLighting=true; m.emissiveColor=color; m.diffuseColor=C3.Black(); m.specularColor=C3.Black(); m.alpha=alpha;
  if(tex){ m.opacityTexture=tex; } m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.backFaceCulling=false; m.disableDepthWrite=true; return m; }

// ---------- sky: procedural nebula shader on an infinite sphere ----------
function makeSky(){
  BABYLON.Effect.ShadersStore.skyVertexShader=`precision highp float; attribute vec3 position; uniform mat4 worldViewProjection; varying vec3 vDir; void main(){ vDir=position; gl_Position=worldViewProjection*vec4(position,1.0); }`;
  BABYLON.Effect.ShadersStore.skyFragmentShader=`precision highp float; varying vec3 vDir; uniform vec3 c1; uniform vec3 c2; uniform vec3 c3; uniform float seed;
    float hash(vec3 p){ p=fract(p*0.3183099+vec3(0.11,0.17,0.13)+seed); p*=17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
    float noise(vec3 x){ vec3 i=floor(x); vec3 f=fract(x); f=f*f*(3.0-2.0*f);
      return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
                 mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z); }
    float fbm(vec3 p){ float v=0.0; float a=0.5; for(int i=0;i<6;i++){ v+=a*noise(p); p=p*2.03+vec3(1.7,9.2,3.1); a*=0.5; } return v; }
    void main(){ vec3 d=normalize(vDir);
      float band=exp(-pow(d.y*1.35+0.3+0.25*d.x,2.0)*2.0);
      vec3 q=vec3(fbm(d*1.7+seed*3.0),fbm(d*1.7+vec3(5.2,1.3,2.8)),fbm(d*1.7+vec3(1.7,9.2,3.3)));
      float n=fbm(d*2.1+q*1.9);
      float fil=fbm(d*5.5+q*3.0+vec3(3.0));
      float dust=fbm(d*3.4+q*1.4+vec3(7.0,2.0,1.0));
      float neb=smoothstep(0.36,0.88,n)*(0.28+0.95*band);
      float fl=pow(smoothstep(0.5,0.78,fil),2.2)*neb;
      vec3 col=vec3(0.005,0.008,0.018)+c1*neb*0.55+c2*pow(neb,2.0)*0.95+c3*pow(neb,4.0)*1.6*band+mix(c1,c3,0.4)*fl*0.9;
      col*=1.0-smoothstep(0.48,0.78,dust)*0.8*smoothstep(0.1,0.5,neb+band*0.4);
      col+=vec3(0.02,0.022,0.035)*band;
      vec3 cell=floor(d*380.0); float h=hash(cell); float cl=smoothstep(0.55,0.9,fbm(d*6.0+vec3(2.0)))*band;
      float st=step(0.9975-cl*0.004,h)*(0.4+0.6*hash(cell+1.7)); col+=vec3(0.9,0.93,1.0)*st*(0.35+band*0.8);
      vec3 c2=floor(d*900.0); float h2=hash(c2); col+=vec3(0.75,0.8,1.0)*step(0.9965,h2)*0.35*(0.3+band);
      gl_FragColor=vec4(col,1.0); }`;
  const sky=MB.CreateSphere('sky',{diameter:20000,segments:24,sideOrientation:BABYLON.Mesh.BACKSIDE},G.scene);
  const m=new BABYLON.ShaderMaterial('skyM',G.scene,{vertex:'sky',fragment:'sky'},{attributes:['position'],uniforms:['worldViewProjection','c1','c2','c3','seed']});
  m.setColor3('c1',new C3(.13,.26,.6)); m.setColor3('c2',new C3(.62,.22,.45)); m.setColor3('c3',new C3(1,.64,.36)); m.setFloat('seed',.37);
  m.backFaceCulling=false; sky.material=m; sky.infiniteDistance=true; sky.isPickable=false; G.glow.addExcludedMesh(sky); G.sky=sky; G.skyMat=m;
}
function makeStars(){
  BABYLON.Effect.ShadersStore.starVertexShader=`precision highp float; attribute vec3 position; attribute vec4 color; uniform mat4 worldViewProjection; uniform float scale; varying vec4 vC; void main(){ vC=color; gl_Position=worldViewProjection*vec4(position,1.0); gl_PointSize=color.a*scale; }`;
  BABYLON.Effect.ShadersStore.starFragmentShader=`precision highp float; varying vec4 vC; void main(){ gl_FragColor=vec4(vC.rgb,1.0); }`;
  const n=5200, pos=[], col=[], r=seeded(11);
  for(let i=0;i<n;i++){ let x,y,z,l; do{ x=r()*2-1; y=r()*2-1; z=r()*2-1; l=x*x+y*y+z*z; }while(l>1||l<.01); l=Math.sqrt(l);
    pos.push(x/l*9000,y/l*9000,z/l*9000); const t=r(), b=.35+Math.pow(r(),3)*1.4;
    const c=t<.12?[1,.78,.55]:t<.3?[.7,.8,1]:[1,.96,.9]; col.push(c[0]*b,c[1]*b,c[2]*b, r()<.04?2.4:r()<.3?1.6:1.1); }
  const m=new BABYLON.Mesh('stars',G.scene); const vd=new BABYLON.VertexData(); vd.positions=pos; vd.colors=col; vd.indices=[...Array(n).keys()]; vd.applyToMesh(m);
  const mat=new BABYLON.ShaderMaterial('starM',G.scene,{vertex:'star',fragment:'star'},{attributes:['position','color'],uniforms:['worldViewProjection','scale']});
  mat.pointsCloud=true; mat.setFloat('scale',Math.max(1,Math.min(2.2,window.devicePixelRatio||1))); m.material=mat; m.infiniteDistance=true; m.isPickable=false; G.glow.addExcludedMesh(m); G.stars=m;
}
function makePlanet(){ // v42: a procedural planet shader (bands, continents, ice, clouds, city lights, limb scattering) replaces the painted texture
  const p=MB.CreateSphere('planet',{diameter:2600,segments:64},G.scene);
  p.position=new V3(5200,-5600,11800); p.rotation.set(.35,-.6,.18);
  const m=planetMaterial('planetM'); m.setFloat('oct',G.mobile?4:6); p.material=m; p.isPickable=false;
  const at=MB.CreateSphere('atmo',{diameter:2690,segments:48},G.scene); at.position=p.position.clone(); at.isPickable=false; at.material=atmoMaterial('atmoM');
  G.glow.addExcludedMesh(p); G.glow.addExcludedMesh(at); G.planet=p; G.atmo=at; setPlanetLook(PLANET_LOOKS[0],.37,null);
  // a thin ring system
  const ring=MB.CreateDisc('pring',{radius:2340,tessellation:128,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene);
  ring.position=p.position.clone(); ring.rotation.set(Math.PI/2-.28,0,.2); ring.isPickable=false;
  const rt=dynTex('ringTex',512,512,(g,w)=>{ const c=w/2; for(let i=0;i<90;i++){ const rr=c*(.62+i/90*.37); g.strokeStyle=`rgba(230,205,160,${(.05+Math.random()*.22)*(i%11===0?.2:1)})`; g.lineWidth=c*.37/90+.6; g.beginPath(); g.arc(c,c,rr,0,Math.PI*2); g.stroke(); } });
  const rm=new BABYLON.StandardMaterial('pringM',G.scene); rm.diffuseTexture=rt; rm.opacityTexture=rt; rm.specularColor=C3.Black(); rm.emissiveColor=new C3(.18,.15,.12); rm.backFaceCulling=false; ring.material=rm; G.glow.addExcludedMesh(ring); G.pring=ring;
}

// ---------- per-battle environment: grid, asteroids, nebulae, dust ----------
// an exception inside a frame must never stop the render loop (Babylon does not catch it): report at most every 10 s and keep drawing
function frameError(e){ try{ console.error(e); const now=performance.now(); if(now-(G.lastFrameErr||-1e9)>10000){ G.lastFrameErr=now; if(typeof reportError==='function') reportError('frame: '+(e&&e.message||e),e&&e.stack); }
    // a broken mesh would fail every frame and freeze the screen: find it, repair or hide it, and record which one it was
    if(now-(G.lastHeal||-1e9)>500){ G.lastHeal=now; const fixed=healScene(); if(fixed.length&&typeof tel==='function') tel('scene_heal',{msg:String(e&&e.message||e).slice(0,80),meshes:fixed.slice(0,8)}); } }catch(_){} }
function healScene(){ const out=[]; if(!G.scene) return out;
  for(const m of G.scene.meshes.slice()){ try{
      if(!m.isEnabled()) continue; // disabled templates are never drawn
      const inst=m instanceof BABYLON.InstancedMesh, src=inst?m.sourceMesh:m;
      if(inst&&(!src||src.isDisposed())){ out.push(m.name+':orphan'); m.setEnabled(false); m.isVisible=false; continue; }
      const subs=src.subMeshes||[]; if(!subs.some(sm=>!sm.getBoundingInfo())) continue;
      try{ if(src.getTotalVertices()>0) src.refreshBoundingInfo(true); }catch(_){}
      if(subs.some(sm=>!sm.getBoundingInfo())){ out.push(m.name+':hidden'); m.setEnabled(false); m.isVisible=false; } else out.push(m.name+':refreshed');
    }catch(err){ try{ out.push((m.name||'?')+':error'); m.setEnabled(false); }catch(_){} } }
  return out; }
function clearEnv(){ for(const m of G.env) m.dispose(); G.env=[]; for(const m of G.blockTint||[]) try{ m.dispose(); }catch(e){} G.blockTint=[]; for(const t of G.envTex||[]) t.dispose(); G.envTex=[];
  const brdf=G.scene&&G.scene.environmentBRDFTexture; if(brdf&&!brdf.getInternalTexture()) G.scene.environmentBRDFTexture=null; } // PBR rebuilds the lookup table if it was lost
function cachedTextures(){ const keep=new Set(Object.values(G.tex)); const sc=G.scene; for(const t of [sc.environmentBRDFTexture,sc.environmentTexture,G.probe&&G.probe.cubeTexture]) if(t) keep.add(t); sc.textures.forEach(t=>{ if(/brdf/i.test(t.name||'')) keep.add(t); }); for(const M of Object.values(MATS)) for(const m of Object.values(M)) if(m&&m.getActiveTextures) m.getActiveTextures().forEach(t=>keep.add(t)); return keep; }
// each enemy faction's space has its own colour: the sky nebula is re-tinted per battle and reseeded so its shape changes too
const BIOMES={voidsworn:[[.13,.26,.6],[.62,.22,.45],[1,.64,.36]], hegemony:[[.08,.2,.42],[.22,.42,.72],[.85,.93,1]], corsair:[[.32,.12,.06],[.8,.32,.1],[1,.74,.34]],
  chorus:[[.16,.36,.16],[.6,.18,.56],[.9,1,.5]], ithar:[[.04,.26,.32],[.38,.18,.7],[.7,.95,1]], deathless:[[.06,.22,.15],[.16,.52,.34],[.6,1,.72]]};
function applyBiome(fac){ try{ const b=BIOMES[fac]||BIOMES.voidsworn, m=G.skyMat, k=G.mobile?.8:1.0; /* v52: backdrop ~30% darker so hulls, hexes and fire own the contrast (was .95/1.45) */ if(G.sun){ const warm=new C3(1,.86,.68), st=new C3(...b[2]); G.sun.diffuse=C3.Lerp(warm,st,.35); G.sun.specular=C3.Lerp(new C3(1,.9,.75),st,.3); const hm=G.scene.getMaterialByName('haloM'); if(hm&&hm.emissiveColor) hm.emissiveColor=C3.Lerp(new C3(.55,.38,.22),st.scale(.5),.5); } /* v45: each battle's star tints the key light */ if(!m) return; m.setColor3('c1',new C3(...b[0]).scale(k)); m.setColor3('c2',new C3(...b[1]).scale(k)); m.setColor3('c3',new C3(...b[2]).scale(k*1.1)); m.setFloat('seed',.1+Math.random()*.8);
  if(G.nebMats) G.nebMats.forEach((nm,i)=>{ nm.setColor3('ca',new C3(...b[i%2]).scale(.62)); nm.setColor3('cb',new C3(...b[(i+1)%3]).scale(.76)); nm.setFloat('seed',Math.random()*20); });
  if(G.nebBaked) G.nebBaked.forEach((nm,i)=>rebakeNebula(nm,new C3(...b[i%2]).scale(.62),new C3(...b[(i+1)%3]).scale(.76),Math.random()*20));
  composeBackdrop(fac); }catch(e){ console.warn(e); } } // v42: each battle also gets its own planet and re-coloured nebula banks
// light the grid up around a hex (the selected ship); with no focus the whole grid stays a faint wash
function gridFocus(c,R){ const g=G.grid; if(!g||g.isDisposed()||!G.gridHexes) return; R=R||6; const key=c?c.q+','+c.r+','+R:'none'; if(G.gridKey===key) return; G.gridKey=key;
  const cols=new Float32Array(G.gridHexes.length*28); let o=0;
  for(const h of G.gridHexes){ let a=.13; if(c){ const d=hdist(h,c); a=d<=R?.5-.34*(d/R):Math.max(.1,.16-.02*(d-R)); } /* v53: the grid never fades out (was .075 / .06) */ for(let i=0;i<7;i++){ cols[o++]=.5; cols[o++]=.82; cols[o++]=1; cols[o++]=a; } }
  try{ g.updateVerticesData(BABYLON.VertexBuffer.ColorKind,cols); }catch(e){ console.warn(e); } }
function buildBattleEnv(){ G.rockPending=false;
  clearEnv(); const texBefore=new Set(G.scene.textures); applyBiome(B&&B.cfg&&B.cfg.fac);
  const sc=G.scene;
  // holographic tactical layer: a faint cyan grid that lights up around the selected ship, and a glowing frame on the board edge
  G.gridFar=null; G.gridHexes=[]; const lines=[], colors=[];
  for(const h of boardHexes()){ const c=hexWorld(h.q,h.r,0); const pts=[];
    for(let i=0;i<7;i++){ const a=Math.PI/180*(60*i-30); pts.push(new V3(c.x+HS*.96*Math.cos(a),.02,c.z+HS*.96*Math.sin(a))); }
    lines.push(pts); colors.push(pts.map(()=>new C4(.5,.82,1,.08))); G.gridHexes.push(h); }
  const grid=MB.CreateLineSystem('grid',{lines,colors,useVertexAlpha:true,updatable:true},sc); grid.isPickable=false; grid.alpha=1; G.env.push(grid); G.grid=grid; G.gridKey=null;
  { const fr=[]; for(const h of G.gridHexes){ const c=hexWorld(h.q,h.r,0);
      for(let i=0;i<6;i++){ const a0=Math.PI/180*(60*i-30), a1=Math.PI/180*(60*(i+1)-30), mx=(Math.cos(a0)+Math.cos(a1))/2, mz=(Math.sin(a0)+Math.sin(a1))/2; const out=worldHex(c.x+mx*HS*1.6,c.z+mz*HS*1.6);
        if(onBoard(out.q,out.r)) continue; fr.push([new V3(c.x+HS*Math.cos(a0),.05,c.z+HS*Math.sin(a0)),new V3(c.x+HS*Math.cos(a1),.05,c.z+HS*Math.sin(a1))]); } }
    const fm=MB.CreateLineSystem('frame',{lines:fr},sc); fm.color=new C3(.45,.85,1); fm.alpha=.75; fm.isPickable=false; G.env.push(fm); }
  // v47: a smoked-glass plate under the board, so the grid, move highlights and ships stay readable over bright planets, rings and nebulae
  { const discs=boardHexes().map(h=>{ const d=MB.CreateDisc('ul',{radius:HS*1.02,tessellation:6},sc); d.rotation.x=Math.PI/2; d.rotation.y=Math.PI/6; d.position=hexWorld(h.q,h.r,-.4); d.bakeCurrentTransformIntoVertices(); return d; });
    const ul=BABYLON.Mesh.MergeMeshes(discs,true,true); if(ul){ ul.name='boardUnder'; const um=new BABYLON.StandardMaterial('boardUnderM',sc); um.diffuseColor=C3.Black(); um.specularColor=C3.Black(); um.emissiveColor=new C3(.008,.016,.03); um.disableLighting=true; um.alpha=G.boardDim!=null?G.boardDim:.6; /* v53: darker smoked glass (was .36) so the grid reads over bright nebula and planets */ um.disableDepthWrite=false; um.backFaceCulling=false; /* writes depth: far nebula cards drawn after it stay behind the plate */
      ul.material=um; ul.isPickable=false; ul.alphaIndex=-100; try{ G.glow.addExcludedMesh(ul); if(G.vls) G.vls.excludedMeshes.push(ul); }catch(e){} G.env.push(ul,um); G.boardUnder=ul; } }
  // asteroids
  const rockMat=new BABYLON.StandardMaterial('rockM',sc); const RK=(typeof ROCK_KINDS!=='undefined'&&B&&B.biome&&ROCK_KINDS[B.biome.rock])||null; // v47: the sector's asteroid type
  rockMat.diffuseTexture=(G.tex.rockTex&&!G.tex.rockTex._disposed&&G.tex.rockTex.getInternalTexture())?G.tex.rockTex:G.tex.rockTex=dynTex('rockTex',256,256,(g,w)=>{ /* v53: built once (it is seeded), not every battle */ const r=seeded(5); g.fillStyle='#5d544c'; g.fillRect(0,0,w,w); for(let i=0;i<900;i++){ const s=r()*6+1; g.fillStyle=`rgba(${r()<.5?'20,16,14':'150,140,125'},${r()*.35})`; g.fillRect(r()*w,r()*w,s,s);} });
  rockMat.diffuseTexture.hasAlpha=false; rockMat.specularColor=new C3(.035,.035,.035); if(G.tex.rockNrm&&G.tex.rockNrm.getInternalTexture()) rockMat.bumpTexture=G.tex.rockNrm; else { const rm=mapsFromCanvas('rockMaps',rockMat.diffuseTexture.getContext().canvas,{strength:5}); rm.orm.dispose(); rockMat.bumpTexture=G.tex.rockNrm=rm.normal; } rockMat.bumpTexture.level=.7; if(typeof addRockFx==='function') addRockFx(rockMat); G.env.push(rockMat);
  if(RK){ rockMat.diffuseColor=new C3(RK.col[0],RK.col[1],RK.col[2]); const sk=RK.spec>.3?.3:.15; /* v52: matte regolith, not wet coal (ice keeps some gloss); v53: no sparkle at all on iron (was .7/.35) */ rockMat.specularColor=new C3(RK.spec*sk,RK.spec*sk,RK.spec*sk*1.05); rockMat.specularPower=RK.spec>.3?14:6; if(RK.em) rockMat.emissiveColor=new C3(RK.em[0],RK.em[1],RK.em[2]); }
  // v44: rocks are smooth-shaded, multi-octave and cratered (were faceted 'crumpled paper' icospheres)
  // v49 asteroids: two sets of eight shapes (dense ones for the asteroids on the board, light ones for small chunks, the belt and the distance),
  // each a lumpy fBm body with ridges, boulder bumps and overlapping craters
  const vn=(x,y,z,sd)=>{ const h=(i,j,k)=>{ let n=(i*374761393+j*668265263+k*1440662683+sd*974711)|0; n=(n^(n>>>13))*1274126177|0; return ((n^(n>>>16))>>>0)/4294967296; };
    const xi=Math.floor(x),yi=Math.floor(y),zi=Math.floor(z),xf=x-xi,yf=y-yi,zf=z-zi,u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf),w=zf*zf*(3-2*zf), L=(a,b,t)=>a+(b-a)*t;
    return L(L(L(h(xi,yi,zi),h(xi+1,yi,zi),u),L(h(xi,yi+1,zi),h(xi+1,yi+1,zi),u),v),L(L(h(xi,yi,zi+1),h(xi+1,yi,zi+1),u),L(h(xi,yi+1,zi+1),h(xi+1,yi+1,zi+1),u),v),w)*2-1; };
  const mkBase=(k,sub,tag)=>{ const rr=seeded(100+k); const m=MB.CreateIcoSphere('rockBase'+tag+k,{radius:1,subdivisions:sub,flat:false},sc);
    const p=m.getVerticesData(BABYLON.VertexBuffer.PositionKind), sd=k*31+7, cr=[]; const ncr=6+Math.floor(rr()*8);
    for(let i=0;i<ncr;i++){ const u=rr()*2-1,t=rr()*6.28,q=Math.sqrt(1-u*u); cr.push([q*Math.cos(t),u,q*Math.sin(t),.12+rr()*.32,.04+rr()*.09]); }
    const sx=[1.35,1,1.6,1.1,.9,1.25,1.8,1.05][k], sy=[.78,.9,.7,1,.85,.6,.65,.95][k], sz=[1,1.15,.9,1.25,1,1.1,.8,1.3][k];
    for(let i=0;i<p.length;i+=3){ const x=p[i],y=p[i+1],z=p[i+2]; let n=1, amp=.32, f=1.3;
      for(let o=0;o<5;o++){ n+=amp*vn(x*f+o*7.1,y*f-o*3.3,z*f+o*5.7,sd); amp*=.5; f*=2.1; }
      n+=.06*(1-Math.abs(vn(x*5.5,y*5.5,z*5.5,sd+3)))-.03; // ridges
      for(const [cx,cy,cz,r0,d0] of cr){ const d=Math.hypot(x-cx,y-cy,z-cz); if(d<r0) n-=d0*(1-d/r0)*(1-d/r0)*2.2; else if(d<r0*1.35) n+=d0*.35*(1-(d-r0)/(r0*.35)); }
      p[i]=x*n*sx; p[i+1]=y*n*sy; p[i+2]=z*n*sz; }
    m.setVerticesData(BABYLON.VertexBuffer.PositionKind,p); const nr=[]; BABYLON.VertexData.ComputeNormals(p,m.getIndices(),nr); m.setVerticesData(BABYLON.VertexBuffer.NormalKind,nr);
    m.material=rockMat; m.isVisible=false; m.isPickable=false; castShadows(m); G.glow.addExcludedMesh(m); G.env.push(m); return m; };
  const bases=[]; for(let k=0;k<4;k++) bases.push(mkBase(k,G.mobile?5:7,'lo')); /* v53: the soft noise shapes only dress the distance now (the board's rocks are faceted blockers, mkFacet), so four light ones and no hi set */
  const tinyB=[0,1,2].map(i=>mkBase([0,2,5][i],G.mobile?3:4,'tiny')); // the 2,500-rock background ring and belt stay light (thin instances)
  G.rocks=[];
  const rr=seeded(B.seed||42);
  // v53 two-class rocks. An asteroid hex blocks movement and fire, so it gets tall, faceted, clearly solid rock (a tilted pillar or slab standing
  // well above the hulls, or a cluster of mediums, or a boulder in a rubble drift) cut from icospheres by flat planes; the recipe is rolled per hex
  // from B.seed. Dressing (rim fill, the deep field, the belt) stays soft, low, sparse and darker, and never sits on a playable hex.
  const blockMat=rockMatLike(rockMat,'blockRockM'); blockMat.diffuseColor=rockMat.diffuseColor.scale(.6); blockMat.specularColor=rockMat.specularColor.scale(.25); blockMat.specularPower=6; blockMat.emissiveColor=rockMat.emissiveColor.scale(.6); blockMat.bumpTexture=rockMat.bumpTexture; G.env.push(blockMat); /* the clone carries the RockFx plugin, like rimRockM */
  const libSet=ROCK_SET[B.biome&&B.biome.rock]||'RST', libReady=!!ROCK_LIB.sets[libSet]; let fb=null; if(libReady) try{ fb=rockLibMeshes(ROCK_LIB.sets[libSet]); }catch(e){ console.warn('rock library meshes',e); }
  if(!fb) fb=[0,1,2,3,4,5,6].map(k=>mkFacet(k,blockMat)); const fbuf=fb.map(()=>[]); /* sculpted rocks when this kind is loaded, procedural until then */
  const fput=(k,x,y,z,s,ax,az,yaw,tx,tz)=>fbuf[k].push(BABYLON.Matrix.Compose(new V3(s*ax*(.86+rr()*.28),s,s*az*(.86+rr()*.28)),BABYLON.Quaternion.RotationYawPitchRoll(yaw,tx,tz),new V3(x,y,z)));
  const tilt=()=>(rr()-.5)*.44, around=(c,rad,f)=>{ const a=rr()*6.28, d=rad*(.6+rr()*.4); f(c.x+Math.cos(a)*d,c.z+Math.sin(a)*d); };
  const rockHex=(c,q,r)=>{ const pick=rr(), j=()=>(rr()-.5)*3;
    if(pick<.36){ fput(rr()<.5?0:1,c.x+j(),2.1,c.z+j(),6.6+rr()*1.1,.9+rr()*.3,.9+rr()*.3,rr()*6.28,tilt(),tilt()); /* hero pillar: top ~7.5, about 1.5x a hull's height */
      for(let i=0,n=2+Math.floor(rr()*2);i<n;i++) around(c,5.6,(x,z)=>fput(3+Math.floor(rr()*2)*3,x,.6+rr()*.8,z,1.8+rr()*1.2,1,1,rr()*6.28,rr()*6,rr()*6)); }
    else if(pick<.6){ fput(2,c.x+j(),1.9,c.z+j(),6.2+rr()*1,1,1,rr()*6.28,tilt()*.7,tilt()); /* standing slab */
      for(let i=0;i<2;i++) around(c,5.4,(x,z)=>fput(i?6:4,x,.5+rr(),z,1.9+rr()*1.1,1,1,rr()*6.28,rr()*6,rr()*6)); }
    else if(pick<.85){ around(c,2.8,(x,z)=>fput(1,x,1.2,z,5.4+rr()*.8,1,1,rr()*6.28,tilt(),tilt())); around(c,3.6,(x,z)=>fput(3,x,1.4,z,3.1+rr()*.6,1,1,rr()*6.28,rr()*6,rr()*6)); /* a cluster of mediums */
      around(c,3.8,(x,z)=>fput(5,x,1.6,z,4.4+rr()*.8,1,1,rr()*6.28,(rr()-.5)*.9,(rr()-.5)*.9)); around(c,5.8,(x,z)=>fput(4,x,.4,z,1.6+rr()*.8,1,1,rr()*6.28,rr()*6,rr()*6)); }
    else { fput(6,c.x+j(),1.9,c.z+j(),5.4+rr()*.8,1.05,1,rr()*6.28,rr()*6,rr()*6); /* a boulder in a rubble drift */
      for(let i=0;i<5;i++) around(c,6.2,(x,z)=>fput(3+Math.floor(rr()*2),x,-.4+rr()*1.2,z,.9+rr()*.9,1,1,rr()*6.28,rr()*6,rr()*6)); }
    for(let i=0;i<3;i++){ const D=DIRS[i]; if(B.terrain[(q+D[0])+','+(r+D[1])]!=='rock') continue; const o=hexWorld(q+D[0],r+D[1]); fput(3+Math.floor(rr()*2)*3,(c.x+o.x)/2+(rr()-.5)*2,.6+rr(),(c.z+o.z)/2+(rr()-.5)*2,2+rr()*1.2,1,1,rr()*6.28,rr()*6,rr()*6); } }; // neighbouring rock hexes knit into a wall
  for(const [k,t] of Object.entries(B.terrain)){ const [q,r]=k.split(',').map(Number); const c=hexWorld(q,r);
    if(t==='rock') rockHex(c,q,r);
    if(t==='neb'){ for(let i=0;i<(G.mobile?2:3);i++){ const pl=MB.CreatePlane('neb',{size:(22+rr()*14)*(G.mobile?1.15:1)},sc); pl.position=c.add(new V3((rr()-.5)*8,1+rr()*6,(rr()-.5)*8)); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; pl.isPickable=false;
        const nm=addMat('nebM',rr()<.5?new C3(.42,.25,.62):new C3(.25,.35,.7),.34,G.tex.neb); pl.material=nm; pl.rotation.z=rr()*6; G.glow.addExcludedMesh(pl); G.env.push(pl,nm); } } }
  // distant decorative rocks below and around the table for depth
  fb.forEach((m,k)=>{ if(!fbuf[k].length) return; m.isVisible=true; m.thinInstanceAdd(fbuf[k]); m.thinInstanceRefreshBoundingInfo(false); }); /* one draw per shape for every blocker on the board */
  G.rockPending=!libReady; /* v53.8: the battle cover waits for the sculpted set too */
  if(!libReady){ const b0=B; loadRockSet(libSet).then(list=>{ if(B!==b0||!fb||!fb[0]||fb[0].isDisposed()){ G.rockPending=false; return; } const lib=rockLibMeshes(list), tex=[]; lib.forEach(m=>m.material.getActiveTextures().forEach(t=>{ if(!tex.includes(t)) tex.push(t); }));
      BABYLON.Texture.WhenAllReady(tex,()=>{ if(B!==b0||lib[0].isDisposed()){ G.rockPending=false; return; } lib.forEach((m,k)=>{ if(!fbuf[k].length) return; m.isVisible=true; m.thinInstanceAdd(fbuf[k]); m.thinInstanceRefreshBoundingInfo(false); fb[k].setEnabled(false); }); G.rockPending=false; }); }).catch(()=>{ G.rockPending=false; }); } // swap in place once the sculpted set and its maps have arrived
  { const dm=rockMatLike(rockMat,'dressRockM'); dm.diffuseColor=rockMat.diffuseColor.scale(.55); dm.specularColor=C3.Black(); dm.emissiveColor=rockMat.emissiveColor.scale(.4); G.env.push(dm); const buf=bases.map(()=>[]); /* v53: the deep field is thin instances (was 70 spinning instances) */
    for(let i=0;i<70;i++){ const a=rr()*Math.PI*2, d=G.bx*.9+rr()*380, s=2+rr()*12; buf[Math.floor(rr()*bases.length)].push(BABYLON.Matrix.Compose(new V3(s,s,s),BABYLON.Quaternion.RotationYawPitchRoll(rr()*6,rr()*6,rr()*6),new V3(Math.cos(a)*d*1.15,-50-rr()*200,Math.sin(a)*d*.8))); }
    bases.forEach((m,k)=>{ if(!buf[k].length) return; m.material=dm; m.isVisible=true; m.thinInstanceAdd(buf[k]); m.thinInstanceRefreshBoundingInfo(false); m.receiveShadows=false; try{ if(G.shadow) G.shadow.removeShadowCaster(m); }catch(e){} }); }
  { const ring=tinyB[0].clone('rockRing'); ring.isVisible=true; ring.material=rockMat; ring.isPickable=false; G.glow.addExcludedMesh(ring); const node=new BABYLON.TransformNode('ringNode',sc); ring.parent=node; const mats=[];
    for(let i=0;i<2500;i++){ const a=rr()*Math.PI*2, d=G.bx*(1.15+rr()*.75), s=.4+Math.pow(rr(),3)*4; mats.push(BABYLON.Matrix.Compose(new V3(s,s*(.6+rr()*.6),s),BABYLON.Quaternion.RotationYawPitchRoll(rr()*6,rr()*6,rr()*6),new V3(Math.cos(a)*d,-70-rr()*170+Math.sin(a*3)*25,Math.sin(a)*d*.75))); }
    ring.thinInstanceAdd(mats); G.ringNode=node; G.env.push(ring,node); }
  buildTerrainFeatures(rr); try{ buildTerrainTints(); }catch(e){ console.error(e); }
  try{ buildRimFill(mkBase,rockMat,rr); }catch(e){ console.warn('rim fill',e); }
  buildBelt(rr,tinyB); buildTraffic(rr); gradeFor((B.map||{}).map,B.cfg&&B.cfg.fac);
  { // only dispose textures that battlefield materials actually use; never the shared lighting textures
    const keep=cachedTextures(); [G.scene.environmentBRDFTexture,G.scene.environmentTexture].forEach(t=>t&&keep.add(t)); const used=new Set();
    for(const m of G.env){ const mat=m instanceof BABYLON.Material?m:m.material; if(mat&&mat.getActiveTextures) mat.getActiveTextures().forEach(t=>used.add(t)); if(m instanceof BABYLON.BaseTexture) used.add(m); }
    G.envTex=[...used].filter(t=>!keep.has(t)); }
  // drifting dust for parallax
  const dust=new BABYLON.ParticleSystem('dust',700,sc); dust.particleTexture=G.tex.soft; dust.emitter=new V3(0,8,-2);
  dust.minEmitBox=new V3(-HW*BW*.55,-20,-HS*BH*.85); dust.maxEmitBox=new V3(HW*BW*.55,30,HS*BH*.85);
  dust.color1=new C4(.7,.75,.9,.35); dust.color2=new C4(.9,.8,.6,.25); dust.colorDead=new C4(0,0,0,0);
  dust.minSize=.15; dust.maxSize=.45; dust.minLifeTime=8; dust.maxLifeTime=16; dust.emitRate=45; dust.minEmitPower=.2; dust.maxEmitPower=.6;
  dust.direction1=new V3(-1,-.2,-1); dust.direction2=new V3(1,.2,1); dust.blendMode=BABYLON.ParticleSystem.BLENDMODE_ADD; dust.preWarmCycles=200; dust.preWarmStepOffset=10; dust.start(); G.env.push(dust);
}

// ---------- camera controller: RTS style with smoothing ----------
class CamCtl{
  constructor(cam,canvas){ this.cam=cam; this.el=canvas; this.a=cam.alpha; this.b=cam.beta; this.r=cam.radius; this.t=cam.target.clone();
    this.keys=new Set(); this.drag=null; this.saved=null; this.follow=null; this.attract=true; this.topdown=false; this.prevBeta=.88;
    canvas.addEventListener('wheel',e=>{ e.preventDefault(); this.attract=false; this.estab=null; const k=Math.exp(e.deltaY*.0011); this.r=clamp(this.r*k,this.minR(),900); },{passive:false});
    window.addEventListener('keydown',e=>{ if(e.target.tagName==='INPUT') return; this.keys.add(e.key.toLowerCase()); });
    window.addEventListener('keyup',e=>this.keys.delete(e.key.toLowerCase()));
    window.addEventListener('blur',()=>this.keys.clear()); }
  // v53.7 (Ryan's pick: "a bit further out"): the closest view keeps the biggest ship on the board to about half the screen, where the hull still
  // reads crisp; scripted cinematics (hold/release) and test shots (G.camMinOff) may go closer
  minR(){ if(G.camMinOff||typeof B==='undefined'||!B||B.showcase||!G.views) return 22; let L=0; for(const v of G.views.values()) if(v&&v.L&&!v.wing&&(v.state==null||v.state==='alive')&&v.L>L) L=v.L; return clamp(L*1.5,26,55); }
  panBy(dx,dz){ this.estab=null; const s=this.r/340; const fwd=new V3(-Math.cos(this.a),0,-Math.sin(this.a)); const right=new V3(-Math.sin(this.a),0,Math.cos(this.a));
    this.t.addInPlace(right.scale(dx*s)).addInPlace(fwd.scale(dz*s)); this.t.x=clamp(this.t.x,-G.bx,G.bx); this.t.z=clamp(this.t.z,-G.bz,G.bz); this.attract=false; }
  orbit(dx,dy){ this.estab=null; this.a-=dx*.0055; this.b=clamp(this.b-dy*.0045,.05,1.36); this.topdown=false; }
  focus(p,r){ this.estab=null; this.slowUntil=0; this.t=new V3(p.x,0,p.z); if(r) this.r=r; this.attract=false; }
  // establishing shot: open high over the whole battlefield while the fleets drop in, then glide down to your fleet
  establish(){ this.reset(); const fin={a:this.a,b:this.b,r:this.r,t:this.t.clone()}, c=this.cam, tok={};
    const port=innerHeight>innerWidth*1.1, ov={a:fin.a,b:.36,r:clamp(Math.max(G.bx,G.bz)*(port?3.6:2.2),420,1050),t:(G.home||fin.t).clone()}; Object.assign(this,ov); this.t=ov.t.clone();
    c.alpha=ov.a; c.beta=ov.b; c.radius=ov.r; c.target.copyFrom(ov.t); this.estab=tok; this.slowUntil=G.time+4;
    setTimeout(()=>{ if(this.estab!==tok) return; this.a=fin.a; this.b=fin.b; this.r=fin.r; this.t=fin.t; this.estab=null; },1500); }
  toggleTop(){ if(this.topdown){ this.b=this.prevBeta; this.topdown=false; } else { this.prevBeta=this.b; this.b=.05; this.topdown=true; } }
  reset(){ this.a=-Math.PI/2; this.b=.86; this.r=215; this.t=G.home.clone(); this.topdown=false;
    // v47: when the fleets come in at an angle, swing round so yours is on the left and theirs on the right, as on the classic strip
    try{ if(!(innerHeight>innerWidth*1.1)&&typeof B!=='undefined'&&B&&B.approach&&!B.showcase&&B.units){ const pl=B.units.filter(u=>u.side==='player'&&!u.dead&&!u.isSq), en=B.units.filter(u=>u.side==='enemy'&&!u.dead&&!u.isSq);
      if(pl.length&&en.length){ const avg=l=>{ let x=0,z=0; for(const u of l){ const p=hexWorld(u.q,u.r,0); x+=p.x; z+=p.z; } return new V3(x/l.length,0,z/l.length); }; const P=avg(pl), d=avg(en).subtract(P); const L=Math.max(1,d.length());
        this.a=Math.atan2(-d.x/L,d.z/L); this.r=clamp(L*1.05,190,330); this.t=P.add(d.scale(.38)); this.t.y=0; } } }catch(e){ console.warn(e); }
    // portrait phones: look up the field from behind your fleet (yours at the bottom, theirs at the top) instead of across a board too wide to fit
    try{ if(innerHeight>innerWidth*1.1&&typeof B!=='undefined'&&B&&!B.showcase&&B.units){ const pl=B.units.filter(u=>u.side==='player'&&!u.dead&&!u.isSq), en=B.units.filter(u=>u.side==='enemy'&&!u.dead&&!u.isSq);
      const avg=l=>{ let x=0,z=0; for(const u of l){ const p=hexWorld(u.q,u.r,0); x+=p.x; z+=p.z; } return new V3(x/l.length,0,z/l.length); };
      if(pl.length){ const P=avg(pl), E=en.length?avg(en):P.add(new V3(100,0,0)), d=E.subtract(P); d.y=0; const L=Math.max(1,d.length());
        const ux=-d.z/L, uz=d.x/L; let spread=0; for(const u of pl.concat(en)){ const p=hexWorld(u.q,u.r,0); spread=Math.max(spread,Math.abs((p.x-P.x)*ux+(p.z-P.z)*uz)); } /* v35: frame the fleets, not the whole board, so ships read on a phone */
        this.a=Math.atan2(-d.z,-d.x); this.b=.64; this.r=clamp(Math.max(L*1.55,spread*2.3),170,380); this.t=P.add(d.scale(.32)); } } }catch(e){ console.warn(e); } }
  hold(t,a,b,r){ if(!this.saved){ this.saved={a:this.a,b:this.b,r:this.r,t:this.t.clone()}; try{ cineBars(true); }catch(e){} } this.t=t; if(a!=null) this.a=a; if(b!=null) this.b=b; if(r!=null) this.r=r; }
  release(){ if(G.pipe&&G.pipe.depthOfFieldEnabled) G.pipe.depthOfFieldEnabled=false; try{ cineBars(false); }catch(e){} if(this.saved){ Object.assign(this,{a:this.saved.a,b:this.saved.b,r:this.saved.r,t:this.saved.t}); this.saved=null; } }
  update(dt){
    const c=this.cam; if(this._sh){ c.target.subtractInPlace(this._sh.o); c.alpha-=this._sh.a; c.beta-=this._sh.b; this._sh=null; } /* v53-I: last frame's shake never becomes camera state */
    if(this.attract){ this.a+=dt*.05; }
    let px=0,pz=0; const k=this.keys;
    if(!document.querySelector('.intro')){ if(k.has('w')||k.has('arrowup')) pz+=1; if(k.has('s')||k.has('arrowdown')) pz-=1; if(k.has('a')||k.has('arrowleft')) px-=1; if(k.has('d')||k.has('arrowright')) px+=1; }
    if(px||pz){ this.panBy(px*dt*300,pz*dt*300); }
    if(!this.saved){ const mr=this.minR(); if(this.r<mr) this.r=mr; }
    const f=1-Math.exp(-dt*((this.slowUntil&&G.time<this.slowUntil)?1.7:7));
    let da=this.a-c.alpha; c.alpha+=da*f; c.beta+=(this.b-c.beta)*f; c.radius+=(this.r-c.radius)*f;
    const tgt=c.target.clone(); tgt.addInPlace(this.t.subtract(tgt).scale(f));
    c.target.copyFrom(tgt);
    if(typeof shakeOffset==='function'){ const s=shakeOffset(dt,c); if(s){ c.target.addInPlace(s.o); c.alpha+=s.a; c.beta+=s.b; this._sh=s; } } /* v53-I: trauma shake (wfx3d) */
  }
}
// v53.8 battle load (Ryan: "lag on loading into a battle"; his pick: a short loading moment is fine, no hitch once the battle shows).
// Every battle start goes through the establishing shot, so that is where the work moves: a dark "Entering battle" cover goes up, the ships
// are built (first frame), every hull's baked maps load and upload, and the shaders compile with those maps in place; then the cover lifts
// and the establishing shot plays. Before v53.8 the maps arrived a second or two into the battle and each one recompiled its hull material.
// A 4 s cap means a slow network can never hold the battle (late maps then swap in as before).
const _establish=CamCtl.prototype.establish;
CamCtl.prototype.establish=function(){ const self=this; if(!(typeof B!=='undefined'&&B&&!B.showcase)||G.noWarm) return _establish.call(self);
  const tok=G.warmTok={}; battleVeil(true); try{ _establish.call(self); }catch(e){}
  battleWarm().catch(e=>console.warn('battle warm',e)).then(r=>{ if(G.warmTok!==tok) return; G.lastWarm=r; try{ _establish.call(self); }catch(e){} battleVeil(false); try{ if(typeof FRAMES!=='undefined') FRAMES.reset(); }catch(e){} }); };
function battleVeil(on){ let el=document.getElementById('bveil');
  if(on){ if(!el){ el=document.createElement('div'); el.id='bveil'; el.textContent='Entering battle…'; el.style.cssText='position:fixed;inset:0;z-index:45;display:grid;place-items:center;background:#04060c;color:var(--bone2,#b3aa95);font-size:18px;font-family:var(--ui,sans-serif);letter-spacing:.04em;transition:opacity .35s;pointer-events:auto'; document.body.appendChild(el); } el.style.opacity='1'; el.style.pointerEvents='auto'; clearTimeout(G._veilT); G._veilT=setTimeout(()=>battleVeil(false),8000); } /* never traps input: lifts after 8 s regardless */
  else if(el){ clearTimeout(G._veilT); el.style.opacity='0'; el.style.pointerEvents='none'; setTimeout(()=>{ try{ if(el.style.opacity==='0') el.remove(); }catch(e){} },400); } }
const nextFrame=()=>new Promise(r=>requestAnimationFrame(()=>r()));
async function battleWarm(){ const t0=performance.now(), cap=t0+4000, out={ms:0,maps:0,late:0,build:0,compile:0};
  await nextFrame(); await nextFrame(); out.build=Math.round(performance.now()-t0); // updateWorld builds every ship view on the first frame
  const live=new Set(), add=mt=>{ if(!mt) return; if(mt.subMaterials) mt.subMaterials.forEach(add); else if(mt._isAiHull) live.add(mt); }; for(const m of G.scene.meshes) if(m.isEnabled()) add(m.material); // merged live ships carry multi-materials
  const ents=Object.values(AI_TEX).filter(e=>!e.failed&&(live.has(e.m)||e.loading)); out.maps=ents.length; for(const e of ents) if(live.has(e.m)) aiTexTouch(e); // every map still on its way counts too
  while(performance.now()<cap&&ents.some(e=>e.loading||!e.n||!e.t||!e.n.isReady()||!e.t.isReady())){ if(ents.every(e=>e.failed)) break; await new Promise(r=>setTimeout(r,40)); }
  while(performance.now()<cap&&G.rockPending) await new Promise(r=>setTimeout(r,40)); out.rocks=!G.rockPending;
  out.late=ents.filter(e=>!(e.n&&e.t&&e.n.isReady()&&e.t.isReady())).length;
  const t1=performance.now(); { const ms=[]; for(const v of G.views.values()) if(v&&v.root&&v.root.getChildMeshes) for(const m of v.root.getChildMeshes(false)) if(m.isEnabled()&&m.material) ms.push(m); // the ships' own shaders, compiled with their maps in place
    while(performance.now()<cap){ let ok=true; for(const m of ms){ try{ if(!m.isDisposed()&&!m.isReady(true)){ ok=false; break; } }catch(e){} } if(ok) break; await new Promise(r=>setTimeout(r,40)); } out.notReady=ms.filter(m=>{ try{ return !m.isDisposed()&&!m.isReady(true); }catch(e){ return false; } }).length; } out.compile=Math.round(performance.now()-t1);
  await nextFrame(); await nextFrame(); out.ms=Math.round(performance.now()-t0); out.end=performance.now(); try{ if(typeof tel==='function') tel('battle_warm',out); }catch(e){} return out; }
// on the sector map: start fetching the baked maps of your fleet and the sector's enemy roster (browser cache), so the battle cover is short
function hullMapPrefetch(){ try{ if(!aiHullsOn()||G.noBake||typeof RUN==='undefined'||!RUN||!RUN.fleet) return; const dir=(G.mobile||G.quality==='medium')?'hulls/':'hulls_hi/', want=new Set(), seen=G._pref||(G._pref=new Set());
    const add=tpl=>{ const h=HULLS[tpl]; if(!h||h.sq) return; const k=(h.fac||'voidsworn')+'|'+h.cls, d=AI_HULL_DATA[k]; if(d&&d.tex&&AI_HULLS[k]) want.add(AI_HULLS[k]); };
    for(const s of RUN.fleet) add(s.tpl); const ef=RUN.foes&&RUN.foes[(RUN.sector||1)-1]; if(ef&&FACTIONS[ef]) for(const t of FACTIONS[ef].roster.concat([FACTIONS[ef].boss])) add(t);
    try{ for(const s of new Set(Object.values(ROCK_SET))) setTimeout(()=>loadRockSet(s).catch(()=>{}),900); }catch(e){} // the sculpted asteroid sets decode once per session
    let i=0; for(const c of want){ const cd=dir==='hulls/'&&AI_HI_ON_PHONE.has(c)?'hulls_hi/':dir; for(const s of ['_n.webp','_m.webp']){ const url=cd+c+s; if(seen.has(url)) continue; seen.add(url); setTimeout(()=>{ try{ fetch(url,{priority:'low'}).catch(()=>{}); }catch(e){} },400+120*(i++)); } } }catch(e){ console.warn('prefetch',e); } }

// ---------- battlefield features: debris, derelict station, planet edge, ion storms, graveyard wrecks ----------
// a collapsed star fills the hole in the middle of a 'dead star' board: a black core, a hot photon ring and a slow accretion disc
function buildDeadStar(c){ const sc=G.scene;
  const core=MB.CreateSphere('dsCore',{diameter:34,segments:28},sc); core.position=new V3(c.x,-10,c.z); const cm=new BABYLON.StandardMaterial('dsCoreM',sc); cm.diffuseColor=C3.Black(); cm.specularColor=C3.Black(); cm.emissiveColor=C3.Black(); core.material=cm; core.isPickable=false; G.glow.addExcludedMesh(core);
  const ring=MB.CreateTorus('dsRing',{diameter:36.5,thickness:1,tessellation:96},sc); ring.position=core.position.clone(); ring.rotation.x=Math.PI/2-.35; ring.material=emMat('dsRingM',new C3(1.9,1.35,.85)); ring.isPickable=false;
  const tex=G.tex.accretion||(G.tex.accretion=dynTex('accretionTex',512,512,(g,w)=>{ const c=w/2, gr=g.createRadialGradient(c,c,w*.2,c,c,w*.5); gr.addColorStop(0,'rgba(0,0,0,0)'); gr.addColorStop(.36,'rgba(255,250,235,1)'); gr.addColorStop(.46,'rgba(255,196,110,.95)'); gr.addColorStop(.7,'rgba(230,110,50,.45)'); gr.addColorStop(1,'rgba(120,40,20,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w);
      g.globalCompositeOperation='lighter'; for(let i=0;i<140;i++){ const r0=w*(.22+Math.random()*.26), a0=Math.random()*6.28, len=.3+Math.random()*1.2; g.strokeStyle=`rgba(255,${150+Math.random()*90|0},${70+Math.random()*60|0},${.05+Math.random()*.12})`; g.lineWidth=1+Math.random()*3; g.beginPath(); g.arc(c,c,r0,a0,a0+len); g.stroke(); } }));
  const disc=MB.CreateDisc('dsDisc',{radius:44,tessellation:96},sc); disc.position=core.position.clone(); disc.rotation.x=Math.PI/2-.22; const dm=new BABYLON.StandardMaterial('dsDiscM',sc); dm.disableLighting=true; dm.emissiveTexture=tex; dm.opacityTexture=tex; dm.diffuseColor=C3.Black(); dm.specularColor=C3.Black(); dm.alphaMode=BABYLON.Engine.ALPHA_ADD; dm.disableDepthWrite=true; dm.backFaceCulling=false; disc.material=dm; disc.isPickable=false; G.glow.addExcludedMesh(disc);
  const halo=MB.CreatePlane('dsHalo',{size:130},sc); halo.position=core.position.add(new V3(0,2,0)); halo.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; const hm=emMat('dsHaloM',new C3(.9,.45,.25),.35); hm.opacityTexture=G.tex.soft; hm.alphaMode=BABYLON.Engine.ALPHA_ADD; hm.disableDepthWrite=true; halo.material=hm; halo.isPickable=false; G.glow.addExcludedMesh(halo);
  const tilt=new BABYLON.TransformNode('dsTilt',sc), spinN=new BABYLON.TransformNode('dsSpin',sc); tilt.position=core.position.clone(); tilt.rotation.x=-.22; spinN.parent=tilt; disc.parent=spinN; disc.position.set(0,0,0); disc.rotation.set(Math.PI/2,0,0); spinN.spin=new V3(0,.1,0); G.rocks.push(spinN); G.env.push(spinN,tilt); G.env.push(core,cm,ring,ring.material,disc,dm,halo,hm); }
// ---------- set pieces that fill holes in the battlefield (they block movement and line of sight) ----------
function lumpyRock(name,rr,sub){ const m=MB.CreateIcoSphere(name,{radius:1,subdivisions:sub||4},G.scene); const p=m.getVerticesData(BABYLON.VertexBuffer.PositionKind), a=rr()*6, b=rr()*6;
  const craters=[]; for(let i=0;i<9;i++){ const u=rr()*2-1, t=rr()*6.28, s=Math.sqrt(1-u*u); craters.push([s*Math.cos(t),u,s*Math.sin(t),.18+rr()*.28,.06+rr()*.1]); }
  for(let i=0;i<p.length;i+=3){ const x=p[i],y=p[i+1],z=p[i+2]; let n=1+.2*Math.sin(x*2.3+a)*Math.cos(y*1.9+b)+.12*Math.sin(z*4.1+x*1.7+a)+.05*Math.sin(x*9+y*7+b)+(rr()-.5)*.03;
    for(const [cx,cy,cz,cr,cd] of craters){ const d=Math.hypot(x-cx,y-cy,z-cz); if(d<cr) n-=cd*(1-d/cr)*(1-d/cr)*2; else if(d<cr*1.25) n+=cd*.25; }
    p[i]=x*n; p[i+1]=y*n; p[i+2]=z*n; }
  m.setVerticesData(BABYLON.VertexBuffer.PositionKind,p); m.convertToFlatShadedMesh(); m.isPickable=false; return m; }
// v53 sculpted asteroid library (Blender: rocks/ for phones and Medium, 512 maps; rocks_hi/ for desktop, 1024 maps). Eight rocks per kind:
// RCA carbon (craggy, cratered), RST stone (planar fracture faces, strata), RCR crystal (rock with crystal spikes), RIC ice (smooth, crack lines).
// CODE.json is the hull format (quantised p/q/i, 'u' UVs as Uint16/65535, normalised so x length = 1, centred), CODE_n.webp a tangent-space
// normal map, CODE_m.webp R = ambient occlusion, G = curvature. Only the kind a battle needs is fetched, lazily: until it arrives (or if it fails,
// or on file://) the board shows the procedural rocks, and the library meshes then take over the same thin-instance matrices in place.
const ROCK_LIB={sets:{},loading:{},mats:{},index:{}}, ROCK_SET={stone:'RST',carbon:'RCA',iron:'RCA',crystal:'RCR',ice:'RIC'};
const ROCK_TINT={RST:[.34,.31,.28],RCA:[.27,.255,.245],RCR:[.25,.27,.28],RIC:[.34,.4,.47]}, ROCK_GLOW={RCR:[.12,.5,.42]}; // dark albedo per kind; crystal spikes glow
function rockLibDir(){ return (G.mobile||G.quality==='medium')?'rocks/':'rocks_hi/'; }
function loadRockSet(set){ if(ROCK_LIB.sets[set]) return Promise.resolve(ROCK_LIB.sets[set]); if(ROCK_LIB.loading[set]) return ROCK_LIB.loading[set];
  if(typeof fetch!=='function'||typeof location==='undefined'||location.protocol==='file:'||typeof decodeAIHull!=='function') return Promise.reject(new Error('no rock library here'));
  const dir=rockLibDir(), t0=performance.now();
  // dir/index.json lists the kinds that are present ({"RST":8,...}); the live build may ship {} until the files are uploaded, which keeps it procedural
  const idx=ROCK_LIB.index[dir]||(ROCK_LIB.index[dir]=fetch(dir+'index.json').then(r=>r.ok?r.json():{}).catch(()=>({})));
  return ROCK_LIB.loading[set]=idx.then(ix=>{ if(!ix||!ix[set]) throw new Error('rock set '+set+' not in '+dir+'index.json'); }).then(()=>Promise.all([0,1,2,3,4,5,6,7].map(async i=>{ const code=set+'0'+i, r=await fetch(dir+code+'.json'); if(!r.ok) throw new Error(code+' '+r.status); const j=await r.json(), d=decodeAIHull(j);
      if(j.u){ const bin=atob(j.u), u8=new Uint8Array(bin.length); for(let k=0;k<bin.length;k++) u8[k]=bin.charCodeAt(k); const qu=new Uint16Array(u8.buffer); d.uv=new Float32Array(qu.length); for(let k=0;k<qu.length;k++) d.uv[k]=qu[k]/65535; }
      d.code=code; d.dir=dir; d.size=j.size||[1,1,1]; return d; })))
    .then(list=>{ ROCK_LIB.sets[set]=list; console.debug('[rocks] '+set+' library from '+dir+' in '+Math.round(performance.now()-t0)+'ms'); return list; })
    .catch(e=>{ console.warn('rock library',set,e); delete ROCK_LIB.loading[set]; throw e; }); }
// cavity darkening and edge highlights from the baked AO/curvature map, and (crystal) a glow on the convex spikes; no extra draws
class RockLibPlugin extends BABYLON.MaterialPluginBase{
  constructor(mat,tex,glow){ super(mat,'RockLib',201,{ROCKLIB:false}); this.tex=tex; this.glow=glow; this._enable(true); }
  prepareDefines(d){ d.ROCKLIB=true; } getClassName(){ return 'RockLibPlugin'; }
  isReadyForSubMesh(){ return !this.tex||this.tex.isReady(); }
  getSamplers(s){ s.push('rlibM'); } getActiveTextures(a){ if(this.tex) a.push(this.tex); } hasTexture(t){ return t===this.tex; }
  getUniforms(){ return {ubo:[{name:'rlibG',size:3,type:'vec3'}],fragment:'#ifdef ROCKLIB\nuniform vec3 rlibG;\n#endif\n'}; }
  bindForSubMesh(ubo){ ubo.updateColor3('rlibG',this.glow); if(this.tex) ubo.setTexture('rlibM',this.tex); }
  getCustomCode(type){ if(type!=='fragment') return null; return {CUSTOM_FRAGMENT_DEFINITIONS:'#ifdef ROCKLIB\nuniform sampler2D rlibM;\n#endif\n',
    CUSTOM_FRAGMENT_UPDATE_DIFFUSE:`
#ifdef ROCKLIB
#ifdef MAINUV1
  vec4 rlm=texture2D(rlibM,vMainUV1);
#else
  vec4 rlm=vec4(1.0,0.5,1.0,1.0);
#endif
  baseColor.rgb*=mix(0.32,1.0,rlm.r)*mix(1.0,0.62,smoothstep(0.5,0.18,rlm.g))*mix(1.0,1.45,smoothstep(0.56,0.9,rlm.g));
#endif
`,CUSTOM_FRAGMENT_BEFORE_FRAGCOLOR:`
#ifdef ROCKLIB
  color.rgb+=rlibG*smoothstep(0.62,0.92,rlm.g);
#endif
`}; } }
function rockLibMat(d){ const k=d.code+'@'+d.dir; let m=ROCK_LIB.mats[k]; if(m&&G.scene.materials.includes(m)) return m; const set=d.code.slice(0,3), t=ROCK_TINT[set]||[.3,.3,.3], gl=ROCK_GLOW[set];
  m=new BABYLON.StandardMaterial('rockLib_'+d.code,G.scene); m.diffuseColor=new C3(t[0],t[1],t[2]); /* v53.6 lighting: the 2.2x lift blew stone out to cream */ m.specularColor=set==='RIC'?new C3(.1,.11,.13):new C3(.025,.025,.025); m.specularPower=set==='RIC'?24:8; /* rough, non-metallic, no sparkle */
  m.bumpTexture=new BABYLON.Texture(d.dir+d.code+'_n.webp',G.scene); const mt=new BABYLON.Texture(d.dir+d.code+'_m.webp',G.scene);
  try{ new RockLibPlugin(m,mt,gl?new C3(gl[0],gl[1],gl[2]):new C3(0,0,0)); }catch(e){ console.warn('rock lib shading',e); } return ROCK_LIB.mats[k]=m; } // cached across battles (not in G.env), so the maps load once
// the eight rocks fill the seven board roles: the most elongated stand up as pillars, slab and shard (long axis turned vertical, squeezed toward
// a column), the rest are chunks; each bakes into a mesh shaped like the procedural role so the per-hex recipes and matrices carry over unchanged
function rockLibMeshes(list){ const el=list.map(d=>({d,e:1/Math.max(.05,Math.max(d.size[1],d.size[2]))})).sort((a,b)=>b.e-a.e), order=[1,2,3,4,5,0,6]; // role k takes el[order[k]]
  return [0,1,2,3,4,5,6].map(k=>{ const d=el[order[k]].d, tall=k<3||k===5, P=d.pos, N=d.nor, n=P.length/3, pos=new Float32Array(P.length), nor=new Float32Array(N.length);
    let ex=[0,0,0]; for(let i=0;i<P.length;i+=3) for(let c=0;c<3;c++) ex[c]=Math.max(ex[c],Math.abs(P[i+c]));
    const sx=tall?.5/Math.max(.05,ex[1]):.9/Math.max(...ex), sy=tall?1/Math.max(.05,ex[0]):sx, sz=tall?.45/Math.max(.05,ex[2]):sx; // tall: x (long) becomes y
    for(let v=0;v<n;v++){ const o=v*3; if(tall){ pos[o]=P[o+1]*sx; pos[o+1]=P[o]*sy; pos[o+2]=P[o+2]*sz; let a=N[o+1]/sx, b=N[o]/sy, c=N[o+2]/sz; const l=Math.hypot(a,b,c)||1; nor[o]=a/l; nor[o+1]=b/l; nor[o+2]=c/l; }
      else { pos[o]=P[o]*sx; pos[o+1]=P[o+1]*sy; pos[o+2]=P[o+2]*sz; nor[o]=N[o]; nor[o+1]=N[o+1]; nor[o+2]=N[o+2]; } }
    const idx=tall?Uint32Array.from(d.idx):d.idx; if(tall) for(let t=0;t<idx.length;t+=3){ const x=idx[t+1]; idx[t+1]=idx[t+2]; idx[t+2]=x; } // swapping x and y mirrors the mesh: keep the winding
    const m=new BABYLON.Mesh('rockLib'+k,G.scene), vd=new BABYLON.VertexData(); vd.positions=pos; vd.normals=nor; vd.indices=idx; vd.uvs=d.uv; vd.applyToMesh(m);
    m.material=rockLibMat(d); m.isVisible=false; m.isPickable=false; castShadows(m); G.glow.addExcludedMesh(m); G.env.push(m); return m; }); }
// v53: a fresh material sharing the rock textures. A clone of rockM tries to re-create the RockFx plugin from its serialized form, cannot find the
// class, and the clone never becomes ready, so nothing using it drew (this is why the v51 rim fill rocks were invisible).
function rockMatLike(b,name){ const m=new BABYLON.StandardMaterial(name,G.scene); m.diffuseTexture=b.diffuseTexture; m.bumpTexture=b.bumpTexture; m.diffuseColor=b.diffuseColor.clone(); m.specularColor=b.specularColor.clone(); m.specularPower=b.specularPower; m.emissiveColor=b.emissiveColor.clone(); if(typeof addRockFx==='function') addRockFx(m); return m; }
// v53 board rock: a column, slab, chunk or shard whose silhouette comes from flat cleavage planes, but built as a dense radial surface: along each
// direction the radius is a soft minimum over the planes (rounded edges, no tessellation steps), then fine multi-octave noise and shallow pits,
// with smooth normals so it holds up at close zoom (no glittering facets). Vertex colour carries cavity darkening, darker bases and a faint
// warm/cool variation, so the rock reads solid and matte without a triplanar shader.
function mkFacet(k,mat){ const fr=seeded(700+k*13), kind=['pillar','pillar','slab','chunk','chunk','shard','chunk'][k], D={pillar:[.46,1,.42],slab:[.78,1,.26],chunk:[.9,.75,.8],shard:[.24,1,.2]}[kind];
  const nrm=a=>{ const l=Math.hypot(a[0],a[1],a[2])||1; return [a[0]/l,a[1]/l,a[2]/l]; }, PL=[[1,0,0,D[0]],[-1,0,0,D[0]],[0,1,0,D[1]],[0,-1,0,D[1]],[0,0,1,D[2]],[0,0,-1,D[2]]], big=kind==='chunk'?11:9;
  for(let c=0;c<big+5;c++){ let n=[fr()*2-1,fr()*2-1,fr()*2-1]; if(kind!=='chunk'&&c<4) n[1]*=.15; /* columns keep near-vertical flanks */ if(kind!=='chunk'&&c===4) n=[n[0]*.4,1,n[2]*.4]; /* a broken top */ n=nrm(n);
    const sup=Math.hypot(n[0]*D[0],n[1]*D[1],n[2]*D[2]); PL.push([n[0],n[1],n[2],sup*(c<big?.68+fr()*.2:.86+fr()*.06)]); }
  const h3=(i,j,l,sd)=>{ let n=(i*374761393+j*668265263+l*1440662683+sd*974711)|0; n=(n^(n>>>13))*1274126177|0; return ((n^(n>>>16))>>>0)/4294967296; };
  const vn=(x,y,z,sd)=>{ const xi=Math.floor(x),yi=Math.floor(y),zi=Math.floor(z),xf=x-xi,yf=y-yi,zf=z-zi,u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf),w=zf*zf*(3-2*zf),L=(a,b,t)=>a+(b-a)*t;
    return L(L(L(h3(xi,yi,zi,sd),h3(xi+1,yi,zi,sd),u),L(h3(xi,yi+1,zi,sd),h3(xi+1,yi+1,zi,sd),u),v),L(L(h3(xi,yi,zi+1,sd),h3(xi+1,yi,zi+1,sd),u),L(h3(xi,yi+1,zi+1,sd),h3(xi+1,yi+1,zi+1,sd),u),v),w)*2-1; };
  const pits=[]; for(let i=0;i<5+Math.floor(fr()*5);i++) pits.push([...nrm([fr()*2-1,fr()*2-1,fr()*2-1]),.1+fr()*.16,.02+fr()*.03]);
  const sub=G.mobile?9:G.quality==='medium'?12:G.quality==='ultra'?22:17, m=MB.CreateIcoSphere('rockFacet'+k,{radius:1,subdivisions:sub,flat:false},G.scene), p=m.getVerticesData(BABYLON.VertexBuffer.PositionKind), nv=p.length/3;
  const sd=k*31+11, K=26/((D[0]+D[1]+D[2])/3), cav=new Float32Array(nv), tint=new Float32Array(nv);
  for(let v=0;v<nv;v++){ const o=v*3, u=nrm([p[o],p[o+1],p[o+2]]); let acc=0, rmin=1e9; const rs=[];
    for(const q of PL){ const c=u[0]*q[0]+u[1]*q[1]+u[2]*q[2]; if(c>1e-4){ const r=q[3]/c; rs.push(r); rmin=Math.min(rmin,r); } }
    for(const r of rs) acc+=Math.exp(-K*(r-rmin)); let r=rmin-Math.log(acc)/K; // soft minimum: rounded edges where cleavage planes meet
    const x=u[0]*r, y=u[1]*r, z=u[2]*r; let n=0, amp=.5, f=2.4; for(let oc=0;oc<5;oc++){ n+=amp*vn(x*f+oc*7.1,y*f-oc*3.3,z*f+oc*5.7,sd); amp*=.5; f*=2.05; }
    let pit=0; for(const [cx,cy,cz,pr,pd] of pits){ const d=Math.hypot(u[0]-cx,u[1]-cy,u[2]-cz); if(d<pr) pit-=pd*(1-d/pr)*(1-d/pr)*3; }
    const disp=n*.07+pit; r*=1+disp; cav[v]=disp; tint[v]=vn(x*1.3,y*1.3,z*1.3,sd+5); p[o]=u[0]*r; p[o+1]=u[1]*r; p[o+2]=u[2]*r; }
  let y0=1e9,y1=-1e9; for(let v=0;v<nv;v++){ y0=Math.min(y0,p[v*3+1]); y1=Math.max(y1,p[v*3+1]); }
  const col=new Float32Array(nv*4); for(let v=0;v<nv;v++){ const h=(p[v*3+1]-y0)/Math.max(1e-6,y1-y0), ao=Math.max(.35,Math.min(1,.86+cav[v]*3.2))*(.55+.45*Math.min(1,h*1.5)), t=tint[v]*.06;
    col[v*4]=ao*(1+t); col[v*4+1]=ao; col[v*4+2]=ao*(1-t*1.2); col[v*4+3]=1; }
  m.setVerticesData(BABYLON.VertexBuffer.PositionKind,p); m.setVerticesData(BABYLON.VertexBuffer.ColorKind,col,false,4); const nr=[]; BABYLON.VertexData.ComputeNormals(p,m.getIndices(),nr); m.setVerticesData(BABYLON.VertexBuffer.NormalKind,nr); m.refreshBoundingInfo();
  m.material=mat; m.isVisible=false; m.isPickable=false; castShadows(m); G.glow.addExcludedMesh(m); G.env.push(m); return m; }
// wrecks on the field come from the fleets in this fight, so they reuse materials already built (no new faction texture sets per battle)
function battleFacs(){ const f=new Set(); try{ for(const u of (B&&B.units)||[]) if(u.fac) f.add(u.fac); }catch(e){} return f.size?[...f]:['hegemony','voidsworn','corsair','ithar','deathless','chorus']; }
const HOLE_BUILD={
  asteroid(c,R,rr){ const sc=G.scene, m=lumpyRock('giantRock',rr,4); m.material=sc.getMaterialByName('rockM'); m.scaling=new V3(R*.86,R*.7,R*.78); m.position=c.add(new V3(0,-R*.06,0)); m.rotation.set((rr()-.5)*.4,rr()*6,(rr()-.5)*.3); m.spin=new V3(0,.006,0); G.rocks.push(m); G.env.push(m); castShadows(m);
    for(let i=0;i<7;i++){ const k=lumpyRock('rockChunk',rr,2); k.material=m.material; const a=rr()*6.28, d=R*(.55+rr()*.3), s=R*(.07+rr()*.08); k.scaling.setAll(s); k.position=c.add(new V3(Math.cos(a)*d,(rr()-.3)*R*.4,Math.sin(a)*d)); k.spin=new V3((rr()-.5)*.2,(rr()-.5)*.2,0); G.rocks.push(k); G.env.push(k); } },
  moon(c,R,rr){ const sc=G.scene, tex=G.tex.moon2||(G.tex.moon2=dynTex('moonTex2',512,256,(g,w,h)=>{ const r=seeded(31); g.fillStyle='#7d7975'; g.fillRect(0,0,w,h);
      for(let i=0;i<60;i++){ const x=r()*w,y=r()*h,rad=20+r()*70, gr=g.createRadialGradient(x,y,0,x,y,rad); const dk=r()<.5; gr.addColorStop(0,dk?'rgba(70,66,62,.35)':'rgba(170,165,158,.3)'); gr.addColorStop(1,'rgba(0,0,0,0)'); g.fillStyle=gr; g.fillRect(x-rad,y-rad,rad*2,rad*2); }
      for(let i=0;i<160;i++){ const x=r()*w,y=r()*h,rad=1.5+Math.pow(r(),3)*18, gr=g.createRadialGradient(x+rad*.2,y+rad*.2,rad*.1,x,y,rad); gr.addColorStop(0,'rgba(45,42,40,.5)'); gr.addColorStop(.75,'rgba(80,76,72,.25)'); gr.addColorStop(.9,'rgba(205,200,192,.35)'); gr.addColorStop(1,'rgba(205,200,192,0)'); g.fillStyle=gr; g.fillRect(x-rad,y-rad,rad*2,rad*2); }
      for(let i=0;i<2500;i++){ g.fillStyle=`rgba(${r()<.5?'40,38,36':'200,196,190'},${r()*.08})`; g.fillRect(r()*w,r()*h,1+r()*2,1+r()*2); } }));
    const m=MB.CreateSphere('moonlet',{diameter:R*2.1,segments:40},sc); m.position=c.add(new V3(0,-R*.5,0)); const mt=new BABYLON.StandardMaterial('moonM',sc); mt.diffuseTexture=tex; mt.specularColor=new C3(.04,.04,.04); mt.emissiveColor=new C3(.05,.05,.06); m.material=mt; m.isPickable=false; m.rotation.set(.4,rr()*6,.2); m.spin=new V3(0,.01,0); G.rocks.push(m); G.env.push(m,mt); castShadows(m); },
  station(c,R,rr){ const b=new SB('hegemony',30), M=b.M;
    b.cylY(M.dark,0,0,0,7,4,5,12); b.cylY(M.hull,0,6,0,3,2.4,3.4,12); b.cylY(M.dark,0,-7,0,4,2.6,1.2,10);
    for(const [a0,a1] of [[10,120],[160,230],[275,330]]){ const pts=[]; for(let a=a0;a<=a1;a+=5){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*15,(rr()-.5)*.6,Math.sin(r)*15)); } tube(b,rr()<.5?M.hull:M.dark,pts,()=>1.6,8); }
    for(let i=0;i<5;i++){ const a=i*1.256+rr()*.3, l=6+rr()*8; b.box(M.dark,Math.cos(a)*(3+l/2),(rr()-.5)*2,Math.sin(a)*(3+l/2),l,.9,.9,(rr()-.5)*.3,-a,(rr()-.5)*.4); }
    for(let i=0;i<5;i++){ const a=rr()*6.28, r=rr()<.5?15:3+rr()*9; b.box(M.ember,Math.cos(a)*r,(rr()-.5)*2,Math.sin(a)*r,.6+rr()*.8,.4,.6+rr()*.8); }
    for(let i=0;i<10;i++){ const a=rr()*6.28, r=6+rr()*8; b.box(rr()<.5?M.hull:M.dark,Math.cos(a)*r,(rr()-.5)*5,Math.sin(a)*r,.8+rr()*2.4,.5+rr()*1.2,.6+rr()*2,rr()*3,rr()*3,rr()*3); }
    const m=b.finish(); m.root.position=c.add(new V3(0,1.5,0)); m.root.scaling.setAll(R/16.5); m.root.rotation.set((rr()-.5)*.5,rr()*6,(rr()-.5)*.4); m.meshes.forEach(x=>x.isPickable=false); G.env.push(m.root); },
  hulk(c,R,rr){ const facs=battleFacs(), f=facs[Math.floor(rr()*facs.length)];
    const mdl=buildShipModel({fac:f,cls:'Battleship',isSq:false,side:'enemy',tpl:'wreck'}); if(mdl.toSplit) mdl.toSplit(); const Mw=facMats(f);
    mdl.meshes.forEach(m=>{ m.material=(m.material===Mw.win||m.material===Mw.eng||m.material===Mw.tip||m.material===Mw.sail)?Mw.ember:Mw.wreck; m.isPickable=false; }); mdl.plumes.forEach(p=>p.dispose()); (mdl.flares||[]).forEach(p=>p.dispose());
    mdl.root.position=c.add(new V3(0,1,0)); mdl.root.scaling.setAll(R*1.85/Math.max(10,mdl.L)); mdl.root.rotation.set((rr()-.5)*.4,rr()*6.28,(rr()-.5)*.6); mdl.fore.position.x+=mdl.L*.12; mdl.fore.rotation.set((rr()-.5)*.5,(rr()-.5)*.7,(rr()-.5)*.5); mdl.aft.rotation.z=(rr()-.5)*.4; G.env.push(mdl.root); },
  comet(c,R,rr){ const sc=G.scene, m=lumpyRock('cometCore',rr,3), mt=new BABYLON.StandardMaterial('iceM',sc); mt.diffuseColor=new C3(.3,.36,.44); mt.specularColor=new C3(.18,.22,.28); mt.specularPower=24; mt.emissiveColor=new C3(.02,.04,.07); m.material=mt;
    m.scaling=new V3(R*.72,R*.5,R*.64); m.position=c.add(new V3(0,0,0)); m.spin=new V3(0,.02,.01); G.rocks.push(m); G.env.push(m,mt);
    const a=rr()*6.28, dir=new V3(Math.cos(a),0,Math.sin(a)), tail=MB.CreateCylinder('cometTail',{height:R*5,diameterTop:R*1.9,diameterBottom:R*.6,tessellation:16},sc), tm=emMat('cometTailM',new C3(.45,.75,1.1),.18); tm.opacityTexture=G.tex.soft; tm.alphaMode=BABYLON.Engine.ALPHA_ADD; tm.disableDepthWrite=true; tm.backFaceCulling=false;
    tail.material=tm; tail.isPickable=false; tail.rotation.z=Math.PI/2; const tn=new BABYLON.TransformNode('tailN',sc); tail.parent=tn; tail.position.x=R*2.5; tn.position=c.add(new V3(0,1,0)); tn.rotation.y=-a; G.glow.addExcludedMesh(tail); G.env.push(tail,tm,tn); } };
function buildHoleFills(holes,rr){ for(const h of holes){ if(h.kind==='deadstar'||!HOLE_BUILD[h.kind]) continue; const ps=h.cells.map(([q,r])=>hexWorld(q,r,0)); let x=0,z=0; for(const p of ps){ x+=p.x; z+=p.z; }
    const c=new V3(x/ps.length,0,z/ps.length); let R=Math.max(HS*1.1,...ps.map(p=>Math.hypot(p.x-c.x,p.z-c.z)))+HS*.7;
    /* the set piece must fit the hole: it stops short of the nearest board hex (playable or not), so no ship or rock ever sits inside it */
    let dmin=1e9; for(const b of boardHexes()){ const p=hexWorld(b.q,b.r,0); dmin=Math.min(dmin,Math.hypot(p.x-c.x,p.z-c.z)); }
    for(const o of holes){ if(o===h) continue; let ox=0,oz=0; for(const [q,r] of o.cells){ const p=hexWorld(q,r,0); ox+=p.x; oz+=p.z; } dmin=Math.min(dmin,Math.hypot(ox/o.cells.length-c.x,oz/o.cells.length-c.z)*.5+HS*.75); }
    R=Math.max(Math.min(HS*.8,dmin*.6),Math.min(R,dmin-HS*.55)); h.vis={x:c.x,z:c.z,R,dmin}; try{ HOLE_BUILD[h.kind](c,R,rr); }catch(e){ console.warn('hole fill',e); } } }
// v51 rim fill: every hex cut away from the board (ragged edges, arena margins, hourglass waists, corridor walls) now has a visible
// reason to be impassable. Close to the playable hexes it is a dense wall (asteroid scree, wreck debris, ice, ion cloud); further out
// it thins into big bodies, and the largest rim pockets get a centrepiece (a giant asteroid, a wrecked capital, a derelict station).
function buildRimFill(mkBase,rockMat,rr){ if(!B||!B.terrain) return; const sc=G.scene, meta=B.map||{}, kind=(TERRAIN_META&&TERRAIN_META.map)||meta.map||'belt';
  const solid=k=>SOLID&&SOLID.has(k), rift=new Set((meta.riftCells||[]).map(x=>x[0]+','+x[1]));
  const cells=new Map(), q0=[]; // BFS outward from the playable board over the canvas (+2 rings)
  for(const h of boardHexes()) { cells.set(h.q+','+h.r,0); q0.push(h); }
  const inCanvas=(q,r)=>{ if(r<-2||r>=BH+2) return false; const c=q+Math.floor(r/2); return c>=-2&&c<BW+2; };
  let qi=0; while(qi<q0.length){ const h=q0[qi++], d=cells.get(h.q+','+h.r); if(d>=7) continue;
    for(const D of DIRS){ const q=h.q+D[0], r=h.r+D[1], k=q+','+r; if(cells.has(k)||!inCanvas(q,r)||onBoard(q,r)||solid(k)||rift.has(k)) continue; cells.set(k,d+1); q0.push({q,r}); } }
  const rim=[...cells].filter(([k,d])=>d>0).map(([k,d])=>{ const [q,r]=k.split(',').map(Number); return {q,r,d}; }); if(!rim.length) return;
  // keep clear of the near planet and the dead star, which explain their own space
  const avoid=[]; if(G.nearPlanet){ const p=G.nearPlanet.position, R=(G.nearPlanet.getBoundingInfo().boundingSphere.radiusWorld||0)*1.02; avoid.push({x:p.x,z:p.z,R}); }
  const ok=c=>{ const w=hexWorld(c.q,c.r); return !avoid.some(a=>Math.hypot(w.x-a.x,w.z-a.z)<a.R); };
  const R=rim.filter(ok); G.rimCells=R.length;
  const debrisWall=kind==='graveyard', cloudWall=kind==='storm', mob=G.mobile;
  // one light rock base set shared by thin instances: one draw per shape
  const sub=mob?3:(G.quality==='medium'?4:5), shapes=[0,3,6].map(k=>mkBase(k,sub,'rim')); const bufs=shapes.map(()=>[]);
  const put=(c,w,s,y,squash)=>{ const m=BABYLON.Matrix.Compose(new V3(s,s*(squash||(.6+rr()*.5)),s*(.8+rr()*.4)),BABYLON.Quaternion.RotationYawPitchRoll(rr()*6,rr()*6,rr()*6),new V3(w.x,y,w.z)); bufs[Math.floor(rr()*shapes.length)].push(m); };
  // v53: pulled back from the playable edge: the first ring is fewer, smaller, lower pieces pushed toward the outer side of the cut hex
  const outward=c=>{ const w=hexWorld(c.q,c.r); let x=0,z=0; for(const D of DIRS){ if(!onBoard(c.q+D[0],c.r+D[1])) continue; const o=hexWorld(c.q+D[0],c.r+D[1]); x+=w.x-o.x; z+=w.z-o.z; } const l=Math.hypot(x,z)||1; return new V3(x/l,0,z/l); };
  for(const c of R){ const w0=hexWorld(c.q,c.r), n=c.d===1?2:c.d===2?(mob?2:3):c.d<=4?2:1, ow=c.d===1?outward(c).scale(HW*.24):null;
    for(let i=0;i<n;i++){ const j=c.d===1?.3:.6, w=w0.add(new V3((rr()-.5)*HW*j,0,(rr()-.5)*HS*j*1.4)); if(ow) w.addInPlace(ow);
      const s=c.d===1?(1.6+rr()*2.4)*(debrisWall?.7:1):c.d===2?3.5+rr()*4.5:c.d<=4?5+rr()*7:7+rr()*10;
      const y=c.d===1?-2.8+rr()*2:c.d===2?-3+(rr()-.5)*6:-6+(rr()-.5)*10; put(c,w,s,y,cloudWall?.5:null); }
    if(c.d===1&&!mob){ const w=w0.add(new V3((rr()-.5)*HW*.5,0,(rr()-.5)*HS*.6)).add(ow); put(c,w,.6+rr()*.9,-1.6+rr()*1.4); } } // scree
  const rimMat=rockMatLike(rockMat,'rimRockM'); rimMat.diffuseColor=rockMat.diffuseColor.scale(.5); rimMat.specularColor=rockMat.specularColor.scale(.35); rimMat.emissiveColor=rockMat.emissiveColor.scale(.5); G.env.push(rimMat); // a shade darker than the board's own rocks, so the playfield stays the brightest thing
  shapes.forEach((m,i)=>{ if(!bufs[i].length){ return; } m.material=rimMat; m.isVisible=true; m.isPickable=false; m.alwaysSelectAsActiveMesh=true; m.thinInstanceAdd(bufs[i]); m.receiveShadows=false; try{ if(G.shadow) G.shadow.removeShadowCaster(m); }catch(e){} });
  if(debrisWall&&typeof debThinUpdate==='function'&&G.debThin&&G.debThin.length){ // add wreck plates and spars to the existing debris batches
    for(const c of R) if(c.d<=2) for(let i=0;i<(mob?2:4);i++){ const rec=G.debThin[Math.floor(rr()*G.debThin.length)], w=hexWorld(c.q,c.r).add(new V3((rr()-.5)*HW*.6,(rr()-.4)*5,(rr()-.5)*HS*.8)); rec.items.push({p:w,r:new V3(rr()*6,rr()*6,rr()*6),s:1+rr()*2.4,spin:new V3((rr()-.5)*.15,(rr()-.5)*.15,(rr()-.5)*.15)}); }
    for(const rec of G.debThin){ rec.buf=new Float32Array(rec.items.length*16); for(const x of rec.ms) x.thinInstanceSetBuffer('matrix',rec.buf,16,false); debThinUpdate(rec,0); } }
  if(cloudWall||kind==='planet'){ const nm=addMat('rimNebM',cloudWall?new C3(.3,.36,.85):new C3(.36,.42,.6),cloudWall?.3:.16,G.tex.neb); G.env.push(nm); let k=0;
    for(const c of R){ if(c.d!==1&&c.d!==3) continue; if(rr()>(cloudWall?.5:.22)||k>(mob?14:34)) continue; k++; const pl=MB.CreatePlane('rimNeb',{size:HS*(2.4+rr()*1.8)},sc); pl.position=hexWorld(c.q,c.r).add(new V3(0,-1+rr()*5,0)); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; pl.material=nm; pl.isPickable=false; pl.rotation.z=rr()*6; G.glow.addExcludedMesh(pl); G.env.push(pl); } }
  // centrepieces in the deepest rim pockets
  const deep=R.filter(c=>c.d>=3).sort((a,b)=>b.d-a.d||rr()-.5), used=[], pool={belt:['asteroid','asteroid','station'],station:['station','hulk','asteroid'],planet:['moon','asteroid','station'],storm:['comet','asteroid','moon'],graveyard:['hulk','hulk','station']}[kind]||['asteroid','hulk','station'];
  for(const c of deep){ if(used.length>=(mob?1:2)) break; const w=hexWorld(c.q,c.r); if(used.some(u=>Math.hypot(u.x-w.x,u.z-w.z)<HW*7)) continue;
    let dmin=1e9; for(const b of boardHexes()){ const p=hexWorld(b.q,b.r); dmin=Math.min(dmin,Math.hypot(p.x-w.x,p.z-w.z)); } const Rr=Math.max(HS*1.2,dmin-HS*1.3); if(Rr<HS*1.6) continue;
    const kd=pool[Math.floor(rr()*pool.length)]; try{ HOLE_BUILD[kd](new V3(w.x,-HS*.4,w.z),Math.min(Rr,HS*3.4),rr); used.push(w); }catch(e){ console.warn('rim piece',e); } }
  G.rimPieces=used.length; }
// the rift: a violet tear in space below the board where the chasm runs
function buildRift(cells,rr){ const sc=G.scene, m=emMat('riftM',new C3(.85,.42,1.7),.6); m.opacityTexture=G.tex.soft; m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; G.env.push(m);
  for(const [q,r] of cells){ const c=hexWorld(q,r,0); for(let i=0;i<2;i++){ const pl=MB.CreatePlane('rift',{size:HS*(2.6+rr()*1.4)},sc); pl.position=new V3(c.x+(rr()-.5)*5,-4-rr()*10,c.z+(rr()-.5)*5); pl.rotation.x=Math.PI/2; pl.rotation.y=rr()*6.28; pl.material=m; pl.isPickable=false; G.glow.addExcludedMesh(pl); G.env.push(pl); } } }
function debThinUpdate(rec,dt){ const {items,buf,q,mt,sv}=rec; for(let i=0;i<items.length;i++){ const it=items[i]; it.r.x+=it.spin.x*dt; it.r.y+=it.spin.y*dt; it.r.z+=it.spin.z*dt;
    BABYLON.Quaternion.RotationYawPitchRollToRef(it.r.y,it.r.x,it.r.z,q); sv.set(it.s,it.s,it.s); BABYLON.Matrix.ComposeToRef(sv,q,it.p,mt); mt.copyToArray(buf,i*16); }
  for(const x of rec.ms) if(!x.isDisposed()) x.thinInstanceBufferUpdated('matrix'); }
function buildTerrainFeatures(rr){
  const sc=G.scene, M=facMats('hegemony'); G.storms=[]; G.lightT=0;
  const debBases=[0,1,2].map(k=>{ const b=new SB('hegemony',6); if(k===0){ b.box(M.dark,0,0,0,3,.4,1.2); b.box(M.hull,.8,.3,.2,1.2,.3,.9); } else if(k===1){ b.cylX(M.dark,0,0,0,4,.35,.35,6); b.box(M.hull,-1.2,0,0,.4,1.2,1.2); } else { b.box(M.hull,0,0,0,1.6,1,1.4,.3,.2,.1); b.box(M.dark,0,.6,0,.3,1.4,.3); } const m=b.finish(); m.meshes.forEach(x=>{ x.material=facMats('hegemony').wreck; x.isVisible=false; }); m.root.position.y=-5000; G.env.push(m.root); return m; });
  const debItems=[[],[],[]];
  for(const [k,t] of Object.entries(B.terrain)){ const [q,r]=k.split(',').map(Number); const c=hexWorld(q,r);
    if(t==='debris'){ for(let i=0;i<9;i++){ const k=Math.floor(rr()*3); debItems[k].push({p:c.add(new V3((rr()-.5)*14,(rr()-.2)*5,(rr()-.5)*14)),r:new V3(rr()*6,rr()*6,rr()*6),s:.5+rr()*1.3,spin:new V3((rr()-.5)*.2,(rr()-.5)*.2,(rr()-.5)*.2)}); } }
    if(t==='storm'){ G.storms.push(c); for(let i=0;i<(G.mobile?1:2);i++){ const pl=MB.CreatePlane('storm',{size:(26+rr()*16)*(G.mobile?1.2:1)},sc); /* v44.1: one cloud card per storm hex on phones (overdraw) */ pl.position=c.add(new V3((rr()-.5)*6,2+rr()*6,(rr()-.5)*6)); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; pl.isPickable=false; const sm=addMat('stormM',rr()<.5?new C3(.28,.36,.9):new C3(.45,.3,.85),.36,G.tex.neb); pl.material=sm; pl.rotation.z=rr()*6; G.glow.addExcludedMesh(pl); G.env.push(pl,sm); } } }
  // v44.1: wreck debris is drawn as thin instances (one draw per piece type and material, no scene node per piece); it used to be
  // ~190 instanced hierarchies (~380 active meshes) on a graveyard map, each with its own world matrix every frame
  G.debThin=[]; debBases.forEach((m,k)=>{ const items=debItems[k]; if(!items.length) return; m.root.position.y=0; const buf=new Float32Array(items.length*16);
    const ms=m.meshes.filter(x=>x.getTotalVertices()>0); m.root.getChildMeshes(false).forEach(x=>{ if(!ms.includes(x)) x.setEnabled(false); }); ms.forEach(x=>{ x.isVisible=true; x.isPickable=false; x.alwaysSelectAsActiveMesh=true; x.thinInstanceSetBuffer('matrix',buf,16,false); });
    const rec={items,buf,ms,q:new BABYLON.Quaternion(),mt:new BABYLON.Matrix(),sv:new V3()}; G.debThin.push(rec); debThinUpdate(rec,0); });
  const meta=B.map||{};
  if(meta.station) buildStation(hexWorld(meta.station.q,meta.station.r),rr);
  if(meta.planet) buildNearPlanet(meta.planet);
  if(meta.deadstar) buildDeadStar(hexWorld(meta.deadstar.q,meta.deadstar.r,0));
  if(meta.riftCells) buildRift(meta.riftCells,rr);
  if(meta.holes) buildHoleFills(meta.holes,rr);
  if(meta.wrecks) for(const h of meta.wrecks){ const facs=battleFacs(), f=facs[Math.floor(rr()*facs.length)], cls=['Cruiser','Battleship','Carrier'][Math.floor(rr()*3)];
    const mdl=buildShipModel({fac:f,cls,isSq:false,side:'enemy',tpl:'wreck'}); if(mdl.toSplit) mdl.toSplit(); const Mw=facMats(f); mdl.meshes.forEach(m=>{ m.material=(m.material===Mw.win||m.material===Mw.eng||m.material===Mw.tip||m.material===Mw.sail)?Mw.ember:Mw.wreck; m.isPickable=false; }); mdl.plumes.forEach(p=>p.dispose()); (mdl.flares||[]).forEach(p=>p.dispose());
    const c=hexWorld(h.q,h.r,1.5); mdl.root.position=c; mdl.root.scaling.setAll(Math.min(1,HS*1.7/Math.max(1,mdl.L))); /* a wreck fills its own hex, not its neighbours */ mdl.root.rotation.set((rr()-.5)*.5,rr()*6.28,(rr()-.5)*.7); mdl.fore.position.x+=mdl.L*.08; mdl.fore.rotation.set((rr()-.5)*.4,(rr()-.5)*.5,(rr()-.5)*.4); mdl.aft.rotation.z=(rr()-.5)*.3; G.env.push(mdl.root); (G._wreckMeshes=G._wreckMeshes||[]).push(...mdl.meshes, ...mdl.root.getChildMeshes(false).filter(m=>m.name.endsWith('emblem'))); }
  // wrecks never move: bake them into one mesh per material (dozens of draw calls become a handful)
  if(G._wreckMeshes&&G._wreckMeshes.length){ const by=new Map(); for(const m of G._wreckMeshes){ if(m.isDisposed()) continue; if(!by.has(m.material)) by.set(m.material,[]); by.get(m.material).push(m); }
    for(const [mat,ms] of by){ if(ms.length<2) continue; try{ const mm=BABYLON.Mesh.MergeMeshes(ms,true,true); if(mm){ mm.name='wreckMerged'; mm.material=mat; mm.isPickable=false; mm.receiveShadows=true; G.env.push(mm); } }catch(e){ console.warn('wreck merge',e); } }
    G._wreckMeshes=null; }
}
// v47: three station types, matched to the sector: an orbital ring hub, a scaffolded mining rig, or a dark derelict spire
function buildStation(c,rr){ const kind=(B&&B.biome&&B.biome.station)||'ring'; if(typeof buildMeshStation==='function'&&aiHullsOn()&&buildMeshStation(c,rr)) return; /* v53.7: the concept station mesh on every station map (the old procedural spire and rig, with windows and spikes floating off the hull, showed on Engagement fights; Ryan's Pixel shot Oct 21). The builders below are only the fallback when the meshes did not load */ if(kind==='rig') return buildRigStation(c,rr); if(kind==='spire') return buildSpireStation(c,rr); return buildRingStation(c,rr); }
function stationFinish(b,c,rr){ const m=b.finish(); m.root.position=c.add(new V3(0,4,0)); m.root.rotation.set(.12,rr()*6,.08); m.meshes.forEach(x=>x.isPickable=false); G.env.push(m.root); G.station=m; }
function buildRigStation(c,rr){ const b=new SB('corsair',30), M=b.M;
  b.cylY(M.dark,0,-14,0,30,2.4,2.8,8); b.cylY(M.hull,0,9,0,7,6.5,6.5,12); b.cylY(M.steel,0,16,0,2,3,6.5,12); b.cylY(M.dark,0,-16,0,3,4.5,2.6,8);
  for(let i=0;i<3;i++){ const a=i*2.094+.3; b.box(M.steel,Math.cos(a)*8,2,Math.sin(a)*8,16,1.2,1.4,0,-a,0); b.box(M.hull,Math.cos(a)*16,2,Math.sin(a)*16,3.2,3.2,3.2,0,-a,0); b.box(M.dark,Math.cos(a)*16,-3,Math.sin(a)*16,.8,7,.8,0,-a,0); }
  for(const y of [-8,-2,4]){ const pts=[]; for(let a=0;a<=360;a+=20){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*5.2,y,Math.sin(r)*5.2)); } tube(b,M.steel,pts,()=>.35,5); }
  b.box(M.trim,4,14,0,14,1,1.2,0,.4,.5); for(let i=0;i<14;i++){ const a=rr()*6.28; b.box(M.win,Math.cos(a)*6.6,7+rr()*6,Math.sin(a)*6.6,.5,.3,.5); }
  for(let i=0;i<4;i++) b.flashers.push(b.sph(M.tip,(rr()-.5)*30,2,(rr()-.5)*30,.5)); stationFinish(b,c,rr); }
function buildSpireStation(c,rr){ const b=new SB('voidsworn',30), M=b.M;
  b.cylY(M.hull,0,-10,0,34,1.2,6,8); b.cylY(M.dark,0,-14,0,5,6,3,8); b.cylY(M.trim,0,22,0,8,0,1.2,6);
  for(let i=0;i<4;i++){ const a=i*Math.PI/2+.4; b.box(M.dark,Math.cos(a)*6,-2,Math.sin(a)*6,2,18,1.4,0,-a,.22*(i%2?1:-1)); b.cylY(M.trim,Math.cos(a)*9,6,Math.sin(a)*9,9,0,.8,6); }
  const pts=[]; for(let a=0;a<=360;a+=10){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*11,-4,Math.sin(r)*11)); } tube(b,M.dark,pts,()=>.9,6);
  for(let i=0;i<18;i++){ const a=rr()*6.28, y=-6+rr()*22; b.box(M.win,Math.cos(a)*(5.8-y*.13),y,Math.sin(a)*(5.8-y*.13),.4,.9,.4); }
  for(let i=0;i<3;i++) b.flashers.push(b.sph(M.tip,(rr()-.5)*4,10+rr()*12,(rr()-.5)*4,.45)); stationFinish(b,c,rr); }
function buildRingStation(c,rr){
  const b=new SB('hegemony',30), M=b.M;
  b.cylY(M.hull,0,-8,0,18,6,7,16); b.cylY(M.dark,0,10,0,4,3.2,5,16); b.cylY(M.dark,0,-12,0,4,5,3,16); b.cylY(M.dark,0,14,0,9,.2,.6,6);
  for(let i=0;i<4;i++){ const a=i*Math.PI/2+.4; b.box(M.dark,Math.cos(a)*7.5,0,Math.sin(a)*7.5,9,1.1,1.1,0,-a,0); }
  for(let a0=0;a0<360;a0+=90){ const pts=[]; for(let a=a0+8;a<=a0+72;a+=4){ const r=a*Math.PI/180; pts.push(new V3(Math.cos(r)*14,0,Math.sin(r)*14)); } tube(b,M.hull,pts,()=>1.5,8); }
  for(let i=0;i<24;i++){ const a=rr()*Math.PI*2; b.box(M.win,Math.cos(a)*14.6,(rr()-.5)*1.4,Math.sin(a)*14.6,.5,.3,.5); }
  for(const s of [1,-1]){ b.box(M.dark,s*20,2,0,10,.2,5); for(let k=0;k<4;k++) b.box(M.trim,s*(16.5+k*2.3),2.15,0,1.9,.05,4.6); }
  for(let i=0;i<5;i++) b.flashers.push(b.sph(M.tip,(rr()-.5)*6,-8+rr()*20,(rr()-.5)*6,.5));
  const m=b.finish(); m.root.position=c.add(new V3(0,4,0)); m.root.rotation.set(.18,rr()*6,.12); m.meshes.forEach(x=>x.isPickable=false); G.env.push(m.root); G.station=m;
}
function buildNearPlanet(P){ // v42: the planet under the battlefield uses the procedural planet shader (relief, oceans, two cloud decks, city lights, limb scattering)
  const edge=planetEdge(P.R), Rs=edge/.89, c=hexWorld(P.q,P.r,-Rs*.45), fac=(B&&B.cfg&&B.cfg.fac)||'voidsworn';
  const p=MB.CreateSphere('nearPlanet',{diameter:Rs*2,segments:G.mobile?72:128},G.scene); p.position=c; p.rotation.set(.3,.8,0); p.isPickable=false; const look=(B&&B.biome&&B.biome.planet!=null)?B.biome.planet:null; p.material=nearPlanetMaterial(fac,look);
  const at=MB.CreateSphere('nearAtmo',{diameter:Rs*2.035,segments:G.mobile?48:80},G.scene); at.position=c; at.isPickable=false; at.material=atmoMaterial('nearAtmoM'); at.material.setColor3('atmo',new C3(.45,.7,1).scale(.9));
  G.glow.addExcludedMesh(p); G.glow.addExcludedMesh(at); G.nearPlanet=p; G.nearAtmo=at; G.npClouds=null; G.env.push(p,at,p.material,at.material);
  // v47: a gas giant gets its ring system and a pair of moons; rocky and ice worlds keep a clear sky
  try{ const L=look!=null&&PLANET_LOOKS[look]; if(L){ at.material.setColor3('atmo',new C3(L.atmo[0],L.atmo[1],L.atmo[2]).scale(.9)); }
    if(L&&L.kind===0){ const ring=MB.CreateDisc('npRing',{radius:Rs*1.34,tessellation:160,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene); ring.position=c.clone(); ring.rotation.set(Math.PI/2,0,0); ring.isPickable=false; /* flat, level with the planet's equator, well below the board: the fleets skim above the ring plane */
      const rt=dynTex('npRingT',512,8,(g,w)=>{ const r=seeded(21); for(let x=0;x<w;x++){ const u=x/w, band=u<.78?0:(.35+.65*Math.abs(Math.sin(u*41+r()*.4))*(u>.92?.4:1)); g.fillStyle=`rgba(${Math.round(200+L.pc[0]*50)},${Math.round(180+L.pc[1]*60)},${Math.round(150+L.pc[2]*80)},${(band*(.55+r()*.4)).toFixed(3)})`; g.fillRect(x,0,1,8); } });
      const rm=new BABYLON.StandardMaterial('npRingM',G.scene); rm.diffuseTexture=rt; rm.diffuseTexture.hasAlpha=true; rm.useAlphaFromDiffuseTexture=true; rm.backFaceCulling=false; rm.specularColor=C3.Black(); rm.emissiveColor=new C3(.22,.2,.19); rm.alpha=.42; rm.disableDepthWrite=true;
      ring.material=rm; const uv=[]; const pos=ring.getVerticesData(BABYLON.VertexBuffer.PositionKind); for(let i=0;i<pos.length;i+=3){ const rr2=Math.hypot(pos[i],pos[i+1])/(Rs*1.34); uv.push(rr2,.5); } ring.setVerticesData(BABYLON.VertexBuffer.UVKind,uv);
      G.glow.addExcludedMesh(ring); G.env.push(ring,rm,rt);
      for(let i=0;i<2;i++){ const mr=Rs*(.09+.05*i), a=1.1+i*1.9, d=Rs*(2.3+i*.7), moon=MB.CreateSphere('npMoon',{diameter:mr*2,segments:40},G.scene); moon.position=c.add(new V3(Math.cos(a)*d,Rs*(.35+.25*i),Math.sin(a)*d*.6)); moon.isPickable=false;
        const mm=planetMaterial('npMoonM'+i); lookTo(mm,PLANET_LOOKS[i?7:5],3+i*2); mm.setFloat('oct',5); mm.setFloat('expo',.9); mm.setFloat('freq',2.4); moon.material=mm; G.glow.addExcludedMesh(moon); G.env.push(moon,mm); (G.nearMats=G.nearMats||[]).push(mm); } } }catch(e){ console.warn('gas giant extras',e); }
}
function updateStorms(dt){
  if(!G.storms||!G.storms.length||G.fxReduced) return; G.lightT-=dt; if(G.lightT>0) return; G.lightT=.25+Math.random()*.7;
  const c=G.storms[Math.floor(Math.random()*G.storms.length)]; const pts=[]; let p=c.add(new V3((Math.random()-.5)*12,9+Math.random()*4,(Math.random()-.5)*12));
  for(let i=0;i<7;i++){ pts.push(p.clone()); p=p.add(new V3((Math.random()-.5)*4,-1.6-Math.random()*1.2,(Math.random()-.5)*4)); }
  for(let i=0;i<pts.length-1;i++) lineSprite(pts[i],pts[i+1],.3,new C3(1.4,1.6,2.2),{dur:.14,fade:1.2}); /* v53-I: pooled sprite segments */
  flash(pts[Math.floor(pts.length/2)],10,new C3(.6,.7,1),.25);
}

// ---------- background life: asteroid belt, distant traffic, colour grading ----------
function buildBelt(rr,bases){ const belt=bases[2].clone('belt'); belt.isVisible=true; belt.isPickable=false; G.glow.addExcludedMesh(belt); const n=2500, buf=new Float32Array(16*n);
  for(let i=0;i<n;i++){ const a=rr()*Math.PI*2, d=650+rr()*700, s=1.5+Math.pow(rr(),3)*14; const m=BABYLON.Matrix.Compose(new V3(s,s*.8,s),BABYLON.Quaternion.RotationYawPitchRoll(rr()*6,rr()*6,rr()*6),new V3(Math.cos(a)*d*1.3,-210+(rr()-.5)*120+Math.sin(a*3)*40,Math.sin(a)*d)); m.copyToArray(buf,i*16); }
  belt.thinInstanceSetBuffer('matrix',buf,16); G.env.push(belt); }
function buildTraffic(rr){ G.traffic=[]; if(!B||B.showcase==='fleet') return; const fac=(B.cfg&&B.cfg.fac)||'hegemony';
  for(let i=0;i<(G.mobile?0:3);i++){ try{ const md=buildShipModel({fac:i===1?'voidsworn':fac,cls:i===2?'Cruiser':'Battleship',isSq:false,side:'enemy',tpl:'bg'}); /* phones skip the distant traffic */ md.meshes.forEach(m=>{ m.isPickable=false; if(G.shadow) G.shadow.removeShadowCaster(m); });
      const a=(rr()-.5)*1.6+(i%2?Math.PI:0), d=1100+rr()*900; md.root.position=new V3(Math.cos(a)*d,-60+rr()*140,Math.sin(a)*d+600); md.root.scaling.setAll(3.5+rr()*2); md.root.rotation.y=rr()*6.28;
      G.traffic.push({root:md.root,vel:new V3(Math.cos(md.root.rotation.y),0,-Math.sin(md.root.rotation.y)).scale(2.5+rr()*3)}); G.env.push(md.root); }catch(e){} } }
const FAC_GRADE={voidsworn:[38,8],hegemony:[212,8],corsair:[24,10],chorus:[312,9],ithar:[186,9],deathless:[138,9]}; // v42: each enemy faction's space tints the highlights
function hueMix(a,b,k){ let d=((b-a)%360+540)%360-180; return Math.round((a+d*k+360)%360); }
function gradeFor(map,fac){ try{ const ip=G.pipe.imageProcessing; ip.colorCurvesEnabled=true; const cc=new BABYLON.ColorCurves();
  const g={belt:[35,22,215,12],station:[190,10,210,14],planet:[200,16,30,10],storm:[275,24,250,18],graveyard:[25,26,210,22],none:[40,14,220,10]}[map||'none']||[40,14,220,10];
  const fg=FAC_GRADE[fac]; cc.highlightsHue=fg?hueMix(g[0],fg[0],.6):g[0]; cc.highlightsDensity=g[1]+(fg?fg[1]:0); cc.highlightsSaturation=20; cc.shadowsHue=g[2]; cc.shadowsDensity=g[3]; cc.shadowsSaturation=25; cc.globalSaturation=8; ip.colorCurves=cc; }catch(e){} }
