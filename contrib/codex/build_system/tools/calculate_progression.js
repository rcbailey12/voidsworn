#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path');
const API=require('../src/lineage');
const engine=()=>API.create(require('../data/catalog.json'),require('../data/roster.json'));
const outcomes={
 immediate_loss:{victory:false,stats:{battles:0,elites:0,bosses:0}},
 early_loss:{victory:false,stats:{battles:1,elites:0,bosses:0}},
 sector1_loss:{victory:false,stats:{battles:4,elites:1,bosses:1}},
 midrun_loss:{victory:false,stats:{battles:7,elites:2,bosses:1}},
 late_loss:{victory:false,stats:{battles:11,elites:3,bosses:2}},
 victory43:{victory:true,stats:{battles:12,elites:3,bosses:3}}
};
// Exact finite-horizon distribution over XP; no battle or random simulation.
function passage(threshold,winXP,lossXP,p,maxRuns=200){
 for(const n of [threshold,winXP,lossXP,maxRuns])if(!Number.isSafeInteger(n)||n<0)throw Error('integer nonnegative passage inputs required');
 if(threshold<1||maxRuns<1||!Number.isFinite(p)||p<0||p>1)throw Error('invalid threshold/horizon/probability');
 let pending=new Map([[0,1]]),cdf=0,sumSurvival=0,median=null,p90=null;const byRun=[];
 for(let run=1;run<=maxRuns;run++){
  sumSurvival+=[...pending.values()].reduce((a,b)=>a+b,0);const next=new Map();let reached=0;
  for(const [xp,prob] of pending)for(const [gain,weight] of [[winXP,p],[lossXP,1-p]]){
   const mass=prob*weight;if(!mass)continue;const total=xp+gain;
   if(total>=threshold)reached+=mass;else next.set(total,(next.get(total)||0)+mass);
  }
  cdf=Math.min(1,cdf+reached);if(median===null&&cdf>=.5-1e-12)median=run;if(p90===null&&cdf>=.9-1e-12)p90=run;
  byRun.push({run,cdf});pending=next;
 }
 return {threshold,winXP,lossXP,assumedWinProbability:p,horizon:maxRuns,medianRuns:median,p90Runs:p90,
  restrictedMeanRuns:sumSurvival,unreachedProbability:Math.max(0,1-cdf),byRun,
  note:'Restricted mean is E[min(time-to-threshold,horizon)]; not an unqualified expected completion time.'};
}
function generate(){
 const L=engine(),traces=[];
 for(const [label,cycle,heat] of [
  ['all victories',['victory43'],0],['all early losses',['early_loss'],0],
  ['four sector-1 losses then victory',['sector1_loss','sector1_loss','sector1_loss','sector1_loss','victory43'],0],
  ['four midrun losses then victory',['midrun_loss','midrun_loss','midrun_loss','midrun_loss','victory43'],0],
  ['four sector-1 losses then victory, Heat 4',['sector1_loss','sector1_loss','sector1_loss','sector1_loss','victory43'],4],
  ['no battles completed',['immediate_loss'],0]
 ]){
  let state=L.newState(),firstPick=null,thirdPick=null,capstone=null;const rows=[];
  for(let i=0;i<100;i++){
   const outcome=outcomes[cycle[i%cycle.length]],r=L.award(state,{id:'vaelen',...outcome,heat,settlementId:label.replace(/[^a-z0-9]/gi,'-')+':'+i});state=r.state;
   const xp=state.lines.vaelen.xpQ/4;if(firstPick===null&&xp>=75)firstPick=i+1;if(thirdPick===null&&xp>=160)thirdPick=i+1;if(capstone===null&&xp>=230)capstone=i+1;
   if(i<15||[firstPick,thirdPick,capstone].includes(i+1))rows.push({run:i+1,outcome:cycle[i%cycle.length],xp,ordinaryBenchXP:state.lines.aelith.xpQ/4,pendingHeatPoolXP:(state.shadowPoolQ.ithar||0)/4,level:L.level(state.lines.vaelen.xpQ)});
  }
  traces.push({label,cycle,heat,firstPickRun:firstPick,thirdPickRun:thirdPick,capstoneRun:capstone,rows});
 }
 const distributions=[];
 for(const [name,lossXP] of [['chair flat-loss assumption',10],['one won battle then loss',1],['sector-1 example',11]])
  for(const p of [.2,.5,.8])for(const xp of [75,160,230])distributions.push({scenario:name,...passage(xp,43,lossXP,p)});
 return {version:1,sourcePin:'355a2ac7',implementedBaseFormula:'battles + 2*elites + 5*bosses + (victory ? 10 : 0)',
  outcomeDefinitions:Object.fromEntries(Object.entries(outcomes).map(([k,o])=>[k,{...o,baseXP:L.baseXp(o.stats,o.victory)}])),
  assumptions:{profiles:'Illustrative counts, not measured player behavior. elites and bosses are subsets of total battles won.',probabilities:'Sensitivity inputs only; no measured bot rate is used as a human forecast.',shadow:'Quarter-XP precision; 25% of flown payout including Heat; heir doubles ordinary shadow. Heat +1 goes into an undistributed faction pool.',caps:'Prototype banks overflow above 600 per line; preserves XP while choices are pending. Distribution and intermediate-cap policy require adoption.'},traces,distributions};
}
function write(out){
 const result=generate();fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'progression_report.json'),JSON.stringify(result,null,2)+'\n');
 const lines=['# Progression sensitivity, not a player forecast','','Native loss XP is variable. The source formula is `battles + 2*elites + 5*bosses + victory*10`; a flat 10-XP loss is a proposal assumption. Example outcomes below are specified inputs, not measured campaign data.','',
 '| Stated outcome cycle | Heat | First tree pick (75 XP) | Third pick (160 XP) | Capstone (230 XP) |','|---|---:|---:|---:|---:|'];
 for(const t of result.traces)lines.push('| '+t.label+' | '+t.heat+' | '+[t.firstPickRun,t.thirdPickRun,t.capstoneRun].map(x=>x===null?'not within 100 runs':x).join(' | ')+' |');
 lines.push('','The proposal’s “43 win / 10 loss / 20% wins” has mean XP 16.6 per run. Dividing a threshold by 16.6 is not the expected first-passage time. The JSON provides exact finite-horizon crossing distributions, medians, 90th percentiles, residual mass, and explicitly restricted means for 20%, 50%, and 80% assumed wins. No combat simulations were rerun.','',
 'Policy notes: exact quarter-XP avoids silent rounding; ordinary shadow includes the proposed Heat payout; Heat’s additional faction pool is banked, not silently paid to every benched admiral. Overflow is retained per line above 600. These implementation policies are marked for adoption in the contract; they are not new owner rulings.');
 fs.writeFileSync(path.join(out,'progression_report.md'),lines.join('\n')+'\n');console.log(lines.slice(4,11).join('\n'));
}
if(require.main===module)write(path.resolve(process.argv[2]||path.join(__dirname,'../evidence')));
module.exports={passage,generate,outcomes};
