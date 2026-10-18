// ---------- v42 graphics: GPU shader library ----------
// Everything here is generated on the GPU from code (no downloaded art). Every effect has a cheaper path on Medium (phones).

// Hull rim light: a faction-coloured fresnel edge on hulls, brighter as the camera pulls back, so ships read as silhouettes
// against bright nebulae instead of dark blobs. Runs inside Babylon's PBR shader, so it costs no extra draw calls.
class HullFxPlugin extends BABYLON.MaterialPluginBase{
  constructor(material,rim,str){ super(material,'HullFx',210,{HULLFX:false}); this.rim=rim; this.str=str; this._enable(true); }
  prepareDefines(defines){ defines.HULLFX=true; }
  getClassName(){ return 'HullFxPlugin'; }
  getUniforms(){ return {ubo:[{name:'hfxRim',size:3,type:'vec3'},{name:'hfxK',size:2,type:'vec2'}],fragment:'#ifdef HULLFX\nuniform vec3 hfxRim;\nuniform vec2 hfxK;\n#endif\n'}; }
  bindForSubMesh(ubo){ ubo.updateColor3('hfxRim',this.rim); ubo.updateFloat2('hfxK',this.str*(G.rimBoost||1),G.time||0); }
  getCustomCode(type){ if(type!=='fragment') return null; return {CUSTOM_FRAGMENT_BEFORE_FRAGCOLOR:`
#ifdef HULLFX
  vec3 hfxV=normalize(vEyePosition.xyz-vPositionW);
  float hfxF=pow(1.0-clamp(abs(dot(normalW,hfxV)),0.0,1.0),2.6);
  finalColor.rgb+=hfxRim*hfxF*hfxK.x;
#endif
`}; }
}
function addHullFx(M,fac){ try{ const P=FAC3D[fac]||FAC3D.hegemony; const rim=C3.Lerp(P.eng,new C3(.75,.85,1),.45);
    for(const [k,s] of [['hull',.85],['dark',.55],['steel',.45],['trim',.35]]) if(M[k]&&!M[k]._hullFx){ M[k]._hullFx=new HullFxPlugin(M[k],rim,s); } }catch(e){ console.warn('rim light unavailable',e); } }

