'use strict';
const C=require('../../finalization/tools/common');
const BASE=C.path.resolve(__dirname,'..');
async function logged(label,cmd,args,options={}){
 const log=C.path.join(BASE,'evidence',label+'.log');C.put(log,'');
 return new Promise((resolve,reject)=>{
  const child=C.cp.spawn(cmd,args,{cwd:C.ROOT,env:C.cleanEnv(),windowsHide:true,...options});
  let tail='',timedOut=false;const timer=setTimeout(()=>{timedOut=true;child.kill();},options.timeout||1800000);
  for(const stream of [child.stdout,child.stderr])stream.on('data',chunk=>{C.fs.appendFileSync(log,chunk);tail=(tail+chunk.toString()).slice(-12000);});
  child.on('error',e=>{clearTimeout(timer);reject(e);});
  child.on('close',code=>{clearTimeout(timer);const all=C.fs.readFileSync(log,'utf8');if(timedOut||code!==0||/SCRIPT ERROR|Parse Error|Compile Error/.test(all))reject(Error(label+' failed ('+code+'): '+tail));else resolve({label,code,log,tail});});
 });
}
module.exports={...C,BASE,logged};
