#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),cp=require('child_process');
const base=path.resolve(__dirname,'..'),root=path.resolve(base,'../../..'),{setup}=require('./prepare_pilot_checks');
const work=path.resolve(process.argv[2]),seed=setup(path.join(work,'seed')),repo=path.join(work,'repo');
fs.mkdirSync(repo,{recursive:true});fs.cpSync(seed.overlay,repo,{recursive:true});fs.cpSync(seed.project,path.join(repo,'godot'),{recursive:true});
const manifest=require('../patches/manifest.json');
for(const f of manifest.files.filter(f=>f.job==='combined_runtime')){
 const p=path.join(repo,f.path);if(f.newFile){fs.rmSync(p,{force:true});continue;}
 const bytes=cp.execFileSync('git',['show',manifest.sourcePin+':'+f.path],{cwd:root,maxBuffer:8*1024*1024});fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,bytes);
}
cp.execFileSync('git',['apply','--whitespace=error-all',path.join(base,'patches/combined_runtime.patch')],{cwd:repo,encoding:'utf8'});
const dirs={work,overlay:repo,project:path.join(repo,'godot')};fs.writeFileSync(path.join(work,'paths.json'),JSON.stringify(dirs,null,2)+'\n');console.log(JSON.stringify(dirs));
