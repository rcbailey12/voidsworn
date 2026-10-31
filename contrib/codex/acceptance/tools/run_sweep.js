#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,path,BASE,put,run,logged,sha}=C,{compare}=require('../../finalization/tools/compare');
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi<0?process.env.VOIDSWORN_GODOT_EXE||'godot':args[gi+1];
const summary={status:'INCOMPLETE',count:200,sweepSeed:31,scope:'Both engines execute one identical 200-battle sequence with actual combined repaired browser source and refreshed native battle rules.'};
(async()=>{
 const work=require('../../finalization/tools/check_patches').check(),project=path.join(work,'godot');summary.work=work;
 const files=['data.js','core.js','battle.js','ui3d.js','campaign_run.js','godot/rules/rules.gd','godot/rules/battle_api.gd','godot/rules/jsm.gd','godot/rules/data/tables.json'];summary.inputs=C.receipt(work,files);
 const list=path.join(work,'sweep_200.json'),js=path.join(work,'sweep_js'),gd=path.join(work,'sweep_gd');fs.mkdirSync(js);fs.mkdirSync(gd);
 run(process.execPath,[path.join(project,'rules/test/node/sweep_gen.js'),'200','31',list]);
 const scenarios=JSON.parse(fs.readFileSync(list));assert.equal(Object.keys(scenarios).length,200);assert(Object.keys(scenarios).every((id,i)=>id==='w'+(i+1)));summary.scenariosSHA256=sha(fs.readFileSync(list));
 put(path.join(BASE,'evidence/sweep_scenarios.json'),fs.readFileSync(list));put(path.join(BASE,'evidence/sweep_summary.json'),JSON.stringify(summary,null,2)+'\n');
 console.log('Running 200 varied real battles in each engine; progress logs are in acceptance/evidence.');
 await Promise.all([
  logged('sweep_node',process.execPath,[path.join(project,'rules/test/node/golden.js'),'batch',list,js],{env:C.cleanEnv({VS_ORACLE:work})}),
  logged('sweep_godot',godot,['--headless','--path',project,'--script','res://rules/test/parity_main.gd','--','batch',list,gd])
 ]);
 summary.cases=[];
 for(const id of Object.keys(scenarios)){const a=path.join(js,id+'.jsonl'),b=path.join(gd,id+'.jsonl'),result=compare(a,b);summary.cases.push({id,seed:scenarios[id].seed,...result,nodeFileSHA256:sha(fs.readFileSync(a)),godotFileSHA256:sha(fs.readFileSync(b))});if(!result.pass)console.log('FAIL '+id+': '+JSON.stringify(result.first));}
 assert.deepEqual(C.receipt(work,files),summary.inputs,'Source changed during sweep');
 summary.pass=summary.cases.filter(x=>x.pass).length;summary.fail=200-summary.pass;summary.records=summary.cases.reduce((n,x)=>n+Math.min(x.recordsJS,x.recordsGodot),0);summary.status=summary.fail?'FAIL':'PASS';
 summary.endings=summary.cases.reduce((o,x)=>(o[x.terminalJS]=(o[x.terminalJS]||0)+1,o),{});
 summary.limits=['No rendered scene, GPU timing, Windows execution or campaign save transport.','An end none record is the explicit scenario round limit, not a win.'];
 put(path.join(BASE,'evidence/sweep_summary.json'),JSON.stringify(summary,null,2)+'\n');console.log(summary.status+': '+summary.pass+'/200 exact battles; '+summary.records+' records');process.exitCode=summary.fail?1:0;
})().catch(e=>{summary.error=e.stack;put(path.join(BASE,'evidence/sweep_summary.json'),JSON.stringify(summary,null,2)+'\n');console.error(e.stack);process.exitCode=2;});
