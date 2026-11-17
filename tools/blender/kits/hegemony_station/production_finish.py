"""Refs #975 run 3. Built module tones, structural weathering and fitted glazing.

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
    'hgrey': ((184, 181, 171), (184, 181, 171)),
    'hpanel': ((175, 172, 162), (175, 172, 162)),
    'hmetal': ((192, 193, 187), (192, 193, 187)),
    'htrim': ((105, 117, 128), (105, 117, 128)),
    'dark': ((77, 89, 99), (77, 89, 99)),
}

# Accent decisions belong to complete pressure modules, never random plates.
# Values multiply the neutral station tiles in linear space.
MODULE_TONES = {
    'pale': (.96, .96, .92), 'warm': (.90, .82, .67),
    'steel': (.76, .84, .90), 'blue': (.37, .57, .76),
}


def module_family(module):
    if module.startswith('core_'):
        return ('pale', 'steel', 'pale', 'warm', 'pale', 'warm', 'steel', 'pale', 'pale')[int(module[-2:])-1]
    if module.startswith('tower_'):
        return ('pale', 'steel', 'blue', 'pale', 'steel')[int(module[-1])-1]
    if module.startswith('habitat_'):
        return ('warm', 'pale', 'steel', 'pale', 'warm', 'pale')[int(module.split('_')[1])-1]
    if module in ('arm_2', 'service_finger_3', 'service_finger_6'):
        return 'blue'
    if module.startswith('cargo_'): return 'warm'
    return 'pale'


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
    # The shared patchwork layer was inherited from scavenged Hullbreakers.
    # Disable it on this private stack, including its object-random base tone.
    stack.LAYERS = dict(stack.LAYERS, island_tone=0, plate_var=0, mottle=0, grain=0)
    for zone in PALETTE:
        stack.ZONES[zone].update(patchwork=0, patchwork_parts=0)
    stack.PATCH_FAMILIES_PARTS = []
    return dict(palette_srgb=PALETTE, source='accepted station_T2 beauty; station-only Hegemony overrides',
                module_tones=MODULE_TONES, plate_variation_percent=3,
                hierarchy='module base > structural zone > +/-1.5 percent plate value',
                rust=0, window_source='hegemony.stack.glow_material(hwin)')


def random_value(*values):
    raw = '|'.join(str(v) for v in values).encode()
    return int.from_bytes(hashlib.sha256(raw).digest()[:4], 'little') / 4294967295


def island_tones(mesh, module, zone):
    """One module family; each connected plate varies only +/-1.5 percent."""
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
        family = MODULE_TONES[module_family(module)]
        tones[root] = np.asarray(family) * (.985 + .03 * pick)
    return roots, tones


def weather(point, normal, cavity, edge, tone):
    """Cavity, bevel and directional soot over connected-panel tones.

    Slow fields live in actual world space and cannot repeat every two units.
    Narrow residue tracks are sampled in the detail tile too. No brown rust.
    """
    x, y, z = point
    damage = max(0.0, min(1.0, (-y + 1) / 24))
    # Exposure is continuous across the entire damaged side. Fine streaks
    # originate at the tile's seams/vents, not a random colour on each island.
    exposure = .6 + .4 * max(0, -normal.y)
    soot = damage * (.20 + .24 * exposure)
    grime = (1 - cavity) * (.80 + .7 * damage)
    worn = min(.16, edge * .65) * cavity
    value = np.maximum(.20, 1 - soot - grime)
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
    cx, cy = np.mod(x, .50) / .50, np.mod(y, .48) / .48
    room = ((cx > .07) & (cx < .93) & (cy > .10) & (cy < .90)).astype(np.float32)
    # Stable room-to-room brightness, a sill and a faint interior equipment row.
    cells = np.sin(np.floor(x/.50)*17.13 + np.floor(y/.48)*31.71) * 43758.5453
    cells -= np.floor(cells)
    room *= np.where(cells < .16, .08, .62 + .34*cells)
    interior = ((cx > .48) & (cx < .58) & (cy < .55)) | ((cy > .28) & (cy < .37))
    room *= np.where(interior, .32, 1)
    arrays = {}
    albedo = np.zeros((resolution, resolution, 4), np.float32)
    reflection = (.5 + .5*np.cos((cx*.65+cy)*math.tau)) * .012
    albedo[..., :3] = np.array((.010, .020, .030)) + room[..., None]*np.array((.009, .016, .024))
    albedo[..., :3] += reflection[...,None]*np.array((.6,.8,1))
    frame = (room == 0)
    albedo[frame,:3] = (.055,.068,.077)
    albedo[..., 3] = 1
    arrays['albedo'] = albedo
    orm = np.ones_like(albedo)
    orm[..., 0] = np.where(frame,.64,1)
    orm[..., 1] = np.where(frame, .68, .24 + reflection*5)
    orm[..., 2] = np.where(frame, .60, .38)
    arrays['orm'] = orm
    normal = np.ones_like(albedo)
    gy,gx = np.gradient(np.where(frame,.004,0).astype(np.float32),tile_world/resolution)
    nv = np.stack((-gx,gy,np.ones_like(gx)),axis=2)
    nv /= np.linalg.norm(nv,axis=2,keepdims=True)
    normal[..., :3] = nv*.5+.5
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
    def material(name, images, strength):
        mat = stack.glow_material('hwin')
        mat.name = name
        nt = mat.node_tree
        bs = nt.nodes.get('Principled BSDF')
        textures = {}
        for channel, im in images.items():
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
        bs.inputs['Emission Strength'].default_value = strength
        normal_node = nt.nodes.new('ShaderNodeNormalMap')
        nt.links.new(textures['normal'].outputs['Color'], normal_node.inputs['Color'])
        nt.links.new(normal_node.outputs[0], bs.inputs['Normal'])
        return mat
    for lit in (False, True):
        result.append(material('T2_glass_' + ('lit' if lit else 'dark'), maps, 1 if lit else .035))
    # The 90 old flat blue cards and five flat battery bars get real recessed
    # lenses and bezels. UVs fit each original face; no geometry or light added.
    for name, colour in [('marker_lens',(.12,.52,1)), ('battery_strip',(.40,.12,.025))]:
        bezel = (cx < .12) | (cx > .88) | (cy < .16) | (cy > .84)
        # Draw a single lens in normalized face space, not the repeating rooms.
        u,v = x/tile_world,y/tile_world
        bezel = (u < .14) | (u > .86) | (v < .16) | (v > .84)
        ribs = (np.mod(u*9,1)<.13) & ~bezel
        light = np.where(bezel,0,np.where(ribs,.12,.68+.22*np.sin(u*math.pi)))
        lens_maps = {}
        for channel in arrays:
            pixels = np.ones_like(albedo)
            if channel == 'albedo':
                pixels[...,:3] = np.where(bezel[...,None],(.048,.058,.063),(.004,.010,.018))
                pixels[...,:3] += light[...,None]*np.array(colour)*.028
            elif channel == 'orm':
                pixels[...,0] = np.where(bezel,.62,1)
                pixels[...,1] = np.where(bezel,.70,.29+light*.10)
                pixels[...,2] = np.where(bezel,.62,.22)
            elif channel == 'normal':
                gy,gx = np.gradient(np.where(bezel,.004,0).astype(np.float32),tile_world/resolution)
                nv = np.stack((-gx,gy,np.ones_like(gx)),axis=2)
                pixels[...,:3] = nv/np.linalg.norm(nv,axis=2,keepdims=True)*.5+.5
            else:
                pixels[...,:3] = light[...,None]*np.array(colour)*.60
            im = paint.new_image('T2_'+name+'_'+channel,resolution,channel in ('albedo','emission'))
            im.pixels.foreach_set(pixels.ravel())
            paint.save(im,str(out),im.name)
            lens_maps[channel] = im
        result.append(material('T2_'+name,lens_maps,1))
    return result


def assign_glazing(ob, materials):
    ob.data.materials.clear()
    for mat in materials[:2]: ob.data.materials.append(mat)
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
