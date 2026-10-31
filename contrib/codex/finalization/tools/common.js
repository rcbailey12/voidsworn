'use strict';
const fs=require('fs'),path=require('path'),os=require('os'),cp=require('child_process'),crypto=require('crypto');
const ROOT=path.resolve(__dirname,'../../../..'),BASE=path.resolve(__dirname,'..');
const PIN='355a2ac70860db4446f040a5787b19c2d746d779';
const SIM_OVERRIDES=['RAMP','BOSS_SCALE','BOSS_DMG','NOCOMPACT','NOCLEAR','ADAPT','NOADAPT','NOPRELAUNCH','TORP_INSTANT','NOMIDFIRE','NOTRAITS','COVER'];
function cleanEnv(extra={}){const env={...process.env};for(const key of SIM_OVERRIDES)delete env[key];return {...env,...extra};}
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const put=(p,s)=>{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,s);};
function run(cmd,args,options={}){
 const r=cp.spawnSync(cmd,args,{cwd:ROOT,encoding:'utf8',maxBuffer:32*1024*1024,timeout:180000,windowsHide:true,env:cleanEnv(),...options});
 const output=(r.stdout||'')+(r.stderr||'');
 if(r.error||r.status!==0||/SCRIPT ERROR|Parse Error|Compile Error|NOT PORTED|BATTLE HALTED/.test(output))throw Error([cmd,args.join(' '),r.error?.message||'',output].join('\n'));
 return output;
}
function copyProject(repo,work){
 const project=path.join(work,'godot');
 for(const d of ['rules','campaign'])fs.cpSync(path.join(repo,'godot',d),path.join(project,d),{recursive:true,filter:p=>!/(?:^|[/\\])(?:\.godot|out|golden)(?:[/\\]|$)/.test(p)});
 put(path.join(project,'project.godot'),'[application]\nconfig/name="Voidsworn isolated finalization checks"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
 return project;
}
function receipt(repo,files){return files.map(file=>{const b=fs.readFileSync(path.join(repo,file)),lines=b.toString().split('\n');if(lines.at(-1)==='')lines.pop();return {path:file,sha256:sha(b),bytes:b.length,lines:lines.length,lastLineStart:lines.at(-1)?.slice(0,40)||''};});}
function diff(a,b,p='',out=[]){
 if(JSON.stringify(a)===JSON.stringify(b))return out;
 if(a&&b&&typeof a==='object'&&typeof b==='object'&&!Array.isArray(a)&&!Array.isArray(b)){
  for(const k of [...new Set([...Object.keys(a),...Object.keys(b)])].sort())diff(a[k],b[k],p?p+'.'+k:k,out);
 }else out.push({path:p,before:a===undefined?null:a,after:b===undefined?null:b});
 return out;
}
function patch(before,after,file){
 const work=fs.mkdtempSync(path.join(os.tmpdir(),'voidsworn-patch-'));
 try{put(path.join(work,'old'),before);put(path.join(work,'new'),after);const r=cp.spawnSync('git',['diff','--no-index','--no-ext-diff','--text','--','old','new'],{cwd:work,encoding:'utf8',maxBuffer:8*1024*1024});if(![0,1].includes(r.status))throw Error(r.stderr);return r.stdout.split('\n').map(l=>l.startsWith('diff --git ')?'diff --git a/'+file+' b/'+file:l.startsWith('--- ')?'--- a/'+file:l.startsWith('+++ ')?'+++ b/'+file:l).join('\n');}finally{fs.rmSync(work,{recursive:true,force:true});}
}
module.exports={fs,path,os,cp,ROOT,BASE,PIN,sha,put,run,copyProject,receipt,diff,patch,cleanEnv,SIM_OVERRIDES};
