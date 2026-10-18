// ======================= PROCEDURAL SHIPS =======================
const FAC3D={
  voidsworn:{hull:'#b7a782',dark:'#3b3229',trim:'#c7953a',win:new C3(1,.58,.2),eng:new C3(.5,.8,1),bolt:new C3(1,.7,.28),beam:new C3(1,.84,.5),shield:new C3(.35,.85,.75),tip:new C3(1,.2,.15)},
  hegemony:{hull:'#a3abb6',dark:'#373d45',trim:'#b53c35',win:new C3(.82,.92,1),eng:new C3(.42,.64,1),bolt:new C3(.35,1,.45),beam:new C3(.5,.78,1),shield:new C3(1,.38,.32),tip:new C3(1,.15,.15)},
  corsair:{hull:'#9a6040',dark:'#3a2a20',trim:'#d9a441',win:new C3(1,.7,.3),eng:new C3(1,.55,.25),bolt:new C3(1,.6,.2),beam:new C3(1,.5,.2),shield:new C3(1,.6,.3),tip:new C3(1,.3,.1)},
  chorus:{hull:'#6d3f68',dark:'#2c1a2b',trim:'#c77ab8',win:new C3(1,.45,.85),eng:new C3(.9,.4,1),bolt:new C3(1,.45,.85),beam:new C3(1,.5,.9),shield:new C3(1,.5,.9),tip:new C3(1,.4,.9)},
  ithar:{hull:'#d8e4ea',dark:'#6c8594',trim:'#9fe3ff',win:new C3(.6,.95,1),eng:new C3(.6,.95,1),bolt:new C3(.6,.95,1),beam:new C3(.7,.95,1),shield:new C3(.6,.9,1),tip:new C3(.6,1,1)},
  deathless:{hull:'#2c3431',dark:'#151a18',trim:'#58c878',win:new C3(.35,1,.5),eng:new C3(.35,1,.5),bolt:new C3(.4,1,.55),beam:new C3(.4,1,.55),shield:new C3(.4,1,.55),tip:new C3(.4,1,.5)},
};
const MATS={}, EMBLEMS={};
function emblemMat(fac){ if(EMBLEMS[fac]) return EMBLEMS[fac]; const P=FAC3D[fac]||FAC3D.hegemony;
  const t=dynTex('emb_'+fac,256,256,(g,w)=>{ g.clearRect(0,0,w,w); const c=w/2; g.lineCap='round'; g.lineJoin='round';
    const col={voidsworn:'#d8b25a',hegemony:'#d0463c',corsair:'#e8dcc4',chorus:'#ff6fcf',ithar:'#9fe8ff',deathless:'#6dff8e'}[fac]||'#ddd'; g.strokeStyle=col; g.fillStyle=col; g.lineWidth=9;
    if(fac==='voidsworn'){ for(const sd of [1,-1]) for(let i=0;i<6;i++){ g.beginPath(); g.moveTo(c+sd*18,c-4+i*7); g.quadraticCurveTo(c+sd*(60+i*8),c-50+i*14,c+sd*(110-i*6),c-30+i*18); g.stroke(); } g.beginPath(); g.arc(c,c+6,22,0,Math.PI*2); g.fill(); g.fillStyle='#1a1408'; g.fillRect(c-10,c,7,7); g.fillRect(c+3,c,7,7); }
    else if(fac==='hegemony'){ g.beginPath(); for(let i=0;i<=6;i++){ const a=i*Math.PI/3-Math.PI/2; g.lineTo(c+Math.cos(a)*92,c+Math.sin(a)*92); } g.stroke(); g.beginPath(); g.moveTo(c-50,c-20); g.lineTo(c,c+40); g.lineTo(c+50,c-20); g.stroke(); g.beginPath(); g.moveTo(c,c-70); g.lineTo(c,c+10); g.stroke(); }
    else if(fac==='corsair'){ g.beginPath(); g.arc(c,c-18,42,0,Math.PI*2); g.fill(); g.fillStyle='#120c08'; g.beginPath(); g.arc(c-16,c-22,10,0,7); g.arc(c+16,c-22,10,0,7); g.fill(); g.lineWidth=14; g.beginPath(); g.moveTo(c-80,c+30); g.lineTo(c+80,c+100); g.moveTo(c+80,c+30); g.lineTo(c-80,c+100); g.stroke(); }
    else if(fac==='chorus'){ g.lineWidth=8; g.beginPath(); for(let a=0;a<14;a+=.1){ const r=6+a*6; g.lineTo(c+Math.cos(a)*r,c+Math.sin(a)*r); } g.stroke(); g.beginPath(); g.arc(c,c,14,0,7); g.fill(); }
    else if(fac==='ithar'){ g.beginPath(); g.arc(c,c,80,Math.PI*.25,Math.PI*1.75); g.arc(c+28,c,62,Math.PI*1.7,Math.PI*.3,true); g.fill(); g.beginPath(); for(let i=0;i<10;i++){ const a=i*Math.PI/5-Math.PI/2, r=i%2?10:26; g.lineTo(c+50+Math.cos(a)*r,c+Math.sin(a)*r); } g.fill(); }
    else { g.beginPath(); g.arc(c,c-46,30,0,7); g.stroke(); g.beginPath(); g.moveTo(c,c-16); g.lineTo(c,c+90); g.moveTo(c-55,c+8); g.lineTo(c+55,c+8); g.stroke(); } });
  const m=new BABYLON.StandardMaterial('embM_'+fac,G.scene); m.diffuseTexture=t; m.diffuseTexture.hasAlpha=true; m.useAlphaFromDiffuseTexture=true; m.emissiveColor=P.win.scale(.25); m.specularColor=new C3(.3,.3,.3); m.backFaceCulling=false; return EMBLEMS[fac]=m; }
function styleTex(fac,name,base,seed){
  if(fac==='chorus') return (()=>{ const t=dynTex(name,512,512,(g,w)=>{ g.fillStyle=base; g.fillRect(0,0,w,w); const r=seeded(seed);
      for(let i=0;i<70;i++){ g.strokeStyle=`rgba(${r()<.5?'255,170,230':'40,10,40'},${.1+r()*.2})`; g.lineWidth=1+r()*4; g.beginPath(); let x=r()*w,y=r()*w; g.moveTo(x,y); for(let k=0;k<5;k++){ x+=(r()-.5)*120; y+=(r()-.5)*120; g.quadraticCurveTo(x+(r()-.5)*60,y+(r()-.5)*60,x,y); } g.stroke(); }
      for(let i=0;i<160;i++){ const x=r()*w,y=r()*w,rad=2+r()*10; const gr=g.createRadialGradient(x,y,0,x,y,rad); gr.addColorStop(0,'rgba(255,200,240,.25)'); gr.addColorStop(1,'rgba(255,200,240,0)'); g.fillStyle=gr; g.fillRect(x-rad,y-rad,rad*2,rad*2); } }); t.hasAlpha=false; return t; })();
  if(fac==='ithar') return (()=>{ const t=dynTex(name,512,512,(g,w)=>{ const gr=g.createLinearGradient(0,0,w,0); gr.addColorStop(0,base); gr.addColorStop(.5,'#f4fbff'); gr.addColorStop(1,base); g.fillStyle=gr; g.fillRect(0,0,w,w); const r=seeded(seed);
      for(let i=0;i<26;i++){ g.strokeStyle=`rgba(90,150,180,${.08+r()*.12})`; g.lineWidth=1; g.beginPath(); const y=r()*w; g.moveTo(0,y); g.bezierCurveTo(w*.3,y+(r()-.5)*40,w*.6,y+(r()-.5)*40,w,y); g.stroke(); } }); t.hasAlpha=false; return t; })();
  if(fac==='deathless') return (()=>{ const t=dynTex(name,512,512,(g,w)=>{ g.fillStyle=base; g.fillRect(0,0,w,w); const r=seeded(seed);
      for(let i=0;i<120;i++){ g.strokeStyle=`rgba(${r()<.3?'120,160,130':'0,0,0'},${.15+r()*.25})`; g.lineWidth=1+r(); g.beginPath(); let x=Math.round(r()*16)*32,y=Math.round(r()*16)*32; g.moveTo(x,y); for(let k=0;k<4;k++){ if(r()<.5) x+=Math.round((r()-.5)*6)*32; else y+=Math.round((r()-.5)*6)*32; g.lineTo(x,y); } g.stroke(); } }); t.hasAlpha=false; return t; })();
  const t=panelTex(name,base,seed);
  if(fac==='corsair'){ const g=t.getContext(), r=seeded(seed+5); for(let i=0;i<360;i++){ const x=r()*2048,y=r()*2048; const gr=g.createLinearGradient(x,y,x,y+300); gr.addColorStop(0,`rgba(${r()<.5?'150,70,25':'60,35,20'},.35)`); gr.addColorStop(1,'rgba(120,60,20,0)'); g.fillStyle=gr; g.fillRect(x,y,8+r()*40,300); } for(let i=0;i<900;i++){ g.fillStyle='rgba(30,20,12,.5)'; g.fillRect(r()*2048,r()*2048,3,3); } t.update(); }
  return t;
}
function panelTex(name,base,seed){ const PT=G.mobile?1024:2048; const t=dynTex(name,PT,PT,(g,w)=>{ g.fillStyle=base; g.fillRect(0,0,w,w); const r=seeded(seed);
    for(let i=0;i<70;i++){ const x=r()*w,y=r()*w,rad=100+r()*420; const gr=g.createRadialGradient(x,y,0,x,y,rad); const dk=r()<.55; gr.addColorStop(0,dk?'rgba(0,0,0,.13)':'rgba(255,245,225,.08)'); gr.addColorStop(1,'rgba(0,0,0,0)'); g.fillStyle=gr; g.fillRect(x-rad,y-rad,rad*2,rad*2); }
    let y=0; while(y<w){ const ph=36+Math.floor(r()*110); let x=-r()*200; while(x<w){ const pw=70+Math.floor(r()*240), sh=(r()-.5)*.17;
        g.fillStyle=sh>0?`rgba(255,250,235,${sh})`:`rgba(0,0,0,${-sh})`; g.fillRect(x,y,pw,ph);
        g.fillStyle='rgba(0,0,0,.5)'; g.fillRect(x,y,pw,2); g.fillRect(x,y,2,ph); g.fillStyle='rgba(255,255,255,.09)'; g.fillRect(x+2,y+2,pw-3,1); g.fillRect(x+2,y+2,1,ph-3);
        if(r()<.55){ g.fillStyle='rgba(0,0,0,.38)'; for(let k=8;k<pw-4;k+=13){ g.fillRect(x+k,y+5,2,2); g.fillRect(x+k,y+ph-7,2,2); } }
        if(r()<.4){ const dw=12+r()*46, dh=10+r()*32, dx=x+r()*Math.max(1,pw-dw), dy=y+r()*Math.max(1,ph-dh); g.fillStyle='rgba(0,0,0,.28)'; g.fillRect(dx,dy,dw,dh); g.fillStyle='rgba(255,255,255,.07)'; g.fillRect(dx+1,dy+1,dw-2,dh-2); g.fillStyle='rgba(0,0,0,.2)'; g.fillRect(dx+2,dy+dh/2,dw-4,1); }
        if(r()<.06){ g.fillStyle='rgba(0,0,0,.3)'; for(let k=0;k<pw;k+=10) g.fillRect(x+k,y+ph/2-3,5,6); }
        x+=pw; } y+=ph; }
    for(let i=0;i<260;i++){ const x=r()*w,y=r()*w,h=60+r()*280; const gr=g.createLinearGradient(x,y,x,y+h); gr.addColorStop(0,'rgba(24,17,11,.28)'); gr.addColorStop(1,'rgba(24,17,11,0)'); g.fillStyle=gr; g.fillRect(x,y,3+r()*10,h); }
    for(let i=0;i<45;i++){ const x=r()*w,y=r()*w,rad=20+r()*80; const gr=g.createRadialGradient(x,y,0,x,y,rad); gr.addColorStop(0,'rgba(8,6,5,.32)'); gr.addColorStop(1,'rgba(8,6,5,0)'); g.fillStyle=gr; g.fillRect(x-rad,y-rad,rad*2,rad*2); }
    g.strokeStyle='rgba(255,250,240,.13)'; g.lineWidth=1; for(let i=0;i<700;i++){ const x=r()*w,y=r()*w; g.beginPath(); g.moveTo(x,y); g.lineTo(x+(r()-.5)*34,y+(r()-.5)*8); g.stroke(); } });
  t.hasAlpha=false; t.anisotropicFilteringLevel=16; return t; }
function emMat(name,col,alpha=1){ const m=new BABYLON.StandardMaterial(name,G.scene); m.diffuseColor=C3.Black(); m.specularColor=C3.Black(); m.emissiveColor=col; m.disableLighting=true; m.alpha=alpha; return m; }
function windowTex(fac){ const t=dynTex(fac+'wt',512,512,(g,w)=>{ g.fillStyle='#000'; g.fillRect(0,0,w,w); const r=seeded(31);
    if(fac==='chorus'){ for(let i=0;i<60;i++){ const x=r()*w,y=r()*w,rad=2+r()*6; const gr=g.createRadialGradient(x,y,0,x,y,rad); gr.addColorStop(0,'rgba(255,255,255,.85)'); gr.addColorStop(1,'rgba(255,255,255,0)'); g.fillStyle=gr; g.fillRect(x-rad,y-rad,rad*2,rad*2);} return; }
    if(fac==='deathless'||fac==='ithar'){ g.strokeStyle='rgba(255,255,255,.75)'; g.lineWidth=1.5; for(let i=0;i<22;i++){ let x=Math.round(r()*16)*32,y=Math.round(r()*16)*32; g.beginPath(); g.moveTo(x,y); for(let k=0;k<3;k++){ if(r()<.5) x+=Math.round((r()-.5)*4)*32; else y+=Math.round((r()-.5)*4)*32; g.lineTo(x,y);} g.stroke(); } return; }
    for(let row=0;row<18;row++){ const y=12+row*28+r()*6; if(r()<.35) continue; let x=r()*40; while(x<w){ const run=6+Math.floor(r()*18); for(let k=0;k<run&&x<w;k++){ if(r()<.75){ g.fillStyle=`rgba(255,255,255,${.5+r()*.5})`; g.fillRect(x,y,3,4); } x+=6; } x+=20+r()*60; } } });
  t.hasAlpha=false; return t; }
