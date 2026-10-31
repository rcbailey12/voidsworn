#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path');
const {prepare}=require('./prepare_checks');
const base=path.resolve(__dirname,'..');
function setup(work){
 const dirs=prepare(work),candidate=path.join(base,'candidates/lineage_pilot');
 for(const file of ['core.js','battle.js','campaign_meta.js','ui3d.js'])fs.copyFileSync(path.join(candidate,file),path.join(dirs.overlay,file));
 for(const file of ['godot/campaign/campaign.gd','godot/campaign/lineage_model.gd','godot/campaign/data/lineage_pilot.json','godot/rules/rules.gd','godot/rules/lineage_pilot.gd']){
  const to=path.join(dirs.project,file.replace(/^godot\//,''));fs.mkdirSync(path.dirname(to),{recursive:true});fs.copyFileSync(path.join(candidate,file),to);
 }
 fs.copyFileSync(path.join(base,'tools/pilot_checks.gd'),path.join(dirs.project,'codex/pilot_checks.gd'));
 fs.writeFileSync(path.join(work,'paths.json'),JSON.stringify(dirs,null,2)+'\n');return dirs;
}
if(require.main===module)console.log(JSON.stringify(setup(path.resolve(process.argv[2]))));module.exports={setup};
