'use strict';
// Refs #838. Offline replay of saved REST replies, including both auth routes.
const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { generateOpenWork, renderOpenWork } = require('./gen_open_work');
const FIXTURES = path.join(__dirname, 'fixtures/open_work');
const read = file => fs.readFileSync(path.join(FIXTURES, file));
const saved = JSON.parse(read('api_replies.json'));
const edges = JSON.parse(read('edge_cases.json'));
// This instant is Nov 16 in the input's offset, but Nov 15 in UTC.
const now = new Date('2026-11-16T01:20:47+02:00');
let passed = 0;

function replyPage(endpoint, data, perPage, calls) {
  const url = new URL(endpoint, 'https://api.github.com/');
  assert.equal(url.origin, 'https://api.github.com');
  const match = /^\/repos\/rcbailey12\/voidsworn\/(pulls|issues)$/.exec(url.pathname);
  assert.ok(match, 'REST endpoint belongs to this repo');
  assert.equal(url.searchParams.get('state'), 'open');
  assert.equal(url.searchParams.get('per_page'), String(perPage));
  const page = Number(url.searchParams.get('page'));
  assert.ok(Number.isInteger(page) && page > 0);
  calls.push(match[1] + ':' + page);
  return data[match[1]].slice((page - 1) * perPage, page * perPage);
}

function assertPageVisits(calls, data, perPage) {
  const expected = [];
  for (const resource of ['pulls', 'issues']) {
    for (let i = 1; i <= Math.floor(data[resource].length / perPage) + 1; i++) expected.push(resource + ':' + i);
  }
  assert.deepEqual(calls, expected, 'both endpoints are read through the final page');
}

async function check(name, test) {
  await test();
  passed++;
  console.log('PASS ' + name);
}

async function main() {
  for (const [env, expectedToken] of [
    [{ GH_TOKEN: 'first-test-token', GITHUB_TOKEN: 'second-test-token' }, 'first-test-token'],
    [{ GITHUB_TOKEN: 'second-test-token' }, 'second-test-token'],
  ]) {
    await check(Object.keys(env)[0] + ' REST replay matches expected bytes', async () => {
      const calls = [];
      const output = await generateOpenWork({
        env, now, perPage: 20,
        runGh: () => { throw new Error('gh must not run with a token'); },
        fetchImpl: async (url, options) => {
          assert.equal(options.headers.Authorization, 'Bearer ' + expectedToken);
          assert.equal(options.headers.Accept, 'application/vnd.github+json');
          assert.ok(options.headers['User-Agent']);
          assert.ok(options.headers['X-GitHub-Api-Version']);
          assert.ok(options.signal instanceof AbortSignal);
          return { ok: true, json: async () => replyPage(url, saved, 20, calls) };
        },
      });
      assert.deepEqual(Buffer.from(output), read('expected.md'));
      assertPageVisits(calls, saved, 20);
    });
  }

  await check('gh api REST replay matches expected bytes without a token', async () => {
    const calls = [];
    const env = { PATH: 'test-path' };
    const output = await generateOpenWork({
      env, now, perPage: 20,
      fetchImpl: () => { throw new Error('fetch must not run without a token'); },
      runGh: async (file, args, options) => {
        assert.equal(file, 'gh');
        assert.deepEqual(args.slice(0, -1), ['api', '--hostname', 'github.com', '--method', 'GET']);
        assert.equal(options.env, env);
        assert.equal(options.windowsHide, true);
        assert.ok(options.timeout > 0);
        return { stdout: JSON.stringify(replyPage(args.at(-1), saved, 20, calls)) };
      },
    });
    assert.deepEqual(Buffer.from(output), read('expected.md'));
    assertPageVisits(calls, saved, 20);
  });

  await check('table text, UTC stamp, sort order and PR exclusion match expected bytes', async () => {
    const before = JSON.stringify(edges);
    const calls = [];
    const output = await generateOpenWork({
      env: { GH_TOKEN: 'test-token' }, now, perPage: 2,
      fetchImpl: async url => ({ ok: true, json: async () => replyPage(url, edges, 2, calls) }),
    });
    assert.deepEqual(Buffer.from(output), read('edge_expected.md'));
    assert.ok(!output.includes('\u2014'));
    assert.ok(!output.includes('Exclude this PR'));
    assert.equal(JSON.stringify(edges), before, 'rendering does not mutate the API data');
    assertPageVisits(calls, edges, 2); // Exactly full PR page requires a final empty page.
  });

  await check('empty endpoints still produce both table headers', async () => {
    const calls = [];
    const output = await generateOpenWork({
      env: { GH_TOKEN: 'test-token' }, now,
      fetchImpl: async url => ({ ok: true, json: async () => replyPage(url, { pulls: [], issues: [] }, 100, calls) }),
    });
    assert.equal(output, renderOpenWork([], [], now));
    assert.equal(output.split('\n').filter(line => line.startsWith('|')).length, 4);
    assert.deepEqual(calls, ['pulls:1', 'issues:1']);
  });

  await check('later-page HTTP failure rejects the whole page', async () => {
    await assert.rejects(generateOpenWork({
      env: { GH_TOKEN: 'test-token' }, perPage: 2,
      fetchImpl: async url => url.includes('page=1')
        ? { ok: true, json: async () => edges.pulls }
        : { ok: false, status: 403 },
    }), /pulls page 2: HTTP 403/);
  });

  await check('issues failure after PRs loaded rejects the whole page', async () => {
    await assert.rejects(generateOpenWork({
      env: { GH_TOKEN: 'test-token' },
      fetchImpl: async url => url.includes('/pulls?')
        ? { ok: true, json: async () => [] }
        : { ok: false, status: 500 },
    }), /issues page 1: HTTP 500/);
  });

  await check('malformed REST replies fail loudly', async () => {
    await assert.rejects(generateOpenWork({
      env: { GH_TOKEN: 'test-token' },
      fetchImpl: async () => ({ ok: true, json: async () => ({ message: 'bad response' }) }),
    }), /expected an array/);
  });

  await check('gh failures and invalid JSON fail loudly', async () => {
    await assert.rejects(generateOpenWork({ env: {}, runGh: async () => {
      throw Object.assign(new Error('exit 1'), { stderr: 'authentication required' });
    } }), /gh api pulls page 1 failed: authentication required/);
    await assert.rejects(generateOpenWork({ env: {}, runGh: async () => ({ stdout: '{' }) }), SyntaxError);
  });

  await check('CLI failure returns nonzero with no partial Markdown on stdout', async () => {
    const result = spawnSync(process.execPath, [path.join(__dirname, 'gen_open_work.js')], {
      env: { ...process.env, GH_TOKEN: '', GITHUB_TOKEN: '', PATH: '' },
      encoding: 'utf8', windowsHide: true, timeout: 10000,
    });
    assert.ifError(result.error);
    assert.equal(result.status, 1);
    assert.equal(result.stdout, '');
    assert.match(result.stderr, /Set GH_TOKEN or GITHUB_TOKEN, or install gh/);
  });

  console.log(`PASS: ${passed} open work generator tests (offline)`);
}

main().catch(error => { console.error('FAIL: ' + error.stack); process.exitCode = 1; });
