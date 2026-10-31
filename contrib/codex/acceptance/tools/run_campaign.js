#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,path,BASE,put,run,logged,sha}=C,{compare}=require('./compare_campaign');
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi<0?process.env.VOIDSWORN_GODOT_EXE||'godot':args[gi+1];
const summary={status:'INCOMPLETE',scope:'Full current-source campaign logic and saved-state replay through the existing UI-action bot. Battles remain deterministic stubs in this campaign harness.'};
(async()=>{
 const {work,project}=require('./prepare_campaign').prepare();summary.work=work;const out=path.join(work,'campaign_full');fs.mkdirSync(out);
 const source=['data.js','core.js','battle.js','campaign_meta.js','campaign_run.js','campaign3d.js','ui3d.js'];summary.inputs=C.receipt(work,source);
 const seeds=Array.from({length:30},(_,i)=>i+1);
 console.log('Running 30 current-source campaign/save-reload seeds');
 for(const seed of seeds)run(process.execPath,[path.join(project,'campaign/test/node/golden_campaign.js'),String(seed),path.join(out,'js'+seed+'.jsonl')],{env:C.cleanEnv({VS_ORACLE:work})});
 await logged('campaign_current_godot',godot,['--headless','--path',project,'--script','res://campaign/test/parity_campaign.gd','--',out,...seeds.map(String)]);
 summary.cases=seeds.map(seed=>compare(path.join(out,'js'+seed+'.jsonl'),path.join(out,'c'+seed+'.jsonl'),seed));
 assert.deepEqual(C.receipt(work,source),summary.inputs,'Source changed during campaign checks');
 const manifest=JSON.parse(fs.readFileSync(path.join(BASE,'patches/campaign_manifest.json')));for(const e of manifest.files)assert.equal(sha(fs.readFileSync(path.join(work,e.path))),e.candidateSHA256);
 summary.pass=summary.cases.filter(x=>x.pass).length;summary.fail=30-summary.pass;summary.records=summary.cases.reduce((n,x)=>n+Math.min(x.recordsJS,x.recordsGodot),0);summary.reloads=summary.cases.reduce((n,x)=>n+x.reloads,0);summary.status=summary.fail?'FAIL':'PASS';
 summary.limits=['Does not render the campaign UI or compare telemetry, which the existing harness excludes.','Does not migrate browser saves or access player data.','Real battle execution is covered separately; this campaign harness substitutes battles.'];
 put(path.join(BASE,'evidence/campaign_summary.json'),JSON.stringify(summary,null,2)+'\n');console.log(summary.status+': '+summary.pass+'/30 campaigns; '+summary.records+' exact records, '+summary.reloads+' reloads');process.exitCode=summary.fail?1:0;
})().catch(e=>{summary.error=e.stack;put(path.join(BASE,'evidence/campaign_summary.json'),JSON.stringify(summary,null,2)+'\n');console.error(e.stack);process.exitCode=2;});
