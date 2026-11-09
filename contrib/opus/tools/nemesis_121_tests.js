// Issue #121 (Nemesis redesign 2): meetings, the run clock, adaptation and lessons per commander, and NEM_VOICE.
// Proves the #201 check pack for issue 121 (contrib/muse/reviews/nemesis_checks_2026_11/legs/rey_blind.md as amended by synthesis.md
// section 3) on the live browser code. The Godot twin is proven by the same flows in godot/campaign/test/nem_scenarios.gd (section 15
// onward, compared line by line with node/nem_scenarios.js) and by the per-commander clash fixtures (nemesis_clash_tests.js).
//   node contrib/opus/tools/nemesis_121_tests.js
'use strict';
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el()), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
let pass = 0, fail = 0; const tests = [];
function check(name, fn) { tests.push([name, fn]); }
eval(src + `
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){} function tel(){} function nodeSeeds(){ return 0; }
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} function fxSectionDown(){} async function fxBoard(){}
var MODAL=''; modal=function(h){ MODAL=h; }; show=function(){}; toast=function(){};
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get B(){ return B; }, get MODAL(){ return MODAL; }, migrateRun, newRun, startBattle, rndSeed, META, ADMIRALS,
  nemActive, ensureNemesis, nemClockAdd, nemNodeIs, nemBattleCfg, nemAdapt, nemAfterBattle, nemLearn, nemSay, nemFull, nemPanel, nemFeedLosses, nemOpenLine, nemAdaptLine,
  nemStrikeLine, nemAdaptWhyLine,
  afterBattle, NEM_CLOCK, NEM_WEAK, NEM_FAC, NEM_VOICE, NEM_LINES, NEM_BEAT_WORD, NEM_BEAT_COUNTER, NEM_ADAPT_FAC, W:window };
`);
const pickAdm = fac => Object.entries(T.ADMIRALS).find(([k, a]) => (a.fac || 'voidsworn') === fac)[0];
const canon = v => JSON.stringify(v, (k, x) => (x && typeof x === 'object' && !Array.isArray(x) ? Object.keys(x).sort().reduce((o, q) => (o[q] = x[q], o), {}) : x));
// a run with a forced assignment; the player's faction is one no hunter uses
function forced(assign, player) {
  const fac = player || ['voidsworn', 'hegemony', 'corsair', 'ithar', 'chorus', 'deathless'].find(f => !assign.includes(f));
  T.rndSeed(4242); T.META.unlocked = {}; T.newRun(pickAdm(fac), fac); const R = T.RUN;
  R.nemAssign = assign.slice(); R.nems = {}; R.nem = null; R.nemClock = 0; R.nemStrike = false; R.sector = 1; T.nemActive(); return R;
}
const nodes = R => R.map.cols.flat().filter(n => n.type === 'battle' || n.type === 'elite');
const lateNode = R => nodes(R).find(n => n.col >= R.map.cols.length - 3);
const earlyNode = R => nodes(R).find(n => n.col < R.map.cols.length - 3);
const noClockOnCommanders = R => Object.values(R.nems).every(N => !('clock' in N) && !('strike' in N));

// 121-1: the meeting targets the active commander (RUN.nemAssign[RUN.sector - 1])
check('121-1 the meeting targets the active commander, sector by sector', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const late = lateNode(R);
  const s1 = T.nemNodeIs(late) && T.nemBattleCfg().fac === 'hegemony'; T.nemAfterBattle('win', false, {});
  R.sector = 2; const s2 = T.nemNodeIs(late) && T.nemBattleCfg().fac === 'corsair';
  return s1 && s2; });
