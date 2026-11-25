# Issue 1943: concept options for the three missing torpedo bodies (Meridian Directorate, the Chorus, Eclipse), and the status
# picture of the four strike craft the brief listed as missing (all four are already published).
#
# Run headless with the PC Blender, through the GPU watchdog (tools/pc/tmo.bat):
#   blender -b -P contrib/opus/concepts/craft_1124/torpedo_sheets.py -- bodies <faction> <scratch>   build, paint, export 3 glbs
#   blender -b -P contrib/opus/concepts/craft_1124/torpedo_sheets.py -- sheet <faction> <scratch>    render the 3 options + scale strip
#   blender -b -P contrib/opus/concepts/craft_1124/torpedo_sheets.py -- status <scratch>             render the 4 published craft
# compose_sheets.py (system Python, Pillow) then lays the renders out as the review sheets.
#
# Each body is built in the old casing's frame (fx_weapons.gd _casing: x -1.15 to 1.15, +X nose, +Z up), so the game's own
# sizing (rk = k * pulse * ROUND_SIZE torp 0.5) fits it as it fits the Sunward torpedo. Every piece comes from the faction's
# part kit (tools/blender/kits/<kit>/parts.py) and is painted by the faction's paint stack through munitions.py paint(), as
# the two published bodies are. Nothing here is written into godot/; nothing is published.
import importlib.util
import json
import math
import os
import sys
import traceback

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..'))
KITS = os.path.join(REPO, 'tools', 'blender', 'kits')
sys.path.insert(0, os.path.join(KITS, 'shared'))
import bpy  # noqa: E402
from mathutils import Vector, Matrix  # noqa: E402
from geom import Part, revolve, prism, octa, block  # noqa: E402

BUILD = os.path.join(os.path.expanduser('~'), 'Downloads', 'voidsworn_test', 'build', 'godot', 'assets', 'ships')
X0, X1 = -1.15, 1.15


def _load(path, name):
    sp = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
    return m


MUN = _load(os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'munitions', 'munitions.py'), 'mun1943')


def kit(name, fn='parts.py'):
    return MUN.kit(name, fn)


def _sheet_mats():
    """the sheet kit's shared colour rows (tools/blender/build_sheets/kit.py MATS), read without running that module"""
    import ast
    src = open(os.path.join(REPO, 'tools', 'blender', 'build_sheets', 'kit.py'), encoding='utf-8').read()
    for node in ast.parse(src).body:
        if isinstance(node, ast.Assign) and any(getattr(t, 'id', '') == 'MATS' for t in node.targets):
            return ast.literal_eval(node.value)
    return {}


MATS = _sheet_mats()
# Eclipse light on a torpedo (brief, issue 1943): violet accents only, never orange or green. The kit's corona, core and lens
# are green, so on these bodies they become one violet glow, kept out of the paint stack as munitions.py keeps its oath band.
MATS['vglow'] = ((0.55, 0.30, 1.0), 1.5)   # 2.4 blew out to near white on the close-ups
GREEN_TO_VIOLET = {'corona': 'vglow', 'ecore': 'vglow', 'lens': 'vglow'}

# ship codes of the launcher drawn beside each faction's options (the build's installed glbs, length_world from the manifest)
LAUNCHER = {
    'hegemony': ('H9_23', 14.5, 'Vanguard cruiser H9_23'),
    'chorus': ('B22_11', 16.5, 'brood-sac carrier B22_11'),
    'deathless': ('D21_23', 14.5, 'zenith ring cruiser D21_23'),
}
STACK = {'hegemony': 'hegemony', 'chorus': 'chorus', 'deathless': 'eclipse'}
# the torpedo is a few pixels on the board: the dark finishes are lifted on the baked albedo, as the Sunward torpedo's is
# (munitions.py LIFT, Ryan Nov 20 "Brighten"); the pale Hegemony finish needs none
LIFT = {'hegemony': 1.0, 'chorus': 1.4, 'deathless': 1.8}


