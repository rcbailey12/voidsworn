"""Issues 889, 957 and 1064: image saves, per-output revisions, and runner reports.

All test files and the isolated git index stay in TEMP. No commits or pushes.
"""
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
from unittest.mock import patch
# Issue 1739: a headless Godot opening a fresh temp project imports it first; on the PC beside other lanes that took over
# 30 s, so every real Godot call here may take up to 2 minutes. A call that still runs then is stuck: its output so far
# is printed before the failure.
GODOT_TIMEOUT = 120

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
BUILD_COMMIT = '1234567890abcdef1234567890abcdef12345678'
GIT_COMMIT_DATE = '2026-11-17T22:22:04-06:00'
BUILD_INFO = {'commit': BUILD_COMMIT, 'commit_date': '2026-11-18T04:22:04Z'}
sys.path.insert(0, str(ROOT / 'tools'))
from PIL import Image, ImageChops, ImageDraw, ImageFont
from picture_provenance import (Review, check_body, digest, git, open_picture,
                                publish_report, revision, save_picture, sidecar, stamp_file,
                                text_lines, verify)


def refused(action, label):
    try:
        action()
    except (ValueError, OSError, subprocess.CalledProcessError):
        print('PASS refused ' + label)
        return
    raise AssertionError('accepted ' + label)


def review_outputs(folder, original):
    paths = [folder / 'INPUT_A.png', folder / 'INPUT_B.png']
    for path, revision in zip(paths, ('a' * 40, 'b' * 40)):
        source = dict(source_commit=revision, source_dirty=False, source_diff_sha256='', stage='sheet built')
        with patch('picture_provenance.revision', return_value=source):
            save_picture(original, path, 'sheet built')
    pictures = Review('paint proof')
    for path in paths:
        output = folder / ('OUTPUT_' + path.stem + '.png')
        pictures.save(pictures.open(path), output)
        record = verify(output)
        assert [s['picture_name'] for s in record['inputs']] == [path.name], record['inputs']
        assert record['source_commit'] == verify(path)['source_commit']
        assert record['sources'] == verify(path)['sources']
    print('PASS consecutive Review saves keep only their own input and revision')

    cached = pictures.open(paths[0]).convert('RGB').crop((0, 0, 1000, 600))
    shared_sources = pictures.take_sources()
    for name in ('REUSED_A.png', 'REUSED_B.jpg'):
        output = folder / name
        pictures.save(cached.resize((1280, 720)), output, sources=shared_sources)
        assert [s['picture_name'] for s in verify(output)['inputs']] == [paths[0].name]
        assert verify(output)['source_commit'] == 'a' * 40
    assert shared_sources and not pictures.sources
    pictures.open(paths[1])
    output = folder / 'SHARED_COMPOSITE.png'
    pictures.save(original, output, sources=shared_sources + shared_sources)
    assert [s['picture_name'] for s in verify(output)['inputs']] == [p.name for p in paths]
    assert [s['source_commit'] for s in verify(output)['sources']] == ['a' * 40, 'b' * 40]
    refused(lambda: pictures.save(original, folder / 'NO_INPUT.png'), 'save without new or explicitly reused inputs')
    pictures.open(paths[1])
    refused(lambda: pictures.save(original, folder / 'BAD_FORMAT.bmp'), 'unsupported output format')
    pictures.save(original, folder / 'RETRY.png')
    assert [s['picture_name'] for s in verify(folder / 'RETRY.png')['inputs']] == [paths[1].name]
    for path in paths:
        output = folder / ('COPY_' + path.name)
        pictures.copy(path, output)
        assert [s['picture_name'] for s in verify(output)['inputs']] == [path.name]
    print('PASS cached inputs survive reuse, composite inputs deduplicate, retries retain inputs and copies stay separate')


