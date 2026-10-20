// ---------- sound (v53-F) ----------
// The page stays one self-contained file: recorded clips are base64 in sfx_data.js, everything else is synthesised here.
// How it works: on the first user gesture the clips are decoded once, then every cue not fully covered by clips is rendered
// once, offline, into a few round-robin AudioBuffers (OfflineAudioContext, 32 kHz). Each play() resolves a cue to layers
// (clips from SFX.MAP and/or its synth take) under one voice: sources -> gain -> stereo pan -> bus.
// Buses (weapons, impacts, explosions, ui, ambient) feed a short dark generated reverb send and a master chain of
// gentle compressor -> brickwall limiter -> trim. No per-frame JS runs for audio.
// More clips: add keys to sfx_data.js and layers to SFX.MAP, or SFX.setSample(cue, audioBuffer) / await SFX.loadSample(cue, url).
// Every legacy method keeps its signature; each takes an optional trailing source (world position, unit, view, {q,r} or {pan}).
const SFX={ctx:null,master:null,bus:{},chain:null,bank:{},peaks:{},custom:{},ready:false,last:{},active:[],byCue:{},salvo:{},tailT:0,noise:null,vol:.8,SR:32000,_rendering:null,_amb:null,
  // ---- lifecycle ----
  init(){ if(this.ctx) return; try{ const C=window.AudioContext||window.webkitAudioContext; if(!C) return; this.ctx=new C({latencyHint:'interactive'}); }catch(e){ this.ctx=null; return; }
    const c=this.ctx; this.getVol();
    try{ this.noise=this._makeNoise(c); this.chain=this._chain(c,c.destination,this._makeIR(c)); this.master=this.chain.m; this.bus=this.chain.bus;
      this.master.gain.value=G.sfxOn?this._mg():0; this.ambient(); }catch(e){ console.warn('sfx init',e); }
    if(!G.sfxOn){ try{ c.suspend(); }catch(e){} }
    this._rendering=this._decodePending().then(()=>this._renderAll()); }, // clips first, so cues they fully cover are never synthesised
  resume(){ const c=this.ctx; if(c&&G.sfxOn&&c.state!=='running'&&c.state!=='closed'){ try{ const p=c.resume(); if(p&&p.catch) p.catch(()=>{}); }catch(e){} } },
  whenReady(){ this.init(); return this._rendering||Promise.resolve(); },
  _mg(){ return .62*Math.pow(Math.max(0,Math.min(1,this.vol)),1.6); },
  getVol(){ try{ const v=typeof META!=='undefined'&&META.opts&&META.opts.sfxVol; if(v!=null&&isFinite(v)) this.vol=Math.max(0,Math.min(1,+v)); }catch(e){} return this.vol; },
  setVol(v,save){ this.vol=Math.max(0,Math.min(1,+v||0)); if(this.master&&G.sfxOn) this.master.gain.setTargetAtTime(this._mg(),this.ctx.currentTime,.04);
    if(save){ try{ META.opts=META.opts||{}; META.opts.sfxVol=this.vol; Persist.saveLocal(); }catch(e){} this.play('ui_confirm'); } },
  setOn(on){ G.sfxOn=on; const c=this.ctx; if(!c||!this.master) return; if(on) this.resume(); this.master.gain.setTargetAtTime(on?this._mg():0,c.currentTime,.05);
    if(!on) setTimeout(()=>{ try{ if(!G.sfxOn&&c.state==='running') c.suspend(); }catch(e){} },400); }, // a muted game costs no audio CPU on phones
  ok(key,gap){ if(!this.ctx||!G.sfxOn) return false; const now=this.ctx.currentTime; if(key&&this.last[key]&&now-this.last[key]<gap) return false; if(key) this.last[key]=now; return true; },

  // ---- graph ----
  _chain(c,dest,ir){ const m=c.createGain(); m.gain.value=1;
    const hp=c.createBiquadFilter(); hp.type='highpass'; hp.frequency.value=24; hp.Q.value=.6; // sub-sonic mud only eats headroom
    const comp=c.createDynamicsCompressor(); comp.threshold.value=-22; comp.knee.value=14; comp.ratio.value=2.6; comp.attack.value=.014; comp.release.value=.3;
    const lim=c.createDynamicsCompressor(); lim.threshold.value=-6; lim.knee.value=0; lim.ratio.value=20; lim.attack.value=.001; lim.release.value=.12;
    const trim=c.createGain(); trim.gain.value=.6;
    m.connect(hp); hp.connect(comp); comp.connect(lim); lim.connect(trim); trim.connect(dest);
    const conv=c.createConvolver(); conv.buffer=ir; const ret=c.createGain(); ret.gain.value=.5; conv.connect(ret); ret.connect(hp);
    const bus={}; for(const [k,lvl,send] of [['weapons',.8,.22],['impacts',.8,.2],['explosions',1,.3],['ui',.6,.06],['ambient',.5,0]]){ const g=c.createGain(); g.gain.value=lvl; g.connect(m); if(send){ const s=c.createGain(); s.gain.value=send; g.connect(s); s.connect(conv); } bus[k]=g; }
    return {m,bus,comp,lim,trim,conv}; },
  _makeNoise(c){ const SR=this.SR, L=SR*2, mk=()=>c.createBuffer(1,L,SR); const rnd=this._rng(7);
    const w=mk(), p=mk(), b=mk(), k=mk(); const dw=w.getChannelData(0), dp=p.getChannelData(0), db=b.getChannelData(0), dk=k.getChannelData(0);
    let b0=0,b1=0,b2=0,b3=0,b4=0,b5=0,b6=0,br=0,pk=0,bk=0,cr=0;
    for(let i=0;i<L;i++){ const x=rnd()*2-1; dw[i]=x*.7;
      b0=.99886*b0+x*.0555179; b1=.99332*b1+x*.0750759; b2=.969*b2+x*.153852; b3=.8665*b3+x*.3104856; b4=.55*b4+x*.5329522; b5=-.7616*b5-x*.016898; dp[i]=b0+b1+b2+b3+b4+b5+b6+x*.5362; b6=x*.115926; pk=Math.max(pk,Math.abs(dp[i]));
      br=(br+.02*x)/1.02; db[i]=br; bk=Math.max(bk,Math.abs(br));
      if(rnd()<.0035) cr=(rnd()<.5?-1:1)*(.35+rnd()*.65); dk[i]=cr*(.6+.4*(rnd()*2-1)); cr*=.82; } // crackle: sparse decaying ticks, not hiss
    for(let i=0;i<L;i++){ dp[i]/=pk*1.05; db[i]/=bk*1.05; }
    for(const d of [dw,dp,db,dk]) for(let i=0;i<256;i++){ const f=i/256; d[i]*=f; d[L-1-i]*=f; } // loop seams fade
    return {w,p,b,k}; },
  _makeIR(c){ const SR=c.sampleRate, dur=1.6, L=Math.floor(SR*dur), ir=c.createBuffer(2,L,SR); const rnd=this._rng(11), pre=Math.floor(SR*.012);
    for(let ch=0;ch<2;ch++){ const d=ir.getChannelData(ch); let y=0;
      for(let i=pre;i<L;i++){ const t=(i-pre)/SR, x=rnd()*2-1; const a=.42*Math.exp(-t*3.2)+.035; y+=a*(x-y); d[i]=y*Math.exp(-t*4.3)*(1-Math.exp(-t*90)); } // darkens as it decays
      for(let j=0;j<6;j++){ const at=pre+Math.floor(SR*(.007+rnd()*.07)); if(at<L) d[at]+=(rnd()<.5?-1:1)*(.25+rnd()*.3)*(1-j*.12); } // a few early reflections, different per ear
      for(let i=0;i<64;i++) d[L-1-i]*=i/64; }
    return ir; },
  _rng(seed){ let s=(seed*2654435761)>>>0||1; return ()=>{ s^=s<<13; s>>>=0; s^=s>>>17; s^=s<<5; s>>>=0; return s/4294967296; }; },
  _hash(str){ let h=2166136261; for(let i=0;i<str.length;i++){ h^=str.charCodeAt(i); h=Math.imul(h,16777619); } return h>>>0; },

  // ---- offline synthesis kit (used only while rendering the bank) ----
  _kit(c,out,rnd){ const N=this.noise;
    const env=(g,t,a,pk,dec,hold)=>{ hold=hold||0; g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(pk,t+a); if(hold) g.gain.setValueAtTime(pk,t+a+hold); g.gain.setTargetAtTime(0,t+a+hold,dec/5); return t+a+hold+dec*1.45; };
    const filt=(type,f,q)=>{ const b=c.createBiquadFilter(); b.type=type; b.frequency.value=f; b.Q.value=q==null?.7:q; return b; };
    const glide=(prm,t,f0,f1,dur)=>{ prm.setValueAtTime(f0,t); if(f1!=null&&f1!==f0) prm.exponentialRampToValueAtTime(Math.max(5,f1),t+Math.max(.004,dur)); };
    const K={c,out,rnd,rv:(a,b)=>a+(b-a)*rnd(),
      pan(x){ if(!c.createStereoPanner) return out; const p=c.createStereoPanner(); p.pan.value=x; p.connect(out); return p; },
      // tone: {type,f0,f1,gl,t,a,dec,pk,hold,lp,lp1,lq,det,vib,vibHz,to}
      osc(o){ const t=o.t, end=t+(o.a||.003)+(o.hold||0)+o.dec*1.45; const os=c.createOscillator(); os.type=o.type||'sine'; glide(os.frequency,t,o.f0,o.f1,o.gl==null?o.dec:o.gl); if(o.det) os.detune.value=o.det;
        if(o.vib){ const l=c.createOscillator(); l.frequency.value=o.vibHz||6; const lg=c.createGain(); lg.gain.value=o.vib; l.connect(lg); lg.connect(os.detune); l.start(t); l.stop(end+.02); }
        let n=os; if(o.lp){ const f=filt('lowpass',o.lp,o.lq); if(o.lp1) glide(f.frequency,t,o.lp,o.lp1,o.lgl||o.dec); n.connect(f); n=f; }
        const g=c.createGain(); n.connect(g); g.connect(o.to||out); env(g,t,o.a||.003,o.pk,o.dec,o.hold); os.start(t); os.stop(end+.02); },
      // filtered noise: {k:'w'|'p'|'b'|'k', type,f0,f1,gl,q,t,a,dec,pk,hold,rate,lp,to}
      noise(o){ const t=o.t, end=t+(o.a||.002)+(o.hold||0)+o.dec*1.45; const s=c.createBufferSource(); s.buffer=N[o.k||'p']; s.loop=true; s.playbackRate.value=o.rate||1;
        const f=filt(o.type||'lowpass',o.f0,o.q); glide(f.frequency,t,o.f0,o.f1,o.gl==null?o.dec:o.gl); s.connect(f); let n=f;
        if(o.lp){ const f2=filt('lowpass',o.lp,.5); n.connect(f2); n=f2; }
        const g=c.createGain(); n.connect(g); g.connect(o.to||out); env(g,t,o.a||.002,o.pk,o.dec,o.hold); s.start(t,rnd()*1.6); s.stop(end+.02); },
      // struck metal: inharmonic bar partials, higher ones die first
      metal(o){ const r=o.ratios||[1,2.76,5.4,8.93], d=o.decs||[1,.62,.38,.22]; r.forEach((x,i)=>K.osc({f0:o.f*x,f1:o.f*x*(o.bend||.985),t:o.t,a:.0015,dec:o.dec*d[i],pk:o.pk*Math.pow(.62,i),to:o.to,det:(rnd()-.5)*12})); } };
    return K; },

  // ---- bank ----
  async _renderAll(){ const O=window.OfflineAudioContext||window.webkitOfflineAudioContext; if(!O||!this.noise) return;
    const names=Object.keys(this.CUES).sort((a,b)=>(this.CUES[a].first?0:1)-(this.CUES[b].first?0:1));
    for(const n of names){ if(this.custom[n]) continue; const m=this.MAP[n]; if(m&&!m.some(L=>L.syn)&&m.every(L=>!L.s||this.samp[L.s])) continue; try{ const b=await this._render(n,O); if(!this.custom[n]) this.bank[n]=b; }catch(e){ console.warn('sfx render',n,e); } }
    this.ready=true; },
  _render(name,O){ const cue=this.CUES[name], SR=this.SR, n=cue.n||3, len=cue.len, ch=cue.st?2:1;
    const c=new O(ch,Math.ceil(SR*len*n),SR); const out=c.createGain(); out.connect(c.destination);
    const rnd=this._rng(this._hash(name)), K=this._kit(c,out,rnd); for(let i=0;i<n;i++) cue.fn(K,i*len+.002,i);
    return c.startRendering().then(buf=>this._slice(name,buf,n,len,ch)); },
  _slice(name,buf,n,len,ch){ const SR=this.SR, L=Math.floor(len*SR), outv=[]; let pkAll=0;
    for(let i=0;i<n;i++){ const o=i*L, src=[]; let pk=0, last=0, bad=false;
      for(let k=0;k<ch;k++){ const d=buf.getChannelData(k).subarray(o,o+L); src.push(d); for(let j=0;j<d.length;j++){ const a=Math.abs(d[j]); if(!(a===a)) { bad=true; break; } if(a>pk) pk=a; if(a>1.5e-4) last=j; } }
      if(bad||pk<1e-6){ console.warn('sfx: bad variant',name,i); continue; }
      const Lt=Math.min(L,last+Math.floor(SR*.012)), g=.89/pk, b=this.ctx.createBuffer(ch,Lt,SR), fo=Math.floor(SR*.006);
      for(let k=0;k<ch;k++){ const d=new Float32Array(Lt); for(let j=0;j<Lt;j++) d[j]=src[k][j]*g; for(let j=0;j<fo&&j<Lt;j++) d[Lt-1-j]*=j/fo; if(b.copyToChannel) b.copyToChannel(d,k); else b.getChannelData(k).set(d); }
      outv.push(b); pkAll=Math.max(pkAll,pk); }
    this.peaks[name]=pkAll; return outv; },
  // ---- recorded samples: any cue plays a registered sample instead of its synth take (same bus, reverb, pan, voice caps, jitter, round robin) ----
  setSample(name,bufs){ const a=(Array.isArray(bufs)?bufs:[bufs]).filter(Boolean).map(b=>this._norm(b)); if(!a.length) return; this.bank[name]=a; this.custom[name]=true; if(!this.CUES[name]) this.CUES[name]={bus:'ui',g:.3,max:3,len:1,fn(){}}; },
  _norm(b){ try{ let pk=0; for(let k=0;k<b.numberOfChannels;k++){ const d=b.getChannelData(k); for(let j=0;j<d.length;j++){ const a=Math.abs(d[j]); if(a>pk) pk=a; } } if(pk>1e-6&&Math.abs(pk-.89)>.01){ const g=.89/pk; for(let k=0;k<b.numberOfChannels;k++){ const d=b.getChannelData(k); for(let j=0;j<d.length;j++) d[j]*=g; } } }catch(e){} return b; }, // samples sit at the same -1 dBFS as synth takes, so the cue table stays the mix
  _decode(ab){ return new Promise((res,rej)=>{ try{ const p=this.ctx.decodeAudioData(ab,res,rej); if(p&&p.then) p.then(res,rej); }catch(e){ rej(e); } }); },
  async loadSample(name,url){ this.init(); if(!this.ctx) return; const ab=await (await fetch(url)).arrayBuffer(); this.setSample(name,await this._decode(ab)); },
  // SFX.registerSamples({boomBig:[b64,...], hullHit:[...]}): clip keys (see SFX.MAP) or cue names; stored now, decoded once after the first user gesture, never blocks boot
  _pending:{},samp:{},_rrS:{},
  registerSamples(map){ if(!map) return; for(const k in map){ const v=map[k]; const a=(Array.isArray(v)?v:[v]).filter(x=>typeof x==='string'&&x.length>16); if(a.length) this._pending[k]=a; } if(this.ctx) return this._decodePending(); },
  async _decodePending(){ if(!this.ctx) return; const keys=Object.keys(this._pending); for(const k of keys){ const a=this._pending[k]; delete this._pending[k]; const bufs=[];
      for(const s of a){ try{ const bin=atob(s.replace(/^data:[^,]*,/,'')), u=new Uint8Array(bin.length); for(let i=0;i<bin.length;i++) u[i]=bin.charCodeAt(i); bufs.push(await this._decode(u.buffer)); }catch(e){ console.warn('sfx sample',k,e); } }
      if(!bufs.length) continue; this.samp[k]=bufs; if(this.CUES[k]&&!this.MAP[k]) this.setSample(k,bufs); } // a clip that fails to decode leaves the synth take in place
    this._ambSample(); },

  // ---- spatial ----
  _where(src){ if(!src) return null; try{ if(src.pan!=null) return {pan:+src.pan||0,att:src.att||1};
      let p=src; if(p.root&&p.root.getAbsolutePosition) p=p.root.getAbsolutePosition(); else if(p.id!=null&&p.x==null&&G.views&&G.views.get(p.id)){ const v=G.views.get(p.id); p=v.root?v.root.getAbsolutePosition():null; } else if(p.x==null&&p.q!=null&&typeof hexWorld==='function') p=hexWorld(p.q,p.r,0);
      if(!p||p.x==null||!G.cam) return null; const v=BABYLON.Vector3.TransformCoordinates(p,G.cam.getViewMatrix()); const asp=(G.engine&&G.engine.getAspectRatio)?G.engine.getAspectRatio(G.cam):1.6;
      let pan=v.z>1?v.x/(v.z*Math.tan((G.cam.fov||.8)/2)*asp):Math.sign(v.x)*.5; pan=Math.max(-1,Math.min(1,pan))*.72;
      const dist=Math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z); const att=Math.max(.5,Math.min(1,Math.sqrt(230/Math.max(1,dist))));
      return (isFinite(pan)&&isFinite(att))?{pan,att}:null; }catch(e){ return null; } },

  // ---- voices ----
  maxVoices(){ return G.mobile?20:34; },
  // A cue resolves to layers: recorded clips from SFX.MAP when they decoded, plus (or else) its synth take.
  _pick(arr,key){ if(arr.length<2) return arr[0]; let ix=Math.floor(Math.random()*arr.length); if(ix===this._rrS[key]) ix=(ix+1)%arr.length; this._rrS[key]=ix; return arr[ix]; }, // round robin, never the same take twice
  _layers(name,cue){ const out=[], m=this.MAP[name]; let sampled=false;
    if(m) for(const L of m){ if(L.s){ const a=this.samp[L.s]; if(a&&a.length){ out.push({buf:this._pick(a,L.s),g:L.g==null?1:L.g,r:L.r||1,d:L.d||0,pj:L.pj==null?(cue.spj==null?.07:cue.spj):L.pj}); sampled=true; } } }
    const syn=this.bank[name]; if(syn&&syn.length){ const sl=m&&m.find(L=>L.syn); if(!sampled||sl) out.push({buf:this._pick(syn,name),g:sampled?sl.g:1,r:1,d:0,pj:cue.pj==null?.03:cue.pj,syn:1}); }
    return out; },
  play(name,o){ o=o||{}; const c=this.ctx; if(!c||!G.sfxOn||!this.master) return null; const cue=this.CUES[name]; if(!cue) return null; const lay=this._layers(name,cue); if(!lay.length) return null;
    if(c.state!=='running') this.resume(); const now=c.currentTime; let t=now+(o.delay||0)+.004;
    const lt=this.last[name]||0, gap=cue.gap||0;
    if(gap&&t<lt+gap){ const nt=lt+gap*(1+Math.random()*.6); if(nt-now>(cue.defer||0)) return null; t=nt; } // overlapping calls stagger into a roll instead of stacking
    this.last[name]=t; let gain=cue.g*(o.gain==null?1:o.gain);
    if(cue.salvo){ const s=this.salvo[cue.salvo]||(this.salvo[cue.salvo]={t:0,n:0}); s.n=now-s.t<.45?s.n+1:1; s.t=now; gain*=Math.max(.42,1/Math.sqrt(1+.3*(s.n-1)));
      if(s.n===4&&now-this.tailT>1.1){ this.tailT=now; this.play('salvo_tail',{gain:cue.tail||1,delay:.06,pos:o.pos}); } } // a broadside gets one rolling body under it
    const w=this._where(o.pos); if(w) gain*=w.att; if(!(gain>0)) return null;
    this._reap(now); const list=this.byCue[name]||(this.byCue[name]=[]);
    while(list.length>=(cue.max||4)) this._steal(list[0],now);
    if(this.active.length>=this.maxVoices()){ const pri=cue.pri||1; const vi=this.active.findIndex(v=>(this.CUES[v.name].pri||1)<=pri); if(vi<0) return null; this._steal(this.active[vi],now); }
    const u=Math.random()*2-1;
    try{ const g=c.createGain(); g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(gain,t+.003);
      let p=null; const panv=w?w.pan:(o.pan||0); if(panv&&c.createStereoPanner){ p=c.createStereoPanner(); p.pan.value=panv; p.connect(this.bus[cue.bus]); g.connect(p); } else g.connect(this.bus[cue.bus]);
      const v={srcs:[],g,p,name,t0:t,end:t,dead:false}; let longest=null, dur=0;
      for(const L of lay){ const rate=Math.max(.25,(o.rate||1)*L.r*(1+u*L.pj)); const s=c.createBufferSource(); s.buffer=L.buf; s.playbackRate.value=rate; let n=s;
        if(L.g!==1){ const lg=c.createGain(); lg.gain.value=L.g; s.connect(lg); n=lg; v.srcs.push(lg); } n.connect(g); s.start(t+L.d); v.srcs.push(s); const e=L.d+L.buf.duration/rate; if(e>dur){ dur=e; longest=s; } }
      v.end=t+dur+.05; longest.onended=()=>this._free(v); list.push(v); this.active.push(v);
      if(cue.duck) this.duck(cue.duck*Math.min(1.4,gain/cue.g),dur*.5,t);
      return v; }catch(e){ return null; } },
  _drop(v){ const l=this.byCue[v.name]; if(l){ const i=l.indexOf(v); if(i>=0) l.splice(i,1); } const i=this.active.indexOf(v); if(i>=0) this.active.splice(i,1); },
  _free(v){ if(v.freed) return; v.freed=true; v.dead=true; this._drop(v); try{ for(const s of v.srcs) s.disconnect(); v.g.disconnect(); if(v.p) v.p.disconnect(); }catch(e){} },
  _steal(v,now){ if(!v) return; this._drop(v); if(v.dead) return; v.dead=true; try{ const gp=v.g.gain; if(gp.cancelAndHoldAtTime) gp.cancelAndHoldAtTime(now); else { gp.cancelScheduledValues(now); gp.setValueAtTime(gp.value,now); } gp.setTargetAtTime(0,now,.012); for(const s of v.srcs) if(s.stop) s.stop(now+.09); }catch(e){ this._free(v); } }, // fade the oldest out, never cut it
  _reap(now){ for(let i=this.active.length-1;i>=0;i--){ const v=this.active[i]; if(v.end<now) this._free(v); } },
  duck(depth,hold,at){ const a=this.bus.ambient, c=this.ctx; if(!a||!c) return; const t=Math.max(c.currentTime,at||0), base=.5; a.gain.cancelScheduledValues(t); a.gain.setTargetAtTime(base*Math.max(.12,1-depth),t,.04); a.gain.setTargetAtTime(base,t+Math.max(.2,hold),.9); },
  stats(){ const st={state:this.ctx?this.ctx.state:'none',voices:this.active.length,ready:this.ready,cues:Object.keys(this.bank).length,of:Object.keys(this.CUES).length}; st.nodes=this.active.reduce((a,v)=>a+v.srcs.length+2,0)+(this._amb?this._amb.n:0)+(this._ambS?2:0)+18; st.clips=Object.keys(this.samp).length; return st; },
  stopAll(){ const c=this.ctx; if(!c) return; const now=c.currentTime; this.active.slice().forEach(v=>this._steal(v,now)); },

  // ---- cues (legacy signatures + optional source) ----
  gun(k,sq,style,pos){ if(sq) return this.play('gun_sq',{pos}); if(k==='flak') return this.play('gun_flak',{pos});
    if(style==='twin'){ this.play('gun_shell',{pos,gain:.8}); return this.play('gun_shell',{pos,gain:.6,delay:.05}); }
    const n='gun_'+(style||'shell'); return this.play(this.CUES[n]?n:'gun_shell',{pos}); },
  lance(ion,fac,pos){ return this.play(fac==='deathless'?'lance_dark':fac==='ithar'?'lance_choir':ion?'lance_ion':'lance',{pos}); },
  torp(fac,pos){ return this.play({corsair:'torp_rocket',chorus:'torp_sac',ithar:'torp_star',voidsworn:'torp_heavy'}[fac]||'torp',{pos}); },
  phase(pos){ return this.play('phase',{pos}); },
  charge(pos){ return this.play('charge',{pos}); },
  cough(pos){ return this.play('cough',{pos}); },
  puff(pos){ return this.play('puff',{pos}); },
  hit(pos,heavy){ return this.play(heavy?'hit_heavy':'hit',{pos}); },
  shield(pos,big){ return this.play(big?'shield_break':'shield',{pos}); },
  patter(shielded,pos){ return this.play(shielded?'patter_shield':'patter_hull',{pos}); },
  boom(s=1,pos){ s=Math.max(.05,+s||1); const n=s<.35?'boom_s':s<.95?'boom_m':'boom_l', top=s<.35?.35:s<.95?.95:1.5; const v=this.play(n,{pos,gain:Math.min(1.15,.45+.6*s/top),rate:s>1.25?.9:1});
    if(s>=1.1) this.play('bass_drop',{pos,gain:Math.min(1,s/1.5)}); if(s>=1) this.play('wreck',{pos,delay:.7,gain:Math.min(1,s/1.4)}); return v; }, // capitals get a sub drop and a groaning wreck
  pop(pos){ return this.play('pop',{pos}); },
  launch(pos){ return this.play('launch',{pos}); },
  engine(size,pos){ size=size||1; return this.play('engine',{pos,gain:Math.min(1,.55+size*.15),rate:Math.max(.7,1.12-size*.1)}); },
  click(act){ const a=String(act||''); if(/^(take|buy|upgrade|promote|repairAll)/.test(a)) return this.play('ui_reward'); if(/^(endTurn|begin|startRun|continueRun|c3continue|enterNode|sellConfirm|tipOk|rewardNext|leaveYard|c3retreatYes|confirm)/.test(a)) return this.play('ui_confirm');
    if(/(close|Close|cancel|back|No$|abandon|tipOff)/.test(a)) return this.play('ui_cancel'); if(/(Toggle|settings|fleetScreen|help|legend|diag|Screen|progTab|sheet)/.test(a)) return this.play('ui_panel'); if(/^(pick|rosterPick|equip|unequip|arm|launchKind|command|ability)/.test(a)) return this.play('ui_select'); return this.play('ui_click'); },
  select(){ return this.play('ui_select'); },
  reward(){ return this.play('ui_reward'); },
  confirm(){ return this.play('ui_confirm'); },
  cancel(){ return this.play('ui_cancel'); },
  turn(kind){ return this.play(kind==='player'?'ui_your':kind==='enemy'?'ui_enemy':'ui_round'); },
  banner(text,color){ const s=String(text||''); if(s==='Your turn') return this.turn('player'); if(s==='Enemy turn') return this.turn('enemy'); if(/^Round \d/.test(s)) return this.turn('round'); if(color==='#ff8a6a') return this.play('ui_alert'); if(s==='Sector flagship') return this.play('ui_boss'); return null; },
  sting(win){ this.duck(.8,3); return this.play(win?'sting_win':'sting_loss'); },
  // legacy live helpers (nothing in the game calls these now; kept so old snippets still work, click-free)
  tone({type='sine',f0=60,f1=40,peak=.4,dec=.3,start=0}={}){ if(!this.ok()) return; const c=this.ctx,t=c.currentTime+start+.004,o=c.createOscillator(),g=c.createGain(); o.type=type; o.frequency.setValueAtTime(f0,t); o.frequency.exponentialRampToValueAtTime(Math.max(20,f1),t+dec); g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(peak*.5,t+.004); g.gain.setTargetAtTime(0,t+.004,dec/5); o.connect(g); g.connect(this.bus.ui); o.start(t); o.stop(t+dec*1.5+.05); o.onended=()=>{ try{ g.disconnect(); }catch(e){} }; },
  noiseHit({f0=800,f1=120,q=.8,peak=.5,dec=.4,type='lowpass',start=0}={}){ if(!this.ok()) return; const c=this.ctx,t=c.currentTime+start+.004,s=c.createBufferSource(),f=c.createBiquadFilter(),g=c.createGain(); s.buffer=this.noise.p; f.type=type; f.Q.value=q; f.frequency.setValueAtTime(f0,t); f.frequency.exponentialRampToValueAtTime(Math.max(30,f1),t+dec); g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(peak*.5,t+.004); g.gain.setTargetAtTime(0,t+.004,dec/5); s.connect(f); f.connect(g); g.connect(this.bus.ui); s.start(t); s.stop(t+dec*1.5+.05); s.onended=()=>{ try{ g.disconnect(); }catch(e){} }; },
  env(node,t,a,peak,dec){ node.gain.setValueAtTime(0,t); node.gain.linearRampToValueAtTime(peak,t+a); node.gain.setTargetAtTime(0,t+a,dec/5); },

  // ---- ambient: a low evolving bed, native nodes only ----
  ambient(){ const c=this.ctx; if(!c||this._amb) return; const out=this.bus.ambient, N=this.noise; let n=0; const mk=x=>{ n++; return x; };
    const lp=mk(c.createBiquadFilter()); lp.type='lowpass'; lp.frequency.value=150; lp.Q.value=.5; const lg=mk(c.createGain()); lg.gain.value=0; lp.connect(lg); lg.connect(out);
    const br=mk(c.createBufferSource()); br.buffer=N.b; br.loop=true; br.playbackRate.value=.5; const bg=mk(c.createGain()); bg.gain.value=.5; br.connect(bg); bg.connect(lp);
    for(const [f,a] of [[55,.05],[55.21,.04],[82.6,.016]]){ const o=mk(c.createOscillator()); o.frequency.value=f; const g=mk(c.createGain()); g.gain.value=a; o.connect(g); g.connect(lg); o.start(); }
    const air=mk(c.createBufferSource()); air.buffer=N.p; air.loop=true; air.playbackRate.value=.6; const bp=mk(c.createBiquadFilter()); bp.type='bandpass'; bp.frequency.value=700; bp.Q.value=.8; const ag=mk(c.createGain()); ag.gain.value=.012; air.connect(bp); bp.connect(ag); ag.connect(lg);
    const l1=mk(c.createOscillator()); l1.frequency.value=.023; const l1g=mk(c.createGain()); l1g.gain.value=60; l1.connect(l1g); l1g.connect(lp.frequency);
    const l2=mk(c.createOscillator()); l2.frequency.value=.011; const l2g=mk(c.createGain()); l2g.gain.value=260; l2.connect(l2g); l2g.connect(bp.frequency);
    const l3=mk(c.createOscillator()); l3.frequency.value=.017; const l3g=mk(c.createGain()); l3g.gain.value=.008; l3.connect(l3g); l3g.connect(ag.gain);
    br.start(); air.start(); l1.start(); l2.start(); l3.start(); const t=c.currentTime; lg.gain.setValueAtTime(0,t); lg.gain.linearRampToValueAtTime(.55,t+4); // fades in, never pops
    this._amb={n,lg}; this._ambSample(); },
  _ambSample(){ const c=this.ctx, a=this.samp.ambient; if(!c||!a||!this._amb||this._ambS) return; try{ const s=c.createBufferSource(); s.buffer=a[0]; s.loop=true; const g=c.createGain(), t=c.currentTime; g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(.3,t+5);
      s.connect(g); g.connect(this.bus.ambient); s.start(t,Math.random()*a[0].duration*.5); this._ambS={s,g}; this._amb.lg.gain.setTargetAtTime(.25,t,2); }catch(e){} }, // recorded roomtone over a thinner synth bed
};

