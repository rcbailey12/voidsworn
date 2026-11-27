'use strict';

const fs = require('node:fs');
const path = require('node:path');
const env = process.env;
const win = process.platform === 'win32';
const slash = p => win ? p.replace(/\\/g, '/') : p;
const absolute = p => p && (win ? /^(?:[a-z]:[\\/]|[\\/]{2})/i.test(p) : path.isAbsolute(p));

function shardScratch() {
  // Use native path APIs. Git Bash mkdir can be denied on sandbox paths with doubled backslashes.
  // An explicit CI root must work. Only look for a fallback when none was set.
  const bases = env.RUNNER_TEMP ? [env.RUNNER_TEMP] : [env.TMPDIR, env.TEMP, env.TMP,
    win ? (env.USERPROFILE && path.join(env.USERPROFILE, 'AppData', 'Local', 'Temp')) : '/tmp'];
  for (const base of bases) {
    if (!absolute(base)) continue;
    let dir;
    try {
      dir = fs.mkdtempSync(path.join(path.resolve(base), 'godot_checks-'));
    } catch {
      continue;
    }
    // Existing save and settings tests require the literal /godot_checks/xdg/ marker.
    const work = path.join(dir, 'godot_checks');
    try {
      fs.mkdirSync(work);
      for (const child of ['logs', 'fixtures', 'xdg']) fs.mkdirSync(path.join(work, child));
    } catch (err) {
      fs.rmSync(dir, { recursive: true, force: true });
      throw err;
    }
    return work;
  }
  throw new Error('no writable temp root');
}

function removeShard(work) {
  const dir = path.dirname(work);
  if (!absolute(work) || path.basename(work) !== 'godot_checks' || !/^godot_checks-[a-z0-9]{6}$/i.test(path.basename(dir))) {
    throw new Error('refusing to remove a directory outside this shard scratch');
  }
  fs.rmSync(dir, { recursive: true, force: true });
}

function onboardingAlias() {
  if (!absolute(env.GODOT_TEMP_DIR)) throw new Error('Godot did not report an absolute temp path');
  const dir = fs.mkdtempSync(path.join(env.GODOT_TEMP_DIR, 'voidsworn-onboarding-ci-'));
  const profile = path.join(dir, 'profile');
  try {
    // A Windows directory junction does not require symlink privileges.
    fs.symlinkSync(env.CHECK_USER_DIR, profile, win ? 'junction' : 'dir');
  } catch (err) {
    fs.rmdirSync(dir);
    throw err;
  }
  return profile;
}

try {
  if (process.argv[2] === 'shard') process.stdout.write(slash(shardScratch()));
  else if (process.argv[2] === 'remove-shard') removeShard(env.CHECK_SHARD_SCRATCH || '');
  else if (process.argv[2] === 'onboarding') process.stdout.write(slash(onboardingAlias()));
  else if (process.argv[2] === 'unlink-onboarding') {
    fs.unlinkSync(env.CHECK_PROFILE_ALIAS);
    fs.rmdirSync(path.dirname(env.CHECK_PROFILE_ALIAS));
  } else throw new Error('unknown scratch operation');
} catch (err) {
  console.error(err.message);
  process.exitCode = 1;
}
