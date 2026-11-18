"""Review baked GLB paint and loose debris without loading Blender or Godot."""

import argparse
from collections import Counter, defaultdict
import hashlib
from io import BytesIO
from itertools import product
import json
import math
from pathlib import Path
import re
import struct
from urllib.parse import unquote

from PIL import Image


ROOT = Path(__file__).resolve().parents[4]
IDENTITY = (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
SRGB = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4
        for v in (i / 255 for i in range(256))]
JUMP_DELTA_E = 18


def percentile(values, fraction):
    values = sorted(values)
    return values[round(fraction * (len(values) - 1))] if values else None


def lab(rgb):
    r, g, b = rgb
    def f(x):
        return x ** (1 / 3) if x > .008856 else 7.787 * x + 16 / 116
    x = f((.4124564*r + .3575761*g + .1804375*b) / .95047)
    y = f(.2126729*r + .7151522*g + .0721750*b)
    z = f((.0193339*r + .1191920*g + .9503041*b) / 1.08883)
    return 116*y - 16, 500*(x - y), 200*(y - z)


def bounds(points):
    x, y, z = zip(*points)
    return (min(x), min(y), min(z)), (max(x), max(y), max(z))


def gap(first, second):
    return math.hypot(*(max(first[0][i] - second[1][i], second[0][i] - first[1][i], 0)
                        for i in range(3)))


def transform(mat, p):
    x, y, z = p
    return tuple(mat[i]*x + mat[4+i]*y + mat[8+i]*z + mat[12+i] for i in range(3))


def matrix(node):
    if 'matrix' in node:
        return node['matrix']
    x, y, z, w = node.get('rotation', (0, 0, 0, 1))
    a, b, c = node.get('scale', (1, 1, 1))
    return (a*(1-2*(y*y+z*z)), a*2*(x*y+z*w), a*2*(x*z-y*w), 0,
            b*2*(x*y-z*w), b*(1-2*(x*x+z*z)), b*2*(y*z+x*w), 0,
            c*2*(x*z+y*w), c*2*(y*z-x*w), c*(1-2*(x*x+y*y)), 0,
            *node.get('translation', (0, 0, 0)), 1)


def multiply(a, b):
    return tuple(sum(a[k*4+row] * b[col*4+k] for k in range(4))
                 for col in range(4) for row in range(4))


class GLB:
    def __init__(self, path):
        self.path = path
        self.raw = path.read_bytes()
        magic, version, size = struct.unpack_from('<4sII', self.raw)
        if (magic, version, size) != (b'glTF', 2, len(self.raw)):
            raise ValueError('expected glTF 2 binary')
        length, kind = struct.unpack_from('<I4s', self.raw, 12)
        if kind != b'JSON' or self.raw[24+length:28+length] != b'BIN\0':
            raise ValueError('expected JSON and BIN chunks')
        self.doc = json.loads(self.raw[20:20+length])
        self.binary = memoryview(self.raw)[28+length:]
        self.images = {}

    def view(self, index):
        view = self.doc['bufferViews'][index]
        if view['buffer'] != 0:
            raise ValueError('expected embedded buffer')
        offset = view.get('byteOffset', 0)
        return self.binary[offset:offset+view['byteLength']], view.get('byteStride')

    def accessor(self, index):
        acc = self.doc['accessors'][index]
        if 'sparse' in acc or 'bufferView' not in acc:
            raise ValueError('unsupported sparse accessor')
        data, stride = self.view(acc['bufferView'])
        count = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[acc['type']]
        fmt, divisor = {5120: ('b', 127), 5121: ('B', 255), 5122: ('h', 32767),
                        5123: ('H', 65535), 5125: ('I', 4294967295), 5126: ('f', 1)}[acc['componentType']]
        item = struct.Struct('<' + fmt * count)
        start = acc.get('byteOffset', 0)
        if stride is None or stride == item.size:
            values = list(item.iter_unpack(data[start:start+acc['count']*item.size]))
        else:
            values = [item.unpack_from(data, start+i*stride) for i in range(acc['count'])]
        if acc.get('normalized') and divisor != 1:
            return [tuple(max(-1, v/divisor) for v in value) for value in values]
        return values

    def image(self, texture):
        binding = self.doc['textures'][texture['index']]
        index = binding['source']
        if index not in self.images:
            image = self.doc['images'][index]
            src = (BytesIO(self.view(image['bufferView'])[0]) if 'bufferView' in image
                   else self.path.parent / unquote(image['uri']))
            with Image.open(src) as decoded:
                self.images[index] = decoded.convert('RGB')
        return self.images[index]

    def nodes(self):
        def walk(ids, parent):
            for i in ids:
                node = self.doc['nodes'][i]
                name = node.get('name', f'node {i}')
                # A4 embeds alternate breach skins at the same position. Their
                # separate damage/wreck exports get rows of their own.
                if re.search(r'_skin_(?:[0-9]|bow)', name):
                    continue
                pose = multiply(parent, matrix(node))
                if 'mesh' in node:
                    yield name, pose, self.doc['meshes'][node['mesh']]['primitives']
                yield from walk(node.get('children', []), pose)
        yield from walk(self.doc['scenes'][self.doc.get('scene', 0)]['nodes'], IDENTITY)


