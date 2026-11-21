'use strict';
// Issue 1487 (audit GH-03): decides whether a push changed only writing and pictures, so checks.yml can skip the four Godot
// jobs for it. The standing checks (em dashes, rules text, picture provenance) always run, whatever this says.
// Usage: node tools/ci/docs_only.js <file with one changed path per line>   prints docs_only=true|false and the reason.
// Self-test: node tools/ci/docs_only.js --self-test
// Kept narrow on purpose: when in doubt a path counts as code and every check runs.
//   Docs: a .md file or a picture, video or PDF, at the repo root or under docs/ or contrib/.
//   Code: everything else, including every file under godot/ (godot/story/outlines.md is read by a test), any .json
//   (docs/ship_pipeline/build_sheets/*/checks.json is read by formation_check.gd), .js under contrib/ (the Godot checks run
//   contrib/opus/tools and contrib/codex scripts) and anything in .github/.
const fs = require('fs');

const DOC_EXT = /\.(?:md|png|jpe?g|webp|gif|mp4|webm|pdf)$/i;

function isDoc(path) {
  if (!DOC_EXT.test(path)) return false;
  return !path.includes('/') || path.startsWith('docs/') || path.startsWith('contrib/');
}

function classify(paths) {
  const list = paths.map(p => p.trim()).filter(Boolean);
  // An empty list means the comparison saw nothing (a ref compared with itself, such as main with main): run everything.
  if (!list.length) return { docsOnly: false, reason: 'no changed files found, so every check runs' };
  const code = list.filter(p => !isDoc(p));
  if (code.length) return { docsOnly: false, reason: `${code.length} of ${list.length} changed file(s) are not docs, first: ${code[0]}` };
  return { docsOnly: true, reason: `all ${list.length} changed file(s) are docs or pictures` };
}

function selfTest() {
  const cases = [
    [['contrib/muse/reviews/x/PACK.md', 'docs/shots/a.jpg', 'HANDOFF.md'], true],
    [[], false],
    [['godot/story/outlines.md'], false],
    [['docs/ship_pipeline/build_sheets/voidsworn_SF3/checks.json'], false],
    [['contrib/opus/tools/check_em_dashes.js'], false],
    [['docs/a.md', 'godot/rules/rules.gd'], false],
    [['.github/workflows/checks.yml'], false],
    [['hulls/C19_51.png'], false],
    [['tools/shots/x.png'], false],
    [['battle.js'], false],
  ];
  let bad = 0;
  for (const [paths, want] of cases) {
    const got = classify(paths).docsOnly;
    if (got !== want) { bad++; console.log(`FAIL: ${JSON.stringify(paths)} gave ${got}, want ${want}`); }
  }
  // Regression (Artoo on PR 1494): a run on main compares main with itself, an empty list, so it must run every check;
  // and All checks may accept a skip only from the four Godot jobs. Both live in checks.yml: hold them here.
  const yml = fs.readFileSync(require('path').join(__dirname, '../../.github/workflows/checks.yml'), 'utf8');
  const wiring = [
    ['main with no base runs every check', /\[ -z "\$BASE" \] && \{ \[ "\$EVENT" = workflow_dispatch \] \|\| \[ "\$GITHUB_REF" = refs\/heads\/main \]; \}/],
    ['All checks accepts skips only from the four Godot jobs', /IN\("godot-parity", "rules-safety", "godot-game", "a16-fixture"\)/],
  ];
  for (const [what, re] of wiring) if (!re.test(yml)) { bad++; console.log(`FAIL: checks.yml lost: ${what}`); }
  console.log(bad ? `FAIL: ${bad} of ${cases.length + wiring.length} cases` : `PASS: ${cases.length} cases, ${wiring.length} checks.yml wiring checks`);
  return bad ? 1 : 0;
}

if (require.main === module) {
  if (process.argv[2] === '--self-test') process.exit(selfTest());
  const r = classify(fs.readFileSync(process.argv[2], 'utf8').split('\n'));
  console.log(`docs_only=${r.docsOnly}`);
  console.log(r.reason);
}

module.exports = { classify, isDoc };
