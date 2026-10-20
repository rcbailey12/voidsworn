// ======================= LOADING AND PHONE PERFORMANCE (v53) =======================
// is anything on screen moving? phones render every frame while it is, and skip frames only when the board is still
function sceneAnimating(){ try{
    if(G.tweens>0) return true;
    if(typeof B!=='undefined'&&B&&(B.busy||B.ending&&!document.getElementById('endcard'))) return true;
    if(PROJ.length||TORPS.size) return true;
    if(performance.now()-G.lastInput<700) return true; // a finger on the glass: camera drags stay smooth
    for(const h of G.hulks||[]) if(G.time-h.t0<8) return true;
    const c=G.cam, k=G.ctl; if(c&&k&&!k.attract&&(Math.abs(k.a-c.alpha)>.01||Math.abs(k.b-c.beta)>.01||Math.abs(k.r-c.radius)>1||V3.DistanceSquared(k.t,c.target)>.25)) return true;
    for(const v of G.views.values()){ if(v.arrive||v.launch||v.slide||v.jolt||v.state==='dying'||(v.u&&v.u.vis)) return true; const C=v.coast; if(C&&C.vc>.3) return true; const P=v.ph; if(P&&Math.abs(P.vx)+Math.abs(P.vz)>1.5) return true; /* above the hold-station sway */ }
  }catch(e){} return false; }

// ---------- hulls: the first battle waits for the fetch (started before the title), with a progress line ----------
function hullTag(){ try{ const h=hullPath(); return h.path+' '+h.loaded+'/'+h.total+(h.failed?' ('+h.failed+' failed)':'')+(h.state==='loading'?' loading':''); }catch(e){ return null; } }
function hullProgressUI(){ const S=HULLS_LOAD; let el=document.getElementById('hullprog');
  if(S.state!=='loading'){ if(el) el.remove(); return; }
  if(!el){ el=document.createElement('div'); el.id='hullprog'; el.setAttribute('aria-live','polite'); el.style.cssText='position:fixed;right:12px;bottom:10px;z-index:60;font-size:12px;opacity:.75;pointer-events:none;color:var(--bone,#ddd);font-variant-numeric:tabular-nums'; document.body.appendChild(el); }
  el.textContent='Loading ship hulls '+(S.loaded+S.failed)+'/'+S.total; }
function startHullLoad(){ try{ HULLS_LOAD.onProgress=()=>{ hullProgressUI(); const w=document.getElementById('hullwait'); if(w){ const b=w.querySelector('b'); if(b) b.textContent=(HULLS_LOAD.loaded+HULLS_LOAD.failed)+'/'+HULLS_LOAD.total; } };
    const p=loadAIHulls(); hullProgressUI(); p.then(()=>hullProgressUI(),()=>hullProgressUI()); }catch(e){ console.warn('hull load',e); } }
// a battle started while the fetch is still running shows a short wait (never more than 12 s, with a skip) instead of building procedural ships
function whenHullsReady(go){ const S=HULLS_LOAD; if(S.state!=='loading'||!aiHullsOn()||!S.promise) return go();
  if(document.getElementById('hullwait')) return; // a second tap while waiting does not queue a second battle
  let done=false; const t0=performance.now();
  const fin=why=>{ if(done) return; done=true; clearTimeout(to); const w=document.getElementById('hullwait'); if(w) w.remove(); try{ tel('hull_wait',{ms:Math.round(performance.now()-t0),why,hulls:hullTag()}); }catch(e){} go(); };
  const to=setTimeout(()=>fin('timeout'),12000);
  const w=document.createElement('div'); w.id='hullwait'; w.className='hud'; w.style.cssText='position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);z-index:80;padding:16px 22px;text-align:center;background:rgba(6,10,18,.88);border:1px solid rgba(160,190,230,.25);border-radius:8px';
  w.innerHTML='<div>Loading ship hulls <b class="num">'+(S.loaded+S.failed)+'/'+S.total+'</b></div><button style="margin-top:10px" data-hullskip="1">Start now</button>';
  w.querySelector('button').addEventListener('click',()=>fin('skip')); document.body.appendChild(w);
  S.promise.then(()=>fin('done'),()=>fin('error')); }
{ const _bs=battleScreen; battleScreen=function(cfg){ return whenHullsReady(()=>_bs(cfg)); }; }
{ const _sk=ACT.c3skirmish; ACT.c3skirmish=function(){ return whenHullsReady(()=>_sk.apply(this,arguments)); }; }
// every battle's telemetry says which hull path it was built with
{ const _tel=tel; tel=function(ev,d){ if(ev==='battle_start'||ev==='battle_end'||ev==='session') d=Object.assign({hulls:hullTag()},d||{}); if(ev==='battle_end'&&PERFCAP.on) d.prof=PERFCAP.summary||null; return _tel(ev,d); }; }

