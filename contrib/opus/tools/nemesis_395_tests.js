// Issue #395: the Sunward Crusade speaks through NEM_VOICE like the other five factions.
// Proves the Crusade block is the merged Muse text word for word, and drives the real campaign functions
// (newRun and the run's own draw, nemOpenLine, nemBattleCfg, nemWarnLine, nemClockAdd, nemStrikeLine,
// nemAfterBattle, nemAdaptLine, nemLessonText, nemDebrief, migrateRun) with a real run whose Nemesis is the Crusade.
//   node contrib/opus/tools/nemesis_395_tests.js
'use strict';
global.window = {}; global.performance = { now: () => Date.now() };
const STORE = {}; global.localStorage = { getItem: k => (k in STORE ? STORE[k] : null), setItem: (k, v) => { STORE[k] = String(v); }, removeItem: k => { delete STORE[k]; } };
const IDS = {};
const el = tag => ({ tag, style: {}, dataset: {}, children: [], innerHTML: '', classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
  appendChild(c) { if (c.id) IDS[c.id] = c; this.children.push(c); return c; }, remove() { if (this.id && IDS[this.id] === this) delete IDS[this.id]; },
  querySelector() { return null; }, querySelectorAll() { return []; }, addEventListener() {}, setAttribute() {}, focus() {} });
global.document = { createElement: el, getElementById: id => IDS[id] || (id === 'modal' ? null : el()), querySelector: () => null, querySelectorAll: () => [], body: el('body'), addEventListener() {}, documentElement: el() };
global.addEventListener = () => {}; global.requestAnimationFrame = () => 0; global.innerWidth = 1600; global.innerHeight = 900; global.setTimeout = () => 0;
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const src = ['data.js', 'core.js', 'battle.js', 'campaign_meta.js', 'campaign_run.js'].map(f => fs.readFileSync(path.join(ROOT, f), 'utf8')).join('\n');
let pass = 0, fail = 0; const tests = [];
function check(name, fn) { tests.push([name, fn]); }
eval(src + `
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){} function tel(){} function nodeSeeds(){ return 0; }
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} async function fxSectionDown(){} async function fxBoard(){}
var MODAL=''; modal=function(h){ MODAL=h; }; show=function(){}; toast=function(){};
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get B(){ return B; }, get MODAL(){ return MODAL; }, migrateRun, newRun, rndSeed, META, ADMIRALS,
  nemActive, ensureNemesis, nemClockAdd, nemNodeIs, nemBattleCfg, nemAdapt, nemAfterBattle, nemLearn, nemSay, nemFull, nemPanel, nemFeedLosses, nemOpenLine, nemAdaptLine,
  nemStrikeLine, nemAdaptWhyLine, nemWarnLine, nemLessonText, nemDebrief, NEM_CLOCK, NEM_WEAK, NEM_FAC, NEM_VOICE, NEM_LINES, NEM_BEAT_WORD, NEM_BEAT_COUNTER, NEM_ADAPT_FAC, W:window };
`);
const pickAdm = fac => Object.entries(T.ADMIRALS).find(([k, a]) => (a.fac || 'voidsworn') === fac)[0];
const canon = v => JSON.stringify(v, (k, x) => (x && typeof x === 'object' && !Array.isArray(x) ? Object.keys(x).sort().reduce((o, q) => (o[q] = x[q], o), {}) : x));
// A real run whose H1 draw is the Crusade. newRun draws the hunters exactly as the game does; the loop only advances the seed.
function crusadeRun(player, personaWanted) {
  for (let seed = 1; seed < 4000; seed++) {
    T.rndSeed(seed); T.META.unlocked = {}; T.newRun(pickAdm(player), player);
    if (T.RUN.nemAssign[0] !== 'voidsworn') continue;
    const N = T.nemActive();
    if (personaWanted && N.persona !== personaWanted) continue;
    return T.RUN;
  }
  return null;
}
const VOICE = () => T.NEM_VOICE.voidsworn;
const pool = N => VOICE()[N.persona];
function otherFactionLines() { // every raw line the other five factions own, to prove the Crusade never borrows one
  const out = new Set();
  for (const f of Object.keys(T.NEM_VOICE)) {
    if (f === 'voidsworn') continue;
    const V = T.NEM_VOICE[f];
    for (const p of Object.keys(V)) {
      const P = V[p]; if (!P || typeof P !== 'object') continue;
      for (const k of ['meet', 'win', 'flee', 'fall', 'fall_final']) if (Array.isArray(P[k])) P[k].forEach(x => out.add(x));
      for (const k of ['again', 'remember']) if (typeof P[k] === 'string') out.add(P[k]);
    }
    if (V.adapt) Object.values(V.adapt).forEach(x => out.add(x));
    if (V.lessons) Object.values(V.lessons).forEach(x => out.add(x));
  }
  return out;
}
const OTHER = otherFactionLines();
const own = (arr, line) => Array.isArray(arr) && arr.includes(line);

