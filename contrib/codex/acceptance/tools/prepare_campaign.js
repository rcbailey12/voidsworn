#!/usr/bin/env node
'use strict';
const C=require('./common'),{fs,path,BASE,ROOT,put,run,sha}=C;
function prepare(){
 const work=require('../../finalization/tools/check_patches').check(),project=path.join(work,'godot'),changes=[];let patch='';
 function candidate(file,before,after){if(before===after)return;put(path.join(BASE,'candidates/current_campaign',file),after);patch+=C.patch(before,after,file);changes.push({path:file,baseSHA256:sha(before),candidateSHA256:sha(after)});put(path.join(work,file),after);}
 const file='campaign3d.js',before=fs.readFileSync(path.join(work,file),'utf8');
 const bad=' // R42: a Hegemony Nemesis always brings reinforcements in round 3 prepBattle(); const setupMs=Math.round(performance.now()-setupT0);';
 const good=' prepBattle(); const setupMs=Math.round(performance.now()-setupT0); // R42: a Hegemony Nemesis always brings reinforcements in round 3';
 if(before.split(bad).length!==2)throw Error('Battle-entry source anchor changed');candidate(file,before,before.replace(bad,good));
 const names=['data.js','core.js','battle.js','campaign_meta.js','campaign_run.js','campaign3d.js','ui3d.js'];
 for(const name of names){const p='godot/campaign/test/oracle/'+name;candidate(p,fs.readFileSync(path.join(work,p),'utf8'),fs.readFileSync(path.join(work,name),'utf8'));}
 const table='godot/campaign/data/campaign_tables.json',old=fs.readFileSync(path.join(work,table),'utf8'),dest=path.join(work,'current_campaign_tables.json');
 run(process.execPath,[path.join(project,'campaign/test/node/export_campaign.js'),dest],{env:C.cleanEnv({VS_ORACLE:work})});
 const fresh=fs.readFileSync(dest,'utf8'),d=C.diff(JSON.parse(old).tables,JSON.parse(fresh).tables);candidate(table,old,fresh);
 const readme='godot/campaign/test/oracle/README.md',oldNote=fs.readFileSync(path.join(work,readme),'utf8');
 const note='# Current-source campaign oracle candidate\n\nPrepared from main '+C.PIN+' plus the earlier integration, hull synchronization and browser battle-entry statement repair. All seven JS files here are byte copies of the combined browser source. This intentionally supersedes the older campaign pin below. All campaign tables are regenerated from that same source, not cherry-picked; see contrib/codex/acceptance/evidence/current_campaign_table_changes.json. No migration policy, boot unlock grant, imported player profile or native save is changed. The campaign bot uses stub battles; real rules battles are tested separately.\n\n## Historical oracle notes\n\n'+oldNote;
 candidate(readme,oldNote,note);
 put(path.join(BASE,'patches/campaign_current.patch'),patch);
 put(path.join(BASE,'patches/campaign_manifest.json'),JSON.stringify({sourcePin:C.PIN,base:'integration + campaign_hulls_after_integration + battle_refresh',files:changes},null,2)+'\n');
 put(path.join(BASE,'evidence/current_campaign_table_changes.json'),JSON.stringify({sourcePin:C.PIN,tables:[...new Set(d.map(x=>x.path.split('.')[0]))],changes:d},null,2)+'\n');
 put(path.join(BASE,'evidence/campaign_preparation.json'),JSON.stringify({work,project,files:changes,sourceInputs:C.receipt(work,names)},null,2)+'\n');
 return {work,project};
}
if(require.main===module){try{console.log(JSON.stringify(prepare()));}catch(e){console.error(e.stack);process.exitCode=2;}}
module.exports={prepare};