def publish_outputs(folder, original):
    """Run the real publisher with a different source revision for every input."""
    fixture = folder / 'publisher'
    renders, layout, repo = [fixture / name for name in ('renders', 'layout', 'repo')]
    ships = repo / 'tools/blender/build_sheets/ships'
    for directory in (renders, layout, ships):
        directory.mkdir(parents=True)
    code = 'PROVENANCE_957'
    (ships / (code + '.py')).write_text("BEAUTY = 'concept.png'\n")
    match = dict(result='PASS', slots=[dict(slot=0, weapon='ion', arc='F', shots=1,
                                          mounts=[dict(id='I1', muzzles=1)])])
    (renders / (code + '_weapon_match.json')).write_text(json.dumps(match))
    (renders / (code + '_fit.json')).write_text('{}')
    for name in ('feature_table.md', 'checks.json', 'manifest.json', 'fit_report.md', 'cells.json', 'inventory.md'):
        (layout / name).write_text('{}' if name.endswith('.json') else 'Publisher test fixture\n')

    views = ('side', 'top', 'underside', 'bow', 'stern', 'cutaway', 'threequarter')
    copies = ('sheet.jpg', 'preview.jpg', 'fit_view.jpg', 'side_by_side.jpg', 'cells.jpg')
    inputs = [layout / (name + '.png') for name in views] + [layout / name for name in copies]
    inputs += [fixture / 'overlay.jpg', repo / 'concept.png', renders / 'beauty_cam.png']
    inputs += [renders / ('weapon_' + weapon + '.png') for weapon in ('ion', 'rail')]
    revisions = {}
    for number, path in enumerate(inputs, 1):
        revision = format(number, '040x')
        revisions[path] = revision
        source = dict(source_commit=revision, source_dirty=False, source_diff_sha256='')
        with patch('picture_provenance.revision', return_value=source):
            save_picture(original, path, 'sheet built')
    result = subprocess.run([sys.executable, str(ROOT / 'tools/blender/build_sheets/publish.py'),
                             code, str(renders), str(layout), str(fixture / 'overlay.jpg'), str(repo)],
                            capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr

    expected = {name + '.jpg': [layout / (name + '.png')] for name in views}
    expected.update({name: [layout / name] for name in copies})
    expected['outline_check.jpg'] = [fixture / 'overlay.jpg']
    for name in ('beauty_vs_blockout.jpg', 'weapon_review.jpg'):
        expected[name] = [repo / 'concept.png', renders / 'beauty_cam.png']
    for weapon in ('ion', 'rail'):
        expected['weapon_' + weapon + '.jpg'] = [renders / ('weapon_' + weapon + '.png')]
    published = repo / 'docs/ship_pipeline/build_sheets' / code
    assert {path.name for path in published.glob('*.jpg')} == set(expected)
    for name, paths in expected.items():
        record = verify(published / name)
        assert [s['picture_name'] for s in record['inputs']] == [p.name for p in paths], (name, record['inputs'])
        assert [s['source_commit'] for s in record['sources']] == [revisions[p] for p in paths], (name, record['sources'])
        assert record['source_commit'] == revisions[paths[0]], (name, record['source_commit'])
    print('PASS real build-sheet publisher isolates every copy and retains both composite input revisions')


def playtest_job(build):
    tools = build / 'tools'
    (tools / 'pc').mkdir(parents=True)
    shutil.copyfile(ROOT / 'tools/picture_font.json', tools / 'picture_font.json')
    job = ROOT / 'tools/pc/jobs/g2_playtest_capture.bat'
    env = dict(os.environ, CAPTURE_TEST_PYTHON=sys.executable)

    def call(*args, **settings):
        return subprocess.run(['cmd', '/d', '/c', 'call', str(job), *args], cwd=build,
                              env=dict(env, **settings), capture_output=True, text=True, timeout=30)

    for bad_commit, bad_date in (('unknown', GIT_COMMIT_DATE), ('0' * 40, GIT_COMMIT_DATE),
                                 (BUILD_COMMIT, 'not a date')):
        result = call('prepare', bad_commit, bad_date)
        assert result.returncode != 0 and not (build / 'godot/build_info.json').exists(), result
    result = call('prepare', BUILD_COMMIT, GIT_COMMIT_DATE)
    assert result.returncode == 0, result

    # Run the Windows job with a stand-in for tmo. The Godot runs below exercise the real stamp.
    (build / 'export').mkdir()
    (build / 'export/Voidsworn.console.exe').touch()
    (tools / 'pc/tmo.bat').write_bytes(
        b'@echo off\r\n"%CAPTURE_TEST_PYTHON%" "%~dp0capture_fixture.py" %*\r\nexit /b %ERRORLEVEL%\r\n')
    (tools / 'pc/capture_fixture.py').write_text('''import os
from pathlib import Path
import sys

args = sys.argv
mode = os.environ.get('CAPTURE_TEST_MODE')
if '--title-shot' in args:
    shot = Path(args[args.index('--title-shot') + 1])
    if 'credits' in shot.name:
        assert args[args.index('--title-open') + 1] == 'credits'
        if mode == 'exit':
            sys.exit(7)
else:
    folder = Path(args[args.index('--ui-shots') + 1])
    assert folder == Path(args[args.index('--shots') + 1])
    (folder / 'ui_check.txt').touch()
    shot = folder / '01_1_battle_start.png'
shot.touch()
if mode != 'missing' or 'credits' not in shot.name:
    Path(str(shot) + '.provenance.json').touch()
''')
    for mode, expected in (('success', 0), ('exit', 1), ('missing', 1)):
        shots = build / ('shots ' + mode)
        result = call('capture', str(shots), CAPTURE_TEST_MODE=mode)
        report = (shots / 'result.txt').read_text()
        for name in ('title 3840x2160', 'title 1920x1080', 'battle 3840x2160', 'battle 1920x1080'):
            assert name + ' exit 0' in report, report
        credits_code = 7 if mode == 'exit' else 0
        assert f'credits 1920x1080 exit {credits_code}' in report, report
        assert result.returncode == expected, (result, report)
        if mode == 'missing':
            assert 'FAIL: missing picture or provenance sidecar' in report, report
    result = call('capture', str(build / 'shots success'))
    assert result.returncode == 1, result
    assert 'use a fresh shots folder' in (build / 'shots success/result.txt').read_text()
    print('PASS Windows playtest prepare and five capture exit checks, including missing and stale evidence')


# The scene the native Godot check runs. Issue 1739: it called save_jpg(image, path) after issue 1567 made quality and stage
# required, so Godot failed to parse it and sat idle until the timeout, and only on Windows, where the check runs. The
# stage sweep below now reads this text too, on every host.
NATIVE_TEST_GD = '''extends Node
func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    var out := args[0]
    var stamp := preload("res://tools/picture_provenance.gd")
    if args.size() > 1 and args[1] == "moments":
        var strip := Image.create(1920, 216, false, Image.FORMAT_RGB8)
        strip.fill(Color("#203044"))
        strip.fill_rect(Rect2i(0, 150, 384, 66), Color("#d38c45"))
        var err := stamp.save_png(strip, out.path_join("MOMENT_1849__c170.png"), stamp.capture_stage(), true)
        get_tree().quit(0 if err == OK else 1)
        return
    var image := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
    image.fill(Color(0.1, 0.2, 0.3, 0.0))
    image.fill_rect(Rect2i(300, 260, 660, 250), Color("#d38c45"))
    # Artoo on PR 1757: a failed save ends Godot at once with its error, never an idle wait for the timeout
    var err := stamp.save_png(image, out.path_join("NATIVE_889.png"), "paint proof")
    if err != OK:
        printerr("native fixture: save_png failed, error ", err)
        get_tree().quit(1)
        return
    err = stamp.save_jpg(image, out.path_join("NATIVE_889.jpg"), 0.9, "paint proof")
    if err != OK:
        printerr("native fixture: save_jpg failed, error ", err)
        get_tree().quit(1)
        return
    get_tree().quit(0)
'''


def native_outputs(folder, godot):
    build = folder / 'archive build'
    project = build / 'godot'
    (project / 'tools').mkdir(parents=True)
    (project / 'project.godot').write_text('''[application]
config/name="Picture stamp self-test"
run/main_scene="res://test.tscn"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    shutil.copyfile(ROOT / 'godot/tools/picture_provenance.gd', project / 'tools/picture_provenance.gd')
    # Issue 1739: the stamp preloads every script it names (render/placeholder_guard.gd since PR 1600); copy them all,
    # or the fixture fails to compile and Godot idles
    for dep in re.findall(r'preload\("res://([^"]+\.gd)"\)', (ROOT / 'godot/tools/picture_provenance.gd').read_text(encoding='utf-8')):
        (project / dep).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / 'godot' / dep, project / dep)
    shutil.copyfile(ROOT / 'godot/export_presets.cfg', project / 'export_presets.cfg')
    (project / 'test.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://test.gd" id="1"]
[node name="PictureStampTest" type="Node"]
script = ExtResource("1")
''')
    (project / 'test.gd').write_text(NATIVE_TEST_GD)
    env = dict(os.environ)
    for key in ('PICTURE_SOURCE_REPO', 'PICTURE_STAMP_TOOL', 'PICTURE_PYTHON'):
        env.pop(key, None)

    def invoke(command, name, settings, expected=0, moments=False):
        out = folder / name
        out.mkdir()
        try:
            # --quit-after: a fixture that never reaches its own quit (a compile error) ends in seconds, not at the timeout
            args = ['moments'] if moments else []
            result = subprocess.run([*command, '--quit-after', '3000', '--', str(out), *args], cwd=build, env=settings,
                                    capture_output=True, text=True, timeout=GODOT_TIMEOUT)
        except subprocess.TimeoutExpired as stuck:
            def text(v):
                return v.decode('utf-8', 'replace') if isinstance(v, bytes) else (v or '')
            print('Godot did not exit within %d s for %r; its output so far:\n%s%s' % (
                GODOT_TIMEOUT, name, text(stuck.stdout), text(stuck.stderr)))
            raise
        log = result.stdout + result.stderr
        assert result.returncode == expected and 'SCRIPT ERROR' not in log, log
        if expected:
            assert 'Picture provenance unavailable: no Git checkout context or valid res://build_info.json' in log, log
            assert not list(out.iterdir())
            return
        if moments:
            return out / 'MOMENT_1849__c170.png'
        records = [verify(out / ('NATIVE_889.' + ext)) for ext in ('png', 'jpg')]
        assert open_picture(out / 'NATIVE_889.png').getpixel((0, 719))[3] == 0
        return records

    editor = [godot, '--headless', '--path', str(project)]
    invoke(editor, 'no build info', env, expected=1)
    info = project / 'build_info.json'
    for label, fields in (('unknown build commit', {'commit': '1234567'}),
                          ('invalid commit date', {'commit_date': '2026-02-31T04:22:04Z'})):
        info.write_text(json.dumps(dict(BUILD_INFO, **fields)))
        invoke(editor, label, env, expected=1)
    info.rename(project / 'rejected_build_info.txt')
    if os.name == 'nt':
        playtest_job(build)
    else:
        info.write_text(json.dumps(BUILD_INFO))
        shutil.copyfile(ROOT / 'tools/picture_font.json', project / 'tools/picture_font.json')
    assert json.loads(info.read_text()) == BUILD_INFO
    assert not (build / '.git').exists() and not (build / 'tools/picture_provenance.py').exists()

    checkout_env = dict(env, PICTURE_PYTHON=sys.executable, PICTURE_SOURCE_REPO=str(ROOT),
                        PICTURE_STAMP_TOOL=str(ROOT / 'tools/picture_provenance.py'))
    checkout_records = invoke(editor, 'checkout captures', checkout_env)
    for record in checkout_records:
        assert {key: record[key] for key in revision(str(ROOT))} == revision(str(ROOT))
        assert 'source_commit_date' not in record['sources'][0]
        assert text_lines(record)[1].startswith(record['source_commit'][:12] +
                                                (' + working ' if record['source_dirty'] else ' | '))
    print('PASS checkout stamp keeps its Git revision, working tree state and shared font')

    # Reuse existing commits in an isolated, sparse checkout. The job checkout and its refs stay untouched.
    bench = folder / 'bench checkout'
    git(ROOT, 'clone', '--shared', '--no-checkout', '--quiet', str(ROOT), str(bench))
    git(bench, 'sparse-checkout', 'set', '--no-cone', '/__no_picture_fixture_files__')
    git(bench, 'checkout', '--quiet', '--detach', 'HEAD')
    head = git(bench, 'rev-parse', 'HEAD').decode().strip()
    main_ref = 'refs/remotes/origin/main'
    git(bench, 'update-ref', '-d', main_ref)
    parent = subprocess.run(['git', '-C', str(bench), 'rev-parse', '--verify', 'HEAD^'], capture_output=True, text=True)
    if parent.returncode == 0:
        git(bench, 'update-ref', main_ref, parent.stdout.strip())
    # A shallow fixture exercises the missing-main fallback instead.
    bench_env = dict(checkout_env, PICTURE_SOURCE_REPO=str(bench))
    expected_pixels = Image.new('RGB', (1920, 216), '#203044')
    expected_pixels.paste('#d38c45', (0, 150, 384, 216))
    for label, stage in (('pre-merge', 'pre-merge capture'), ('on main', 'installed in game')):
        if label == 'on main':
            git(bench, 'update-ref', main_ref, head)
        path = invoke(editor, 'moments ' + label, bench_env, moments=True)
        record = verify(path)
        assert record.keys() == checkout_records[0].keys(), record.keys()
        assert record['stage'] == record['sources'][0]['stage'] == stage, record['stage']
        assert record['source_commit'] == head, record['source_commit']
        assert record['stamp_box'][1] == 216, record['stamp_box']
        with Image.open(path) as stamped:
            assert stamped.size == (1920, record['stamp_box'][3]) and stamped.height > 216, stamped.size
            assert ImageChops.difference(stamped.crop((0, 0, 1920, 216)).convert('RGB'), expected_pixels).getbbox() is None
    print('PASS headless moments stamp distinguishes pre-merge and main, preserves all cell pixels, and keeps schema 1')

    # Issue 2025 (Artoo 7123643915): the commit is on main here, but the working tree is dirty, so it is never "installed in game"
    (bench / 'dirty_fixture.py').write_text('# a source edit that main does not have\n')
    record = verify(invoke(editor, 'moments dirty on main', bench_env, moments=True))
    assert record['source_dirty'] and record['source_commit'] == head, record
    assert record['stage'] == record['sources'][0]['stage'] == 'pre-merge capture', record['stage']
    (bench / 'dirty_fixture.py').unlink()
    print('PASS a dirty source on main is stamped pre-merge capture, never installed in game')

    def check_build(records):
        for record in records:
            for source in [record, *record['sources']]:
                assert source['source_commit'] == BUILD_COMMIT and source['source_commit_date'] == BUILD_INFO['commit_date']
                assert not source['source_dirty'] and source['source_diff_sha256'] == ''
            assert text_lines(record)[1] == 'built from ' + BUILD_COMMIT[:12] + ' | ' + record['sources'][0]['stage']

    check_build(invoke(editor, 'archive captures', dict(env, PICTURE_PYTHON='missing-python')))
    # Artoo on PR 1757: a save that fails (the output folder is a file here) ends Godot at once and non-zero
    blocked = folder / 'blocked output'
    blocked.write_text('a file where the output folder should be')
    started = time.monotonic()
    result = subprocess.run([*editor, '--quit-after', '3000', '--', str(blocked)], cwd=build, env=dict(env, PICTURE_PYTHON='missing-python'),
                            capture_output=True, text=True, timeout=GODOT_TIMEOUT)
    log = result.stdout + result.stderr
    assert result.returncode != 0 and ('native fixture: save_png failed' in log or 'Picture stamp FAILED' in log), log
    assert time.monotonic() - started < 60, 'a failed save waited %.0f s' % (time.monotonic() - started)
    print('PASS a failed native save exits non-zero at once')
    review = Review('paint proof')
    image = review.open(folder / 'archive captures/NATIVE_889.jpg')
    sheet = folder / 'BUILD_REVIEW.png'
    review.save(image, sheet)
    record = verify(sheet)
    check_build([record])
    assert record['inputs'][0]['source_commit_date'] == BUILD_INFO['commit_date']
    print('PASS non-Git Godot PNG/JPEG stamps verify with full build commit and date; missing/unknown commit exits 1')

    template = Path(env.get('APPDATA', '')) / 'Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe'
    if os.name == 'nt' and template.is_file():
        exe = build / 'export' / 'StampFixture.exe'
        for args in (['--import'], ['--export-release', 'Windows Desktop', str(exe)]):
            result = subprocess.run([*editor, *args], env=env, capture_output=True, text=True, timeout=GODOT_TIMEOUT)
            assert result.returncode == 0, result.stdout + result.stderr
        # Give the packed game a valid checkout override to prove it uses its baked-in commit.
        exported = [str(exe.with_suffix('.console.exe')), '--headless']
        check_build(invoke(exported, 'packed captures', checkout_env))
        pack = exe.with_suffix('.pck')
        good_pack = pack.rename(exe.with_name('known-commit.pck'))
        info.rename(project / 'fixture_build_info.txt')
        for kind in ('missing', 'unknown'):
            if kind == 'unknown':
                info.write_text(json.dumps(dict(BUILD_INFO, commit='unknown')))
            result = subprocess.run([*editor, '--export-pack', 'Windows Desktop', str(pack)],
                                    env=env, capture_output=True, text=True, timeout=GODOT_TIMEOUT)
            assert result.returncode == 0, result.stdout + result.stderr
            invoke(exported, 'packed commit ' + kind, checkout_env, expected=1)
            pack.rename(exe.with_name(kind + '-commit.pck'))
        good_pack.rename(pack)
        print('PASS headless Windows fixture exe stamps the packed commit and refuses missing or unknown revisions')


def checkout_picture_links(repo, out, picture):
    report = out / 'last.md'
    destination = 'docs/shots/issue-1064'
    expected = picture.relative_to(repo).as_posix()
    env = dict(os.environ, PICTURE_PYTHON=sys.executable)
    if os.name == 'nt':
        command = ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                   str(ROOT / 'tools/pc/review_evidence.ps1'), 'prepare', str(repo), str(out), destination]
    else:
        command = [sys.executable, str(ROOT / 'tools/picture_provenance.py'), 'publish-report',
                   str(out), '--repo', str(repo), '--destination', destination]

    def prepare(body):
        report.write_text(body, encoding='utf-8')
        return subprocess.run(command, env=env, capture_output=True, text=True, timeout=30)

    spellings = [picture.as_posix()]
    if os.name == 'nt':
        spellings.append(str(picture).swapcase())
    for absolute in spellings:
        result = prepare(f'[Picture](<{absolute}>)')
        assert result.returncode == 0, result.stdout + result.stderr
        assert f'Rewrote picture link: {absolute} -> {expected}' in result.stdout.splitlines(), result.stdout
        body = report.read_text(encoding='utf-8')
        assert body == f'[Picture](<{expected}>)', body
        check_body(repo, body, staged=True)
    assert not (repo / destination).exists()
    print('PASS checkout picture links are rewritten, logged, and accepted with the staged pair')

    outside = repo.with_name('repo-other') / picture.name
    outside.parent.mkdir()
    shutil.copyfile(picture, outside)
    shutil.copyfile(sidecar(picture), sidecar(outside))
    for target in (outside.as_posix(), picture.as_uri(), 'https://example.com/a.png', r'\\host\share\a.png'):
        body = f'[Picture](<{target}>)'
        result = prepare(body)
        assert result.returncode == 1, result.stdout + result.stderr
        assert 'use a relative repo picture link' in result.stderr, result.stderr
        assert report.read_text(encoding='utf-8') == body
    print('PASS prepare refuses outside checkout paths, file URLs, web URLs and UNC paths')


