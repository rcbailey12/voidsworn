'use strict';
// Issue 873: prove that stage 5 (5_paint_bake.bat) and the issue 207 scene gate (bench207_scene_gate.bat) stop with a
// FAILED line and a non-zero exit when a step fails. The Windows fault matrix uses fake Blender, fake Blender python,
// fake Godot and fake nvidia-smi executables in TEMP, so it needs no GPU, no Blender install and no network.
// The fake Blender and Godot are tiny C# console programs compiled once at the start with Add-Type.
// Every fixture (saves, logs, cloned repo) stays in the system TEMP folder, never in this checkout.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
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
        File.WriteAllText(Path.Combine(outDir, "results.txt"), "fake results\\n");
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

// Issue 916: the fake Blender and Godot are not GPU work, but tmo.bat classifies them by exe name. Run the bats from the
// TEMP fixture, not the checkout: on a code-only lane the checkout path holds a "board_c" segment and the watchdog would
// refuse (tools/pc/gpu_slots.js checks both PC_GPU_LANE and the working directory). The fixture also has a space in its
// path, which must keep working.
function runBat(bat, env) {
  const r = spawnSync(COMSPEC, ['/d', '/s', '/c', '""' + bat + '""'], {
    cwd: root, env, encoding: 'utf8', timeout: 180000, windowsHide: true, windowsVerbatimArguments: true
  });
  if (r.error) throw r.error;
  return { code: r.status, text: (r.stdout || '') + (r.stderr || '') };
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
  const gpu = path.join(root, 'gpu-s5-' + label);
  write(path.join(gpu, 'gpu_go.txt'), 'GPU cleared\r\n');
  const env = {
    ...process.env, USERPROFILE: home, SHIP: ship, RECIPE_NOPAUSE: '1', PC_GPU_ISSUE: 'self-test',
    LOCALAPPDATA: path.join(home, 'AppData', 'Local'), APPDATA: path.join(home, 'AppData', 'Roaming'),
    TEMP: path.join(home, 'Temp'), TMP: path.join(home, 'Temp'),
    PC_RUNNER_TEST: '1', PC_TEST_TIMEOUT_LOG: path.join(root, 'timeouts-s5-' + label + '.log'),
    // Issue 916: the runner exports PC_GPU_LANE=C on a code-only lane. The fakes do no GPU work, so drop the lane flag
    // here or tmo.bat refuses the bake and the success case looks like a failed bake.
    PC_GPU_LANE: '',
    PC_TEST_GPU_ROOT: gpu, FAKE_STATE: state,
    FAKE_SHIP_HULL: 'armA7', FAKE_SHIP_CELL: 'C873', FAKE_SHIP_CODE: 'C873G', FAKE_SHIP_BAKE: 'bakeAb6.py'
  };
  return { vt, ship, env, job: path.join(vt, 'recipe', ship) };
}
const stage5Bat = path.join(ROOT, 'tools/recipe/5_paint_bake.bat');
let s5 = stage5Home('ok');
let r = runBat(stage5Bat, s5.env);
check(r.code === 0, 'stage 5 success case exited ' + r.code + '. Output: ' + r.text);
for (const log of ['log_render.txt', 'log_render_concept.txt', 'log_render_far.txt']) {
  check(read(path.join(s5.job, log)).includes('RENDER DONE'), 'stage 5 success case: ' + log + ' has no RENDER DONE');
}
check(r.text.includes('Stage 5 done'), 'stage 5 success case did not reach the done line. Output: ' + r.text);
pass('stage 5 success case: all three render passes finish and the stage exits 0');

s5 = stage5Home('missingscript');
s5.env.FAKE_SHIP_BAKE = 'missing_bake.py';
r = runBat(stage5Bat, s5.env);
expectFail('stage 5 missing Blender script stops the stage', r, ['Stage 5 FAILED: the bake (missing_bake.py) exited code 2']);

s5 = stage5Home('renderfail');
s5.env.FAKE_RENDER_FAIL = '2';
s5.env.FAKE_FAIL_CODE = '3';
r = runBat(stage5Bat, s5.env);
expectFail('stage 5 render pass 2 exit code stops the stage', r, ['Stage 5 FAILED: render pass 2 (concept light) exited code 3']);

