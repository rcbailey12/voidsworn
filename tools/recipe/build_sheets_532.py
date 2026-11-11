"""Issue 532: reproducible, measured concept blockouts and build sheets.

Run with ComfyUI's Python for prep/fit/sheets, TRELLIS Python for shape,
and Blender -b -P this_file -- geometry|render ROOT for Blender work.
All PC artifacts go below the explicit ROOT. No game assets are installed.
"""
import argparse
import json
import math
import os
from pathlib import Path
import sys
import re
sys.dont_write_bytecode = True

REPO = Path(__file__).resolve().parents[2]
DEST = REPO / "docs/ship_pipeline/build_sheets"
BEAUTIES = REPO / "contrib/muse/design/concept_round8_2026_11"


def spec(code):
    big = code == "corsair_A16"
    cls="Battle-barge" if big else "Cruiser"
    source=(REPO/"godot/render/hull_table.gd").read_text(encoding="utf-8")
    lengths=json.loads("{"+re.search(r"const CLS_LEN\s*:=\s*\{(.*?)\}",source,re.S).group(1)+"}")
    multiplier=float(re.search(r"const SHIP_K\s*:=\s*([0-9.]+)",source).group(1))
    return dict(code=code, cls=cls,
                name="Warlord's Pyre-Barge" if big else "Pack Hunter",
                length=lengths[cls], game_draw_multiplier=multiplier, big=big,
                beauty=str(BEAUTIES / (code + "_beauty.jpg")))