def _mat(name):
    m = bpy.data.materials.get(name)
    if m:
        return m
    rgb, em = MATS.get(name, ((0.2, 0.2, 0.2), 0))
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*rgb, 1)
    b.inputs['Roughness'].default_value = 0.55
    b.inputs['Metallic'].default_value = 0.3 if name in ('hmetal', 'htrim', 'gunv', 'steel') else 0.08
    if em:
        b.inputs['Emission Color'].default_value = (*rgb, 1)
        b.inputs['Emission Strength'].default_value = em
    return m


def _grp(cname):
    """the object a piece goes in: drive_* and vent* are parts (the parts atlas); bandseam_N and band_N are one object each
    (the Hegemony stack reads every *_bandseam_* hull object as one module joint); the rest is the hull"""
    for pre, kind in (('drive_', 'engine'), ('vent', 'vent')):
        if cname.startswith(pre):
            return 'part', kind, pre.rstrip('_')
    for pre in ('bandseam_', 'band_'):
        if cname.startswith(pre):
            return 'hull', '', pre + cname[len(pre):].split('_')[0]
    return 'hull', '', 'body'


def to_blender(part, name):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    by = {}
    for c in part.comps:
        role, kind, grp = _grp(c['name'])
        V, F = by.setdefault((role, kind, grp, c['mat']), ([], []))
        o = len(V); V.extend(tuple(v) for v in c['verts']); F.extend(tuple(i + o for i in f) for f in c['faces'])
    for (role, kind, grp, m), (V, F) in by.items():
        nm = '%s_%s_%s' % (name, grp, m)
        me = bpy.data.meshes.new(nm); me.from_pydata(V, [], F); me.validate(); me.update()
        for poly in me.polygons:
            poly.use_smooth = False
        ob = bpy.data.objects.new(nm, me); ob.data.materials.append(_mat(m))
        ob['role'] = role; ob['grp'] = grp
        if kind:
            ob['part_kind'] = kind
        bpy.context.scene.collection.objects.link(ob); ob.parent = root
    return root


def _put(p, part, prefix, M=None, remap=None):
    """add a kit part to the body under a name prefix, moved by M, with its materials remapped"""
    for c in part.comps:
        vs = [(M @ Vector(v)) if M is not None else Vector(v) for v in c['verts']]
        p.add(prefix + c['name'], c['role'], (remap or {}).get(c['mat'], c['mat']), (vs, c['faces']))


def _at(x, y=0.0, z=0.0):
    return Matrix.Translation(Vector((x, y, z)))


def _surface(p, tag, part, x, a, rad, remap=None):
    """a kit part built local +Z out placed on the body at station x, angle a round X (0 = +Y, pi/2 = +Z), radius rad"""
    nv = Vector((0, math.cos(a), math.sin(a)))
    M = Matrix.Translation(Vector((x, 0, 0)) + nv * rad) @ Matrix(((1, 0, 0), (0, -nv.z, nv.y), (0, nv.y, nv.z))).to_4x4()
    _put(p, part, tag + '_', M, remap)


def _fin(x0, x1, a, r0, h, t, sweep=0.6):
    return MUN._fin(x0, x1, a, r0, h, t, sweep)


# --------------------------------------------------------------------------------------------- Meridian Directorate (hegemony)
# factions.md: a pale machined wedge, flush modular panels, blue strip light, rectangular blue-white nozzles; no rust, no warm
# light, no ornament. Module bands at every joint (the stack keys its finish on them).
HG = None


def _hband(p, i, x, hw, hh, ch, yo=0.0):
    p.add('band_%d' % i, 'body', 'htrim', block(x - 0.045, x + 0.045, hw + 0.012, hh + 0.012, ch, yo=yo))
    p.add('bandseam_%d' % i, 'body', 'hgrey2', block(x - 0.008, x + 0.008, hw + 0.018, hh + 0.018, ch, yo=yo))


def _hstrip(p, x0, x1, hw, side):
    p.add('strip', 'body', 'hblue', block(x0, x1, 0.006, 0.014, 0, yo=side * (hw + 0.003)))


def _hdrive(p, w, h, body_len, cells, y=0.0, z=0.0, tag='drive_'):
    _put(p, HG.craft_drive(w, h, body_len, cells=cells), tag, _at(X0 + 0.02, y, z))


