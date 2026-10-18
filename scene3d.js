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
  const engine=new BABYLON.Engine(canvas,true,{stencil:true,antialias:true,preserveDrawingBuffer:true},true);
  const scene=new BABYLON.Scene(engine);
  scene.clearColor=new C4(.01,.015,.03,1);
  scene.ambientColor=new C3(.2,.22,.28);
  scene.skipPointerMovePicking=true;
  const cam=new BABYLON.ArcRotateCamera('cam',-Math.PI/2,.84,290,new V3(-90,0,-10),scene);
  cam.minZ=.5; cam.maxZ=30000; cam.fov=.72; cam.lowerBetaLimit=.04; cam.upperBetaLimit=1.42;
  // lights: warm key from behind the viewer, cool fill from the far side
  const sun=new BABYLON.DirectionalLight('sun',new V3(-.45,-.62,.64).normalize(),scene); sun.intensity=3; sun.diffuse=new C3(1,.86,.68); sun.specular=new C3(1,.9,.75);
  const fill=new BABYLON.DirectionalLight('fill',new V3(.55,-.25,-.8).normalize(),scene); fill.intensity=1.7; fill.diffuse=new C3(.42,.72,1); fill.specular=new C3(.5,.8,1); G.rim=fill; /* cool rim against the warm key: ships read as silhouettes */
  const hemi=new BABYLON.HemisphericLight('hemi',new V3(0,1,0),scene); hemi.intensity=.34; hemi.diffuse=new C3(.4,.5,.75); hemi.groundColor=new C3(.08,.06,.12); hemi.specular=C3.Black();
  const glow=new BABYLON.GlowLayer('glow',scene,{mainTextureFixedSize:1024,blurKernelSize:48}); glow.intensity=.6;
  const pipe=new BABYLON.DefaultRenderingPipeline('pipe',true,scene,[cam]);
  pipe.samples=4; pipe.fxaaEnabled=true;
  pipe.bloomEnabled=true; pipe.bloomThreshold=.5; pipe.bloomWeight=.55; pipe.bloomKernel=72; pipe.bloomScale=.5;
  pipe.imageProcessingEnabled=true;
  const ip=pipe.imageProcessing; ip.toneMappingEnabled=true; ip.toneMappingType=BABYLON.ImageProcessingConfiguration.TONEMAPPING_ACES; ip.exposure=1.12; ip.contrast=1.42;
  { const cc=new BABYLON.ColorCurves(); cc.globalSaturation=18; cc.shadowsHue=205; cc.shadowsDensity=45; cc.shadowsSaturation=35; cc.highlightsHue=32; cc.highlightsDensity=28; cc.highlightsSaturation=25; ip.colorCurvesEnabled=true; ip.colorCurves=cc; } // cinematic grade: teal shadows, warm highlights
  ip.vignetteEnabled=true; ip.vignetteWeight=3.2; ip.vignetteColor=new C4(0,0,0,0); ip.vignetteStretch=.2;
  pipe.chromaticAberrationEnabled=true; pipe.chromaticAberration.aberrationAmount=10; pipe.chromaticAberration.radialIntensity=.8;
  pipe.grainEnabled=true; pipe.grain.intensity=5; pipe.grain.animated=true;
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
  scene.onBeforeRenderObservable.add(()=>{ const now=performance.now(); const raw=(now-last)/1000, dt=Math.min(.05,raw); last=now; try{ FRAMES.tick(raw); }catch(e){} G.time+=dt; try{ G.ctl.update(dt); updateWorld(dt); updateStorms(dt); if(G.planet) G.planet.rotation.y+=dt*.0025; if(G.npClouds) G.npClouds.rotation.y+=dt*.006; if(G.ringNode) G.ringNode.rotation.y+=dt*.003; if(G.planet) G.planet.rotation.y+=dt*.004; if(G.npClouds) G.npClouds.rotation.y+=dt*.01; if(G.traffic) for(const t of G.traffic) if(!t.root.isDisposed()) t.root.position.addInPlace(t.vel.scale(dt)); if(G.gridFar) G.gridFar.alpha=clamp((G.cam.radius-260)/240,0,1)*.6; }catch(e){ frameError(e); } });
  // phones: ~30 fps in play, ~15 fps when idle, to save battery and heat
  ['pointerdown','pointermove','keydown','wheel'].forEach(ev=>window.addEventListener(ev,()=>{ G.lastInput=performance.now(); },{passive:true}));
  engine.runRenderLoop(()=>{ if(G.mobile){ G.fskip=(G.fskip||0)+1; const idle=performance.now()-G.lastInput>4000&&!(typeof PROJ!=='undefined'&&PROJ.length)&&!(B&&B.busy)&&scene.particleSystems.length<=1; if(G.fskip%(idle?4:2)) return; } try{ scene.render(); }catch(e){ frameError(e); } });
}

