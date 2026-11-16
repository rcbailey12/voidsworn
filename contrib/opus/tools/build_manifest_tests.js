'use strict';
// Issue 550 (R214 mechanism 3: provenance checked, not trusted). A normal row in run_all_checks.js (the runner picks up
// every *_tests.js). Reads only files in git; no Blender, no PC.
//
// For every docs/ship_pipeline/build_sheets/SHIP/ that has a manifest.json, the manifest is held against the build sheet
// (feature_table.md). The schema and every rule are in docs/ship_pipeline/build_sheets/manifest_schema.md. It fails when:
//   ROUTE     a part's or a mass's route (kit, hand-built, generated) disagrees with the sheet
//   LIBRARY   a generated part names no reviewed part-library entry
//   INTERIOR  the sheet's INSIDE section names a break piece the manifest gives no interior
//   PARTS     a feature table row has no manifest part, or the other way round (an unlisted part has no checked route)
//   MASSES    the same for the Major masses table
//   COUNT     a part's count or description differs from its feature table row
//   BOUNDS    a manifest break piece is bounded by other break lines than the sheet's, or the sheet does not name it
//   KIT       a kit part on a ship whose manifest names no kit file in git
//   FORMAT    a table or field the check needs is missing or unreadable
// A break piece whose stations drifted from the sheet's break lines is printed as a note, never a failure (the done-when of
// issue 550 lists the three failures above; the A16 manifest predates the R226 seam move).
//
// Then it proves it can fail: the broken fixture under contrib/opus/tools/fixtures/build_manifest_mismatch/ must be refused
// for each of its planted faults, and single-fault copies of the A16 manifest must each be refused for their own reason.
//
// Usage: node contrib/opus/tools/build_manifest_tests.js            the standing check (all sheets, fixture, mutations)
//        node contrib/opus/tools/build_manifest_tests.js <sheet dir> [<part library root>]   one sheet, its problems listed
const fs = require('fs');
const path = require('path');

const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const SHEETS = path.join(ROOT, 'docs', 'ship_pipeline', 'build_sheets');
const LIBRARIES = path.join(ROOT, 'docs', 'ship_pipeline', 'part_libraries');
const FIXTURE = path.join(__dirname, 'fixtures', 'build_manifest_mismatch');
const ROUTES = ['kit', 'hand-built', 'generated'];

// ---------- reading the sheet ----------

function sections(md) {
  const out = {};
  let cur = null;
  for (const line of md.split(/\r?\n/)) {
    const h = /^##\s+(.*)$/.exec(line);
    if (h) { cur = h[1].trim(); out[cur] = []; continue; }
    if (cur) out[cur].push(line);
  }
  return out;
}

function findSection(secs, prefix) {
  const key = Object.keys(secs).find(k => k.toLowerCase().startsWith(prefix.toLowerCase()));
  return key ? secs[key] : null;
}

function cells(line) {
  const t = line.trim().replace(/\\\|/g, '\u0000');
  if (!t.startsWith('|')) return null;
  return t.replace(/^\|/, '').replace(/\|$/, '').split('|').map(c => c.replace(/\u0000/g, '|').trim());
}

// The table in `lines` whose header's first cell is `first`: [{column: value}], header names lower case.
function table(lines, first) {
  if (!lines) return null;
  for (let i = 0; i < lines.length; i++) {
    const head = cells(lines[i]);
    if (!head || head[0].toLowerCase() !== first.toLowerCase()) continue;
    const names = head.map(h => h.toLowerCase());
    const rows = [];
    for (let j = i + 2; j < lines.length; j++) {
      const c = cells(lines[j]);
      if (!c) break;
      const row = {};
      names.forEach((n, k) => { row[n] = c[k] === undefined ? '' : c[k]; });
      rows.push(row);
    }
    return { columns: names, rows };
  }
  return null;
}

// A sheet Route cell: "kit", "hand-built", or "generated: <library>/<entry>".
function parseRoute(cell) {
  const m = /^\s*([a-z-]+)\s*(?::\s*(\S+))?\s*$/i.exec(cell || '');
  if (!m) return { route: String(cell || '').trim(), entry: null };
  return { route: m[1].toLowerCase(), entry: m[2] || null };
}

