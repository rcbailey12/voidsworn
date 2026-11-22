'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const {Worker, isMainThread, parentPort, workerData} = require('node:worker_threads');

const root = path.resolve(__dirname, '../../..');
const sources = require('./rules_sources.json');
const git = (...args) => execFileSync('git', args, {cwd: root, encoding: 'utf8'});
const trial = fs.readFileSync(path.join(__dirname, 'trial_rules.js'), 'utf8');
const setups = ['today', 'shapes', 'placement', 'tempo', 'all'];
const followups = ['hunt_placement', 'hunt_all', 'recommended'];
const huntSettings = JSON.parse(fs.readFileSync(path.join(__dirname, 'hunt_settings.json'), 'utf8'));
const ordinary = ['rout', 'ambush', 'defend', 'hunt', 'intercept', 'break', 'hold', 'flagship'];
const bosses = [1, 2, 3].flatMap(s => ['rout', 'ambush'].map(enc => `boss${s}_${enc}`));
const encounters = [...ordinary, ...bosses];
const maps = ['belt', 'graveyard', 'storm', 'planet', 'station'];
const fleets = {
  hegemony: ['h_vanguard', 'h_interdictor', 'h_interdictor', 'h_picket', 'h_picket', 'h_dominion'],
  voidsworn: ['reliquary', 'penitent', 'cathedral', 'harrow', 'warden', 'warden'],
  corsair: ['c_hulk', 'c_marauder', 'c_marauder', 'c_reaver', 'c_reaver', 'c_raider', 'c_raider'],
  chorus: ['b_brood', 'b_razor', 'b_razor', 'b_spitter', 'b_spitter', 'b_drone'],
  ithar: ['i_carrier', 'i_song', 'i_song', 'i_blade', 'i_wisp'],
  deathless: ['d_harvester', 'd_harvester', 'd_jackal', 'd_jackal', 'd_scythe', 'd_scythe', 'd_scythe', 'd_scythe'],
};
const factions = Object.keys(fleets);

function replaceOnce(source, old, value) {
  const at = source.indexOf(old);
  assert(at >= 0 && source.indexOf(old, at + old.length) < 0, `Expected one source match for ${old}`);
  return source.slice(0, at) + value + source.slice(at + old.length);
}

