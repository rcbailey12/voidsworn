// ---------- v42 graphics: GPU shader library ----------
// Everything here is generated on the GPU from code (no downloaded art). Every effect has a cheaper path on Medium (phones).
// Note: this file is evaluated by the simulator too (only the browser calls these functions), so keep it free of top-level GPU work.

// ---------- hull shading ----------
// Runs inside Babylon's PBR shader (no extra draw calls). Per pixel, in the ship's own coordinates so patterns ride with the hull:
//  - a faction rim light (brighter as the camera pulls back) so ships read as silhouettes against bright nebulae
//  - grime and exhaust streaks that break up the tiled panel texture
//  - faction energy: Deathless circuit traces with pulses, Chorus veins with a heartbeat, Ithar light sweeping along the hull
const HULLFX_STYLE={deathless:1,chorus:2,ithar:3,voidsworn:4,hegemony:4,corsair:5};
const HFX_RIM0=new BABYLON.Color3(.6,.7,.9), HFX_E0=new BABYLON.Color3(1,.62,.3); // fallbacks: a missing colour must never break the bind (it hides the hull)
// every field the bind writes must be a real number or colour: an undefined one throws (the hull never draws) or turns a uniform NaN (the hull
// renders pitch black on D3D/ANGLE; SwiftShader hid it). Plugins that arrive through a material clone start with none of them.
function hfxSane(pl){ const c=x=>x&&typeof x.r==='number'&&isFinite(x.r)&&isFinite(x.g)&&isFinite(x.b), n=(x,d)=>typeof x==='number'&&isFinite(x)?x:d;
  if(!c(pl.rim)) pl.rim=HFX_RIM0; if(!c(pl.ecol)) pl.ecol=HFX_E0; if(pl.wcol&&!c(pl.wcol)) pl.wcol=null; pl.str=n(pl.str,.85); pl.wear=n(pl.wear,.25); pl.seed=n(pl.seed,3); pl.style=n(pl.style,0); pl.dmg=n(pl.dmg,0); pl.dseed=n(pl.dseed,0); } // a handful of type checks per bind: cheap