// ---- cue table: bus, level, voice cap, min gap/defer (rolling), pitch jitter, variants, length, stereo, synth ----
// Levels are set here; every rendered take is normalised to -1 dBFS first so these numbers are the mix.
SFX.CUES={
  // weapons: kinetic broadside cannon is the house sound
  gun_shell:{bus:'weapons',g:.42,max:6,gap:.045,defer:.14,salvo:'gun',n:4,len:1,first:1,fn(K,t){ const f=K.rv(100,124);
    K.noise({k:'p',type:'bandpass',f0:2100,f1:700,q:.9,t,a:.001,dec:.05,pk:.5}); K.noise({k:'b',f0:1500,f1:170,t,a:.002,dec:.32,pk:.9});
    K.osc({f0:f,f1:40,gl:.22,t,a:.002,dec:.34,pk:1}); K.osc({type:'triangle',f0:f*2.2,f1:f,lp:900,t,dec:.09,pk:.22}); K.noise({k:'b',f0:340,f1:110,t,a:.03,dec:.6,pk:.28}); }},
  gun_flak:{bus:'weapons',g:.26,max:4,gap:.04,defer:.1,salvo:'gun',tail:.4,n:4,len:.4,fn(K,t){ for(let i=0;i<2;i++){ const u=t+i*K.rv(.045,.07); K.noise({k:'p',type:'bandpass',f0:1300,f1:600,q:1.1,t:u,dec:.05,pk:.55-i*.12}); K.osc({f0:190,f1:90,t:u,dec:.07,pk:.4-i*.1}); } }},
  gun_sq:{bus:'weapons',g:.16,max:3,gap:.05,defer:.08,n:3,len:.3,fn(K,t){ for(let i=0;i<3;i++){ const u=t+i*K.rv(.04,.05); K.noise({k:'p',type:'bandpass',f0:K.rv(2400,3000),q:2,t:u,dec:.025,pk:.45*(1-i*.15)}); K.osc({f0:170,f1:110,t:u,dec:.04,pk:.16}); } }},
  gun_las:{bus:'weapons',g:.3,max:6,gap:.045,defer:.14,salvo:'gun',n:4,len:.7,fn(K,t){ const f=K.rv(1450,1700);
    K.osc({type:'triangle',f0:f,f1:f*.22,gl:.16,lp:3600,t,a:.002,dec:.18,pk:.5}); K.osc({f0:f*1.007,f1:f*.23,gl:.17,t,a:.002,dec:.2,pk:.32});
    K.osc({f0:125,f1:52,gl:.12,t,dec:.22,pk:.75}); K.noise({k:'p',type:'bandpass',f0:5000,f1:2500,q:.8,t,dec:.06,pk:.12}); K.noise({k:'b',f0:520,f1:150,t,a:.01,dec:.32,pk:.16}); }},
  gun_plasma:{bus:'weapons',g:.34,max:5,gap:.05,defer:.14,salvo:'gun',n:3,len:.9,fn(K,t){ const f=K.rv(235,270);
    K.osc({type:'sawtooth',f0:f,f1:68,gl:.3,lp:1300,lp1:240,lq:4,t,a:.004,dec:.32,pk:.38,vib:40,vibHz:22}); K.osc({f0:96,f1:44,t,dec:.3,pk:.85});
    K.noise({k:'b',f0:950,f1:160,t,dec:.36,pk:.42}); K.noise({k:'w',type:'bandpass',f0:3000,f1:1500,q:1.2,t,dec:.1,pk:.07}); }},
  gun_tracer:{bus:'weapons',g:.3,max:5,gap:.06,defer:.16,salvo:'gun',n:3,len:.6,fn(K,t){ const d=K.rv(.05,.06); for(let i=0;i<3;i++){ const u=t+i*d;
      K.osc({f0:K.rv(140,160),f1:60,t:u,dec:.07,pk:.55*(1-.13*i)}); K.noise({k:'p',type:'bandpass',f0:K.rv(1500,1900),q:1.1,t:u,dec:.035,pk:.5*(1-.1*i)}); K.osc({f0:2900,t:u,dec:.05,pk:.035}); }
    K.noise({k:'b',f0:420,f1:130,t,a:.02,dec:.3,pk:.16}); }},
  gun_spine:{bus:'weapons',g:.32,max:5,gap:.05,defer:.14,salvo:'gun',n:3,len:.7,fn(K,t){ K.noise({k:'p',type:'bandpass',f0:320,f1:1300,gl:.1,q:6,t,dec:.14,pk:.6});
    K.osc({f0:K.rv(140,160),f1:55,t,dec:.24,pk:.75}); K.osc({f0:1100,f1:700,t,a:.001,dec:.02,pk:.25}); K.osc({type:'triangle',f0:72,f1:60,lp:400,t,a:.02,dec:.3,pk:.2,vib:30,vibHz:7}); }},
  gun_needle:{bus:'weapons',g:.22,max:6,gap:.045,defer:.14,salvo:'gun',tail:.5,n:4,len:.7,fn(K,t){ const f=K.rv(2250,2600);
    K.osc({f0:f,f1:f*.86,gl:.25,t,a:.002,dec:.3,pk:.45}); K.osc({f0:f*1.5,f1:f*1.3,gl:.25,t,a:.002,dec:.22,pk:.24}); K.osc({f0:f*2.01,t,dec:.12,pk:.09});
    K.noise({k:'w',type:'bandpass',f0:7000,q:.8,t,dec:.05,pk:.1}); K.osc({f0:180,f1:90,t,dec:.1,pk:.3}); }},
  gun_rail:{bus:'weapons',g:.42,max:4,gap:.06,defer:.16,salvo:'gun',n:3,len:1.1,fn(K,t){ K.osc({f0:420,f1:2600,gl:.05,t,a:.045,dec:.012,pk:.18}); const u=t+.05;
    K.noise({k:'w',type:'bandpass',f0:4500,f1:1400,q:.7,t:u,dec:.045,pk:.55}); K.osc({f0:64,f1:36,gl:.3,t:u,dec:.46,pk:1}); K.metal({f:K.rv(400,480),t:u,dec:.55,pk:.24}); K.noise({k:'b',f0:260,f1:90,t:u,a:.02,dec:.62,pk:.26}); }},
  gun_glob:{bus:'weapons',g:.3,max:5,gap:.05,defer:.14,salvo:'gun',n:3,len:.7,fn(K,t){ K.osc({f0:300,f1:90,gl:.12,t,dec:.15,pk:.6,vib:180,vibHz:28}); K.noise({k:'b',f0:700,f1:200,t,dec:.2,pk:.42});
    for(let i=0;i<2;i++) K.osc({f0:K.rv(550,700),f1:950,gl:.04,t:t+.1+i*K.rv(.05,.09),dec:.04,pk:.12}); }},
  salvo_tail:{bus:'weapons',g:.4,max:2,n:2,len:2,pj:.06,fn(K,t){ K.noise({k:'b',f0:260,f1:90,t,a:.08,dec:1.1,pk:.9}); K.noise({k:'p',type:'bandpass',f0:600,q:.7,t,a:.05,dec:.4,pk:.14}); K.osc({f0:52,f1:38,gl:.6,t,a:.05,dec:.7,pk:.42});
    for(let i=0;i<3;i++) K.noise({k:'b',f0:500,f1:140,t:t+.15+i*K.rv(.12,.22),a:.01,dec:.3,pk:.35}); }},
  lance:{bus:'weapons',g:.36,max:3,gap:.08,defer:.2,n:2,len:1.4,fn(K,t){ K.noise({k:'p',type:'bandpass',f0:900,f1:3000,gl:.05,q:1.2,t,dec:.08,pk:.3});
    K.osc({type:'sawtooth',f0:110,lp:1600,lp1:500,lgl:.8,lq:1.5,t,a:.03,hold:.25,dec:.45,pk:.32}); K.osc({type:'triangle',f0:165,t,a:.03,hold:.25,dec:.45,pk:.28});
    K.osc({f0:55,t,a:.02,hold:.2,dec:.5,pk:.5}); K.noise({k:'k',type:'bandpass',f0:2500,q:1.2,t,a:.02,hold:.25,dec:.3,pk:.3}); }},
  lance_ion:{bus:'weapons',g:.32,max:3,gap:.08,defer:.2,n:2,len:1.4,fn(K,t){ K.noise({k:'p',type:'bandpass',f0:1400,f1:4000,gl:.05,q:1.2,t,dec:.07,pk:.25});
    K.osc({type:'sawtooth',f0:220,lp:2400,lp1:800,lgl:.8,lq:1.4,t,a:.03,hold:.22,dec:.4,pk:.26}); K.osc({type:'triangle',f0:330,t,a:.03,hold:.22,dec:.4,pk:.24});
    K.osc({f0:880,t,a:.03,hold:.2,dec:.35,pk:.1,vib:25,vibHz:9}); K.osc({f0:110,t,a:.02,hold:.2,dec:.45,pk:.4}); K.noise({k:'k',type:'bandpass',f0:3500,q:1,t,a:.02,hold:.25,dec:.3,pk:.38}); }},
  lance_dark:{bus:'weapons',g:.4,max:3,gap:.08,defer:.2,n:2,len:1.6,fn(K,t){ K.osc({type:'sawtooth',f0:82,lp:520,lq:3,t,a:.04,hold:.3,dec:.5,pk:.42,vib:15,vibHz:5});
    K.osc({f0:41,t,a:.04,hold:.3,dec:.55,pk:.6}); K.noise({k:'b',f0:320,t,a:.04,hold:.3,dec:.4,pk:.3}); K.noise({k:'k',type:'bandpass',f0:1200,q:1,t,a:.03,hold:.3,dec:.35,pk:.18}); }},
  lance_choir:{bus:'weapons',g:.3,max:3,gap:.08,defer:.2,n:2,len:1.5,fn(K,t){ for(const [f,a] of [[440,.25],[880,.3],[1320,.2],[1760.5,.1]]) K.osc({type:f===880?'triangle':'sine',f0:f,f1:f*.95,gl:.7,t,a:.04,hold:.25,dec:.5,pk:a,det:(K.rnd()-.5)*10});
    K.noise({k:'p',type:'bandpass',f0:6000,q:1,t,a:.04,hold:.2,dec:.3,pk:.06}); }},
  torp:{bus:'weapons',g:.36,max:4,gap:.07,defer:.2,n:3,len:1.3,fn(K,t){ K.osc({f0:85,f1:45,t,dec:.3,pk:.7}); K.noise({k:'b',f0:800,f1:200,t,dec:.12,pk:.5});
    K.noise({k:'p',type:'bandpass',f0:350,f1:1800,gl:.6,q:1.4,t,a:.06,dec:.55,pk:.5}); K.noise({k:'b',f0:500,t,a:.05,dec:.6,pk:.3}); }},
  torp_rocket:{bus:'weapons',g:.3,max:4,gap:.07,defer:.2,n:3,len:.9,fn(K,t){ for(let i=0;i<4;i++){ const u=t+i*K.rv(.055,.075); K.noise({k:'p',type:'bandpass',f0:600,f1:2400,gl:.25,q:1.6,t:u,a:.01,dec:.22,pk:.5}); K.osc({f0:140,f1:70,t:u,dec:.06,pk:.3}); } }},
  torp_sac:{bus:'weapons',g:.34,max:4,gap:.07,defer:.2,n:3,len:.9,fn(K,t){ K.noise({k:'p',type:'bandpass',f0:250,f1:700,gl:.25,q:4,t,dec:.3,pk:.6}); K.osc({f0:95,f1:45,t,dec:.35,pk:.7}); K.osc({f0:400,f1:200,t:t+.05,dec:.12,pk:.14,vib:150,vibHz:24}); }},
  torp_star:{bus:'weapons',g:.28,max:4,gap:.07,defer:.2,n:3,len:1,fn(K,t){ K.osc({type:'triangle',f0:700,f1:1800,gl:.45,lp:3000,t,a:.02,dec:.45,pk:.4}); K.osc({f0:1400,f1:3600,gl:.45,t,a:.02,dec:.4,pk:.14});
    K.noise({k:'w',type:'bandpass',f0:4000,f1:7000,q:.8,t,a:.02,dec:.4,pk:.07}); K.osc({f0:70,f1:50,t,dec:.3,pk:.3}); }},
  torp_heavy:{bus:'weapons',g:.4,max:4,gap:.07,defer:.2,n:3,len:1.4,fn(K,t){ K.osc({f0:62,f1:32,gl:.4,t,dec:.6,pk:.85}); K.noise({k:'b',f0:700,f1:160,t,dec:.16,pk:.55}); K.metal({f:150,t,dec:.4,pk:.15});
    K.noise({k:'p',type:'bandpass',f0:300,f1:1500,gl:.7,q:1.4,t:t+.03,a:.08,dec:.6,pk:.45}); K.noise({k:'b',f0:420,t,a:.06,dec:.7,pk:.32}); }},
  // impacts
  hit:{bus:'impacts',g:.36,max:4,gap:.05,defer:.12,n:4,len:.9,first:1,fn(K,t){ K.noise({k:'b',type:'bandpass',f0:K.rv(700,1100),f1:300,q:.8,t,dec:.12,pk:.75});
    K.noise({k:'p',type:'bandpass',f0:2600,q:1,t,a:.001,dec:.03,pk:.42}); K.metal({f:K.rv(170,260),t,dec:.45,pk:.3}); K.osc({f0:95,f1:48,t,dec:.16,pk:.6}); K.noise({k:'k',type:'bandpass',f0:3000,q:.8,t:t+.02,a:.01,dec:.25,pk:.18}); }},
  hit_heavy:{bus:'impacts',g:.46,max:3,gap:.08,defer:.15,n:3,len:1.5,fn(K,t){ K.noise({k:'b',type:'bandpass',f0:K.rv(500,800),f1:180,q:.7,t,dec:.22,pk:.85}); K.noise({k:'p',type:'bandpass',f0:2200,q:1,t,a:.001,dec:.04,pk:.4});
    K.metal({f:K.rv(90,130),t,dec:.8,pk:.32}); K.osc({f0:72,f1:34,t,dec:.3,pk:.8}); K.noise({k:'k',type:'bandpass',f0:2400,q:.7,t:t+.03,a:.02,dec:.6,pk:.25}); }},
  shield:{bus:'impacts',g:.3,max:4,gap:.06,defer:.12,n:3,len:1.1,first:1,fn(K,t){ const f=K.rv(780,940);
    [[1,.5,.24],[1.5,.42,.18],[2.32,.34,.13],[3.01,.24,.08]].forEach(([r,d,a])=>{ K.osc({f0:f*r,f1:f*r*.99,t,a:.002,dec:d,pk:a,det:-5}); K.osc({f0:f*r,f1:f*r*.99,t,a:.002,dec:d*.9,pk:a*.7,det:6}); });
    K.noise({k:'w',type:'bandpass',f0:4200,f1:2200,q:3,t,dec:.1,pk:.22}); K.osc({f0:240,f1:180,t,dec:.2,pk:.3}); K.noise({k:'k',type:'bandpass',f0:6000,q:1,t:t+.02,a:.01,dec:.3,pk:.1}); }},
  patter_hull:{bus:'impacts',g:.12,max:3,gap:.07,defer:0,n:3,len:.3,fn(K,t){ K.noise({k:'p',type:'bandpass',f0:K.rv(1300,1800),q:1,t,dec:.04,pk:.5}); K.osc({f0:K.rv(800,1000),t,dec:.06,pk:.15}); K.osc({f0:110,f1:70,t,dec:.05,pk:.25}); }},
  patter_shield:{bus:'impacts',g:.1,max:3,gap:.07,defer:0,n:3,len:.4,fn(K,t){ const f=K.rv(1700,2200); K.osc({f0:f,t,dec:.12,pk:.3}); K.osc({f0:f*1.5,t,dec:.08,pk:.15}); K.noise({k:'w',type:'bandpass',f0:5000,q:2,t,dec:.03,pk:.15}); }},
  pop:{bus:'explosions',g:.3,max:3,gap:.05,defer:.12,n:3,len:.7,fn(K,t){ K.osc({f0:320,f1:70,t,dec:.12,pk:.7}); K.noise({k:'p',f0:2500,f1:600,t,dec:.1,pk:.6}); K.noise({k:'k',type:'bandpass',f0:2500,q:.8,t:t+.02,a:.01,dec:.3,pk:.25}); }},
  // explosions: sub thump + body + crackle debris, sized by class; they duck the ambient bed
  boom_s:{bus:'explosions',g:.42,max:3,gap:.06,defer:.12,pri:2,duck:.3,n:3,len:1.4,st:1,pj:.06,first:1,fn(K,t){ const L=K.pan(-.5), R=K.pan(.5);
    K.noise({k:'p',f0:3500,f1:800,t,dec:.06,pk:.55}); K.noise({k:'b',f0:900,f1:120,gl:.5,t,dec:.5,pk:.9}); K.osc({f0:80,f1:40,t,dec:.3,pk:.7});
    K.noise({k:'k',type:'bandpass',f0:2200,q:.7,t:t+.03,a:.02,dec:.6,pk:.22,to:L}); K.noise({k:'k',type:'bandpass',f0:1800,q:.7,t:t+.05,a:.02,dec:.55,pk:.22,to:R}); }},
  boom_m:{bus:'explosions',g:.6,max:3,gap:.08,defer:.15,pri:3,duck:.5,n:2,len:2.4,st:1,pj:.05,fn(K,t){ const L=K.pan(-.6), R=K.pan(.6);
    K.noise({k:'p',f0:3200,f1:700,t,dec:.08,pk:.55}); K.noise({k:'b',f0:700,f1:80,gl:1,t,a:.005,dec:1,pk:1}); K.osc({f0:62,f1:30,gl:.6,t,a:.004,dec:.7,pk:.9});
    K.noise({k:'p',type:'bandpass',f0:400,f1:150,q:.6,t,dec:.6,pk:.32}); K.noise({k:'k',type:'bandpass',f0:2000,q:.7,t:t+.05,a:.05,dec:1.4,pk:.28,to:L}); K.noise({k:'k',type:'bandpass',f0:1600,q:.7,t:t+.08,a:.05,dec:1.3,pk:.28,to:R});
    for(let i=0;i<2;i++){ const u=t+K.rv(.25,.6); K.noise({k:'b',f0:1200,f1:200,t:u,dec:.18,pk:.35,to:i?R:L}); } }},
  boom_l:{bus:'explosions',g:.8,max:2,gap:.12,defer:.2,pri:4,duck:.75,n:2,len:3.6,st:1,pj:.04,fn(K,t){ const L=K.pan(-.65), R=K.pan(.65);
    K.noise({k:'p',f0:3000,f1:600,t,dec:.1,pk:.5}); K.noise({k:'b',f0:600,f1:60,gl:1.5,t,a:.006,dec:1.8,pk:1}); K.osc({f0:50,f1:24,gl:1,t,a:.006,dec:1.4,pk:1});
    K.noise({k:'b',f0:200,t,a:.1,dec:2.2,pk:.6}); K.noise({k:'k',type:'bandpass',f0:2000,q:.7,t:t+.06,a:.08,dec:2.4,pk:.3,to:L}); K.noise({k:'k',type:'bandpass',f0:1500,q:.7,t:t+.1,a:.08,dec:2.3,pk:.3,to:R});
    for(let i=0;i<4;i++){ const u=t+K.rv(.2,1.5); K.noise({k:'b',f0:1300,f1:180,t:u,dec:.22,pk:.4*(1-i*.12),to:i%2?R:L}); K.osc({f0:K.rv(70,100),f1:40,t:u,dec:.2,pk:.3}); }
    K.osc({type:'sawtooth',f0:55,f1:40,gl:1.4,lp:220,t:t+.2,a:.3,dec:1.2,pk:.14}); }},
  // ship systems
  phase:{bus:'impacts',g:.3,max:2,gap:.1,defer:.15,n:2,len:1.3,fn(K,t){ K.noise({k:'p',type:'bandpass',f0:400,f1:3000,gl:.3,q:2,t,a:.25,dec:.08,pk:.4}); K.osc({f0:300,f1:1800,gl:.3,t,a:.25,dec:.1,pk:.22});
    const u=t+.3; K.osc({f0:160,f1:50,t:u,dec:.3,pk:.6}); K.osc({f0:1200,t:u,dec:.5,pk:.1}); K.osc({f0:1800,t:u,dec:.4,pk:.07}); }},
  launch:{bus:'weapons',g:.28,max:3,gap:.12,defer:.2,n:3,len:.9,fn(K,t){ K.noise({k:'b',f0:900,f1:250,t,dec:.06,pk:.6}); K.osc({f0:130,f1:70,t,dec:.08,pk:.5});
    K.noise({k:'p',type:'bandpass',f0:400,f1:1700,gl:.5,q:1.2,t,a:.05,dec:.4,pk:.45}); K.osc({type:'triangle',f0:600,f1:900,lp:2000,t,a:.02,dec:.2,pk:.07}); }},
  engine:{bus:'impacts',g:.26,max:2,gap:.35,defer:0,n:2,len:1.4,fn(K,t){ K.noise({k:'b',f0:140,f1:230,gl:.4,q:1.5,t,a:.18,hold:.2,dec:.5,pk:.8}); K.osc({f0:48,t,a:.2,hold:.2,dec:.5,pk:.4}); K.noise({k:'p',type:'bandpass',f0:300,q:.8,t,a:.2,dec:.4,pk:.12}); }},
  cough:{bus:'impacts',g:.18,max:2,gap:.12,defer:0,n:3,len:.45,fn(K,t){ for(let i=0;i<2;i++){ const u=t+i*K.rv(.07,.11); K.noise({k:'b',f0:450,f1:120,q:2,t:u,dec:.09,pk:.6}); K.osc({f0:70,f1:50,t:u,dec:.08,pk:.3}); } }},
  puff:{bus:'impacts',g:.14,max:2,gap:.1,defer:0,n:2,len:.5,fn(K,t){ K.noise({k:'p',f0:900,f1:300,t,a:.02,dec:.22,pk:.5}); K.noise({k:'b',f0:300,t,a:.02,dec:.2,pk:.3}); }},
  // ui: soft and short
  ui_click:{bus:'ui',g:.12,max:2,gap:.03,defer:0,n:4,len:.12,pj:.015,first:1,fn(K,t){ const f=K.rv(1450,1700); K.osc({f0:f,f1:f*.75,gl:.02,t,a:.001,dec:.03,pk:.5}); K.osc({f0:f/2,t,a:.001,dec:.04,pk:.28}); K.noise({k:'p',type:'bandpass',f0:4000,q:2,t,dec:.01,pk:.12}); }},
  ui_confirm:{bus:'ui',g:.16,max:2,gap:.06,defer:0,n:1,len:.55,pj:0,first:1,fn(K,t){ K.osc({f0:660,t,a:.004,dec:.18,pk:.5}); K.osc({f0:1320,t,a:.004,dec:.1,pk:.08}); K.osc({f0:990,t:t+.07,a:.004,dec:.25,pk:.5}); K.osc({f0:1980,t:t+.07,a:.004,dec:.12,pk:.07}); }},
  ui_cancel:{bus:'ui',g:.14,max:2,gap:.06,defer:0,n:1,len:.45,pj:0,first:1,fn(K,t){ K.osc({type:'triangle',f0:520,lp:1500,t,a:.004,dec:.12,pk:.5}); K.osc({type:'triangle',f0:390,lp:1200,t:t+.06,a:.004,dec:.2,pk:.5}); }},
  ui_round:{bus:'ui',g:.2,max:1,gap:.3,defer:0,n:1,len:1.3,pj:0,fn(K,t){ K.osc({f0:440,t,a:.005,dec:.6,pk:.5}); K.osc({f0:880,t,a:.005,dec:.35,pk:.18}); K.osc({f0:1324,t,a:.005,dec:.2,pk:.08}); K.osc({f0:220,t,a:.005,dec:.7,pk:.3}); }},
  ui_your:{bus:'ui',g:.22,max:1,gap:.3,defer:0,n:1,len:1.4,pj:0,fn(K,t){ [[220,0],[277.18,.08],[329.63,.16],[440,.24]].forEach(([f,d],i)=>K.osc({type:'triangle',f0:f,lp:2200,t:t+d,a:.006,dec:.55,pk:i===3?.25:.4})); K.osc({f0:110,t,a:.01,dec:.6,pk:.25}); }},
  ui_enemy:{bus:'ui',g:.22,max:1,gap:.3,defer:0,n:1,len:1.5,pj:0,fn(K,t){ K.osc({type:'triangle',f0:146.83,lp:900,t,a:.008,dec:.6,pk:.45}); K.osc({type:'triangle',f0:110,lp:900,t,a:.008,dec:.6,pk:.3});
    K.osc({type:'triangle',f0:130.81,lp:900,t:t+.14,a:.008,dec:.65,pk:.45}); K.osc({f0:55,t,a:.02,dec:.8,pk:.3}); K.osc({f0:155.56,t:t+.14,a:.05,dec:.6,pk:.07}); }},
  sting_win:{bus:'ui',g:.4,max:1,n:1,len:4,st:1,pj:0,fn(K,t){ const L=K.pan(-.45), R=K.pan(.45);
    [220,277.18,329.63,440,493.88,554.37].forEach((f,i)=>{ const u=t+i*.1; K.osc({type:'triangle',f0:f,lp:1800,t:u,a:.06,hold:.3,dec:1.6,pk:.18,det:-6,to:L}); K.osc({type:'triangle',f0:f,lp:1800,t:u,a:.06,hold:.3,dec:1.6,pk:.18,det:6,to:R}); });
    K.osc({f0:880,t:t+.45,a:.004,dec:1,pk:.12,to:L}); K.osc({f0:1318.5,t:t+.55,a:.004,dec:1,pk:.08,to:R}); K.osc({f0:55,t,a:.2,dec:1.8,pk:.3}); }},
  sting_loss:{bus:'ui',g:.4,max:1,n:1,len:4,st:1,pj:0,fn(K,t){ const L=K.pan(-.4), R=K.pan(.4);
    [293.66,261.63,233.08,220].forEach((f,i)=>{ const u=t+i*.22; K.osc({type:'triangle',f0:f,lp:1100,t:u,a:.05,hold:.2,dec:1.2,pk:.2,det:-5,to:L}); K.osc({type:'triangle',f0:f,lp:1100,t:u,a:.05,hold:.2,dec:1.2,pk:.2,det:5,to:R}); });
    [146.83,174.61,220].forEach(f=>K.osc({type:'triangle',f0:f,lp:700,t,a:.3,hold:.5,dec:1.6,pk:.12})); K.osc({f0:73.42,t,a:.3,dec:2,pk:.3}); }},
  // added with the recorded set: each still has a synth take for when its clip is missing
  shield_break:{bus:'impacts',g:.42,max:2,gap:.1,defer:.15,pri:2,n:2,len:1.7,fn(K,t){ const f=K.rv(420,520);
    [[1,.9,.24],[1.5,.7,.18],[2.32,.5,.13],[3.01,.35,.08]].forEach(([r,d,a])=>{ K.osc({f0:f*r,f1:f*r*.9,t,a:.002,dec:d,pk:a,det:-6}); K.osc({f0:f*r,f1:f*r*.9,t,a:.002,dec:d*.9,pk:a*.7,det:7}); });
    K.noise({k:'w',type:'bandpass',f0:3500,f1:900,q:2,t,dec:.3,pk:.3}); K.osc({f0:160,f1:70,t,dec:.4,pk:.5}); K.noise({k:'k',type:'bandpass',f0:5000,q:1,t:t+.02,a:.02,dec:.8,pk:.18}); }},
  charge:{bus:'weapons',g:.32,max:1,gap:.5,defer:0,n:1,len:1.9,pj:0,fn(K,t){ K.osc({type:'triangle',f0:180,f1:900,gl:1.4,lp:2500,t,a:1.3,dec:.25,pk:.4,vib:30,vibHz:9}); K.osc({f0:90,f1:180,gl:1.4,t,a:1.3,dec:.25,pk:.4}); K.noise({k:'p',type:'bandpass',f0:500,f1:3000,gl:1.4,q:2,t,a:1.3,dec:.15,pk:.25}); }},
  bass_drop:{bus:'explosions',g:.5,max:1,gap:.5,defer:0,pri:4,n:1,len:2.4,pj:0,fn(K,t){ K.osc({f0:46,f1:24,gl:1.4,t,a:.01,dec:1.6,pk:1}); K.noise({k:'b',f0:120,t,a:.02,dec:1.2,pk:.4}); }},
  wreck:{bus:'explosions',g:.2,max:1,gap:1,defer:0,n:1,len:3,pj:.05,fn(K,t){ K.osc({type:'sawtooth',f0:58,f1:41,gl:2,lp:240,lq:2,t,a:.4,dec:1.6,pk:.5,vib:30,vibHz:1.3}); K.noise({k:'b',f0:300,t,a:.4,dec:1.5,pk:.4}); K.noise({k:'k',type:'bandpass',f0:1500,q:.8,t:t+.3,a:.3,dec:1.4,pk:.15}); }},
  ui_select:{bus:'ui',g:.13,max:2,gap:.04,defer:0,n:1,len:.3,pj:0,spj:.02,fn(K,t){ K.osc({f0:880,t,a:.003,dec:.09,pk:.5}); K.osc({f0:1320,t:t+.03,a:.003,dec:.1,pk:.3}); }},
  ui_panel:{bus:'ui',g:.12,max:2,gap:.06,defer:0,n:1,len:.3,pj:0,spj:.02,fn(K,t){ K.noise({k:'p',type:'bandpass',f0:900,f1:2400,gl:.08,q:1.2,t,a:.02,dec:.08,pk:.5}); K.osc({f0:600,t,a:.01,dec:.08,pk:.2}); }},
  ui_reward:{bus:'ui',g:.2,max:1,gap:.2,defer:0,n:1,len:1.2,pj:0,spj:.02,fn(K,t){ [523.25,659.25,783.99,1046.5].forEach((f,i)=>{ K.osc({f0:f,t:t+i*.06,a:.004,dec:.5,pk:.4}); K.osc({f0:f*2,t:t+i*.06,a:.004,dec:.2,pk:.08}); }); K.osc({f0:130.8,t,a:.01,dec:.5,pk:.3}); }},
  ui_alert:{bus:'ui',g:.18,max:1,gap:.5,defer:0,n:1,len:1.6,pj:0,spj:.02,fn(K,t){ K.osc({type:'triangle',f0:164.8,lp:900,t,a:.01,dec:.6,pk:.45}); K.osc({type:'triangle',f0:155.6,lp:900,t:t+.16,a:.01,dec:.7,pk:.45}); K.osc({f0:61.7,t,a:.03,dec:.9,pk:.35}); }},
  ui_boss:{bus:'ui',g:.3,max:1,gap:1,defer:0,n:1,len:2.6,st:1,pj:0,spj:.02,fn(K,t){ const L=K.pan(-.4), R=K.pan(.4); [73.42,110,146.83].forEach((f,i)=>{ K.osc({type:'triangle',f0:f,lp:600,t,a:.02,hold:.2,dec:1.5,pk:.3,det:-5,to:L}); K.osc({type:'triangle',f0:f,lp:600,t,a:.02,hold:.2,dec:1.5,pk:.3,det:5,to:R}); });
    K.osc({f0:48,f1:30,t,a:.005,dec:.9,pk:.8}); K.noise({k:'b',f0:500,f1:90,t,dec:.7,pk:.5}); }},
};

