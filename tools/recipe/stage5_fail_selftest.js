'use strict';
// Issue 873: prove that stage 5 (5_paint_bake.bat) and the issue 207 scene gate (bench207_scene_gate.bat) stop with a
// FAILED line and a non-zero exit when a step fails. The Windows fault matrix uses fake Blender, fake Blender python,
// fake Godot and fake nvidia-smi executables in TEMP, so it needs no GPU, no Blender install and no network.
// The fake Blender and Godot are tiny C# console programs compiled once at the start with Add-Type.
// Every fixture (saves, logs, cloned repo) stays in the system TEMP folder, never in this checkout.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFile, spawnSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../..');
const COMSPEC = process.env.COMSPEC || 'cmd.exe';
let passed = 0;
function pass(s) { passed++; console.log('PASS ' + s); }
function check(ok, what) { if (!ok) throw new Error(what); }
function read(p) { return fs.readFileSync(p, 'utf8'); }
function write(p, s) { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, s); }

// Static half: runs on every host, so GitHub has a row even where cmd.exe is absent.
const stage5 = read(path.join(ROOT, 'tools/recipe/5_paint_bake.bat'));
check(stage5.includes('log_render.txt') && stage5.includes('log_render_concept.txt') && stage5.includes('log_render_far.txt'),
  '5_paint_bake.bat must keep one render log per pass');
check((stage5.match(/RENDER DONE/g) || []).length >= 3, '5_paint_bake.bat must check RENDER DONE on every render pass');
check(stage5.includes('render pass 1') && stage5.includes('render pass 2') && stage5.includes('render pass 3'),
  '5_paint_bake.bat FAILED lines must name each render pass');
check(stage5.includes('exit /b 1'), '5_paint_bake.bat must exit non-zero on a failed step');
const bench = read(path.join(ROOT, 'tools/pc/jobs/bench207_scene_gate.bat'));
check(bench.includes('bench207_settings.txt'), 'bench207_scene_gate.bat must read its hi and env folders from settings');
check(bench.includes('FAILED: %FAILMSG%') && bench.includes(':fail') && bench.includes('exit /b 1'),
  'bench207_scene_gate.bat must print FAILED and exit non-zero on a failed step');
check(bench.includes('import failed') && bench.includes('build_assets pass 1 failed') && bench.includes('bench run1 failed'),
  'bench207_scene_gate.bat FAILED lines must name import, build_assets and bench runs');
pass('stage 5 and bench 207 scripts carry the issue 873 failure checks');

// Issue 1015: a lane checkout is two levels below the bundle. All three launchers must walk to the drive root.
function bundleLoop(name) {
  const script = read(path.join(ROOT, 'tools/pc', name)).replace(/\r\n/g, '\n');
  const loop = script.match(/^:bundle\n([\s\S]*?)^:bundle_done$/m);
  check(loop && /^set "SEARCH=%NEXT%"\ngoto :bundle$/m.test(loop[1]), name + ' must search successive parent folders');
  return loop[1];
}
const parityLoop = bundleLoop('parity.bat');
for (const name of ['parity_campaign.bat', 'parity_sweep.bat', 'audio_checks.bat']) {
  check(bundleLoop(name) === parityLoop, name + ' must use the parity.bat search for Node and godot_path.txt');
}
pass('campaign parity, sweep and audio launchers search parent folders for the PC bundle');

if (process.platform !== 'win32') {
  console.log('SKIP Windows fault matrix: run tools/recipe/stage5_fail_selftest.bat on the PC');
  console.log('PASS stage5_fail_selftest: static contract only on this host');
  process.exit(0);
}

