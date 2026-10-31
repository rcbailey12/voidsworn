#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),crypto=require('crypto'),assert=require('assert');
const data=require('../data/catalog.json'),roster=require('../data/roster.json'),manifest=require('../data/source_manifest.json');
const L=require('../src/lineage').create(data,roster),root=path.resolve(__dirname,'../../../..');
let checks=0;const ok=(label,fn)=>{fn();checks++;console.log('PASS '+label);};
const rejects=fn=>assert.throws(fn);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
ok('360 unique slots and 216/48/96 source coverage',()=>{assert.equal(data.skills.length,360);assert.equal(new Set(data.skills.map(s=>s.id)).size,360);assert.deepEqual(manifest.files.map(f=>f.compiled),[216,48,96]);});
ok('all source hashes, exact option text and owner mappings retained',()=>{
 for(const f of manifest.files)assert.equal(hash(fs.readFileSync(path.join(root,f.path))),f.sha256);
 for(const s of data.skills){const line=fs.readFileSync(path.join(root,s.source.path),'utf8').split(/\r?\n/)[s.source.line-1];assert.equal(hash(line),s.source.sha256);assert.equal(line.slice(line.indexOf(': ')+2).split(' || ')[s.option],s.original);assert(s.contract.resolution!==undefined);}
});
ok('all 24 admirals expose 20 slots and 160 distinct complete builds',()=>{
 let total=0;for(const a of roster.admirals){assert.equal(data.skills.filter(s=>s.owner.members.includes(a.id)).length,20);const builds=L.enumerate(a.id);assert.equal(builds.length,160);assert.equal(new Set(builds.map(b=>b.picks.join('|')+'|'+b.capstone)).size,160);for(const b of builds)L.validateBuild(a.id,920,b.picks,b.capstone);total+=builds.length;}assert.equal(total,3840);
});
ok('skipped tier, both sides of a pair, wrong owner and premature capstone rejected',()=>{
 for(const picks of [['adm.vaelen.A2.0'],['adm.vaelen.A1.0','adm.vaelen.A1.1'],['adm.vex.A1.0']])rejects(()=>L.validateBuild('vaelen',920,picks,null));
 rejects(()=>L.validateBuild('vaelen',916,[],'adm.vaelen.CAP.0'));rejects(()=>L.validateBuild('vaelen',296,['adm.vaelen.A1.0'],null));
});
let state=L.newState({vaelen:75}),original=L.serialize(state);
ok('pick is immutable; duplicate and unimplemented picks fail',()=>{state=L.choose(state,'vaelen','adm.vaelen.A1.0');assert.equal(L.deserialize(original).lines.vaelen.picks.length,0);rejects(()=>L.choose(state,'vaelen','adm.vaelen.A1.0'));rejects(()=>L.choose(L.newState({vex:75}),'vex','adm.vex.A1.0'));});
ok('no mid-run choices or respec; cancel keeps identical save',()=>{const before=L.serialize(state);rejects(()=>L.choose(state,'vaelen','adm.vaelen.A1.1',{liveRun:true}));rejects(()=>L.respec(state,'vaelen',['adm.vaelen.A1.0'],100,{liveRun:true}));assert.equal(L.serialize(state),before);});
ok('respec costs escalate per transaction, preserves XP and refunds no currency',()=>{let r=L.respec(state,'vaelen',['adm.vaelen.A1.0'],100);assert.equal(r.cost,25);assert.equal(r.wallet,75);assert.equal(r.state.lines.vaelen.xpQ,300);r.state=L.choose(r.state,'vaelen','adm.vaelen.A1.1');r=L.respec(r.state,'vaelen',['adm.vaelen.A1.1'],r.wallet);assert.equal(r.cost,35);assert.equal(r.wallet,40);state=r.state;});
ok('insufficient funds and missing dependency removal are atomic',()=>{let s=L.newState({vaelen:160});s=L.choose(s,'vaelen','adm.vaelen.A1.0');s=L.choose(s,'vaelen','adm.vaelen.A2.0',{implementedOnly:false});const b=L.serialize(s);rejects(()=>L.respec(s,'vaelen',['adm.vaelen.A1.0'],100));rejects(()=>L.respec(s,'vaelen',['adm.vaelen.A2.0'],0));assert.equal(L.serialize(s),b);});
ok('100 save/load cycles preserve pending picks, quarters and unknown same-version fields',()=>{state.note='preserved';const b=L.serialize(state);for(let i=0;i<100;i++)state=L.deserialize(L.serialize(state));assert.equal(L.serialize(state),b);});
ok('corrupt/future saves fail without silently dropping records',()=>{for(const patch of [{version:2},{lines:{}},{lines:{...state.lines,unknown:{}}},{shadowPoolQ:{unknown:1}}])rejects(()=>L.deserialize(JSON.stringify({...state,...patch})));rejects(()=>L.deserialize('{'));});
ok('native XP gives 0/1/11/16/27 on losses and 43 on defined win',()=>{const expected=[0,1,11,16,27,43];const values=Object.values(require('./calculate_progression').outcomes).map(o=>L.baseXp(o.stats,o.victory));assert.deepEqual(values,expected);rejects(()=>L.baseXp({battles:1,elites:1,bosses:1},false));});
ok('Heat, exact-quarter bench/heir and pending pool accounting',()=>{const r=L.award(L.newState(),{id:'vaelen',stats:{battles:12,elites:3,bosses:3},victory:true,heat:4,heirLines:['aelith'],settlementId:'heat:1'});assert.equal(r.state.lines.vaelen.xpQ,204);assert.equal(r.state.lines.aelith.xpQ,102);assert.equal(r.state.lines.thorne.xpQ,51);assert.equal(r.state.lines.vex.xpQ,0);assert.equal(r.state.shadowPoolQ.ithar,16);state=r.state;});
ok('settlement replay is idempotent and conflicting replay rejected',()=>{const event={id:'vaelen',stats:{battles:12,elites:3,bosses:3},victory:true,heat:4,heirLines:['aelith'],settlementId:'heat:1'};const r=L.award(state,event);assert(r.duplicate);assert.equal(L.serialize(r.state),L.serialize(state));rejects(()=>L.award(state,{...event,heat:3}));});
ok('four 1-XP runs bank exactly one ordinary shadow XP',()=>{let s=L.newState();for(let i=0;i<4;i++)s=L.award(s,{id:'vaelen',stats:{battles:1,elites:0,bosses:0},victory:false,settlementId:'quarter:'+i}).state;assert.equal(s.lines.vaelen.xpQ,16);assert.equal(s.lines.aelith.xpQ,4);});
ok('cap overflow preserved separately; pending choices do not destroy XP',()=>{let s=L.newState({vaelen:598,aelith:600});s=L.award(s,{id:'vaelen',stats:{battles:12,elites:3,bosses:3},victory:true,settlementId:'cap:1'}).state;assert.equal(s.lines.vaelen.xpQ,2400);assert.equal(s.lines.vaelen.overflowQ,164);assert.equal(s.lines.aelith.overflowQ,43);assert.equal(s.lines.vaelen.picks.length,0);});
ok('source mastery above 600 is preserved as overflow',()=>{const s=L.newState({vaelen:701.25});assert.equal(s.lines.vaelen.xpQ,2400);assert.equal(s.lines.vaelen.overflowQ,405);});
ok('first-passage distributions match deterministic controls and retain tail mass',()=>{const {passage}=require('./calculate_progression');assert.equal(passage(75,43,1,1).medianRuns,2);assert.equal(passage(75,43,1,0).p90Runs,75);const r=passage(75,43,0,0,20);assert.equal(r.medianRuns,null);assert.equal(r.unreachedProbability,1);assert.equal(r.restrictedMeanRuns,20);});
ok('vector comparator rejects equal truncated prefixes, duplicates, missing newline and changed state',()=>{
 const os=require('os'),dir=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-vector-parser-')),a=path.join(dir,'a'),b=path.join(dir,'b'),{compare}=require('./compare_vectors');
 try{
  const lines=[{kind:'x',case:'1',value:1},{kind:'x',case:'2',value:2}].map(JSON.stringify);fs.writeFileSync(a,lines.join('\n')+'\n');fs.writeFileSync(b,lines.join('\n')+'\n');assert.equal(compare(a,b,2),2);
  fs.writeFileSync(a,lines[0]+'\n');fs.writeFileSync(b,lines[0]+'\n');rejects(()=>compare(a,b,2));
  fs.writeFileSync(a,[lines[0],lines[0]].join('\n')+'\n');rejects(()=>compare(a,b,2));
  fs.writeFileSync(a,lines.join('\n'));rejects(()=>compare(a,b,2));
  fs.writeFileSync(a,lines.join('\n')+'\n');fs.writeFileSync(b,lines[0]+'\n'+JSON.stringify({kind:'x',case:'2',value:99})+'\n');rejects(()=>compare(a,b,2));
 }finally{fs.rmSync(dir,{recursive:true,force:true});}
});
console.log(checks+' contract/progression checks passed');