// ---------- ?prof=1 (or Settings > Profiler): Babylon's performance collector for one battle, exported as CSV ----------
const PERFCAP={on:false,added:false,col:null,summary:null,csv:null};
function profWanted(){ try{ return /[?&]prof=1\b/.test(location.search)||!!(META.opts&&META.opts.prof); }catch(e){ return false; } }
function profSetup(){ if(PERFCAP.added||!G.scene) return; const S=BABYLON.PerfCollectionStrategy; if(!S||!G.scene.getPerfCollector) return;
  const col=G.scene.getPerfCollector(), list=[['FpsStrategy'],['FrameTotalStrategy'],['RenderStrategy'],['InterFrameStrategy'],['DrawCallsStrategy'],['ActiveMeshesStrategy'],['ActiveIndicesStrategy'],['TotalTexturesStrategy'],['ActiveParticlesStrategy'],['GpuFrameTimeStrategy']];
  for(const [k] of list){ try{ if(typeof S[k]==='function') col.addCollectionStrategies({strategyCallback:S[k](),category:'voidsworn'}); }catch(e){ console.warn('perf strategy',k,e); } }
  PERFCAP.col=col; PERFCAP.added=true; }
function profStart(){ if(!PERFCAP.on) return; try{ profSetup(); if(!PERFCAP.col) return; if(PERFCAP.col.isStarted) PERFCAP.col.stop(); PERFCAP.col.start(false); PERFCAP.summary=null; PERFCAP.csv=null; PERFCAP.t0=performance.now(); }catch(e){ console.warn('profiler',e); } }
function profSetOn(on){ PERFCAP.on=!!on; if(PERFCAP.on){ profStart(); } else if(PERFCAP.col&&PERFCAP.col.isStarted) PERFCAP.col.stop(); }
// the collector writes its CSV through BABYLON.Tools.Download; borrow it for a moment to get the text instead
function profCsv(){ if(!PERFCAP.col) return null; const T=BABYLON.Tools, keep=T.Download; let txt=null; T.Download=(blob)=>{ txt=blob; }; try{ PERFCAP.col.exportDataToCsv(); }finally{ T.Download=keep; } return txt; }
function profSummarize(text){ const lines=text.split('\n').filter(Boolean); if(lines.length<2) return null; const head=lines[0].split(','), cols=head.slice(2).map(h=>h.replace(/@.*$/,'')), vals=cols.map(()=>[]);
  for(let i=1;i<lines.length;i++){ const r=lines[i].split(','); for(let c=0;c<cols.length;c++){ const x=parseFloat(r[c+2]); if(isFinite(x)) vals[c].push(x); } }
  const out={frames:lines.length-1,secs:Math.round((performance.now()-(PERFCAP.t0||0))/1000),q:G.quality,mob:!!G.mobile,rw:G.engine.getRenderWidth(),rh:G.engine.getRenderHeight(),hulls:hullTag()};
  cols.forEach((n,c)=>{ const a=vals[c].sort((x,y)=>x-y); if(!a.length) return; const q=p=>Math.round(a[Math.min(a.length-1,Math.floor(a.length*p))]*100)/100; const key=n.replace(/[^A-Za-z]+/g,'_').replace(/^_|_$/g,'').toLowerCase(); out[key]={p50:q(.5),p90:q(.9),p99:q(.99),max:q(1)}; });
  return out; }
