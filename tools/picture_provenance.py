"""Picture labels and review evidence. Pillow is already used by the sheet tools.

New renders call stamp_file immediately after saving. Compositors use Review.open
and Review.save: input revisions survive crops, resizing and later sheet runs.
The covered pixels live in the sidecar so alpha measurements see the original.
"""
import argparse
import base64
from datetime import datetime, timezone
from functools import lru_cache
import hashlib
import io
import json
import os
import shutil
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import quote, unquote, urlsplit

if __name__ != '__main__' or sys.argv[1:2] != ['context']:
    from PIL import Image, ImageDraw, ImageSequence

PRE_MERGE_STAGE = 'pre-merge capture'
STAGES = ('sheet built', 'paint proof', 'installed in game', 'cloud direction check', PRE_MERGE_STAGE)
EXTENSIONS = {'.png', '.jpg', '.jpeg', '.webp', '.gif'}
ROOT = Path(__file__).resolve().parents[1]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def sidecar(path):
    return Path(str(path) + '.provenance.json')


def git(repo, *args, input=None):
    return subprocess.check_output(['git', '-C', str(repo), *args], stderr=subprocess.PIPE, input=input)


@lru_cache(maxsize=8)
def revision(repo):
    commit = git(repo, 'rev-parse', 'HEAD').decode().strip()
    if not re.fullmatch(r'[a-f0-9]{40,64}', commit):
        raise ValueError('picture source has no full git commit')
    changes = git(repo, 'diff', '--binary', 'HEAD')
    paths = [n for n in git(repo, 'diff', '--name-only', '-z', 'HEAD').decode().split('\0') if n]
    # Include new source files as well as tracked edits. Do not hash PC assets.
    for name in git(repo, 'ls-files', '--others', '--exclude-standard', '-z').decode().split('\0'):
        if name and name != 'CODEX_TASK.md' and Path(name).suffix in {'.py', '.gd', '.js', '.ps1', '.bat'}:
            changes += name.encode() + b'\0' + (Path(repo) / name).read_bytes()
            paths.append(name)
    # source_dirty_files (issue 1539): each file that made the tree dirty and the git blob hash of its working copy (None
    # when deleted), so a reader can match a PC ship job's own install (its ship files, its manifest row, the watchdog
    # hand-off) exactly against what the job recorded, and refuse a real source edit
    names = sorted(set(paths))
    present = [n for n in names if (Path(repo) / n).is_file()]
    # git's own hash (its line-ending filters applied), the same number ship_job.bat records for the watchdog hand-off
    blobs = git(repo, 'hash-object', '--stdin-paths', input='\n'.join(present).encode()).decode().split() if present else []
    files = dict.fromkeys(names)
    files.update(zip(present, blobs))
    return dict(source_commit=commit, source_dirty=bool(changes),
                source_diff_sha256=digest(changes) if changes else '', source_dirty_files=files)



def text_lines(record):
    lines = [record['picture_name']]
    for src in record['sources']:
        rev = src['source_commit'][:12]
        if 'source_commit_date' in src:
            rev = 'built from ' + rev
        elif src['source_dirty']:
            rev += ' + working ' + src['source_diff_sha256'][:8]
        line = rev + ' | ' + src['stage']
        if line not in lines:
            lines.append(line)
    lines.append(record['stage'] + ' | ' + record['date'])
    if 'build_sha256' in record:
        lines.extend((f"Commit {record['source_commit']}",
                      f"Build SHA-256 {record['build_sha256']}",
                      f"Manifest SHA-256 {record['manifest_sha256']}"))
    return lines