function harness({rules, revision, ramp}) {
  const read = name => git('show', `${revision}:${name}`).replace(/\r\n/g, '\n');
  const data = read('data.js');
  const core = replaceOnce(read('core.js'), "const newId = () => 'x'+Date.now().toString(36)+(UID++);",
    "const newId = () => 'x'+String(UID++).padStart(8,'0');");
  let source = read('battle.js');
  source = replaceOnce(source, 'const eList = cfg.enemies || genEnemyFleet', 'const eList = cfg.enemies || cfg.trialEnemies || genEnemyFleet');
  source = replaceOnce(source, "else if(enc==='hunt'){ const bb0=boardBounds()", `else if(cfg.trialPlacement&&enc==='hunt'){
    trialHunt(B.units.filter(u=>u.side==='player'), B.units.filter(u=>u.side==='enemy'));
  } else if(enc==='hunt'){ const bb0=boardBounds()`);
  source = replaceOnce(source, '  clearSpawns();\n  treeBattleStart();', `  if(cfg.trialPlacement && enc!=='hunt') {
    const player = B.units.filter(u=>u.side==='player');
    const enemy = B.units.filter(u=>u.side==='enemy'&&!u.transport);
    if(enc==='ambush') trialAmbush(enemy, player);
    if(enc==='defend') trialDefend(player);
    if(enc==='intercept') trialIntercept(enemy, B.units.filter(u=>u.transport));
    if(enc==='break') trialBreak(player,enemy);
    if(cfg.kind==='boss'&&enc==='rout'||enc==='flagship') {
      const target = enemy.find(u=>u.t.boss)||enemy.slice().sort((a,b)=>b.t.cp-a.t.cp||b.maxHp-a.maxHp)[0];
      trialBehind(target,enemy.filter(u=>u!==target),player);
    }
  }
  clearSpawns();
  treeBattleStart();`);
  source = replaceOnce(source, "  startSideTurn('player');\n  for(const u of alive('enemy'))", `  if(cfg.trialTempo) for(const u of B.units) trialScale(u);
  B.trialStarted=true;
  startSideTurn('player');
  for(const u of alive('enemy'))`);
  // The trial quarry follows its jump bearing in place of the AI's generic approach term.
  source = rules === 'frozen'
    ? replaceOnce(source, 'if(off<=0){ const hd=', 'if(u!==B.trialQuarry&&off<=0){ const hd=')
    : replaceOnce(source, 'if(off<=0||unloaded){', 'if(u!==B.trialQuarry&&(off<=0||unloaded)){');
  source = replaceOnce(source, '  const keep=[w.fired,w.cdLeft,u.sureUsed,u.postFire,u.postMp], b0=B;', `  if(!opts.intercept) trialShot(u,t,w);
  const keep=[w.fired,w.cdLeft,u.sureUsed,u.postFire,u.postMp], b0=B;`);

  let sim = read('sim3d.js');
  const start = sim.indexOf('function log(m)');
  const end = sim.indexOf('async function match(');
  assert(start >= 0 && end > start, 'Expected sim3d bot and animation hooks');
  sim = sim.slice(start, end);
  sim = replaceOnce(sim, 'const hex=path.filter(p=>!p.rot).length, rot=path.length-hex;', `const hex=path.filter(p=>!p.rot).length, rot=path.length-hex;
  trialMove(u,hex);`);
  sim = replaceOnce(sim, 'async function animMove(u,q,r,f){ u.q=q;', 'async function animMove(u,q,r,f){ trialMove(u,hdist(u,{q,r})); u.q=q;');

  // Each worker owns its own compiled copy, with only the default simulation flags.
  // Zero-delay presentation waits resolve immediately; rule promises still run in order.
  const compile = new Function('process', 'setTimeout', 'setInterval', 'clearInterval', 'console',
    // ramp: fleet budget values to use instead of the frozen battle.js ones (R414: Godot's tables moved after the JS froze).
    [data, core, source, ramp ? 'Object.assign(RAMP,' + JSON.stringify(ramp) + ');' : '', sim, trial, runtime, 'return trialApi;'].join('\n'));
  return compile({env: {}}, fn => { fn(); return 0; }, () => 0, () => {}, {log() {}, debug() {}, warn: console.warn});
}

const runtime = `
var STATS={rams:0,boards:0,caps:0};
let meter=null;
function trialScaledStat(value) { return Math.round(value*1.25); }
const trialOriginalObjScore=aiObjScore;
aiObjScore=function(u,v) {
  if(B.obj&&!u.isSq&&!u.transport&&B.trialQuarry&&(u===B.trialQuarry||u.trialStation)) return trialHuntScore(u,v);
  return trialOriginalObjScore(u,v);
};
function trialScale(u) {
  u.speed=trialScaledStat(u.speed);
  for(const w of u.weapons) w.r=trialScaledStat(w.r);
}
const trialMake=makeUnit;
makeUnit=function(...args) {
  const u=trialMake(...args);
  if(B&&B.trialStarted&&B.cfg.trialTempo) trialScale(u);
  return u;
};
const trialAbility=useAbility;
useAbility=async function(u,...args) {
  const from=u.ab==='blink'?{q:u.q,r:u.r}:null;
  const result=await trialAbility(u,...args);
  if(meter&&meter.unit===u&&result) meter.other=true;
  if(from) trialMove(u,hdist(from,u));
  return result;
};
const trialOrder=giveOrder;
giveOrder=function(u,...args) {
  if(meter&&meter.unit===u&&canOrder(u,args[0])) meter.other=true;
  return trialOrder(u,...args);
};
const trialCommand=useCommand;
useCommand=async function(...args) {
  if(meter&&meter.unit&&canCommand(args[0])) meter.other=true;
  return trialCommand(...args);
};
function trialMove(u, distance) {
  if(!meter||meter.unit!==u||distance<1) return;
  meter.distance+=distance;
  meter.moves++;
}
function trialShot(u,t,w) {
  if(!meter) return;
  if(meter.unit===u) meter.shot=true;
  const fire={acts:meter.acts,round:B.round,side:u.side,wing:!!u.isSq};
  meter.any??=fire;
  if(!u.isSq) meter.first??=fire;
  if(!u.isSq&&!t.isSq) meter.capitalContact??=fire;
  if(t===meter.objective) meter.targetFirst??=fire;
  if(w.k==='torp'){ meter.torpShots++; meter.torpRange+=hdist(u,t); }
}
const trialApi={
  HULLS, W, FACTIONS, SECTOR_POOL, ENCOUNTERS, ENC_ARENA, ADMIRALS, MODULES, DIRS, BW, BH,
  newShip, derive, rndSeed, genEnemyFleet, startBattle, alive, caps, boardBounds, boardHexes,
  hdist, hkey, blocks, inReach, onBoard, objZone, hexLine, ramInfo, canFire, startSideTurn,
  swarmPhase, botUnit, aiUnit, aiPickActivation, roundStart,
  getB:()=>B, setRUN:value=>{RUN=value;UID=0;}, meter:value=>{meter=value;}, stats:STATS
};`;

