'use strict';
// Issue 1658: .claude/skills must be an exact copy of .agents/skills (sync_skills.js), every skill folder has a SKILL.md
// whose name matches its folder, and every copied third-party skill carries its LICENSE and SOURCE.md.
const assert = require('assert'), fs = require('fs'), path = require('path');
const { diff, SRC } = require('./sync_skills');
const d = diff();
assert.equal(d.length, 0, d.slice(0, 10).join('\n') + '\nrun node contrib/opus/tools/sync_skills.js');
let n = 0;
for (const e of fs.readdirSync(SRC, { withFileTypes: true }).filter(e => e.isDirectory())) {
  const md = fs.readFileSync(path.join(SRC, e.name, 'SKILL.md'), 'utf8');
  const name = (md.match(/^name:\s*(\S+)\s*$/m) || [])[1];
  assert.equal(name, e.name, `skill ${e.name}: SKILL.md name is ${name}`);
  assert(/^description:\s*\S/m.test(md), `skill ${e.name} has no description`);
  if (fs.existsSync(path.join(SRC, e.name, 'SOURCE.md'))) assert(fs.existsSync(path.join(SRC, e.name, 'LICENSE')), `skill ${e.name}: SOURCE.md without LICENSE`);
  n++;
}
console.log(`PASS: ${n} skills; .claude/skills is an exact copy of .agents/skills; names match folders; copied skills carry LICENSE and SOURCE.md`);
