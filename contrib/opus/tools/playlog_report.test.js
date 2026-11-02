'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { load, report } = require('./playlog_report');

// These are the fields emitted by PlayLog.open/act/close/summary and _play_log_out.
function activation(ship, think, acts, end, cancels = 0) {
  return { r: 1, ship, name: ship, tpl: 'test_hull', cls: 'frigate', how: 'auto',
    acts, plans: acts.some(a => a.k === 'move') ? 2 : 0, targets: 0, inspects: 1,
    cancels, think_ms: think, dur_ms: Math.max(think, ...acts.map(a => a.at)) + 1000, end };
}
const battle = { v: 1, result: 'win', rounds: 2, secs: 120, hurries: 1,
  enemy_s: { '1': 4.25, '2': 6.5 }, acts: [
    activation('Scout', 2000, [{ k: 'move', at: 2000, cost: 2, to: '1,2', f: 0 },
      { k: 'fire', at: 4000, guns: 2, target: 'destroyer', tid: 'e1', armed: false }], 'nothing_left', 3),
    activation('Guard', 6000, [{ k: 'brace', at: 6000 }], 'brace', 1),
    activation('Idle', 9000, [], 'space_pass'),
    activation('Striker', 10000, [{ k: 'fire', at: 10000, guns: 1, target: 'frigate', tid: 'e2', armed: true }], 'rules')
  ], battle: { seed: 42, obj: 'rout', enemy: 'corsair', campaign: true } };
// close() uses the whole duration as think_ms when there was no action.
battle.acts[2].dur_ms = 9000;
const temp = fs.mkdtempSync(path.join(__dirname, '.playlog-test-'));
try {
  const logs = path.join(temp, 'play_logs'); fs.mkdirSync(logs);
  fs.writeFileSync(path.join(logs, 'battle_2026-11-01T20-00-00.json'), JSON.stringify(battle));
  const campaignFile = path.join(temp, 'voidsworn_campaign.json');
  const { battle: meta, ...summary } = battle;
  const save = { format: 'voidsworn-godot-campaign', v: 1, uid: 'test', meta: {}, run: { none: true }, tel: [
    { t: 1, ev: 'run_start', sector: 1, fac: 'player_fac', admiral: 'vex' },
    { t: 2, ev: 'battle_start', sector: 1, seed: 42, obj: { type: 'rout' }, kind: 'battle', fac: 'corsair' },
    { t: 3, ev: 'battle_play', sector: 1, ...summary, enemy_s: { '1': '#d:4011000000000000', '2': 6.5 } },
    { t: 4, ev: 'battle_end', sector: 1, result: 'win', kind: 'battle', fac: 'corsair', rounds: 2, kills: 2, lost: 0 }
  ] };
  fs.writeFileSync(campaignFile, JSON.stringify(save));
  const out = path.join(temp, 'report.md');
  const cli = spawnSync(process.execPath, [path.join(__dirname, 'playlog_report.js'), logs, campaignFile, '--out', out], { encoding: 'utf8' });
  assert.equal(cli.status, 0, cli.stderr);
  assert.equal(cli.stdout, fs.readFileSync(out, 'utf8'));
  const text = cli.stdout;
  for (const expected of ['Battles played: 1.', '| corsair | rout | win | 2 | 2.00 |',
    'Average think time: 6.00s. Median: 6.00s.', '2/4 (50.00%)', 'Cancels: 4;',
    'average per battle with activation details: 4.00', 'round 1: 4.25s; round 2: 6.50s',
    '9.00 (until close)', '| pass | space_pass |', 'Scout: 3 cancels',
    '1. Battle 1, round 1, Striker', 'fire @ 4.00s', 'Plans, targets, inspections and cancels are counts']) assert.ok(text.includes(expected), expected);
  assert.ok(!text.includes('Idle [Idle]: 9.00s; first action'));
  assert.ok(/^[\x00-\x7f]*$/.test(text));
  const fallback = load(path.join(temp, 'missing'), campaignFile, true);
  assert.equal(fallback.battles.length, 1);
  assert.equal(fallback.battles[0].log.enemy_s['1'], 4.25);
  assert.ok(report(fallback).includes('| corsair | rout | win | 2 | 2.00 |'));
  const empty = report({ battles: [] });
  assert.ok(empty.includes('Battles played: 0.'));
  assert.ok(!empty.includes('NaN'));
  const trimmed = { ...summary }; delete trimmed.acts;
  assert.ok(report({ battles: [{ source: 'old', log: trimmed }] }).includes('Activation details not retained.'));
  const even = report({ battles: [{ source: 'even', log: { ...battle, acts: [battle.acts[0], battle.acts[1]] } }] });
  assert.ok(even.includes('Average think time: 4.00s. Median: 4.00s.'));
  const invalid = spawnSync(process.execPath, [path.join(__dirname, 'playlog_report.js'), '--out'], { encoding: 'utf8' });
  assert.equal(invalid.status, 1);
  console.log('All playlog report tests passed. CLI stdout and --out verified.');
  console.log('\nSynthetic report:\n');
  process.stdout.write(text);
} finally {
  // Only remove this test's uniquely named scratch directory inside tools.
  if (path.dirname(temp) !== __dirname || !path.basename(temp).startsWith('.playlog-test-')) throw new Error('Unsafe test cleanup');
  fs.rmSync(temp, { recursive: true, force: true });
}
