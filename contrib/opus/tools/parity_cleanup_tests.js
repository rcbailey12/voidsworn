'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { withRunRoot } = require('../../../godot/rules/test/node/run_parity');

async function test() {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), 'parity-cleanup-proof-'));
  const neighbor = path.join(parent, 'voidsworn-parity-other-run');
  process.env.RUNNER_TEMP = parent;
  process.env.USERPROFILE = path.join(parent, 'unused-profile');
  delete process.env.PARITY_RUN_ROOT;
  delete process.env.GITHUB_ACTIONS;
  let scratch;
  function useScratch(dir) {
    scratch = dir;
    assert.equal(path.dirname(dir), parent);
    assert.match(path.basename(dir), /^voidsworn-parity-/);
    assert.notEqual(dir, neighbor);
    fs.mkdirSync(path.join(dir, 'workers'));
    fs.writeFileSync(path.join(dir, 'workers', 'parity.log'), 'check output');
  }
  try {
    fs.mkdirSync(neighbor);
    fs.writeFileSync(path.join(neighbor, 'proof.txt'), 'another run');
    for (const code of [0, 1]) {
      assert.equal(await withRunRoot(dir => { useScratch(dir); return code; }), code);
      assert(!fs.existsSync(scratch), `scratch left after exit ${code}`);
    }
    await assert.rejects(withRunRoot(dir => {
      useScratch(dir);
      throw new Error('worker failed');
    }), /worker failed/);
    assert(!fs.existsSync(scratch), 'scratch left after an exception');
    assert.equal(fs.readFileSync(path.join(neighbor, 'proof.txt'), 'utf8'), 'another run');

    const chosen = path.join(parent, 'chosen-records');
    process.env.PARITY_RUN_ROOT = chosen;
    assert.equal(await withRunRoot(dir => {
      assert.equal(dir, chosen);
      fs.writeFileSync(path.join(dir, 'evidence'), 'failure details');
      return 1;
    }), 1);
    await assert.rejects(withRunRoot(() => assert.fail('used a nonempty output folder')), /must be empty/);
    assert.equal(fs.readFileSync(path.join(chosen, 'evidence'), 'utf8'), 'failure details');
    delete process.env.PARITY_RUN_ROOT;

    process.env.GITHUB_ACTIONS = 'true';
    assert.equal(await withRunRoot(dir => { useScratch(dir); return 0; }), 0);
    assert(fs.existsSync(path.join(scratch, 'workers', 'parity.log')), 'CI evidence must survive');
    delete process.env.GITHUB_ACTIONS;
    if (process.platform === 'win32') {
      const pause = path.join(process.env.USERPROFILE, 'Downloads', 'voidsworn_test', 'gpu_go.txt');
      fs.mkdirSync(path.dirname(pause), { recursive: true });
      fs.writeFileSync(pause, 'GPU not cleared: paused by the Board at 12:30');
      assert.equal(await withRunRoot(dir => { useScratch(dir); return 1; }), 1);
      assert(fs.existsSync(path.join(scratch, 'workers', 'parity.log')), 'parity scratch must survive a pause');
    }
    console.log('PASS parity cleanup: pass, failure, exception, other runs, explicit records, CI and PC pause');
  } finally {
    fs.rmSync(parent, { recursive: true, force: true, maxRetries: 3 });
  }
}
test().catch(e => { console.error(e); process.exitCode = 1; });
