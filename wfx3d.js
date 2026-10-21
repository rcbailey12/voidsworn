// ======================= v53-I EFFECTS: weapon identity, game feel, explosions =======================
// One table (WFX) says how every weapon family looks, sounds and lands; one set of tiers (JUICE) says how hard an event hits the camera, the clock and
// the screen. Everything draws through the pooled sprite managers in vfx3d (no mesh, material or particle system per shot), plus a few pooled meshes
// (lance beams, torpedo bodies, reactor fireballs). Rules code never awaits any of this beyond the existing animWeapon/animExplode promises.

// ---------- generated textures (once; cached by TexCache) ----------
function fxNoise2(seed){ const hs=(x,y)=>{ const v=Math.sin(x*127.1+y*311.7+seed*17.13)*43758.5453; return v-Math.floor(v); };
  const ns=(x,y)=>{ const xi=Math.floor(x),yi=Math.floor(y),xf=x-xi,yf=y-yi,u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf); return (hs(xi,yi)*(1-u)+hs(xi+1,yi)*u)*(1-v)+(hs(xi,yi+1)*(1-u)+hs(xi+1,yi+1)*u)*v; };
  const fb=(x,y,o)=>{ let a=.5,t=0,n=0; for(let i=0;i<(o||4);i++){ t+=a*ns(x,y); n+=a; x=x*2.03+1.7; y=y*2.03-.9; a*=.5; } return t/n; }; return {ns,fb}; }
// generators draw one cell or frame per step: fxPrep steps them in idle slices on the title screen, a battle that starts first finishes them at once
const FXJOBS={};
function fxJob(name,w,h,gen){ let J=FXJOBS[name]; if(J) return J; const c=document.createElement('canvas'); c.width=w; c.height=h; const g=c.getContext('2d'); const hit=typeof TexCache!=='undefined'?TexCache.get(name,w,h):null;
  J=FXJOBS[name]={c,done:false,step(){ return true; }}; if(hit&&hit!==true){ g.drawImage(hit,0,0,w,h); J.done=true; return J; }
  const it=gen(g,w,h); J.step=()=>{ if(J.done) return true; if(it.next().done){ J.done=true; try{ TexCache.save(name,c); }catch(e){} } return J.done; }; return J; }
function fxCanvas(name,w,h,gen){ const J=fxJob(name,w,h,gen); while(!J.done) J.step(); return J.c; }
function fxPrep(){ try{ if(typeof document==='undefined') return; const jobs=[fxAtlasCanvas(true),fxBookCanvas(true),fxChunkCanvas(true)];
    const tick=()=>{ const t0=performance.now(); for(const J of jobs) while(!J.done&&performance.now()-t0<10) J.step(); if(jobs.some(J=>!J.done)) setTimeout(tick,40); else setTimeout(()=>{ try{ fxAtlasURLs(); }catch(e){} },60); }; tick(); }catch(e){ console.warn('fx prep',e); } }
if(typeof window!=='undefined') window.addEventListener('load',()=>setTimeout(fxPrep,4500)); // after the texture cache has opened
// the misc additive atlas: 4x4 cells of 128 (cells 0-3 keep the v44 layout)
function fxAtlasCanvas(job){ return (job?fxJob:fxCanvas)('fxAtlasI1',512,512,function*(g){ const S=128, img=g.createImageData(512,512), d=img.data, N=fxNoise2(3), r=seeded(41);
  const arcY=[]; { let y=0; for(let i=0;i<=24;i++){ arcY.push(y); y=clamp(y+(r()-.5)*.34,-.32,.32); } }
  const spikes=[...Array(15)].map(()=>({a:r()*6.283,l:.45+r()*.5,w:.05+r()*.09,dr:r()<.6}));
  for(let cell=0;cell<16;cell++){ const ox=(cell%4)*S, oy=Math.floor(cell/4)*S;
    for(let y=0;y<S;y++) for(let x=0;x<S;x++){ const dx=(x+.5-S/2)/(S/2), dy=(y+.5-S/2)/(S/2), rr=Math.hypot(dx,dy), an=Math.atan2(dy,dx); let v=0, lum=1;
      switch(cell){
        case 0: v=Math.exp(-rr*rr*4.5)*clamp((1-rr)*5,0,1); break;
        case 1: v=(Math.exp(-rr*rr*16)*1.3+(Math.exp(-Math.abs(dy)*34)*Math.exp(-Math.abs(dx)*2.6)+Math.exp(-Math.abs(dx)*34)*Math.exp(-Math.abs(dy)*2.6))*.9+Math.exp(-rr*rr*3.2)*.22)*clamp((1-rr)*3,0,1); break;
        case 2: v=(Math.exp(-Math.pow((rr-.74)*10,2))*.95+Math.exp(-rr*rr*5)*.1)*clamp((1-rr)*6,0,1); break;
        case 3: v=Math.exp(-dy*dy*38)*Math.pow(Math.max(0,1-Math.abs(dx)),.7)*(dx>0?1:.75+.25*(1+dx)); break;
        case 4: v=(Math.exp(-dy*dy*90)*1.0+Math.exp(-dy*dy*9)*.32)*smoothstep01((1-Math.abs(dx))/.14); lum=.75+.25*Math.exp(-dy*dy*90); break; // a beam: even along its length, hard core, soft sheath
        case 5: { const n=N.fb(dx*2.6+11,dy*2.6+3,4), n2=N.fb(dx*6+2,dy*6-5,3); const edge=.78+(n-.5)*.42; v=smoothstep01((edge-rr)/.18); lum=.55+.45*clamp(1.15-rr*.9+(n2-.5)*.9,0,1); break; } // molten plasma core: lumpy edge, veined inside
        case 6: { const n=N.fb(Math.cos(an)*2.2+5,Math.sin(an)*2.2+rr*3.2,4); v=Math.exp(-Math.pow((rr-.48-(n-.5)*.3)*5.5,2))*(.35+1.1*n)+Math.exp(-rr*rr*3)*.18; v*=clamp((1-rr)*4,0,1); break; } // wispy corona
        case 7: { const ax=Math.abs(dx), ay=Math.abs(dy); v=clamp(1-ax*1.05-ay*7.5,0,1); v=Math.pow(v,.7)+Math.exp(-dy*dy*400)*Math.max(0,1-ax)*.6; lum=.7+.3*(dy>0?1:.6); break; } // glassy shard, two facets
        case 8: v=Math.exp(-rr*rr*48)*1.2+Math.exp(-rr*rr*7)*.35; break;
        case 9: { const u=(dx+1)/2*24, i=Math.min(23,Math.floor(u)), f=u-i, yy=arcY[i]*(1-f)+arcY[i+1]*f; v=(Math.exp(-Math.pow((dy-yy)*30,2))+Math.exp(-Math.pow((dy-yy)*7,2))*.3)*smoothstep01((1-Math.abs(dx))/.2); break; }
        case 10: { const u=(dx+1)/2, wd=.1+.42*Math.pow(u,.75), n=N.fb(u*5-3,dy*3+7,3); v=Math.exp(-Math.pow(dy/wd,2)*2.2)*Math.pow(Math.max(0,1-u),1.1)*smoothstep01(u*10)*(.45+.9*n); lum=.6+.4*(1-u); break; } // flame tongue, root at the left
        case 11: { const k=dx>0?dx*1.6:dx*.55; const q=Math.hypot(k,dy*1.5); v=smoothstep01((.62-q)/.12); lum=.7+.3*clamp(1-Math.hypot(dx-.3,dy+.15)*1.6,0,1); break; } // droplet, head toward +x
        case 12: v=Math.exp(-Math.pow((rr-.82)*34,2))*1.1+Math.exp(-Math.pow((rr-.78)*9,2))*.22; v*=clamp((1-rr)*12,0,1); break;
        case 13: { const p=[dx*6,dy*6], q=[p[0]+p[1]*.577,p[1]*1.155], f=[q[0]-Math.floor(q[0])-.5,q[1]-Math.floor(q[1])-.5], hx=smoothstep01((Math.max(Math.abs(f[0]),Math.abs(f[1]))-.38)/.1);
          const cid=Math.sin(Math.floor(q[0])*12.9+Math.floor(q[1])*78.2)*43758.5, fl=cid-Math.floor(cid); v=(hx*.8+(fl>.72?.55:0)+N.fb(dx*9,dy*9,2)*.25)*Math.pow(clamp(1-rr,0,1),.8); break; } // hex static
        case 14: { let s=Math.exp(-rr*rr*9)*1.1; for(const sp of spikes){ const da=Math.abs(((an-sp.a)%6.283+9.425)%6.283-3.1416); s+=Math.exp(-da*da/(sp.w*sp.w))*Math.max(0,1-rr/sp.l)*.9; if(sp.dr){ const tx=Math.cos(sp.a)*sp.l*1.1, ty=Math.sin(sp.a)*sp.l*1.1; s+=Math.exp(-(Math.pow(dx-tx,2)+Math.pow(dy-ty,2))*260)*.9; } } v=s*clamp((1-rr)*5,0,1); break; } // splash
        case 15: { const n=N.fb(dx*3+31,dy*3+7,4), c=N.fb(dx*9-4,dy*9+2,3); v=smoothstep01((.62+(n-.5)*.5-rr)/.2); lum=.35+.65*smoothstep01((c-.38)/.3); break; } // slag: lumpy blob, cracked crust
      }
      const o=((oy+y)*512+ox+x)*4, L=Math.round(255*clamp(lum,0,1)); d[o]=d[o+1]=d[o+2]=L; d[o+3]=Math.round(clamp(v,0,1)*255); } yield; }
  g.putImageData(img,0,0); }); }
function smoothstep01(x){ x=clamp(x,0,1); return x*x*(3-2*x); }
// the explosion flipbook, as a Blender render would deliver it: R = flame emission, G = smoke density, frames left to right, top to bottom
function fxBookCanvas(job){ const C=G.mobile?64:128, cols=4, rows=4, W=C*cols;
  return (job?fxJob:fxCanvas)('fxBookRG4_'+C,W,W,function*(g){ const img=g.createImageData(W,W), d=img.data, N=fxNoise2(9), bil=(x,y,o)=>{ let a=.5,t=0,n=0; for(let i=0;i<o;i++){ t+=a*(1-Math.abs(2*N.ns(x,y)-1)); n+=a; x=x*2.1+3.1; y=y*2.1-1.7; a*=.5; } return t/n; };
    for(let f=0;f<16;f++){ const t=f/15, ox=(f%cols)*C, oy=Math.floor(f/cols)*C, r0=.42+.4*Math.pow(t,.5), r1=.36+.5*Math.pow(t,.6);
      for(let y=0;y<C;y++) for(let x=0;x<C;x++){ const dx=(x+.5-C/2)/(C/2), dy=(y+.5-C/2)/(C/2), rr=Math.hypot(dx,dy);
        const n=bil(dx*2.2+t*.9,dy*2.2-t*1.4,4), n2=N.fb(dx*4.5-t*2,dy*4.5+t*1.5,2), n3=bil(dx*1.6+7-t*.5,dy*1.6+2+t*.4,3);
        // flame: a billowing ball that cools from the edge inward and breaks into tongues as it ages
        const m=smoothstep01((r0+(n-.55)*.5-rr)/.22), heat=clamp(1.35-t*1.05-rr/r0*.75+(n2-.5)*.7,0,1), holes=smoothstep01((n2+.25-t*.75)/.3);
        const flame=m*Math.pow(heat,.85)*(.5+.5*n)*holes;
        // smoke: soft billows, dense and small early, wide and thin late
        const sm=smoothstep01(((r1-rr)/r1+(n3-.5)*.7)/.55)*(.45+.55*n3)*(1-t*.5);
        const ed=smoothstep01((1-Math.max(Math.abs(dx),Math.abs(dy)))/.14), o=((oy+y)*W+ox+x)*4; d[o]=Math.round(clamp(flame*1.15*ed,0,1)*255); d[o+1]=Math.round(clamp(sm*ed,0,1)*255); d[o+2]=0; d[o+3]=255; } yield; }
    g.putImageData(img,0,0); }); }
