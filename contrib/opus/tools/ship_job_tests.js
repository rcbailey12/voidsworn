'use strict';
// Issue 1174: static checks of the shared ship job, tools/pc/jobs/ship_job.bat, and of the helper wrappers that call it.
// Runs on any host (no cmd needed). What it holds:
//   the guard: after every step that can fail, "if defined FAILED goto collect" comes before the next command, so a failed
//     stage, install or check never reaches the shots; the shots line sits right behind that guard;
//   all three installed-glb checks (readback, interiors, death seam) count toward the guard (S10_RUN_1157.bat let a failed
//     death seam through to the shots);
//   the GPU wait default (21600, within gpu_slots.js MAX_WAIT_SECONDS) is set before any GPU step;
//   the last line: every way out of the main job writes "done PASS" or "done FAILED: ..." and then "all done";
//   no delete or move commands, and output only under the job folder;
//   every wrapper in docs/ship_pipeline/ship_job/wrappers/ is three lines that set the inputs and call ship_job.bat.
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const JOB = path.join(ROOT, 'tools/pc/jobs/ship_job.bat');
const WRAPPERS = path.join(ROOT, 'docs/ship_pipeline/ship_job/wrappers');
let passed = 0;
const pass = s => { passed++; console.log('PASS ' + s); };

const text = fs.readFileSync(JOB, 'utf8');
const lines = text.split(/\r?\n/);
const code = lines.map((l, i) => ({ n: i + 1, s: l.trim() })).filter(l => l.s && !/^rem\b/i.test(l.s));
const at = re => code.findIndex(l => re.test(l.s));
const main = code.slice(0, at(/^:collect$/));
const isCommand = s => /(tmo\.bat|^git |^cmd \/c|^powershell |^call |^xcopy |^copy )/i.test(s);
const guard = /^if defined FAILED goto collect$/i;
const mayFail = s => /set "?(FAILED|CHECKFAIL)=/i.test(s) && !/^set (FAILED|CHECKFAIL)=$/i.test(s);

