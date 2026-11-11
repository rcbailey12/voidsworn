'use strict';
// Issue 529: behaviour checks for the last seven tree rows and the "you may" prompts. Each check proves the number moves,
// not only that a flag was set. The picks, the run and the battle come from the game's own functions (lineagePick, newRun,
// startBattle) through the campaign bundle; the checks then call the real rules functions and compare a battle with the pick
// (or one answer) against the same battle without it (or the other answer), with the dice reseeded so both sides roll the same.
// The few setup lines that are not game moves are marked "setup": ships placed in range of an enemy, a hull dented before a
// regrowth, flak switched off so the full and half strikes roll the same dice.
// Also checked: the parity fixtures carry the lineage the real functions build (tree_last_rows_fixtures.js), and every
// fixture's row fires (or, for a "no" answer, stays quiet) in the golden run.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const FIXT = require('./tree_last_rows_fixtures.js');

let bad = 0;
const ok = (name, cond, msg) => { if (cond) console.log('PASS ' + name + ': ' + msg); else { console.log('FAIL ' + name + ': ' + msg); bad++; } };

// 1. fixtures: lineage from the real functions, and each row fires (or stays quiet) in the golden run
{ const f = FIXT.check(); for (const x of f) ok('fixture', false, x); if (!f.length) ok('fixtures', true, Object.keys(FIXT.FIX).length + ' fixtures carry the lineage lineagePick and newRun build'); }
{
  const scen = JSON.parse(fs.readFileSync(path.join(ROOT, 'godot/rules/test/scenarios.json'), 'utf8'));
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 't529-'));
  for (const [name, f] of Object.entries(FIXT.FIX)) {
    const out = path.join(tmp, name + '.jsonl');
    const r = spawnSync(process.execPath, [path.join(ROOT, 'godot/rules/test/node/golden.js'), 'scenario', name, out], { cwd: ROOT, encoding: 'utf8' });
    if (r.status !== 0 || !scen[name]) { ok(name, false, 'the golden run failed'); continue; }
    const lines = fs.readFileSync(out, 'utf8').trim().split('\n');
    const st = JSON.parse(JSON.parse(lines[lines.length - 1]).state).b.treeStats || {};
    const fired = (st[f.key] || 0) >= 1;
    ok(name, f.fire === false ? !fired : fired, f.key + (f.fire === false ? ' stays quiet after a "no" answer' : ' fires ' + (st[f.key] || 0) + ' times'));
  }
}

// 2. the rules, called directly on battles built by the real campaign functions
FIXT.lineages(); // loads the campaign bundle (the root game files) once; the code below joins it
require('vm').runInThisContext(String.raw`
function animWeapon(){} function animTorpLaunch(){} function animPath(){} function animMove(u,q,r,f){ u.q=q; u.r=r; u.facing=f; }
function animRotate(){} function animExplode(){} function animNova(){} function animBlink(){} function fxRam(){} function fxBoard(){}
function onCapture(){} function fxShieldBreak(){} function fxWithdraw(){} function toast(){}
globalThis.__t529 = {
  battle(id, fac, picks, enemies, fleet, cfgExtra) {
    RUN = null; SAVED_RUN = null; META = migrateMeta(defaultMeta()); META.admirals[id] = true; META.mastery[id] = 230;
    for (const k of picks) if (lineagePick(k) !== true) throw new Error('lineagePick(' + k + ') refused');
    newRun(id, fac);
    if (fleet) { RUN.fleet = fleet.map(t => newShip(t, false)); RUN.flagUid = RUN.fleet[0].uid; }
    startBattle(Object.assign({kind: 'battle', fac: 'hegemony', col: 1, seed: 7, obj: 'rout', shape: 'open', map: 'open', enemies: enemies.map(tpl => ({tpl}))}, cfgExtra || {}));
    B.alt = true; B.side = 'player'; for (const x of B.units) x.activated = false;
    return B;
  },
  P: () => B.units.filter(x => x.side === 'player' && !x.isSq && !x.dead),
  E: () => B.units.filter(x => x.side === 'enemy' && !x.isSq && !x.dead),
  gun: u => u.weapons.findIndex(w => w.k !== 'flak'),
  near(u, t, d) { const occ = occMap(); let best = null, bd = 1e9; for (const h of boardHexes()) { if (blocks(terr(h.q, h.r)) || occ.has(hkey(h.q, h.r))) continue; const dd = hdist(h, t); if (dd < 1 || dd > d) continue; const du = hdist(h, u); if (du < bd) { bd = du; best = h; } } if (best) { u.q = best.q; u.r = best.r; } return !!best; },
  get B() { return B; }, get FX() { return TREE_FX; }, get MAY() { return TREE_MAY; }
};`, { filename: 't529_bundle.js' });
const T = global.__t529;
console.debug = () => {};
const g = (n) => global[n];