def heg_wedge():
    """HT-A wedge: an eight-sided machined body that flattens forward into a chisel wedge, two module bands, a blue strip down
    each flank, one three-cell rectangular drive"""
    p = Part('munition')
    hw, hh, ch = 0.25, 0.19, 0.06
    p.add('hull', 'body', 'hgrey', prism([(X0 + 0.05, octa(0.21, 0.16, 0.05)), (-0.85, octa(hw, hh, ch)), (0.35, octa(hw, hh, ch)),
                                          (0.85, octa(0.21, 0.11, 0.04)), (X1, octa(0.13, 0.025, 0.012))]))
    for x0, x1 in ((-0.80, -0.62), (-0.48, 0.10), (0.20, 0.32)):
        p.add('plate', 'body', 'hpanel', block(x0, x1, hw * 0.72, hh + 0.006, 0.02))
    _hband(p, 0, -0.55, hw, hh, ch); _hband(p, 1, 0.15, hw, hh, ch)
    for s in (1, -1):
        _hstrip(p, -0.45, 0.10, hw, s)
        p.add('vane', 'body', 'htrim', block(-1.05, -0.78, 0.012, 0.12, 0, yo=s * (hw + 0.07)))
    p.add('vane', 'body', 'htrim', block(-1.05, -0.78, 0.05, 0.10, 0, zo=hh + 0.06))
    _hdrive(p, 0.30, 0.17, 0.35, 3)
    return p


def heg_slab():
    """HT-B twin slab: a wide flat module block with a squared prow, a blue-white seeker slit in the prow, two module bands, a
    blue strip along the spine and two side-by-side two-cell drives"""
    p = Part('munition')
    hw, hh, ch = 0.30, 0.14, 0.04
    p.add('hull', 'body', 'hgrey', prism([(X0 + 0.05, octa(hw, hh, ch)), (0.55, octa(hw, hh, ch)), (0.95, octa(0.24, 0.11, 0.03)),
                                          (X1, octa(0.16, 0.07, 0.02))]))
    for x0, x1 in ((-0.95, -0.45), (-0.25, 0.25), (0.45, 0.80)):
        for s in (1, -1):
            p.add('plate', 'body', 'hpanel', block(x0, x1, hw * 0.38, hh + 0.005, 0.015, yo=s * hw * 0.48))
    _hband(p, 0, -0.35, hw, hh, ch); _hband(p, 1, 0.35, hw, hh, ch)
    p.add('strip', 'body', 'hblue', block(-0.25, 0.25, 0.012, 0.006, 0, zo=hh + 0.004))
    sl = HG.slit(0.16, 0.04, depth=0.03, fr=0.015)
    _put(p, sl, 'seeker_', _at(X1 - 0.005, 0, 0.0) @ Matrix.Rotation(math.pi, 4, 'Z'))   # the kit's slit faces -X: turn it to the prow
    for s in (1, -1):
        p.add('vane', 'body', 'htrim', block(-1.08, -0.80, 0.10, 0.012, 0, yo=s * (hw + 0.06)))
        _hdrive(p, 0.16, 0.12, 0.30, 2, y=s * 0.14, tag='drive_%s_' % ('p' if s > 0 else 's'))
    return p


def heg_stack():
    """HT-C module stack: three square modules joined by bands, a four-sided pyramid seeker with a light-blue lens, four
    straight cruciform vanes at the stern and one square two-cell drive"""
    p = Part('munition')
    hw, hh, ch = 0.20, 0.20, 0.05
    p.add('hull', 'body', 'hgrey', prism([(X0 + 0.05, octa(hw, hh, ch)), (0.55, octa(hw, hh, ch)), (X1 - 0.05, octa(0.035, 0.035, 0.01))]))
    for x0, x1 in ((-0.90, -0.52), (-0.38, 0.12), (0.28, 0.50)):
        p.add('plate', 'body', 'hpanel', block(x0, x1, hw * 0.7, hh + 0.006, 0.02))
        p.add('plate', 'body', 'hpanel', block(x0, x1, hw + 0.006, hh * 0.7, 0.02))
    _hband(p, 0, -0.45, hw, hh, ch); _hband(p, 1, 0.20, hw, hh, ch)
    p.add('lens', 'body', 'hlens', block(X1 - 0.07, X1, 0.03, 0.03, 0.008))
    for s in (1, -1):
        _hstrip(p, -0.36, 0.10, hw, s)
    for a in range(4):
        ang = a * math.pi / 2
        V, F = _fin(-1.05, -0.72, ang, 0.19, 0.14, 0.012, sweep=0.0)
        p.add('vane', 'body', 'htrim', (V, F))
    _hdrive(p, 0.24, 0.24, 0.35, 2)
    return p