class HullFxPlugin extends BABYLON.MaterialPluginBase{
  constructor(material,o){ super(material,'HullFx',210,{HULLFX:false,HULLFX_HI:false,HULLFX_PLATE:false,HULLFX_AI:false,HULLFX_D2:false,HULLFX_RING:false,HULLFX_HAZ:false,HULLFX_MAP:false,HULLFX_PAINT:false}); Object.assign(this,o); this._enable(true); }
  prepareDefines(defines){ defines.HULLFX=true; defines.HULLFX_HI=G.quality!=='medium'&&!G.diagNoHullHi&&!!(G.engine&&G.engine.webGLVersion>=2); defines.HULLFX_PLATE=this.style!==2&&this.style!==3&&!this.ai; defines.HULLFX_AI=!!this.ai; defines.HULLFX_PAINT=!!this.paint; defines.HULLFX_RING=!!this.ring; defines.HULLFX_HAZ=!!this.haz; defines.HULLFX_MAP=!!(this.mtex&&this.mtex.isReady&&this.mtex.isReady()); defines.HULLFX_D2=!!(G.engine&&G.engine.webGLVersion>=2); } // v53-G: ai = concept-mesh hull (shader ports, fine detail, its plating is in the textures) // organic Chorus and porcelain Ithar hulls get no riveted plating
  getClassName(){ return 'HullFxPlugin'; }
  getSamplers(samplers){ samplers.push('hfxMap'); }
  getActiveTextures(a){ if(this.mtex) a.push(this.mtex); }
  hasTexture(t){ return t===this.mtex; }
  getUniforms(){ return {ubo:[{name:'hfxRim',size:3,type:'vec3'},{name:'hfxK',size:4,type:'vec4'},{name:'hfxE',size:3,type:'vec3'},{name:'hfxS',size:2,type:'vec2'},{name:'hfxD',size:2,type:'vec2'},{name:'hfxW',size:4,type:'vec4'}],
    fragment:'#ifdef HULLFX\nuniform vec3 hfxRim;\nuniform vec4 hfxK;\nuniform vec3 hfxE;\nuniform vec2 hfxS;\nuniform vec2 hfxD;\nuniform vec4 hfxW;\n#endif\n'}; } // the baked-map sampler is declared with the fragment definitions (it is read inside the reflectivity block, which comes before the uniforms)
  bindForSubMesh(ubo){ hfxSane(this); ubo.updateColor3('hfxRim',this.rim); ubo.updateFloat4('hfxK',this.str*(G.rimBoost||1),(G.time||0)%600,this.wear,this.energy?this.style:0); ubo.updateColor3('hfxE',this.ecol); ubo.updateFloat2('hfxS',this.seed,G.hullEnergy==null?1:G.hullEnergy); ubo.updateFloat2('hfxD',this.dmg||0,this.dseed||0); const w=this.wcol; ubo.updateFloat4('hfxW',w?w.r:0,w?w.g:0,w?w.b:0,w?(G.hullPorts==null?1:G.hullPorts):0); if(this.mtex) ubo.setTexture('hfxMap',this.mtex); }
  getCustomCode(type){
    if(type==='vertex') return {CUSTOM_VERTEX_DEFINITIONS:'#ifdef HULLFX\nvarying vec3 vHfxL;\nvarying vec3 vHfxN;\n#endif\n',CUSTOM_VERTEX_MAIN_END:'#ifdef HULLFX\nvHfxL=positionUpdated;\nvHfxN=normalUpdated;\n#endif\n'};
    if(type!=='fragment') return null;
    return {
CUSTOM_FRAGMENT_DEFINITIONS:`
#ifdef HULLFX_MAP
uniform sampler2D hfxMap;
#endif
#ifdef HULLFX
varying vec3 vHfxL;
varying vec3 vHfxN;
float hfxH(vec3 p){ p=fract(p*0.3183099+vec3(0.71,0.113,0.419)); p*=17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
float hfxN(vec3 x){ vec3 i=floor(x); vec3 f=fract(x); f=f*f*(3.0-2.0*f);
  return mix(mix(mix(hfxH(i),hfxH(i+vec3(1,0,0)),f.x),mix(hfxH(i+vec3(0,1,0)),hfxH(i+vec3(1,1,0)),f.x),f.y),mix(mix(hfxH(i+vec3(0,0,1)),hfxH(i+vec3(1,0,1)),f.x),mix(hfxH(i+vec3(0,1,1)),hfxH(i+vec3(1,1,1)),f.x),f.y),f.z); }
#endif
`,
CUSTOM_FRAGMENT_UPDATE_ALBEDO:`
#ifdef HULLFX
  { vec3 hl=vHfxL+hfxS.x;
#ifndef HULLFX_PAINT
    float gr=smoothstep(0.42,0.92,hfxN(hl*vec3(0.05,0.16,0.16)))*0.6;
#ifdef HULLFX_HI
    gr+=smoothstep(0.5,0.95,hfxN(vec3(hl.x*0.03,hl.y*0.9,hl.z*0.9)))*0.4;
#endif
    surfaceAlbedo*=1.0-gr*hfxK.z;
#ifdef HULLFX_HAZ
    { float cx=vHfxL.x; float col=max(max(1.0-smoothstep(0.55,0.65,abs(cx-3.6)),1.0-smoothstep(0.4,0.5,abs(cx+0.6))),1.0-smoothstep(0.4,0.5,abs(cx+4.3))); // v53-G transport: hazard collars fore, amidships and aft
      float str=step(0.5,fract((vHfxL.x+vHfxL.y+vHfxL.z)*1.4)); surfaceAlbedo=mix(surfaceAlbedo,mix(vec3(0.05,0.045,0.04),vec3(0.95,0.7,0.08),str),col*0.92); }
#endif
    { vec3 cq=floor(vHfxL*vec3(0.32,0.55,0.55)+hfxS.x*3.0); float tone=hfxH(cq); surfaceAlbedo*=0.88+0.22*tone; // plate-to-plate tone, visible at any distance
      float ny=normalize(vHfxN).y; surfaceAlbedo*=mix(0.72,1.0,smoothstep(-0.85,0.35,ny)); } // undersides sit in shadow
#endif
    if(hfxD.x>0.001){ float dn=hfxN(vHfxL*0.16+hfxD.y)*0.7+hfxN(vHfxL*0.55+hfxD.y*1.7)*0.3;
      float burn=smoothstep(1.0-hfxD.x*0.62,1.0-hfxD.x*0.62+0.07,dn);
      surfaceAlbedo=mix(surfaceAlbedo,surfaceAlbedo*vec3(0.09,0.075,0.065),burn); } }
#ifdef HULLFX_MAP
  { vec3 mp=texture2D(hfxMap,vMainUV2).rgb; float vao=1.0; // v53-G baked maps: texel AO replaces the vertex AO, curvature wears the edges bright and fills the cavities with grime
#ifdef VERTEXCOLOR
    vao=max(vColor.r,0.25);
#endif
    surfaceAlbedo*=clamp(mix(1.0,mp.r,0.9)/vao,0.3,1.3); float cv=mp.g-0.5;
    surfaceAlbedo*=1.0+smoothstep(0.03,0.2,cv)*0.4-smoothstep(0.02,0.16,-cv)*0.32; }
#endif
#endif
`,
CUSTOM_FRAGMENT_BEFORE_LIGHTS:`
#ifdef HULLFX
#if defined(HULLFX_HI) && defined(HULLFX_PLATE)
    // plating: seams, inset hatches and per-plate tone, bump-mapped from a height computed per pixel (no texture), fading out with distance
    { float hd0=length(vEyePosition.xyz-vPositionW); float pf=1.0-smoothstep(55.0,130.0,hd0);
      if(pf>0.001){ vec3 an=abs(normalize(vHfxN)); vec2 pu=an.x>an.y&&an.x>an.z?vHfxL.zy:(an.y>an.z?vHfxL.xz:vHfxL.xy); pu*=1.15;
        float row=floor(pu.y/0.85); float wd=1.3+hfxH(vec3(row,3.1,0.0))*2.8; float off=hfxH(vec3(row,7.7,0.0))*wd;
        float cx=floor((pu.x+off)/wd); vec2 fr=vec2(fract((pu.x+off)/wd)*wd,fract(pu.y/0.85)*0.85);
        float e=min(min(fr.x,wd-fr.x),min(fr.y,0.85-fr.y)); float seam=smoothstep(0.0,0.045,e); float id=hfxH(vec3(cx,row,1.3));
        float inset=step(0.8,id)*smoothstep(0.1,0.15,e);
        float ht=(seam-inset*0.45+(id-0.5)*0.08)*0.035;
        vec3 dpx=dFdx(vPositionW), dpy=dFdy(vPositionW); float dhx=dFdx(ht), dhy=dFdy(ht);
        vec3 r1=cross(dpy,normalW), r2=cross(normalW,dpx); float det=dot(dpx,r1); vec3 grd=sign(det)*(dhx*r1+dhy*r2);
        vec3 nb=normalize(abs(det)*normalW-grd); normalW=normalize(mix(normalW,nb,pf*0.9));
        surfaceAlbedo*=mix(1.0,(0.7+0.3*seam)*(0.93+0.14*id),pf); } }
#endif
#if defined(HULLFX_AI) && defined(HULLFX_D2) && !defined(HULLFX_PAINT)
    // v53.8 close-up plating on concept hulls (Ryan: "melted" up close): staggered panel seams, inset hatches, small raised blocks and dents,
    // bump-mapped from a per-pixel height. Laid in ship units on the open plating only (the baked cavities and raised edges keep their own shape).
    // Each layer fades out by its own pixel footprint, so it is crisp when there are pixels for it and never shimmers when there are not.
    { float hd0=length(vEyePosition.xyz-vPositionW); float pf=1.0-smoothstep(60.0,120.0,hd0);
#ifdef HULLFX_MAP
      { vec3 mq=texture2D(hfxMap,vMainUV2).rgb; pf*=smoothstep(0.22,0.5,mq.r)*(1.0-smoothstep(0.1,0.28,abs(mq.g-0.5))); }
#endif
      if(pf>0.001){ vec3 an=abs(normalize(vHfxN)); vec2 pu=an.x>an.y&&an.x>an.z?vHfxL.zy:(an.y>an.z?vHfxL.xz:vHfxL.xy);
        vec2 pp=pu*vec2(1.5,2.3); float row=floor(pp.y); float wd=1.0+hfxH(vec3(row,3.1,hfxS.x))*2.4; float off=hfxH(vec3(row,7.7,0.0))*wd; float cx=floor((pp.x+off)/wd);
        vec2 fr=vec2(fract((pp.x+off)/wd)*wd,fract(pp.y)); float e=min(min(fr.x,wd-fr.x),min(fr.y,1.0-fr.y)); float pid=hfxH(vec3(cx,row,1.3));
        float fp=max(fwidth(pp.x),fwidth(pp.y)); float pk=pf*(1.0-smoothstep(0.06,0.16,fp)); // plates: gone once a seam is under a pixel
        float seam=(1.0-smoothstep(0.0,max(0.035,fp*1.2),e))*pk;
        vec2 sp=pu*vec2(5.2,6.8); vec2 ci=floor(sp); vec2 sf=fract(sp); float id=hfxH(vec3(ci,2.7+hfxS.x)); float se=min(min(sf.x,1.0-sf.x),min(sf.y,1.0-sf.y));
        float fs=max(fwidth(sp.x),fwidth(sp.y)); float sk=pf*(1.0-smoothstep(0.07,0.16,fs)); // small cells need about eight pixels, or they read as a screen-door grain
        float hatch=step(0.87,id)*smoothstep(0.07,0.13,se)*sk; float greeb=step(id,0.07)*smoothstep(0.1,0.17,se)*sk;
        float ht=(-seam*0.6+(pid-0.5)*0.22*pk-hatch*0.45+greeb*0.6+(hfxN(vHfxL*2.2)-0.5)*0.12*pk)*0.016;
        vec3 dpx=dFdx(vPositionW), dpy=dFdy(vPositionW); float dhx=dFdx(ht), dhy=dFdy(ht);
        vec3 r1=cross(dpy,normalW), r2=cross(normalW,dpx); float det=dot(dpx,r1); vec3 grd=sign(det)*(dhx*r1+dhy*r2);
        vec3 nb=normalize(abs(det)*normalW-grd); normalW=normalize(mix(normalW,nb,0.85));
        surfaceAlbedo*=(1.0-seam*0.24-hatch*0.1+greeb*0.05)*(1.0+(pid-0.5)*0.12*pk); } }
#endif
#endif
`,
CUSTOM_FRAGMENT_UPDATE_METALLICROUGHNESS:`
#ifdef HULLFX_AI
  { float hdr=length(vEyePosition.xyz-vPositionW); float rn=hfxN(vHfxL*1.9+hfxS.x)*0.6+hfxN(vHfxL*5.3)*0.4; // v53-G: no mirror-smooth texels (glitter), and a broken-up sheen up close
    metallicRoughness.g=clamp(max(metallicRoughness.g,0.42)+(rn-0.5)*0.24*(1.0-smoothstep(30.0,110.0,hdr)),0.32,1.0);
#ifdef HULLFX_MAP
    { float cv=texture2D(hfxMap,vMainUV2).g-0.5; metallicRoughness.g=clamp(metallicRoughness.g-smoothstep(0.03,0.2,cv)*0.12+smoothstep(0.02,0.16,-cv)*0.18,0.34,1.0); } // polished edges, rough grimy recesses
#endif
  }
#endif
`,
CUSTOM_FRAGMENT_BEFORE_FINALCOLORCOMPOSITION:`
#ifdef HULLFX
  { vec3 hv=normalize(vEyePosition.xyz-vPositionW); float hd=length(vEyePosition.xyz-vPositionW);
    float hf=pow(1.0-clamp(abs(dot(normalW,hv)),0.0,1.0),2.6);
    float hdk=clamp(hd/110.0,1.0,2.4); // v52: rims and running lights grow with camera distance, so hulls keep their outline at fleet zoom
    finalEmissive+=hfxRim*hf*hfxK.x*hdk;
#ifdef HULLFX_AI
    // v53-G lit ports, part of the hull surface: short runs of small ports in deck rows on the flanks only (side-facing, open plating),
    // laid out in ship units so they keep scale. Edges are anti-aliased from the pixel footprint, below a pixel they fade to a faint average, then out.
    { vec3 wn=normalize(vHfxN);
#ifdef HULLFX_RING
      float side=1.0-smoothstep(0.3,0.55,abs(wn.y)); float ru=abs(wn.x)>abs(wn.z)?vHfxL.z:vHfxL.x; float sd=(abs(wn.x)>abs(wn.z)?(wn.x>0.0?1.7:5.3):(wn.z>0.0?2.9:7.1)); // all-round ports on a station
#else
      float side=smoothstep(0.42,0.75,abs(wn.z))*(1.0-smoothstep(0.35,0.6,abs(wn.y))); float ru=vHfxL.x; float sd=vHfxL.z>0.0?1.7:5.3;
#endif
      if(side>0.001&&hfxW.a>0.001){ vec2 wp=vec2(ru*2.6,vHfxL.y*1.55); vec2 wc=floor(wp); vec2 wf=fract(wp)-0.5;
        float lit=step(0.34,hfxH(vec3(wc.y*0.37,sd,hfxS.x)))*step(0.26,hfxH(vec3(floor(wc.x/6.0)*0.53,wc.y*0.71,sd+hfxS.x)))*step(0.1,hfxH(vec3(wc*0.91,4.2)));
#ifdef HULLFX_D2
        vec2 fw=max(fwidth(wp),vec2(1e-4));
#else
        vec2 fw=vec2(2.6,1.55)*hd*0.0011;
#endif
        float fm=max(fw.x,fw.y); vec2 hs=vec2(0.22,0.085);
        float bx=(1.0-smoothstep(hs.x-fw.x,hs.x+fw.x,abs(wf.x)))*(1.0-smoothstep(hs.y-fw.y,hs.y+fw.y,abs(wf.y)));
        float port=mix(bx,0.06,smoothstep(0.3,0.8,fm))*(1.0-smoothstep(0.8,1.8,fm));
        float cav=1.0;
#ifdef HULLFX_MAP
        { vec3 mp=texture2D(hfxMap,vMainUV2).rgb; cav=smoothstep(0.35,0.6,mp.r)*(1.0-smoothstep(0.03,0.12,mp.g-0.5)); } // ports sit in the plating, never on raised edges
#elif defined(VERTEXCOLOR)
        cav=smoothstep(0.38,0.62,vColor.r);
#endif
        finalEmissive+=hfxW.rgb*port*lit*side*cav*hfxW.a; } }
#endif
    if(hfxD.x>0.001){ float dn=hfxN(vHfxL*0.16+hfxD.y)*0.7+hfxN(vHfxL*0.55+hfxD.y*1.7)*0.3; float th=1.0-hfxD.x*0.62;
      float edge=smoothstep(th-0.014,th,dn)*(1.0-smoothstep(th+0.004,th+0.022,dn))*smoothstep(0.48,0.72,hfxN(vHfxL*1.4+hfxD.y*5.0)); // v53-G: the burn front smoulders in short ember runs, not one continuous ribbon
      float crack=(1.0-smoothstep(0.0,0.035+hd*0.0003,abs(hfxN(vHfxL*0.9+hfxD.y*3.0)-0.5)))*smoothstep(th+0.04,th+0.12,dn);
      float fl=0.7+0.3*sin(hfxK.y*9.0+vHfxL.x*1.7)*sin(hfxK.y*5.3+vHfxL.z*2.1);
      finalEmissive+=vec3(1.3,0.4,0.08)*(edge*0.75+crack*0.6)*fl*hfxD.x; }
    float st=hfxK.w, t=hfxK.y, w=0.05+hd*0.00045, en=hfxS.y*mix(1.0,hdk,0.7); vec3 lp=vHfxL;
    if(st>0.5&&st<1.5){
#ifdef HULLFX_AI
      const float CS=0.26, T1=0.74, T2=0.92, EB=0.28, WS=0.6; // v53-G: concept hulls get sparse, thin circuit traces (they were a dense green cage)
#else
      const float CS=0.55, T1=0.45, T2=0.78, EB=1.0, WS=1.0;
#endif
      vec3 q=lp*CS+hfxS.x; vec3 c=floor(q); vec3 f=fract(q); w*=CS/0.55*WS; en*=EB;
      float lx=(1.0-smoothstep(0.0,w,abs(f.y-0.5)))*step(T1,hfxH(c));
      float lz=(1.0-smoothstep(0.0,w,abs(f.x-0.5)))*step(T2,hfxH(c+3.1))*step(abs(f.y-0.5),0.5);
      float pu=pow(fract(q.x*0.2-t*0.3+hfxH(c)*3.0),10.0);
      finalEmissive+=hfxE*max(lx,lz*0.8)*(0.22+2.6*pu)*en; }
    else if(st>1.5&&st<2.5){ float n=hfxN(lp*0.32+hfxS.x)+0.35*hfxN(lp*0.9);
      float v=1.0-smoothstep(0.0,w*0.9,abs(n-0.68));
      float beat=0.5+0.5*sin(t*2.4-lp.x*0.22); beat=pow(beat,5.0);
      finalEmissive+=hfxE*v*(0.18+1.4*beat)*en; }
    else if(st>2.5&&st<3.5){ float b=pow(0.5+0.5*sin(lp.x*0.42-t*1.3+lp.y*0.25),22.0);
      finalEmissive+=hfxE*b*(0.2+0.4*hf)*en; }
  }
#endif
`}; }
}
try{ BABYLON.RegisterClass('BABYLON.HullFxPlugin',HullFxPlugin); }catch(e){}
function addHullFx(M,fac){ try{ const P=FAC3D[fac]||FAC3D.hegemony; const rim=C3.Lerp(P.eng,new C3(.75,.85,1),.45), style=HULLFX_STYLE[fac]||0, ecol=P.win.scale(fac==='deathless'?1.6:fac==='chorus'?1.2:fac==='ithar'?.35:.9);
    const wear={corsair:.45,voidsworn:.32,hegemony:.22,deathless:.3,chorus:.12,ithar:.08}[fac]??.25, seed=(fac.length*13.7)%10;
    const dk=(fac==='voidsworn'||fac==='deathless')?1.7:1; // the black fleets need a stronger rim to read against space
    for(const [k,s0,en] of [['hull',.85,1],['dark',.55,1],['steel',.45,0],['trim',.35,0]]) if(M[k]&&!M[k]._hullFx){ const s=s0*dk; M[k]._hullFx=new HullFxPlugin(M[k],{rim,str:s,style,ecol,wear:k==='trim'?wear*.4:wear,seed,energy:!!en}); } }catch(e){ console.warn('hull shading unavailable',e); } }

