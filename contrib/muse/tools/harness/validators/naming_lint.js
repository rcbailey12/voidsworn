// naming_lint.js - retired display-name linter for current-voice documents.
//
// The Oct 29 naming QA pass checked by hand whether old (pre-rename) names
// had caused wrong reads; this linter keeps the cheap half of that check
// alive: it scans prose documents for retired display strings so a stale
// name in a living document is caught at edit time instead of by an audit.
//
// HARD HITS (exit 1): exact retired display strings with a single correct
// replacement.
//   Mending Choir     -> The Mending Throng
//   Discordant volley -> Spitting volley
//   Grax Steelgrin / Steelgrin -> Grax Ironmaw / Ironmaw
//
// LABEL CANDIDATES (warnings): capitalized old faction labels used as
// display names (Deathless, Ithar, Corsair as a faction label). These are
// classified by line context, mirroring the QA pass:
//   ID/HISTORICAL: the line also carries a code or rename marker (a
//     backtick, an id pattern like deathless:, 'formerly', 'renamed',
//     'was', 'retired', 'old name', 'data id') - reported as info.
//   CURRENT-VOICE: no such marker - a candidate stale display use.
// 'Voidsworn' is never flagged: it is the game's title and brand; only the
// faction display name changed (to Sunward Crusade), and prose rarely
// means the faction by it unambiguously.
//
// Targets: pass files or directories as arguments (directories are walked
// for .md and .txt). With no arguments it scans the repo's current-voice
// set: the root docs (NEXT, PROGRESS, BACKLOG, HANDOFF, CLAUDE, AGENTS)
// and docs/. Filed records (contrib reviews, the rename map, the lore
// bible) are history and are never default targets; scan them explicitly
// only to classify, knowing hits there are expected.
//
// An allowlist JSON (path via --allow, default ./naming_allowlist.json
// beside this script when present) maps file substrings to pattern names
// that are exempt in those files, for documents that must quote the old
// names (for example the OPUS_HANDOFF names addendum).
//
// Usage: node naming_lint.js [--allow file.json] [target ...]
'use strict';
const fs = require('fs');
const path = require('path');

const HARD = [
  { re: /Mending Choir/g, name: 'Mending Choir', fix: 'The Mending Throng' },
  { re: /Discordant volley/g, name: 'Discordant volley', fix: 'Spitting volley' },
  { re: /Steelgrin/g, name: 'Steelgrin', fix: 'Ironmaw' },
];
const LABELS = [
  { re: /\bDeathless\b/g, name: 'Deathless (faction label)', fix: 'Eclipse' },
  { re: /\bIthar\b/g, name: 'Ithar (faction label)', fix: 'The Glasswrights' },
  { re: /\bCorsair\b/g, name: 'Corsair (faction label)', fix: 'Ashfall Hullbreakers' },
];
const HISTORICAL = /`|\.js|formerly|renamed|retired|old name|was the|data id|id:|\bold\b/i;

let args = process.argv.slice(2);
let allowPath = path.join(__dirname, 'naming_allowlist.json');
const ai = args.indexOf('--allow');
if (ai >= 0) { allowPath = args[ai + 1]; args = args.filter((_, i) => i !== ai && i !== ai + 1); }
let allow = {};
if (allowPath && fs.existsSync(allowPath)) allow = JSON.parse(fs.readFileSync(allowPath, 'utf8'));

let targets = args;
if (!targets.length) {
  const root = path.join(__dirname, '..', '..', 'voidsworn-fresh');
  targets = ['NEXT.md', 'PROGRESS.md', 'BACKLOG.md', 'HANDOFF.md', 'CLAUDE.md', 'AGENTS.md', 'docs']
    .map(t => path.join(root, t)).filter(t => fs.existsSync(t));
}

function filesOf(t) {
  const st = fs.statSync(t);
  if (st.isFile()) return [t];
  const out = [];
  for (const e of fs.readdirSync(t, { withFileTypes: true })) {
    if (e.name.startsWith('.')) continue;
    const p = path.join(t, e.name);
    if (e.isDirectory()) out.push(...filesOf(p));
    else if (/\.(md|txt)$/.test(e.name)) out.push(p);
  }
  return out;
}
const exempt = (file, patName) => Object.entries(allow).some(([sub, pats]) => file.includes(sub) && pats.includes(patName));

let hard = 0, cand = 0, hist = 0;
for (const t of targets) {
  for (const f of filesOf(t)) {
    const lines = fs.readFileSync(f, 'utf8').split('\n');
    lines.forEach((line, i) => {
      const where = f + ':' + (i + 1);
      for (const p of HARD) {
        if (exempt(f, p.name)) continue;
        const m = line.match(p.re);
        if (m) { hard += m.length; console.log('HARD ' + where + ' "' + p.name + '" -> ' + p.fix + ' :: ' + line.trim().slice(0, 110)); }
      }
      for (const p of LABELS) {
        if (exempt(f, p.name)) continue;
        const m = line.match(p.re);
        if (!m) continue;
        if (HISTORICAL.test(line)) { hist += m.length; }
        else { cand += m.length; console.log('CANDIDATE ' + where + ' "' + p.name + '" -> ' + p.fix + ' :: ' + line.trim().slice(0, 110)); }
      }
    });
  }
}
console.log('naming_lint: ' + hard + ' hard hits, ' + cand + ' current-voice candidates, ' + hist + ' historical/id mentions (info)');
process.exit(hard ? 1 : 0);