function noiseTex(name,size,seed,soft=.55){ return dynTex(name,size,size,(g,w)=>{ const img=g.createImageData(w,w), d=img.data;
    const hs=(x,y)=>{ const v=Math.sin(x*127.1+y*311.7+seed*13.7)*43758.5453; return v-Math.floor(v); };
    const ns=(x,y)=>{ const xi=Math.floor(x),yi=Math.floor(y),xf=x-xi,yf=y-yi,u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf); return (hs(xi,yi)*(1-u)+hs(xi+1,yi)*u)*(1-v)+(hs(xi,yi+1)*(1-u)+hs(xi+1,yi+1)*u)*v; };
    for(let y=0;y<w;y++) for(let x=0;x<w;x++){ const dx=x/w-.5, dy=y/w-.5, r=Math.hypot(dx,dy)*2; let a=.5,t=0,px=x/w*5,py=y/w*5; const wx=ns(px*.7+9,py*.7), wy=ns(px*.7,py*.7+4); px+=wx*2; py+=wy*2; for(let o=0;o<5;o++){ t+=a*ns(px,py); px*=2.05; py*=2.05; a*=.5; }
      const v=clamp((t-.35)*2.2,0,1)*Math.pow(clamp(1-r,0,1),soft); const o=(y*w+x)*4; d[o]=d[o+1]=d[o+2]=255; d[o+3]=v*255; }
    g.putImageData(img,0,0); }); }
