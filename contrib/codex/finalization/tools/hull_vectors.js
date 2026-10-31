'use strict';
const vm=require('vm'),{fs,path,ROOT,put}=require('./common');
const [repo,out]=process.argv.slice(2);
const G=require(path.join(ROOT,'contrib/muse/tools/harness/game_loader')).loadGame(repo),box=G._sandbox;
vm.runInContext('RUN=null',box);
const canon=v=>{
 if(v==null)return 'null';if(typeof v==='boolean')return String(v);
 if(typeof v==='number'){if(Number.isInteger(v))return String(v);const b=Buffer.alloc(8);b.writeDoubleBE(v);return '"d:'+b.toString('hex')+'"';}
 if(typeof v==='string')return JSON.stringify(v);if(Array.isArray(v))return '['+v.map(canon).join(',')+']';
 return '{'+Object.keys(v).filter(k=>v[k]!=null).sort().map(k=>JSON.stringify(k)+':'+canon(v[k])).join(',')+'}';
};
const rows=[];
for(const id of Object.keys(G.HULLS).sort()){
 const h=JSON.parse(JSON.stringify(G.HULLS[id]));delete h.n;rows.push({id:id+':hull',state:canon(h)});
 for(const mod of Object.keys(G.MODULES).sort()){box.__s={tpl:id,mods:[]};box.__m=mod;rows.push({id:id+':fit:'+mod,allowed:vm.runInContext('canFitModule(__s,__m)',box)});}
 for(const mk of [1,3]){const d=G.derive({uid:'fixture',tpl:id,name:'fixture',mk,hp:1,mods:[],cap:{perks:[]}});for(const w of d.weapons)delete w.n;rows.push({id:id+':derive:'+mk,state:canon(d)});}
}
put(out,rows.map(r=>JSON.stringify(r)).join('\n')+'\n');console.log(rows.length+' browser hull/fitting/derived records');