// 121-2: once per sector per commander, the return case, and the negative control on the snapshot's derived met
check('121-2 once per sector per commander; the returning SP1 commander is met again in sector 3; the snapshot met is not the flag', () => {
  const R = forced(['hegemony', 'corsair', 'hegemony']); const late = lateNode(R);
  const before = T.nemNodeIs(late); T.nemAfterBattle('win', false, {}); const A = R.nems.hegemony;
  const met1 = A.met === 1 && nodes(R).every(n => !T.nemNodeIs(n));
  R.sector = 2; T.nemActive(); T.nemAfterBattle('win', false, {});
  R.sector = 3; const N3 = T.nemActive(); const same = N3 === A && Object.keys(R.nems).length === 2;
  const derived = T.nemBattleCfg().met === true; // beaten 1: the snapshot says "has ever met"
  const again = T.nemNodeIs(late); T.nemAfterBattle('win', false, {}); const met3 = A.met === 3 && nodes(R).every(n => !T.nemNodeIs(n));
  return before && met1 && same && derived && again && met3; });
// 121-3: one run clock, paced by the active commander, exact half steps; no commander holds a clock
function clockRun(fac, player) {
  const R = forced([fac, fac, fac], player); R.fleet.forEach(s => { s.hp = 9999; }); const seq = []; let strikeAt = 0;
  for (let i = 1; i <= 8 && !strikeAt; i++) { T.nemClockAdd(1); seq.push(R.nemClock); if (R.nemStrike) strikeAt = i; }
  return { seq, strikeAt, ok: noClockOnCommanders(R) };
}
check('121-3 one run clock: Eclipse 0.5 a win (strike on the 8th), Crusade 1.5 (strike on the 3rd, clamped at 4), others 1 (strike on the 4th)', () => {
  const e = clockRun('deathless'), v = clockRun('voidsworn', 'hegemony'), h = clockRun('hegemony');
  return canon(e.seq) === canon([.5, 1, 1.5, 2, 2.5, 3, 3.5, 4]) && e.strikeAt === 8 && canon(v.seq) === canon([1.5, 3, 4]) && v.strikeAt === 3
    && canon(h.seq) === canon([1, 2, 3, 4]) && h.strikeAt === 4 && e.ok && v.ok && h.ok && T.NEM_CLOCK === 4; });
check('121-3 the clock lives on the run, carries across sectors and is paced by whoever is active now', () => {
  const R = forced(['deathless', 'voidsworn', 'hegemony'], 'corsair'); R.fleet.forEach(s => { s.hp = 9999; });
  T.nemClockAdd(1); const a = R.nemClock; R.sector = 2; T.nemActive(); T.nemClockAdd(1); const b = R.nemClock;
  return a === .5 && b === 2 && noClockOnCommanders(R) && !('clock' in R.nem); });
// 121-4: a strike brings the meeting forward and never changes the hunter
check('121-4 a strike brings the sector meeting forward; the hunter and the assignment stay', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); T.nemAfterBattle('win', false, {}); R.sector = 2; const B0 = T.nemActive(); const early = earlyNode(R);
  const a0 = canon(R.nemAssign), off = !T.nemNodeIs(early); R.credits = 0; let i = 0; while (!R.nemStrike && i++ < 8) T.nemClockAdd(1);
  return off && R.nemStrike && T.nemNodeIs(early) && T.nemActive() === B0 && B0.fac === 'corsair' && canon(R.nemAssign) === a0; });
// #282 (Muse, #274 design call 4): what crosses a sector advance is the full clock, not a pending strike. A clock filled after
// this sector's meeting arms nothing; the next sector's first add arms the strike, when the incoming commander's met is 0.
check('121-4 (#282) a full clock crosses the sector advance; the strike arms on the next sector first clock add', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); R.fleet.forEach(s => { s.hp = 9999; });
  T.nemAfterBattle('win', false, {});                                  // meet the sector 1 commander: met 1, clock 0
  let i = 0; while (R.nemClock < T.NEM_CLOCK && i++ < 8) T.nemClockAdd(1);
  const fullNoStrike = R.nemClock === T.NEM_CLOCK && !R.nemStrike;     // met this sector: the full clock arms nothing
  advance(R);                                                          // the real boss advance into sector 2
  const early = earlyNode(R);
  const carried = R.sector === 2 && R.nemClock === T.NEM_CLOCK && !R.nemStrike && !T.nemNodeIs(early);
  const line = T.nemClockAdd(1);                                       // the next sector's first clock add
  return fullNoStrike && carried && R.nemStrike && T.nemNodeIs(early) && line !== '' && /found your trail/.test(line); });
