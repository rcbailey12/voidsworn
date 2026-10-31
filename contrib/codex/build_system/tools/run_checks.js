#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),os=require('os'),cp=require('child_process'),assert=require('assert'),crypto=require('crypto');
const base=path.resolve(__dirname,'..'),root=path.resolve(base,'../../..'),evidence=path.join(base,'evidence');fs.mkdirSync(evidence,{recursive:true});
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi>=0?args[gi+1]:process.env.VOIDSWORN_GODOT_EXE||'godot';
const work=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-build-system-')),results=[];
function run(label,cmd,argv,allowed=[0],timeout=60000){
 console.log('Checking: '+label);const r=cp.spawnSync(cmd,argv,{cwd:root,encoding:'utf8',windowsHide:true,timeout,maxBuffer:16*1024*1024});
 const output=(r.stdout||'')+(r.stderr||'');fs.writeFileSync(path.join(evidence,label+'.txt'),output);
 const ok=!r.error&&allowed.includes(r.status);results.push({label,status:r.status,ok,error:r.error?r.error.message:null});
 if(!ok)throw Error(label+' did not pass: '+(r.error?r.error.message:'exit '+r.status)+'\n'+output.slice(-2400));
 if(/SCRIPT ERROR|Parse Error|Compile Error|NOT PORTED/.test(output))throw Error(label+' produced a Godot script/port error');
 return output;
}
const node=(script,argv=[])=>[path.join(__dirname,script),...argv];
function copy(from,to){fs.copyFileSync(from,path.join(evidence,to));}
function hash(file){return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');}
function suite(repo,label){const output=run(label,process.execPath,[path.join(root,'contrib/muse/tools/findings_tests/findings_tests.js'),repo],[1]);const states={};for(const m of output.matchAll(/^(PASS|FAIL) (\S+)\s/gm)){if(Object.hasOwn(states,m[2]))throw Error('duplicate suite identity');states[m[2]]=m[1];}assert.equal(Object.keys(states).length,80,'all 80 assertions must execute');return states;}
try{
 for(const script of ['source_guard.js','compile_catalog.js','prepare_module_fit.js','prepare_pilot.js','prepare_tree_copy.js','check_contract.js','calculate_progression.js','check_patches.js'])run(script.replace('.js',''),process.execPath,node(script));
 const version=run('godot_version',godot,['--version']).trim();
 const common=path.join(work,'model'),pilot=path.join(work,'pilot');
 run('prepare_model',process.execPath,node('prepare_checks.js',[common]));run('model_js',process.execPath,node('cross_engine_vectors.js',[common]));
 run('model_godot',godot,['--headless','--path',path.join(common,'godot'),'--script','res://codex/godot_checks.gd','--',path.join(common,'gd_vectors.jsonl')]);
 run('model_compare',process.execPath,node('compare_vectors.js',[path.join(common,'js_vectors.jsonl'),path.join(common,'gd_vectors.jsonl'),'707']));
 run('prepare_pilot',process.execPath,node('prepare_pilot_checks.js',[pilot]));run('pilot_js',process.execPath,node('pilot_checks.js',[pilot]));
 run('pilot_godot',godot,['--headless','--path',path.join(pilot,'godot'),'--script','res://codex/pilot_checks.gd','--',path.join(pilot,'pilot_gd.jsonl')]);
 run('pilot_compare',process.execPath,node('compare_vectors.js',[path.join(pilot,'pilot_js.jsonl'),path.join(pilot,'pilot_gd.jsonl'),'96']));
 const original=suite(root,'suite_baseline'),moduleFit=suite(path.join(common,'browser'),'suite_module_fit'),prototype=suite(path.join(pilot,'browser'),'suite_pilot_disabled');
 const delta=(a,b)=>Object.keys(a).filter(k=>a[k]!==b[k]);assert.deepEqual(delta(original,moduleFit),['MOD-3']);assert.equal(moduleFit['MOD-3'],'PASS');assert.deepEqual(delta(original,prototype),[]);
 const combined=path.join(work,'combined');
 run('prepare_combined',process.execPath,node('prepare_combined_checks.js',[combined]));
 run('combined_model_js',process.execPath,node('cross_engine_vectors.js',[combined]));
 run('combined_model_godot',godot,['--headless','--path',path.join(combined,'repo/godot'),'--script','res://codex/godot_checks.gd','--',path.join(combined,'gd_vectors.jsonl')]);
 run('combined_model_compare',process.execPath,node('compare_vectors.js',[path.join(combined,'js_vectors.jsonl'),path.join(combined,'gd_vectors.jsonl'),'707']));
 run('combined_pilot_js',process.execPath,node('pilot_checks.js',[combined]));
 run('combined_pilot_godot',godot,['--headless','--path',path.join(combined,'repo/godot'),'--script','res://codex/pilot_checks.gd','--',path.join(combined,'pilot_gd.jsonl')]);
 run('combined_pilot_compare',process.execPath,node('compare_vectors.js',[path.join(combined,'pilot_js.jsonl'),path.join(combined,'pilot_gd.jsonl'),'96']));
 const combinedStates=suite(path.join(combined,'repo'),'suite_combined');assert.deepEqual(delta(original,combinedStates),['MOD-3']);assert.equal(combinedStates['MOD-3'],'PASS');
 run('build_preview',process.execPath,node('build_preview.js',[pilot]));run('preview_code',process.execPath,node('check_preview.js'));
 for(const [file,dest] of [[path.join(common,'js_vectors.jsonl'),'model_js.jsonl'],[path.join(common,'gd_vectors.jsonl'),'model_gd.jsonl'],[path.join(common,'gd_vectors.jsonl.native_table_drift.json'),'native_table_drift.json'],[path.join(pilot,'pilot_js.jsonl'),'pilot_js.jsonl'],[path.join(pilot,'pilot_gd.jsonl'),'pilot_gd.jsonl'],[path.join(pilot,'pilot_js_summary.json'),'pilot_js_summary.json']])copy(file,dest);
 const summary={status:'PASS for this bounded packet',sourcePin:'355a2ac7',godot:version,workDirectory:work,legalBuilds:3840,modelRecords:707,pilotRecords:96,combinedRuntime:{modelRecords:707,pilotRecords:96,moduleAssertionDelta:['MOD-3 FAIL -> PASS']},moduleAssertionDelta:['MOD-3 FAIL -> PASS'],prototypeDisabledAssertionDelta:[],results,
  limits:['General cutover parity corpus remains NOT RUN.','Rendered browser/layout and Windows launcher verification remain NOT RUN.','Native module inventories have four recorded compatibility differences from two pre-existing weapon-loadout discrepancies. Shared-input predicate parity does not clear that drift.','The browser picker/Command dialogs are prepared; native Godot equivalents are not in this packet.','Two operational skill candidates are implemented; 358 other authored entries remain source contracts, not implemented effects.','Shadow allocation/overflow/respec policy choices are documented candidates, not new owner rulings.'],hashes:{modelJS:hash(path.join(evidence,'model_js.jsonl')),modelGodot:hash(path.join(evidence,'model_gd.jsonl')),pilotJS:hash(path.join(evidence,'pilot_js.jsonl')),pilotGodot:hash(path.join(evidence,'pilot_gd.jsonl')),combinedModelJS:hash(path.join(combined,'js_vectors.jsonl')),combinedModelGodot:hash(path.join(combined,'gd_vectors.jsonl')),combinedPilotJS:hash(path.join(combined,'pilot_js.jsonl')),combinedPilotGodot:hash(path.join(combined,'pilot_gd.jsonl'))}};
 fs.writeFileSync(path.join(evidence,'verification_summary.json'),JSON.stringify(summary,null,2)+'\n');console.log('PASS: 360 texts / 3,840 legal builds / 707 model-fit records / 96 native pilot records. Only MOD-3 changes in the 80-assertion control.');
}catch(e){fs.writeFileSync(path.join(evidence,'verification_summary.json'),JSON.stringify({status:'FAILED OR INCOMPLETE',error:e.message,results,workDirectory:work},null,2)+'\n');console.error(e.message);process.exitCode=1;}