function readSheet(md) {
  const secs = sections(md);
  const problems = [];
  const feat = table(findSection(secs, 'Feature table'), 'ID');
  const mass = table(findSection(secs, 'Major masses'), 'Mass');
  const inside = findSection(secs, 'INSIDE');
  const brk = table(inside, 'Break line');
  if (!feat) problems.push(['FORMAT', 'the sheet has no "## Feature table" section with an "| ID |" table']);
  if (!mass) problems.push(['FORMAT', 'the sheet has no "## Major masses" section with a "| Mass |" table']);
  if (!inside) problems.push(['FORMAT', 'the sheet has no "## INSIDE" section']);
  else if (!brk) problems.push(['FORMAT', 'the INSIDE section has no "| Break line |" table']);
  const parts = [];
  if (feat) {
    const hasRoute = feat.columns.includes('route');
    for (const r of feat.rows) {
      const rt = hasRoute ? parseRoute(r.route) : { route: 'kit', entry: null };
      parts.push({ id: r.id, what: r.fitting, count: r.count, route: rt.route, entry: rt.entry, routeStated: hasRoute });
    }
  }
  const masses = [];
  if (mass) {
    const hasRoute = mass.columns.includes('route');
    for (const r of mass.rows) masses.push({ name: r.mass, route: hasRoute ? parseRoute(r.route).route : 'hand-built' });
  }
  const lines = [];
  if (brk) {
    for (const r of brk.rows) {
      const st = r['station %'] || '';
      let m = /^\s*([\d.]+)\s+to\s+([\d.]+)\s*\(along\)/i.exec(st);
      if (m) { lines.push({ name: r['break line'], long: true, s0: +m[1], s1: +m[2] }); continue; }
      m = /^\s*([\d.]+)/.exec(st);
      if (m) { lines.push({ name: r['break line'], long: false, s: +m[1] }); continue; }
      problems.push(['FORMAT', 'break line ' + r['break line'] + ' has no readable station: "' + st + '"']);
    }
  }
  return { parts, masses, lines, problems };
}

// The break pieces the sheet's break lines name (the rule of tools/blender/build_sheets/layout.py, stated in
// manifest_schema.md): transverse lines cut the hull into bow piece, midships piece 1..n, stern piece; a line along the
// hull splits every piece it runs through into an upper and a lower half.
function piecesFromLines(lines) {
  const tr = lines.filter(l => !l.long).sort((a, b) => a.s - b.s);
  const lg = lines.filter(l => l.long);
  const edges = [0, ...tr.map(l => l.s), 100];
  const names = ['bow piece', ...tr.slice(1).map((_, i) => 'midships piece ' + (i + 1)), 'stern piece'];
  const out = [];
  for (let i = 0; i < edges.length - 1; i++) {
    const a = edges[i], b = edges[i + 1];
    const bounds = tr.filter(l => l.s === a || l.s === b).map(l => l.name);
    const split = lg.filter(l => l.s0 < b && l.s1 > a).map(l => l.name);
    const nm = names[i] || 'piece ' + i;
    if (split.length) {
      for (const half of ['upper', 'lower']) out.push({ name: nm + ', ' + half + ' half', a, b, bounded_by: bounds.concat(split) });
    } else out.push({ name: nm, a, b, bounded_by: bounds });
  }
  return out;
}

// ---------- part libraries ----------

function loadLibraries(root) {
  const libs = {};
  if (!root || !fs.existsSync(root)) return libs;
  for (const d of fs.readdirSync(root, { withFileTypes: true })) {
    const f = path.join(root, d.name, 'library.json');
    if (!d.isDirectory() || !fs.existsSync(f)) continue;
    try { libs[d.name] = JSON.parse(fs.readFileSync(f, 'utf8')); } catch (e) { libs[d.name] = { error: e.message }; }
  }
  return libs;
}

function reviewedProblem(entryName, libs) {
  const m = /^([^/\s]+)\/([^/\s]+)$/.exec(entryName || '');
  if (!m) return 'names no part-library entry (library_entry must read "<library>/<entry>")';
  const lib = libs[m[1]];
  if (!lib) return 'names library "' + m[1] + '", which has no library.json under docs/ship_pipeline/part_libraries/';
  if (lib.error) return 'library "' + m[1] + '" does not read: ' + lib.error;
  const e = (lib.entries || []).find(x => x && x.id === m[2]);
  if (!e) return 'names entry "' + m[2] + '", which library "' + m[1] + '" does not hold';
  const rv = e.reviewed || {};
  const missing = ['by', 'date', 'ref'].filter(k => !String(rv[k] || '').trim());
  if (missing.length) return 'names entry "' + entryName + '", which is not reviewed (reviewed.' + missing.join(', reviewed.') + ' empty)';
  return null;
}