// Keep the random input draw paired when the candidate pool changes. Separate
// channels keep map, shape, fleets and the battle seed independent of each other.
function draw(seed, channel) {
  let x = (seed ^ Math.imul(channel, 0x9e3779b9)) >>> 0;
  x = Math.imul(x ^ x >>> 16, 0x21f0aaad);
  x = Math.imul(x ^ x >>> 15, 0x735a2d97);
  return ((x ^ x >>> 15) >>> 0) / 2**32;
}

function pick(list, fraction) { return list[Math.floor(fraction * list.length)]; }

function setupBattle(H, cell, seed) {
  const boss = cell.enc.startsWith('boss');
  const enc = boss ? cell.enc.split('_')[1] : cell.enc;
  const sector = boss ? Number(cell.enc[4]) : cell.sector ?? (cell.group === 'faction' ? 1 : 2);
  const factionPool = H.SECTOR_POOL[sector - 1];
  const channel = 8 * encounters.indexOf(cell.enc);
  const ef = boss ? pick(factionPool, draw(seed, channel + 3)) : cell.ef;
  const p = fleets[cell.pf];
  const e = fleets[ef];
  const cp = ids => ids.reduce((sum, id) => sum + H.HULLS[id].cp, 0);
  assert.equal(cp(p), 16);
  assert.equal(cp(e), 16);

  H.rndSeed(seed);
  const run = {
    fac: cell.pf, admiral: cell.group === 'faction' ? null : 'vex', sector, cpCap: 40,
    relics: [], boons: [], inventory: [], patrons: [], fleet: [], fallen: [],
    stats: {battles: 0, elites: 0, bosses: 0, kills: 0},
  };
  H.setRUN(run);
  run.fleet = p.map(id => H.newShip(id, true));
  run.flagUid = run.fleet[0].uid;

  const map = enc === 'defend' ? 'station' : pick(maps, draw(seed, channel + 1));
  const current = H.ENCOUNTERS[enc].shapes;
  const base = boss ? ['ring', 'open', 'hourglass'].filter(shape => current.includes(shape)) : current;
  const weights = base.filter(shape => shape !== 'deadstar' || sector > 1 && ['storm', 'graveyard'].includes(map));
  const pool = weights.slice();
  if (cell.setup !== 'today') {
    const standard = name => { while (pool.filter(shape => shape === name).length < 2) pool.push(name); };
    standard('hourglass');
    if (enc === 'rout') standard('corridor');
    if (map === 'belt' || map === 'graveyard') pool.push('archipelago', 'archipelago');
  }
  const shape = pick(pool, draw(seed, channel + 2));
  // Explicitly requested strip-only features need the strip; approachDeploy
  // otherwise substitutes a different shape on the round and square fields.
  const arena = cell.setup !== 'today' && ['hourglass', 'corridor'].includes(shape) ? 'strip' : undefined;
  const config = {
    kind: boss ? 'boss' : 'battle', fac: ef, col: boss ? 6 : 3,
    obj: enc, map, shape, arena, seed, noStar: sector === 1,
    dep: boss ? 'line' : pick(['line', 'line', 'flank'], draw(seed, channel + 4)),
    trialPlacement: ['placement', 'all'].includes(cell.setup) ||
      (['hunt_placement', 'hunt_all'].includes(cell.setup) && enc === 'hunt') ||
      (cell.setup === 'recommended' && (boss || ['hunt', 'ambush'].includes(enc))),
    trialTempo: ['tempo', 'all', 'hunt_all', 'recommended'].includes(cell.setup),
    huntTuning: cell.huntTuning ?? (followups.includes(cell.setup) ? huntSettings[0] : null),
  };
  if (boss) {
    if (!cell.generateBossInBattle) config.trialEnemies = H.genEnemyFleet(ef, sector, config.col, 'boss');
  } else config.enemies = e.map(tpl => ({tpl}));
  H.startBattle(config);
  const B = H.getB();
  B.alt = true;
  for (const u of B.units) u.activated = false;
  return {B, config, ef, run};
}

