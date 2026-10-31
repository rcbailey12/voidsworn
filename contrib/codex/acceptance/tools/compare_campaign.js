'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,sha}=C;
const PARTS=['run','map','meta','t','saved'];
function read(file,seed){
 const txt=fs.readFileSync(file,'utf8');assert(txt.endsWith('\n'),'truncated campaign');const rows=txt.trimEnd().split('\n').map(JSON.parse);
 assert(rows.length>=3);assert.equal(rows[0].act,'start');assert.equal(rows[0].rng,seed);assert.equal(rows.at(-1).act,'end','campaign did not terminate');
 const carry={};
 return rows.map((r,i)=>{
  assert.equal(r.i,i,'missing/duplicate campaign step');
  if(r.act==='end'){assert.equal(i,rows.length-1);return {...r,completeState:{...carry}};}
  assert(typeof r.acts==='string'&&Number.isInteger(r.rng)&&r.rng>=0&&r.rng<=0xffffffff);assert(r.h);
  for(const p of PARTS){if(r[p]!==undefined){assert.equal(typeof r[p],'string');JSON.parse(r[p]);carry[p]=r[p];}assert.equal(sha(carry[p]||'' ).slice(0,16),r.h[p],'payload hash mismatch '+p);}
  return {...r,completeState:{...carry}};
 });
}
function compare(a,b,seed){
 const A=read(a,seed),B=read(b,seed);let first=null;
 for(let i=0;i<Math.max(A.length,B.length);i++){
  const x=A[i],y=B[i];if(!x||!y){first={step:i,reason:'missing record'};break;}
  for(const k of ['i','act','arg','acts','rng'])if(x[k]!==y[k]){first={step:i,field:k,browser:x[k],godot:y[k]};break;}
  if(first)break;
  for(const p of PARTS)if(x.completeState[p]!==y.completeState[p]){first={step:i,field:p,...(C.diff(JSON.parse(x.completeState[p]),JSON.parse(y.completeState[p]))[0]||{})};break;}
  if(first)break;
 }
 return {seed,pass:first===null,recordsJS:A.length,recordsGodot:B.length,first,reloads:A.filter(x=>x.act==='reload').length};
}
if(require.main===module){try{const r=compare(process.argv[2],process.argv[3],+process.argv[4]);console.log(JSON.stringify(r,null,2));process.exitCode=r.pass?0:1;}catch(e){console.error(e.stack);process.exitCode=2;}}
module.exports={read,compare};
