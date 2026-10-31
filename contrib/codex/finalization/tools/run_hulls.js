#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,path,os,cp,ROOT,BASE,put,run,sha}=C;
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi<0?process.env.VOIDSWORN_GODOT_EXE||'godot':args[gi+1];
const out=path.join(BASE,'evidence/hull_validation'),work=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-hulls-'));fs.mkdirSync(out,{recursive:true});
const summary={status:'INCOMPLETE',work,scope:'Prepared integration, then campaign hull synchronization; no native table replacement by fixture input.'};
try{
 const expected=JSON.parse(fs.readFileSync(path.join(ROOT,'contrib/codex/pre_opus/patches/manifest.json'))).files.filter(x=>x.job==='integration');
 const receipt=C.receipt(ROOT,expected.map(x=>x.path));
 // Export the browser vectors from actual integrated core.js and current data.js.
 C.copyProject(ROOT,work);for(const f of fs.readdirSync(ROOT).filter(f=>f.endsWith('.js')))fs.copyFileSync(path.join(ROOT,f),path.join(work,f));
 for(const e of expected){assert.equal(sha(fs.readFileSync(path.join(ROOT,e.path))),e.baseSHA256,'Integration base drift: '+e.path);}
 run('git',['apply','--whitespace=error-all',path.join(ROOT,'contrib/codex/pre_opus/patches/integration.patch')],{cwd:work});
 put(path.join(work,'godot/campaign/test/final_hulls.gd'),fs.readFileSync(path.join(__dirname,'hull_vectors.gd')));
 const js=path.join(work,'js.jsonl');put(path.join(out,'browser.log'),run(process.execPath,[path.join(__dirname,'hull_vectors.js'),work,js]));
 const load=p=>{const t=fs.readFileSync(p,'utf8');assert(t.endsWith('\n'));const r=t.trim().split('\n').map(JSON.parse);assert.equal(r.length,816);assert.equal(new Set(r.map(x=>x.id)).size,816);return r;};
 const want=load(js);
 for(const lane of ['integration_control','hull_candidate']){
  if(lane==='hull_candidate')run('git',['apply','--whitespace=error-all',path.join(BASE,'patches/campaign_hulls_after_integration.patch')],{cwd:work});
  const gd=path.join(work,lane+'.jsonl');put(path.join(out,lane+'.log'),run(godot,['--headless','--path',path.join(work,'godot'),'--script','res://campaign/test/final_hulls.gd','--',gd]));
  const got=load(gd),differences=[];
  for(let i=0;i<want.length;i++){assert.equal(got[i].id,want[i].id);try{assert.deepEqual(got[i],want[i]);}catch(_){differences.push({id:want[i].id,browser:want[i],godot:got[i]});}}
  summary[lane]={total:816,matched:816-differences.length,differences,nodeFileSHA256:sha(fs.readFileSync(js)),godotFileSHA256:sha(fs.readFileSync(gd))};
  if(lane==='integration_control'){assert.equal(differences.filter(x=>x.id.includes(':hull')).length,12);assert.equal(differences.filter(x=>x.id.includes(':fit:')).length,4);}
  else assert.equal(differences.length,0,'Candidate must match every native record');
 }
 // Check each applied candidate file, not just git apply's exit status.
 const manifest=JSON.parse(fs.readFileSync(path.join(BASE,'patches/manifest.json'))).jobs.campaign_hulls_after_integration;
 for(const e of manifest)assert.equal(sha(fs.readFileSync(path.join(work,e.path))),e.candidateSHA256,e.path);
 assert.deepEqual(C.receipt(ROOT,expected.map(x=>x.path)),receipt,'Runtime source changed during hull checks');
 summary.status='PASS';summary.sourceInputs=receipt;summary.limits=['Display names and weapon labels are deliberately excluded in this mechanical inventory fixture.','Both native campaign and browser derive are executed on synthetic Mark I/III ships with no admiral, perks, refits, boons or relics. This is not whole-campaign parity.'];
 put(path.join(out,'summary.json'),JSON.stringify(summary,null,2)+'\n');console.log('PASS: 816 native hull/fitting/derived records match after the separate hull candidate');
}catch(e){summary.error=e.stack;put(path.join(out,'summary.json'),JSON.stringify(summary,null,2)+'\n');console.error(e.stack);process.exitCode=2;}
