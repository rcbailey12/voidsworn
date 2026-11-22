// Issue 1551 (OpenAI review of the Board fixes, issue 1575): ship names in prose use one article rule in both runtimes.
// Run from the repo root: node contrib/opus/tools/ship_article_1551_tests.js
// The Godot twin is the ARTICLE_CASES block in godot/campaign/test/shipyard_repair_text_test.gd, with the same table.
'use strict';
const fs = require('fs'), path = require('path'), assert = require('assert');
const ROOT = path.resolve(__dirname, '..', '..', '..');
const run = fs.readFileSync(path.join(ROOT, 'campaign_run.js'), 'utf8');
const c3d = fs.readFileSync(path.join(ROOT, 'campaign3d.js'), 'utf8');
const gd = fs.readFileSync(path.join(ROOT, 'godot/campaign/campaign.gd'), 'utf8');
let pass = 0;
const ok = (cond, msg) => { assert.ok(cond, msg); pass++; console.log('ok ' + msg); };
const src = ['shipWithArticle', 'shipBare'].map(n => (run.match(new RegExp('^function ' + n + '\\(.*$', 'm')) || [''])[0]);
ok(src.every(Boolean), 'campaign_run.js defines shipWithArticle and shipBare (loaded by every browser test harness)');
ok(!/^function shipWithArticle\(/m.test(c3d) && !/^function shipBare\(/m.test(c3d), 'campaign3d.js keeps no second copy');
const { shipWithArticle, shipBare } = new Function(src.join('\n') + '\nreturn { shipWithArticle, shipBare };')();
const CASES = [ // [name, start, with article, bare]
  ['Ember', true, 'The Ember', 'Ember'], ['Ember', false, 'the Ember', 'Ember'],
  ['The Unbroken', true, 'The Unbroken', 'Unbroken'], ['The Unbroken', false, 'the Unbroken', 'Unbroken'],
  ['MDV Precedent', true, 'MDV Precedent', 'MDV Precedent'], ['HNS Relentless', false, 'HNS Relentless', 'HNS Relentless'],
];
for (const [n, st, want, bare] of CASES) {
  ok(shipWithArticle(n, st) === want, `shipWithArticle(${JSON.stringify(n)}, ${st}) is ${JSON.stringify(want)}`);
  ok(shipBare(n) === bare, `shipBare(${JSON.stringify(n)}) is ${JSON.stringify(bare)}`);
}
for (const [f, text] of [['campaign_run.js', run], ['campaign3d.js', c3d]]) {
  const left = text.split('\n').map((l, i) => [i + 1, l]).filter(([, l]) => /`The \$\{\w+\.(name|ship)\}/.test(l));
  ok(left.length === 0, `${f}: no ship name gets a hand-written "The" (${left.map(x => x[0]).join(', ') || 'none'})`);
}
const gleft = gd.split('\n').map((l, i) => [i + 1, l]).filter(([, l]) => /"The " \+ str\(\w+\["(name|ship)"\]\)/.test(l));
ok(gleft.length === 0, `campaign.gd: no ship name gets a hand-written "The" (${gleft.map(x => x[0]).join(', ') || 'none'})`);
ok(/fresh \$\{hw\?'spawn-mind':'lieutenant'\}/.test(run), 'browser shipyard: the Chorus line says a fresh spawn-mind, others a fresh lieutenant');
console.log(`\nship_article_1551 tests: ${pass} ok`);
