#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,path,os,BASE,ROOT,put,run,sha}=C,{compare}=require('./compare');
const FOCUSED=['s1','s2','s4','s6','s7','s8','s10','s14','s21','s26','s27','s28','s30','s33','s45','s46'];
function cli(argv=process.argv.slice(2)){
 const value=(flag,def)=>{const i=argv.indexOf(flag);if(i<0)return def;if(!argv[i+1]||argv[i+1].startsWith('--'))throw Error('Missing '+flag+' value');return argv[i+1];};
 const known=new Set(['--godot','--out','--candidate','--all']);
 for(const a of argv.filter(x=>x.startsWith('--')))if(!known.has(a))throw Error('Unknown option '+a);
 const positional=argv.filter((a,i)=>!a.startsWith('--')&&!['--godot','--out'].includes(argv[i-1]));
 if(positional.length>1)throw Error('Only one repository path is accepted');
 const repo=path.resolve(positional[0]||ROOT),candidate=argv.includes('--candidate'),all=argv.includes('--all');
 const lane=candidate?'battle_refresh_candidate':'native_current_source';
 const out=path.resolve(value('--out',path.join(BASE,'evidence',lane+(all?'_all48':'')))),godot=value('--godot',process.env.VOIDSWORN_GODOT_EXE||process.env.GODOT||'godot');
 fs.mkdirSync(out,{recursive:true});const work=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-combat-corpus-'));
 let summary={status:'INCOMPLETE',lane,work,sourceRepo:repo,scope:'Current browser battle.js and core.js with no-op presentation, versus native battle API. Headless rules evidence only.',cases:[]};
 try{
  const files=['data.js','core.js','battle.js','ui3d.js','campaign_run.js','godot/rules/rules.gd','godot/rules/battle_api.gd','godot/rules/jsm.gd','godot/rules/data/tables.json','godot/rules/test/node/golden.js','godot/rules/test/parity_main.gd','godot/rules/test/scenarios.json'];
  const receipt=C.receipt(repo,files);summary.inputs=receipt;
  summary.godotVersion=run(godot,['--version']).trim();
  const project=C.copyProject(repo,work);
  if(candidate){
   const entries=JSON.parse(fs.readFileSync(path.join(BASE,'patches/manifest.json'))).jobs.battle_refresh;
   for(const e of entries){const target=path.join(repo,e.path);assert.equal(sha(fs.readFileSync(target)),e.baseSHA256,'Candidate base drift: '+e.path);const bytes=fs.readFileSync(path.join(BASE,'candidates/battle_refresh',e.path));assert.equal(sha(bytes),e.candidateSHA256);put(path.join(work,e.path),bytes);}
   summary.candidateFiles=entries;
  }
  const scenarios=JSON.parse(fs.readFileSync(path.join(repo,'godot/rules/test/scenarios.json'))),ids=all?Object.keys(scenarios):FOCUSED;
  assert.equal(new Set(ids).size,ids.length);assert.equal(ids.length,all?48:16);
  const selected=Object.fromEntries(ids.map(id=>{assert(scenarios[id]);return [id,scenarios[id]];}));
  const scenarioPath=path.join(work,'scenarios.json');put(scenarioPath,JSON.stringify(selected));summary.scenariosSHA256=sha(fs.readFileSync(scenarioPath));
  const jsDir=path.join(work,'js'),gdDir=path.join(work,'gd');fs.mkdirSync(jsDir);fs.mkdirSync(gdDir);
  console.log('Running '+ids.length+' real battles: '+lane);
  const env=C.cleanEnv({VS_ORACLE:repo});summary.disabledSimulationOverrides=C.SIM_OVERRIDES;
  const jslog=run(process.execPath,[path.join(repo,'godot/rules/test/node/golden.js'),'batch',scenarioPath,jsDir],{env,timeout:600000});put(path.join(out,'node.log'),jslog);
  const gdlog=run(godot,['--headless','--path',project,'--script','res://rules/test/parity_main.gd','--','batch',scenarioPath,gdDir],{timeout:600000});put(path.join(out,'godot.log'),gdlog);
  for(const id of ids){
   const a=path.join(jsDir,id+'.jsonl'),b=path.join(gdDir,id+'.jsonl'),r=compare(a,b);
   summary.cases.push({id,seed:scenarios[id].seed,note:scenarios[id].note,...r,nodeFileSHA256:sha(fs.readFileSync(a)),godotFileSHA256:sha(fs.readFileSync(b))});
   console.log((r.pass?'PASS':'FAIL')+' vector '+id);
  }
  assert.deepEqual(C.receipt(repo,files),receipt,'Checked source changed during corpus execution');
  summary.pass=summary.cases.filter(x=>x.pass).length;summary.fail=ids.length-summary.pass;summary.total=ids.length;
  summary.comparedRecords=summary.cases.reduce((n,x)=>n+Math.min(x.recordsJS,x.recordsGodot),0);
  summary.status=summary.fail?'FAIL':'PASS';
  summary.limits=['No rendered UI, animation playback, Windows execution, GPU timing, save migration or cutover clearance.','The native lane retains installed tables and strings. The candidate lane explicitly replaces only the filed battle-refresh files in a temporary project.','No field, log string or numeric difference is normalized away.','The 16-case default is a focused corpus, not the complete 48-scenario suite or a random sweep.','The golden harness terminal end none is an explicit round limit, not a victory.'];
  put(path.join(out,'summary.json'),JSON.stringify(summary,null,2)+'\n');
  console.log('parity_vectors: '+summary.pass+' pass, '+summary.fail+' fail, '+summary.total+' total');
  return summary.fail?1:0;
 }catch(e){summary.error=e.stack;put(path.join(out,'summary.json'),JSON.stringify(summary,null,2)+'\n');console.error('INCOMPLETE: '+e.message);return 2;}
}
if(require.main===module){try{process.exitCode=cli();}catch(e){console.error(e.stack);process.exitCode=2;}}
module.exports={cli,FOCUSED};
