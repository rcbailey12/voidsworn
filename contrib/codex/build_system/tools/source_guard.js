#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),cp=require('child_process'),crypto=require('crypto');
const root=path.resolve(__dirname,'../../../..'),pin='355a2ac70860db4446f040a5787b19c2d746d779';
const files=['data.js','core.js','battle.js','campaign_meta.js','campaign_run.js','ui3d.js','godot/campaign/campaign.gd','godot/rules/rules.gd','godot/campaign/data/campaign_tables.json','godot/rules/data/tables.json',
 'godot/campaign/test/oracle/core.js','godot/campaign/test/oracle/battle.js','godot/campaign/test/oracle/campaign_meta.js','godot/rules/test/oracle/core.js','godot/rules/test/oracle/battle.js',
 ...['skill_tree_proposal_final_2026_10_28.md','skill_tree_phase1_assembled_2026_10_29.md','skill_tree_tier2_assembled_2026_10_29.md','skill_tree_tier3_assembled_2026_10_29.md'].map(f=>'contrib/muse/reviews/'+f)];
const sha=b=>crypto.createHash('sha256').update(b).digest('hex'),hashes={};
for(const file of files){const pinned=cp.execFileSync('git',['show',pin+':'+file],{cwd:root,maxBuffer:8*1024*1024}),working=fs.readFileSync(path.join(root,file));if(pinned.toString('utf8').replace(/\r\n/g,'\n')!==working.toString('utf8').replace(/\r\n/g,'\n'))throw Error('Source drift: '+file+'. Rebase this packet and update its pin/expectations; do not overwrite intervening work.');hashes[file]={gitSHA256:sha(pinned),checkoutSHA256:sha(working),lineEndingNormalizedMatch:true};}
fs.mkdirSync(path.resolve(__dirname,'../evidence'),{recursive:true});fs.writeFileSync(path.resolve(__dirname,'../evidence/source_hashes.json'),JSON.stringify({pin,hashes},null,2)+'\n');console.log(files.length+' native/design inputs match the recorded pin');
