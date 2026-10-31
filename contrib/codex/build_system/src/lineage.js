(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.VSLineage=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const LEVEL_XP=[0,6,16,30,50,75,110,160,230],MASTERY_XP=[320,440,600];
const clone=x=>JSON.parse(JSON.stringify(x));
function integer(n,label){if(!Number.isSafeInteger(n)||n<0)throw Error(label+' must be a nonnegative safe integer');return n;}
function create(catalog,roster){
 const skills=new Map(catalog.skills.map(s=>[s.id,s])),admirals=new Map(roster.admirals.map(a=>[a.id,a]));
 if(skills.size!==catalog.skills.length||admirals.size!==roster.admirals.length)throw Error('duplicate catalog/roster id');
 function adm(id){const a=admirals.get(id);if(!a)throw Error('unknown admiral '+id);return a;}
 function level(xpQ){integer(xpQ,'XP quarters');let n=0;for(let i=1;i<LEVEL_XP.length;i++)if(xpQ>=LEVEL_XP[i]*4)n=i;return n;}
 function validateBuild(id,xpQ,picks,capstone){
  adm(id);integer(xpQ,'XP quarters');if(!Array.isArray(picks)||new Set(picks).size!==picks.length)throw Error('duplicate/non-array picks');
  if(picks.length>Math.max(0,Math.min(3,level(xpQ)-4)))throw Error('too many picks for XP');
  const tiers={A:[],B:[],C:[]};
  for(const key of picks){const s=skills.get(key);if(!s||!s.owner.members.includes(id)||!tiers[s.branch])throw Error('wrong owner or branch '+key);tiers[s.branch].push(s.tier);}
  for(const ts of Object.values(tiers)){ts.sort((a,b)=>a-b);if(ts.some((t,i)=>t!==i+1))throw Error('exclusive pair or skipped branch tier');}
  if(capstone!==null&&capstone!==''){const c=skills.get(capstone);if(!c||c.branch!=='CAP'||!c.owner.members.includes(id)||level(xpQ)<8)throw Error('invalid capstone');}
  return true;
 }
 function newState(masteries={}){
  const lines={};for(const a of admirals.values()){
   const xp=masteries[a.id]===undefined?0:masteries[a.id];if(!Number.isFinite(xp)||xp<0||!Number.isSafeInteger(xp*4))throw Error('invalid native mastery');
   lines[a.id]={xpQ:Math.min(2400,xp*4),overflowQ:Math.max(0,xp*4-2400),picks:[],capstone:'',respecs:0};
  }
  return {version:1,lines,shadowPoolQ:{},awards:{}};
 }
 function validate(state){
  if(!state||state.version!==1||!state.lines||typeof state.lines!=='object'||Array.isArray(state.lines))throw Error('unsupported lineage save');
  if(!state.shadowPoolQ||typeof state.shadowPoolQ!=='object'||Array.isArray(state.shadowPoolQ)||!state.awards||typeof state.awards!=='object'||Array.isArray(state.awards))throw Error('invalid pools/awards');
  const knownFacs=new Set([...admirals.values()].map(a=>a.fac));
  for(const [fac,q] of Object.entries(state.shadowPoolQ)){if(!knownFacs.has(fac))throw Error('unknown shadow pool');integer(q,'pool quarters');}
  for(const [id,l] of Object.entries(state.lines)){adm(id);if(!l||typeof l!=='object')throw Error('invalid line');integer(l.xpQ,'XP quarters');if(l.xpQ>2400)throw Error('XP cap exceeded');integer(l.overflowQ,'overflow quarters');integer(l.respecs,'respec count');if(typeof l.capstone!=='string')throw Error('capstone must use the empty-string sentinel');validateBuild(id,l.xpQ,l.picks,l.capstone);}
  if([...admirals.keys()].some(id=>!Object.hasOwn(state.lines,id)))throw Error('missing admiral line');
  for(const [id,value] of Object.entries(state.awards))if(!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/.test(id)||typeof value!=='string')throw Error('invalid settlement receipt');
  return true;
 }
 function deserialize(text){const s=JSON.parse(text);validate(s);return s;}
 function serialize(state){validate(state);return JSON.stringify(state);}
 function choose(state,id,key,options={}){
  validate(state);if(options.liveRun)throw Error('choices are between runs');const a=adm(id),s=skills.get(key);
  if(!s||!s.owner.members.includes(a.id))throw Error('unknown/wrong-owner skill');
  if(options.implementedOnly!==false&&s.availability!=='pilot_candidate')throw Error('effect not implemented in pilot');
  const next=clone(state),line=next.lines[id];if(s.branch==='CAP'){if(line.capstone!=='')throw Error('capstone already chosen');line.capstone=key;}else line.picks.push(key);
  validate(next);return next;
 }
 function respec(state,id,keys,wallet,options={}){
  validate(state);adm(id);integer(wallet,'renown');if(options.liveRun)throw Error('respec is between runs');
  if(!Array.isArray(keys)||!keys.length||new Set(keys).size!==keys.length)throw Error('respec needs unique owned picks');
  const next=clone(state),line=next.lines[id],owned=line.picks.concat(line.capstone===''?[]:[line.capstone]);
  if(keys.some(k=>!owned.includes(k)))throw Error('cannot refund unowned pick');
  const cost=keys.length*(25+10*line.respecs);integer(cost,'respec cost');if(wallet<cost)throw Error('not enough renown');
  line.picks=line.picks.filter(k=>!keys.includes(k));if(keys.includes(line.capstone))line.capstone='';line.respecs++;
  validate(next);return {state:next,wallet:wallet-cost,cost};
 }
 function baseXp(stats,victory){
  if(!stats||typeof victory!=='boolean')throw Error('stats and boolean victory required');
  for(const k of ['battles','elites','bosses'])integer(stats[k],k);
  if(stats.elites+stats.bosses>stats.battles)throw Error('elite/boss wins must be subsets of battles');
  return integer(stats.battles+2*stats.elites+5*stats.bosses+(victory?10:0),'base XP');
 }
 function award(state,{id,stats,victory,heat=0,heirLines=[],settlementId}){
  validate(state);const active=adm(id);integer(heat,'weighted Heat');if(heat>1000)throw Error('Heat outside calculator bounds');
  if(!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/.test(settlementId||''))throw Error('explicit settlement id required');
  if(!Array.isArray(heirLines)||new Set(heirLines).size!==heirLines.length||heirLines.some(k=>adm(k).fac!==active.fac||k===id))throw Error('heir lines must be unique benched same-faction lines');
  const base=baseXp(stats,victory),fingerprint=[id,stats.battles,stats.elites,stats.bosses,victory?1:0,heat,heirLines.slice().sort().join(',')].join('|');
  if(Object.hasOwn(state.awards,settlementId)){
   if(state.awards[settlementId]!==fingerprint)throw Error('settlement id reused for a different outcome');
   return {state:clone(state),duplicate:true,report:null};
  }
  const next=clone(state),report={baseXp:base,heatXp:2*heat,creditedQ:{},overflowQ:{},shadowPoolQ:heat*4};
  const grant=(key,q)=>{integer(q,'grant quarters');const l=next.lines[key],credit=Math.min(q,2400-l.xpQ);l.xpQ+=credit;l.overflowQ+=q-credit;integer(l.overflowQ,'overflow quarters');report.creditedQ[key]=credit;report.overflowQ[key]=q-credit;};
  const flown=(base+2*heat)*4;grant(id,flown);
  for(const a of admirals.values())if(a.id!==id&&a.fac===active.fac)grant(a.id,flown/4*(heirLines.includes(a.id)?2:1));
  next.shadowPoolQ[active.fac]=(next.shadowPoolQ[active.fac]||0)+heat*4;
  next.awards[settlementId]=fingerprint;validate(next);return {state:next,duplicate:false,report};
 }
 function available(state,id,options={}){
  validate(state);adm(id);const result=[];
  for(const s of skills.values())if(s.owner.members.includes(id))try{choose(state,id,s.id,options);result.push(s.id);}catch(_){}
  return result;
 }
 function enumerate(id){
  adm(id);let states=new Map([['',[]]]);
  for(let n=0;n<3;n++){
   const next=new Map();for(const picks of states.values())for(const s of skills.values())if(s.branch!=='CAP'&&s.owner.members.includes(id)){
    const p=picks.concat(s.id);try{validateBuild(id,920,p,null);const k=p.slice().sort().join('|');next.set(k,p.slice().sort());}catch(_){}
   }states=next;
  }
  const builds=[];for(const picks of states.values())for(const c of skills.values())if(c.branch==='CAP'&&c.owner.members.includes(id))builds.push({picks,capstone:c.id});
  return builds;
 }
 return {level,validateBuild,newState,validate,serialize,deserialize,choose,respec,baseXp,award,available,enumerate,thresholds:LEVEL_XP.slice(),masteryThresholds:MASTERY_XP.slice()};
}
return {create,LEVEL_XP,MASTERY_XP};
});