// 121-5: meeting side effects, per commander
check('121-5 a win, a loss and a retreat reset the run clock and strike; only the commander met changes', () => {
  let ok = true;
  for (const res of ['win', 'loss', 'retreat']) {
    const R = forced(['hegemony', 'corsair', 'ithar']); T.nemAfterBattle('win', false, {}); const A = R.nems.hegemony, A0 = canon(A);
    R.sector = 2; const B = T.nemActive(); R.nemClock = 4; R.nemStrike = true; const b0 = B.beaten, r0 = B.revealed.length;
    T.nemAfterBattle(res, false, {});
    if (B.met !== 2 || R.nemStrike !== false || R.nemClock !== (res === 'win' ? 0 : 1) || canon(A) !== A0) ok = false;
    if (res === 'win' && (B.beaten !== b0 + 1 || B.revealed.length !== r0 + 1)) ok = false;
  }
  return ok; });
// 121-6 and A4: the real sector advance adapts the commander who fought the sector just ended, from his own seen
function advance(R) { R.reward = null; T.W._rewardCfg = { kind: 'boss' }; T.afterBattle(); }
check('121-6 (A4) the sector advance adapts the outgoing commander from his own seen; the incoming one does not adapt', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const A = R.nems.hegemony; A.seen = { battery: 5 };
  advance(R); const B = R.nems.corsair;
  const s2 = R.sector === 2 && canon(A.adapt) === canon(['evasion']) && B && B.adapt.length === 0 && T.nemActive() === B && /Intelligence:/.test(T.MODAL) && T.MODAL.includes(T.nemFull(A));
  const A2 = canon(A); B.seen = { lance: 9 }; advance(R); const C = R.nems.ithar;
  return s2 && R.sector === 3 && canon(B.adapt) === canon(['shields']) && canon(A) === A2 && C.adapt.length === 0; });
check('121-6 (A4) a returning SP1 commander keeps his sector 1 adaptation and does not adapt on arrival', () => {
  const R = forced(['hegemony', 'corsair', 'hegemony']); const A = R.nems.hegemony; A.seen = { ram: 3 }; advance(R);
  const B = R.nems.corsair; B.seen = {}; advance(R); return R.sector === 3 && T.nemActive() === A && canon(A.adapt) === canon(['armor']) && B.adapt.length === 1; });
// 121-8: Chorus fast adaptation reads the Chorus commander's own beaten and scars (SP2, not the first commander created)
check('121-8 Chorus SP2 adapts with its own cap: (2 - 1) + beaten 1 + scars 1 = 3', () => {
  const R = forced(['hegemony', 'chorus', 'ithar']); const A = R.nems.hegemony; A.beaten = 0; A.scars = 0; R.sector = 2; const C = T.nemActive();
  C.beaten = 1; C.scars = 1; C.adapt = ['armor', 'aim']; C.seen = { lance: 9 }; const a = T.nemAdapt(); C.seen = { torp: 9 }; const b = T.nemAdapt();
  return a === 'shields' && b === null && C.adapt.length === 3 && A.adapt.length === 0; });
check('121-8 Chorus still adapts after every meeting, from its own state', () => {
  const R = forced(['hegemony', 'chorus', 'ithar']); R.sector = 2; const C = T.nemActive(); C.beaten = 1; C.scars = 1; C.adapt = ['armor']; C.seen = { lance: 9 };
  const out = T.nemAfterBattle('loss', false, {}); return C.adapt.length === 2 && out.some(l => /learns from it at once/.test(l)); });
