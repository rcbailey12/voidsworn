#!/usr/bin/env node
// Rarity balance driver for the eight rescaled protocols (issue 443, R175).
// It does not copy any rules. Every battle is the game's own sim3d.js generic
// mode (`node sim3d.js '<json>' <sector> <n>`), which loads data.js, core.js and
// battle.js and runs the shipped bot. This file only chooses the battle setup,
// forces one protocol at one rarity through the sim's own boons field, runs
// seeded chunks in parallel and adds up the results.
//
// Usage:
//   node contrib/deepseek/tools/protocol_balance.js --probe      (calibration)
//   node contrib/deepseek/tools/protocol_balance.js --full       (report cells)
//   node contrib/deepseek/tools/protocol_balance.js --one ...    (single cell)
//
// All scratch output stays on stdout. Nothing is written to the repo.

const { spawn } = require('child_process');

const ROOT = process.cwd();
const NODE = process.execPath;

function arg(name, def) {
  const i = process.argv.indexOf('--' + name);
  return i >= 0 ? process.argv[i + 1] : def;
}
function flag(name) { return process.argv.includes('--' + name); }

const CONC = +(arg('conc', 8));
const CHUNK = +(arg('chunk', 20));
const FULL_N = +(arg('n', 200));
const SEED0 = +(arg('seed', 100000));
const SECTOR = +(arg('sector', 1));
const TIMEOUT_MS = +(arg('timeout', 300000));

function runChunk(setup, boons, seed, n) {
  const S = {
    tag: setup.id,
    player: setup.player,
    enemy: setup.enemy,
    boons: boons,
    kind: setup.kind || 'battle',
    fac: setup.fac || 'hegemony',
  };
  const args = ['sim3d.js', JSON.stringify(S), String(setup.sector || SECTOR), String(n)];
  return new Promise((resolve) => {
    const p = spawn(NODE, args, { cwd: ROOT, env: Object.assign({}, process.env, { SEED: String(seed) }) });
    let out = '', err = '';
    const t = setTimeout(() => { try { p.kill(); } catch (e) {} }, TIMEOUT_MS);
    p.stdout.on('data', (d) => { out += d; });
    p.stderr.on('data', (d) => { err += d; });
    p.on('close', (code) => { clearTimeout(t); resolve({ code, out, err, seed, n }); });
  });
}

function parse(out) {
  const m = out.match(/win (\d+)\/(\d+) \(([-\d]+)%\), hull left ([\d.]+)%, lost ([\d.]+), rounds ([\d.]+)/);
  if (!m) return null;
  return { wins: +m[1], n: +m[2], hull: +m[4], lost: +m[5], rounds: +m[6] };
}

async function pool(tasks, conc) {
  const results = new Array(tasks.length);
  let next = 0;
  async function worker() {
    while (next < tasks.length) {
      const i = next++;
      results[i] = await tasks[i]();
    }
  }
  await Promise.all(Array.from({ length: Math.min(conc, tasks.length) }, worker));
  return results;
}

function cellTasks(setup, boons, total, chunkSize, seedBase) {
  const chunks = Math.ceil(total / chunkSize);
  const tasks = [];
  for (let i = 0; i < chunks; i++) {
    const n = Math.min(chunkSize, total - i * chunkSize);
    const seed = seedBase + i * 7919;
    tasks.push(() => runChunk(setup, boons, seed, n));
  }
  return tasks;
}

function summarize(rows, label) {
  let wins = 0, n = 0, hull = 0, lost = 0, rounds = 0, crashed = 0, timedOut = 0;
  const seeds = [];
  for (const r of rows) {
    if (r.code !== 0) { crashed++; continue; }
    const p = parse(r.out);
    if (!p) { timedOut++; continue; }
    wins += p.wins; n += p.n;
    hull += p.hull * p.n; lost += p.lost * p.n; rounds += p.rounds * p.n;
    seeds.push(r.seed);
  }
  const win = n ? wins / n : NaN;
  const se = n ? Math.sqrt(win * (1 - win) / n) * 100 : NaN;
  return {
    label, wins, n, win: win * 100, se,
    hull: n ? hull / n : NaN, lost: n ? lost / n : NaN, rounds: n ? rounds / n : NaN,
    crashed, timedOut, seedMin: Math.min(...seeds), seedMax: Math.max(...seeds),
  };
}

function fmt(s) {
  return `${s.label.padEnd(16)} win ${s.win.toFixed(1).padStart(5)}% +-${s.se.toFixed(1)}  n ${String(s.n).padStart(4)}  rounds ${s.rounds.toFixed(1)}  hull ${s.hull.toFixed(0)}%  lost ${s.lost.toFixed(2)}  seeds ${s.seedMin}-${s.seedMax}${s.crashed ? '  CRASH ' + s.crashed : ''}${s.timedOut ? '  NOPARSE ' + s.timedOut : ''}`;
}