// ---------- procedural planets: gas giants, rocky worlds and ice worlds, lit by the sun with scattering at the limb ----------
const PLANET_GLSL={
  vert:`precision highp float; attribute vec3 position; attribute vec3 normal; uniform mat4 world; uniform mat4 worldViewProjection; varying vec3 vO; varying vec3 vN; varying vec3 vP;
    void main(){ vO=normalize(position); vN=normalize((world*vec4(normal,0.0)).xyz); vP=(world*vec4(position,1.0)).xyz; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  noise:`float h3(vec3 p){ p=fract(p*0.3183099+vec3(0.71,0.113,0.419)); p*=17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
    float n3(vec3 x){ vec3 i=floor(x); vec3 f=fract(x); f=f*f*(3.0-2.0*f);
      return mix(mix(mix(h3(i),h3(i+vec3(1,0,0)),f.x),mix(h3(i+vec3(0,1,0)),h3(i+vec3(1,1,0)),f.x),f.y),mix(mix(h3(i+vec3(0,0,1)),h3(i+vec3(1,0,1)),f.x),mix(h3(i+vec3(0,1,1)),h3(i+vec3(1,1,1)),f.x),f.y),f.z); }
    float fbm(vec3 p,int oct){ float v=0.0,a=0.5; for(int i=0;i<8;i++){ if(i>=oct) break; v+=a*n3(p); p=p*2.02+vec3(1.3,7.1,4.7); a*=0.5; } return v; }`,
  frag:`precision highp float; varying vec3 vO; varying vec3 vN; varying vec3 vP;
    uniform vec3 sunDir; uniform vec3 camPos; uniform vec3 pa; uniform vec3 pb; uniform vec3 pc; uniform vec3 pd; uniform vec3 atmo; uniform vec3 city; uniform float seed; uniform float kind; uniform float t; uniform float oct; uniform float expo; uniform float freq;
    NOISE
    void main(){
      vec3 o=vO*freq, N=normalize(vN), V=normalize(camPos-vP); int oc=int(oct); vec3 oo=vO;
      float ndl=dot(N,sunDir), day=smoothstep(-0.12,0.32,ndl);
      vec3 col; float land=0.0, spec=0.0;
      if(kind<0.5){ // gas giant: domain-warped latitude bands, fine turbulence and a great storm
        vec3 wq=o*vec3(1.6,5.0,1.6)+seed; float w=fbm(wq+vec3(t*0.002,0.0,0.0),oc)*0.9;
        float lat=oo.y*6.0+w*1.4+0.3*sin(o.x*3.0+o.z*2.0+seed*4.0);
        float b=0.5+0.5*sin(lat*2.1)+0.22*fbm(vec3(lat*1.6,o.x*1.2,o.z*1.2)+seed,oc);
        col=mix(pa,pb,smoothstep(0.25,0.75,b)); col*=0.82+0.36*fbm(vec3(lat*5.0,oo.x*3.0,oo.z*3.0)+seed*1.7,oc); col=mix(col,pc,smoothstep(0.6,0.95,fbm(o*vec3(1.5,12.0,1.5)+seed*2.0,oc))*0.5);
        vec3 sc=normalize(vec3(0.6,-0.25,0.75)); float sd=length(oo-sc); float sw=fbm(o*10.0+vec3(sd*8.0),oc);
        float st=smoothstep(0.2,0.0,sd+0.05*sw); col=mix(col,pd,st*0.8); col=mix(col,pc,smoothstep(0.1,0.0,sd)*0.4);
      } else if(kind<1.5){ // rocky world: continents with relief, shelves and oceans, ice caps
        float h=fbm(o*2.2+seed,oc)+0.22*fbm(o*8.0+seed*3.0,oc);
        land=smoothstep(0.53,0.55,h);
        vec3 sea=mix(pd*0.35,pd,smoothstep(0.32,0.53,h)); sea=mix(sea,pd*1.6+vec3(0.0,0.06,0.06),smoothstep(0.5,0.535,h)*0.6);
        float rel=fbm(o*16.0+seed,oc);
        vec3 gr=mix(pa,pb,smoothstep(0.55,0.75,h+rel*0.15)); gr=mix(gr,pc,smoothstep(0.72,0.9,h+rel*0.1));
        col=mix(sea,gr,land); float cap=smoothstep(0.78,0.9,abs(oo.y)+0.08*fbm(o*6.0,oc)); col=mix(col,vec3(0.92,0.95,1.0),cap);
        spec=(1.0-land)*(1.0-cap);
        // relief shading: tilt the normal by the height gradient
        if(oct>6.5){ float e=0.01; float hx=fbm((o+vec3(e,0,0))*2.2+seed,oc)-fbm((o-vec3(e,0,0))*2.2+seed,oc); float hz=fbm((o+vec3(0,0,e))*2.2+seed,oc)-fbm((o-vec3(0,0,e))*2.2+seed,oc);
        N=normalize(N-vec3(hx,0.0,hz)*land*3.0); ndl=dot(N,sunDir); } // relief costs four more noise stacks: High and Ultra only
      } else { // ice world: cracked pale crust with dark rifts
        float h=fbm(o*3.0+seed,oc); float h2=fbm(o*vec3(2.0,7.0,2.0)+seed*1.3,oc); float cr=1.0-smoothstep(0.0,0.025,abs(fbm(o*5.0+seed*2.0,oc)-0.5)); float cr2=1.0-smoothstep(0.0,0.015,abs(fbm(o*11.0+seed*4.0,oc)-0.5));
        col=mix(pb,pa,smoothstep(0.3,0.75,h)); col=mix(col,pc,smoothstep(0.55,0.8,h2)*0.5); col=mix(col,pd,max(cr*0.8,cr2*0.45)); spec=0.35;
      }
      // two cloud decks drift with time and cast a soft shadow on the ground
      float cl=smoothstep(0.55,0.82,fbm(o*4.0+vec3(t*0.004,0.0,seed),oc));
      float cl2=smoothstep(0.6,0.85,fbm(o*vec3(3.0,9.0,3.0)+vec3(-t*0.003,seed,0.0),oc));
      float cov=(kind>0.5&&kind<1.5?0.9:0.22); cl=max(cl,cl2*0.7)*cov;
      col*=1.0-cl*0.35; col=mix(col,vec3(1.0),cl*0.85);
      float limb=pow(clamp(dot(normalize(vN),V),0.0,1.0),0.35);
      vec3 lit=col*(0.02+0.95*day*max(ndl,0.0)+0.07*day)*mix(0.55,1.0,limb);
      vec3 H=normalize(sunDir+V); lit+=vec3(1.0,0.92,0.8)*pow(max(dot(N,H),0.0),70.0)*spec*day*(1.0-cl)*0.7;
      float night=1.0-smoothstep(-0.25,0.05,ndl); float lights=land*(1.0-cl)*smoothstep(0.6,0.8,fbm(o*30.0+seed,oc))*smoothstep(0.4,0.7,fbm(o*7.0+seed,oc)+0.3);
      lit+=city*lights*night*1.6;
      float fr=pow(1.0-clamp(dot(normalize(vN),V),0.0,1.0),3.0);
      lit+=atmo*fr*(0.12+1.3*smoothstep(-0.35,0.6,dot(normalize(vN),sunDir)));
      lit+=vec3(1.0,0.45,0.2)*exp(-ndl*ndl*60.0)*0.12*fr;
      gl_FragColor=vec4(lit*expo,1.0); }`,
  atmoFrag:`precision highp float; varying vec3 vO; varying vec3 vN; varying vec3 vP; uniform vec3 sunDir; uniform vec3 camPos; uniform vec3 atmo;
    void main(){ vec3 N=normalize(vN), V=normalize(camPos-vP); float ndl=dot(N,sunDir); float rim=1.0-abs(dot(N,V));
      float a=pow(rim,4.0)*smoothstep(-0.45,0.4,ndl); vec3 c=atmo*a*1.3+vec3(1.0,0.5,0.25)*exp(-ndl*ndl*30.0)*a*0.25; gl_FragColor=vec4(c,a); }`
};
function planetShaders(){ const S=BABYLON.Effect.ShadersStore; if(!S.vsPlanetVertexShader){ S.vsPlanetVertexShader=PLANET_GLSL.vert; S.vsPlanetFragmentShader=PLANET_GLSL.frag.replace('NOISE',PLANET_GLSL.noise); S.vsAtmoVertexShader=PLANET_GLSL.vert; S.vsAtmoFragmentShader=PLANET_GLSL.atmoFrag; } }
function planetMaterial(name){ planetShaders();
  const m=new BABYLON.ShaderMaterial(name,G.scene,{vertex:'vsPlanet',fragment:'vsPlanet'},{attributes:['position','normal'],uniforms:['world','worldViewProjection','sunDir','camPos','pa','pb','pc','pd','atmo','city','seed','kind','t','oct','expo','freq']});
  m.setFloat('expo',1); m.setFloat('freq',1); m.setFloat('t',0); m.setVector3('sunDir',new V3(0,1,0)); m.setVector3('camPos',V3.Zero()); return m; }
function atmoMaterial(name){ planetShaders(); const m=new BABYLON.ShaderMaterial(name,G.scene,{vertex:'vsAtmo',fragment:'vsAtmo'},{attributes:['position','normal'],uniforms:['world','worldViewProjection','sunDir','camPos','atmo'],needAlphaBlending:true});
  m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.backFaceCulling=false; m.disableDepthWrite=true; m.setVector3('sunDir',new V3(0,1,0)); m.setVector3('camPos',V3.Zero()); return m; }
// planet looks: palettes per kind; the battle's faction picks among them so each fight has its own sky
const PLANET_LOOKS=[
  {kind:0,pa:[.83,.66,.46],pb:[.6,.42,.28],pc:[.95,.88,.7],pd:[.75,.35,.2],atmo:[1,.72,.45]},   // amber gas giant
  {kind:0,pa:[.38,.55,.78],pb:[.2,.32,.55],pc:[.82,.9,1],pd:[.95,.95,1],atmo:[.45,.7,1]},       // blue gas giant
  {kind:0,pa:[.7,.45,.7],pb:[.4,.22,.45],pc:[.95,.8,.95],pd:[1,.6,.4],atmo:[.9,.55,1]},         // violet gas giant
  {kind:1,pa:[.3,.4,.2],pb:[.5,.42,.3],pc:[.78,.72,.62],pd:[.06,.2,.4],atmo:[.45,.68,1],city:[1,.75,.4]},   // garden world
  {kind:1,pa:[.62,.36,.2],pb:[.42,.22,.14],pc:[.85,.62,.4],pd:[.25,.12,.1],atmo:[1,.55,.35],city:[1,.5,.25]},     // desert world
  {kind:1,pa:[.22,.24,.26],pb:[.36,.33,.3],pc:[.6,.58,.55],pd:[.05,.08,.12],atmo:[.6,.75,.9],city:[.6,.9,1]},     // forge world
  {kind:2,pa:[.7,.78,.86],pb:[.42,.56,.7],pc:[.86,.93,1],pd:[.12,.22,.34],atmo:[.6,.85,1]},        // ice world
  {kind:2,pa:[.6,.76,.72],pb:[.32,.5,.5],pc:[.85,1,.95],pd:[.06,.2,.2],atmo:[.5,1,.85]}           // green ice
];
const FAC_PLANETS={voidsworn:[0,4,5],hegemony:[5,1,3],corsair:[4,0,2],chorus:[3,2,7],ithar:[1,6,7],deathless:[5,2,6]};
const FAC_WORLDS={voidsworn:[3,4],hegemony:[3,6],corsair:[4,3],chorus:[3,7],ithar:[6,3],deathless:[4,7]}; // the planet under the battlefield on Planet edge maps
const PLANET_SPOTS=[[5200,-5600,11800,2600],[-7800,-3200,9400,2200],[9800,-2600,-3600,3000],[-3600,-6400,-9800,2800],[2400,-4200,12600,1700]];
function lookTo(m,look,seed){ const c=a=>new C3(a[0],a[1],a[2]); m.setFloat('kind',look.kind); m.setColor3('pa',c(look.pa)); m.setColor3('pb',c(look.pb)); m.setColor3('pc',c(look.pc)); m.setColor3('pd',c(look.pd)); m.setColor3('atmo',c(look.atmo)); m.setColor3('city',c(look.city||[0,0,0])); m.setFloat('seed',seed); }
function setPlanetLook(look,seed,spot){ const p=G.planet, m=p&&p.material; if(!m||!m.setColor3) return; lookTo(m,look,seed);
  if(G.atmo&&G.atmo.material&&G.atmo.material.setColor3) G.atmo.material.setColor3('atmo',new C3(...look.atmo));
  if(spot){ const pos=new V3(spot[0],spot[1],spot[2]), s=spot[3]/2600; p.position.copyFrom(pos); p.scaling.setAll(s); if(G.atmo){ G.atmo.position.copyFrom(pos); G.atmo.scaling.setAll(s); } if(G.pring){ G.pring.position.copyFrom(pos); G.pring.scaling.setAll(s); G.pring.setEnabled(look.kind===0&&seed%1<.6); } } }
// each battle composes its own backdrop: planet type, palette, size and position from the enemy faction and a seed
function composeBackdrop(fac){ try{ const r=Math.random, ids=FAC_PLANETS[fac]||[0,1,3], look=PLANET_LOOKS[ids[Math.floor(r()*ids.length)]];
    setPlanetLook(look,r()*10,PLANET_SPOTS[Math.floor(r()*PLANET_SPOTS.length)]); }catch(e){ console.warn('backdrop',e); } }
// the planet whose edge the battle is fought over: the same shader, close up, with more octaves for the detail
function nearPlanetMaterial(fac,look){ const m=planetMaterial('nearPlanetM'), ids=FAC_WORLDS[fac]||[3]; lookTo(m,PLANET_LOOKS[look!=null&&PLANET_LOOKS[look]?look:ids[Math.floor(Math.random()*ids.length)]],Math.random()*10); m.setFloat('oct',G.mobile?6:8); m.setFloat('expo',.95); m.setFloat('freq',3.2); G.nearMats=[m]; return m; }

// ---------- engine plumes: a static fade from the nozzle to the tip, with plasma streaks scrolling down its length ----------
// (cylinder UVs: u runs around the cone, v along it, so the streaks vary with u and the fade with v)
function plumeFadeTex(){ if(G.tex.plumeFade) return G.tex.plumeFade; G.tex.plumeFade=dynTex('plumeFade2',16,128,(g,w,h)=>{ const img=g.createImageData(w,h), d=img.data;
    for(let y=0;y<h;y++){ const v=1-y/(h-1), a=Math.pow(v,1.6)*(1-Math.pow(v,24)*.35); for(let x=0;x<w;x++){ const o=(y*w+x)*4; d[o]=d[o+1]=d[o+2]=255; d[o+3]=a*255; } } g.putImageData(img,0,0); });
  G.tex.plumeFade.wrapU=G.tex.plumeFade.wrapV=BABYLON.Texture.CLAMP_ADDRESSMODE; return G.tex.plumeFade; }
function plumeTex(){ if(G.tex.plume) return G.tex.plume; G.tex.plume=dynTex('plumeT2',64,128,(g,w,h)=>{ const img=g.createImageData(w,h), d=img.data, r=seeded(77);
    const cols=[...Array(16)].map(()=>r()), ph=[...Array(16)].map(()=>r()*6.28);
    for(let y=0;y<h;y++) for(let x=0;x<w;x++){ const u=x/w, v=y/h, k=Math.floor(u*16); const st=.55+.45*cols[k]*(.5+.5*Math.sin(v*Math.PI*8+ph[k])); const l=Math.max(0,Math.min(1,st)); const o=(y*w+x)*4; d[o]=d[o+1]=d[o+2]=l*255; d[o+3]=255; } g.putImageData(img,0,0); });
  G.tex.plume.wrapU=G.tex.plume.wrapV=BABYLON.Texture.WRAP_ADDRESSMODE; G.tex.plume.hasAlpha=false; return G.tex.plume; }
function plumeMaterial(m,col){ m.opacityTexture=plumeFadeTex(); m.emissiveTexture=plumeTex(); m.emissiveColor=col; return m; }

// ---------- nebula banks: domain-warped emission clouds. High and Ultra animate them live; phones bake each one into a texture once ----------
const NEB_GLSL={
  vert:`precision highp float; attribute vec3 position; attribute vec2 uv; uniform mat4 worldViewProjection; varying vec2 vUV; void main(){ vUV=uv; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  body:`vec2 p=vUV-0.5; float r=length(p)*2.0;
      vec3 q=vec3(p*2.6,seed); vec3 w=vec3(fbm(q+vec3(0.0,0.0,t*0.01),5),fbm(q+vec3(5.2,1.3,t*0.012),5),0.0);
      float n=fbm(q+w*1.8,6); float fall=smoothstep(1.0,0.15,r);
      float dens=smoothstep(0.35,0.85,n)*fall; float hot=smoothstep(0.62,0.95,n)*fall;
      vec3 c=mix(ca,cb,smoothstep(0.4,0.9,n))*dens+cb*hot*0.8;`,
};
NEB_GLSL.frag=`precision highp float; varying vec2 vUV; uniform vec3 ca; uniform vec3 cb; uniform float seed; uniform float t; uniform float alpha;
    NOISE
    void main(){ ${NEB_GLSL.body} if(r>1.0) discard; gl_FragColor=vec4(c*alpha*1.6,dens*alpha); }`;
NEB_GLSL.bake=`precision highp float; varying vec2 vUV; uniform vec3 ca; uniform vec3 cb; uniform float seed; const float t=0.0;
    NOISE
    void main(){ ${NEB_GLSL.body} gl_FragColor=vec4(c*1.6,dens*step(r,1.0)); }`;
function nebShaders(){ const S=BABYLON.Effect.ShadersStore; if(!S.vsNebVertexShader){ S.vsNebVertexShader=NEB_GLSL.vert; S.vsNebFragmentShader=NEB_GLSL.frag.replace('NOISE',PLANET_GLSL.noise); S.vsNebBakePixelShader=NEB_GLSL.bake.replace('NOISE',PLANET_GLSL.noise); } }
function nebulaMaterial(name,ca,cb,alpha,seed){ nebShaders();
  const m=new BABYLON.ShaderMaterial(name,G.scene,{vertex:'vsNeb',fragment:'vsNeb'},{attributes:['position','uv'],uniforms:['worldViewProjection','ca','cb','seed','t','alpha'],needAlphaBlending:true});
  m.setColor3('ca',ca); m.setColor3('cb',cb); m.setFloat('alpha',alpha); m.setFloat('seed',seed); m.setFloat('t',0); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.backFaceCulling=false; m.disableDepthWrite=true; return m; }
// phones: render the same cloud shader into a 256 texture once (re-baked when the battle's colours change), then draw it as a plain additive sprite
function bakedNebula(i,ca,cb,seed){ nebShaders(); try{ const pt=new BABYLON.ProceduralTexture('nebBake'+i,256,'vsNebBake',G.scene,null,true);
    pt.setColor3('ca',ca); pt.setColor3('cb',cb); pt.setFloat('seed',seed); pt.refreshRate=0; pt.hasAlpha=true; return pt; }catch(e){ console.warn('nebula bake',e); return null; } }
function bakedNebulaMat(i,ca,cb,alpha,seed){ const tx=bakedNebula(i,ca,cb,seed); if(!tx) return null; const m=new BABYLON.StandardMaterial('nebBakeM'+i,G.scene); m.disableLighting=true; m.diffuseColor=C3.Black(); m.specularColor=C3.Black();
  m.emissiveTexture=tx; m.opacityTexture=tx; m.emissiveColor=new C3(1,1,1); m.alpha=Math.min(1,alpha*3); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.backFaceCulling=false; m.disableDepthWrite=true; m._bake=tx; return m; }
function rebakeNebula(m,ca,cb,seed){ const tx=m&&m._bake; if(!tx) return; tx.setColor3('ca',ca); tx.setColor3('cb',cb); tx.setFloat('seed',seed); tx.resetRefreshCounter(); }

// ---------- shader fireballs: a noise-displaced sphere that blooms white-hot, then cools through orange to smoke-dark ----------
const FIRE_GLSL={
  vert:`precision highp float; attribute vec3 position; attribute vec3 normal; uniform mat4 world; uniform mat4 worldViewProjection; uniform float t; uniform float seed; varying vec3 vO; varying vec3 vN; varying vec3 vP; varying float vD;
    NOISE
    void main(){ vec3 o=normalize(position); float d=fbm(o*2.6+vec3(seed,seed*0.7,t*1.5),4); vD=d; vec3 p=position*(0.72+d*0.75);
      vO=o; vN=normalize((world*vec4(normal,0.0)).xyz); vP=(world*vec4(p,1.0)).xyz; gl_Position=worldViewProjection*vec4(p,1.0); }`,
  frag:`precision highp float; varying vec3 vO; varying vec3 vN; varying vec3 vP; varying float vD; uniform vec3 camPos; uniform float t; uniform float seed; uniform vec3 tint;
    NOISE
    void main(){ vec3 V=normalize(camPos-vP); float fac=abs(dot(normalize(vN),V));
      float n=fbm(vO*4.5+vec3(seed,t*2.0,-t*1.3),5); float n2=fbm(vO*11.0+vec3(-t*3.0,seed,t),3);
      float heat=clamp(1.05-t*1.25+(n-0.5)*1.2+(n2-0.5)*0.5+fac*0.3-(1.0-vD)*0.45,0.0,1.0);
      vec3 c=heat>0.72?mix(vec3(1.0,0.48,0.12),vec3(1.0,0.78,0.42),(heat-0.72)/0.28):heat>0.38?mix(vec3(0.62,0.12,0.03),vec3(1.0,0.55,0.16),(heat-0.38)/0.34):mix(vec3(0.0),vec3(0.62,0.12,0.03),heat/0.38);
      c=mix(c,c*tint,0.35);
      float a=smoothstep(0.0,0.08,t)*(1.0-smoothstep(0.55,1.0,t))*smoothstep(0.3,0.58,n+0.2*fac+0.15*n2)*(0.55+0.45*fac);
      vec3 smoke=vec3(0.07,0.06,0.055)*(0.6+0.8*n);
      float hot=max(smoothstep(0.18,0.5,heat),1.0-smoothstep(0.25,0.55,t)); vec3 rgb=mix(smoke,c*(0.6+heat*2.4),hot);
      gl_FragColor=vec4(rgb,a*mix(0.92,0.7,1.0-hot)); }`
};
function fireballFx(pos,size,dur=1.1,tint){ try{ if(!G.scene) return; const S=BABYLON.Effect.ShadersStore; if(!S.vsFireVertexShader){ S.vsFireVertexShader=FIRE_GLSL.vert.replace('NOISE',PLANET_GLSL.noise); S.vsFireFragmentShader=FIRE_GLSL.frag.replace('NOISE',PLANET_GLSL.noise); }
    if(!G.fireBase||G.fireBase.isDisposed()){ G.fireBase=MB.CreateSphere('fireBase',{diameter:2,segments:G.quality==='medium'?14:28},G.scene); G.fireBase.isVisible=false; G.fireBase.isPickable=false; }
    const e=fxShPool('fireball',()=>{ const m=new BABYLON.ShaderMaterial('fireM',G.scene,{vertex:'vsFire',fragment:'vsFire'},{attributes:['position','normal'],uniforms:['world','worldViewProjection','t','seed','camPos','tint'],needAlphaBlending:true});
      m.alphaMode=BABYLON.Engine.ALPHA_COMBINE; m.disableDepthWrite=true; m.backFaceCulling=true; const sp=G.fireBase.clone('fire'); sp.isVisible=true; sp.material=m; try{ G.glow.addExcludedMesh(sp); }catch(e){} return {mesh:sp,mat:m}; }); /* v53-I: pooled mesh and material */
    const m=e.mat, sp=e.mesh; m.setFloat('seed',Math.random()*40); m.setColor3('tint',tint||new C3(1,1,1)); m.setFloat('t',0); m.setVector3('camPos',G.cam.position); sp.position.copyFrom(pos); sp.rotation.set(Math.random()*6,Math.random()*6,0); sp.scaling.setAll(size*.35);
    const t0=G.time, D=dur*Math.max(.3,SPEED); const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/D; if(k>=1||sp.isDisposed()){ G.scene.onBeforeRenderObservable.remove(obs); e.release(); return; }
      m.setFloat('t',k); m.setVector3('camPos',G.cam.position); sp.scaling.setAll(size*(.35+.9*Math.pow(k,.45))); }); }catch(e){ console.warn('fireball',e); } }

