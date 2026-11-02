'use strict';
// Focused onboarding checks plus the full standing rules and 30-run campaign parity suites.
// All generated files and Godot user data stay inside this checkout.
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..'), out = path.join(root, '.onboarding_checks');
fs.mkdirSync(out, { recursive: true });
const godot = process.argv[2];
if (!godot || !fs.existsSync(godot)) throw new Error('Pass the path to the Godot console executable.');
if (Number(process.versions.node.split('.')[0]) !== 22) throw new Error('Use the project Node 22 oracle runtime (voidsworn_test/node/node.exe). The rules math port targets V8 in Node 22.');
const env = { ...process.env, APPDATA: path.join(out, 'appdata') };
env.NODE_OPTIONS = ((env.NODE_OPTIONS || '') + ' --preserve-symlinks --preserve-symlinks-main').trim();
delete env.VS_ORACLE;
let serial = 0;
function run(exe, args, label) {
  const r = spawnSync(exe, args, { cwd: root, env, encoding: 'utf8', timeout: 240000, maxBuffer: 32 * 1024 * 1024, windowsHide: true });
  const text = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(path.join(out, `${++serial}_${label.replace(/[^a-z0-9]/gi, '_')}.log`), text);
  if (r.error || r.status !== 0 || /SCRIPT ERROR|Parse Error|FAIL(?!ED to read the root certificate store)/.test(text)) {
    console.error(text.slice(-8000)); throw r.error || new Error(label + ' failed with exit ' + r.status);
  }
  return text;
}
function node(file, args = [], label = path.basename(file)) { return run(process.execPath, [file, ...args], label); }
function gd(script, args = [], label = path.basename(script), check = false) {
  return run(godot, ['--headless', '--path', 'godot', '--log-file', path.join(out, 'engine.log'), ...(check ? ['--check-only'] : []), '--script', 'res://' + script, ...(args.length ? ['--', ...args] : [])], label);
}
const changedGD = ['campaign/campaign.gd', 'main/main.gd', 'main/title.gd', 'rules/battle_api.gd', 'rules/rules.gd',
  'scenes/battle/battle.gd', 'scenes/battle/play_log.gd', 'ui/battle/hud.gd', 'ui/campaign/campaign_ui.gd', 'ui/campaign/campaign_tips.gd',
  'campaign/test/onboarding_test.gd', 'campaign/test/onboarding_visual.gd'];