# ------------------------------------------------------------------------------------------------------------- Eclipse
# factions.md: a black shade, layered plates, an eclipse-ring engine; brief: violet accents only, never orange or green.
EC = None
ER = dict(GREEN_TO_VIOLET)


def _ebell(p, r, body_len, y=0.0, z=0.0, halo=0.0, tag='drive_', bell_len=None):
    _put(p, EC.engine_bell(r, body_len, bell_len=bell_len, seg=16, halo=halo), tag, _at(X0 + 0.02, y, z), ER)


def ecl_shade():
    """ET-A shade dart: an eight-sided shade body in even layered plates, a black eclipse disc for a nose ringed by a thin
    violet line, one ringed eclipse bell"""
    p = Part('munition')
    ph = math.pi / 8
    p.add('hull', 'body', 'shade', revolve([(X0 + 0.05, 0.20), (-0.85, 0.25), (0.55, 0.25), (0.92, 0.19), (1.04, 0.0)], 8, cap0=True, phase=ph))
    EC.panels(p, 'skin', 'body', ('shade2', 'violet'), -0.80, 0.50, 0.25, 8, ph, size=(0.14, 0.26), th=0.016)
    p.add('disc', 'body', 'dark', revolve([(1.00, 0.0), (1.00, 0.15), (1.03, 0.155)], 24))
    p.add('ring', 'body', 'vglow', revolve([(1.005, 0.150), (1.045, 0.150), (1.045, 0.172), (1.005, 0.172)], 24, closed=True))
    p.add('collar', 'body', 'mauve', revolve([(0.86, 0.205), (0.86, 0.225), (0.96, 0.18), (0.96, 0.16)], 8, closed=True, phase=ph))
    _ebell(p, 0.19, 0.30)
    return p


def ecl_halo():
    """ET-B halo: a slim shade lance with three swept shade blades, a long faceted nose and a free violet ring of light
    standing round its bell (the kit's halo, as on the E14 flare)"""
    p = Part('munition')
    ph = math.pi / 6
    p.add('hull', 'body', 'shade', revolve([(X0 + 0.05, 0.16), (-0.80, 0.19), (0.20, 0.19), (0.75, 0.12), (X1, 0.0)], 6, cap0=True, phase=ph))
    EC.panels(p, 'skin', 'body', ('shade2', 'mauve'), -0.75, 0.15, 0.19, 6, ph, size=(0.12, 0.24), th=0.014)
    for k in range(3):
        a = math.pi / 2 + k * 2 * math.pi / 3
        p.add('blade', 'body', 'shade2', _fin(-0.80, -0.30, a, 0.17, 0.20, 0.012, sweep=0.75))
        p.add('edge', 'body', 'violet', _fin(-0.80, -0.30, a, 0.36, 0.015, 0.016, sweep=0.75))
    p.add('tipline', 'body', 'vglow', revolve([(0.74, 0.122), (0.80, 0.112), (0.80, 0.126), (0.74, 0.136)], 6, closed=True, phase=ph))
    _ebell(p, 0.15, 0.32, halo=0.30, bell_len=0.30)   # the halo stands on the bell: it needs a bell longer than 0.17
    return p


