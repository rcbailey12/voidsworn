// Issue #122 (Nemesis redesign 3): telemetry (signatures per commander, the run escape counter, the Chorus compounding counter),
// the Nemesis panel (the current sector's hunter, a return with scars and lessons, earlier hunters still readable) and the tests.
// Proves the #201 check pack for issue 122 (contrib/muse/reviews/nemesis_checks_2026_11/legs/rey_blind.md as amended by synthesis.md
// section 3) on the live browser code. The Godot twin is proven by the same flows in godot/campaign/test/nem_scenarios.gd (sections
// 25 to 31, compared line by line with node/nem_scenarios.js); the panel data both UIs draw is in those records too.
//   node contrib/opus/tools/nemesis_122_tests.js
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
function log(m){ if(B&&B.log) B.log.push({m}); } function fxText(){} function fxShield(){} function fxFlash(){} function nodeSeeds(){ return 0; }
var TEL=[]; function tel(ev,d){ TEL.push(Object.assign({ev},d||{})); }
async function animWeapon(){} async function animExplode(){} function fxShieldBreak(){} function fxCrit(){} function fxWithdraw(){} async function fxRam(){} function fxSectionDown(){} async function fxBoard(){}
var MODAL=''; modal=function(h){ MODAL=h; }; show=function(){}; toast=function(){};
global.T = { get RUN(){ return RUN; }, set RUN(v){ RUN=v; }, get TEL(){ return TEL; }, set TEL(v){ TEL=v; }, migrateRun, newRun, rndSeed, META, ADMIRALS, afterBattle,
  nemActive, nemClockAdd, nemAfterBattle, nemPanel, nemPanelData, nemFeedLosses, nemSignature, nemCompound, nemTelSummary, nemFull, roman,
  NEM_CLOCK, NEM_WEAK, NEM_FAC, NEM_VOICE, W:window };
