#!/usr/bin/env node
'use strict';
/*
 * oracle_drift_guard.js: one-command drift check for the Godot port's vendored JS oracles
 * and its hand-copied render/world constants.
 *
 * Run from the repo clone root:
 *   node contrib/muse/tools/oracle_drift/oracle_drift_guard.js
 * Or from anywhere:
 *   node oracle_drift_guard.js /path/to/clone
 * Machine-readable output:
 *   node oracle_drift_guard.js --json
 *
 * What it checks:
 *   (a) battle.js, data.js and core.js at the repo root vs godot/rules/test/oracle/
 *       vs godot/campaign/test/oracle/: SHA-256 equality, and for differing pairs a
 *       line-level diff summary (added / removed line counts, first differing lines).
 *   (b) The pin claims in the two oracle READMEs: the commit each README says its files
 *       were copied from, verified against git history when git is available, plus
 *       whether the vendored copies still match the live root files.
 *   (c) Hand-copied constants (FAC3D, AI_HULLS, CLS_LEN, FINISH, BIOMES, ROCKS, PLANETS):
 *       browser definitions vs Godot definitions, values compared entry by entry.
 *
 * The guard reports facts. It does not edit anything and it exits 0 on a completed run
 * even when drift is found; exit 2 means the run itself failed (missing files, bad root).
 * No dependencies beyond Node itself. Output is deterministic: sorted keys, no timestamps.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

// ---------------------------------------------------------------- small helpers

function fail(msg) {
  console.error('oracle_drift_guard: ' + msg);
  process.exit(2);
}

function readText(p) {
  return fs.readFileSync(p, 'utf8');
}

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

function num(x) {
  const n = parseFloat(x);
  return Number.isFinite(n) ? n : NaN;
}

function fmtNum(n) {
  if (!Number.isFinite(n)) return String(n);
  return String(Number(n.toFixed(6)));
}

function fmtVec(v) {
  return '[' + v.map(fmtNum).join(', ') + ']';
}

function vecEq(a, b) {
  if (!a || !b || a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) if (Math.abs(a[i] - b[i]) > 1e-9) return false;
  return true;
}

// Extract the balanced literal (open/close pair) that starts at or after index `from`.
// String-aware and comment-aware: // and /* */ comments are skipped everywhere, and
// # comments are skipped when opts.hashComments is set (GDScript files).
function extractLiteral(text, from, open, close, opts) {
  const hashComments = !!(opts && opts.hashComments);
  const start = text.indexOf(open, from);
  if (start < 0) return null;
  let depth = 0, inStr = null, esc = false, lineCom = false, blockCom = false;
  for (let i = start; i < text.length; i++) {
    const ch = text[i], nx = text[i + 1];
    if (lineCom) { if (ch === '\n') lineCom = false; continue; }
    if (blockCom) { if (ch === '*' && nx === '/') { blockCom = false; i++; } continue; }
    if (inStr) {
      if (esc) esc = false;
      else if (ch === '\\') esc = true;
      else if (ch === inStr) inStr = null;
      continue;
    }
    if (ch === '/' && nx === '/') { lineCom = true; i++; continue; }
    if (ch === '/' && nx === '*') { blockCom = true; i++; continue; }
    if (hashComments && ch === '#') { lineCom = true; continue; }
    if (ch === "'" || ch === '"' || ch === '`') { inStr = ch; continue; }
    if (ch === open) depth++;
    else if (ch === close) { depth--; if (depth === 0) return text.slice(start, i + 1); }
  }
  return null;
}

function extractBraced(text, from, opts) { return extractLiteral(text, from, '{', '}', opts); }
function extractBracketed(text, from, opts) { return extractLiteral(text, from, '[', ']', opts); }

// Find "NAME =" / "NAME :=" / "NAME=" and return the index just past the equals sign.
function findAssign(text, name) {
  const re = new RegExp('(^|[^A-Za-z0-9_])' + name + '\\s*:?=', 'm');
  const m = re.exec(text);
  return m ? m.index + m[0].length : -1;
}

// Line-level diff via LCS. Files here are at most a few thousand lines, so the
// quadratic table is fine (1402 x 1402 worst case, a few MB).
function diffLines(aText, bText) {
  const a = aText.split('\n'), b = bText.split('\n');
  const n = a.length, m = b.length;
  const dp = new Int32Array((n + 1) * (m + 1));
  const W = m + 1;
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      dp[i * W + j] = a[i] === b[j]
        ? dp[(i + 1) * W + j + 1] + 1
        : Math.max(dp[(i + 1) * W + j], dp[i * W + j + 1]);
    }
  }
  let i = 0, j = 0, added = 0, removed = 0;
  const firstDiffs = [];
  while (i < n && j < m) {
    if (a[i] === b[j]) { i++; j++; continue; }
    if (dp[(i + 1) * W + j] >= dp[i * W + j + 1]) {
      removed++;
      if (firstDiffs.length < 5) firstDiffs.push({ aLine: i + 1, bLine: j + 1, kind: 'removed' });
      i++;
    } else {
      added++;
      if (firstDiffs.length < 5) firstDiffs.push({ aLine: i + 1, bLine: j + 1, kind: 'added' });
      j++;
    }
  }
  while (i < n) { removed++; if (firstDiffs.length < 5) firstDiffs.push({ aLine: i + 1, bLine: j + 1, kind: 'removed' }); i++; }
  while (j < m) { added++; if (firstDiffs.length < 5) firstDiffs.push({ aLine: i + 1, bLine: j + 1, kind: 'added' }); j++; }
  return { added, removed, firstDiffs, aLines: n, bLines: m };
}