const fakeSource = `
using System;
using System.IO;
using System.Linq;

public static class Fake873 {
  static string State() {
    string s = Environment.GetEnvironmentVariable("FAKE_STATE");
    if (String.IsNullOrEmpty(s)) s = Path.GetTempPath();
    Directory.CreateDirectory(s);
    return s;
  }
  static string Env(string name, string dflt) {
    string v = Environment.GetEnvironmentVariable(name);
    return String.IsNullOrEmpty(v) ? dflt : v;
  }
  static int Count(string key) {
    string p = Path.Combine(State(), key + ".txt");
    int n = 0;
    try { if (File.Exists(p)) n = Int32.Parse(File.ReadAllText(p).Trim()); } catch { }
    n++;
    File.WriteAllText(p, n.ToString());
    return n;
  }
  static int FailCode() {
    int n;
    return Int32.TryParse(Environment.GetEnvironmentVariable("FAKE_FAIL_CODE"), out n) ? n : 5;
  }
  static string Arg(string[] a, string flag) {
    int i = Array.FindIndex(a, x => x == flag);
    return i >= 0 && i + 1 < a.Length ? a[i + 1] : "";
  }
  public static int Main(string[] a) {
    string self = Path.GetFileNameWithoutExtension(System.Reflection.Assembly.GetExecutingAssembly().Location).ToLowerInvariant();
    try {
      if (self == "python") return Python(a);
      if (self == "blender") return Blender(a);
      if (self == "nvidia-smi") {
        Console.WriteLine("NVIDIA GeForce RTX 5080, 600.00, 0 %, 210 MHz, 10000 MHz, 40, 100.00, P0, 1024 MiB");
        return 0;
      }
      return Godot(a);
    } catch (Exception e) {
      Console.Error.WriteLine("fake " + self + " error: " + e.Message);
      return 9;
    }
  }
  static int Python(string[] a) {
    if (a.Length >= 1 && a[0] == "-c") { Console.WriteLine("ok"); return 0; }
    string script = a.FirstOrDefault(x => x.EndsWith(".py", StringComparison.OrdinalIgnoreCase)) ?? "";
    string name = Path.GetFileName(script).ToLowerInvariant();
    if (name == "ship.py") {
      int i = Array.FindIndex(a, x => x == "get");
      string key = i >= 0 && i + 1 < a.Length ? a[i + 1].ToLowerInvariant() : "";
      string val = "";
      if (key == "hull") val = Env("FAKE_SHIP_HULL", "armA7");
      else if (key == "cell") val = Env("FAKE_SHIP_CELL", "C873");
      else if (key == "game_code") val = Env("FAKE_SHIP_CODE", "C873G");
      else if (key == "bake") val = Env("FAKE_SHIP_BAKE", "bakeAb6.py");
      else if (key == "faction") val = Env("FAKE_SHIP_FACTION", "testfaction");
      else if (key == "sheet") val = Environment.GetEnvironmentVariable("FAKE_SHIP_SHEET") ?? "";
      else if (key == "length_world") val = Env("FAKE_SHIP_LENGTH", "400");
      else if (key == "concept_camera") val = Environment.GetEnvironmentVariable("FAKE_CAMERA") ?? "";
      if (!String.IsNullOrEmpty(val)) Console.WriteLine(val);
      return 0;
    }
    if (name == "blink.py") { Console.WriteLine("fake blink ok"); return 0; }
    if (name == "standing.py") { Console.WriteLine("PASS standing " + (a.Length > 1 ? a[1] : "")); return 0; }
    Console.WriteLine("fake python ok");
    return 0;
  }
  static int Blender(string[] a) {
    int pi = Array.FindIndex(a, x => x == "-P");
    string script = pi >= 0 && pi + 1 < a.Length ? a[pi + 1] : "";
    if (String.IsNullOrEmpty(script) || !File.Exists(script)) {
      Console.Error.WriteLine("fake blender: cannot find Blender script: " + script);
      return 2;
    }
    string name = Path.GetFileName(script).ToLowerInvariant();
    if (name.Contains("bake")) {
      if (Env("FAKE_BAKE_FAIL", "") == "1") { Console.Error.WriteLine("fake blender: bake failed"); return FailCode(); }
      Console.WriteLine("[209] " + Env("FAKE_SHIP_CELL", "C873") + " {");
      Console.WriteLine(Env("FAKE_BAKE_MESSAGE", ""));
      return 0;
    }
    if (name == "detail_check.py") {
      // issue 1739: the surface-detail check (issues 1291, 1517) that stage 5 runs for every paint-stack ship
      if (Env("FAKE_DETAIL_FAIL", "") == "1") { Console.WriteLine("FAIL detail check: flat clay surface (fake)"); return FailCode(); }
      Console.WriteLine("PASS detail check");
      return 0;
    }
    if (name == "surface_check.py") {
      Console.WriteLine("PASS surface check");
      if (Env("FAKE_SURFACE_FAIL", "") == "1") return FailCode();
      return 0;
    }
    if (name == "render.py") {
      int n = Count("render");
      if (n == 1 && Env("FAKE_SHEET_VIEWS", "") == "1" && !a.Contains("--views=concept,hero,side,top,below,battle")) {
        Console.Error.WriteLine("fake blender: sheet paint views missing");
        return 8;
      }
      if ((Environment.GetEnvironmentVariable("FAKE_RENDER_FAIL") ?? "") == n.ToString()) {
        Console.Error.WriteLine("fake blender: render pass " + n + " failed");
        return FailCode();
      }
      if ((Environment.GetEnvironmentVariable("FAKE_RENDER_NO_DONE") ?? "") == n.ToString()) return 0;
      Console.WriteLine("RENDER DONE");
      return 0;
    }
    if (name == "close6.py") {
      if (Env("FAKE_CLOSE_FAIL", "") == "1") { Console.Error.WriteLine("fake blender: close6 failed"); return FailCode(); }
      return 0;
    }
    return 0;
  }
  static int Godot(string[] a) {
    string step = "other";
    int counter = 0;
    if (a.Any(x => x.IndexOf("--import", StringComparison.OrdinalIgnoreCase) >= 0)) step = "import";
    else if (a.Any(x => x.IndexOf("build_assets.gd", StringComparison.OrdinalIgnoreCase) >= 0)) { step = "build"; counter = Count("build"); }
    else if (a.Any(x => x.IndexOf("scene_gate.tscn", StringComparison.OrdinalIgnoreCase) >= 0)) { step = "bench"; counter = Count("bench"); }
    string fail = Environment.GetEnvironmentVariable("FAKE_GODOT_FAIL") ?? "";
    if (fail == step || fail == step + counter) {
      Console.Error.WriteLine("fake godot: " + step + (counter > 0 ? counter.ToString() : "") + " failed");
      return FailCode();
    }
    if (step == "build") {
      if (Env("FAKE_GODOT_NO_V3", "") != "1") {
        string proj = Arg(a, "--path");
        Directory.CreateDirectory(Path.Combine(proj, "gen"));
        File.WriteAllText(Path.Combine(proj, "gen", "v3.txt"), "fake v3\\n");
      }
    }
    if (step == "bench") {
      if ((Environment.GetEnvironmentVariable("FAKE_GODOT_NO_OUT") ?? "") != "bench" + counter) {
        string outDir = Arg(a, "--out");
        Directory.CreateDirectory(outDir);
        if ((Environment.GetEnvironmentVariable("FAKE_GODOT_EMPTY_OUT") ?? "") != "bench" + counter)
          File.WriteAllText(Path.Combine(outDir, "scene_gate.json"), "{}\\n");
      }
    }
    return 0;
  }
}
`;
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'stage873 '));
const fakeExe = path.join(root, 'fake.exe');
const compile = path.join(root, 'compile.ps1');
write(compile, "$ErrorActionPreference='Stop'\r\nAdd-Type -TypeDefinition @'\r\n" + fakeSource + "\r\n'@ -OutputAssembly '" +
  fakeExe + "' -OutputType ConsoleApplication\r\nif (-not (Test-Path '" + fakeExe + "')) { exit 9 }\r\n");