(async () => {
  // Roles: strike is +10 aim, screen +10 evasion (inside the 45 cap), each through the real change-role action
  {
    T.battle('matriarch', 'chorus', ['matriarch:B:0:0'], ['h_interdictor'], ['b_brood', 'b_drone']);
    const [u, u2] = T.P(), e = T.E()[0]; T.near(u, e, 2); // setup: place the ship two hexes from the enemy so the odds are off the 5% floor
    const w = u.weapons[T.gun(u)], we = e.weapons[T.gun(e)];
    const role0 = u.treeRole, hcStrike = g('hitChance')(u, w, e), hitOnU = g('hitChance')(e, we, u);
    const changed = g('treeSetRole')(u, 'screen', true), again = g('treeSetRole')(u, 'mend', true);
    const hcScreen = g('hitChance')(u, w, e), hitOnScreen = g('hitChance')(e, we, u);
    ok('Roles (strike)', role0 === 'strike' && hcStrike - hcScreen === 10, 'the default role is strike and its aim is 10 points more (' + hcStrike + ' against ' + hcScreen + ' once the ship becomes a screen)');
    ok('Roles (screen)', hitOnU - hitOnScreen === 10, 'an enemy shot at a screen ship has 10 points less to hit (' + hitOnU + ' to ' + hitOnScreen + ')');
    ok('Roles (change once)', changed === true && again === false && u.treeRole === 'screen', 'the change-role action works once per battle and is refused the second time');
    // the battle-start prompt asks each ship once; the change prompt offers the two other roles and keep
    const B0 = T.B; B0.treeRoleAsked = null; B0.treeAsk = null;
    const a1 = g('treeRoleAsk')(), ask1 = JSON.parse(JSON.stringify(B0.treeAsk)); g('treeAnswer')('mend');
    const a2 = g('treeRoleAsk')(), ask2 = B0.treeAsk ? B0.treeAsk.id : null; g('treeAnswer')('screen'); const a3 = g('treeRoleAsk')();
    ok('Role prompt', a1 && ask1.kind === 'role' && ask1.opts.length === 3 && ask1.id === u.id && a2 && ask2 === u2.id && !a3 && u.treeRole === 'mend' && u2.treeRole === 'screen',
      'the battle-start prompt asks each ship once with three choices and the answers set the roles');
    const can = g('treeCanChangeRole')(u2), opened = g('treeRoleChangeAsk')(u2), opts = B0.treeAsk ? B0.treeAsk.opts.map(o => o.id).join(',') : '';
    g('treeAnswer')('keep');
    ok('Role change prompt', can && opened && opts === 'strike,mend,keep' && u2.treeRole === 'screen' && !u2.treeRoleChanged, 'the change prompt offers the two other roles or keep; keep changes nothing');
  }
  // Roles: mend makes regrowth 10% stronger: the Mending Throng's per-round hull regrowth and the Regrowth tide Command
  {
    const run = async role => { T.battle('mending', 'chorus', ['mending:B:0:0'], ['h_dominion'], ['b_brood', 'b_drone']);
      const u = T.P()[0]; g('treeRoleAsk')(); g('treeAnswer')(role); // the battle-start prompt, answered for the first ship
      u.hp = Math.round(u.maxHp / 3); // setup: the ship has lost two thirds of its hull
      let h0 = u.hp; g('startSideTurn')('player'); const tick = u.hp - h0;
      h0 = u.hp; await g('useCommand')('player'); return { tick, tide: u.hp - h0, regen: u.hullRegen }; };
    const s = await run('strike'), m = await run('mend');
    ok('Roles (mend)', s.tick === s.regen && m.tick === Math.round(s.regen * 1.1) && m.tide > s.tide,
      'the round regrowth goes from ' + s.tick + ' to ' + m.tick + ' hull and the Regrowth tide from ' + s.tide + ' to ' + m.tide + ' on a mend ship');
  }
  // Scent in the Dark: after a kill in the frenzy, the next shot at a new target has +10 aim, and only that one
  {
    T.battle('razormaw', 'chorus', ['razormaw:A:0:0', 'razormaw:A:1:1'], ['h_picket', 'h_picket'], ['b_razor', 'b_razor']);
    const u = T.P()[0], [e1, e2] = T.E(); const w = u.weapons[T.gun(u)];
    await g('useCommand')('player');
    const before = g('hitChance')(u, w, e2);
    await g('killUnit')(e1, u);
    const after = g('hitChance')(u, w, e2);
    ok('Scent in the Dark', g('cmdActive')('player', 'surge') && after - before === 10 && u.treeScent && u.treeScent.from === e1.id, 'the next shot at a new target goes from ' + before + ' to ' + after + ' to hit after a kill in the frenzy');
    T.battle('razormaw', 'chorus', ['razormaw:A:0:0'], ['h_picket', 'h_picket'], ['b_razor', 'b_razor']);
    const v = T.P()[0], [f1, f2] = T.E(); await g('useCommand')('player'); const b2 = g('hitChance')(v, v.weapons[T.gun(v)], f2); await g('killUnit')(f1, v);
    ok('Scent in the Dark (control)', g('hitChance')(v, v.weapons[T.gun(v)], f2) === b2, 'without the pick a kill changes nothing');
  }
  // Spawned Before the Strike: a brood that moved this round gives its extra swarms +15% damage
  {
    const run = async (picks) => {
      T.battle('matriarch', 'chorus', picks, ['h_interdictor'], ['b_brood', 'b_drone']);
      const br = T.P()[0]; const st = g('computeReach')(br).states.filter(s => s.path && s.path.some(p => !p.rot)).sort((a, b) => a.path.length - b.path.length || (a.q - b.q) || (a.r - b.r))[0];
      await g('moveUnit')(br, st); await g('useCommand')('player');
      const sq = T.B.units.find(x => x.isSq && x.extra && x.parent === br.id); const e = T.E()[0];
      return sq ? { d: g('dmgMult')(sq, sq.weapons[0], e, false), w: sq.weapons[0].dmg, bonus: sq.treeBonus || 0, moved: br.hexMoved } : null;
    };
    const base = await run(['matriarch:A:0:0']), sp = await run(['matriarch:A:0:0', 'matriarch:A:1:1']);
    ok('Spawned Before the Strike', base && sp && sp.moved > 0 && sp.bonus === 0.15 && base.bonus === 0 && sp.d / base.d > 1.1 && sp.d / base.d <= 1.15 + 1e-9, 'an extra swarm of a brood that moved deals ' + (sp && sp.d.toFixed(2)) + ' per hit against ' + (base && base.d.toFixed(2)) + ' without the pick (+0.15 added to the swarm\'s other damage bonuses)');
  }
  // The Brood Does Not Stop: the swarm that destroyed its target strikes another enemy, at half the damage of a normal strike
  {
    const run = async (half) => {
      T.battle('matriarch', 'chorus', ['matriarch:A:0:0', 'matriarch:B:0:0', 'matriarch:C:0:0', 'matriarch:cap:1'], ['h_picket', 'h_picket'], ['b_brood', 'b_drone']);
      await g('useCommand')('player');
      const s = T.B.units.find(x => x.isSq && x.extra && !x.dead), [e1, e2] = T.E();
      T.near(s, e2, 1); // setup: place the swarm next to the second enemy
      for (const x of T.B.units) if (x.side === 'enemy') x.intercepts = 0; // setup: no flak, so both runs roll only the strike
      const lostOf = t => (t.maxHp - t.hp) + t.sh.reduce((a, v) => a + (t.shMax - v), 0); // hull lost plus shield lost
      const lost0 = lostOf(e2);
      g('rndSeed')(4242);
      if (half) { await g('killUnit')(e1, s); await g('treeNoStop')(s); }
      else { for (let i = 0; i < s.weapons.length; i++) await g('treeExtraShot')(s, i, e2, {}); }
      return { n: (T.B.treeStats || {})['matriarch:cap:1'] || 0, lost: lostOf(e2), lost0 };
    };
    const full = await run(false), half = await run(true);
    const dFull = full.lost - full.lost0, dHalf = half.lost - half.lost0;
    ok('The Brood Does Not Stop', half.n >= 1 && dFull > 0 && Math.abs(dHalf - dFull / 2) <= 2, 'after the kill the swarm strikes another enemy for ' + dHalf.toFixed(1) + ' damage where a normal strike deals ' + dFull.toFixed(1));
  }
  // The "you may" prompt: Debt Comes Due answered yes delays the volley, answered no fires it at once, unanswered keeps the old default
  {
    const run = async (answer) => {
      T.battle('vex', 'voidsworn', ['vex:A:0:0', 'vex:A:1:0', 'vex:A:2:1'], ['h_picket', 'h_picket'], ['penitent', 'harrow']);
      const BB = T.B; let asked = null, saved = null;
      for (const u of T.P()) T.near(u, T.E()[0], 2); // setup: place the fleet two hexes from an enemy so the volley has targets
      if (answer) { g('treeAskCommand')('player'); asked = BB.treeAsk && BB.treeAsk.key; saved = JSON.parse(JSON.stringify(BB.treeAsk)); g('treeAnswer')(answer); }
      const hp0 = T.E().reduce((a, x) => a + x.hp + x.sh.reduce((p, q) => p + q, 0), 0);
      g('rndSeed')(99); await g('useCommand')('player');
      const hp1 = T.E().reduce((a, x) => a + x.hp + x.sh.reduce((p, q) => p + q, 0), 0);
      return { asked, saved, pending: (BB.treePending || []).some(p => p.k === 'debtDue'), dealt: hp0 - hp1 };
    };
    const none = await run(null), yes = await run('yes'), no = await run('no');
    ok('Debt Comes Due prompt', yes.asked === 'vex:A:2:1' && yes.saved.opts.length === 2 && yes.saved.then === 'command', 'the Command opens a yes or no prompt for Debt Comes Due, kept as plain data in the battle state');
    ok('Debt Comes Due (yes)', yes.pending && yes.dealt === 0, 'yes delays the whole volley to next round (nothing hits now)');
    ok('Debt Comes Due (no)', !no.pending && no.dealt > 0, 'no fires the volley at once (' + no.dealt.toFixed(1) + ' damage now, nothing held)');
    ok('Debt Comes Due (bot default)', none.pending && none.dealt === 0, 'with no answer the bot keeps the old default and delays');
  }
  // The other nine "you may" rows: each one opens a prompt for its own Command
  {
    const rows = [['vex', 'voidsworn', ['vex:A:0:1'], ['penitent', 'harrow']], ['malek', 'voidsworn', ['malek:A:0:1'], null], ['ashgrove', 'voidsworn', ['ashgrove:A:0:0', 'ashgrove:A:1:1'], null],
      ['thale', 'voidsworn', ['thale:A:0:1'], null], ['reyes', 'hegemony', ['reyes:A:0:0', 'reyes:A:1:0'], null], ['vesh', 'corsair', ['vesh:A:0:0'], null], ['vesh', 'corsair', ['vesh:A:0:0', 'vesh:A:1:0'], null],
      ['mending', 'chorus', ['mending:A:0:0'], null], ['khepra', 'deathless', ['khepra:A:0:0'], null]];
    const seen = [];
    for (const [id, fac, picks, fleet] of rows) {
      T.battle(id, fac, picks, ['h_picket'], fleet);
      const BB = T.B; const keys = [];
      while (g('treeAskCommand')('player')) { keys.push(BB.treeAsk.key); g('treeAnswer')('no'); }
      const want = picks.filter(k => { const fx = T.FX[k]; return fx && T.MAY[fx.k]; });
      ok('Prompt ' + want.join(','), JSON.stringify(keys) === JSON.stringify(want) && want.every(k => BB.treeMay[k] === false), 'asked ' + keys.length + ' prompt(s) for the Command and stored the answer');
      seen.push(...keys);
    }
    seen.push('vex:A:2:1'); // Debt Comes Due, checked above
    const all = Object.keys(T.MAY).sort(), got = [...new Set(seen.map(k => T.FX[k].k))].sort();
    ok('Every you-may row', JSON.stringify(all) === JSON.stringify(got), all.length + ' you-may skills each open their prompt');
  }
  if (bad) { console.log('FAIL: ' + bad + ' issue 529 check(s) failed'); process.exit(1); }
  console.log('PASS: issue 529, the last seven tree rows and the you-may prompts move their numbers');
})().catch(e => { console.log('FAIL: ' + (e && e.stack || e)); process.exit(1); });
