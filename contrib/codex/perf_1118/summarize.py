"""Keep full frame traces and derive JSON tables without pooling the sessions."""

import argparse
import gzip
import hashlib
import json
import math
import statistics
from collections import Counter, defaultdict
from pathlib import Path


def summarize(samples, columns):
    if not samples or any(len(frame) != len(columns) for frame in samples):
        raise ValueError("Missing or malformed frame samples")
    stats = {}
    for key, values in zip(columns, zip(*samples)):
        ordered = sorted(values)
        stats[key] = {
            "median": round(statistics.median(ordered), 3),
            "p95": round(ordered[math.ceil(0.95 * len(ordered)) - 1], 3),
            "p99": round(ordered[math.ceil(0.99 * len(ordered)) - 1], 3),
            "max": round(ordered[-1], 3),
        }
    return stats


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def write_baseline(path, groups):
    names = {"gate": "Scene 207", "dense": "Dense storm", "large": "Sector 3 station"}
    metrics = ("frame_ms", "main_process_ms", "render_cpu_ms", "gpu_ms")
    lines = [
        "# Baseline timing",
        "",
        "Each timing cell is median / p95 / p99 / worst in ms. "
        "See the [method and fixture details](README.md).",
        "",
        "| Fixture | Shield | Quality | 3D | Mesh LOD | Sessions | Frame | Main CPU | Render CPU | GPU |",
        "|---|---|---|---|---|---:|---:|---:|---:|---:|",
    ]
    baseline = [row for row in groups if row["phase"].startswith("baseline")]
    for row in sorted(baseline, key=lambda row: (
        list(names).index(row["case"].split(":")[0]),
        row["shield"] != "fitted",
        ["max", "high", "low"].index(row["case"].split(":")[1]),
        row["case"].split(":")[2],
        row["case"].split(":")[3] != "native_lod",
    )):
        fixture, tier, scale, variant = row["case"].split(":")
        cells = [names[fixture], row["shield"], tier, "1080p" if scale == "1" else "4K",
                 "Shipped" if variant == "native_lod" else "Full detail", str(row["sessions"])]
        cells.extend(" / ".join(f"{row['stats'][metric][stat]:.3f}" for stat in ("median", "p95", "p99", "max"))
                     for metric in metrics)
        lines.append("| " + " | ".join(cells) + " |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("work", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    result = {"machine": json.loads((args.work / "machine.json").read_text())}
    raw = args.out / "raw"
    raw.mkdir(parents=True, exist_ok=True)
    runs = []
    groups = defaultdict(list)
    gate = []
    rejected = []
    probes = {}
    for path in sorted((args.work / "run").glob("*/*/samples.jsonl")):
        phase, process, _ = path.relative_to(args.work / "run").parts
        records = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
        if not records:
            rejected.append({"phase": phase, "process": process, "reason": "Empty sample journal"})
            continue
        info, *rows = records
        if not rows:
            rejected.append({"phase": phase, "process": process, "reason": "No completed case"})
            continue
        if not info["adapter"] or info["renderer"] != "forward_plus":
            raise ValueError(f"{path} has no windowed Forward+ run")
        for manifest in ("ship", "gen"):
            if info[f"{manifest}_manifest_sha256"] != result["machine"][f"installed_{manifest}_manifest_sha256"]:
                raise ValueError(f"Manifest changed during {path}")
        trace = raw / f"{phase}_{process}.jsonl.gz"
        trace.write_bytes(gzip.compress(path.read_bytes(), mtime=0))
        record = {"phase": phase, "process": process, "trace": trace.name, "rows": []}
        probe = path.parents[1] / "probe.gd"
        if phase not in probes and probe.exists():
            source = probe.read_bytes()
            if hashlib.sha256(source).hexdigest() != info["source_sha256"]:
                raise ValueError(f"Probe hash does not match {phase} trace")
            stored = raw / f"{phase}_probe.gd.gz"
            stored.write_bytes(gzip.compress(source, mtime=0))
            probes[phase] = stored.name
        if phase in probes:
            record["probe"] = probes[phase]
        telemetry = path.with_name("gpu.csv")
        if telemetry.exists():
            record["gpu_before_after_csv"] = telemetry.read_text(encoding="ascii").splitlines()
        engine_log = path.with_name("engine.log")
        if engine_log.exists():
            errors = Counter(line for line in engine_log.read_text(encoding="utf-8").splitlines()
                             if line.startswith(("ERROR:", "SCRIPT ERROR:")))
            if errors:
                record["godot_errors"] = errors
        runs.append(record)
        if phase == "profile":
            profiler = raw / f"{phase}_{process}_engine.log.gz"
            profiler.write_bytes(gzip.compress(engine_log.read_bytes(), mtime=0))
            record["profiler"] = profiler.name
        for row in rows:
            samples = row.pop("samples", None)
            if samples is not None:
                row["sample_count"] = len(samples)
                row["stats"] = summarize(samples, info["metrics"])
                fx_trace = row.pop("fx_profile_by_frame_us", [])
                if fx_trace:
                    spikes = sorted(range(len(samples)), key=lambda index: samples[index][0], reverse=True)[:5]
                    row["worst_five_fx_us"] = [[index, samples[index][:4], fx_trace[index]] for index in spikes]
                if row["stats"]["gpu_ms"]["median"] <= 0:
                    raise ValueError(f"No GPU timings for {phase} {process} {row['case']}")
                if phase != "profile":
                    groups[(phase, info["shield"], row["case"])].append(row)
            for event in row.get("events", []):
                if isinstance(event, dict) and "samples" in event:
                    samples = event.pop("samples")
                    samples = samples[event.get("pre_frames", 0):]
                    if not samples:
                        event["missing_event"] = True
                        continue
                    event["sample_count"] = len(samples)
                    event["stats"] = summarize(samples, info["metrics"])
                    event["worst_frame_index"] = max(range(len(samples)), key=lambda index: samples[index][0])
                    fx_trace = event.pop("fx_profile_by_frame_us", [])
                    if fx_trace:
                        event["worst_frame_fx_us"] = fx_trace[event["worst_frame_index"]]
            record["rows"].append(row)
    for path in sorted((args.work / "run").glob("*/*/scene_gate.json")):
        phase, process, _ = path.relative_to(args.work / "run").parts
        data = json.loads(path.read_text(encoding="utf-8"))
        gate.append({"phase": phase, "process": process, "report": data})
    result["runs"] = runs
    result["rejected"] = rejected
    result["native_gate"] = gate
    result["groups"] = [
        {
            "phase": phase,
            "shield": shield,
            "case": case,
            "sessions": len(rows),
            "build_ms": [round(row["build_ms"], 3) for row in rows],
            "session_frame_medians": [row["stats"]["frame_ms"]["median"] for row in rows],
            "stats": {
                metric: {
                    stat: round((max if stat == "max" else statistics.median)(
                        row["stats"][metric][stat] for row in rows), 3)
                    for stat in ("median", "p95", "p99", "max")
                }
                for metric in rows[0]["stats"]
            },
        }
        for (phase, shield, case), rows in sorted(groups.items())
    ]
    write_json(args.out / "summary.json", result)
    write_baseline(args.out / "baseline.md", result["groups"])
    if not runs:
        raise ValueError("No runs were collected")


if __name__ == "__main__":
    main()
