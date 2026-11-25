"""Issue 2035 (AAA item 9): build Ryan-ready before/after comparison sheets for
nebula and ion storm hexes with ships inside at cameras 170 and 26.

Usage:
  python make_sheets_2035.py --before DIR --after DIR --out DIR \
      --before-sha SHA --after-sha SHA [--repo REPO]

Each output sheet is 1280 x 680 px (strictly <= 720 px tall per RULEBOOK 1.2),
carries its code name clearly, shows BEFORE (main) on the left and AFTER
(neon/issue-2035) on the right, with Calm on the top row and Weapon/Explosion
Flash on the bottom row, plus 1080p frame median and 4K GPU median vs 12.5 ms.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import statistics
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

SHEET_W = 1280
SHEET_H = 680  # <= 720 px (RULEBOOK 1.2)
HEADER_H = 44
COL_LABEL_H = 22
FOOTER_H = 74  # room for timing line + provenance strip
GUTTER = 12
PAD_X = 16
CELL_W = (SHEET_W - PAD_X * 2 - GUTTER) // 2
CELL_H = (SHEET_H - HEADER_H - COL_LABEL_H - FOOTER_H - GUTTER) // 2

SHEETS = [
    ("N2035_NEB_C170", "nebula", 170, "Nebula Hex + Ships | Camera 170"),
    ("N2035_NEB_C26", "nebula", 26, "Nebula Hex + Ships | Camera 26"),
    ("N2035_STORM_C170", "storm", 170, "Ion Storm Hex + Ships | Camera 170"),
    ("N2035_STORM_C26", "storm", 26, "Ion Storm Hex + Ships | Camera 26"),
]


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for name in ("arialbd.ttf", "arial.ttf", "DejaVuSans-Bold.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _crop_center_fit(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    # Preserve native aspect ratio cleanly around the central subject without stretching.
    sw, sh = img.size
    target_ar = target_w / float(target_h)
    src_ar = sw / float(sh)
    if src_ar > target_ar:
        nw = int(round(sh * target_ar))
        x0 = (sw - nw) // 2
        cropped = img.crop((x0, 0, x0 + nw, sh))
    else:
        nh = int(round(sw / target_ar))
        y0 = (sh - nh) // 2
        cropped = img.crop((0, y0, sw, y0 + nh))
    return cropped.resize((target_w, target_h), Image.Resampling.LANCZOS)


def _iter_mode_rows(data: dict) -> list[tuple[str, dict]]:
    modes = data.get("modes")
    pairs: list[tuple[str, dict]] = []
    if isinstance(modes, dict):
        for mode_name, entries in modes.items():
            if isinstance(entries, dict):
                pairs.append((str(mode_name), entries))
            elif isinstance(entries, list):
                for entry in entries:
                    if isinstance(entry, dict):
                        pairs.append((str(entry.get("mode", mode_name)), entry))
        return pairs
    rows = modes if isinstance(modes, list) else data.get("rows")
    if isinstance(rows, list):
        for entry in rows:
            if isinstance(entry, dict):
                pairs.append((str(entry.get("mode", "")), entry))
    return pairs


def _read_gate(path: pathlib.Path) -> dict | None:
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
    if not isinstance(data, dict):
        return None
    expected_sessions = int(data.get("sessions") or 0)
    f1080_vals: list[float] = []
    g4k_vals: list[float] = []
    f1080_sessions: set[int] = set()
    g4k_sessions: set[int] = set()
    for idx, (mode, row) in enumerate(_iter_mode_rows(data)):
        sid = int(row.get("session") or (idx + 1))
        if mode == "base" and row.get("frame_median") is not None:
            f1080_vals.append(float(row["frame_median"]))
            f1080_sessions.add(sid)
        if mode == "res_2160" and row.get("gpu_median") is not None:
            g4k_vals.append(float(row["gpu_median"]))
            g4k_sessions.add(sid)
    if not f1080_vals and not g4k_vals:
        return None
    need = expected_sessions if expected_sessions > 0 else 1
    out: dict[str, float | int | bool] = {"expected_sessions": expected_sessions}
    if f1080_vals:
        med = float(statistics.median(f1080_vals))
        n_sess = len(f1080_sessions)
        out["f1080"] = med
        out["f1080_sessions"] = n_sess
        out["f1080_pass"] = n_sess >= need and med <= 12.5
    if g4k_vals:
        med = float(statistics.median(g4k_vals))
        n_sess = len(g4k_sessions)
        out["g4k"] = med
        out["g4k_sessions"] = n_sess
        out["g4k_pass"] = n_sess >= need and med <= 12.5
    out["complete"] = (
        int(out.get("f1080_sessions", 0)) >= need
        and int(out.get("g4k_sessions", 0)) >= need
    )
    return out


def _fmt_gate(label: str, metrics: dict | None) -> str:
    if not metrics:
        return f"{label}: timing incomplete"
    need = int(metrics.get("expected_sessions", 0) or 0)
    parts = []
    if "f1080" in metrics:
        n = int(metrics.get("f1080_sessions", 0))
        val = float(metrics["f1080"])
        if need > 0 and n < need:
            status = f"INCOMPLETE {n}/{need}s"
        else:
            status = "PASS" if val <= 12.5 else "OVER"
        parts.append(f"1080p {val:.2f}ms ({status})")
    else:
        parts.append("1080p MISSING")
    if "g4k" in metrics:
        n = int(metrics.get("g4k_sessions", 0))
        val = float(metrics["g4k"])
        if need > 0 and n < need:
            status = f"INCOMPLETE {n}/{need}s"
        else:
            status = "PASS" if val <= 12.5 else "OVER"
        parts.append(f"4K GPU {val:.2f}ms ({status})")
    else:
        parts.append("4K GPU MISSING")
    return f"{label}: " + ", ".join(parts)


def build_sheets(
    before_dir: pathlib.Path,
    after_dir: pathlib.Path,
    out_dir: pathlib.Path,
    before_sha: str,
    after_sha: str,
    repo_dir: pathlib.Path | None,
) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    f_title = _font(20)
    f_sub = _font(14)
    f_tag = _font(13)
    summary: dict[str, object] = {
        "before_sha": before_sha,
        "after_sha": after_sha,
        "sheets": [],
        "timing": {},
    }
    stamp_tool = (repo_dir / "tools" / "picture_provenance.py") if repo_dir else None

    for code, case, cam, title in SHEETS:
        b_calm = before_dir / f"gas2035_{case}_c{cam}_calm.png"
        a_calm = after_dir / f"gas2035_{case}_c{cam}_calm.png"
        b_flash = before_dir / f"gas2035_{case}_c{cam}_flash.png"
        a_flash = after_dir / f"gas2035_{case}_c{cam}_flash.png"
        missing = [str(p) for p in (b_calm, a_calm, b_flash, a_flash) if not p.exists()]
        if missing:
            raise FileNotFoundError(f"{code}: missing input stills: {missing}")

        sheet = Image.new("RGB", (SHEET_W, SHEET_H), (12, 14, 20))
        draw = ImageDraw.Draw(sheet)
        draw.text((PAD_X, 11), f"{code}   {title}", fill=(242, 245, 252), font=f_title)
        draw.text(
            (SHEET_W - PAD_X - 310, 14),
            f"main {before_sha[:8]} vs issue-2035 {after_sha[:8]}",
            fill=(165, 178, 196),
            font=f_sub,
        )

        y_col = HEADER_H
        x_left = PAD_X
        x_right = PAD_X + CELL_W + GUTTER
        draw.text((x_left, y_col), f"BEFORE (main {before_sha[:8]})", fill=(195, 204, 218), font=f_sub)
        draw.text((x_right, y_col), f"AFTER (neon/issue-2035 {after_sha[:8]})", fill=(135, 224, 208), font=f_sub)

        y_row0 = y_col + COL_LABEL_H
        y_row1 = y_row0 + CELL_H + GUTTER
        cells = [
            (b_calm, x_left, y_row0, "CALM"),
            (a_calm, x_right, y_row0, "CALM"),
            (b_flash, x_left, y_row1, "WEAPON FLASH + BLAST"),
            (a_flash, x_right, y_row1, "WEAPON FLASH + BLAST"),
        ]
        for path, cx, cy, badge in cells:
            with Image.open(path) as im:
                tile = _crop_center_fit(im.convert("RGB"), CELL_W, CELL_H)
            sheet.paste(tile, (cx, cy))
            bw = 182 if len(badge) > 6 else 64
            draw.rectangle((cx + 6, cy + 6, cx + 6 + bw, cy + 26), fill=(10, 12, 18))
            draw.text((cx + 12, cy + 9), badge, fill=(232, 238, 248), font=f_tag)

        t_before = _read_gate(before_dir / f"timing_{case}" / "scene_gate.json")
        t_after = _read_gate(after_dir / f"timing_{case}" / "scene_gate.json")
        summary["timing"][case] = {"before": t_before, "after": t_after}
        # Place timing summary under the right column so the bottom-left provenance stamp never covers it.
        foot_x = x_right
        foot_y = y_row1 + CELL_H + 10
        draw.text(
            (foot_x, foot_y),
            f"{_fmt_gate('Before', t_before)}  (gate <= 12.5ms)",
            fill=(195, 204, 218),
            font=f_sub,
        )
        draw.text(
            (foot_x, foot_y + 22),
            f"{_fmt_gate('After', t_after)}  (gate <= 12.5ms)",
            fill=(135, 224, 208),
            font=f_sub,
        )

        out_path = out_dir / f"{code}.jpg"
        sheet.save(out_path, quality=92, subsampling=0)
        if stamp_tool and stamp_tool.exists() and repo_dir:
            subprocess.run(
                [
                    sys.executable,
                    str(stamp_tool),
                    "stamp",
                    str(out_path),
                    "--repo",
                    str(repo_dir),
                    "--stage",
                    "pre-merge capture",
                ],
                check=True,
            )
        summary["sheets"].append({"code": code, "file": out_path.name, "size": [SHEET_W, SHEET_H]})

    (out_dir / "summary_2035.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    return summary


def _selftest() -> int:
    import tempfile

    with tempfile.TemporaryDirectory() as td:
        tmp = pathlib.Path(td)
        # 1. Partial fixture: only 1 of 3 base sessions (below 12.5 ms) and missing GPU row.
        partial = tmp / "partial.json"
        partial.write_text(
            json.dumps({"sessions": 3, "modes": {"base": [{"session": 1, "frame_median": 9.5}]}}),
            encoding="utf-8",
        )
        m_part = _read_gate(partial)
        assert m_part is not None and not m_part["complete"] and not m_part["f1080_pass"]
        txt_part = _fmt_gate("After", m_part)
        assert "INCOMPLETE 1/3s" in txt_part and "PASS" not in txt_part and "4K GPU MISSING" in txt_part, txt_part

        # 2. Complete over-budget fixture: 3 distinct sessions, base over 12.5 ms, 4K under.
        over = tmp / "over.json"
        over.write_text(
            json.dumps(
                {
                    "sessions": 3,
                    "modes": {
                        "base": [
                            {"session": 1, "frame_median": 13.4},
                            {"session": 2, "frame_median": 14.5},
                            {"session": 3, "frame_median": 16.6},
                        ],
                        "res_2160": [
                            {"session": 1, "gpu_median": 8.4},
                            {"session": 2, "gpu_median": 8.5},
                            {"session": 3, "gpu_median": 8.4},
                        ],
                    },
                }
            ),
            encoding="utf-8",
        )
        m_over = _read_gate(over)
        assert m_over is not None and m_over["complete"] and not m_over["f1080_pass"] and m_over["g4k_pass"]
        txt_over = _fmt_gate("After", m_over)
        assert "(OVER)" in txt_over and "(PASS)" in txt_over, txt_over

        # 3. Complete passing fixture: 3 distinct sessions under 12.5 ms in both modes.
        ok = tmp / "ok.json"
        ok.write_text(
            json.dumps(
                {
                    "sessions": 3,
                    "modes": {
                        "base": [
                            {"session": 1, "frame_median": 11.2},
                            {"session": 2, "frame_median": 11.5},
                            {"session": 3, "frame_median": 11.4},
                        ],
                        "res_2160": [
                            {"session": 1, "gpu_median": 7.9},
                            {"session": 2, "gpu_median": 8.1},
                            {"session": 3, "gpu_median": 8.0},
                        ],
                    },
                }
            ),
            encoding="utf-8",
        )
        m_ok = _read_gate(ok)
        assert m_ok is not None and m_ok["complete"] and m_ok["f1080_pass"] and m_ok["g4k_pass"]
        txt_ok = _fmt_gate("After", m_ok)
        assert "1080p 11.40ms (PASS)" in txt_ok and "4K GPU 8.00ms (PASS)" in txt_ok, txt_ok
    print("make_sheets_2035 selftest: PASS")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--before")
    ap.add_argument("--after")
    ap.add_argument("--out")
    ap.add_argument("--before-sha", default="main")
    ap.add_argument("--after-sha", default="issue2035")
    ap.add_argument("--repo", default="")
    args = ap.parse_args()
    if args.selftest:
        return _selftest()
    if not args.before or not args.after or not args.out:
        ap.error("--before, --after, and --out are required unless --selftest is given")
    repo = pathlib.Path(args.repo) if args.repo else None
    summary = build_sheets(
        pathlib.Path(args.before),
        pathlib.Path(args.after),
        pathlib.Path(args.out),
        args.before_sha,
        args.after_sha,
        repo,
    )
    print("SHEETS_2035_DONE", json.dumps(summary))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
