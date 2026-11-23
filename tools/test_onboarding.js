'use strict';
// Focused onboarding checks plus the saved Godot rules and 30-run campaign suites.
// Logs, rules records and the isolated test profile go to temp.
const fs = require('node:fs'), os = require('node:os'), path = require('node:path'), assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const godot = process.argv[2];
if (!godot || !fs.existsSync(godot)) throw new Error('Pass the path to the Godot console executable.');
if (Number(process.versions.node.split('.')[0]) !== 22) throw new Error('Use the bundled Node 22 (voidsworn_test/node/node.exe).');
const out = fs.mkdtempSync(path.join(os.tmpdir(), 'voidsworn-onboarding-'));
const user = path.join(out, 'profile');
fs.mkdirSync(user);
const parityOut = path.join(out, 'rules');
const env = { ...process.env, APPDATA: user, XDG_DATA_HOME: user, GODOT: path.resolve(godot),
  RUNNER_TEMP: out, PARITY_RUN_ROOT: parityOut };
env.NODE_OPTIONS = ((env.NODE_OPTIONS || '') + ' --preserve-symlinks --preserve-symlinks-main').trim();
delete env.RULES_TWIN;
delete env.SAVED_CAMPAIGN_SELFTEST;
let serial = 0;
function run(exe, args, label, timeout = 240000) {
  const r = spawnSync(exe, args, { cwd: root, env, encoding: 'utf8', timeout, maxBuffer: 32 * 1024 * 1024, windowsHide: true });
  const text = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(path.join(out, `${++serial}_${label.replace(/[^a-z0-9]/gi, '_')}.log`), text);
  if (r.error || r.status !== 0 || /SCRIPT ERROR|Parse Error|FAIL(?!ED to read the root certificate store)/.test(text)) {
    console.error(text.slice(-8000)); throw r.error || new Error(label + ' failed with exit ' + r.status);
  }
  return text;
}
function node(file, args = [], timeout) { return run(process.execPath, [file, ...args], path.basename(file), timeout); }
function gd(script, args = [], label = path.basename(script), check = false) {
  return run(godot, ['--headless', '--path', 'godot', '--log-file', path.join(out, 'engine.log'), ...(check ? ['--check-only'] : []), '--script', 'res://' + script, ...(args.length ? ['--', ...args] : [])], label);
}
const changedGD = ['campaign/campaign.gd', 'main/main.gd', 'main/title.gd', 'rules/battle_api.gd', 'rules/rules.gd',
  'main/campaign_host.gd', 'audio/sfx.gd', 'fx/fx.gd', 'fx/fx_death.gd', 'world/world_living.gd',
  'audio/test/smoke_lifetime_check.gd',
  'scenes/battle/battle.gd', 'scenes/battle/play_log.gd', 'ui/battle/hud.gd', 'ui/campaign/campaign_ui.gd', 'ui/campaign/campaign_tips.gd',
  'campaign/test/onboarding_test.gd', 'campaign/test/onboarding_visual.gd'];
for (const file of changedGD) gd(file, [], 'parse_' + file, true);
console.log('PASS: headless parse of all changed GDScript files');
for (const f of ['contrib/opus/tools/playlog_report.js', 'tools/test_onboarding.js']) run(process.execPath, ['--check', f], 'syntax_' + f);
const cards = JSON.parse(fs.readFileSync(path.join(__dirname, 'onboarding_cards.json')));
// The manifest mirrors the shipped Godot cards. The frozen browser keeps its own screen copy.
for (const [file, name, expected] of [['godot/scenes/battle/battle.gd', 'TIPS', cards.slice(0, 9)], ['godot/ui/campaign/campaign_tips.gd', 'CARDS', cards.slice(9)]]) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  const block = new RegExp('const ' + name + ' := (\\[[\\s\\S]*?\\n\\])').exec(source)[1];
  assert.deepEqual(JSON.parse(block.replace(/,\s*\]/g, ']')), expected);
}
assert.ok(gd('campaign/test/onboarding_test.gd', [user], 'onboarding').includes('ONBOARDING PASS'));
console.log('PASS: focused onboarding checks');
assert.ok(gd('audio/test/smoke_lifetime_check.gd', [], 'smoke_lifetime').includes('SMOKE LIFETIME PASS: 0'));
console.log('PASS: cancelled callback lifetimes');
node('contrib/opus/tools/playlog_report.test.js');
console.log('PASS: playlog reporter, including card counts and older logs');
assert.match(gd('rules/tools/reseal_tables.gd', ['check']), /^PASS: reseal tables\s*$/m);
console.log('PASS: both Godot tables have current checksums');
if (process.argv.includes('--quick')) { console.log('ONBOARDING QUICK CHECKS PASS'); process.exit(0); }
console.log(node('godot/rules/test/node/run_parity.js', [], 30 * 60 * 1000).trim());
const { read, records } = require('../godot/rules/test/saved/records');
function states(id) {
  return records(read(path.join(parityOut, 'out', `${id}.jsonl`))).map(row => JSON.parse(row.state));
}

const first = states('s49');
const start = first[0].b;
assert.equal(start.shape, 'open');
assert.ok(first.every(state => !state.b.event), 'first teaching fight suppresses arrivals');
// The spawn safety pass may trim the cluster. It must leave one small edge feature.
const cells = Object.keys(start.terrain).map(key => key.split(',').map(Number));
assert.ok(cells.length >= 1 && cells.length <= 3);
for (const [q, r] of cells) {
  assert.ok(r <= 6);
  assert.ok(cells.length === 1 || cells.some(([oq, or]) => Math.max(Math.abs(q-oq), Math.abs(r-or), Math.abs(q+r-oq-or)) === 1));
}
const second = states('s50');
const event = second.find(state => state.b.event)?.b.event;
assert.equal(event?.k, 'reinf_enemy');
assert.ok([3, 4].includes(event.r));
assert.ok(second.some(state => state.units.some(unit => unit.reinf)), 'second-fight reinforcement must actually arrive');
console.log('PASS: teaching battle edge feature and reinforcement');

console.log(node('godot/campaign/test/node/saved_campaign.js', ['check', '1', '30'], 30 * 60 * 1000).trim());
fs.writeFileSync(path.join(out, 'PASS.txt'), 'Onboarding checks PASS\nGodot rules and 30 campaign runs matched the saved results\n');
