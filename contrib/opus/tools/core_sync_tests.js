'use strict';
// Exercise actual protocol picks, save/reload, announcements and paid debriefs.
const fs = require('fs'), path = require('path');
process.env.VS_ORACLE = path.resolve(__dirname, '../../..');
require('../../../godot/campaign/test/node/env.js').load(`
globalThis.coreSyncTest = () => {
  const ok = require('assert'), fixtures = [], p = Object.keys(PATRONS)[0];
  const ordinary = Object.keys(BOONS).find(id => BOONS[id].p === p && !BOONS[id].leg);
  const duo = Object.keys(BOONS).find(id => BOONS[id].duo), pair = BOONS[duo].duo;
  const cases = [
    ...[4,12,25].map(at => ({name:'tier '+at, favour:{[p]:at-1}, picks:[{id:ordinary,r:0}]})),
    {name:'epic crosses tier', favour:{[p]:11}, picks:[{id:ordinary,r:2}], victory:true},
    {name:'resumed repeated picks', favour:{[p]:3}, picks:[{id:ordinary,r:0},{id:ordinary,r:0},{id:ordinary,r:0}], resume:true},
    {name:'duo tiers', favour:{[pair[0]]:3,[pair[1]]:11}, picks:[{id:duo,r:1}], abandoned:true},
    {name:'below next tier', favour:{[p]:5}, picks:[{id:ordinary,r:0}]},
    {name:'first ticks', favour:{}, picks:[{id:ordinary,r:0},{id:ordinary,r:0}]},
    {name:'past full sync', favour:{[p]:25}, picks:[{id:ordinary,r:2}]},
    {name:'gift only', favour:Object.fromEntries(Object.keys(PATRONS).map(id=>[id,12])), picks:[]}
  ];
  let html='', notices=[], timers=[];
  show = h => {html=h;}; toast = msg => notices.push(msg); globalThis.setTimeout = cb => {timers.push(cb);return 0;};
  for(const f of cases){
    META=migrateMeta(defaultMeta()); META.favour={...f.favour}; SAVED_RUN=null;
    const meta=JSON.parse(JSON.stringify(META)); newRun('vex','voidsworn'); notices=[];
    if(f.name==='gift only') ok.ok(RUN.giftBoon, 'a starting gift does not count as a picked protocol');
    const totals={...f.favour}, before={};
    for(let i=0;i<f.picks.length;i++){
      const o=f.picks[i], b=BOONS[o.id], ps=b.p?[b.p]:b.duo;
      for(const id of ps){if(before[id]==null) before[id]=totals[id]||0; totals[id]=(totals[id]||0)+1+o.r;}
      RUN.reward={kind:'story',rw:{k:'boon',p:ps[0]},stage:'pick'}; window._boonOffer=[o]; timers=[];
      ACT.takeBoon(0); for(const cb of timers) cb();
      ok.deepEqual(RUN.coreSync,before); ok.deepEqual(META.favour,totals);
      if(f.resume && i===0){
        const saved=JSON.parse(JSON.stringify({meta:META,run:SAVED_RUN}));
        META=migrateMeta(saved.meta); RUN=migrateRun(saved.run); SAVED_RUN=saved.run;
        ok.deepEqual(RUN.coreSync,before,'sync baseline survives reopening');
      }
    }
    const run=RUN; endRun(!!f.victory,!!f.abandoned); const cores=run.carry.inheritance.cores;
    ok.deepEqual(cores.map(row=>row.id),Object.keys(before),'only cores that ticked this run');
    for(const row of cores){
      const tier=FAVOUR_TIERS.reduce((t,x,i)=>totals[row.id]>=x.at?i:t,0), next=FAVOUR_TIERS[tier+1];
      ok.equal(row.total,totals[row.id]); ok.equal(row.before,before[row.id]); ok.equal(row.gain,totals[row.id]-before[row.id]);
      ok.equal(row.tier,tier); ok.equal(row.next,next?next.at:null); ok.equal(row.remaining,next?next.at-row.total:0);
      ok.equal(row.tierUp,before[row.id]<FAVOUR_TIERS[tier].at);
      ok.ok(html.includes(esc(PATRONS[row.id].n)) && html.includes(esc(FAVOUR_TIERS[tier].n)),'new tier on this debrief');
      ok.ok(html.includes(next?row.total+' / '+next.at+' sync':row.total+' sync. Full sync reached.'));
      const announced=notices.some(msg=>msg.includes('Core sync: '+PATRONS[row.id].n+' reached '));
      ok.equal(announced,row.tierUp,'announce tier crossings only');
    }
    if(!cores.length) ok.ok(!html.includes('<h3>Core sync</h3>'),'no empty panel');
    fixtures.push({...f,meta,cores,notices:notices.filter(msg=>msg.startsWith('Core sync: '))});
  }
  return fixtures;
};
`);
const fixtures = global.coreSyncTest();
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(fixtures));
console.log('PASS: core sync tiers at 4/12/25, rare/epic and duo gains, resumed picks, full sync, gifts and all debrief endings.');
