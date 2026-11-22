'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const settings = require('../settings.json');

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'voidsworn-hooks-'));
const work = path.join(temp, 'fixture');
const remote = path.join(temp, 'origin.git');
const root = path.resolve(__dirname, '../..');
const session_id = path.basename(temp);
// Main seat: no seat variable, as every cloud Opus thread (Board and workers) launches.
const mainEnv = { ...process.env, CLAUDE_PROJECT_DIR: work };
delete mainEnv.VOIDSWORN_CLAUDE_SEAT;
delete mainEnv.VOIDSWORN_BOARD_SESSION_ID;
// Fenced seat: a launch that names a non-main seat keeps the contrib/<seat>/ fence.
const fencedEnv = { ...mainEnv, VOIDSWORN_CLAUDE_SEAT: 'fable' };
const opusEnv = { ...mainEnv, VOIDSWORN_CLAUDE_SEAT: 'opus' };

function git(...args) {
  const result = spawnSync('git', args, { cwd: work, encoding: 'utf8', windowsHide: true });
  assert.equal(result.status, 0, result.stderr || String(result.error));
  return result.stdout.trim();
}

function write(file, content) {
  const target = path.join(work, file);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, content);
}

function hook(hook_event_name, tool_name, tool_input, options = {}) {
  const { env = mainEnv, ...extra } = options;
  options = extra;
  const spec = settings.hooks[hook_event_name].find(group => !group.matcher ||
    new RegExp('^(?:' + group.matcher + ')$').test(tool_name));
  assert.ok(spec, 'Missing configured hook for ' + hook_event_name + ' ' + tool_name);
  const [handler] = spec.hooks;
  assert.equal(handler.command, 'node');
  const args = handler.args.map(arg => arg.replace('${CLAUDE_PROJECT_DIR}', root));
  const input = JSON.stringify({ hook_event_name, tool_name, tool_input, session_id, cwd: work, ...options });
  return spawnSync(process.execPath, args, { input, env, encoding: 'utf8', timeout: 120000, windowsHide: true });
}

function permit(result) {
  assert.equal(result.status, 0, result.stderr || String(result.error));
}

function deny(result, reason) {
  assert.equal(result.status, 2, result.stderr || String(result.error));
  assert.match(result.stderr, reason);
}

function pre(tool, input, options) {
  return hook('PreToolUse', tool, input, options);
}

function shell(command, options) {
  return pre('Bash', { command }, options);
}