// split an R/G flipbook into the two sprite atlases: fire (white, alpha = R) and smoke (shaded from the G gradient, alpha = G)
function fxBookSplit(src,cols,rows){ const W=src.width, H=src.height, sg=src.getContext('2d'), s=sg.getImageData(0,0,W,H).data;
  const mk=()=>{ const c=document.createElement('canvas'); c.width=W; c.height=H; return c; }, fc=mk(), scv=mk(), fi=fc.getContext('2d').createImageData(W,H), si=scv.getContext('2d').createImageData(W,H), fd=fi.data, sd=si.data;
  const k=Math.max(3,Math.round(W/100)), Gat=(x,y)=>s[((clamp(y,0,H-1)*W+clamp(x,0,W-1))*4)+1]/255; for(let y=0;y<H;y++) for(let x=0;x<W;x++){ const o=(y*W+x)*4, R=s[o]/255, Gc=s[o+1]/255, gx=(Gat(x+k,y)-Gat(x-k,y)+.5*(Gat(x+k,y+k)-Gat(x-k,y+k)+Gat(x+k,y-k)-Gat(x-k,y-k)))/2, gy=(Gat(x,y+k)-Gat(x,y-k)+.5*(Gat(x+k,y+k)-Gat(x+k,y-k)+Gat(x-k,y+k)-Gat(x-k,y-k)))/2;
    const fl=Math.pow(R,.5); fd[o]=fd[o+1]=fd[o+2]=Math.round(255*fl); fd[o+3]=Math.round(255*R);
    const lit=clamp((.8+(-gx-gy)*.65)*(1-.2*Gc),.4,1); sd[o]=sd[o+1]=sd[o+2]=Math.round(255*lit); sd[o+3]=Math.round(255*Gc); }
  fc.getContext('2d').putImageData(fi,0,0); scv.getContext('2d').putImageData(si,0,0); return {fire:fc.toDataURL(),smoke:scv.toDataURL(),cell:W/cols,nF:cols*rows}; }
function fxChunkCanvas(job){ return (job?fxJob:fxCanvas)('fxChunkI1',256,64,function*(g){ const img=g.createImageData(256,64), d=img.data, r=seeded(5);
  for(let c=0;c<4;c++){ const pts=[...Array(7)].map((_,i)=>{ const a=i/7*6.283+r()*.6; return [Math.cos(a)*(.45+r()*.5),Math.sin(a)*(.3+r()*.55)]; });
    for(let y=0;y<64;y++) for(let x=0;x<64;x++){ const dx=(x+.5-32)/32, dy=(y+.5-32)/32; let ins=true; for(let i=0;i<pts.length;i++){ const a=pts[i], b=pts[(i+1)%pts.length]; if((b[0]-a[0])*(dy-a[1])-(b[1]-a[1])*(dx-a[0])<0){ ins=false; break; } }
      const o=(y*256+c*64+x)*4, lit=.45+.55*clamp(.5-dx*.4-dy*.5,0,1); d[o]=d[o+1]=d[o+2]=Math.round(255*lit); d[o+3]=ins?255:0; } yield; }
  g.putImageData(img,0,0); }); }
const FXBOOK={src:null,cols:4,rows:4}; // a rendered flipbook (fxBookLoad) replaces the procedural one
let FXURL=null; // the atlases as data URLs, built once per page (not per scene) and ahead of time by fxPrep
function fxAtlasURLs(){ if(FXURL&&FXURL.src===FXBOOK.src) return FXURL; const t0=performance.now(); const add=fxAtlasCanvas().toDataURL(), bk=fxBookSplit(FXBOOK.src||fxBookCanvas(),FXBOOK.cols,FXBOOK.rows), chunk=fxChunkCanvas().toDataURL();
  FXURL={src:FXBOOK.src,add,fire:bk.fire,smoke:bk.smoke,chunk,cell:bk.cell,nF:bk.nF,ms:Math.round(performance.now()-t0)}; return FXURL; }
function fxAtlases(){ if(G._fxA&&G._fxA.scene===G.scene) return G._fxA; const t0=performance.now(), U=fxAtlasURLs();
  G._fxA=Object.assign({scene:G.scene},U); G.fxAtlasMs=Math.round(performance.now()-t0); return G._fxA; }
// drop-in for the Blender explosion sims: an image whose R channel is flame and G channel smoke, cols x rows frames
function fxBookLoad(url,cols,rows){ return new Promise((res,rej)=>{ const im=new Image(); im.crossOrigin='anonymous'; im.onload=()=>{ try{ const c=document.createElement('canvas'); c.width=im.width; c.height=im.height; c.getContext('2d').drawImage(im,0,0);
      FXBOOK.src=c; FXBOOK.cols=cols||8; FXBOOK.rows=rows||8; G._fxA=null; FXURL=null; const P=G.fxPool; if(P&&P.mgr){ const bk=fxBookSplit(c,FXBOOK.cols,FXBOOK.rows);
        for(const [Q,u] of [[P.fire,bk.fire],[P.sm,bk.smoke]]) if(Q&&Q.mgr){ const old=Q.mgr.texture; Q.mgr.texture=new BABYLON.Texture(u,G.scene,true,false,BABYLON.Texture.TRILINEAR_SAMPLINGMODE); Q.mgr.cellWidth=bk.cell; Q.mgr.cellHeight=bk.cell; try{ old&&old.dispose(); }catch(e){} }
        P.nF=bk.nF; } res(true); }catch(e){ rej(e); } }; im.onerror=rej; im.src=url; }); }

// ---------- game feel: tiers, trauma shake, hit-stop, screen flash ----------
// Every impact, detonation and death goes through juice(tier): the tier decides the camera trauma, the hit-stop and the flash, so the game stays proportional.
const JUICE={
  s:{trauma:.06,stop:0,flash:0,pulse:0},          // routine hits: a broadside bolt, a tracer ping
  m:{trauma:.2,stop:.045,flash:.06,pulse:.12},    // a plasma splash, a rail punch-through, a crit, a frigate death
  l:{trauma:.48,stop:.09,flash:.16,pulse:.35},    // lance burn-through, torpedo detonation, destroyer death
  xl:{trauma:.8,stop:.13,flash:.3,pulse:.9}};     // capital reactor, ram, nova
G.trauma=0; G.shakeT=0;
function addTrauma(x){ if(!(x>0)) return; G.trauma=Math.min(1,(G.trauma||0)+x); }
function juice(tier,pos,o){ const T=JUICE[tier]||JUICE.s; o=o||{}; let att=1;
  try{ if(pos&&G.cam){ const d=V3.Distance(pos,G.cam.target), R=Math.max(60,G.cam.radius); att=clamp(1.35-d/(R*1.1),.25,1); } }catch(e){}
  addTrauma(T.trauma*att*(o.k||1));
  if(T.stop&&!o.noStop) hitStop(T.stop*(o.k||1));
  if(T.flash&&!G.fxReduced) screenFlash(T.flash*att,o.col);
  if(T.pulse&&!G.fxReduced) G.pulse=Math.min(1.2,(G.pulse||0)+T.pulse*att);
  if(o.sfx) try{ o.sfx(); }catch(e){} }
// trauma -> camera: trauma^2 drives a smooth offset (summed sines, never per-frame random), decays in real time; the camera's own state never keeps it
function shakeOffset(dt,c){ if(G.shake>0){ addTrauma(G.shake); G.shake=0; } /* older code still writes G.shake */ const tr=G.trauma||0; if(tr<=0) return null;
  G.trauma=Math.max(0,tr-dt*1.25); const k=G.shakeRed?.18:1, s=tr*tr*k; if(s<1e-4) return null; G.shakeT=(G.shakeT||0)+dt; const t=G.shakeT*22;
  const nx=.6*Math.sin(t*1.13+.3)+.4*Math.sin(t*2.71+1.9), ny=.6*Math.sin(t*1.37+2.2)+.4*Math.sin(t*2.29+.7), na=.6*Math.sin(t*.91+4.1)+.4*Math.sin(t*1.93+.2), nb=.6*Math.sin(t*1.07+1.4)+.4*Math.sin(t*2.53+3.3);
  const R=Math.max(40,c.radius), off=R*.011*s, m=c.getViewMatrix(), rx=new V3(m.m[0],m.m[4],m.m[8]), uy=new V3(m.m[1],m.m[5],m.m[9]);
  return {o:rx.scale(nx*off).addInPlace(uy.scale(ny*off)),a:na*.009*s*(G.shakeRed?0:1),b:nb*.006*s*(G.shakeRed?0:1)}; }
// hit-stop: game time (effects, bolts, wrecks) slows to a crawl for a few frames; input, the camera and the rules' timers keep running
function hitStop(d){ if(!(d>0)||typeof performance==='undefined') return; const now=performance.now(), H=G.hitStop;
  if(H&&now<H.end+250) return; /* one stop per beat: they never chain into a stall */ d=Math.min(.14,d)*1000; G.hitStop={t0:now,end:now+d,scale:.06}; }
function timeScaleNow(){ const H=G.hitStop; if(!H) return 1; const now=performance.now(); if(now>=H.end){ if(now>H.end+300) G.hitStop=null; return 1; }
  const k=(now-H.t0)/(H.end-H.t0); return k<.7?H.scale:H.scale+(1-H.scale)*((k-.7)/.3); }
function screenFlash(a,col){ try{ if(typeof document==='undefined'||G.fxReduced) return; let el=G._flashEl; if(!el||!el.isConnected){ el=G._flashEl=document.createElement('div'); el.id='fxflash'; el.style.cssText='position:fixed;inset:0;pointer-events:none;z-index:4;opacity:0;mix-blend-mode:screen;will-change:opacity'; document.body.appendChild(el); }
    const c=col||new C3(1,.9,.75); el.style.background=`radial-gradient(ellipse at center,rgba(${255*Math.min(1,c.r)|0},${255*Math.min(1,c.g)|0},${255*Math.min(1,c.b)|0},1) 0%,rgba(${255*Math.min(1,c.r)|0},${200*Math.min(1,c.g)|0},${150*Math.min(1,c.b)|0},.55) 55%,rgba(0,0,0,0) 100%)`;
    el.style.transition='none'; el.style.opacity=String(Math.min(.45,a)); void el.offsetWidth; el.style.transition='opacity '+(0.12+a*.6).toFixed(2)+'s ease-out'; el.style.opacity='0'; }catch(e){} }

