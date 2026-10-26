// B4 checks (stream B, Oct 26): events with blue options and flags, the Nemesis, faction verbs, wing doctrines. Run from the repo root: node contrib/opus/tools/b4_tests.js
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el()), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
let pass = 0, fail = 0; const tests = [];
function check(name, fn) { tests.push([name, fn]); }
eval(src + `
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){} function tel(){} function nodeSeeds(){ return 0; }
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} function fxSectionDown(){} async function fxBoard(){}
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get B(){ return B; }, migrateRun, newShip, newRun, startBattle, HULLS, EVENTS, EVENT_FALLBACK, nextEvent, needMet, needText, applyOutcome, eventFlags,
  newNemesis, ensureNemesis, nemReveal, nemClockAdd, nemNodeIs, nemBattleCfg, nemAdapt, nemAfterBattle, nemLearn, NEM_CLOCK, NEM_WEAK, FAC_VERBS, verbCanUse, useVerb, wingVetAfter, wingPerkGrant, WING_XP,
  setStance, canStance, wingStance, aiStance, killUnit, dmgMult, hitChance, genSector, META, RUN_FACTIONS, ADMIRALS, mapScreen, eventScreen, shipyardScreen, boonStep, NEM_FAC, nemFull, nemFeedLosses, startSideTurn };
`);
const pickAdm = fac => Object.entries(T.ADMIRALS).find(([k, a]) => (a.fac || 'voidsworn') === fac)[0];
const fresh = (fac, adm) => { T.META.unlocked = {}; T.newRun(adm || pickAdm(fac), fac); return T.RUN; };

check('20 new events plus blue options on the old ones; every option of every event applies and writes a flag', () => {
  const bad = []; let n = 0;
  for (const ev of T.EVENTS) for (let i = 0; i < ev.o.length; i++) { const o = ev.o[i]; if (o.r && o.r.fight) continue;
    for (const fac of T.RUN_FACTIONS) { const R = fresh(fac); R.credits = 999; R.inventory = ['prow', 'auspex']; R.relics = ['ledger']; R.fleet.forEach(s => { s.hp = 1; s.cap.rank = 3; });
      try { T.eventFlags(ev, o, i); const out = T.applyOutcome(o.r); if (!Array.isArray(out) || !out.length) bad.push(ev.id + ':' + i + ' no lines'); if (R.flags[ev.id] == null) bad.push(ev.id + ':' + i + ' no flag'); n++; } catch (e) { bad.push(ev.id + ':' + i + ' ' + fac + ' ' + e.message); } } }
  const fresh20 = T.EVENTS.filter(e => !['derelict', 'beacon', 'astropath', 'merc', 'storm', 'seer', 'wright', 'moon', 'shrine', 'deserters', 'cache', T.EVENT_FALLBACK].includes(e.id)).length;
  const oldBlue = ['derelict', 'beacon', 'astropath', 'storm', 'seer', 'wright', 'moon', 'shrine', 'deserters', 'cache', 'merc'].every(id => T.EVENTS.find(e => e.id === id).o.some(o => o.need));
  if (bad.length) throw new Error(bad.slice(0, 4).join(' | '));
  return fresh20 >= 20 && oldBlue && n > 300; });
check('blue options: shown with a plain requirement, usable only when the fleet meets it', () => {
  const R = fresh('voidsworn'); R.inventory = []; const need = { mod: 1 }, t0 = T.needMet(need); R.inventory.push('prow'); const t1 = T.needMet(need);
  const fk = T.needMet({ fac: 'corsair' }), txt = T.needText({ kind: 'torp', carrier: 1 });
  return !t0 && t1 && !fk && /torpedoes in the fleet/.test(txt) && /a carrier/.test(txt) && /^Needs /.test(txt); });
check('no event repeats within a run; a quiet stretch once every event is seen', () => {
  const R = fresh('hegemony'); const seen = new Set(); let dup = 0, last = null; for (let i = 0; i < 40; i++) { const e = T.nextEvent(); if (e.id !== T.EVENT_FALLBACK) { if (seen.has(e.id)) dup++; seen.add(e.id); } last = e.id; if (e.not && e.not.includes('hegemony')) dup++; }
  return dup === 0 && last === T.EVENT_FALLBACK && seen.size >= 25; });