function deployment(H) {
  const B = H.getB();
  const player = H.caps('player');
  const enemy = H.caps('enemy').filter(u => !u.transport);
  const cells = H.boardHexes();
  const target = B.units.find(u => u.side === 'enemy' && (u.flagship || u.t.boss));
  const gap = (units, goals) => Math.min(...units.flatMap(u => goals.map(g => H.hdist(u, g))));
  const exit = cells.filter(h => ['exit', 'texit'].includes(H.objZone(h.q, h.r)));
  const station = B.obj.type === 'defend';
  const radius = station ? B.map.stationR + 1 : 1;
  const zone = B.obj.hex ? cells.filter(h => H.hdist(h, B.obj.hex) <= radius && !H.blocks(B.terrain[H.hkey(h.q,h.r)])) : [];
  const transports = B.units.filter(u => u.transport);
  const goals = zone.length ? zone : B.obj.type === 'break' ? exit : transports.length ? transports : target ? [target] : enemy;
  const gun = (a, b) => a.some(u => u.weapons.some(w => w.k !== 'flak' && b.some(t => H.canFire(u, w, t))));
  const nearest = (p, e) => e.filter(u => H.hdist(p, u) === Math.min(...e.map(v => H.hdist(p, v))));
  const screened = target && enemy.length > 1 ? nearest(target, player).some(p =>
    enemy.some(u => u !== target && H.hdist(p, u) < H.hdist(p, target) && H.hdist(target, u) <= 6)) : null;
  const screenDistances = B.units.filter(u => u.trialScreen).map(u => H.hdist(u, target));
  const home = B.trialExitHex ? [B.trialExitHex] : [];
  const screenOrientation = B.obj.type === 'break' ? enemy.filter(u => u.q + Math.floor(u.r / 2) < 10).map(u => u.facing) : [];
  const metrics = {
    line_gap: gap(player, enemy), objective_gap: gap(player, goals),
    enemy_objective_gap: zone.length ? gap(enemy, zone) : null,
    escort_gap: transports.length ? gap(transports, enemy) : null,
    transport_exit_gap: transports.length ? gap(transports, exit) : null,
    player_open_shot: Number(gun(player, enemy.concat(transports))), enemy_open_shot: Number(gun(enemy, player)),
    screened: screened === null ? null : Number(screened),
    hunt_screen_min: screenDistances.length ? Math.min(...screenDistances) : null,
    hunt_screen_max: screenDistances.length ? Math.max(...screenDistances) : null,
    rear_facing_player: screenOrientation.length ? Number(screenOrientation.every(f => [5, 0, 1].includes(f))) : null,
    ambush_top: B.enc === 'ambush' ? enemy.filter(u => u.r < H.BH / 2).length : null,
    ambush_bottom: B.enc === 'ambush' ? enemy.filter(u => u.r >= H.BH / 2).length : null,
  };
  const used = new Set();
  for (const u of B.units.filter(u => !u.treeOff && !u.dead)) {
    const key = H.hkey(u.q, u.r);
    assert(H.onBoard(u.q, u.r) && !H.blocks(B.terrain[key]) && !used.has(key), `Invalid spawn ${u.name} at ${key} seed ${B.seed} ${B.enc}`);
    used.add(key);
  }
  return {metrics, target, picture: () => ({
    cells, terrain: B.terrain, shape: B.shape, map: B.map.map, arena: B.arena,
    approach: B.approach?.k ?? '', objective: B.obj.hex, exit, home, zone,
    quarryExitGap: B.trialExitHex && target ? H.hdist(target, B.trialExitHex) : null,
    initial: metrics, station: B.map.station, mapHoles: B.map.holes,
    units: B.units.filter(u => !u.treeOff && !u.dead).map(u => ({
      q:u.q, r:u.r, f:u.facing, side:u.side, hull:u.tpl, name:u.name, wing:!!u.isSq,
      target:u===target, screen:!!u.trialScreen, transport:!!u.transport,
    })),
  })};
}

