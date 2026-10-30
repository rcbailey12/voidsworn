// softlock_sweep.js - seed sweep for campaign-map and battle-setup softlocks.
//
// Part 1, sector maps: for each seed x sector, genSector must produce a
// map the campaign can actually be finished on:
//   - 7 columns; column 0 holds exactly one entry node; the last column
//     holds exactly one boss node; the column before the boss is all
//     rest stops (shipyard / drydock / field).
//   - every middle column offers at least one fight (battle or elite),
//     column 4 offers an elite, column 3 offers a shipyard (the game's
//     own guarantees, asserted so a future edit cannot drop one).
//   - the boss is reachable from the entry node along the edge list
//     (the true softlock check: edges are built per column pair, and a
//     node with no path forward strands the run).
//   - fight nodes carry an encounter that exists in ENCOUNTERS.
//   - the same seed regenerates the identical map.
//
// Part 2, battle setup: for a seed grid over shapes x maps x encounter
// objectives x kinds, startBattle must complete and deploy legally:
//   - no throw; B exists and the battle is not already over.
//   - the terrain passes the game's own terrainConnected check.
//   - every deployed unit is on the board; no two non-squadron units
//     share a hex at deployment.
//   - the player side fields exactly the living ships in RUN.fleet.
//
// Usage: node softlock_sweep.js [repoDir] [sectorSeeds] [battleSeedsPerCell]
// Exit code 0 = no softlock found; 1 = failures printed with their seeds.
'use strict';
const { loadGame } = require('./game_loader');
const path = require('path');

const repoDir = process.argv[2] || path.join(__dirname, '..', 'voidsworn-fresh');
const SECTOR_SEEDS = parseInt(process.argv[3] || '1500', 10);
const BATTLE_SEEDS = parseInt(process.argv[4] || '4', 10);
const G = loadGame(repoDir);
const { ENCOUNTERS, SHAPES } = G;

let failures = [];
const fail = m => failures.push(m);

// ---------- part 1: sector maps ----------
const NODE_TYPES = new Set(['battle', 'elite', 'event', 'shipyard', 'drydock', 'field', 'boss']);
let maps = 0;
for (let seed = 1; seed <= SECTOR_SEEDS; seed++) {
  for (let s = 1; s <= 3; s++) {
    const run = G.runDefaults();
    run.sector = s; run.foes = null; run.condsUsed = []; run.regionsUsed = [];
    G.RUN = run;
    G.rndSeed(seed * 31 + s);
    let m1, m2;
    try {
      m1 = G.genSector(s);
      const again = G.runDefaults(); again.sector = s; again.foes = run.foes; again.condsUsed = []; again.regionsUsed = [];
      // determinism: same seed, fresh run state (condsUsed/regionsUsed evolve by design, so compare the map body)
      G.RUN = again; G.rndSeed(seed * 31 + s); m2 = G.genSector(s);
    } catch (e) { fail('sector seed ' + seed + ' s' + s + ': genSector threw ' + e.message); continue; }
    maps++;
    const tag = 'sector seed ' + seed + ' s' + s + ': ';
    const body = m => JSON.stringify([m.cols.map(c => c.map(n => n.type + (n.enc || ''))), m.edges]);
    if (body(m1) !== body(m2)) fail(tag + 'nondeterministic map');
    const cols = m1.cols;
    if (cols.length !== 7) { fail(tag + 'cols ' + cols.length); continue; }
    if (cols[0].length !== 1) fail(tag + 'entry column has ' + cols[0].length + ' nodes');
    if (cols[6].length !== 1 || cols[6][0].type !== 'boss') fail(tag + 'last column is not a single boss');
    for (const n of cols[5]) if (!['shipyard', 'drydock', 'field'].includes(n.type)) fail(tag + 'pre-boss column holds ' + n.type);
    for (let c = 1; c <= 4; c++) if (!cols[c].some(n => n.type === 'battle' || n.type === 'elite')) fail(tag + 'column ' + c + ' offers no fight');
    if (!cols[4].some(n => n.type === 'elite')) fail(tag + 'column 4 offers no elite');
    if (!cols[3].some(n => n.type === 'shipyard')) fail(tag + 'column 3 offers no shipyard');
    for (const col of cols) for (const n of col) {
      if (!NODE_TYPES.has(n.type)) fail(tag + 'unknown node type ' + n.type);
      if ((n.type === 'battle' || n.type === 'elite') && n.enc && !ENCOUNTERS[n.enc]) fail(tag + 'unknown encounter ' + n.enc);
    }
    // reachability: BFS from the entry node along edges to the boss.
    const adj = new Map();
    for (const [a, b] of m1.edges) { if (!adj.has(a)) adj.set(a, []); adj.get(a).push(b); }
    const seen = new Set([cols[0][0].id]); const queue = [cols[0][0].id];
    while (queue.length) { const cur = queue.shift(); for (const nx of adj.get(cur) || []) if (!seen.has(nx)) { seen.add(nx); queue.push(nx); } }
    if (!seen.has(cols[6][0].id)) fail(tag + 'boss unreachable from entry');
    const allIds = new Set(cols.flat().map(n => n.id));
    for (const id of allIds) if (!seen.has(id) && id !== cols[0][0].id) { /* unreachable side nodes are legal (choice), not a softlock */ }
  }
}
G.RUN = null;
console.log('softlock_sweep part 1: ' + maps + ' sector maps, ' + failures.length + ' failures so far');

