"""Read installed ship hashes and GLB destruction metadata without altering the build."""

import argparse
from hashlib import file_digest
import json
from pathlib import Path
import struct


def sha256(path):
    with path.open("rb") as stream:
        return file_digest(stream, "sha256").hexdigest()


def read_glb_json(path):
    with path.open("rb") as stream:
        magic, version, _, size, chunk_type = struct.unpack("<4sIIII", stream.read(20))
        if (magic, version, chunk_type) != (b"glTF", 2, 0x4E4F534A):
            raise ValueError(f"Invalid GLB header: {path.name}")
        return json.loads(stream.read(size))


def inspect(project, installed):
    folder = project / "assets" / "ships"
    manifest_file = folder / "manifest.json"
    source = json.loads((project / "build_info.json").read_text())
    manifest = json.loads(manifest_file.read_text())["ships"]
    runtime = json.loads((project / "gen" / "manifest.json").read_text())["ships"]
    rows = []
    for code, entry in manifest.items():
        path = folder / code / f"{code}.glb"
        contract = []
        present = path.is_file()
        if present:
            glb = read_glb_json(path)
            slots = {mat.get("name") for mat in glb.get("materials", [])}
            for node in glb["nodes"]:
                meta = node.get("extras", {}).get("voidsworn_destruct")
                if not meta:
                    continue
                inside = [name for name in meta.get("interior_materials", []) if not name.endswith("_inside_skin")]
                contract.append({
                    "version": meta.get("version"),
                    "interior_materials": len(slots.intersection(inside)),
                    "seams": len(meta.get("seams", [])),
                    "seam_paths_or_spans": sum(len(seam.get("path", [])) >= 2 or len(seam.get("span", [])) == 2
                                                for seam in meta.get("seams", [])),
                    "machines": len(meta.get("machines", [])),
                })
        problems = []
        for filename, expected in entry["files"].items():
            for label, base in (("snapshot", folder), ("installed", installed)):
                file = base / code / filename
                if not file.is_file() or file.stat().st_size != expected["bytes"] or sha256(file) != expected["sha256"]:
                    problems.append([label, filename])
        rows.append({"code": code, "faction": entry["faction"], "class": entry["cls"], "present": present,
                     "runtime_res": runtime.get(code, {}).get("res"), "contract": contract, "file_mismatches": problems})
    return {"source_commit": source["commit"], "manifest_sha256": sha256(manifest_file),
            "files": sum(len(entry["files"]) for entry in manifest.values()), "rows": rows}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("shared_project", type=Path)
    args = parser.parse_args()
    print(json.dumps(inspect(args.snapshot, args.shared_project / "assets" / "ships"), indent=2))
