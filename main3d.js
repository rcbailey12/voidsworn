// ======================= BOOT =======================
// Only the real browser supplies profile preferences. Bots and parity load the rules without this boot file.
const _teachingNewRun=newRun;
newRun=function(admiral,fac,opt){ initFinishedRuns(); return _teachingNewRun(admiral,fac,Object.assign({},opt,{teachingGate:!(META.opts||{}).tipsOff})); };
function initFinishedRuns(){
  // Old profiles only counted launches. Exclude their one unfinished saved run when migrating.
  if(META.stats.finishedRuns==null) META.stats.finishedRuns=Math.max(0,(META.stats.runs||0)-((RUN&&!RUN.over||SAVED_RUN&&!SAVED_RUN.over)?1:0));
}
function syncTeachingGate(){
  if(!RUN) return;
  initFinishedRuns();
  const on=!(META.opts||{}).tipsOff&&META.stats.finishedRuns<2;
  if(on||'teachingGate' in RUN) RUN.teachingGate=on;
  const first=RUN.sector===1&&RUN.map&&RUN.map.cols&&RUN.map.cols[0][0];
  if(first){
    if(on&&!first.done){ if(!('teachingShape' in first)) first.teachingShape=first.shape; first.shape='open'; }
    else if('teachingShape' in first){ first.shape=first.teachingShape; delete first.teachingShape; }
  }
}
const _teachingMap=mapScreen, _teachingBattle=battleScreen;
mapScreen=function(){ syncTeachingGate(); return _teachingMap(); };
battleScreen=function(cfg){ syncTeachingGate(); return _teachingBattle(cfg); };
const _teachingOff=ACT.tipOff, _teachingOpts=ACT.c3opt;
ACT.tipOff=()=>{ _teachingOff(); syncTeachingGate(); };
ACT.c3opt=k=>{ _teachingOpts(k); syncTeachingGate(); };
(async function(){
  if(!window.BABYLON){ document.getElementById('loading').textContent='The 3D engine failed to load. Check your connection and reload the page.'; return; }
  const canvas=document.getElementById('c3d');
  // the cache must never block boot: give it 3 s, then start without it
  const T0=performance.now(), bl=s=>console.debug('[boot] '+s+' '+Math.round(performance.now()-T0)+'ms');
  try{ await Promise.race([TexCache.init(),new Promise(r=>setTimeout(r,3000))]); }catch(e){}
  bl('cache ready ('+TexCache.mem.size+' cached)');
  try{ init3D(canvas); bl('engine ready'); }catch(e){ console.error(e); document.getElementById('loading').textContent='WebGL is unavailable in this browser, so the 3D view can\u2019t start.'; return; }
  buildHud(); bindInput(canvas);
  Persist.loadLocal(); { const o=META.opts||{}; if(o.fxSet) G.fxReduced=!!o.fxReduced; else if(G.mobile) G.fxReduced=false; else if(o.fxReduced!=null) G.fxReduced=!!o.fxReduced; G.shakeRed=o.shakeRed!=null?!!o.shakeRed:!!(o.fxSet&&o.fxReduced)||!!G.fxReduced; /* v53-I: screen shake has its own toggle; old saves with reduced flashes keep shake reduced */ /* v35: phones start cinematic (full flashes) until the player chooses; Reduced is one tap away in Settings */ if(o.quality) G.quality=o.quality; else if(G.mobile) G.quality='medium'; if(o.sfxOn!=null) G.sfxOn=!!o.sfxOn; if(o.cine!=null) G.cine=!!o.cine; if(o.alt!=null) SETUP.alt=!!o.alt; if(o.fast) SPEED=.45; if(o.ai) AI_LEVEL=o.ai; else if((META.stats&&META.stats.runs)>0) AI_LEVEL='veteran'; if(o.unlockAll!==false){ for(const k in LEGACY) META.unlocked[k]=true; for(const k in ADMIRALS) META.admirals[k]=true; } G.cineMode=o.cineMode||'key'; G.cine=G.cineMode!=='off'; G.aiHulls=o.aiHulls!==false; /* v45: cut-ins on key moments by default, tap to skip */ G.follow=o.follow==null?true:!!o.follow; /* v35: action camera on by default on phones (kills and big hits), camera follows enemy moves */ if(o.taa) G.taaOn=true; } setQuality(G.quality);
  try{ startHullLoad(); bl('hull fetch started ('+HULLS_LOAD.total+' files)'); }catch(e){} /* v53: before the title, all files at once; the first battle waits for it */ try{ if(profWanted()) profSetOn(true); }catch(e){}
  onPersistLoaded=()=>{ if(!RUN && document.querySelector('.title .menu')) titleScreen(); };
  mergeLocalTel(); titleScreen(); tel('session',{bootMs:Math.round(performance.now()),quality:G.quality,mobile:!!G.mobile,w:innerWidth,h:innerHeight,dpr:devicePixelRatio||1});
  Persist.connect();
  // the loading veil must never trap input: remove it when the scene is ready, or after 12 s regardless
  { const kill=()=>{ const l=document.getElementById('loading'); if(l) l.remove(); }; G.scene.executeWhenReady(kill); setTimeout(kill,12000); }
})();
// v45: a battle left mid-fight (tab closed or app backgrounded for good) leaves a marker, so abandonment shows up in telemetry before any save redesign
window.addEventListener('pagehide',()=>{ try{ if(typeof B!=='undefined'&&B&&!B.over&&!B._abandonLogged&&typeof tel==='function'){ B._abandonLogged=1; let perf=null; try{ perf=FRAMES.summary(); }catch(e){} tel('battle_abandon',{round:B.round,side:B.side,perf}); if(typeof Persist!=='undefined'&&Persist.saveLocal) Persist.saveLocal(); } }catch(e){} });