// ---------- shader beams: a white-hot core inside a coloured sheath, with energy crawling along it ----------
const BEAM_GLSL={
  vert:`precision highp float; attribute vec3 position; attribute vec3 normal; attribute vec2 uv; uniform mat4 world; uniform mat4 worldViewProjection; varying vec2 vUV; varying vec3 vN; varying vec3 vP;
    void main(){ vUV=uv; vN=normalize((world*vec4(normal,0.0)).xyz); vP=(world*vec4(position,1.0)).xyz; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  frag:`precision highp float; varying vec2 vUV; varying vec3 vN; varying vec3 vP; uniform vec3 camPos; uniform vec3 col; uniform float t; uniform float len; uniform float fade;
    NOISE
    void main(){ vec3 V=normalize(camPos-vP); float f=abs(dot(normalize(vN),V)); float core=pow(f,6.0); float sheath=pow(f,1.6);
      float n=fbm(vec3(vUV.y*len*0.12-t*14.0,vUV.x*6.0,t*3.0),3); float crawl=0.55+0.9*n;
      float ends=smoothstep(0.0,0.02,vUV.y)*smoothstep(1.0,0.97,vUV.y);
      vec3 c=col*sheath*crawl*1.25+mix(col,vec3(1.0,0.97,0.9),0.6)*core*1.6;
      gl_FragColor=vec4(c*fade*ends,(sheath*0.6+core)*fade*ends); }`
};
function beamMaterial(col){ const S=BABYLON.Effect.ShadersStore; if(!S.vsBeamVertexShader){ S.vsBeamVertexShader=BEAM_GLSL.vert; S.vsBeamFragmentShader=BEAM_GLSL.frag.replace('NOISE',PLANET_GLSL.noise); }
  const m=new BABYLON.ShaderMaterial('beamM',G.scene,{vertex:'vsBeam',fragment:'vsBeam'},{attributes:['position','normal','uv'],uniforms:['world','worldViewProjection','camPos','col','t','len','fade'],needAlphaBlending:true});
  m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; m.setColor3('col',col); m.setFloat('t',0); m.setFloat('len',10); m.setFloat('fade',1); m.setVector3('camPos',G.cam.position); return m; }

// ---------- frame time: p50/p90 per battle and quality level, logged at battle end ----------
const FRAMES={ft:[],draws:0,inst:null,h50:0,h100:0,max:0,by:{},
  tick(dt){ if(dt>0&&dt<3){ const ms=dt*1000; this.ft.push(ms); if(this.ft.length>3600) this.ft.splice(0,600); if(ms>this.max) this.max=ms;
      if(ms>50&&!document.hidden){ this.h50++; if(ms>100){ this.h100++; const f=G.fxLast&&performance.now()-G.fxLast.t<1500?G.fxLast.k:'other'; this.by[f]=(this.by[f]||0)+1; } } } },
  reset(){ this.ft=[]; this.h50=0; this.h100=0; this.max=0; this.by={}; try{ if(!this.inst&&G.scene) this.inst=new BABYLON.SceneInstrumentation(G.scene); }catch(e){} },
  summary(){ const a=this.ft.slice().sort((x,y)=>x-y), q=p=>a.length?Math.round(a[Math.min(a.length-1,Math.floor(a.length*p))]*10)/10:null;
    let draws=null; try{ if(this.inst) draws=this.inst.drawCallsCounter.lastSecAverage||this.inst.drawCallsCounter.current; }catch(e){}
    return {p50:q(.5),p90:q(.9),p99:q(.99),max:Math.round(this.max),h50:this.h50,h100:this.h100,hitch:this.by,n:a.length,draws:draws==null?null:Math.round(draws),rw:G.engine?G.engine.getRenderWidth():0,rh:G.engine?G.engine.getRenderHeight():0,q:G.quality,mob:!!G.mobile}; } };

// per-frame updates for the shader library: rim strength and tactical ship scale follow the camera distance; planets and nebulae animate
function gfxTick(dt){ dt=dt||(G.engine?G.engine.getDeltaTime()/1000:.016); const cr=G.cam?G.cam.radius:250, k=Math.max(0,Math.min(1,(cr-130)/320));
  G.rimBoost=.5+1.25*k; G.tacScale=1+.38*Math.max(0,Math.min(1,(cr-170)/300)); G.hullEnergy=G.fxReduced?.55:1;
  const sunAt=pos=>G.sunPosW?G.sunPosW.subtract(pos).normalize():V3.Up();
  const p=G.planet&&G.planet.material; if(p&&p.setVector3){ p.setVector3('sunDir',sunAt(G.planet.position)); p.setVector3('camPos',G.cam.position); p.setFloat('t',G.time||0); }
  const a=G.atmo&&G.atmo.material; if(a&&a.setVector3){ a.setVector3('sunDir',sunAt(G.planet.position)); a.setVector3('camPos',G.cam.position); }
  if(G.nearPlanet&&!G.nearPlanet.isDisposed()){ const s=G.sun?G.sun.direction.scale(-1).add(new V3(-.55,.3,0)).normalize():sunAt(G.nearPlanet.position); for(const m of [G.nearPlanet.material,G.nearAtmo&&G.nearAtmo.material].concat((G.nearMats||[]).slice(1))) if(m&&m.setVector3&&!m._disposed){ m.setVector3('sunDir',s); m.setVector3('camPos',G.cam.position); if(m===G.nearPlanet.material) m.setFloat('t',G.time||0); } }
  if(G.tex.plume) G.tex.plume.vOffset=((G.time||0)*1.7)%1;
  // big blasts briefly flare the exposure and split the colour at the screen edges
  // v44.1: the flare rides bloom weight, not exposure: an exposure change re-dirties every material in the scene each frame
  try{ const pp=G.pipe; if(pp){ if(G.bloomBase==null) G.bloomBase=pp.bloomWeight; const k=Math.max(0,G.pulse||0), bw=G.bloomBase*(1+k*1.3); if(Math.abs(pp.bloomWeight-bw)>.003) pp.bloomWeight=bw; if(G.pipe.chromaticAberration&&G.pipe.chromaticAberrationEnabled) G.pipe.chromaticAberration.aberrationAmount=10+k*40; G.pulse=k>0?Math.max(0,k-(dt||.016)*2.4):0; } }catch(e){}
  if(G.nebMats&&!(G.fskip&1)) for(const m of G.nebMats) if(m.setFloat) m.setFloat('t',G.time||0); }

// ---------- shield collapse: the broken facing shatters into hexagonal shards that spin away and fade ----------
function shieldShatter(p,dir,col){ try{ if(!G.scene||G.fxReduced) return; const n=G.quality==='medium'?10:22;
    if(!G.shardBase||G.shardBase.isDisposed()){ const d=MB.CreateDisc('shardBase',{radius:.9,tessellation:6,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene); const m=emMat('shardM',SHIELD_C.scale(1.8),.85); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; d.material=m; d.isVisible=false; d.isPickable=false; try{ G.glow.addExcludedMesh(d); }catch(e){} G.shardBase=d; }
    if(col&&G.shardBase.material&&G.shardBase.material.emissiveColor) G.shardBase.material.emissiveColor=col.scale(1.8); // v45: shards take the shield's faction colour
    const side=new V3(-dir.z,0,dir.x), parts=[];
    for(let i=0;i<n;i++){ const s=G.shardBase.createInstance('shard'); s.isPickable=false; s.position.copyFrom(p.add(side.scale((Math.random()-.5)*6)).add(new V3(0,(Math.random()-.3)*4,0)));
      const v=dir.scale(4+Math.random()*10).add(side.scale((Math.random()-.5)*10)).add(new V3(0,(Math.random()-.2)*6,0)); s.rotation.set(Math.random()*6,Math.random()*6,Math.random()*6); const sc=.4+Math.random()*.9; s.scaling.setAll(sc);
      parts.push({s,v,spin:new V3(Math.random()*8,Math.random()*8,Math.random()*8),sc}); }
    const t0=G.time; const obs=G.scene.onBeforeRenderObservable.add(()=>{ const dt=G.engine.getDeltaTime()/1000, k=(G.time-t0)/(.9*Math.max(.3,SPEED));
      if(k>=1){ G.scene.onBeforeRenderObservable.remove(obs); parts.forEach(q=>q.s.dispose()); return; }
      for(const q of parts){ q.s.position.addInPlace(q.v.scale(dt)); q.v.scaleInPlace(1-dt*1.6); q.s.rotation.addInPlace(q.spin.scale(dt)); q.s.scaling.setAll(q.sc*(1-k*k)); } }); }catch(e){ console.warn('shatter',e); } }

// ---------- battle damage that burns into the hull ----------
// Damaged ships get their own copies of the hull and dark materials, so scorched plating and glowing cracks spread across that ship alone as its hull drops.
function shipDamageFx(v,hr){ try{ if(!v||!v.model||v.state!=='alive') return; const amt=Math.max(0,Math.min(1,(.8-hr)/.72)); if(amt<=0&&!v.dmgMats) return;
    if(v.lastDmg!=null&&Math.abs(v.lastDmg-amt)<.01) return; v.lastDmg=amt;
    if(!v.dmgMats){ const M=facMats(v.fac), map=new Map(); v.dmgMats=[]; const seed=(v.u&&v.u.id?String(v.u.id).split('').reduce((a,c)=>a+c.charCodeAt(0),0):Math.random()*100)%37;
      const srcs=[M.hull,M.dark,M.aiHull]; for(const m of v.model.meshes) if(m.material&&m.material._isAiHull&&!srcs.includes(m.material)) srcs.push(m.material);
      for(const src of srcs){ if(!src||!src._hullFx) continue; const c=src.clone(src.name+'_dmg');
        for(const k of ['albedoTexture','bumpTexture','metallicTexture','emissiveTexture','ambientTexture','opacityTexture','microSurfaceTexture','reflectivityTexture','lightmapTexture','reflectionTexture']){ if(c[k]!==src[k]){ const blank=c[k]; c[k]=src[k]||null; try{ if(blank&&blank!==src[k]&&!Object.values(G.tex).includes(blank)) blank.dispose(); }catch(e){} } } // clones of generated textures come back blank: share the originals
        const o=src._hullFx, opts=Object.assign(typeof hfxOpts==='function'?hfxOpts(o,v.fac):{rim:o.rim,str:o.str,style:o.style,ecol:o.ecol,wear:o.wear,seed:o.seed,energy:o.energy},{ai:o.ai,wcol:o.wcol,ring:o.ring,haz:o.haz,mtex:o.mtex}); let pl=c.pluginManager&&c.pluginManager.getPlugin&&c.pluginManager.getPlugin('HullFx');
        if(pl) Object.assign(pl,opts); else pl=new HullFxPlugin(c,opts); c._hullFx=pl; pl.dseed=seed; map.set(src,c); v.dmgMats.push(c); }
      for(const m of v.model.meshes) if(map.has(m.material)) m.material=map.get(m.material); }
    for(const c of v.dmgMats) if(c._hullFx) c._hullFx.dmg=amt; }catch(e){ console.warn('damage shading',e); } }
function disposeDamageMats(v){ try{ (v.dmgMats||[]).forEach(m=>m.dispose(false,false)); }catch(e){} v.dmgMats=null; }

// ---------- asteroid surfaces: dust, darker basalt and mineral veins over the rock texture, in each rock's own coordinates ----------
class RockFxPlugin extends BABYLON.MaterialPluginBase{
  constructor(material){ super(material,'RockFx',200,{ROCKFX:false}); this._enable(true); }
  prepareDefines(defines){ defines.ROCKFX=true; }
  getClassName(){ return 'RockFxPlugin'; }
  getCustomCode(type){
    if(type==='vertex') return {CUSTOM_VERTEX_DEFINITIONS:'#ifdef ROCKFX\nvarying vec3 vRfxL;\n#endif\n',CUSTOM_VERTEX_MAIN_END:'#ifdef ROCKFX\nvRfxL=positionUpdated;\n#endif\n'};
    if(type!=='fragment') return null;
    return {CUSTOM_FRAGMENT_DEFINITIONS:`
#ifdef ROCKFX
varying vec3 vRfxL;
float rfxH(vec3 p){ p=fract(p*0.3183099+vec3(0.71,0.113,0.419)); p*=17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
float rfxN(vec3 x){ vec3 i=floor(x); vec3 f=fract(x); f=f*f*(3.0-2.0*f);
  return mix(mix(mix(rfxH(i),rfxH(i+vec3(1,0,0)),f.x),mix(rfxH(i+vec3(0,1,0)),rfxH(i+vec3(1,1,0)),f.x),f.y),mix(mix(rfxH(i+vec3(0,0,1)),rfxH(i+vec3(1,0,1)),f.x),mix(rfxH(i+vec3(0,1,1)),rfxH(i+vec3(1,1,1)),f.x),f.y),f.z); }
#endif
`,CUSTOM_FRAGMENT_UPDATE_DIFFUSE:`
#ifdef ROCKFX
  { vec3 q=vRfxL*2.3; float a=rfxN(q)*0.6+rfxN(q*2.7)*0.28+rfxN(q*7.5)*0.12;
    float dust=smoothstep(0.45,0.75,a); float basalt=1.0-smoothstep(0.2,0.45,a);
    float vein=1.0-smoothstep(0.0,0.02,abs(rfxN(vRfxL*4.1+7.0)-0.5));
    baseColor.rgb*=mix(1.0,1.35,dust)*mix(1.0,0.5,basalt);
    baseColor.rgb=mix(baseColor.rgb,baseColor.rgb*vec3(1.2,0.98,0.85),vein*0.22); }
#endif
`}; }
}
function addRockFx(mat){ try{ if(mat&&!mat._rockFx) mat._rockFx=new RockFxPlugin(mat); }catch(e){ console.warn('rock shading',e); } }

// ---------- hyperspace rift: a ring of light tears open where a ship drops in, swirls, and snaps shut behind it ----------
const RIFT_GLSL={vert:`precision highp float; attribute vec3 position; attribute vec2 uv; uniform mat4 worldViewProjection; varying vec2 vUV; void main(){ vUV=uv; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  frag:`precision highp float; varying vec2 vUV; uniform vec3 col; uniform float t; uniform float seed;
    NOISE
    void main(){ vec2 p=vUV-0.5; float r=length(p)*2.0; float ang=atan(p.y,p.x);
      float open=sin(clamp(t,0.0,1.0)*3.14159); float R=0.25+0.6*open;
      float sw=fbm(vec3(cos(ang)*2.0,sin(ang)*2.0,r*3.0-t*4.0+seed),4);
      float ring=exp(-pow((r-R+0.1*(sw-0.5))*14.0,2.0))*(0.6+0.8*sw);
      float inner=smoothstep(R,0.0,r)*open*(0.15+0.35*sw);
      float a=(ring*0.75+inner*0.3)*open; if(r>1.0) a=0.0;
      gl_FragColor=vec4(col*a*1.1+vec3(1.0)*ring*open*0.15,a*0.8); }`};
function warpRift(pos,fwd,size,col){ try{ if(!G.scene||G.fxReduced) return; const S=BABYLON.Effect.ShadersStore; if(!S.vsRiftVertexShader){ S.vsRiftVertexShader=RIFT_GLSL.vert; S.vsRiftFragmentShader=RIFT_GLSL.frag.replace('NOISE',PLANET_GLSL.noise); }
    const e=fxShPool('rift',()=>{ const pl=MB.CreatePlane('rift',{size:1,sideOrientation:BABYLON.Mesh.DOUBLESIDE},G.scene); pl.isPickable=false;
      const m=new BABYLON.ShaderMaterial('riftM',G.scene,{vertex:'vsRift',fragment:'vsRift'},{attributes:['position','uv'],uniforms:['worldViewProjection','col','t','seed'],needAlphaBlending:true});
      m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.disableDepthWrite=true; m.backFaceCulling=false; pl.material=m; try{ G.glow.addExcludedMesh(pl); }catch(e){} return {mesh:pl,mat:m}; }); /* v53-I: pooled mesh and material */
    const pl=e.mesh, m=e.mat; pl.position.copyFrom(pos); pl.rotation.set(0,0,0); pl.lookAt(pos.add(fwd)); pl.scaling.setAll(size); m.setColor3('col',col); m.setFloat('seed',Math.random()*30); m.setFloat('t',0);
    const t0=G.time, D=1.15*Math.max(.4,SPEED); const obs=G.scene.onBeforeRenderObservable.add(()=>{ const k=(G.time-t0)/D; if(k>=1||pl.isDisposed()){ G.scene.onBeforeRenderObservable.remove(obs); e.release(); return; } m.setFloat('t',k); }); }catch(e){ console.warn('rift',e); } }