// ---------- sprite helpers ----------
// effects read at battle zoom: sprite sizes follow the camera distance (like the ships' tactical scale), velocities by the square root
function fxScaleTick(){ const r=G.cam?G.cam.radius:200; G.fxK=clamp(.9+r/160,1.3,2.4)*(G.mobile?1.35:G.quality==='medium'?1.15:1); } // a 412-wide phone gets bigger effects
function wfp(p,o){ const k=G.fxK||1; if(k!==1){ if(o.size) o.size*=k; if(o.vel) o.vel=o.vel.scale(Math.sqrt(k)); } return fxp(p,o); }
function fxQ(){ return G.mobile?.45:G.quality==='medium'?.6:G.quality==='ultra'?1.15:1; } // particle budget; Medium keeps every layer, just fewer of each
function nq(n,cap){ return Math.max(1,Math.min(cap||999,Math.round(n*fxQ()*(G.fxReduced?.7:1)))); }
function rdir(){ const v=new V3(Math.random()-.5,Math.random()-.5,Math.random()-.5); return v.lengthSquared()<1e-6?new V3(0,1,0):v.normalize(); }
function coneDir(d,spread){ return d.add(rdir().scale(spread)).normalize(); }
function hotOf(col,k){ return C3.Lerp(col,WHITE3,k==null?.55:k); }
function rr(a,b){ return a+Math.random()*(b-a); }
function viewMats(){ const f=G.scene.getFrameId(); if(G._vmF!==f||!G._vm){ G._vmF=f; G._vm=G.cam.getViewMatrix(); G._ivm=G._vm.clone(); G._ivm.invert(); } }
// stretch a pooled sprite so it spans a..b on screen exactly (both ends projected), thick world units across
function alignSprite(e,a,b,thick){ viewMats(); const A=V3.TransformCoordinates(a,G._vm), Bv=V3.TransformCoordinates(b,G._vm); if(A.z<.5&&Bv.z<.5){ e.sp.width=0; return false; }
  const za=Math.max(.5,A.z), zb=Math.max(.5,Bv.z), sax=A.x/za, say=A.y/za, sbx=Bv.x/zb, sby=Bv.y/zb, zm=(za+zb)/2, len=Math.max(thick*.5,Math.hypot(sbx-sax,sby-say)*zm);
  V3.TransformCoordinatesToRef(new V3((sax+sbx)/2*zm,(say+sby)/2*zm,zm),G._ivm,e.sp.position); e.sp.angle=Math.atan2(sby-say,sbx-sax); e.s0=thick/.45; e.w=len/thick; e.h=1; e.sp.width=len; e.sp.height=thick; return true; }
// a thin ring around axis d at p, drawn as a sprite squashed to the ellipse it projects to
function ringAround(p,d,R,col,o){ o=o||{}; const vd=p.subtract(G.cam.position).normalize(), ratio=Math.max(o.minRatio||.14,Math.abs(V3.Dot(d,vd))); return wfp(p,{cell:12,size:R,col,dur:o.dur||.35,grow:o.grow==null?1.2:o.grow,ang:screenAng(p,d),w:ratio,h:1,fade:o.fade||1.4}); }
function lineSprite(a,b,thick,col,o){ o=o||{}; thick*=G.fxK||1; const e=fxp(a,{cell:o.cell==null?4:o.cell,size:thick/.45,col,dur:o.dur||.12,grow:0,fade:o.fade==null?1.5:o.fade,alpha:o.alpha==null?1:o.alpha,c2:o.c2||null}); if(e){ alignSprite(e,a,b,thick); e.grow=0; } return e; }
function sparkSpray(p,dir,n,sp,col,spread,o){ o=o||{}; for(let i=0;i<n;i++){ const d=dir?coneDir(dir,spread==null?.8:spread):rdir(), v=d.scale(rr(sp[0],sp[1]));
    wfp(p,{cell:3,size:rr(.9,1.8)*(o.k||1),col:C3.Lerp(col,new C3(1,.5,.15),Math.random()*.6).scale(1.7),dur:rr(.25,.6)*(o.life||1),grow:0,vel:v,drag:o.drag==null?2:o.drag,grav:o.grav==null?3:o.grav,ang:screenAng(p,v),w:1,h:.2,fade:1.1}); } }
function embers(p,n,col,o){ o=o||{}; for(let i=0;i<n;i++){ const v=rdir().scale(rr(o.v0||2,o.v1||7)); v.y+=o.up||0;
    wfp(p,{cell:8,size:rr(.5,1.1)*(o.k||1),col:(col||new C3(1,.62,.25)).scale(1.8),c2:o.c2||new C3(.45,.05,0),dur:rr(o.l0||1,o.l1||2.2),grow:0,vel:v,drag:.7,grav:o.grav==null?1.2:o.grav,fade:.8}); } }
function smokePuff(p,n,size,o){ o=o||{}; const base=o.col||new C3(.2,.17,.15); for(let i=0;i<n;i++){ const d=rdir(), v=d.scale(rr(.3,1)*(o.v||size*.4)); v.y+=o.up==null?.5:o.up;
    wfp(p.add(d.scale(size*rr(0,.35))),{pool:'smoke',size:size*rr(.8,1.3),col:base.scale(rr(.8,1.2)),alpha:o.alpha||.6,dur:rr(o.l0||2,o.l1||3.4),grow:o.grow||1.7,vel:v,drag:.45,spin:rr(-.6,.6),fade:1.1}); } }
function flames(p,n,size,tint,o){ o=o||{}; for(let i=0;i<n;i++){ const d=rdir(); d.y*=.7; const v=d.scale(size*rr(.2,.7)*(o.v||1)/Math.max(.3,o.life||.8));
    wfp(p.add(d.scale(size*rr(0,o.spread==null?.35:o.spread))),{pool:'fire',size:size*rr(.85,1.35),col:tint.scale(rr(1.3,1.8)),dur:(o.life||.8)*rr(.7,1.15),grow:o.grow||1.4,vel:v,drag:1.3,spin:rr(-1.2,1.2),fade:o.fade==null?.7:o.fade,anim:o.anim||null}); } }
function chunks(p,dir,n,sp,o){ o=o||{}; for(let i=0;i<n;i++){ const d=dir?coneDir(dir,o.spread==null?.7:o.spread):rdir(), v=d.scale(rr(sp[0],sp[1]));
    wfp(p,{pool:'chunk',cell:Math.floor(Math.random()*4),anim:null,size:rr(.5,1.3)*(o.k||1),col:o.col||new C3(.24,.21,.2),alpha:1,dur:rr(1.2,2.4),grow:0,vel:v,drag:.35,grav:o.grav==null?1.5:o.grav,spin:rr(-9,9),fade:.6});
    if(o.hot&&Math.random()<o.hot) wfp(p,{cell:8,size:rr(.7,1.2),col:new C3(1,.55,.2).scale(1.8),c2:new C3(.4,.04,0),dur:rr(.6,1.2),grow:0,vel:v.scale(.95),drag:.35,grav:o.grav==null?1.5:o.grav,fade:.8}); } }
function toLocal(v,p){ try{ v.root.computeWorldMatrix(true); return V3.TransformCoordinates(p,BABYLON.Matrix.Invert(v.root.getWorldMatrix())); }catch(e){ return null; } }
// something glowing left on the plating: rides the hull as it drifts, cools from c to c2
function hullGlow(v,p,size,col,c2,dur,cell){ if(!v||!v.root||v.state!=='alive') return null; const lp=toLocal(v,p); if(!lp) return null; return wfp(p,{cell:cell==null?15:cell,size,col,c2,dur,grow:.15,fade:.7,stick:{v,p:lp}}); }

// ---------- explosions: layered flipbook fire, flame tongues, sparks, embers, lingering smoke, shock ring, debris ----------
function blast(pos,size,o){ o=o||{}; const s=Math.max(.3,size), tint=o.tint||new C3(1,.46,.14), hot=o.hot||new C3(1,.85,.6);
  try{ wfp(pos,{cell:0,size:s*2.8,col:hot.scale(2),dur:.11,grow:.9,fade:2.5});
    if(s>=.8) wfp(pos,{cell:1,size:s*3.2,col:hot.scale(1.5),dur:.15,grow:.6});
    flames(pos,nq(2+s*.6,10),s*1.15,hot,{life:.42+s*.03,spread:.2,grow:1.2});
    flames(pos,nq(3+s*.9,16),s*1.6,tint,{life:.75+s*.05,spread:.45,grow:1.6,v:1.2,fade:.85});
    if(s>=.9){ const nL=nq(3+s*.35,9); for(let i=0;i<nL;i++){ const d=rdir(); wfp(pos.add(d.scale(s*.35)),{cell:10,size:s*.95,col:new C3(1,.62,.26).scale(1.7),dur:rr(.2,.34),grow:1.1,vel:d.scale(s*1.6),drag:2,ang:screenAng(pos,d),w:2.6,h:1,fade:1.2}); } }
    if(o.sparks!==false) sparkSpray(pos,null,nq(8+s*5,60),[4+s*1.5,10+s*3],new C3(1,.82,.5),1,{grav:2.5});
    embers(pos,nq(3+s*2,30),null,{v0:s*1.2,v1:s*3.5+2,l0:1,l1:2.4});
    if(o.smoke!==false) smokePuff(pos,nq(2+s*.7,14),s*1.9,{l0:2.2+s*.08,l1:3.8+s*.12,v:s*.5});
    if(o.debris||s>=2.2) chunks(pos,null,nq(3+s*.8,18),[5+s,12+s*1.6],{k:Math.sqrt(s)*.8,hot:.35});
    if(o.ring){ wfp(pos,{cell:0,size:s*4,col:hot.scale(1.4),dur:.22,grow:1.2,fade:2}); if(typeof shockRing==='function'&&s>=2.2) shockRing(pos,s*3,(o.ringCol||new C3(1,.72,.45)).scale(.8),{flat:true,dur:.9+s*.03,thick:.04}); else wfp(pos,{cell:12,size:s*2,col:new C3(1,.8,.55).scale(1.3),dur:.28,grow:3,fade:1.5}); } /* one flat ring on the board plane and a spherical flash */
    if(o.light!==false&&typeof lightFlash==='function') lightFlash(pos,new C3(1,.62,.3),3+s*.6,s*9,.6);
  }catch(e){ console.warn('blast',e); } }

// ---------- sprite projectiles: every bolt is a few pooled sprites (core, corona, tail) plus a trail it sheds ----------
const WB=[];
function wbFly(from,to,o){ const dir=to.subtract(from), dist=Math.max(.01,dir.length()); dir.normalize();
  const side=V3.Cross(dir,V3.Up()); if(side.lengthSquared()<1e-4) side.set(1,0,0); side.normalize();
  const rec={from:from.clone(),dir,side,dist:dist+(o.overshoot||0),arriveAt:dist,go:0,speed:o.speed||150,o,arrived:false,ph:Math.random()*6.28,pos:from.clone(),prev:from.clone(),L:(o.layers||[]).map(l=>({l,e:null,g:-1})),t0:G.time,acc:0};
  WB.push(rec); wbPose(rec); wbDraw(rec,0); return rec; }
function wbPose(rec){ const o=rec.o, k=clamp(rec.go/Math.max(.01,rec.arriveAt),0,1.5), p=rec.from.add(rec.dir.scale(rec.go)); const env=Math.sin(Math.min(1,k)*Math.PI);
  if(o.arc) p.y+=env*o.arc; if(o.curve) p.addInPlace(rec.side.scale(env*o.curve)); if(o.wob){ const w=env*o.wob; p.addInPlace(rec.side.scale(Math.sin(k*19+rec.ph)*w)); p.y+=Math.cos(k*15+rec.ph)*w; }
  rec.prev.copyFrom(rec.pos); rec.pos.copyFrom(p); }