def ecl_crescent():
    """ET-C crescent: a flat lens-shaped shade body under three stacked crescent plates (the Eclipse's layered shade), violet
    plate edges, a thin violet line across the prow and twin small eclipse bells"""
    p = Part('munition')
    p.add('hull', 'body', 'shade', prism([(X0 + 0.05, octa(0.26, 0.10, 0.06)), (-0.6, octa(0.32, 0.13, 0.08)), (0.45, octa(0.30, 0.12, 0.07)),
                                          (X1, octa(0.06, 0.03, 0.02))]))
    for i, (x0, x1, w) in enumerate(((-0.95, -0.15, 0.30), (-0.45, 0.35, 0.26), (0.05, 0.80, 0.20))):
        z = 0.12 + 0.025 * i
        p.add('crescent%d' % i, 'body', 'shade2' if i % 2 else 'mauve', block(x0, x1, w, 0.022, 0.015, zo=z, taper=0.55))
        p.add('lip%d' % i, 'body', 'violet', block(x1 - 0.06, x1, w * 0.62, 0.026, 0.01, zo=z))
    p.add('prowline', 'body', 'vglow', block(0.86, 0.90, 0.17, 0.02, 0.006, zo=0.02))
    for s in (1, -1):
        _ebell(p, 0.10, 0.30, y=s * 0.15, tag='drive_%s_' % ('p' if s > 0 else 's'))
    return p


# ------------------------------------------------------------------------------------------------------------- the Chorus
# factions.md: grown, not built; no metal, no eyes; olive-brown hide, ochre bone, muted amber. A bio-munition.
CH = None


def _cvent(p, r, body_len, x=X0 + 0.15, y=0.0, z=0.0, seed=0, tag='drive_'):
    _put(p, CH.craft_vent(r, body_len, seed=seed), tag, _at(x, y, z))


def chr_seed():
    """CT-A seed pod: a lumpy seed of hide under overlapping ochre chitin scutes, a knuckled bone crest along its back, a bone
    point for a nose and one muscle-ringed vent"""
    p = Part('munition')
    rx, ry, rz, cx = 1.0, 0.27, 0.25, 0.02
    p.add('hull', 'body', 'flesh', CH.blob(rx, ry, rz, centre=(cx, 0, 0), nu=28, nv=14, seed=3, amp=0.05))

    def rad(x, r):
        return r * math.sqrt(max(0.0, 1 - ((x - cx) / rx) ** 2))
    for i, x in enumerate((-0.55, -0.20, 0.15, 0.48)):
        for a in (math.radians(30), math.radians(150), math.radians(-90)):
            _surface(p, 'scute%d%d' % (i, int(math.degrees(a)) % 360), CH.chitin(0.24, 0.34, t=0.035, growth=2, seed=i), x, a, rad(x, 0.255) - 0.02)
    _surface(p, 'crest', CH.bone_crest(0.95, 0.11, seed=5), 0.0, math.pi / 2, rad(0.0, rz) - 0.02)
    p.add('nose', 'body', 'bone', CH.tube([Vector((0.96, 0, 0)), Vector((1.06, 0, 0)), Vector((1.15, 0, 0.005))], [0.07, 0.04, 0.004], n=8))
    _cvent(p, 0.10, 0.35, x=-0.93)
    return p


def chr_dart():
    """CT-B barbed dart: a slim hide spine swelling behind a long bone barb, ringed by raw tissue welts, four raked bone
    blades for fins and one vent"""
    p = Part('munition')
    pts = [Vector((x, 0, 0)) for x in (-1.0, -0.7, -0.3, 0.1, 0.5, 0.85)]
    p.add('hull', 'body', 'hide', CH.tube(pts, [0.13, 0.17, 0.19, 0.17, 0.13, 0.08], n=12))
    for i, x in enumerate((-0.45, -0.05, 0.35)):
        r = {-0.45: 0.185, -0.05: 0.185, 0.35: 0.145}[x]
        ring = [Vector((x, r * math.cos(2 * math.pi * k / 12), r * math.sin(2 * math.pi * k / 12))) for k in range(13)]
        p.add('welt%d' % i, 'body', 'tissue', CH.tube(ring, [0.022] * 13, n=5, cap0=False, cap1=False))
    p.add('barb', 'body', 'bone', CH.tube([Vector((0.80, 0, 0)), Vector((0.98, 0, 0)), Vector((1.15, 0, 0.01))], [0.09, 0.05, 0.004], n=8))
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        _surface(p, 'fin%d' % k, CH.spine_blade(0.26, 0.24, rake=35.0, teeth=3, seed=k), -0.72, a, 0.15)
    _cvent(p, 0.09, 0.30, x=-0.98)
    return p