// Recorded clip layers per cue (keys are SFX_DATA keys). A cue plays its decoded clips (round robin, +-7% pitch unless spj says otherwise)
// plus its synth take when a {syn} layer is listed; if none of its clips decoded it plays the synth take alone.
// g = layer level, r = playback rate (pitch per faction), d = delay in seconds.
SFX.MAP={
  gun_shell:[{syn:1,g:.7},{s:'boomLow',g:.5,r:1.3}], gun_las:[{s:'laserLarge',r:.9},{syn:1,g:.3}], gun_needle:[{s:'laserSmall',r:1.3},{syn:1,g:.35}], gun_sq:[{s:'laserSmall',g:.8,r:1.05}],
  gun_plasma:[{syn:1,g:.85},{s:'laserLarge',g:.35,r:.62}], gun_rail:[{syn:1,g:.85},{s:'boomLow',g:.4,r:1.1}], salvo_tail:[{syn:1,g:.8},{s:'boomLow',g:.45,r:.75,d:.05}],
  lance:[{s:'laserLarge',g:.75,r:.55},{syn:1,g:.7}], lance_ion:[{s:'arc',g:.7},{syn:1,g:.6}], lance_dark:[{syn:1,g:.85},{s:'laserLarge',g:.35,r:.42}], lance_choir:[{syn:1,g:.8},{s:'laserSmall',g:.35,r:1.5}],
  torp:[{s:'whoosh',g:.75,r:1.1},{syn:1,g:.55}], torp_heavy:[{s:'whoosh',g:.7,r:.85},{syn:1,g:.7}], torp_star:[{s:'whoosh',g:.45,r:1.5},{syn:1,g:.7}],
  launch:[{s:'launch'}], phase:[{s:'whoosh',g:.6,r:1.2},{s:'arc',g:.4,d:.25}],
  hit:[{s:'hullHit'},{syn:1,g:.3}], hit_heavy:[{s:'hullHitBig'},{s:'boomLow',g:.45}], shield:[{s:'shieldHit'},{syn:1,g:.35}], shield_break:[{s:'shieldBig'},{s:'shieldHit',g:.5,r:.8},{syn:1,g:.3}],
  pop:[{s:'boomSmall',g:.8,r:1.35}], boom_s:[{s:'boomSmall'},{syn:1,g:.3}], boom_m:[{s:'boomSmall',r:.8},{s:'boomLow',g:.65},{s:'debris',g:.4,d:.15}], boom_l:[{s:'boomBig'},{s:'debris',g:.45,d:.3}],
  bass_drop:[{s:'bassDrop'}], charge:[{s:'ionCharge'}], wreck:[{s:'scrape'}],
  ui_click:[{s:'uiClick'}], ui_confirm:[{s:'uiConfirm'}], ui_cancel:[{s:'uiDeny'}], ui_select:[{s:'uiSelect'}], ui_panel:[{s:'uiPanel'}], ui_reward:[{s:'reward'}],
  ui_your:[{s:'yourTurn'}], ui_alert:[{s:'enemyTurn',g:.6}], ui_boss:[{s:'impactChord'}], sting_win:[{s:'victory'},{syn:1,g:.55}], sting_loss:[{s:'enemyTurn',r:.8},{syn:1,g:.6}],
};
for(const k of ['ui_click','ui_confirm','ui_cancel','ui_round','ui_your','ui_enemy','sting_win','sting_loss']) SFX.CUES[k].spj=k.startsWith('sting')?0:.02;

