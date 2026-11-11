'use strict';
// Authored copy, browser screens, and live beat 3 rewards (issues 55 and 110).
const fs = require('fs'), path = require('path'), vm = require('vm'), assert = require('assert');
const ROOT = path.resolve(__dirname, '../../..');
process.env.VS_ORACLE = ROOT;
require(path.join(ROOT, 'godot/campaign/test/node/env.js')).load(`
globalThis.story55={table:STORY_BEAT3,admirals:ADMIRALS,card:beat3Card,
  start(fac,id){META.admirals[id]=true;newRun(id,fac);RUN.sector=3;},
  decision(){showBeat3();},
  choose(i){ACT.eventChoice(String(i));},
  end(won){endRun(won);},
  resume(){RUN=JSON.parse(JSON.stringify(SAVED_RUN));},
  run(){return RUN;}, debrief:beat3Debrief,
  continueCore(){ACT.storyCore();}, resumeReward,
  take(i){ACT.takeBoon(String(i));}, decline(){ACT.boonDecline();},
  offer(){return window._boonOffer;}, boons:BOONS,
  battle(extra={}){battleScreen({kind:'battle',fac:'hegemony',col:1,seed:110,obj:'rout',shape:'open',map:'belt',enemies:[{tpl:'h_picket'}],...extra});return B;},
  finish:finishBattle, damage:dmgMult, multiplier:storyDamageMult, lines:storyModifierLines,
  sync:syncOn, mark:syncMarkShot, inSync, traits:factionTraitLines,
  unmodified(u,w,t){const m=B.cfg.storyMods;delete B.cfg.storyMods;const d=dmgMult(u,w,t,false);B.cfg.storyMods=m;return d;}};
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
const choose = (fac, i) => {
  const id = Object.keys(story55.admirals).find(id => story55.admirals[id].fac === fac);
  story55.start(fac, id); story55.decision(); story55.choose(i);
};
for (const [fac, i, factor, text] of [['voidsworn', 0, 1.25, '+25%'], ['chorus', 0, .9, '-10%'], ['chorus', 1, 1.1, '+10%']]) {
  choose(fac, i);
  assert(global.story55html.includes(text));
  const pending = JSON.stringify(story55.run().storyNext);
  story55.resume(); assert.strictEqual(JSON.stringify(story55.run().storyNext), pending, 'pending modifier survives reload');
  if (fac === 'chorus' && i === 0) story55.continueCore(), story55.decline();
  const b = story55.battle(), players = b.units.filter(u => u.side === 'player');
  assert.strictEqual(story55.run().storyNext, null);
  assert(story55.lines().join(' ').includes(text));
  for (const u of b.units) {
    const wanted = u.side === 'player' && (fac !== 'voidsworn' || u.pflag) ? factor : 1;
    assert.strictEqual(story55.multiplier(u), wanted, 'only intended ships are modified');
    if (u.weapons.length) {
      const t = b.units.find(t => t.side !== u.side);
      assert.strictEqual(story55.damage(u, u.weapons[0], t, false), story55.unmodified(u, u.weapons[0], t) * wanted);
    }
  }
  assert(story55.traits(players.find(u => u.pflag)).join(' ').includes(text));
  const lateWing = {side: 'player', isSq: true};
  assert.strictEqual(story55.multiplier(lateWing), fac === 'voidsworn' ? 1 : factor, 'later wings share fleet damage only');
  story55.resume(); assert.strictEqual(story55.run().storyNext, null, 'battle entry saves consumption');
  assert.strictEqual(story55.multiplier(story55.battle().units[0]), 1, 'next battle is normal');
}
choose('hegemony', 0);
assert(global.story55html.includes('round 1') && global.story55html.includes('round 2'));
const syncBattle = story55.battle();
const syncShips = syncBattle.units.filter(u => u.side === 'player' && !u.isSq), target = syncBattle.units.find(u => u.side === 'enemy');
syncShips[1].q = syncShips[0].q; syncShips[1].r = syncShips[0].r;
story55.mark(syncShips[0], target);
assert(!story55.inSync(syncShips[0]) && !story55.sync(syncShips[1], target));
assert.deepStrictEqual(syncBattle.syncMark.player, {}, 'disabled shots leave no sync mark');
assert(story55.traits(syncShips[0]).some(s => s.includes('off in round 1')));
assert(story55.inSync(target), 'enemy synchronization stays enabled');
syncBattle.round = 2; story55.mark(syncShips[0], target);
assert(story55.inSync(syncShips[0]) && story55.sync(syncShips[1], target), 'round 2 sync works normally');
for (const [fac, patron] of [['corsair', 'rook'], ['chorus', 'hunger']]) {
  for (const take of [true, false]) {
    choose(fac, 0);
    const r = story55.run(), credits = r.credits, boons = r.boons.length, pos = r.pos;
    assert.strictEqual(r.reward.rw.p, patron);
    assert(global.story55html.includes('1 free protocol offer') && global.story55html.includes('60 credits'));
    story55.resume(); story55.continueCore();
    assert.strictEqual(story55.run().credits, credits, 'offer is free');
    assert.strictEqual(story55.run().boonRerolls || 0, 0, 'offer does not spend a reroll');
    const offer = JSON.stringify(story55.offer());
    assert(global.story55html.includes(patron === 'rook' ? 'R-5 Rook' : 'H-3 Crucible'), 'offering core is shown');
    story55.resume(); story55.resumeReward();
    assert.strictEqual(JSON.stringify(story55.offer()), offer, 'reload keeps the same offer');
    if (take) story55.take(0); else story55.decline();
    assert.strictEqual(story55.run().boons.length, boons + (take ? 1 : 0));
    assert.strictEqual(story55.run().credits, credits + (take ? 0 : 60));
    assert.strictEqual(story55.run().reward, null);
    assert.strictEqual(story55.run().pos, pos, 'story offer does not complete a map node');
    story55.resume(); assert.strictEqual(story55.run().reward, null, 'resolved offer stays resolved');
  }
  choose(fac, 0);
  story55.run().boons = Object.keys(story55.boons).map(id => ({id, r: 0}));
  const credits = story55.run().credits;
  story55.continueCore();
  assert.strictEqual(story55.run().credits, credits + 60, 'exhausted pool pays once');
  assert.strictEqual(story55.run().reward, null);
  assert.strictEqual(story55.resumeReward(), false);
}
for (const extra of [{kind:'battle'}, {kind:'elite'}, {kind:'boss'}, {kind:'elite',eventRelic:true}, {kind:'battle',nemesis:{fac:'hegemony',name:'Test',title:'Admiral',traits:[],weak:[],revealed:[],adapt:[]}}]) {
  choose('voidsworn', 0);
  assert(story55.battle(extra).cfg.storyMods.power, 'any battle kind consumes the reward');
  assert.strictEqual(story55.run().storyNext, null);
}
for (const result of ['win', 'loss', 'retreat']) {
  choose('voidsworn', 0); story55.battle(); const run = story55.run(); story55.finish(result);
  assert.strictEqual(run.storyNext, null, result + ' does not restore the modifier');
}
console.log('PASS: authored beat 3 screens, all five reward keys, exact damage, round 1 sync, free core offers, reloads, all battle kinds and win/loss/retreat expiry.');
