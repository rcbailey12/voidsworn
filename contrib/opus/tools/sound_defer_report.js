'use strict';
// Issue 238, S8 and S9: report only. Read every gun cue in the two sound tables and test S8's defer rule, then run the
// salvo arithmetic the way the playable build's scheduler runs it and count how many voices of the largest legal salvo
// actually start. S9 is the measured defect this proves: gun_sq's 0.08 s defer is 1.6 gaps, and several cues' defers
// cannot cover their own voice cap. Nothing is changed here; the report says where the defect still sits.
//
//   node contrib/opus/tools/sound_defer_report.js [--out FILE.json]
//
// S8 rule (fx audit PACK section 5): every gun cue's defer window is at least 2.5 times its gap.
// Full requirement (S8's own derivation): defer must cover the gap between every pair in the largest legal salvo, so
// the last voice starts, not just the first 2.5 of them.

const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');

function read(name) { return fs.readFileSync(path.join(ROOT, name), 'utf8'); }

// sfx.js stores the table as a JS object literal; take the numbers out of each gun cue's text. A cue's text runs from
// its key to the next top-level cue key (two spaces, name, colon, brace).
function jsCues() {
  const src = read('sfx.js');
  const start = src.indexOf('SFX.CUES={');
  if (start < 0) throw Error('sfx.js: SFX.CUES not found');
  const end = src.indexOf('\n};', start);
  const block = src.slice(start, end < 0 ? src.length : end);
  const re = /^  (gun_[a-z_]+):\{/gm;
  const marks = [];
  let m;
  while ((m = re.exec(block))) marks.push({ name: m[1], at: m.index });
  const out = {};
  for (let i = 0; i < marks.length; i++) {
    const text = block.slice(marks[i].at, i + 1 < marks.length ? marks[i + 1].at : block.length);
    const num = k => { const x = new RegExp('(?:^|[,\\s])' + k + ':(-?(?:\\d+(?:\\.\\d+)?|\\.\\d+))').exec(text); return x ? Number(x[1]) : null; };
    out[marks[i].name] = { gap: num('gap'), defer: num('defer'), max: num('max'), salvo: /salvo:'([^']*)'/.test(text) ? RegExp.$1 : null, n: num('n') };
  }
  return { file: 'sfx.js', cues: out };
}

function godotCues() {
  const raw = JSON.parse(read('godot/audio/cues.json'));
  const out = {};
  for (const [k, v] of Object.entries(raw)) if (k.startsWith('gun_')) out[k] = { gap: v.gap, defer: v.defer, max: v.max, salvo: v.salvo || null, n: v.n || null };
  return { file: 'godot/audio/cues.json', cues: out };
}

// The playable scheduler (sfx.js play): a request at now when last[name] + gap is still ahead moves its start to
// last + gap * (1 + random * 0.6), and drops the request if that start would land further than defer past now.
// First start is now + 0.004. Run a burst of N requests at the same now, worst case (random 0) and a typical draw.
function starts(cue, count, jitter) {
  const now = 1000;
  let last = 0, started = 0;
  for (let i = 0; i < count; i++) {
    let t = now + 0.004;
    if (cue.gap && t < last + cue.gap) {
      const nt = last + cue.gap * (1 + jitter);
      if (nt - now > (cue.defer || 0)) continue;
      t = nt;
    }
    last = t;
    started++;
  }
  return started;
}

function table(which) {
  const rows = [];
  for (const [name, c] of Object.entries(which.cues)) {
    const gap = Number(c.gap || 0), defer = Number(c.defer || 0), max = Number(c.max || 0);
    const rule25 = gap > 0 ? defer + 1e-12 >= gap * 2.5 : true;
    const needed = Math.max(0, 0.004 + (max - 1) * gap);
    const full = defer + 1e-12 >= needed;
    const worst = starts(c, max, 0);
    const typical = starts(c, max, 0.3);
    rows.push({ cue: name, gap, defer, max, salvo: c.salvo, ratio: gap > 0 ? +(defer / gap).toFixed(3) : null,
      rule25, required_defer: +needed.toFixed(4), full, starts_worst: worst, starts_typical: typical, starts_wanted: max });
  }
  return rows;
}

function verdict(rows) {
  const fail25 = rows.filter(r => !r.rule25).map(r => r.cue);
  const failFull = rows.filter(r => !r.full).map(r => r.cue);
  const dropWorst = rows.filter(r => r.starts_worst < r.starts_wanted).map(r => `${r.cue} ${r.starts_worst}/${r.starts_wanted}`);
  return { fail25, failFull, dropWorst };
}

function main() {
  const args = process.argv.slice(2);
  let out = '';
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--out') out = path.resolve(args[++i]);
    else { console.error('Usage: node sound_defer_report.js [--out FILE.json]'); process.exit(1); }
  }
  const js = jsCues(), gd = godotCues();
  const jsRows = table(js), gdRows = table(gd);
  const jsV = verdict(jsRows), gdV = verdict(gdRows);
  const report = {
    item: 'S8 defer validation rule, proving S9',
    rule: 'defer >= 2.5 * gap (S8); defer >= 0.004 + (max - 1) * gap to start every voice of the largest legal salvo',
    tables: { js: { file: js.file, rows: jsRows, verdict: jsV }, godot: { file: gd.file, rows: gdRows, verdict: gdV } },
  };
  if (out) fs.writeFileSync(out, JSON.stringify(report, null, 2) + '\n');
  console.log('S8/S9 defer report: ' + js.file + ' and ' + gd.file);
  for (const [label, t] of [['sfx.js', report.tables.js], ['godot/audio/cues.json', report.tables.godot]]) {
    console.log('  ' + label);
    for (const r of t.rows) {
      const flags = [!r.rule25 ? 'S8-RULE-FAILED' : '', !r.full ? 'FULL-SALVO-DROPS' : ''].filter(Boolean).join(', ');
      console.log(`    ${r.cue} gap=${r.gap} defer=${r.defer} max=${r.max} ratio=${r.ratio} starts_worst=${r.starts_worst}/${r.starts_wanted} starts_typical=${r.starts_typical}/${r.starts_wanted}${flags ? '  ' + flags : ''}`);
    }
    console.log(`    S8 rule failed: ${t.verdict.fail25.length ? t.verdict.fail25.join(', ') : 'none'}`);
    console.log(`    largest salvo drops voices: ${t.verdict.dropWorst.length ? t.verdict.dropWorst.join('; ') : 'none'}`);
  }
  const jsDefect = jsV.fail25.length > 0 || jsV.dropWorst.length > 0;
  const gdDefect = gdV.fail25.length > 0 || gdV.dropWorst.length > 0;
  console.log('S9 in ' + js.file + ': ' + (jsDefect ? 'CONFIRMED (defect still present in the playable JS oracle)' : 'not reproduced'));
  console.log('S9 in ' + gd.file + ': ' + (gdDefect ? 'CONFIRMED' : 'not reproduced (fix already present in the port)'));
  console.log('PASS: report only, S8/S9 tests ran against both tables');
}

if (require.main === module) main();
module.exports = { jsCues, godotCues, table, verdict };
