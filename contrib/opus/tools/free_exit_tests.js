// Progression step 8, R62: exercise the shipped exits, including at zero credits.
// node contrib/opus/tools/free_exit_tests.js [fixtures.json]
'use strict';
const assert = require('assert/strict');
const fs = require('fs'), path = require('path');
const root = path.resolve(__dirname, '../../..');
process.env.VS_ORACLE = root;
require(path.join(root, 'godot/campaign/test/node/env.js')).load(`
let testPage='', testModal='';
show=h=>{ testPage=String(h); testModal=''; };
modal=h=>{ testModal=String(h); };
closeModal=()=>{ testModal=''; };
globalThis.ExitTest = {
  EVENTS, RUN_FACTIONS, ADMIRALS, ACT, newRun, rndSeed, findNode, availableNodes,
  get run(){ return RUN; }, get meta(){ return META; }, get saved(){ return SAVED_RUN; },
  get event(){ return curEvent; }, get uid(){ return UID; }, get rng(){ return RNG_S>>>0; },
  get page(){ return testPage; }, get modal(){ return testModal; },
  reset(){ META=defaultMeta(); UID=1; RUN=null; B=null; curEvent=null; },
  acts(){ const html=testModal||testPage, out=[]; let m;
    const re=/<(?:button|g|div|a|span)\\b([^>]*)>/g;
    while((m=re.exec(html))){ const at=m[1], a=at.match(/data-act="([^"]*)"/);
      if(!a) continue; const arg=at.match(/data-arg="([^"]*)"/);
      out.push([a[1],arg?arg[1]:'',/(^|\\s)disabled(\\s|$|=)/.test(at)?0:1]); }
    return out; }
};
`);
const T = globalThis.ExitTest;
const copy = v => JSON.parse(JSON.stringify(v));
const fixtures = [];
const events = T.EVENTS.filter(e => e.id === 'haven' || e.o.some(o => o.r && o.r.fight) ||
  Object.values(e.v || {}).some(v => (v.o || []).some(o => o.r && o.r.fight)));
assert.ok(events.some(e => e.id === 'haven'), 'haven covered');
assert.ok(events.some(e => e.id !== 'haven'), 'other fight events covered');
function snapshot() {
  const meta = copy(T.meta);
  delete meta.tel; // Browser-only telemetry, excluded by campaign parity too.
  return copy({run:T.run, saved:T.saved, meta, rng:T.rng, uid:T.uid, acts:T.acts()});
}
for (const ev of events) for (const fac of T.RUN_FACTIONS) {
  if ((ev.not || []).includes(fac)) continue;
  for (const credits of [0, 120]) {
    const name = ev.id + '/' + fac + '/' + credits;
    T.reset(); T.rndSeed(4242);
    const adm = Object.keys(T.ADMIRALS).find(k => T.ADMIRALS[k].fac === fac);
    assert.ok(adm, name + ': faction admiral');
    T.newRun(adm, fac);
    const node = T.findNode(T.availableNodes()[0]);
    node.type = 'event';
    // Use the real event picker with only this event unseen, rather than replacing its logic.
    T.run.seenEvents = T.EVENTS.filter(e => e.id !== ev.id).map(e => e.id);
    T.run.credits = credits;
    const initial = snapshot(), hp = T.run.fleet.map(s => s.hp);
    T.ACT.enterNode(node.id);
    assert.equal(T.event.id, ev.id, name + ': entered the requested event');
    // A free exit may award charts or captain XP, but cannot require kit, payment or harm.
    const exit = T.event.o.findIndex(o => !o.need && /leave|wide berth/i.test(o.l) &&
      Object.entries(o.r || {}).every(([k,v]) => ['cred','xp'].includes(k) && v >= 0));
    assert.ok(exit >= 0, name + ': an unconditional, harmless exit is offered');
    assert.ok(T.acts().some(a => a[0] === 'eventChoice' && a[1] === String(exit) && a[2] === 1),
      name + ': exit button enabled');
    const entered = snapshot();
    T.ACT.eventChoice(String(exit));
    const result = snapshot();
    assert.equal(T.run.curNode, null, name + ': event completed');
    assert.ok(node.done, name + ': node marked done');
    assert.ok(T.run.credits >= credits, name + ': no credits charged');
    assert.deepEqual(T.run.fleet.map(s => s.hp), hp, name + ': no hull damage');
    assert.equal(T.run.stats.battles, 0, name + ': no battle');
    assert.deepEqual(T.run.inventory, initial.run.inventory, name + ': no refits spent');
    assert.deepEqual(T.run.relics, initial.run.relics, name + ': no salvage spent');
    const clockOf = r => r.nems[r.nemAssign[r.sector - 1]].clock;
    assert.equal(clockOf(result.run), clockOf(entered.run), name + ': no hunt penalty');
    assert.ok(T.acts().some(a => a[0] === 'closeModal' && a[2] === 1), name + ': Continue offered');
    T.ACT.closeModal();
    assert.equal(T.modal, '', name + ': result dismissed');
    const next = T.availableNodes();
    assert.ok(next.length > 0, name + ': onward route');
    assert.ok(T.acts().some(a => a[0] === 'enterNode' && next.includes(a[1]) && a[2] === 1),
      name + ': back on the playable sector map');
    assert.deepEqual(T.saved, T.run, name + ': exit saved');
    fixtures.push({name, event:ev.id, node:node.id, exit, initial, entered, result, map:snapshot()});
  }
}
// Preserve exact doubles when Godot reads the browser state fixtures.
function encode(v) {
  if (typeof v === 'number' && !Number.isInteger(v)) {
    const b = Buffer.alloc(8); b.writeDoubleBE(v); return '#d:' + b.toString('hex');
  }
  if (Array.isArray(v)) return v.map(encode);
  if (v && typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k,x]) => [k,encode(x)]));
  return v;
}
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(encode(fixtures)));
console.log('PASS: ' + fixtures.length + ' free exits across ' + events.map(e => e.id).join(', ') +
  ', every eligible faction, zero and 120 credits, return to map and save.');