// Recorded clips live in sfx_data.js (SFX_DATA = {cueName:[base64,...]}); they are decoded on the first gesture.
if(typeof SFX_DATA!=='undefined') SFX.registerSamples(SFX_DATA);
// The browser only lets sound start from a user gesture (and phones suspend it in the background).
if(typeof window!=='undefined'&&typeof document!=='undefined'){
  const wake=()=>{ try{ SFX.init(); SFX.resume(); }catch(e){} };
  for(const ev of ['pointerdown','touchend','keydown']) document.addEventListener(ev,wake,{capture:true,passive:true});
  document.addEventListener('visibilitychange',()=>{ try{ const c=SFX.ctx; if(!c) return; if(document.hidden){ if(c.state==='running') c.suspend(); } else SFX.resume(); }catch(e){} });
  // Sound test: window.sfxTest() plays every cue in order; open the page with ?sfx=1 for a panel of buttons.
  SFX.TESTS=[['gun: kinetic shell',s=>s.gun('gun',false,'shell')],['gun: twin',s=>s.gun('gun',false,'twin')],['gun: las (Voidsworn)',s=>s.gun('gun',false,'las')],['gun: plasma (Hegemony)',s=>s.gun('gun',false,'plasma')],
    ['gun: tracer (Corsair)',s=>s.gun('gun',false,'tracer')],['gun: spine (Chorus)',s=>s.gun('gun',false,'spine')],['gun: glob (bio)',s=>s.gun('gun',false,'glob')],['gun: needle (Ithar)',s=>s.gun('gun',false,'needle')],['gun: rail (Deathless)',s=>s.gun('gauss',false,'rail')],
    ['gun: flak',s=>s.gun('flak',false)],['gun: squadron',s=>s.gun('gun',true)],['broadside x12 (salvo aggregation)',s=>{ for(let i=0;i<12;i++) setTimeout(()=>s.gun('gun',false,'shell',{pan:(i/11-.5)*1.2}),i*28); }],
    ['lance',s=>s.lance(false,'hegemony')],['lance: ion',s=>s.lance(true,'voidsworn')],['lance: Deathless',s=>s.lance(false,'deathless')],['lance: Ithar',s=>s.lance(false,'ithar')],
    ['torpedo',s=>s.torp('hegemony')],['torpedo: Corsair rockets',s=>s.torp('corsair')],['torpedo: Chorus sac',s=>s.torp('chorus')],['torpedo: Ithar star',s=>s.torp('ithar')],['torpedo: Voidsworn heavy',s=>s.torp('voidsworn')],
    ['hull hit',s=>s.hit()],['hull hit heavy',s=>s.hit(null,true)],['shield hit',s=>s.shield()],['shield facing collapses',s=>s.shield(null,true)],['patter hull',s=>s.patter(false)],['patter shield',s=>s.patter(true)],
    ['fighter destroyed (pop)',s=>s.pop()],['boom 0.12 (burning hull)',s=>s.boom(.12)],['boom 0.3 (frigate)',s=>s.boom(.3)],['boom 0.6',s=>s.boom(.6)],['boom 0.8 (torpedo)',s=>s.boom(.8)],['boom 1.2 (capital)',s=>s.boom(1.2)],['boom 1.5 (reactor)',s=>s.boom(1.5)],
    ['pan left to right',s=>{ [-1,-.5,0,.5,1].forEach((p,i)=>setTimeout(()=>s.hit({pan:p}),i*220)); }],
    ['phase jump',s=>s.phase()],['nova charge',s=>s.charge()],['launch',s=>s.launch()],['engine small',s=>s.engine(1)],['engine capital',s=>s.engine(4)],['engine cough',s=>s.cough()],['puff',s=>s.puff()],
    ['ui click',s=>s.click()],['ui confirm',s=>s.confirm()],['ui cancel',s=>s.cancel()],['ui select',s=>s.select()],['ui panel',s=>s.click('settings')],['ui reward',s=>s.reward()],['round start',s=>s.turn('round')],['your turn',s=>s.turn('player')],['enemy turn',s=>s.turn('enemy')],['boss warning',s=>s.banner('X next round','#ff8a6a')],['boss arrival',s=>s.banner('Sector flagship')],
    ['victory sting',s=>s.sting(true)],['defeat sting',s=>s.sting(false)]];
  window.sfxTest=async(gap=1100,only)=>{ SFX.init(); if(!SFX.ctx) return []; if(!G.sfxOn) SFX.setOn(true); SFX.resume(); await SFX.whenReady(); const done=[];
    for(const [n,f] of SFX.TESTS){ if(only&&!n.includes(only)) continue; try{ f(SFX); done.push(n); console.log('sfx:',n); }catch(e){ console.warn('sfx test',n,e); } await new Promise(r=>setTimeout(r,/sting|boom 1|broadside/.test(n)?gap*2.6:gap)); } return done; };
  if(/[?&]sfx=1/.test(location.search)) window.addEventListener('load',()=>{ const d=document.createElement('div'); d.id='sfxpanel';
    d.style.cssText='position:fixed;left:8px;top:8px;z-index:99999;max-width:min(560px,calc(100vw - 16px));max-height:calc(100vh - 16px);overflow:auto;background:rgba(8,10,14,.92);color:#ddd;font:12px system-ui;padding:8px;border:1px solid #445;border-radius:6px';
    d.innerHTML='<b>Sound test</b> <button data-x="all">Play all</button> <button data-x="stop">Stop</button> <label>Vol <input type="range" min="0" max="100" value="'+Math.round(SFX.getVol()*100)+'"></label> <button data-x="hide">x</button><div></div>';
    const box=d.lastChild; SFX.TESTS.forEach(([n],i)=>{ const b=document.createElement('button'); b.textContent=n; b.dataset.i=i; b.style.margin='2px'; box.appendChild(b); });
    d.addEventListener('click',e=>{ const b=e.target.closest('button'); if(!b) return; e.stopPropagation(); SFX.init(); if(!G.sfxOn) SFX.setOn(true); SFX.resume();
      if(b.dataset.x==='all') window.sfxTest(); else if(b.dataset.x==='stop') SFX.stopAll(); else if(b.dataset.x==='hide') d.remove(); else if(b.dataset.i!=null) SFX.whenReady().then(()=>SFX.TESTS[+b.dataset.i][1](SFX)); });
    d.querySelector('input').addEventListener('input',e=>SFX.setVol(e.target.value/100)); d.querySelector('input').addEventListener('change',e=>SFX.setVol(e.target.value/100,true));
    document.body.appendChild(d); });
}
