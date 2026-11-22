// Short test for tools/ai_pair_1160.js: the same battles give the same results however they are sharded (true pairs),
// seeds are shared across AI levels, and the summary math holds.
const H = require('./ai_pair_1160.js'), assert = require('assert');
(async () => {
  assert.strictEqual(H.median([3, 1, 2]), 2); assert.strictEqual(H.median([1, 2, 3, 4]), 2.5);
  const list = H.jobs(3, ['hegemony', 'corsair'], [1], ['standard', 'veteran']);
  assert.strictEqual(list.length, 12);
  assert.strictEqual(list[0].seed, list[6].seed, 'battle 0 meets the same seed at both levels');
  const a = await H.run(list, 1), b = await H.run(list, 3);
  assert.deepStrictEqual(a, b, 'sharding must not change any battle');
  const s = H.summarize(a);
  assert.strictEqual(s['standard|all|all'].n, 6); assert.strictEqual(s['veteran|1|corsair'].n, 3);
  console.log('PASS: ai_pair_1160 harness: 12 battles identical across 1 and 3 workers, seeds shared across levels, summary counts hold');
})().catch(e => { console.error('FAIL:', e.message); process.exit(1); });
