#!/usr/bin/env node
'use strict';
const C=require('./common'),assert=require('assert/strict');
try{
 const work=require('../../finalization/tools/check_patches').check(),manifest=JSON.parse(C.fs.readFileSync(C.BASE+'/patches/campaign_manifest.json'));
 for(const e of manifest.files)assert.equal(C.sha(C.fs.readFileSync(C.path.join(work,e.path))),e.baseSHA256,e.path+' base');
 C.run('git',['apply','--whitespace=error-all',C.BASE+'/patches/campaign_current.patch'],{cwd:work});
 for(const e of manifest.files)assert.equal(C.sha(C.fs.readFileSync(C.path.join(work,e.path))),e.candidateSHA256,e.path+' candidate');
 C.run('git',['apply','--check','--whitespace=error-all',C.ROOT+'/contrib/codex/pre_opus/patches/saro.patch'],{cwd:work});
 C.put(C.BASE+'/evidence/campaign_patch_checks.json',JSON.stringify({status:'PASS',work,verifiedFiles:manifest.files.length,saroAppliesAfterward:true},null,2)+'\n');
 console.log('PASS: strict campaign patch application, file hashes and optional Saro patch');
}catch(e){console.error(e.stack);process.exitCode=2;}
