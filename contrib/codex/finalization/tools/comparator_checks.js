#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),{fs,path,os,put,sha}=require('./common'),{compare}=require('./compare');
const args=process.argv.slice(2);if(args.length!==1)throw Error('Provide one complete real-battle jsonl fixture');
const work=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-comparator-test-')),original=fs.readFileSync(args[0],'utf8');
const rows=original.trim().split('\n').map(JSON.parse),a=path.join(work,'a.jsonl'),b=path.join(work,'b.jsonl');
put(a,original);put(b,original);assert(compare(a,b).pass);let count=1;
function rejects(label,change){const r=structuredClone(rows),text=change(r);put(b,typeof text==='string'?text:r.map(x=>JSON.stringify(x)).join('\n')+'\n');let rejected=false;try{rejected=!compare(a,b).pass;}catch(_){rejected=true;}assert(rejected,label+' passed');count++;}
rejects('empty',()=> '');rejects('missing trailing newline',()=>original.trimEnd());
rejects('missing terminal',r=>{r.pop();});rejects('duplicate turn',r=>{r[1].turn=0;});
rejects('missing start',r=>{for(const x of r)if(x.actor==='start')x.actor='other';});
rejects('tampered payload hash',r=>{r[0].state+=' ';});
rejects('invalid PRNG',r=>{r[0].rng=-1;});rejects('wrong round metadata',r=>{r[0].round++;});
rejects('validly hashed state divergence',r=>{const s=JSON.parse(r[0].state);s.units[0].hp--;r[0].state=JSON.stringify(s);r[0].hash=sha(r[0].state);});
rejects('PRNG-only divergence',r=>{r[0].rng=(r[0].rng+1)>>>0;});
console.log('PASS: '+count+' comparator checks against a complete actual battle');
