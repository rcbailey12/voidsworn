# Read a .glb into its JSON document and binary blob. Standard library only, so stage 7 (manifest_merge.py) can read an
# export's texture list without numpy; check_export.py re-exports it (issue 1180: the CI host has no numpy).
import json, struct


def read_glb(path):
    b = open(path, 'rb').read(); magic, ver, total = struct.unpack_from('<4sII', b, 0)
    if magic != b'glTF': raise ValueError('not a glb')
    off = 12; js = None; blob = b''
    while off < total:
        n, kind = struct.unpack_from('<I4s', b, off); data = b[off + 8:off + 8 + n]; off += 8 + n
        if kind == b'JSON': js = json.loads(data)
        elif kind == b'BIN\0': blob = data
    return js, blob