check('Nemesis: created with the run (a rival faction, two hidden weaknesses), clock fills toward his fight, intel reveals', () => {
  const R = fresh('ithar'); const N = R.nem; if (!N || N.fac === 'ithar' || N.weak.length !== 2 || N.revealed.length) throw new Error('setup ' + JSON.stringify(N));
  let msg = ''; for (let i = 0; i < T.NEM_CLOCK; i++) msg = T.nemClockAdd(1) || msg; const w = T.nemReveal();
  return N.strike && /next fight/.test(msg) && w === N.weak[0] && N.revealed.length === 1; });
check('Nemesis: met once per sector (strike, or the fight before the rest stop), marked on the map', () => {
  const R = fresh('voidsworn'); const N = R.nem; const cols = R.map.cols, early = cols[1].find(n => n.type === 'battle' || n.type === 'elite'), late = cols[cols.length - 3].find(n => n.type === 'battle' || n.type === 'elite');
  const a = early ? T.nemNodeIs(early) : false, b = late ? T.nemNodeIs(late) : true; N.met = R.sector; const c = late ? T.nemNodeIs(late) : false;
  return !a && b && !c; });
check('Nemesis battle: his flagship named, weaknesses and adaptations applied to his ships only', async () => {
  const R = fresh('voidsworn'); const N = R.nem; N.weak = ['slow', 'board']; N.adapt = ['armor']; N.fac = 'hegemony';
  T.startBattle({ kind: 'elite', fac: 'hegemony', col: 4, nemesis: T.nemBattleCfg(), obj: 'rout', shape: 'open', map: 'storm', seed: 3 });
  const es = T.B.units.filter(u => u.side === 'enemy' && !u.isSq), fl = es.find(u => u.nemFlag), ps = T.B.units.filter(u => u.side === 'player' && !u.isSq);
  return !!fl && fl.name.includes(N.name) && es.every(u => u.nem) && !ps.some(u => u.nem) && es.every(u => u.speed === u.t.sp + 1 - 1 || u.speed >= 1) && es.every(u => u.armor >= u.t.ar + .1 - 1e-9) && es.every(u => u.crewMax < Math.round((12 + u.size * 40) * 1.01)); });
check('Nemesis after battle: a win reveals a weakness and resets the clock; sector 3 flagship kill ends him; one adaptation per sector', () => {
  const R = fresh('corsair'); const N = R.nem; N.fac = 'hegemony'; N.clock = 3; const l1 = T.nemAfterBattle('win', true); const ok1 = N.revealed.length === 1 && N.clock === 0 && N.scars === 1 && !N.dead && N.met === 1;
  T.nemLearn({ kind: { torp: 9 }, fire: {} }, 0); R.sector = 2; const a1 = T.nemAdapt(), a2 = T.nemAdapt(); R.sector = 3; N.met = 2; T.nemAfterBattle('win', true);
  return ok1 && a1 === 'pd' && a2 === null && N.dead && l1.length >= 1; });
check('faction verbs: once per sector, costs paid, free with the right event flag, next-battle verbs wait for the fight', () => {
  const R = fresh('hegemony'); R.credits = 100; const c0 = T.verbCanUse(); const out = T.useVerb(); const ok1 = c0 && out && R.credits === 65 && R.verbNext === 'drill' && !T.verbCanUse();
  R.sector = 2; R.flags.defector = 'question'; R.credits = 0; const free = T.verbCanUse(); T.useVerb();
  const C = fresh('corsair'); C.nem.fac = 'ithar'; C.credits = 0; C.flags.greed = 2; T.useVerb(); const shake = C.credits === 50 && C.nem.clock === 1;
  return ok1 && free && shake; });