async function fight(H, cell, seed, drawPicture = false) {
  const {B, config, ef} = setupBattle(H, cell, seed);
  const {metrics, target, picture} = deployment(H);
  if (drawPicture) return {seed, setup: cell.setup, encounter: cell.enc, ...picture()};
  const quarry = cell.huntFixture && target && {
    hunt_fixture: cell.huntFixture, quarry_hull: target.tpl, quarry_max_hp: target.maxHp, quarry_speed: target.speed,
  };
  const m = {unit:null, acts:0, moves:0, distance:0, first:null, any:null, targetFirst:null,
    objective:target, torpShots:0, torpRange:0};
  const stat0 = {...H.stats};
  H.meter(m);
  let moving = 0, moveOnly = 0, movingAndFiring = 0, post = 0, postMoving = 0;
  const activate = async (u, play) => {
    m.unit = u;
    m.shot = m.other = false;
    const distance = m.distance;
    const rams = H.stats.rams;
    const boards = H.stats.boards;
    const afterContact = !!m.first;
    await play(u);
    const moved = m.distance > distance;
    moving += Number(moved);
    movingAndFiring += Number(moved && m.shot);
    moveOnly += Number(moved && !m.shot && !m.other && rams === H.stats.rams && boards === H.stats.boards);
    post += Number(afterContact);
    postMoving += Number(afterContact && moved);
    m.acts++;
    u.activated = true;
    m.unit = null;
  };

  await H.startSideTurn('enemy');
  while (!B.over && B.round <= 30) {
    await H.swarmPhase('player');
    await H.swarmPhase('enemy');
    let guard = 0;
    while (!B.over) {
      assert(++guard < 100, `Activation loop did not terminate, seed ${seed}`);
      const p = H.alive('player').find(u => !u.isSq && !u.activated);
      const e = () => H.alive('enemy').filter(u => !u.isSq && !u.activated);
      if (!p && !e().length) break;
      if (p) await activate(p, H.botUnit);
      if (!B.over) {
        const ready = e();
        if (ready.length) await activate(H.aiPickActivation(ready), H.aiUnit);
      }
    }
    if (B.over || B.round === 30) break;
    B.round++;
    for (const u of B.units) u.activated = false;
    await H.roundStart();
  }
  H.meter(null);
  const factionStat = key => Object.values(B.fstat || {}).reduce((sum, f) => sum + (f[key] || 0), 0);
  return {
    group: cell.group, encounter: cell.enc, setup: cell.setup, seed, sector: B.sector,
    player_faction: cell.pf, enemy_faction: ef, player_cp: B.cp0.player, enemy_cp: B.cp0.enemy,
    requested_map: config.map, map: B.map.map, requested_shape: config.shape, shape: B.shape, arena: B.arena,
    approach: B.approach?.k ?? '', deployment: B.deployMode, board_hexes: H.boardHexes().length, ...metrics,
    first_shot_act: m.first?.acts, first_shot_round: m.first?.round, first_shot_side: m.first?.side,
    first_any_act: m.any?.acts, first_any_round: m.any?.round, first_any_is_wing: m.any ? Number(m.any.wing) : null,
    first_target_shot_act: m.targetFirst?.acts, first_target_shot_round: m.targetFirst?.round,
    rounds: B.round, acts: m.acts, moving, move_only: moveOnly, moving_and_firing: movingAndFiring,
    move_actions: m.moves, move_hexes: m.distance, post_acts: post, post_moving: postMoving,
    torp_shots: m.torpShots, torp_range_sum: m.torpRange, torp_launches: factionStat('torpLaunch'), torp_hits: factionStat('torpHit'),
    torp_dodges: factionStat('torpDodge'), rams: H.stats.rams - stat0.rams,
    win: Number(B.over === 'win'), full_win: Number(B.over === 'win' && !B.partial),
    escaped: B.obj.type === 'hunt' ? Number(!!B.obj.escaped) : null,
    quarry_kill: B.obj.type === 'hunt' ? Number(!!target.dead && !target.fled) : null,
    timeout: Number(!B.over), result: B.over || 'timeout',
    ...(cell.huntTuning && {capital_contact_round: m.capitalContact?.round}),
    ...quarry,
  };
}

