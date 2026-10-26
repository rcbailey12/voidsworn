# Stream B: build a PC queue job that runs sims in parallel windows on Ryan's PC, without blocking the shared queue.
# Usage (from the repo root): python3 contrib/opus/tools/pc_simjob.py TAG "name|mode args" ["name|ENV=1;ENV2=x::mode args"] ...
# Writes /mnt/user-data/outputs/sb_TAG/ (game rule files plus sb_TAG.bat). Commit the files to
# Downloads\voidsworn_test\build\streamb\TAG\ and the .bat to Downloads\voidsworn_test\queue\.
# The job starts one minimized window per sim and returns at once; each sim writes NAME.txt and then NAME.done in its folder.
import sys, os, shutil
tag = sys.argv[1]; jobs = sys.argv[2:]
src = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
out = f'/mnt/user-data/outputs/sb_{tag}'
if os.path.exists(out): sys.exit('staging folder exists, pick a new tag')
os.makedirs(out)
for f in ['data.js', 'core.js', 'battle.js', 'sim3d.js', 'campaign_run.js', 'campaign_meta.js']: shutil.copy(os.path.join(src, f), out)
L = ['@echo off', 'cd streamb\\' + tag, 'echo stream B job %cd%']
for j in jobs:
    name, cmd = j.split('|', 1)
    env = ''
    if '::' in cmd:
        env, cmd = cmd.split('::', 1)
        env = ' '.join(f'set "{e}" &&' for e in env.split(';') if e) + ' '
    L.append(f'start "sb {tag} {name}" /min cmd /c "{env}..\\..\\..\\node\\node.exe sim3d.js {cmd} > {name}.txt 2>&1 & echo done> {name}.done"')
L += ['echo launched', 'exit /b']
open(f'{out}/sb_{tag}.bat', 'w', newline='\r\n').write('\n'.join(L) + '\n')
print(open(f'{out}/sb_{tag}.bat').read())
