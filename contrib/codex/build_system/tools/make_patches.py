#!/usr/bin/env python3
"""Maintainer packaging only; Ryan's verification launcher requires no Python."""
from pathlib import Path
import subprocess,difflib,json,hashlib,tempfile
BASE=Path(__file__).resolve().parents[1]
ROOT=BASE.parents[2]
PIN='355a2ac70860db4446f040a5787b19c2d746d779'
out=BASE/'patches';out.mkdir(exist_ok=True)
manifest=[]
for job in ['module_fit','lineage_pilot','tree_copy']:
    parts=[]
    for p in sorted((BASE/'candidates'/job).rglob('*')):
        if not p.is_file():continue
        name=p.relative_to(BASE/'candidates'/job).as_posix()
        old=subprocess.run(['git','show',PIN+':'+name],cwd=ROOT,capture_output=True)
        before=old.stdout.decode() if old.returncode==0 else ''
        after=p.read_text()
        if before==after:continue
        parts.append('diff --git a/'+name+' b/'+name+'\n')
        if old.returncode:parts.append('new file mode 100644\n')
        parts.extend(difflib.unified_diff(before.splitlines(keepends=True),after.splitlines(keepends=True),fromfile='a/'+name if not old.returncode else '/dev/null',tofile='b/'+name,n=3))
        manifest.append({'job':job,'path':name,'newFile':old.returncode!=0,'baseSHA256':hashlib.sha256(old.stdout).hexdigest() if not old.returncode else None,'candidateSHA256':hashlib.sha256(p.read_bytes()).hexdigest()})
    (out/(job+'.patch')).write_text(''.join(parts))
with tempfile.TemporaryDirectory(prefix='voidsworn-combined-patch-') as folder:
    temp=Path(folder)
    names=sorted({m['path'] for m in manifest if m['job'] in ['module_fit','lineage_pilot']})
    for name in names:
        old=subprocess.run(['git','show',PIN+':'+name],cwd=ROOT,capture_output=True)
        if old.returncode==0:
            p=temp/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(old.stdout)
    for job in ['module_fit','lineage_pilot']:
        args=['git','apply']
        if job=='lineage_pilot':args+=['--exclude=godot/campaign/test/oracle/README.md']
        r=subprocess.run(args+[str(out/(job+'.patch'))],cwd=temp,capture_output=True,text=True)
        if r.returncode:raise RuntimeError(r.stderr)
    readme='godot/campaign/test/oracle/README.md'
    original=subprocess.check_output(['git','show',PIN+':'+readme],cwd=ROOT).decode()
    merged=original
    for job in ['module_fit','lineage_pilot']:
        full=(BASE/'candidates'/job/readme).read_text()
        assert full.startswith(original)
        merged+=full[len(original):]
    (temp/readme).write_text(merged)
    parts=[]
    for name in names:
        old=subprocess.run(['git','show',PIN+':'+name],cwd=ROOT,capture_output=True)
        before=old.stdout.decode() if old.returncode==0 else '';after=(temp/name).read_text()
        if before==after:continue
        parts.append('diff --git a/'+name+' b/'+name+'\n')
        if old.returncode:parts.append('new file mode 100644\n')
        parts.extend(difflib.unified_diff(before.splitlines(keepends=True),after.splitlines(keepends=True),fromfile='a/'+name if not old.returncode else '/dev/null',tofile='b/'+name,n=3))
        manifest.append({'job':'combined_runtime','path':name,'newFile':old.returncode!=0,'baseSHA256':hashlib.sha256(old.stdout).hexdigest() if not old.returncode else None,'candidateSHA256':hashlib.sha256((temp/name).read_bytes()).hexdigest()})
    (out/'combined_runtime.patch').write_text(''.join(parts))
(out/'manifest.json').write_text(json.dumps({'sourcePin':PIN,'files':manifest},indent=2)+'\n')
print('Three job patches, combined runtime patch, and SHA-256 adoption manifest written')