// ---------- the check ----------

function leadInt(v) {
  const m = /^\s*(\d+)/.exec(String(v));
  return m ? +m[1] : NaN;
}

function checkShip(sheetMd, man, opts = {}) {
  const root = opts.root || ROOT;
  const libs = opts.libs || loadLibraries(opts.libRoot || LIBRARIES);
  const sheet = readSheet(sheetMd);
  const fails = sheet.problems.map(([code, msg]) => ({ code, msg }));
  const notes = [];
  const fail = (code, msg) => fails.push({ code, msg });
  if (!man || typeof man !== 'object') { fail('FORMAT', 'manifest.json does not read as an object'); return { fails, notes }; }
  for (const k of ['parts', 'masses', 'break_pieces']) if (!Array.isArray(man[k])) fail('FORMAT', 'manifest.json has no "' + k + '" list');
  if (fails.some(f => f.code === 'FORMAT')) return { fails, notes };

  // parts: one manifest part per feature table row, the same route
  const byId = new Map();
  for (const p of man.parts) {
    if (byId.has(p.id)) fail('PARTS', 'manifest part ' + p.id + ' is listed twice');
    byId.set(p.id, p);
  }
  const sheetIds = new Set();
  let kitParts = 0;
  for (const s of sheet.parts) {
    if (sheetIds.has(s.id)) fail('PARTS', 'feature table row ' + s.id + ' is listed twice');
    sheetIds.add(s.id);
    const p = byId.get(s.id);
    if (!p) { fail('PARTS', 'feature table row ' + s.id + ' (' + s.what + ') has no manifest part, so its route is never checked'); continue; }
    if (!ROUTES.includes(s.route)) fail('ROUTE', s.id + ': the sheet\'s route "' + s.route + '" is not one of ' + ROUTES.join(', '));
    if (!ROUTES.includes(p.route)) fail('ROUTE', s.id + ': the manifest route "' + p.route + '" is not one of ' + ROUTES.join(', '));
    else if (p.route !== s.route) {
      fail('ROUTE', s.id + ' (' + s.what + '): the manifest says ' + p.route + ', the sheet\'s feature table says ' + s.route +
        (s.routeStated ? '' : ' (no Route column: a feature table row is kit)'));
    }
    if (p.route === 'generated') {
      const why = reviewedProblem(p.library_entry, libs);
      if (why) fail('LIBRARY', s.id + ' is generated but ' + why);
      if (s.entry && p.library_entry && s.entry !== p.library_entry) {
        fail('LIBRARY', s.id + ': the manifest names library entry ' + p.library_entry + ', the sheet names ' + s.entry);
      }
    }
    if (p.route === 'kit') kitParts++;
    if (leadInt(s.count) !== leadInt(p.count)) fail('COUNT', s.id + ': the manifest count ' + p.count + ' differs from the sheet\'s "' + s.count + '"');
    if (String(p.what || '').trim() !== s.what) fail('COUNT', s.id + ': the manifest says "' + p.what + '", the sheet says "' + s.what + '"');
  }
  for (const p of man.parts) if (!sheetIds.has(p.id)) fail('PARTS', 'manifest part ' + p.id + ' is not in the sheet\'s feature table');

  // the kit the kit parts come from must be a file in git
  if (kitParts) {
    const kitFile = man.kit || (/tools\/blender\/kits\/[^\s,;)]+\.py/.exec(man.routes_note || '') || [])[0];
    if (!kitFile) fail('KIT', kitParts + ' kit part(s), but the manifest names no kit file (field "kit" or a tools/blender/kits/... path in routes_note)');
    else if (!fs.existsSync(path.join(root, kitFile))) fail('KIT', 'the manifest\'s kit file ' + kitFile + ' is not in the repository');
  }

  // masses: one manifest mass per Major masses row, the same route
  const massBy = new Map();
  for (const m of man.masses) massBy.set(m.name, m);
  const sheetMasses = new Set(sheet.masses.map(m => m.name));
  for (const s of sheet.masses) {
    const m = massBy.get(s.name);
    if (!m) { fail('MASSES', 'major mass "' + s.name + '" has no manifest mass'); continue; }
    if (m.route !== s.route) fail('ROUTE', 'mass "' + s.name + '": the manifest says ' + m.route + ', the sheet says ' + s.route);
    if (m.route === 'generated') {
      const why = reviewedProblem(m.library_entry, libs);
      if (why) fail('LIBRARY', 'mass "' + s.name + '" is generated but ' + why);
    }
  }
  for (const m of man.masses) if (!sheetMasses.has(m.name)) fail('MASSES', 'manifest mass "' + m.name + '" is not in the sheet\'s Major masses table');

  // break pieces: every piece the INSIDE section's break lines name carries an interior in the manifest
  const want = piecesFromLines(sheet.lines);
  const have = new Map(man.break_pieces.map(b => [b.name, b]));
  const same = (x, y) => x.length === y.length && [...x].sort().join('|') === [...y].sort().join('|');
  for (const w of want) {
    const b = have.get(w.name);
    const where = w.name + ' (' + w.a + ' to ' + w.b + ' percent, bounded by ' + (w.bounded_by.join(', ') || 'no line') + ')';
    if (!b) { fail('INTERIOR', 'the INSIDE section names break piece ' + where + '; the manifest has no such piece, so no interior'); continue; }
    if (b.full_interior !== true) fail('INTERIOR', 'the INSIDE section names break piece ' + where + '; the manifest gives it no interior (full_interior is ' + JSON.stringify(b.full_interior) + ')');
    if (!same(b.bounded_by || [], w.bounded_by)) fail('BOUNDS', w.name + ': the manifest bounds it by ' + JSON.stringify(b.bounded_by) + ', the sheet\'s break lines by ' + JSON.stringify(w.bounded_by));
    const m = /^\s*([\d.]+)\s+to\s+([\d.]+)/.exec(b.stations || '');
    if (m && (Math.abs(+m[1] - w.a) > 0.15 || Math.abs(+m[2] - w.b) > 0.15)) {
      notes.push(w.name + ': the manifest says ' + m[1] + ' to ' + m[2] + ' percent, the sheet\'s break lines give ' + w.a + ' to ' + w.b);
    }
  }
  for (const b of man.break_pieces) if (!want.some(w => w.name === b.name)) fail('BOUNDS', 'manifest break piece "' + b.name + '" is not one the sheet\'s break lines make');
  if (!String(man.insides || '').trim()) fail('INTERIOR', 'the manifest has no "insides" statement');
  return { fails, notes };
}

