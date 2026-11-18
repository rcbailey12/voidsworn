// Issue 1019: map pace numbers for the map size study (1004 / PR 1008).
// Measurement only. Runs headless browser-rules battles through the sim3d harness,
// with board size and ship speed changed in this file's own setup, not in battle.js
// or data.js. No game file is edited.
//
// The R314 comparison reads battle.js at b0c490b2. The other setups use the
// checkout's battle.js. Each battle labels its own station footprint.
//
//   node contrib/deepseek/map_pace_1117/sim_map_pace.js
//   node contrib/deepseek/map_pace_1117/sim_map_pace.js --sims 200 --out contrib/deepseek/map_pace_1117/raw.csv
//   node contrib/deepseek/map_pace_1117/sim_map_pace.js --only today_standard --sims 5
//
// The per-setup raw_<setup>.json files and summary.md are written beside --out
// (default: this script's folder). --merge reads them from that same folder, so a
// smoke run pointed at a temp folder never touches the saved dataset.
//
// Metrics per capital-ship activation: whether any weapon fired. A flak interception
// is not a shot (the rules do not spend the gun), and a launch or other ability is not
// a shot. First contact is the number of completed capital activations before the
// first one that fired a weapon.
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..', '..', '..');
const SOURCE_KEYS = ['data_commit', 'core_commit', 'battle_commit', 'sim3d_commit'];

const FLEET = ['h_vanguard', 'h_interdictor', 'h_interdictor', 'h_picket', 'h_picket', 'h_dominion'];

// The original R314 comparison used this revision of battle.js.
const STATION_983_COMMIT = 'b0c490b2';

// PR 1008 measured a 38 by 26 canvas at today's speed, +1 and +2. Its recommendation
// was to keep the 30 by 22 canvas; these are the size and speed options it priced.
const SETUPS = [
  { id: 'today_standard', label: 'Today standard strip 30x22 speed +0', w: 30, h: 22, speed: 0, enc: 'rout', map: 'belt', shape: 'open', arena: 'strip' },
  { id: 'today_defend', label: 'Today station defend 30x22 speed +0', w: 30, h: 22, speed: 0, enc: 'defend', map: 'station', shape: 'open', arena: 'strip' },
  { id: 'today_defend_19hex', label: 'R314 comparison station defend 30x22 speed +0', w: 30, h: 22, speed: 0, enc: 'defend', map: 'station', shape: 'open', arena: 'strip', src: '983' },
  { id: 'big_speed0', label: '38x26 speed +0', w: 38, h: 26, speed: 0, enc: 'rout', map: 'belt', shape: 'open', arena: 'strip' },
  { id: 'big_speed1', label: '38x26 speed +1', w: 38, h: 26, speed: 1, enc: 'rout', map: 'belt', shape: 'open', arena: 'strip' },
  { id: 'big_speed2', label: '38x26 speed +2', w: 38, h: 26, speed: 2, enc: 'rout', map: 'belt', shape: 'open', arena: 'strip' },
];

function args() {
  const out = { sims: 200, out: path.join(__dirname, 'raw.csv'), only: null, setups: null, merge: false, seed: 1000 };
  const a = process.argv.slice(2);
  for (let i = 0; i < a.length; i++) {
    if (a[i] === '--sims') out.sims = Math.max(1, +a[++i]);
    else if (a[i] === '--out') out.out = path.resolve(a[++i]);
    else if (a[i] === '--only') out.only = a[++i];
    else if (a[i] === '--setups') out.setups = a[++i].split(',').map((x) => x.trim()).filter(Boolean);
    else if (a[i] === '--merge') out.merge = true;
    else if (a[i] === '--seed') out.seed = +a[++i];
    else throw new Error('unknown argument: ' + a[i]);
  }
  return out;
}

