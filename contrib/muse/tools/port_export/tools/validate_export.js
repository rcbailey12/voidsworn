// Voidsworn port spec: export validation.
// Reads ../export/*.json (produced by export_data.js) and checks counts, id
// uniqueness, and cross-reference resolution. Emits validation.json and
// prints a human summary. Usage: node validate_export.js [exportDir]
'use strict';
const fs = require('fs');
const path = require('path');
const dir = process.argv[2] || path.join(__dirname, '..', 'export');
const J = f => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));

const W = J('w.json'), HULLS = J('hulls.json'), FACTIONS = J('factions.json'),
  ABILITIES = J('abilities.json'), MODULES = J('modules.json'), PERKS = J('perks.json'),
  RELICS = J('relics.json'), ADMIRALS = J('admirals.json'), EVENTS = J('events.json'),
  BOONS = J('boons.json'), PATRONS = J('patrons.json'), VARIANTS = J('hull_variants.json'),
  NEM_FAC = J('nem_fac.json'), NEM_WEAK = J('nem_weak.json'), NEM_ADAPT = J('nem_adapt.json'),
  NEM_ADAPT_FAC = J('nem_adapt_fac.json'), NEM_TRAITS = J('nem_traits.json'), NEM_PERSONA = J('nem_persona.json'),
  FAC_WNAMES = J('fac_wnames.json'), FAC_WTRAIT = J('fac_wtrait.json'), WTRAITS = J('wtraits.json'),
  FAC_WPOOL = J('fac_wpool.json'), FAC_PRICE = J('fac_price.json'), RELIC_NAMES = J('relic_names.json'),
  MOD_NEED = J('mod_need.json'), BOON_NEED = J('boon_need.json'), SHIP_NAMES = J('ship_names.json'),
  MORE_SHIP_NAMES = J('more_ship_names.json'), CAP_FIRST = J('cap_first.json'), CAP_LAST = J('cap_last.json'),
  MANIFEST = J('manifest.json');

const findings = [];   // {level: BLOCKER|FIX|NOTE, check, detail}
const passes = [];     // {check, detail}
const F = (level, check, detail) => findings.push({ level, check, detail });
const P = (check, detail) => passes.push({ check, detail });
const facIds = Object.keys(FACTIONS);
const has = (o, k) => Object.prototype.hasOwnProperty.call(o, k);

// ---- counts -------------------------------------------------------------
const counts = {};
for (const [name, t] of Object.entries(MANIFEST.tables)) if (!t.missing) counts[name] = t.count;
P('counts', JSON.stringify(counts));

// ---- array duplicate checks --------------------------------------------
function dupes(arr) { const s = new Set(), d = []; for (const x of arr) { if (s.has(x)) d.push(x); s.add(x); } return d; }
for (const [nm, arr] of [['SHIP_NAMES', SHIP_NAMES], ['CAP_FIRST', CAP_FIRST], ['CAP_LAST', CAP_LAST]]) {
  const d = dupes(arr); if (d.length) F('NOTE', nm + ' duplicates', d.join(', ')); else P(nm + ' unique', arr.length + ' entries');
}
for (const f of Object.keys(MORE_SHIP_NAMES)) {
  const d = dupes(MORE_SHIP_NAMES[f]); if (d.length) F('NOTE', 'MORE_SHIP_NAMES.' + f + ' duplicates', d.join(', '));
}
const evIds = EVENTS.map(e => e.id);
{ const d = dupes(evIds); if (d.length) F('FIX', 'EVENTS duplicate ids', d.join(', ')); else P('EVENTS ids unique', evIds.length + ' events'); }

// ---- weapons -------------------------------------------------------------
const wKeys = Object.keys(W).sort();
for (let i = 0; i < wKeys.length; i++) for (let j = i + 1; j < wKeys.length; j++) {
  const a = W[wKeys[i]], b = W[wKeys[j]];
  const strip = o => { const c = { ...o }; delete c.n; return JSON.stringify(c); };
  if (strip(a) === strip(b)) F('FIX', 'weapon definitions identical except name', wKeys[i] + ' == ' + wKeys[j] + ' : ' + strip(a));
}
P('weapons defined', wKeys.length + ' weapons: ' + wKeys.join(', '));

