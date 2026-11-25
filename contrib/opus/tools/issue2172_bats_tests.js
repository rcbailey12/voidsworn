'use strict';
// Issue 2172 items 20 and 21, checked as text: the key savers must read the paste without echoing it, and play.bat must
// start the Godot game instead of the retired browser game. Text only, so the same check runs on the PC and in CI.
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const repo = path.resolve(__dirname, '../../..');
const read = file => fs.readFileSync(path.join(repo, file), 'utf8');
const keys = [
  ['tools/pc/claude_api_key.bat', 'VOIDSWORN_CLAUDE_API_KEY'],
  ['tools/pc/openai_api_key.bat', 'VOIDSWORN_OPENAI_API_KEY'],
  ['tools/pc/kimi_code_key.bat', 'KIMI_CODE_API_KEY'],
];
for (const [file, name] of keys) {
  const text = read(file);
  assert(!/set\s+\/p/i.test(text), file + ' must not read the key with set /p, which echoes the pasted key');
  assert(/Read-Host -AsSecureString/i.test(text), file + ' must read the key with PowerShell Read-Host -AsSecureString');
  assert(text.includes(`'${name}'`), file + ' must save the key as ' + name);
  assert(!/%K%/.test(text), file + ' must not keep the key in a batch variable that could be printed');
  assert(!/echo\s+.*%[A-Za-z_]+%/i.test(text), file + ' must not print an environment value');
}
const play = read('tools/pc/play.bat');
assert(/play_godot\.bat/i.test(play), 'play.bat must start the Godot game');
assert(!/msedge|index_test\.html|http\.server/i.test(play), 'play.bat must not open the retired browser game');
console.log('PASS: key savers hide the paste; play.bat opens the Godot game');