function git(args) {
  return execFileSync('git', args, { cwd: ROOT, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
}

function checkoutSource(file, commit) {
  const text = fs.readFileSync(path.join(ROOT, file), 'utf8');
  const dirty = git(['diff', '--name-only', commit, '--', file]).trim();
  return { text, commit: commit + (dirty ? '+working' : '') };
}

let station983Src;
function battleSourceFor(setup, commit) {
  if (setup.src !== '983') return checkoutSource('battle.js', commit);
  if (!station983Src) {
    try {
      const pinned = git(['rev-parse', STATION_983_COMMIT + '^{commit}']).trim();
      station983Src = { commit: pinned, text: git(['show', pinned + ':battle.js']) };
    } catch (e) {
      throw new Error('cannot read battle.js at ' + STATION_983_COMMIT + '; run git fetch origin work/issue-983-deepseek first (' + e.message + ')');
    }
  }
  return station983Src;
}

function boardSource(src, w, h) {
  const from = 'const BW=30, BH=22;';
  if (src.indexOf(from) < 0) throw new Error('battle.js board constant not found at the usual line');
  return src.replace(from, `const BW=${w}, BH=${h};`);
}

// Load one private copy of the browser rules and the sim3d bot in a fresh VM context.
// The board constant is replaced in memory only. HULLS speed is changed after load.
function loadHarness(setup) {
  const commit = git(['rev-parse', 'HEAD']).trim();
  const harness = checkoutSource('sim3d.js', commit);
  const data = checkoutSource('data.js', commit);
  const core = checkoutSource('core.js', commit);
  const battle = battleSourceFor(setup, commit);
  let src = harness.text;
  const cut = src.indexOf("(async()=>{ if(process.argv[2]==='varmatrix')");
  if (cut < 0) throw new Error('sim3d.js dispatcher not found, the harness layout changed');
  src = src.slice(0, cut);

  const evalFrom = "eval(['data.js','core.js','battle.js'].map(f=>fs.readFileSync(f,'utf8')).join('\\n')";
  if (src.indexOf(evalFrom) < 0) throw new Error('sim3d.js game-file loader not found, the harness layout changed');
  src = src.replace(evalFrom, "eval([__DATA_SRC,__CORE_SRC,__BATTLE_SRC].join('\\n')");

  const marker = 'global.sqCheck=sqCheck;';
  if (src.indexOf(marker) < 0) throw new Error('sim3d.js harness export marker not found');
  src = src.replace(marker, marker + ' global.__H={rndSeed,startBattle,newShip,swarmPhase,botUnit,alive,aiUnit,aiPickActivation,roundStart,derive,HULLS,getRUN:()=>RUN,setRUN:v=>{RUN=v;},getB:()=>B,setAlt:v=>{B.alt=v;},startSideTurn};');

  const sandbox = {
    __DATA_SRC: data.text,
    __CORE_SRC: core.text,
    __BATTLE_SRC: boardSource(battle.text, setup.w, setup.h),
    require,
    module: { exports: {} },
    exports: {},
    process,
    console: { log() {}, warn() {}, error() {}, debug() {} },
    setTimeout: (fn) => { fn(); return 0; },
    clearTimeout() {},
    setInterval: () => 0,
    clearInterval() {},
    Date,
    Math,
    JSON,
  };
  sandbox.global = sandbox;
  sandbox.globalThis = sandbox;
  sandbox.window = {};
  sandbox.document = undefined;
  sandbox.performance = { now: () => Date.now() };
  vm.createContext(sandbox);
  vm.runInContext(src, sandbox, { filename: 'sim3d_harness.js' });
  if (!sandbox.__H) throw new Error('harness export failed');
  return Object.assign(sandbox.__H, {
    sourceCommits: { data_commit: data.commit, core_commit: core.commit, battle_commit: battle.commit, sim3d_commit: harness.commit },
  });
}

function buildRun(H) {
  const run = {
    fac: 'hegemony', admiral: 'vex', credits: 0, cpCap: 40, sector: 2,
    relics: [], inventory: [], fleet: [], boons: [], patrons: [], aspect: null, lineage: null,
    stats: { battles: 0, elites: 0, bosses: 0, kills: 0 }, fallen: [],
  };
  for (const tpl of FLEET) run.fleet.push(H.newShip(tpl, true));
  run.flagUid = run.fleet[0].uid;
  return run;
}

function firedCount(u) {
  let n = 0;
  for (const w of u.weapons || []) if (w.fired) n++;
  return n;
}

async function fight(H, setup, seed) {
  H.rndSeed(seed);
  H.setRUN(buildRun(H));
  H.startBattle({
    kind: 'battle', fac: 'hegemony', col: 3, seed,
    obj: setup.enc, map: setup.map, shape: setup.shape, arena: setup.arena, dep: 'line',
    enemies: FLEET.map((tpl) => ({ tpl })),
  });
  const terrain = H.getB().map;
  const stationR = terrain.stationR ?? null;
  const label = stationR === null ? setup.label : `${setup.label} (${1 + 3 * stationR * (stationR + 1)}-hex station)`;

  let activations = 0, noShot = 0, firstContact = null;
  const activate = async (u, fn) => {
    if (!u || u.isSq) { await fn(); return; }
    const before = firedCount(u);
    await fn();
    const after = firedCount(u);
    activations++;
    if (after > before) {
      if (firstContact === null) firstContact = activations - 1;
    } else {
      noShot++;
    }
  };

  H.setAlt(true);
  for (const x of H.getB().units) x.activated = false;
  H.startSideTurn('enemy');
  let rounds = 0;
  while (!H.getB().over && rounds < 30) {
    await H.swarmPhase('player');
    await H.swarmPhase('enemy');
    let guard = 0;
    while (!H.getB().over && guard++ < 400) {
      const B = H.getB();
      const pp = H.alive('player').filter((x) => !x.isSq && !x.activated);
      const pe = H.alive('enemy').filter((x) => !x.isSq && !x.activated);
      if (!pp.length && !pe.length) break;
      if (pp.length) {
        await activate(pp[0], () => H.botUnit(pp[0]));
        pp[0].activated = true;
      }
      const pp2 = H.alive('player').some((x) => !x.isSq && !x.activated);
      const batch = pp2 ? (pe.length ? [H.aiPickActivation(pe)] : []) : pe;
      for (const u of batch) {
        if (H.getB().over) break;
        await activate(u, () => H.aiUnit(u));
        u.activated = true;
      }
    }
    if (H.getB().over) break;
    const B = H.getB();
    B.round++;
    for (const x of B.units) x.activated = false;
    await H.roundStart();
    rounds++;
  }

  const B = H.getB();
  return {
    setup: setup.id,
    label,
    board_w: setup.w,
    board_h: setup.h,
    speed_delta: setup.speed,
    encounter: setup.enc,
    map: B.map && B.map.map || setup.map,
    arena: B.arena,
    seed,
    first_contact_activations: firstContact === null ? '' : firstContact,
    battle_rounds: B.round,
    capital_activations: activations,
    no_shot_activations: noShot,
    no_shot_share: activations ? +(noShot / activations).toFixed(4) : '',
    win: B.over === 'win' ? 1 : 0,
    timeout: B.over ? 0 : 1,
    result: B.over || 'timeout',
    station_r: stationR,
    ...H.sourceCommits,
  };
}

function median(xs) {
  if (!xs.length) return null;
  const a = xs.slice().sort((x, y) => x - y);
  const m = a.length >> 1;
  return a.length % 2 ? a[m] : (a[m - 1] + a[m]) / 2;
}
function mean(xs) { return xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null; }
function wilson(k, n) {
  if (!n) return [0, 0];
  const p = k / n, z = 1.96, d = 1 + z * z / n;
  const c = (p + z * z / (2 * n)) / d, s = z * Math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d;
  return [Math.max(0, c - s), Math.min(1, c + s)];
}

function summarise(rows) {
  if (!rows.length) return null;
  const contacts = rows.map((r) => r.first_contact_activations).filter((x) => x !== '');
  const rounds = rows.map((r) => r.battle_rounds);
  const acts = rows.map((r) => r.capital_activations);
  const noShot = rows.reduce((a, r) => a + r.no_shot_activations, 0);
  const totalActs = rows.reduce((a, r) => a + r.capital_activations, 0);
  const wins = rows.reduce((a, r) => a + r.win, 0);
  const ci = wilson(wins, rows.length);
  return {
    id: rows[0].setup,
    label: rows[0].label,
    board_w: rows[0].board_w,
    board_h: rows[0].board_h,
    speed_delta: rows[0].speed_delta,
    sims: rows.length,
    wins,
    win_rate: wins / rows.length,
    win_lo: ci[0],
    win_hi: ci[1],
    timeouts: rows.reduce((a, r) => a + r.timeout, 0),
    contact_n: contacts.length,
    contact_median: median(contacts),
    contact_mean: mean(contacts),
    rounds_mean: mean(rounds),
    rounds_median: median(rounds),
    acts_mean: mean(acts),
    no_shot_share: totalActs ? noShot / totalActs : 0,
    sourceRows: [...new Set(rows.map((r) => [
      r.label, ...SOURCE_KEYS.map((key) => r[key] || 'unrecorded'),
    ].join(' | ')))],
  };
}

function pct(x) { return (x * 100).toFixed(1) + '%'; }
function num(x, d) { return x == null ? 'n/a' : x.toFixed(d == null ? 1 : d); }

function report(summaries) {
  const lines = [];
  lines.push('| Setup | Board | Speed | Sims | First contact median (mean), activations [sims with contact] | Battle rounds mean (median) | Capital activations, mean | No shot fired, share | Win rate (95% CI) | Timeouts |');
  lines.push('|---|---|---|---|---|---|---|---|---|---|');
  for (const s of summaries) {
    lines.push('| ' + s.label + ' | ' + s.board_w + ' by ' + s.board_h + ' | +' + s.speed_delta + ' | ' + s.sims + ' | ' + num(s.contact_median) + ' (' + num(s.contact_mean) + ') [' + s.contact_n + '/' + s.sims + '] | ' + num(s.rounds_mean) + ' (' + num(s.rounds_median) + ') | ' + num(s.acts_mean) + ' | ' + pct(s.no_shot_share) + ' | ' + pct(s.win_rate) + ' (' + pct(s.win_lo) + ' to ' + pct(s.win_hi) + ') | ' + s.timeouts + ' |');
  }
  const base = summaries.find((s) => s.id === 'today_standard');
  if (base) {
    lines.push('');
    lines.push('Change against today standard (setup summary minus baseline summary; same seed set; positive first contact means slower contact):');
    lines.push('');
    lines.push('| Setup | First contact median change | First contact mean change | Battle rounds change | No shot share change | Win rate change |');
    lines.push('|---|---|---|---|---|---|');
    for (const s of summaries) {
      if (s === base) continue;
      lines.push('| ' + s.label + ' | ' + (s.contact_median == null || base.contact_median == null ? 'n/a' : (s.contact_median - base.contact_median).toFixed(1)) + ' | ' + (s.contact_mean == null || base.contact_mean == null ? 'n/a' : (s.contact_mean - base.contact_mean).toFixed(1)) + ' | ' + (s.rounds_mean - base.rounds_mean).toFixed(1) + ' | ' + ((s.no_shot_share - base.no_shot_share) * 100).toFixed(1) + ' pts | ' + ((s.win_rate - base.win_rate) * 100).toFixed(1) + ' pts |');
    }
  }
  lines.push('', '| Setup | data.js commit | core.js commit | battle.js commit | sim3d.js commit |');
  lines.push('|---|---|---|---|---|');
  for (const s of summaries) {
    for (const row of s.sourceRows) lines.push('| ' + row + ' |');
  }
  return lines.join('\n');
}

const CSV_KEYS = ['setup', 'label', 'board_w', 'board_h', 'speed_delta', 'encounter', 'map', 'arena', 'seed', 'first_contact_activations', 'battle_rounds', 'capital_activations', 'no_shot_activations', 'no_shot_share', 'win', 'timeout', 'result', 'station_r', ...SOURCE_KEYS];

function csvOf(rows) {
  return [CSV_KEYS.join(',')].concat(rows.map((r) => CSV_KEYS.map((k) => {
    const v = r[k];
    return typeof v === 'string' && /[",]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
  }).join(','))).join('\n') + '\n';
}

function writeFinal(rows, outPath) {
  const summaries = SETUPS.map((s) => summarise(rows.filter((r) => r.setup === s.id))).filter(Boolean);
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, csvOf(rows), 'utf8');
  fs.writeFileSync(path.join(path.dirname(outPath), 'summary.md'), report(summaries) + '\n', 'utf8');
  console.log('\n' + report(summaries));
  console.log('\nCSV: ' + outPath);
  console.log('Summary: ' + path.join(path.dirname(outPath), 'summary.md'));
}

(async () => {
  const opt = args();
  if (opt.merge) {
    const rows = [];
    const rawDir = path.dirname(opt.out);
    for (const setup of SETUPS) {
      const f = path.join(rawDir, 'raw_' + setup.id + '.json');
      if (!fs.existsSync(f)) throw new Error('missing ' + f + ', run that setup first');
      rows.push(...JSON.parse(fs.readFileSync(f, 'utf8')));
    }
    writeFinal(rows, opt.out);
    return;
  }
  const setups = opt.setups ? SETUPS.filter((s) => opt.setups.includes(s.id)) : opt.only ? SETUPS.filter((s) => s.id === opt.only) : SETUPS;
  if (!setups.length) throw new Error('no setup named ' + (opt.only || opt.setups));
  const rawDir = path.dirname(opt.out);
  fs.mkdirSync(rawDir, { recursive: true });
  const all = [];
  for (const setup of setups) {
    const H = loadHarness(setup);
    if (setup.speed) {
      for (const id of Object.keys(H.HULLS)) {
        const h = H.HULLS[id];
        if (h && typeof h.sp === 'number') h.sp += setup.speed;
      }
    }
    const rows = [];
    for (let i = 0; i < opt.sims; i++) {
      const seed = opt.seed + i;
      const row = await fight(H, setup, seed);
      rows.push(row);
      all.push(row);
      if ((i + 1) % 25 === 0 || i + 1 === opt.sims) process.stdout.write('  ' + setup.id + ': ' + (i + 1) + '/' + opt.sims + '\n');
    }
    fs.writeFileSync(path.join(rawDir, 'raw_' + setup.id + '.json'), JSON.stringify(rows, null, 0), 'utf8');
    const s = summarise(rows);
    process.stdout.write('SUMMARY ' + s.id + ': contact median ' + num(s.contact_median) + ' activations, rounds ' + num(s.rounds_mean) + ', no shot ' + pct(s.no_shot_share) + ', win ' + pct(s.win_rate) + ', timeouts ' + s.timeouts + '/' + s.sims + '\n');
  }
  writeFinal(all, opt.out);
})().catch((e) => { console.error(e && e.stack || e); process.exit(1); });