def rgb_at(img, uv, texture, sampler):
    u, v = uv
    tx = texture.get('extensions', {}).get('KHR_texture_transform', {})
    sx, sy = tx.get('scale', (1, 1))
    ox, oy = tx.get('offset', (0, 0))
    angle = tx.get('rotation', 0)
    cu, si = math.cos(angle), math.sin(angle)
    u, v = ox + cu*u*sx - si*v*sy, oy + si*u*sx + cu*v*sy
    def address(x, wrap):
        if wrap == 33071:
            return min(1, max(0, x))
        return 1 - abs(x % 2 - 1) if wrap == 33648 else x % 1
    pixel = img.getpixel((min(img.width-1, int(address(u, sampler.get('wrapS')) * img.width)),
                          min(img.height-1, int(address(v, sampler.get('wrapT')) * img.height))))
    return [SRGB[v] for v in pixel]


def area(a, b, c):
    x, y, z = (b[i] - a[i] for i in range(3))
    u, v, w = (c[i] - a[i] for i in range(3))
    return .5 * math.hypot(y*w - z*v, z*u - x*w, x*v - y*u)


def islands(points, triangles):
    # Weld on position to restore seams split by normals/UVs. Union across
    # triangle edges so separate parts touching at one point stay separate.
    ids = {}
    weld = [ids.setdefault(tuple(round(x, 7) for x in p), len(ids)) for p in points]
    parent = list(range(len(triangles)))
    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    edges = {}
    for i, (a, b, c) in enumerate(triangles):
        a, b, c = weld[a], weld[b], weld[c]
        for u, v in ((a, b), (b, c), (c, a)):
            if u != v:
                other = edges.setdefault((min(u, v), max(u, v)), i)
                if other != i:
                    parent[root(i)] = root(other)
    groups = defaultdict(list)
    for i, face in enumerate(triangles):
        groups[root(i)].append(face)
    return groups.values()


def box_shape(points, faces):
    if len(points) == 4 and len(faces) == 2:
        return 'quad'
    if len(points) != 8 or len(faces) != 12:
        return None
    # Three edges at one corner generate the eight corners of a rectangular
    # box. Testing the corner sums catches rotated boxes and rejects wedges.
    origin, *corners = sorted(points)
    vectors = [tuple(p[i]-origin[i] for i in range(3)) for p in corners]
    scale = max(math.hypot(*p) for p in vectors)
    if not scale:
        return None
    for u in vectors:
        for v in vectors:
            if u == v or abs(sum(x*y for x, y in zip(u, v))) > scale*scale*1e-5:
                continue
            for w in vectors:
                if w in (u, v) or any(abs(sum(x*y for x, y in zip(w, k))) > scale*scale*1e-5 for k in (u, v)):
                    continue
                expected = [tuple(origin[i]+a*u[i]+b*v[i]+c*w[i] for i in range(3))
                            for a, b, c in product((0, 1), repeat=3)]
                if all(any(math.dist(p, q) < scale*1e-4 for q in points) for p in expected):
                    lengths = sorted(math.hypot(*e) for e in (u, v, w))
                    return 'slab' if lengths[0] < .20*lengths[1] else 'box'
    return None


