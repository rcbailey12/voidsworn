#!/usr/bin/env node
'use strict';
const C=require('./common'),{fs,path,os,BASE,ROOT,put,run}=C,{prepare}=require('./prepare'),{check}=require('./check_patches');
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi<0?process.env.VOIDSWORN_GODOT_EXE||'godot':args[gi+1];
const summary={status:'INCOMPLETE',checks:[]};
function job(label,fn){console.log('Checking '+label);const result=fn();summary.checks.push({label,status:'PASS'});return result;}
try{
 job('Godot version',()=>run(godot,['--version']));
 job('prepare candidates',()=>prepare(fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-final-prepare-'))));
 const combined=job('strict patch application and final hashes',check);
 job('native hull vectors',()=>run(process.execPath,[path.join(__dirname,'run_hulls.js'),'--godot',godot]));
 job('current JS action lifecycle',()=>run(process.execPath,[path.join(__dirname,'lifecycle_checks.js')]));
 job('48 current-source battle candidates',()=>run(process.execPath,[path.join(__dirname,'run_vectors.js'),'--candidate','--all','--godot',godot],{timeout:900000}));
 // Reuse actual fresh output from the corpus as adversarial comparator input.
 const corpus=JSON.parse(fs.readFileSync(path.join(BASE,'evidence/battle_refresh_candidate_all48/summary.json')));
 job('adversarial comparator checks',()=>run(process.execPath,[path.join(__dirname,'comparator_checks.js'),path.join(corpus.work,'js/s1.jsonl')]));
 job('repairs plus both finalization patches',()=>run(process.execPath,[path.join(__dirname,'run_vectors.js'),combined,'--godot',godot,'--out',path.join(BASE,'evidence/combined_current_source')],{timeout:900000}));
 job('optional Saro after both refreshes',()=>run(process.execPath,[path.join(__dirname,'check_saro.js'),'--godot',godot]));
 summary.status='PASS for prepared candidates only';summary.limits=['No cutover gate baseline is refreshed.','No runtime or player save is installed or modified.','Native unchanged tables/text are separately known to fail the current-source corpus.','Windows, Blender/GPU renders, randomized battle sweep and shipping save import remain separate checks.'];
 put(path.join(BASE,'evidence/packet_summary.json'),JSON.stringify(summary,null,2)+'\n');console.log(summary.status);
}catch(e){summary.error=e.stack;put(path.join(BASE,'evidence/packet_summary.json'),JSON.stringify(summary,null,2)+'\n');console.error(e.stack);process.exitCode=2;}