// ---------- procedural planets: gas giants, rocky worlds and ice worlds, lit by the sun with scattering at the limb ----------
const PLANET_GLSL={
  vert:`precision highp float; attribute vec3 position; attribute vec3 normal; uniform mat4 world; uniform mat4 worldViewProjection; varying vec3 vO; varying vec3 vN; varying vec3 vP;
    void main(){ vO=normalize(position); vN=normalize((world*vec4(normal,0.0)).xyz); vP=(world*vec4(position,1.0)).xyz; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  noise:`float h3(vec3 p){ p=fract(p*0.3183099+vec3(0.71,0.113,0.419)); p*=17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
    float n3(vec3 x){ vec3 i=floor(x); vec3 f=fract(x); f=f*f*(3.0-2.0*f);
      return mix(mix(mix(h3(i),h3(i+vec3(1,0,0)),f.x),mix(h3(i+vec3(0,1,0)),h3(i+vec3(1,1,0)),f.x),f.y),mix(mix(h3(i+vec3(0,0,1)),h3(i+vec3(1,0,1)),f.x),mix(h3(i+vec3(0,1,1)),h3(i+vec3(1,1,1)),f.x),f.y),f.z); }
    float fbm(vec3 p,int oct){ float v=0.0,a=0.5; for(int i=0;i<7;i++){ if(i>=oct) break; v+=a*n3(p); p=p*2.02+vec3(1.3,7.1,4.7); a*=0.5; } return v; }`,
  frag:`precision highp float; varying vec3 vO; varying vec3 vN; varying vec3 vP;
    uniform vec3 sunDir; uniform vec3 camPos; uniform vec3 pa; uniform vec3 pb; uniform vec3 pc; uniform vec3 pd; uniform vec3 atmo; uniform vec3 city; uniform float seed; uniform float kind; uniform float t; uniform float oct;
    NOISE
    void main(){
      vec3 o=vO, N=normalize(vN), V=normalize(camPos-vP); int oc=int(oct);
      float ndl=dot(N,sunDir), day=smoothstep(-0.12,0.32,ndl);
      vec3 col; float land=0.0, spec=0.0;
      if(kind<0.5){ // gas giant: warped latitude bands with a storm
        float w=fbm(o*vec3(2.0,6.0,2.0)+seed,oc)*0.9;
        float lat=o.y*7.0+w*1.6+0.35*sin(o.x*3.0+o.z*2.0+seed*4.0);
        float b=0.5+0.5*sin(lat*2.3)+0.25*fbm(vec3(lat*1.7,o.x*0.5,o.z*0.5)+seed,oc);
        col=mix(pa,pb,smoothstep(0.15,0.85,b)); col=mix(col,pc,smoothstep(0.62,0.95,fbm(o*vec3(1.0,14.0,1.0)+seed*2.0,oc))*0.6);
        vec3 sc=normalize(vec3(0.6,-0.25,0.75)); float st=smoothstep(0.17,0.0,length(o-sc)+0.04*fbm(o*12.0,oc)); col=mix(col,pd,st*0.85);
      } else if(kind<1.5){ // rocky world: continents, oceans, ice caps
        float h=fbm(o*2.4+seed,oc)+0.25*fbm(o*9.0+seed*3.0,oc);
        land=smoothstep(0.52,0.56,h);
        vec3 sea=mix(pd*0.45,pd,smoothstep(0.3,0.52,h));
        vec3 gr=mix(pa,pb,smoothstep(0.56,0.8,h)); gr=mix(gr,pc,smoothstep(0.75,0.95,h));
        col=mix(sea,gr,land); float cap=smoothstep(0.72,0.86,abs(o.y)+0.08*fbm(o*6.0,oc)); col=mix(col,vec3(0.92,0.95,1.0),cap);
        spec=(1.0-land)*(1.0-cap);
      } else { // ice world: cracked pale crust with dark rifts
        float h=fbm(o*3.0+seed,oc); float cr=1.0-smoothstep(0.0,0.035,abs(fbm(o*5.0+seed*2.0,oc)-0.5));
        col=mix(pa,pb,h); col=mix(col,pd,cr*0.7); spec=0.4;
      }
      // clouds drift with time
      float cl=smoothstep(0.55,0.8,fbm(o*4.0+vec3(t*0.004,0.0,seed),oc))*(kind>0.5&&kind<1.5?0.9:0.25);
      col=mix(col,vec3(1.0),cl*0.85);
      vec3 lit=col*(0.03+1.25*day*max(ndl,0.0)+0.15*day);
      vec3 H=normalize(sunDir+V); lit+=vec3(1.0,0.92,0.8)*pow(max(dot(N,H),0.0),60.0)*spec*day*0.6;
      // city lights on the night side of rocky worlds
      float night=1.0-smoothstep(-0.25,0.05,ndl); float lights=land*(1.0-cl)*smoothstep(0.62,0.8,fbm(o*28.0+seed,oc));
      lit+=city*lights*night*1.4;
      // atmosphere: scattering at the limb, brighter on the sunlit side, a warm band along the terminator
      float fr=pow(1.0-clamp(dot(N,V),0.0,1.0),3.2);
      lit+=atmo*fr*(0.15+1.3*smoothstep(-0.35,0.6,ndl));
      lit+=vec3(1.0,0.45,0.2)*exp(-ndl*ndl*60.0)*0.12*fr;
      gl_FragColor=vec4(lit,1.0); }`,
  atmoFrag:`precision highp float; varying vec3 vO; varying vec3 vN; varying vec3 vP; uniform vec3 sunDir; uniform vec3 camPos; uniform vec3 atmo;
    void main(){ vec3 N=normalize(vN), V=normalize(camPos-vP); float ndl=dot(N,sunDir); float rim=1.0-abs(dot(N,V));
      float a=pow(rim,2.4)*smoothstep(-0.45,0.4,ndl); vec3 c=atmo*a*1.6+vec3(1.0,0.5,0.25)*exp(-ndl*ndl*30.0)*a*0.25; gl_FragColor=vec4(c,a); }`
};
function planetShaders(){ const S=BABYLON.Effect.ShadersStore; if(!S.vsPlanetVertexShader){ S.vsPlanetVertexShader=PLANET_GLSL.vert; S.vsPlanetFragmentShader=PLANET_GLSL.frag.replace('NOISE',PLANET_GLSL.noise); S.vsAtmoVertexShader=PLANET_GLSL.vert; S.vsAtmoFragmentShader=PLANET_GLSL.atmoFrag; } }
function planetMaterial(name){ planetShaders();
  const m=new BABYLON.ShaderMaterial(name,G.scene,{vertex:'vsPlanet',fragment:'vsPlanet'},{attributes:['position','normal'],uniforms:['world','worldViewProjection','sunDir','camPos','pa','pb','pc','pd','atmo','city','seed','kind','t','oct']});
  return m; }
function atmoMaterial(name){ planetShaders(); const m=new BABYLON.ShaderMaterial(name,G.scene,{vertex:'vsAtmo',fragment:'vsAtmo'},{attributes:['position','normal'],uniforms:['world','worldViewProjection','sunDir','camPos','atmo'],needAlphaBlending:true});
  m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.backFaceCulling=false; m.disableDepthWrite=true; return m; }
// planet looks: palettes per kind; the battle's faction picks among them so each fight has its own sky
const PLANET_LOOKS=[
  {kind:0,pa:[.83,.66,.46],pb:[.6,.42,.28],pc:[.95,.88,.7],pd:[.75,.35,.2],atmo:[1,.72,.45]},   // amber gas giant
  {kind:0,pa:[.38,.55,.78],pb:[.2,.32,.55],pc:[.82,.9,1],pd:[.95,.95,1],atmo:[.45,.7,1]},       // blue gas giant
  {kind:0,pa:[.7,.45,.7],pb:[.4,.22,.45],pc:[.95,.8,.95],pd:[1,.6,.4],atmo:[.9,.55,1]},         // violet gas giant
  {kind:1,pa:[.34,.42,.22],pb:[.5,.42,.3],pc:[.78,.72,.62],pd:[.08,.22,.42],atmo:[.45,.68,1],city:[1,.75,.4]},   // garden world
  {kind:1,pa:[.62,.36,.2],pb:[.42,.22,.14],pc:[.85,.62,.4],pd:[.25,.12,.1],atmo:[1,.55,.35],city:[1,.5,.25]},     // desert world
  {kind:1,pa:[.22,.24,.26],pb:[.36,.33,.3],pc:[.6,.58,.55],pd:[.05,.08,.12],atmo:[.6,.75,.9],city:[.6,.9,1]},     // forge world
  {kind:2,pa:[.82,.88,.95],pb:[.62,.75,.88],pc:[1,1,1],pd:[.2,.32,.45],atmo:[.6,.85,1]},        // ice world
  {kind:2,pa:[.7,.85,.8],pb:[.45,.65,.62],pc:[1,1,1],pd:[.12,.3,.28],atmo:[.5,1,.85]}           // green ice
];
const FAC_PLANETS={voidsworn:[0,4,5],hegemony:[5,1,3],corsair:[4,0,2],chorus:[3,2,7],ithar:[1,6,7],deathless:[5,2,6]};
const PLANET_SPOTS=[[5200,-5600,11800,2600],[-7800,-3200,9400,2200],[9800,-2600,-3600,3000],[-3600,-6400,-9800,2800],[2400,-4200,12600,1700]];
function setPlanetLook(look,seed,spot){ const p=G.planet, m=p&&p.material; if(!m||!m.setColor3) return; const c=a=>new C3(a[0],a[1],a[2]);
  m.setFloat('kind',look.kind); m.setColor3('pa',c(look.pa)); m.setColor3('pb',c(look.pb)); m.setColor3('pc',c(look.pc)); m.setColor3('pd',c(look.pd)); m.setColor3('atmo',c(look.atmo)); m.setColor3('city',c(look.city||[0,0,0])); m.setFloat('seed',seed);
  if(G.atmo&&G.atmo.material&&G.atmo.material.setColor3) G.atmo.material.setColor3('atmo',c(look.atmo));
  if(spot){ const pos=new V3(spot[0],spot[1],spot[2]), s=spot[3]/2600; p.position.copyFrom(pos); p.scaling.setAll(s); if(G.atmo){ G.atmo.position.copyFrom(pos); G.atmo.scaling.setAll(s); } if(G.pring){ G.pring.position.copyFrom(pos); G.pring.scaling.setAll(s); G.pring.setEnabled(look.kind===0&&seed%1<.6); } } }
// each battle composes its own backdrop: planet type, palette, size and position from the enemy faction and a seed
function composeBackdrop(fac){ try{ const r=Math.random, ids=FAC_PLANETS[fac]||[0,1,3], look=PLANET_LOOKS[ids[Math.floor(r()*ids.length)]];
    setPlanetLook(look,r()*10,PLANET_SPOTS[Math.floor(r()*PLANET_SPOTS.length)]); }catch(e){ console.warn('backdrop',e); } }

// ---------- engine plumes: a scrolling plasma streak texture, shared by every faction's plume material ----------
function plumeTex(){ if(G.tex.plume) return G.tex.plume; G.tex.plume=dynTex('plumeT',128,256,(g,w,h)=>{ const img=g.createImageData(w,h), d=img.data, r=seeded(77);
    const cols=[...Array(16)].map(()=>r());
    for(let y=0;y<h;y++) for(let x=0;x<w;x++){ const u=x/w, v=y/h; const core=Math.exp(-Math.pow((u-.5)*3.2,2)); const streak=.55+.45*cols[Math.floor(u*16)]*(.6+.4*Math.sin(v*Math.PI*6+cols[Math.floor(u*16)]*9));
      const a=Math.max(0,Math.min(1,core*streak*1.25)); const o=(y*w+x)*4; d[o]=d[o+1]=d[o+2]=255; d[o+3]=a*255; } g.putImageData(img,0,0); });
  G.tex.plume.wrapV=BABYLON.Texture.WRAP_ADDRESSMODE; return G.tex.plume; }

// ---------- nebula banks: animated, domain-warped emission clouds on High and Ultra (Medium keeps the cheap textures) ----------
const NEB_GLSL={
  vert:`precision highp float; attribute vec3 position; attribute vec2 uv; uniform mat4 worldViewProjection; varying vec2 vUV; void main(){ vUV=uv; gl_Position=worldViewProjection*vec4(position,1.0); }`,
  frag:`precision highp float; varying vec2 vUV; uniform vec3 ca; uniform vec3 cb; uniform float seed; uniform float t; uniform float alpha;
    NOISE
    void main(){ vec2 p=vUV-0.5; float r=length(p)*2.0; if(r>1.0) discard;
      vec3 q=vec3(p*2.6,seed); vec3 w=vec3(fbm(q+vec3(0.0,0.0,t*0.01),5),fbm(q+vec3(5.2,1.3,t*0.012),5),0.0);
      float n=fbm(q+w*1.8,6); float fall=smoothstep(1.0,0.15,r);
      float dens=smoothstep(0.35,0.85,n)*fall; float hot=smoothstep(0.62,0.95,n)*fall;
      vec3 c=mix(ca,cb,smoothstep(0.4,0.9,n))*dens+cb*hot*0.8;
      gl_FragColor=vec4(c*alpha*1.6,dens*alpha); }`
};
function nebulaMaterial(name,ca,cb,alpha,seed){ const S=BABYLON.Effect.ShadersStore; if(!S.vsNebVertexShader){ S.vsNebVertexShader=NEB_GLSL.vert; S.vsNebFragmentShader=NEB_GLSL.frag.replace('NOISE',PLANET_GLSL.noise); }
  const m=new BABYLON.ShaderMaterial(name,G.scene,{vertex:'vsNeb',fragment:'vsNeb'},{attributes:['position','uv'],uniforms:['worldViewProjection','ca','cb','seed','t','alpha'],needAlphaBlending:true});
  m.setColor3('ca',ca); m.setColor3('cb',cb); m.setFloat('alpha',alpha); m.setFloat('seed',seed); m.setFloat('t',0); m.alphaMode=BABYLON.Engine.ALPHA_ADD; m.backFaceCulling=false; m.disableDepthWrite=true; return m; }

// per-frame updates for the shader library: rim strength and tactical ship scale follow the camera distance; planets and nebulae animate
function gfxTick(){ const cr=G.cam?G.cam.radius:250, k=Math.max(0,Math.min(1,(cr-130)/320));
  G.rimBoost=.5+1.25*k; G.tacScale=1+.32*Math.max(0,Math.min(1,(cr-210)/260));
  const p=G.planet&&G.planet.material; if(p&&p.setVector3){ p.setVector3('sunDir',G.sunPosW?G.sunPosW.subtract(G.planet.position).normalize():V3.Up()); p.setVector3('camPos',G.cam.position); p.setFloat('t',G.time||0); }
  const a=G.atmo&&G.atmo.material; if(a&&a.setVector3){ a.setVector3('sunDir',G.sunPosW?G.sunPosW.subtract(G.planet.position).normalize():V3.Up()); a.setVector3('camPos',G.cam.position); }
  if(G.tex.plume) G.tex.plume.vOffset=((G.time||0)*1.7)%1;
  if(G.nebMats&&!(G.fskip&1)) for(const m of G.nebMats) m.setFloat('t',G.time||0); }