// ---------------------------------------------------------------- (a) vendored copies

const ORACLE_DIRS = [
  { id: 'root', rel: '' },
  { id: 'rules-oracle', rel: 'godot/rules/test/oracle' },
  { id: 'campaign-oracle', rel: 'godot/campaign/test/oracle' },
];
const VENDORED_FILES = ['battle.js', 'data.js', 'core.js'];

function checkVendoredCopies(root) {
  const out = { files: {} };
  for (const f of VENDORED_FILES) {
    const entry = { locations: {}, pairs: [] };
    for (const loc of ORACLE_DIRS) {
      const p = path.join(root, loc.rel, f);
      if (!fs.existsSync(p)) { entry.locations[loc.id] = { missing: true }; continue; }
      const text = readText(p);
      entry.locations[loc.id] = {
        sha256: sha256(text).slice(0, 16),
        bytes: Buffer.byteLength(text, 'utf8'),
        lines: text.split('\n').length,
      };
    }
    for (let x = 0; x < ORACLE_DIRS.length; x++) {
      for (let y = x + 1; y < ORACLE_DIRS.length; y++) {
        const A = ORACLE_DIRS[x].id, B = ORACLE_DIRS[y].id;
        const pa = path.join(root, ORACLE_DIRS[x].rel, f);
        const pb = path.join(root, ORACLE_DIRS[y].rel, f);
        if (!fs.existsSync(pa) || !fs.existsSync(pb)) continue;
        const ta = readText(pa), tb = readText(pb);
        const pair = { a: A, b: B, equal: sha256(ta) === sha256(tb) };
        if (!pair.equal) pair.diff = diffLines(ta, tb);
        entry.pairs.push(pair);
      }
    }
    out.files[f] = entry;
  }
  return out;
}

// ---------------------------------------------------------------- (b) README pin claims

function gitShow(root, pin, file) {
  try {
    return execFileSync('git', ['-C', root, 'show', pin + ':' + file], { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024, stdio: ['ignore', 'pipe', 'ignore'] });
  } catch (e) {
    return null;
  }
}

function gitHead(root) {
  try {
    return execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
  } catch (e) {
    return null;
  }
}

