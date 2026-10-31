#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),cp=require('child_process');
const root=path.resolve(__dirname,'../../../..'),dest=path.resolve(__dirname,'../candidates/module_fit');
const js=`function canFitModule(ship,id){
  const mod=typeof id==='string'&&Object.hasOwn(MODULES,id)?MODULES[id]:null, hull=ship&&Object.hasOwn(HULLS,ship.tpl)?HULLS[ship.tpl]:null;
  if(!mod||!hull||!Array.isArray(ship.mods)||ship.mods.length>=(hull.slots||0)) return false;
  if(mod.only&&hull.ab!==mod.only) return false;
  const need=MOD_NEED[id];
  if(need==='shields') return (hull.sh||0)>0;
  if(need==='carrier') return hull.ab==='launch'&&(hull.hangar||0)>0;
  const kind={batt:'battery',lance:'lance',torp:'torp',flak:'flak'}[need];
  if(kind) return (hull.w||[]).some(([wid])=>W[wid]&&W[wid].k===kind);
  return !need;
}
`;
const gd=`func canFitModule(sh, m) -> bool:
\tif not (sh is Dictionary) or not (m is String) or not MODULES.has(m): return false
\tvar t = HULLS.get(sh.get("tpl"))
\tif t == null or not (sh.get("mods") is Array) or sh["mods"].size() >= int(t.get("slots", 0)): return false
\tvar md = MODULES[m]
\tif jt(md.get("only")) and t.get("ab") != md["only"]: return false
\tvar need = MOD_NEED.get(m)
\tif need == "shields": return float(z0(t.get("sh"))) > 0.0
\tif need == "carrier": return t.get("ab") == "launch" and float(z0(t.get("hangar"))) > 0.0
\tvar kind = {"batt":"battery", "lance":"lance", "torp":"torp", "flak":"flak"}.get(need)
\tif kind != null:
\t\tfor pair in t.get("w", []):
\t\t\tif W_.has(pair[0]) and W_[pair[0]].get("k") == kind: return true
\t\treturn false
\treturn not jt(need)
`;
function replace(s,a,b,label){if(!s.includes(a))throw Error('Source drift '+label);return s.replace(a,b);}
const files=['core.js','campaign_run.js','godot/campaign/campaign.gd','godot/campaign/test/oracle/core.js','godot/campaign/test/oracle/campaign_run.js'];
for(const file of files){
 let s=cp.execFileSync('git',['show','355a2ac7:'+file],{cwd:root,encoding:'utf8'});
 if(file.endsWith('core.js'))s=replace(s,'function modulePool(){',js+'function modulePool(){',file);
 else if(file.endsWith('campaign_run.js')){
  s=replace(s,"s.mods.length<HULLS[s.tpl].slots && (!MODULES[m].only||HULLS[s.tpl].ab===MODULES[m].only)",'canFitModule(s,m)',file+' UI');
  s=replace(s,"ACT.equip=arg=>{ const [i,uid]=arg.split(':'); const s=RUN.fleet.find(x=>x.uid===uid); const m=RUN.inventory[+i]; if(!s||!m) return;",
   "ACT.equip=arg=>{ if(!RUN||typeof arg!=='string') return false; const parts=arg.split(':'); if(parts.length!==2||parts[0].length>15||!/^(0|[1-9][0-9]*)$/.test(parts[0])) return false; const [i,uid]=parts; const index=Number(i); if(!Number.isSafeInteger(index)||index>=RUN.inventory.length) return false; const s=RUN.fleet.find(x=>x.uid===uid); const m=RUN.inventory[index]; if(!canFitModule(s,m)) return false;",file+' action');
 }else{
  s=replace(s,'func modulePool() -> Array:',gd+'func modulePool() -> Array:',file);
  s=replace(s,'s["mods"].size() < int(HULLS[s["tpl"]]["slots"]) and (not jt(MODULES[m].get("only")) or HULLS[s["tpl"]].get("ab") == MODULES[m]["only"])','canFitModule(s, m)',file+' UI');
  s=replace(s,'var p = arg.split(":"); var s = _ship(p[1]); var i = int(p[0])\n\tvar m = RUN["inventory"][i] if i >= 0 and i < RUN["inventory"].size() else null\n\tif s == null or not jt(m): return',
   'if RUN == null: return\n\tvar p = arg.split(":")\n\tif p.size() != 2 or p[0].length() > 15 or not p[0].is_valid_int() or p[0].begins_with("-") or p[0].begins_with("+") or (p[0].length() > 1 and p[0].begins_with("0")): return\n\tvar i = int(p[0]); var s = _ship(p[1])\n\tvar m = RUN["inventory"][i] if i >= 0 and i < RUN["inventory"].size() else null\n\tif not canFitModule(s, m): return',file+' action');
 }
 const target=path.join(dest,file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,s);
}
const readme='godot/campaign/test/oracle/README.md';const src=cp.execFileSync('git',['show','355a2ac7:'+readme],{cwd:root,encoding:'utf8'});
fs.writeFileSync(path.join(dest,readme),src+'\n## Proposed module-fit exception (Codex, Oct 31, 2026)\n\nThe pinned oracle above remains the baseline. This candidate changes only module compatibility in core.js and its fleet-screen/action consumers in campaign_run.js, matching the browser/Godot candidate. It does not re-pin the rest of either file or adopt unrelated gameplay candidates.\n');
console.log('module-fit candidate: UI and action guard, five source copies plus explicit oracle exception');
