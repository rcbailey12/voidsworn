#!/usr/bin/env node
'use strict';
// Adversarial adapter tests: run the real gate code against controlled child output.
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const os = require('os');
const {spawnSync} = require('child_process');
const repo = path.resolve(__dirname, '../../..');
const gate = path.join(repo, 'contrib/muse/tools/cutover_gate/gate.js');
let child = {status:0, stdout:'', stderr:''};
const sandbox = {module:{exports:{}}, __dirname:path.dirname(gate), process,
  require(name) { return name === 'child_process' ? {spawnSync:()=>child} : require(name); }};
vm.runInNewContext(fs.readFileSync(gate,'utf8'),sandbox,{filename:gate});
const g = sandbox.module.exports;
let checks=0;
function check(name, fn) { fn(); checks++; console.log('PASS '+name); }
const base={badSet:['B'],goodSet:['A'],watchSet:[]};
const cur=(bad,good)=>({badSet:bad,goodSet:good,watchSet:[]});
check('missing baseline stays NOT RUN',()=>assert.equal(g.classify(cur([],['A']),null,true).verdict,'NOT RUN'));
check('removed failing test is REGRESSION',()=>assert.equal(g.classify(cur([],['A']),base,true).verdict,'REGRESSION'));
check('observed failing-to-passing test is IMPROVEMENT',()=>assert.equal(g.classify(cur([],['A','B']),base,true).verdict,'IMPROVEMENT'));
check('lost passing test is REGRESSION',()=>assert.equal(g.classify(cur(['B'],[]),base,true).verdict,'REGRESSION'));
check('unchanged failure never becomes PASS',()=>assert.equal(g.classify(cur(['B'],['A']),base,true).verdict,'KNOWN-FAIL'));
check('missing check outranks improvement',()=>assert.match(g.overallVerdict(['IMPROVEMENT','NOT RUN']),/^INCOMPLETE/));
check('shrinking drift coverage is REGRESSION',()=>assert.equal(g.classify({...cur([],[]),signature:{constCompared:95}}, {...cur([],[]),signature:{constCompared:120}},true).verdict,'REGRESSION'));
const ctx={repo,find:()=>'/fixture/runner.js',findDir:()=>'/fixture'};
function output(text,status=0){child={stdout:text,status,stderr:''};}
check('complete findings accepted',()=>{output('PASS A works\nFAIL B broken\n2 tests, 1 pass, 1 fail\n',1);assert(!g.compFindings(ctx).notRun);});
check('duplicate findings identities rejected',()=>{output('PASS A works\nFAIL A broken\n2 tests, 1 pass, 1 fail\n',1);assert(g.compFindings(ctx).notRun);});
check('truncated findings rejected',()=>{output('PASS A works\n2 tests, 1 pass, 1 fail\n',1);assert(g.compFindings(ctx).notRun);});
check('findings abnormal exit rejected',()=>{output('PASS A works\n1 tests, 1 pass, 0 fail\n',2);assert(g.compFindings(ctx).notRun);});
check('empty findings rejected',()=>{output('0 tests, 0 pass, 0 fail\n');assert(g.compFindings(ctx).notRun);});
check('complete parity accepted',()=>{output('PASS vector V1\nparity_vectors: 1 pass, 0 fail, 1 total\n');assert(!g.compParity(ctx).notRun);});
check('truncated parity rejected',()=>{output('parity_vectors: 1 pass, 0 fail, 1 total\n');assert(g.compParity(ctx).notRun);});
check('duplicate parity rejected',()=>{output('PASS vector V1\nPASS vector V1\nparity_vectors: 2 pass, 0 fail, 2 total\n');assert(g.compParity(ctx).notRun);});
check('parity exit mismatch rejected',()=>{output('PASS vector V1\nparity_vectors: 1 pass, 0 fail, 1 total\n',1);assert(g.compParity(ctx).notRun);});
check('xref abnormal exit rejected',()=>{output('table_xref: 0 failures, 0 warnings\n',2);assert(g.compXref(ctx).notRun);});
check('xref truncated failure rejected',()=>{output('table_xref: 1 failures, 0 warnings\n',1);assert(g.compXref(ctx).notRun);});
check('lint without coverage rejected',()=>{output('naming_lint: 0 hard hits, 0 current-voice candidates, 0 historical/id mentions\n');assert(g.compNaming(ctx).notRun);});
check('importer duplicate identities rejected',()=>{output('PASS A\nPASS A\nAll checks (fixtures + synthetic): 2/2 passing\n');assert(g.compImporter(ctx).notRun);});
check('fixtures abnormal exit rejected',()=>{output('PASS fixture A\nfixture_check: 1/1 cases passing\n',2);assert(g.compFixtures(ctx).notRun);});
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-empty-'));
try {
 const lint=path.join(repo,'contrib/muse/tools/harness/validators/naming_lint.js');
 check('real lint rejects empty directory',()=>assert.equal(spawnSync(process.execPath,[lint,temp]).status,2));
 check('real lint rejects missing target',()=>assert.equal(spawnSync(process.execPath,[lint,path.join(temp,'missing')]).status,2));
 check('drift rejects missing source before child execution',()=>assert(g.compDrift({...ctx,repo:temp}).notRun));
} finally { fs.rmSync(temp,{recursive:true,force:true}); }
console.log(checks+' verification repair checks passed');
