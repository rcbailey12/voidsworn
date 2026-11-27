'use strict';
// Test the Board's workflow handoff before rollout without touching the live workflow directory.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

function workflowTexts() {
  const root = path.resolve(__dirname, '../../..');
  const dir = path.join(root, '.github/workflows');
  const read = (from, name) => fs.readFileSync(path.join(from, name), 'utf8').replace(/\r\n/g, '\n');
  const texts = new Map(fs.readdirSync(dir).filter(name => /\.ya?ml$/.test(name)).map(name => [name, read(dir, name)]));
  const patch = path.join(root, 'contrib/codex/issue-2179/workflows.patch');
  if (texts.has('main_checks.yml') || !fs.existsSync(patch)) return texts;

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'issue-2179-workflow-'));
  try {
    for (const name of ['checks.yml', 'auto_pr.yml']) fs.writeFileSync(path.join(tmp, name), texts.get(name));
    // Strip a/.github/workflows so git apply writes only to the fixture.
    const result = spawnSync('git', ['apply', '-p3', '--whitespace=error', patch], {
      cwd: tmp, encoding: 'utf8', windowsHide: true, timeout: 20000,
    });
    assert.ifError(result.error);
    assert.equal(result.status, 0, result.stderr);
    for (const name of fs.readdirSync(tmp)) texts.set(name, read(tmp, name));
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
  return texts;
}

module.exports = { workflowTexts };
