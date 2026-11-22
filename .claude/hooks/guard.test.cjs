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
const env = { ...process.env, CLAUDE_PROJECT_DIR: work,
  VOIDSWORN_CLAUDE_SEAT: 'opus', VOIDSWORN_BOARD_SESSION_ID: session_id + '-board' };

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

  const board = { session_id: env.VOIDSWORN_BOARD_SESSION_ID };
  const workerInBoard = { ...board, agent_id: 'helper' };
  const preGuard = settings.hooks.PreToolUse[0].hooks[0];
  assert.equal(preGuard.onFailure, 'block');
  assert.ok(settings.permissions.deny.includes('Read(//**/.env)'));
  assert.ok(settings.permissions.deny.includes('Read(//**/secrets/**)'));
  deny(pre('Read', { file_path: path.join(work, 'nested/.env') }, board), /protected files/);
  deny(pre('Read', { file_path: 'nested/.envrc' }, board), /protected files/);
  deny(pre('Grep', { path: 'nested/SECRETS/readme.txt' }, board), /protected files/);
  deny(pre('Read', { file_path: 'nested/server.key' }), /protected files/);
  deny(shell('cat "nested/.env.local"', board), /protected files/);
  deny(pre('PowerShell', { command: 'Get-Content -LiteralPath secrets/credentials.json' }, board), /protected files/);
  deny(shell('git show HEAD:.env', board), /protected files/);
  permit(pre('Read', { file_path: 'README.md' }, board));
  console.log('PASS credential guard: blocked file, search, Bash, PowerShell and Git reads');

  deny(pre('Edit', { file_path: 'README.md' }), /Worker edits/);
  deny(pre('Write', { file_path: 'contrib/muse/notes.md' }), /Worker edits/);
  deny(pre('NotebookEdit', { notebook_path: 'contrib/opus/../../README.md' }), /Worker edits/);
  deny(pre('Write', { file_path: path.join(temp, 'outside.txt') }), /Worker edits/);
  deny(pre('Write', { file_path: 'contrib/opus/notes.md' }, { cwd: temp }), /Worker edits/);
  deny(pre('Edit', { file_path: 'README.md' }, workerInBoard), /Worker edits/);
  deny(shell('echo changed > README.md'), /Workers use Claude file tools/);
  permit(pre('Write', { file_path: 'contrib/opus/new/notes.md' }));
  permit(pre('Edit', { file_path: 'README.md' }, board));
  fs.symlinkSync(temp, path.join(work, 'contrib/opus/link'), process.platform === 'win32' ? 'junction' : 'dir');
  deny(pre('Write', { file_path: 'contrib/opus/link/new.txt' }), /Worker edits/);
  fs.unlinkSync(path.join(work, 'contrib/opus/link'));
  console.log('PASS seat guard: blocked sibling seats, traversal, symlink escapes and shell writes');

  deny(shell('git push origin main'), /Only the Board/);
  deny(shell('git push origin HEAD:refs/heads/MAIN'), /Only the Board/);
  deny(shell('git push origin HEAD:refs/heads/main', workerInBoard), /Only the Board/);
  deny(shell('git push origin HEAD', board), /destination branch/);
  deny(shell('git push --mirror origin', board), /explicit refspec/);
  deny(shell('git push origin :main', board), /explicit refspec/);
  deny(shell('git -C . push origin main', board), /single plain command/);
  deny(shell('git status && git push origin main', board), /single plain command/);
  deny(pre('mcp__github__push_files', { branch: 'main' }, board), /checked git push/);
  deny(shell('gh api -X PATCH repos/team/game/git/refs/heads/main -f sha=abc', board), /checked git push/);
  permit(shell('gh api -X GET repos/team/game/git/refs/heads/main', board));
  permit(shell('git push -u origin HEAD:refs/heads/opus/issue-1660'));
  permit(shell('git push relay HEAD:refs/heads/pc-out-proof', board));
  write('contrib/opus/LOOP.md', 'after\n');
  write('contrib/opus/FINDINGS.md', 'after\n');
  git('add', 'contrib');
  git('commit', '-m', 'Change only both Board logs');
  permit(shell('git push origin main', board));
  permit(shell('git push origin HEAD:refs/heads/main', board));
  write('README.md', 'planted outside change\n');
  git('add', 'README.md');
  git('commit', '-m', 'Plant a disallowed change');
  deny(shell('git push origin main', board), /Each commit/);
  git('revert', '--no-edit', 'HEAD');
  deny(shell('git push origin main', board), /Each commit/);
  console.log('PASS push guard: allowed Board log commits and blocked main pushes with an outside change even if reverted');

  const dash = String.fromCharCode(0x2014);
  const warning = hook('PostToolUse', 'Edit', { new_string: 'one' + dash + 'two' });
  permit(warning);
  assert.match(JSON.parse(warning.stdout).hookSpecificOutput.additionalContext, /em dash/);
  const fixed = hook('PostToolUse', 'Edit', { old_string: 'one' + dash + 'two', new_string: 'one, two' });
  permit(fixed);
  assert.equal(fixed.stdout, '');
  console.log('PASS punctuation hook: flagged the planted em dash and cleared after replacement');

  permit(hook('UserPromptSubmit'));
  const clean = hook('Stop');
  permit(clean);
  assert.equal(clean.stdout, '');
  write('godot/probe.gd', 'extends Node\nfunc broken(\n');
  deny(hook('Stop'), /Godot parse check failed[\s\S]*(?:Parse Error|load all: FAILED)/);
  git('add', 'godot/probe.gd');
  git('commit', '-m', 'Commit the planted script while the turn is open');
  deny(hook('Stop'), /Godot parse check failed[\s\S]*(?:Parse Error|load all: FAILED)/);
  write('godot/probe.gd', 'extends Node\n');
  const fixedGodot = hook('Stop');
  permit(fixedGodot);
  assert.match(fixedGodot.stdout, /Godot parse check passed/);
  console.log('PASS Godot hook: skipped a clean turn, blocked a real parse error before and after commit, then passed the fix');
  console.log('PASS all five Claude hook checks');
} finally {
  permit(hook('SessionEnd'));
  fs.rmSync(temp, { recursive: true, force: true });
}