def read_surface(glb, name, pose, primitive):
    attrs = primitive['attributes']
    if primitive.get('mode', 4) != 4:
        raise ValueError(f'{name}: expected triangle list')
    points = glb.accessor(attrs['POSITION'])
    indices = ([i[0] for i in glb.accessor(primitive['indices'])] if 'indices' in primitive
               else list(range(len(points))))
    triangles = list(zip(indices[::3], indices[1::3], indices[2::3]))
    world = points if pose == IDENTITY else [transform(pose, p) for p in points]
    mat_id = primitive.get('material', -1)
    mat = glb.doc['materials'][mat_id] if mat_id >= 0 else {}
    pbr = mat.get('pbrMetallicRoughness', {})
    texture = pbr.get('baseColorTexture')
    image = glb.image(texture) if texture else None
    mapping = texture.get('extensions', {}).get('KHR_texture_transform', {}) if texture else {}
    uv_id = attrs.get(f"TEXCOORD_{mapping.get('texCoord', texture.get('texCoord', 0) if texture else 0)}")
    uv = glb.accessor(uv_id) if uv_id is not None else None
    colors = glb.accessor(attrs['COLOR_0']) if 'COLOR_0' in attrs else None
    factor = pbr.get('baseColorFactor', (1, 1, 1, 1))
    sampler_id = glb.doc['textures'][texture['index']].get('sampler') if texture else None
    sampler = glb.doc['samplers'][sampler_id] if sampler_id is not None else {}
    pieces = []
    sampled = []
    density = []
    total_area = 0.0
    surface_box = bounds(world)
    for faces in islands(points, triangles):
        all_ids = set(i for face in faces for i in face)
        box = bounds([world[i] for i in all_ids])
        if not math.dist(*box):
            continue
        samples = []
        patch_area = 0.0
        for a, b, c in faces[::max(1, len(faces)//24)][:32]:
            face_area = area(world[a], world[b], world[c])
            if face_area <= 0:
                continue
            patch_area += face_area
            if image and uv:
                u, v = ((uv[a][j]+uv[b][j]+uv[c][j])/3 for j in range(2))
                rgb = rgb_at(image, (u, v), texture, sampler)
                uv_area = abs((uv[b][0]-uv[a][0])*(uv[c][1]-uv[a][1]) -
                              (uv[b][1]-uv[a][1])*(uv[c][0]-uv[a][0]))*.5
                us, vs = mapping.get('scale', (1, 1))
                density.append(math.sqrt(uv_area * abs(us*vs) * image.width * image.height / face_area))
            else:
                rgb = (1, 1, 1)
            samples.append(lab([rgb[j]*factor[j]*((colors[a][j]+colors[b][j]+colors[c][j])/3 if colors else 1)
                                for j in range(3)]))
        if not samples:
            continue
        total_area += patch_area * len(faces) / len(samples)
        sampled.extend(samples)
        average = tuple(sum(channel) / len(samples) for channel in zip(*samples))
        shape = box_shape({world[i] for i in all_ids}, faces) if len(all_ids) <= 24 else None
        pieces.append((box, average, shape, len(faces)))
    center = tuple(percentile(channel, .5) for channel in zip(*sampled))
    spread = percentile([math.dist(p, center) for p in sampled], .9)
    name_mat = mat.get('name', f'material {mat_id}')
    emissive = ('baseColorTexture' not in pbr and max(mat.get('emissiveFactor', [0])) > 0
                or bool(re.search(r'glow|glass_(lit|dark)|hwin|lamp|light$', name_mat, re.I)))
    return pieces, surface_box, {
        'module': name, 'material': name_mat, 'triangles': len(triangles),
        'islands': len(pieces), 'area_estimate': total_area, 'albedo_spread': spread,
        'base_map': image is not None, 'normal_map': 'normalTexture' in mat,
        'orm_map': 'metallicRoughnessTexture' in pbr or 'occlusionTexture' in mat,
        'vertex_color': colors is not None, 'emissive': emissive,
        'texels_per_unit_p10': percentile(density, .10), 'texels_per_unit_p50': percentile(density, .50),
    }


def neighbours(pieces, length):
    # Fixed-radius search in model units. Use same-size pieces, so a bulb or
    # decal next to a deck does not stand in for two adjacent armour plates.
    cell = length * .055
    bins = defaultdict(list)
    centers = []
    for i, (box, _, _, _) in enumerate(pieces):
        center = tuple((a+b)/2 for a, b in zip(*box))
        centers.append(center)
        bins[tuple(math.floor(c/cell) for c in center)].append(i)
    pairs = set()
    for i, ((box, _, _, _), center) in enumerate(zip(pieces, centers)):
        span = math.dist(*box)
        if not .002*length <= span <= .105*length:
            continue
        origin = tuple(math.floor(c/cell) for c in center)
        nearest = []
        for offset in product((-1, 0, 1), repeat=3):
            key = tuple(a+b for a, b in zip(origin, offset))
            for j in bins.get(key, ()):
                if i == j:
                    continue
                other = pieces[j][0]
                span2 = math.dist(*other)
                d = math.dist(center, centers[j])
                if .3*span <= span2 <= span/.3 and .20*min(span, span2) < d < 1.25*max(span, span2):
                    air = gap(box, other)
                    if air <= min(.009*length, .45*min(span, span2)):
                        nearest.append((air+.10*d, j))
        for _, j in sorted(nearest)[:2]:
            pairs.add((min(i, j), max(i, j)))
    return sorted(pairs)


class BoundsTree:
    def __init__(self, entries):
        self.box = bounds([p for box, _ in entries for p in box])
        self.entries = entries
        self.children = ()
        if len(entries) > 12:
            axis = max(range(3), key=lambda k: self.box[1][k]-self.box[0][k])
            entries.sort(key=lambda entry: entry[0][0][axis]+entry[0][1][axis])
            mid = len(entries)//2
            self.children = (BoundsTree(entries[:mid]), BoundsTree(entries[mid:]))
            self.entries = ()

    def supported(self, box, own_id, span, clearance):
        if gap(self.box, box) > clearance:
            return False
        if self.children:
            return any(child.supported(box, own_id, span, clearance) for child in self.children)
        return any(i != own_id and math.dist(*other) >= .45*span and gap(other, box) <= clearance
                   for other, i in self.entries)


def loose_shapes(pieces, modules, length):
    tree = BoundsTree([(p[0], i) for i, p in enumerate(pieces)])
    counts = Counter()
    for i, (box, _, shape, _, module) in enumerate(pieces):
        span = math.dist(*box)
        if shape and .002*length <= span <= .06*length and not tree.supported(box, i, span, span*.08):
            row = modules[module]
            counts[row['module'], row['material'], shape] += 1
    return [dict(module=n, material=m, shape=s, count=count)
            for (n, m, s), count in sorted(counts.items())]


def review(path, faction, label=None):
    glb = GLB(path)
    modules = []
    pieces = []
    surface_boxes = []
    for name, pose, primitives in glb.nodes():
        for primitive in primitives:
            surface_pieces, box, row = read_surface(glb, name, pose, primitive)
            pieces.extend((*piece, len(modules)) for piece in surface_pieces)
            surface_boxes.append(box)
            modules.append(row)
    if not pieces:
        raise ValueError('no visible triangles')
    length = max(b - a for a, b in zip(*bounds([p for box in surface_boxes for p in box])))
    limit = JUMP_DELTA_E
    groups = defaultdict(list)
    for box, color, shape, faces, module in pieces:
        if faces >= 2 and not modules[module]['emissive'] and not re.search(r'inside|liner', modules[module]['material'], re.I):
            groups[modules[module]['material']].append((box, color, shape, faces))
    jumps = []
    material_jumps = {}
    for material, group in groups.items():
        deltas = [math.dist(group[i][1], group[j][1]) for i, j in neighbours(group, length)]
        jumps += deltas
        if deltas:
            material_jumps[material] = {'pairs': len(deltas), 'p90': percentile(deltas, .90),
                                        'above_limit': sum(delta >= limit for delta in deltas)}
    loud = sum(delta >= limit for delta in jumps)
    loose = loose_shapes(pieces, modules, length)
    findings = []
    for row in modules:
        row['no_detail_map'] = not (row['normal_map'] or row['orm_map'] or row['base_map'])
        row['flat_albedo'] = row['albedo_spread'] is not None and row['albedo_spread'] < 2.0
        if row['no_detail_map'] and not row['emissive']:
            findings.append('missing_detail_map')
        if row['flat_albedo'] and not row['emissive']:
            findings.append('flat_albedo')
    if any(m['pairs'] >= 12 and m['above_limit'] / m['pairs'] >= .10 for m in material_jumps.values()):
        findings.append('neighbour_colour_jumps')
    if loose:
        findings.append('loose_box_or_quad')
    return {'model': label or path.stem, 'faction': faction, 'sha256': hashlib.sha256(glb.raw).hexdigest(),
            'model_span': length, 'surfaces': modules, 'findings': dict(Counter(findings)),
            'jump': {'limit_delta_e76': limit, 'pairs': len(jumps), 'p50': percentile(jumps, .5),
                     'p90': percentile(jumps, .9), 'above_limit': loud, 'by_material': material_jumps},
            'loose_pieces': loose}


def installed(path):
    manifest = json.loads((path / 'manifest.json').read_text(encoding='utf-8-sig'))
    for code, info in sorted(manifest['ships'].items()):
        folder = path / code
        yield folder / (code + '.glb'), info.get('faction', ''), code
        for variant in sorted(folder.glob(code + '_*.glb')):
            yield variant, info.get('faction', ''), variant.stem


def self_test():
    assert math.dist(lab((0, 0, 0)), lab((1, 1, 1))) > 99
    assert math.isclose(math.dist(lab((.5, .5, .5)), lab((.51, .51, .51))), .61, abs_tol=.03)
    box = ((0, 0, 0), (1, 1, 1))
    adjacent = ((1.05, 0, 0), (2.05, 1, 1))
    assert neighbours([(box, None, None, 12), (adjacent, None, None, 12)], 20) == [(0, 1)]
    assert len(list(islands([(0, 0, 0), (0, 1, 0), (1, 0, 0), (0, 1, 0), (0, 0, 0), (-1, 0, 0)],
                            [(0, 1, 2), (3, 4, 5)]))) == 1
    corners = set(product((0, 1), (0, 1), (0, 1)))
    assert box_shape(corners, [None]*12) == 'box'
    assert box_shape({(x, y, z*.1) for x, y, z in corners}, [None]*12) == 'slab'
    assert box_shape((corners - {(1, 1, 1)}) | {(1, 1, 1.2)}, [None]*12) is None
    tree = BoundsTree([(box, 0), (adjacent, 1)])
    assert tree.supported(box, 0, 1, .08) and not tree.supported(box, 0, 1, .01)
    detached = ((5, 4, 0), (6, 5, 1))
    actual = loose_shapes([(box, None, 'box', 12, 0), (adjacent, None, None, 24, 0),
                           (detached, None, 'box', 12, 0)], [{'module': 'hull', 'material': 'metal'}], 50)
    assert actual == [dict(module='hull', material='metal', shape='box', count=1)]
    print('PASS paint_lint: colour, welded islands, adjacency and a planted loose box')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('glb', nargs='*', type=Path, help='extra GLB models, such as the station run 2 reference')
    parser.add_argument('--installed', type=Path, action='append', default=[], help='assets/ships directory with manifest')
    parser.add_argument('--faction', default='', help='faction id for extra GLBs')
    parser.add_argument('--json', type=Path, help='write detailed, machine-readable results')
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--strict', action='store_true', help='return 1 when an asset triggers any review flag')
    args = parser.parse_args()
    if args.self_test:
        self_test()
    if not args.self_test and not (args.glb or args.installed):
        args.installed = [ROOT / 'godot/assets/ships']
    inputs = [(p, args.faction, p.stem) for p in args.glb]
    for folder in args.installed:
        try:
            inputs.extend(installed(folder))
        except (OSError, ValueError, KeyError) as exc:
            print(f'Cannot read installed manifest: {exc}')
            return 2
    rows = []
    for path, faction, label in inputs:
        try:
            result = review(path, faction, label)
            rows.append(result)
            j = result['jump']
            print(f"{label}: {len(result['surfaces'])} surfaces, {j['pairs']} pairs, p90 {j['p90']}, {result['findings']}", flush=True)
        except (OSError, ValueError, KeyError, IndexError, struct.error) as exc:
            rows.append({'model': label, 'faction': faction, 'error': str(exc).replace(str(path.parent), '.')})
            print(f'{label}: SKIP {rows[-1]["error"]}', flush=True)
    if args.json:
        args.json.write_text(json.dumps(rows, indent=2) + '\n', encoding='utf-8')
    if any('error' in row for row in rows):
        return 2
    return int(args.strict and any(row.get('findings') for row in rows))


if __name__ == '__main__':
    raise SystemExit(main())
