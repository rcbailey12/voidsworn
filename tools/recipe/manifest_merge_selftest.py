"""Fault checks for stage 7. All writes go to a temporary project."""
import json
from pathlib import Path
import struct
import tempfile
from unittest.mock import patch

import manifest_merge as stage


CODE = 'TEST_1101'
GLB = CODE + '.glb'
JPG = CODE + '_base.jpg'
NORMAL = CODE + '_normal.png'
ORM = CODE + '_parts_orm.png'
OLD_MAP = CODE + '_old.jpg'
OLD_PNG = CODE + '_old_normal.png'


def write_glb(path, *maps):
    doc = json.dumps({'images': [{'uri': name} for name in maps]}).encode('utf-8')
    doc += b' ' * (-len(doc) % 4)
    glb = struct.pack('<4sIII4s', b'glTF', 2, 20 + len(doc), len(doc), b'JSON') + doc
    path.write_bytes(glb)


def make_export(export):
    export.mkdir(parents=True)
    write_glb(export / GLB, JPG, NORMAL, ORM)
    (export / JPG).write_bytes(b'checked texture')
    (export / NORMAL).write_bytes(b'checked normal')
    (export / ORM).write_bytes(b'checked orm')
    (export / OLD_MAP).write_bytes(b'left over from a previous export')
    (export / stage.ENTRY).write_text('{"hardpoints":{"core":1}}', encoding='utf-8')


def check_stray_maps(root):
    export, snapshot = root / 'export', root / 'checked'
    make_export(export)
    snapshot.mkdir()
    for stray in (CODE + '_base.png', '../' + NORMAL, 'OTHER_normal.png'):
        write_glb(export / GLB, JPG, NORMAL, ORM, stray)
        try:
            stage.export_snapshot(export, snapshot, CODE)
        except ValueError as exc:
            assert 'unsupported export texture path' in str(exc), exc
        else:
            raise AssertionError(f'accepted stray texture name {stray}')
    print('PASS stray texture paths rejected')


def setup(root):
    export, snapshot = root / 'export', root / 'checked'
    make_export(export)
    snapshot.mkdir()
    expected = stage.export_snapshot(export, snapshot, CODE)
    assert set(expected) == {GLB, JPG, NORMAL, ORM, stage.ENTRY}
    assert {path.name for path in snapshot.iterdir()} == set(expected)

    project = root / 'project with spaces'
    live = project / 'assets' / 'ships' / CODE
    scene = project / 'gen' / 'ships' / (CODE + '.scn')
    live.mkdir(parents=True)
    scene.parent.mkdir(parents=True)
    originals = {live / GLB: b'old hull', live / JPG: b'old texture',
                 live / OLD_PNG: b'old lossless map',
                 live / OLD_MAP: b'old map', live / (CODE + '_wreck.glb'): b'old wreck',
                 live / (CODE + '_damage.glb'): b'old damage', live / 'notes.txt': b'keep',
                 live.parent / 'manifest.json': b'{"ships":{"other":{"keep":true}}}',
                 scene: b'old cached scene', scene.parent.parent / 'manifest.json': b'old cache manifest'}
    for path, data in originals.items():
        path.write_bytes(data)
    (project / 'project.godot').touch()
    return project, live, scene, snapshot, expected, originals


