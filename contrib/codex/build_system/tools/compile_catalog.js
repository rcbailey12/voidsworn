#!/usr/bin/env node
'use strict';
// Source-preserving compiler. Suggested hooks/evidence are not resolved mechanics.
const fs=require('fs'), path=require('path'), crypto=require('crypto');
const ROOT=path.resolve(__dirname,'../../../..'), OUT=path.resolve(__dirname,'../data');
const {loadGame}=require(path.join(ROOT,'contrib/muse/tools/harness/game_loader'));
const G=loadGame(ROOT), roster=Object.entries(G.ADMIRALS).map(([id,a])=>({id,sourceName:a.n,displayName:id==='grax'?'Warlord Grax Ironmaw':a.n,fac:a.fac||'voidsworn',primaryCommand:a.cmd.id}));
const hash=s=>crypto.createHash('sha256').update(s).digest('hex');
const sources=['skill_tree_phase1_assembled_2026_10_29.md','skill_tree_tier2_assembled_2026_10_29.md','skill_tree_tier3_assembled_2026_10_29.md'];
const norm=s=>s.toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();
function adm(s){
 const aliases={grax:['grax ironmaw','grax steelgrin'],reyes:['corin reyes'],nekhet:['ninth frame']};
 const matches=roster.filter(a=>[a.displayName,a.sourceName,...(aliases[a.id]||[])].some(n=>norm(s).includes(norm(n))));
 if(matches.length!==1)throw Error('Ambiguous admiral: '+s);return matches[0];
}
const facets={
 trigger:/\b(?:when|after|before|if|during|at the start|at battle start|at round end)[^.;]*/gi,
 timing:/\b(?:at the start of[^.;]*|at round end|before[^.;]*|after[^.;]*|immediately|next round|this round)\b/gi,
 duration:/\b(?:for the rest of the battle|for the battle|for one round|for two rounds|until[^.;]*|next round|this round|whole battle)\b/gi,
 limit:/\b(?:once per[^,;.]*|first[^,;.]*|up to [^,;.]*|at most [^,;.]*)/gi,
 playerInput:/\b(?:choose|name|assign|may|hold|split|swap|give|exchange|select|reassign|retarget)\b/gi,
 actor:/\b(?:flagship|ships?|carriers?|broods?|swarms?|squadrons?|wings?|fleet)\b/gi,
 target:/\b(?:enemy|enemies|target|friendly|adjacent|nearest|lowest|most damaged)\b/gi
};
const hookRules={command_declaration:/command|volley|salvo|ward|wall|swarm|frenzy|burn|scatter|regrowth|tide|strike/i,
 targeting:/target|arc|aim|accuracy|range|retarget|lance|shot/i,damage_resolution:/damage|armor|hull|shield|critical|crit|hit/i,
 movement:/movement|move|hex|facing|turns|turn limit|reposition|ram/i,deployment:/deploy|formation|reserve|battle start/i,
 section_repair:/section|repair|patch|rebuild|regrow|mend/i,wing_lifecycle:/wing|squadron|brood|swarm|launch/i,
 round_boundary:/next round|round start|round end|start of|end of|until/i,activation:/activation|act before|act immediately|fires? again/i};
