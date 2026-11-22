// Issue 1175, browser twin of godot/campaign/test/nem_dodge_test.gd: the same 3,000 seeded sectors through the root JS game
// files (env.js). Prints the same lines as the Godot check, plus a digest of every boss stop's rolled objective and board,
// which the Godot check prints too, so the two twins can be compared line by line.
//   node godot/campaign/test/node/nem_dodge.js [--report]
'use strict';
const env = require('./env.js');
env.load(String.raw`
var __N={met:0,dead:false}; nemActive=function(){ return __N; };
function __reach(m){ const byId={}; for(const c of m.cols) for(const n of c) byId[n.id]=n;
  const fr=m.cols[0].filter(n=>!nemNodeIs(n)).map(n=>n.id), seen={};
  while(fr.length){ const id=fr.pop(); if(seen[id]) continue; seen[id]=1; if(byId[id].type==='boss') return true;
    for(const e of m.edges) if(e[0]===id&&!nemNodeIs(byId[e[1]])) fr.push(e[1]); }
  return false; }
globalThis.__dodge=function(per){ let dodge=0,total=0,bossBad=0,tagBad=0,h=0;
  for(const s of [1,2,3]) for(let i=0;i<per;i++){
    rndSeed(1175000+s*10000+i); RUN=null; const m=genSector(s); RUN={sector:s,map:m,nemStrike:false}; total++;
    if(__reach(m)) dodge++;
    const boss=m.cols[m.cols.length-1][0]; if(!(boss.enc&&boss.shape&&BOSS_ENC.includes(boss.enc))) bossBad++;
    for(const ch of String(boss.enc)+'/'+String(boss.shape)+';') h=(h*31+ch.charCodeAt(0))%2147483647;
    for(const n of m.cols[m.cols.length-3]) if(!nemNodeIs(n)||nemNodeTag(n)!=='Nemesis meeting') tagBad++;
  }
  RUN=null; return {dodge,total,bossBad,tagBad,h}; };
`);
const r = globalThis.__dodge(1000);
console.log(`nem_dodge: ${r.dodge} of ${r.total} sectors let an unmet Nemesis be dodged (${(100 * r.dodge / r.total).toFixed(1)}%)`);
console.log(`nem_dodge: ${r.bossBad} boss stops without an objective and board shape on the map; ${r.tagBad} column 4 stops not marked and tagged as the meeting`);
console.log(`nem_dodge: boss roll digest ${r.h}`);
if (process.argv.includes('--report')) process.exit(0);
const ok = r.dodge === 0 && r.bossBad === 0 && r.tagBad === 0;
console.log(ok ? 'PASS' : 'FAIL'); process.exit(ok ? 0 : 1);
