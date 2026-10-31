#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),os=require('os');
const ROOT=path.resolve(__dirname,'../../../..'),BASE=path.resolve(__dirname,'..');
function prepare(work){
 const overlay=path.join(work,'browser'),project=path.join(work,'godot');fs.mkdirSync(overlay,{recursive:true});fs.mkdirSync(project,{recursive:true});
 for(const f of fs.readdirSync(ROOT))if(f.endsWith('.js'))fs.copyFileSync(path.join(ROOT,f),path.join(overlay,f));
 for(const f of ['core.js','campaign_run.js'])fs.copyFileSync(path.join(BASE,'candidates/module_fit',f),path.join(overlay,f));
 const files=fs.readdirSync(path.join(ROOT,'godot/rules')).filter(f=>f.endsWith('.gd')).map(f=>'godot/rules/'+f).concat(['godot/rules/data/tables.json','godot/campaign/data/campaign_tables.json']);
 for(const f of files){const to=path.join(project,f.replace(/^godot\//,''));fs.mkdirSync(path.dirname(to),{recursive:true});fs.copyFileSync(path.join(ROOT,f),to);}
 fs.mkdirSync(path.join(project,'campaign'),{recursive:true});fs.copyFileSync(path.join(BASE,'candidates/module_fit/godot/campaign/campaign.gd'),path.join(project,'campaign/campaign.gd'));
 fs.mkdirSync(path.join(project,'codex'),{recursive:true});fs.copyFileSync(path.join(BASE,'src/lineage.gd'),path.join(project,'codex/lineage.gd'));
 fs.copyFileSync(path.join(BASE,'tools/godot_checks.gd'),path.join(project,'codex/godot_checks.gd'));
 for(const f of ['catalog.json','roster.json'])fs.copyFileSync(path.join(BASE,'data',f),path.join(project,'codex',f));
 fs.writeFileSync(path.join(project,'project.godot'),'config_version=5\n[application]\nconfig/name="Voidsworn Codex build checks"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
 return {work,overlay,project};
}
if(require.main===module){const dirs=prepare(path.resolve(process.argv[2]||fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-build-checks-'))));fs.writeFileSync(path.join(dirs.work,'paths.json'),JSON.stringify(dirs,null,2)+'\n');console.log(JSON.stringify(dirs));}
module.exports={prepare};