const built = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', compile], {
  cwd: root, encoding: 'utf8', windowsHide: true,
  env: { ...process.env, LOCALAPPDATA: path.join(root, 'appdata-local'), APPDATA: path.join(root, 'appdata-roaming'), TEMP: path.join(root, 'temp'), TMP: path.join(root, 'temp') }
});
if (built.status !== 0) throw new Error('fake executable compile failed: ' + (built.stdout || '') + (built.stderr || ''));
function fakeCopy(dest) { fs.mkdirSync(path.dirname(dest), { recursive: true }); fs.copyFileSync(fakeExe, dest); }
console.log('Evidence: ' + root);

// Run the unchanged job scripts with a fixture-only watchdog. The fakes have no delays or child processes. Starting
// PowerShell and checking GPU slots for each fake call was most of the matrix's runtime. runner_selftest covers the
// real watchdog. Here the shim passes the arguments and exit code through, and only allows the expected fake exe.
const fixtureRepo = path.join(root, 'scripts');
for (const file of ['tools/recipe/5_paint_bake.bat', 'tools/recipe/env.bat', 'tools/pc/jobs/bench207_scene_gate.bat',
  'tools/blender/r209/bakeAb6.py', 'tools/blender/r209/bake_sheet.py', 'tools/blender/r209/render.py',
  'tools/blender/r209/close6.py', 'tools/recipe/surface_check.py']) {
  const dest = path.join(fixtureRepo, file);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(path.join(ROOT, file), dest);
}
write(path.join(fixtureRepo, 'tools/pc/tmo.bat'), [
  '@echo off',
  'setlocal enableextensions disabledelayedexpansion',
  'if not defined FAKE_TMO_EXE exit /b 99',
  'if /i not "%~2"=="%FAKE_TMO_EXE%" exit /b 99',
  'set "command=%*"',
  '%command:* =%',
  'exit /b %ERRORLEVEL%',
  ''
].join('\r\n'));