def make_folder():
    # Issue 1535: a plain mkdir, never tempfile.mkdtemp. Python 3.12.4+ on Windows gives a mkdtemp folder a private ACL
    # (mode 0o700), protected from inheritance, and the cleanup of the job's voidsworn-run TEMP could not remove it
    # (cleanup 4, Nov 21: 31 folders, about 49 GB; proof board/pc-out-1535: a non-elevated job's stock mkdtemp folder
    # is protected too, so elevation is not needed for this).
    base = Path(tempfile.gettempdir())
    for _ in range(100):
        folder = base / ('picture889-' + os.urandom(8).hex())
        try:
            folder.mkdir()
            return folder
        except FileExistsError:
            continue
    raise FileExistsError('no free picture889 folder name in ' + str(base))


def remove_folder(folder):
    # Our own folder only, after a PASS. Git leaves read-only object files, so clear that flag and try again; a link is
    # removed as a link, never followed.
    def again(func, path, _info):
        os.chmod(path, 0o700 if os.path.isdir(path) and not os.path.islink(path) else 0o600)
        func(path)
    if sys.version_info >= (3, 12):
        shutil.rmtree(folder, onexc=again)
    else:
        shutil.rmtree(folder, onerror=again)


def run():
    folder = make_folder()
    try:
        checks(folder)
    except BaseException:
        print('FAIL picture provenance self-test; artifacts kept for diagnosis in ' + str(folder))
        raise
    remove_folder(folder)
    print('PASS picture provenance self-test; its own folder removed: ' + str(folder))