// 395-1: the block is the merged Muse text, word for word, and it fills the same shape as the other five
check('395-1 NEM_VOICE.voidsworn equals the merged crusade_voice.md block word for word', () => {
  const md = fs.readFileSync(path.join(ROOT, 'contrib/muse/design/nemesis_writing_2026_11/crusade_voice.md'), 'utf8');
  const m = /```js\r?\n([\s\S]*?)```/.exec(md); if (!m) throw new Error('no js block in crusade_voice.md');
  const want = vm.runInThisContext('({' + m[1].trim() + '})', { filename: 'crusade_voice.md' });
  if (!want || !want.voidsworn) throw new Error('the merged block has no voidsworn key');
  if (canon(want.voidsworn) !== canon(VOICE())) throw new Error('NEM_VOICE.voidsworn differs from the merged text');
  return true; });
check('395-2 the Crusade fills every slot the other factions fill: four personas, adapt, all lessons', () => {
  const V = T.NEM_VOICE, bad = [];
  if (!V.voidsworn) bad.push('no block');
  const personas = T.NEM_FAC.voidsworn.personas;
  if (canon(Object.keys(V.voidsworn).filter(k => !['adapt', 'lessons'].includes(k)).sort()) !== canon(personas.slice().sort())) bad.push('personas');
  for (const p of personas) { const P = V.voidsworn[p]; if (!P) { bad.push(p); continue; }
    for (const k of ['meet', 'win', 'fall']) if (!Array.isArray(P[k]) || !P[k].length) bad.push(p + ' ' + k);
    if (!Array.isArray(P.flee) || P.flee.length) bad.push(p + ' flee (the Crusade never flees, so the pool is empty)');
    for (const k of ['again', 'remember']) if (typeof P[k] !== 'string' || !P[k].includes('{beat}')) bad.push(p + ' ' + k); }
  for (const a of ['shields', 'pd', 'armor', 'evasion', 'aim', 'special']) if (typeof V.voidsworn.adapt[a] !== 'string') bad.push('adapt ' + a);
  for (const w of Object.keys(T.NEM_WEAK).concat('strike')) if (typeof V.voidsworn.lessons[w] !== 'string') bad.push('lesson ' + w);
  if (bad.length) throw new Error(bad.join(', ')); return true; });

// 395-3 and 395-4: a real run whose Nemesis is the Crusade answers every kind of line with Crusade text
check('395-3 a real run draws the Crusade as its Nemesis and the meeting line is the Crusade meet pool', () => {
  const R = crusadeRun('hegemony'); if (!R) throw new Error('no seed drew the Crusade');
  const N = T.nemActive(), line = T.nemOpenLine(N), cfg = T.nemBattleCfg();
  const armed = N.fac === 'voidsworn' && N.persona && T.NEM_FAC.voidsworn.personas.includes(N.persona)
    && typeof line === 'string' && line.length > 0 && own(pool(N).meet, line) && cfg.line === line && cfg.fac === 'voidsworn';
  if (!armed) throw new Error('the drawn commander or its meet line is not the Crusade'); return true; });
