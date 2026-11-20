'use strict';
// Issue 1311: static checks of tools/pc/jobs/publish_ship.bat, the job that publishes an accepted ship build into build\godot.
// Runs on any host (no cmd needed). What it holds:
//   the guard: after every line that can set FAILED, "if defined FAILED goto finish" comes before the next command;
//   the refusals (no done PASS, a done FAILED, no commit= line, not ending in all done, another code, an export that is not
//     what the job checked) all come before the first change to build\godot;
//   the old files are copied aside, with the undo written, before the install;
//   every Godot and Python step runs through tools_live's tmo.bat;
//   nothing is deleted: no del, erase, rd, rmdir or Remove-Item anywhere, and the undo only moves and copies;
//   the job ends "all done PASS" or "all done FAILED: ..." on every way out; CRLF line ends.
const assert = require('assert');
const fs = require('fs');
const path = require('path');
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
const guard = /^if defined FAILED goto finish$/i;
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
for (const re of [/done PASS/, /done FAILED/, /commit=/, /LAST:~0,8%"=="all done"/, /built %JCODE%, not %CODE%/, /differs from what the job checked/, /StartsWith\(\$env:WANT/]) {
  const k = at(re);
  assert(k > 0 && k < install, `refusal ${re} comes before the install`);
}
const firstGameWrite = main.findIndex(l => /%GAME%\\_replaced|"%B%/.test(l.s) && /^(mkdir|if not exist|robocopy|copy|type nul|for |call :undo)/i.test(l.s));
const lastRefusal = at(/differs from what the job checked/);
assert(firstGameWrite > lastRefusal, 'nothing in build\\godot changes before the last refusal');
pass('every refusal comes before the first change to build\\godot');

const backup = at(/robocopy "%GAME%\\assets\\ships\\%CODE%" "%B%\\ship"/);
const writeUndo = at(/^call :undo > "%B%\\UNDO_%CODE%\.bat"$/);
assert(backup > 0 && backup < install, 'the old ship folder is copied aside before the install');
assert(writeUndo > 0 && writeUndo < install, 'the undo bat is written before the install');
assert(raw.includes('.gdignore'), 'the _replaced folder carries a .gdignore');
pass('old files aside and the undo written before the install');

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
assert(undo.some(l => /^echo if exist .* move /.test(l.s)), 'the undo moves the published ship aside');
pass('nothing is deleted, by the job or by its undo');

const outs = code.filter(l => /^echo all done /.test(l.s)).map(l => l.s);
assert(outs.some(s => s.startsWith('echo all done PASS')) && outs.some(s => s.startsWith('echo all done FAILED: %FAILED%')), 'both endings written');
assert(!main.some(l => /^exit \/b [1-9]$/.test(l.s) && code.indexOf(l) > at(/^echo start publish/)), 'after the result starts, every way out goes through :finish');
pass('every way out ends in all done PASS or all done FAILED');

console.log(`publish_ship_tests: ${passed} passed`);
