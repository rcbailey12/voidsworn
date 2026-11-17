"""Refs #975 run 2. T2's aged metal and glazing, without changing its mesh.

The accepted T2 beauty supplies the pale, warm-grey and dark-band direction.
These are station overrides on a privately loaded Hegemony stack, not changes
to the fleet palette. Its ordered seams, PBR machinery and hwin light stay.
All drawn maps are own work, dedicated CC0.
"""
import hashlib
import math

import bpy
import numpy as np

PALETTE = {
    'hgrey': ((166, 160, 147), (198, 193, 180)),
    'hpanel': ((139, 131, 113), (181, 173, 152)),
    'hmetal': ((113, 122, 129), (162, 169, 173)),
    'htrim': ((38, 48, 60), (70, 82, 96)),
    'dark': ((12, 18, 26), (27, 35, 44)),
}


def configure(stack):
    # H10's narrow blue-grey tone range was inappropriate for the approved T2
    # concept. Keep its machinery and ordered grid; replace station tones only.
    def tone(rgb):
        return tuple(min(1.0, c / (stack.LIGHT_GAIN * stack.LIFT))
                     for c in stack.lin_raw(rgb))
    stack.CAP_LIN = tone((206, 203, 193))
    stack.BARE = stack.CAP_LIN
    stack.GRIME = tone((13, 21, 30))
    stack.RUST = stack.RUST_DARK = stack.GRIME
    for zone, (lo, hi) in PALETTE.items():
        stack.ZONES[zone] = dict(stack.ZONES[zone], lo=tone(lo), hi=tone(hi))
    stack.PATCH_FAMILIES_PARTS = [
        (.18, (tone((130, 144, 157)), tone((159, 170, 177)))),
        (.24, (tone((151, 140, 120)), tone((181, 170, 146)))),
    ]
    return dict(palette_srgb=PALETTE, source='accepted station_T2 beauty; station-only Hegemony overrides',
                rust=0, window_source='hegemony.stack.glow_material(hwin)')


def random_value(*values):
    raw = '|'.join(str(v) for v in values).encode()
    return int.from_bytes(hashlib.sha256(raw).digest()[:4], 'little') / 4294967295


def island_tones(mesh, module, zone):
    """One tone per connected plate/fitting, including all its bevel faces.

    Never per-triangle noise. Adjacency comes from the unchanged mesh itself.
    """
    parent = list(range(len(mesh.vertices)))
    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for edge in mesh.edges:
        a, b = (find(i) for i in edge.vertices)
        if a != b: parent[b] = a
    tones = {}
    roots = [find(i) for i in range(len(parent))]
    for root in set(roots):
        co = mesh.vertices[root].co
        seed = tuple(round(v, 3) for v in co)
        pick = random_value(module, zone, seed)
        # Blue is a minority of external panels, not a tint over all metals.
        if zone in ('plate', 'plate2', 'frost'):
            if pick < .12:
                rgb = (.24, .39, .59)
            elif pick < .38:
                rgb = (.73, .64, .48)
            elif pick < .62:
                rgb = (.66, .70, .72)
            else:
                rgb = (.91, .90, .86)
        else:
            v = .72 + .26 * pick
            rgb = (v, v, v)
        tones[root] = np.asarray(rgb)
    return roots, tones


def weather(point, normal, cavity, edge, tone):
    """Cavity, bevel and directional soot over connected-panel tones.

    Slow fields live in actual world space and cannot repeat every two units.
    Narrow residue tracks are sampled in the detail tile too. No brown rust.
    """
    x, y, z = point
    damage = max(0.0, min(1.0, (-y + 1) / 24))
    broad = .5 + .5 * math.sin(x * .34 + math.sin(z * .19) * 1.8)
    tracks = (.5 + .5 * math.sin(x * 2.3 + y * .43)) ** 10
    soot = damage * (.18 + .30 * broad + .18 * tracks)
    grime = (1 - cavity) * (.85 + .5 * damage)
    worn = min(.24, edge * .9) * cavity
    value = np.maximum(.18, 1 - soot - grime)
    rgb = tone * value * np.array((1 - .10 * damage, 1 - .035 * damage, 1))
    return np.clip(rgb * (1 - worn) + np.array((.94, .96, .97)) * worn, 0, 1)