function wbDraw(rec,dt){ const p=rec.pos; let d=p.subtract(rec.prev); if(d.lengthSquared()<1e-6) d=rec.dir.clone(); else d.normalize(); const t=G.time;
  for(const s of rec.L){ const l=s.l; if(!s.e||s.e.gen!==s.g){ s.e=fxp(p,{pool:l.pool||'add',cell:l.cell||0,size:(l.size||l.thick||1)/.45,col:l.col,alpha:l.alpha==null?1:l.alpha,dur:5,grow:0,fade:.01,anim:l.anim||null}); if(!s.e) continue; s.e.hold=true; s.g=s.e.gen; }
    const e=s.e, K=G.fxK||1, back=(l.back||0)*K, wob=l.wob?1+l.wob*Math.sin(t*(l.wf||18)+rec.ph+(l.wp||0)):1;
    if(l.len){ const head=p.subtract(d.scale(back)); alignSprite(e,head.subtract(d.scale(l.len*wob*K)),head,K*(l.thick||.4)*(l.wob?1+l.wob*.5*Math.sin(t*(l.wf||18)*1.3+rec.ph):1)); }
    else { e.sp.position.copyFrom(back?p.subtract(d.scale(back)):p); const sz=(l.size||1)*wob*K; e.s0=sz/.45; e.sp.width=e.sp.height=sz; if(l.spin) e.sp.angle+=l.spin*dt; }
    if(l.flick&&!G.fxReduced) e.alpha=(l.alpha==null?1:l.alpha)*(.55+.45*Math.abs(Math.sin(t*l.flick+rec.ph*7))); }
  if(rec.o.trail) try{ rec.o.trail(rec,p,d,dt); }catch(e){} }
function wbRelease(rec){ for(const s of rec.L){ const e=s.e; if(e&&e.gen===s.g){ e.hold=false; e.t0=G.time; e.dur=.07; e.fade=1.5; } } rec.L.length=0; }
function wbTick(dt){ for(let i=WB.length-1;i>=0;i--){ const r=WB[i]; r.go+=r.speed*dt/Math.max(.2,SPEED); wbPose(r); wbDraw(r,dt);
    if(!r.arrived&&r.go>=r.arriveAt){ r.arrived=true; if(r.o.onArrive) try{ r.o.onArrive(r); }catch(e){ frameError(e); } }
    if(r.go>=r.dist){ wbRelease(r); WB.splice(i,1); if(r.o.settle) try{ r.o.settle(); }catch(e){} } } }
function wbClear(){ for(const r of WB){ wbRelease(r); try{ if(!r.arrived&&r.o.settle) r.o.settle(); }catch(e){} } WB.length=0; }
function onceFn(f){ let d=false; return ()=>{ if(d) return; d=true; try{ f&&f(); }catch(e){ frameError(e); } }; }

// ---------- weapon families: look, timing and impact ----------
// fire(c,from,to,hit,lead,done): muzzle + flight; calls done() once, at the moment of impact (lead shots carry the dice; volley barrels are visual only)
// impact(c,p,from,lead): what the hull shows; tier: how hard a lead hit lands (JUICE); gap: ms between lead shots; vol: share of extra broadside barrels
const PRISM=[new C3(1,.55,.62),new C3(1,.86,.5),new C3(.68,1,.6),new C3(.5,.95,1),new C3(.66,.7,1),new C3(.95,.6,1)];
const BILE=new C3(.32,.38,.08), BRASS=new C3(1,.83,.48);
function wMuzzle(p,d,col,k,o){ o=o||{}; wfp(p,{cell:1,size:(o.star||2.8)*k,col:hotOf(col,.6).scale(2),dur:o.sd||.07,grow:.35}); wfp(p.add(d.scale(.4)),{cell:0,size:(o.glow||3.4)*k,col:col.scale(1.5),dur:o.gd||.12,grow:.45});
  if(o.tongue) wfp(p.add(d.scale(o.tongue*k*.45)),{cell:10,size:1.6*k,col:C3.Lerp(col,new C3(1,.85,.6),.4).scale(1.7),dur:.1,grow:.5,ang:screenAng(p,d),w:o.tongue/1.6,h:1,fade:1.4}); }