// the guard
const shots = main.filter(l => /a4_shots\.tscn/.test(l.s));
assert.equal(shots.length, 1, 'exactly one shots command in the main job');
const before = main[main.indexOf(shots[0]) - 1];
assert(guard.test(before.s), `line ${before.n} before the shots must be the FAILED guard, is: ${before.s}`);
const firstFail = main.findIndex(l => mayFail(l.s));
assert(firstFail > 0, 'the job sets FAILED somewhere');
for (let i = firstFail; i < main.indexOf(shots[0]); i++) {
  if (!mayFail(main[i].s)) continue;
  let j = i + 1;
  while (j < main.length && !guard.test(main[j].s) && !isCommand(main[j].s)) j++;
  // a CHECKFAIL line may be followed by the next check: the checks all run, then CHECKFAIL turns into FAILED before the guard
  if (/CHECKFAIL=/.test(main[i].s) && isCommand(main[j].s) && /installed_ship_check|authored_interiors|death_seam/.test(main[j].s)) continue;
  if (/^if defined FAILED git -C .* merge --abort/.test(main[j].s)) j++;
  assert(j < main.length && guard.test(main[j].s), `line ${main[i].n} can fail, but line ${main[j] && main[j].n} runs before the guard`);
}
for (const check of ['installed_ship_check.gd', 'authored_interiors_check.gd', 'death_seam_check.gd']) {
  const k = main.findIndex(l => l.s.includes(check));
  assert(k > 0, check + ' runs');
  const tail = main.slice(k + 1, k + 5).map(l => l.s).join('\n');
  assert(/set EL=%ERRORLEVEL%/.test(tail) && /if not "%EL%"=="0" set "CHECKFAIL=/.test(tail), check + ' counts toward CHECKFAIL');
  assert(k < main.indexOf(shots[0]), check + ' runs before the shots');
}
assert(main.some(l => /^if defined CHECKFAIL set "FAILED=/.test(l.s)), 'CHECKFAIL becomes FAILED before the shots');
const fresh = main.findIndex(l => /LastWriteTimeUtc\.Ticks -lt \[long\]\$env:START_TICKS/.test(l.s));
assert(fresh > 0 && fresh < main.findIndex(l => l.s.includes('installed_ship_check.gd')), 'the installed glb must be this run\'s before any check');
assert(/for %%S in \(%STAGES%\) do call :stage %%S/.test(text), 'the stages loop runs STAGES in order');
const stage = text.slice(text.indexOf(':stage'));
assert(/if defined FAILED \(\s*\r?\n\s*echo %1 SKIPPED/.test(stage), 'a failed stage skips the later stages');
pass('the guard: a failed fetch, merge, import, stage, install or check never reaches the shots; all three checks count');

// the wait default
const wait = code.findIndex(l => /^if not defined PC_GPU_WAIT_SECONDS set PC_GPU_WAIT_SECONDS=21600$/.test(l.s));
assert(wait > 0, 'PC_GPU_WAIT_SECONDS defaults to 21600');
assert(wait < code.findIndex(l => /tmo\.bat/.test(l.s)), 'the wait default is set before the first GPU step');
const { MAX_WAIT_SECONDS } = require(path.join(ROOT, 'tools/pc/gpu_slots.js'));
assert(21600 <= MAX_WAIT_SECONDS, 'gpu_slots.js accepts the 21600 s wait');
pass('the GPU wait: 21600 s by default for every GPU step, accepted by gpu_slots.js');

// the last line
const finish = code.findIndex(l => l.s === ':finish');
const tailLines = code.slice(finish).map(l => l.s);
assert.deepEqual(tailLines.slice(1, 8), ['if defined FAILED goto finish_failed', 'echo done PASS %DATE% %TIME% >> "%RES%"',
  'echo all done >> "%RES%"', 'exit /b 0', ':finish_failed', 'echo done FAILED: %FAILED% %DATE% %TIME% >> "%RES%"',
  'echo all done >> "%RES%"']);
const start = code.findIndex(l => /^echo start /.test(l.s));
const subs = code.findIndex(l => l.s === ':ship');
for (let i = start; i < subs; i++) {
  if (/exit \/b/i.test(code[i].s)) assert(i > finish, `line ${code[i].n} leaves the job before the done and all done lines`);
}
for (const l of code.slice(start, finish)) {
  if (/goto (\w+)/i.test(l.s)) assert(['collect', 'finish', 'based'].includes(/goto (\w+)/i.exec(l.s)[1]), `line ${l.n}: ${l.s}`);
}
pass('the last line: every way out of the job writes done PASS or done FAILED, then all done');

// no deletes, output only in the job folder
for (const l of code) {
  assert(!/^(del|erase|rd|rmdir|move)\b/i.test(l.s) && !/\b(del|rmdir|rd) \/[sq]/i.test(l.s), `line ${l.n} deletes or moves: ${l.s}`);
  for (const m of l.s.matchAll(/>>?\s*("[^"]*"|\S+)/g)) {
    const target = m[1].replace(/"/g, '');
    if (target === 'nul' || target === '&1') continue;
    assert(/^%(O|RES)%/.test(target), `line ${l.n} writes outside the job's out folder: ${target}`);
  }
}
assert(/^ren "%O%" "out_before_%STAMP%"$/m.test(text.replace(/^if exist "%O%" /m, '')), 'an earlier out folder is renamed, not removed');
assert(/^xcopy \/e \/i \/y \/q "%V%\\recipe\\%SHIP%" "%O%\\recipe"/m.test(text), 'the recipe folder is copied, never moved');
pass('no deletes or moves; logs only under out; the recipe folder copied into out\\recipe');

// the wrappers
const wrappers = fs.existsSync(WRAPPERS) ? fs.readdirSync(WRAPPERS).filter(f => /\.bat$/i.test(f)) : [];
assert(wrappers.length >= 1, 'at least one wrapper (the S10 port) in docs/ship_pipeline/ship_job/wrappers');
for (const f of wrappers) {
  const w = fs.readFileSync(path.join(WRAPPERS, f), 'utf8').split(/\r?\n/).filter(l => l.trim());
  assert.equal(w.length, 3, f + ' is three lines');
  assert.equal(w[0].trim(), '@echo off', f);
  for (const v of ['SHIP', 'CODE', 'BRANCH', 'JOB_DIR']) assert(new RegExp(`set "${v}=[^"]+"`).test(w[1]), `${f} sets ${v}`);
  assert(/^call "%USERPROFILE%\\Downloads\\voidsworn_test\\ship_job\\ship_job\.bat"$/.test(w[2].trim()), f + ' calls the shared copy');
}
pass(`the wrappers: ${wrappers.length} three-line wrapper(s) set the inputs and call the shared job`);
console.log(`PASS ship job checks (${passed} groups)`);
