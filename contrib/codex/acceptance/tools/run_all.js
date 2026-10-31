#!/usr/bin/env node
'use strict';
const C=require('./common'),{fs,path,BASE,run,put}=C;
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi<0?process.env.VOIDSWORN_GODOT_EXE||'godot':args[gi+1],summary={status:'INCOMPLETE',checks:[]};
try{
 for(const file of ['run_campaign.js','check_campaign_patch.js','entry_checks.js','campaign_comparator_checks.js','run_threads.js','run_real_campaigns.js','check_saro_current.js','run_sweep.js']){
  console.log('Checking '+file);const text=run(process.execPath,[path.join(__dirname,file),'--godot',godot],{timeout:2400000});put(path.join(BASE,'evidence/aggregate_'+file+'.log'),text);summary.checks.push({file,status:'PASS'});
 }
 summary.status='PASS for automated source/campaign/rules checks only';summary.unverified=['Windows export and launch','Blender fixture execution and production renders','Production mesh sign-off','GPU stress at roughly 20 ships','Rendered phased-battle interaction acceptance','Shipping save migration intent'];
 put(path.join(BASE,'evidence/aggregate_summary.json'),JSON.stringify(summary,null,2)+'\n');console.log(summary.status+'; PC/render acceptance remains separate');
}catch(e){summary.error=e.stack;put(path.join(BASE,'evidence/aggregate_summary.json'),JSON.stringify(summary,null,2)+'\n');console.error(e.stack);process.exitCode=2;}