function boltTo(from,to,h,lead,done,o){ return wbFly(from,to,Object.assign({overshoot:h?0:30,onArrive:lead?done:(h?done:null),settle:done},o)); }
const WFX={
  las:{tier:'s',gap:60,vol:1,decal:.3,
    fire(c,from,to,h,lead,done){ const d=to.subtract(from).normalize(), k=lead?1:.7, hot=hotOf(c.col,.8);
      wfp(from,{cell:1,size:6*k,col:new C3(1,.98,.92).scale(2.6),dur:.07,grow:.25}); wfp(from,{cell:0,size:5*k,col:c.col.scale(1.6),dur:.12,grow:.4}); // hard muzzle flash
      lineSprite(from,to,.95*k,new C3(1,.98,.94).scale(3),{dur:.11,fade:1.2}); lineSprite(from,to,2.8*k,c.col.scale(1.8),{dur:.16,fade:1.5}); // white-hot core inside a coloured halo
      if(lead) lineSprite(from,to,6.5,c.col.scale(.5),{dur:.2,fade:2,alpha:.6});
      setTimeout(done,16); },
    impact(c,p,from,lead){ const back=from.subtract(p).normalize(), n=lead?1:.6; wfp(p,{cell:1,size:7*n,col:new C3(1,.97,.9).scale(2.4),dur:.09,grow:.35}); wfp(p,{cell:0,size:6*n,col:hotOf(c.col,.3).scale(1.8),dur:.14,grow:.4});
      wfp(p,{cell:0,size:5*n+1,col:new C3(1,.55,.22).scale(1.7),dur:.5,grow:.5,fade:1.1});
      const tg=V3.Cross(back,V3.Up()); if(tg.lengthSquared()<.01) tg.set(1,0,0); tg.normalize(); const L=(lead?3.6:2)*rr(.7,1.2), ax=tg.add(new V3(0,rr(-.5,.5),0)).normalize();
      lineSprite(p.subtract(ax.scale(L*.5)),p.add(ax.scale(L*.5)),.6,new C3(1,.72,.36).scale(2),{dur:lead?.9:.5,fade:.9,c2:new C3(.55,.07,.02)});
      sparkSpray(p,back,nq(lead?14:6),[12,30],new C3(1,.88,.6),.9,{k:1.3});
      if(lead&&Math.random()<.5) smokePuff(p.add(back.scale(.6)),1,1.3,{l0:1.2,l1:2}); },
    hitSfx(p){ SFX.play('hit_las',{pos:p}); }},
  plasma:{tier:'m',gap:150,vol:.55,decal:.5,
    // a tight electric-blue bolt with a white-hot core line, small blue-violet crackle and sparse cyan embers; additive overlap kept low so it stays blue
    fire(c,from,to,h,lead,done){ const d=to.subtract(from).normalize(), k=lead?1:.8, EB=new C3(.18,.48,1), VI=new C3(.5,.45,1), CY=new C3(.45,.9,1), WH=new C3(.85,.93,1);
      wfp(from,{cell:1,size:4.5*k,col:WH.scale(1.8),dur:.07,grow:.3}); wfp(from,{cell:0,size:4.5*k,col:EB.scale(.9),dur:.2,grow:.6}); wfp(from,{cell:12,size:1.6*k,col:EB.scale(1.2),dur:.2,grow:2.5,fade:1.5});
      for(let i=0;i<nq(3);i++){ const v=coneDir(d,.8).scale(rr(5,11)); wfp(from,{cell:8,size:rr(.5,.8),col:CY.scale(1.6),dur:rr(.2,.4),grow:0,vel:v,drag:1.2}); }
      boltTo(from,to,h,lead,done,{speed:105*rr(.95,1.05),heat:lead?4:2.5,layers:[{cell:0,size:4.2*k,col:EB.scale(.55)},{cell:3,len:9*k,thick:1.5*k,col:EB.scale(1.05),back:.2,wob:.1,wf:23},{cell:4,len:6.5*k,thick:.45*k,col:WH.scale(1.9),back:.4},{cell:8,size:1.7*k,col:WH.scale(1.8),wob:.15,wf:47}],
        trail(r,p,dd,dt){ r.acc+=dt; const st=(G.mobile?.09:.05)*(lead?1:2.2); while(r.acc>=st){ r.acc-=st; r.ti=(r.ti||0)+1;
          if(r.ti%2===0) wfp(p.subtract(dd.scale(rr(1,3))),{cell:8,size:rr(.4,.7),col:CY.scale(1.5),dur:rr(.25,.45),grow:0,vel:dd.scale(-rr(1,3)).add(rdir().scale(rr(1.5,4))),drag:1.4,fade:.9}); // sparse cyan embers
          if(lead&&r.ti%3===1){ const a=p.subtract(dd.scale(rr(.5,2.5))), q=a.add(rdir().scale(rr(1.2,2.4)*(G.fxK||1))); arcLine(a,q,VI.scale(1.4),{n:3,jag:.5,thick:.12,dur:.07}); } } }}); }, // blue-violet crackle
    impact(c,p,from,lead){ const back=from.subtract(p).normalize(), col=c.col, k=lead?1:.6, OR=new C3(1,.55,.16), WH=new C3(1,.95,.8);
      wfp(p,{cell:1,size:9*k,col:WH.scale(2.6),dur:.12,grow:.5}); wfp(p,{cell:0,size:13*k,col:OR.scale(2),dur:.42,grow:.7,fade:1.2}); wfp(p,{cell:6,size:9*k,col:col.scale(1.5),dur:.34,grow:1.6,spin:4,fade:1.5}); wfp(p,{cell:12,size:3*k,col:col.scale(1.3),dur:.3,grow:3,fade:1.5});
      for(let i=0;i<nq(lead?16:6);i++){ const v=coneDir(back.add(rdir().scale(.6)).normalize(),.9).scale(rr(6,16)); wfp(p,{cell:5,size:rr(.8,1.6)*k+.3,col:new C3(1,.75,.35).scale(2),c2:new C3(.6,.08,.02),dur:rr(.5,1),grow:0,vel:v,drag:.8,grav:9,spin:rr(-6,6),fade:.7}); }
      for(let i=0;i<nq(lead?6:2);i++) wfp(p.add(rdir().scale(.8)),{cell:11,size:rr(1.1,1.6),col:new C3(1,.7,.3).scale(2),c2:new C3(.5,.06,0),dur:rr(1.1,1.8),grow:0,vel:new V3(rr(-.8,.8),-rr(.5,1.5),rr(-.8,.8)),grav:4,ang:-Math.PI/2,w:1.5,h:1,fade:.6});
      const sl=lead?2:(Math.random()<.4?1:0); for(let i=0;i<sl;i++) hullGlow(c.vt,p.add(rdir().scale(.8)),rr(3.2,4.6)*k*(G.fxK||1),new C3(1,.62,.22).scale(2.2),new C3(.35,.04,0),rr(3,4.2),15);
      if(lead||!G.mobile) smokePuff(p.add(back.scale(.8)),nq(lead?3:1),2,{col:new C3(.18,.16,.15),up:1.3,l0:1.8,l1:3});
      if(lead&&typeof lightFlash==='function') lightFlash(p,new C3(1,.6,.3),3.2,34,.5); },
    hitSfx(p){ SFX.play('hit_plasma',{pos:p}); }},
  tracer:{tier:'s',gap:40,vol:1.2,decal:.2,
    fire(c,from,to,h,lead,done){ const d=to.subtract(from).normalize(), n=lead?5:2;
      for(let i=0;i<n;i++) setTimeout(()=>{ try{ const jt=i?new V3(rr(-1.3,1.3),rr(-.7,.7),rr(-1.3,1.3)):V3.Zero(), tgt=to.add(jt), first=i===0;
        wfp(from,{cell:1,size:rr(3,4),col:BRASS.scale(2.4),dur:.05,grow:.3}); wfp(from,{cell:0,size:2.6,col:new C3(1,.6,.25).scale(1.4),dur:.08,grow:.3});
        wbFly(from,tgt,{speed:rr(240,280),overshoot:first&&h?0:22,layers:[{cell:3,len:7.5,thick:1.5,col:BRASS.scale(2.8),flick:70},{cell:4,len:5,thick:.6,col:new C3(1,.97,.85).scale(2.6)},{cell:8,size:2,col:new C3(1,.95,.8).scale(2.6)},{cell:0,size:3.6,col:new C3(1,.62,.25).scale(1.2),flick:55}],
          onArrive:first?done:(h&&Math.random()<.7?()=>WFX.tracer.ping(c,tgt,from):null),settle:first?done:null}); }catch(e){ if(i===0) done(); } },i*28*Math.max(.4,SPEED)); },
    ping(c,p,from){ const back=from.subtract(p).normalize(); wfp(p,{cell:1,size:rr(2.8,3.8),col:new C3(1,.92,.7).scale(2.2),dur:.07,grow:.3}); wfp(p,{cell:0,size:2.6,col:new C3(1,.6,.25).scale(1.5),dur:.18,grow:.4}); sparkSpray(p,back,nq(4),[8,18],BRASS,1,{k:1.2});
      if(Math.random()<.35) wfp(p,{pool:'smoke',size:rr(.8,1.3),col:new C3(.42,.4,.38),alpha:.5,dur:rr(.6,1),grow:1.4,vel:back.scale(1.2),drag:.8}); },
    impact(c,p,from,lead){ this.ping(c,p,from); if(lead) for(let i=1;i<3;i++) setTimeout(()=>{ try{ this.ping(c,p.add(rdir().scale(rr(.6,1.6))),from); }catch(e){} },i*30); },
    hitSfx(p){ SFX.play('patter_hull',{pos:p,gain:2}); SFX.hit(p); }},
  shell:{tier:'s',gap:70,vol:.9,decal:.35,
    fire(c,from,to,h,lead,done){ const d=to.subtract(from).normalize(); wMuzzle(from,d,c.col,lead?1.2:.9,{tongue:4.5});
      boltTo(from,to,h,lead,done,{speed:150,layers:[{cell:3,len:3.4,thick:.75,col:c.col.scale(1.6)},{cell:0,size:2.2,col:c.col.scale(.8)}]}); },
    impact(c,p,from,lead){ blast(p,lead?1.25:.7,{light:lead&&Math.random()<.4,smoke:lead,sparks:true}); },
    hitSfx(p){ SFX.hit(p); }},
  rail:{tier:'m',gap:170,vol:.4,decal:.4,
    // a slug at a fifth of light: the shot is a white-hot head crossing the gap in a few frames, the green ionised wake it leaves fades after it
    fire(c,from,to,h,lead,done){ const d=to.subtract(from).normalize(), col=c.col, k=lead?1:.7, WH=new C3(.92,1,.95);
      wfp(from,{cell:12,size:2.4*k,col:WH.scale(2),dur:.32,grow:5,fade:1.3}); wfp(from,{cell:2,size:3*k,col:col.scale(1.4),dur:.4,grow:3.5,fade:1.8}); wfp(from,{cell:1,size:8*k,col:WH.scale(2.6),dur:.08,grow:.35});
      sparkSpray(from,d,nq(lead?8:3),[20,40],WH,.35,{grav:0,k:1.2});
      const len=V3.Distance(from,to), RC=c.va.fac==='deathless'?FAC3D.deathless.bolt:(c.P.bolt||col), nr=lead?6:3;
      for(let i=0;i<nr;i++) setTimeout(()=>{ try{ const q=from.add(d.scale(Math.min(len*.3,16)*(i+.35)/nr)); ringAround(q,d,(5.2+i*.5)*k,RC.scale(2.4),{dur:.42,grow:1.1,minRatio:.5,fade:1.2}); }catch(e){} },i*16);
      ringAround(from.add(d.scale(1)),d,7*k,RC.scale(2),{dur:.5,grow:1.6,minRatio:.55}); // stylised magnetic accelerator rings, facing the camera enough to read as rings // stylised magnetic accelerator rings (rule of cool)
      wbFly(from,to,{speed:1500,overshoot:h?0:40,layers:[{cell:3,len:Math.min(len*.6,30)*k,thick:1.5*k,col:WH.scale(3)},{cell:8,size:4*k,col:WH.scale(3.5)},{cell:1,size:6*k,col:WH.scale(2.2)},{cell:0,size:5*k,col:col.scale(1.5)}],
        onArrive:()=>{ try{ lineSprite(from,to,.5*k,WH.scale(2),{dur:.12,fade:1.6}); lineSprite(from,to,2.4*k,col.scale(.6),{dur:.8,fade:.9,alpha:.6});
          if(lead&&!G.mobile){ const n=Math.min(18,Math.floor(len/3.5)), side=V3.Cross(d,V3.Up()).normalize(), up=V3.Cross(side,d); for(let i=1;i<n;i++){ const a=i*.95, q=from.add(d.scale(len*i/n)).add(side.scale(Math.cos(a)*.9)).add(up.scale(Math.sin(a)*.9)); wfp(q,{cell:0,size:2,col:col.scale(.9),dur:rr(.5,.8),grow:.7,fade:1.2}); } } }catch(e){} done(); },settle:done}); },
    impact(c,p,from,lead){ const d=p.subtract(from).normalize(), back=d.scale(-1), col=c.col, hot=hotOf(col,.7);
      wfp(p,{cell:1,size:lead?9:5,col:new C3(1,1,.95).scale(2.6),dur:.09,grow:.4}); wfp(p,{cell:0,size:lead?7:4,col:col.scale(1.5),dur:.25,grow:.6});
      sparkSpray(p,back,nq(lead?10:4),[14,30],new C3(.9,1,.9),.6,{grav:1});
      if(lead&&!c.shielded){ const vt=c.vt, L=(vt&&vt.L)||10; setTimeout(()=>{ try{ if(!vt.root||vt.root.isDisposed()) return; const ex=p.add(d.scale(L*.42)); // punch-through: the slug exits the far side and drags the hull out with it
        wfp(ex,{cell:1,size:7,col:hot.scale(2.2),dur:.1,grow:.4}); wfp(ex,{cell:0,size:6,col:new C3(1,.6,.25).scale(1.8),dur:.3,grow:.6}); chunks(ex,d,nq(14,18),[16,36],{hot:.6,spread:.4,k:1.5}); sparkSpray(ex,d,nq(26),[22,48],new C3(.9,1,.9),.4,{grav:1,k:1.6});
        flames(ex,nq(2),1.4,new C3(1,.5,.18),{life:.5,spread:.2}); smokePuff(ex,nq(2),1.4,{v:2,l0:1.4,l1:2.4}); SFX.play('hit_rail',{pos:ex,gain:.7}); }catch(e){} },80*Math.max(.4,SPEED)); } },
    hitSfx(p){ SFX.play('hit_rail',{pos:p}); }},
  needle:{tier:'s',gap:55,vol:1,decal:.2,
    fire(c,from,to,h,lead,done){ const d=to.subtract(from).normalize(), hot=hotOf(c.col,.7); wfp(from,{cell:1,size:2.4,col:hot.scale(1.8),dur:.07,grow:.3}); wfp(from,{cell:1,size:1.4,col:PRISM[Math.floor(Math.random()*6)].scale(1.8),dur:.1,grow:.3,ang:Math.PI/4});
      boltTo(from,to,h,lead,done,{speed:300,layers:[{cell:7,len:4.4,thick:.6,col:hot.scale(1.9)},{cell:3,len:9,thick:.34,col:c.col.scale(1.1),back:1}],
        trail(r,p,dd,dt){ r.acc+=dt; const st=(G.mobile?.07:.04)*(lead?1:2); while(r.acc>=st){ r.acc-=st; r.gi=(r.gi||0)+1; wfp(p.subtract(dd.scale(rr(0,3))),{cell:1,size:rr(.9,1.6),col:PRISM[r.gi%6].scale(1.8),dur:rr(.08,.16),grow:.2,ang:rr(0,.8)}); } }}); },
    impact(c,p,from,lead){ const k=lead?1:.6; wfp(p,{cell:1,size:3*k,col:new C3(1,1,1).scale(2),dur:.07,grow:.4}); wfp(p,{cell:12,size:1.4*k,col:hotOf(c.col,.6).scale(1.4),dur:.2,grow:2.4,fade:1.5});
      for(let i=0;i<nq(lead?8:3);i++){ const v=rdir().scale(rr(6,14)); wfp(p,{cell:7,size:rr(.8,1.6),col:PRISM[i%6].scale(1.5),dur:rr(.35,.7),grow:0,vel:v,drag:1.2,spin:rr(-14,14),w:1.6,h:.7,fade:1}); }
      for(let i=0;i<nq(lead?6:2);i++) wfp(p.add(rdir().scale(rr(0,1.6))),{cell:1,size:rr(1,1.9),col:PRISM[(i+3)%6].scale(1.8),dur:rr(.1,.25),grow:.3}); },
    hitSfx(p){ SFX.play('hit_glass',{pos:p}); }},
  spine:{tier:'s',gap:70,vol:.9,decal:.3,k:1,
    fire(c,from,to,h,lead,done){ const d=to.subtract(from).normalize(), col=c.col, k=this.k*(lead?1:.8);
      wfp(from,{cell:0,size:3*k,col:col.scale(1.1),dur:.15,grow:.5}); for(let i=0;i<nq(5);i++) wfp(from,{pool:'smoke',size:rr(.5,.8)*k,col:BILE,alpha:.9,dur:rr(.35,.55),grow:.3,vel:coneDir(d,.5).scale(rr(4,10)),grav:8,drag:.5,fade:1});
      boltTo(from,to,h,lead,done,{speed:this.speed*rr(.92,1.08),arc:this.arc,wob:.25,layers:[{cell:11,len:2.4*k,thick:1.05*k,col:col.scale(1.25)},{cell:0,size:2.6*k,col:col.scale(.45)}],
        trail(r,p,dd,dt){ r.acc+=dt; const st=(G.mobile?.09:.05)*(lead?1:2); while(r.acc>=st){ r.acc-=st; wfp(p,{pool:'smoke',size:rr(.4,.7)*k,col:BILE,alpha:.85,dur:rr(.4,.6),grow:.2,vel:dd.scale(-2),grav:7,fade:1}); } }}); },
    impact(c,p,from,lead){ const back=from.subtract(p).normalize(), k=this.k*(lead?1:.6);
      wfp(p,{cell:14,size:4.6*k,col:new C3(.85,.95,.3).scale(1.3),dur:.26,grow:.7,fade:1.4}); wfp(p,{cell:0,size:4*k,col:c.col.scale(.9),dur:.25,grow:.5});
      for(let i=0;i<nq(lead?12:4);i++) wfp(p,{pool:'smoke',size:rr(.6,1)*k,col:BILE.scale(rr(.8,1.2)),alpha:.9,dur:rr(.5,.9),grow:.3,vel:coneDir(back,1).scale(rr(5,12)),grav:9,drag:.4,fade:1});
      if(lead) smokePuff(p,nq(3),1.4*k,{col:new C3(.5,.58,.2),alpha:.45,up:1.5,l0:1.4,l1:2.2});
      if(lead||Math.random()<.3) hullGlow(c.vt,p,1.6*k,new C3(.7,.95,.25).scale(1.6),new C3(.12,.2,0),2.2,15); },
    hitSfx(p){ SFX.play('hit_wet',{pos:p}); }},
  flak:{tier:'s',gap:45,vol:.5,decal:0,
    fire(c,from,to,h,lead,done){ const d=to.subtract(from).normalize(); wfp(from,{cell:1,size:1.6,col:new C3(1,.85,.6).scale(1.6),dur:.06,grow:.3});
      wbFly(from,to,{speed:190,overshoot:0,layers:[{cell:3,len:1.6,thick:.32,col:new C3(1,.85,.6).scale(1.8)}],onArrive:()=>{ WFX.flak.puff(to); done(); },settle:done}); },
    puff(p){ wfp(p,{cell:1,size:2.2,col:new C3(1,.92,.75).scale(1.6),dur:.08,grow:.3}); wfp(p,{cell:0,size:3,col:new C3(1,.7,.35).scale(1.3),dur:.2,grow:.8}); wfp(p,{cell:12,size:1.3,col:new C3(1,.85,.6),dur:.22,grow:2.4,fade:1.6});
      wfp(p,{pool:'smoke',size:rr(1.6,2.2),col:new C3(.48,.47,.45),alpha:.55,dur:rr(.9,1.4),grow:1.3,vel:rdir().scale(.5),drag:.6}); sparkSpray(p,null,nq(4),[5,10],new C3(1,.8,.5),1); },
    impact(c,p,from,lead){ sparkSpray(p,from.subtract(p).normalize(),nq(3),[6,12],new C3(1,.8,.5),1); },
    hitSfx(p){ SFX.play('patter_hull',{pos:p,gain:1.6}); }},
  sq:{tier:'s',gap:55,vol:0,decal:.1,
    fire(c,from,to,h,lead,done){ boltTo(from,to,h,lead,done,{speed:120,layers:[{cell:3,len:1.8,thick:.32,col:c.col.scale(1.9)},{cell:0,size:1.2,col:c.col.scale(.7)}]}); },
    impact(c,p,from,lead){ WFX.tracer.ping(c,p,from); },
    hitSfx(p){ SFX.hit(p); }},
  lance:{tier:'l',decal:1,lance:true}, ion:{tier:'m',decal:.4,lance:true}, torp:{tier:'l',decal:1,torp:true}};