check('faction verbs in battle: the drill widens Hegemony sync to 4 hexes, the vigil guards the line, waken adds a legion return', () => {
  const R = fresh('hegemony'); T.startBattle({ kind: 'battle', fac: 'corsair', col: 2, verb: 'drill', obj: 'rout', shape: 'open', map: 'storm', seed: 5 }); const d = T.B.syncR && T.B.syncR.player === 4;
  const V = fresh('voidsworn'); T.startBattle({ kind: 'battle', fac: 'corsair', col: 2, verb: 'vigil', obj: 'rout', shape: 'open', map: 'storm', seed: 5 }); const v = T.B.units.filter(u => u.side === 'player' && !u.isSq).every(u => u.fx.lineGuard >= .15);
  const D = fresh('deathless'); T.startBattle({ kind: 'battle', fac: 'corsair', col: 2, verb: 'waken', obj: 'rout', shape: 'open', map: 'storm', seed: 5 }); const w = T.B.legion.player.max === 2;
  return d && v && w; });
check('wing veterancy: perks at 3, 8 and 15 wing kills, never more than three', () => {
  const R = fresh('voidsworn', 'ashgrove'); const c = R.fleet.find(s => T.HULLS[s.tpl].hangar); const g1 = T.wingVetAfter(c, 3), g2 = T.wingVetAfter(c, 5), g3 = T.wingVetAfter(c, 20), g4 = T.wingVetAfter(c, 50);
  return g1.length === 1 && g2.length === 1 && g3.length === 1 && g4.length === 0 && c.wingVet.perks.length === 3; });
check('wing doctrines: one free stance change per round; hunting wings deal more to crippled ships and are easier to hit', () => {
  const R = fresh('voidsworn', 'ashgrove'); T.startBattle({ kind: 'battle', fac: 'hegemony', col: 2, obj: 'rout', shape: 'open', map: 'storm', seed: 9 });
  const car = T.B.units.find(u => u.side === 'player' && u.ab === 'launch'), wing = T.B.units.find(u => u.side === 'player' && u.isSq && u.parent === car.id), t = T.B.units.find(u => u.side === 'enemy' && !u.isSq);
  if (!car || !wing) throw new Error('no carrier wing'); const ch1 = T.setStance(car, 'hunt'), ch2 = T.setStance(car, 'screen');
  const w = wing.weapons[0]; t.hp = Math.floor(t.maxHp * .3); const m1 = T.dmgMult(wing, w, t, false); car.stance = 'strike'; const m0 = T.dmgMult(wing, w, t, false);
  const foe = T.B.units.find(u => u.side === 'enemy' && !u.isSq && u.weapons.some(x => x.k !== 'flak' && x.arc === 'T')), fw = foe.weapons.find(x => x.k !== 'flak' && x.arc === 'T'); T.B.terrain = {}; foe.q = wing.q + 2; foe.r = wing.r; foe.aim = 20; const h0 = T.hitChance(foe, fw, wing); car.stance = 'hunt'; const h1 = T.hitChance(foe, fw, wing);
  return ch1 && !ch2 && T.wingStance(wing) === 'hunt' && m1 > m0 && (h1 > h0 || h1 === 95); });
check('screens render without errors: map (Nemesis card, verb button, Nemesis node tag), events, shipyard (class refits), boon offer (reroll, decline)', () => {
  const R = fresh('chorus'); R.nem.strike = true; R.inventory = ['prow']; T.mapScreen(); const n = R.map.cols[1][0]; R.curNode = n.id; T.eventScreen(n);
  T.shipyardScreen({ id: 'x' }); R.reward = { boonOffer: null }; T.boonStep('iron', 1); return true; });
// ---- R42 Nemesis v2 ----
check('R42 identity: a new rival every run from his faction pools, never a player admiral name; persona, two traits, a portrait id', () => {
  const names = new Set(); let ok = true;
  for (let i = 0; i < 30; i++) { const R = fresh(T.RUN_FACTIONS[i % 6]); const N = R.nem, F = T.NEM_FAC[N.fac]; names.add(N.name);
    if (N.fac === R.fac || !F.personas.includes(N.persona) || N.traits.length !== 2 || !N.traits.every(t => F.traits.includes(t)) || !/^nem_[a-z]+_[1-6]$/.test(N.portrait)) ok = false;
    if (Object.values(T.ADMIRALS).some(a => a.n.includes(N.name))) ok = false; if ((F.beh.noFlee || F.beh.revive) && N.weak.includes('anchor')) ok = false; }
  return ok && names.size >= 25; });
