'use strict';
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const repo = path.resolve(__dirname, '../../..');
const cwd = fs.mkdtempSync(path.join(os.tmpdir(), 'punctuation 1100 '));
const workflow = fs.readFileSync(path.join(repo, '.github/workflows/checks.yml'), 'utf8');
const step = workflow.split('No em dashes in changed text files')[1].split('      - name:')[0];
const script = /node (contrib\/\S+\.js)/.exec(step);
function git(...args) {
  const r = spawnSync('git', args, { cwd, encoding: 'utf8' });
  assert.equal(r.status, 0, r.stderr);
  return r.stdout.trim();
}
const mark = String.fromCodePoint(0x2014);
const put = (name, text) => {
  fs.mkdirSync(path.join(cwd, path.dirname(name)), { recursive: true });
  fs.writeFileSync(path.join(cwd, name), text);
};
const snapshot = () => { git('add', '-A'); return git('write-tree'); };
git('init', '-q');
put('old-name.ps1', `existing text with ${mark} in a pure rename\n`);
put('unchanged.md', mark);
const base = snapshot();
fs.renameSync(path.join(cwd, 'old-name.ps1'), path.join(cwd, 'renamed path.ps1'));
put('tools/with spaces.bat', mark);
put('tools/normal.ps1', Buffer.from('\ufeff' + mark, 'utf16le'));
put('.github/workflows/sample.yml', mark);
// Issue 1488: Godot shader and resource text, .toml and .cmd files are text too.
const added = ['godot/fx/glow.gdshader', 'godot/fx/common.gdshaderinc', 'godot/ships/look.tres', 'tools/sample.toml', 'tools/run.cmd'];
for (const name of added) put(name, `x ${mark} y\n`);
put('assets/image.png', mark);
if (process.platform !== 'win32') put('tools/with\na newline.sh', mark);

function scan() {
  const head = snapshot();
  if (script) {
    const r = spawnSync(process.execPath, [path.join(repo, script[1]), `${base}..${head}`], { cwd, encoding: 'utf8' });
    return { ...r, stdout: (r.stdout || '') + (r.stderr || '') };
  }
  // Reproduce the old workflow in this fixture so the same probe demonstrates the original false pass.
  const bash = process.platform === 'win32' ? path.resolve(git('--exec-path'), '../../../bin/bash.exe') : 'bash';
  const body = step.split('run: |')[1].replace('origin/main...HEAD', `${base}..${head}`);
  return spawnSync(bash, ['-e', '-c', body], { cwd, encoding: 'utf8' });
}
const bad = scan();
assert.equal(bad.status, 1, (bad.stderr || '') + (bad.stdout || ''));
for (const name of ['renamed path.ps1', 'tools/with spaces.bat', 'tools/normal.ps1', '.github/workflows/sample.yml', ...added]) {
  assert(bad.stdout.includes(name), `missing planted mark in ${name}`);
  put(name, 'clean\n');
}
if (process.platform !== 'win32') {
  assert(bad.stdout.includes('tools/with\\na newline.sh'));
  put('tools/with\na newline.sh', 'clean\n');
}
assert(!bad.stdout.includes('unchanged.md') && !bad.stdout.includes('image.png'));
put('clean.md', 'clean\n');
const good = scan();
assert.equal(good.status, 0, good.stderr);
console.log('PASS: punctuation gate catches planted marks in renamed, spaced, PowerShell, workflow, shader, resource, toml and cmd paths');