WFX.glob=Object.assign({},WFX.spine,{k:1.6}); WFX.spine.speed=105; WFX.spine.arc=1.6; WFX.glob.speed=72; WFX.glob.arc=3.2; WFX.glob.tier='m';
WFX.lance.impact=WFX.ion.impact=function(c,p,from,lead){ lanceImpact(c,p,from,lead); }; WFX.lance.hitSfx=p=>SFX.hit(p,true); WFX.ion.hitSfx=p=>{ SFX.play('hit_ion',{pos:p}); };
WFX.torp.impact=function(c,p,from,lead){ const tint=c.va.fac==='chorus'?new C3(.75,.9,.25):c.va.fac==='ithar'?new C3(.65,1,.85):null; blast(p,lead?4.6:2.4,{ring:true,debris:true,tint:tint||undefined,hot:tint?hotOf(tint,.5):undefined}); hullGlow(c.vt,p,3.2,new C3(1,.6,.25).scale(1.8),new C3(.3,.03,0),3.5,15); };
WFX.torp.hitSfx=p=>SFX.boom(.8,p);

function wFamily(u,w,fac){ if(u.isSq) return 'sq'; if(w.k==='flak') return 'flak'; if(w.k==='torp') return 'torp'; if(w.k==='lance') return w.ion?'ion':'lance'; if(w.k==='gauss') return 'rail';
  if(w.k==='bio') return w.id==='bioplasma'?'spine':'glob'; return ({las:'las',plasma:'plasma',scrap:'tracer',needle:'needle',spines:'spine'})[w.trait]||({voidsworn:'las',hegemony:'plasma',corsair:'tracer',chorus:'spine',ithar:'needle',deathless:'rail'})[fac]||'shell'; }
function wCtx(u,w,t,va,vt,fam){ const P=FAC3D[va.fac]||FAC3D.hegemony, quad=shieldQuad(t,u), shielded=(t.sh[quad]||0)>.5&&(w.pierce||0)<1;
  let col=fam==='ion'?new C3(.45,.75,1):fam==='lance'?P.beam:fam==='rail'?FAC3D.deathless.bolt:(fam==='spine'||fam==='glob')?FAC3D.chorus.bolt:P.bolt; if(u.isSq) col=P.bolt;
  return {u,w,t,va,vt,fam,P,col,shielded,quad,sc:shCol(vt),tp:vt.root.getAbsolutePosition()}; }
// a lead hit lands: the hull is pushed, the family's impact plays, and the tier sets shake, hit-stop, flash and the impact sound together
function landLead(c,p,from){ const vt=c.vt, F=WFX[c.fam]||WFX.shell; if(!vt||!vt.root||vt.root.isDisposed()) return;
  const d=c.tp.subtract(from), f=c.fam, mag=f==='torp'?(c.shielded?5:11):(f==='lance'||f==='ion')?(c.shielded?3:7):f==='rail'?3.2:f==='plasma'?2.8:c.shielded?.9:2.2; physKick(c.t,d,mag,(Math.random()-.5)*mag*.06);
  if(c.shielded){ shieldHitFx(c,p,from,F); return; }
  F.impact(c,p,from,true); if(Math.random()<(F.decal==null?.35:F.decal)) hullDecal(vt,from,f==='torp'||f==='lance');
  if((f==='torp'||f==='lance')&&!vt.jolt){ const dd=d.clone(); dd.y=0; dd.normalize(); vt.jolt={d:dd.scale(f==='torp'?1.6:.9),t0:G.time}; }
  juice(F.tier,p,{sfx:()=>F.hitSfx?F.hitSfx(p):SFX.hit(p)}); }
function shieldHitFx(c,p,from,F){ const sc=c.sc, vt=c.vt, ion=c.fam==='ion', big=F.tier!=='s', back=from.subtract(p).normalize();
  shieldDome(vt,from.subtract(c.tp).normalize(),sc,ion?{stat:1,dur:1.6}:big?{dur:.95}:null);
  wfp(p,{cell:2,size:big?6.5:3.4,col:sc.scale(1.2),dur:.3,grow:1.6,fade:2,alpha:.8}); wfp(p,{cell:0,size:big?6:3.5,col:sc.scale(1.2),dur:.25,grow:.6}); wfp(p,{cell:1,size:big?5:2.8,col:hotOf(sc,.5).scale(1.6),dur:.1});
  sparkSpray(p,back,nq(big?10:5),[6,16],sc,1.1,{grav:0});
  if(ion) for(let i=0;i<nq(7);i++) wfp(p.add(rdir().scale(rr(.5,3.5))),{cell:13,size:rr(2.5,4.8),col:new C3(.42,.72,1).scale(1.5),dur:rr(.6,1.3),grow:.4,fade:1.1});
  if(c.fam==='plasma') for(let i=0;i<nq(6);i++) wfp(p,{cell:5,size:rr(.5,.9),col:hotOf(c.col,.6).scale(1.7),c2:c.col.scale(.3),dur:rr(.3,.6),grow:0,vel:coneDir(back,.9).scale(rr(5,11)),drag:.8,grav:6});
  if(c.fam==='torp') blast(p.add(back.scale(1.5)),3,{ring:true,light:true});
  juice(F.tier==='l'?'m':'s',p,{sfx:()=>SFX.shield(p)});
  if((c.w.pierce||0)>0){ try{ F.impact(c,hitPoint(vt,from,false),from,false); }catch(e){} } }

// ---------- lances: charge-up, a thick crackling beam, a melt where it lands ----------
// a jagged electric arc a..b drawn as a few screen-aligned segments (pooled; replaces a tube mesh and material per arc)
function arcLine(a,b,col,o){ o=o||{}; const n=o.n||6, jag=o.jag==null?V3.Distance(a,b)*.12+.3:o.jag, pts=[a];
  for(let i=1;i<n;i++){ const p=V3.Lerp(a,b,i/n); p.addInPlace(rdir().scale(jag*rr(.4,1))); pts.push(p); } pts.push(b);
  for(let i=0;i<pts.length-1;i++) lineSprite(pts[i],pts[i+1],o.thick||.22,col,{dur:o.dur||.1,fade:1.2,cell:4}); }
function chargeUp(pos,col,dur){ if(G.fxReduced) dur*=.7; const n=nq(26,40), D=dur*.9;
  for(let i=0;i<n;i++){ const d=rdir(), r=rr(3.5,6.5); wfp(pos.add(d.scale(r)),{cell:8,size:rr(.4,.8),col:C3.Lerp(col,WHITE3,Math.random()*.6).scale(1.8),dur:D*rr(.7,1),grow:0,vel:d.scale(-r/Math.max(.05,D)),fade:.5}); }
  wfp(pos,{cell:0,size:1.2,col:col.scale(1.6),dur:dur+.05,grow:6,fade:.4}); wfp(pos,{cell:6,size:2.4,col:col.scale(1.1),dur:dur,grow:2.5,spin:8,fade:.6});
  if(!G.mobile) for(let i=0;i<3;i++) setTimeout(()=>{ try{ arcLine(pos.add(rdir().scale(2.5)),pos,hotOf(col,.5).scale(1.8),{n:4,thick:.16,dur:.08}); }catch(e){} },dur*1000*(i+1)/4); }
function chargeFx(pos,col,dur=.28){ try{ chargeUp(pos,col,dur); }catch(e){} }
function lanceBeam(from,to,col,width,dur,o){ o=o||{}; const len=V3.Distance(from,to); if(len<.1) return;
  const e=fxShPool('beam',()=>{ const m=MB.CreateCylinder('beam',{height:1,diameter:1,tessellation:14,cap:BABYLON.Mesh.NO_CAP},G.scene); m.bakeTransformIntoVertices(BABYLON.Matrix.RotationX(Math.PI/2)); m.isPickable=false; m.alwaysSelectAsActiveMesh=true;
    const mat=beamMaterial(col); m.material=mat; try{ G.glow.addExcludedMesh(m); }catch(err){} return {mesh:m,mat}; });
  const m=e.mesh, mat=e.mat; m.position=from.add(to).scale(.5); m.scaling.set(width*1.15,width*1.15,len); m.lookAt(to); mat.setColor3('col',col.scale(1.15)); mat.setFloat('len',len); mat.setFloat('fade',1);
  lineSprite(from,to,width*3.4,col.scale(.42),{dur,fade:1.6,alpha:.6}); wfp(from,{cell:1,size:width*5,col:hotOf(col,.6).scale(1.8),dur:Math.min(.35,dur),grow:.4}); wfp(to,{cell:1,size:width*4.4,col:hotOf(col,.6).scale(1.8),dur:dur*.9,grow:.3});
  const t0=G.time, D=dur*Math.max(.3,SPEED), hot=hotOf(col,.55).scale(1.9); let nextArc=0;
  const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/D; if(k>=1||m.isDisposed()){ G.scene.onBeforeRenderObservable.remove(obs); e.release(); return; }
    mat.setFloat('t',G.time%100); mat.setFloat('fade',Math.pow(1-k,1.4)); mat.setVector3('camPos',G.cam.position); const s=width*1.15*(1-k*.55+Math.sin(G.time*80)*.06); m.scaling.x=m.scaling.y=s;
    if(G.time>=nextArc&&k<.85){ nextArc=G.time+(G.mobile?.1:o.ion?.03:.05); for(let q=0;q<(o.ion?2:1);q++){ const a=rr(.05,.85), b=Math.min(1,a+rr(.06,.18)); arcLine(V3.Lerp(from,to,a),V3.Lerp(from,to,b),hot,{n:5,jag:width*(o.dark?1.6:o.ion?1.8:1.1),thick:o.dark||o.ion?.3:.2,dur:.08}); } } }); }