function makeSunAndSky(){
  const sc=G.scene, dir=new V3(-.55,.22,.8).normalize(), pos=dir.scale(9000); G.sunPosW=pos.clone();
  const sun=MB.CreatePlane('sun',{size:900},sc); sun.position=pos; sun.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; sun.infiniteDistance=true; sun.isPickable=false;
  sun.material=addMat('sunM',new C3(2.2,1.9,1.5),1,G.tex.flare); G.glow.addExcludedMesh(sun); G.sunMesh=sun;
  const halo=MB.CreatePlane('sunHalo',{size:3400},sc); halo.position=pos.scale(1.001); halo.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; halo.infiniteDistance=true; halo.isPickable=false; halo.material=addMat('haloM',new C3(.55,.38,.22),.55,G.tex.soft); G.glow.addExcludedMesh(halo);
  try{ const emitter=MB.CreateBox('flareEmitter',{size:1},sc); emitter.position=pos; emitter.isVisible=false; emitter.isPickable=false; emitter.infiniteDistance=true;
    const mk=(draw)=>{ const c=document.createElement('canvas'); c.width=c.height=256; const g=c.getContext('2d'); draw(g,256); return c.toDataURL(); };
    const ringT=mk((g,w)=>{ const gr=g.createRadialGradient(w/2,w/2,w*.3,w/2,w/2,w/2); gr.addColorStop(0,'rgba(255,255,255,0)'); gr.addColorStop(.8,'rgba(255,255,255,.35)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); });
    const hexT=mk((g,w)=>{ g.fillStyle='rgba(255,255,255,.28)'; g.beginPath(); for(let i=0;i<6;i++){ const a=i*Math.PI/3; g.lineTo(w/2+Math.cos(a)*w*.45,w/2+Math.sin(a)*w*.45); } g.fill(); });
    const glowT=mk((g,w)=>{ const gr=g.createRadialGradient(w/2,w/2,0,w/2,w/2,w/2); gr.addColorStop(0,'rgba(255,255,255,.9)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(0,0,w,w); });
    const lfs=new BABYLON.LensFlareSystem('lfs',emitter,sc);
    new BABYLON.LensFlare(.35,0,new C3(1,.85,.6),glowT,lfs); new BABYLON.LensFlare(.08,.25,new C3(.6,.8,1),hexT,lfs); new BABYLON.LensFlare(.14,.45,new C3(1,.6,.3),hexT,lfs);
    new BABYLON.LensFlare(.22,.7,new C3(.5,.7,1),ringT,lfs); new BABYLON.LensFlare(.05,.85,new C3(1,.9,.7),hexT,lfs); new BABYLON.LensFlare(.4,1.1,new C3(.35,.5,.9),ringT,lfs); G.lfs=lfs; }catch(e){ console.warn('lens flare unavailable',e); }
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
    sg.filteringQuality=BABYLON.ShadowGenerator.QUALITY_MEDIUM; sg.darkness=.32; sg.bias=.003; sg.normalBias=.015; G.shadow=sg; }catch(e){ console.warn('shadows unavailable',e); G.shadow=null; }
}
function makeSSAO(){
  try{ if(!BABYLON.SSAO2RenderingPipeline.IsSupported) return; const p=new BABYLON.SSAO2RenderingPipeline('ssao',G.scene,{ssaoRatio:.5,blurRatio:.5},[G.cam],true);
    p.radius=2.4; p.totalStrength=1.15; p.base=.12; p.samples=16; p.maxZ=1600; p.minZAspect=.4; p.expensiveBlur=true; G.ssao=p; }catch(e){ console.warn('ssao unavailable',e); G.ssao=null; }
}
function castShadows(mesh){ mesh.receiveShadows=true; if(G.shadow) G.shadow.addShadowCaster(mesh,false); }
function setQuality(q){
  G.quality=q; const ultra=q==='ultra', hi=q!=='medium';
  const taa=ultra&&!!G.taaOn; if(taa&&!G.taa){ try{ G.taa=new BABYLON.TAARenderingPipeline('taa',G.scene,[G.cam]); G.taa.samples=8; }catch(e){ console.warn('TAA unavailable',e); G.taaOn=false; } } if(G.taa) G.taa.isEnabled=taa;
  if(G.shadow) G.sun.shadowEnabled=hi; try{ if(G.shadow) G.shadow.filteringQuality=ultra?BABYLON.ShadowGenerator.QUALITY_HIGH:BABYLON.ShadowGenerator.QUALITY_MEDIUM; G.pipe.bloomKernel=ultra?96:hi?72:48; }catch(e){} // Ultra: softer shadows, wider bloom, up to four weapon lights
  const mgr=G.scene.postProcessRenderPipelineManager;
  try{ if(ultra&&!G.vls&&G.sunMesh){ G.vls=new BABYLON.VolumetricLightScatteringPostProcess('vls',.5,G.cam,G.sunMesh,70,BABYLON.Texture.BILINEAR_SAMPLINGMODE,G.engine,false,G.scene); G.vls.exposure=.22; G.vls.decay=.965; G.vls.weight=.5; G.vls.density=.9;
    // points and lines break the occlusion pass (no element buffer), so keep them out of it
    const skipVls=m=>{ if(!G.vls) return; if(m instanceof BABYLON.LinesMesh||(m.material&&m.material.pointsCloud)||m===G.stars||m===G.sky) G.vls.excludedMeshes.push(m); };
    G.scene.meshes.forEach(skipVls); G.scene.onNewMeshAddedObservable.add(m=>setTimeout(()=>skipVls(m),0)); } else if(!ultra&&G.vls){ G.vls.dispose(G.cam); G.vls=null; } }catch(e){ console.warn('god rays unavailable',e); G.vls=null; }
  if(G.ssao){ if(G.ssaoOn===undefined) G.ssaoOn=true; if(ultra&&!G.ssaoOn){ mgr.attachCamerasToRenderPipeline('ssao',G.cam); G.ssaoOn=true; } else if(!ultra&&G.ssaoOn){ mgr.detachCamerasFromRenderPipeline('ssao',G.cam); G.ssaoOn=false; } }
  G.pipe.samples=hi&&!(ultra&&G.taaOn)?4:1; G.pipe.fxaaEnabled=!(ultra&&G.taaOn); G.pipe.chromaticAberrationEnabled=hi&&!G.fxReduced; G.pipe.grainEnabled=hi; G.glow.intensity=hi?.6:.45;
  const dpr=window.devicePixelRatio||1; // v42: Medium renders at about 1.5x CSS pixels (was clamped to 1x: 41% of a Pixel's resolution per axis), width capped at 720
  G.engine.setHardwareScalingLevel(q==='medium'?1/Math.max(1,Math.min(dpr,1.5,720/Math.max(320,innerWidth))):ultra&&!G.mobile&&dpr<1.5?1/Math.min(1.25,1.25*dpr):1/Math.min(2,dpr)); // Ultra supersamples 1.25x on screens below 4K
  G.pipe.sharpenEnabled=hi; G.glow.isEnabled=hi; try{ for(const M of Object.values(MATS)) for(const k of ['hull','dark','steel','trim']) if(M[k]) M[k].markAsDirty(BABYLON.Material.AllDirtyFlag); }catch(e){} // hull shading detail follows the quality level // the phone image is sharp enough now, and bloom carries the emissives
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
function applyBiome(fac){ try{ const b=BIOMES[fac]||BIOMES.voidsworn, m=G.skyMat, k=1.45; if(!m) return; m.setColor3('c1',new C3(...b[0]).scale(k)); m.setColor3('c2',new C3(...b[1]).scale(k)); m.setColor3('c3',new C3(...b[2]).scale(k*1.1)); m.setFloat('seed',.1+Math.random()*.8);
  if(G.nebMats) G.nebMats.forEach((nm,i)=>{ nm.setColor3('ca',new C3(...b[i%2]).scale(.9)); nm.setColor3('cb',new C3(...b[(i+1)%3]).scale(1.1)); nm.setFloat('seed',Math.random()*20); });
  if(G.nebBaked) G.nebBaked.forEach((nm,i)=>rebakeNebula(nm,new C3(...b[i%2]).scale(.9),new C3(...b[(i+1)%3]).scale(1.1),Math.random()*20));
  composeBackdrop(fac); }catch(e){ console.warn(e); } } // v42: each battle also gets its own planet and re-coloured nebula banks
// light the grid up around a hex (the selected ship); with no focus the whole grid stays a faint wash
function gridFocus(c,R){ const g=G.grid; if(!g||g.isDisposed()||!G.gridHexes) return; R=R||6; const key=c?c.q+','+c.r+','+R:'none'; if(G.gridKey===key) return; G.gridKey=key;
  const cols=new Float32Array(G.gridHexes.length*28); let o=0;
  for(const h of G.gridHexes){ let a=.075; if(c){ const d=hdist(h,c); a=d<=R?.5-.36*(d/R):Math.max(.06,.14-.03*(d-R)); } for(let i=0;i<7;i++){ cols[o++]=.5; cols[o++]=.82; cols[o++]=1; cols[o++]=a; } }
  try{ g.updateVerticesData(BABYLON.VertexBuffer.ColorKind,cols); }catch(e){ console.warn(e); } }
function buildBattleEnv(){
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
  // asteroids
  const rockMat=new BABYLON.StandardMaterial('rockM',sc);
  rockMat.diffuseTexture=dynTex('rockTex',256,256,(g,w)=>{ const r=seeded(5); g.fillStyle='#5d544c'; g.fillRect(0,0,w,w); for(let i=0;i<900;i++){ const s=r()*6+1; g.fillStyle=`rgba(${r()<.5?'20,16,14':'150,140,125'},${r()*.35})`; g.fillRect(r()*w,r()*w,s,s);} });
  rockMat.diffuseTexture.hasAlpha=false; rockMat.specularColor=new C3(.08,.08,.08); { const rm=mapsFromCanvas('rockMaps',rockMat.diffuseTexture.getContext().canvas,{strength:5}); rm.orm.dispose(); rockMat.bumpTexture=rm.normal; } rockMat.bumpTexture.level=1.2; if(typeof addRockFx==='function') addRockFx(rockMat); G.env.push(rockMat);
  const bases=[]; for(let k=0;k<4;k++){ const rr=seeded(100+k); const m=MB.CreateIcoSphere('rockBase'+k,{radius:1,subdivisions:3},sc);
    const p=m.getVerticesData(BABYLON.VertexBuffer.PositionKind); for(let i=0;i<p.length;i+=3){ const x=p[i],y=p[i+1],z=p[i+2]; const n=1+.28*Math.sin(x*3.1+k)*Math.cos(y*2.7+k*2)+.18*Math.sin(z*5.3+x*2)+(rr()-.5)*.08; p[i]=x*n*(1+.3*(k%2)); p[i+1]=y*n*.8; p[i+2]=z*n; }
    m.setVerticesData(BABYLON.VertexBuffer.PositionKind,p); m.convertToFlatShadedMesh(); m.material=rockMat; m.isVisible=false; m.isPickable=false; castShadows(m); G.glow.addExcludedMesh(m); bases.push(m); G.env.push(m); }
  G.rocks=[];
  const rr=seeded(B.seed||42);
  const addRock=(pos,s)=>{ const inst=bases[Math.floor(rr()*4)].createInstance('rock'); inst.position=pos; inst.scaling.setAll(s); inst.rotation.set(rr()*6,rr()*6,rr()*6); inst.isPickable=false; inst.spin=new V3((rr()-.5)*.1,(rr()-.5)*.14,(rr()-.5)*.1); G.rocks.push(inst); G.env.push(inst); };
  for(const [k,t] of Object.entries(B.terrain)){ const [q,r]=k.split(',').map(Number); const c=hexWorld(q,r);
    if(t==='rock'){ addRock(c.add(new V3(0,1.5,0)),4+rr()*2.5); for(let i=0;i<4;i++) addRock(c.add(new V3((rr()-.5)*8,(rr()-.3)*5,(rr()-.5)*8)),1+rr()*2.2); }
    if(t==='neb'){ for(let i=0;i<3;i++){ const pl=MB.CreatePlane('neb',{size:22+rr()*14},sc); pl.position=c.add(new V3((rr()-.5)*8,1+rr()*6,(rr()-.5)*8)); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; pl.isPickable=false;
        const nm=addMat('nebM',rr()<.5?new C3(.42,.25,.62):new C3(.25,.35,.7),.34,G.tex.neb); pl.material=nm; pl.rotation.z=rr()*6; G.glow.addExcludedMesh(pl); G.env.push(pl,nm); } } }
  // distant decorative rocks below and around the table for depth
  for(let i=0;i<70;i++){ const a=rr()*Math.PI*2, d=G.bx*.9+rr()*380; addRock(new V3(Math.cos(a)*d*1.15,-50-rr()*200,Math.sin(a)*d*.8),2+rr()*12); }
  { const ring=bases[0].clone('rockRing'); ring.isVisible=true; ring.material=rockMat; ring.isPickable=false; G.glow.addExcludedMesh(ring); const node=new BABYLON.TransformNode('ringNode',sc); ring.parent=node; const mats=[];
    for(let i=0;i<2500;i++){ const a=rr()*Math.PI*2, d=G.bx*(1.15+rr()*.75), s=.4+Math.pow(rr(),3)*4; mats.push(BABYLON.Matrix.Compose(new V3(s,s*(.6+rr()*.6),s),BABYLON.Quaternion.RotationYawPitchRoll(rr()*6,rr()*6,rr()*6),new V3(Math.cos(a)*d,-70-rr()*170+Math.sin(a*3)*25,Math.sin(a)*d*.75))); }
    ring.thinInstanceAdd(mats); G.ringNode=node; G.env.push(ring,node); }
  buildTerrainFeatures(rr); try{ buildTerrainTints(); }catch(e){ console.error(e); }
  buildBelt(rr,bases); buildTraffic(rr); gradeFor((B.map||{}).map,B.cfg&&B.cfg.fac);
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
    canvas.addEventListener('wheel',e=>{ e.preventDefault(); this.attract=false; this.estab=null; const k=Math.exp(e.deltaY*.0011); this.r=clamp(this.r*k,22,900); },{passive:false});
    window.addEventListener('keydown',e=>{ if(e.target.tagName==='INPUT') return; this.keys.add(e.key.toLowerCase()); });
    window.addEventListener('keyup',e=>this.keys.delete(e.key.toLowerCase()));
    window.addEventListener('blur',()=>this.keys.clear()); }
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
    // portrait phones: look up the field from behind your fleet (yours at the bottom, theirs at the top) instead of across a board too wide to fit
    try{ if(innerHeight>innerWidth*1.1&&typeof B!=='undefined'&&B&&!B.showcase&&B.units){ const pl=B.units.filter(u=>u.side==='player'&&!u.dead&&!u.isSq), en=B.units.filter(u=>u.side==='enemy'&&!u.dead&&!u.isSq);
      const avg=l=>{ let x=0,z=0; for(const u of l){ const p=hexWorld(u.q,u.r,0); x+=p.x; z+=p.z; } return new V3(x/l.length,0,z/l.length); };
      if(pl.length){ const P=avg(pl), E=en.length?avg(en):P.add(new V3(100,0,0)), d=E.subtract(P); d.y=0; const L=Math.max(1,d.length());
        const ux=-d.z/L, uz=d.x/L; let spread=0; for(const u of pl.concat(en)){ const p=hexWorld(u.q,u.r,0); spread=Math.max(spread,Math.abs((p.x-P.x)*ux+(p.z-P.z)*uz)); } /* v35: frame the fleets, not the whole board, so ships read on a phone */
        this.a=Math.atan2(-d.z,-d.x); this.b=.64; this.r=clamp(Math.max(L*1.55,spread*2.3),170,380); this.t=P.add(d.scale(.32)); } } }catch(e){ console.warn(e); } }
  hold(t,a,b,r){ if(!this.saved) this.saved={a:this.a,b:this.b,r:this.r,t:this.t.clone()}; this.t=t; if(a!=null) this.a=a; if(b!=null) this.b=b; if(r!=null) this.r=r; }
  release(){ if(G.pipe&&G.pipe.depthOfFieldEnabled) G.pipe.depthOfFieldEnabled=false; if(this.saved){ Object.assign(this,{a:this.saved.a,b:this.saved.b,r:this.saved.r,t:this.saved.t}); this.saved=null; } }
  update(dt){
    const c=this.cam;
    if(this.attract){ this.a+=dt*.05; }
    let px=0,pz=0; const k=this.keys;
    if(!document.querySelector('.intro')){ if(k.has('w')||k.has('arrowup')) pz+=1; if(k.has('s')||k.has('arrowdown')) pz-=1; if(k.has('a')||k.has('arrowleft')) px-=1; if(k.has('d')||k.has('arrowright')) px+=1; }
    if(px||pz){ this.panBy(px*dt*300,pz*dt*300); }
    const f=1-Math.exp(-dt*((this.slowUntil&&G.time<this.slowUntil)?1.7:7));
    let da=this.a-c.alpha; c.alpha+=da*f; c.beta+=(this.b-c.beta)*f; c.radius+=(this.r-c.radius)*f;
    const tgt=c.target.clone(); tgt.addInPlace(this.t.subtract(tgt).scale(f));
    if(G.fxReduced) G.shake=0;
    if(G.shake>0){ G.shake=Math.max(0,G.shake-dt*2.2); const s=G.shake*G.shake*3.5; tgt.addInPlace(new V3((Math.random()-.5)*s,(Math.random()-.5)*s,(Math.random()-.5)*s)); }
    c.target.copyFrom(tgt);
  }
}

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
    for(let i=0;i<14;i++){ const a=rr()*6.28, r=rr()<.5?15:3+rr()*9; b.box(M.ember,Math.cos(a)*r,(rr()-.5)*2,Math.sin(a)*r,.6+rr()*.8,.4,.6+rr()*.8); }
    for(let i=0;i<10;i++){ const a=rr()*6.28, r=6+rr()*8; b.box(rr()<.5?M.hull:M.dark,Math.cos(a)*r,(rr()-.5)*5,Math.sin(a)*r,.8+rr()*2.4,.5+rr()*1.2,.6+rr()*2,rr()*3,rr()*3,rr()*3); }
    const m=b.finish(); m.root.position=c.add(new V3(0,1.5,0)); m.root.scaling.setAll(R/16.5); m.root.rotation.set((rr()-.5)*.5,rr()*6,(rr()-.5)*.4); m.meshes.forEach(x=>x.isPickable=false); G.env.push(m.root); },
  hulk(c,R,rr){ const facs=['hegemony','voidsworn','corsair','ithar','deathless','chorus'], f=facs[Math.floor(rr()*6)];
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
// the rift: a violet tear in space below the board where the chasm runs
function buildRift(cells,rr){ const sc=G.scene, m=emMat('riftM',new C3(.85,.42,1.7),.6); m.opacityTexture=G.tex.soft; m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; G.env.push(m);
  for(const [q,r] of cells){ const c=hexWorld(q,r,0); for(let i=0;i<2;i++){ const pl=MB.CreatePlane('rift',{size:HS*(2.6+rr()*1.4)},sc); pl.position=new V3(c.x+(rr()-.5)*5,-4-rr()*10,c.z+(rr()-.5)*5); pl.rotation.x=Math.PI/2; pl.rotation.y=rr()*6.28; pl.material=m; pl.isPickable=false; G.glow.addExcludedMesh(pl); G.env.push(pl); } } }
function buildTerrainFeatures(rr){
  const sc=G.scene, M=facMats('hegemony'); G.storms=[]; G.lightT=0;
  const debBases=[0,1,2].map(k=>{ const b=new SB('hegemony',6); if(k===0){ b.box(M.dark,0,0,0,3,.4,1.2); b.box(M.hull,.8,.3,.2,1.2,.3,.9); } else if(k===1){ b.cylX(M.dark,0,0,0,4,.35,.35,6); b.box(M.hull,-1.2,0,0,.4,1.2,1.2); } else { b.box(M.hull,0,0,0,1.6,1,1.4,.3,.2,.1); b.box(M.dark,0,.6,0,.3,1.4,.3); } const m=b.finish(); m.meshes.forEach(x=>{ x.material=facMats('hegemony').wreck; x.isVisible=false; }); m.root.position.y=-5000; G.env.push(m.root); return m; });
  for(const [k,t] of Object.entries(B.terrain)){ const [q,r]=k.split(',').map(Number); const c=hexWorld(q,r);
    if(t==='debris'){ for(let i=0;i<9;i++){ const src=debBases[Math.floor(rr()*3)]; const inst=src.root.instantiateHierarchy(null); inst.getChildMeshes().forEach(m=>{ m.isVisible=true; m.isPickable=false; }); inst.position=c.add(new V3((rr()-.5)*14,(rr()-.2)*5,(rr()-.5)*14)); inst.rotation.set(rr()*6,rr()*6,rr()*6); inst.scaling.setAll(.5+rr()*1.3); inst.spin=new V3((rr()-.5)*.2,(rr()-.5)*.2,(rr()-.5)*.2); G.rocks.push(inst); G.env.push(inst); } }
    if(t==='storm'){ G.storms.push(c); for(let i=0;i<2;i++){ const pl=MB.CreatePlane('storm',{size:26+rr()*16},sc); pl.position=c.add(new V3((rr()-.5)*6,2+rr()*6,(rr()-.5)*6)); pl.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; pl.isPickable=false; const sm=addMat('stormM',rr()<.5?new C3(.28,.36,.9):new C3(.45,.3,.85),.36,G.tex.neb); pl.material=sm; pl.rotation.z=rr()*6; G.glow.addExcludedMesh(pl); G.env.push(pl,sm); } } }
  const meta=B.map||{};
  if(meta.station) buildStation(hexWorld(meta.station.q,meta.station.r),rr);
  if(meta.planet) buildNearPlanet(meta.planet);
  if(meta.deadstar) buildDeadStar(hexWorld(meta.deadstar.q,meta.deadstar.r,0));
  if(meta.riftCells) buildRift(meta.riftCells,rr);
  if(meta.holes) buildHoleFills(meta.holes,rr);
  if(meta.wrecks) for(const h of meta.wrecks){ const facs=['hegemony','voidsworn','corsair','ithar','deathless','chorus'], f=facs[Math.floor(rr()*6)], cls=['Cruiser','Battleship','Carrier'][Math.floor(rr()*3)];
    const mdl=buildShipModel({fac:f,cls,isSq:false,side:'enemy',tpl:'wreck'}); if(mdl.toSplit) mdl.toSplit(); const Mw=facMats(f); mdl.meshes.forEach(m=>{ m.material=(m.material===Mw.win||m.material===Mw.eng||m.material===Mw.tip||m.material===Mw.sail)?Mw.ember:Mw.wreck; m.isPickable=false; }); mdl.plumes.forEach(p=>p.dispose()); (mdl.flares||[]).forEach(p=>p.dispose());
    const c=hexWorld(h.q,h.r,1.5); mdl.root.position=c; mdl.root.scaling.setAll(Math.min(1,HS*1.7/Math.max(1,mdl.L))); /* a wreck fills its own hex, not its neighbours */ mdl.root.rotation.set((rr()-.5)*.5,rr()*6.28,(rr()-.5)*.7); mdl.fore.position.x+=mdl.L*.08; mdl.fore.rotation.set((rr()-.5)*.4,(rr()-.5)*.5,(rr()-.5)*.4); mdl.aft.rotation.z=(rr()-.5)*.3; G.env.push(mdl.root); (G._wreckMeshes=G._wreckMeshes||[]).push(...mdl.meshes, ...mdl.root.getChildMeshes(false).filter(m=>m.name.endsWith('emblem'))); }
  // wrecks never move: bake them into one mesh per material (dozens of draw calls become a handful)
  if(G._wreckMeshes&&G._wreckMeshes.length){ const by=new Map(); for(const m of G._wreckMeshes){ if(m.isDisposed()) continue; if(!by.has(m.material)) by.set(m.material,[]); by.get(m.material).push(m); }
    for(const [mat,ms] of by){ if(ms.length<2) continue; try{ const mm=BABYLON.Mesh.MergeMeshes(ms,true,true); if(mm){ mm.name='wreckMerged'; mm.material=mat; mm.isPickable=false; mm.receiveShadows=true; G.env.push(mm); } }catch(e){ console.warn('wreck merge',e); } }
    G._wreckMeshes=null; }
}
function buildStation(c,rr){
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
  const p=MB.CreateSphere('nearPlanet',{diameter:Rs*2,segments:G.mobile?72:128},G.scene); p.position=c; p.rotation.set(.3,.8,0); p.isPickable=false; p.material=nearPlanetMaterial(fac);
  const at=MB.CreateSphere('nearAtmo',{diameter:Rs*2.035,segments:G.mobile?48:80},G.scene); at.position=c; at.isPickable=false; at.material=atmoMaterial('nearAtmoM'); at.material.setColor3('atmo',new C3(.45,.7,1).scale(.9));
  G.glow.addExcludedMesh(p); G.glow.addExcludedMesh(at); G.nearPlanet=p; G.nearAtmo=at; G.npClouds=null; G.env.push(p,at,p.material,at.material);
}
function updateStorms(dt){
  if(!G.storms||!G.storms.length||G.fxReduced) return; G.lightT-=dt; if(G.lightT>0) return; G.lightT=.25+Math.random()*.7;
  const c=G.storms[Math.floor(Math.random()*G.storms.length)]; const pts=[]; let p=c.add(new V3((Math.random()-.5)*12,9+Math.random()*4,(Math.random()-.5)*12));
  for(let i=0;i<7;i++){ pts.push(p.clone()); p=p.add(new V3((Math.random()-.5)*4,-1.6-Math.random()*1.2,(Math.random()-.5)*4)); }
  const t=MB.CreateTube('bolt',{path:pts,radius:.14,tessellation:4},G.scene); const m=emMat('boltL',new C3(1.4,1.6,2.2)); t.material=m; t.isPickable=false;
  flash(pts[Math.floor(pts.length/2)],10,new C3(.6,.7,1),.25); setTimeout(()=>{ t.dispose(); m.dispose(); },140);
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