def strip_for(record, size):
    # One bitmap alphabet for Python and Godot, independent of installed fonts.
    glyphs = json.loads((Path(__file__).with_name('picture_font.json')).read_text())
    scale = 2 if size[0] >= 1000 and 'build_sha256' not in record else 1
    width = size[0] // scale
    lines = []
    for text in text_lines(record):
        while text:
            end = max(1, (width - 12) // 6)
            lines.append(text[:end])
            text = text[end:]
    height = len(lines) * 13 + 10
    if height * scale > size[1]:
        raise ValueError('picture is too small for a readable provenance strip')
    strip_width = min(width, max(len(t) * 6 for t in lines) + 12)
    strip = Image.new('RGB', (strip_width, height), '#10151e')
    draw = ImageDraw.Draw(strip)
    draw.line((0, 0, strip_width, 0), fill='#e8b56b')
    for row, text in enumerate(lines):
        for col, char in enumerate(text):
            for y, bits in enumerate(glyphs.get(char, glyphs['?'])):
                for x in range(6):
                    if bits & (1 << (5 - x)):
                        draw.point((6 + col * 6 + x, 4 + row * 13 + y), fill='#f1e8d9')
    return strip.resize((strip.width * scale, height * scale), Image.Resampling.NEAREST)


def summary(record):
    keys = ('picture_name', 'source_commit', 'source_dirty', 'source_diff_sha256',
            'stage', 'date', 'image_sha256', 'sources')
    result = {k: record[k] for k in keys}
    if 'source_commit_date' in record:
        result['source_commit_date'] = record['source_commit_date']
    return result


def ffmpeg_executable():
    command = os.environ.get('FFMPEG') or shutil.which('ffmpeg')
    if command:
        return command
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def _verify_clip(path, record):
    from PIL import ImageChops, ImageStat
    template = strip_for(record, (1280, 720))
    if digest(template.tobytes()) != record['stamp_template_sha256']:
        raise ValueError('the clip stamp differs from its provenance: ' + str(path))
    letters = template.convert('L').point(lambda p: 255 if p > 180 else 0)
    crop = f'crop={template.width}:{template.height}:0:{720 - template.height}:exact=1'
    duration = float(record['duration_s'])
    if not 0 < duration < float('inf'):
        raise ValueError('invalid review clip duration: ' + str(path))
    ffmpeg = ffmpeg_executable()
    for offset in (0, duration / 2):
        pixels = subprocess.check_output([
            ffmpeg, '-loglevel', 'error', '-nostdin', '-ss', str(offset), '-i', str(path),
            '-vf', crop, '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-threads', '1', '-'
        ])
        actual = Image.frombytes('RGB', template.size, pixels)
        if max(ImageStat.Stat(ImageChops.difference(actual, template), letters).mean) > 45:
            raise ValueError('provenance text is absent from the clip: ' + str(path))


def verify(path):
    path = Path(path)
    record = json.loads(sidecar(path).read_text(encoding='utf-8'))
    if record.get('schema') != 1 or record.get('picture_name') != path.name:
        raise ValueError('wrong picture name or provenance schema: ' + str(path))
    if record.get('stage') not in STAGES:
        raise ValueError('missing or invalid picture stage: ' + str(path))
    datetime.strptime(record['date'], '%Y-%m-%dT%H:%M:%SZ')
    for src in [record] + record['sources']:
        if not re.fullmatch(r'[a-f0-9]{40,64}', src['source_commit']) or src['stage'] not in STAGES:
            raise ValueError('invalid source revision/stage: ' + str(path))
        if src['source_dirty'] and not re.fullmatch(r'[a-f0-9]{64}', src['source_diff_sha256']):
            raise ValueError('working revision lacks its digest: ' + str(path))
        if 'source_commit_date' in src:
            datetime.strptime(src['source_commit_date'], '%Y-%m-%dT%H:%M:%SZ')
            if src['source_dirty'] or src['source_diff_sha256']:
                raise ValueError('build revision has a working-tree state: ' + str(path))
    if not record['sources'] or record['image_sha256'] != digest(path.read_bytes()):
        raise ValueError('picture changed after stamping: ' + str(path))
    is_clip = path.suffix.lower() == '.mp4'
    if is_clip or 'build_sha256' in record:
        if ('source_commit_date' not in record or any(
                not re.fullmatch(r'[a-f0-9]{64}', record.get(key, ''))
                for key in ('build_sha256', 'manifest_sha256'))):
            raise ValueError('missing installed build provenance: ' + str(path))
    if is_clip:
        _verify_clip(path, record)
        return record
    with Image.open(path) as image:
        box = record['stamp_box']
        frames = [f.copy() for f in ImageSequence.Iterator(image)]
        if len(frames) != len(record['strip_sha256']):
            raise ValueError('picture frame count changed: ' + str(path))
        for frame, expected in zip(frames, record['strip_sha256']):
            strip = frame.convert('RGB').crop(box)
            if digest(strip.tobytes()) != expected or strip.size != tuple(record['strip_size']):
                raise ValueError('missing burned-in strip: ' + str(path))
            template = strip_for(record, image.size)
            if template.size != strip.size or digest(template.tobytes()) != record['stamp_template_sha256']:
                raise ValueError('invalid stamp bounds: ' + str(path))
            # JPEG and GIF quantize pixels. The text still has to be present.
            from PIL import ImageChops, ImageStat
            if max(ImageStat.Stat(ImageChops.difference(strip, template)).mean) > 18:
                raise ValueError('provenance text is absent from the picture: ' + str(path))
    return record


def open_picture(path, required=False):
    """Restore only the pixels hidden by the strip, for crops and measurements."""
    path = Path(path)
    record = verify(path) if sidecar(path).exists() or required else None
    with Image.open(path) as original:
        image = original.copy()
    if record:
        patch = Image.open(io.BytesIO(base64.b64decode(record['covered_pixels'][0])))
        image = image.convert(patch.mode)
        image.paste(patch, tuple(record['stamp_box'][:2]))
    return image


def save_picture(image, path, stage, sources=None, repo=None, **options):
    if stage not in STAGES:
        raise ValueError('unknown picture stage: ' + stage)
    path = Path(path)
    if path.suffix.lower() not in EXTENSIONS:
        raise ValueError('unsupported review image: ' + str(path))
    source_list = []
    for record in sources or []:
        for src in record['sources']:
            if src not in source_list:
                source_list.append(src)
    if not source_list:
        source_list = [dict(revision(str(Path(repo or ROOT).resolve())), stage=stage)]
    record = dict(source_list[0], schema=1, picture_name=path.name, stage=stage,
                  date=datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
                  sources=source_list, inputs=[summary(s) for s in sources or []])
    strip = strip_for(record, image.size)
    box = [0, image.height - strip.height, strip.width, image.height]
    frames = [image] + list(options.pop('append_images', []))
    covered = []
    stamped = []
    for frame in frames:
        frame = frame.copy().convert('RGBA' if 'A' in frame.getbands() and path.suffix.lower() not in {'.jpg', '.jpeg'} else 'RGB')
        if frame.size != image.size:
            raise ValueError('animation frames must have the same size')
        buf = io.BytesIO()
        frame.crop(box).save(buf, format='PNG')
        covered.append(base64.b64encode(buf.getvalue()).decode('ascii'))
        frame.paste(strip, tuple(box[:2]))
        stamped.append(frame)
    path.parent.mkdir(parents=True, exist_ok=True)
    if len(stamped) > 1:
        options.update(save_all=True, append_images=stamped[1:])
    stamped[0].save(path, **options)
    with Image.open(path) as saved:
        strips = [digest(f.convert('RGB').crop(box).tobytes()) for f in ImageSequence.Iterator(saved)]
    record.update(stamp_box=box, strip_size=list(strip.size), strip_sha256=strips,
                  stamp_template_sha256=digest(strip.tobytes()),
                  covered_pixels=covered, image_sha256=digest(path.read_bytes()))
    sidecar(path).write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8', newline='\n')
    return record


def stamp_file(path, stage, repo=None, new_render=False):
    path = Path(path)
    if sidecar(path).exists() and not new_render:
        # Never turn a cached old capture into a new revision.
        return verify(path)
    with Image.open(path) as image:
        frames = [f.convert('RGBA') for f in ImageSequence.Iterator(image)]
        options = {}
        if image.format == 'GIF':
            options.update(duration=image.info.get('duration', 100), loop=image.info.get('loop', 0))
        elif image.format == 'JPEG':
            options.update(quality=95)
    return save_picture(frames[0], path, stage, repo=repo, append_images=frames[1:], **options)


class Review:
    """Collect inputs for one output at a time.

    take_sources reserves inputs alongside cached pixels. Pass those records to
    save(sources=...) whenever another output uses the same cached pictures.
    """
    def __init__(self, stage):
        self.stage = stage
        self.sources = []

    def open(self, path, reference=False):
        if not reference or sidecar(path).exists():
            record = verify(path)
            if record not in self.sources:
                self.sources.append(record)
        return open_picture(path)

    def take_sources(self):
        sources, self.sources = self.sources, []
        return sources

    def save(self, image, path, sources=(), **options):
        output_sources = []
        for source in [*sources, *self.sources]:
            if source not in output_sources:
                output_sources.append(source)
        if not output_sources:
            raise ValueError('review sheet needs stamped source pictures; rerun the capture, do not relabel an old picture')
        stage = self.stage
        if stage == 'installed in game' and any(
                source['stage'] == PRE_MERGE_STAGE for picture in output_sources for source in picture['sources']):
            stage = PRE_MERGE_STAGE
        record = save_picture(image, path, stage, sources=output_sources, **options)
        self.sources.clear()
        return record

    def copy(self, source, destination):
        return self.save(self.open(source), destination)


def picture_target_matches(body):
    patterns = (
        r'!?\[[^\]]*\]\(\s*(<[^>]+>|[^\s)]+)',
        r'(?m)^\s*\[[^\]]+\]:\s*(<[^>]+>|\S+)',
        r'(?i)(?:src|href)=[\"\']([^\"\']+)',
        r'(?i)((?:https?://|file:/|[A-Za-z]:[\\/]|\\\\)[^\s<>\"\')]+\.(?:png|jpe?g|webp|gif)\b)',
    )
    for pattern in patterns:
        for match in re.finditer(pattern, body):
            target = unquote(match[1].strip('<>')).replace('\\', '/')
            if Path(urlsplit(target).path).suffix.lower() in EXTENSIONS:
                yield match


def picture_targets(body):
    return {match[1] for match in picture_target_matches(body)}


def check_body(repo, body, staged=False, tracked=True):
    """Require linked pictures AND sidecars in the PR tree. Never follow PC links."""
    repo = Path(repo).resolve()
    errors = []
    # Links inside code fences still reach the published PR and must be checked.
    targets = picture_targets(body)
    for target in set(targets):
        target = unquote(target.strip('<>'))
        suffix = Path(urlsplit(target.replace('\\', '/')).path).suffix.lower()
        if suffix not in EXTENSIONS:
            continue
        if re.match(r'(?i)(?:[a-z]+:|[/\\])', target) or '\\' in target:
            errors.append('use a relative repo picture link, never a PC or web path: ' + target)
            continue
        name = target.split('#')[0].split('?')[0]
        try:
            path = (repo / name).resolve()
            path.relative_to(repo)
            verify(path)
            for file in (path, sidecar(path)):
                relative = file.relative_to(repo).as_posix()
                if staged:
                    indexed = git(repo, 'show', ':' + relative)
                    same = (json.loads(indexed) == json.loads(file.read_bytes())) if file == sidecar(path) else indexed == file.read_bytes()
                    if not same:
                        raise ValueError('picture and sidecar must match the staged PR tree: ' + relative)
                elif tracked:
                    git(repo, 'ls-files', '--error-unmatch', '--', relative)
        except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as exc:
            errors.append('review picture refused: ' + name + ': ' + str(exc))
    if errors:
        raise ValueError('\n'.join(errors))
    return len(set(targets))


def publish_report(repo, out, destination):
    """Copy only the linked, validated shots. Rewrite the report before staging."""
    repo, out = Path(repo).resolve(), Path(out).resolve()
    report = out / 'last.md'
    if not report.exists():
        return
    body = report.read_text(encoding='utf-8-sig')
    copies, replacements = [], []
    matches = sorted(picture_target_matches(body), key=lambda match: (match.start(1), -match.end(1)))
    previous_end = 0
    for match in matches:
        start, end = match.span(1)
        if start < previous_end:
            continue  # A complete link already covers this bare path match.
        previous_end = end
        if match[1].startswith('<') and match[1].endswith('>'):
            start, end = start + 1, end - 1
        old = body[start:end]
        path_text, *suffix = re.split(r'(?=[?#])', old, maxsplit=1)
        name = unquote(path_text)
        candidate = Path(name)
        absolute = candidate.is_absolute()
        if name.replace('\\', '/').startswith('//') or (not absolute and re.match(r'(?i)[a-z]+:', name)):
            continue  # Leave UNC paths and URLs to check_body.
        if not absolute:
            candidate = out / candidate
        try:
            resolved = candidate.resolve()
        except (OSError, RuntimeError, ValueError):
            continue
        try:
            relative = resolved.relative_to(out / 'shots')
        except ValueError:
            if not absolute:
                continue
            try:
                relative = resolved.relative_to(repo)
            except ValueError:
                continue
        else:
            verify(candidate)
            dest = repo / destination / relative
            dest.resolve().relative_to(repo)
            copies.append((candidate, dest))
            relative = dest.relative_to(repo)
        new = quote(relative.as_posix()) + ''.join(suffix)
        if old != new:
            replacements.append((start, end, old, new))
    for start, end, _, new in reversed(replacements):
        body = body[:start] + new + body[end:]
    for source, dest in copies:
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, dest)
        shutil.copyfile(sidecar(source), sidecar(dest))
    check_body(repo, body, tracked=False)
    report.write_text(body, encoding='utf-8')
    for _, _, old, new in replacements:
        print(f'Rewrote picture link: {old} -> {new}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    stamp = sub.add_parser('stamp')
    stamp.add_argument('path')
    stamp.add_argument('--stage', required=True, choices=STAGES)
    stamp.add_argument('--repo', default=str(ROOT))
    stamp.add_argument('--new-render', action='store_true')
    verify_media = sub.add_parser('verify')
    verify_media.add_argument('paths', nargs='+')
    check = sub.add_parser('check-body')
    check.add_argument('body')
    check.add_argument('--repo', default=str(ROOT))
    check.add_argument('--staged', action='store_true')
    publish = sub.add_parser('publish-report')
    publish.add_argument('out')
    publish.add_argument('--repo', default=str(ROOT))
    publish.add_argument('--destination', required=True)
    context = sub.add_parser('context')
    context.add_argument('--repo', default=str(ROOT))
    args = parser.parse_args()
    try:
        if args.command == 'context':
            print(json.dumps(revision(str(Path(args.repo).resolve()))))
            return 0
        if args.command == 'stamp':
            stamp_file(args.path, args.stage, args.repo, args.new_render)
        elif args.command == 'verify':
            for path in args.paths:
                verify(path)
        elif args.command == 'check-body':
            check_body(args.repo, Path(args.body).read_text(encoding='utf-8-sig'), args.staged)
        else:
            publish_report(args.repo, args.out, args.destination)
        print('PASS picture provenance ' + args.command)
    except Exception as exc:
        print('FAIL picture provenance: ' + str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