def _call_args(text, start):
    # the top-level arguments of a call whose "(" ends at start, strings and brackets kept whole
    depth, cur, out, quote, i = 0, '', [], None, start
    while i < len(text):
        c = text[i]
        if quote:
            cur += c
            if c == '\\' and i + 1 < len(text):
                cur += text[i + 1]; i += 2; continue
            if c == quote:
                quote = None
        elif c in '"\'':
            quote = c; cur += c
        elif c in '([{':
            depth += 1; cur += c
        elif c in ')]}':
            if depth == 0:
                out.append(cur.strip())
                return [a for a in out if a]
            depth -= 1; cur += c
        elif c == ',' and depth == 0:
            out.append(cur.strip()); cur = ''
        else:
            cur += c
        i += 1
    return [a for a in out if a]


# Issue 1567: save_png(image, path, stage) and save_jpg(image, path, quality, stage) have no default stage, so every call
# names one. GDScript under godot/ fails to load without it; this also covers the scripts kept beside build sheets.
def stage_unnamed_saves():
    missing = []
    files = subprocess.run(['git', '-C', str(ROOT), 'grep', '-l', 'picture_provenance.gd', '--', '*.gd'],
                           capture_output=True, text=True, check=True).stdout.split()
    for rel in files:
        if rel == 'godot/tools/picture_provenance.gd' or rel.startswith('docs/archive/'):
            continue
        missing += [rel + ':' + str(n) for n in unnamed_saves_in(ROOT.joinpath(rel).read_text(encoding='utf-8-sig'))]
    missing += ['NATIVE_TEST_GD:' + str(n) for n in unnamed_saves_in(NATIVE_TEST_GD)]
    return missing