for (const file of changedGD) gd(file, [], 'parse_' + file, true);
console.log('PASS: headless parse of all changed GDScript files');
for (const f of ['battle.js', 'campaign3d.js', 'ui3d.js', 'contrib/opus/tools/playlog_report.js', 'tools/test_onboarding.js']) run(process.execPath, ['--check', f], 'syntax_' + f);
const cards = JSON.parse(fs.readFileSync(path.join(__dirname, 'onboarding_cards.json')));
const ui = fs.readFileSync(path.join(root, 'ui3d.js'), 'utf8');
assert.deepEqual(JSON.parse(/const TIPS=(\[[\s\S]*?\n\]);/.exec(ui)[1]), cards);
for (const [file, name, expected] of [['godot/scenes/battle/battle.gd', 'TIPS', cards.slice(0, 9)], ['godot/ui/campaign/campaign_tips.gd', 'CARDS', cards.slice(9)]]) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  const block = new RegExp('const ' + name + ' := (\\[[\\s\\S]*?\\n\\])').exec(source)[1];
  assert.deepEqual(JSON.parse(block.replace(/,\s*\]/g, ']')), expected);
}
for (const file of ['core.js', 'battle.js', 'campaign3d.js', 'ui3d.js']) assert.equal(fs.readFileSync(path.join(root, file), 'utf8'), fs.readFileSync(path.join(root, 'godot/campaign/test/oracle', file), 'utf8'));
assert.equal(fs.readFileSync(path.join(root, 'battle.js'), 'utf8'), fs.readFileSync(path.join(root, 'godot/rules/test/oracle/battle.js'), 'utf8'));
console.log('PASS: exact approved browser copy and oracle copies');
assert.ok(gd('campaign/test/onboarding_test.gd', [], 'onboarding').includes('ONBOARDING PASS'));
console.log('PASS: focused onboarding checks');
node('contrib/opus/tools/playlog_report.test.js');
console.log('PASS: playlog reporter, including card counts and older logs');
node('godot/campaign/test/node/export_campaign.js', [path.join(out, 'campaign_tables_check.json')]);
assert.equal(JSON.parse(fs.readFileSync(path.join(out, 'campaign_tables_check.json'))).sha256, JSON.parse(fs.readFileSync(path.join(root, 'godot/campaign/data/campaign_tables.json'))).sha256);
node('godot/rules/test/node/export_data.js', [path.join(out, 'rules_tables_check.json')]);
assert.equal(JSON.parse(fs.readFileSync(path.join(out, 'rules_tables_check.json'))).sha256, JSON.parse(fs.readFileSync(path.join(root, 'godot/rules/data/tables.json'))).sha256);
if (process.argv.includes('--quick')) { console.log('ONBOARDING QUICK CHECKS PASS'); process.exit(0); }
for (const seed of [1001, 7, 4242424242]) {
  const a = path.join(out, `prng_${seed}_js.txt`), b = path.join(out, `prng_${seed}_gd.txt`);
  node('godot/rules/test/node/golden.js', ['prng', String(seed), '10000', a]);
  gd('rules/test/parity_main.gd', ['prng', String(seed), '10000', b]);
  node('godot/rules/test/node/compare.js', ['same', a, b]);
}
const math = path.join(out, 'math.txt');
node('godot/rules/test/node/golden.js', ['math', math]);
gd('rules/test/parity_main.gd', ['math', math]);
console.log('PASS: PRNG and math parity');
const scenarios = require('../godot/rules/test/scenarios.json');
for (const id of Object.keys(scenarios)) {
  const a = path.join(out, `${id}_js.jsonl`), b = path.join(out, `${id}_gd.jsonl`);
  node('godot/rules/test/node/golden.js', ['scenario', id, a]);
  gd('rules/test/parity_main.gd', ['scenario', id, b]);
  const cmp = node('godot/rules/test/node/compare.js', ['scenario', a, b]);
  if (id === 's49' || id === 's50') {
    const records = fs.readFileSync(a, 'utf8').trim().split('\n').map(JSON.parse), start = JSON.parse(records[0].state).b;
    if (id === 's49') {
      assert.equal(start.shape, 'open'); assert.equal(start.event, undefined);
      // The existing spawn safety pass may trim the cluster; it must leave one small edge feature.
      const cells = Object.keys(start.terrain);
      assert.ok(cells.length >= 1 && cells.length <= 3);
      for (const key of cells) {
        const [q, r] = key.split(',').map(Number);
        assert.ok(cells.length === 1 || cells.some(other => { const [oq, or] = other.split(',').map(Number); return other !== key && Math.max(Math.abs(q-oq),Math.abs(r-or),Math.abs(q+r-oq-or)) === 1; }));
      }
      const rows = Object.keys(start.terrain).map(k => Number(k.split(',')[1])); assert.ok(Math.max(...rows) <= 6);
    } else {
      const ready = records.map(r => JSON.parse(r.state).b).find(b => b.event);
      assert.equal(ready.event.k, 'reinf_enemy'); assert.ok([3, 4].includes(ready.event.r));
      assert.ok(records.some(r => JSON.parse(r.state).units.some(u => u.reinf)), 'second-fight reinforcement must actually arrive');
    }
  }
  console.log('Rules ' + id + ': ' + cmp.trim());
}
for (const id of ['s4', 's19', 's23']) {
  const a = path.join(out, `threat_${id}_js.json`), b = path.join(out, `threat_${id}_gd.json`);
  node('godot/rules/test/node/golden.js', ['threat', id, a]);
  gd('rules/test/parity_main.gd', ['threat', id, b]); assert.equal(fs.readFileSync(a, 'utf8'), fs.readFileSync(b, 'utf8'));
}
gd('rules/test/thread_test.gd', ['s4', 's23']);
console.log(`RULES PARITY PASS: ${Object.keys(scenarios).length} battles, PRNG, math, threat and thread checks`);
const seeds = Array.from({ length: 30 }, (_, i) => String(i + 1));
for (const seed of seeds) node('godot/campaign/test/node/golden_campaign.js', [seed, path.join(out, `c${seed}_js.jsonl`)]);
gd('campaign/test/parity_campaign.gd', [out, ...seeds], 'campaign_30_runs');
for (const seed of seeds) console.log('Campaign ' + seed + ': ' + node('godot/campaign/test/node/compare_campaign.js', [path.join(out, `c${seed}_js.jsonl`), path.join(out, `c${seed}.jsonl`)]).trim());
console.log('CAMPAIGN PARITY PASS: 30 seeded runs');
fs.writeFileSync(path.join(out, 'PASS.txt'), 'Onboarding checks PASS\nHeadless parse: all changed .gd\nRules parity: 50 scenarios plus PRNG, math, threats and threads\nCampaign parity: 30 seeded runs\nFocused onboarding and playlog reporter: PASS\n');
