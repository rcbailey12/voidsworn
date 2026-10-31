#!/usr/bin/env node
'use strict';
// Prepare two independent, explicit candidates. Never install either into runtime.
const C=require('./common'),{fs,path,os,ROOT,BASE,PIN,put,run,sha,diff,patch}=C;
function prepare(work){
 fs.mkdirSync(work,{recursive:true});const project=C.copyProject(ROOT,work);
 const current=path.join(work,'current_rules_tables.json');
 run(process.execPath,[path.join(ROOT,'godot/rules/test/node/export_data.js'),current],{env:C.cleanEnv({VS_ORACLE:ROOT})});
 const live=JSON.parse(fs.readFileSync(current)),native=JSON.parse(fs.readFileSync(path.join(ROOT,'godot/campaign/data/campaign_tables.json')));
 const hullDiff=diff(native.tables.HULLS,live.tables.HULLS,'HULLS').filter(x=>!x.path.endsWith('.n'));
 const rulesHullDiff=diff(JSON.parse(fs.readFileSync(path.join(ROOT,'godot/rules/data/tables.json'))).tables.HULLS,live.tables.HULLS,'HULLS').filter(x=>!x.path.endsWith('.n'));
 if(hullDiff.length!==16||new Set(hullDiff.map(x=>x.path.split('.')[1])).size!==12||rulesHullDiff.length)throw Error('Unexpected hull drift; review source before regenerating candidates');
 put(path.join(BASE,'evidence/hull_drift.json'),JSON.stringify({pin:PIN,comparedHulls:Object.keys(live.tables.HULLS).length,campaignMechanicalDifferences:hullDiff,rulesMechanicalDifferences:rulesHullDiff,note:'Only display field n is excluded from the mechanical hull comparison. Full exports remain unchanged in runtime.'},null,2)+'\n');
 const manifest={pin:PIN,jobs:{battle_refresh:[],campaign_hulls_after_integration:[]}};
 function candidate(job,file,base,after){
  if(base===after)return;put(path.join(BASE,'candidates',job,file),after);
  manifest.jobs[job].push({path:file,baseSHA256:sha(base),candidateSHA256:sha(after)});
  return patch(base,after,file);
 }
 let battlePatch='';const rulePath='godot/rules/rules.gd',before=fs.readFileSync(path.join(ROOT,rulePath),'utf8');let after=before;
 const edits=[
  [" is torn apart by the dead star's gravity."," is torn apart by the Hollow Sun's gravity."],
  [' on the auspex.',' on the scanners.'],['A dead star warps this field.','The Hollow Sun warps this field.'],
  ['The phylactery hums. ','Second ignition. '],[' reawakens at 25% hull.',' restarts at 25% hull.'],
  [' reanimates ',' rebuilds '],['Nova blast hits ','Spinal shell hits '],
  ['flt(t, "Reawakens",','flt(t, "Restarts",'],['flt(t, "Reanimating",','flt(t, "Rebuilding",']
 ];
 for(const [from,to] of edits){if(after.split(from).length!==2)throw Error('Battle text anchor changed: '+from);after=after.replace(from,to);}
 battlePatch+=candidate('battle_refresh',rulePath,before,after)||'';
 battlePatch+=candidate('battle_refresh','godot/rules/data/tables.json',fs.readFileSync(path.join(ROOT,'godot/rules/data/tables.json'),'utf8'),fs.readFileSync(current,'utf8'))||'';
 for(const file of ['data.js','core.js','battle.js'])battlePatch+=candidate('battle_refresh','godot/rules/test/oracle/'+file,fs.readFileSync(path.join(ROOT,'godot/rules/test/oracle',file),'utf8'),fs.readFileSync(path.join(ROOT,file),'utf8'))||'';
 const ui=fs.readFileSync(path.join(ROOT,'ui3d.js'),'utf8'),names=ui.match(/^const FNAMES=[\s\S]*?\};/m)?.[0];
 const hook=fs.readFileSync(path.join(ROOT,'campaign_run.js'),'utf8').match(/^function nemAdaptName\(.*$/m)?.[0];
 if(!names||!hook)throw Error('Cannot extract current ship names / Nemesis name hook');
 for(const [f,s] of [['fnames.js',names+'\n'],['campaign_hooks.js',hook+'\n']])battlePatch+=candidate('battle_refresh','godot/rules/test/oracle/'+f,fs.readFileSync(path.join(ROOT,'godot/rules/test/oracle',f),'utf8'),s)||'';
 const readme='godot/rules/test/oracle/README.md',old=fs.readFileSync(path.join(ROOT,readme),'utf8');
 const note='# Battle oracle refresh candidate\n\nSource: '+PIN+'. data.js, core.js and battle.js are byte copies of that source. FNAMES and nemAdaptName are extracted verbatim from its UI/campaign files. This intentionally replaces the older oracle described below. The native rules change is text-only; tables, including RAMP and current names, are regenerated from this pin.\n\nRun the finalization current-source corpus and the original parity/sweep checks after adoption. This is not rendered gameplay, whole campaign parity, migration approval or release clearance. Apply before optional Saro, whose rules.gd and oracle hunks require reconciliation.\n\n## Previous oracle record (historical)\n\n'+old;
 battlePatch+=candidate('battle_refresh',readme,old,note)||'';
 put(path.join(BASE,'patches/battle_refresh.patch'),battlePatch);
 // Campaign hull synchronization is layered AFTER the prepared integration patch.
 const integration=path.join(ROOT,'contrib/codex/pre_opus/candidates/integration');
 const cpath='godot/campaign/test/oracle/data.js',cbase=fs.readFileSync(path.join(integration,cpath),'utf8');let cafter=cbase;
 const data=fs.readFileSync(path.join(ROOT,'data.js'),'utf8');
 for(const id of ['b_drone','b_spitter','b_razor','b_brood']){
  const re=new RegExp('^  '+id+':.*$','m'),a=cafter.match(re)?.[0],b=data.match(re)?.[0];if(!a||!b)throw Error('Missing hull '+id);
  const n=b.match(/regen:(\d+)/)?.[1];if(!n)throw Error('Missing regen '+id);cafter=cafter.replace(a,a.replace(/regen:\d+/,'regen:'+n));
 }
 for(const id of ['vs_penitent_l','h_interdictor_e','c_marauder_g','b_razor_e','i_carrier_a','d_jackal_h']){
  const re=new RegExp('^  '+id+':.*$','m'),a=cafter.match(re)?.[0],b=data.match(re)?.[0];if(!a||!b)throw Error('Missing variant '+id);
  const oldName=a.match(/n:'([^']+)'/)?.[0];if(!oldName)throw Error('Missing variant name '+id);
  cafter=cafter.replace(a,b.replace(/n:'([^']+)'/,oldName));
 }
 put(path.join(project,'campaign/test/oracle/data.js'),cafter);
 const tempTables=path.join(work,'hull_campaign_tables.json');
 run(process.execPath,[path.join(project,'campaign/test/node/export_campaign.js'),tempTables],{env:C.cleanEnv({VS_ORACLE:path.join(project,'campaign/test/oracle')})});
 const sourceBase=JSON.parse(fs.readFileSync(path.join(integration,'godot/campaign/data/campaign_tables.json'))),exported=JSON.parse(fs.readFileSync(tempTables));
 // The integration's only table exception outside hulls is the shield-legendary gate.
 const baseRest=structuredClone(sourceBase.tables),afterRest=structuredClone(exported.tables);
 for(const t of ['HULLS','HULL_VARIANTS']){delete baseRest[t];delete afterRest[t];}
 afterRest.BOON_NEED=sourceBase.tables.BOON_NEED;
 if(JSON.stringify(baseRest)!==JSON.stringify(afterRest))throw Error('Unexpected non-hull campaign table change');
 exported.tables.BOON_NEED=sourceBase.tables.BOON_NEED;
 const canon=v=>v===null||v===undefined?'null':typeof v==='boolean'?String(v):typeof v==='number'?String(v):typeof v==='string'?(v.startsWith('#d:')?'"d:'+v.slice(3)+'"':JSON.stringify(v)):Array.isArray(v)?'['+v.map(canon).join(',')+']':'{'+Object.keys(v).filter(k=>v[k]!=null).sort().map(k=>JSON.stringify(k)+':'+canon(v[k])).join(',')+'}';
 exported.sha256=sha(canon(exported.tables));
 const remaining=diff(exported.tables.HULLS,live.tables.HULLS,'HULLS').filter(x=>!x.path.endsWith('.n'));
 if(remaining.length)throw Error('Hull candidate still differs: '+JSON.stringify(remaining));
 const changes=diff(sourceBase.tables,exported.tables);
 if(changes.some(x=>!/^HULLS\.|^HULL_VARIANTS\./.test(x.path)))throw Error('Unexpected table change');
 let hullPatch='';hullPatch+=candidate('campaign_hulls_after_integration',cpath,cbase,cafter)||'';
 hullPatch+=candidate('campaign_hulls_after_integration','godot/campaign/data/campaign_tables.json',JSON.stringify(sourceBase),JSON.stringify(exported))||'';
 const campaignReadme='godot/campaign/test/oracle/README.md',campaignNote=fs.readFileSync(path.join(integration,campaignReadme),'utf8');
 hullPatch+=candidate('campaign_hulls_after_integration',campaignReadme,campaignNote,'# Additional explicit hull synchronization candidate\n\nCodex finalization, October 31, 2026: four base hull regeneration rows and six arc-variant rows are synchronized mechanically to main '+PIN+', preserving this older campaign oracle\'s display names. The resulting HULLS/HULL_VARIANTS changes and checksum are regenerated; all other exported tables, including prices and the integrated legendary shield gate, are retained. This is a separate exception to the older pin, not a whole campaign re-pin. This header qualifies the older exception wording retained below. See contrib/codex/finalization/README.md for exact field deltas and native verification.\n\n## Retained campaign oracle history\n\n'+campaignNote)||'';
 // Preserve exact pre-existing table bytes as the patch base (not a JSON reformat).
 const rawBase=fs.readFileSync(path.join(integration,'godot/campaign/data/campaign_tables.json'),'utf8');
 if(rawBase!==JSON.stringify(sourceBase))throw Error('Campaign serialization changed');
 put(path.join(BASE,'patches/campaign_hulls_after_integration.patch'),hullPatch);
 put(path.join(BASE,'evidence/hull_candidate_changes.json'),JSON.stringify({changes,retainedBoonGate:exported.tables.BOON_NEED.L_storm,remainingMechanicalDifferences:remaining},null,2)+'\n');
 put(path.join(BASE,'patches/manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 return {work,project,manifest};
}
if(require.main===module){try{console.log(JSON.stringify(prepare(path.resolve(process.argv[2]||fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-final-prepare-'))))))}catch(e){console.error(e.stack);process.exitCode=2;}}
module.exports={prepare};
