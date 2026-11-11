'use strict';
// Issue 374: one cross-twin check of the save hand-off.
//
// The twins cannot read each other's save files by design. The Godot save is a fresh format
// ("voidsworn-godot-campaign", godot/campaign/campaign.gd) and the browser save is the {meta, run} pair in
// localStorage (core.js). R33 rules that browser saves are not carried over. This check says that in one line,
// then tests the hand-off the campaign parity harness really uses: the same fixed seed is played by each twin's
// own functions (lineagePick, newRun, saveRun and the real save text in Godot; the same calls in the JS game),
// and the first fixed number of step records, including the saved run and profile copy, are compared record by
// record by compare_campaign.js.
//
//   node cross_twin_handoff_test.js <godot_exe> [seed] [steps]
//
// Scratch files live in the system temp folder and are removed before it exits. No repo file is written.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const HERE = __dirname;
const ROOT = path.resolve(HERE, '..', '..', '..', '..');
const GODOT = process.argv[2] || process.env.GODOT || 'godot';
const SEED = process.argv[3] != null ? +process.argv[3] : 1;
const STEPS = process.argv[4] != null ? +process.argv[4] : 40;

function tail(s) {
  return String(s || '').split(/\r?\n/).map(l => l.trim()).filter(Boolean).slice(-4).join(' | ');
}
function run(cmd, args) {
  return spawnSync(cmd, args, { cwd: ROOT, encoding: 'utf8', windowsHide: true, maxBuffer: 1 << 26 });
}
function fail(msg) {
  console.log('FAIL: ' + msg);
  return 1;
}
function readRecords(file) {
  return fs.readFileSync(file, 'utf8').trim().split('\n').filter(Boolean).map(l => JSON.parse(l));
}

function main() {
  // The one-line finding, rooted in the two save formats the twins actually write.
  const campaign = fs.readFileSync(path.join(ROOT, 'godot', 'campaign', 'campaign.gd'), 'utf8');
  const core = fs.readFileSync(path.join(ROOT, 'core.js'), 'utf8');
  if (!/"format":\s*"voidsworn-godot-campaign"/.test(campaign)) return fail('the Godot save format line was not found in godot/campaign/campaign.gd');
  if (!/JSON\.stringify\(\{meta:\s*META,\s*run:\s*SAVED_RUN\}\)/.test(core)) return fail('the browser save shape was not found in core.js');
  console.log('NOTE: the twins cannot read each other\'s save files by design: Godot writes the "voidsworn-godot-campaign" format and the browser writes the {meta, run} pair, and R33 rules that browser saves are not carried over. This check tests the hand-off the parity harness really uses: the same fixed seed played by each twin\'s own functions, one record per step.');

  const work = fs.mkdtempSync(path.join(os.tmpdir(), 'vs_cross_twin_'));
  try {
    const jsFile = path.join(work, 'js.jsonl');
    const js = run(process.execPath, [path.join(HERE, 'golden_campaign.js'), String(SEED), jsFile]);
    if (js.status !== 0) return fail('the JS twin did not finish seed ' + SEED + ': ' + tail(js.stdout + js.stderr));

    const godotDir = path.join(work, 'godot');
    fs.mkdirSync(godotDir, { recursive: true });
    const gd = run(GODOT, ['--headless', '--path', path.join(ROOT, 'godot'), '--script', 'res://campaign/test/parity_campaign.gd', '--', godotDir, String(SEED)]);
    if (gd.error) return fail('could not start Godot (' + GODOT + '): ' + gd.error.message);
    if (gd.status !== 0) return fail('the Godot twin did not finish seed ' + SEED + ': ' + tail(gd.stdout + gd.stderr));
    const godotFile = path.join(godotDir, 'c' + SEED + '.jsonl');
    if (!fs.existsSync(godotFile)) return fail('the Godot twin wrote no record file for seed ' + SEED);

    const jsCut = readRecords(jsFile).slice(0, STEPS);
    const gCut = readRecords(godotFile).slice(0, STEPS);
    if (!jsCut.length || !gCut.length) return fail('no step records to compare');
    let savedSteps = 0;
    for (const r of jsCut) if (r.saved !== undefined && r.saved !== 'null') savedSteps += 1;
    if (!savedSteps) return fail('the fixed window never carries the JS twin\'s saved run and profile copy');

    const jsCutFile = path.join(work, 'js_prefix.jsonl');
    const gCutFile = path.join(work, 'godot_prefix.jsonl');
    const dump = (file, recs) => fs.writeFileSync(file, recs.map(r => JSON.stringify(r)).join('\n') + '\n');
    dump(jsCutFile, jsCut);
    dump(gCutFile, gCut);
    const cmp = run(process.execPath, [path.join(HERE, 'compare_campaign.js'), jsCutFile, gCutFile]);
    if (cmp.status !== 0) return fail('the twins differ inside the fixed window: ' + tail(cmp.stdout + cmp.stderr));

    console.log('PASS: seed ' + SEED + ', first ' + jsCut.length + ' steps identical in both twins, including the saved run and profile copy (' + savedSteps + ' step(s) carry a saved run); ' + tail(cmp.stdout));
    return 0;
  } finally {
    fs.rmSync(work, { recursive: true, force: true });
  }
}

process.exitCode = main();
