#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),cp=require('child_process'),os=require('os'),assert=require('assert'),P=require('./prepare');
const base=P.BASE,root=P.ROOT,evidence=path.join(base,'evidence'),work=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-pre-opus-'));
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi>=0?args[gi+1]:process.env.VOIDSWORN_GODOT_EXE||'godot',results=[],counts={};
fs.mkdirSync(evidence,{recursive:true});
function run(label,cmd,argv,cwd=root,allowed=[0],timeout=60000){console.log('Checking '+label);const r=cp.spawnSync(cmd,argv,{cwd,encoding:'utf8',maxBuffer:20*1024*1024,timeout,windowsHide:true});const out=(r.stdout||'')+(r.stderr||'');fs.writeFileSync(path.join(evidence,label+'.txt'),out);const ok=!r.error&&allowed.includes(r.status)&&!/SCRIPT ERROR|Parse Error|Compile Error|NOT PORTED/.test(out);results.push({label,exit:r.status,ok,error:r.error?.message||null});if(!ok)throw Error(label+': '+(r.error?.message||out.slice(-1800)));return out;}
const node=(label,file,a=[],cwd=root,allowed=[0])=>run(label,process.execPath,[file,...a],cwd,allowed);
function compare(label,a,b,n){node(label,path.join(root,'contrib/codex/build_system/tools/compare_vectors.js'),[a,b,String(n)]);}
function suite(repo,job){const s=node('suite_'+job,path.join(root,'contrib/muse/tools/findings_tests/findings_tests.js'),[repo],root,[1]);const states={};for(const m of s.matchAll(/^(PASS|FAIL) (\S+)\s/gm)){assert(!Object.hasOwn(states,m[2]));states[m[2]]=m[1];}assert.equal(Object.keys(states).length,80);return states;}
function patchCheck(dirs){node('patch_checks',path.join(__dirname,'check_patches.js'),[dirs.control,path.join(work,'apply')]);}
try{
 run('godot_version',godot,['--version']);
 const prep=node('prepare',path.join(__dirname,'prepare.js'),[work]),dirs=JSON.parse(prep.trim());patchCheck(dirs);
 const original=suite(dirs.control,'control');
 const expected={nemesis:['FR-2','NEM-2'],boons:['RWD-3','RWD-4','RWD-8'],integration:['FR-2','MOD-3','NEM-2','RWD-3','RWD-4','RWD-8','TXT-2','W3-1'],saro:['FR-2','MOD-3','NEM-2','RWD-3','RWD-4','RWD-8','TXT-2','W3-1']};
 for(const job of ['nemesis','boons','integration','saro']){const got=suite(dirs[job],job),delta=Object.keys(original).filter(k=>original[k]!==got[k]).sort();assert.deepEqual(delta,expected[job]);for(const k of delta)assert.equal(got[k],'PASS');counts[job]={assertions:80,pass:Object.values(got).filter(v=>v==='PASS').length,delta};}
 for(const [job,mode,n] of [['nemesis','nemesis',522],['boons','boons',2521],['integration','all',3043]]){
  const repo=dirs[job],js=path.join(work,job+'_js.jsonl'),gd=path.join(work,job+'_gd.jsonl');
  node('repairs_js_'+job,path.join(__dirname,'repair_vectors.js'),[repo,js,mode]);P.put(repo,'godot/campaign/test/pre_opus_vectors.gd',fs.readFileSync(path.join(__dirname,'repair_vectors.gd')));
  run('repairs_godot_'+job,godot,['--headless','--path',path.join(repo,'godot'),'--script','res://campaign/test/pre_opus_vectors.gd','--',gd]);compare('repairs_compare_'+job,js,gd,n);
  counts[job].repairRecords=n;fs.copyFileSync(js+'.summary.json',path.join(evidence,'repairs_'+job+'_summary.json'));counts[job].repairHashes={js:P.hash(fs.readFileSync(js)),godot:P.hash(fs.readFileSync(gd))};
 }
 const integration=dirs.integration,project=path.join(integration,'godot');
 const flowJS=path.join(work,'flow_js.jsonl'),flowGD=path.join(work,'flow_gd.jsonl');
 node('finish_flow_js',path.join(__dirname,'finish_flow.js'),[project,flowJS]);P.put(integration,'godot/campaign/test/pre_opus_flow.gd',fs.readFileSync(path.join(__dirname,'finish_flow.gd')));
 run('finish_flow_godot',godot,['--headless','--path',project,'--script','res://campaign/test/pre_opus_flow.gd','--',flowGD]);compare('finish_flow_compare',flowJS,flowGD,18);counts.finishFlow=18;
 assert(fs.readFileSync(flowJS,'utf8').trim().split('\n').map(JSON.parse).filter(r=>r.case.startsWith('chorus:')).every(r=>r.adapt.length>0));counts.finishFlowFastAdaptExercised=true;
 for(const name of ['flow_js.jsonl','flow_gd.jsonl'])fs.copyFileSync(path.join(work,name),path.join(evidence,name));
 P.put(integration,'godot/campaign/test/codex_fix_vectors.gd',fs.readFileSync(path.join(root,'contrib/codex/tools/godot_validation/fix_vectors.gd')));
 const fixJS=path.join(work,'fix_js.jsonl'),fixGD=path.join(work,'fix_gd.jsonl');node('maps_shipwright_js',path.join(root,'contrib/codex/tools/godot_validation/fix_vectors.js'),[project,fixJS]);
 run('maps_shipwright_godot',godot,['--headless','--path',project,'--script','res://campaign/test/codex_fix_vectors.gd','--',fixGD,'1500']);node('maps_shipwright_compare',path.join(root,'contrib/codex/tools/godot_validation/compare_vectors.js'),[fixJS,fixGD,'candidate']);counts.mapsAndShipwright=4506;
 // Campaign UI, seeded actions and the existing reload/save cycle use the original harness.
 const campaignOut=path.join(work,'campaign');fs.mkdirSync(campaignOut,{recursive:true});let steps=0;
 for(let seed=1;seed<=30;seed++)node('campaign_js_'+seed,path.join(project,'campaign/test/node/golden_campaign.js'),[String(seed),path.join(campaignOut,'js'+seed+'.jsonl')]);
 run('campaign_godot',godot,['--headless','--path',project,'--script','res://campaign/test/parity_campaign.gd','--',campaignOut,...Array.from({length:30},(_,i)=>String(i+1))],root,[0],60000);
 for(let seed=1;seed<=30;seed++){const a=path.join(campaignOut,'js'+seed+'.jsonl'),b=path.join(campaignOut,'c'+seed+'.jsonl');for(const f of [a,b]){const s=fs.readFileSync(f,'utf8');assert(s.endsWith('\n'),'truncated campaign '+seed);const rows=s.trim().split('\n').map(JSON.parse);assert(rows.length>1&&rows[0].act==='start'&&rows[0].rng===seed&&rows.at(-1).act==='end','incomplete campaign '+seed);assert(rows.every((r,i)=>r.i===i),'missing or duplicate campaign step '+seed);}steps+=fs.readFileSync(a,'utf8').trim().split('\n').length;node('campaign_compare_'+seed,path.join(project,'campaign/test/node/compare_campaign.js'),[a,b]);}
 counts.campaign={seeds:30,steps,scope:'Existing stub-battle campaign/save-reload harness, not real battle parity'};
 node('nem_scenarios_js',path.join(project,'campaign/test/node/nem_scenarios.js'),[path.join(work,'nem_js.txt')]);run('nem_scenarios_godot',godot,['--headless','--path',project,'--script','res://campaign/test/nem_scenarios.gd','--',path.join(work,'nem_gd.txt')]);const a=fs.readFileSync(path.join(work,'nem_js.txt'),'utf8').trim(),b=fs.readFileSync(path.join(work,'nem_gd.txt'),'utf8').trim();assert.equal(a,b);assert.equal(a.split('\n').length,64);counts.nemScenarios=64;
 // The optional Saro layer has no native dialogs; validate its actual rules and browser handlers explicitly.
 const saro=dirs.saro,bs=path.join(root,'contrib/codex/build_system');fs.mkdirSync(path.join(saro,'godot/codex'),{recursive:true});
 for(const [from,to] of [['src/lineage.gd','lineage.gd'],['tools/godot_checks.gd','godot_checks.gd'],['tools/pilot_checks.gd','pilot_checks.gd'],['data/catalog.json','catalog.json'],['data/roster.json','roster.json']])P.put(saro,'godot/codex/'+to,fs.readFileSync(path.join(bs,from)));
 P.put(saro,'paths.json',JSON.stringify({work:saro,overlay:saro,project:path.join(saro,'godot')}));
 for(const [label,script,gdscript,jsfile,gdfile,n] of [['model','cross_engine_vectors.js','godot_checks.gd','js_vectors.jsonl','gd_vectors.jsonl',707],['pilot','pilot_checks.js','pilot_checks.gd','pilot_js.jsonl','pilot_gd.jsonl',96]]){
  node('saro_'+label+'_js',path.join(bs,'tools',script),[saro]);run('saro_'+label+'_godot',godot,['--headless','--path',path.join(saro,'godot'),'--script','res://codex/'+gdscript,'--',path.join(saro,gdfile)]);compare('saro_'+label+'_compare',path.join(saro,jsfile),path.join(saro,gdfile),n);counts['saro_'+label]=n;
 }
 const summary={status:'PASS for bounded integration and repair packet',pin:P.PIN,work,counts,results,limits:['General real-battle parity corpus is still absent; no cutover clearance.','Saro native picker/Command dialogs are not implemented; no full campaign-UI parity claim for that optional layer.','Existing native hull-table drift is not cleared.','The 3:1 ordinary-pool weights, duo45/legendary55 special-slot weights and one-new-weakness debrief cap are explicit candidate tuning.','The battle can reveal two weaknesses; the debrief preserves that knowledge and adds none if a valid battle discovery was supplied.','Blender/Windows/GPU acceptance is separate from this headless check.']};
 fs.writeFileSync(path.join(evidence,'summary.json'),JSON.stringify(summary,null,2)+'\n');console.log('PASS: integrated repairs, 30 campaign seeds, native repair vectors, 4,506 map/repair vectors and optional Saro checks');
}catch(e){fs.writeFileSync(path.join(evidence,'summary.json'),JSON.stringify({status:'FAILED OR INCOMPLETE',error:e.message,work,counts,results},null,2)+'\n');console.error(e.stack);process.exitCode=1;}
