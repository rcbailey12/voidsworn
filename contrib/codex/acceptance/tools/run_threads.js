#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,path,BASE,put,logged}=C;
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi<0?process.env.VOIDSWORN_GODOT_EXE||'godot':args[gi+1];
const summary={status:'INCOMPLETE',scope:'Existing native API thread and hard-stop test, with current-source refreshed tables and the earlier repairs.'};
(async()=>{
 const prepared=JSON.parse(fs.readFileSync(path.join(BASE,'evidence/campaign_preparation.json')));summary.project=prepared.project;
 await logged('thread_checks',godot,['--headless','--path',prepared.project,'--script','res://rules/test/thread_test.gd','--','s4','s23'],{timeout:900000});
 const text=fs.readFileSync(path.join(BASE,'evidence/thread_checks.log'),'utf8');assert.match(text,/hard stop check: PASS/);summary.tests=[];
 for(const id of ['s4','s23']){const match=text.match(new RegExp('thread test '+id+': PASS \\(over after round (\\d+), (\\d+) events, (\\d+) reads during enemy steps on a worker'));assert(match,'Missing complete thread result '+id);assert(+match[3]>0,'No concurrent reads '+id);summary.tests.push({id,phase:'over',round:+match[1],events:+match[2],workerReads:+match[3]});}
 summary.status='PASS';summary.limits=['Intentional NOT PORTED and bad-config probes in this test must halt; their expected diagnostics are not normal-game failures.','No rendered scene, GPU work or native scene teardown is exercised by this API test.'];put(path.join(BASE,'evidence/thread_summary.json'),JSON.stringify(summary,null,2)+'\n');console.log('PASS: both native threaded battles terminate identically; hard stop blocks subsequent commands');
})().catch(e=>{summary.error=e.stack;put(path.join(BASE,'evidence/thread_summary.json'),JSON.stringify(summary,null,2)+'\n');console.error(e.stack);process.exitCode=2;});