def features(code):
    # Positions: fraction of overall length measured from the prow; signed
    # lateral offset (port positive); height above the centreline. These are
    # explicit blockout decisions, NOT measurements recovered from perspective.
    big = spec(code)["big"]
    f = []
    def add(fid, kind, stations, ys, z, aim, size, note="Visible; dimensions are blockout interpretation"):
        for i, (s, y) in enumerate(zip(stations, ys)):
            f.append(dict(id=fid + (str(i + 1) if len(stations) > 1 else ""),
                          kind=kind, station=s, offset=y, height=z,
                          aim=aim, size=size, evidence=note))
    add("I", "intake", [.12, .12], [.115, -.115], -.015, [1, 0, 0], [.105, .105, .105])
    add("D", "dish", [.23, .23] if big else [.25, .25],
        [.055, -.055] if big else [.175, -.175], .13 if big else .11,
        [.95, 0, .32], [.055, .055, .055] if big else [.086, .086, .086])
    add("H", "hook", [.08, .08], [.105, -.105], -.14,
        [1, 0, -.2], [.14, .025, .045],
        "Visible paired boarding claws; hinge and hidden actuator TO BE DESIGNED")
    add("C", "chain", [.45, .45], [.125, -.125], .09,
        [1, 0, 0], [.52, .008, .008],
        "Two upper runs visible; underside return and attachment hardware TO BE DESIGNED")
    if big:
        add("G", "single_gun", [.55, .78], [.24, .235],
            -.025, [.7, .714, 0], [.065, .027, .027],
            "Port lower single-barrel mount; see annotated beauty inventory")
        add("T", "twin_gun", [.57, .76, .86], [.20, .24, .20],
            .075, [.82, .572, 0], [.07, .022, .022],
            "Port twin battery stand-ins; mount geometry simplified")
        add("F", "single_gun", [.20, .29, .42, .49, .61], [-.18, -.20, -.23, -.21, -.23],
            .04, [1, 0, 0], [.07, .025, .025],
            "Five distinct far-flank single mounts visible; see inventory. Hidden lower battery TO BE DESIGNED")
        add("V", "twin_gun", [.72, .80], [-.21, -.18], .12,
            [1,0,0], [.065,.021,.021], "Two far upper twin mounts visible beside the launcher")
        add("U", "single_gun", [.82], [0], .245, [1, 0, 0], [.105, .04, .04],
            "One roof turret. Beauty barrel reads aft; rest aim changed forward to satisfy standard")
        add("R", "launcher", [.60], [0], .17, [1, 0, 0], [.115, .13, .065],
            "One rack, ten mouths in two rows of five; rack back TO BE DESIGNED")
        add("E", "engine", [.93, .93], [.245, -.245], .005,
            [-1, 0, 0], [.14, .145, .145],
            "Port large exit and far shoulder pod visible; far exit TO BE DESIGNED")
        add("A", "engine", [.95], [.12], .20, [-1, 0, 0], [.085, .075, .075],
            "One upper port cylindrical aft unit visible; far equivalent TO BE DESIGNED")
        add("e", "engine", [.94], [.255], -.11, [-1, 0, 0], [.07, .065, .065],
            "One lower port exit visible; far equivalent TO BE DESIGNED")
    else:
        add("G", "twin_gun", [.70, .83], [.23, .205],
            .005, [.78, .626, 0], [.075, .024, .024],
            "Two port middle/aft twin mounts; see annotated beauty inventory")
        add("g", "twin_gun", [.63], [.225], -.10,
            [1, 0, 0], [.08, .021, .021], "One low port twin visible")
        add("J", "single_gun", [.55,.72,.82], [.225,.23,.19], .045,
            [.85,.526,0], [.055,.022,.022],
            "Port forward round gun, small low middle gun and upper shoulder single; see inventory")
        add("F", "twin_gun", [.35, .47, .61], [-.21, -.23, -.22],
            .075, [1, 0, 0], [.08, .022, .022],
            "Three far upper paired barrels visible; hidden lower battery TO BE DESIGNED")
        add("U", "single_gun", [.70], [-.12], .23, [1, 0, 0], [.075, .03, .03])
        add("E", "engine", [.91, .95, .96], [.20, .16, .135],
            .08, [-1, 0, 0], [.12, .09, .09],
            "Three port aft cylinders visible at staggered heights; far layout TO BE DESIGNED")
        # Individual heights resolve the vertical engine stack.
        for item, h in zip(f[-3:], [.08, -.025, -.12]): item["height"] = h
        add("A", "engine", [.93], [-.18], .12, [-1, 0, 0], [.10, .075, .075],
            "Far upper aft cylinder visible; exit and hidden engine-end structure TO BE DESIGNED")
    for item in f:
        if item["id"] in (("F2","V2") if big else ("F1","F2","F3")):
            item["aim"]=[.90,-.4359,0]
            item["evidence"] += "; rest aim forward/outboard to clear other fittings"
        if big and item["id"]=="G2":item["aim"]=[.35,.93675,0]
        if not big and item["id"]=="g":item["aim"]=[.70,.71414,0]
        if not big and item["id"] in ("F1","F2"):item["aim"]=[.70,-.71414,0]
    return f