function facMats(fac){
  if(MATS[fac]) return MATS[fac];
  const P=FAC3D[fac]||FAC3D.hegemony, sc=G.scene;
  const ht=styleTex(fac,fac+'ht',P.hull,7), dt=styleTex(fac,fac+'dt',P.dark,13);
  const metal={voidsworn:.28,hegemony:.4,corsair:.35,chorus:.05,ithar:.25,deathless:.6}[fac]??.35, rough={voidsworn:.52,hegemony:.46,corsair:.64,chorus:.32,ithar:.24,deathless:.5}[fac]??.5;
  const hm=mapsFromCanvas(fac+'hm',ht.getContext().canvas,{metal,rough,strength:fac==='ithar'?1.2:2.6}), dm=mapsFromCanvas(fac+'dm',dt.getContext().canvas,{metal:Math.min(.9,metal+.1),rough:rough+.08,strength:2.2});
  const tile=[1,1], wt=windowTex(fac);
  for(const t of [ht,hm.normal,hm.orm,wt]){ t.uScale=tile[0]; t.vScale=tile[1]; }
  const pbr=(n,alb,maps,color,m0,r0,em)=>{ const m=new BABYLON.PBRMaterial(fac+n,sc);
    if(alb){ m.albedoTexture=alb; m.albedoColor=C3.White(); } else m.albedoColor=hexC3(color);
    if(maps){ m.bumpTexture=maps.normal; m.useParallax=true; m.useParallaxOcclusion=false; m.parallaxScaleBias=.022; m.bumpTexture.level=1; m.metallicTexture=maps.orm; m.useRoughnessFromMetallicTextureGreen=true; m.useMetallnessFromMetallicTextureBlue=true; m.useAmbientOcclusionFromMetallicTextureRed=true; m.metallic=1; m.roughness=1; }
    else { m.metallic=m0; m.roughness=r0; }
    if(em){ m.emissiveTexture=em; m.emissiveColor=P.win.scale(fac==='voidsworn'?.55:1.1); }
    m.environmentIntensity=1.5; m.directIntensity=1.25; m.maxSimultaneousLights=6; m.backFaceCulling=false; m.twoSidedLighting=true; return m; };
  const M={P, hull:pbr('hull',ht,hm,null,0,0,wt), dark:pbr('dark',dt,dm), trim:pbr('trim',null,null,P.trim,.95,.26),
    win:emMat(fac+'win',P.win), eng:emMat(fac+'eng',P.eng.scale(1.4)), tip:emMat(fac+'tip',P.tip.scale(1.5)),
    wreck:pbr('wreck',null,null,'#17120f',.35,.85), ember:emMat(fac+'ember',new C3(.9,.32,.08))};
  if(fac==='ithar'){ M.hull.iridescence.isEnabled=true; M.hull.iridescence.intensity=.9; M.hull.iridescence.indexOfRefraction=1.3; M.hull.iridescence.minimumThickness=120; M.hull.iridescence.maximumThickness=420; }
  if(fac==='chorus'){ M.hull.clearCoat.isEnabled=true; M.hull.clearCoat.intensity=.7; M.hull.clearCoat.roughness=.12; M.hull.subSurface.isTranslucencyEnabled=true; M.hull.subSurface.translucencyIntensity=.55; M.hull.subSurface.tintColor=new C3(1,.35,.65); }
  if(fac==='voidsworn'||fac==='hegemony'){ M.hull.clearCoat.isEnabled=true; M.hull.clearCoat.intensity=.25; M.hull.clearCoat.roughness=.3; }
  M.steel=new BABYLON.PBRMaterial(fac+'steel',sc); M.steel.albedoColor=hexC3({voidsworn:'#8a7651',hegemony:'#6f757d',corsair:'#6b5140',chorus:'#3a2638',ithar:'#b9c7cf',deathless:'#2c3431'}[fac]||'#707070'); M.steel.metallic=.9; M.steel.roughness=.33; M.steel.bumpTexture=dm.normal; M.steel.environmentIntensity=1; M.steel.backFaceCulling=false; M.steel.twoSidedLighting=true;
  M.paint=new BABYLON.PBRMaterial(fac+'paint',sc); M.paint.albedoColor=hexC3({corsair:'#8e2a22',hegemony:'#9a2e28',voidsworn:'#7a1f1a'}[fac]||P.trim); M.paint.metallic=.15; M.paint.roughness=.6; M.paint.bumpTexture=hm.normal; M.paint.environmentIntensity=1.3;
  M.flesh=new BABYLON.PBRMaterial(fac+'flesh',sc); M.flesh.albedoColor=hexC3('#6e2a5c'); M.flesh.metallic=0; M.flesh.roughness=.3; M.flesh.emissiveColor=P.win.scale(.45); M.flesh.bumpTexture=hm.normal; M.flesh.environmentIntensity=1.2;
  const stx=dynTex(fac+'sailT',256,256,(g,w)=>{ const gr=g.createLinearGradient(0,w,0,0); gr.addColorStop(0,'rgba(255,255,255,.95)'); gr.addColorStop(1,'rgba(255,255,255,.12)'); g.fillStyle=gr; g.fillRect(0,0,w,w); g.fillStyle='rgba(255,255,255,.5)'; for(let y=6;y<w;y+=18) g.fillRect(0,y,w,1); }); M._sailT=stx;
  M.sail=emMat(fac+'sail',fac==='chorus'?new C3(.55,.16,.42):new C3(.25,.6,.75),.26); M.sail.backFaceCulling=false; M.sail.disableDepthWrite=true; M.sail.alphaMode=BABYLON.Engine.ALPHA_ADD; M.sail.opacityTexture=M._sailT; M.sail.alpha=.3;
  M.plume=emMat(fac+'plume',P.eng.scale(1.25),.85); M.plume.alphaMode=BABYLON.Engine.ALPHA_ADD; if(typeof plumeMaterial==='function') plumeMaterial(M.plume,P.eng.scale(1.7)); else M.plume.opacityTexture=G.tex.soft; M.plume.disableDepthWrite=true; M.plume.backFaceCulling=false;
  { const ps=typeof plumeShaderMat==='function'?plumeShaderMat(fac,P.eng.scale(1.35)):null; if(ps){ M.plumeOld=M.plume; M.plume=ps; } } // v44: shader plumes with shock diamonds
  M.flare=emMat(fac+'flare',P.eng.scale(1.05),.75); M.flare.alphaMode=BABYLON.Engine.ALPHA_ADD; M.flare.opacityTexture=G.tex.flare; M.flare.disableDepthWrite=true; M.flare.backFaceCulling=false;
  if(typeof addHullFx==='function') addHullFx(M,fac); // v42: faction rim light
  return MATS[fac]=M;
}
// class lengths (world units; one hex is ~17 across)
const CLS_LEN={Squadron:1.6,Frigate:6.5,Destroyer:9.5,Cruiser:14.5,Carrier:16.5,Battleship:21,Dreadnought:27,'Super-dreadnought':31,'Battle-barge':26,'Bio-titan':28,Ark:26,'Tomb-ark':28};

function interpStation(a,b,x){ const k=(x-a.x)/(b.x-a.x||1); const o={x}; for(const key of ['w','t','b','y']) o[key]=(a[key]||0)+((b[key]||0)-(a[key]||0))*k; return o; }
function loftMesh(stations,prof){
  const rings=stations.map(st=>{ const hp=prof(st), y0=st.y||0, ring=[]; for(const [y,z] of hp) ring.push([st.x,y+y0,z]); for(let i=hp.length-2;i>=1;i--){ const [y,z]=hp[i]; ring.push([st.x,y+y0,-z]); } return ring; });
  const n=rings[0].length, pos=[], idx=[], uv=[], x0=stations[0].x, x1=stations[stations.length-1].x;
  rings.forEach(ring=>ring.forEach((p,j)=>{ pos.push(p[0],p[1],p[2]); uv.push((p[0]-x0)/(x1-x0||1), j/n); }));
  for(let i=0;i<rings.length-1;i++) for(let j=0;j<n;j++){ const a=i*n+j,b=i*n+(j+1)%n,c=(i+1)*n+j,d=(i+1)*n+(j+1)%n; idx.push(a,c,b,b,c,d); }
  const cap=(i,flip)=>{ const ring=rings[i]; let cx=0,cy=0,cz=0; for(const p of ring){cx+=p[0];cy+=p[1];cz+=p[2];} const ci=pos.length/3; pos.push(cx/n,cy/n,cz/n); uv.push(i?1:0,.5);
    for(let j=0;j<n;j++){ const a=i*n+j,b=i*n+(j+1)%n; if(flip) idx.push(ci,a,b); else idx.push(ci,b,a); } };
  cap(0,false); cap(rings.length-1,true);
  const m=new BABYLON.Mesh('loft',G.scene); const vd=new BABYLON.VertexData(); const nr=[]; BABYLON.VertexData.ComputeNormals(pos,idx,nr); vd.positions=pos; vd.indices=idx; vd.normals=nr; vd.uvs=uv; vd.applyToMesh(m,true);
  return m;
}
const PROF={
  gothic2:st=>{ const {w,t,b}=st; return [[t,0],[t,w*.5],[t*.93,w*.6],[t*.9,w*.74],[t*.72,w*.8],[t*.68,w],[-b*.4,w],[-b*.55,w*.9],[-b*.9,w*.72],[-b,w*.45],[-b,0]]; },
  gothic:st=>{ const {w,t,b}=st; return [[t,0],[t,w*.7],[t*.7,w],[-b*.45,w],[-b,w*.62],[-b,0]]; },
  wedge:st=>{ const {w,t,b}=st; return [[t,0],[t*.92,w*.16],[t*.16,w*.93],[0,w],[-b*.16,w*.93],[-b*.9,w*.16],[-b,0]]; },
  round:st=>{ const {w,t,b}=st, o=[]; for(let i=0;i<=8;i++){ const a=i/8*Math.PI; const y=Math.cos(a)>0?Math.cos(a)*t:Math.cos(a)*b; o.push([y,Math.sin(a)*w]); } return o; },
};
// ---------- geometry kit: parts are written straight into vertex buffers ----------
const VDC={}, q20=x=>Math.round(x*20)/20;
function vdCache(k,f){ return VDC[k]||(VDC[k]=f()); }
function vdBox(){ return vdCache('box',()=>BABYLON.VertexData.CreateBox({size:1})); }
function vdCyl(tess,ratio,down){ if(tess>4&&!G.mobile) tess=Math.max(tess,tess<=8?16:tess); else if(tess>4) tess=Math.max(tess,10); const r=q20(ratio); return vdCache('c'+tess+'_'+r+(down?'d':''),()=>BABYLON.VertexData.CreateCylinder({height:1,diameterTop:down?1:r,diameterBottom:down?0:1,tessellation:tess})); }
function vdSph(seg){ seg=G.mobile?seg:Math.max(seg,10); return vdCache('s'+seg,()=>BABYLON.VertexData.CreateSphere({diameter:1,segments:seg})); }
function vdTor(th){ const t=Math.max(.04,q20(th)); return vdCache('t'+t,()=>BABYLON.VertexData.CreateTorus({diameter:1,thickness:t,tessellation:20})); }
let WIND=null;
function windSign(){ if(WIND!==null) return WIND; const v=vdBox(), P=v.positions, I=v.indices, N=v.normals; const a=I[0]*3,b=I[1]*3,c=I[2]*3;
  const e1=[P[b]-P[a],P[b+1]-P[a+1],P[b+2]-P[a+2]], e2=[P[c]-P[a],P[c+1]-P[a+1],P[c+2]-P[a+2]]; const cr=[e1[1]*e2[2]-e1[2]*e2[1],e1[2]*e2[0]-e1[0]*e2[2],e1[0]*e2[1]-e1[1]*e2[0]];
  WIND=Math.sign(cr[0]*N[a]+cr[1]*N[a+1]+cr[2]*N[a+2])||1; return WIND; }
// a box with chamfered edges and corners: the bevels catch highlights like real armour plate
function bevelBoxVD(sx,sy,sz,c){ const hx=sx/2,hy=sy/2,hz=sz/2, ax=hx-c, ay=hy-c, az=hz-c, P=[],N=[],I=[], w=windSign();
  const tri=(p,n)=>{ let [a,b,d]=p; const e1=[b[0]-a[0],b[1]-a[1],b[2]-a[2]], e2=[d[0]-a[0],d[1]-a[1],d[2]-a[2]]; const cr=[e1[1]*e2[2]-e1[2]*e2[1],e1[2]*e2[0]-e1[0]*e2[2],e1[0]*e2[1]-e1[1]*e2[0]];
    if(Math.sign(cr[0]*n[0]+cr[1]*n[1]+cr[2]*n[2])!==w){ const t=b; b=d; d=t; } const base=P.length/3; for(const q of [a,b,d]){ P.push(q[0],q[1],q[2]); N.push(n[0],n[1],n[2]); } I.push(base,base+1,base+2); };
  const quad=(a,b,d,e,n)=>{ tri([a,b,d],n); tri([a,d,e],n); }, r2=Math.SQRT1_2, r3=1/Math.sqrt(3);
  for(const g of [1,-1]){ quad([g*hx,-ay,-az],[g*hx,ay,-az],[g*hx,ay,az],[g*hx,-ay,az],[g,0,0]); quad([-ax,g*hy,-az],[ax,g*hy,-az],[ax,g*hy,az],[-ax,g*hy,az],[0,g,0]); quad([-ax,-ay,g*hz],[ax,-ay,g*hz],[ax,ay,g*hz],[-ax,ay,g*hz],[0,0,g]); }
  for(const p of [1,-1]) for(const q of [1,-1]){ quad([p*hx,q*ay,-az],[p*hx,q*ay,az],[p*ax,q*hy,az],[p*ax,q*hy,-az],[p*r2,q*r2,0]); quad([p*hx,-ay,q*az],[p*hx,ay,q*az],[p*ax,ay,q*hz],[p*ax,-ay,q*hz],[p*r2,0,q*r2]); quad([-ax,p*hy,q*az],[ax,p*hy,q*az],[ax,p*ay,q*hz],[-ax,p*ay,q*hz],[0,p*r2,q*r2]); }
  for(const a of [1,-1]) for(const b of [1,-1]) for(const d of [1,-1]) tri([[a*hx,b*ay,d*az],[a*ax,b*hy,d*az],[a*ax,b*ay,d*hz]],[a*r3,b*r3,d*r3]);
  return {positions:P,normals:N,indices:I}; }
function qFromUp(n){ const up=new V3(0,1,0), ax=V3.Cross(up,n); const ang=Math.acos(clamp(V3.Dot(up,n),-1,1)); return ax.length()<1e-5?BABYLON.Quaternion.Identity():BABYLON.Quaternion.RotationAxis(ax.normalize(),ang); }
class PH{ constructor(vd,mat,pre,half){ this.vd=vd; this.mat=mat; this.pre=pre; this.half=half; this.position=new V3(0,0,0); this.rotation=new V3(0,0,0); this.scaling=new V3(1,1,1); this.q=null; }
  matrix(){ const q=this.q||BABYLON.Quaternion.RotationYawPitchRoll(this.rotation.y,this.rotation.x,this.rotation.z); const m=BABYLON.Matrix.Compose(this.scaling,q,this.position); return this.pre?this.pre.multiply(m):m; } }
function det3(a){ return a[0]*(a[5]*a[10]-a[6]*a[9])-a[4]*(a[1]*a[10]-a[2]*a[9])+a[8]*(a[1]*a[6]-a[2]*a[5]); }
class GeoBuf{ constructor(){ this.p=[]; this.n=[]; this.uv=[]; this.i=[]; }
  add(vd,m,uvs=.12){ const P=vd.positions,N=vd.normals,I=vd.indices,a=m.m,base=this.p.length/3, nm=m.clone(); nm.setTranslationFromFloats(0,0,0); nm.invert(); nm.transpose(); const c=nm.m;
    for(let k=0;k<P.length;k+=3){ const x=P[k],y=P[k+1],z=P[k+2]; const wx=a[0]*x+a[4]*y+a[8]*z+a[12], wy=a[1]*x+a[5]*y+a[9]*z+a[13], wz=a[2]*x+a[6]*y+a[10]*z+a[14];
      let nx=c[0]*N[k]+c[4]*N[k+1]+c[8]*N[k+2], ny=c[1]*N[k]+c[5]*N[k+1]+c[9]*N[k+2], nz=c[2]*N[k]+c[6]*N[k+1]+c[10]*N[k+2]; const l=Math.hypot(nx,ny,nz)||1; nx/=l; ny/=l; nz/=l;
      this.p.push(wx,wy,wz); this.n.push(nx,ny,nz); const ax=Math.abs(nx),ay=Math.abs(ny),az=Math.abs(nz);
      if(ax>=ay&&ax>=az) this.uv.push(wz*uvs,wy*uvs); else if(ay>=az) this.uv.push(wx*uvs,wz*uvs); else this.uv.push(wx*uvs,wy*uvs); }
    const flip=det3(a)<0; for(let k=0;k<I.length;k+=3){ if(flip) this.i.push(base+I[k],base+I[k+2],base+I[k+1]); else this.i.push(base+I[k],base+I[k+1],base+I[k+2]); } }
  mesh(name){ const m=new BABYLON.Mesh(name,G.scene); const vd=new BABYLON.VertexData(); vd.positions=this.p; vd.normals=this.n; vd.uvs=this.uv; vd.indices=this.i; vd.applyToMesh(m); return m; } }
