'use strict';
// Issues 953 and 1100: rewrite intentional report links, and never publish raw runner diagnostics.
// This test drives the real commit message steps of both runners (tools/pc/codex_issue.ps1 and tools/pc/work_issue.ps1)
// with a fake report holding one of each kind of path. It checks that a file inside the job's checkout becomes a GitHub
// link on the delivery branch, that every other path under the user's home folder becomes %USERPROFILE%\..., and that
// raw check and resume files are left local. Windows PowerShell 5.1 or pwsh, no model calls and no network.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const pc = path.join(ROOT, 'tools/pc');
const ps = process.env.PC_TEST_POWERSHELL || (process.platform === 'win32' ? 'powershell.exe' : 'pwsh');

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'report953 '));
const repo = path.join(tmp, 'repo');
const home = process.platform === 'win32' ? (process.env.USERPROFILE || os.homedir()) : os.homedir();
fs.mkdirSync(repo, { recursive: true });
const write = (p, s) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s); };

const slashes = s => s.replace(/\\/g, '/');
const backslashes = s => s.replace(/\//g, '\\');
const repoFwd = slashes(repo), repoBs = backslashes(repo), repoUpper = slashes(repo).toUpperCase();
const homeFwd = slashes(home), homeBs = backslashes(home);
const rel = 'tools/pc/runner_selftest.js';
const relBs = backslashes(rel), relFwd = slashes(rel);
const repoRelBs = '\\' + relBs, repoRelFwd = '/' + relFwd;
const marker = 'MARKER: this sentence must survive byte for byte.';

const report = [
  marker,
  '',
  '- markdown forward: [runner_selftest.js](' + repoFwd + repoRelFwd + ')',
  '- bare backslash: ' + repoBs + repoRelBs,
  '- mixed case: ' + repoUpper + repoRelFwd,
  '- markdown backslash: [runner_selftest.js](' + repoBs + repoRelBs + ')',
  '- temp backslash: ' + homeBs + '\\AppData\\Local\\Temp\\picture889-abcd.png',
  '- temp forward link: [shot](' + homeFwd + '/AppData/Local/Temp/picture890.png)',
  '- other home path: ' + homeBs + '\\Downloads\\voidsworn_test\\board_d\\repo\\' + relBs
].join('\n') + '\n';
const secret = 'fake-api-secret-1100';
const privatePath = 'Z:\\a private folder\\picture891.txt';
const checkText = `FAIL: ${privatePath} ${secret}\ncheck | result | seconds | detail\n--- | --- | --- | ---\nfixture | PASS | 0.12 | PASS: ${privatePath} ${secret}\n`;

function ask(runner, extra, out) {
  const r = spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(pc, runner + '.ps1'), 'msg', ...extra], {
    encoding: 'utf8', windowsHide: true, timeout: 60000,
    env: { ...process.env, USERPROFILE: home, NODE_EXIT: '0', PARITY_EXIT: '1' }
  });
  assert.equal(r.status, 0, runner + ' msg failed\n' + (r.stdout || '') + (r.stderr || '') + String(r.error || ''));
  return fs.readFileSync(path.join(out, 'commit.txt'), 'utf8');
}

let passed = 0;
function pass(name) { passed++; console.log('PASS ' + name); }

// Codex runner: msg <n> <repo> <out>
const codexOut = path.join(tmp, 'codex-out');
write(path.join(codexOut, 'title.txt'), 'Fixture title');
write(path.join(codexOut, 'last.md'), report);
write(path.join(codexOut, 'checks_node.txt'), checkText);
write(path.join(codexOut, 'checks_parity.txt'), "PASS: the Godot port matches the game's rules exactly.\nFAIL: " + secret);
const codex = ask('codex_issue', ['953', repo, codexOut], codexOut);

// Workhorse runner: msg <n> <arm> <out>; its checkout is the repo folder beside out.
const workOut = path.join(tmp, 'out');
write(path.join(workOut, 'title.txt'), 'Fixture title');
write(path.join(workOut, 'last.md'), report);
write(path.join(workOut, 'checks.txt'), checkText);
write(path.join(workOut, 'checks_node.txt'), checkText);
write(path.join(workOut, 'checks_parity.txt'), 'FAIL: ' + secret);
write(path.join(workOut, 'stats.txt'), 'run log: ' + privatePath + ' ' + secret);
const work = ask('work_issue', ['953', 'deepseek', workOut], workOut);

function check(name, out, branch, links) {
  const lower = s => s.toLowerCase();
  const url = 'https://github.com/rcbailey12/voidsworn/blob/' + branch + '/' + rel;
  assert.equal(out.split(url).length - 1, links, name + ': expected ' + links + ' GitHub links to ' + branch);
  const escaped = url.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  assert(!new RegExp('[\\\\/]' + escaped).test(out), name + ': a separator was left in front of a link');
  assert(!lower(out).includes(lower(repoFwd)), name + ': the checkout path is still in the message');
  assert(!lower(out).includes(lower(repoBs)), name + ': the backslash checkout path is still in the message');
  assert(!lower(out).includes(lower(homeFwd)), name + ': the real home folder is still in the message');
  assert(!lower(out).includes(lower(homeBs)), name + ': the backslash home folder is still in the message');
  assert(out.includes('%USERPROFILE%\\AppData\\Local\\Temp\\picture889-abcd.png'), name + ': bare temp path not rewritten');
  assert(out.includes('%USERPROFILE%\\AppData/Local/Temp/picture890.png'), name + ': temp link not rewritten');
  assert(!out.includes(secret) && !out.includes(privatePath), name + ': raw check or stats output escaped');
  assert(out.includes('PASS: standing checks') && out.includes('FAIL: parity'), name + ': safe check rows missing');
  assert(out.includes('%USERPROFILE%\\Downloads\\voidsworn_test\\board_d\\repo\\' + relBs), name + ': other home path not rewritten');
  assert(out.includes(marker), name + ': a sentence without paths changed');
  assert(out.includes('Refs #953'), name + ': Refs line missing');
}

check('codex', codex, 'codex/issue-953', 4);
assert(codex.startsWith('Codex (issue #953): Fixture title\n\n' + marker), 'codex: title or first report line changed');
pass('codex runner: checkout paths become GitHub links on codex/issue-953 and home paths become %USERPROFILE%');

check('work', work, 'work/issue-953-deepseek', 4);
assert(work.startsWith('Workhorse deepseek arm (issue #953): Fixture title\n\n' + marker), 'work: title or first report line changed');
pass('work runner: checkout paths become GitHub links on work/issue-953-deepseek and home paths become %USERPROFILE%');

for (const [runner, args, out] of [['codex_issue', ['953', repo, codexOut], codexOut], ['work_issue', ['953', 'deepseek', workOut], workOut]]) {
  write(path.join(out, 'last.md'), 'interrupted agent output ' + secret);
  write(path.join(out, 'partial.txt'), 'CEILING');
  write(path.join(out, 'stop_reason.txt'), 'CEILING');
  write(path.join(out, 'resume.txt'), `Stop reason: CEILING\nLast log lines: ${privatePath} ${secret}`);
  const msg = ask(runner, args, out);
  assert(!msg.includes(secret) && !msg.includes(privatePath), runner + ': private resume or interrupted report escaped');
  assert(msg.includes('CEILING'), runner + ': fixed stop reason missing');
  assert(fs.readFileSync(path.join(out, 'resume.txt'), 'utf8').includes(secret), runner + ': local resume was lost');
}
console.log('PASS report_paths_tests: both public messages keep report links and safe check rows; raw checks and partial resume stay local');