s5 = stage5Home('renderfail3');
s5.env.FAKE_RENDER_FAIL = '3';
s5.env.FAKE_FAIL_CODE = '4';
r = runBat(stage5Bat, s5.env);
expectFail('stage 5 render pass 3 exit code stops the stage', r, ['Stage 5 FAILED: render pass 3 (far side) exited code 4']);

s5 = stage5Home('norender');
s5.env.FAKE_RENDER_NO_DONE = '2';
r = runBat(stage5Bat, s5.env);
expectFail('stage 5 render pass 2 missing output stops the stage', r, ['Stage 5 FAILED: render pass 2 (concept light) wrote no RENDER DONE']);

s5 = stage5Home('bakefail');
s5.env.FAKE_BAKE_FAIL = '1';
s5.env.FAKE_FAIL_CODE = '6';
r = runBat(stage5Bat, s5.env);
expectFail('stage 5 bake exit code stops the stage', r, ['Stage 5 FAILED: the bake (bakeAb6.py) exited code 6']);

for (const message of ['out of SVM stack space', 'failed to compile', 'shader compilation failed',
  'shader compilation error', 'shader compile error', 'error compiling']) {
  s5 = stage5Home('compile-' + message);
  s5.env.FAKE_BAKE_MESSAGE = message.toUpperCase();
  r = runBat(stage5Bat, s5.env);
  expectFail('stage 5 rejects zero-exit compile error: ' + message, r,
    ['Stage 5 FAILED: Cycles could not compile a bake shader']);
}
for (const step of ['bake', 'render', 'surface', 'close']) {
  s5 = stage5Home('negative-' + step);
  s5.env.FAKE_FAIL_CODE = '-1073741819';
  if (step === 'render') s5.env.FAKE_RENDER_FAIL = '1';
  else s5.env['FAKE_' + step.toUpperCase() + '_FAIL'] = '1';
  if (step === 'surface') s5.env.FAKE_SHIP_BAKE = 'bake_sheet.py';
  r = runBat(stage5Bat, s5.env);
  expectFail('stage 5 rejects negative ' + step + ' exit', r, ['Stage 5 FAILED:', 'exited code -1073741819']);
}
s5 = stage5Home('surfacefail');
s5.env.FAKE_SHIP_BAKE = 'bake_sheet.py';
s5.env.FAKE_SURFACE_FAIL = '1';
s5.env.FAKE_FAIL_CODE = '7';
r = runBat(stage5Bat, s5.env);
expectFail('stage 5 surface exit fails even with a PASS marker', r, ['Stage 5 FAILED: the surface check exited code 7']);

s5 = stage5Home('sheetviews');
s5.env.FAKE_SHIP_BAKE = 'bake_sheet.py';
s5.env.FAKE_SHIP_SHEET = 'corsair_A17';
s5.env.FAKE_SHEET_VIEWS = '1';
r = runBat(stage5Bat, s5.env);
check(r.code === 0 && r.text.includes('Stage 5 done'), 'sheet paint views failed: ' + r.text);
pass('stage 5 sheet ships select the paint views and finish all three passes');

// Exercise the exact log reader used by the issue 726 helper, without entering its GPU route.
const helperSource = read(path.join(ROOT, 'tools/pc/jobs/hb_paint_726.ps1'));
check(helperSource.includes(". (Join-Path $PSScriptRoot 'hb_paint_726_logs.ps1')") &&
  helperSource.includes('Assert-Hb726Stage5Logs -Job $job -Cell $cell'), 'issue 726 helper must use the tested log reader');
