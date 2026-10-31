#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),assert=require('assert'),P=require('./prepare'),manifest=require('../patches/manifest.json');
const control=path.resolve(process.argv[2]),work=path.resolve(process.argv[3]),checks=[];
for(const jobs of [['nemesis'],['boons'],['integration','saro']]){
 const dest=path.join(work,jobs.join('_'));fs.cpSync(control,dest,{recursive:true});
 for(const job of jobs)P.run('git',['apply','--whitespace=error-all',path.join(P.BASE,'patches',job+'.patch')],dest);
 const latest=new Map();for(const job of jobs)for(const f of manifest.files.filter(f=>f.job===job))latest.set(f.path,f);
 for(const f of latest.values())assert.equal(P.hash(fs.readFileSync(path.join(dest,f.path))),f.candidateSHA256,f.path);
 checks.push({jobs,files:latest.size,status:'PASS'});
}
P.put(P.BASE,'evidence/patch_checks.json',JSON.stringify({pin:P.PIN,checks},null,2)+'\n');console.log('PASS: standalone Nemesis/boon patches and integration followed by Saro; all resulting hashes match');
