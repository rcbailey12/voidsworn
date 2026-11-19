"""Make review clips and sheets from the 1080p Godot Movie Maker masters."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
from datetime import datetime, timezone

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'tools'))
import picture_provenance as pictures

FPS = 30
SECONDS_PER_PART = 48
CLIP_LIMIT = 8_000_000
ROUTES = {10: ("navy", "Navy"), 121: ("hullbreakers", "Hullbreakers")}
INK = "#10151e"
BONE = "#f1e8d9"
EMBER = "#ffae70"
FONT = Path(os.environ.get("WINDIR", r"C:\Windows")) / "Fonts" / "consola.ttf"


def run(*args, **options):
    return subprocess.run([pictures.ffmpeg_executable(), "-hide_banner", "-nostdin", *map(str, args)], check=True, **options)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")


def file_sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def title_for(event):
    kind = event["kind"]
    return {
        "battle_start": "Opening board",
        "board": "Fleet and HUD",
        "danger": "Danger overlay",
        "teaching_card": f"Card / {event.get('id', '').replace('_', ' ')}",
        "move_preview": "Move preview",
        "target_preview": "Target preview",
        "attack_move_preview": "Attack-move preview",
        "cut_start": f"Cut-in / {event.get('text', '').split(':')[0]}",
        "arrival": "Reinforcements",
        "command": "Command",
        "end_card": str(event.get("result", "")).title(),
    }.get(kind, kind)


def contact_times(events, start, stop):
    handed_over = next((event["frame"] / FPS for event in events if event["kind"] == "board"), start + 1.0)
    opening = max(start + 0.3, handed_over - 0.7)
    picks = [(min(opening, stop), "Opening board")]
    priorities = [
        ("teaching_card", "danger"),
        ("move_preview", "attack_move_preview"),
        ("target_preview",),
        ("arrival", "cut_start", "command"),
        ("end_card",),
    ]
    for kinds in priorities:
        pick = next((e for kind in kinds for e in events if e["kind"] == kind), None)
        if pick:
            delay = 0.6 if pick["kind"] in {"arrival", "cut_start", "command"} else 0.27
            picks.append((min(pick["frame"] / FPS + delay, stop), title_for(pick)))
    for fraction in (0.32, 0.52, 0.73, 0.82, 0.92):
        if len(picks) == 6:
            break
        picks.append((start + fraction * (stop - start), "Battle in progress"))
    return sorted(picks)


def frame_image(movie, seconds, width, height):
    pixels = run("-loglevel", "error", "-ss", f"{seconds:.6f}", "-i", movie, "-frames:v", "1",
                 "-vf", f"scale={width}:{height}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-",
                 stdout=subprocess.PIPE).stdout
    if len(pixels) != width * height * 3:
        raise RuntimeError(f"No frame at {seconds:.2f} seconds in {movie}")
    return Image.frombytes("RGB", (width, height), pixels)


def contact_sheet(movie, path, title, events, start, stop, provenance, master):
    sheet = Image.new("RGB", (1280, 720), INK)
    draw = ImageDraw.Draw(sheet)
    draw.text((25, 21), title, font=ImageFont.truetype(str(FONT), 30), fill=BONE)
    draw.text((25, 57), "Times are measured from the start of this battle.", font=ImageFont.truetype(str(FONT), 17), fill=EMBER)
    labels = []
    for i, (sec, name) in enumerate(contact_times(events, start, stop - 0.1)):
        x, y = 24 + (i % 3) * 416, 95 + (i // 3) * 263
        sheet.paste(frame_image(movie, sec, 400, 225), (x, y))
        offset = sec - start
        minute, second = divmod(offset, 60)
        label = f"{int(minute):02d}:{second:04.1f}  {name}"
        draw.text((x, y + 233), label, font=ImageFont.truetype(str(FONT), 18), fill=BONE)
        labels.append({"seconds": round(offset, 2), "label": name})
    source = dict(master, sources=[provenance])
    record = pictures.save_picture(sheet, path, provenance['stage'], sources=[source], quality=91, optimize=True)
    record['frames'] = labels
    write_json(pictures.sidecar(path), record)
    pictures.verify(path)


def review_clips(movie, out, scratch, code, start, stop, provenance, master):
    parts = max(1, math.ceil((stop - start) / SECONDS_PER_PART))
    for index in range(parts):
        elapsed = index * SECONDS_PER_PART
        duration = min(SECONDS_PER_PART, stop - start - elapsed)
        stem = f"{code}-p{index + 1:02d}"
        path = out / f"{stem}.mp4"
        record = dict(provenance, picture_name=path.name, sources=[provenance], inputs=[pictures.summary(master)],
                      seconds_in_battle=elapsed, duration_s=round(duration, 3))
        badge = pictures.strip_for(record, (1280, 720))
        record['stamp_template_sha256'] = pictures.digest(badge.tobytes())
        stamp = scratch / f"{stem}.png"
        badge.save(stamp)
        run("-loglevel", "error", "-n", "-ss", f"{start + elapsed:.6f}", "-i", movie, "-i", stamp,
            "-filter_complex_threads", "2", "-filter_complex",
            "[0:v]scale=1120:630,pad=1280:720:80:0:0x10151e,setsar=1[board];[board][1:v]overlay=0:H-h[out]",
            "-map", "[out]", "-map", "0:a:0", "-t", f"{duration:.6f}", "-c:v", "libx264",
            "-threads", "4", "-preset", "veryfast", "-b:v", "980k", "-maxrate", "1100k", "-bufsize", "1400k",
            "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart",
            "-metadata", f"title={code.upper()}, part {index + 1}/{parts}",
            "-metadata", "comment=" + " | ".join(pictures.text_lines(record)), path)
        if path.stat().st_size >= CLIP_LIMIT:
            raise RuntimeError(f"Review clip exceeds {CLIP_LIMIT} bytes: {path}")
        record['image_sha256'] = file_sha256(path)
        write_json(pictures.sidecar(path), record)
        pictures.verify(path)


def package(full, out, scratch, seed, build_hash):
    movie = full / f"seed-{seed}.avi"
    events = [json.loads(line) for line in (full / f"seed-{seed}.jsonl").read_text(encoding="utf-8").splitlines()]
    setup = next(row for row in events if row["kind"] == "run")
    build = setup.get("build") or {}
    commit = build.get("commit", "")
    manifest = setup.get("manifest_sha256", "")
    if (setup.get("headless") or not setup.get("profile_isolated") or setup["seed"] != seed
            or build.get("source_dirty") or build.get("source_diff_sha256") or not re.fullmatch(r"[0-9a-f]{40,64}", commit)
            or any(not re.fullmatch(r"[0-9a-f]{64}", v) for v in (manifest, build_hash))):
        raise RuntimeError("The capture is missing installed build provenance")
    if (setup["mesh_lod_threshold"] <= 0 or setup["settings"]["cine"] != "key" or not setup["settings"]["tips"]
            or not setup["settings"]["sound"] or setup["settings"]["ai"] != "standard"):
        raise RuntimeError("The capture did not use the player's defaults")
    completed = [row["battle"] for row in events if row["kind"] == "battle_end"]
    wins = [row["battle"] for row in events if row["kind"] == "end_card" and row["result"] == "win"]
    if completed != [1, 2, 3] or wins != completed or any(row["kind"] == "failure" for row in events):
        raise RuntimeError(f"Seed {seed} recorded {len(completed)} battles and won {len(wins)}")
    boards = [event for event in events if event["kind"] == "board"]
    if [row["battle"] for row in boards] != completed:
        raise RuntimeError(f"Seed {seed} has an incomplete board trace")
    for row in boards:
        if not (row["tips_on"] and row["hud"] and row["voice_on"] and row["cut_ins"] == "key"):
            raise RuntimeError(f"Player cues are missing in seed {seed}, Battle {row['battle']}")
    date = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    source = {"source_commit": commit, "source_commit_date": build["commit_date"], "stage": "installed in game",
              "source_dirty": build.get("source_dirty", False), "source_diff_sha256": build.get("source_diff_sha256", "")}
    provenance = dict(source, schema=1, date=date, seed=seed, build_sha256=build_hash,
                      manifest_sha256=manifest, fps=FPS)
    out.mkdir(parents=True, exist_ok=True)
    master = dict(provenance, picture_name=movie.name, resolution=[1920, 1080], sources=[source], inputs=[],
                  image_sha256=file_sha256(movie))
    write_json(pictures.sidecar(movie), master)
    route, label = ROUTES[seed]
    for battle in completed:
        rows = [row for row in events if row["battle"] == battle]
        begin = next(row for row in rows if row["kind"] == "battle_start")
        end = next(row for row in rows if row["kind"] == "battle_end")
        start, stop = begin["frame"] / FPS, end["frame"] / FPS
        code = f"{route}-b{battle}"
        title = f"{code.upper()} | {label} route | Seed {seed}"
        one = dict(provenance, battle=battle, enemy=begin["enemy"], objective=begin["objective"])
        review_clips(movie, out, scratch, code, start, stop, one, master)
        contact_sheet(movie, out / f"{code}.jpg", title, rows, start, stop, one, master)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("full", nargs="?", type=Path)
    parser.add_argument("out", nargs="?", type=Path)
    parser.add_argument("scratch", nargs="?", type=Path)
    parser.add_argument("seed", nargs="?", type=int, choices=ROUTES)
    parser.add_argument("build_hash", nargs="?")
    args = parser.parse_args()
    if args.check:
        run("-version", stdout=subprocess.DEVNULL)
        ImageFont.truetype(str(FONT), 17)
    elif None in (args.full, args.out, args.scratch, args.seed, args.build_hash):
        parser.error("provide full, review and scratch folders, seed and build hash")
    else:
        package(args.full, args.out, args.scratch, args.seed, args.build_hash)


if __name__ == "__main__":
    main()