function beam(from,to,col,width,dur){ lanceBeam(from,to,col,width,dur); }
function lanceImpact(c,p,from,lead){ const ion=c.fam==='ion', col=c.col, hot=hotOf(col,.6), back=from.subtract(p).normalize(), k=lead?1:.6;
  wfp(p,{cell:1,size:9*k,col:hot.scale(1.9),dur:.18,grow:.5}); wfp(p,{cell:0,size:10*k,col:(ion?col:new C3(1,.72,.4)).scale(1.5),dur:.55,grow:.6,fade:1.2});
  sparkSpray(p,back,nq(lead?30:10),[12,32],ion?new C3(.7,.9,1):new C3(1,.9,.7),1,{k:1.2});
  if(ion){ for(let i=0;i<nq(6);i++) setTimeout(()=>{ try{ const sk=typeof skinPoint==='function'?skinPoint(c.vt,null):null, q=sk?toWorld(c.vt,sk.p):p.add(rdir().scale(rr(2,5))); arcLine(p.add(rdir().scale(.5)),V3.Lerp(p,q,.6),new C3(.6,.85,1.8),{n:5,thick:.2,dur:.1}); }catch(e){} },i*90);
    hullGlow(c.vt,p,2.4*k,new C3(.5,.8,1.6),new C3(.05,.1,.3),1.4,13); }
  else { hullGlow(c.vt,p,3.4*k,new C3(1,.86,.6).scale(2),new C3(.4,.05,0),3.6,15); hullGlow(c.vt,p,5*k,new C3(1,.45,.15).scale(1.2),new C3(.15,.02,0),2.6,0);
    flames(p.add(back.scale(.6)),nq(2),1.6*k,new C3(1,.5,.18),{life:.6,spread:.3}); smokePuff(p.add(back.scale(.8)),nq(3),1.8,{up:2,l0:2.2,l1:3.4}); }
  if(lead&&typeof lightFlash==='function') lightFlash(p,ion?col:new C3(1,.7,.4),3.2,40,.55); }
async function lanceRun(c,shots,mz){ const ion=c.fam==='ion', col=c.col, dark=c.va.fac==='deathless', cT=ion?.38:.32;
  for(let i=0;i<shots.length;i++){ const from=mz[i%mz.length], h=shots[i], to=h?hitPoint(c.vt,from,c.shielded):missPoint(c.vt,from);
    try{ SFX.play('charge',{pos:from,gain:.45,rate:ion?1.25:1.05}); }catch(e){} chargeUp(from,col,cT); await wait(cT*900);
    if(typeof lightFlash==='function') lightFlash(from,col,2.2,40,.5); wfp(from,{cell:12,size:2,col:hotOf(col,.5).scale(1.5),dur:.25,grow:3.5,fade:1.4});
    lanceBeam(from,to,col,ion?1.3:dark?2:1.6,.7,{dark,ion}); SFX.lance(ion,c.va.fac,from); addTrauma(.05);
    if(h) landLead(c,to,from); else wfp(to,{cell:0,size:3,col:col.scale(.8),dur:.3,grow:.5});
    await wait(150); }
  await wait(150); }

// ---------- torpedoes: a modelled body (shared instances), an exhaust that curls with the flight path, a big detonation ----------
function torpProto(fac,sac){ const key=fac+(sac?'s':''), P=G.torpProto=G.torpProto||{}; let p=P[key]; if(p&&!p.body.isDisposed()) return p; const M=facMats(fac), sc=G.scene;
  let body; if(sac){ body=MB.CreateSphere('torpB',{diameter:1.2,segments:10},sc); body.scaling.set(.85,.85,1.35); body.bakeCurrentTransformIntoVertices(); }
  else { const c=MB.CreateCylinder('tb',{height:2,diameter:.52,tessellation:12},sc); c.rotation.x=Math.PI/2; c.bakeCurrentTransformIntoVertices(); const n=MB.CreateCylinder('tn',{height:.8,diameterTop:0,diameterBottom:.52,tessellation:12},sc); n.rotation.x=Math.PI/2; n.position.z=1.4; n.bakeCurrentTransformIntoVertices();
    const fins=[0,1,2,3].map(i=>{ const f=MB.CreateBox('tf',{width:.05,height:.62,depth:.55},sc); f.position.set(0,0,-.75); f.rotation.z=i*Math.PI/2; f.bakeCurrentTransformIntoVertices(); f.position.set(0,0,0); return f; });
    body=BABYLON.Mesh.MergeMeshes([c,n,...fins],true,true); }
  body.name='torpProto_'+key; body.material=sac?(M.flesh||M.hull):M.dark; body.isVisible=false; body.isPickable=false; body.position.y=-9000;
  const g=sac?MB.CreateSphere('tg',{diameter:.5,segments:6},sc):MB.CreateTorus('tg',{diameter:.5,thickness:.12,tessellation:16},sc); if(!sac){ g.rotation.x=Math.PI/2; g.position.z=.35; g.bakeCurrentTransformIntoVertices(); g.position.set(0,0,0); }
  g.name='torpGlow_'+key; g.material=M.eng; g.isVisible=false; g.isPickable=false; g.position.y=-9000;
  return P[key]={body,glow:g,rigs:[]}; }
function torpRig(fac,sac){ const p=torpProto(fac,sac); let r=p.rigs.find(x=>!x.busy&&!x.node.isDisposed()); if(!r){ const node=new BABYLON.TransformNode('torp',G.scene), b=p.body.createInstance('torpI'), g=p.glow.createInstance('torpG'); b.parent=node; g.parent=node; b.isPickable=g.isPickable=false; r={node,b,g,busy:false}; if(p.rigs.length<16) p.rigs.push(r); else r.temp=true; }
  r.busy=true; r.node.setEnabled(true); r.node.scaling.setAll((sac?2.4:2.2)*(G.fxK||1)*.75); r.release=()=>{ if(r.temp){ r.node.dispose(); return; } r.node.setEnabled(false); r.busy=false; }; return r; }
async function torpRun(c,shots,mz){ const fac=c.va.fac, TF={corsair:{dur:.8,arc:2,wob:.9,curve:4},chorus:{dur:1.15,arc:5.5,sac:true,curve:2},ithar:{dur:.55,arc:.6,curve:1.5},voidsworn:{dur:.85,arc:3.2,curve:6}}[fac]||{dur:.75,arc:3,curve:5};
  const P=c.P, eng=(P.eng||c.col), hot=hotOf(eng,.6);
  const arrivals=shots.map((h,i)=>new Promise(res=>{ setTimeout(()=>{ let rig=null; const fin=onceFn(()=>{ try{ if(rig) rig.release(); }catch(e){} res(); });
    try{ const from=mz[i%mz.length], to=h?hitPoint(c.vt,from,c.shielded):missPoint(c.vt,from), d=to.subtract(from).normalize();
      wfp(from,{cell:1,size:3.4,col:hot.scale(1.8),dur:.1,grow:.4}); smokePuff(from.add(d.scale(1)),nq(3),1.2,{l0:1.2,l1:2,v:2}); SFX.torp(fac,from);
      rig=torpRig(fac,TF.sac); const dist=V3.Distance(from,to);
      wbFly(from,to,{speed:dist/TF.dur,overshoot:0,arc:TF.arc,curve:(Math.random()<.5?-1:1)*TF.curve*rr(.6,1.2),wob:TF.wob,
        layers:[{cell:0,size:5.5,col:eng.scale(1.5),back:2.6,wob:.15,wf:40},{cell:1,size:4.5,col:hot.scale(2),back:2.6,flick:38},{cell:3,len:6,thick:2,col:hot.scale(1.6),back:2.6}],
        trail(r,p,dd,dt){ if(rig){ rig.node.position.copyFrom(p); rig.node.lookAt(p.add(dd)); } r.acc+=dt; const st=G.mobile?.05:.022;
          while(r.acc>=st){ r.acc-=st; const tail=p.subtract(dd.scale(2.8)); wfp(tail,{pool:'fire',size:rr(2,2.8),col:hot.scale(1.5),dur:rr(.18,.26),grow:.6,anim:[0,6],vel:dd.scale(-3),fade:.8});
            wfp(tail.subtract(dd.scale(.6)),{pool:'smoke',size:rr(1.8,2.6),col:new C3(.42,.39,.36),alpha:.55,dur:rr(1.4,2.4),grow:2.6,vel:rdir().scale(.6),drag:.5,fade:1.1}); }
          const k=r.go/Math.max(1,r.arriveAt); if(typeof pdFire==='function'&&k>.25&&k<.92) pdFire(c.vt,p); },
        onArrive:()=>{ try{ if(h) landLead(c,to,from); else blast(to,1.8,{light:false}); }finally{ fin(); } },settle:fin});
    }catch(e){ console.warn('torp',e); fin(); } },i*120*SPEED); }));
  await Promise.all(arrivals); await wait(90); }

// ---------- the weapon pass (called by the rules engine before damage is applied) ----------
async function animWeapon(u,w,t,shots){
  const va=G.views.get(u.id), vt=G.views.get(t.id); if(!va||!vt) return;
  if(w.k==='lance'||w.k==='torp') await cineFrame(u,t,w.k); else if(!u.isSq) await cineFrame(u,t,'volley');
  if(!vt.root||vt.root.isDisposed()||!va.root) return;
  fxMark(w.k==='lance'?'lance':w.k==='torp'?'torp':'volley');
  const fam=wFamily(u,w,va.fac), F=WFX[fam]||WFX.shell, c=wCtx(u,w,t,va,vt,fam), tp=c.tp;
  const mz=muzzles(va,w.arc,tp).sort((p1,p2)=>V3.Distance(p1,tp)-V3.Distance(p2,tp)); if(!mz.length) mz.push(va.root.getAbsolutePosition());
  if(!u.isSq&&fam!=='flak'){ const d=va.root.getAbsolutePosition().subtract(tp); const rk=fam==='lance'?3.2:fam==='torp'?1.6:fam==='plasma'||fam==='rail'?2.8:(w.arc==='P'||w.arc==='S')?2.4:1.2; setTimeout(()=>{ try{ physKick(u,d,rk*(G.fxReduced?.6:1),(w.arc==='P'?1:w.arc==='S'?-1:0)*rk*.05); }catch(e){} },fam==='lance'?300:110); } // recoil
  if(w.arc==='T'&&typeof aimTurrets==='function'&&va.model&&va.model.turrets){ aimTurrets(va,tp); await wait(160); }
  if(F.lance) return lanceRun(c,shots,mz);
  if(F.torp) return torpRun(c,shots,mz);
  const gap=F.gap*(u.isSq?.8:1);
  if(!u.isSq&&F.vol>0){ try{ let vol=volleyPlan(va,w,shots.length,tp); if(fam==='flak') vol=vol.filter((_,i)=>i%2===0); vol=vol.slice(0,Math.max(0,Math.round(vol.length*F.vol)));
      const span=Math.max(shots.length*gap,300+vol.length*9), anyHit=shots.some(x=>x), nHit=anyHit?Math.max(1,Math.round(vol.length*shots.filter(Boolean).length/Math.max(1,shots.length))):0, hitIx=new Set(vol.map((_,i)=>i).sort(()=>Math.random()-.5).slice(0,nHit));
      vol.forEach((q,j)=>{ setTimeout(()=>{ try{ if(!vt.root||vt.root.isDisposed()) return; const h=hitIx.has(j), to=h?hitPoint(vt,q.p,c.shielded):missPoint(vt,q.p); if(h&&c.shielded) to.addInPlace(new V3((Math.random()-.5)*vt.L*.35,(Math.random()-.3)*2.5,(Math.random()-.5)*vt.L*.35));
        if(j%2===0) SFX.gun(w.k,false,fam==='rail'?'rail':fam==='spine'||fam==='glob'||fam==='plasma'||fam==='las'||fam==='tracer'||fam==='needle'?fam:'shell',q.p);
        F.fire(c,q.p,to,h,false,()=>{ if(!h||!vt.root||vt.root.isDisposed()) return; if(c.shielded) volleyImpact(to,c.col,true,q.p,c.sc); else { F.impact(c,to,q.p,false); if(Math.random()<.04) hullDecal(vt,q.p,false); } if(j%3===1) SFX.patter(c.shielded,to); }); }catch(e){} },(j/Math.max(1,vol.length))*span*SPEED+Math.random()*25); });
    }catch(e){ console.warn('volley',e); } }
  const arrivals=shots.map((h,i)=>new Promise(res=>{ setTimeout(()=>{ const done=onceFn(()=>{ try{ if(h){ if(fam==='flak'&&t.isSq){} else landLead(c,to,from); } }finally{ res(); } });
    let from=null,to=null; try{ from=mz[i%mz.length]; to=h?hitPoint(vt,from,c.shielded):missPoint(vt,from);
      SFX.gun(w.k,u.isSq,fam==='sq'?null:fam==='spine'||fam==='glob'||fam==='plasma'||fam==='las'||fam==='tracer'||fam==='needle'||fam==='rail'?fam:'shell',from);
      F.fire(c,from,to,h,true,done); }catch(e){ console.warn('fire',e); done(); } },i*gap*SPEED); }));
  await Promise.all(arrivals); await wait(90); }