def unnamed_saves_in(text):
    # line numbers of shared writer calls in this GDScript text that do not pass every required argument
    found = []
    aliases = re.findall(r'(?:const|var)\s+([A-Za-z_]\w*)\s*:?=?\s*(?:pre)?load\("res://tools/picture_provenance\.gd"\)', text)
    receiver = r'(?:(?:pre)?load\("res://tools/picture_provenance\.gd"\)' + ''.join('|' + re.escape(a) + r'\b' for a in aliases) + ')'
    for m in re.finditer(receiver + r'\s*\.\s*save_(png|jpg)\s*\(', text):
        if len(_call_args(text, m.end())) < (3 if m.group(1) == 'png' else 4):
            found.append(text.count('\n', 0, m.start()) + 1)
    return found


def checks(folder):
    repo, out = folder / 'repo', folder / 'out'
    repo.mkdir(); (out / 'shots').mkdir(parents=True)
    subprocess.run(['git', 'init', '-q', str(repo)], check=True)
    subprocess.run(['git', '-C', str(repo), 'config', 'core.autocrlf', 'false'], check=True)
    unstamped_saves = []
    exceptions = {'godot/tools/picture_provenance.gd', 'godot/world/world_bake.gd', 'godot/main/test_loading.gd'}
    captures = list((ROOT / 'godot').rglob('*.gd')) + list((ROOT / 'tools').rglob('*.gd')) + list((ROOT / 'contrib/opus/tools').glob('*.gd'))
    for path in captures:
        if path.relative_to(ROOT).as_posix() in exceptions:
            continue  # Shared writer, game texture cache, and byte-for-byte loader fixture.
        for number, line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(), 1):
            if re.search(r'\.save_(png|jpg)\(', line) and 'picture_provenance.gd' not in line:
                if path.name == 'station_check.gd' and '_mask.png' in line:
                    continue  # Numeric silhouette mask, never a review picture.
                if path.relative_to(ROOT).as_posix() == 'godot/ui/battle/icons/make_silhouettes.gd' and '.save_png(OUTPUT.path_join(code + ".png"))' in line:
                    continue  # The in-game alpha mask. The labelled review sheet is stamped below it.
                if path.relative_to(ROOT).as_posix() == 'godot/world/test/planet_v2_check.gd' and '.save_png(fdir.path_join(fk + ".png"))' in line:
                    continue  # Flat dummy maps seeded into a test bake cache (issue 1765), never a review picture.
                unstamped_saves.append(str(path.relative_to(ROOT)) + ':' + str(number))
    assert not unstamped_saves, 'capture saves bypass the shared stamp: ' + ', '.join(unstamped_saves)
    print('PASS capture save sweep: game, probes, recipe previews and tool captures use the shared writer')
    unnamed = stage_unnamed_saves()
    assert not unnamed, 'shared writer calls that do not name their stage (issue 1567): ' + ', '.join(unnamed)
    print('PASS stage sweep: every shared writer call names its stage (no default claims installed in game)')
    original = Image.new('RGBA', (1280, 720), (15, 28, 44, 255))
    review_outputs(folder, original)
    publish_outputs(folder, original)
    draw = ImageDraw.Draw(original)
    draw.text((48, 40), 'PROVENANCE_889 / picture label self-test', font=ImageFont.load_default(size=32), fill='white')
    draw.text((48, 105), 'Synthetic test image. The corner strip is written by the picture tool.', font=ImageFont.load_default(size=24), fill='#c4ccd8')
    draw.rounded_rectangle((300, 230, 960, 510), radius=30, fill='#d38c45')
    draw.text((350, 340), 'Revision + stage + UTC date', font=ImageFont.load_default(size=26), fill='#10151e')
    original.putpixel((0, 719), (15, 28, 44, 0))
    shot = out / 'shots' / 'PROVENANCE_889.png'
    original.save(shot)
    stamp_file(shot, 'paint proof', ROOT)
    record = verify(shot)
    assert record['source_commit'] == git(ROOT, 'rev-parse', 'HEAD').decode().strip()
    assert open_picture(shot).tobytes() == original.tobytes()
    assert Image.open(shot).size == (1280, 720)
    assert Image.open(shot).tobytes() != original.tobytes()
    print('PASS PNG has a visible stamp, full revision, UTC date, and exact restored alpha/pixels')

    for ext in ('jpg', 'webp', 'gif'):
        path = folder / ('PROVENANCE_889.' + ext)
        options = {'quality': 90} if ext in ('jpg', 'webp') else {}
        if ext == 'gif':
            other = original.copy(); ImageDraw.Draw(other).rectangle((400, 300, 800, 450), fill='white')
            options.update(append_images=[other], duration=100, loop=0)
        save_picture(original, path, 'installed in game', repo=ROOT, **options)
        verify(path)
    print('PASS JPEG, WebP and every animated GIF frame carry verifiable strips')

    # A compositor run at today's checkout must retain yesterday's source.
    old = dict(source_commit='a' * 40, source_dirty=False, source_diff_sha256='', stage='sheet built')
    old_path = folder / 'BEFORE.png'
    save_picture(original, old_path, 'sheet built', sources=[dict(record, **old, sources=[old])])
    pictures = Review('paint proof')
    pictures.open(old_path); pictures.open(shot)
    composite = folder / 'BEFORE_AFTER.jpg'
    pictures.save(original, composite, quality=95)
    assert [s['source_commit'] for s in verify(composite)['sources']] == ['a' * 40, record['source_commit']]
    assert stamp_file(old_path, 'paint proof', ROOT)['source_commit'] == 'a' * 40
    print('PASS composites preserve both input revisions and cached pictures are never relabelled')

    # Run the real look-bench compositor. Different labels must not create a
    # false visual difference, and both source revisions must reach its sheets.
    for name, before in (('before', True), ('after', False)):
        run_dir = folder / name; (run_dir / 'moments').mkdir(parents=True)
        source = run_dir / 'moments' / 'PROVENANCE_889__c170.png'
        frame = Image.new('RGB', (400, 240), '#203044')
        source_record = dict(record, **old, sources=[dict(old, stage='installed in game')]) if before else None
        stage = 'installed in game' if before else 'pre-merge capture'
        save_picture(frame, source, stage, sources=[source_record] if before else None, repo=ROOT)
        (run_dir / 'bench.json').write_text(json.dumps({'commit': 'a' * 40 if before else record['source_commit'],
            'stills': [{'part': 'moments', 'id': 'PROVENANCE_889', 'cam': 170,
                        'file': 'moments/PROVENANCE_889__c170.png', 'cells': [{'t': 0}]}]}))
        (run_dir / 'moments.json').write_text(json.dumps({'cell': [400, 240],
            'rows': [{'id': 'PROVENANCE_889', 'label': 'Label self-test', 'group': 'provenance', 'key': 0}]}))
        bench = json.loads((run_dir / 'bench.json').read_text())
        moments = json.loads((run_dir / 'moments.json').read_text())
        for part, identity, digit in (('moments', 'OTHER_889', 'c' if before else 'd'),
                                      ('fleet', 'quiet', 'e' if before else 'f'),
                                      ('fleet', 'storm', '1' if before else '2')):
            name = identity + '.png'
            source_revision = dict(source_commit=digit * 40, source_dirty=False, source_diff_sha256='')
            with patch('picture_provenance.revision', return_value=source_revision):
                save_picture(frame, run_dir / name, stage if identity == 'storm' else 'installed in game')
            still = dict(part=part, id=identity, cam=170, file=name, cells=[{'t': 0}])
            if part == 'fleet':
                still.update(sky=identity, code='PROVENANCE_889')
            else:
                moments['rows'].append(dict(id=identity, label='Independent input', group='other', key=0))
            bench['stills'].append(still)
        (run_dir / 'bench.json').write_text(json.dumps(bench))
        (run_dir / 'moments.json').write_text(json.dumps(moments))
    sheets = folder / 'sheets'
    result = subprocess.run([sys.executable, str(ROOT / 'tools/pc/jobs/look_bench_sheets.py'),
                             '--after', str(folder / 'after'), '--before', str(folder / 'before'), '--out', str(sheets)],
                            capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr
    assert json.loads((sheets / 'diffs.json').read_text())['stills'][0]['diff'] == 0
    assert len(verify(sheets / 'moments/PROVENANCE_889.jpg')['sources']) == 2
    pre_merge_sheets = {'moments/PROVENANCE_889.jpg', 'moments_overview_provenance.jpg', 'fleet_storm.jpg'}
    for name, inputs, commits in (
            ('moments/PROVENANCE_889.jpg', {'PROVENANCE_889__c170.png'}, {'a' * 40, record['source_commit']}),
            ('moments_overview_provenance.jpg', {'PROVENANCE_889__c170.png'}, {'a' * 40, record['source_commit']}),
            ('moments/OTHER_889.jpg', {'OTHER_889.png'}, {'c' * 40, 'd' * 40}),
            ('moments_overview_other.jpg', {'OTHER_889.png'}, {'c' * 40, 'd' * 40}),
            ('fleet_quiet.jpg', {'quiet.png'}, {'e' * 40, 'f' * 40}),
            ('fleet_storm.jpg', {'storm.png'}, {'1' * 40, '2' * 40})):
        output = verify(sheets / name)
        assert {s['picture_name'] for s in output['inputs']} == inputs, (name, output['inputs'])
        assert {s['source_commit'] for s in output['sources']} == commits, (name, output['sources'])
        expected_stage = 'pre-merge capture' if name in pre_merge_sheets else 'installed in game'
        assert output['stage'] == expected_stage, (name, output['stage'])
    print('PASS real look-bench moments, overviews and fleet skies isolate inputs while retaining reused captures')
    print('PASS real look-bench sheets retain both revisions and compare original pixels with zero label noise')

    raw = folder / 'UNSTAMPED.png'; original.save(raw)
    refused(lambda: Review('sheet built').open(raw), 'unstamped sheet input')
    refused(lambda: check_body(repo, '[picture](../UNSTAMPED.png)', tracked=False), 'unstamped PR picture')
    refused(lambda: check_body(repo, '[picture](C:/shots/PROVENANCE_889.png)'), 'PC picture link')
    refused(lambda: check_body(repo, '![picture](file:///C:/shots/a.png)'), 'file URL')
    refused(lambda: check_body(repo, '<img src="https://example.com/a.png">'), 'web picture link')
    refused(lambda: check_body(repo, '[picture][proof]\n[proof]: C:/shots/a.png'), 'reference-style PC link')
    (out / 'last.md').write_text('[Picture](<' + str(shot) + '>)', encoding='utf-8')
    publish_report(repo, out, 'docs/shots/issue-889')
    body = (out / 'last.md').read_text(encoding='utf-8')
    assert 'docs/shots/issue-889/PROVENANCE_889.png' in body and str(out) not in body
    refused(lambda: check_body(repo, body, staged=True), 'uncommitted picture/sidecar')
    subprocess.run(['git', '-C', str(repo), 'add', '.'], check=True)
    check_body(repo, body, staged=True)
    print('PASS runner copies stamped evidence, rewrites PC links, and checks the staged pair')
    dest = repo / 'docs/shots/issue-889/PROVENANCE_889.png'
    if os.name == 'nt':
        # The fixture repo has no tools: use the real helper through a copied tool folder.
        (repo / 'tools').mkdir()
        for name in ('picture_provenance.py', 'picture_font.json'):
            shutil.copyfile(ROOT / 'tools' / name, repo / 'tools' / name)
    checkout_picture_links(repo, out, dest)

    ImageDraw.Draw(original).rectangle((0, 600, 1000, 720), fill='red')
    original.save(dest)
    refused(lambda: check_body(repo, body, staged=True), 'modified or removed strip')
    shutil.copyfile(shot, dest)
    metadata = json.loads(sidecar(dest).read_text())
    metadata['stage'] = 'installed in game'
    sidecar(dest).write_text(json.dumps(metadata))
    refused(lambda: check_body(repo, body, staged=True), 'sidecar stage disagrees with burned text')

    # Exercise the same PowerShell entry used by both PC runners.
    if os.name == 'nt':
        env = dict(os.environ, PICTURE_PYTHON=sys.executable)
        body_path = folder / 'body.md'; body_path.write_text(body)
        result = subprocess.run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                                 str(ROOT / 'tools/pc/review_evidence.ps1'), 'check', str(repo), str(body_path)],
                                env=env, capture_output=True, text=True)
        assert result.returncode != 0, result.stdout + result.stderr
        shutil.copyfile(sidecar(shot), sidecar(dest))
        result = subprocess.run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                                 str(ROOT / 'tools/pc/review_evidence.ps1'), 'check', str(repo), str(body_path)],
                                env=env, capture_output=True, text=True)
        assert result.returncode == 0, result.stdout + result.stderr
        print('PASS actual PowerShell PR body entry refuses bad evidence and accepts the staged pair')

    # CPU-only image saves exercise the native checkout and playtest stamps.
    godot = os.environ.get('GODOT')
    if not godot and os.name == 'nt':
        candidate = Path.home() / 'Downloads/voidsworn_test/godot/Godot_v4.7.2-stable_win64_console.exe'
        if candidate.exists(): godot = str(candidate)
    if godot:
        native_outputs(folder, godot)
    else:
        print('Godot native save check unavailable on this host; Python and runner refusal checks ran')


if __name__ == '__main__':
    run()