def write_table(d, root):
    code = d["code"]; fs = features(code); out = DEST / code; out.mkdir(parents=True, exist_ok=True)
    data = dict(**d, features=fs, version="2026-11-11 v1", frame="+X bow, +Y port, +Z up",
                station_origin="Forward-most claw tip; overall length includes fittings",
                unresolved=["Belly skin, internal decks, break lines and belly fittings TO BE DESIGNED",
                            "Unseen starboard lower battery, engine end plumbing and chain returns TO BE DESIGNED",
                            "All dimensions and stations are a proposed blockout interpretation of the accepted beauty",
                            "Annotated beauty inventory pins the visible mounts; concealed barrels and far lower weapons stay open"])
    (out / "blockout.json").write_text(json.dumps(data, indent=2) + "\n", encoding="ascii")
    lines = [f"# {code}: {d['name']}", "", "Ashfall Hullbreakers | " + d["cls"] + " | 2026-11-11 v1", "",
             "## Authority and units", "",
             f"Class length: **{d['length']:g} world units**, from `godot/render/hull_table.gd`, `CLS_LEN`. "
             f"The game applies `SHIP_K = {d['game_draw_multiplier']:g}`, drawing this class at {d['length'] * d['game_draw_multiplier']:g} units. "
             "This sheet uses the unmultiplied class length. The same 5-unit bars appear on the side and top.", "",
             "Accepted beauty is the identity reference. The old generated sheet is not a geometry source. "
             "Stations, offsets, mount heights and sizes below are an explicit proposed 3D interpretation, "
             "not measurements taken from the perspective picture. Counts are individually enumerated. "
             "No unseen counterpart is added by symmetry. A stand-in is not a production fitting.", "",
             "Frame: +X bow, +Y port, +Z up. Station 0% is the foremost claw tip; 100% is the aft-most fitting. "
             "Offset is signed world units from the centreline. Aim is a unit vector in this frame. "
             "Every row is ONE mount, dish, claw, chain run or engine. A twin has two barrels. "
             "A launcher has ten individual tubes. Engine directions may point aft; gun directions may not.", "",
             "| ID | Fitting | Count | Station % | Offset units | Height units | Aim X,Y,Z | Evidence / open work |",
             "|---|---|---:|---:|---:|---:|---|---|"]
    for f in fs:
        a = f["aim"]; n = math.sqrt(sum(v*v for v in a)); a = [v/n for v in a]
        lines.append(f"| {f['id']} | {f['kind'].replace('_', ' ')} | 1 | {100*f['station']:.1f} | "
                     f"{f['offset']*d['length']:+.3f} | {f['height']*d['length']:+.3f} | "
                     + ",".join(f"{v:+.3f}" for v in a) + f" | {f['evidence']} |")
    lines += ["", "## TO BE DESIGNED", ""] + ["- " + x for x in data["unresolved"]]
    lines += ["", "The neutral belly and far engine caps in the blockout are closure placeholders. "
              "Their outer envelope can be measured; no hidden machinery is approved by those surfaces. "
              "Top views omit belly-only claws through genuine occlusion by the hull where applicable. "
              "Far-side mounts hidden in port profile are shown in the dashed register below that view.", "",
              "## Rebuild", "", "Run `tools/recipe/build_sheets_532.bat`. The blockout .blend stays in "
              f"`{root / code / (code + '_blockout.blend')}`. "
              "The JSON in this folder is the placement source for all renders and the table.", "",
              "Refs", "", "- ../../../../contrib/muse/design/concept_round8_2026_11/" + code + "_beauty.jpg",
              "- ../../../../contrib/muse/design/concept_directions_2026_11/corsair_" + ("A" if d["big"] else "B") + ".jpg",
              "- ../../../../contrib/muse/design/concept_standard_2026_11/standard.md", ""]
    (out / "feature_table.md").write_text("\n".join(lines), encoding="ascii")
    return data


