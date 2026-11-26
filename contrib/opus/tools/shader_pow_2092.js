'use strict';
// Issue 2092 (Neon audit 2083 finding 9): GLSL pow(x, 2.0) is undefined for x < 0, so some drivers draw
// black or NaN. This standing check scans the shader strings in godot/ (the triple-quoted blocks in .gd
// files and the whole of every standalone .gdshader file, issue 2129) and fails when a pow(<base>, 2.0)
// carries a subtraction in its base and is not wrapped in a non-negative guard. Rewrite such a base as a
// product: float d = <expr>; d * d.
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../../..');
const GODOT = path.join(ROOT, 'godot');

// A base that starts with one of these calls is non-negative by construction, so a subtraction inside is safe.
const GUARDED = /^(?:max|abs|clamp|smoothstep)\s*\(/;

function findClose(text, open) {
  let depth = 0;
  for (let i = open; i < text.length; i++) {
    const ch = text[i];
    if (ch === '(') depth++;
    else if (ch === ')') { depth--; if (depth === 0) return i; }
  }
  return -1;
}

function splitArgs(inner) {
  const args = [];
  let depth = 0, start = 0;
  for (let i = 0; i < inner.length; i++) {
    const ch = inner[i];
    if (ch === '(') depth++;
    else if (ch === ')') depth--;
    else if (ch === ',' && depth === 0) { args.push(inner.slice(start, i)); start = i + 1; }
  }
  args.push(inner.slice(start));
  return args;
}

// Return the pow(...) calls in one shader block whose base can go negative with exponent 2.0, each with
// its offset in the block.
function offendersAt(block) {
  const found = [];
  const re = /\bpow\s*\(/g;
  let m;
  while ((m = re.exec(block))) {
    const open = block.indexOf('(', m.index);
    const close = findClose(block, open);
    if (close < 0) break;
    const args = splitArgs(block.slice(open + 1, close));
    if (args.length !== 2) continue;
    const base = args[0].trim();
    const exp = args[1].trim();
    if (exp !== '2.0') continue;
    if (!base.includes('-')) continue;
    if (GUARDED.test(base)) continue;
    found.push({ index: m.index, call: block.slice(m.index, close + 1) });
  }
  return found;
}

function offenders(block) {
  return offendersAt(block).map(o => o.call);
}

// The triple-quoted blocks hold the GLSL in these .gd files; plain GDScript math is fine under this rule.
function shaderBlocks(text) {
  const blocks = [];
  const re = /("""|''')([\s\S]*?)\1/g;
  let m;
  while ((m = re.exec(text))) blocks.push({ start: m.index + m[0].indexOf(m[2]), body: m[2] });
  return blocks;
}

function walk(dir, out) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (entry.name === '.godot' || entry.name === 'gen') continue;
      walk(path.join(dir, entry.name), out);
    } else if (entry.name.endsWith('.gd') || entry.name.endsWith('.gdshader')) out.push(path.join(dir, entry.name));
  }
  return out;
}

function scanFile(file) {
  const text = fs.readFileSync(file, 'utf8');
  const bad = [];
  for (const block of shaderBlocks(text)) {
    for (const call of offenders(block.body)) {
      const line = text.slice(0, block.start).split('\n').length +
        block.body.slice(0, block.body.indexOf(call)).split('\n').length - 1;
      bad.push({ file: path.relative(ROOT, file).replace(/\\/g, '/'), line, call });
    }
  }
  return bad;
}

// A standalone .gdshader file is one GLSL block: scan the whole file exactly the same way.
function scanShaderFile(file) {
  const text = fs.readFileSync(file, 'utf8');
  const bad = [];
  for (const call of offendersAt(text)) {
    const line = text.slice(0, call.index).split('\n').length;
    bad.push({ file: path.relative(ROOT, file).replace(/\\/g, '/'), line, call: call.call });
  }
  return bad;
}

function selfTest() {
  const cases = [
    ['float a = pow((x - y) / z, 2.0);', 1],
    ['float a = pow(x * x, 2.0);', 0],
    ['float a = pow((x - y) / z, 3.0);', 0],
    ['float a = spow((x - y) / z, 2.0);', 0],
    ['float a = pow(max(x - y, 0.0), 2.0);', 0],
  ];
  for (const [text, want] of cases) {
    const got = offenders(text).length;
    if (got !== want) return 'self-test: ' + JSON.stringify(text) + ' gave ' + got + ', wanted ' + want;
  }
  return '';
}

function main() {
  const selfError = selfTest();
  if (selfError) { console.error('FAIL: ' + selfError); process.exit(1); }

  const files = walk(GODOT, []);
  const bad = [];
  for (const file of files) {
    if (file.endsWith('.gdshader')) bad.push(...scanShaderFile(file));
    else bad.push(...scanFile(file));
  }

  if (bad.length) {
    for (const b of bad) console.error('FAIL: ' + b.file + ':' + b.line + ' ' + b.call);
    console.error('FAIL: ' + bad.length + ' shader pow(x, 2.0) call(s) on a base that can be negative; write it as d * d (issue 2092)');
    process.exit(1);
  }
  console.log('PASS: no shader pow(x, 2.0) on a possibly negative base in ' + files.length + ' files (issue 2092)');
}

if (require.main === module) main();

module.exports = { offenders, offendersAt, shaderBlocks, scanFile, scanShaderFile, walk, selfTest };
