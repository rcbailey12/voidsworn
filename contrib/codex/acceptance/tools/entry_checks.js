#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,path,BASE,ROOT,put}=C;
const prepared=JSON.parse(fs.readFileSync(path.join(BASE,'evidence/campaign_preparation.json'))),cases=[];
for(const [id,repo,pass]of [['native_control',ROOT,false],['campaign_candidate',prepared.work,true]]){
 const r=C.cp.spawnSync(process.execPath,[path.join(__dirname,'entry_probe.js')],{cwd:ROOT,env:C.cleanEnv({VS_ORACLE:repo}),encoding:'utf8',timeout:60000});
 put(path.join(BASE,'evidence/entry_'+id+'.log'),(r.stdout||'')+(r.stderr||''));
 if(pass){assert.equal(r.status,0);const result=JSON.parse(r.stdout);assert.equal(result.prepCount,1);assert(Number.isFinite(result.setupMs)&&result.setupMs>=0);assert.equal(result.units,4);cases.push({id,exit:r.status,result});}
 else {assert.notEqual(r.status,0);assert.match(r.stderr,/ReferenceError: setupMs is not defined/);cases.push({id,exit:r.status,error:'ReferenceError: setupMs is not defined'});}
}
put(path.join(BASE,'evidence/entry_checks.json'),JSON.stringify({status:'PASS',scope:'Actual current JS battleScreen with four real rule units and instrumented presentation; candidate prepares once and records finite setup time; native control reproduces the entry crash.',cases},null,2)+'\n');console.log('PASS: battle-entry control fails as expected; candidate prepares once and records setup time');