// ---- hulls ---------------------------------------------------------------
let rearArc = [], badFac = [], badWeapon = [], badAb = [], noReanimateDeathless = [];
for (const [id, h] of Object.entries(HULLS)) {
  if (!facIds.includes(h.fac)) {
    if (h.sq && h.fac === undefined) P('factionless squadron template (intentional)', id + ' is a generic wing template (data.js:70-71); the port must not assume every HULLS entry has fac');
    else badFac.push(id + ' fac=' + h.fac);
  }
  for (const [wid, arc] of (h.w || [])) {
    if (!has(W, wid)) badWeapon.push(id + ' mounts unknown weapon ' + wid);
    if (arc === 'R') rearArc.push(id + ' mounts ' + wid + ' in rear arc');
    if (!['F', 'P', 'S', 'T', 'R'].includes(arc)) badWeapon.push(id + ' bad arc ' + arc);
  }
  if (h.ab && !has(ABILITIES, h.ab)) badAb.push(id + ' ability ' + h.ab);
  if (h.fac === 'deathless' && !h.reanimate) noReanimateDeathless.push(id);
}
if (badFac.length) F('FIX', 'hull faction refs', badFac.join('; ')); else P('hull faction refs', 'all ' + Object.keys(HULLS).length + ' hulls name a defined faction');
if (badWeapon.length) F('FIX', 'hull weapon refs', badWeapon.join('; ')); else P('hull weapon refs', 'every mount resolves to a defined weapon');
if (badAb.length) F('FIX', 'hull ability refs', badAb.join('; ')); else P('hull ability refs', 'every hull ability resolves to ABILITIES');
if (rearArc.length) F('NOTE', 'rear-arc mounts (fiction rule: guns never face backward)', rearArc.join('; '));
F('NOTE', 'deathless hulls without reanimate field', noReanimateDeathless.join(', ') || 'none');

// ---- factions ------------------------------------------------------------
for (const [f, Fd] of Object.entries(FACTIONS)) {
  for (const hid of (Fd.roster || [])) {
    if (!has(HULLS, hid)) F('FIX', 'faction roster', f + ' roster names unknown hull ' + hid);
    else if (HULLS[hid].fac !== f) F('FIX', 'faction roster', f + ' roster includes ' + hid + ' whose fac is ' + HULLS[hid].fac);
  }
  if (Fd.boss && !has(HULLS, Fd.boss)) F('FIX', 'faction boss', f + ' boss ' + Fd.boss + ' not a hull');
}
P('faction rosters checked', facIds.join(', '));

// ---- admirals --------------------------------------------------------------
for (const [id, a] of Object.entries(ADMIRALS)) {
  if (!facIds.includes(a.fac)) F('FIX', 'admiral faction', id + ' fac=' + a.fac);
  for (const hid of (a.start || [])) if (!has(HULLS, hid)) F('FIX', 'admiral start fleet', id + ' starts with unknown hull ' + hid);
  if (!a.cmd || !a.cmd.id) F('NOTE', 'admiral command', id + ' has no cmd.id');
}
P('admirals checked', Object.keys(ADMIRALS).length + ' admirals');

// ---- variants --------------------------------------------------------------
const wmult = h => { const m = {}; for (const [wid] of (h.w || [])) m[wid] = (m[wid] || 0) + 1; return m; };
const variantDiffs = [];
for (const [vid, v] of Object.entries(VARIANTS)) {
  if (!has(HULLS, v.base)) { F('FIX', 'variant base', vid + ' base ' + v.base + ' unknown'); continue; }
  if (v.w) {
    const b = wmult(HULLS[v.base]), n = wmult(v);
    const removed = [], added = [];
    for (const k of new Set([...Object.keys(b), ...Object.keys(n)])) {
      if ((b[k] || 0) > (n[k] || 0)) removed.push(k + ' x' + ((b[k] || 0) - (n[k] || 0)));
      if ((n[k] || 0) > (b[k] || 0)) added.push(k + ' x' + ((n[k] || 0) - (b[k] || 0)));
    }
    if (removed.length) variantDiffs.push(vid + ' (base ' + v.base + ') removes: ' + removed.join(', ') + (added.length ? '; adds: ' + added.join(', ') : '') + ' | d: "' + (v.d || '') + '"');
  }
}
for (const d of variantDiffs) F('NOTE', 'variant weapon removal vs base (disclosure judged in spec)', d);
P('variants checked', Object.keys(VARIANTS).length + ' variants, ' + variantDiffs.length + ' with weapon removals');

// ---- boons / patrons --------------------------------------------------------
for (const [id, b] of Object.entries(BOONS)) {
  if (b.p && !has(PATRONS, b.p)) F('FIX', 'boon patron', id + ' patron ' + b.p);
  if (b.duo) for (const p of b.duo) if (!has(PATRONS, p)) F('FIX', 'boon duo patron', id + ' duo ' + p);
}
for (const k of Object.keys(BOON_NEED)) if (!has(BOONS, k)) F('FIX', 'BOON_NEED key', k + ' not a boon');
P('boons checked', Object.keys(BOONS).length + ' boons, patrons: ' + Object.keys(PATRONS).join(', '));

// ---- relics ------------------------------------------------------------------
const relicCov = {};
for (const f of facIds) {
  const row = RELIC_NAMES[f];
  if (!row) { relicCov[f] = 'NO RELIC_NAMES ROW'; F('NOTE', 'RELIC_NAMES coverage', f + ' has no RELIC_NAMES row at all (all relic names fall back to base names)'); continue; }
  relicCov[f] = Object.keys(row).length + ' of ' + Object.keys(RELICS).length;
  for (const rid of Object.keys(row)) if (!has(RELICS, rid)) F('FIX', 'RELIC_NAMES id', f + ' renames unknown relic ' + rid);
}
P('relic name coverage', JSON.stringify(relicCov));