const skills=[], pairs=[];let current=null, faction=null, branch=null;
function add(pairText,owner,b,tier,line,file,sourceLine){
 const choices=pairText.split(' || ');if(choices.length!==2)throw Error('Expected pair '+file+':'+line);
 choices.forEach((original,option)=>{
  const sep=original.indexOf(' - ');if(sep<0)throw Error('Missing effect delimiter '+original);
  const label=original.slice(0,sep), effect=original.slice(sep+3);
  const id=owner.key+'.'+b+(b==='CAP'?'':tier)+'.'+option;
  const evidence={};for(const [k,re] of Object.entries(facets))evidence[k]=[...new Set(effect.match(re)||[])];
  skills.push({id,owner:{scope:owner.scope,key:owner.key,members:owner.members},branch:b,tier,option,
   name:label.replace(/ \[(?:Qwen|DeepSeek) swap\]/g,''),effect,original,
   source:{path:'contrib/muse/reviews/'+file,line,sha256:hash(sourceLine)},
   primaryCommandOnly:b==='A'||b==='CAP',availability:'not_implemented',
   contract:{status:'needs_resolution',evidence,actor:null,target:null,trigger:null,resolution:null,duration:null,limit:null,stacking:null,cleanup:null,playerInput:null,engineHooks:Object.entries(hookRules).filter(([,re])=>re.test(effect)).map(([k])=>k),
    note:'Evidence is verbatim extraction; hook tags are suggestions. Null fields must not be defaulted into game behavior.'}});
 });
}
const manifest=[];
for(let fi=0;fi<sources.length;fi++){
 const file=sources[fi],bytes=fs.readFileSync(path.join(ROOT,'contrib/muse/reviews',file)),lines=bytes.toString('utf8').split(/\r?\n/);let count0=skills.length;
 for(let ix=0;ix<lines.length;ix++){
  const line=lines[ix];let m;
  if((m=line.match(/^### (.+?) - Command:/))){current=adm(m[1]);faction=current.fac;branch=null;}
  else if(fi===0&&(m=line.match(/^### (.+) shared tier-1 sets/))){current=null;branch=null;}
  else if(fi===2&&(m=line.match(/^### (.+)/))){current=adm(m[1]);}
  else if(fi===1&&(m=line.match(/^## Pair (\d+): (.+?) \+ (.+?) \(([^)]+)\)/))){
   const a=adm(m[2]),b=adm(m[3]);current={key:'pair.'+m[1].padStart(2,'0'),scope:'pair',members:[a.id,b.id]};pairs.push({...current,declaredFamily:m[4],sourceLine:ix+1});
  }
  if(fi===0&&/^Branch A - /.test(line))branch='A';
  if(fi===0&&(m=line.match(/^T([123]): (.+)/))){if(!current||branch!=='A')throw Error('Missing Branch A context');add(m[2],{key:'adm.'+current.id,scope:'admiral',members:[current.id]},'A',+m[1],ix+1,file,line);}
  if(fi===0&&(m=line.match(/^Capstone: (.+)/)))add(m[1],{key:'adm.'+current.id,scope:'admiral',members:[current.id]},'CAP',0,ix+1,file,line);
  if((m=line.match(/^Branch ([BC]) T([123]): (.+)/))){
   const owner=fi===0?{key:'faction.'+faction,scope:'faction',members:roster.filter(a=>a.fac===faction).map(a=>a.id)}:fi===1?current:{key:'adm.'+current.id,scope:'admiral',members:[current.id]};
   add(m[3],owner,m[1],+m[2],ix+1,file,line);
  }
 }
 manifest.push({path:'contrib/muse/reviews/'+file,sha256:hash(bytes),lines:lines.length-(lines.at(-1)===''?1:0),lastLineFirst40:lines.filter((_,i)=>i!==lines.length-1||lines[i]!=='').at(-1).slice(0,40),compiled:skills.length-count0,readRanges:[[1,lines.length-(lines.at(-1)===''?1:0)]]});
}
if(skills.length!==360||new Set(skills.map(s=>s.id)).size!==360)throw Error('Catalog coverage failed');
for(const a of roster){const ss=skills.filter(s=>s.owner.members.includes(a.id));if(ss.length!==20)throw Error(a.id+' has '+ss.length+' slots');}
if(pairs.length!==12||new Set(pairs.flatMap(p=>p.members)).size!==24)throw Error('Pair coverage failed');
const pilot={
 'adm.vaelen.A1.0':{actor:'Each player non-squadron ship firing the primary Burning glass Command',target:'The actual target chosen for this weapon by the existing Command targeting',trigger:'Immediately before a primary-Command weapon resolves',resolution:'Multiply that weapon shot damage by 1.20 only if hex distance is strictly greater than half its printed maximum range',duration:'Only this Command weapon resolution',limit:'Once as a damage multiplier per eligible weapon; not an extra shot',stacking:'Multiply the existing Command multiplier once; no effect on normal fire, boss Commands or alternate Command',cleanup:'Restore the original battle multiplier in finally, including aborted or thrown actions',playerInput:'Weapon eligibility follows the existing Command; no additional target override',engineHooks:['command_volley_weapon'],status:'candidate_interpretation_requires_adoption'},
 'adm.vaelen.A1.1':{actor:'Each player non-squadron ship with an explicit focused-weapon selection',target:'The actual legal target chosen by the existing Command for that weapon',trigger:'Before iterating a ship’s primary-Command weapons',resolution:'For a ship choosing one weapon index, fire a single projectile from that weapon during the Command at 1.25 damage; null/omitted selection keeps its normal volley',duration:'Only this Command resolution',limit:'One projectile from one chosen weapon per ship; native shot count restored afterward',stacking:'Multiply existing Command damage once; only one A1 option can be owned',cleanup:'Restore normal weapons/cooldowns/post-fire movement and the original battle multiplier; consume intent with Command',playerInput:'Per ship: normal volley, or one weapon index. Cancel does not spend Command',engineHooks:['command_volley_weapon'],status:'candidate_interpretation_requires_adoption'}
};
for(const skill of skills)if(pilot[skill.id]){Object.assign(skill.contract,pilot[skill.id]);skill.availability='pilot_candidate';skill.interpretationNote='A single shot means one projectile from a selected weapon entry; “ship range” is interpreted as that weapon’s printed maximum r. These terms are proposed clarifications, not silent edits to the source.';}
fs.mkdirSync(OUT,{recursive:true});
for(const [name,value] of Object.entries({'catalog.json':{version:1,sourcePin:'355a2ac70860db4446f040a5787b19c2d746d779',skills},'roster.json':{version:1,admirals:roster,pairs},'source_manifest.json':{version:1,files:manifest}}))fs.writeFileSync(path.join(OUT,name),JSON.stringify(value,null,2)+'\n');
console.log('catalog: '+skills.length+' unique texts, 480 admiral slot references, '+roster.length+' admirals, '+pairs.length+' pairs');
