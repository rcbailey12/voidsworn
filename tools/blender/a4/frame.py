# A4 frames (K1 decision 2). The game's hull files store x bow, y up, z port, which is right in Babylon (left-handed). Read as-is by a
# right-handed tool they come out mirrored, so A4 reflects once at load:
#   game file (gx, gy, gz)  ->  Blender working frame (bx, by, bz) = (gx, gz, gy): x bow, y PORT, z up, true chirality
#   Blender working frame   ->  glTF / Godot (x, y, z) = (bx, bz, -by): x bow, y up, -z port, +z starboard (Blender's own glTF export map)
# The reflection flips triangle orientation, so the loader reverses the winding (checked by signed volume).
# No Blender needed here.
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
for p in (os.path.join(HERE, '..', 'a2detail'),):
    if p not in sys.path: sys.path.insert(0, p)
import hullio


def yaw_game(p, yaw):
    """the game's AI_HULL_YAW turn (ships3d.js applyAIHull), applied in the game frame: +1 turns -z to the bow, -1 turns +z"""
    if not yaw: return p
    p = p.copy(); x = p[:, 0].copy(); z = p[:, 2].copy()
    if yaw == 2:  # A4 addition: a hull meshed back to front (the bow at -x), turned half round
        p[:, 0] = -x; p[:, 2] = -z; return p
    p[:, 0] = -z if yaw > 0 else z; p[:, 2] = x if yaw > 0 else -x
    return p


def roll_game(p, roll):
    """A4 addition: roll about the bow axis in quarter turns (game frame: y up, z port); +1 brings port (+z) up to +y"""
    if not roll: return p
    p = p.copy(); y = p[:, 1].copy(); z = p[:, 2].copy()
    for _ in range(roll % 4): y, z = z, -y
    p[:, 1] = y; p[:, 2] = z; return p


def game_to_bl(p):
    p = np.asarray(p, np.float32); return np.stack([p[:, 0], p[:, 2], p[:, 1]], 1)


def bl_to_gl(p):
    p = np.asarray(p, np.float32); return np.stack([p[:, 0], p[:, 2], -p[:, 1]], 1)


def gl_to_bl(p):
    p = np.asarray(p, np.float32); return np.stack([p[:, 0], -p[:, 2], p[:, 1]], 1)


def signed_volume(p, idx):
    a, b, c = p[idx[:, 0]], p[idx[:, 1]], p[idx[:, 2]]
    return float(np.einsum('ij,ij->i', a, np.cross(b, c)).sum() / 6.0)


def load(root, code, yaw=0, folder='hulls_hi', roll=0):
    """hull in the Blender working frame with outward winding: dict(pos, nor, idx, uv2 (v-down), tex, flipped)"""
    h = hullio.load_hull(root, code, folder)
    pos = game_to_bl(roll_game(yaw_game(h['pos'], yaw), roll)); nor = game_to_bl(roll_game(yaw_game(h['nor'], yaw), roll)); idx = h['idx'][:, ::-1].copy()
    flipped = False
    if signed_volume(pos, idx) < 0: idx = idx[:, ::-1].copy(); flipped = True  # open AI meshes: trust the volume sign, not the convention
    return dict(pos=pos, nor=nor, idx=idx, uv2=h['uv2'], tex=h['tex'], flipped=flipped)