def chr_sac():
    """CT-C acid sac: a heavy sealed sac of hide banded by gill folds with a muted amber blush between them, a puckered
    muscle sphincter at the front that bursts on contact, a short bone beak and one vent"""
    p = Part('munition')
    rx, ry, rz, cx = 0.78, 0.31, 0.30, -0.18
    p.add('hull', 'body', 'flesh', CH.blob(rx, ry, rz, centre=(cx, 0, 0), nu=28, nv=14, seed=7, amp=0.04))

    def rad(x, r):
        return r * math.sqrt(max(0.0, 1 - ((x - cx) / rx) ** 2))
    for i, x in enumerate((-0.60, -0.38, -0.16, 0.06, 0.28)):
        r = rad(x, 0.30) + 0.004
        ring = [Vector((x, r * math.cos(2 * math.pi * k / 16), r * math.sin(2 * math.pi * k / 16))) for k in range(17)]
        p.add('gill%d' % i, 'body', 'flesh2', CH.tube(ring, [0.028] * 17, n=5, cap0=False, cap1=False))
        if i < 4:
            xb = x + 0.11; rb = rad(xb, 0.30) - 0.008
            p.add('blush%d' % i, 'body', 'amber', revolve([(xb - 0.05, rb), (xb + 0.05, rb)], 16))
    p.add('neck', 'body', 'tissue', revolve([(0.50, 0.17), (0.66, 0.15), (0.74, 0.12)], 12, phase=0.1))
    p.add('sphincter', 'body', 'tissue', revolve([(0.72, 0.13), (0.80, 0.115), (0.84, 0.07), (0.82, 0.03), (0.78, 0.0)], 12, phase=0.1))
    for k in range(6):
        a = 2 * math.pi * k / 6
        p.add('pucker%d' % k, 'body', 'flesh2', CH.tube([Vector((0.70, 0.12 * math.cos(a), 0.12 * math.sin(a))),
                                                         Vector((0.83, 0.05 * math.cos(a + 0.2), 0.05 * math.sin(a + 0.2)))], [0.03, 0.012], n=5))
    p.add('beak', 'body', 'bone', CH.tube([Vector((0.82, 0, 0)), Vector((0.98, 0, 0)), Vector((1.15, 0, -0.01))], [0.05, 0.03, 0.004], n=8))
    _cvent(p, 0.11, 0.30, x=-0.92)
    return p


OPTIONS = {
    'hegemony': [('HT-A', 'wedge', heg_wedge), ('HT-B', 'twin slab', heg_slab), ('HT-C', 'module stack', heg_stack)],
    'deathless': [('ET-A', 'shade dart', ecl_shade), ('ET-B', 'halo', ecl_halo), ('ET-C', 'crescent', ecl_crescent)],
    'chorus': [('CT-A', 'seed pod', chr_seed), ('CT-B', 'barbed dart', chr_dart), ('CT-C', 'acid sac', chr_sac)],
}


def _load_kit(fac):
    global HG, EC, CH
    if fac == 'hegemony':
        HG = kit('hegemony')
    elif fac == 'deathless':
        EC = kit('eclipse')
    else:
        CH = kit('chorus')


# ------------------------------------------------------------------------------------------------------------- stages
def _export(root, path):
    bpy.ops.object.select_all(action='DESELECT')
    for o in [root] + list(root.children):
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format='GLB', export_apply=True, export_yup=True,
                              export_extras=True, export_image_format='JPEG', export_jpeg_quality=88)


def bodies(fac, scratch):
    _load_kit(fac)
    MUN.STACKS[fac] = STACK[fac]
    MUN.LIFT[fac] = LIFT[fac]
    MUN.KEEP = ('oath', 'vglow')
    report = {}
    for code, label, fn in OPTIONS[fac]:
        cell = code.replace('-', '_')
        glb = os.path.join(scratch, cell + '.glb')
        bpy.ops.wm.read_factory_settings(use_empty=True)
        part = fn()
        root = to_blender(part, cell)
        tris = sum(len(o.data.polygons) for o in root.children)
        try:
            info = MUN.paint(bpy, root, fac, cell, os.path.join(scratch, '_paint', cell))
            painted = True
            note = 'painted by the %s stack' % STACK[fac]
        except BaseException as e:      # the Hegemony stack stops with SystemExit; keep the option, flat, and say so
            traceback.print_exc()
            painted = False
            note = 'paint stack failed (%s: %s); flat kit colours' % (type(e).__name__, str(e)[:160])
            bpy.ops.wm.read_factory_settings(use_empty=True)
            root = to_blender(fn(), cell)
            info = {}
        _export(root, glb)
        report[code] = dict(label=label, painted=painted, note=note, faces=tris, device=info.get('device'))
        print('[1943] body', code, note, 'faces', tris)
    json.dump(report, open(os.path.join(scratch, 'bodies.json'), 'w'), indent=1)


