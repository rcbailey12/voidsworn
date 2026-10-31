// table_xref.js - structural cross-reference validator for the data tables.
//
// Loads the shipped tables through ../game_loader and checks that every
// id one table speaks is defined by the table that owns it. This is the
// class of error the Oct 29 naming QA pass checked by hand (admiral in the
// wrong faction, FAC_PRICE miskeying, weapon-id mismatches); here it is a
// script that can run after any data edit.
//
// FAILURES (exit 1): a dangling or crossed reference.
//   - faction roster and boss ids exist in HULLS
//   - a roster/boss hull's fac field agrees with the faction listing it
//   - every hull weapon id exists in W, and its arc exists in ARC_NAME
//   - variant bases exist; variant weapon ids exist in W
//   - admiral fac is a real faction; admiral start hulls exist; an
//     admiral's start hulls belong to their own faction (roster, boss,
//     variant of either, or a hull whose fac field matches)
//   - boon patron ids (p, or each of duo) exist in PATRONS
//   - BOON_NEED keys exist in BOONS
//   - MODULES.only names an ability at least one hull carries
//   - RELIC_NAMES rows are factions and their keys are relics
//   - FAC_PRICE rows are factions; FAC_GATES rows are factions and their
//     noKind values are weapon kinds present in W
//   - a faction's sq names a squadron hull (a HULLS entry with that sq)
//
// WARNINGS (printed, exit stays 0): things that are legal today but are
// the known shape of a future defect.
//   - cross-table id collisions beyond the allowlist (RELICS x MODULES
//     'cogitator' is allowlisted: verified namespace-explicit everywhere
//     in the Oct 29 relics audit)
//   - a faction with a non-empty FAC_PRICE row whose roster or boss uses
//     a hull class the row does not price (the price falls back to x1;
//     this is the gap the Oct 29 faction-shape audit found around the
//     ruled Eclipse battleship: no Battleship key, price inversion)
//   - factions whose admiral count is not four
//   - relic display-name coverage per faction (informational; partial
//     coverage is by design, the counts are the audit trail)
//
// Usage: node table_xref.js [repoDir]
'use strict';
const { loadGame } = require('../game_loader');
const path = require('path');

const repoDir = process.argv[2] || path.resolve(__dirname, '..', '..', '..', '..', '..');
const G = loadGame(repoDir);
const { HULLS, FACTIONS, ADMIRALS, RELICS, MODULES, BOONS, PATRONS, W, HULL_VARIANTS, FAC_PRICE, RELIC_NAMES, BOON_NEED, ARC_NAME, FAC_GATES } = G;

let failures = [], warnings = [];
const fail = m => failures.push(m);
const warn = m => warnings.push(m);
const has = (T, k) => Object.prototype.hasOwnProperty.call(T, k);

// Factions, rosters, bosses.
for (const [fid, F] of Object.entries(FACTIONS)) {
  for (const id of F.roster) {
    if (!has(HULLS, id)) { fail(fid + ' roster names missing hull ' + id); continue; }
    if (HULLS[id].fac && HULLS[id].fac !== fid) fail(fid + ' roster hull ' + id + ' has fac ' + HULLS[id].fac);
  }
  if (!has(HULLS, F.boss)) fail(fid + ' boss names missing hull ' + F.boss);
  else if (HULLS[F.boss].fac && HULLS[F.boss].fac !== fid) fail(fid + ' boss ' + F.boss + ' has fac ' + HULLS[F.boss].fac);
  // F.sq is a HULLS key: wingKind returns it and the launch code reads
  // HULLS[kind] as the wing template (battle.js wingKind / spawnWing).
  // The template's own sq field is its flight role, which need not match:
  // the Chorus spore template flies the bomber role.
  if (F.sq && !(has(HULLS, F.sq) && HULLS[F.sq].sq)) fail(fid + ' sq ' + F.sq + ' is not a squadron hull key');
}

// Hull weapons and arcs.
for (const [id, h] of Object.entries(HULLS)) {
  for (const [wid, arc] of h.w || []) {
    if (!has(W, wid)) fail('hull ' + id + ' mounts unknown weapon ' + wid);
    if (!has(ARC_NAME, arc)) fail('hull ' + id + ' weapon ' + wid + ' has unknown arc ' + arc);
  }
}

// Variants.
for (const [id, v] of Object.entries(HULL_VARIANTS)) {
  if (!has(HULLS, v.base)) fail('variant ' + id + ' bases on missing hull ' + v.base);
  for (const [wid, arc] of v.w || []) {
    if (!has(W, wid)) fail('variant ' + id + ' mounts unknown weapon ' + wid);
    if (!has(ARC_NAME, arc)) fail('variant ' + id + ' weapon ' + wid + ' has unknown arc ' + arc);
  }
}