function cell(group, enc, setup, pf = 'hegemony', ef = 'hegemony') { return {group, enc, setup, pf, ef}; }

function options() {
  const input = process.argv.slice(2);
  const options = { mode: input.shift(), rules: 'frozen', sims: 100, seed: 1000,
    jobs: Math.min(8, os.availableParallelism()) };
  for (let i = 0; i < input.length; i += 2) {
    const key = input[i].slice(2);
    assert(['out','jobs','sims','seed','enc','setup','input','rules','revision','hunt-fixture'].includes(key) &&
      input[i + 1], `Bad option ${input[i]}`);
    options[key === 'hunt-fixture' ? 'huntFixture' : key] =
      ['jobs','sims','seed'].includes(key) ? Number(input[i + 1]) : input[i + 1];
  }
  for (const key of ['jobs','sims','seed']) assert(Number.isSafeInteger(options[key]) && options[key] > 0);
  assert(['frozen', 'current'].includes(options.rules), 'Choose --rules frozen or current');
  assert(!options.revision || options.rules === 'current' && /^[a-f0-9]{40}$/.test(options.revision),
    '--revision requires current mode and a full commit SHA');
  options.revision = options.rules === 'frozen' ? sources.frozen : options.revision || git('rev-parse', 'origin/main').trim();
  return options;
}

function tasks(opt) {
  if (opt.mode === 'encounters' || opt.mode === 'smoke') {
    const selected = opt.setup ? opt.setup.split(',') : setups;
    assert(selected.every(setup => [...setups, ...followups].includes(setup)), 'Unknown encounter setup');
    return encounters.filter(enc => !opt.enc || opt.enc.split(',').includes(enc)).flatMap(enc =>
      selected.filter(setup => !setup.startsWith('hunt_') || enc === 'hunt').map(setup => cell('encounter', enc, setup)));
  }
  if (opt.mode === 'hunt-sweep') {
    const candidates = opt.input ? JSON.parse(fs.readFileSync(opt.input, 'utf8')) : huntSettings;
    if (opt.huntFixture) {
      const fixtures = opt.huntFixture.split(',');
      assert(fixtures.every(fixture => ['sector2', 'sector1-mirror', 'sector1-mix'].includes(fixture)),
        'Unknown Hunt fixture');
      return candidates.flatMap(huntTuning => fixtures.flatMap(huntFixture => {
        const base = {huntTuning, huntFixture};
        if (huntFixture === 'sector1-mix') return factions.flatMap(pf => factions.map(ef => ({
          ...cell('faction', 'hunt', 'recommended', pf, ef), ...base,
        })));
        return [{...cell('encounter', 'hunt', 'recommended'), ...base,
          sector:huntFixture === 'sector1-mirror' ? 1 : 2}];
      }));
    }
    return candidates.flatMap(tuning => ['hunt_placement', 'hunt_all'].map(setup => ({
      ...cell('encounter', 'hunt', setup), huntTuning: tuning,
    })));
  }
  assert.equal(opt.mode, 'factions');
  const selected = opt.setup ? opt.setup.split(',') : ['today', 'all', 'tempo', 'recommended'];
  assert(selected.every(setup => ['today', 'all', 'tempo', 'recommended'].includes(setup)), 'Unknown faction setup');
  return factions.flatMap(pf => factions.flatMap(ef => selected
    .map(setup => cell('faction', 'mix', setup, pf, ef))));
}

