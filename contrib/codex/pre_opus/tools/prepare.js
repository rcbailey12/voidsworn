#!/usr/bin/env node
'use strict';
const fs=require('fs'),path=require('path'),cp=require('child_process'),os=require('os'),crypto=require('crypto'),T=require('./transforms');
const BASE=path.resolve(__dirname,'..'),ROOT=path.resolve(BASE,'../../..'),PIN='355a2ac70860db4446f040a5787b19c2d746d779';
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
function run(cmd,args,cwd=ROOT){const r=cp.spawnSync(cmd,args,{cwd,encoding:'utf8',maxBuffer:20*1024*1024});if(r.status!==0)throw Error(cmd+' '+args.join(' ')+'\n'+r.stderr+'\n'+r.stdout);return r.stdout;}
function put(root,file,data){const p=path.join(root,file);fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,data);}
function edit(root,file,fn){put(root,file,fn(fs.readFileSync(path.join(root,file),'utf8')));}
function pinned(file){const r=cp.spawnSync('git',['show',PIN+':'+file],{cwd:ROOT,maxBuffer:20*1024*1024});return r.status===0?r.stdout:null;}
function patch(before,after,file,temp){
 if(before!==null&&Buffer.compare(Buffer.from(before),Buffer.from(after))===0)return '';
 put(temp,'old',before||'');put(temp,'new',after);
 const r=cp.spawnSync('git',['diff','--no-index','--no-ext-diff','--text','--','old','new'],{cwd:temp,encoding:'utf8',maxBuffer:20*1024*1024});if(![0,1].includes(r.status))throw Error(r.stderr);
 return r.stdout.split('\n').map(l=>l.startsWith('diff --git ')?'diff --git a/'+file+' b/'+file+(before===null?'\nnew file mode 100644':''):l.startsWith('--- ')?'--- '+(before===null?'/dev/null':'a/'+file):l.startsWith('+++ ')?'+++ b/'+file:l).join('\n');
}
function list(root){let out=[];for(const f of fs.readdirSync(root,{withFileTypes:true})){if(f.name==='.godot')continue;const p=path.join(root,f.name);if(f.isDirectory())out=out.concat(list(p));else out.push(p);}return out;}
function nemesis(repo){
 for(const f of ['campaign_run.js','godot/campaign/test/oracle/campaign_run.js'])edit(repo,f,T.nemJS);
 for(const f of ['campaign3d.js','godot/campaign/test/oracle/campaign3d.js'])edit(repo,f,T.battleConsumer);
 edit(repo,'godot/campaign/campaign.gd',T.nemGD);
}
function boons(repo){
 for(const f of ['core.js','godot/campaign/test/oracle/core.js'])edit(repo,f,T.boonCore);
 for(const f of ['data.js','godot/campaign/test/oracle/data.js'])edit(repo,f,T.boonData);
 edit(repo,'godot/campaign/campaign.gd',T.boonCampaign);
 const before=JSON.parse(fs.readFileSync(path.join(repo,'godot/campaign/data/campaign_tables.json')));
 run(process.execPath,[path.join(repo,'godot/campaign/test/node/export_campaign.js')],repo);
 const after=JSON.parse(fs.readFileSync(path.join(repo,'godot/campaign/data/campaign_tables.json')));
 const a=JSON.parse(JSON.stringify(after.tables));delete a.BOON_NEED.L_storm;
 if(JSON.stringify(a)!==JSON.stringify(before.tables))throw Error('Unexpected campaign table change');
 if(after.tables.BOON_NEED.L_storm!=='shields')throw Error('Missing exported legendary gate');
}
function prepare(work){
 fs.mkdirSync(work,{recursive:true});const diffTemp=path.join(work,'diff');fs.mkdirSync(diffTemp,{recursive:true});
 const control=path.join(work,'control');fs.mkdirSync(control,{recursive:true});
 for(const file of fs.readdirSync(ROOT))if(file.endsWith('.js'))put(control,file,pinned(file));
 const godotFiles=run('git',['ls-tree','-r','--name-only',PIN,'--','godot']).trim().split('\n').filter(f=>f==='godot/project.godot'||/^godot\/(rules|campaign)\//.test(f)&&/\.(gd|js|json|sh|bat|md)$/.test(f));
 for(const file of godotFiles)put(control,file,pinned(file));
 // Assert checkout contents match source pin; Contrib candidate inputs are recorded separately below.
 const receipt=[];for(const f of list(control)){const rel=path.relative(control,f).replaceAll(path.sep,'/');const bytes=fs.readFileSync(f);if(fs.existsSync(path.join(ROOT,rel))){const local=fs.readFileSync(path.join(ROOT,rel));if(local.toString().replaceAll('\r\n','\n')!==bytes.toString().replaceAll('\r\n','\n'))throw Error('Source drift: '+rel);}receipt.push({path:rel,sha256:hash(bytes),lines:bytes.toString().trimEnd().split('\n').length,lastLineStart:bytes.toString().trimEnd().split('\n').at(-1).slice(0,40)});}
 const note=(repo,jobs)=>edit(repo,'godot/campaign/test/oracle/README.md',s=>s+'\n## Proposed pre-Opus exceptions (Codex, Oct 31, 2026)\n\nSource pin remains '+PIN+'. Only '+jobs+' are changed. Other pinned oracle behavior is retained. The exported campaign table changes only BOON_NEED.L_storm when the boon repair is selected; checksums are regenerated from this candidate oracle. Full general battle parity is not claimed.\n');
 const dirs={control};
 for(const job of ['nemesis','boons','integration','saro']){
  const repo=path.join(work,job);fs.cpSync(control,repo,{recursive:true});dirs[job]=repo;
  if(['integration','saro'].includes(job)){
   let earlier='';for(const f of ['core.js','campaign_run.js','godot/campaign/campaign.gd','godot/campaign/test/oracle/core.js','godot/campaign/test/oracle/campaign_run.js'])earlier+=patch(pinned(f),fs.readFileSync(path.join(ROOT,'contrib/codex/proposed',f)),f,diffTemp);
   put(work,'earlier.patch',earlier);run('git',['apply','--whitespace=error-all',path.join(work,'earlier.patch')],repo);
   run('git',['apply','--whitespace=error-all','--exclude=godot/campaign/test/oracle/README.md',path.join(ROOT,'contrib/codex/build_system/patches/module_fit.patch')],repo);
  }
  if(job!=='boons')nemesis(repo);
  if(job!=='nemesis')boons(repo);
  if(job==='saro'){
   run('git',['apply','--whitespace=error-all','--exclude=godot/campaign/test/oracle/README.md','--exclude=godot/rules/test/oracle/README.md',path.join(ROOT,'contrib/codex/build_system/patches/lineage_pilot.patch')],repo);
   edit(repo,'godot/rules/test/oracle/README.md',s=>s+'\nProposed Saro primary-Command pilot exception; other pinned behavior retained. See contrib/codex/build_system/README.md.\n');
  }
  note(repo,job==='nemesis'?'loss-learning and known-weakness clash repairs':job==='boons'?'weighted useful boon offers, shared offering-patron favour and shield legendary eligibility':job==='saro'?'elite/shipwright/module/Nemesis/boon repairs plus the opt-in Saro pilot':'elite/shipwright/module/Nemesis/boon repairs');
 }
 const manifest=[];
 for(const job of ['nemesis','boons','integration','saro']){
  const from=job==='saro'?dirs.integration:control;let full='';
  for(const f of list(dirs[job])){
   const name=path.relative(dirs[job],f).replaceAll(path.sep,'/'),old=path.join(from,name),before=fs.existsSync(old)?fs.readFileSync(old):null,after=fs.readFileSync(f);
   if(before!==null&&Buffer.compare(before,after)===0)continue;
   full+=patch(before,after,name,diffTemp);put(path.join(BASE,'candidates',job),name,after);manifest.push({job,path:name,baseSHA256:before===null?null:hash(before),candidateSHA256:hash(after)});
  }
  put(BASE,'patches/'+job+'.patch',full);
 }
 put(BASE,'patches/manifest.json',JSON.stringify({sourcePin:PIN,saroPatchBase:'integration',files:manifest},null,2)+'\n');
 put(BASE,'evidence/source_receipt.json',JSON.stringify({pin:PIN,scope:'Inventory and hashes; only touched function windows were reviewed. Not a full audit of these files.',files:receipt},null,2)+'\n');
 put(work,'paths.json',JSON.stringify(dirs,null,2)+'\n');return dirs;
}
if(require.main===module)console.log(JSON.stringify(prepare(path.resolve(process.argv[2]||fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-pre-opus-'))))));
module.exports={prepare,ROOT,BASE,PIN,run,put,hash,list};