function run(exe, args, options) {
  return new Promise((resolve, reject) => {
    execFile(exe, args, { cwd: root, encoding: 'utf8', windowsHide: true, ...options }, (error, stdout, stderr) => {
      if (error && typeof error.code !== 'number') reject(error);
      else resolve({ code: error ? error.code : 0, text: stdout + stderr });
    });
  });
}
function runBat(bat, env) {
  return run(COMSPEC, ['/d', '/s', '/c', '""' + bat + '""'], {
    env, timeout: 180000, windowsVerbatimArguments: true
  });
}
function expectFail(label, r, lines) {
  check(r.code !== 0, label + ': expected a non-zero exit, got 0. Output: ' + r.text);
  for (const line of lines) check(r.text.includes(line), label + ': output is missing "' + line + '". Output: ' + r.text);
  pass(label);
}

// ---- Stage 5 fault matrix ----
function stage5Home(label) {
  const home = path.join(root, 's5-' + label);
  const vt = path.join(home, 'Downloads', 'voidsworn_test');
  const blender = path.join(vt, 'blender', 'blender-4.5.14-windows-x64');
  fakeCopy(path.join(blender, 'blender.exe'));
  fakeCopy(path.join(blender, '4.5', 'python', 'bin', 'python.exe'));
  const ship = 'T873' + label.replace(/[^a-z0-9]/gi, '');
  write(path.join(vt, 'bakeoff', ship + '_trellis.glb'), 'glb');
  fs.mkdirSync(path.join(vt, 'recipe', ship, 'build'), { recursive: true });
  const state = path.join(root, 'state-s5-' + label);
  fs.mkdirSync(state, { recursive: true });
  const env = {
    ...process.env, USERPROFILE: home, SHIP: ship, RECIPE_NOPAUSE: '1',
    LOCALAPPDATA: path.join(home, 'AppData', 'Local'), APPDATA: path.join(home, 'AppData', 'Roaming'),
    TEMP: path.join(home, 'Temp'), TMP: path.join(home, 'Temp'),
    FAKE_TMO_EXE: path.join(blender, 'blender.exe'), FAKE_STATE: state,
    FAKE_SHIP_HULL: 'armA7', FAKE_SHIP_CELL: 'C873', FAKE_SHIP_CODE: 'C873G', FAKE_SHIP_BAKE: 'bakeAb6.py'
  };
  return { vt, ship, env, job: path.join(vt, 'recipe', ship) };
}
const stage5Bat = path.join(fixtureRepo, 'tools/recipe/5_paint_bake.bat');
const cases = [];
function stage5Case(label, overrides, verify) {
  cases.push(async () => {
    const { env, job } = stage5Home(label);
    verify(await runBat(stage5Bat, { ...env, ...overrides }), job);
  });
}
stage5Case('ok', {}, (r, job) => {
  check(r.code === 0, 'stage 5 success case exited ' + r.code + '. Output: ' + r.text);
  for (const log of ['log_render.txt', 'log_render_concept.txt', 'log_render_far.txt']) {
    check(read(path.join(job, log)).includes('RENDER DONE'), 'stage 5 success case: ' + log + ' has no RENDER DONE');
  }
  check(r.text.includes('Stage 5 done'), 'stage 5 success case did not reach the done line. Output: ' + r.text);
  pass('stage 5 success case: all three render passes finish and the stage exits 0');
});

