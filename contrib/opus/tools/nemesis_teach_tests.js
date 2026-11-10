// Issue #24, progression step 7: finish the Nemesis teaching loop.
// Proves the step's own test: a lost meeting still teaches one weakness on the run debrief, recorded against the
// commander who fought it, and the sector map names the meeting with the sector's assigned hunter as certain, not a chance.
// The Godot twin is proven by the same fixtures in godot/campaign/test/nemesis_teach_test.gd (run with this file's
// optional fixture argument) plus campaign parity.
//   node contrib/opus/tools/nemesis_teach_tests.js [fixtures.json]
'use strict';
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
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} async function fxSectionDown(){} async function fxBoard(){}
var MODAL='', HTML='';
modal=function(h){ MODAL=h; }; show=function(h){ HTML=h; }; toast=function(){};
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get MODAL(){ return MODAL; }, get HTML(){ return HTML; }, clearHtml(){ HTML=''; }, migrateRun, newRun, rndSeed, META, ADMIRALS,
  nemActive, ensureNemesis, nemNodeIs, nemNodeTag, nemMeetingLine, nemDebrief, nemAfterBattle, nemFull, mapScreen, endRun,
  NEM_WEAK, NEM_FAC, NEM_VOICE };
`);
const pickAdm = fac => Object.entries(T.ADMIRALS).find(([k, a]) => (a.fac || 'voidsworn') === fac)[0];
// a run with a forced assignment; the player's faction is one no hunter uses
function forced(assign, player) {
  const fac = player || ['voidsworn', 'hegemony', 'corsair', 'ithar', 'chorus', 'deathless'].find(f => !assign.includes(f));
  T.rndSeed(4242); T.META.unlocked = {}; T.newRun(pickAdm(fac), fac); const R = T.RUN;
  R.nemAssign = assign.slice(); R.nems = {}; R.nem = null; R.nemClock = 0; R.nemStrike = false; R.sector = 1; T.nemActive(); return R;
}
const lateNode = R => R.map.cols.flat().filter(n => n.type === 'battle' || n.type === 'elite').find(n => n.col >= R.map.cols.length - 3);

// 24-1: a lost meeting still records one taught weakness, on the commander who fought it
check('24-1 a lost meeting adds exactly one taught weakness to the run debrief, keyed to the commander who fought it', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const A = T.nemActive(); const name = T.nemFull(A);
  const out = T.nemAfterBattle('loss', false, {}); const w = A.revealed[A.revealed.length - 1]; const d = T.nemDebrief(R);
  return A.lessons.length === 1 && A.lessons[0].w === w && A.lessons[0].taught === true
    && out.some(l => l === 'Lesson: ' + T.NEM_VOICE.hegemony.lessons[w])
    && d.lessons.length === 1 && d.lessons[0].w === w && d.lessons[0].taught === true
    && d.lessons[0].fac === 'hegemony' && d.lessons[0].name === name
    && Object.keys(R.nems).length === 1 && d.met === 1;
});
// 24-2: the run-end debrief (the inheritance panel) shows that lesson against that commander
check('24-2 the lost meeting reaches the run-end debrief: the inheritance panel names the commander and the weakness', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const A = T.nemActive(); const name = T.nemFull(A);
  T.nemAfterBattle('loss', false, {}); const w = A.revealed[A.revealed.length - 1]; T.clearHtml();
  T.endRun(false, false); const nz = R.carry.inheritance.nem; const html = T.HTML;
  return nz.lessons.length === 1 && nz.lessons[0].name === name && nz.lessons[0].taught === true
    && html.includes('Nemesis lesson') && html.includes(name) && html.includes(T.NEM_WEAK[w].n)
    && /beat you and taught you a weakness/.test(html);
});
// 24-3: the sector map names the sector's assigned hunter and calls the meeting certain, with the clock an accelerant only
check('24-3 the sector map names the assigned hunter and the meeting as certain, not a chance', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const N = T.nemActive(); const name = T.nemFull(N);
  const line = T.nemMeetingLine(N); T.clearHtml(); T.mapScreen(); const map = T.HTML; const tag = T.nemNodeTag(lateNode(R));
  const certainty = /will meet/.test(line) && /certain/.test(line) && /only an accelerant/.test(line) && !/might|possibly|could|may not/.test(line);
  return line.includes(name) && certainty && tag === 'Nemesis meeting' && map.includes('Nemesis meeting') && map.includes(name) && map.includes('certain');
});
check('24-3 once met, the map says the meeting is done; the tag clears for the rest of the sector', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const N = T.nemActive(); const name = T.nemFull(N);
  T.nemAfterBattle('loss', false, {}); const line = T.nemMeetingLine(N); const tag = T.nemNodeTag(lateNode(R));
  return /have met/.test(line) && line.includes(name) && !/will meet/.test(line) && tag === '';
});
// 24-4: a won meeting does not fabricate a taught weakness; the empty row says so honestly
check('24-4 a won meeting reveals but does not teach; the debrief says no weakness was taught', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const A = T.nemActive();
  T.nemAfterBattle('win', false, {}); const d = T.nemDebrief(R); T.clearHtml(); T.endRun(true, false);
  return A.lessons.length === 0 && d.lessons.length === 0 && d.met === 1
    && T.HTML.includes('No weakness was taught this run.') && !/beat you and taught you a weakness/.test(T.HTML);
});
check('24-4 a run that never met him keeps the empty row and says so', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const d = T.nemDebrief(R); T.clearHtml(); T.endRun(false, false);
  return d.lessons.length === 0 && d.met === 0 && T.HTML.includes('No Nemesis meeting this run.');
});
// 24-5: an old save's lesson (written before the taught flag existed) still reads as a lesson taught on a loss
check('24-5 a lesson from a save written before this step still shows as taught', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const A = R.nems.hegemony;
  A.lessons = [{ w: A.weak[0], t: 'old lesson', sector: 1 }]; const d = T.nemDebrief(R);
  return d.lessons.length === 1 && d.lessons[0].taught === true && d.lessons[0].text === 'old lesson';
});
// 24-6: the lesson belongs to the commander met, not the last active one in the registry
check('24-6 the debrief keys the lesson to the commander who fought it, not the next sector hunter', () => {
  const R = forced(['hegemony', 'corsair', 'ithar']); const A = R.nems.hegemony; T.nemAfterBattle('win', false, {});
  R.sector = 2; T.nemActive(); const B = R.nems.corsair; T.nemAfterBattle('loss', false, {});
  const d = T.nemDebrief(R); const w = B.revealed[B.revealed.length - 1];
  return A.lessons.length === 0 && B.lessons.length === 1 && d.lessons.length === 1 && d.lessons[0].name === T.nemFull(B)
    && d.lessons[0].fac === 'corsair' && d.lessons[0].w === w && d.lessons[0].text === T.NEM_VOICE.corsair.lessons[w];
});

const fixtures = (() => { const out = [];
  { const R = forced(['hegemony', 'corsair', 'ithar']); const A = T.nemActive(); T.nemAfterBattle('loss', false, {});
    out.push({ name: 'lost meeting', run: JSON.parse(JSON.stringify(R)), who: 'hegemony', expected: T.nemDebrief(R), line: T.nemMeetingLine(A) }); }
  { const R = forced(['hegemony', 'corsair', 'ithar']); const A = T.nemActive(); A.lessons = [{ w: A.weak[0], t: 'old lesson', sector: 1 }];
    out.push({ name: 'old save lesson', run: JSON.parse(JSON.stringify(R)), who: 'hegemony', expected: T.nemDebrief(R), line: T.nemMeetingLine(A) }); }
  return out; })();
if (process.argv[2]) fs.writeFileSync(process.argv[2], JSON.stringify(fixtures));

(async () => {
  for (const [name, fn] of tests) { try { const r = await fn(); if (r === true) pass++; else { fail++; console.log('FAIL  ' + name + ': returned ' + r); } } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.stack || e)); } }
  console.log(`\n#24 Nemesis teaching tests: ${pass} ok, ${fail} FAIL`); process.exit(fail ? 1 : 0);
})();