async function runCell(setup, boons, total, seedBase) {
  const rows = await pool(cellTasks(setup, boons, total, CHUNK, seedBase), CONC);
  return summarize(rows, `${setup.id} r${boons.split(':')[1]}`);
}

// Fleets chosen so the protocol has something to act on. Voidsworn hulls only.
const SETUPS = {
  i_wall: {
    id: 'i_wall', player: ['cathedral', 'penitent', 'penitent', 'warden'],
    enemy: ['h_dominion', 'h_vanguard', 'h_vanguard', 'h_picket'], fac: 'hegemony',
    why: 'scaling extra hull cut on braced neighbours; a tough shielded line that braces',
  },
  s_chain: {
    id: 's_chain', player: ['penitent', 'penitent', 'harrow', 'warden'],
    enemy: ['h_vanguard', 'h_interdictor', 'h_interdictor', 'h_picket'], fac: 'hegemony',
    why: 'chains off a knocked out shield facing; Hegemony ships carry four facings',
  },
  h_brood: {
    id: 'h_brood', player: ['reliquary', 'reliquary', 'penitent', 'warden'],
    enemy: ['h_vanguard', 'h_dominion', 'h_picket'], fac: 'hegemony',
    why: 'carrier fleet: free wing and scaling repair on capital kills',
  },
  a_mark: {
    id: 'a_mark', player: ['cathedral', 'penitent', 'penitent', 'warden'],
    enemy: ['h_dominion', 'h_dominion', 'h_vanguard'], fac: 'hegemony',
    why: 'lance fleet: mark aim scales 10 / 15 / 20',
  },
  r_slip: {
    id: 'r_slip', player: ['penitent', 'penitent', 'harrow', 'warden'],
    enemy: ['h_dominion', 'h_dominion'], fac: 'hegemony',
    why: 'move after firing: half / three quarters / all of the movement left',
  },
  e_spread: {
    id: 'e_spread', player: ['harrow', 'harrow', 'harrow', 'cathedral'],
    enemy: ['h_dominion', 'h_dominion'], fac: 'hegemony',
    why: 'torpedo fleet: miss splash scales 30 / 45 / 60%',
  },
  h_hatch: {
    id: 'h_hatch', player: ['reliquary', 'reliquary', 'penitent', 'warden'],
    enemy: ['h_dominion', 'h_dominion'], fac: 'hegemony',
    why: 'carrier fleet: 1 / 2 / 3 extra wings',
  },
  e_reload: {
    id: 'e_reload', player: ['harrow', 'harrow', 'harrow', 'cathedral'],
    enemy: ['h_dominion', 'h_dominion'], fac: 'hegemony',
    why: 'torpedo fleet: reload 1 / 2 / 3 turns sooner, minimum 1',
  },
};

// Calibration candidates: the same player fleets against a ladder of enemies.
const PROBE = {
  lance: { id: 'probe', player: ['cathedral', 'penitent', 'penitent', 'warden'], fac: 'hegemony' },
  carrier: { id: 'probe', player: ['reliquary', 'reliquary', 'penitent', 'warden'], fac: 'hegemony' },
  torp: { id: 'probe', player: ['harrow', 'harrow', 'harrow', 'cathedral'], fac: 'hegemony' },
  mobile: { id: 'probe', player: ['penitent', 'harrow', 'harrow', 'warden'], fac: 'hegemony' },
  screen: { id: 'probe', player: ['penitent', 'penitent', 'harrow', 'warden'], fac: 'hegemony' },
};
const PROBE_ENEMIES = [
  ['h_vanguard', 'h_picket', 'h_picket'],
  ['h_vanguard', 'h_interdictor', 'h_picket'],
  ['h_vanguard', 'h_interdictor', 'h_interdictor'],
  ['h_vanguard', 'h_interdictor', 'h_interdictor', 'h_picket'],
  ['h_vanguard', 'h_vanguard', 'h_picket'],
  ['h_dominion', 'h_picket'],
  ['h_dominion', 'h_interdictor'],
  ['h_vanguard', 'h_dominion', 'h_picket'],
  ['h_vanguard', 'h_dominion', 'h_interdictor'],
  ['h_dominion', 'h_dominion'],
  ['h_vanguard', 'h_vanguard', 'h_interdictor', 'h_picket'],
  ['h_dominion', 'h_vanguard', 'h_vanguard'],
  ['h_dominion', 'h_dominion', 'h_picket'],
  ['h_vanguard', 'h_vanguard', 'h_vanguard', 'h_picket'],
  ['h_dominion', 'h_vanguard', 'h_interdictor'],
  ['h_dominion', 'h_vanguard', 'h_vanguard', 'h_picket'],
];

