"""Stage 7 install and the standalone ship manifest merge used by the look bench."""
import contextlib
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


HERE = Path(__file__).resolve().parent
ENTRY = 'manifest_entry.json'


@contextlib.contextmanager
def project_lock(project):
    # The OS releases the lock even if the installer exits. Keep the lock file so
    # later installers always lock the same file.
    with (project / '.stage7.lock').open('a+b') as lock:
        try:
            if os.name == 'nt':
                import msvcrt
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as exc:
            raise RuntimeError(f'another ship install is using {project}') from exc
        yield


def sha256(path):
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def verify(folder, expected):
    for name, digest in expected.items():
        if sha256(folder / name) != digest:
            raise ValueError(f'{folder / name} differs from the checked export')


def copy_verified(source, dest, digest=None):
    expected = sha256(source) if digest is None else digest
    shutil.copy2(source, dest)
    if sha256(dest) != expected:
        raise ValueError(f'copy verification failed for {dest}')


def backup_file(source, dest):
    if source.exists():
        copy_verified(source, dest)
        return dest
    return None


def read_json(path):
    return json.loads(path.read_bytes())


def merge_entry(entry, previous, code, dest):
    manifest = read_json(previous) if previous else dict(note='', ships={})
    manifest.setdefault('ships', {})[code] = entry
    dest.write_text(json.dumps(manifest, indent=1), encoding='utf-8', newline='\n')


def main(entry_path, godot, code):
    """Keep the existing manifest-only command for the look-bench overlay."""
    project = Path(godot).resolve()
    with project_lock(project):
        path = project / 'assets' / 'ships' / 'manifest.json'
        work = Path(tempfile.mkdtemp(prefix='manifest.bak_', dir=path.parent))
        previous = backup_file(path, work / path.name)
        entry = read_json(Path(entry_path))
        new = work / 'new.json'
        merge_entry(entry, previous, code, new)
        os.replace(new, path)
    print(f'manifest PASS: {code} written into {path} with points {entry.get("hardpoints", {})}')
    return 0


def is_export_map(code, name):
    return re.fullmatch(
        re.escape(code) + r'(?:_[\w-]+\.jpg|(?:_[\w-]+)?_(?:normal|orm)\.png)', name
    ) is not None


def export_snapshot(export, snapshot, code):
    # Read the exact texture set from the GLB. Earlier exports can leave maps
    # of either format in the same directory.
    from glb_io import read_glb

    glb = code + '.glb'
    copy_verified(export / glb, snapshot / glb)
    doc, _ = read_glb(snapshot / glb)
    maps = {image.get('uri') for image in doc.get('images', [])}
    for name in maps:
        if not isinstance(name, str) or not is_export_map(code, name):
            raise ValueError(f'unsupported export texture path {name!r}')
    for name in [ENTRY, *sorted(maps)]:
        copy_verified(export / name, snapshot / name)
    return {name: sha256(snapshot / name) for name in [glb, ENTRY, *sorted(maps)]}


def run_check(command, log, marker=None):
    with log.open('w', encoding='utf-8') as output:
        result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT)
    report = log.read_text(encoding='utf-8', errors='replace')
    if marker is None or result.returncode or marker not in report:
        print(report, end='')
    if result.returncode or (marker is not None and marker not in report):
        raise RuntimeError(f'check failed. See {log}')


