#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,path,os,ROOT,BASE,put,run,sha}=C;
function check(){
 const work=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-final-combined-'));C.copyProject(ROOT,work);
 for(const f of fs.readdirSync(ROOT).filter(f=>f.endsWith('.js')))fs.copyFileSync(path.join(ROOT,f),path.join(work,f));
 const manifest=JSON.parse(fs.readFileSync(path.join(BASE,'patches/manifest.json'))),old=JSON.parse(fs.readFileSync(path.join(ROOT,'contrib/codex/pre_opus/patches/manifest.json')));
 const final=new Map(old.files.filter(x=>x.job==='integration').map(x=>[x.path,x.candidateSHA256]));
 for(const e of old.files.filter(x=>x.job==='integration'))assert.equal(sha(fs.readFileSync(path.join(work,e.path))),e.baseSHA256,e.path);
 run('git',['apply','--whitespace=error-all',path.join(ROOT,'contrib/codex/pre_opus/patches/integration.patch')],{cwd:work});
 for(const job of ['campaign_hulls_after_integration','battle_refresh']){
  for(const e of manifest.jobs[job])assert.equal(sha(fs.readFileSync(path.join(work,e.path))),e.baseSHA256,e.path+' base');
  run('git',['apply','--whitespace=error-all',path.join(BASE,'patches',job+'.patch')],{cwd:work});
  for(const e of manifest.jobs[job])final.set(e.path,e.candidateSHA256);
 }
 for(const [p,hash] of final)assert.equal(sha(fs.readFileSync(path.join(work,p))),hash,p+' result');
 const checks={status:'PASS',work,order:['integration.patch','campaign_hulls_after_integration.patch','battle_refresh.patch'],verifiedFiles:final.size,hashes:Object.fromEntries(final)};
 put(path.join(BASE,'evidence/patch_checks.json'),JSON.stringify(checks,null,2)+'\n');
 console.log(JSON.stringify(checks));return work;
}
if(require.main===module){try{check();}catch(e){console.error(e.stack);process.exitCode=2;}}
module.exports={check};