function profBattleEnd(){ if(!PERFCAP.on||!PERFCAP.col) return; try{ const blob=profCsv(); PERFCAP.col.stop(); if(!blob) return;
    blob.text().then(t=>{ PERFCAP.csv=t; PERFCAP.summary=profSummarize(t); try{ tel('perf_prof',PERFCAP.summary||{}); }catch(e){} console.info('[prof] '+JSON.stringify(PERFCAP.summary)); profButton(); }); }catch(e){ console.warn('profiler export',e); } }
function profButton(){ const card=document.getElementById('endcard'); if(!card||card.querySelector('[data-profcsv]')||!PERFCAP.csv) return; const row=document.createElement('div'); row.className='row'; row.style.cssText='justify-content:center;margin-top:10px';
  const s=PERFCAP.summary||{}, ft=s.frame_total_time||s.frame_total||null; row.innerHTML='<button data-profcsv="1">Download perf CSV</button><button data-profcopy="1">Copy perf CSV</button>'+(ft?'<span class="muted num" style="margin-left:8px">frame p50 '+ft.p50+' ms, p90 '+ft.p90+' ms</span>':'');
  row.querySelector('[data-profcsv]').addEventListener('click',profDownload); row.querySelector('[data-profcopy]').addEventListener('click',profCopy); card.appendChild(row); }
async function profDownload(){ const csv=PERFCAP.csv; if(!csv) return; const name='voidsworn-perf-'+(typeof BUILD_ID!=='undefined'?BUILD_ID:'dev')+'-'+new Date().toISOString().replace(/[:.]/g,'-').slice(0,19)+'.csv';
  try{ const dl=window.claude&&typeof window.claude.use==='function'?await window.claude.use('downloads'):null; // claude.ai artifact: the viewer confirms the save
    if(dl){ try{ await dl.save({filename:name,data:new Blob([csv],{type:'text/csv'})}); toast('Perf CSV saved.'); return; }catch(e){ if(e&&e.code==='declined') return; console.warn('downloads',e); } } }catch(e){}
  try{ const a=document.createElement('a'); a.href=URL.createObjectURL(new Blob([csv],{type:'text/csv'})); a.download=name; document.body.appendChild(a); a.click(); setTimeout(()=>{ URL.revokeObjectURL(a.href); a.remove(); },4000); toast('Perf CSV download started. If nothing appears, use Copy perf CSV.'); }catch(e){ profCopy(); } }
function profCopy(){ const csv=PERFCAP.csv; if(!csv) return; const manual=()=>modal('<h2>Perf CSV</h2><p class="muted">Select all and copy:</p><textarea readonly style="width:100%;height:240px;font-size:11px" onclick="this.select()">'+esc(csv)+'</textarea><div class="row" style="margin-top:10px"><button class="primary" data-act="c3optClose">Done</button></div>');
  try{ if(navigator.clipboard&&navigator.clipboard.writeText) navigator.clipboard.writeText(csv).then(()=>toast('Perf CSV copied ('+Math.round(csv.length/1024)+' KB).'),manual); else manual(); }catch(e){ manual(); } }
// one capture per battle: restart with each battle's frame counters, export when the end card appears
{ const _r=FRAMES.reset; FRAMES.reset=function(){ const x=_r.apply(this,arguments); if(PERFCAP.on) profStart(); return x; }; }
{ const _e=endBattleFlow; endBattleFlow=async function(){ const x=await _e.apply(this,arguments); try{ profBattleEnd(); }catch(e){} return x; }; }
// Settings: a Profiler row under the others
{ const _h=settingsHtml; settingsHtml=function(){ const h=_h(); const row=`<div class="row" style="margin:6px 0"><span style="flex:1">Profiler (perf CSV after each battle)</span><button data-act="c3opt" data-arg="prof">${PERFCAP.on?'On':'Off'}</button></div>`; const at=h.lastIndexOf('<div class="row" style="margin-top:14px">'); return at>0?h.slice(0,at)+row+h.slice(at):h+row; }; }
{ const _o=ACT.c3opt; ACT.c3opt=function(k){ if(k==='prof'){ META.opts=META.opts||{}; META.opts.prof=!PERFCAP.on; profSetOn(META.opts.prof); toast(PERFCAP.on?'Profiler on: a perf CSV is offered at the end of each battle':'Profiler off'); } return _o.apply(this,arguments); }; }
