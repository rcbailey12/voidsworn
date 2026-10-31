#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),vm=require('vm'),assert=require('assert');
const ROOT=path.resolve(__dirname,'../../../..'),L=require('../src/lineage').create(require('../data/catalog.json'),require('../data/roster.json'));
function cases(){return [
 {id:'choices-respec',masteries:{vaelen:75},ops:[{op:'choose',id:'vaelen',key:'adm.vaelen.A1.0'},{op:'choose',id:'vaelen',key:'adm.vaelen.A1.1'},{op:'roundtrip'},{op:'respec',id:'vaelen',keys:['adm.vaelen.A1.0']},{op:'choose',id:'vaelen',key:'adm.vaelen.A1.1'},{op:'respec',id:'vaelen',keys:['adm.vaelen.A1.1']}]},
 {id:'eligibility',masteries:{vaelen:74},ops:[{op:'choose',id:'vaelen',key:'adm.vaelen.A1.0'},{op:'choose',id:'vex',key:'adm.vaelen.A1.0'},{op:'choose',id:'vaelen',key:'adm.vaelen.A2.0'}]},
 {id:'dependency-refund',masteries:{vaelen:160},ops:[{op:'choose',id:'vaelen',key:'adm.vaelen.A1.0'},{op:'choose',id:'vaelen',key:'adm.vaelen.A2.0',options:{implementedOnly:false}},{op:'respec',id:'vaelen',keys:['adm.vaelen.A1.0']},{op:'respec',id:'vaelen',keys:['adm.vaelen.A1.0','adm.vaelen.A2.0']}]},
 {id:'heat-and-replay',masteries:{},ops:[{op:'award',event:{id:'vaelen',stats:{battles:12,elites:3,bosses:3},victory:true,heat:4,heirLines:['aelith','thorne'],settlementId:'run:1'}},{op:'roundtrip'},{op:'award',event:{id:'vaelen',stats:{battles:12,elites:3,bosses:3},victory:true,heat:4,heirLines:['thorne','aelith'],settlementId:'run:1'}},{op:'award',event:{id:'vaelen',stats:{battles:12,elites:3,bosses:3},victory:true,heat:3,heirLines:['aelith','thorne'],settlementId:'run:1'}}]},
 {id:'overflow',masteries:{vaelen:598,aelith:600},ops:[{op:'award',event:{id:'vaelen',stats:{battles:12,elites:3,bosses:3},victory:true,heat:2,settlementId:'cap:1'}},{op:'roundtrip'}]},
 {id:'quarters',masteries:{},ops:[0,1,2,3].map(i=>({op:'award',event:{id:'vaelen',stats:{battles:1,elites:0,bosses:0},victory:false,settlementId:'q:'+i}}))},
 {id:'midrun-and-invalid',masteries:{vaelen:75},ops:[{op:'choose',id:'vaelen',key:'adm.vaelen.A1.0',options:{liveRun:true}},{op:'award',event:{id:'vaelen',stats:{battles:1,elites:1,bosses:1},victory:false,settlementId:'bad:1'}},{op:'award',event:{id:'vaelen',stats:{battles:1,elites:0,bosses:0},victory:false,heirLines:['vex'],settlementId:'bad:2'}}]},
 {id:'funds',masteries:{vaelen:75},wallet:0,ops:[{op:'choose',id:'vaelen',key:'adm.vaelen.A1.0'},{op:'respec',id:'vaelen',keys:['adm.vaelen.A1.0']}]},
 {id:'capstone',masteries:{vaelen:230},ops:[{op:'choose',id:'vaelen',key:'adm.vaelen.CAP.0',options:{implementedOnly:false}},{op:'choose',id:'vaelen',key:'adm.vaelen.CAP.1',options:{implementedOnly:false}},{op:'respec',id:'vaelen',keys:['adm.vaelen.CAP.0']}]}
 ];}