def exercise(root, fault):
    project, live, scene, snapshot, expected, originals = setup(root)
    checked_glb = (snapshot / GLB).read_bytes()
    manifest = live.parent / 'manifest.json'
    cache = scene.parent.parent / 'manifest.json'
    refreshed = False

    def refresh(ships):
        nonlocal refreshed
        refreshed = True
        assert [child.name for child in ships.iterdir()] == [CODE]
        assert (ships / CODE / GLB).read_bytes() == checked_glb
        assert not scene.exists(), 'the old cache scene could suppress a rebuild'
        # A second stage or manifest-only merge cannot write inside this window.
        try:
            stage.main(snapshot / stage.ENTRY, project, 'another_ship')
        except RuntimeError as exc:
            assert 'another ship install' in str(exc)
        else:
            raise AssertionError('a second installer acquired the project lock')
        scene.write_bytes(b'new cached scene')
        cache.write_bytes(b'new cache manifest')
        if fault == 'refresh':
            raise RuntimeError('injected refresh failure')

    def readback():
        assert scene.read_bytes() == b'new cached scene'
        assert (live / GLB).read_bytes() == checked_glb
        assert (live / JPG).read_bytes() == b'checked texture'
        assert (live / NORMAL).read_bytes() == b'checked normal'
        assert (live / ORM).read_bytes() == b'checked orm'
        assert (live / 'notes.txt').read_bytes() == b'keep'
        assert set(path.name for path in live.iterdir()) == {GLB, JPG, NORMAL, ORM, 'notes.txt'}
        assert json.loads(manifest.read_bytes())['ships'] == {
            'other': {'keep': True}, CODE: {'hardpoints': {'core': 1}}}
        if fault == 'readback':
            raise RuntimeError('injected readback failure')
        if fault == 'changed_installed_map':
            (live / JPG).write_bytes(b'wrong installed texture')

    real_copy = stage.shutil.copy2
    real_replace = stage.os.replace
    manifest_publishes = 0

    def copy(source, target, *args, **kwargs):
        if (fault == 'backup_copy' and source == cache) or (fault == 'stage_copy' and source == snapshot / JPG):
            raise PermissionError('injected copy failure')
        return real_copy(source, target, *args, **kwargs)

    def replace(src, dest):
        nonlocal manifest_publishes
        if fault == 'backup_move' and src == scene:
            raise PermissionError('injected backup move failure')
        if dest == manifest and src.name == 'manifest.json':
            manifest_publishes += 1
            assert manifest.read_bytes() == originals[manifest]
        return real_replace(src, dest)

    if fault == 'changed_checked_glb':
        (snapshot / GLB).write_bytes(b'changed checked hull')

    with patch.object(stage.shutil, 'copy2', copy), patch.object(stage.os, 'replace', replace):
        try:
            stage.install(project, CODE, snapshot, expected, refresh, readback)
        except (OSError, RuntimeError, ValueError) as exc:
            assert fault is not None, exc
            assert 'injected' in str(exc) or 'differs from the checked export' in str(exc), exc
        else:
            assert fault is None, f'{fault} was accepted'

    if fault:
        assert all(path.read_bytes() == data for path, data in originals.items()), 'the previous install changed'
        assert refreshed == (fault in ('refresh', 'readback', 'changed_installed_map'))
    else:
        readback()
        assert manifest_publishes == 1
        backup = next(project.glob('.stage7-replaced-*')) / 'previous'
        assert (backup / CODE / GLB).read_bytes() == originals[live / GLB]
        assert (backup / 'asset_manifest.json').read_bytes() == originals[manifest]
        assert (backup / 'ship.scn').read_bytes() == originals[scene]
    # The lock also releases on a failed transaction.
    with stage.project_lock(project):
        pass
    print(f'PASS {fault or "install"}')


def exercise_scratch(root, failed):
    project, _, _, _, _, _ = setup(root)
    job = root / 'job'
    job.mkdir()
    export = root / 'export'
    snapshots = []

    def run_check(command, log):
        snapshot = Path(command[4])
        (snapshot / (CODE + '_check.json')).write_text('{}', encoding='utf-8')

    def install(project, code, snapshot, expected, refresh, readback):
        stage.verify(snapshot, expected)
        snapshots.append(snapshot)
        if failed:
            raise RuntimeError('injected install failure')

    with patch.object(stage.tempfile, 'tempdir', str(root)), patch.object(stage, 'run_check', run_check), patch.object(stage, 'install', install):
        try:
            assert stage.install_export(export, project, CODE, 'godot', job, 'ship.json') == 0
        except RuntimeError as exc:
            assert failed and 'injected install failure' in str(exc)
        else:
            assert not failed
    assert len(snapshots) == 1 and snapshots[0].exists() == failed
    print('PASS stage 7 scratch ' + ('kept after failed install' if failed else 'removed after successful install'))


if __name__ == '__main__':
    with tempfile.TemporaryDirectory(prefix='stage7-selftest-') as temp:
        root = Path(temp)
        check_stray_maps(root / 'stray')
        for fault in (None, 'changed_checked_glb', 'stage_copy', 'backup_copy', 'backup_move',
                      'refresh', 'readback', 'changed_installed_map'):
            exercise(root / (fault or 'success'), fault)
        exercise_scratch(root / 'scratch_success', False)
        exercise_scratch(root / 'scratch_failure', True)
