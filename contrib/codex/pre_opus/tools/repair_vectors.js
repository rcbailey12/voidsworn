#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),vm=require('vm'),assert=require('assert');
const ROOT=path.resolve(__dirname,'../../../..'),{loadCampaign}=require(path.join(ROOT,'contrib/muse/tools/findings_tests/campaign_loader'));
const repo=path.resolve(process.argv[2]),out=path.resolve(process.argv[3]),G=loadCampaign(repo),control=loadCampaign(ROOT),input=[],rows=[];
const mode=process.argv[4]||'all';assert(['all','nemesis','boons'].includes(mode));
const clone=x=>JSON.parse(JSON.stringify(x));
function clean(x){if(Array.isArray(x))return x.map(clean);if(x&&typeof x==='object')return Object.fromEntries(Object.keys(x).filter(k=>x[k]!=null&&typeof x[k]!=='function').map(k=>[k,clean(x[k])]));return x;}
function runIn(code){return vm.runInContext(code,G._sandbox);}
function invoke(g,op,args){g._sandbox.__args=args;return vm.runInContext(op+'(...__args)',g._sandbox);}
let controls=0,offWhileOn=0,duos=0,legends=0;
function fixture(fac='hegemony'){
 G.META=G.defaultMeta();G.RUN=G.runDefaults();runIn("B=null;");G.rndSeed(1901);runIn('Date.now=()=>0; UID=1;');
 G.RUN.fac='voidsworn';G.RUN.admiral='vex';G.RUN.sector=2;G.RUN.patrons=['iron','storm','star','rook','hunger','ember'];
 G.RUN.fleet=['warden','harrow','reliquary'].map(t=>G.newShip(t));G.RUN.flagUid=G.RUN.fleet[0].uid;
 G.RUN.nem={fac,name:'Test Nem',title:'First Admiral',persona:'proud',traits:[],portrait:'nem_x_1',g:'m',weak:['ion','torp'],revealed:[],adapt:[],clock:0,met:0,beaten:1,scars:0,scarKinds:[],epithets:[],epithet:null,last_beat:null,fed:0,riches:0,loot:0,held:null,gloat:null,honed:0,revived:false,dead:false,strike:false,seen:{},signatures:[]};
}
function execute(id,op,args,seed,check,unchanged=false){
 const test={id,op,args:clone(args),seed,run:clone(G.RUN),meta:clone(G.META)};input.push(test);G.rndSeed(seed);
 const result=invoke(G,op,args),row={kind:'repair',case:id,result:result===undefined?null:clone(result),nem:clean(G.RUN.nem),rng:runIn('RNG_S>>>0')};
 check(result,test);rows.push(row);
 if(unchanged){control.RUN=clone(test.run);control.META=clone(test.meta);vm.runInContext("B=null;",control._sandbox);control.rndSeed(seed);const r=invoke(control,op,clone(args));assert.deepEqual(clean(r),clean(result),'unchanged native return '+id);assert.deepEqual(clean(control.RUN.nem),row.nem,'unchanged native state '+id);assert.equal(vm.runInContext('RNG_S>>>0',control._sandbox),row.rng);controls++;}
}
const factions=['voidsworn','hegemony','ithar','deathless','chorus','corsair'];
let n=0;
if(mode!=='boons'){
for(const fac of factions)for(const revealed of [[],['ion'],['torp'],['ion','torp']])for(const seen of [{lance:10,ion:10,torp:10,sq:10},{ram:3,board:3,battery:2},{}])for(const adapt of [[],['armor','evasion','aim']])for(const force of [false,true]){
 fixture(fac);G.RUN.nem.revealed=clone(revealed);G.RUN.nem.seen=clone(seen);G.RUN.nem.adapt=clone(adapt);
 execute('adapt:'+n++,'nemAdapt',[force],100+n,r=>{if(revealed.includes('ion'))assert.notEqual(r,'shields');if(revealed.includes('torp'))assert.notEqual(r,'pd');assert.equal(new Set(G.RUN.nem.adapt).size,G.RUN.nem.adapt.length);},revealed.length===0);
}
for(const fac of factions)for(const result of ['loss','retreat','win'])for(const revealed of [[],['ion'],['ion','torp']])for(const found of [[],['torp'],['nonsense','torp','torp'],['ion','torp']]){
 fixture(fac);G.RUN.nem.revealed=clone(revealed);const known=found.filter(k=>G.RUN.nem.weak.includes(k)),expected=new Set([...revealed,...known]);
 if(result==='win'||known.length===0){const next=G.RUN.nem.weak.find(k=>!revealed.includes(k));if(next)expected.add(next);}
 execute('debrief:'+n++,'nemAfterBattle',[result,false,{found}],100+n,lines=>{
  assert.deepEqual([...G.RUN.nem.revealed].sort(),[...expected].sort());assert.equal(new Set(G.RUN.nem.revealed).size,G.RUN.nem.revealed.length);
  if(result!=='win'){assert(lines.some(s=>/Your analysts|file on/.test(s)));for(const k of known.length?new Set(known):[...expected].filter(k=>!revealed.includes(k)))assert(lines.some(s=>s.includes(runIn('NEM_WEAK['+JSON.stringify(k)+'].n'))));}
 },result==='win'&&found.length===0);
}
for(const fac of factions)for(const revealed of [['ion'],['torp'],['ion','torp']]){
 fixture(fac);G.RUN.nem.revealed=clone(revealed);G.RUN.nem.adapt=runIn('Object.keys(NEM_ADAPT).filter(k=>!((k===\"shields\"&&RUN.nem.revealed.includes(\"ion\"))||(k===\"pd\"&&RUN.nem.revealed.includes(\"torp\")))).concat(NEM_ADAPT_FAC[RUN.nem.fac].special.id)');
 execute('exhausted:'+n++,'nemAdapt',[true],100+n,r=>assert.equal(r,null));
}
}
if(mode!=='nemesis'){
// Full useful pools, depleted pools and shieldless fleets; all offering-patron favour tiers.
for(const p of ['iron','storm','star','rook','hunger','ember'])for(const favour of [0,4,25])for(const min of [0,1])for(let seed=1;seed<=30;seed++)for(const fleet of ['mixed','shieldless']){
 fixture();G.META.favour[p]=favour;
 if(fleet==='shieldless')G.RUN.fleet=[G.newShip('b_drone')];
 const tier=G.favourTier?G.favourTier(p):runIn('favourTier('+JSON.stringify(p)+')');
 execute('offer:'+p+':'+favour+':'+min+':'+seed+':'+fleet,'rollBoonOffer',[p,min],seed,offer=>{
  assert(offer.length<=3);assert.equal(new Set(offer.map(o=>o.id)).size,offer.length);
  for(const o of offer){G._sandbox.__id=o.id;const b=runIn('BOONS[__id]'),useful=runIn('boonUseful(__id,fleetKit())');assert(useful,'incompatible offer '+o.id);assert(!G.RUN.boons.some(x=>x.id===o.id));assert([0,1,2,3].includes(o.r));if(b.duo)assert.equal(o.r,0);else if(b.leg)assert.equal(o.r,3);else{if(tier>=3)assert(o.r>=1);if(b.p!==p)offWhileOn++;}}
 });
}
// Both rare special classes remain reachable. Eligibility comes from real owned boons.
for(let seed=1;seed<=300;seed++){
 fixture();const setup=runIn("(()=>{const id=Object.keys(BOONS).find(k=>BOONS[k].duo);const [p,q]=BOONS[id].duo;const of=x=>Object.keys(BOONS).filter(k=>BOONS[k].p===x&&!BOONS[k].leg);return {id,p,q,held:[of(p)[0],of(p)[1],of(q)[0]]};})()");
 G.RUN.boons=setup.held.map(id=>({id,r:0}));
 execute('special:'+seed,'rollBoonOffer',[setup.p,1],seed,offer=>{duos+=offer.filter(o=>o.id===setup.id).length;legends+=offer.filter(o=>o.r===3).length;});
}
assert(offWhileOn>0);assert(duos>0);assert(legends>0);
// The same offering patron must reach every ordinary rarity roll, including off-patron selections.
fixture();runIn('globalThis.__rarityCalls=[]; globalThis.__oldRarity=rollRarity; rollRarity=function(a,b,p){__rarityCalls.push(p);return __oldRarity(a,b,p);};');invoke(G,'rollBoonOffer',['iron',0]);assert(runIn('__rarityCalls.every(p=>p===\'iron\')'));runIn('rollRarity=__oldRarity;');
// Empty useful pool is an honest short offer, never an incompatible filler or duplicate.
fixture();G.RUN.boons=runIn('Object.keys(BOONS).map(id=>({id,r:0}))');execute('empty-pool','rollBoonOffer',['iron',1],321,r=>assert.deepEqual(clone(r),[]));
for(const keep of [0,1])for(let seed=1;seed<=30;seed++){
 fixture();G.META.favour.iron=25;G.RUN.boons=runIn("Object.keys(BOONS).filter(id=>BOONS[id].p==='iron'&&!BOONS[id].leg).slice("+keep+").map(id=>({id,r:0}))");
 execute('depleted:'+keep+':'+seed,'rollBoonOffer',['iron',0],seed,offer=>{assert(offer.length>0);assert.equal(new Set(offer.map(o=>o.id)).size,offer.length);for(const o of offer){G._sandbox.__id=o.id;const b=runIn('BOONS[__id]');if(!b.duo&&!b.leg)assert(o.r>=1);assert(!G.RUN.boons.some(x=>x.id===o.id));}});
}
}
fs.mkdirSync(path.dirname(out),{recursive:true});fs.writeFileSync(out,rows.map(r=>JSON.stringify(r)).join('\n')+'\n');fs.writeFileSync(path.join(repo,'godot/campaign/test/pre_opus_input.json'),JSON.stringify(input));
fs.writeFileSync(out+'.summary.json',JSON.stringify({records:rows.length,unchangedNativeControls:controls,offPatronPicks:offWhileOn,duos,legends,emptyPool:true,sharedRarityArgument:true},null,2)+'\n');
console.log(rows.length+' repair vectors; '+controls+' original-JS controls; '+duos+' duos / '+legends+' legendaries in eligible special-slot fixture');
