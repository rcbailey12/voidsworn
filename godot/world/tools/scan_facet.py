#!/usr/bin/env python3
"""Issue 1361 (World V2, R419): re-bake the fresh-face channel (COLOR_0.b, the shader's `facet`) on the scanned rocks.

planet369_remix.py wrote 1 - roughness into COLOR_0.b. The scans are rough everywhere, so the channel came out crushed
(mean 0.09 to 0.24, range under 0.3) and every shader branch that reads it went quiet: no metal on iron, specks of ice,
no crystal veins. This script replaces it with the scan's own ridge and edge convexity at two scales, ranked per mesh so
every scan spans 0 to 1 with the same spread (mean about 0.4, like rockgen.py's procedural rocks).

The far mesh (_lo) takes the mean value of the full mesh's vertices in its own clustering cell (planet369_remix.py
cluster(), grid 13), so the near and far rock carry the same pattern. Only the colour bytes change; the files keep their
size and layout. Run: python3 scan_facet.py ROCK_DIR scan_00 scan_01 ...   (numpy only; prints the new sha256 and stats)
"""
import sys, json, struct, hashlib
from pathlib import Path
import numpy as np

GRID = 13          # planet369_remix.py cluster() grid for the _lo meshes
CURVE = 1.5        # rank ** CURVE: mean about 0.4, a few bright ridges at 1


def read(path):
    b = path.read_bytes()
    jl = struct.unpack('<I', b[12:16])[0]
    doc = json.loads(b[20:20 + jl])
    bin_start = 20 + jl + 8
    prim = doc['meshes'][0]['primitives'][0]

    def acc(i):
        a = doc['accessors'][i]
        v = doc['bufferViews'][a['bufferView']]
        n = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4}[a['type']]
        dt = {5126: '<f4', 5125: '<u4'}[a['componentType']]
        off = bin_start + v.get('byteOffset', 0) + a.get('byteOffset', 0)
        assert 'byteStride' not in v
        return np.frombuffer(b, dt, a['count'] * n, off).reshape(-1, n), off

    P, _ = acc(prim['attributes']['POSITION'])
    N, _ = acc(prim['attributes']['NORMAL'])
    C, coff = acc(prim['attributes']['COLOR_0'])
    I, _ = acc(prim['indices'])
    return b, P.astype(np.float64), N.astype(np.float64), C.copy(), coff, I.reshape(-1, 3)


def smooth(val, ii, n, steps):
    # one-ring averaging through the triangle edges, `steps` times
    a = np.concatenate([ii[:, 0], ii[:, 1], ii[:, 2], ii[:, 1], ii[:, 2], ii[:, 0]])
    c = np.concatenate([ii[:, 1], ii[:, 2], ii[:, 0], ii[:, 0], ii[:, 1], ii[:, 2]])
    deg = np.bincount(a, minlength=n).astype(np.float64) + 1.0
    for _ in range(steps):
        val = (np.bincount(a, weights=val[c], minlength=n) + val) / deg
    return val


def convexity(P, N, ii):
    n = len(P)
    a = np.concatenate([ii[:, 0], ii[:, 1], ii[:, 2], ii[:, 1], ii[:, 2], ii[:, 0]])
    c = np.concatenate([ii[:, 1], ii[:, 2], ii[:, 0], ii[:, 0], ii[:, 1], ii[:, 2]])
    deg = np.maximum(np.bincount(a, minlength=n), 1).astype(np.float64)
    mean = np.stack([np.bincount(a, weights=P[c, k], minlength=n) for k in range(3)], 1) / deg[:, None]
    edge = np.linalg.norm(P[ii[:, 0]] - P[ii[:, 1]], axis=1).mean()
    # neighbours' mean below the vertex along its normal: a ridge or an edge (positive), a hollow (negative)
    cv = np.einsum('ij,ij->i', P - mean, N) / max(edge, 1e-9)
    fine = smooth(cv, ii, n, 2)
    broad = smooth(cv, ii, n, 12)
    return fine * 0.55 + broad / max(np.std(broad), 1e-9) * np.std(fine) * 0.45


def ranked(v):
    r = np.empty(len(v))
    r[np.argsort(v, kind='stable')] = np.linspace(0.0, 1.0, len(v))
    return r ** CURVE


def cell_keys(P):
    k = np.floor((P + 1.0) * GRID).astype(np.int64)
    return (k[:, 0] * 4096 + k[:, 1]) * 4096 + k[:, 2]


def write(path, b, coff, C):
    out = bytearray(b)
    blob = C.astype('<f4').tobytes()
    out[coff:coff + len(blob)] = blob
    path.write_bytes(bytes(out))
    return hashlib.sha256(bytes(out)).hexdigest()


def main():
    root = Path(sys.argv[1])
    for name in sys.argv[2:]:
        b, P, N, C, coff, ii = read(root / f'{name}.glb')
        # weld split vertices (UV seams) by position, so the one-ring sees across seams
        _, first, weld = np.unique(np.round(P * 1e5).astype(np.int64), axis=0, return_index=True, return_inverse=True)
        weld = weld.reshape(-1)
        wn = np.zeros((len(first), 3))
        np.add.at(wn, weld, N)
        wn /= np.maximum(np.linalg.norm(wn, axis=1, keepdims=True), 1e-9)
        facet = ranked(convexity(P[first], wn, weld[ii]))[weld]
        C[:, 2] = facet
        sha = write(root / f'{name}.glb', b, coff, C)
        print(name, 'b mean %.2f p2 %.2f p98 %.2f' % (facet.mean(), np.percentile(facet, 2), np.percentile(facet, 98)), sha)
        # far mesh: the cell mean of the full mesh
        keys = cell_keys(P)
        uk, inv = np.unique(keys, return_inverse=True)
        cell_mean = np.bincount(inv, weights=facet) / np.bincount(inv)
        lb, LP, _, LC, lcoff, _ = read(root / f'{name}_lo.glb')
        lk = cell_keys(LP)
        pos = np.searchsorted(uk, lk)
        pos = np.clip(pos, 0, len(uk) - 1)
        hit = uk[pos] == lk
        lf = np.where(hit, cell_mean[pos], np.nan)
        if (~hit).any():
            # a far vertex outside every cell: nearest full vertex
            for j in np.nonzero(~hit)[0]:
                lf[j] = facet[np.argmin(np.sum((P - LP[j]) ** 2, axis=1))]
        LC[:, 2] = lf
        lsha = write(root / f'{name}_lo.glb', lb, lcoff, LC)
        print(name + '_lo', 'b mean %.2f p2 %.2f p98 %.2f misses %d' % (lf.mean(), np.percentile(lf, 2), np.percentile(lf, 98), (~hit).sum()), lsha)


if __name__ == '__main__':
    main()