def install(project, code, snapshot, expected, refresh, readback):
    """Publish the checked files and roll the ship and its cache back together."""
    ship_base = project / 'assets' / 'ships'
    live = ship_base / code
    manifest = ship_base / 'manifest.json'
    gen_manifest = project / 'gen' / 'manifest.json'
    scene = project / 'gen' / 'ships' / (code + '.scn')
    files = {name: digest for name, digest in expected.items() if name != ENTRY}

    with project_lock(project):
        verify(snapshot, expected)
        ship_base.mkdir(parents=True, exist_ok=True)
        work = Path(tempfile.mkdtemp(prefix='.stage7-replaced-', dir=project))
        incoming = work / 'incoming' / code
        incoming.mkdir(parents=True)
        replaced = work / 'previous'
        replaced.mkdir()
        failed = work / 'failed'
        failed.mkdir()

        def managed(name):
            return (name in files or name in {code + '_damage.glb', code + '_wreck.glb'}
                    or is_export_map(code, name)
                    or (name.startswith(code + '_') and name.lower().endswith('.jpg')))

        # Keep other files in the ship directory, and stage every copy and
        # manifest backup before the first live change.
        if live.exists():
            shutil.copytree(live, incoming, dirs_exist_ok=True,
                            ignore=lambda directory, names: [name for name in names if managed(name)]
                            if Path(directory) == live else [])
        for name, digest in files.items():
            copy_verified(snapshot / name, incoming / name, digest)
        previous_manifest = backup_file(manifest, replaced / 'asset_manifest.json')
        previous_cache = backup_file(gen_manifest, replaced / 'cache_manifest.json')
        entry = read_json(snapshot / ENTRY)
        verify(snapshot, expected)
        new_manifest = work / 'manifest.json'
        merge_entry(entry, previous_manifest, code, new_manifest)
        manifest_digest = sha256(new_manifest)

        def verify_install():
            verify(live, files)
            if sha256(manifest) != manifest_digest:
                raise ValueError('installed ship manifest differs from the checked export')
            if any(managed(path.name) and path.name not in files for path in live.iterdir()):
                raise ValueError('obsolete export files remain in the ship folder')

        changes = []
        try:
            previous_ship = replaced / code if live.exists() else None
            if previous_ship:
                os.replace(live, previous_ship)
            changes.append((live, previous_ship, code))

            previous_scene = replaced / 'ship.scn' if scene.exists() else None
            if previous_scene:
                os.replace(scene, previous_scene)
            changes.append((scene, previous_scene, 'ship.scn'))
            changes.append((gen_manifest, previous_cache, 'cache_manifest.json'))
            # Only this ship is visible to the builder. Moving the old scene
            # aside forces a rebuild even when old and new stamps collide.
            refresh(incoming.parent)

            os.replace(incoming, live)

            os.replace(new_manifest, manifest)
            changes.append((manifest, previous_manifest, 'asset_manifest.json'))
            verify_install()
            readback()
            verify_install()
        except (Exception, KeyboardInterrupt):
            errors = []
            for dest, previous, name in reversed(changes):
                try:
                    if previous is not None and previous.is_file():
                        os.replace(previous, dest)
                    else:
                        if dest.exists():
                            os.replace(dest, failed / name)
                        if previous is not None:
                            os.replace(previous, dest)
                except OSError as exc:
                    errors.append(str(exc))
            if errors:
                raise RuntimeError(f'rollback incomplete. Backups at {work}: ' + ' | '.join(errors)) from None
            print(f'Install rolled back. Recovery files at {work}', file=sys.stderr)
            raise
        print(f'Installed into {live}; previous files at {replaced}')


def install_export(export, project, code, godot, job, ship, *options):
    export, project, job, ship = (Path(path).resolve() for path in (export, project, job, ship))
    if not (project / 'project.godot').is_file():
        raise ValueError(f'INSTALL_TO is not a Godot project folder: {project}')
    if not re.fullmatch(r'[A-Za-z0-9_][A-Za-z0-9_-]*', code):
        raise ValueError(f'invalid ship folder code {code!r}')

    snapshot = Path(tempfile.mkdtemp(prefix=f'stage7-checked-{code}-'))
    expected = export_snapshot(export, snapshot, code)
    for script, log, failed in (
        ('check_export.py', 'log_export_check.txt', 'CHECK FAILED'),
        ('check_export_selftest.py', 'log_export_selftest.txt', 'SELFTEST FAILED'),
    ):
        try:
            run_check([sys.executable, '-B', str(HERE / script), str(ship), str(snapshot), *options], job / log)
        except RuntimeError:
            (export / 'export_status.txt').write_text(failed + '\n', encoding='utf-8')
            raise
    verify(snapshot, expected)
    copy_verified(snapshot / (code + '_check.json'), export / (code + '_check.json'))
    with (export / 'export_status.txt').open('a', encoding='utf-8') as status:
        status.write('CHECKED\n')

    def headless(script, args, log, marker):
        run_check([godot, '--headless', '--path', str(project), '--script', script, '--', *args], job / log, marker)

    def refresh(ships):
        headless('res://render/build_assets.gd', ['--ships-only', '--ships', ships.as_posix()],
                 'log_install_cache.txt', '[assets] ships refreshed:')

    def readback():
        headless('res://render/test/installed_ship_check.gd', [code],
                 'log_install_readback.txt', f'INSTALL READBACK PASS code={code} ')
        for line in (job / 'log_install_readback.txt').read_text(encoding='utf-8', errors='replace').splitlines():
            if line.startswith('INSTALL READBACK PASS'):
                print(line)

    install(project, code, snapshot, expected, refresh, readback)
    try:
        shutil.rmtree(snapshot)
    except OSError as exc:
        print(f'Could not remove checked export scratch {snapshot}: {exc}', file=sys.stderr)
    return 0


if __name__ == '__main__':
    try:
        args = sys.argv[1:]
        if len(args) >= 7 and args[0] == '--install':
            sys.exit(install_export(*args[1:]))
        if len(args) == 3:
            sys.exit(main(*args))
        sys.exit('usage: manifest_merge.py ENTRY PROJECT CODE or --install EXPORT PROJECT CODE GODOT JOB SHIP_JSON [unbaked=1]')
    except (OSError, ValueError, RuntimeError) as exc:
        sys.exit(f'Stage 7 FAILED: {exc}')