function fxCrit(t){ try{ const v=G.views.get(t.id); if(!v||!v.root) return; const p=v.root.getAbsolutePosition(); juice('m',p,{sfx:()=>SFX.hit(p,true)}); sparkSpray(p.add(new V3(0,1,0)),null,nq(14),[10,24],new C3(1,.85,.5),1); }catch(e){} }

// ---------- burning ships and smoking stacks: pooled emitters instead of particle systems ----------
const EMIT=new Set();
function emitter(v,local,kind,rate){ const em={v,p:local,kind,rate,acc:Math.random(),on:true,stop(){ this.on=false; EMIT.delete(this); },dispose(){ this.on=false; EMIT.delete(this); }}; EMIT.add(em); return em; }
function emitTick(dt){ if(!EMIT.size) return; const q=fxQ();
  for(const em of EMIT){ const v=em.v; if(!em.on||!v.root||v.root.isDisposed()||(v.state&&v.state!=='alive')){ EMIT.delete(em); continue; } em.acc+=dt*em.rate*q; if(em.acc<1) continue;
    const p=V3.TransformCoordinates(em.p,v.root.getWorldMatrix());
    while(em.acc>=1){ em.acc-=1;
      if(em.kind==='fire'){ wfp(p.add(new V3(rr(-.4,.4),rr(0,.3),rr(-.4,.4))),{pool:'fire',size:rr(1,1.8),col:new C3(1,.5,.18).scale(rr(1.3,1.7)),dur:rr(.5,.9),grow:1.2,vel:new V3(rr(-.3,.3),rr(1.2,2.4),rr(-.3,.3)),drag:.6,spin:rr(-1,1),fade:.8});
        if(Math.random()<.5) wfp(p.add(new V3(0,.8,0)),{pool:'smoke',size:rr(1.2,1.8),col:new C3(.16,.14,.13),alpha:.55,dur:rr(1.4,2.4),grow:2,vel:new V3(rr(-.4,.4),rr(1.4,2.4),rr(-.4,.4)),drag:.3,spin:rr(-.5,.5)});
        if(Math.random()<.15) wfp(p,{cell:8,size:.6,col:new C3(1,.6,.25).scale(1.8),c2:new C3(.4,.04,0),dur:rr(.8,1.4),grow:0,vel:new V3(rr(-1.5,1.5),rr(1.5,3.5),rr(-1.5,1.5)),drag:.5,grav:.6}); }
      else if(em.kind==='vent') wfp(p,{pool:'smoke',size:rr(.5,.9),col:new C3(.78,.82,.9),alpha:.32,dur:rr(.6,1.2),grow:2.6,vel:V3.TransformNormal(new V3(rr(-.2,.2),rr(.1,.4),em.side||1),v.root.getWorldMatrix()).normalize().scale(rr(3,6)),drag:.8});
      else wfp(p,{pool:'smoke',size:rr(.5,.8),col:new C3(.3,.27,.24),alpha:.45,dur:rr(1.6,3),grow:3,vel:new V3(rr(-.2,.2),rr(.6,1.3),rr(-.2,.2)),drag:.25,spin:rr(-.4,.4)}); } } }
function addFire(v){ const sk=typeof skinPoint==='function'?skinPoint(v,null):null, lp=sk?sk.p.clone():new V3((Math.random()-.5)*v.L*.6,v.H*.35,(Math.random()-.5)*v.L*.12);
  v.fires.push(emitter(v,lp,'fire',G.mobile?9:16));
  if(v.fires.length===2){ const side=Math.random()<.5?1:-1, vp=new V3((Math.random()-.5)*v.L*.5,v.H*.2,side*v.L*.07), e=emitter(v,vp,'vent',G.mobile?14:30); e.side=side; v.fires.push(e); } }
function stackSmoke(v){ return (v.model.stacks||[]).map(sp=>emitter(v,sp.clone(),'stack',G.mobile?4:9)); }

// ---------- per-frame: bolts, emitters; is anything still playing (phones keep full frame rate while it is) ----------
function wfxTick(dt){ fxScaleTick(); try{ wbTick(dt); }catch(e){ console.warn('bolts',e); } try{ heatTick(); }catch(e){} try{ emitTick(dt); }catch(e){} }
function fxBusy(){ return WB.length>0||(G.trauma||0)>.01||!!(G.hitStop&&performance.now()<G.hitStop.end); }

// ---------- staged deaths ----------
// a point on the real hull surface (concept meshes carry a sampled skin) near fraction fx of its length, with the outward normal
function hullPointAt(v,fx){ const L=v.L||10; try{ v.root.computeWorldMatrix(true); const W=v.root.getWorldMatrix(), sk=v.model&&v.model.skin;
    if(sk&&sk.length){ const x=fx*L; let b=null,bd=1e9; for(let i=0;i<10;i++){ const c=sk[Math.floor(Math.random()*sk.length)], d=Math.abs(c.p.x-x); if(d<bd){ bd=d; b=c; } } return {p:V3.TransformCoordinates(b.p,W),n:V3.TransformNormal(b.n,W).normalize()}; }
    const lp=new V3(fx*L,(v.H||3)*(.15+Math.random()*.5),(Math.random()-.5)*L*.14), n=new V3(0,.5,lp.z>=0?1:-1).normalize(); return {p:V3.TransformCoordinates(lp,W),n:V3.TransformNormal(n,W).normalize()}; }catch(e){ return {p:v.root.getAbsolutePosition().clone(),n:new V3(0,1,0)}; } }
// one internal blast: fire bursts out of the plating along its normal, sparks and a scorch; capitals feel each one
function deathPop(v,p,n,L,i,of,reactor){ const s=(reactor?1.4:.9)+L*(reactor?.07:.05);
  blast(p.add(n.scale(s*.3)),s,{light:i%3===0,smoke:true,debris:reactor||L>=20}); const jets=nq(reactor?4:3,6);
  for(let k=0;k<jets;k++){ const d=coneDir(n,.35), q=p.add(d.scale(s*.4)); wfp(q,{cell:10,size:s*.9,col:new C3(1,.6,.24).scale(1.8),dur:rr(.25,.4),grow:1,vel:d.scale(s*2),drag:2,ang:screenAng(q,d),w:3,h:1,fade:1.1}); wfp(q,{pool:'fire',size:s*rr(.9,1.3),col:new C3(1,.5,.18).scale(1.6),dur:rr(.5,.8),grow:1.4,vel:d.scale(s*rr(1.5,3)),drag:1.4,fade:.8}); }
  sparkSpray(p,n,nq(10+L*.3,40),[8+L*.2,18+L*.4],new C3(1,.82,.5),.7);
  addTrauma(.06+L/320); if(i===0&&L>=18&&!reactor) hitStop(.05); if(reactor&&i===0) juice('m',p,{noStop:L<18}); }

// ---------- broken hulls: no hollow insides. A wreck shows its back faces (inner walls seen through a cut) as charred metal with a few embers ----------
class WreckInPlugin extends BABYLON.MaterialPluginBase{
  constructor(m){ super(m,'WreckIn',230,{WRECKIN:false}); this._enable(true); }
  prepareDefines(d){ d.WRECKIN=true; } getClassName(){ return 'WreckInPlugin'; }
  getCustomCode(type){ if(type!=='fragment') return null; return {CUSTOM_FRAGMENT_BEFORE_FRAGCOLOR:`
#ifdef WRECKIN
  if(!gl_FrontFacing){ float wn=fract(sin(dot(floor(vPositionW*1.4),vec3(12.9898,78.233,37.719)))*43758.5453); finalColor.rgb=vec3(0.02,0.016,0.013)+vec3(1.0,0.34,0.07)*step(0.95,wn)*0.45; }
#endif
`}; } }
function wreckInterior(M){ try{ for(const m of [M&&M.wreck]) if(m&&!m._wreckIn&&m.getClassName&&m.getClassName()==='PBRMaterial'){ m._wreckIn=new WreckInPlugin(m); m.backFaceCulling=false; } }catch(e){ console.warn('wreck interior',e); } }

// ---------- heat shimmer: plasma bolts (and fresh slag) bend the picture behind them (desktop High/Ultra; a pass-through when nothing is hot) ----------
const HEAT_FS=`precision highp float; varying vec2 vUV; uniform sampler2D textureSampler; uniform vec4 hp[8]; uniform float hn; uniform float t; uniform float aspect;
void main(){ vec2 uv=vUV; vec2 off=vec2(0.0);
  for(int i=0;i<8;i++){ if(float(i)>=hn) break; vec4 p=hp[i]; vec2 d=uv-p.xy; d.x*=aspect; float r=length(d); float f=smoothstep(p.z,0.0,r)*p.w;
    off+=vec2(sin(uv.y*160.0+t*23.0+float(i)*2.1),cos(uv.x*150.0-t*19.0+float(i)*1.7))*f*0.0035; }
  gl_FragColor=texture2D(textureSampler,uv+off); }`;
function heatHazeOn(){ if(G.heatPP!==undefined) return G.heatPP; G.heatPP=null; if(G.mobile||G.quality==='medium'||!G.cam) return null;
  try{ BABYLON.Effect.ShadersStore.heatHazeFragmentShader=HEAT_FS; const pp=new BABYLON.PostProcess('heatHaze','heatHaze',['hp','hn','t','aspect'],null,1.0,G.cam); const buf=new Float32Array(32); G.heatPts=[];
    pp.onApply=e=>{ const n=Math.min(8,G.heatPts.length); for(let i=0;i<n;i++) buf.set(G.heatPts[i],i*4); e.setArray4('hp',buf); e.setFloat('hn',n); e.setFloat('t',(G.time||0)%100); e.setFloat('aspect',G.engine.getAspectRatio(G.cam)); };
    G.heatPP=pp; }catch(e){ console.warn('heat haze off',e); G.heatPP=null; } return G.heatPP; }
function heatTick(){ if(!G.heatPP) return; const pts=G.heatPts; pts.length=0; if(G.fxReduced) return; let tm=null, vp=null;
  for(const r of WB){ if(!r.o.heat||pts.length>=8) continue; if(!tm){ tm=G.scene.getTransformMatrix(); vp=new BABYLON.Viewport(0,0,1,1); } const s=V3.Project(r.pos,BABYLON.Matrix.Identity(),tm,vp); if(s.z<0||s.z>1) continue;
    const dist=Math.max(5,V3.Distance(G.cam.position,r.pos)), ru=r.o.heat*(G.fxK||1)/(dist*.85); pts.push([s.x,1-s.y,ru,1]); } }
