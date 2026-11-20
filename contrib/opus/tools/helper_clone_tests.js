'use strict';
// Issue 1180: tools/pc/helper_clone.ps1 is the one shared base for helper PC jobs. Static contract (it needs the PC's
// mirror and network to run): shared objects, the mirror lock, reuse without resetting work, copied (never linked) ships.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../../..');
const ps = fs.readFileSync(path.join(root, 'tools/pc/helper_clone.ps1'), 'utf8');
const bat = fs.readFileSync(path.join(root, 'tools/pc/helper_clone.bat'), 'utf8');
const code = ps.split(/\r?\n/).filter(line => !line.trim().startsWith('#')).join('\n');
assert.match(code, /clone --local -q --no-checkout \$mirror \$repo/, 'clones from the shared mirror with shared objects');
assert.match(code, /\$mirror \+ '\.lock', 'OpenOrCreate', 'ReadWrite', 'None'/, 'takes the same mirror lock as the runners');
assert.match(code, /status --porcelain --untracked-files=no/, 'checks a reused clone for local edits first');
assert.match(code, /rev-list HEAD --not --remotes=origin/, 'checks a reused clone for local-only commits first');
assert.match(code, /StartsWith\(\$vt \+ '\\'/, 'job folder must be under voidsworn_test');
assert.match(code, /get_ship_files\.bat/, 'ships come from the checked copy step');
for (const banned of [/reset\s+--hard/, /checkout\s+(-q\s+)?-f\b/, /--force/, /Remove-Item/, /\bclean\s+-/, /HardLink|mklink|SymbolicLink/i,
  /github\.com\/rcbailey12\/voidsworn'.*clone/]) {
  assert.doesNotMatch(code, banned, `helper_clone.ps1 must not use ${banned}`);
}
assert.match(bat, /helper_clone\.ps1" -JobDir "%~1" -Branch "%~2" -Ships "%~3"/);
assert.match(bat, /exit \/b %ERRORLEVEL%/);
console.log('PASS helper clone: shared mirror objects under the mirror lock, reuse never resets work, ships copied and checked');