// 121-9: scars, epithets and lessons attach to the commander met
check('121-9 scars and epithets on the commander met; a lost meeting records its lesson (NEM_VOICE text) on that commander only', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const A = R.nems.hegemony; T.nemAfterBattle('win', true, { cause: 'big' });
  const scar = A.scars === 1 && !!A.epithet; R.sector = 2; const B = T.nemActive(); const A0 = canon(A);
  const out = T.nemAfterBattle('loss', false, {}); const w = B.revealed[B.revealed.length - 1];
  return scar && B.scars === 0 && B.lessons.length === 1 && B.lessons[0].w === w && B.lessons[0].t === T.NEM_VOICE.corsair.lessons[w] && B.lessons[0].sector === 2
    && out.includes('Lesson: ' + T.NEM_VOICE.corsair.lessons[w]) && canon(A) === A0 && A.lessons.length === 0; });
check('121-9 a full file teaches the faction strike lesson once; a Crusade commander (no table) records the weakness itself', () => {
  const R = forced(['hegemony', 'voidsworn', 'ithar'], 'corsair'); const A = R.nems.hegemony; A.revealed = A.weak.slice();
  T.nemAfterBattle('loss', false, {}); T.nemAfterBattle('loss', false, {}); const strike = A.lessons.length === 1 && A.lessons[0].w === 'strike' && A.lessons[0].t === T.NEM_VOICE.hegemony.lessons.strike;
  R.sector = 2; const V = T.nemActive(); T.nemAfterBattle('loss', false, {}); const w = V.lessons[0] && V.lessons[0].w;
  return strike && V.lessons.length === 1 && V.lessons[0].t === T.NEM_WEAK[w].n + ': ' + T.NEM_WEAK[w].d; });
// 121-10 and 121-11: NEM_VOICE structure and content rules
const PRON = /\b(he|she|his|her|him|hers)\b/i, FEM = /\b(she|her|hers)\b/i;
check('121-10 NEM_VOICE is complete for the five tabled factions; the Crusade has no table and keeps NEM_LINES', () => {
  const V = T.NEM_VOICE, bad = [];
  if (canon(Object.keys(V).sort()) !== canon(['chorus', 'corsair', 'deathless', 'hegemony', 'ithar'])) bad.push('keys');
  for (const f of Object.keys(V)) {
    for (const p of T.NEM_FAC[f].personas) { const P = V[f][p]; if (!P) { bad.push(f + ' ' + p); continue; }
      for (const k of ['meet', 'win', 'fall']) if (!Array.isArray(P[k]) || !P[k].length) bad.push(f + p + k);
      if (!Array.isArray(P.flee) || (f !== 'deathless' && !P.flee.length)) bad.push(f + p + 'flee');
      for (const k of ['again', 'remember']) if (typeof P[k] !== 'string') bad.push(f + p + k);
      if (f === 'deathless' && (!Array.isArray(P.fall_final) || !P.fall_final.length)) bad.push(f + p + 'fall_final'); }
    for (const a of ['shields', 'pd', 'armor', 'evasion', 'aim', 'special']) if (typeof V[f].adapt[a] !== 'string') bad.push(f + ' adapt ' + a);
    for (const w of Object.keys(T.NEM_WEAK).concat('strike')) if (typeof V[f].lessons[w] !== 'string') bad.push(f + ' lesson ' + w);
  }
  const R = forced(['voidsworn', 'hegemony', 'ithar'], 'corsair'); const N = T.nemActive();
  if (T.nemOpenLine(N) !== null || T.nemBattleCfg().line !== null || T.nemAdaptLine(N, 'shields') !== '') bad.push('crusade fallback');
  if (bad.length) throw new Error(bad.join(', ')); return true; });
