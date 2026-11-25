'use strict';
// Issue 2129: prove contrib/opus/tools/shader_pow_2092.js also scans standalone .gdshader files
// (PR 1780 moves the shaders out of the triple-quoted .gd blocks). The bad fixture carries a
// pow(a - b, 2.0) and must be flagged at its own line; the good fixture writes (a - b) * (a - b)
// and must pass. The .gd shader-string path must keep working unchanged.
const fs = require('fs');
const path = require('path');
const tool = require('./shader_pow_2092.js');

const ROOT = path.resolve(__dirname, '../../..');
const rel = p => path.relative(ROOT, p).replace(/\\/g, '/');
const FIX = path.join(__dirname, 'fixtures', 'shader_pow_2092');
const badFile = path.join(FIX, 'bad.gdshader');
const goodFile = path.join(FIX, 'good.gdshader');

const fails = [];
const ok = (cond, msg) => { if (!cond) fails.push(msg); };

for (const p of [badFile, goodFile]) ok(fs.existsSync(p), 'missing ' + rel(p));

if (fs.existsSync(badFile)) {
  const bad = tool.scanShaderFile(badFile);
  ok(bad.length === 1, 'bad.gdshader gave ' + bad.length + ' offender(s), wanted 1');
  if (bad.length) {
    ok(bad[0].line === 5, 'bad.gdshader offender line was ' + bad[0].line + ', wanted 5');
    ok(/pow\s*\(/.test(bad[0].call), 'bad.gdshader offender is not a pow call: ' + bad[0].call);
    ok(bad[0].file === rel(badFile), 'bad.gdshader reported ' + bad[0].file + ', wanted ' + rel(badFile));
  }
}

if (fs.existsSync(goodFile)) {
  const good = tool.scanShaderFile(goodFile);
  ok(good.length === 0, 'good.gdshader gave ' + good.length + ' offender(s), wanted 0');
}

// The .gd path must stay as it is: the same bad base inside a triple-quoted block still fails.
const gd = 'var s = """\nvoid fragment() {\n\tfloat e = pow(a - b, 2.0);\n}\n"""';
ok(tool.offenders(tool.shaderBlocks(gd)[0].body).length === 1, 'the .gd shader-string path stopped flagging a bad base');

if (fails.length) {
  for (const f of fails) console.error('FAIL: ' + f);
  console.error('FAIL: ' + fails.length + ' shader_pow_2092 check(s) failed (issue 2129)');
  process.exit(1);
}
console.log('PASS: shader_pow_2092 scans .gdshader files: bad fixture flagged at line 5, good fixture passes (issue 2129)');
