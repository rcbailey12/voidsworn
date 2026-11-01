'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { literals, patterns, scan } = require('./naming_lint_game');
// Keep even temporary fixtures inside this repository.
const dir = fs.mkdtempSync(path.join(__dirname, 'naming-lint-test-'));
try {
  const retired = 'Ashfall Corsairs';
  const positive = path.join(dir, 'positive.js');
  const negative = path.join(dir, 'negative.js');
  fs.writeFileSync(positive, 'const label = "' + retired + '";\n');
  fs.writeFileSync(negative, '// ' + retired + '\n/* "' + retired + '" */\nconst AshfallCorsairs = 1;\n');
  for (const [file, expected] of [[positive, 1], [negative, 0]]) {
    const result = spawnSync(process.execPath, [path.join(__dirname, 'naming_lint_game.js'), '--json', file], { encoding: 'utf8' });
    assert.strictEqual(result.status, expected, result.stderr);
    assert.strictEqual(JSON.parse(result.stdout).some(h => h.pattern === retired), Boolean(expected));
  }
  assert.deepStrictEqual(literals('"relic": "Relics"', 'json').map(s => s.text), ['Relics']);
  assert.deepStrictEqual(literals('# "relic"\nvar x = "say \\"relic\\""', 'gd').map(s => s.text), ['say "relic"']);
  assert.deepStrictEqual(literals('`hello ${ /* "relic" */ name + "world" } end`').map(s => s.text), ['hello ', 'world', ' end']);
  fs.writeFileSync(positive, '"Relics relicensed relic"');
  assert.strictEqual(scan([positive], { hard: [], word: ['relic'] }).length, 2);
  assert.strictEqual(scan([positive], { hard: [], word: ['relic'] }, { 'positive.js': ['relic'] }).length, 0);
  assert(patterns().hard.includes(retired));
  fs.writeFileSync(negative, 'const label = "the Hollow Sun";');
  assert(!patterns().hard.includes('the Hollow'));
  assert.deepStrictEqual(scan([negative], patterns()), []);
  fs.writeFileSync(negative, "if (kind === 'relic') {}\n");
  assert.deepStrictEqual(scan([negative], { hard: [], word: ['relic'] }), []);
  fs.writeFileSync(negative, "const keys = {'relic label': 1}; kind !== 'Ancient relic'; set.has('Ancient relic'); map.get('Ancient relic'); switch (kind) { case 'Ancient relic': break; }");
  assert.deepStrictEqual(scan([negative], { hard: [], word: ['relic'] }), []);
  fs.writeFileSync(positive, '"The Hollow Sun warps this field; warped space"; "warp drive"; "the Warp"; "drop out of warp";');
  assert.strictEqual(scan([positive], { hard: [], word: ['warp'] }).length, 3);
  console.log('naming_lint_game.test: pass');
} finally {
  for (const name of fs.readdirSync(dir)) fs.unlinkSync(path.join(dir, name));
  fs.rmdirSync(dir);
}