check('121-11 content rules: {beat} in again and remember; Chorus no gendered pronouns, no song or choir; Eclipse never flees; lessons pronoun-free; no persona reads', () => {
  const V = T.NEM_VOICE, bad = [];
  for (const f of Object.keys(V)) {
    const keys = Object.keys(V[f]).filter(k => !['adapt', 'lessons'].includes(k));
    if (keys.some(k => !T.NEM_FAC[f].personas.includes(k))) bad.push(f + ' extra keys');
    for (const p of keys) { const P = V[f][p];
      const allowed = f === 'deathless' ? ['meet', 'win', 'flee', 'fall', 'fall_final', 'again', 'remember'] : ['meet', 'win', 'flee', 'fall', 'again', 'remember'];
      if (Object.keys(P).some(k => !allowed.includes(k))) bad.push(f + p + ' slots');
      if (!P.again.includes('{beat}') || !P.remember.includes('{beat}')) bad.push(f + p + ' beat');
      if (f === 'deathless' && P.flee.length !== 0) bad.push('eclipse flee');
      const spoken = [].concat(P.meet, P.win, P.flee, P.fall, P.fall_final || [], P.again, P.remember);
      for (const t of spoken) { if (f === 'chorus' && (PRON.test(t) || /song|choir/i.test(t))) bad.push('chorus: ' + t); if (f !== 'chorus' && FEM.test(t)) bad.push('fem: ' + t); } }
    for (const t of Object.values(V[f].adapt)) if ((f === 'chorus' && (PRON.test(t) || /song|choir/i.test(t))) || FEM.test(t)) bad.push('adapt: ' + t);
    for (const t of Object.values(V[f].lessons)) if (PRON.test(t)) bad.push('lesson: ' + t);
  }
  if (bad.length) throw new Error(bad.slice(0, 5).join(' | ')); return true; });
// 121-12: what nemSay actually speaks (Eclipse fall and fall_final per A1; pronoun swap; {beat})
check('121-12 Eclipse: a sector 2 kill speaks fall; the sector 3 kill that revives speaks fall_final; the permanent death speaks neither', () => {
  const R = forced(['deathless', 'deathless', 'deathless'], 'hegemony'); const N = T.nemActive(); const P = T.NEM_VOICE.deathless[N.persona];
  const said = out => out.filter(l => l.startsWith(T.nemFull(N) + ': "')).map(l => l.slice(T.nemFull(N).length + 3, -1));
  R.sector = 2; const o1 = said(T.nemAfterBattle('win', true, { cause: 'big' }));
  R.sector = 3; const o2 = said(T.nemAfterBattle('win', true, {})); const o3 = said(T.nemAfterBattle('win', true, {}));
  return o1.length === 1 && P.fall.includes(o1[0]) && !P.fall_final.includes(o1[0]) && o2.length === 1 && P.fall_final.includes(o2[0]) && N.revived && o3.length === 0 && N.dead; });
check('121-12 lines render through nemSay ({beat} filled, pronouns swapped for her and it); the battle logs the line the campaign sends', async () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const N = T.nemActive(); N.beaten = 1; N.last_beat = 'lance'; N.adapt = [];
  const want = T.NEM_VOICE.hegemony[N.persona].remember.replace('{beat}', T.NEM_BEAT_WORD.lance);
  const m = T.nemOpenLine(N); N.adapt = [T.NEM_BEAT_COUNTER.lance]; const a = T.nemOpenLine(N);
  const ad = T.NEM_VOICE.hegemony.adapt.shields, gm = T.nemAdaptLine(N, 'shields'); N.g = 'f'; const gf = T.nemAdaptLine(N, 'shields');
  const swap = T.nemSay('He holds his line and him.', N) === 'She holds her line and her.';
  N.g = 'm'; N.adapt = []; N.beaten = 0; N.last_beat = null; const cfg = T.nemBattleCfg();
  T.startBattle({ kind: 'elite', fac: 'hegemony', col: 4, nemesis: cfg, obj: 'rout', shape: 'open', map: 'storm', seed: 3 });
  const logged = T.B.log.some(x => x.m.endsWith(': "' + cfg.line + '"'));
  return m === want && !m.includes('{beat}') && a === T.NEM_VOICE.hegemony[N.persona].again.replace('{beat}', T.NEM_BEAT_WORD.lance) && gm === T.nemFull(N) + ': "' + ad + '"' && gf === gm && swap
    && T.NEM_VOICE.hegemony[N.persona].meet.includes(cfg.line) && logged; });
