'use strict';
// Keep LOOP.md short (ways-of-working audit, Nov 25 2026): move every LATEST line past the newest KEEP into LOOP_LOG.md,
// newest first. LOOP.md is in every Board turn's context, so its size is paid again on every turn of every thread.
// The Board runs this at the end of each hourly lane check; memory_lint FAILs past 25 LATEST lines.
//   node contrib/opus/tools/loop_roll.js [--keep 15] [--dry]
const fs = require('node:fs');
const path = require('node:path');
const root = path.join(__dirname, '../../..');
const loopPath = path.join(root, 'contrib/opus/LOOP.md');
const logPath = path.join(root, 'contrib/opus/LOOP_LOG.md');
const argv = process.argv.slice(2);
const keep = argv.includes('--keep') ? Number(argv[argv.indexOf('--keep') + 1]) : 15;
const eol = fs.readFileSync(loopPath, 'utf8').includes('\r\n') ? '\r\n' : '\n';
const lines = fs.readFileSync(loopPath, 'utf8').split(/\r?\n/);
const isLatest = l => /^\s*[-*]\s*LATEST\b/i.test(l);
let seen = 0; const moved = []; const kept = [];
for (const l of lines) {
  if (isLatest(l) && ++seen > keep) moved.push(l); else kept.push(l);
}
if (!moved.length) { console.log(`loop_roll: ${seen} LATEST lines, nothing to move`); process.exit(0); }
const head = '# LOOP log\n\nOlder LATEST lines rolled out of LOOP.md by contrib/opus/tools/loop_roll.js, newest first. History only: no seat needs to read this file.\n\n';
let log = fs.existsSync(logPath) ? fs.readFileSync(logPath, 'utf8').replace(/\r\n/g, '\n') : head;
if (!log.startsWith('# LOOP log')) log = head + log;
const body = log.slice(head.length);
const out = head + moved.join('\n') + '\n' + body;
const before = fs.statSync(loopPath).size;
const loopOut = kept.join(eol);
console.log(`loop_roll: moved ${moved.length} of ${seen} LATEST lines; LOOP.md ${before} -> ${Buffer.byteLength(loopOut)} bytes`);
if (argv.includes('--dry')) process.exit(0);
// Write beside and rename, so a hard-linked checkout never edits another copy in place.
fs.writeFileSync(logPath + '.tmp', out.replace(/\n/g, eol)); fs.renameSync(logPath + '.tmp', logPath);
fs.writeFileSync(loopPath + '.tmp', loopOut); fs.renameSync(loopPath + '.tmp', loopPath);