async function doProbe() {
  const n = +(arg('n', 20));
  const pi = process.argv.indexOf('--probe');
  const pv = process.argv[pi + 1];
  const which = pv && !pv.startsWith('--') ? pv : 'all';
  const names = which === 'all' ? Object.keys(PROBE) : [which];
  const cells = [];
  for (const name of names) {
    const base = PROBE[name];
    for (let ei = 0; ei < PROBE_ENEMIES.length; ei++) {
      const enemy = PROBE_ENEMIES[ei];
      const setup = Object.assign({}, base, { id: name + ' vs ' + enemy.length, enemy });
      cells.push({ setup, label: name + ' ' + enemy.join('+'), seed: SEED0 + ei * 100003 });
    }
  }
  const tasks = [];
  for (const c of cells) tasks.push(() => runChunk(c.setup, 'i_wall:0', c.seed, n));
  const rows = await pool(tasks, CONC);
  for (let i = 0; i < cells.length; i++) {
    const s = summarize([rows[i]], cells[i].setup.id + ' r0');
    console.log(`${cells[i].label.padEnd(70)} ${fmt(s)}`);
  }
}

async function doFull() {
  const ids = arg('protocol', null) ? [arg('protocol')] : Object.keys(SETUPS);
  const rarityNames = ['Common', 'Rare', 'Epic'];
  const cells = [];
  for (const id of ids) {
    const setup = SETUPS[id];
    for (let r = 0; r < 3; r++) {
      const boons = id + ':' + r;
      const chunks = Math.ceil(FULL_N / CHUNK);
      const tasks = [];
      for (let i = 0; i < chunks; i++) {
        const n = Math.min(CHUNK, FULL_N - i * CHUNK);
        const seed = SEED0 + i * 7919;
        tasks.push({ n, seed, run: () => runChunk(setup, boons, seed, n) });
      }
      cells.push({ id, setup, r, boons, tasks, label: id + ' ' + rarityNames[r] });
    }
  }
  const flat = [];
  for (const c of cells) for (const t of c.tasks) flat.push(t);
  const rows = await pool(flat.map((t) => t.run), CONC);
  let k = 0;
  const byCell = new Map();
  for (const c of cells) {
    const cellRows = [];
    for (let i = 0; i < c.tasks.length; i++) cellRows.push(rows[k++]);
    byCell.set(c.id + ':' + c.r, summarize(cellRows, c.label));
  }
  const out = [];
  for (const id of ids) {
    const setup = SETUPS[id];
    console.log('# ' + id + ': ' + setup.why);
    console.log('# player ' + setup.player.join(',') + ' | enemy ' + setup.enemy.join(',') + ' | ' + (setup.fac || 'hegemony') + ' sector ' + (setup.sector || SECTOR));
    const common = byCell.get(id + ':0'), rare = byCell.get(id + ':1'), epic = byCell.get(id + ':2');
    for (const s of [common, rare, epic]) console.log(fmt(s));
    const dRare = rare.win - common.win, dEpic = epic.win - common.win;
    console.log(`  delta vs Common: Rare ${dRare >= 0 ? '+' : ''}${dRare.toFixed(1)} points (se ~${Math.sqrt(rare.se ** 2 + common.se ** 2).toFixed(1)}), Epic ${dEpic >= 0 ? '+' : ''}${dEpic.toFixed(1)} points (se ~${Math.sqrt(epic.se ** 2 + common.se ** 2).toFixed(1)})`);
    out.push({ id, common, rare, epic, dRare, dEpic });
  }
  return out;
}

async function doOne() {
  const setup = {
    id: arg('id', 'one'),
    player: arg('player', 'penitent,harrow,harrow,warden').split(','),
    enemy: arg('enemy', 'h_vanguard,h_interdictor,h_picket,h_picket').split(','),
    fac: arg('fac', 'hegemony'),
    kind: arg('kind', 'battle'),
  };
  const boons = arg('boon', 'i_wall:0');
  const s = await runCell(setup, boons, +(arg('n', 20)), +(arg('seed', SEED0)));
  console.log(fmt(s));
}

(async () => {
  if (flag('probe')) return doProbe();
  if (flag('one')) return doOne();
  return doFull();
})().catch((e) => { console.error(e && e.stack || e); process.exit(1); });
