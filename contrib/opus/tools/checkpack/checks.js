// Voidsworn mechanical checks. No AI, no opinions: cross-references, duplicate
// declarations, dead content and drift between the build and the smoke test.
// Run with: node checks.js   (or double-click RUN_CHECKS.bat)
// Output is a report. FAIL = almost certainly a real problem. CHECK = eyeball it.
'use strict';
const fs = require('fs');
const path = require('path');
// Lives in contrib/opus/tools/checkpack; the repo root is four folders up.
const DIR = process.env.VS_ROOT || (fs.existsSync(path.join(__dirname, 'data.js')) ? __dirname : path.resolve(__dirname, '../../../..'));
let fails = 0, warns = 0;
const fail = m => { fails++; console.log('FAIL  ' + m); };
const warn = m => { warns++; console.log('CHECK ' + m); };
const ok = m => console.log('ok    ' + m);
const read = f => fs.readFileSync(path.join(DIR, f), 'utf8');

// The 18 files build.py concatenates, in build order.
const BUILD_FILES = ['meshopt3d.js','data.js','core.js','battle.js','scene3d.js','ships3d.js','fx3d.js','sfx_data.js','sfx.js','gfx3d.js','vfx3d.js','wfx3d.js','campaign_meta.js','campaign_run.js','ui3d.js','campaign3d.js','perf3d.js','main3d.js'];

console.log('VOIDSWORN MECHANICAL CHECKS');
console.log('===========================\n');

// ---------- 0. Files present ----------
console.log('--- Files ---');
for (const f of BUILD_FILES) {
  if (!fs.existsSync(path.join(DIR, f))) fail('build file missing: ' + f);
}
ok('all ' + BUILD_FILES.length + ' build files present (or FAILs above)');

// ---------- 1. Duplicate top-level declarations (build.py only checks functions) ----------
console.log('\n--- Duplicate top-level names ---');
{
  const seen = new Map();
  const re = /^(?:async\s+)?(?:function|const|let|var|class)\s+([A-Za-z_$][\w$]*)/gm;
  for (const f of BUILD_FILES) {
    const src = read(f); let m;
    while ((m = re.exec(src))) {
      if (seen.has(m[1])) fail('duplicate top-level name "' + m[1] + '" in ' + f + ' (first in ' + seen.get(m[1]) + '); the later one silently wins');
      else seen.set(m[1], f);
    }
  }
  ok('scanned ' + seen.size + ' top-level names');
}

// ---------- 2. Em dashes in shipped text/code (house rule: none, ever) ----------
console.log('\n--- Em dashes ---');
{
  let total = 0;
  for (const f of BUILD_FILES.concat(['head.html'])) {
    if (!fs.existsSync(path.join(DIR, f))) continue;
    const n = (read(f).match(/—/g) || []).length;
    if (n) { total += n; warn(f + ' contains ' + n + ' em dash(es)'); }
  }
  if (!total) ok('no em dashes in game files');
}

// ---------- 3. smoke.py file list vs build.py file list ----------
console.log('\n--- Build vs smoke drift ---');
{
  try {
    const smoke = read('smoke.py');
    const m = smoke.match(/FILES\s*=\s*\[([^\]]*)\]/);
    const smokeFiles = m ? [...m[1].matchAll(/'([^']+)'/g)].map(x => x[1]) : [];
    const missing = BUILD_FILES.filter(f => !smokeFiles.includes(f));
    const extra = smokeFiles.filter(f => !BUILD_FILES.includes(f));
    if (missing.length) warn('smoke.py does NOT test these build files: ' + missing.join(', '));
    if (extra.length) warn('smoke.py lists files not in the build: ' + extra.join(', '));
    if (!missing.length && !extra.length) ok('smoke.py and build.py cover the same files');
  } catch (e) { warn('smoke.py not readable here: ' + e.message); }
}

