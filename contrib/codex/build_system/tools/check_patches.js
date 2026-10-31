#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),cp=require('child_process'),os=require('os'),assert=require('assert'),crypto=require('crypto');
const base=path.resolve(__dirname,'..'),root=path.resolve(base,'../../..'),manifest=require('../patches/manifest.json'),results=[];
for(const jobs of [['module_fit'],['lineage_pilot'],['tree_copy'],['combined_runtime','tree_copy']]){
 const temp=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-patch-'));
 try{
  const files=manifest.files.filter(f=>jobs.includes(f.job));
  for(const f of files){if(f.newFile)continue;const bytes=cp.execFileSync('git',['show',manifest.sourcePin+':'+f.path],{cwd:root,maxBuffer:8*1024*1024});const p=path.join(temp,f.path);fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,bytes);}
  for(const job of jobs)cp.execFileSync('git',['apply','--whitespace=error-all',path.join(base,'patches',job+'.patch')],{cwd:temp});
  for(const f of files){const actual=crypto.createHash('sha256').update(fs.readFileSync(path.join(temp,f.path))).digest('hex');assert.equal(actual,f.candidateSHA256,f.job+':'+f.path);}
  results.push({jobs,files:files.length,status:'PASS: applies without whitespace errors and all candidate hashes match'});
 }finally{fs.rmSync(temp,{recursive:true,force:true});}
}
fs.writeFileSync(path.join(base,'evidence/patch_checks.json'),JSON.stringify({sourcePin:manifest.sourcePin,results},null,2)+'\n');
console.log('PASS: all three individual patches, plus combined runtime followed by tree copy; resulting SHA-256 hashes match');