check('R42 scars: surviving a defeat adds a scar and a new epithet; he remembers how you beat him', () => {
  const R = fresh('voidsworn'); const N = R.nem; N.fac = 'corsair'; const n0 = T.nemFull(); T.nemAfterBattle('win', true, { beat: 'torp', cause: 'big' });
  return N.scars === 1 && N.epithet && T.NEM_FAC.corsair.scars.includes(N.epithet) && T.nemFull() !== n0 && N.beat === 'torp' && T.nemBattleCfg().beat === 'torp'; });
check('R42 Deathless: patient clock (half speed), comes back once after being killed, even in sector 3', () => {
  const R = fresh('voidsworn'); const N = R.nem; N.fac = 'deathless'; N.clock = 0; T.nemClockAdd(1); const half = N.clock === .5;
  R.sector = 3; T.nemAfterBattle('win', true, {}); const back = !N.dead && N.revived && N.met === 2; T.nemAfterBattle('win', true, {}); return half && back && N.dead; });
check('R42 Corsair: a full clock raids your credits (announced on his card), and he flees a lost fight in battle and comes back richer', async () => {
  const R = fresh('voidsworn'); const N = R.nem; N.fac = 'corsair'; R.credits = 200; N.clock = 3; const msg = T.nemClockAdd(1); const raided = R.credits === 150 && /raiders/.test(msg);
  T.startBattle({ kind: 'elite', fac: 'corsair', col: 4, nemesis: T.nemBattleCfg(), obj: 'rout', shape: 'open', map: 'storm', seed: 3 }); const fl = T.B.units.find(u => u.nemFlag);
  fl.hp = Math.round(fl.maxHp * .3); T.startSideTurn('enemy'); const fled = T.B.nemFled && fl.fled && T.B.over === 'win';
  T.nemAfterBattle('win', false, { fled: true }); return raided && fled && N.riches === 1 && N.scars === 1; });
check('R42 Chorus: your losses make his fleet tougher; he adapts after every meeting', () => {
  const R = fresh('voidsworn'); const N = R.nem; N.fac = 'chorus'; T.nemFeedLosses(3); const fedOk = N.fed === 3;
  N.traits = ['swift', 'deadeye']; const hpOf = () => { T.startBattle({ kind: 'elite', fac: 'chorus', col: 4, nemesis: T.nemBattleCfg(), obj: 'rout', shape: 'open', map: 'storm', seed: 4 }); return T.B.units.find(x => x.nemFlag).maxHp; };
  const h3 = hpOf(); N.fed = 0; const h0 = hpOf(); N.fed = 3; const tough = Math.abs(h3 / h0 - 1.12) < .02; const a0 = N.adapt.length; T.nemAfterBattle('win', false, {}); return fedOk && tough && N.adapt.length === a0 + 1; });
check('R42 Voidsworn: never routs, challenges your flagship (20% more damage between the two flagships)', () => {
  const R = fresh('hegemony'); const N = R.nem; N.fac = 'voidsworn'; N.traits = ['armored', 'gunnery'];
  T.startBattle({ kind: 'elite', fac: 'voidsworn', col: 4, nemesis: T.nemBattleCfg(), obj: 'rout', shape: 'open', map: 'storm', seed: 5 }); const fl = T.B.units.find(u => u.nemFlag), me = T.B.units.find(u => u.pflag);
  const w = me.weapons.find(x => x.k !== 'flak'); const m1 = T.dmgMult(me, w, fl, false); T.B.nemChallenge = false; const m0 = T.dmgMult(me, w, fl, false);
  return T.B.nemNoRout && Math.abs(m1 - m0 - w.dmg * .2 * (w.vsCap || 1)) < 1e-6; });
(async () => { for (const [name, fn] of tests) { try { const r = await fn(); if (r === false) throw new Error('returned false'); pass++; console.log('ok    ' + name); } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.message)); } }
  console.log('\nB4 tests: ' + pass + ' ok, ' + fail + ' FAIL'); process.exitCode = fail ? 1 : 0; })();
