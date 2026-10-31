#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),vm=require('vm');
const project=path.resolve(process.argv[2]),output=path.resolve(process.argv[3]);
const source=fs.readFileSync(path.join(project,'campaign/test/node/golden_campaign.js'),'utf8');
const begin=source.indexOf('const HARNESS = String.raw`'),end=source.indexOf('`;\nenv.load(HARNESS);',begin);
if(begin<0||end<0)throw Error('Existing campaign harness boundary changed');
const harness=source.slice(begin+'const HARNESS = '.length,end+1);
const decoded=vm.runInNewContext(harness);
require(path.join(project,'campaign/test/node/env.js')).load(decoded+`
const flowFs=require('fs'), flowAssert=require('assert'), flowInput=[], flowRows=[];
for(const fac of ['hegemony','chorus'])for(const revealed of [[],['ion'],['ion','torp']])for(const found of [[],['torp'],['ion','torp']]){
 UID=1;rndSeed(144);META=defaultMeta();SAVED_RUN=null;RUN=runDefaults();B=null;
 RUN.fac='voidsworn';RUN.admiral='vex';RUN.sector=1;RUN.foes={1:fac,2:fac,3:fac};RUN.patrons=['iron','storm','star','rook'];
 RUN.fleet=['warden','harrow'].map(t=>newShip(t));RUN.flagUid=RUN.fleet[0].uid;RUN.map=genSector(1);RUN.nem=newNemesis();
 RUN.nem.fac=fac;RUN.nem.beaten=1;RUN.nem.weak=['ion','torp'];RUN.nem.revealed=revealed.slice();RUN.nem.seen={lance:10,torp:10};
 stubStart({kind:'elite',fac,seed:987,node:RUN.map.cols[4][0].id,nemesis:nemBattleCfg()});B.campaign=true;B.nemFound=found.filter(k=>!revealed.includes(k));
 for(const u of B.units)if(u.side==='player'){u.dead=true;u.hp=0;}
 const runRef=RUN, test={id:fac+':'+revealed.length+':'+found.length,run:JSON.parse(JSON.stringify(RUN)),meta:JSON.parse(JSON.stringify(META)),battle:JSON.parse(JSON.stringify(B)),seed:77};flowInput.push(test);
 rndSeed(77);finishBattle('loss');
 const expected=new Set(revealed.concat(test.battle.nemFound));if(!test.battle.nemFound.length){const next=['ion','torp'].find(k=>!expected.has(k));if(next)expected.add(next);}
 flowAssert.deepEqual([...runRef.nem.revealed].sort(),[...expected].sort());
 if(runRef.nem.revealed.includes('ion'))flowAssert(!runRef.nem.adapt.includes('shields'));if(runRef.nem.revealed.includes('torp'))flowAssert(!runRef.nem.adapt.includes('pd'));
 flowRows.push({kind:'finish_flow',case:test.id,revealed:runRef.nem.revealed,adapt:runRef.nem.adapt,rng:RNG_S>>>0});
}
flowFs.writeFileSync(${JSON.stringify(output)},flowRows.map(x=>JSON.stringify(x)).join('\\n')+'\\n');
flowFs.writeFileSync(${JSON.stringify(path.join(project,'campaign/test/pre_opus_flow_input.json'))},JSON.stringify(flowInput));
console.log(flowRows.length+' actual finishBattle loss flows pass');
`);