def glass_materials(stack, paint, out, resolution, tile_world):
    """Framed blue glazing with dim room silhouettes, not a white light card.

    Uses opaque reflective glass treatment to avoid sorting the nested shells.
    hwin is the sole emission colour and peak; texture masks only reduce it.
    """
    y, x = np.mgrid[0:resolution, 0:resolution].astype(np.float32)
    x = x / resolution * tile_world
    y = y / resolution * tile_world
    cx, cy = np.mod(x, .25) / .25, np.mod(y, .25) / .25
    room = ((cx > .075) & (cx < .925) & (cy > .12) & (cy < .88)).astype(np.float32)
    # Stable room-to-room brightness, a sill and a faint interior equipment row.
    cells = np.sin(np.floor(x/.25)*17.13 + np.floor(y/.25)*31.71) * 43758.5453
    cells -= np.floor(cells)
    room *= np.where(cells < .16, .08, .62 + .34*cells)
    interior = ((cx > .48) & (cx < .58) & (cy < .55)) | ((cy > .28) & (cy < .37))
    room *= np.where(interior, .32, 1)
    arrays = {}
    albedo = np.zeros((resolution, resolution, 4), np.float32)
    albedo[..., :3] = np.array((.018, .042, .070)) + room[..., None]*np.array((.018, .048, .075))
    albedo[..., 3] = 1
    arrays['albedo'] = albedo
    orm = np.ones_like(albedo)
    orm[..., 1] = np.where(room > .01, .24, .55)
    orm[..., 2] = np.where(room > .01, .62, .72)
    arrays['orm'] = orm
    normal = np.ones_like(albedo)
    normal[..., :3] = (.5, .5, 1)
    arrays['normal'] = normal
    glow = np.zeros_like(albedo)
    base = stack.GLOW_FLAT['hwin'][1]()
    # Blue glass filters the hwin light; its original blue-channel peak stays.
    glow[..., :3] = room[..., None]*np.asarray(base)*np.array((.12, .52, 1))
    glow[..., 3] = 1
    arrays['emission'] = glow
    maps = {}
    for channel, pixels in arrays.items():
        im = paint.new_image('T2_glass_' + channel, resolution, channel in ('albedo', 'emission'))
        im.pixels.foreach_set(pixels.ravel())
        paint.save(im, str(out), im.name)
        maps[channel] = im
    result = []
    for lit in (False, True):
        mat = stack.glow_material('hwin')
        mat.name = 'T2_glass_' + ('lit' if lit else 'dark')
        nt = mat.node_tree
        bs = nt.nodes.get('Principled BSDF')
        textures = {}
        for channel, im in maps.items():
            tex = nt.nodes.new('ShaderNodeTexImage')
            tex.image = im
            tex.extension = 'REPEAT'
            textures[channel] = tex
        nt.links.new(textures['albedo'].outputs['Color'], bs.inputs['Base Color'])
        sep = nt.nodes.new('ShaderNodeSeparateColor')
        nt.links.new(textures['orm'].outputs['Color'], sep.inputs[0])
        nt.links.new(sep.outputs[1], bs.inputs['Roughness'])
        nt.links.new(sep.outputs[2], bs.inputs['Metallic'])
        nt.links.new(textures['emission'].outputs['Color'], bs.inputs['Emission Color'])
        bs.inputs['Emission Strength'].default_value = 1 if lit else .035
        # Retained normal channel also gives the density/export reader a full PBR set.
        normal_node = nt.nodes.new('ShaderNodeNormalMap')
        nt.links.new(textures['normal'].outputs['Color'], normal_node.inputs['Color'])
        nt.links.new(normal_node.outputs[0], bs.inputs['Normal'])
        result.append(mat)
    return result


def assign_glazing(ob, materials):
    ob.data.materials.clear()
    for mat in materials: ob.data.materials.append(mat)
    lit_count = dark_count = 0
    for polygon in ob.data.polygons:
        p = polygon.center
        damaged = p.y < -4
        # Whole panels, with fewer lit rooms on the abandoned side. The broad
        # observation pane gets the same framed, dim-interior window treatment.
        cell = (round(p.x*2), round(p.y*2), round(p.z*2))
        lit = (not ob['module'].startswith('service_finger_') and
               random_value(ob['module'], cell) > (.52 if damaged else .12))
        polygon.material_index = int(lit)
        lit_count += int(lit)
        dark_count += int(not lit)
    return dict(lit_faces=lit_count, dark_faces=dark_count)
