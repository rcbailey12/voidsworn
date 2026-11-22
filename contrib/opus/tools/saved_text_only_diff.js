// Issue 1551: compares the saved Godot baseline with a parity run folder and fails on any difference that is not a
// changed string (numbers, keys, record counts, RNG, actor, round). Usage: node contrib/opus/tools/saved_text_only_diff.js <parity run folder>
const R=require(process.cwd()+'/godot/rules/test/saved/records.js'),fs=require('fs'),path=require('path');
const run=process.argv[2]; const m=R.manifest();
let bad=0, n=0, usageDiff=0; const strSamples=new Map();
function cmp(a,b,p,name){
  if(typeof a==='string'&&typeof b==='string'){ if(a!==b){ const k=a.slice(0,60)+' -> '+b.slice(0,60); strSamples.set(k,(strSamples.get(k)||0)+1);} return; }
  if(typeof a!==typeof b||Array.isArray(a)!==Array.isArray(b)||(a===null)!==(b===null)){ if(bad++<10) console.log('TYPE',name,p,JSON.stringify(a)?.slice(0,80),JSON.stringify(b)?.slice(0,80)); return; }
  if(a&&typeof a==='object'){
    if(Array.isArray(a)){ if(a.length!==b.length){ if(bad++<10) console.log('LEN',name,p); return;} a.forEach((x,i)=>cmp(x,b[i],p+'['+i+']',name)); return; }
    const ka=Object.keys(a).sort(),kb=Object.keys(b).sort();
    if(ka.join()!==kb.join()){ if(/usage/.test(p)) usageDiff++; if(bad++<10) console.log('KEYS',name,p,ka.filter(k=>!kb.includes(k)),kb.filter(k=>!ka.includes(k))); return; }
    for(const k of ka) cmp(a[k],b[k],p+'.'+k,name); return; }
  if(a!==b){ if(bad++<10) console.log('VAL',name,p,a,b); }
}
for(const name of Object.keys(m.battles)){
  const f=path.join(run,'out',name+'.jsonl'); if(!fs.existsSync(f)){ continue; }
  const A=R.records(R.unpack(R.HOME,m.battles[name])), B=R.records(fs.readFileSync(f)); n++;
  if(A.length!==B.length){ bad++; console.log('RECS',name); continue; }
  for(let i=0;i<A.length;i++){ if(A[i].rng!==B[i].rng||A[i].round!==B[i].round||A[i].actor!==B[i].actor){bad++;console.log('META',name,i);break;}
    cmp(JSON.parse(A[i].state),JSON.parse(B[i].state),'',name); }
}
console.log('battles',n,'non-text differences',bad,'usage key diffs',usageDiff,'distinct string changes',strSamples.size);
[...strSamples.entries()].sort((a,b)=>b[1]-a[1]).slice(0,40).forEach(([k,v])=>console.log(v,k));
process.exitCode = bad ? 1 : 0;
