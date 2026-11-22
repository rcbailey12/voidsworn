// Issue 1556 (campaign and saves audit, Nov 21) on the browser twin (core.js, campaign_run.js):
//   node contrib/opus/tools/campaign_saves_1556_tests.js
// The checkpoint (SAVED_RUN) holds every shipyard and refit change at once, a hull refit taken off and on again never adds hull,
// and the event drawn on entry is on the node and in the checkpoint. The Godot twin with real files and cold restarts:
// godot/campaign/test/campaign_saves_1556_test.gd. Every case fails on main d16c734b except two guards (leaving clears the mark, a full ship stays full).
'use strict';
const path = require('path');
const root = path.resolve(__dirname, '../../..');
process.env.VS_ORACLE = root;
require(path.join(root, 'godot/campaign/test/node/env.js')).load(`
let testPage='', testModal='';
show=h=>{ testPage=String(h); testModal=''; };
modal=h=>{ testModal=String(h); };
closeModal=()=>{ testModal=''; };
globalThis.T1556 = {
  ACT, ADMIRALS, HULLS, buyClassTrack, newRun, newShip, cheapHull, genSector, rndSeed, findNode, availableNodes, mapScreen, saveRun, changeShip, derive,
  get run(){ return RUN; }, get saved(){ return SAVED_RUN; }, get event(){ return curEvent; },
  reset(){ META=defaultMeta(); UID=1; RUN=null; B=null; curEvent=null; },
  acts(){ const html=testModal||testPage, out=[]; let m; const re=/<(?:button|g|div|a|span)\\b([^>]*)>/g;
    while((m=re.exec(html))){ const at=m[1], a=at.match(/data-act="([^"]*)"/); if(!a) continue; const arg=at.match(/data-arg="([^"]*)"/);
      out.push([a[1],arg?arg[1]:'',/(^|\\s)disabled(\\s|$|=)/.test(at)?0:1]); } return out; }
};
`);
const T = globalThis.T1556;
const HULLS_CLS = s => T.HULLS[s.tpl].cls;
let pass = 0, fail = 0;
const check = (ok, what) => { if (ok) { pass++; console.log('ok    ' + what); } else { fail++; console.log('FAIL  ' + what); } };
const sig = R => JSON.stringify(R.fleet.map(s => [s.uid, s.tpl, s.hp, s.mk, s.mods])) + ' cr ' + R.credits + ' hold ' + JSON.stringify(R.inventory);

function mapSave(seed, want) {
  T.reset(); T.rndSeed(seed);
  const adm = Object.keys(T.ADMIRALS).find(id => T.ADMIRALS[id].fac === 'voidsworn');
  T.newRun(adm, 'voidsworn', {}); const R = T.run;
  R.sector = 2; R.map = T.genSector(2); R.pos = null; R.credits = 5000;
  for (let i = 0; i < 2; i++) R.fleet.push(T.newShip(T.cheapHull('voidsworn')));
  let target = '';
  for (const col of R.map.cols) for (const n of col) {
    if (target) break; R.pos = n.id;
    for (const id of T.availableNodes()) { const m = T.findNode(id); if (!target && m && m.type === want) target = id; }
    if (target) n.done = true;
  }
  R.curNode = null; T.mapScreen(); T.saveRun();
  return target;
}
const ok = (kind) => T.acts().filter(a => a[0] === kind && a[2] === 1);

{ const target = mapSave(1556, 'shipyard');
  T.ACT.enterNode(target);
  const h = ok('buyHull'), m = ok('buyMod');
  if (h.length) T.ACT.buyHull(h[0][1]); if (m.length) T.ACT.buyMod(m[0][1]);
  const s = T.run.fleet[0]; s.hp -= 10; T.ACT.repair(s.uid);
  check(h.length && m.length && sig(T.saved) === sig(T.run), '(1) the checkpoint holds a shipyard buy and repair at once');
  check(T.saved.inYard === target && T.findNode(target).stock && JSON.stringify(T.saved.map.cols.flat().find(n => n.id === target).stock.hulls) === JSON.stringify(T.findNode(target).stock.hulls), '(3) the checkpoint is inside the yard, with its stock');
  T.ACT.leaveYard();
  check(T.saved.inYard === undefined && T.saved.curNode === null, '(1) leaving the yard clears the in-yard mark'); }

{ mapSave(1557, 'shipyard'); T.run.inventory.push('prow');
  T.ACT.fleetScreen(); const e = ok('equip'); if (e.length) T.ACT.equip(e[0][1]);
  check(e.length && sig(T.saved) === sig(T.run), '(1) the checkpoint holds a refit fitted on the map fleet screen'); }

{ mapSave(1558, 'shipyard'); const s = T.run.fleet[0]; s.mods = []; T.run.inventory = ['prow'];
  T.ACT.fleetScreen(); T.ACT.equip('0:' + s.uid); s.hp = 10;
  T.ACT.unequip(s.uid + ':' + s.mods.indexOf('prow')); const mid = s.hp; T.ACT.equip('0:' + s.uid);
  check(s.hp <= 10 && s.mods.includes('prow'), '(2) Reinforced prow off and on again at 10 hull never adds hull (10 to ' + mid + ' to ' + s.hp + ')');
  const full = T.derive(s).maxHp; s.hp = full; T.ACT.unequip(s.uid + ':' + s.mods.indexOf('prow')); T.ACT.equip('0:' + s.uid);
  check(s.hp === full, '(2) a full ship still comes back full');
  // Artoo on PR 1602: an unrelated refit in between keeps the owed hull; a partial gain carries the rest
  s.hp = 10; T.run.inventory.push('auspex'); T.ACT.unequip(s.uid + ':' + s.mods.indexOf('prow'));
  T.ACT.fleetScreen(); T.ACT.equip(T.run.inventory.indexOf('auspex') + ':' + s.uid); T.ACT.equip(T.run.inventory.indexOf('prow') + ':' + s.uid);
  check(s.mods.includes('auspex') && s.mods.includes('prow') && s.hp <= 10, '(2) prow off, a scanner on, prow on again: still no free hull (' + s.hp + ')');
  s.mods.splice(s.mods.indexOf('prow'), 1); T.run.inventory.push('prow'); s.hp = 1; s.hpOwed = [500, 1];
  T.ACT.equip(T.run.inventory.indexOf('prow') + ':' + s.uid);
  check(s.hp === 1 && s.hpOwed && s.hpOwed[0] > 0 && s.hpOwed[0] < 500, '(2) a gain smaller than the owed hull pays part and carries the rest (' + JSON.stringify(s.hpOwed) + ')');
  // Artoo on PR 1602 (readback 045bdb7d): a class refit pays the owed hull too
  const o0 = s.hpOwed[0]; T.run.credits = 99999; T.buyClassTrack(HULLS_CLS(s));
  check(s.hp === 1 && s.hpOwed && s.hpOwed[0] < o0, '(2) a class refit pays the owed hull first (' + o0 + ' to ' + JSON.stringify(s.hpOwed) + ')'); }

{ const target = mapSave(1559, 'event'); T.ACT.enterNode(target);
  const ev = T.event && T.event.id, n = T.saved.map.cols.flat().find(x => x.id === target);
  check(ev && n && n.evId === ev && T.saved.curNode === target, '(3) the event drawn on entry is on the node and in the checkpoint (' + ev + ')'); }

console.log('\nIssue 1556 campaign save tests (browser twin): ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0;