function checkPinClaims(root) {
  const suites = [
    { id: 'rules-oracle', dir: 'godot/rules/test/oracle' },
    { id: 'campaign-oracle', dir: 'godot/campaign/test/oracle' },
  ];
  const out = { head: gitHead(root), suites: [] };
  for (const s of suites) {
    const dirAbs = path.join(root, s.dir);
    const readmes = fs.existsSync(dirAbs)
      ? fs.readdirSync(dirAbs).filter(f => /^README/i.test(f)).sort()
      : [];
    const suite = { id: s.id, readmes, claims: [] };
    for (const rm of readmes) {
      const text = readText(path.join(dirAbs, rm));
      const pinMatch = /from commit ([0-9a-f]{7,40})/.exec(text);
      const allTokens = [...new Set([...text.matchAll(/\b[0-9a-f]{7}\b/g)].map(m => m[0]))];
      const claim = { readme: rm, allCommitTokens: allTokens };
      if (pinMatch) {
        claim.pin = pinMatch[1];
        claim.files = {};
        const vendoredHere = fs.readdirSync(dirAbs).filter(f => f.endsWith('.js')).sort();
        for (const f of vendoredHere) {
          const vendoredText = readText(path.join(dirAbs, f));
          const rec = { matchesRootWorkingTree: null, matchesPinContent: null };
          const rootFile = path.join(root, f);
          if (fs.existsSync(rootFile)) rec.matchesRootWorkingTree = sha256(vendoredText) === sha256(readText(rootFile));
          const pinned = gitShow(root, claim.pin, f);
          if (pinned !== null) rec.matchesPinContent = sha256(vendoredText) === sha256(pinned);
          claim.files[f] = rec;
        }
      }
      // Secondary claim in the rules README: core.js unchanged since a named commit.
      const coreSince = /core\.js is unchanged since ([0-9a-f]{7,40})/.exec(text);
      if (coreSince) {
        const pinned = gitShow(root, coreSince[1], 'core.js');
        const vendored = path.join(dirAbs, 'core.js');
        claim.coreUnchangedSince = {
          commit: coreSince[1],
          holds: pinned !== null && fs.existsSync(vendored) ? sha256(pinned) === sha256(readText(vendored)) : null,
        };
      }
      // The campaign README discloses one deliberate fix in its vendored campaign3d.js.
      if (/campaign3d\.js`?\s+line 56/.test(text) && fs.existsSync(path.join(dirAbs, 'campaign3d.js'))) {
        const vendoredText = readText(path.join(dirAbs, 'campaign3d.js'));
        const rec = { disclosedFix: 'campaign3d.js line 56 comment move' };
        if (claim.pin) {
          const pinned = gitShow(root, claim.pin, 'campaign3d.js');
          if (pinned !== null) {
            const d = diffLines(pinned, vendoredText);
            rec.vsPin = { added: d.added, removed: d.removed, firstDiffLines: d.firstDiffs.map(x => x.aLine) };
          }
        }
        const rootFile = path.join(root, 'campaign3d.js');
        if (fs.existsSync(rootFile)) {
          const d = diffLines(readText(rootFile), vendoredText);
          rec.vsRootWorkingTree = { added: d.added, removed: d.removed, firstDiffLines: d.firstDiffs.map(x => x.bLine) };
        }
        claim.campaign3dFix = rec;
        // The one file that differs from its pin is the README's own disclosed fix:
        // mark it so the summary does not count a documented exception as a broken claim.
        if (claim.files && claim.files['campaign3d.js'] && claim.files['campaign3d.js'].matchesPinContent === false) {
          claim.files['campaign3d.js'].disclosedException = true;
        }
      }
      suite.claims.push(claim);
    }
    out.suites.push(suite);
  }
  return out;
}

// ---------------------------------------------------------------- (c) constants

function literalAt(text, name, opts) {
  const idx = findAssign(text, name);
  if (idx < 0) return null;
  return extractBraced(text, idx, opts);
}

function literalArrayAt(text, name, opts) {
  const idx = findAssign(text, name);
  if (idx < 0) return null;
  return extractBracketed(text, idx, opts);
}

function parseVecList(s) {
  return s.split(',').map(x => num(x.trim())).filter(x => Number.isFinite(x) || true);
}

// 'key': value / "key": value / bare: value pairs inside an object literal.
function topEntries(lit, opts) {
  // Returns [{key, valueText}] for the top level of an object literal.
  const hashComments = !!(opts && opts.hashComments);
  const out = [];
  let i = 1; // skip opening brace
  const n = lit.length;
  const skipFiller = () => {
    while (i < n) {
      if (/[\s,]/.test(lit[i])) { i++; continue; }
      if (lit[i] === '/' && lit[i + 1] === '/') { while (i < n && lit[i] !== '\n') i++; continue; }
      if (lit[i] === '/' && lit[i + 1] === '*') { const e = lit.indexOf('*/', i + 2); i = e < 0 ? n : e + 2; continue; }
      if (hashComments && lit[i] === '#') { while (i < n && lit[i] !== '\n') i++; continue; }
      break;
    }
  };
  while (i < n) {
    skipFiller();
    if (i >= n || lit[i] === '}') break;
    // read a key: quoted or bare
    let key = null;
    if (lit[i] === "'" || lit[i] === '"') {
      const q = lit[i]; let j = i + 1, s = '';
      while (j < n && lit[j] !== q) { if (lit[j] === '\\') j++; s += lit[j]; j++; }
      key = s; i = j + 1;
    } else {
      let j = i;
      while (j < n && /[A-Za-z0-9_$-]/.test(lit[j])) j++;
      key = lit.slice(i, j); i = j;
    }
    while (i < n && /[\s:]/.test(lit[i])) i++;
    if (lit[i] === '=') i++; // GDScript :=
    // read the value: braced, bracketed, string, or bare token
    let valueText = null;
    if (lit[i] === '{') { valueText = extractBraced(lit, i, opts); i += valueText.length; }
    else if (lit[i] === '[') { valueText = extractBracketed(lit, i, opts); i += valueText.length; }
    else if (lit[i] === "'" || lit[i] === '"') {
      const q = lit[i]; let j = i + 1, s = '';
      while (j < n && lit[j] !== q) { if (lit[j] === '\\') j++; s += lit[j]; j++; }
      valueText = q + s + q; i = j + 1;
    } else {
      // Bare token or a call like Color(1, .5, .2): consume to the next top-level , or }.
      let j = i, depth = 0;
      while (j < n) {
        const c = lit[j];
        if (c === '(') depth++;
        else if (c === ')') depth--;
        else if (depth === 0 && (c === ',' || c === '}')) break;
        j++;
      }
      valueText = lit.slice(i, j).trim(); i = j;
    }
    if (key) out.push({ key, valueText });
  }
  return out;
}

function parseKeyNumMap(lit) {
  const map = {};
  for (const e of topEntries(lit)) map[e.key] = num(e.valueText);
  return map;
}

function parseKeyStrMap(lit) {
  const map = {};
  for (const e of topEntries(lit)) {
    const m = /^['"](.*)['"]$/.exec(e.valueText.trim());
    map[e.key] = m ? m[1] : e.valueText.trim();
  }
  return map;
}

// FAC3D: per faction, hull/dark/trim hex strings plus C3()/Color() triples.
function parseFac3d(lit, opts) {
  const out = {};
  for (const e of topEntries(lit, opts)) {
    const fac = {};
    const hexRe = /['"]?(\w+)['"]?\s*:\s*'([^']+)'/g;
    let m;
    while ((m = hexRe.exec(e.valueText))) fac[m[1]] = m[2];
    const colRe = /['"]?(\w+)['"]?\s*:\s*(?:new\s+C3|Color)\(([^)]+)\)/g;
    while ((m = colRe.exec(e.valueText))) fac[m[1]] = parseVecList(m[2]);
    out[e.key] = fac;
  }
  return out;
}

// FINISH (Godot only): per faction ["#hex", metal, roughness].
function parseFinish(lit, opts) {
  const out = {};
  for (const e of topEntries(lit, opts)) {
    const inner = extractBracketed(e.valueText, 0, opts);
    if (!inner) continue;
    const parts = inner.slice(1, -1).split(',').map(s => s.trim());
    const hexM = /^['"](.*)['"]$/.exec(parts[0] || '');
    out[e.key] = { base: hexM ? hexM[1] : parts[0], metal: num(parts[1]), roughness: num(parts[2]) };
  }
  return out;
}

// BIOMES browser side: per faction, an array of RGB triples.
function parseBiomes(lit, opts) {
  const out = {};
  for (const e of topEntries(lit, opts)) {
    const triples = [];
    const re = /\[([^\[\]]+)\]/g; // innermost brackets only
    let m;
    while ((m = re.exec(e.valueText))) triples.push(parseVecList(m[1]));
    out[e.key] = triples;
  }
  return out;
}

// ROCK_KINDS browser side: per kind, the col triple (other fields are not copied).
function parseRockKinds(lit, opts) {
  const out = {};
  for (const e of topEntries(lit, opts)) {
    const m = /col\s*:\s*\[([^\]]+)\]/.exec(e.valueText);
    out[e.key] = m ? parseVecList(m[1]) : null;
  }
  return out;
}

// PLANET_LOOKS browser side: ordered entries {kind, pa, pb, pc, pd, atmo}.
function parsePlanetLooks(text) {
  const idx = findAssign(text, 'PLANET_LOOKS');
  if (idx < 0) return null;
  const lit = extractBracketed(text, idx);
  if (!lit) return null;
  const out = [];
  let pos = 0;
  while (true) {
    const obj = extractBraced(lit, pos);
    if (!obj) break;
    pos = lit.indexOf(obj, pos) + obj.length;
    const rec = {};
    const kindM = /kind\s*:\s*([\d.]+)/.exec(obj);
    rec.kind = kindM ? num(kindM[1]) : null;
    const re = /(\w+)\s*:\s*\[([^\]]+)\]/g;
    let m;
    while ((m = re.exec(obj))) rec[m[1]] = parseVecList(m[2]);
    out.push(rec);
  }
  return out;
}

// Godot PLANETS in world.gd: ordered entries [Vector3, Vector3, Vector3, flag].
function parseWorldPlanets(lit, opts) {
  const out = [];
  const inner = lit.slice(1, -1); // unwrap the outer array, then read entry by entry
  let pos = 0;
  while (true) {
    const entry = extractBracketed(inner, pos, opts);
    if (!entry) break;
    pos = inner.indexOf(entry, pos) + entry.length;
    const vecs = [];
    const re = /Vector3\(([^)]+)\)/g;
    let m;
    while ((m = re.exec(entry))) vecs.push(parseVecList(m[1]));
    const tail = entry.slice(entry.lastIndexOf(')') + 1).replace(/[\],\s]/g, '');
    out.push({ a: vecs[0] || null, b: vecs[1] || null, atmo: vecs[2] || null, flag: tail === '' ? null : num(tail) });
  }
  return out;
}

// Godot PLANETS in map3d_system.gd: ordered entries [kind, Color, Color, Color].
function parseMapPlanets(lit, opts) {
  const out = [];
  const inner = lit.slice(1, -1); // unwrap the outer array, then read entry by entry
  let pos = 0;
  while (true) {
    const entry = extractBracketed(inner, pos, opts);
    if (!entry) break;
    pos = inner.indexOf(entry, pos) + entry.length;
    const headM = /^\[\s*([\d.]+)/.exec(entry);
    const cols = [];
    const re = /Color\(([^)]+)\)/g;
    let m;
    while ((m = re.exec(entry))) cols.push(parseVecList(m[1]));
    out.push({ kind: headM ? num(headM[1]) : null, a: cols[0] || null, b: cols[1] || null, atmo: cols[2] || null });
  }
  return out;
}

// Godot ROCKS in world.gd: per kind [Vector3 albedo, shader kind int].
function parseWorldRocks(lit, opts) {
  const out = {};
  for (const e of topEntries(lit, opts)) {
    const vm = /Vector3\(([^)]+)\)/.exec(e.valueText);
    const tail = e.valueText.slice(e.valueText.lastIndexOf(')') + 1).replace(/[\],\s]/g, '');
    out[e.key] = { albedo: vm ? parseVecList(vm[1]) : null, shaderKind: tail === '' ? null : num(tail) };
  }
  return out;
}

function walkFiles(dir, ext, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const name of fs.readdirSync(dir).sort()) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) walkFiles(p, ext, acc);
    else if (name.endsWith(ext)) acc.push(p);
  }
  return acc;
}

// Every `const NAME` definition site in the Godot tree, for the seven audited names.
function searchGodotDefs(root, names) {
  const gdFiles = walkFiles(path.join(root, 'godot'), '.gd', []);
  const sites = {};
  for (const name of names) sites[name] = [];
  for (const f of gdFiles) {
    const text = readText(f);
    for (const name of names) {
      const re = new RegExp('const\\s+' + name + '\\b', 'g');
      let m;
      while ((m = re.exec(text))) {
        const line = text.slice(0, m.index).split('\n').length;
        sites[name].push(path.relative(root, f) + ':' + line);
      }
    }
  }
  return sites;
}

function valEq(a, b) {
  if (Array.isArray(a) && Array.isArray(b)) return vecEq(a, b);
  if (typeof a === 'number' && typeof b === 'number') return Math.abs(a - b) <= 1e-9;
  return a === b;
}

function fmtVal(v) {
  if (Array.isArray(v)) return fmtVec(v);
  return String(v);
}

// Compare two flat {key: value} maps.
function compareFlat(browserMap, godotMap) {
  const r = { compared: 0, matched: 0, differed: [], onlyBrowser: [], onlyGodot: [] };
  const keys = [...new Set([...Object.keys(browserMap || {}), ...Object.keys(godotMap || {})])].sort();
  for (const k of keys) {
    const inB = browserMap && Object.prototype.hasOwnProperty.call(browserMap, k);
    const inG = godotMap && Object.prototype.hasOwnProperty.call(godotMap, k);
    if (inB && inG) {
      r.compared++;
      if (valEq(browserMap[k], godotMap[k])) r.matched++;
      else r.differed.push({ key: k, browser: fmtVal(browserMap[k]), godot: fmtVal(godotMap[k]) });
    } else if (inB) r.onlyBrowser.push(k);
    else r.onlyGodot.push(k);
  }
  return r;
}

function checkConstants(root) {
  const GD = { hashComments: true };
  const ships = readText(path.join(root, 'ships3d.js'));
  const scene = readText(path.join(root, 'scene3d.js'));
  const gfx = readText(path.join(root, 'gfx3d.js'));
  const battle = readText(path.join(root, 'battle.js'));
  const hullTablePath = path.join(root, 'godot/render/hull_table.gd');
  const worldPath = path.join(root, 'godot/world/world.gd');
  const mapSysPath = path.join(root, 'godot/ui/campaign/map3d_system.gd');
  const hullTable = fs.existsSync(hullTablePath) ? readText(hullTablePath) : '';
  const world = fs.existsSync(worldPath) ? readText(worldPath) : '';
  const mapSys = fs.existsSync(mapSysPath) ? readText(mapSysPath) : '';

  const defNames = ['FAC3D', 'AI_HULLS', 'CLS_LEN', 'FINISH', 'BIOMES', 'ROCKS', 'PLANETS', 'ROCK_SET', 'ROCK_TINT'];
  const defSites = searchGodotDefs(root, defNames);
  const out = { defSites, constants: [] };

  // FAC3D: flatten to faction.subkey entries.
  const flatFac = (parsed) => {
    const flat = {};
    for (const fac of Object.keys(parsed).sort()) {
      for (const sub of Object.keys(parsed[fac]).sort()) flat[fac + '.' + sub] = parsed[fac][sub];
    }
    return flat;
  };
  const bFac = parseFac3d(literalAt(ships, 'FAC3D'), {});
  const gFacLit = literalAt(hullTable, 'FAC3D', GD);
  const gFac = gFacLit ? parseFac3d(gFacLit, GD) : {};
  out.constants.push(Object.assign(
    { name: 'FAC3D', browserSource: 'ships3d.js', godotSource: 'godot/render/hull_table.gd' },
    compareFlat(flatFac(bFac), flatFac(gFac)),
    { notes: ['Browser FAC3D also carries hull/dark/trim hex strings per faction; the Godot FAC3D carries only win/eng/bolt/beam/shield. The hull hex is cross-checked under FINISH below; dark and trim have no counterpart in hull_table.gd.'] }
  ));

  // AI_HULLS
  const bHulls = parseKeyStrMap(literalAt(ships, 'AI_HULLS'));
  const gHullsLit = literalAt(hullTable, 'AI_HULLS', GD);
  const gHulls = gHullsLit ? parseKeyStrMap(gHullsLit) : {};
  out.constants.push(Object.assign(
    { name: 'AI_HULLS', browserSource: 'ships3d.js', godotSource: 'godot/render/hull_table.gd' },
    compareFlat(bHulls, gHulls), { notes: [] }
  ));

  // CLS_LEN
  const bCls = parseKeyNumMap(literalAt(ships, 'CLS_LEN'));
  const gClsLit = literalAt(hullTable, 'CLS_LEN', GD);
  const gCls = gClsLit ? parseKeyNumMap(gClsLit) : {};
  out.constants.push(Object.assign(
    { name: 'CLS_LEN', browserSource: 'ships3d.js', godotSource: 'godot/render/hull_table.gd' },
    compareFlat(bCls, gCls), { notes: [] }
  ));

  // FINISH: a Godot-only table whose base hex duplicates the browser FAC3D hull hex.
  const gFinLit = literalAt(hullTable, 'FINISH', GD);
  const gFin = gFinLit ? parseFinish(gFinLit, GD) : {};
  const finRes = { name: 'FINISH', browserSource: 'ships3d.js FAC3D hull hex (no FINISH table in the browser)', godotSource: 'godot/render/hull_table.gd', compared: 0, matched: 0, differed: [], onlyBrowser: [], onlyGodot: [], notes: [] };
  for (const fac of Object.keys(gFin).sort()) {
    finRes.compared++;
    const bHull = bFac[fac] && bFac[fac].hull;
    if (bHull && bHull.toLowerCase() === String(gFin[fac].base).toLowerCase()) finRes.matched++;
    else finRes.differed.push({ key: fac + '.base', browser: String(bHull), godot: String(gFin[fac].base) });
    finRes.notes.push(fac + ': Godot-only finish fields metal=' + fmtNum(gFin[fac].metal) + ', roughness=' + fmtNum(gFin[fac].roughness) + ' (the browser has no per-faction metal/roughness table to copy from).');
  }
  out.constants.push(finRes);

  // BIOMES: browser table vs the nebula field of godot/fx/faction_looks.json.
  const bBiomes = parseBiomes(literalAt(scene, 'BIOMES'), {});
  let gBiomes = {};
  const looksPath = path.join(root, 'godot/fx/faction_looks.json');
  if (fs.existsSync(looksPath)) {
    const looks = JSON.parse(readText(looksPath));
    for (const fac of Object.keys(looks)) {
      if (looks[fac] && Array.isArray(looks[fac].nebula)) gBiomes[fac] = looks[fac].nebula;
    }
  }
  const biomeRes = { name: 'BIOMES', browserSource: 'scene3d.js', godotSource: 'godot/fx/faction_looks.json (nebula field; world.gd names this file as its source)', compared: 0, matched: 0, differed: [], onlyBrowser: [], onlyGodot: [], notes: ['No const BIOMES exists in the Godot tree; the values live in the faction look JSON.'] };
  for (const fac of [...new Set([...Object.keys(bBiomes), ...Object.keys(gBiomes)])].sort()) {
    if (bBiomes[fac] && gBiomes[fac]) {
      biomeRes.compared++;
      const same = bBiomes[fac].length === gBiomes[fac].length && bBiomes[fac].every((t, i) => vecEq(t, gBiomes[fac][i]));
      if (same) biomeRes.matched++;
      else biomeRes.differed.push({ key: fac, browser: bBiomes[fac].map(fmtVec).join(' '), godot: gBiomes[fac].map(fmtVec).join(' ') });
    } else if (bBiomes[fac]) biomeRes.onlyBrowser.push(fac);
    else biomeRes.onlyGodot.push(fac);
  }
  out.constants.push(biomeRes);

  // ROCKS part 1: ROCK_SET and ROCK_TINT (scene3d.js vs hull_table.gd).
  const bRockSet = parseKeyStrMap(literalAt(scene, 'ROCK_SET'));
  const gRockSetLit = literalAt(hullTable, 'ROCK_SET', GD);
  const gRockTintLit = literalAt(hullTable, 'ROCK_TINT', GD);
  const gRockSet = gRockSetLit ? parseKeyStrMap(gRockSetLit) : {};
  // ROCK_TINT values are triples (a [...] in JS, a Color(...) in GDScript): parse as vectors.
  const parseTint = (lit, opts) => {
    const map = {};
    for (const e of topEntries(lit, opts)) {
      const cm = /Color\(([^)]+)\)/.exec(e.valueText);
      if (cm) { map[e.key] = parseVecList(cm[1]); continue; }
      const inner = extractBracketed(e.valueText, 0, opts);
      map[e.key] = inner ? parseVecList(inner.slice(1, -1)) : null;
    }
    return map;
  };
  const bTintLit = literalAt(scene, 'ROCK_TINT');
  const bTint = bTintLit ? parseTint(bTintLit, {}) : {};
  const gTint = gRockTintLit ? parseTint(gRockTintLit, GD) : {};
  const rockSetRes = compareFlat(
    Object.assign({}, prefixKeys(bRockSet, 'ROCK_SET.'), prefixKeys(bTint, 'ROCK_TINT.')),
    Object.assign({}, prefixKeys(gRockSet, 'ROCK_SET.'), prefixKeys(gTint, 'ROCK_TINT.'))
  );
  out.constants.push(Object.assign(
    { name: 'ROCKS (ROCK_SET / ROCK_TINT)', browserSource: 'scene3d.js', godotSource: 'godot/render/hull_table.gd' },
    rockSetRes, { notes: [] }
  ));

  // ROCKS part 2: ROCK_KINDS col (battle.js) vs world.gd ROCKS albedo.
  const bKinds = parseRockKinds(literalAt(battle, 'ROCK_KINDS'), {});
  const gWorldRocksLit = literalAt(world, 'ROCKS', GD);
  const gWorldRocks = gWorldRocksLit ? parseWorldRocks(gWorldRocksLit, GD) : {};
  const gKindFlat = {};
  for (const k of Object.keys(gWorldRocks)) gKindFlat[k] = gWorldRocks[k].albedo;
  out.constants.push(Object.assign(
    { name: 'ROCKS (ROCK_KINDS col vs world ROCKS albedo)', browserSource: 'battle.js ROCK_KINDS', godotSource: 'godot/world/world.gd ROCKS' },
    compareFlat(bKinds, gKindFlat),
    { notes: ['The browser col is a tint multiplied into the rock material; the Godot value is an absolute albedo. They are the same table in two different quantities, so every entry differing is expected unless one side is re-derived from the other. The browser spec and em fields have no Godot counterpart in this table.'] }
  ));

  // PLANETS: browser PLANET_LOOKS vs both Godot PLANETS tables.
  const bLooks = parsePlanetLooks(gfx) || [];
  const gWorldLit = literalArrayAt(world, 'PLANETS', GD);
  const gWorldPlanets = gWorldLit ? parseWorldPlanets(gWorldLit, GD) : [];
  out.constants.push(comparePlanets('PLANETS (world.gd)', 'gfx3d.js PLANET_LOOKS', 'godot/world/world.gd PLANETS', bLooks, gWorldPlanets, 'world'));
  const gMapLit = literalArrayAt(mapSys, 'PLANETS', GD);
  const gMapPlanets = gMapLit ? parseMapPlanets(gMapLit, GD) : [];
  out.constants.push(comparePlanets('PLANETS (map3d_system.gd)', 'gfx3d.js PLANET_LOOKS', 'godot/ui/campaign/map3d_system.gd PLANETS', bLooks, gMapPlanets, 'map'));

  return out;
}

function prefixKeys(map, prefix) {
  const out = {};
  for (const k of Object.keys(map)) out[prefix + k] = map[k];
  return out;
}

// PLANETS comparison: fields a/pa, b/pb, atmo, and kind vs kind (map) or kind vs gas flag (world).
function comparePlanets(name, browserSource, godotSource, bLooks, gEntries, flavor) {
  const r = { name, browserSource, godotSource, compared: 0, matched: 0, differed: [], onlyBrowser: [], onlyGodot: [], notes: [] };
  const n = Math.max(bLooks.length, gEntries.length);
  for (let i = 0; i < n; i++) {
    const b = bLooks[i], g = gEntries[i];
    if (b && g) {
      r.compared++;
      const diffs = [];
      if (!vecEq(b.pa || [], g.a || [])) diffs.push('a: browser ' + fmtVec(b.pa || []) + ' vs godot ' + fmtVec(g.a || []));
      if (!vecEq(b.pb || [], g.b || [])) diffs.push('b: browser ' + fmtVec(b.pb || []) + ' vs godot ' + fmtVec(g.b || []));
      if (!vecEq(b.atmo || [], g.atmo || [])) diffs.push('atmo: browser ' + fmtVec(b.atmo || []) + ' vs godot ' + fmtVec(g.atmo || []));
      if (flavor === 'world') {
        const bGas = b.kind === 0;
        const gGas = g.flag === 1;
        if (bGas !== gGas) diffs.push('gas-giant flag: browser kind=' + b.kind + ' vs godot flag=' + fmtNum(g.flag === null ? NaN : g.flag));
      } else {
        if (b.kind !== g.kind) diffs.push('kind: browser ' + b.kind + ' vs godot ' + g.kind);
      }
      if (diffs.length) r.differed.push({ key: 'entry ' + i, browser: 'kind=' + b.kind + ' pa=' + fmtVec(b.pa || []) + ' pb=' + fmtVec(b.pb || []) + ' atmo=' + fmtVec(b.atmo || []), godot: diffs.join('; ') });
      else r.matched++;
    } else if (b) r.onlyBrowser.push('entry ' + i);
    else r.onlyGodot.push('entry ' + i);
  }
  r.notes.push('Browser PLANET_LOOKS also carries pc and pd fields per entry; neither Godot table has them.');
  r.notes.push('FAC_PLANETS (gfx3d.js, per-faction planet picks) has no Godot namesake; the Godot world code indexes planets by biome.planet instead.');
  return r;
}

// ---------------------------------------------------------------- report rendering

function renderText(r) {
  const L = [];
  L.push('ORACLE DRIFT GUARD');
  L.push('repo root: ' + r.root);
  L.push('clone HEAD: ' + (r.pins.head || '(git unavailable)'));
  L.push('');
  L.push('== (a) Vendored oracle copies ==');
  for (const f of VENDORED_FILES) {
    const e = r.vendored.files[f];
    L.push(f + ':');
    for (const loc of ORACLE_DIRS) {
      const v = e.locations[loc.id];
      L.push('  ' + (loc.id + ' ').padEnd(18, '.') + (v.missing ? 'MISSING' : 'sha256 ' + v.sha256 + '  ' + v.bytes + ' bytes  ' + v.lines + ' lines'));
    }
    for (const p of e.pairs) {
      if (p.equal) L.push('  ' + p.a + ' == ' + p.b + ': IDENTICAL');
      else L.push('  ' + p.a + ' vs ' + p.b + ': DIFFER (added ' + p.diff.added + ', removed ' + p.diff.removed + ', first differing lines ' + p.diff.firstDiffs.map(d => d.aLine + '/' + d.bLine).join(', ') + ')');
    }
  }
  L.push('');
  L.push('== (b) README pin claims ==');
  for (const s of r.pins.suites) {
    L.push(s.id + ':');
    if (!s.readmes.length) L.push('  no README found');
    for (const c of s.claims) {
      L.push('  ' + c.readme + ': commit tokens mentioned: ' + (c.allCommitTokens.join(', ') || 'none'));
      if (c.pin) {
        L.push('  claimed copy pin: ' + c.pin);
        for (const f of Object.keys(c.files).sort()) {
          const rec = c.files[f];
          let line = '    ' + f + ': matches root working tree = ' + yn(rec.matchesRootWorkingTree) + ', matches content at pin = ' + yn(rec.matchesPinContent);
          if (rec.disclosedException) line += '  [disclosed exception: the README itself documents this one fix]';
          if (rec.matchesPinContent === null) line += '  [not a root file at the pin; an extract, unverifiable by file hash]';
          L.push(line);
        }
      } else L.push('  no "from commit" pin claim found');
      if (c.coreUnchangedSince) L.push('  claim "core.js unchanged since ' + c.coreUnchangedSince.commit + '": ' + (c.coreUnchangedSince.holds === null ? 'UNVERIFIABLE (git)' : c.coreUnchangedSince.holds ? 'HOLDS' : 'CONTRADICTED'));
      if (c.campaign3dFix) {
        const cf = c.campaign3dFix;
        L.push('  disclosed fix: ' + cf.disclosedFix);
        if (cf.vsPin) L.push('    vendored vs content at pin: added ' + cf.vsPin.added + ', removed ' + cf.vsPin.removed + ', first differing lines ' + cf.vsPin.firstDiffLines.join(', '));
        if (cf.vsRootWorkingTree) L.push('    vendored vs root working tree: added ' + cf.vsRootWorkingTree.added + ', removed ' + cf.vsRootWorkingTree.removed + ', first differing lines ' + cf.vsRootWorkingTree.firstDiffLines.join(', '));
      }
    }
  }
  L.push('');
  L.push('== (c) Hand-copied constants ==');
  L.push('Godot definition sites found by search:');
  for (const name of Object.keys(r.constantsCheck.defSites).sort()) {
    const sites = r.constantsCheck.defSites[name];
    L.push('  ' + name + ': ' + (sites.length ? sites.join('; ') : '(none in godot/**/*.gd)'));
  }
  for (const c of r.constantsCheck.constants) {
    L.push(c.name + '  [' + c.browserSource + '  vs  ' + c.godotSource + ']');
    L.push('  compared ' + c.compared + ', matched ' + c.matched + ', differed ' + c.differed.length + ', browser-only ' + c.onlyBrowser.length + ', godot-only ' + c.onlyGodot.length);
    for (const d of c.differed) L.push('  DIFFER ' + d.key + ': browser ' + d.browser + ' | godot ' + d.godot);
    if (c.onlyBrowser.length) L.push('  browser-only: ' + c.onlyBrowser.join(', '));
    if (c.onlyGodot.length) L.push('  godot-only: ' + c.onlyGodot.join(', '));
    for (const n of c.notes) L.push('  note: ' + n);
  }
  L.push('');
  L.push('== Summary ==');
  L.push('vendored pairs: ' + r.summary.vendoredPairs + ' compared, ' + r.summary.vendoredEqual + ' identical, ' + r.summary.vendoredDiffering + ' differing');
  L.push('pin claims: ' + r.summary.pinClaimsChecked + ' file checks against pinned content, ' + r.summary.pinClaimsHeld + ' held' + (r.summary.pinExceptions ? ' (including ' + r.summary.pinExceptions + ' disclosed exception)' : '') + ', ' + r.summary.pinClaimsFailed + ' contradicted');
  L.push('constants: ' + r.summary.constCompared + ' entries compared, ' + r.summary.constMatched + ' matched, ' + r.summary.constDiffered + ' differed, ' + r.summary.constOnlyBrowser + ' browser-only, ' + r.summary.constOnlyGodot + ' godot-only');
  return L.join('\n') + '\n';
}

function yn(v) {
  return v === null ? 'unknown' : v ? 'YES' : 'NO';
}

// ---------------------------------------------------------------- main

function main() {
  const args = process.argv.slice(2);
  const json = args.includes('--json');
  const positional = args.filter(a => !a.startsWith('--'));
  const root = path.resolve(positional[0] || process.cwd());
  if (!fs.existsSync(path.join(root, 'battle.js')) || !fs.existsSync(path.join(root, 'godot'))) {
    fail('repo root not recognised at ' + root + ' (needs battle.js and godot/ at the top level)');
  }
  const vendored = checkVendoredCopies(root);
  const pins = checkPinClaims(root);
  const constantsCheck = checkConstants(root);

  const summary = { vendoredPairs: 0, vendoredEqual: 0, vendoredDiffering: 0, pinClaimsChecked: 0, pinClaimsHeld: 0, pinClaimsFailed: 0, constCompared: 0, constMatched: 0, constDiffered: 0, constOnlyBrowser: 0, constOnlyGodot: 0 };
  for (const f of VENDORED_FILES) {
    for (const p of vendored.files[f].pairs) {
      summary.vendoredPairs++;
      if (p.equal) summary.vendoredEqual++; else summary.vendoredDiffering++;
    }
  }
  for (const s of pins.suites) {
    for (const c of s.claims) {
      if (!c.files) continue;
      for (const f of Object.keys(c.files)) {
        if (c.files[f].matchesPinContent === null) continue;
        summary.pinClaimsChecked++;
        if (c.files[f].matchesPinContent || c.files[f].disclosedException) summary.pinClaimsHeld++; else summary.pinClaimsFailed++;
        if (c.files[f].disclosedException) summary.pinExceptions = (summary.pinExceptions || 0) + 1;
      }
    }
  }
  for (const c of constantsCheck.constants) {
    summary.constCompared += c.compared;
    summary.constMatched += c.matched;
    summary.constDiffered += c.differed.length;
    summary.constOnlyBrowser += c.onlyBrowser.length;
    summary.constOnlyGodot += c.onlyGodot.length;
  }

  const result = { root, vendored, pins, constantsCheck, summary };
  if (json) process.stdout.write(JSON.stringify(result, null, 2) + '\n');
  else process.stdout.write(renderText(result));
}

main();
