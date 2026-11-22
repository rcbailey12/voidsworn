'use strict';
// Issue 1658: .agents/skills is the one skills folder for every seat; Claude Code reads .claude/skills. This copies the
// first over the second (plain files, no links: links break on a Windows checkout) and removes skill folders there that
// no longer exist in .agents/skills. node contrib/opus/tools/sync_skills.js [--check]   (--check changes nothing)
const fs = require('fs'), path = require('path');
const ROOT = process.env.VS_ROOT || path.resolve(__dirname, '../../..');
const SRC = path.join(ROOT, '.agents', 'skills'), DST = path.join(ROOT, '.claude', 'skills');
const list = (dir, base = dir) => fs.existsSync(dir) ? fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => {
  const p = path.join(dir, e.name);
  if (e.isSymbolicLink()) throw new Error('a link in the skills: ' + p);
  return e.isDirectory() ? list(p, base) : [path.relative(base, p).split(path.sep).join('/')];
}) : [];
function diff() {
  const a = new Set(list(SRC)), b = new Set(list(DST)), out = [];
  for (const f of a) if (!b.has(f)) out.push('missing in .claude/skills: ' + f);
    else if (!fs.readFileSync(path.join(SRC, f)).equals(fs.readFileSync(path.join(DST, f)))) out.push('differs: ' + f);
  for (const f of b) if (!a.has(f)) out.push('only in .claude/skills: ' + f);
  return out;
}
module.exports = { diff, SRC, DST };
if (require.main === module) {
  if (process.argv.includes('--check')) {
    const d = diff();
    if (d.length) { console.log(d.slice(0, 20).join('\n')); console.log(`FAIL: ${d.length} difference(s); run node contrib/opus/tools/sync_skills.js`); process.exit(1); }
    console.log('PASS: .claude/skills matches .agents/skills'); process.exit(0);
  }
  fs.rmSync(DST, { recursive: true, force: true });
  for (const f of list(SRC)) { const to = path.join(DST, ...f.split('/')); fs.mkdirSync(path.dirname(to), { recursive: true }); fs.copyFileSync(path.join(SRC, ...f.split('/')), to); }
  console.log(`synced ${list(SRC).length} files from .agents/skills to .claude/skills`);
}