const helperFixture = path.join(root, 'helper-logs.ps1');
const helperModule = path.join(ROOT, 'tools/pc/jobs/hb_paint_726_logs.ps1').replace(/'/g, "''");
write(helperFixture, "param([string]$Job)\r\n$ErrorActionPreference='Stop'\r\n. '" + helperModule +
  "'\r\ntry { Assert-Hb726Stage5Logs -Job $Job -Cell 'A20'; Write-Output 'PASS helper logs' } catch { Write-Output $_.Exception.Message; exit 1 }\r\n");
const renderLogs = ['log_render.txt', 'log_render_concept.txt', 'log_render_far.txt'];
function helperLogs(label, overrides = {}) {
  const job = path.join(root, 'helper-' + label);
  const logs = { 'log_bake.txt': '[209] A20 {\n', 'log_surface.txt': 'PASS surface check\n' };
  for (const log of renderLogs) logs[log] = 'RENDER DONE\n';
  Object.assign(logs, overrides);
  for (const [log, contents] of Object.entries(logs)) if (contents !== null) write(path.join(job, log), contents);
  const result = spawnSync('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', helperFixture, '-Job', job], {
    cwd: root, encoding: 'utf8', timeout: 30000, windowsHide: true
  });
  if (result.error) throw result.error;
  return { code: result.status, text: (result.stdout || '') + (result.stderr || '') };
}
r = helperLogs('good');
check(r.code === 0 && r.text.includes('PASS helper logs'), 'helper rejected three good render logs: ' + r.text);
pass('issue 726 helper accepts one completion in each of three good logs');
for (const log of renderLogs) {
  r = helperLogs('missing-' + log, { [log]: null });
  expectFail('issue 726 helper rejects missing ' + log, r, ['missing render pass log ' + log]);
  r = helperLogs('silent-' + log, { [log]: 'render started\n' });
  expectFail('issue 726 helper rejects incomplete ' + log, r, ['expected one RENDER DONE in ' + log + ', got 0']);
}
r = helperLogs('pooled', { 'log_render.txt': 'RENDER DONE\nRENDER DONE\nRENDER DONE\n', 'log_render_concept.txt': '' });
expectFail('issue 726 helper rejects pooled completions', r, ['expected one RENDER DONE in log_render.txt, got 3']);
r = helperLogs('compile', { 'log_bake.txt': '[209] A20 {\nERROR: out of SVM stack space\n' });
expectFail('issue 726 helper rejects a bake shader failure', r, ['Cycles could not compile a bake shader']);

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

function benchHome(label, settings, extra) {
  const home = path.join(root, 'b207-' + label);
  const vt = path.join(home, 'Downloads', 'voidsworn_test');
  fs.mkdirSync(vt, { recursive: true });
  git(['clone', '-q', origin, path.join(vt, 'opus207', 'repo')], root);
  const bin = path.join(vt, 'bin');
  fakeCopy(path.join(bin, 'Godot_fake.exe'));
  fakeCopy(path.join(bin, 'nvidia-smi.exe'));
  write(path.join(vt, 'godot_path.txt'), path.join(bin, 'Godot_fake.exe') + '\r\n');
  write(path.join(vt, 'bench207_settings.txt'), settings);
  write(path.join(vt, 'build', 'godot', 'assets', 'ships', 'a4', 'ship.glb'), 'glb');
  fs.mkdirSync(path.join(vt, 'build'), { recursive: true });
  fs.mkdirSync(path.join(vt, 'queue', 'logs'), { recursive: true });
  const hi = path.join(vt, 'assets_hi');
  const envDir = path.join(vt, 'assets_env');
  write(path.join(hi, 'flagship.glb'), 'glb');
  write(path.join(envDir, 'sky_deadstar_8k.png'), 'png');
  const gpu = path.join(root, 'gpu-b207-' + label);
  write(path.join(gpu, 'gpu_go.txt'), 'GPU cleared\r\n');
  // System32 first: a Git Bash PATH otherwise finds the Unix find.exe, which would walk all of C: on "find /c".
  const system32 = path.join(process.env.SystemRoot || 'C:\\Windows', 'System32');
  const env = {
    ...process.env, USERPROFILE: home, PATH: bin + ';' + system32 + ';' + (process.env.PATH || ''), PC_GPU_ISSUE: 'self-test',
    LOCALAPPDATA: path.join(home, 'AppData', 'Local'), APPDATA: path.join(home, 'AppData', 'Roaming'),
    TEMP: path.join(home, 'Temp'), TMP: path.join(home, 'Temp'),
    PC_RUNNER_TEST: '1', PC_TEST_TIMEOUT_LOG: path.join(root, 'timeouts-b207-' + label + '.log'),
    // Issue 916: same as the stage 5 env: no code-only lane flag for the fakes (the bench's GPU launches are faked too).
    PC_GPU_LANE: '',
    PC_TEST_GPU_ROOT: gpu, FAKE_STATE: path.join(root, 'state-b207-' + label)
  };
  Object.assign(env, extra || {});
  return { home, vt, hi, envDir, env, out: path.join(vt, 'opus207', 'out') };
}
function benchSettings(h) { return 'hi=' + h.hi + '\r\nenv=' + h.envDir + '\r\n'; }
const benchBat = path.join(ROOT, 'tools/pc/jobs/bench207_scene_gate.bat');