fs.mkdirSync(work);
try {
  git('init', '-b', 'main');
  git('config', 'user.name', 'Hook Test');
  git('config', 'user.email', 'hooks@example.invalid');
  git('init', '--bare', remote);
  git('remote', 'add', 'origin', remote);
  write('README.md', 'fixture\n');
  write('.gitignore', 'godot/.godot/\n');
  write('contrib/opus/LOOP.md', 'before\n');
  write('contrib/opus/FINDINGS.md', 'before\n');
  write('godot/project.godot', 'config_version=5\n');
  write('godot/tools/ci/load_all.gd', fs.readFileSync(path.join(root, 'godot/tools/ci/load_all.gd')));
  git('add', '.');
  git('commit', '-m', 'Seed isolated fixture');
  git('push', 'origin', 'main');

  const main = {};
  const fence = { env: fencedEnv };
  const subagent = { agent_id: 'helper' };
  const preGuard = settings.hooks.PreToolUse[0].hooks[0];
  assert.equal(preGuard.onFailure, 'block');
  assert.ok(settings.permissions.deny.includes('Read(//**/.env)'));
  assert.ok(settings.permissions.deny.includes('Read(//**/secrets/**)'));
  deny(pre('Read', { file_path: path.join(work, 'nested/.env') }, main), /protected files/);
  deny(pre('Read', { file_path: 'nested/.envrc' }, main), /protected files/);
  deny(pre('Grep', { path: 'nested/SECRETS/readme.txt' }, main), /protected files/);
  deny(pre('Read', { file_path: 'nested/server.key' }, fence), /protected files/);
  deny(shell('cat "nested/.env.local"', main), /protected files/);
  deny(pre('PowerShell', { command: 'Get-Content -LiteralPath secrets/credentials.json' }, main), /protected files/);
  deny(shell('git show HEAD:.env', main), /protected files/);
  permit(pre('Read', { file_path: 'README.md' }, main));
  permit(shell('git commit -m "Move secrets note to the README"', main));
  permit(shell('grep -rn secrets .github/workflows', main));
  // Fable's audit of PR 1706: code such as board.key( is not a key file; a path or an existing file still is
  permit(shell('grep -n "board.key(" godot/battle.gd', main));
  deny(shell('cat certs/server.key', main), /protected files/);
  deny(shell('cat HEAD:server.pem', main), /protected files/);
  write('server.key', 'not really\n');
  deny(shell('cat server.key', main), /protected files/);
  fs.rmSync(path.join(work, 'server.key'));
  deny(shell('cat .env.key', main), /protected files/);
  console.log('PASS credential guard: blocked file, search, Bash, PowerShell and Git reads; plain word "secrets" allowed');

  // Must pass: main seats (no seat variable, or seat opus) work anywhere in the repo, as Opus helper threads do.
  permit(pre('Edit', { file_path: 'godot/rules/battle.gd' }, main));
  permit(pre('Write', { file_path: 'tools/new_tool.js' }, main));
  permit(pre('Edit', { file_path: 'docs/RULEBOOK.md' }, subagent));
  permit(pre('Edit', { file_path: 'godot/rules/battle.gd' }, { env: opusEnv }));
  permit(shell('godot --headless --path godot --script res://tools/ci/load_all.gd', main));
  permit(shell('node contrib/opus/tools/sync_skills.js && node tools/checks.js', main));
  permit(shell('echo changed > README.md', main));
  console.log('PASS main seat: edits in godot/, tools/ and docs/, and ordinary shell, all allowed with no seat set');

  deny(pre('Edit', { file_path: 'README.md' }, fence), /edits only under contrib\/fable/);
  deny(pre('Write', { file_path: 'contrib/muse/notes.md' }, fence), /contrib\/fable/);
  deny(pre('NotebookEdit', { notebook_path: 'contrib/fable/../../README.md' }, fence), /contrib\/fable/);
  deny(pre('Write', { file_path: path.join(temp, 'outside.txt') }, fence), /contrib\/fable/);
  deny(shell('echo changed > README.md', fence), /Fenced seats use Claude file tools/);
  permit(pre('Write', { file_path: 'contrib/fable/new/notes.md' }, fence));
  fs.mkdirSync(path.join(work, 'contrib/fable'), { recursive: true });
  fs.symlinkSync(temp, path.join(work, 'contrib/fable/link'), process.platform === 'win32' ? 'junction' : 'dir');
  deny(pre('Write', { file_path: 'contrib/fable/link/new.txt' }, fence), /contrib\/fable/);
  fs.unlinkSync(path.join(work, 'contrib/fable/link'));
  console.log('PASS fenced seat: a named non-main seat is held to contrib/<seat>/, traversal and symlink escapes blocked');

  // Must pass: ordinary pushes, never checked beyond "does it land on main".
  git('switch', '-q', '-c', 'opus/issue-1660');
  permit(shell('git push -q origin opus/issue-1660', main));
  permit(shell('git push -u origin HEAD:refs/heads/opus/issue-1660', main));
  permit(shell('git push origin A:refs/heads/board/pin-a B:refs/heads/board/pin-b', main));
  permit(shell('git push --force-with-lease origin opus/issue-1660', main));
  permit(shell('cd ' + work + ' && git push -u origin opus/issue-1660', main));
  permit(shell('for i in 1 2 3; do git push -u origin opus/issue-1660 && break; sleep 2; done', main));
  permit(shell('git push', main));
  permit(shell('git push relay HEAD:refs/heads/pc-out-proof', main));
  permit(shell('git push -q origin opus/issue-1660', fence));
  permit(shell('git commit -m "main menu push fix"', main));
  console.log('PASS ordinary pushes: -q, -u, two pins in one call, lease, compound and retry loops all go through');

  deny(shell('git push origin HEAD:refs/heads/main', fence), /Only a main seat/);
  deny(shell('git push --mirror origin', main), /named branches/);
  deny(shell('git push origin :main', main), /cannot be deleted/);
  deny(shell('git push origin --delete main', main), /cannot be deleted/);
  deny(shell('git push -f origin HEAD:main', main), /fast-forward/);
  deny(shell('git push origin +HEAD:main', main), /fast-forward/);
  write('godot/feature.gd', 'extends Node\n');
  git('add', 'godot/feature.gd');
  git('commit', '-m', 'Feature work on the issue branch');
  deny(shell('git push origin opus/issue-1660:main', main), /Each commit/);
  deny(shell('git push origin "$B":main', main), /plain git push/);
  deny(pre('mcp__github__push_files', { branch: 'main' }, main), /Direct writes to main/);
  deny(pre('mcp__github__create_or_update_file', { path: 'x' }, main), /Name the branch/);
  permit(pre('mcp__github__push_files', { branch: 'opus/issue-1660' }, main));
  permit(pre('mcp__github__create_branch', { branch: 'opus/issue-1660', from_branch: 'main' }, main));
  deny(shell('gh api -X PATCH repos/team/game/git/refs/heads/main -f sha=abc', main), /Direct writes to main/);
  deny(shell('gh api -X PUT repos/team/game/contents/README.md -f message=x -f content=eA==', main), /Direct writes to main/);
  permit(shell('gh api -X PUT repos/team/game/contents/README.md -f message=x -f content=eA== -f branch=opus/issue-1660', main));
  permit(shell('gh api -X GET repos/team/game/git/refs/heads/main', main));
  console.log('PASS main guard: force, delete, mirror, unverifiable and direct API writes to main blocked; branch writes allowed');

  git('switch', '-q', 'main');
  write('contrib/opus/LOOP.md', 'after\n');
  write('contrib/opus/FINDINGS.md', 'after\n');
  git('add', 'contrib');
  git('commit', '-m', 'Change only both Board logs');
  permit(shell('git push origin main', main));
  permit(shell('git push origin HEAD:refs/heads/main', main));
  permit(shell('git push', main));
  permit(shell('cd ' + work + ' && git push origin main 2>&1', main));
  write('README.md', 'planted outside change\n');
  git('add', 'README.md');
  git('commit', '-m', 'Plant a disallowed change');
  deny(shell('git push origin main', main), /Each commit/);
  deny(shell('git push', main), /Each commit/);
  deny(shell('git status && git push origin main', main), /Bash call of its own/);
  deny(shell("git commit -qam 'x' && git push origin main 2>&1", main), /Bash call of its own/);
  deny(shell('git push origin main 2>&1', main), /Each commit/);
  deny(shell('git -C ' + work + ' push origin main', main), /Each commit/);
  git('revert', '--no-edit', 'HEAD');
  deny(shell('git push origin main', main), /Each commit/);
  console.log('PASS Board log push: LOOP.md and FINDINGS.md fast-forward to main allowed; any other change blocked even if reverted');

  const dash = String.fromCharCode(0x2014);
  const warning = hook('PostToolUse', 'Edit', { new_string: 'one' + dash + 'two' });
  permit(warning);
  assert.match(JSON.parse(warning.stdout).hookSpecificOutput.additionalContext, /em dash/);
  const fixed = hook('PostToolUse', 'Edit', { old_string: 'one' + dash + 'two', new_string: 'one, two' });
  permit(fixed);
  assert.equal(fixed.stdout, '');
  console.log('PASS punctuation hook: flagged the planted em dash and cleared after replacement');

  git('reset', '-q', '--hard', 'origin/main');
  permit(hook('UserPromptSubmit'));
  const clean = hook('Stop');
  permit(clean);
  assert.equal(clean.stdout, '');
  write('godot/probe.gd', 'extends Node\nfunc broken(\n');
  deny(hook('Stop'), /Godot parse check failed[\s\S]*(?:Parse Error|load all: FAILED)/);
  git('add', 'godot/probe.gd');
  git('commit', '-m', 'Commit the planted script while the turn is open');
  deny(hook('Stop'), /Godot parse check failed[\s\S]*(?:Parse Error|load all: FAILED)/);
  // The retry the hook caused, with the same failure: end the turn with a visible note instead of looping.
  const looped = hook('Stop', undefined, undefined, { stop_hook_active: true });
  permit(looped);
  assert.match(JSON.parse(looped.stdout).systemMessage, /still fails after one retry/);
  write('godot/probe.gd', 'extends Node\n');
  const fixedGodot = hook('Stop', undefined, undefined, { stop_hook_active: true });
  permit(fixedGodot);
  assert.match(fixedGodot.stdout, /Godot parse check passed/);
  console.log('PASS Godot hook: skipped a clean turn, blocked a real parse error, ended after one unchanged retry, passed the fix');

  // Godot missing: never block, on the first stop or the retry; say it was skipped.
  write('godot/probe.gd', 'extends Node\nfunc broken(\n');
  const noGodotEnv = { ...mainEnv, GODOT_EXE: path.join(temp, 'no-such-godot') };
  for (const stop_hook_active of [false, true]) {
    const missing = hook('Stop', undefined, undefined, { env: noGodotEnv, stop_hook_active });
    permit(missing);
    assert.match(JSON.parse(missing.stdout).systemMessage, /Godot parse check skipped/);
  }
  // A folder with no git repo must not block a prompt or a stop either.
  const outside = { cwd: temp, env: { ...mainEnv, CLAUDE_PROJECT_DIR: temp } };
  permit(hook('UserPromptSubmit', undefined, undefined, outside));
  permit(hook('Stop', undefined, undefined, outside));
  console.log('PASS setup failures: missing Godot or no repo never blocks a prompt or a stop, so no turn can loop');
  console.log('PASS all Claude hook checks');
} finally {
  permit(hook('SessionEnd'));
  fs.rmSync(temp, { recursive: true, force: true });
}