// ---- nemesis -------------------------------------------------------------------
for (const f of Object.keys(NEM_FAC)) if (!facIds.includes(f)) F('FIX', 'NEM_FAC key', f + ' not a faction');
for (const [f, nf] of Object.entries(NEM_FAC)) for (const p of (nf.personas || [])) if (!has(NEM_PERSONA, p)) F('FIX', 'NEM_FAC persona', f + ' persona ' + p + ' not in NEM_PERSONA');
for (const f of Object.keys(NEM_ADAPT_FAC)) if (!facIds.includes(f)) F('FIX', 'NEM_ADAPT_FAC key', f);
P('nemesis tables checked', 'weaknesses: ' + Object.keys(NEM_WEAK).length + ', adaptations: ' + Object.keys(NEM_ADAPT).length + ', traits: ' + Object.keys(NEM_TRAITS).length);

// ---- faction weapon naming / traits / pools --------------------------------------
for (const [f, m] of Object.entries(FAC_WNAMES)) {
  if (!facIds.includes(f)) F('FIX', 'FAC_WNAMES key', f);
  for (const wid of Object.keys(m)) if (!has(W, wid)) F('FIX', 'FAC_WNAMES weapon', f + ' renames unknown weapon ' + wid);
}
for (const [f, m] of Object.entries(FAC_WTRAIT)) for (const [wid, t] of Object.entries(m)) {
  if (!has(W, wid)) F('FIX', 'FAC_WTRAIT weapon', f + '.' + wid);
  if (!has(WTRAITS, t)) F('FIX', 'FAC_WTRAIT trait', f + '.' + wid + ' -> ' + t);
}
// recompute FAC_WPOOL from HULLS and compare with the shipped computed table
{
  const recomp = {};
  for (const f of facIds) recomp[f] = [...new Set(Object.values(HULLS).filter(h => h.fac === f).flatMap(h => (h.w || []).map(x => x[0])))].sort();
  for (const f of facIds) if (JSON.stringify(recomp[f]) !== JSON.stringify([...(FAC_WPOOL[f] || [])].sort()))
    F('FIX', 'FAC_WPOOL mismatch', f + ': shipped ' + JSON.stringify(FAC_WPOOL[f]) + ' vs recomputed ' + JSON.stringify(recomp[f]));
  P('FAC_WPOOL recomputed', 'matches shipped table for all factions unless flagged above');
}

// ---- price table coverage ---------------------------------------------------------
for (const f of facIds) {
  const classes = new Set(Object.values(HULLS).filter(h => h.fac === f).map(h => h.cls));
  const priced = FAC_PRICE[f] || {};
  const missing = [...classes].filter(c => !(c in priced));
  if (missing.length) F('NOTE', 'FAC_PRICE missing class keys (falls back to x1.0)', f + ': ' + missing.join(', '));
}

// ---- mod_need -----------------------------------------------------------------------
for (const k of Object.keys(MOD_NEED)) if (!has(MODULES, k)) F('FIX', 'MOD_NEED key', k + ' not a module');
P('modules checked', Object.keys(MODULES).length + ' modules, ' + Object.keys(PERKS).length + ' perks');

// ---- known-finding verification ------------------------------------------------------
{
  const strip = o => { const c = { ...o }; delete c.n; return c; };
  F('NOTE', 'KNOWN: flak vs gsentry', 'field-identical except name: ' + (JSON.stringify(strip(W.flak)) === JSON.stringify(strip(W.gsentry))) + ' | flak=' + JSON.stringify(W.flak) + ' gsentry=' + JSON.stringify(W.gsentry));
  F('NOTE', 'KNOWN: d_boss reanimate', 'd_boss.reanimate = ' + HULLS.d_boss.reanimate + '; deathless hulls WITH reanimate: ' + Object.entries(HULLS).filter(([, h]) => h.reanimate).map(([i]) => i).join(', '));
  const asc = HULLS.ascendant, cath = HULLS.cathedral;
  if (asc && cath) F('NOTE', 'KNOWN: ascendant vs cathedral', 'ascendant cp' + asc.cp + ' sp' + asc.sp + ' cost ' + asc.cost + ' w=' + JSON.stringify(asc.w) + ' | cathedral cp' + cath.cp + ' sp' + cath.sp + ' cost ' + cath.cost + ' w=' + JSON.stringify(cath.w));
  F('NOTE', 'KNOWN: d_meridian in HULLS', String(has(HULLS, 'd_meridian')) + ' (battleship entry filed Oct 29 is a proposal, not in data.js at the pin)');
  const al = SHIP_NAMES.includes('Acceptable Loss');
  F('NOTE', 'KNOWN: Acceptable Loss in Crusade SHIP_NAMES', String(al) + ' (Oct 28 ruling swapped it out; still present at pin)');
}

const report = { pin: '264f441d43a54e3679950dcc4457133b40811807', counts, passes, findings };
fs.writeFileSync(path.join(dir, 'validation.json'), JSON.stringify(report, null, 1) + '\n');
console.log('PASSES:', passes.length, 'FINDINGS:', findings.length);
for (const f of findings) console.log('[' + f.level + ']', f.check, '::', f.detail);
