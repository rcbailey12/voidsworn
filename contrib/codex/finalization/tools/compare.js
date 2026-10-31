'use strict';
// Unlike the historical comparator, verify completeness and the payload hashes too.
const assert=require('assert/strict'),{fs,sha}=require('./common');
function diff(a,b,p='',out=[]){
 if(a===b)return out;
 if(a&&b&&typeof a==='object'&&typeof b==='object'&&Array.isArray(a)===Array.isArray(b)){
  for(const k of [...new Set([...Object.keys(a),...Object.keys(b)])].sort())diff(a[k],b[k],Array.isArray(a)?p+'['+k+']':p+'.'+k,out);
 }else out.push({path:p,before:a===undefined?null:a,after:b===undefined?null:b});
 return out;
}
function read(file){
 const text=fs.readFileSync(file,'utf8');assert(text.endsWith('\n'),'truncated output: '+file);
 const rows=text.slice(0,-1).split('\n').map(JSON.parse);assert(rows.length>=3,'empty/short battle: '+file);
 assert(rows.some(r=>r.actor==='start'),'missing start: '+file);assert.match(rows.at(-1).actor,/^end (win|loss|none)$/,'missing terminal: '+file);
 for(let i=0;i<rows.length;i++){
  const r=rows[i];assert.equal(r.turn,i,'missing/duplicate record: '+file);assert(Number.isInteger(r.round)&&r.round>=1);assert(Number.isInteger(r.rng)&&r.rng>=0&&r.rng<=0xffffffff);
  assert.equal(typeof r.state,'string');assert.equal(r.hash,sha(r.state),'invalid payload hash: '+file);const s=JSON.parse(r.state);
  assert(s.b&&s.g&&Array.isArray(s.units));assert.equal(s.b.round,r.round,'round metadata contradicts state');
 }
 return rows;
}
function compare(a,b){
 const A=read(a),B=read(b);let first=null,differences=0;const paths=new Map();
 for(let i=0;i<Math.max(A.length,B.length);i++){
  const x=A[i],y=B[i];if(JSON.stringify(x)===JSON.stringify(y))continue;
  if(x&&y&&x.turn===y.turn&&x.round===y.round&&x.actor===y.actor&&x.rng===y.rng&&x.hash===y.hash&&x.state===y.state)continue;
  differences++;
  const ds=x&&y?diff(JSON.parse(x.state),JSON.parse(y.state),'state'):[];
  for(const d of ds){const k=d.path.replace(/\[\d+\]/g,'[]');paths.set(k,(paths.get(k)||0)+1);}
  if(!first)first={record:i,node:x?{turn:x.turn,round:x.round,actor:x.actor,rng:x.rng}:null,godot:y?{turn:y.turn,round:y.round,actor:y.actor,rng:y.rng}:null,field:ds[0]||null};
 }
 return {pass:differences===0,recordsJS:A.length,recordsGodot:B.length,differingRecords:differences,first,differingFields:[...paths].map(([path,records])=>({path,records})),terminalJS:A.at(-1).actor,terminalGodot:B.at(-1).actor};
}
if(require.main===module){try{const r=compare(...process.argv.slice(2));console.log(JSON.stringify(r,null,2));process.exitCode=r.pass?0:1;}catch(e){console.error(e.message);process.exitCode=2;}}
module.exports={read,compare};