# ---- rendering
def _scene():
    sc = bpy.context.scene
    world = bpy.data.worlds.new('w'); sc.world = world; world.use_nodes = True
    world.node_tree.nodes['Background'].inputs[0].default_value = (0.2, 0.2, 0.2, 1)
    world.node_tree.nodes['Background'].inputs[1].default_value = 0.7

    def sun(name, toward, strength, angle=4.0):
        l = bpy.data.lights.new(name, 'SUN'); l.energy = strength; l.angle = math.radians(angle)
        o = bpy.data.objects.new(name, l); sc.collection.objects.link(o)
        o.rotation_euler = Vector(toward).normalized().to_track_quat('Z', 'Y').to_euler()
    # the build sheets' key and fill (tools/blender/build_sheets/build.py)
    sun('key', (0.5, 0.5, 0.707), 4.0)
    sun('fill', (-0.66, -0.66, -0.35), 0.8, angle=20)
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'GPU' if os.name == 'nt' else 'CPU'
    if sc.cycles.device == 'GPU':
        sys.path.insert(0, os.path.join(REPO, 'tools', 'blender', 'r209'))
        from cycles_devices import configure_cycles_device
        configure_cycles_device(sc)
    sc.cycles.samples = 64
    sc.cycles.use_denoising = True
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    return sc


def _cam(sc, look, target, ortho, res):
    b = Vector(look).normalized()
    r = Vector((0, 0, 1)).cross(b).normalized(); u = b.cross(r)
    loc = Vector(target) + b * 200
    c = bpy.data.cameras.new('cam'); o = bpy.data.objects.new('cam', c); sc.collection.objects.link(o)
    o.matrix_world = Matrix(((r.x, u.x, b.x, loc.x), (r.y, u.y, b.y, loc.y), (r.z, u.z, b.z, loc.z), (0, 0, 0, 1)))
    c.type = 'ORTHO'; c.ortho_scale = ortho; c.clip_start, c.clip_end = 1, 500
    sc.camera = o
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    return o


def _import(path, name):
    """import a glb under one empty; returns the empty and its meshes"""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    root = bpy.data.objects.new(name, None); bpy.context.scene.collection.objects.link(root)
    for o in new:
        if o.parent is None:
            o.parent = root
    return root, [o for o in new if o.type == 'MESH']


def _bbox(meshes):
    bpy.context.view_layer.update()
    P = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo = Vector((min(p.x for p in P), min(p.y for p in P), min(p.z for p in P)))
    hi = Vector((max(p.x for p in P), max(p.y for p in P), max(p.z for p in P)))
    return lo, hi


def _fit(root, meshes, length, at):
    """scale the import so its length along X is `length`, its centre at `at`"""
    lo, hi = _bbox(meshes)
    s = length / max(1e-6, hi.x - lo.x)
    root.scale = (s, s, s)
    bpy.context.view_layer.update()
    lo, hi = _bbox(meshes)
    root.location = Vector(at) - (lo + hi) / 2 + root.location
    bpy.context.view_layer.update()


def _render(sc, path, show):
    for o in sc.objects:
        if o.type == 'MESH':
            o.hide_render = o not in show
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print('[1943] wrote', path)


def _shown(roots):
    out = set()
    for r in roots:
        stack = [r]
        while stack:
            o = stack.pop(); out.add(o); stack.extend(o.children)
    return out