stage5Case('missingscript', { FAKE_SHIP_BAKE: 'missing_bake.py' }, r =>
  expectFail('stage 5 missing Blender script stops the stage', r, ['Stage 5 FAILED: the bake (missing_bake.py) exited code 2']));
stage5Case('renderfail', { FAKE_RENDER_FAIL: '2', FAKE_FAIL_CODE: '3' }, r =>
  expectFail('stage 5 render pass 2 exit code stops the stage', r, ['Stage 5 FAILED: render pass 2 (concept light) exited code 3']));
stage5Case('renderfail3', { FAKE_RENDER_FAIL: '3', FAKE_FAIL_CODE: '4' }, r =>
  expectFail('stage 5 render pass 3 exit code stops the stage', r, ['Stage 5 FAILED: render pass 3 (far side) exited code 4']));
stage5Case('norender', { FAKE_RENDER_NO_DONE: '2' }, r =>
  expectFail('stage 5 render pass 2 missing output stops the stage', r, ['Stage 5 FAILED: render pass 2 (concept light) wrote no RENDER DONE']));
stage5Case('bakefail', { FAKE_BAKE_FAIL: '1', FAKE_FAIL_CODE: '6' }, r =>
  expectFail('stage 5 bake exit code stops the stage', r, ['Stage 5 FAILED: the bake (bakeAb6.py) exited code 6']));

for (const message of ['out of SVM stack space', 'failed to compile', 'shader compilation failed',
  'shader compilation error', 'shader compile error', 'error compiling']) {
  stage5Case('compile-' + message, { FAKE_BAKE_MESSAGE: message.toUpperCase() }, r =>
    expectFail('stage 5 rejects zero-exit compile error: ' + message, r,
      ['Stage 5 FAILED: Cycles could not compile a bake shader']));
}
for (const step of ['bake', 'render', 'surface', 'close']) {
  const overrides = { FAKE_FAIL_CODE: '-1073741819', ['FAKE_' + step.toUpperCase() + '_FAIL']: '1' };
  if (step === 'surface') overrides.FAKE_SHIP_BAKE = 'bake_sheet.py';
  stage5Case('negative-' + step, overrides, r =>
    expectFail('stage 5 rejects negative ' + step + ' exit', r, ['Stage 5 FAILED:', 'exited code -1073741819']));
}
stage5Case('surfacefail', { FAKE_SHIP_BAKE: 'bake_sheet.py', FAKE_SURFACE_FAIL: '1', FAKE_FAIL_CODE: '7' }, r =>
  expectFail('stage 5 surface exit fails even with a PASS marker', r, ['Stage 5 FAILED: the surface check exited code 7']));
stage5Case('detailfail', { FAKE_SHIP_BAKE: 'bake_sheet.py', FAKE_DETAIL_FAIL: '1', FAKE_FAIL_CODE: '5' }, r =>
  expectFail('stage 5 stops a ship under its surface-detail floor', r, ['Stage 5 FAILED: the surface-detail check failed']));
stage5Case('sheetviews', { FAKE_SHIP_BAKE: 'bake_sheet.py', FAKE_SHIP_SHEET: 'corsair_A17', FAKE_SHEET_VIEWS: '1' }, r => {
  check(r.code === 0 && r.text.includes('Stage 5 done'), 'sheet paint views failed: ' + r.text);
  pass('stage 5 sheet ships select the paint views and finish all three passes');
});

// Exercise the exact log reader used by the issue 726 helper, without entering its GPU route.
const helperSource = read(path.join(ROOT, 'tools/pc/jobs/hb_paint_726.ps1'));
check(helperSource.includes(". (Join-Path $PSScriptRoot 'hb_paint_726_logs.ps1')") &&
  helperSource.includes('Assert-Hb726Stage5Logs -Job $job -Cell $cell'), 'issue 726 helper must use the tested log reader');