check('395-4 warning, strike, meeting and debrief all come back as Crusade text, never empty or another faction line', () => {
  const R = crusadeRun('hegemony'); const N = T.nemActive(), P = pool(N), V = VOICE(), out = [];
  const meet = T.nemOpenLine(N); out.push(['meeting', meet]);
  N.met = 0; R.nemStrike = false; R.nemClock = T.NEM_CLOCK - (T.NEM_FAC.voidsworn.beh.clock || 1);
  const warn = T.nemWarnLine(N); out.push(['warning', warn]);
  const found = T.nemClockAdd(1); out.push(['strike', found]);
  const strikeLine = T.nemStrikeLine(N); out.push(['strike line', strikeLine]);
  R.nemStrike = false; R.nemClock = 0;
  const loss = T.nemAfterBattle('loss', false, {}); const w = N.revealed[N.revealed.length - 1];
  out.push(['debrief', T.nemLessonText(N, w)]);
  N.seen = { lance: 9 }; const a = T.nemAdapt(true, N); const key = a === T.NEM_ADAPT_FAC.voidsworn.special.id ? 'special' : a;
  out.push(['adapt', T.nemAdaptLine(N, a)]);
  const winLine = loss.find(l => l.startsWith(T.nemFull(N) + ': "'));
  const bad = [];
  if (!meet || !own(P.meet, meet)) bad.push('meeting');
  if (!warn || OTHER.has(warn)) bad.push('warning');
  if (!found || !/found your trail/.test(found)) bad.push('strike');
  if (!strikeLine || OTHER.has(strikeLine)) bad.push('strike line');
  const lesson = T.nemLessonText(N, w);
  if (!lesson || lesson !== V.lessons[w] || !loss.includes('Lesson: ' + lesson)) bad.push('debrief');
  if (T.nemDebrief().lessons.every(l => l.text !== V.lessons[w])) bad.push('debrief row');
  if (!a || !own(Object.values(V.adapt), V.adapt[key]) || T.nemAdaptLine(N, a) !== T.nemFull(N) + ': "' + V.adapt[key] + '"') bad.push('adapt');
  if (!winLine || !own(P.win, winLine.slice(T.nemFull(N).length + 3, -1))) bad.push('win line');
  N.seen = {}; const fallOut = T.nemAfterBattle('win', true, {}); const fallLine = fallOut.find(l => l.startsWith(T.nemFull(N) + ': "'));
  if (!fallLine || !own(P.fall, fallLine.slice(T.nemFull(N).length + 3, -1))) bad.push('fall line');
  if (bad.length) throw new Error('bad slots: ' + bad.join(', ') + ' | ' + JSON.stringify(out)); return true; });
check('395-5 every persona of the Crusade speaks its own meet pool through a drawn run', () => {
  const seen = {}; const bad = [];
  for (const p of T.NEM_FAC.voidsworn.personas) {
    const R = crusadeRun('hegemony', p); if (!R) { bad.push(p + ' not drawn'); continue; }
    const N = T.nemActive(); seen[N.persona] = 1;
    const line = T.nemOpenLine(N); if (!own(VOICE()[p].meet, line)) bad.push(p + ': ' + line);
    const filler = T.NEM_BEAT_WORD.lance;
    N.beaten = 1; N.last_beat = 'lance'; N.adapt = [];
    const remember = T.nemOpenLine(N); if (!own([VOICE()[p].remember.replace('{beat}', filler)], remember)) bad.push(p + ' remember: ' + remember);
  }
  if (bad.length) throw new Error(bad.join(' | ')); return true; });

// 395-6: a save written before this change still loads, and the Crusade commander now speaks its table
check('395-6 a run save round-trips through the real loader and the Crusade lesson and meeting survive', () => {
  const R = crusadeRun('hegemony'); const N = T.nemActive();
  const meet = T.nemOpenLine(N);
  T.RUN = T.migrateRun(JSON.parse(JSON.stringify(T.RUN))); const M = T.nemActive();
  const loadOk = M && M.fac === 'voidsworn' && M.persona === N.persona && T.nemOpenLine(M) === meet && own(pool(M).meet, meet);
  T.nemAfterBattle('loss', false, {}); const L = T.nemActive(); const rec = L.lessons[0];
  T.RUN = T.migrateRun(JSON.parse(JSON.stringify(T.RUN))); const M2 = T.nemActive();
  const saveOk = M2 && M2.lessons.length === 1 && rec && M2.lessons[0].t === rec.t && rec.t === VOICE().lessons[rec.w];
  return !!loadOk && !!saveOk; });

(async () => {
  for (const [name, fn] of tests) { try { const r = await fn(); if (r === true) pass++; else { fail++; console.log('FAIL  ' + name + ': returned ' + r); } } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.stack || e)); } }
  console.log(`\n#395 Crusade voice tests: ${pass} ok, ${fail} FAIL`); process.exit(fail ? 1 : 0);
})();
