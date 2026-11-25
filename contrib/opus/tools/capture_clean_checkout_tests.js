'use strict';
// Issue 2062: a capture refuses a checkout whose `git status --porcelain` is not empty (the clean-checkout gate in the
// issue 2001 capture launcher, PR 2017, reads `git status --porcelain` with no `--ignored`). The ships step copies the
// PC backups named manifest.json.bak_<stamp> into the warm slot repo, and those untracked files failed the MM_TRIAL
// capture. The root .gitignore ignores those backups, so the same check must now see a clean checkout.
// Auto-discovered by run_all_checks.js (every *_tests.js here runs as a row).
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const root = path.join(__dirname, '..', '..', '..');
const RULE = 'godot/assets/ships/manifest.json.bak_*';
const BACKUP = 'godot/assets/ships/manifest.json.bak_20261116_120000';

const rootIgnore = fs.readFileSync(path.join(root, '.gitignore'), 'utf8');
assert.ok(rootIgnore.split(/\r?\n/).includes(RULE), 'the root .gitignore has the line ' + RULE);

// Build a temp checkout like the warm slot repo, commit its files, then drop in the untracked PC backup.
function checkout(ignoreText) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'capture clean 2062 '));
  const write = (name, text) => {
    const file = path.join(dir, name);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, text);
  };
  const git = (...args) => {
    const r = spawnSync('git', ['-C', dir, ...args], { encoding: 'utf8', windowsHide: true });
    assert.equal(r.status, 0, 'git ' + args.join(' ') + ': ' + (r.stderr || ''));
    return r.stdout;
  };
  git('init', '-q');
  write('.gitignore', ignoreText);
  write('godot/assets/ships/manifest.json', '{}\n');
  git('add', '.gitignore', 'godot/assets/ships/manifest.json');
  git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-q', '-m', 'fixture');
  write(BACKUP, 'backup\n');
  return { dir, git };
}

const fixed = checkout(rootIgnore);
try {
  assert.equal(fixed.git('check-ignore', '--quiet', BACKUP), '', 'the root rule ignores the backup');
  assert.equal(fixed.git('status', '--porcelain'), '', 'the capture clean check is empty with a backup present');
  assert.match(fixed.git('status', '--porcelain', '--ignored'), /manifest\.json\.bak_20261116_120000/,
    'the backup is present and ignored, not absent');
} finally {
  fs.rmSync(fixed.dir, { recursive: true, force: true });
}

// Control: without the rule the same backup fails the capture clean check, so the rule is what makes it clean.
const control = checkout('node_modules/\n');
try {
  assert.match(control.git('status', '--porcelain'), /^\?\? godot\/assets\/ships\/manifest\.json\.bak_20261116_120000$/m,
    'without the rule the backup shows as untracked');
} finally {
  fs.rmSync(control.dir, { recursive: true, force: true });
}

console.log('PASS capture_clean_checkout_tests: a checkout holding a ships manifest.json.bak backup passes the capture clean check after the root ignore rule, and fails it without');