const helperFixture = path.join(root, 'helper-logs.ps1');
const helperModule = path.join(ROOT, 'tools/pc/jobs/hb_paint_726_logs.ps1').replace(/'/g, "''");
write(helperFixture, "param([string]$Job)\r\n$ErrorActionPreference='Stop'\r\n. '" + helperModule +
  "'\r\ntry { Assert-Hb726Stage5Logs -Job $Job -Cell 'A20'; Write-Output 'PASS helper logs' } catch { Write-Output $_.Exception.Message; exit 1 }\r\n");
const renderLogs = ['log_render.txt', 'log_render_concept.txt', 'log_render_far.txt'];
function helperCase(label, overrides, verify) {
  cases.push(async () => {
    const job = path.join(root, 'helper-' + label);
    const logs = { 'log_bake.txt': '[209] A20 {\n', 'log_surface.txt': 'PASS surface check\n' };
    for (const log of renderLogs) logs[log] = 'RENDER DONE\n';
    Object.assign(logs, overrides);
    for (const [log, contents] of Object.entries(logs)) if (contents !== null) write(path.join(job, log), contents);
    verify(await run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', helperFixture, '-Job', job], {
      timeout: 30000
    }));
  });
}
helperCase('good', {}, r => {
  check(r.code === 0 && r.text.includes('PASS helper logs'), 'helper rejected three good render logs: ' + r.text);
  pass('issue 726 helper accepts one completion in each of three good logs');
});
for (const log of renderLogs) {
  helperCase('missing-' + log, { [log]: null }, r =>
    expectFail('issue 726 helper rejects missing ' + log, r, ['missing render pass log ' + log]));
  helperCase('silent-' + log, { [log]: 'render started\n' }, r =>
    expectFail('issue 726 helper rejects incomplete ' + log, r, ['expected one RENDER DONE in ' + log + ', got 0']));
}
helperCase('pooled', { 'log_render.txt': 'RENDER DONE\nRENDER DONE\nRENDER DONE\n', 'log_render_concept.txt': '' }, r =>
  expectFail('issue 726 helper rejects pooled completions', r, ['expected one RENDER DONE in log_render.txt, got 3']));
helperCase('compile', { 'log_bake.txt': '[209] A20 {\nERROR: out of SVM stack space\n' }, r =>
  expectFail('issue 726 helper rejects a bake shader failure', r, ['Cycles could not compile a bake shader']));