function checkDir(dir, opts = {}) {
  if (!fs.existsSync(path.join(dir, 'feature_table.md'))) return { fails: [{ code: 'FORMAT', msg: 'no feature_table.md beside manifest.json' }], notes: [] };
  const md = fs.readFileSync(path.join(dir, 'feature_table.md'), 'utf8');
  let man;
  try { man = JSON.parse(fs.readFileSync(path.join(dir, 'manifest.json'), 'utf8')); } catch (e) {
    return { fails: [{ code: 'FORMAT', msg: 'manifest.json does not parse: ' + e.message }], notes: [] };
  }
  return checkShip(md, man, opts);
}

module.exports = { checkShip, checkDir, readSheet, piecesFromLines, loadLibraries };

// ---------- the standing run ----------

function standing() {
  const errors = [];
  const out = s => console.log(s);
  const rel = p => path.relative(ROOT, p).split(path.sep).join('/');

  // 1. every real sheet with a manifest
  const ships = fs.readdirSync(SHEETS, { withFileTypes: true })
    .filter(d => d.isDirectory() && fs.existsSync(path.join(SHEETS, d.name, 'manifest.json'))).map(d => d.name).sort();
  if (!ships.length) errors.push('no build sheet has a manifest.json');
  for (const s of ships) {
    const dir = path.join(SHEETS, s);
    if (!fs.existsSync(path.join(dir, 'feature_table.md'))) { errors.push(s + ': manifest.json has no feature_table.md beside it'); out('FAIL ' + s + ': no feature_table.md'); continue; }
    const r = checkDir(dir);
    if (r.fails.length) {
      for (const f of r.fails) out('FAIL ' + s + ' ' + f.code + ': ' + f.msg);
      errors.push(s + ': ' + r.fails.length + ' problem(s)');
    } else {
      const man = JSON.parse(fs.readFileSync(path.join(dir, 'manifest.json'), 'utf8'));
      const routes = {};
      for (const p of man.parts) routes[p.route] = (routes[p.route] || 0) + 1;
      out('PASS ' + s + ': ' + man.parts.length + ' parts (' + Object.entries(routes).map(([k, v]) => v + ' ' + k).join(', ') +
        '), ' + man.masses.length + ' masses (hand-built), ' + man.break_pieces.length + ' break pieces with interiors, routes and pieces match ' + rel(dir) + '/feature_table.md');
    }
    for (const n of r.notes) out('  note ' + s + ' (not a failure): ' + n);
  }
  for (const must of ['corsair_A16', 'corsair_A17']) if (!ships.includes(must)) errors.push(must + ' has no manifest.json to check');

  // 2. the broken fixture must be refused for each planted fault
  const fx = checkDir(path.join(FIXTURE, 'build_sheets', 'fixture_X1'), { libRoot: path.join(FIXTURE, 'part_libraries') });
  const planted = [
    ['ROUTE', /^K1 /], ['ROUTE', /^mass "Hull slab"/], ['LIBRARY', /^G1 .*names no part-library entry/],
    ['LIBRARY', /^G2 .*not reviewed/], ['LIBRARY', /^G4 .*does not hold/], ['INTERIOR', /midships piece 1 .*gives it no interior/],
    ['INTERIOR', /stern piece .*no such piece/],
  ];
  out('fixture ' + rel(FIXTURE) + ' refused with ' + fx.fails.length + ' problem(s):');
  for (const f of fx.fails) out('  refused ' + f.code + ': ' + f.msg);
  for (const [code, re] of planted) {
    if (!fx.fails.some(f => f.code === code && re.test(f.msg))) errors.push('the fixture was not refused for its planted ' + code + ' fault ' + re);
  }
  if (fx.fails.length !== planted.length) errors.push('the fixture was refused ' + fx.fails.length + ' times, expected exactly the ' + planted.length + ' planted faults');
  if (fx.fails.some(f => /^G3 /.test(f.msg))) errors.push('the fixture\'s G3 names a reviewed library entry and must pass');

  // 3. single-fault copies of the real A16 manifest: each refused for its own reason
  const a16 = path.join(SHEETS, 'corsair_A16');
  if (fs.existsSync(path.join(a16, 'manifest.json'))) {
    const md = fs.readFileSync(path.join(a16, 'feature_table.md'), 'utf8');
    const base = () => JSON.parse(fs.readFileSync(path.join(a16, 'manifest.json'), 'utf8'));
    const cases = [
      ['a kit part marked hand-built', 'ROUTE', m => { m.parts.find(p => p.id === 'T2').route = 'hand-built'; }],
      ['a mass marked kit', 'ROUTE', m => { m.masses[0].route = 'kit'; }],
      ['a made-up route', 'ROUTE', m => { m.parts[0].route = 'ai'; }],
      ['a generated part with no library entry', 'LIBRARY', m => { m.parts[0].route = 'generated'; }],
      ['a break piece with no interior', 'INTERIOR', m => { m.break_pieces[1].full_interior = false; }],
      ['a break piece dropped', 'INTERIOR', m => { m.break_pieces.pop(); }],
      ['a part dropped from the manifest', 'PARTS', m => { m.parts = m.parts.filter(p => p.id !== 'E2'); }],
      ['a part the sheet does not list', 'PARTS', m => { m.parts.push(Object.assign({}, m.parts[0], { id: 'ZZ9' })); }],
      ['a mass renamed', 'MASSES', m => { m.masses[2].name = 'Lower belt'; }],
      ['a count changed', 'COUNT', m => { m.parts.find(p => p.id === 'R1').count = 8; }],
      ['a piece bounded by the wrong line', 'BOUNDS', m => { m.break_pieces[0].bounded_by = ['B-2']; }],
      ['a kit file that is not in git', 'KIT', m => { m.routes_note = 'kit = tools/blender/kits/nowhere/parts.py'; }],
    ];
    for (const [what, code, mut] of cases) {
      const m = base(); mut(m);
      const r = checkShip(md, m);
      const own = r.fails.filter(f => f.code === code);
      if (!own.length) errors.push('A16 with ' + what + ' was not refused for ' + code + (r.fails.length ? ' (got ' + r.fails.map(f => f.code).join(', ') + ')' : ''));
      else out('  refused A16 with ' + what + ': ' + own[0].code + ': ' + own[0].msg);
    }
    // a sheet that states a generated route: the Route column is read, and only a reviewed entry passes
    const withRoute = addRouteColumn(md, id => (id === 'I1' ? 'generated: test_lib/reviewed_dish' : 'kit'));
    const libs = loadLibraries(path.join(FIXTURE, 'part_libraries'));
    const mOk = base(); Object.assign(mOk.parts.find(p => p.id === 'I1'), { route: 'generated', library_entry: 'test_lib/reviewed_dish' });
    const rOk = checkShip(withRoute, mOk, { libs });
    if (rOk.fails.length) errors.push('A16 with I1 generated from a reviewed entry should pass, got: ' + rOk.fails.map(f => f.code + ' ' + f.msg).join('; '));
    else out('  accepted A16 with I1 generated from the reviewed entry test_lib/reviewed_dish (the Route column is read)');
    const mBad = base(); Object.assign(mBad.parts.find(p => p.id === 'I1'), { route: 'generated', library_entry: 'test_lib/unreviewed_claw' });
    const rBad = checkShip(withRoute, mBad, { libs });
    if (!rBad.fails.some(f => f.code === 'LIBRARY')) errors.push('A16 with I1 generated from an unreviewed entry was not refused');
    else out('  refused A16 with I1 generated from an unreviewed entry: ' + rBad.fails.find(f => f.code === 'LIBRARY').msg);
    const rDis = checkShip(withRoute, base(), { libs });
    if (!rDis.fails.some(f => f.code === 'ROUTE' && /^I1 /.test(f.msg))) errors.push('A16 whose sheet says I1 is generated but whose manifest says kit was not refused');
    else out('  refused A16 whose sheet says I1 is generated and whose manifest says kit: ' + rDis.fails.find(f => f.code === 'ROUTE').msg);
  }

  if (errors.length) {
    for (const e of errors) out('FAIL build_manifest_tests: ' + e);
    process.exit(1);
  }
  out('PASS build_manifest_tests: ' + ships.length + ' build sheet manifest(s) match their sheets (' + ships.join(', ') +
    '); the broken fixture is refused for all ' + planted.length + ' planted faults; every single-fault A16 copy is refused for its own reason');
}

