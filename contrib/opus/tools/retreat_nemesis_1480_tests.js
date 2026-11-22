// Issue 1480 (R381, R384; RULEBOOK 11.8 and 11.11), browser twin: a retreat sends the fleet back to the stop it came from with
// the fight kept, a retreat is not the Nemesis meeting, a Nemesis-held service stop survives a retreat, and the revived
// Eclipse rival's last fight is the Sector 3 boss battle. Fixture: godot/campaign/test/fixtures/issue_1480/retreat_nemesis.json
// (the Godot twin reads the same file in godot/campaign/test/retreat_nemesis_1480.gd). Run from the repo root.
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { this.children.push(c); return c; }, remove() {}, querySelector() { return null; }, querySelectorAll() { return []; },
  addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: () => el(), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
const FX = JSON.parse(fs.readFileSync(path.join(ROOT, 'godot/campaign/test/fixtures/issue_1480/retreat_nemesis.json'), 'utf8'));
let pass = 0, fail = 0;
function check(name, fn) { try { const r = fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
eval(src + `
function log(){} function tel(){} function toast(){} function saveRun(){} function modal(){} function closeModal(){} function show(){}
global.T = { get RUN(){ return RUN; }, newRun, rndSeed, retreatBack: typeof retreatBack === 'function' ? retreatBack : null, nemNodeIs, nemNodeTag, ensureNemesis, nemClockAdd, get NEM_CLOCK(){ return NEM_CLOCK; }, nemAfterBattle, availableNodes, findNode };
`);
function fresh() { T.rndSeed(FX.seed); T.newRun(FX.admiral, FX.fac, {}); const all = [].concat(...T.RUN.map.cols); all.forEach((n, i) => { n.seed = 1000 + i; }); return all; }
// the first node of column c reached by an edge from the first node of column c-1 (the path a player would have walked)
function walk(col) { const cols = T.RUN.map.cols; let prev = null, cur = cols[0][0];
  for (let c = 1; c <= col; c++) { prev = cur; const to = T.RUN.map.edges.find(e => e[0] === prev.id); cur = T.findNode(to[1]); }
  for (let c = 0, p = cols[0][0]; p && p !== cur; c++) { p.done = true; const to = T.RUN.map.edges.find(e => e[0] === p.id); p = to ? T.findNode(to[1]) : null; }
  return { prev, cur }; }
function leave(n) { T.RUN.pos = n.id; T.RUN.curNode = n.id; if (!T.retreatBack) throw new Error('no retreatBack (main)'); T.retreatBack(); }
for (const cs of FX.cases) {
  fresh();
  if (cs.kind === 'retreat') {
    const { prev, cur } = walk(cs.col), seed = cur.seed; let ok = true;
    try { leave(cur); } catch (e) { ok = false; }
    check(cs.name + ': back on the stop it came from', () => ok && T.RUN.pos === (cs.expect.pos === 'from' ? prev.id : null) && T.RUN.curNode == null);
    check(cs.name + ': the fight stays on the map, same seed, and can be taken again', () => ok && !cur.done === !cs.expect.done && cur.seed === seed && T.availableNodes().includes(cur.id) === cs.expect.avail);
  } else if (cs.kind === 'nem_retreat') {
    const N = T.ensureNemesis(); N.met = 0; T.RUN.nemClock = 2; T.RUN.nemStrike = true;
    const out = T.nemAfterBattle('retreat', false, {});
    const c4 = T.RUN.map.cols.length - 3, n = T.RUN.map.cols[c4].find(x => x.type === 'battle' || x.type === 'elite') || T.RUN.map.cols[c4][0];
    check(cs.name + ': no meeting recorded, the clock and strike stand', () => N.met === cs.expect.met && T.RUN.nemClock === cs.expect.nemClock && !!T.RUN.nemStrike === cs.expect.nemStrike && N.gloat === cs.expect.gloat && out.length === 1);
    check(cs.name + ': his stops are still his', () => T.nemNodeIs(n) === cs.expect.stillHis);
  } else if (cs.kind === 'nem_stop_retreat') {
    const N = T.ensureNemesis(); N.met = 0; const c4 = T.RUN.map.cols.length - 3;
    const stop = T.RUN.map.cols[c4].find(x => x.type !== 'battle' && x.type !== 'elite') || T.RUN.map.cols[c4][0];
    const prevEdge = T.RUN.map.edges.find(e => e[1] === stop.id), prev = T.findNode(prevEdge[0]); prev.done = true;
    let ok = true; try { leave(stop); T.nemAfterBattle('retreat', false, {}); } catch (e) { ok = false; }
    check(cs.name + ': the stop is not used up and is still his', () => ok && !stop.done === !cs.expect.done && T.nemNodeIs(stop) === cs.expect.stillHis);
    check(cs.name + ': it can be taken again from where the fleet stands', () => ok && T.RUN.pos === prev.id && T.availableNodes().includes(stop.id) === cs.expect.avail);
  } else if (cs.kind === 'eclipse_boss') {
    T.RUN.sector = 3; const N = T.ensureNemesis(); N.fac = 'deathless'; N.revived = cs.revived; N.dead = false; N.met = cs.revived ? 2 : 3;
    const boss = [].concat(...T.RUN.map.cols).find(x => x.type === 'boss');
    check(cs.name, () => T.nemNodeIs(boss) === cs.expect.boss && T.nemNodeTag(boss) === cs.expect.tag);
  } else if (cs.kind === 'eclipse_wait') {
    // the revive put met back a sector: no late fight, strike or full clock may take the meeting before the boss
    T.RUN.sector = 3; const N = T.ensureNemesis(); N.fac = 'deathless'; N.revived = true; N.dead = false; N.met = 2; T.RUN.nemStrike = false; T.RUN.nemClock = 0;
    const all = [].concat(...T.RUN.map.cols), c4 = T.RUN.map.cols.length - 3;
    const late = all.find(x => x.col >= c4 && (x.type === 'battle' || x.type === 'elite')), early = all.find(x => x.col < c4 && x.type === 'battle');
    const boss = all.find(x => x.type === 'boss');
    check(cs.name + ': a late fight is not his', () => !!late && T.nemNodeIs(late) === cs.expect.lateFight);
    T.RUN.nemStrike = true;
    check(cs.name + ': an old strike does not make an early fight his', () => !!early && T.nemNodeIs(early) === cs.expect.strikeFight);
    T.RUN.nemStrike = false; T.nemClockAdd(T.NEM_CLOCK);
    check(cs.name + ': a full clock does not set a strike', () => !!T.RUN.nemStrike === cs.expect.clockStrike);
    check(cs.name + ': the boss battle is his', () => T.nemNodeIs(boss) === cs.expect.boss);
  }
}
console.log(pass + ' ok, ' + fail + ' failed'); if (fail) process.exitCode = 1;
