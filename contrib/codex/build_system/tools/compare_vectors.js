#!/usr/bin/env node
'use strict';
const fs=require('fs'),assert=require('assert');
function read(file){const text=fs.readFileSync(file,'utf8');if(!text.endsWith('\n'))throw Error('truncated vector stream '+file);const rows=text.trim().split('\n').map(s=>JSON.parse(s)),map=new Map();for(const r of rows){const key=[r.kind,r.case??r.tpl,r.step??r.mod??''].join(':');if(map.has(key))throw Error('duplicate vector '+key);map.set(key,r);}return map;}
function delta(a,b,p=''){if(a===b)return null;if(typeof a!==typeof b||a===null||b===null||typeof a!=='object')return p+': '+JSON.stringify(a)+' vs '+JSON.stringify(b);for(const k of [...new Set(Object.keys(a).concat(Object.keys(b)))].sort()){if(!Object.hasOwn(a,k)||!Object.hasOwn(b,k))return p+'.'+k+': key missing';const d=delta(a[k],b[k],p+'.'+k);if(d)return d;}return null;}
function compare(a,b,expectedCount){assert(Number.isSafeInteger(expectedCount)&&expectedCount>0,'explicit expected count required');const left=read(a),right=read(b);assert.equal(left.size,expectedCount,'expected vector count mismatch');assert.equal(right.size,expectedCount,'expected vector count mismatch');for(const [key,row] of left){assert(right.has(key),'missing vector '+key);const d=delta(right.get(key),row);if(d)throw Error('state mismatch '+key+' '+d);}return left.size;}
if(require.main===module)console.log(compare(process.argv[2],process.argv[3],Number(process.argv[4]))+' exact cross-engine records match');
module.exports={compare};
