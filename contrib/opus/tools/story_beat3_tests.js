'use strict';
// Exact authored copy, shipped keys, and browser screen coverage for issue 55.
const fs = require('fs'), path = require('path'), vm = require('vm'), assert = require('assert');
const ROOT = path.resolve(__dirname, '../../..');
process.env.VS_ORACLE = ROOT;
require(path.join(ROOT, 'godot/campaign/test/node/env.js')).load(`
globalThis.story55={table:STORY_BEAT3,admirals:ADMIRALS,card:beat3Card,
  start(fac,id){newRun(id,fac);RUN.sector=3;},
  decision(){showBeat3();},
  choose(i){ACT.eventChoice(String(i));},
  end(won){endRun(won);},
  resume(){RUN=JSON.parse(JSON.stringify(SAVED_RUN));},
  run(){return RUN;}, debrief:beat3Debrief};
`);
let html = '';
vm.runInThisContext('modal=show=function(h){globalThis.story55html=h;};');
const files = ['sunward_crusade', 'hegemony_navy', 'ashfall_hullbreakers', 'the_chorus', 'the_glasswrights', 'eclipse'];
let count = 0;
for (const [index, fac] of Object.keys(story55.table).entries()) {
  const source = fs.readFileSync(path.join(ROOT, 'contrib/muse/design/story_beat3_2026_11', files[index] + '.md'), 'utf8').split('### Flags')[0];
  const node = vm.runInNewContext('({' + source.match(/```\s*([\s\S]*?)```/)[1] + '})');
  const row = story55.table[fac];
  assert.strictEqual(row.id, node.id); assert.strictEqual(row.fight, false);
  assert.strictEqual(JSON.stringify(row.o), JSON.stringify(node.o));
  assert.strictEqual(row.learning, source.match(/Learning payoff: "(.*)"/)[1]);
  assert.strictEqual(row.debrief, source.match(/Debrief: "(.*)"/)[1]);
  for (const line of row.lines) assert(source.includes('- ' + line));
  const admirals = Object.keys(story55.admirals).filter(id => story55.admirals[id].fac === fac);
  assert.deepStrictEqual(Object.keys(row.spotlights), admirals);
  for (const id of admirals) {
    assert(source.includes('- ' + story55.admirals[id].n + ': "' + row.spotlights[id] + '"'));
    story55.start(fac, id); story55.decision();
    html = global.story55html;
    assert(html.includes(row.spotlights[id].replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;')) || html.includes(row.spotlights[id]));
    assert(!/\{rival\}|undefined|PLACEHOLDER|TODO/.test(html)); count++;
  }
  for (let i = 0; i < 2; i++) {
    story55.start(fac, admirals[0]); story55.decision();
    const before = JSON.parse(JSON.stringify(story55.run()));
    story55.choose(i);
    if (row.o[i].r.credits) assert.strictEqual(story55.run().credits - before.credits, row.o[i].r.credits);
    if (row.o[i].r.dmgFlag) assert(story55.run().fleet.find(s => s.uid === before.flagUid).hp < before.fleet.find(s => s.uid === before.flagUid).hp);
    assert.strictEqual(story55.run().flags[row.id], String(i));
    assert.strictEqual(story55.debrief(), row.debrief);
    story55.resume();
    assert.strictEqual(story55.card(), null, 'a saved choice must not replay after reload');
    assert(!/\{rival\}|undefined|You move on\./.test(global.story55html));
  }
  for (const won of [false, true]) {
    story55.start(fac, admirals[0]); story55.end(won);
    assert(global.story55html.includes(row.learning), fac + ' learning on ' + (won ? 'win' : 'loss'));
  }
}
assert.strictEqual(story55.admirals.grax.n, 'Warlord Grax Ironmaw');
assert.strictEqual(story55.admirals.mending.n, 'Mending Throng');
console.log('PASS: six authored nodes and reward sets, 24 spotlights, decision results, saved choices, and win/loss learning screens.');