let b = benchHome('ok', '', {});
write(path.join(b.vt, 'bench207_settings.txt'), benchSettings(b));
r = runBat(benchBat, b.env);
check(r.code === 0, 'bench 207 success case exited ' + r.code + '. Output: ' + r.text);
check(!r.text.includes('FAILED:'), 'bench 207 success case printed a FAILED line. Output: ' + r.text);
for (const run of ['run1', 'run2', 'run3_res']) {
  check(fs.existsSync(path.join(b.out, run, 'results.txt')), 'bench 207 success case: ' + run + ' has no output');
}
pass('bench 207 success case: import, build_assets and all three bench runs finish and the job exits 0');

b = benchHome('import', '', {});
write(path.join(b.vt, 'bench207_settings.txt'), benchSettings(b));
r = runBat(benchBat, Object.assign({}, b.env, { FAKE_GODOT_FAIL: 'import' }));
expectFail('bench 207 import failure stops the job', r, ['FAILED: the Godot import failed']);

b = benchHome('build', '', {});
write(path.join(b.vt, 'bench207_settings.txt'), benchSettings(b));
r = runBat(benchBat, Object.assign({}, b.env, { FAKE_GODOT_FAIL: 'build' }));
expectFail('bench 207 build_assets failure stops the job', r, ['FAILED: build_assets pass 1 failed']);

b = benchHome('nov3', '', {});
write(path.join(b.vt, 'bench207_settings.txt'), benchSettings(b));
r = runBat(benchBat, Object.assign({}, b.env, { FAKE_GODOT_NO_V3: '1' }));
expectFail('bench 207 build_assets missing output stops the job', r, ['FAILED: build_assets wrote no godot\\gen\\v3.txt after 3 passes']);

b = benchHome('bench', '', {});
write(path.join(b.vt, 'bench207_settings.txt'), benchSettings(b));
r = runBat(benchBat, Object.assign({}, b.env, { FAKE_GODOT_FAIL: 'bench2' }));
expectFail('bench 207 bench run2 failure stops the job', r, ['FAILED: bench run2 failed']);

b = benchHome('noout', '', {});
write(path.join(b.vt, 'bench207_settings.txt'), benchSettings(b));
r = runBat(benchBat, Object.assign({}, b.env, { FAKE_GODOT_NO_OUT: 'bench2' }));
expectFail('bench 207 bench run2 missing output stops the job', r, ['FAILED: bench run2 wrote no output at']);

b = benchHome('nohi', '', {});
write(path.join(b.vt, 'bench207_settings.txt'), 'env=' + b.envDir + '\r\n');
r = runBat(benchBat, b.env);
expectFail('bench 207 missing hi setting stops the job', r, ['FAILED: no hi folder in']);

b = benchHome('noenvfolder', '', {});
write(path.join(b.vt, 'bench207_settings.txt'), 'hi=' + b.hi + '\r\nenv=' + path.join(b.vt, 'gone') + '\r\n');
r = runBat(benchBat, b.env);
expectFail('bench 207 missing env folder stops the job', r, ['FAILED: the env folder does not exist:']);

b = benchHome('nosettings', '', {});
fs.unlinkSync(path.join(b.vt, 'bench207_settings.txt'));
r = runBat(benchBat, b.env);
expectFail('bench 207 missing settings file stops the job', r, ['FAILED: no hi folder in']);

console.log('PASS stage5_fail_selftest: ' + passed + ' checks, fake executables only, no GPU, no network.');