function run(work){
 const dirs=JSON.parse(fs.readFileSync(path.join(work,'paths.json'))),output=[],input={cases:cases(),builds:[]};
 for(const c of input.cases){let state=L.newState(c.masteries),wallet=c.wallet===undefined?200:c.wallet;for(let i=0;i<c.ops.length;i++){
  const o=c.ops[i];let ok=true,detail=null;try{
   if(o.op==='choose')state=L.choose(state,o.id,o.key,o.options||{});
   else if(o.op==='respec'){const r=L.respec(state,o.id,o.keys,wallet,o.options||{});state=r.state;wallet=r.wallet;detail={cost:r.cost};}
   else if(o.op==='award'){const r=L.award(state,o.event);state=r.state;detail={duplicate:r.duplicate,report:r.report};}
   else state=L.deserialize(L.serialize(state));
  }catch(_){ok=false;}
  output.push({kind:'model',case:c.id,step:i,ok,state,wallet,detail});
 }}
 for(const a of require('../data/roster.json').admirals)for(const b of L.enumerate(a.id))input.builds.push({id:a.id,...b});
 const GC=require(path.join(ROOT,'contrib/muse/tools/findings_tests/campaign_loader')).loadCampaign(dirs.overlay);
 const canFit=(sh,m)=>{GC._sandbox.__ship=sh;GC._sandbox.__mod=m;return vm.runInContext('canFitModule(__ship,__mod)',GC._sandbox);};
 input.fitHulls=JSON.parse(JSON.stringify(GC.HULLS));input.fitWeapons=JSON.parse(JSON.stringify(GC.W));input.fitExpected={};let fits=0;
 for(const [tpl,t] of Object.entries(GC.HULLS))for(const m of Object.keys(GC.MODULES)){
  const sh={tpl,mods:[]},actual=canFit(sh,m);const needs={loaders:'battery',crystal:'lance',magazine:'torp',flakplus:'flak'};
  const expected=t.slots>0&&(!GC.MODULES[m].only||t.ab===GC.MODULES[m].only)&&
   (!(m==='capacitor'||m==='regen')||t.sh>0)&&(!(m==='hangar')||t.ab==='launch'&&t.hangar>0)&&
   (!needs[m]||t.w.some(([w])=>GC.W[w].k===needs[m]));assert.equal(actual,expected,tpl+':'+m);
  input.fitExpected[tpl+':'+m]=actual;output.push({kind:'fit',tpl,mod:m,allowed:actual});assert.equal(canFit({tpl,mods:Array(t.slots||0).fill('auspex')},m),false);fits++;
 }
 input.actionCases=[['crystal','warden','0'],['loaders','warden','0'],['hangar','warden','0'],['capacitor','b_drone','0'],['prow','warden','0'],['auspex','warden','-1'],['auspex','warden','1.0'],['auspex','warden','+0'],['auspex','warden','18446744073709551616'],['auspex','warden','0:extra'],['auspex','warden','full'],['unknown','warden','0'],['toString','warden','0']];
 for(let i=0;i<input.actionCases.length;i++){
  const [mod,tpl,index]=input.actionCases[i];GC.META=GC.defaultMeta();GC.RUN=GC.runDefaults();GC.rndSeed(1111+i);vm.runInContext('UID=1',GC._sandbox);
  const sh=GC.newShip(tpl);if(index==='full')sh.mods=Array(GC.HULLS[tpl].slots).fill('auspex');GC.RUN.fleet=[sh];GC.RUN.flagUid=sh.uid;GC.RUN.inventory=[mod];
  const view=()=>JSON.parse(JSON.stringify({mods:sh.mods,hp:sh.hp,inventory:GC.RUN.inventory}));const before=view();GC.ACT.equip((index==='full'?'0':index)+':'+sh.uid);const after=view();
  const should=index==='0'&&['loaders','prow'].includes(mod);if(!should)assert.deepEqual(after,before,'invalid equip mutates '+i);else{assert(after.mods.includes(mod));assert.equal(after.inventory.length,0);}
  output.push({kind:'equip',case:i,before,after});
 }
 fs.writeFileSync(path.join(dirs.project,'codex/input.json'),JSON.stringify(input));fs.writeFileSync(path.join(work,'js_vectors.jsonl'),output.map(o=>JSON.stringify(o)).join('\n')+'\n');
 console.log(output.length+' JS records; '+fits+' hull/module predicates plus full-slot rejection; '+input.builds.length+' legal builds queued for Godot');
}
if(require.main===module)run(path.resolve(process.argv[2]));module.exports={run,cases};