// v44 hull lofting: the cross-section is corner-cut (Chaikin) so every hard edge becomes a small machined bevel that catches light,
// stations are resampled along the hull with a gentle spline, normals are smooth, and the end caps get their own flat normals
function refineRing(pts,cut,iters){ for(let it=0;it<iters;it++){ const out=[], n=pts.length; for(let i=0;i<n;i++){ const p=pts[i], q=pts[(i+1)%n]; out.push([p[0]+(q[0]-p[0])*cut,p[1]+(q[1]-p[1])*cut],[p[0]+(q[0]-p[0])*(1-cut),p[1]+(q[1]-p[1])*(1-cut)]); } pts=out; } return pts; }
function resampleStations(st,sub){ if(sub<=1||st.length<2) return st; const out=[], K=['w','t','b','y'], g=(i)=>st[Math.max(0,Math.min(st.length-1,i))];
  for(let i=0;i<st.length-1;i++){ const p0=g(i-1),p1=g(i),p2=g(i+1),p3=g(i+2); for(let k=0;k<sub;k++){ const u=k/sub; if(k===0){ out.push(Object.assign({},p1)); continue; }
      const o={x:p1.x+(p2.x-p1.x)*u}; for(const key of K){ const a=p0[key]||0,b=p1[key]||0,c=p2[key]||0,d=p3[key]||0; const lin=b+(c-b)*u;
        const cr=.5*((2*b)+(-a+c)*u+(2*a-5*b+4*c-d)*u*u+(-a+3*b-3*c+d)*u*u*u); let v=lin+(cr-lin)*.55; if(key!=='y') v=Math.max(Math.min(b,c)*.85,Math.min(Math.max(b,c)*1.08,v)); o[key]=v; } out.push(o); } }
  out.push(Object.assign({},st[st.length-1])); return out; }