// ---------- 4. Load the data tables the way the sim harness does ----------
console.log('\n--- Data integrity (tables loaded) ---');
global.window = {}; global.document = undefined; global.performance = { now: () => Date.now() };
let T = null;
try {
  const src = ['data.js', 'core.js', 'battle.js'].map(read).join('\n') + `
;({HULLS, HULL_VARIANTS, ADMIRALS, BOONS, PATRONS, RELICS, MODULES, PERKS, W, ABILITIES, FACTIONS, EVENTS, FAC_WNAMES, MOD_NAMES, RELIC_NAMES, SECTOR_POOL, CAPTAINS, ARCHETYPES, NODE_MODS, SECTOR_CONDS, HEAT});`;
  T = eval(src);
  ok('data.js + core.js + battle.js loaded');
} catch (e) {
  fail('could not load the game tables: ' + e.message);
}
if (T) {
  const { HULLS, HULL_VARIANTS, ADMIRALS, BOONS, PATRONS, RELICS, MODULES, PERKS, W, ABILITIES, FACTIONS, EVENTS, FAC_WNAMES, MOD_NAMES, RELIC_NAMES, SECTOR_POOL } = T;

  // Hulls
  for (const [id, h] of Object.entries(HULLS)) {
    if (!h.sq && !FACTIONS[h.fac]) fail('hull ' + id + ': faction "' + h.fac + '" not in FACTIONS'); // squadron craft (sq) carry no faction by design
    for (const [wk] of (h.w || [])) if (!W[wk]) fail('hull ' + id + ': weapon "' + wk + '" not in W');
    if (h.ab && !ABILITIES[h.ab]) fail('hull ' + id + ': ability "' + h.ab + '" not in ABILITIES');
  }
  ok(Object.keys(HULLS).length + ' hulls checked (faction, weapons, ability)');

  // Variants
  for (const [id, v] of Object.entries(HULL_VARIANTS)) {
    if (!HULLS[v.base]) fail('variant ' + id + ': base hull "' + v.base + '" not in HULLS');
    for (const [wk] of (v.w || [])) if (!W[wk]) fail('variant ' + id + ': weapon "' + wk + '" not in W');
    if (v.mod && v.mod.ab && !ABILITIES[v.mod.ab]) fail('variant ' + id + ': ability "' + v.mod.ab + '" not in ABILITIES');
  }
  ok(Object.keys(HULL_VARIANTS).length + ' variants checked');

  // Admirals
  const cmdIds = new Map(); const facCount = {}; let sharedCmds = 0;
  for (const [id, a] of Object.entries(ADMIRALS)) {
    for (const tpl of (a.start || [])) if (!HULLS[tpl] && !HULL_VARIANTS[tpl]) fail('admiral ' + id + ': starting ship "' + tpl + '" not in HULLS or HULL_VARIANTS');
    if (a.fac) { if (!FACTIONS[a.fac]) fail('admiral ' + id + ': faction "' + a.fac + '" not in FACTIONS'); facCount[a.fac] = (facCount[a.fac] || 0) + 1; }
    if (a.cmd) { if (cmdIds.has(a.cmd.id)) sharedCmds++; else cmdIds.set(a.cmd.id, id); }
  }
  for (const f of Object.keys(FACTIONS)) if (facCount[f] !== 4) warn('faction ' + f + ' has ' + (facCount[f] || 0) + ' admirals (expected 4)');
  if (sharedCmds) console.log('info  ' + sharedCmds + ' of ' + Object.keys(ADMIRALS).length + ' admirals share a Command id with another admiral (the Command pool is shared by design; the council flagged the sameness, the code is consistent)');
  ok(Object.keys(ADMIRALS).length + ' admirals checked (fleets, factions, commands)');

  // Boons: patron exists, and the text/effect functions actually run
  const perPatron = {}; let duos = 0;
  for (const [id, b] of Object.entries(BOONS)) {
    if (b.duo) { duos++; for (const p of b.duo) if (!PATRONS[p]) fail('duo boon ' + id + ': patron "' + p + '" not in PATRONS'); }
    else if (!PATRONS[b.p]) fail('boon ' + id + ': patron "' + b.p + '" not in PATRONS');
    if (b.p) perPatron[b.p] = (perPatron[b.p] || 0) + 1;
    try { b.d(1); b.d(2); b.fx(1); b.fx(2); } catch (e) { fail('boon ' + id + ': its text/effect function throws: ' + e.message); }
  }
  for (const [p, n] of Object.entries(perPatron)) if (n < 4) warn('patron ' + p + ' has only ' + n + ' boons');
  ok(Object.keys(BOONS).length + ' boons checked (' + duos + ' of them duo boons; patron, text and effect functions executed)');

  // Patron glyphs unique
  const glyphs = new Map();
  for (const [id, p] of Object.entries(PATRONS)) { if (glyphs.has(p.glyph)) warn('patrons ' + glyphs.get(p.glyph) + ' and ' + id + ' share glyph "' + p.glyph + '"'); else glyphs.set(p.glyph, id); }

  // Reskin tables point at real things, and actually rename something
  for (const [fac, table] of Object.entries(FAC_WNAMES)) for (const [wk, nm] of Object.entries(table)) {
    if (!W[wk]) fail('FAC_WNAMES.' + fac + ': weapon "' + wk + '" not in W');
    else if (nm === W[wk].n) warn('dead reskin: FAC_WNAMES.' + fac + '.' + wk + ' is still "' + nm + '" (same as the base name)');
  }
  for (const [k] of Object.entries(MOD_NAMES)) { /* keys are module ids per faction tables below */ }
  for (const [fac, table] of Object.entries(MOD_NAMES)) for (const [mid, nm] of Object.entries(table)) {
    if (!MODULES[mid]) fail('MOD_NAMES.' + fac + ': module "' + mid + '" not in MODULES');
    else if (MODULES[mid].n && nm === MODULES[mid].n) warn('dead reskin: MOD_NAMES.' + fac + '.' + mid + ' is still "' + nm + '"');
  }
  for (const [fac, table] of Object.entries(RELIC_NAMES)) for (const [rid, nm] of Object.entries(table)) {
    if (!RELICS[rid]) fail('RELIC_NAMES.' + fac + ': relic "' + rid + '" not in RELICS');
    else if (RELICS[rid].n && nm === RELICS[rid].n) warn('dead reskin: RELIC_NAMES.' + fac + '.' + rid + ' is still "' + nm + '"');
  }
  ok('reskin tables checked (FAC_WNAMES, MOD_NAMES, RELIC_NAMES)');

  // Events: unique ids, string outcomes handled, faction filters valid
  const runSrc = read('campaign_run.js');
  const ids = new Set();
  for (const ev of EVENTS) {
    if (ids.has(ev.id)) fail('duplicate event id "' + ev.id + '"'); ids.add(ev.id);
    for (const f of (ev.not || [])) if (!FACTIONS[f]) fail('event ' + ev.id + ': not-faction "' + f + '" not in FACTIONS');
    for (const f of (ev.only || [])) if (!FACTIONS[f]) fail('event ' + ev.id + ': only-faction "' + f + '" not in FACTIONS');
    for (const o of (ev.o || [])) if (typeof o.r === 'string' && !runSrc.includes("'" + o.r + "'")) fail('event ' + ev.id + ': outcome "' + o.r + '" has no handler in campaign_run.js');
  }
  ok(EVENTS.length + ' events checked (ids, faction filters, outcome handlers)');

  // Sector pool
  SECTOR_POOL.flat().forEach(f => { if (!FACTIONS[f]) fail('SECTOR_POOL names unknown faction "' + f + '"'); });

  // Weapons never mounted anywhere (informational)
  const mounted = new Set();
  Object.values(HULLS).forEach(h => (h.w || []).forEach(([wk]) => mounted.add(wk)));
  Object.values(HULL_VARIANTS).forEach(v => (v.w || []).forEach(([wk]) => mounted.add(wk)));
  const unmounted = Object.keys(W).filter(k => !mounted.has(k));
  if (unmounted.length) warn('weapons never mounted on any hull or variant: ' + unmounted.join(', '));

  // Abilities no hull uses (informational)
  const usedAb = new Set();
  Object.values(HULLS).forEach(h => h.ab && usedAb.add(h.ab));
  Object.values(HULL_VARIANTS).forEach(v => v.mod && v.mod.ab && usedAb.add(v.mod.ab));
  const unusedAb = Object.keys(ABILITIES).filter(k => !usedAb.has(k));
  if (unusedAb.length) warn('abilities no hull or variant uses: ' + unusedAb.join(', '));
}