def prep(root):
    import numpy as np
    from PIL import Image, ImageDraw
    from scipy import ndimage as nd
    polygons = {
        "corsair_A16": [(66,970),(72,875),(164,680),(164,620),(202,560),(205,458),
                        (315,421),(342,335),(470,340),(590,270),(600,236),(722,242),
                        (725,194),(880,202),(892,176),(958,126),(1108,123),(1163,90),
                        (1194,58),(1305,47),(1399,28),(1407,50),(1438,70),(1550,48),
                        (1626,79),(1680,173),(1705,217),(1784,215),(1858,260),
                        (1858,382),(1800,454),(1769,520),(1700,550),(1535,630),
                        (1490,730),(1340,800),(1230,865),(1150,926),(1015,978),
                        (860,1040),(660,1071),(650,1175),(586,1235),(499,1257),
                        (457,1241),(457,1171),(481,1092),(427,1042),(330,1020),
                        (277,1100),(251,1170),(210,1210),(221,1128),(234,1040),(145,1008)],
        "corsair_A17": [(42,963),(58,896),(110,816),(139,776),(129,696),(140,648),
                        (183,625),(180,531),(190,455),(221,414),(274,421),(318,471),
                        (366,417),(352,404),(356,388),(419,387),(416,326),(510,326),
                        (580,260),(680,241),(704,206),(804,182),(850,193),(920,161),
                        (1007,137),(1082,107),(1190,100),(1260,131),(1307,177),
                        (1373,160),(1422,177),(1431,213),(1506,229),(1548,252),
                        (1572,297),(1605,319),(1595,363),(1530,398),(1502,442),
                        (1505,510),(1507,540),(1447,542),(1460,620),(1402,682),
                        (1370,716),(1304,774),(1269,790),(1190,831),(1110,880),
                        (1035,925),(959,965),(842,1006),(724,1045),(653,1099),
                        (562,1146),(502,1154),(449,1137),(441,1115),(485,1092),
                        (516,1043),(526,1000),(466,952),(416,918),(340,927),
                        (288,1002),(236,1036),(173,1042),(124,1020),(159,995),
                        (217,971),(225,936),(170,905),(106,945),(71,975)]}
    for code in polygons:
        d = spec(code); data = write_table(d, root); p = root / code; p.mkdir(parents=True, exist_ok=True)
        im = Image.open(d["beauty"]).convert("RGB"); roi = Image.new("L", im.size)
        ImageDraw.Draw(roi).polygon(polygons[code], fill=255)
        a = np.asarray(im); region = np.asarray(roi) > 0
        # Near-black armour is foreground. A low threshold preserves it while
        # the manual ROI excludes the escort, stars and most exhaust.
        mask = (a.max(2) > 8) & region
        mask = nd.binary_closing(mask, iterations=4)
        labels, n = nd.label(mask); counts = np.bincount(labels.ravel()); counts[0] = 0
        mask = nd.binary_fill_holes(labels == counts.argmax())
        alpha = Image.fromarray((mask*255).astype("uint8")); rgba = im.convert("RGBA"); rgba.putalpha(alpha)
        rgba.save(p / "concept_cut.png"); alpha.save(p / "concept_mask.png")
        data["mask_pixels"] = int(mask.sum()); data["mask_method"] = "Manual main-ship ROI, RGB max > 8, closing radius 4, largest component, holes filled; escort excluded; retained dark-armour edges reviewed visually"
        (p / "inputs.json").write_text(json.dumps(data, indent=2), encoding="ascii")
        print("PREP", code, mask.sum(), flush=True)


def shape(root):
    # Use the installed recipe's Windows kernel fallbacks without executing its
    # fleet loop. Only the function definition is loaded from that source.
    if all((root/code/"shape_reference_v2.glb").exists() for code in ("corsair_A16","corsair_A17")):
        print("SHAPE: both corrected guides already exist; reusing them",flush=True)
        return
    import ast
    code_dir = Path(os.environ["USERPROFILE"]) / "Downloads/trellis2/code"
    sys.path.insert(0, str(code_dir)); os.chdir(code_dir)
    os.environ["OPENCV_IO_ENABLE_OPENEXR"] = "1"
    os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"
    import torch
    from PIL import Image
    src = ast.parse((REPO / "tools/pc/trellis_fleet.py").read_text())
    func = next(x for x in src.body if isinstance(x, ast.FunctionDef) and x.name == "apply_patches")
    ns = {"log": print}; exec(compile(ast.Module(body=[func], type_ignores=[]), "patches", "exec"), ns); ns["apply_patches"]()
    from trellis2.pipelines import Trellis2ImageTo3DPipeline
    import trimesh
    pipe = Trellis2ImageTo3DPipeline.from_pretrained("microsoft/TRELLIS.2-4B"); pipe.cuda()
    for code in ("corsair_A16", "corsair_A17"):
        p = root / code; target = p / "shape_reference_v2.glb"
        if target.exists(): continue
        meshes = pipe.run(Image.open(p / "concept_cut.png"), seed=1234, pipeline_type="512")
        m = meshes[0]
        trimesh.Trimesh(vertices=m.vertices.cpu().numpy(), faces=m.faces.cpu().numpy(), process=False).export(target)
        print("SHAPE", target, flush=True)
        del meshes, m; torch.cuda.empty_cache()


def main():
    a = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else sys.argv[1:]
    cmd, root = a[0], Path(a[1]).resolve()
    if cmd == "prep": prep(root)
    elif cmd == "shape": shape(root)
    else:
        sys.path.insert(0, str(Path(__file__).parent))
        from build_sheets_532_geometry import dispatch
        dispatch(cmd, root)


if __name__ == "__main__": main()
