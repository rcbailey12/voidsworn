'use strict';
// Issue 1311: static checks of tools/pc/jobs/publish_ship.bat, the job that publishes an accepted ship build into build\godot.
// Runs on any host (no cmd needed). What it holds:
//   the guard: after every line that can set FAILED, "if defined FAILED goto finish" comes before the next command;
//   the receipt check (publish_ship.py receipt, exact commit and glb) comes before the first change to build\godot;
//   the old files are kept, with the undo written, before the install; the publish is sealed after it;
//   every Godot and Python step runs through tools_live's tmo.bat;
//   nothing is deleted: no del, erase, rd, rmdir or Remove-Item anywhere; the undo reports FAILED on any failed step;
//   and tools/recipe/test/publish_ship_selftest.py (the real receipts, publish A, publish B, undo A, forced failures) passes.
//   the job ends "all done PASS" or "all done FAILED: ..." on every way out; CRLF line ends.
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const JOB = path.join(ROOT, 'tools/pc/jobs/publish_ship.bat');
let passed = 0;
const pass = s => { passed++; console.log('PASS ' + s); };

const raw = fs.readFileSync(JOB, 'utf8');
assert(!/[^\r]\n/.test(raw), 'publish_ship.bat has CRLF line ends');
pass('CRLF line ends');
const code = raw.split(/\r?\n/).map((l, i) => ({ n: i + 1, s: l.trim() })).filter(l => l.s && !/^rem\b/i.test(l.s));
const at = re => code.findIndex(l => re.test(l.s));
const main = code.slice(0, at(/^:finish$/));
const undo = code.slice(at(/^:undo$/));
const guard = /^(if defined FAILED )?goto finish$/i;
const mayFail = s => /set "FAILED=[^"]/i.test(s);
const isCommand = s => /(tmo\.bat|^powershell |^robocopy |^copy |^fc |^mkdir |^call |^for )/i.test(s);

for (let i = 0; i < main.length; i++) {
  if (!mayFail(main[i].s) || /^\)$/.test(main[i].s)) continue;
  let j = i + 1;
  while (j < main.length && !guard.test(main[j].s) && !isCommand(main[j].s)) j++;
  // the last step (the shots) falls straight into :finish
  assert(j === main.length || guard.test(main[j].s), `line ${main[i].n} can fail, but line ${main[j] && main[j].n} runs before the guard`);
}
pass('every failure reaches the guard before the next command');