// Adds a Route column to the feature table of a sheet (for the self test only).
function addRouteColumn(md, routeOf) {
  const lines = md.split(/\r?\n/);
  let inFeat = false, state = 0;
  for (let i = 0; i < lines.length; i++) {
    if (/^##\s/.test(lines[i])) { inFeat = /^##\s+Feature table/i.test(lines[i]); state = 0; continue; }
    if (!inFeat) continue;
    const c = cells(lines[i]);
    if (!c) { if (state) state = 3; continue; }
    if (state === 0 && c[0] === 'ID') { lines[i] = lines[i].replace(/\|\s*$/, '| Route |'); state = 1; continue; }
    if (state === 1) { lines[i] = lines[i].replace(/\|\s*$/, '|---|'); state = 2; continue; }
    if (state === 2) lines[i] = lines[i].replace(/\|\s*$/, '| ' + routeOf(c[0]) + ' |');
  }
  return lines.join('\n');
}

function single(dir, libRoot) {
  const r = checkDir(path.resolve(dir), { libRoot: libRoot ? path.resolve(libRoot) : LIBRARIES });
  for (const f of r.fails) console.log('FAIL ' + f.code + ': ' + f.msg);
  for (const n of r.notes) console.log('note (not a failure): ' + n);
  if (r.fails.length) { console.log('FAIL ' + dir + ': ' + r.fails.length + ' problem(s); the manifest disagrees with the build sheet'); process.exit(1); }
  console.log('PASS ' + dir + ': the manifest matches the build sheet');
}

if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length) single(args[0], args[1]);
  else standing();
}