// ---------- part 2: battle setup ----------
const MAPS = ['belt', 'station', 'planet', 'storm', 'graveyard'];
const FACS = Object.keys(G.FACTIONS);
let battles = 0, battleFailures = 0;
for (const shape of Object.keys(SHAPES)) {
  for (const map of MAPS) {
    for (const obj of Object.keys(ENCOUNTERS)) {
      for (let seed = 1; seed <= BATTLE_SEEDS; seed++) {
        const fac = FACS[(seed + shape.length + map.length) % FACS.length];
        const run = G.runDefaults();
        run.sector = 1 + (seed % 3); run.admiral = 'vex'; run.fac = 'voidsworn';
        run.fleet = ['warden', 'harrow', 'penitent', 'warden', 'reliquary'].map(t => { const sh = G.newShip(t, false); return sh; });
        run.flagUid = run.fleet[0].uid;
        G.RUN = run;
        G.rndSeed(seed * 7717 + shape.length * 131 + map.length * 17 + obj.length);
        const tag = 'battle ' + shape + '/' + map + '/' + obj + ' seed ' + seed + ': ';
        try {
          G.startBattle({ kind: seed % 5 === 0 ? 'boss' : seed % 3 === 0 ? 'elite' : 'battle', fac, col: 3, obj, shape, map });
        } catch (e) { fail(tag + 'startBattle threw ' + e.message); battleFailures++; continue; }
        battles++;
        const B = G.B;
        if (!B) { fail(tag + 'no battle state'); battleFailures++; continue; }
        if (B.over) { fail(tag + 'battle already over at setup'); battleFailures++; }
        if (!G.terrainConnected(B.terrain)) { fail(tag + 'terrain disconnected'); battleFailures++; }
        const hexes = new Map();
        for (const u of B.units) {
          if (!G.onBoard(u.q, u.r)) { fail(tag + 'unit ' + u.tpl + ' off board at ' + u.q + ',' + u.r); battleFailures++; }
          if (!u.isSq) { const k = u.q + ',' + u.r; if (hexes.has(k)) { fail(tag + 'deployment overlap at ' + k + ' (' + hexes.get(k) + ' and ' + u.tpl + ')'); battleFailures++; } hexes.set(k, u.tpl); }
          if (!isFinite(u.hp) || !isFinite(u.maxHp)) { fail(tag + 'unit ' + u.tpl + ' has non-finite hull'); battleFailures++; }
        }
        const pl = B.units.filter(u => u.side === 'player' && !u.isSq).length;
        if (pl !== run.fleet.length) { fail(tag + 'player fields ' + pl + ' of ' + run.fleet.length + ' ships'); battleFailures++; }
      }
    }
  }
}
G.RUN = null;
console.log('softlock_sweep part 2: ' + battles + ' battle setups, ' + battleFailures + ' failures');
console.log('softlock_sweep total: ' + failures.length + ' failures');
{ const tally = {}; for (const f of failures) { const k = f.replace(/^sector seed \d+ s\d+: /, '').replace(/\d+/g, 'N'); tally[k] = (tally[k] || 0) + 1; }
  for (const [k, n] of Object.entries(tally).sort((a, b) => b[1] - a[1])) console.log('KIND ' + n + 'x ' + k); }
for (const f of failures.slice(0, 40)) console.log('FAIL ' + f);
if (failures.length > 40) console.log('... and ' + (failures.length - 40) + ' more');
process.exit(failures.length ? 1 : 0);