function loftVD(stations,prof,flat,opt){ opt=opt||{}; const cut=opt.cut==null?.11:opt.cut, iters=opt.iters==null?2:opt.iters, sub=opt.sub==null?3:opt.sub;
  const sts=resampleStations(stations,sub);
  const rings=sts.map(st=>{ const hp=prof(st), y0=st.y||0, full=[]; for(const [y,z] of hp) full.push([y,z]); for(let i=hp.length-2;i>=1;i--){ const [y,z]=hp[i]; full.push([y,-z]); }
    const rr=iters>0?refineRing(full,cut,iters):full; return rr.map(([y,z])=>[st.x,y+y0,z]); });
  const n=rings[0].length; let pos=[], idx=[];
  rings.forEach(ring=>ring.forEach(p=>pos.push(p[0],p[1],p[2])));
  for(let i=0;i<rings.length-1;i++) for(let j=0;j<n;j++){ const a=i*n+j,b=i*n+(j+1)%n,c=(i+1)*n+j,d=(i+1)*n+(j+1)%n; idx.push(a,c,b,b,c,d); }
  if(flat){ const np=[],ni=[]; for(let k=0;k<idx.length;k++){ const v=idx[k]*3; np.push(pos[v],pos[v+1],pos[v+2]); ni.push(k); } pos=np; idx=ni; }
  const nr=[]; BABYLON.VertexData.ComputeNormals(pos,idx,nr);
  // end caps: duplicated vertices with flat normals, so the hull sides keep their smooth shading
  const cap=(i,flip)=>{ const ring=rings[i]; let cx=0,cy=0,cz=0; for(const p of ring){cx+=p[0];cy+=p[1];cz+=p[2];} const nx=flip?1:-1, base=pos.length/3;
    for(const p of ring){ pos.push(p[0],p[1],p[2]); nr.push(nx,0,0); } pos.push(cx/n,cy/n,cz/n); nr.push(nx,0,0); const ci=base+n;
    for(let j=0;j<n;j++){ const a=base+j,b=base+(j+1)%n; if(flip) idx.push(ci,a,b); else idx.push(ci,b,a); } };
  cap(0,false); cap(rings.length-1,true);
  return {positions:pos,indices:idx,normals:nr};
}
const MATKEYS={hull:'hull',dark:'dark',trim:'trim',win:'win',eng:'eng',tip:'tip',steel:'steel',sail:'sail',ember:'ember',paint:'paint',flesh:'flesh'};
class SB{
  constructor(fac,L){ this.fac=fac; this.L=L; this.M=fac?facMats(fac):MATKEYS; this.parts=[]; this.split=0; this.hard={F:[],P:[],S:[],T:[],R:[]}; this.plumes=[]; this.flares=[]; this.bays=[]; this.flashers=[]; this.stations=null; this.greebleN=0; this.anim=[]; this.stacks=[]; this.arcs=[]; this.guns={P:[],S:[],F:[],T:[]}; }
  ring(mat,glow,x,y,z,d,th,tilt,speed){ const node=new BABYLON.TransformNode('ringN',G.scene); node.position.set(x,y,z); const t=MB.CreateTorus('ring',{diameter:d,thickness:th,tessellation:64},G.scene); t.rotation.z=Math.PI/2+tilt; t.parent=node; t.material=mat; t.isPickable=false; castShadows(t);
    for(let i=0;i<8;i++){ const a=i/8*Math.PI*2, st=MB.CreateSphere('stud',{diameter:th*2.4,segments:6},G.scene); st.position.set(Math.cos(a)*d/2,0,Math.sin(a)*d/2); st.parent=t; st.material=glow; st.isPickable=false; }
    this.anim.push({node,axis:'x',speed}); return node; }
  surfAt(x){ const st=this.stations; if(x<=st[0].x) return st[0]; for(let i=0;i<st.length-1;i++){ if(x>=st[i].x&&x<=st[i+1].x) return interpStation(st[i],st[i+1],x); } return st[st.length-1]; }
  topY(s,z){ const a=Math.min(1,Math.abs(z)/Math.max(.001,s.w)), y0=s.y||0; if(this.prof===PROF.wedge) return y0+s.t*(1-a*.86); if(this.prof===PROF.round) return y0+s.t*Math.sqrt(Math.max(0,1-a*a)); return y0+(a<.55?s.t:s.t*(1-(a-.55)*.5)); }
  push(vd,mat,pre,half){ const h=new PH(vd,mat,pre,half); this.parts.push(h); return h; }
  add(mesh,mat,half){ mesh.computeWorldMatrix(true); mesh.refreshBoundingInfo(); const cx=mesh.getBoundingInfo().boundingBox.centerWorld.x; const vd=BABYLON.VertexData.ExtractFromMesh(mesh,true,true); const w=mesh.getWorldMatrix().clone(); mesh.dispose(); return this.push({positions:vd.positions,normals:vd.normals,indices:vd.indices},mat,w,half||(cx>=this.split?'fore':'aft')); }
  box(mat,x,y,z,sx,sy,sz,rx=0,ry=0,rz=0){ const mn=Math.min(sx,sy,sz), bev=this.fac?mn>this.L*(G.mobile?.02:.006):(!G.mobile&&mn>.14); // kit parts are tiny on the hull: only their chunky blocks get bevels, none on phones // bevel only structural blocks, where edge highlights read
    const h=bev?this.push(bevelBoxVD(sx,sy,sz,Math.min(mn*.2,this.fac?this.L*.01:.07)),mat,null):this.push(vdBox(),mat,BABYLON.Matrix.Scaling(sx,sy,sz)); h.position.set(x,y,z); h.rotation.set(rx,ry,rz); return h; }
  cylX(mat,x,y,z,len,dBack,dFront,tess=12,sy=1,sz=1){ const down=dBack<=0, d=down?dFront:dBack; const h=this.push(vdCyl(tess,down?1:dFront/dBack,down),mat,BABYLON.Matrix.Scaling(d,len,d).multiply(BABYLON.Matrix.RotationZ(-Math.PI/2))); h.scaling.set(1,sy,sz); h.position.set(x,y,z); return h; }
  cylY(mat,x,y,z,hh,dTop,dBot,tess=8,ry=0,sx=1,sz=1){ const down=dBot<=0, d=down?dTop:dBot; const h=this.push(vdCyl(tess,down?1:dTop/dBot,down),mat,BABYLON.Matrix.Scaling(d,hh,d)); h.position.set(x,y+hh/2,z); h.rotation.y=ry; h.scaling.set(sx,1,sz); return h; }
  cylZ(mat,x,y,z,len,dIn,dOut,tess=8){ const down=dIn<=0, d=down?dOut:dIn; const h=this.push(vdCyl(tess,down?1:dOut/dIn,down),mat,BABYLON.Matrix.Scaling(d,len,d).multiply(BABYLON.Matrix.RotationX(Math.PI/2))); h.position.set(x,y,z); return h; }
  sph(mat,x,y,z,d,sx=1,sy=1,sz=1,seg=12){ const h=this.push(vdSph(Math.min(seg,12)),mat,BABYLON.Matrix.Scaling(d,d,d)); h.position.set(x,y,z); h.scaling.set(sx,sy,sz); return h; }
  torusY(mat,x,y,z,d,th){ const h=this.push(vdTor(th/d),mat,BABYLON.Matrix.Scaling(d,d,d)); h.position.set(x,y,z); return h; }
  torusX(mat,x,y,z,d,th){ const h=this.push(vdTor(th/d),mat,BABYLON.Matrix.Scaling(d,d,d).multiply(BABYLON.Matrix.RotationZ(-Math.PI/2))); h.position.set(x,y,z); return h; }
  // v44: tapered, chamfered superstructure block (a short loft) - sloped walls and raked ends instead of a plain box.
  // y is the base; wB/wT are full widths at the base and the top; o.rake/o.rakeB chamfer the fore/aft ends; o.cut is the edge bevel
  slab(mat,x,y,z,len,h,wB,wT,o={}){ const k=wT/Math.max(1e-4,wB), rf=o.rake==null?.14:o.rake, rb=o.rakeB==null?rf:o.rakeB, sh=o.shrink==null?.72:o.shrink;
    const prof=st=>[[st.t,0],[st.t,st.w*k],[0,st.w],[0,0]], w=wB/2, hl=len/2;
    const sts=[{x:-hl,w:w*(1-rb*.9),t:h*(rb>0?sh:1)},{x:-hl+len*rb*.5,w,t:h},{x:hl-len*rf*.5,w,t:h},{x:hl,w:w*(1-rf*.9),t:h*(rf>0?sh:1)}];
    const vd=loftVD(sts,prof,false,{cut:o.cut==null?.1:o.cut,iters:G.mobile?1:2,sub:1}); const hh=this.push(vd,mat,null,o.half); hh.position.set(x,y,z); if(o.ry) hh.rotation.y=o.ry; if(o.rx) hh.rotation.x=o.rx; if(o.rz) hh.rotation.z=o.rz; return hh; }
  loft(mat,stations,prof,flat=true){
    const s=this.split; const aft=[],fore=[];
    for(let i=0;i<stations.length;i++){ const st=stations[i]; if(st.x<=s) aft.push(st); if(st.x>=s) fore.push(st);
      const nx=stations[i+1]; if(nx && st.x<s && nx.x>s){ const m=interpStation(st,nx,s); aft.push(m); fore.push(m); } }
    if(!this.stations){ this.stations=stations; this.prof=prof; }
    const fl=false, opt=prof===PROF.round?{cut:.25,iters:1,sub:2}:prof===PROF.wedge?{cut:.06,iters:2,sub:2}:{cut:.11,iters:2,sub:3};
    for(const [list,half] of [[aft,'aft'],[fore,'fore']]){ if(list.length<2) continue; this.push(loftVD(list,prof,fl,opt),mat,null,half); }
  }
  part(name,x,y,z,o={}){ const lib=partLib()[name]; const sc=o.s||1; for(const sub of lib){ const h=this.push(sub.vd,this.M[sub.mat]||this.M.dark,null,o.half); h.position.set(x,y,z); if(Array.isArray(sc)) h.scaling.set(sc[0],sc[1],sc[2]); else h.scaling.setAll(sc); h.rotation.set(o.rx||0,o.ry||0,o.rz||0); if(o.q) h.q=o.q; } }
  bake(){ const g={}; for(const h of this.parts){ (g[h.mat]=g[h.mat]||new GeoBuf()).add(h.vd,h.matrix()); } return Object.entries(g).map(([mat,b])=>({mat,vd:{positions:b.p,normals:b.n,indices:b.i}})); }
  plume(x,y,z,d,len){ const m=MB.CreateCylinder('plume',{height:len,diameterTop:d*.9,diameterBottom:0,tessellation:12},G.scene); m.bakeTransformIntoVertices(BABYLON.Matrix.RotationZ(-Math.PI/2)); m.position.set(x-len/2,y,z); m.material=this.M.plume; m.isPickable=false; this.plumes.push(m); return m; }
  engine(x,y,z,d){ this.part('nozzle',x,y,z,{s:d}); this.plume(x-d*.42,y,z,d*.85,d*1.9);
    const f=MB.CreatePlane('flare',{size:d*2.5},G.scene); f.billboardMode=BABYLON.Mesh.BILLBOARDMODE_ALL; f.position.set(x-d*.45,y,z); f.material=this.M.flare; f.isPickable=false; this.flares.push(f); }
  // surface kit-bash. Designed factions get mirrored (bilaterally symmetric) detail laid out in rows, which reads as engineered
  // rather than random; the corsairs keep their lopsided scatter
  greeble(n){ const r=seeded(Math.round(this.L*131)+n), M=this.M, L=this.L, st=this.stations, x0=st[0].x*.86, x1=st[st.length-1].x*.72, junk=this.fac==='corsair', gothic=this.fac==='voidsworn', sym=!junk;
    const parts=['vent','pipes','radiator','antenna'], N=sym?Math.round(n*.55):n;
    for(let i=0;i<N;i++){ let x=x0+(x1-x0)*r(); if(sym) x=Math.round(x/(L*.018))*L*.018; const s=this.surfAt(x); if(s.w<L*.02||(sym&&r()>s.w/(L*.09))) continue; const k=r(), side0=r()<.5?1:-1;
      const zs=(z)=>sym&&Math.abs(z)>L*.006?[Math.abs(z),-Math.abs(z)]:[z];
      if(k<.34){ const z0=(r()-.5)*s.w*1.1, sx=L*(.012+r()*.03), sy=L*(.003+r()*.007), sz=L*(.008+r()*.02), mat=r()<.35?M.dark:M.hull, rot=[(r()-.5)*.5,(r()-.5)*.6,(r()-.5)*.5];
        for(const z of zs(z0)){ const y=this.topY(s,z); if(sym) this.slab(mat,x,y-sy*.1,z,sx,sy*1.1,sz,sz*.8,{rake:.25,cut:.12}); else { const m=this.box(mat,x,y+sy/2,z,sx,sy,sz); m.rotation.set(rot[0],rot[1],rot[2]); } } }
      else if(k<.52){ const z0=(r()-.5)*s.w*.8, pk=parts[Math.floor(r()*3)], sc=L*(.018+r()*.025), ry=r()<.5?0:Math.PI/2; for(const z of zs(z0)) this.part(pk,x,this.topY(s,z),z,{s:sc,ry}); }
      else if(k<.6){ const z0=(r()-.5)*s.w*.6, sp=gothic&&r()<.6, sc=sp?L*(.012+r()*.012):L*(.015+r()*.03); for(const z of zs(z0)) this.part(sp?'spire':'antenna',x,this.topY(s,z),z,{s:sc}); }
      else if(k<.68){ const z0=(r()-.5)*s.w*.9, ln=L*(.03+r()*.1); for(const z of zs(z0)) this.cylX(M.steel,x,this.topY(s,z)+L*.004,z,ln,L*.005,L*.005,6); }
      else if(k<.75){ const z0=(r()-.5)*s.w*.7, d=L*(.01+r()*.018); for(const z of zs(z0)) this.sph(M.dark,x,this.topY(s,z),z,d,1,.5,1,8); }
      else { const y=(s.y||0)+(r()-.35)*s.t*.8, mat=r()<.5?M.dark:M.steel, sx=L*(.006+r()*.02), sy=L*(.01+r()*.03), rz=(r()-.5)*.6; for(const side of sym?[1,-1]:[side0]){ const m=this.box(mat,x,y,side*s.w*.99,sx,sy,L*.012); if(junk) m.rotation.z=rz; } } } }
  // v44: every visible barrel, per arc, so a broadside really is a broadside. Builders add exact ports; the rest is synthesised
  gunList(){ const G2=this.guns, L=this.L;
    if(this.stations){ for(const [arc,sd] of [['P',1],['S',-1]]) if(G2[arc].length<8){ for(let i=0;i<16;i++){ const x=(-.4+i*.048)*L, s=this.surfAt(x); if(s.w<L*.03) continue; G2[arc].push(new V3(x,(s.y||0)+s.t*(i%2?.12:.42),sd*(s.w+L*.012))); } }
      if(G2.T.length<6) for(let i=0;i<10;i++){ const x=(-.32+i*.065)*L, s=this.surfAt(x); if(s.w<L*.03) continue; const z=(i%2?1:-1)*s.w*.42; G2.T.push(new V3(x,this.topY(s,z)+L*.012,z)); }
      if(G2.F.length<3){ const x=.3*L, s=this.surfAt(x); for(const z of [-.5,.5]) for(const y of [.3,-.2]) G2.F.push(new V3(x+L*.06,(s.y||0)+y*s.t,z*s.w)); } }
    for(const arc of ['P','S','F','T']) for(const p of this.hard[arc]) G2[arc].push(p.clone()); return G2; }
  // navigation lights: red to port, green to starboard at the widest frame, white strobes fore and aft (space-opera running lights)
  navList(){ const L=this.L, out=[]; if(this.stations){ const st=this.stations; let wi=st[0]; for(const s of st) if(s.w>wi.w) wi=s;
      out.push({p:new V3(wi.x,(wi.y||0)+wi.t*.1,wi.w+L*.008),c:new C3(1,.15,.1),k:0},{p:new V3(wi.x,(wi.y||0)+wi.t*.1,-wi.w-L*.008),c:new C3(.15,1,.3),k:0});
      const a=st[0], f=st[st.length-1]; out.push({p:new V3(a.x+L*.02,(a.y||0)+a.t*1.05,0),c:new C3(1,1,1),k:1,ph:0},{p:new V3(f.x-L*.01,(f.y||0),0),c:new C3(1,1,1),k:1,ph:.5}); }
    else out.push({p:new V3(-.3*L,.02*L,0),c:new C3(1,1,1),k:1,ph:0}); return out; }
  finish(){
    if(this.greebleN&&this.stations) this.greeble(Math.round(this.greebleN));
    const root=new BABYLON.TransformNode('ship',G.scene), fore=new BABYLON.TransformNode('fore',G.scene), aft=new BABYLON.TransformNode('aft',G.scene); fore.parent=root; aft.parent=root;
    const groups={};
    for(const h of this.parts){ const half=h.half||(h.position.x>=this.split?'fore':'aft'); const k=h.mat.name+'|'+half; (groups[k]=groups[k]||{mat:h.mat,half,buf:new GeoBuf()}).buf.add(h.vd,h.matrix()); }
    const meshes=[]; let top=0; const M=this.M;
    for(const g of Object.values(groups)){ if(!g.buf.i.length) continue; const mm=g.buf.mesh('hull_'+g.mat.name); mm.material=g.mat; mm.parent=g.half==='fore'?fore:aft; mm.isPickable=true; mm.refreshBoundingInfo(true); mm.alwaysSelectAsActiveMesh=true;
      if(g.mat===M.hull||g.mat===M.dark||g.mat===M.trim||g.mat===M.steel) castShadows(mm); top=Math.max(top,mm.getBoundingInfo().boundingBox.maximum.y); meshes.push(mm); }
    for(const p of this.plumes) p.parent=aft; for(const f of this.flares) f.parent=aft;
    if(this.stations&&this.fac&&this.L>=6){ const em=emblemMat(this.fac), x=.17*this.L, st=this.surfAt(x), sz=Math.max(.9,Math.min((st.t+st.b)*.85,this.L*.07));
      for(const sd of [1,-1]){ const pl=MB.CreatePlane('emblem',{size:sz,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene); pl.material=em; pl.position.set(x,(st.y||0)+(st.t-st.b)*.25,sd*(st.w+this.L*.006)); pl.rotation.y=sd>0?Math.PI:0; pl.parent=x>=this.split?fore:aft; pl.isPickable=false; G.glow.addExcludedMesh(pl); } } for(const a of this.anim) a.node.parent=a.node.position.x>=this.split?fore:aft;
    return {root,fore,aft,meshes,surf:this.stations?{st:this.stations,prof:this.prof,split:this.split}:null,stacks:this.stacks||[],arcs:this.arcs||[],plumes:this.plumes,flares:this.flares,anim:this.anim,stacks:this.stacks,arcs:this.arcs,hard:this.hard,guns:this.gunList(),nav:this.navList(),bays:this.bays,L:this.L,H:top,fac:this.fac};
  }
}
// ---------- kitbash part library (unit-sized, built once) ----------
let PL=null;
function partLib(){ if(PL) return PL; PL={}; const mk=(name,fn)=>{ const b=new SB(null,1); fn(b,b.M); PL[name]=b.bake(); };
  mk('gwin',(b,M)=>{ b.box(M.dark,0,.5,0,.4,1.06,.08); b.cylY(M.dark,0,1.02,0,.36,0,.4,4,Math.PI/4,1,.2); b.box(M.win,0,.46,.045,.26,.84,.02); b.cylY(M.win,0,.87,.045,.22,0,.26,4,Math.PI/4,1,.08); b.box(M.dark,0,.5,.06,.035,.92,.02); b.box(M.dark,0,.62,.06,.26,.03,.02); });
  mk('spire',(b,M)=>{ b.box(M.hull,0,.15,0,.54,.3,.54); b.cylY(M.hull,0,.3,0,.38,.36,.42,8); b.cylY(M.dark,0,.68,0,.08,.44,.44,8); b.cylY(M.trim,0,.76,0,1.25,0,.34,8);
    for(const [x,z] of [[.22,.22],[-.22,.22],[.22,-.22],[-.22,-.22]]) b.cylY(M.trim,x,.3,z,.4,0,.1,4,Math.PI/4); for(let i=0;i<4;i++) b.box(M.win,Math.cos(i*Math.PI/2)*.19,.48,Math.sin(i*Math.PI/2)*.19,.07,.18,.07); b.sph(M.trim,0,2.02,0,.09); for(let k=0;k<5;k++) b.box(M.trim,0,.95+k*.2,0,.36-k*.06,.025,.36-k*.06,0,Math.PI/4,0); });
  mk('buttress',(b,M)=>{ const hb=b.box(M.hull,0,.66,.4,.09,.09,1.05); hb.rotation.x=.68; b.box(M.hull,0,.22,.82,.16,.44,.16); b.cylY(M.trim,0,.44,.82,.36,0,.12,4,Math.PI/4); b.box(M.dark,0,1.02,.02,.14,.12,.14); });
  mk('statue',(b,M)=>{ b.box(M.dark,0,.1,0,.3,.2,.3); b.cylY(M.trim,0,.2,0,.5,.1,.17,6); b.sph(M.trim,0,.8,0,.13); const w1=b.box(M.trim,-.05,.62,.15,.04,.5,.26); w1.rotation.x=.45; const w2=b.box(M.trim,-.05,.62,-.15,.04,.5,.26); w2.rotation.x=-.45; });
  mk('gunport',(b,M)=>{ b.box(M.dark,0,0,0,.92,.74,.2); b.box(M.hull,0,.45,.03,1.06,.14,.3); b.box(M.hull,0,-.44,.03,1.06,.1,.26); b.box(M.hull,.5,0,.03,.1,.9,.28); b.box(M.hull,-.5,0,.03,.1,.9,.28); b.cylZ(M.steel,0,0,.2,.62,.3,.24,10); b.cylZ(M.dark,0,0,.52,.1,.32,.32,10); });
  mk('battery',(b,M)=>{ b.cylY(M.dark,0,0,0,.25,.9,1,12); b.box(M.hull,0,.45,0,1,.4,.8); const f=b.box(M.hull,.48,.43,0,.3,.34,.74); f.rotation.z=-.5; for(const z of [-.24,0,.24]){ b.cylX(M.steel,.85,.5,z,1.1,.13,.1,8); b.cylX(M.dark,.3,.5,z,.2,.18,.18,8); } b.box(M.dark,-.3,.7,0,.3,.12,.5); b.box(M.win,.2,.62,.41,.3,.04,.02); });
  mk('antenna',(b,M)=>{ b.cylY(M.dark,0,0,0,1.6,.02,.06,5); for(const y of [.6,.95,1.25]) b.box(M.dark,0,y,0,.02,.02,.5*(1.4-y*.5)); b.sph(M.tip,0,1.62,0,.07); const d=b.cylY(M.steel,.14,.35,0,.12,.34,.02,10); d.rotation.z=-.7; });
  mk('vent',(b,M)=>{ b.box(M.dark,0,.04,0,1,.08,.6); for(let i=0;i<6;i++) b.box(M.steel,-.4+i*.16,.1,0,.05,.06,.52); });
  mk('pipes',(b,M)=>{ for(const z of [-.16,0,.16]) b.cylX(M.steel,0,.1,z,1,.1,.1,6); for(const x of [-.35,0,.35]) b.box(M.dark,x,.06,0,.08,.14,.5); });
  mk('radiator',(b,M)=>{ b.box(M.dark,0,.05,0,1,.1,.5); for(let i=0;i<8;i++) b.box(M.steel,-.42+i*.12,.3,0,.03,.5,.46); });
  mk('house',(b,M)=>{ b.box(M.hull,0,.35,0,1,.7,.6); b.box(M.dark,0,.72,0,1.04,.42,.42,Math.PI/4,0,0); for(const s of [1,-1]) for(const x of [-.3,0,.3]) b.box(M.win,x,.42,s*.305,.1,.24,.02); b.box(M.dark,0,.02,0,1.08,.06,.66); });
  mk('nozzle',(b,M)=>{ b.cylX(M.dark,.3,0,0,.6,1.1,1.02,16); b.cylX(M.steel,-.14,0,0,.5,1.25,.96,16); b.torusX(M.trim,.06,0,0,1.14,.08); b.torusX(M.dark,-.3,0,0,1.24,.06); b.cylX(M.eng,-.38,0,0,.03,1,1,16); for(let i=0;i<8;i++){ const a=i*Math.PI/4; b.box(M.dark,.35,Math.cos(a)*.55,Math.sin(a)*.55,.5,.06,.06); } });
  mk('trench',(b,M)=>{ b.box(M.dark,0,0,0,1,.05,.55); for(let i=0;i<4;i++) b.box(M.steel,-.36+i*.24,.04,(i%2?.12:-.12),.14,.05,.16); b.box(M.win,.42,.03,.2,.1,.02,.05); b.box(M.hull,0,.03,.3,1,.05,.04); b.box(M.hull,0,.03,-.3,1,.05,.04); });
  mk('container',(b,M)=>{ b.box(M.hull,0,.25,0,1,.5,.45); for(let i=0;i<5;i++) b.box(M.dark,-.4+i*.2,.25,0,.03,.52,.47); });
  mk('pylon',(b,M)=>{ b.cylY(M.dark,0,0,0,1,.08,.2,4,Math.PI/4); b.sph(M.win,0,1.05,0,.16); b.torusX(M.win,0,.6,0,.18,.03); });
  mk('crystal',(b,M)=>{ for(let i=0;i<5;i++){ const a=i*1.3; const c=b.cylY(M.win,Math.cos(a)*.12,0,Math.sin(a)*.12,.5+i*.15,0,.13,6); c.rotation.z=Math.cos(a)*.3; c.rotation.x=Math.sin(a)*.3; } });
  mk('pustule',(b,M)=>{ b.sph(M.dark,0,0,0,1,1,.55,1,10); b.sph(M.win,0,.2,0,.46,1,.6,1,8); });
  mk('spike',(b,M)=>{ b.cylY(M.trim,0,0,0,1,0,.22,6); });
  mk('girder',(b,M)=>{ b.box(M.dark,0,.2,0,1,.05,.05); b.box(M.dark,0,-.2,0,1,.05,.05); for(let i=0;i<6;i++){ const x=-.42+i*.17; const d=b.box(M.steel,x+.085,0,0,.03,.46,.03); d.rotation.z=(i%2?.62:-.62); b.box(M.dark,x,0,0,.03,.42,.03); } });
  mk('crane',(b,M)=>{ b.cylY(M.dark,0,0,0,1,.08,.12,6); const bm=b.box(M.steel,.35,.95,0,.8,.05,.05); bm.rotation.z=-.35; b.cylY(M.steel,.7,.55,0,.25,.01,.01,4); b.box(M.trim,.7,.52,0,.08,.06,.08); b.box(M.dark,0,.05,0,.3,.1,.3); });
  mk('stack',(b,M)=>{ b.cylY(M.dark,0,0,0,1,.22,.28,10); b.cylY(M.trim,0,.9,0,.1,.3,.3,10); b.cylY(M.ember,0,1,0,.02,.2,.2,10); for(let i=0;i<3;i++) b.cylY(M.steel,0,.2+i*.22,0,.04,.3,.3,10); });
  mk('horn',(b,M)=>{ let y=0,x=0; for(let i=0;i<4;i++){ const c=b.cylX(M.trim,x+.12,y,0,.3,.22-i*.05,.17-i*.05,6); c.rotation.z=i*.18; x+=.26; y+=i*.05; } });
  mk('eyes',(b,M)=>{ for(let i=0;i<6;i++){ const a=i*1.05; b.sph(M.win,Math.cos(a)*.2,Math.sin(a)*.13,.06,.12+(i%2)*.07,1,1,1,8); } b.sph(M.dark,0,0,-.05,.55,1,.8,.4,10); });
  mk('vane',(b,M)=>{ b.cylX(M.hull,0,0,0,1,.16,.01,4,1,.12); b.box(M.trim,.05,0,0,.9,.012,.035); b.sph(M.win,.5,0,0,.07,1,1,1,8); });
  mk('coil',(b,M)=>{ b.cylY(M.dark,0,0,0,.9,.1,.16,6); for(let i=0;i<4;i++) b.cylY(M.steel,0,.18+i*.16,0,.03,.34-i*.04,.34-i*.04,12); b.sph(M.win,0,1,0,.2,1,1,1,10); });
  mk('obelisk',(b,M)=>{ b.cylY(M.dark,0,0,0,1,.14,.2,4,Math.PI/4); b.cylY(M.dark,0,1,0,.14,0,.14,4,Math.PI/4); b.box(M.win,0,.5,.075,.03,.7,.01); b.box(M.win,0,.5,-.075,.03,.7,.01); b.box(M.win,.075,.5,0,.01,.7,.03); });
  mk('zig',(b,M)=>{ for(let i=0;i<4;i++){ const w=1-i*.22, wt=w*.84; b.slab(M.dark,0,i*.2,0,w,.205,w,wt,{rake:.16,shrink:.86,cut:.08}); const zw=(w+wt)/4+.006; for(const sg of [1,-1]){ b.box(M.win,0,.1+i*.2,sg*zw,w*.72,.014,.01); b.box(M.win,sg*zw,.1+i*.2,0,.01,.014,w*.72); } } b.sph(M.win,0,.95,0,.18,1,1,1,10); });
  mk('glyph',(b,M)=>{ b.box(M.dark,0,.02,0,1,.04,.6); b.box(M.win,0,.046,0,.8,.012,.03); b.box(M.win,.2,.046,.15,.03,.012,.3); b.box(M.win,-.25,.046,-.12,.03,.012,.25); b.box(M.win,-.05,.046,.2,.25,.012,.03); });
  return PL; }
// ---------- Voidsworn: gothic cathedral ships ----------
const GOTHIC={
  Frigate:{w:.105,t:.075,b:.065,spires:1,tower:.7,decks:0,eng:1,prowGun:1},
  Destroyer:{w:.1,t:.075,b:.07,spires:1,tower:.8,decks:0,eng:2,torp:1,turret:1},
  Cruiser:{w:.105,t:.078,b:.07,spires:2,tower:1,decks:2,eng:3,lance:1},
  Carrier:{w:.15,t:.07,b:.075,spires:2,tower:.85,decks:0,eng:3,bays:1,turret:1},
  Battleship:{w:.115,t:.082,b:.075,spires:3,tower:1.15,decks:3,eng:4,lance:1,turret:1},
  Dreadnought:{w:.12,t:.085,b:.08,spires:5,tower:1.35,decks:3,eng:5,nova:1,turret:2},
};
function buildGothic(b,cls){
  const p=GOTHIC[cls]||GOTHIC.Cruiser, L=b.L, M=b.M, W=p.w*L, T=p.t*L, Bt=p.b*L;
  b.split=-.04*L;
  const sts=[[-.5,.72,.78,.7],[-.45,.96,1,.95],[-.1,1,1,1],[.2,.94,.96,.95],[.34,.72,.84,.9],[.44,.38,.56,.8],[.5,.06,.14,.55]]
    .map(([x,w,t,bb])=>({x:x*L,w:w*W*(p.bays&&x>-.4&&x<.3?1.12:1),t:t*T,b:bb*Bt}));
  b.loft(M.hull,sts,PROF.gothic2);
  // keel blade and armoured ram
  b.slab(M.dark,-.08*L,-Bt*1.45,0,.62*L,Bt*.62,W*.1,W*.3,{rake:.35,rakeB:.2,shrink:.4});
  b.cylX(M.trim,.53*L,-Bt*.25,0,.16*L,W*.7,0,4,.55,1).rotation.x=Math.PI/4;
  b.slab(M.trim,.36*L,T*.05-T*.25,0,.14*L,T*.5,W*1.5,W*1.22,{rake:.3,rakeB:.1});
  // stepped deck city
  let x=-.2*L; const steps=cls==='Frigate'?2:4;
  for(let i=0;i<steps;i++){ const len=.1*L, h=T*(.55-.08*i), wd=W*(1.3-.12*i), ang=Math.atan2(wd*.11,h), zw=wd/2*(1-.62*.22)+.012*L;
    b.slab(i%2?M.dark:M.hull,x,T-h*.04,0,len,h*1.04,wd,wd*.78,{rake:.12}); for(const sd of [1,-1]) b.box(M.win,x,T+h*.62,sd*zw,len*.78,h*.09,.004*L,sd*ang,0,0); x+=len*1.02; }
  // cathedral tower with spires and flying buttresses
  const tx=-.3*L, th=.14*L*p.tower;
  b.slab(M.hull,tx,T-th*.03,0,.13*L,th*1.03,W*1.25,W*1.02,{rake:.1}); b.slab(M.dark,tx,T+th,0,.1*L,th*.5,W*.92,W*.62,{rake:.18,shrink:.6});
  b.box(M.win,tx+.066*L,T+th*.7,0,.02,th*.35,W*.5); // great window facing the prow
  const spireH=.2*L*p.tower;
  b.cylY(M.trim,tx,T+th*1.5,0,spireH,0,W*.55,4,Math.PI/4);
  const tipY=T+th*1.5+spireH; b.flashers.push(b.sph(M.tip,tx,tipY+.2,0,Math.max(.25,L*.012)));
  for(let s=1;s<p.spires;s++){ const side=s%2?1:-1, off=Math.ceil(s/2); const sx=tx+(.07*off)*L*(s>2?1:.2), sz=side*W*(.45+.12*off); const hh=spireH*(.62-.08*off);
    b.slab(M.hull,sx,T-th*.02,sz,.06*L,th*.82,W*.32,W*.22,{rake:.15}); b.cylY(M.trim,sx,T+th*.8,sz,hh,0,W*.3,4,Math.PI/4); }
  for(const side of [1,-1]){ const bt=b.box(M.dark,tx+.02*L,T+th*.55,side*W*1.05,.035*L,th*.9,W*.12); bt.rotation.x=side*.55; }
  // broadside gun decks (port +z, starboard -z)
  for(let d=0;d<p.decks;d++){ const y=T*.45-d*(T+Bt)*.3; const n=cls==='Dreadnought'?26:cls==='Battleship'?22:15;
    for(let i=0;i<n;i++){ const gx=(-.26+i*(.5/(n-1)))*L; const zz=W*(gx>.3*L?.8:1);
      for(const side of [1,-1]){ b.part('gunport',gx,y,side*(zz+.004*L),{s:L*.021,ry:side>0?0:Math.PI}); (side>0?b.guns.P:b.guns.S).push(new V3(gx,y,side*(zz+.016*L)));
        if(i%4===0) (side>0?b.hard.P:b.hard.S).push(new V3(gx,y,side*(zz+.065*L))); } }
    for(const side of [1,-1]){ b.cylX(M.dark,-.01*L,y,side*(W+.004*L),.54*L,.03*L,.03*L,12,1,.45); b.cylX(M.trim,-.01*L,y+.018*L,side*(W+.008*L),.54*L,.007*L,.007*L,8); }
  }
  if(!p.decks){ for(const side of [1,-1]) b.box(M.win,-.05*L,T*.35,side*(W+.01),.5*L,T*.07,.05); b.hard.P.push(new V3(0,T*.4,W*1.1)); b.hard.S.push(new V3(0,T*.4,-W*1.1)); }
  // dorsal turrets
  for(let i=0;i<(p.turret||0);i++){ const gx=(.12-i*.3)*L, gy=T+(i?.6:.35)*T; b.cylY(M.dark,gx,T,0,gy-T+.1,W*.7,W*.85,10); b.slab(M.hull,gx,gy+.075*T,0,.08*L,T*.35,W*.72,W*.5,{rake:.45,rakeB:.12,shrink:.55});
    for(const z of [-.15,.15]) b.cylX(M.trim,gx+.07*L,gy+.28*T,z*W,.1*L,W*.12,W*.1,8); b.hard.T.push(new V3(gx+.12*L,gy+.3*T,0)); }
  // prow weapons
  if(p.lance){ b.cylX(M.dark,.44*L,T*.55,0,.2*L,W*.3,W*.22,10); b.cylX(M.win,.545*L,T*.55,0,.012*L,W*.24,W*.24,10); b.torusX(M.trim,.47*L,T*.55,0,W*.42,W*.08); b.hard.F.push(new V3(.56*L,T*.55,0)); }
  if(p.torp){ for(const z of [-.3,.3]) for(const y of [.1,-.35]){ b.cylX(M.dark,.47*L,y*T,z*W,.06*L,W*.22,W*.22,10); b.hard.F.push(new V3(.51*L,y*T,z*W)); } }
  if(p.prowGun){ for(const z of [-.25,.25]) b.cylX(M.trim,.48*L,T*.45,z*W,.12*L,W*.12,W*.1,8); b.hard.F.push(new V3(.55*L,T*.45,0)); }
  if(p.nova){ b.cylX(M.dark,.35*L,T*.35,0,.62*L,W*.5,W*.42,14); for(let i=0;i<6;i++) b.torusX(M.trim,(.12+i*.1)*L,T*.35,0,W*.62,W*.1); b.cylX(M.win,.665*L,T*.35,0,.01*L,W*.36,W*.36,14); b.hard.F.push(new V3(.68*L,T*.35,0)); }
  if(!b.hard.F.length) b.hard.F.push(new V3(.5*L,T*.3,0));
  if(!b.hard.T.length) b.hard.T.push(new V3(-.05*L,T*1.4,0));
  // carrier launch bays
  if(p.bays){ for(const side of [1,-1]) for(const bx of [-.12,.08]){ b.box(M.dark,bx*L,-Bt*.05,side*(W*1.12),.15*L,(T+Bt)*.6,.05*L); b.box(M.win,bx*L,-Bt*.05,side*(W*1.12+.026*L),.13*L,(T+Bt)*.45,.02); b.bays.push(new V3(bx*L,-Bt*.05,side*W*1.3)); }
    b.box(M.dark,.02*L,T+.03*L,0,.5*L,.02*L,W*1.6); for(let i=0;i<10;i++) for(const z of [-.55,.55]) b.box(M.win,(-.22+i*.05)*L,T+.042*L,z*W,.012*L,.005*L,.012*L); }
  // engines
  const n=p.eng, ed=Math.min(W*.85,T*1.3)*(n>3?.8:1);
  const slots=[[0,0],[.45,.55],[-.45,.55],[.45,-.55],[-.45,-.55]].slice(0,n);
  if(n===2){ slots[0]=[0,.45]; slots[1]=[0,-.45]; }
  for(const [yy,zz] of slots) b.engine(-.5*L,yy*T,zz*W,ed);
  gothicDetail(b,p,cls,W,T,Bt);
  return b.finish();
}

// ---------- Hegemony: wedge-hulled star destroyers ----------
const WEDGE={
  Frigate:{wr:.2,t:.05,b:.04,eng:2,pods:1},
  Destroyer:{wr:.27,t:.058,b:.048,eng:3,ion:1,terr:2},
  Cruiser:{wr:.3,t:.062,b:.052,eng:3,bay:1,terr:3},
  Battleship:{wr:.33,t:.068,b:.058,eng:4,bay:1,terr:4},
  'Super-dreadnought':{wr:.24,t:.052,b:.045,eng:6,terr:6,spinal:1},
};
function buildWedge(b,cls){
  const p=WEDGE[cls]||WEDGE.Cruiser, L=b.L, M=b.M, Wr=p.wr*L, T=p.t*L, Bt=p.b*L;
  b.split=-.08*L;
  const sts=[[-.5,1,1,1],[-.32,.84,1,.95],[-.05,.58,.82,.78],[.25,.3,.52,.48],[.5,.02,.1,.08]].map(([x,w,t,bb])=>({x:x*L,w:w*Wr,t:t*T,b:bb*Bt}));
  b.loft(M.hull,sts,PROF.wedge);
  const wAt=x=>Wr*(1-(x/L+.5)*.98);
  const tAt=x=>{ for(let i=0;i<sts.length-1;i++){ const a=sts[i],c=sts[i+1]; if(x>=a.x&&x<=c.x){ const k=(x-a.x)/(c.x-a.x); return a.t+(c.t-a.t)*k; } } return T*.1; };
  // edge trench lines and window strips along the knife edge
  const ang=Math.atan2(Wr*.98,L), elen=Math.hypot(L,Wr*.98);
  for(const side of [1,-1]){ b.box(M.dark,0,0,side*(wAt(0)+.002*L),elen,.016*L,.01*L,0,side*ang,0);
    for(let i=0;i<22;i++){ const x=(-.46+i*.04)*L; b.box(M.win,x,.011*L,side*(wAt(x)-.004*L),.012*L,.004*L,.006*L,0,side*ang,0); } }
  // terraced superstructure
  let tx=-.44*L;
  for(let i=0;i<(p.terr||1);i++){ const len=.11*L*(1-i*.06), wd=wAt(tx)*.9, h=T*(.55-i*.06);
    b.slab(M.hull,tx+len/2,T*.9-.1,0,len,h,wd,wd*.8,{rake:.1,rakeB:.04}); b.slab(M.dark,tx+len/2,T*.9+h-.1-h*.01,0,len*.92,h*.13,wd*.66,wd*.56,{rake:.2});
    const ang=Math.atan2(wd*.1,h); for(let k=0;k<3;k++){ const f=.22+.22*k; for(const sd of [1,-1]) b.box(M.win,tx+len/2,T*.9+h*f-.1,sd*(wd/2*(1-f*.2)+.003*L),len*.84,h*.04,.003*L,sd*ang,0,0); }
    b.part('vent',tx+len*.3,T*.9+h-.1+h*.075,wd*.2,{s:[len*.35,L*.012,wd*.25]}); b.part('radiator',tx+len*.7,T*.9+h-.1+h*.075,-wd*.2,{s:[len*.25,L*.012,wd*.2]}); tx+=len*.95; }
  // bridge tower on a neck with a T-shaped command deck and sensor masts
  const bx=-.4*L, by=T*1.5;
  b.slab(M.hull,bx,by-.002*L,0,.06*L,.1*L,.06*L,.036*L,{rake:.25});
  b.slab(M.hull,bx,by+.095*L,0,.075*L,.032*L,.17*L,.22*L,{rake:.3,rakeB:.1,shrink:.55}); b.box(M.win,bx+.036*L,by+.112*L,0,.004*L,.008*L,.18*L);
  b.box(M.trim,bx+.02*L,by+.127*L,0,.012*L,.004*L,.2*L);
  for(const z of [-.08,.08]){ b.cylY(M.dark,bx-.01*L,by+.125*L,z*L,.07*L,.002*L,.008*L,6); b.flashers.push(b.sph(M.tip,bx-.01*L,by+.2*L,z*L,.012*L)); }
  // turbolaser turrets along the upper slopes
  for(const x of [-.3,-.14,.02,.16]){ const xx=x*L; for(const side of [1,-1]){ const z=side*wAt(xx)*.5, y=tAt(xx)*.58;
      b.box(M.dark,xx,y+.012*L,z,.03*L,.018*L,.03*L); for(const dz of [-.006,.006]) b.cylX(M.dark,xx+.025*L,y+.02*L,z+dz*L,.035*L,.006*L,.005*L,6);
      (side>0?b.hard.P:b.hard.S).push(new V3(xx+.04*L,y+.02*L,z)); } }
  b.hard.T.push(new V3(-.2*L,T*1.4,0),new V3(0,T*1.1,0));
  b.box(M.trim,.18*L,T*.36,0,.2*L,.006*L,.03*L);
  b.hard.F.push(new V3(.46*L,T*.15,0));
  if(p.ion){ b.torusX(M.dark,.3*L,T*.35,0,.07*L,.012*L); b.torusX(M.eng,.33*L,T*.35,0,.055*L,.006*L); b.cylX(M.trim,.38*L,T*.35,0,.14*L,.02*L,.004*L,6); b.hard.F.unshift(new V3(.45*L,T*.35,0)); }
  if(p.bay){ b.box(M.dark,-.1*L,-Bt*.95,0,.2*L,.02*L,Wr*.5); b.box(M.win,-.1*L,-Bt*.97,0,.17*L,.01*L,Wr*.38); b.bays.push(new V3(-.1*L,-Bt*1.2,0)); }
  if(p.spinal){ b.cylX(M.dark,.18*L,T*1.25,0,.6*L,.05*L,.04*L,12); for(let i=0;i<5;i++) b.torusX(M.trim,(-.02+i*.1)*L,T*1.25,0,.07*L,.01*L); b.cylX(M.eng,.485*L,T*1.25,0,.01*L,.035*L,.035*L,12); b.hard.F.unshift(new V3(.5*L,T*1.25,0));
    const bx2=-.2*L; b.slab(M.hull,bx2,T*1.5,0,.05*L,.08*L,.05*L,.03*L,{rake:.25}); b.slab(M.hull,bx2,T*1.5+.077*L,0,.065*L,.026*L,.12*L,.16*L,{rake:.3,rakeB:.1,shrink:.55}); b.box(M.win,bx2+.031*L,T*1.5+.092*L,0,.003*L,.007*L,.13*L); }
  if(p.pods){ for(const side of [1,-1]){ b.box(M.dark,-.3*L,0,side*Wr*.8,.12*L,.02*L,Wr*.5); b.cylX(M.hull,-.32*L,0,side*Wr*1.1,.34*L,.07*L,.05*L,10); b.engine(-.5*L,0,side*Wr*1.1,.06*L); } }
  // stern engines
  const n=p.eng; for(let i=0;i<n;i++){ const z=(i-(n-1)/2)*(Wr*1.6/n); const y=(i%2?-.25:.15)*T; b.engine(-.5*L,y,z,Math.min(Wr*1.4/n,T*1.3)); }
  wedgeDetail(b,p,cls,Wr,T,Bt);
  return b.finish();
}

// ---------- per-faction detail passes ----------
function gothicDetail(b,p,cls,W,T,Bt){ const L=b.L, M=b.M, r=seeded(Math.round(L*37)+cls.length), big=L>=14, tx=-.3*L, th=.14*L*p.tower;
  for(let x=-.45;x<=.32;x+=big?.022:.035){ const s=b.surfAt(x*L); for(const side of [1,-1]) b.box(M.hull,x*L,-s.b*.05,side*s.w*1.005,.005*L,(s.t+s.b)*.62,.008*L); }
  const rows=big?(p.decks||1)+1:1;
  for(let k=0;k<rows;k++){ const y=T*.36-k*(T+Bt)*.27; for(let x=-.42;x<=.3;x+=big?.017:.028){ const s=b.surfAt(x*L); if(s.w<W*.7) continue; for(const side of [1,-1]) b.part('gwin',x*L,y-L*.009,side*(s.w+.001*L),{s:L*.013,ry:side>0?0:Math.PI}); } }
  for(let x=-.36;x<=.3;x+=.07){ const s=b.surfAt(x*L); for(const side of [1,-1]) b.part('statue',x*L,s.t,side*s.w*.84,{s:L*.024,ry:side>0?0:Math.PI}); }
  for(let x=-.2;x<=.3;x+=.038){ const s=b.surfAt(x*L); for(const zf of [-.56,.56]){ if(r()<.2) continue; const hh=1+r()*.8; b.part('house',x*L,s.t,zf*s.w,{s:[L*.032,L*.026*hh,L*.024]}); if(r()<.3) b.part('spire',x*L,s.t+L*.026*hh*.9,zf*s.w,{s:L*.018}); } }
  for(let row=0;row<3;row++) for(let c=0;c<4;c++){ const x=tx+(-.045+c*.03)*L, f=.16+row*.26, y=T+th*f; for(const side of [1,-1]) b.part('gwin',x,y,side*(W*.625*(1-f*.184)+.002*L),{s:L*.02,ry:side>0?0:Math.PI}); }
  for(let row=0;row<2;row++) for(let c=0;c<3;c++) b.part('gwin',tx+.066*L,T+th*(.2+row*.3),(c-1)*W*.35,{s:L*.018,ry:Math.PI/2});
  for(const dx of [-.05,0,.05]) for(const side of [1,-1]) b.part('buttress',tx+dx*L,T,side*W*.62,{s:L*.07,ry:side>0?0:Math.PI});
  for(const [dx,dz] of [[-.05,.4],[.05,.4],[-.05,-.4],[.05,-.4]]) b.part('spire',tx+dx*L,T+th,dz*W,{s:L*.04});
  b.part('antenna',tx-.04*L,T+th*1.5,0,{s:L*.05}); b.part('antenna',tx+.02*L,T+th*1.5,W*.2,{s:L*.035});
  for(const side of [1,-1]) for(let i=0;i<6;i++){ const h=b.box(M.trim,.425*L,T*.1+i*.012*L,side*(.12+i*.13)*W,.006*L,.01*L,.16*W); h.rotation.x=side*(.3+i*.1); }
  b.sph(M.trim,.43*L,T*.12,0,W*.35,.6,1,.9);
  b.part('spire',-.1*L,-Bt*1.3,0,{s:L*.05,rx:Math.PI}); b.part('antenna',.1*L,-Bt*.95,0,{s:L*.04,rx:Math.PI});
  for(const side of [1,-1]){ b.part('radiator',-.43*L,T*.95,side*W*.45,{s:L*.05}); b.part('vent',-.36*L,T,side*W*.3,{s:L*.04}); b.part('pipes',-.3*L,T,side*W*.75,{s:[L*.1,L*.02,L*.03]}); }
}
function wedgeDetail(b,p,cls,Wr,T,Bt){ const L=b.L, M=b.M, r=seeded(Math.round(L*53)+cls.length);
  for(let x=-.45;x<=.38;x+=.035){ const s=b.surfAt(x*L); if(s.w<L*.03) continue; const slope=(s.t*.86)/s.w, slopeB=(s.b*.86)/s.w;
    for(const f of [.2,.4,.6,.8]){ if(r()<.2) continue; const under=f<.7&&r()<.5; for(const side of [1,-1]){ const z=side*f*s.w;
      b.part('trench',x*L,b.topY(s,z)+.0015*L,z,{s:[L*.03,L*.018,L*.02],q:qFromUp(new V3(0,1,side*slope).normalize())});
      if(under){ const yb=(s.y||0)-s.b*(1-Math.min(1,Math.abs(z)/s.w)*.86); b.part('trench',x*L,yb-.0015*L,z,{s:[L*.03,L*.018,L*.02],q:qFromUp(new V3(0,-1,side*slopeB).normalize())}); } } } }
  for(let x=-.36;x<=.26;x+=.05) for(const side of [1,-1]){ const s=b.surfAt(x*L), z=side*s.w*.66, y=b.topY(s,z); b.part('battery',x*L,y,z,{s:L*.02,ry:side*-.3}); (side>0?b.guns.P:b.guns.S).push(new V3(x*L+L*.018,y+L*.01,z+side*L*.004)); b.guns.T.push(new V3(x*L+L*.018,y+L*.01,z)); }
  for(let x=-.2;x<=.4;x+=.04){ const s=b.surfAt(x*L); b.slab(M.dark,x*L,s.t-.001*L,0,.032*L,.007*L,.024*L,.016*L,{rake:.3}); if(r()<.4){ const z=r()*s.w*.15+.01*L; for(const sd of [1,-1]) b.part('vent',x*L,b.topY(s,sd*z),sd*z,{s:L*.022}); } }
  const bx=-.4*L, by=T*1.5; for(const z of [-.08,-.03,.03,.08]) b.part('antenna',bx-.02*L,by+.125*L,z*L,{s:L*.035});
  for(let i=0;i<3;i++) b.box(M.win,bx+.036*L,by+.08*L+i*.012*L,0,.003*L,.004*L,.05*L);
  for(let x=-.45;x<=.45;x+=.05){ const s=b.surfAt(x*L); for(const side of [1,-1]) b.box(M.tip,x*L,0,side*(s.w+.002*L),.004*L,.004*L,.004*L); }
  for(const side of [1,-1]){ b.part('radiator',-.44*L,T*.9,side*Wr*.4,{s:L*.05}); b.part('pipes',-.38*L,T*.95,side*Wr*.2,{s:[L*.08,L*.02,L*.03]}); }
}
function junkDetail(b,p,cls,W,T,Bt){ const L=b.L,M=b.M,r=seeded(Math.round(L*71)+cls.length);
  for(let i=0;i<Math.round(L*1.2);i++){ const x=(r()-.55)*.8*L, s=b.surfAt(x), z=(r()-.5)*s.w*1.2, y=b.topY(s,z), k=r();
    if(k<.35) b.part('container',x,y,z,{s:[L*(.03+r()*.03),L*.025,L*.022],ry:(r()-.5)*.6});
    else if(k<.55) b.part('pipes',x,y,z,{s:[L*.06,L*.02,L*.025],ry:(r()-.5)*.4});
    else if(k<.7){ b.cylY(M.dark,x,y,z,L*(.03+r()*.05),L*.012,L*.016,8); b.sph(M.ember,x,y+L*.06,z,L*.01); }
    else if(k<.85) b.part('radiator',x,y,z,{s:L*.035,ry:r()*3});
    else { const h=b.box(M.hull,x,y+.01*L,z,L*(.04+r()*.06),L*.008,L*(.03+r()*.04)); h.rotation.set((r()-.5)*.5,r()*3,(r()-.5)*.5); } }
  for(let i=0;i<7;i++) b.part('spike',.55*L,-Bt*.1+(i%2)*T*.3,(i-3)*W*.2,{s:L*.04,rz:-Math.PI/2});
  for(let i=0;i<Math.round(L*.35);i++){ const x=(r()-.55)*.7*L, s=b.surfAt(x), side=r()<.5?1:-1; b.part('girder',x,(s.y||0)+(r()-.3)*s.t,side*s.w*(1+r()*.15),{s:[L*(.06+r()*.08),L*.03,L*.03],ry:(r()-.5)*.4,rx:(r()-.5)*.3}); }
  for(let i=0;i<2;i++){ const x=(-.1+i*.25)*L, s=b.surfAt(x); b.part('crane',x,b.topY(s,0),(i?1:-1)*s.w*.3,{s:L*.08,ry:r()*6}); }
  b.stacks=[]; for(let i=0;i<(cls==='Frigate'?1:3);i++){ const x=(-.38+i*.06)*L, s=b.surfAt(x), z=(r()-.5)*s.w*.8, y=b.topY(s,z); b.part('stack',x,y,z,{s:[L*.035,L*.08,L*.035]}); b.stacks.push(new V3(x,y+L*.08,z)); }
  for(let x=-.3;x<=.3;x+=.06){ const s=b.surfAt(x*L); b.part('spike',x*L,b.topY(s,0),0,{s:L*.035}); }
  for(let i=0;i<8;i++) b.box(i%2?M.dark:M.trim,.47*L,-Bt*.1,(i-3.5)*W*.18,.02*L,T*.5,W*.16);
  for(let i=0;i<Math.round(L*.5);i++){ const x=(r()-.5)*.7*L, s=b.surfAt(x), side=r()<.5?1:-1; b.box(M.win,x,(s.y||0)+(r()-.2)*s.t*.6,side*(s.w+.003*L),L*(.03+r()*.08),.004*L,.004*L); }
  for(let i=0;i<Math.round(L*.5);i++){ const x=(r()-.5)*.6*L, s=b.surfAt(x), z=(r()-.5)*s.w, y=b.topY(s,z); b.part('battery',x,y,z,{s:L*.018,ry:(r()-.5)*2}); }
}
function bioDetail(b,p,cls,W,T,Bt){ const L=b.L,M=b.M,r=seeded(Math.round(L*29));
  for(let x=-.42;x<=.42;x+=.05){ const s=b.surfAt(x*L); const h=b.torusX(M.dark,x*L,(s.y||0),0,s.w*2.03,L*.012); h.scaling.set(1,Math.max(.3,s.t/Math.max(.01,s.w)),1); }
  for(let i=0;i<Math.round(L*1.4);i++){ const x=(r()-.5)*.85*L, s=b.surfAt(x), a=r()*Math.PI*2, z=Math.cos(a)*s.w*.95, y=Math.sin(a)>0?Math.sin(a)*s.t*.95:Math.sin(a)*s.b*.95; const n=new V3(0,y/Math.max(.01,s.t),z/Math.max(.01,s.w)).normalize();
    if(r()<.55) b.part('pustule',x,y,z,{s:L*(.02+r()*.025),q:qFromUp(n)}); else b.part('spike',x,y,z,{s:L*(.03+r()*.05),q:qFromUp(n)}); }
  for(let x=-.4;x<=.38;x+=.042){ const s=b.surfAt(x*L); for(const zf of [-.45,0,.45]){ const z=zf*s.w, y=b.topY(s,z); const h=b.sph(M.dark,x*L,y,z,L*.055,1.4,.32,1,10); h.q=qFromUp(new V3(-.35,1,zf*1.2).normalize()); } }
  for(let x=-.3;x<=.3;x+=.075){ const s=b.surfAt(x*L); const pts=[]; for(let a=-100;a<=100;a+=12){ const rr=a*Math.PI/180; pts.push(new V3(x*L,(s.y||0)+Math.cos(rr)*s.t*1.08,Math.sin(rr)*s.w*1.08)); } tube(b,M.trim,pts,(i)=>L*.009*(1-Math.abs(i-8)/12),6); }
  for(let v=0;v<6;v++){ const pts=[]; const ph=r()*6, zf=(v%2?1:-1)*(.35+r()*.5); for(let i=0;i<=14;i++){ const x=(-.42+i*.058)*L, s=b.surfAt(x); pts.push(new V3(x,(s.y||0)+Math.sin(i*.8+ph)*s.t*.35,zf*s.w*1.01)); } tube(b,M.win,pts,()=>L*.004,4); }
  for(const side of [1,-1]){ b.part('horn',.42*L,-Bt*.2,side*W*.35,{s:L*.1,ry:side*-.35}); b.part('eyes',.45*L,T*.35,side*W*.3,{s:L*.05,ry:Math.PI/2}); }
  b.add(sailMesh(-.3*L,.2*L,T*.75,T*1.5,.25*L),M.sail,'fore');
  if(p.sacs) for(let i=0;i<4;i++){ const x=(-.25+i*.14)*L, s=b.surfAt(x), z=(i%2?1:-1)*s.w*.3, y=b.topY(s,z); b.cylY(M.dark,x,y,z,L*.09,L*.02,L*.035,8); b.sph(M.win,x,y+L*.09,z,L*.03); }
}
function sailDetail(b,p,cls,W,T,Bt){ const L=b.L,M=b.M,r=seeded(Math.round(L*19));
  for(const side of [1,-1]) for(const yy of [.35,-.25]){ const pts=[]; for(let i=0;i<=16;i++){ const x=(-.45+i*.058)*L, s=b.surfAt(x); pts.push(new V3(x,yy*s.t,side*s.w*1.01)); } tube(b,M.win,pts,()=>.004*L,4); }
  for(let i=0;i<Math.round(L*.5);i++){ const x=(-.35+r()*.7)*L, s=b.surfAt(x); b.part('crystal',x,s.t*.9,(r()-.5)*s.w,{s:L*.03}); }
  for(let x=-.4;x<=.4;x+=.08){ const s=b.surfAt(x*L); b.torusX(M.trim,x*L,(s.y||0),0,Math.max(s.w,s.t)*2.1,L*.006); }
  for(let i=0;i<(p.sails>2?6:4);i++){ const x=(-.25+i*.09)*L, s=b.surfAt(x); for(const up of [1,-1]) for(const side of [1,-1]) b.part('vane',x,(s.y||0)+up*s.t*.6,side*s.w*.6,{s:L*.16,ry:Math.PI+side*.3,rz:up*.45,rx:side*up*.55}); }
  const halos=cls==='Ark'?3:cls==='Frigate'?1:2; for(let i=0;i<halos;i++){ const x=(-.05-i*.15)*L, d=Math.max(W,T)*4.4+i*L*.05; b.torusX(M.trim,x,0,0,d,L*.009); b.torusX(M.win,x,0,0,d*.95,L*.003); }
  for(let k=0;k<3;k++){ const pts=[]; const x0=(-.35+k*.2)*L; for(let a=0;a<=180;a+=15){ const rr=a*Math.PI/180; pts.push(new V3(x0+Math.cos(rr)*L*.07,Math.sin(rr)*T*2.4,0)); } tube(b,M.trim,pts,()=>L*.004,4); }
  b.part('crystal',.52*L,0,0,{s:L*.07,rz:-Math.PI/2}); for(const side of [1,-1]) b.part('crystal',-.1*L,-Bt*1.1,side*W*.5,{s:L*.045,rx:Math.PI});
}
function tombDetail(b,p,cls,R,cx){ const L=b.L; const n=Math.round(p.arc/12);
  for(let i=1;i<n;i++){ const a=(-p.arc/2+p.arc*i/n)*Math.PI/180, x=cx+Math.cos(a)*R-R*.45, z=Math.sin(a)*R, u=i/n, taper=Math.min(u,1-u)*2, y=p.th*L*.4*(.2+.8*taper)+.001*L;
    b.part('glyph',x,y,z,{s:[L*.045,L*.02,L*.03],ry:-a}); (z>=0?b.guns.P:b.guns.S).push(new V3(x,y+L*.012,z)); if(i%2===0) b.guns.T.push(new V3(x,y+L*.012,z)); if(i%3===0) b.part('pylon',x,y,z,{s:L*(.03+.03*taper)}); }
  const R2=R*.72, pts=[]; for(let i=0;i<=20;i++){ const a=(-p.arc*.4+p.arc*.8*i/20)*Math.PI/180; pts.push(new V3(cx+Math.cos(a)*R2-R*.45,p.th*L*.5,Math.sin(a)*R2)); } tube(b,b.M.hull,pts,(i)=>p.th*L*.4*(1-Math.abs(i-10)/12),4,true,.5);
  b.part('zig',-.08*L,.02*L,0,{s:L*(cls==='Frigate'?.08:.13)});
  for(let i=1;i<8;i++){ const a=(-p.arc/2+p.arc*i/8)*Math.PI/180; b.part('obelisk',cx+Math.cos(a)*R*.84-R*.45,.02*L,Math.sin(a)*R*.84,{s:L*.07}); }
  b.arcs=[]; for(const sg of [1,-1]){ const a=p.arc/2*Math.PI/180*sg*.9; const pos=new V3(cx+Math.cos(a)*R-R*.45,.02*L,Math.sin(a)*R); b.part('coil',pos.x,pos.y,pos.z,{s:L*.07}); b.arcs.push(pos.add(new V3(0,L*.07,0))); }
  b.arcs.push(new V3(-.08*L,.02*L+L*.12,0));
}

// ---------- fallback for factions not in the prototype yet ----------
function buildGeneric(b,cls){ return buildWedge(b,cls); }
function tube(b,mat,pts,rf,tess=8,flat=false,sy=1){ const m=MB.CreateTube('tb',{path:pts,radiusFunction:rf,tessellation:tess,cap:BABYLON.Mesh.CAP_ALL},G.scene); if(sy!==1) m.scaling.y=sy; if(flat) m.convertToFlatShadedMesh(); b.add(m,mat,pts[Math.floor(pts.length/2)].x>=b.split?'fore':'aft'); return m; }

// ---------- Ashfall Corsairs: asymmetric scrap-built raiders ----------
const JUNK={Frigate:{w:.14,t:.09,b:.07,eng:1},Destroyer:{w:.12,t:.085,b:.07,eng:2,torp:1},Cruiser:{w:.13,t:.085,b:.075,eng:2,torp:1,scat:1},Carrier:{w:.17,t:.1,b:.09,eng:3,bays:1,chunks:2},'Battle-barge':{w:.16,t:.09,b:.085,eng:4,torp:1,scat:1,bays:1,chunks:3}};
function buildJunk(b,cls){
  const p=JUNK[cls]||JUNK.Cruiser, L=b.L, M=b.M, W=p.w*L, T=p.t*L, Bt=p.b*L, r=seeded(cls.length*211+Math.round(L*7)+3);
  b.split=-.05*L;
  const sts=[-.5,-.4,-.2,0,.2,.35,.46].map((x,i)=>({x:x*L,w:W*(i===0?.7:i>4?.75-.2*(i-5):.85+r()*.3),t:T*(.8+r()*.35),b:Bt*(.8+r()*.3),y:(r()-.5)*.02*L}));
  b.loft(M.hull,sts,PROF.gothic);
  // bolted-on armour plates and scrap, deliberately lopsided
  for(let i=0;i<Math.round(6+L*.5);i++){ const x=(r()-.55)*.8*L, side=r()<.6?1:-1; const pl=b.box(r()<.35?M.dark:M.hull,x,(r()-.3)*T,side*(W*(.8+r()*.4)),.06*L+r()*.1*L,.03*L+r()*.05*L,.02*L+r()*.03*L); pl.rotation.set((r()-.5)*.4,(r()-.5)*.3,(r()-.5)*.5); }
  for(let i=0;i<(p.chunks||0);i++){ const cx=(r()-.5)*.5*L, cz=(i%2?1:-1)*W*(1.1+r()*.3); const sub=[-.12,-.05,.05,.12].map(x=>({x:cx+x*L,w:W*(.35+r()*.2),t:T*(.5+r()*.3),b:Bt*.5,y:(r()-.5)*T})); const h=b.push(loftVD(sub,PROF.gothic,false,{cut:.12,iters:2,sub:2}),M.hull,null,cx>=b.split?'fore':'aft'); h.position.z=cz; h.rotation.y=(r()-.5)*.35; b.slab(M.dark,cx,-T*.25,cz*.55,.06*L,T*.5,Math.abs(cz)*.6,Math.abs(cz)*.45,{rake:.2,ry:Math.PI/2*0}); }
  // toothed ram-scoop
  b.cylX(M.trim,.52*L,-Bt*.1,0,.14*L,W*1.4,W*.3,4,.7,1).rotation.x=Math.PI/4;
  for(let i=0;i<5;i++){ const z=(i-2)*W*.3; b.cylX(M.dark,.58*L,-Bt*.3+(i%2)*T*.3,z,.06*L,W*.18,0,4); }
  // superstructure: a crooked bridge stack and antenna
  const bx=-.28*L; b.slab(M.hull,bx,T-.002*L,W*.2,.12*L,.102*L,W*.9,W*.72,{rake:.2,rakeB:.06,ry:.06}); b.slab(M.dark,bx-.02*L,T+.098*L,W*.1,.08*L,.05*L,W*.62,W*.42,{rake:.3,rz:-.04}); b.box(M.win,bx+.06*L,T+.07*L,W*.2,.004*L,.02*L,W*.6);
  const ant=b.cylY(M.dark,bx-.04*L,T+.14*L,W*.1,.14*L,.002*L,.008*L,5); ant.rotation.z=.25; b.flashers.push(b.sph(M.tip,bx-.07*L,T+.28*L,W*.1,.014*L));
  // weapons
  if(p.scat){ for(const side of [1,-1]) for(const x of [-.12,.08]){ b.box(M.dark,x*L,T*.2,side*(W*1.02),.06*L,.04*L,.04*L); for(const dy of [-.01,0,.01]) b.box(M.dark,x*L,T*.2+dy*L,side*(W*1.02+.04*L),.006*L,.006*L,.05*L); (side>0?b.hard.P:b.hard.S).push(new V3(x*L,T*.2,side*(W*1.1+.04*L))); } }
  else { b.hard.P.push(new V3(0,T*.3,W*1.1)); b.hard.S.push(new V3(0,T*.3,-W*1.1)); }
  if(p.torp){ for(const z of [-.4,.4]){ b.cylX(M.dark,.44*L,T*.35,z*W,.08*L,W*.25,W*.25,8); b.hard.F.push(new V3(.49*L,T*.35,z*W)); } }
  b.hard.F.push(new V3(.52*L,0,0)); b.hard.T.push(new V3(bx,T+.16*L,0));
  if(cls==='Frigate'){ for(const z of [-.25,.25]) b.cylX(M.trim,.4*L,T*.4,z*W,.14*L,W*.12,W*.1,6); }
  if(p.bays){ for(const side of [1,-1]){ b.box(M.win,-.02*L,-Bt*.1,side*(W*1.03),.16*L,(T+Bt)*.35,.02); b.bays.push(new V3(-.02*L,-Bt*.1,side*W*1.2)); } }
  // mismatched engines
  for(let i=0;i<p.eng;i++){ const z=(i-(p.eng-1)/2)*W*.8+(r()-.5)*W*.2, d=T*(.9+r()*.8); b.engine(-.5*L-r()*.03*L,(r()-.4)*T*.6,z,d); }
  junkDetail(b,p,cls,W,T,Bt);
  return b.finish();
}

// ---------- The Chorus: living bio-ships ----------
const BIO={Frigate:{w:.16,t:.13,b:.12,tent:3},Destroyer:{w:.14,t:.11,b:.11,tent:4,maw:1},Cruiser:{w:.15,t:.12,b:.11,tent:4,spikes:1},Carrier:{w:.21,t:.17,b:.16,tent:6,sacs:1},'Bio-titan':{w:.18,t:.14,b:.14,tent:8,spikes:1,maw:1,sacs:1}};
function buildBio(b,cls){
  const p=BIO[cls]||BIO.Cruiser, L=b.L, M=b.M, W=p.w*L, T=p.t*L, Bt=p.b*L, r=seeded(cls.length*53+7);
  b.split=-.02*L;
  const sts=[]; for(let i=0;i<=14;i++){ const k=i/14, x=(-.5+k)*L; const bulge=.6+.4*Math.abs(Math.sin(k*Math.PI*2.4)); const env=Math.sin(Math.min(1,k*1.15)*Math.PI*.95+.12);
    sts.push({x,w:Math.max(.02*L,W*bulge*env),t:Math.max(.02*L,T*bulge*env),b:Math.max(.02*L,Bt*env*.9)}); }
  b.loft(M.hull,sts,PROF.round,false);
  // carapace plates and spines along the back
  for(let i=0;i<6;i++){ const x=(-.35+i*.13)*L; b.sph(M.dark,x,T*.72,0,.16*L,1,.35,Math.max(.8,W/(.16*L)*1.6)); if(p.spikes||i%2===0){ const sp=b.cylY(M.trim,x,T*.8,0,.1*L*(p.spikes?1.3:.8),0,.035*L,6); sp.rotation.z=.5; } }
  // glowing sacs on the flanks
  for(let i=0;i<(p.sacs?6:3);i++){ const x=(-.3+i*(p.sacs?.11:.2))*L; for(const side of [1,-1]) b.sph(M.win,x,-Bt*.1,side*W*.85,.07*L*(p.sacs?1.4:1),1,1,.6); }
  // maw
  if(p.maw){ b.torusX(M.trim,.5*L,0,0,W*.9,W*.18); b.sph(M.win,.49*L,0,0,W*.7,.4,1,1); }
  else b.sph(M.dark,.47*L,0,0,W*1.1,1.1,.8,.9);
  // trailing tendrils
  for(let i=0;i<p.tent;i++){ const a=(i/p.tent)*Math.PI*2, oy=Math.sin(a)*T*.5, oz=Math.cos(a)*W*.6; const pts=[]; for(let k=0;k<=12;k++){ const u=k/12; pts.push(new V3(-.42*L-u*L*(.45+r()*.2),oy*(1+u*.6)+Math.sin(u*5+i)*.03*L,oz*(1+u*.5)+Math.cos(u*4+i)*.04*L)); }
    tube(b,M.dark,pts,(k,d)=>Math.max(.004*L,.03*L*(1-k/12)),8); }
  b.hard.F.push(new V3(.52*L,0,0)); b.hard.P.push(new V3(0,0,W*1.05)); b.hard.S.push(new V3(0,0,-W*1.05)); b.hard.T.push(new V3(-.05*L,T*1.1,0));
  if(p.sacs) b.bays.push(new V3(0,-Bt,W*.9),new V3(0,-Bt,-W*.9));
  bioDetail(b,p,cls,W,T,Bt);
  return b.finish();
}

// ---------- The Ithar: elder sail-ships ----------
const SAIL={Frigate:{w:.07,t:.05,b:.045,sails:1},Destroyer:{w:.065,t:.05,b:.045,sails:2},Cruiser:{w:.08,t:.055,b:.05,sails:3,crest:1},Carrier:{w:.1,t:.06,b:.05,sails:2,wings:1},Ark:{w:.1,t:.07,b:.06,sails:4,ring:1,crest:1}};
function sailMesh(x0,x1,y0,h,sweep,z=0,tilt=0){
  const pos=[],idx=[],n=10; for(let i=0;i<=n;i++){ const k=i/n, x=x0+(x1-x0)*k, top=Math.sin(k*Math.PI*.95)*h; pos.push(x,y0,z, x-sweep*(1-k)*.6-sweep*.4,y0+top,z+Math.sin(tilt)*top); }
  for(let i=0;i<n;i++){ const a=i*2; idx.push(a,a+1,a+2,a+1,a+3,a+2); }
  const m=new BABYLON.Mesh('sail',G.scene); const vd=new BABYLON.VertexData(); vd.positions=pos; vd.indices=idx; const nr=[]; BABYLON.VertexData.ComputeNormals(pos,idx,nr); vd.normals=nr; vd.applyToMesh(m); return m; }
function buildSail(b,cls){
  const p=SAIL[cls]||SAIL.Cruiser, L=b.L, M=b.M, W=p.w*L, T=p.t*L, Bt=p.b*L;
  b.split=-.05*L;
  const sts=[[-.5,.5,.6,.6],[-.4,.9,.9,.9],[-.1,1,1,1],[.2,.8,.8,.8],[.4,.4,.5,.5],[.56,.02,.05,.05]].map(([x,w,t,bb])=>({x:x*L,w:w*W,t:t*T,b:bb*Bt}));
  b.loft(M.hull,sts,PROF.round,false);
  b.cylX(M.trim,.1*L,-Bt*.9,0,.7*L,.01*L,.004*L,6);
  const H=.35*L*(p.sails>2?1:.85);
  for(let i=0;i<p.sails;i++){ const off=(i-(p.sails-1)/2); const sm=sailMesh(-.3*L+off*.05*L,.25*L-Math.abs(off)*.08*L,T*.6,H*(1-Math.abs(off)*.18),.3*L,0,off*.35); b.add(sm,M.sail,'fore'); }
  b.cylY(M.trim,-.02*L,T*.5,0,H*.9,.002*L,.012*L,6);
  if(p.wings){ for(const side of [1,-1]){ const sm=sailMesh(-.3*L,.15*L,0,.3*L,.2*L,0,side*1.25); b.add(sm,M.sail,'aft'); } b.bays.push(new V3(-.1*L,0,W*1.4),new V3(-.1*L,0,-W*1.4)); }
  if(p.crest){ for(let i=0;i<3;i++) b.cylY(M.win,(-.25+i*.08)*L,T*.6,(i-1)*W*.5,.08*L*(1+(i===1)),0,.015*L,6); }
  if(p.ring){ b.torusX(M.trim,-.15*L,0,0,.45*L,.012*L); b.torusX(M.win,-.15*L,0,0,.42*L,.004*L); }
  b.engine(-.5*L,0,0,Math.min(W,T)*1.2);
  b.hard.F.push(new V3(.56*L,0,0)); b.hard.P.push(new V3(0,T*.3,W*1.1)); b.hard.S.push(new V3(0,T*.3,-W*1.1)); b.hard.T.push(new V3(0,T+H*.4,0));
  sailDetail(b,p,cls,W,T,Bt);
  return b.finish();
}

// ---------- The Deathless Dynasty: crescent tomb-ships ----------
const TOMB={Frigate:{R:.42,th:.1,arc:150},Destroyer:{R:.42,th:.1,arc:165,mono:1},Cruiser:{R:.42,th:.11,arc:185,mono:1,pyr:1},'Tomb-ark':{R:.42,th:.11,arc:215,mono:2,pyr:3,ring:1}};
function buildTomb(b,cls){
  const p=TOMB[cls]||TOMB.Cruiser, L=b.L, M=b.M, R=p.R*L, cx=-.02*L;
  b.split=cx;
  const arcPts=(rr,y=0,n=28)=>{ const pts=[]; for(let i=0;i<=n;i++){ const a=(-p.arc/2+p.arc*i/n)*Math.PI/180; pts.push(new V3(cx+Math.cos(a)*rr-R*.45,y,Math.sin(a)*rr)); } return pts; };
  const half=(side)=>arcPts(R).filter(v=>side*v.z>=-.001);
  for(const side of [1,-1]){ const pts=half(side); if(side<0) pts.reverse();
    tube(b,M.hull,pts,(k,d)=>{ const u=k/(pts.length-1); return p.th*L*(side>0?(1-u)*.8+.2:(u*.8+.2)); },6,true,.4); }
  for(const side of [1,-1]){ const pts=half(side).map(v=>new V3(v.x,.035*L,v.z)); tube(b,M.win,pts,()=>.006*L,4); }
  b.slab(M.dark,-.05*L,-.025*L,0,.5*L,.05*L,.08*L,.05*L,{rake:.2});
  for(let i=0;i<(p.mono||0);i++){ const x=(-.12-i*.18)*L; b.slab(M.dark,x,-.02*L,0,.075*L,.2*L,.075*L,.045*L,{rake:.08,cut:.06}); b.box(M.win,x+.036*L,.1*L,0,.002*L,.14*L,.012*L); }
  for(let i=0;i<(p.pyr||0);i++){ const x=(.05-i*.14)*L, z=(i%2?1:-1)*(i?.08*L:0); b.cylY(M.dark,x,.02*L,z,.12*L,0,.14*L,4,Math.PI/4); b.flashers.push(b.sph(M.win,x,.15*L,z,.016*L)); }
  if(p.ring){ b.torusX(M.dark,-.3*L,0,0,.3*L,.02*L); b.torusX(M.win,-.3*L,0,0,.3*L,.006*L); }
  const tipA=p.arc/2*Math.PI/180; const tip=s=>new V3(cx+Math.cos(tipA)*R-R*.45,.02*L,s*Math.sin(tipA)*R);
  b.hard.P.push(tip(1),new V3(cx+R*.2,.02*L,R*.8)); b.hard.S.push(tip(-1),new V3(cx+R*.2,.02*L,-R*.8)); b.hard.F.push(new V3(cx+R*.55,.03*L,0)); b.hard.T.push(new V3(-.1*L,.2*L,0));
  b.engine(-.3*L,0,0,.05*L);
  tombDetail(b,p,cls,R,cx);
  return b.finish();
}

// ---------- squadrons ----------
function buildCraft(fac,kind){
  const b=new SB(fac,CLS_LEN.Squadron), M=b.M, L=b.L;
  const st=(FACTIONS[fac]||{}).style;
  if(st==='junk'){ b.box(M.hull,0,0,0,L*.9,.25*L,.3*L); b.cylX(M.dark,-.3*L,0,0,.5*L,.3*L,.25*L,8); b.box(M.trim,0,0,0,.3*L,.04*L,.9*L); if(kind==='bomber') b.box(M.dark,.1*L,-.15*L,0,.5*L,.12*L,.2*L); }
  else if(st==='bio'){ b.sph(M.hull,0,0,0,.6*L,1.3,.9,.9); b.sph(M.win,.2*L,0,0,.25*L); for(let i=0;i<3;i++){ const a=i*2.1; b.cylX(M.dark,-.45*L,Math.sin(a)*.1*L,Math.cos(a)*.1*L,.5*L,.08*L,0,5); } }
  else if(st==='sail'){ b.cylX(M.hull,0,0,0,L,.16*L,0,6); const sm=sailMesh(-.35*L,.2*L,.05*L,.45*L,.25*L); b.add(sm,M.sail,'fore'); }
  else if(fac==='voidsworn'){ b.box(M.hull,0,0,0,L,.18*L,.2*L); b.box(M.trim,.1*L,0,0,.35*L,.04*L,.9*L,0,0,0); b.cylX(M.trim,.55*L,0,0,.25*L,.12*L,0,4);
    if(kind==='bomber'){ for(const z of [-.3,.3]) b.cylX(M.dark,.05*L,-.08*L,z*L,.6*L,.12*L,.1*L,8); }
    b.box(M.hull,-.35*L,.15*L,0,.2*L,.25*L,.04*L); }
  else { b.cylX(M.hull,0,0,0,L,.3*L,0,3,.4,1); for(const z of [-.28,.28]) b.box(M.dark,-.1*L,0,z*L,.5*L,.4*L,.03*L); b.box(M.trim,-.05*L,.05*L,0,.3*L,.03*L,.2*L);
    if(kind==='bomber') b.cylX(M.dark,0,-.12*L,0,.7*L,.18*L,.14*L,8); }
  b.cylX(M.eng,-.52*L,0,0,.06*L,.14*L,.14*L,8);
  return b.finish();
}
// squadron craft: built once per faction and kind, merged into one multi-material mesh, then drawn as instances
// (a wing is three craft; with wings in flight from the start, separate meshes cost ~50 draw calls per carrier)
const CRAFT_CACHE={};
function craftInstance(fac,kind){ const key=fac+'|'+kind; let p=CRAFT_CACHE[key];
  if(!p||p.isDisposed()){ const c=buildCraft(fac,kind); const all=c.root.getChildMeshes(false); const solid=all.filter(m=>m.getTotalVertices()>0&&!m.billboardMode);
    all.filter(m=>!solid.includes(m)).forEach(m=>m.dispose(false,false));
    p=BABYLON.Mesh.MergeMeshes(solid,true,true,undefined,false,true); c.root.dispose(false,false); if(!p) return null;
    p.name='craft_'+key; p.refreshBoundingInfo(true); p.isVisible=false; p.isPickable=false; p.position.y=-9000; CRAFT_CACHE[key]=p; }
  const inst=p.createInstance('craft'); inst.isPickable=true; inst.position.set(0,0,0); return {root:inst,meshes:[inst]}; }
// each ship class is built once, then cloned (clones share geometry)
const MODEL_CACHE={};
function buildShipModel(u){ if(u.isSq) return null; const fac=u.fac||'voidsworn', key=fac+'|'+u.cls;
  let p=MODEL_CACHE[key]; if(!p){ p=buildShipModelFresh(u); p.root.setEnabled(false); p.root.position.y=-9000; MODEL_CACHE[key]=p; }
  if(p.whole===undefined){ try{ p.whole=makeWholeProto(p.root); }catch(e){ console.warn('whole model failed',e); p.whole=null; } }
  const root=(p.whole||p.root).clone('ship',null); root.setEnabled(true); root.position.set(0,0,0);
  const kids=root.getChildren(), fore=kids.find(n=>n.name.endsWith('fore')), aft=kids.find(n=>n.name.endsWith('aft')), all=root.getChildMeshes(false), M=facMats(fac);
  const meshes=all.filter(m=>m.name.includes('hull_')), plumes=all.filter(m=>m.name.endsWith('plume')), flares=all.filter(m=>m.name.endsWith('flare'));
  for(const m of meshes){ m.isPickable=true; m.alwaysSelectAsActiveMesh=true; if(m.material===M.hull||m.material===M.dark) castShadows(m); else if(m.material===M.trim||m.material===M.steel) m.receiveShadows=true; if(m.material===M.dark||m.material===M.trim||m.material===M.steel||(G.quality==='medium'&&m.material===M.hull)) G.glow.addExcludedMesh(m); }
  for(const m of plumes.concat(flares)) m.isPickable=false; all.filter(m=>m.name.endsWith('emblem')).forEach(m=>G.glow.addExcludedMesh(m));
  for(const m of all) try{ m.refreshBoundingInfo(true); }catch(e){} // v41: every clone gets its own bounding data before its first transparent sort
  const model={root,fore,aft,meshes,plumes,flares,surf:p.surf,stacks:p.stacks,arcs:p.arcs,hard:p.hard,guns:p.guns,nav:p.nav,bays:p.bays,L:p.L,H:p.H,fac:p.fac};
  if(typeof addTurrets==='function') addTurrets(model,fore,fac);
  if(p.whole) model.toSplit=()=>splitModel(model,p.root);
  return model; }
// Live ships render from a merged copy (one mesh per material, about half the draw calls).
// The fore/aft split copy is only swapped in when the ship dies and breaks in two.
function makeWholeProto(proto){
  const wr=proto.clone('ship',null), fore=wr.getChildren().find(n=>n.name.endsWith('fore'));
  const byMat=new Map(); for(const m of wr.getChildMeshes(false)){ if(!m.name.includes('hull_')||m instanceof BABYLON.InstancedMesh) continue; /* v41: emblems are never merged; two tiny planes, and the merge was what broke transparent sorting */ if(!byMat.has(m.material)) byMat.set(m.material,[]); byMat.get(m.material).push(m); }
  for(const [mat,ms] of byMat){ if(ms.length<2) continue;
    const vds=ms.map(m=>{ const vd=BABYLON.VertexData.ExtractFromMesh(m,true,true); const loc=m.computeWorldMatrix(true).multiply(BABYLON.Matrix.Invert(wr.computeWorldMatrix(true))); vd.transform(loc); return vd; });
    const nm=new BABYLON.Mesh(ms[0].name.replace(/^.*?(hull_)/,'$1'),G.scene); vds[0].merge(vds.slice(1),true); vds[0].applyToMesh(nm); nm.refreshBoundingInfo(true); nm.material=mat; nm.parent=fore; nm.receiveShadows=ms[0].receiveShadows; nm.isPickable=ms[0].isPickable;
    ms.forEach(m=>m.dispose(false,false)); }
  // engine plumes: one mesh, scaled from the nozzle face; flares are billboards, so phones keep a single bigger one
  const aft=wr.getChildren().find(n=>n.name.endsWith('aft')), all=wr.getChildMeshes(false), pl=all.filter(m=>m.name.endsWith('plume')), fl=all.filter(m=>m.name.endsWith('flare'));
  if(aft&&pl.length>1){ const inv=BABYLON.Matrix.Invert(aft.computeWorldMatrix(true)); const vds=pl.map(m=>{ const vd=BABYLON.VertexData.ExtractFromMesh(m,true,true); vd.transform(m.computeWorldMatrix(true).multiply(inv)); return vd; });
    const nm=new BABYLON.Mesh('plume',G.scene); vds[0].merge(vds.slice(1),true); vds[0].applyToMesh(nm); nm.material=pl[0].material; nm.parent=aft; nm.isPickable=false; nm.refreshBoundingInfo(); nm.setPivotPoint(new V3(nm.getBoundingInfo().boundingBox.maximum.x,0,0)); pl.forEach(m=>m.dispose(false,false)); }
  if(G.mobile&&fl.length>1){ const k=fl[0], c=new V3(0,0,0); fl.forEach(f=>c.addInPlace(f.position)); k.position=c.scale(1/fl.length); k.bakeTransformIntoVertices(BABYLON.Matrix.Scaling(1.6,1.6,1.6)); fl.slice(1).forEach(f=>f.dispose(false,false)); }
  for(const m of wr.getChildMeshes(false)) try{ m.refreshBoundingInfo(true); }catch(e){} // clones copy each part's bounding data, so templates must have it
  wr.setEnabled(false); return wr; }
function splitModel(model,proto){
  const s=proto.clone('shipSplit',null); s.setEnabled(true); s.parent=model.root; s.position.set(0,0,0); s.rotation.set(0,0,0); s.scaling.setAll(1);
  const kids=s.getChildren(), fore=kids.find(n=>n.name.endsWith('fore')), aft=kids.find(n=>n.name.endsWith('aft'));
  for(const d of s.getDescendants(false)){ if(d===fore||d===aft||d.isDisposed()) continue; const keep=d.name.includes('hull_')||d.name.endsWith('emblem'); if(!keep&&(d.parent===fore||d.parent===aft)) d.dispose(false,false); }
  for(const m of model.meshes) m.dispose(false,false);
  model.meshes=s.getChildMeshes(false).filter(m=>m.name.includes('hull_')); model.fore=fore; model.aft=aft; model.toSplit=null; return model; }
function buildShipModelFresh(u){
  const fac=u.fac||'voidsworn';
  const style=(FACTIONS[fac]||{}).style, cls=u.cls, L=CLS_LEN[cls]||14;
  const b=new SB(fac,L); b.greebleN=(({gothic:18,wedge:10,junk:10,sail:3,bio:0,tomb:0})[style]*L||0)*(G.mobile?.6:.85); /* v44: fewer, better greebles: the hull carries the detail */
  if(style==='gothic') return buildGothic(b,cls);
  if(style==='wedge') return buildWedge(b,cls);
  if(style==='junk') return buildJunk(b,cls);
  if(style==='bio') return buildBio(b,cls);
  if(style==='sail') return buildSail(b,cls);
  if(style==='tomb') return buildTomb(b,cls);
  return buildGeneric(b,cls);
}
