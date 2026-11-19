"""Exercise fixture binding and the paired bake writer without launching Blender."""
import contextlib
import gzip
import io
from pathlib import Path
import tempfile
from unittest.mock import patch

import sheet_fixture_hash as fixture


def rejected(message):
    try:
        fixture.check()
    except (OSError, ValueError):
        return
    raise AssertionError(message)


def main():
    work = Path(tempfile.mkdtemp(prefix='fixture-selftest-'))
    output = work / 'fixture.gz'
    metadata = work / 'fixture.sheet.txt'
    fixture_input = work / 'variants.py'
    fixture_input.write_text('variant input', encoding='utf-8')
    calls = []

    def fake_blender(command, **kwargs):
        args = command[command.index('--') + 1:]
        calls.append(args)
        if len(calls) == 2:
            export = Path(args[1])
            export.mkdir()
            (export / 'C19_51.glb').write_bytes(b'glTF baked fixture')
            (export / 'export_status.txt').write_text('WRITTEN C19_51', encoding='utf-8')

    assert 'tools/blender/build_sheets/variants.py' in fixture.FILES
    with patch.multiple(fixture, OUT=metadata, FIXTURE=output, FILES=(str(fixture_input),)), \
            patch.object(fixture.subprocess, 'run', fake_blender):
        rejected('a missing fixture passed')
        fixture.bake('fake Blender')
        assert len(calls) == 2
        assert gzip.decompress(output.read_bytes()) == b'glTF baked fixture'
        bound_bytes = output.read_bytes()
        bound_record = metadata.read_bytes()
        output.write_bytes(gzip.compress(b'glTF replacement'))
        rejected('different fixture bytes passed')
        output.write_bytes(bound_bytes)
        fixture_input.write_text('changed variant input', encoding='utf-8')
        rejected('a changed geometry input passed')
        try:
            with patch.object(fixture.sys, 'argv', ['sheet_fixture_hash.py']), contextlib.redirect_stderr(io.StringIO()):
                fixture.main()
        except SystemExit as exc:
            assert exc.code == 2
        else:
            raise AssertionError('a standalone record refresh was accepted')
        assert metadata.read_bytes() == bound_record
    print('PASS fixture bake writes a bound pair and stale inputs or bytes fail')

    # Issue 1174: --bake --out DIR writes a fresh bound pair into DIR and never touches the committed pair; --check
    # --quiet-stale exits 3 (rebake) for a stale record, 1 for anything else.
    calls.clear()
    dest = work / 'fresh'
    with patch.multiple(fixture, OUT=metadata, FIXTURE=output, FILES=(str(fixture_input),)), \
            patch.object(fixture.subprocess, 'run', fake_blender):
        before = (output.read_bytes(), metadata.read_bytes())
        with patch.object(fixture.sys, 'argv', ['sheet_fixture_hash.py', '--check', '--quiet-stale']), \
                contextlib.redirect_stdout(io.StringIO()):
            assert fixture.main() == 3, 'a stale record did not exit 3 under --quiet-stale'
        with patch.object(fixture.sys, 'argv', ['sheet_fixture_hash.py', '--check']), \
                contextlib.redirect_stdout(io.StringIO()):
            assert fixture.main() == 1, 'a stale record did not fail plain --check'
        with patch.object(fixture.sys, 'argv', ['sheet_fixture_hash.py', '--bake', 'fake Blender', '--out', str(dest)]), \
                contextlib.redirect_stdout(io.StringIO()):
            assert fixture.main() == 0
        assert (output.read_bytes(), metadata.read_bytes()) == before, '--out wrote over the committed pair'
        assert gzip.decompress((dest / output.name).read_bytes()) == b'glTF baked fixture'
        fixture.check(dest / metadata.name, dest / output.name)
        output.unlink()
        with patch.object(fixture.sys, 'argv', ['sheet_fixture_hash.py', '--check', '--quiet-stale']), \
                contextlib.redirect_stdout(io.StringIO()):
            assert fixture.main() == 1, 'a missing fixture exited as merely stale'
    print('PASS --bake --out writes a fresh pair beside, --quiet-stale exits 3 only for a stale record')


if __name__ == '__main__':
    main()