// ---- Issue 207 scene gate fault matrix ----
function git(args, cwd, extraEnv) {
  const r = spawnSync('git', args, { cwd, encoding: 'utf8', windowsHide: true, env: { ...process.env, ...(extraEnv || {}) } });
  if (r.status !== 0) throw new Error('git ' + args.join(' ') + ' failed: ' + (r.stdout || '') + (r.stderr || ''));
  return r.stdout || '';
}
// Build the fixture commit with plumbing only. No git commit or push, and no user or global Git config is read.
const seed = path.join(root, 'seed');
write(path.join(seed, 'godot', 'bench', 'scene_gate.tscn'), '[gd_scene]\n');
git(['init', '-q'], seed);
git(['-C', seed, 'add', '.'], root);
const tree = git(['-C', seed, 'write-tree'], root).trim();
const author = { GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' };
const commit = git(['-C', seed, 'commit-tree', tree, '-m', 'fixture'], root, author).trim();
git(['-C', seed, 'update-ref', 'refs/heads/opus/issue-207', commit], root);
git(['-C', seed, 'symbolic-ref', 'HEAD', 'refs/heads/opus/issue-207'], root);
const origin = path.join(root, 'origin.git');
git(['init', '-q', '--bare', origin], root);
git(['-C', origin, 'fetch', '-q', seed, 'refs/heads/opus/issue-207:refs/heads/opus/issue-207'], root);
git(['-C', origin, 'symbolic-ref', 'HEAD', 'refs/heads/opus/issue-207'], root);

async function benchHome(label) {
  const home = path.join(root, 'b207-' + label);
  const vt = path.join(home, 'Downloads', 'voidsworn_test');
  fs.mkdirSync(vt, { recursive: true });
  const clone = await run('git', ['clone', '-q', origin, path.join(vt, 'opus207', 'repo')], { timeout: 30000 });
  check(clone.code === 0, 'git clone for ' + label + ' failed: ' + clone.text);
  const bin = path.join(vt, 'bin');
  fakeCopy(path.join(bin, 'Godot_fake.exe'));
  fakeCopy(path.join(bin, 'nvidia-smi.exe'));
  write(path.join(vt, 'godot_path.txt'), path.join(bin, 'Godot_fake.exe') + '\r\n');
  write(path.join(vt, 'build', 'godot', 'assets', 'ships', 'a4', 'ship.glb'), 'glb');
  fs.mkdirSync(path.join(vt, 'build'), { recursive: true });
  fs.mkdirSync(path.join(vt, 'queue', 'logs'), { recursive: true });
  const hi = path.join(vt, 'assets_hi');
  const envDir = path.join(vt, 'assets_env');
  write(path.join(hi, 'flagship.glb'), 'glb');
  write(path.join(envDir, 'sky_deadstar_8k.png'), 'png');
  // System32 first: a Git Bash PATH otherwise finds the Unix find.exe, which would walk all of C: on "find /c".
  const system32 = path.join(process.env.SystemRoot || 'C:\\Windows', 'System32');
  const env = {
    ...process.env, USERPROFILE: home, PATH: bin + ';' + system32 + ';' + (process.env.PATH || ''),
    LOCALAPPDATA: path.join(home, 'AppData', 'Local'), APPDATA: path.join(home, 'AppData', 'Roaming'),
    TEMP: path.join(home, 'Temp'), TMP: path.join(home, 'Temp'),
    FAKE_TMO_EXE: path.join(bin, 'Godot_fake.exe'), FAKE_STATE: path.join(root, 'state-b207-' + label)
  };
  return { home, vt, hi, envDir, env, out: path.join(vt, 'opus207', 'out') };
}
const benchBat = path.join(fixtureRepo, 'tools/pc/jobs/bench207_scene_gate.bat');
function writeBenchSettings(b, settings = 'hi=' + b.hi + '\r\nenv=' + b.envDir + '\r\n') {
  write(path.join(b.vt, 'bench207_settings.txt'), settings);
}
function benchCase(label, overrides, verify, setup = writeBenchSettings) {
  cases.push(async () => {
    const b = await benchHome(label);
    setup(b);
    verify(await runBat(benchBat, { ...b.env, ...overrides }), b);
  });
}
const benchRuns = ['run1', 'run2', 'run3_res'];
benchCase('ok', {}, (r, b) => {
  check(r.code === 0, 'bench 207 success case exited ' + r.code + '. Output: ' + r.text);
  check(!r.text.includes('FAILED:'), 'bench 207 success case printed a FAILED line. Output: ' + r.text);
  for (const run of benchRuns) {
    check(fs.existsSync(path.join(b.out, run, 'scene_gate.json')), 'bench 207 success case: ' + run + ' has no report');
  }
  pass('bench 207 success case: import, build_assets and all three bench runs finish and the job exits 0');
});

benchCase('import', { FAKE_GODOT_FAIL: 'import' }, r =>
  expectFail('bench 207 import failure stops the job', r, ['FAILED: the Godot import failed']));
benchCase('build', { FAKE_GODOT_FAIL: 'build' }, r =>
  expectFail('bench 207 build_assets failure stops the job', r, ['FAILED: build_assets pass 1 failed']));
benchCase('nov3', { FAKE_GODOT_NO_V3: '1' }, r =>
  expectFail('bench 207 build_assets missing output stops the job', r, ['FAILED: build_assets wrote no godot\\gen\\v3.txt after 3 passes']));
benchCase('bench', { FAKE_GODOT_FAIL: 'bench2' }, r =>
  expectFail('bench 207 bench run2 failure stops the job', r, ['FAILED: bench run2 failed']));
benchCase('noout', { FAKE_GODOT_NO_OUT: 'bench2' }, r =>
  expectFail('bench 207 bench run2 missing output stops the job', r, ['FAILED: bench run2 wrote no fresh scene_gate.json at']));

// Issue 952: a successful process must write this step's real report after its marker.
const oldTime = new Date('2000-01-01T00:00:00Z');
for (const [index, run] of benchRuns.entries()) {
  for (const fixture of ['empty', 'stale']) {
    const noWrite = fixture === 'empty' ? 'FAKE_GODOT_EMPTY_OUT' : 'FAKE_GODOT_NO_OUT';
    benchCase(fixture + '-' + run, { [noWrite]: 'bench' + (index + 1) }, (r, b) => {
      const failure = 'FAILED: bench ' + run + ' wrote no fresh scene_gate.json at';
      expectFail('bench 207 ' + run + ' rejects zero exit with ' + fixture + ' output', r, [failure]);
      const status = read(path.join(b.out, 'status.txt'));
      check(status.includes(failure) && !/^done /m.test(status), 'bench 207 must log the failed step and stop before done');
      check(read(path.join(b.env.FAKE_STATE, 'bench.txt')).trim() === String(index + 1),
        'bench 207 must stop before the next bench step');
      const outDir = path.join(b.out, run);
      check(fs.existsSync(outDir), 'bench 207 must keep the old output folder');
      if (fixture === 'stale') {
        const report = path.join(outDir, 'scene_gate.json');
        check(read(report) === '{"earlier_run":true}\n' && fs.statSync(report).mtimeMs === oldTime.getTime(),
          'bench 207 must leave the stale report unchanged');
      }
    }, b => {
      writeBenchSettings(b);
      const outDir = path.join(b.out, run);
      fs.mkdirSync(outDir, { recursive: true });
      if (fixture === 'stale') {
        const report = path.join(outDir, 'scene_gate.json');
        write(report, '{"earlier_run":true}\n');
        fs.utimesSync(report, oldTime, oldTime);
        // A reused marker must be refreshed too, or the stale report could still be newer.
        const marker = path.join(b.out, run + '_started.txt');
        write(marker, 'earlier marker\n');
        const olderTime = new Date('1999-01-01T00:00:00Z');
        fs.utimesSync(marker, olderTime, olderTime);
      }
    });
  }
}

// A new report replacing an earlier run's report passes in each reused folder.
benchCase('fresh-over-stale', {}, (r, b) => {
  check(r.code === 0 && !r.text.includes('FAILED:'), 'bench 207 rejected fresh reports in reused folders: ' + r.text);
  for (const run of benchRuns) {
    const report = path.join(b.out, run, 'scene_gate.json');
    const marker = path.join(b.out, run + '_started.txt');
    check(read(report) === '{}\n' && fs.statSync(report).mtimeMs > fs.statSync(marker).mtimeMs,
      'bench 207 ' + run + ' must have a fresh scene_gate.json newer than its marker');
  }
  pass('bench 207 accepts fresh scene_gate.json reports in all three reused output folders');
}, b => {
  writeBenchSettings(b);
  for (const run of benchRuns) {
    const report = path.join(b.out, run, 'scene_gate.json');
    write(report, '{"earlier_run":true}\n');
    fs.utimesSync(report, oldTime, oldTime);
  }
});

benchCase('nohi', {}, r =>
  expectFail('bench 207 missing hi setting stops the job', r, ['FAILED: no hi folder in']),
  b => writeBenchSettings(b, 'env=' + b.envDir + '\r\n'));
benchCase('noenvfolder', {}, r =>
  expectFail('bench 207 missing env folder stops the job', r, ['FAILED: the env folder does not exist:']),
  b => writeBenchSettings(b, 'hi=' + b.hi + '\r\nenv=' + path.join(b.vt, 'gone') + '\r\n'));
benchCase('nosettings', {}, r =>
  expectFail('bench 207 missing settings file stops the job', r, ['FAILED: no hi folder in']),
  () => {});

// Each case has its own home, output and counters. Limit concurrent cases so other PC lanes can keep working.
let nextCase = 0;
async function runCases() {
  while (nextCase < cases.length) {
    const runCase = cases[nextCase++];
    try {
      await runCase();
    } catch (error) {
      console.error('FAIL stage5_fail_selftest: ' + error.stack);
      process.exitCode = 1;
    }
  }
}
Promise.all(Array.from({ length: 6 }, runCases)).then(() => {
  if (!process.exitCode) console.log('PASS stage5_fail_selftest: ' + passed + ' checks, fake executables only, no GPU, no network.');
});