async function runTask(H, task, opt) {
  const rows = [];
  const filter = task.huntFixture ? 'hunt' : opt.enc;
  for (let i = 0; i < opt.sims; i++) {
    // Keep the Hunt seeds from the original eight-encounter faction rotation.
    const enc = task.group === 'faction' ? ordinary[i % ordinary.length] : task.enc;
    if (task.group === 'faction' && filter && enc !== filter) continue;
    const row = await fight(H, {...task, enc}, opt.seed + i);
    rows.push(opt.mode === 'hunt-sweep' ? {...row, ...task.huntTuning} : row);
  }
  return rows;
}

function workerPool(list, opt) {
  const results = new Array(list.length);
  let next = 0;
  let done = 0;
  return new Promise((resolve, reject) => {
    for (let j = 0; j < Math.min(opt.jobs, list.length); j++) {
      const worker = new Worker(__filename, {workerData:opt});
      const send = () => {
        if (next >= list.length) { worker.postMessage(null); return; }
        const index = next++;
        worker.postMessage({index, task:list[index]});
      };
      worker.on('error', reject);
      worker.on('exit', code => { if (code) reject(Error(`Worker exit ${code}`)); });
      worker.on('message', ({index, rows}) => {
        results[index] = rows;
        const task = list[index];
        console.log(`[${++done}/${list.length}] ${task.enc} ${task.setup} ${task.pf}/${task.ef} (${rows.length})`);
        if (done === list.length) resolve(results.flat());
        send();
      });
      send();
    }
  });
}

function csv(rows) {
  assert(rows.length, 'No rows matched the simulation options');
  const keys = [...new Set(rows.flatMap(Object.keys))];
  const record = row => keys.map(k => row[k] ?? '').join(',');
  return [keys.join(','), ...rows.map(record)].join('\n') + '\n';
}

async function main() {
  const opt = options();
  console.error(`Rules: ${opt.rules} (${opt.revision})`);
  if (opt.mode === 'stats') {
    const H = harness(opt);
    console.log(JSON.stringify({hulls:H.HULLS, weapons:H.W, admirals:H.ADMIRALS, modules:H.MODULES}, null, 2));
    return;
  }
  if (opt.mode === 'pictures') {
    const H = harness(opt);
    const chosen = JSON.parse(fs.readFileSync(opt.input, 'utf8'));
    const selected = Object.entries(chosen).filter(([enc]) => !opt.enc || opt.enc.split(',').includes(enc));
    const after = opt.setup || 'all';
    assert(selected.length && [...setups, ...followups].includes(after), 'Choose a picture encounter and valid setup');
    const pictures = {};
    for (const [enc, seed] of selected) {
      pictures[enc] = await Promise.all(['today', after].map(setup => fight(H, cell('encounter', enc, setup), seed, true)));
    }
    fs.writeFileSync(opt.out, JSON.stringify(pictures));
    return;
  }
  const list = tasks(opt);
  assert(list.length && opt.out, 'Provide --out for a non-empty simulation');
  assert(!fs.existsSync(opt.out), `Output already exists: ${opt.out}`);
  const rows = await workerPool(list, opt);
  fs.writeFileSync(opt.out, csv(rows), {flag:'wx'});
  console.log(`${rows.length} rows, ${rows.filter(r => r.timeout).length} reached the round cap`);
}

if (require.main === module && isMainThread) main().catch(error => { console.error(error); process.exit(1); });
if (require.main === module && !isMainThread) {
  const H = harness(workerData);
  parentPort.on('message', async msg => {
    if (!msg) { parentPort.close(); return; }
    parentPort.postMessage({index:msg.index, rows:await runTask(H, msg.task, workerData)});
  });
}

module.exports = { harness, setupBattle, encounters, sources, huntSettings };
