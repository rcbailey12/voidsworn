"""Issue 889: real image saves, inherited revisions, and runner PR refusals.

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

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from PIL import Image, ImageDraw, ImageFont
from picture_provenance import (Review, check_body, digest, git, open_picture,
                                publish_report, save_picture, sidecar, stamp_file, verify)


def refused(action, label):
    try:
        action()
    except (ValueError, OSError, subprocess.CalledProcessError):
        print('PASS refused ' + label)
        return
    raise AssertionError('accepted ' + label)


def run():
    folder = Path(tempfile.mkdtemp(prefix='picture889-'))
    # Deliberately kept for diagnosis, following the PC no-deletion rule.
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
                unstamped_saves.append(str(path.relative_to(ROOT)) + ':' + str(number))
    assert not unstamped_saves, 'capture saves bypass the shared stamp: ' + ', '.join(unstamped_saves)
    print('PASS capture save sweep: game, probes, recipe previews and tool captures use the shared writer')
    original = Image.new('RGBA', (1280, 720), (15, 28, 44, 255))
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
        save_picture(frame, source, 'installed in game', sources=[source_record] if before else None, repo=ROOT)
        (run_dir / 'bench.json').write_text(json.dumps({'commit': 'a' * 40 if before else record['source_commit'],
            'stills': [{'part': 'moments', 'id': 'PROVENANCE_889', 'cam': 170,
                        'file': 'moments/PROVENANCE_889__c170.png', 'cells': [{'t': 0}]}]}))
        (run_dir / 'moments.json').write_text(json.dumps({'cell': [400, 240],
            'rows': [{'id': 'PROVENANCE_889', 'label': 'Label self-test', 'group': 'provenance', 'key': 0}]}))
    sheets = folder / 'sheets'
    result = subprocess.run([sys.executable, str(ROOT / 'tools/pc/jobs/look_bench_sheets.py'),
                             '--after', str(folder / 'after'), '--before', str(folder / 'before'), '--out', str(sheets)],
                            capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr
    assert json.loads((sheets / 'diffs.json').read_text())['stills'][0]['diff'] == 0
    assert len(verify(sheets / 'moments/PROVENANCE_889.jpg')['sources']) == 2
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
        # The fixture repo has no tools: use the real helper through a copied tool folder.
        (repo / 'tools').mkdir()
        for name in ('picture_provenance.py', 'picture_font.json'):
            shutil.copyfile(ROOT / 'tools' / name, repo / 'tools' / name)
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

    # CPU-only Image saves exercise the native stamp, not a screenshot/GPU job.
    godot = os.environ.get('GODOT')
    if not godot and os.name == 'nt':
        candidate = Path.home() / 'Downloads/voidsworn_test/godot/Godot_v4.7.2-stable_win64_console.exe'
        if candidate.exists(): godot = str(candidate)
    if godot:
        project = folder / 'godot'; (project / 'tools').mkdir(parents=True)
        (project / 'project.godot').write_text('[application]\nconfig/name="Picture stamp self-test"\n')
        shutil.copyfile(ROOT / 'godot/tools/picture_provenance.gd', project / 'tools/picture_provenance.gd')
        (project / 'test.gd').write_text('''extends SceneTree
func _initialize() -> void:
    var image := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
    image.fill(Color(0.1, 0.2, 0.3, 0.0))
    image.fill_rect(Rect2i(300, 260, 660, 250), Color("#d38c45"))
    var stamp := preload("res://tools/picture_provenance.gd")
    if stamp.save_png(image, "res://NATIVE_889.png", "paint proof") != OK:
        quit(1)
        return
    if stamp.save_jpg(image, "res://NATIVE_889.jpg") != OK:
        quit(1)
        return
    quit(0)
''')
        env = dict(os.environ, PICTURE_PYTHON=sys.executable, PICTURE_SOURCE_REPO=str(ROOT),
                   PICTURE_STAMP_TOOL=str(ROOT / 'tools/picture_provenance.py'))
        result = subprocess.run([godot, '--headless', '--path', str(project), '--script', 'res://test.gd'],
                                env=env, capture_output=True, text=True, timeout=60)
        assert result.returncode == 0 and 'SCRIPT ERROR' not in result.stdout + result.stderr, result.stdout + result.stderr
        verify(project / 'NATIVE_889.png'); verify(project / 'NATIVE_889.jpg')
        assert open_picture(project / 'NATIVE_889.png').getpixel((0, 719))[3] == 0
        print('PASS native Godot PNG/JPEG saves match the shared font, hashes and restored alpha')
    else:
        print('Godot native save check unavailable on this host; Python and runner refusal checks ran')
    print('PASS picture provenance self-test; artifacts kept in ' + str(folder))


if __name__ == '__main__':
    run()
