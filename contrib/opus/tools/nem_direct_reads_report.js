'use strict';
// Issue 364: report only. Count the direct save reads outside godot/campaign/ so the UI rollout (issue 344) can watch
// the number fall as screens move to the campaign's read-only view API. This is a report, not a gate: it always exits 0.
// Pattern, as the Board re-measured it: RUN[ RUN.get( run.get( run[ Bs.get( Bs[ in .gd files, test folders left out.
// godot/rules is left out too: it reads the battle and run state by design and is not a screen the rollout rewrites.
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const GODOT = path.join(ROOT, 'godot');
const RE = /(?:\bRUN\[|\bRUN\.get\(|\brun\.get\(|\brun\[|\bBs\.get\(|\bBs\[)/g;
const byTop = {};
let total = 0;
function walk(dir) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const rel = path.relative(ROOT, p).split(path.sep).join('/');
    if (rel === 'godot/campaign' || rel.startsWith('godot/campaign/')) continue;
    if (rel === 'godot/rules' || rel.startsWith('godot/rules/')) continue;
    const st = fs.statSync(p);
    if (st.isDirectory()) { walk(p); continue; }
    if (!name.endsWith('.gd')) continue;
    if (/(^|\/)test(\/|$)/.test(rel)) continue;
    const text = fs.readFileSync(p, 'utf8');
    const n = (text.match(RE) || []).length;
    if (!n) continue;
    const top = rel.split('/')[1] || '(root)';
    byTop[top] = (byTop[top] || 0) + n;
    total += n;
  }
}
walk(GODOT);
const keys = Object.keys(byTop).sort();
for (const k of keys) console.log('  ' + k + ' ' + byTop[k]);
console.log('PASS: report only, ' + total + ' direct save reads outside godot/campaign (' + keys.map(k => k + ' ' + byTop[k]).join(', ') + ')');