// 121-13: behaviour packages unchanged (pinned from main before #121), and the Chorus as a non-first commander keeps its feeding cap
const BEH_SHA = 'd2af61f99487c283';
check('121-13 NEM_FAC behaviour packages are unchanged; a non-first Chorus commander feeds to 8 (+32% hull)', () => {
  const sha = crypto.createHash('sha256').update(canon(Object.fromEntries(Object.keys(T.NEM_FAC).sort().map(f => [f, T.NEM_FAC[f].beh])))).digest('hex').slice(0, 16);
  const R = forced(['hegemony', 'chorus', 'ithar']); R.sector = 2; const C = T.nemActive(); T.nemFeedLosses(5); const line = T.nemFeedLosses(9);
  return sha === BEH_SHA && C.fed === 8 && /32% tougher \(fed 8 of 8\)/.test(line) && R.nems.hegemony.fed === 0; });
// saves: an old save (clock on the commander) migrates the clock onto the run; a new save round-trips
check('saves: a pre-#121 save moves the commander clock and strike onto the run; a save round trip keeps clock, strike and lessons', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const A = R.nems.hegemony; delete R.nemClock; delete R.nemStrike; A.clock = 2.5; A.strike = true; T.nemActive();
  const mig = R.nemClock === 2.5 && R.nemStrike === true && !('clock' in A) && !('strike' in A);
  A.lessons = [{ w: 'ion', t: 'x', sector: 1 }]; const S = JSON.parse(JSON.stringify(R)); T.RUN = T.migrateRun(S); T.nemActive();
  return mig && T.RUN.nemClock === 2.5 && T.RUN.nemStrike === true && T.RUN.nems.hegemony.lessons.length === 1 && T.RUN.nem === T.RUN.nems.hegemony; });
check('saves: a legacy single-commander save (pre-#120 shape) keeps its clock on the run', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const N = R.nems.hegemony; R.nems = {}; R.nemAssign = undefined; delete R.nemClock; delete R.nemStrike; N.clock = 3; N.strike = false; R.nem = N;
  T.nemActive(); return R.nemClock === 3 && R.nemStrike === false && R.nems.hegemony === N && !('clock' in N); });
check('the map card reads the run clock', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); R.nemClock = 2.5; const p = T.nemPanel(); R.nemStrike = true; const q = T.nemPanel();
  return p.includes('●●◐○') && q.includes(T.nemStrikeLine(T.nemActive())); });
// #282 (Muse condition 1b): the strike line and the modal reason go through nemSay for a female and a Chorus commander
check('#282 the panel strike line and the modal adaptation reason read correctly for a she and an it', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const F = R.nems.hegemony; R.nemStrike = true;
  F.g = 'f'; const pf = T.nemPanel(), lf = T.nemStrikeLine(F), wf = T.nemAdaptWhyLine('formation', F);
  F.g = 'n'; const pn = T.nemPanel(), ln = T.nemStrikeLine(F), wn = T.nemAdaptWhyLine('hunger', { fac: 'chorus', g: 'n' });
  return pf.includes(lf) && lf === 'Her fleet is coming: your next fight is her.' && wf === 'her own way of war'
    && pn.includes(ln) && ln === 'Its fleet is coming: your next fight is its.' && wn === 'its own way of war'; });

(async () => {
  for (const [name, fn] of tests) { try { const r = await fn(); if (r === true) pass++; else { fail++; console.log('FAIL  ' + name + ': returned ' + r); } } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.stack || e)); } }
  console.log(`\n#121 Nemesis tests: ${pass} ok, ${fail} FAIL`); process.exit(fail ? 1 : 0);
})();