// Admirals.
const perFaction = {};
for (const [id, a] of Object.entries(ADMIRALS)) {
  if (!has(FACTIONS, a.fac)) { fail('admiral ' + id + ' has unknown fac ' + a.fac); continue; }
  perFaction[a.fac] = (perFaction[a.fac] || 0) + 1;
  const F = FACTIONS[a.fac];
  const own = new Set([...F.roster, F.boss]);
  for (const t of a.start || []) {
    if (!has(HULLS, t)) { fail('admiral ' + id + ' starts with missing hull ' + t); continue; }
    const base = HULLS[t].variant ? HULLS[t].base : t;
    if (!own.has(base) && HULLS[t].fac !== a.fac) fail('admiral ' + id + ' (' + a.fac + ') starts with foreign hull ' + t);
  }
}
for (const fid of Object.keys(FACTIONS)) if (perFaction[fid] !== 4) warn('faction ' + fid + ' has ' + (perFaction[fid] || 0) + ' admirals, not four');

// Boons and patrons.
for (const [id, b] of Object.entries(BOONS)) {
  const ps = b.p ? [b.p] : (b.duo || []);
  for (const p of ps) if (!has(PATRONS, p)) fail('boon ' + id + ' names unknown patron ' + p);
}
for (const id of Object.keys(BOON_NEED)) if (!has(BOONS, id)) fail('BOON_NEED names unknown boon ' + id);

// Modules: ability gates must name a real hull ability.
const abilities = new Set(Object.values(HULLS).map(h => h.ab).filter(Boolean));
for (const [id, m] of Object.entries(MODULES)) if (m.only && !abilities.has(m.only)) fail('module ' + id + ' gates on unknown ability ' + m.only);

// Relic display names.
for (const [fid, row] of Object.entries(RELIC_NAMES)) {
  if (!has(FACTIONS, fid)) { fail('RELIC_NAMES row for unknown faction ' + fid); continue; }
  for (const rid of Object.keys(row)) if (!has(RELICS, rid)) fail('RELIC_NAMES.' + fid + ' names unknown relic ' + rid);
}
for (const fid of Object.keys(FACTIONS)) {
  const n = RELIC_NAMES[fid] ? Object.keys(RELIC_NAMES[fid]).length : 0;
  warn('relic display-name coverage: ' + fid + ' ' + n + ' of ' + Object.keys(RELICS).length);
}

// Prices and gates.
for (const fid of Object.keys(FAC_PRICE)) if (!has(FACTIONS, fid)) fail('FAC_PRICE row for unknown faction ' + fid);
const kinds = new Set(Object.values(W).map(w => w.k));
for (const [fid, g] of Object.entries(FAC_GATES)) {
  if (!has(FACTIONS, fid)) fail('FAC_GATES row for unknown faction ' + fid);
  for (const k of g.noKind || []) if (!kinds.has(k)) fail('FAC_GATES.' + fid + ' bans unknown weapon kind ' + k);
}
for (const [fid, F] of Object.entries(FACTIONS)) {
  const row = FAC_PRICE[fid] || {};
  // Sparse rows are a design tool (only listed classes get a multiplier),
  // and an empty row prices everything x1 on purpose (hegemony). The gap
  // that matters is a capital class: the boss hull's class, or a roster
  // class at cp>=4, in a faction whose row otherwise prices its line.
  if (Object.keys(row).length < 2) continue;
  const capital = new Set();
  if (HULLS[F.boss]) capital.add(HULLS[F.boss].cls);
  for (const id of F.roster) if (HULLS[id] && (HULLS[id].cp || 1) >= 4) capital.add(HULLS[id].cls);
  for (const cls of capital) if (cls && !has(row, cls)) warn(fid + ' FAC_PRICE has no ' + cls + ' key; its capital hulls price at the x1 fallback while the row prices the rest of the line');
}

// Cross-table id collisions.
const ALLOW = new Set(['RELICS|MODULES|cogitator']);
const tables = { HULLS, ADMIRALS, RELICS, MODULES, BOONS, PATRONS };
const names = Object.keys(tables);
for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) {
  for (const id of Object.keys(tables[names[i]])) {
    if (has(tables[names[j]], id) && !ALLOW.has(names[i] + '|' + names[j] + '|' + id)) {
      warn('id collision: ' + id + ' exists in both ' + names[i] + ' and ' + names[j]);
    }
  }
}

console.log('table_xref: ' + failures.length + ' failures, ' + warnings.length + ' warnings');
for (const f of failures) console.log('FAIL ' + f);
for (const w of warnings) console.log('WARN ' + w);
process.exit(failures.length ? 1 : 0);
