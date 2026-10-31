'use strict';
// Exact counterpart of fix_vectors.gd. Runs the project's pinned campaign oracle.
// node fix_vectors.js <isolated-godot-project> <output.jsonl> [map-seeds=1500]
const fs=require('fs'),path=require('path');
const project=path.resolve(process.argv[2]);
const dest=path.resolve(process.argv[3]);
const seeds=Number(process.argv[4]||1500);
if(!Number.isInteger(seeds)||seeds<1)throw Error('map-seeds must be positive');
const {load}=require(path.join(project,'campaign/test/node/env.js'));
load(`
const vectorFs=require('fs'), vectorCrypto=require('crypto');
function vectorCanon(v){
  if(v===null||v===undefined)return 'null';
  if(typeof v==='boolean')return v?'true':'false';
  if(typeof v==='number'){
    if(Number.isInteger(v)&&Math.abs(v)<9007199254740992)return String(v===0?0:v);
    const b=Buffer.alloc(8);b.writeDoubleBE(v);return '"d:'+b.toString('hex')+'"';
  }
  if(typeof v==='string')return JSON.stringify(v);
  if(typeof v==='function')return 'null';
  if(Array.isArray(v))return '['+Array.from(v,x=>vectorCanon(x)).join(',')+']';
  return '{'+Object.keys(v).filter(k=>v[k]!==null&&v[k]!==undefined&&typeof v[k]!=='function').sort().map(k=>JSON.stringify(k)+':'+vectorCanon(v[k])).join(',')+'}';
}
const vectorHash=x=>vectorCrypto.createHash('sha256').update(vectorCanon(x)).digest('hex');
const vectorLines=[];
for(let seed=1;seed<=${seeds};seed++)for(let sector=1;sector<=3;sector++){
  META=defaultMeta();RUN=runDefaults();RUN.sector=sector;RUN.foes=null;
  RUN.condsUsed=[];RUN.regionsUsed=[];rndSeed(seed*31+sector);
  const map=genSector(sector);
  vectorLines.push(JSON.stringify({kind:'map',seed,sector,hash:vectorHash(map),rng:RNG_S>>>0,elite:map.cols[4].some(n=>n.type==='elite')}));
}
const vectorCases=[
  ['three identical names',3,{upgradeOne:1,repairOne:1},false],
  ['two ships',2,{upgradeOne:1,repairOne:1},false],
  ['single ship',1,{upgradeOne:1,repairOne:1},false],
  ['repair only',2,{repairOne:1},false],
  ['upgrade only',2,{upgradeOne:1},false],
  ['max Mark',3,{upgradeOne:1,repairOne:1},true]
];
for(let i=0;i<vectorCases.length;i++){
  const [label,count,outcome,maxMark]=vectorCases[i];
  META=defaultMeta();RUN=runDefaults();B=null;UID=1;rndSeed(90210+i);
  const fleet=[];
  for(let j=0;j<count;j++){
    const sh=newShip('warden');sh.name='Same display name';
    if(maxMark&&j===0)sh.mk=3;
    sh.hp=Math.round(derive(sh).maxHp*[.2,.5,.8][j]);fleet.push(sh);
  }
  RUN.fleet=fleet;RUN.flagUid=fleet[0].uid;
  const before=fleet.map(sh=>sh.hp);applyOutcome(outcome);
  const full=j=>fleet[j].hp===derive(fleet[j]).maxHp;
  let holds=full(0);
  if(count>1)holds=holds&&(outcome.upgradeOne&&outcome.repairOne?full(1):fleet[1].hp===before[1]);
  if(count>2)holds=holds&&fleet[2].hp===before[2];
  const state=fleet.map(sh=>({uid:sh.uid,hp:sh.hp,mk:sh.mk,maxHp:derive(sh).maxHp}));
  vectorLines.push(JSON.stringify({kind:'shipwright',label,hash:vectorHash(state),state,contractHolds:holds,rng:RNG_S>>>0}));
}
vectorFs.writeFileSync(${JSON.stringify(dest)},vectorLines.join('\\n')+'\\n');
console.log(vectorLines.length+' vectors written');
`);
