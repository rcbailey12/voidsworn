#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),cp=require('child_process');
const root=path.resolve(__dirname,'../../../..'),base=path.resolve(__dirname,'..'),dest=path.join(base,'candidates/lineage_pilot');
const catalog=require('../data/catalog.json'),roster=require('../data/roster.json');
const spec={catalog:{version:1,skills:catalog.skills.filter(s=>s.availability==='pilot_candidate')},roster};
function source(file){return cp.execFileSync('git',['show','355a2ac7:'+file],{cwd:root,encoding:'utf8'});}
function save(file,text){const p=path.join(dest,file);fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,text);}
function replace(s,a,b,label){if(!s.includes(a))throw Error('Source drift '+label);return s.replace(a,b);}
const runtime=fs.readFileSync(path.join(base,'src/lineage.js'),'utf8').replace("if(typeof module==='object'&&module.exports)module.exports=api;else root.VSLineage=api;","root.VSLineage=api;"),pilot=fs.readFileSync(path.join(base,'src/pilot.js'),'utf8').replace("if(typeof module==='object'&&module.exports)module.exports=api;else root.VSLineagePilot=api;","root.VSLineagePilot=api;");
const adapters=`
const LINEAGE_PILOT_SPEC=${JSON.stringify(spec)};
const LINEAGE_PILOT_ENGINE=VSLineage.create(LINEAGE_PILOT_SPEC.catalog,LINEAGE_PILOT_SPEC.roster);
function lineagePilotState(meta){ const state=meta.lineageV1||LINEAGE_PILOT_ENGINE.newState(meta.mastery||{}); LINEAGE_PILOT_ENGINE.validate(state); return state; }
function lineagePilotMasteryXP(meta,id){ const s=VSLineagePilot.snapshot(meta,id); return s?s.xpQ/4:null; }
function lineagePilotAward(meta,run,stats,victory,heat){
  if(run.admiral!=='vaelen'||!meta.opts||meta.opts.lineagePilot!==true) return null;
  try{ const id='run:'+String(run.t0||0)+':'+run.admiral+':'+String(meta.stats.runs||0);
    const heirLines=Object.keys(meta.lineageHeirs||{}).filter(k=>meta.lineageHeirs[k]===true&&k!=='vaelen'&&LINEAGE_PILOT_SPEC.roster.admirals.some(a=>a.id===k&&a.fac==='ithar'));
    const r=LINEAGE_PILOT_ENGINE.award(lineagePilotState(meta),{id:'vaelen',stats,victory,heat,heirLines,settlementId:id});
    meta.lineageV1=r.state; return r.duplicate?0:r.report.baseXp+r.report.heatXp;
  }catch(e){ console.warn('Lineage pilot kept the original save and used native XP: '+e.message); return null; }
}
`;
for(const f of ['core.js','godot/campaign/test/oracle/core.js','godot/rules/test/oracle/core.js']){
 let s=source(f);
 s=replace(s,"function masteryXP(id){ return (META.mastery&&META.mastery[id])||0; }","function masteryXP(id){ const x=lineagePilotMasteryXP(META,id); return x===null?((META.mastery&&META.mastery[id])||0):x; }",f+' mastery');
 s=replace(s,'  RUN.heat=(opt.heat||[])','  RUN.lineagePilot=VSLineagePilot.snapshot(META,admiralId);\n  RUN.heat=(opt.heat||[])',f+' snapshot');
 s+='\n// Opt-in, two-effect lineage prototype. Original source rules remain the default.\n'+(runtime+'\n'+pilot).split('\n').map(l=>l?'  '+l:'').join('\n')+adapters;save(f,s);
}
const barrage=`  if(c.id==='barrage'){
    const b0=B, live=liveFrom(null), lp=lineageCommandIntent(side,c);
    if(!lp.ok) return false;
    const previous=B.volleyMul; B.volleyMul={side,m:1+cmdPow('barrage',tier)};
    if(lp.mode==='adm.vaelen.A1.1') delete B.lineageIntent;
    try{ for(const u of alive(side).filter(x=>!x.isSq)){
      if(B.over||!live()) break;
      const keep=u.weapons.map(w=>({w,fired:w.fired,cdLeft:w.cdLeft,shots:w.shots})), pf=[u.postFire,u.postMp];
      try{ u.weapons.forEach(w=>{w.fired=false;w.cdLeft=0;});
        for(let i=0;i<u.weapons.length;i++){
          if(B.over||!live()||u.dead) break;
          if(!VSLineagePilot.allows(lp,u,i)) continue;
          const w=u.weapons[i], single=lp.mode==='adm.vaelen.A1.1'&&lp.weapons[u.id]!=null;
          if(single) w.shots=1;
          const ts=alive(foe).filter(t=>canFire(u,w,t)); if(!ts.length) continue;
          const val=t=>{const prior=b0.volleyMul;b0.volleyMul={side,m:prior.m*VSLineagePilot.factor(lp,u,w,t,hdist(u,t))};try{const e=expectedVs(u,w,t);return e.hull+e.shield*.3+(e.hull>=t.hp?25:0);}finally{b0.volleyMul=prior;}};
          ts.sort((a,b2)=>val(b2)-val(a)); const target=ts[0], prior=b0.volleyMul;
          b0.volleyMul={side,m:prior.m*VSLineagePilot.factor(lp,u,w,target,hdist(u,target))};
          try{await fireWeapon(u,i,target);}finally{b0.volleyMul=prior;}
        }
      }finally{for(const k of keep){k.w.fired=k.fired;k.w.cdLeft=k.cdLeft;k.w.shots=k.shots;}u.postFire=pf[0];u.postMp=pf[1];}
    }}finally{b0.volleyMul=previous==null?null:previous;}
  }
`;
for(const f of ['battle.js','godot/campaign/test/oracle/battle.js','godot/rules/test/oracle/battle.js']){
 let s=source(f);const start=s.indexOf("  if(c.id==='barrage'){",s.indexOf('async function runCommand(')),end=s.indexOf("  if(c.id==='hunt')",start);
 if(start<0||end<0)throw Error('Barrage block drift '+f);s=s.slice(0,start)+barrage+s.slice(end);
 s=replace(s,'async function runCommand(side,c,tier){',`function lineageCommandIntent(side,c){
  const lp=VSLineagePilot.intent(typeof RUN==='undefined'?null:RUN,side,c,B);
  if(!lp.ok) return lp;
  if(lp.mode==='adm.vaelen.A1.1') for(const [id,index] of Object.entries(lp.weapons)) if(index!==null){const u=B.units.find(x=>x.id===id);if(!alive(side==='player'?'enemy':'player').some(t=>inReach(u,u.weapons[index],t))) return {ok:false};}
  return lp;
}
async function runCommand(side,c,tier){`,f+' intent helper');
 s=replace(s,"const tier=cmdTier(); B.cmdUsed=true;", "const tier=cmdTier(); if(!lineageCommandIntent(side,c).ok) return false; B.cmdUsed=true;",f+' validate');save(f,s);
}
for(const cmFile of ['campaign_meta.js','godot/campaign/test/oracle/campaign_meta.js']){
let cm=source(cmFile);
cm=replace(cm,"const mx0=masteryLevel(RUN.admiral), mxGain=s.battles+s.elites*2+s.bosses*5+(victory?10:0);", "const mx0=masteryLevel(RUN.admiral), lx=lineagePilotAward(META,RUN,s,!!victory,hl), mxGain=lx===null?s.battles+s.elites*2+s.bosses*5+(victory?10:0):lx;",'campaign XP');
const start=cm.indexOf('function masteryBar('),end=cm.indexOf('function runOptionsHtml(',start);let bar=cm.slice(start,end);
bar=replace(bar,'</i></div></div>`; }','</i></div></div>`+(id===\'vaelen\'?\'<button class="small" data-act="lineagePilot">Saro lineage prototype</button>\':\'\'); }','pilot button');cm=cm.slice(0,start)+bar+cm.slice(end);
cm+=`
// Prototype picker: between runs only; preserves the original META fields.
function lineagePilotBetweenRuns(){ return !(RUN&&!RUN.over)&&!(SAVED_RUN&&!SAVED_RUN.over); }
function lineagePilotMenu(){
  if(!lineagePilotBetweenRuns()){toast('Finish or abandon the current run before changing lineage.');return;}
  try{const state=lineagePilotState(META),line=state.lines.vaelen;
    modal('<h2>Saro: lineage prototype</h2><p>Two tier-1 effects are implemented. Other tree effects are not selectable in this prototype.</p><p>'+line.xpQ/4+' XP; first choice at 75 XP. Renown: '+(META.renown||0)+'.</p>'+LINEAGE_PILOT_SPEC.catalog.skills.map(s=>'<button class="choice" data-act="lineagePilotChoose" data-arg="'+s.id+'" '+(line.picks.length||line.xpQ<300?'disabled':'')+'><b>'+esc(s.name)+'</b><small>'+esc(s.effect)+'</small></button>').join('')+'<p>Current: '+esc(line.picks.map(id=>LINEAGE_PILOT_SPEC.catalog.skills.find(s=>s.id===id).name).join(', ')||'none')+'</p>'+(line.picks.length?'<button data-act="lineagePilotRespec">Respec ('+(25+10*line.respecs)+' renown)</button>':'')+'<button data-act="lineagePilotToggle">'+(META.opts.lineagePilot?'Disable':'Enable')+' for future Saro runs</button><button data-act="lineagePilotClose">Back to mastery</button><p class="dim">Focus Drawn Long measures each weapon’s printed range. One Lens fires one projectile from a selected weapon; normal volley remains available per ship. Heat shadow pools and overflow are banked by the documented prototype policy.</p>');
  }catch(e){toast('Lineage save preserved: '+e.message);}
}
ACT.lineagePilot=()=>lineagePilotMenu();
ACT.lineagePilotClose=()=>{closeModal();progTab='mastery';legacyScreen();};
ACT.lineagePilotChoose=key=>{if(!lineagePilotBetweenRuns())return;try{const state=LINEAGE_PILOT_ENGINE.choose(lineagePilotState(META),'vaelen',key);META.lineageV1=state;META.opts.lineagePilot=true;Persist.save();lineagePilotMenu();}catch(e){toast(e.message);}};
ACT.lineagePilotRespec=()=>{if(!lineagePilotBetweenRuns())return;try{const state=lineagePilotState(META),r=LINEAGE_PILOT_ENGINE.respec(state,'vaelen',state.lines.vaelen.picks,META.renown||0);META.lineageV1=r.state;META.renown=r.wallet;Persist.save();lineagePilotMenu();}catch(e){toast(e.message);}};
ACT.lineagePilotToggle=()=>{if(!lineagePilotBetweenRuns())return;META.lineageV1=JSON.parse(JSON.stringify(lineagePilotState(META)));META.opts.lineagePilot=!META.opts.lineagePilot;Persist.save();lineagePilotMenu();};
`;save(cmFile,cm);
}
let ui=source('ui3d.js');ui+=`
// Called after the existing two-tap Command confirmation.
function lineageCommandPrompt(preserveDraft=false){
  if(!B||B.busy||!canCommand('player')) return;
  const c=commandFor('player');if(VSLineagePilot.mode(RUN,'player',c)!=='adm.vaelen.A1.1'){act(()=>useCommand('player'));return;}
  if(!preserveDraft) B.lineageDraft={};
  modal('<h2 id="lineageCommandAsk">One Lens, One Target</h2><p>For each ship, keep its normal volley or fire one projectile from one weapon at +25% damage. Cancel spends nothing.</p>'+alive('player').filter(u=>!u.isSq).map(u=>'<div><b>'+esc(u.name)+'</b><button data-act="lineageWeapon" data-arg="'+u.id+':normal">Normal volley</button>'+u.weapons.map((w,i)=>'<button data-act="lineageWeapon" data-arg="'+u.id+':'+i+'" '+(w.k==='flak'||w.off||!alive('enemy').some(t=>inReach(u,w,t))?'disabled':'')+'>'+esc(w.n)+' ('+((B.lineageDraft[u.id]===i)?'selected':'single shot')+')</button>').join('')+'</div>').join('')+'<button class="primary" data-act="lineageCommandFire">Fire Command</button><button data-act="lineageCommandCancel">Cancel</button>');
}
ACT.lineageWeapon=arg=>{if(!B||B.busy)return;const p=arg.split(':');if(p.length!==2)return;B.lineageDraft=B.lineageDraft||{};B.lineageDraft[p[0]]=p[1]==='normal'?null:Number(p[1]);lineageCommandPrompt(true);};
ACT.lineageCommandFire=()=>{if(!B||B.busy)return;B.lineageIntent=JSON.parse(JSON.stringify(B.lineageDraft||{}));if(!lineageCommandIntent('player',commandFor('player')).ok){delete B.lineageIntent;toast('Choose a weapon with a legal target, or keep the normal volley.');return;}delete B.lineageDraft;closeModal();act(()=>useCommand('player'));};
ACT.lineageCommandCancel=()=>{if(!B||B.busy)return;delete B.lineageDraft;delete B.lineageIntent;closeModal();bRefresh();};
`;
// Replace only the original confirmed-command dispatch, not other actions.
ui=replace(ui,"B.cmdArm=0; act(()=>useCommand('player')); };", "B.cmdArm=0; lineageCommandPrompt(); };",'command UI dispatch');
ui=replace(ui,"ACT.c3retreatNo(); else closeModal();", "ACT.c3retreatNo(); else if(document.getElementById('lineageCommandAsk')) ACT.lineageCommandCancel(); else closeModal();",'Command Escape cancel');save('ui3d.js',ui);
const gdLib=fs.readFileSync(path.join(base,'src/pilot.gd'),'utf8');save('godot/rules/lineage_pilot.gd',gdLib);save('godot/campaign/lineage_model.gd',fs.readFileSync(path.join(base,'src/lineage.gd'),'utf8'));save('godot/campaign/data/lineage_pilot.json',JSON.stringify(spec)+'\n');
let camp=source('godot/campaign/campaign.gd');camp=replace(camp,'const JSM =', 'const LineagePilot = preload("res://rules/lineage_pilot.gd")\nconst LineageModel = preload("res://campaign/lineage_model.gd")\nconst JSM =','campaign preloads');
camp=replace(camp,'RUN["heat"] =','RUN["lineagePilot"] = LineagePilot.snapshot(META, admiralId)\n\tRUN["heat"] =','campaign snapshot');
camp=replace(camp,'func masteryXP(id) -> float: return float(z0(META["mastery"].get(id))) if META.get("mastery") != null else 0.0',`func masteryXP(id) -> float:
\tvar snap = LineagePilot.snapshot(META, id)
\tif snap != null: return float(snap["xpQ"]) / 4.0
\treturn float(z0(META["mastery"].get(id))) if META.get("mastery") != null else 0.0`,'campaign mastery');
camp=replace(camp,'var mx0 = masteryLevel(RUN["admiral"]); var mxGain = float(s["battles"]) + float(s["elites"]) * 2 + float(s["bosses"]) * 5 + (10.0 if victory else 0.0)',`var mx0 = masteryLevel(RUN["admiral"]); var pilot_gain = lineagePilotAward(s, victory, hl)
\tvar mxGain = float(pilot_gain) if pilot_gain != null else float(s["battles"]) + float(s["elites"]) * 2 + float(s["bosses"]) * 5 + (10.0 if victory else 0.0)`,'campaign award');
camp+=`
# Native UI can call this model through a reviewed between-run screen; browser picker is prepared separately.
func lineagePilotAward(stats: Dictionary, victory: bool, heat) -> Variant:
\tif RUN.get("admiral") != "vaelen" or not (META.get("opts") is Dictionary) or META["opts"].get("lineagePilot") != true: return null
\tvar spec = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/data/lineage_pilot.json"))
\tvar model = LineageModel.new()
\tif spec == null or not model.configure(spec["catalog"], spec["roster"]): return null
\tvar state = META.get("lineageV1", model.new_state(META.get("mastery", {})))
\tif not model.validate(state): return null
\tvar heirs = []
\tfor id in META.get("lineageHeirs", {}):
\t\tif META["lineageHeirs"][id] == true and id != "vaelen" and model.admirals.has(id) and model.admirals[id]["fac"] == "ithar": heirs.append(id)
\tvar receipt = "run:%d:%s:%d" % [RUN.get("t0", 0), RUN["admiral"], META["stats"].get("runs", 0)]
\tvar result = model.award(state, {"id":"vaelen", "stats":stats, "victory":victory, "heat":heat, "heirLines":heirs, "settlementId":receipt})
\tif result == null: return null
\tMETA["lineageV1"] = result["state"]
\treturn 0 if result["duplicate"] else result["report"]["baseXp"] + result["report"]["heatXp"]
`;save('godot/campaign/campaign.gd',camp);
let rules=source('godot/rules/rules.gd');rules=replace(rules,'const JSM =','const LineagePilot = preload("res://rules/lineage_pilot.gd")\nconst JSM =','rules preload');
rules=replace(rules,'var c = commandFor(side); var tier = cmdTier(); B["cmdUsed"] = true;', 'var c = commandFor(side); var tier = cmdTier()\n\tif not lineageCommandIntent(side, c)["ok"]: return false\n\tB["cmdUsed"] = true;','rules intent');
const rs=rules.indexOf('\tif c["id"] == "barrage":',rules.indexOf('func runCommand(')),re=rules.indexOf('\tif c["id"] == "hunt":',rs);if(rs<0||re<0)throw Error('Godot barrage drift');
const gdBarrage=`\tif c["id"] == "barrage":
\t\tvar b0 = B; var live = liveFrom(null); var lp = lineageCommandIntent(side, c)
\t\tif not lp["ok"]: return false
\t\tvar previous = B.get("volleyMul"); B["volleyMul"] = {"side":side, "m":1.0 + cmdPow("barrage", tier)}
\t\tif lp["mode"] == "adm.vaelen.A1.1": B.erase("lineageIntent")
\t\tfor u in caps(side):
\t\t\tif jt(B.get("over")) or not live.call(): break
\t\t\tvar keep = []; var pf = [u.get("postFire"), u.get("postMp")]
\t\t\tfor w in u["weapons"]: keep.append([w, w.get("fired"), w.get("cdLeft"), w["shots"]]); w["fired"] = false; w["cdLeft"] = 0
\t\t\tfor i in range(u["weapons"].size()):
\t\t\t\tif jt(B.get("over")) or not live.call() or jt(u.get("dead")): break
\t\t\t\tif not LineagePilot.allows(lp, u, i): continue
\t\t\t\tvar w = u["weapons"][i]
\t\t\t\tif lp["mode"] == "adm.vaelen.A1.1" and lp["weapons"].get(u["id"]) != null: w["shots"] = 1
\t\t\t\tvar ts = []
\t\t\t\tfor t in alive(foe):
\t\t\t\t\tif canFire(u, w, t): ts.append(t)
\t\t\t\tif ts.is_empty(): continue
\t\t\t\tvar val = func(t):
\t\t\t\t\tvar prior = b0["volleyMul"]; b0["volleyMul"] = {"side":side, "m":prior["m"] * LineagePilot.factor(lp, u, w, t, hdist(u, t))}
\t\t\t\t\tvar e = expectedVs(u, w, t); var value = e.hull + e.shield * 0.3 + (25.0 if e.hull >= t["hp"] else 0.0); b0["volleyMul"] = prior; return value
\t\t\t\tJSM.ssort(ts, func(a,b2): return val.call(b2) - val.call(a))
\t\t\t\tvar prior = b0["volleyMul"]; b0["volleyMul"] = {"side":side, "m":prior["m"] * LineagePilot.factor(lp, u, w, ts[0], hdist(u,ts[0]))}
\t\t\t\tfireWeapon(u, i, ts[0]); b0["volleyMul"] = prior
\t\t\tfor item in keep: item[0]["fired"] = item[1]; item[0]["cdLeft"] = item[2]; item[0]["shots"] = item[3]
\t\t\tu["postFire"] = pf[0]; u["postMp"] = pf[1]
\t\tb0["volleyMul"] = previous
`;
rules=rules.slice(0,rs)+gdBarrage+rules.slice(re);
rules=replace(rules,'func runCommand(side, c, tier) -> bool:',`func lineageCommandIntent(side, c) -> Dictionary:
\tvar lp = LineagePilot.intent(RUN, side, c, B)
\tif not lp["ok"]: return lp
\tif lp["mode"] == "adm.vaelen.A1.1":
\t\tfor id in lp["weapons"]:
\t\t\tvar index = lp["weapons"][id]
\t\t\tif index == null: continue
\t\t\tvar u = null
\t\t\tfor unit in B["units"]:
\t\t\t\tif unit["id"] == id: u = unit; break
\t\t\tvar reaches = false
\t\t\tfor t in alive("enemy" if side == "player" else "player"):
\t\t\t\tif inReach(u, u["weapons"][int(index)], t): reaches = true; break
\t\t\tif not reaches: return {"ok":false}
\treturn lp
func runCommand(side, c, tier) -> bool:`, 'Godot intent helper');
save('godot/rules/rules.gd',rules);
for(const dir of ['godot/rules/test/oracle','godot/campaign/test/oracle'])save(dir+'/README.md',source(dir+'/README.md')+'\n## Proposed Saro lineage exception (Codex, Oct 31, 2026)\n\nThe original pin above is preserved. This candidate adds the opt-in Saro lineage module/snapshot and mastery getter to core.js, and the corresponding guarded primary-barrage resolver to battle.js. The campaign oracle also carries the matching guarded reward/getter and browser picker changes in campaign_meta.js. The Godot campaign candidate carries the native reward adapter. All other oracle content remains at its original pin. This is a scoped prototype, not a whole-oracle re-pin or a whole-port clearance.\n');
console.log('Saro candidate prepared: two tier-1 effects, native reward/snapshot adapters, browser picker and explicit oracle exceptions');