def sheet(fac, scratch):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = _scene()
    code, length, _ = LAUNCHER[fac]
    lroot, lmesh = _import(os.path.join(BUILD, code, code + '.glb'), 'launcher')
    _fit(lroot, lmesh, length, (0, 0, 0))
    k = max(0.25, min(2.5, length / 24.0))
    game_len = (X1 - X0) * k * 0.5          # rk = k * pulse (1.0) * ROUND_SIZE torp 0.5, on the 2.3-long frame
    roots = []
    for i, (oc, label, _) in enumerate(OPTIONS[fac]):
        cell = oc.replace('-', '_')
        r, m = _import(os.path.join(scratch, cell + '.glb'), cell)
        roots.append((oc, r, m))
    # close-ups: each option alone, one scale for all three (the 2.3 frame), three-quarter view from ahead, above, starboard
    look = (0.30, -0.80, 0.52)
    for oc, r, m in roots:
        _fit(r, m, X1 - X0, (0, 0, 0))
    cam = _cam(sc, look, (0, 0, 0), 2.75, (640, 480))
    for oc, r, m in roots:
        _render(sc, os.path.join(scratch, 'close_%s.png' % oc.replace('-', '_')), _shown([r]))
    # the scale strip: the launcher and the three options at their in-game size, in a row off its bow, seen from high up as the
    # battle camera sees them
    bpy.data.objects.remove(cam)
    gap = max(game_len * 1.6, 0.9)
    for i, (oc, r, m) in enumerate(roots):
        _fit(r, m, game_len, (length / 2 + 1.2 + game_len / 2, (1 - i) * gap, 0))
    span = length + 1.2 + game_len + 1.0
    centre = (span / 2 - length / 2 - 0.5, 0, 0)
    # wide launchers (the Chorus brood-sac) must fit the 4:1 frame too: the camera's up axis is about (0, 0.89, 0.45)
    lo, hi = _bbox(lmesh)
    half_h = max(abs(lo.y) * 0.89 + abs(lo.z) * 0.45, hi.y * 0.89 + hi.z * 0.45, gap + game_len)
    ortho = max(span * 1.04, half_h * 2 * 4 * 1.08)
    _cam(sc, (0.0, -0.45, 0.89), centre, ortho, (1280, 320))
    _render(sc, os.path.join(scratch, 'scale_strip.png'), _shown([lroot] + [r for _, r, _ in roots]))
    json.dump(dict(launcher=LAUNCHER[fac], k=k, game_len=game_len, span=span, gap=gap,
                   order=[oc for oc, _, _ in roots]), open(os.path.join(scratch, 'sheet.json'), 'w'), indent=1)


STATUS = [('voidsworn_SF3', 'Sunward fighter'), ('voidsworn_SB4', 'Sunward bomber'),
          ('hegemony_HF1D', 'Meridian fighter'), ('corsair_KB1CC', 'Hullbreaker bomber')]


def status(scratch):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = _scene()
    roots = []
    for code, _ in STATUS:
        r, m = _import(os.path.join(BUILD, code, code + '.glb'), code)
        _fit(r, m, 1.6, (0, 0, 0))
        roots.append((code, r))
    _cam(sc, (0.30, -0.80, 0.52), (0, 0, 0), 2.1, (640, 480))
    for code, r in roots:
        _render(sc, os.path.join(scratch, 'status_%s.png' % code), _shown([r]))


def main():
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    mode = argv[0]
    if mode == 'bodies':
        os.makedirs(argv[2], exist_ok=True); bodies(argv[1], argv[2])
    elif mode == 'sheet':
        sheet(argv[1], argv[2])
    elif mode == 'check':          # CPU only: build every option, no paint, print its size (PC_GPU_MODE=none)
        for fac in OPTIONS:
            _load_kit(fac)
            for oc, _, fn in OPTIONS[fac]:
                bpy.ops.wm.read_factory_settings(use_empty=True)
                root = to_blender(fn(), oc.replace('-', '_'))
                lo, hi = _bbox(list(root.children))
                print('[1943] check', oc, 'objects', len(root.children), 'x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f' % (lo.x, hi.x, lo.y, hi.y, lo.z, hi.z),
                      sorted({o.name.split('_', 2)[2] for o in root.children}))
    elif mode == 'status':
        os.makedirs(argv[1], exist_ok=True); status(argv[1])
    else:
        raise SystemExit('unknown mode ' + mode)


if __name__ == '__main__':
    main()