`);
const pickAdm = fac => Object.entries(T.ADMIRALS).find(([k, a]) => (a.fac || 'voidsworn') === fac)[0];
// a run with a forced assignment; the player's faction is one no hunter uses; the telemetry log starts empty
function forced(assign, player) {
  const fac = player || ['voidsworn', 'hegemony', 'corsair', 'ithar', 'chorus', 'deathless'].find(f => !assign.includes(f));
  T.rndSeed(4242); T.META.unlocked = {}; T.newRun(pickAdm(fac), fac); const R = T.RUN;
  R.nemAssign = assign.slice(); R.nems = {}; R.nem = null; R.nemClock = 0; R.nemStrike = false; R.sector = 1; T.nemActive(); T.TEL = []; return R;
}
const nemTel = ev => T.TEL.filter(e => e.ev === ev);
function advance() { const R = T.RUN; R.reward = null; T.W._rewardCfg = { kind: 'boss' }; T.afterBattle(); } // the real sector advance
// the card block of the panel (the current hunter) and the block after it (earlier hunters)
function cardOf(html) { const i = html.indexOf('<div class="nemcard"'), j = html.indexOf('<div class="nemprior"'); return i < 0 ? '' : html.slice(i, j < 0 ? undefined : j); }
function priorOf(html) { const j = html.indexOf('<div class="nemprior"'); return j < 0 ? '' : html.slice(j); }
const ESC = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
const has = (html, s) => html.includes(s) || html.includes(ESC(s));

// 122-1: nemSignature tags the acting commander's faction and sector; each commander keeps his own list, capped at 40
check('122-1 a flee by the SP1 commander and a raid by the SP2 commander are tagged with their own faction and sector, in their own lists', () => {
  const R = forced(['ithar', 'corsair', 'hegemony']); T.nemAfterBattle('win', false, { fled: true });
  R.sector = 2; T.nemActive(); R.credits = 100; for (let i = 0; i < 8 && !R.nemStrike; i++) T.nemClockAdd(1);
  const ev = nemTel('nem_signature'), A = R.nems.ithar, B = R.nems.corsair;
  const flee = ev.find(e => e.kind === 'flee'), raid = ev.find(e => e.kind === 'raid');
  return !!flee && flee.fac === 'ithar' && flee.sector === 1 && !!raid && raid.fac === 'corsair' && raid.sector === 2
    && A.signatures.includes('flee') && !A.signatures.includes('raid') && B.signatures.includes('raid') && !B.signatures.includes('flee'); });
check('122-1 the list is capped at 40 per commander, oldest dropped; a signature given a commander is his even when he is not active', () => {
  const R = forced(['ithar', 'corsair', 'hegemony']); R.sector = 2; T.nemActive(); const A = R.nems.ithar; T.TEL = [];
  for (let i = 0; i < 41; i++) T.nemSignature('k' + i, A);
  const ev = nemTel('nem_signature');
  return A.signatures.length === 40 && A.signatures[0] === 'k1' && A.signatures[39] === 'k40' && R.nems.corsair.signatures.length === 0
    && ev.length === 41 && ev.every(e => e.fac === 'ithar' && e.sector === 2); });
// 122-2: the run escape counter
check('122-2 run 1 (distinct hunters): 0, a flight makes 1, a sector 2 flagship kill makes 2, the sector 3 death leaves 2', () => {
  const R = forced(['ithar', 'corsair', 'hegemony']); const s = [R.nemEscapes];
  T.nemAfterBattle('win', false, { fled: true }); s.push(R.nemEscapes);
  R.sector = 2; T.nemActive(); T.nemAfterBattle('win', true, { cause: 'big' }); s.push(R.nemEscapes);
  R.sector = 3; T.nemActive(); T.nemAfterBattle('win', true, {}); s.push(R.nemEscapes);
  const ev = nemTel('nem_escape');
  return s.join() === '0,1,2,2' && R.nems.hegemony.dead === true && ev.length === 2 && ev[0].fac === 'ithar' && ev[0].how === 'fled' && ev[1].fac === 'corsair' && ev[1].how === 'flagship'; });
check('122-2 run 2 (the SP1 commander returns): his flight counts once, a plain win over the SP2 commander does not, his sector 3 death does not', () => {
  const R = forced(['ithar', 'corsair', 'ithar']); T.nemAfterBattle('win', false, { fled: true }); const a = R.nemEscapes;
  R.sector = 2; T.nemActive(); T.nemAfterBattle('win', false, {}); const b = R.nemEscapes;
  R.sector = 3; T.nemActive(); T.nemAfterBattle('win', true, {}); return a === 1 && b === 1 && R.nemEscapes === 1 && R.nems.ithar.dead === true; });
check('122-2 run 3 (Eclipse): the revive and the final death in sector 3 never count; a sector 3 flight never counts (A13); losses never count', () => {
  const R = forced(['hegemony', 'corsair', 'deathless']); R.sector = 3; T.nemActive(); T.nemAfterBattle('win', true, {}); const rev = R.nems.deathless.revived === true && R.nemEscapes === 0;
  T.nemAfterBattle('win', true, {}); const dead = R.nems.deathless.dead === true && R.nemEscapes === 0;
  const Q = forced(['hegemony', 'corsair', 'ithar']); Q.sector = 3; T.nemActive(); T.nemAfterBattle('win', false, { fled: true }); const sp3 = Q.nemEscapes === 0 && Q.nems.ithar.scars === 1;
  const L = forced(['ithar', 'corsair', 'ithar']); T.nemAfterBattle('loss', false, {}); L.sector = 2; T.nemActive(); T.nemAfterBattle('retreat', false, {});
  return rev && dead && sp3 && L.nemEscapes === 0 && nemTel('nem_escape').length === 0; });
// 122-3: the compounding counter is the Chorus commander's own fed counter
check('122-3 the Chorus SP2 commander starts at fed 0 whatever happened in sector 1, then 3, then the cap of 8, then still 8; the others never grow', () => {
  const R = forced(['hegemony', 'chorus', 'ithar']); const before = T.nemFeedLosses(5);
  R.sector = 2; const C = T.nemActive(); const f0 = C.fed; const s = []; for (const n of [3, 10, 2]) { T.nemFeedLosses(n); s.push(C.fed); }
  R.sector = 3; T.nemActive(); T.nemFeedLosses(4);
  const comp = nemTel('nem_compound');
  return before === '' && f0 === 0 && s.join() === '3,8,8' && C.fed === 8 && R.nems.hegemony.fed === 0 && R.nems.ithar.fed === 0
    && comp.length === 2 && comp.every(e => e.fac === 'chorus' && e.kind === 'fed' && e.cap === 8) && comp[1].n === 8; });
check('122-3 only a compounding faction carries the counter: riches and honed are not re-counted', () => {
  const R = forced(['corsair', 'ithar', 'chorus']); T.nemAfterBattle('win', false, { fled: true }); const riches = R.nems.corsair.riches;
  R.sector = 2; T.nemActive(); T.nemAfterBattle('win', false, { fled: true }); const honed = R.nems.ithar.honed;
  R.sector = 3; T.nemActive();
  return riches === 1 && honed === 1 && T.nemCompound(R.nems.corsair) === null && T.nemCompound(R.nems.ithar) === null
    && JSON.stringify(T.nemCompound(R.nems.chorus)) === JSON.stringify({ kind: 'fed', n: 0, cap: 8 })
    && JSON.stringify(T.nemTelSummary().compound) === JSON.stringify({ chorus: 0 }) && nemTel('nem_compound').length === 0; });
// 122-9: the two counters are not merged
check('122-9 an escape and Chorus feeding in one run: escapes on the run, fed on the Chorus commander; a second escape moves only the run counter', () => {
  const R = forced(['ithar', 'chorus', 'hegemony']); T.nemAfterBattle('win', false, { fled: true }); R.sector = 2; const C = T.nemActive(); T.nemFeedLosses(3);
  const one = R.nemEscapes === 1 && C.fed === 3 && !('fed' in R) && Object.values(R.nems).every(N => !('nemEscapes' in N));
  T.nemAfterBattle('win', true, { cause: 'big' }); return one && R.nemEscapes === 2 && C.fed === 3; });
// 122-4: the panel shows the current sector's assigned hunter
check('122-4 sector 2: the card names the SP2 commander (clock, a known and an unknown weakness, his adaptation); the SP1 name is not in the card', () => {
  const R = forced(['ithar', 'corsair', 'hegemony']); const A = R.nems.ithar; T.nemAfterBattle('win', false, { fled: true });
  R.sector = 2; const B = T.nemActive(); B.revealed = [B.weak[0]]; B.adapt = ['shields']; R.nemClock = 1;
  const html = T.nemPanel(), card = cardOf(html), prior = priorOf(html);
  return has(card, T.nemFull(B)) && !has(card, A.name) && card.includes('●○○○') && has(card, T.NEM_WEAK[B.weak[0]].n) && card.includes('unknown')
    && card.includes('Adapted:') && has(prior, T.nemFull(A)) && T.nemPanelData().fac === 'corsair'; });
// 122-5: a return shows his scars and lessons, and the earlier commander stays readable
check('122-5 the SP1 commander back at SP3: his scars and the return line on the card; the SP2 commander, his outcome and his lesson still readable', () => {
  const R = forced(['ithar', 'corsair', 'ithar']); const A = R.nems.ithar; T.nemAfterBattle('win', false, { fled: true });
  advance(); const B = T.nemActive(); T.nemAfterBattle('loss', false, {}); const lesson = B.lessons[0] && B.lessons[0].t;
  advance(); const N3 = T.nemActive(); const html = T.nemPanel(), card = cardOf(html), prior = priorOf(html), D = T.nemPanelData();
  return N3 === A && card.includes('scarred 1x') && has(card, 'He is back: you met him in sector I.') && !has(card, B.name)
    && has(prior, T.nemFull(B)) && !!lesson && has(prior, lesson) && has(prior, 'Sector II: drove you off.')
    && D.earlier.length === 1 && D.earlier[0].fac === 'corsair' && D.earlier[0].lessons[0] === lesson && D.back !== ''; });
check('122-5 the return card lists his own lessons; a dead hunter still shows the earlier ones', () => {
  const R = forced(['ithar', 'corsair', 'ithar']); T.nemAfterBattle('win', false, { fled: true }); advance(); T.nemAfterBattle('win', false, {}); advance();
  const A = T.nemActive(); T.nemAfterBattle('loss', false, {}); const t = A.lessons[0] && A.lessons[0].t; const card = cardOf(T.nemPanel());
  T.nemAfterBattle('win', true, {}); const dead = T.nemPanel();
  return !!t && has(card, 'Lessons:') && has(card, t) && A.dead === true && /is dead/.test(dead) && has(priorOf(dead), 'Sector II: beaten, withdrew.'); });
check('the panel data has no earlier hunters in sector 1, and a migrated single-commander save shows its commander only', () => {
  const R = forced(['ithar', 'corsair', 'hegemony']); const D1 = T.nemPanelData();
  const N = R.nems.ithar; R.nems = {}; R.nemAssign = undefined; R.sector = 2; R.nem = N; delete R.nemEscapes; T.nemActive(); const D2 = T.nemPanelData();
  return D1.earlier.length === 0 && D1.back === '' && D2.fac === 'ithar' && D2.earlier.length === 0 && D2.back === '' && !priorOf(T.nemPanel()); });
// 122-6: the promised scenario blocks exist in both twins (run_nem_scenarios.sh compares them line by line)
check('122-6 the once-per-sector and telemetry scenario blocks exist in nem_scenarios.js and nem_scenarios.gd', () => {
  const js = fs.readFileSync(path.join(ROOT, 'godot/campaign/test/node/nem_scenarios.js'), 'utf8'), gd = fs.readFileSync(path.join(ROOT, 'godot/campaign/test/nem_scenarios.gd'), 'utf8');
  const marks = ['(121-1, 121-2)', '(122-1)', '(122-2)', '(122-3)', '(122-9)', '(122-4, 122-5)'];
  const miss = marks.filter(m => !js.includes(m) || !gd.includes(m)); if (miss.length) throw new Error('missing ' + miss.join(', ')); return gd.includes('func run_122()'); });
// saves
check('saves: a save from before the escape counter rebuilds it from the scars (a revive scar is not an escape, at most 2); a round trip keeps it', () => {
  const R = forced(['ithar', 'chorus', 'deathless']); T.nemAfterBattle('win', false, { fled: true }); delete R.nemEscapes; T.nemActive(); const a = R.nemEscapes;
  const Q = forced(['hegemony', 'corsair', 'deathless']); Q.sector = 3; T.nemActive(); T.nemAfterBattle('win', true, {}); delete Q.nemEscapes; T.nemActive(); const b = Q.nemEscapes;
  const P = forced(['ithar', 'corsair', 'hegemony']); P.nems.ithar.scars = 5; delete P.nemEscapes; T.nemActive(); const c = P.nemEscapes;
  P.nemEscapes = 1; T.RUN = T.migrateRun(JSON.parse(JSON.stringify(P))); T.nemActive();
  return a === 1 && b === 0 && c === 2 && T.RUN.nemEscapes === 1; });
check('a new run starts with the escape counter at 0', () => { const R = forced(['ithar', 'corsair', 'hegemony']); return R.nemEscapes === 0; });
// the #274 catch: the clock-full message goes through nemSay
check('the clock-full message speaks of its fleet for the Chorus and her fleet and her raiders for a she', () => {
  forced(['chorus', 'hegemony', 'chorus']); T.RUN.nemClock = 3; const it = T.nemClockAdd(1);
  forced(['corsair', 'hegemony', 'corsair']); T.nemActive().g = 'f'; T.RUN.credits = 100; T.RUN.nemClock = 3; const she = T.nemClockAdd(1);
  forced(['hegemony', 'chorus', 'hegemony']); T.nemActive().g = 'm'; T.RUN.nemClock = 3; const he = T.nemClockAdd(1);
  return /against its fleet/.test(it) && !/\bhis\b/i.test(it) && /against her fleet/.test(she) && /Her raiders/.test(she) && !/\b(his|He)\b/.test(she) && /against his fleet/.test(he); });
// telemetry at the run's end
check('run_end carries the run Nemesis record (assignment, escapes, compounding counters)', () => {
  const R = forced(['chorus', 'ithar', 'hegemony']); T.nemFeedLosses(2); T.nemAfterBattle('win', false, {}); R.sector = 2; T.nemActive(); T.nemAfterBattle('win', false, { fled: true });
  const S = T.nemTelSummary(); const src = fs.readFileSync(path.join(ROOT, 'campaign_meta.js'), 'utf8'), gd = fs.readFileSync(path.join(ROOT, 'godot/campaign/campaign.gd'), 'utf8');
  return JSON.stringify(S) === JSON.stringify({ assign: ['chorus', 'ithar', 'hegemony'], escapes: 1, compound: { chorus: 2 } })
    && /tel\('run_end',\{[^\n]*nem:typeof nemTelSummary==='function'\?nemTelSummary\(\):null/.test(src) && /tel\("run_end", \{[^\n]*"nem": nemTelSummary\(\)/.test(gd); });
// the drawing is separate from the logic (R137: the panel's look will be redone)
// issue #344 (the Briefing layout): the long Nemesis block is the Dossier; campaign_view.gd nem_dossier builds its lines and
// asks C.nemPanelData(N) with the commander it read (C.nemRead), so drawing never resolves one. The screen only draws lines.
check('the Godot Dossier draws the return, lessons and earlier hunters from C.nemPanelData and does not rebuild them', () => {
  const view = fs.readFileSync(path.join(ROOT, 'godot/campaign/campaign_view.gd'), 'utf8'), ui = fs.readFileSync(path.join(ROOT, 'godot/ui/campaign/campaign_ui.gd'), 'utf8');
  const i = view.indexOf('static func nem_dossier('), j = view.indexOf('\n# -', view.indexOf('static func nem_panel('));
  const body = view.slice(i, j); const k = ui.indexOf('func _dossier('), l = ui.indexOf('\nfunc _bb_safe(');
  const draw = ui.slice(k, l);
  return i > 0 && j > i && k > 0 && l > k && body.includes('C.nemPanelData(N)') && draw.includes('View.nem_dossier(C)')
    && !/nemAssign|\.lessons\b|\["lessons"\]\[/.test((body + draw).replace(/D\["lessons"\]|E\["lessons"\]|E\.get\("lessons"\)|D\.get\("lessons"\)/g, '')); });

(async () => {
  for (const [name, fn] of tests) { try { const r = await fn(); if (r === true) pass++; else { fail++; console.log('FAIL  ' + name + ': returned ' + r); } } catch (e) { fail++; console.log('FAIL  ' + name + ': ' + (e && e.stack || e)); } }
  console.log(`\n#122 Nemesis tests: ${pass} ok, ${fail} FAIL`); process.exit(fail ? 1 : 0);
})();