const install = at(/manifest_merge\.py" --install/);
assert(install > 0, 'the install runs manifest_merge.py --install');
const receipt = at(/"%PUB%" receipt "%J%" %CODE% %COMMIT% %GLB_SHA% /);
const backup = at(/"%PUB%" backup "%GAME%" %CODE% "%B%"/);
const writeUndo = at(/^call :undo > "%B%\\UNDO_%CODE%\.bat"$/);
assert(receipt > 0 && receipt < backup && backup < writeUndo && writeUndo < install, 'receipt, then backup, then the undo, then the install');
assert(main.some(l => /^if "%GLB_SHA%"=="" \($/.test(l.s)), 'COMMIT and GLB_SHA are required arguments');
const firstGameWrite = main.findIndex(l => /%GAME%\\_replaced/.test(l.s) && /^(mkdir|if not exist|type nul)/i.test(l.s));
assert(firstGameWrite > receipt, 'nothing in build\\godot changes before the receipt check');
assert(raw.includes('.gdignore'), 'the _replaced folder carries a .gdignore');
const seals = main.filter(l => /"%PUB%" seal "%GAME%" %CODE% "%B%"/.test(l.s)).map(l => main.indexOf(l));
assert(seals.length === 2 && seals[0] > install && seals[0] < at(/build_assets\.gd -- --ships-only/), 'sealed right after the install and again later');
assert(main.some(l => /^findstr \/x \/c:"exit \/b 1" "%B%\\UNDO_%CODE%\.bat"/.test(l.s)), 'the job checks UNDO_CODE.bat was written');
assert(/^if not "%EL%"=="0" goto install_failed$/.test(main[install + 4].s), 'a failed install goes to the restore');
assert(main.some(l => /"%PUB%" restore "%GAME%" %CODE% "%B%"/.test(l.s)), 'the restore puts every kept file back after a failed install');
assert(main.some(l => /"%PUB%" locked "%GAME%" "%GD%" .*build_assets\.gd -- --ships-only/.test(l.s)), 'the cache build runs under the install lock');
pass('receipt before any change; old files kept and the undo written before the install; sealed after it; restore on a failed install; cache build locked');

for (const l of main) {
  if (/("%GD%"|"%BPY%")/.test(l.s) && !/^if not exist/i.test(l.s) && !/^set /i.test(l.s)) {
    assert(/^call "%TMO%" \d+ /.test(l.s), `line ${l.n} runs Godot or Python outside tmo.bat: ${l.s}`);
  }
}
assert(main.some(l => /set "TMO=%V%\\tools_live\\%TLV%\\pc\\tmo\.bat"/.test(l.s)), 'TMO is tools_live\'s copy');
assert(['build_assets.gd -- --ships-only', 'installed_ship_check.gd -- %CODE%', 'a4_shots.tscn'].every(s => main.some(l => l.s.includes(s))), 'cache, readback and shots run on build\\godot');
pass('every Godot and Python step runs through tools_live tmo.bat');

for (const l of code) {
  assert(!/(^|[\s&|(])(del|erase|rd|rmdir)\s/i.test(l.s) && !/Remove-Item/i.test(l.s), `line ${l.n} deletes: ${l.s}`);
}
assert(undo.some(l => /publish_ship\.py" undo "%GAME%" %CODE% "%B%"/.test(l.s)), 'the undo runs publish_ship.py undo');
assert(undo.filter(l => /^echo if errorlevel 1 goto failed$/.test(l.s)).length === 2, 'the undo stops and reports FAILED on either step');
assert(undo.some(l => /^echo echo undo of %CODE% FAILED/.test(l.s)), 'the undo reports FAILED');
pass('nothing is deleted, by the job or by its undo');

const outs = code.filter(l => /^echo all done /.test(l.s)).map(l => l.s);
assert(outs.some(s => s.startsWith('echo all done PASS')) && outs.some(s => s.startsWith('echo all done FAILED: %FAILED%')), 'both endings written');
assert(!main.some(l => /^exit \/b [1-9]$/.test(l.s) && code.indexOf(l) > at(/^echo start publish/)), 'after the result starts, every way out goes through :finish');
pass('every way out ends in all done PASS or all done FAILED');
// Fable, PR 1312: a \" in a findstr search string is not an escape to cmd, so the old check could never fail
assert(!code.some(l => /^findstr .*\\"/.test(l.s)), 'no findstr search string holds a backslash quote (cmd does not escape it)');
// Fable, PR 1312: Ryan's real options are hashed before and after, and every step runs in a throwaway profile
const iProf = main.findIndex(l => /^set "APPDATA=%P%\\profile\\Roaming"$/.test(l.s));
const iLocal = main.findIndex(l => /^set "LOCALAPPDATA=%P%\\profile\\Local"$/.test(l.s));
const iFirstTmo = main.findIndex(l => /^call "%TMO%"/.test(l.s));
assert(iProf >= 0 && iLocal >= 0 && iProf < iFirstTmo && iLocal < iFirstTmo, 'APPDATA and LOCALAPPDATA are redirected before the first step');
assert(code.filter(l => /^powershell .*battle_opts\.json','board_look\.cfg.*real_opts_(before|after)\.txt" 2>&1/.test(l.s)).length === 2, 'both options files are hashed before and after');
assert(code.some(l => /^type "%P%\\real_opts_after\.txt" >> "%RES%"$/.test(l.s)), 'the hashes go into result.txt');
assert(code.some(l => /set "FAILED=%OPTSBAD%"/.test(l.s)), 'a change to the real options fails the job');
assert(undo.some(l => /^echo set "APPDATA=%B%\\undo_profile\\Roaming"$/.test(l.s)), 'the undo bat runs in a throwaway profile too');
pass('Ryan\'s real options are hashed before and after into result.txt, every step runs in a throwaway profile, and the undo-bat check can fail');

const py = ['python3', 'python'].map(c => spawnSync(c, ['-B', path.join(ROOT, 'tools/recipe/test/publish_ship_selftest.py')], { encoding: 'utf8' })).find(r => !r.error);
assert(py, 'no python to run publish_ship_selftest.py');
assert.equal(py.status, 0, 'publish_ship_selftest.py failed:\n' + py.stdout + py.stderr);
pass('publish_ship_selftest.py: ' + py.stdout.trim().split('\n').pop());

console.log(`publish_ship_tests: ${passed} passed`);