// ---------- 5. Call sites with no declaration (candidates only) ----------
console.log('\n--- Undeclared call candidates ---');
{
  const all = BUILD_FILES.map(read).join('\n');
  const declared = new Set();
  let m;
  const dRe = /(?:function\s+([A-Za-z_$][\w$]*)|(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=|[{,]\s*([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{)/g;
  while ((m = dRe.exec(all))) { const n = m[1] || m[2] || m[3]; if (n) declared.add(n); }
  // names assigned onto objects (ACT.foo = ..., G.foo = ...) are defined dynamically
  const dynRe = /(?:ACT|G|window|META|RUN|B|SETUP)\.([A-Za-z_$][\w$]*)\s*=/g;
  while ((m = dynRe.exec(all))) declared.add(m[1]);
  const builtins = new Set(['if','for','while','switch','catch','return','typeof','function','new','delete','void','in','of','setTimeout','setInterval','clearTimeout','clearInterval','setImmediate','parseInt','parseFloat','isNaN','isFinite','Number','String','Boolean','Array','Object','Math','JSON','Date','Promise','Error','TypeError','RegExp','Map','Set','WeakMap','Symbol','console','require','eval','encodeURIComponent','decodeURIComponent','requestAnimationFrame','cancelAnimationFrame','addEventListener','removeEventListener','alert','structuredClone','queueMicrotask','fetch','URL','Intl','Reflect','Proxy','BigInt','escape','unescape','Uint8Array','Uint16Array','Uint32Array','Int32Array','Float32Array','Float64Array','ArrayBuffer','DataView','Worker','Blob','Image','Audio','HTMLElement','customElements','getComputedStyle','btoa','atob']);
  const stripped = all.replace(/\/\/[^\n]*/g, '').replace(/\/\*[\s\S]*?\*\//g, '').replace(/'(?:\\.|[^'\\])*'/g, "''").replace(/"(?:\\.|[^"\\])*"/g, '""').replace(/`(?:\\.|[^`\\])*`/g, '``');
  const calls = new Map();
  const cRe = /(?<![\w$.])([A-Za-z_$][\w$]*)\s*\(/g;
  while ((m = cRe.exec(stripped))) { const n = m[1]; if (!declared.has(n) && !builtins.has(n)) calls.set(n, (calls.get(n) || 0) + 1); }
  const top = [...calls.entries()].sort((a, b) => b[1] - a[1]).slice(0, 40);
  if (top.length) { warn(top.length + ' call names have no visible declaration (top 40 shown). Many will be dynamic or Babylon helpers; eyeball for real typos:'); top.forEach(([n, c]) => console.log('        ' + n + ' x' + c)); }
  else ok('every bare call has a visible declaration');
}

// ---------- Summary ----------
console.log('\n===========================');
console.log('SUMMARY: ' + fails + ' FAIL, ' + warns + ' CHECK');
console.log(fails ? 'Fix the FAILs first; they are the kind of thing that bricks a save or throws mid-battle.'
                  : 'No hard failures. Work the CHECK list when you have an hour.');
