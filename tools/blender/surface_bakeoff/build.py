"""Issue 75, Blender 4.5: remesh/quad retopo/normal bake, or authored C19 kit.

All generated meshes, textures and logs go to --work, never to game folders.
The source NPZ is A4's unquantised final geometry in glTF coordinates.
"""
import argparse
import hashlib
import json
import math
import sys
import time
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

PARTS = []
GUNS = []


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def active(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply(obj, modifier):
    active(obj)
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def triangles(objects):
    return sum(len(p.vertices) - 2 for o in objects for p in o.data.polygons)


def mesh(name, pos, faces):
    data = bpy.data.meshes.new(name)
    data.from_pydata(pos, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    return obj


def save_image(path, rgb, color=False):
    h, w = rgb.shape[:2]
    img = bpy.data.images.new(path.stem, width=w, height=h, alpha=True)
    img.colorspace_settings.name = 'sRGB' if color else 'Non-Color'
    # Blender float image buffers are scene-linear for colour data.
    rgba = np.ones((h, w, 4), np.float32)
    rgba[:, :, :3] = rgb
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = str(path)
    img.file_format = 'PNG'
    img.save()
    return img


def material(folder, prefix=''):
    mat = bpy.data.materials.new('faction_PBR')
    mat.use_nodes = True
    nt = mat.node_tree
    bs = nt.nodes.get('Principled BSDF')
    for name, socket, col in [('base', 'Base Color', True), ('emission', 'Emission Color', True)]:
        node = nt.nodes.new('ShaderNodeTexImage')
        node.image = bpy.data.images.load(str(folder / (prefix + name + '.png')))
        node.image.colorspace_settings.name = 'sRGB' if col else 'Non-Color'
        nt.links.new(node.outputs['Color'], bs.inputs[socket])
    bs.inputs['Emission Strength'].default_value = 2.0
    orm = nt.nodes.new('ShaderNodeTexImage')
    orm.image = bpy.data.images.load(str(folder / (prefix + 'orm.png')))
    orm.image.colorspace_settings.name = 'Non-Color'
    sep = nt.nodes.new('ShaderNodeSeparateColor')
    nt.links.new(orm.outputs['Color'], sep.inputs[0])
    nt.links.new(sep.outputs['Green'], bs.inputs['Roughness'])
    nt.links.new(sep.outputs['Blue'], bs.inputs['Metallic'])
    normal = nt.nodes.new('ShaderNodeTexImage')
    normal.image = bpy.data.images.load(str(folder / (prefix + 'normal.png')))
    normal.image.colorspace_settings.name = 'Non-Color'
    normalmap = nt.nodes.new('ShaderNodeNormalMap')
    nt.links.new(normal.outputs['Color'], normalmap.inputs['Color'])
    nt.links.new(normalmap.outputs['Normal'], bs.inputs['Normal'])
    return mat


def atlas_positions(obj, res):
    """Rasterise UVs to world positions. No concept pixels enter the new maps."""
    obj.data.calc_loop_triangles()
    uv = obj.data.uv_layers.active.data
    xyz = np.zeros((res, res, 3), np.float32)
    normals = np.zeros_like(xyz)
    mask = np.zeros((res, res), bool)
    verts = np.array([v.co[:] for v in obj.data.vertices], np.float32)
    vertex_normals = np.array([v.normal[:] for v in obj.data.vertices],np.float32)
    for tri in obj.data.loop_triangles:
        t = np.array([uv[i].uv[:] for i in tri.loops]) * (res - 1)
        lo = np.maximum(0, np.floor(t.min(0)).astype(int))
        hi = np.minimum(res - 1, np.ceil(t.max(0)).astype(int))
        xx, yy = np.meshgrid(np.arange(lo[0], hi[0] + 1), np.arange(lo[1], hi[1] + 1))
        den = np.cross(t[1] - t[0], t[2] - t[0]).item()
        if abs(den) < 1e-7:
            continue
        qx, qy = xx - t[0, 0], yy - t[0, 1]
        u = (qx * (t[2, 1] - t[0, 1]) - qy * (t[2, 0] - t[0, 0])) / den
        v = ((t[1, 0] - t[0, 0]) * qy - (t[1, 1] - t[0, 1]) * qx) / den
        inside = (u >= -.001) & (v >= -.001) & (u + v <= 1.001)
        px, py = xx[inside], yy[inside]
        points = verts[list(tri.vertices)]
        xyz[py, px] = points[0] + u[inside, None] * (points[1] - points[0]) + v[inside, None] * (points[2] - points[0])
        ns = vertex_normals[list(tri.vertices)]
        normal = ns[0]+u[inside,None]*(ns[1]-ns[0])+v[inside,None]*(ns[2]-ns[0])
        normal /= np.maximum(np.linalg.norm(normal,axis=1,keepdims=True),1e-8)
        normals[py, px] = normal
        mask[py, px] = True
    return xyz, normals, mask


def noise(x, y, z):
    # Interpolated hashed lattice noise avoids the woven/checker pattern
    # produced by multiplying periodic sine waves on large flat surfaces.
    coords = [c * 23 for c in (x, y, z)]
    cells = [np.floor(c) for c in coords]
    f = [c-i for c,i in zip(coords,cells)]
    f = [t*t*(3-2*t) for t in f]
    result = np.zeros_like(x)
    for i in (0,1):
        for j in (0,1):
            for k in (0,1):
                h = np.sin((cells[0]+i)*127.1+(cells[1]+j)*311.7+(cells[2]+k)*74.7)*43758.5453
                h -= np.floor(h)
                result += h * (f[0] if i else 1-f[0]) * (f[1] if j else 1-f[1]) * (f[2] if k else 1-f[2])
    return result


def dilate(rgb, mask, count=12):
    """Extend island colours for mipmaps without introducing black borders."""
    filled = mask.copy()
    for _ in range(count):
        count_ = np.zeros(mask.shape, np.float32)
        total = np.zeros_like(rgb)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ok = np.roll(filled, (dy, dx), (0, 1))
            total += np.roll(rgb, (dy, dx), (0, 1)) * ok[:, :, None]
            count_ += ok
        new = (~filled) & (count_ > 0)
        rgb[new] = total[new] / count_[new, None]
        filled |= new
    return rgb


def pbr_maps(obj, folder, code, res, atlas=None):
    pos, nor, mask = atlas or atlas_positions(obj, res)
    x, y, z = pos.transpose(2, 0, 1)
    n = noise(x, y, z)
    micro = noise(x * 19, y * 19, z * 19)
    emit = np.zeros_like(pos)
    if code == 'B16_23':
        # Flesh folds and vascular strands, no metal, armour grid or decals.
        vein = np.exp(-np.square(np.sin(x * 83 + y * 34 + np.sin(z * 41) * 2) * 20))
        folds = np.sin(x * 48 + np.sin(y * 17 + z * 22) * 2)
        chitin = np.clip((nor[:, :, 2] - .35) * 1.8, 0, 1) * np.clip((n - .40) * 3, 0, 1)
        flesh = np.stack([.085 + n * .055, .095 + n * .065, .042 + n * .025], 2)
        bone = np.stack([.30 + n * .10, .23 + n * .09, .08 + n * .05], 2)
        base = flesh * (1 - chitin[:, :, None]) + bone * chitin[:, :, None]
        base *= (1 - vein * .25)[:, :, None]
        base += (folds * .009)[:, :, None] * np.array([1, .5, .25])
        rough = .28 + chitin * .26 + micro * .05
        metal = np.zeros_like(x)
        sacs = (vein > .82) & (n > .83)
        emit[sacs] = (.23, .34, .018)
    else:
        # Unequal staggered panels. Seams are sparse and hairline, not a grid overlay.
        deck = np.abs(nor[:, :, 2]) > .55
        v = np.where(deck, y, z)
        row = np.floor((v + .53) / .075)
        u = x + .032 * np.sin(row * 2.31)
        w = .105 + .035 * (.5 + .5 * np.sin(row * 3.7))
        cell = np.floor(u / w)
        fu = np.mod(u, w) / w
        fv = np.mod(v + .53, .075) / .075
        d = np.minimum(np.minimum(fu, 1-fu) * w, np.minimum(fv, 1-fv) * .075)
        seams = d < .00065
        wear = (d < .0018) & (micro > .52)
        tone = .85 + .22 * (.5 + .5 * np.sin(cell * 17 + row * 9))
        if code == 'C19_51':
            rust = np.array([.17, .054, .024])
            base = np.ones_like(pos) * rust * tone[:, :, None]
            salvage = np.sin(cell * 3.1 + row * 2.3)
            base[salvage > .87] = (.26, .27, .265)
            base[salvage < -.94] = (.42, .36, .24)
            rough = .58 + micro * .15
        else:
            base = np.ones_like(pos) * np.array([.055, .033, .095]) * tone[:, :, None]
            rough = .32 + micro * .10
            # The zenith's horseshoe uses radial segment seams instead of
            # rectangular wallpaper. A few arcs follow the actual hull mass.
            angle = np.arctan2(y, x + .08)
            radius = np.sqrt((x+.08)**2+y*y)
            seams = (np.abs(np.sin(angle*6)) < .008) & (radius > .20)
            seams |= (np.abs(radius-.34) < .0008) & (z < .08)
            wear = seams & (micro > .68)
            base = np.ones_like(pos) * np.array([.065,.043,.105]) * (.92 + n*.12)[:,:,None]
            emit[seams & (np.abs(nor[:, :, 2]) > .75)] = (.065, .026, .13)
        base *= (.95 + micro * .07)[:, :, None]
        base[seams] *= .38
        base[wear] = (.22, .215, .21) if code == 'C19_51' else (.38, .30, .23)
        metal = np.where(wear, .85, .36 if code == 'C19_51' else .65)
        # Small bone/gold registration bars, mirrored on the two sides.
        decal = (x > .22) & (x < .245) & (np.abs(np.abs(y) - .12) < .03) & (z > -.04) & (z < .015)
        ticks = np.mod(x * 460, 1) < .38
        base[decal & ticks] = (.66, .56, .32)
    orm = np.stack([np.ones_like(x), rough, metal], 2)
    for name, rgb, col in [('base', base, True), ('orm', orm, False), ('emission', emit, True)]:
        save_image(folder / (name + '.png'), dilate(np.clip(rgb, 0, 1), mask), col)
    return mask


def gpu():
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'OPTIX'
    prefs.get_devices()
    assert any(d.type == 'OPTIX' for d in prefs.devices), 'OPTIX GPU is required'
    for d in prefs.devices:
        d.use = d.type == 'OPTIX'
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'GPU'
    sc.cycles.samples = 1


def bake_normal(high, low, folder, res, mask):
    gpu()
    img = bpy.data.images.new('source_detail', width=res, height=res)
    img.colorspace_settings.name = 'Non-Color'
    mat = bpy.data.materials.new('bake_target')
    mat.use_nodes = True
    tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = img
    mat.node_tree.nodes.active = tex
    low.data.materials.clear()
    low.data.materials.append(mat)
    active(low)
    high.select_set(True)
    sc = bpy.context.scene
    sc.render.bake.use_selected_to_active = True
    sc.render.bake.cage_extrusion = .025
    sc.render.bake.max_ray_distance = .065
    sc.render.bake.margin = 12
    bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT')
    raw = np.empty(res * res * 4, np.float32)
    img.pixels.foreach_get(raw)
    raw = raw.reshape(res, res, 4)[:, :, :3]
    save_image(folder / 'normal_raw.png', raw)
    raw[~mask] = (.5,.5,1)
    raw = dilate(raw,mask,24)
    # Normal bake must not reintroduce the source's broad waviness. Remove
    # the low-frequency XY signal, retain fine residuals with a 12 degree cap.
    vec = raw * 2 - 1
    blur = vec[:, :, :2].copy()
    for step in (1, 2, 4, 8, 12):
        blur = (blur + np.roll(blur, step, 0) + np.roll(blur, -step, 0) + np.roll(blur, step, 1) + np.roll(blur, -step, 1)) / 5
    xy = (vec[:, :, :2] - blur) * .22
    strength = np.linalg.norm(xy, axis=2)
    xy *= np.minimum(1, .20 / np.maximum(strength, 1e-6))[:, :, None]
    out = np.concatenate([xy, np.sqrt(np.maximum(.01, 1 - np.sum(xy*xy, 2)))[:, :, None]], 2)
    save_image(folder / 'normal.png', dilate(out * .5 + .5,mask))
    return float(np.mean((raw[:, :, 2] > .5)))


def route_b(args, folder):
    source = args.pc / 'a4' / 'out' / args.code / (args.code + '_ship.npz')
    a = np.load(source)
    # NPZ includes damage skins. Deduplicate identical positions so voxel
    # remesh sees one closed shape rather than disconnected texture vertices.
    # A4 NPZ stores glTF axes: +X bow, +Y up, -Z port. Rotate into Blender.
    source_pos = np.stack([a['pos'][:,0], -a['pos'][:,2], a['pos'][:,1]],axis=1)
    pos, remap = np.unique(np.round(source_pos, 6), axis=0, return_inverse=True)
    idx = remap[a['idx']]
    area = np.linalg.norm(np.cross(pos[idx[:,1]]-pos[idx[:,0]],pos[idx[:,2]]-pos[idx[:,0]]),axis=1)
    idx = idx[area > 1e-10]
    _, unique = np.unique(np.sort(idx,axis=1),axis=0,return_index=True)
    idx = idx[np.sort(unique)]
    high = mesh('AI_source_geometry', pos, idx)
    # A4's intact skin can still have open AI boundaries. Seal those before
    # asking OpenVDB for its volume or it only retains watertight fittings.
    bm = bmesh.new()
    bm.from_mesh(high.data)
    boundary = [e for e in bm.edges if e.is_boundary]
    if boundary:
        bmesh.ops.holes_fill(bm,edges=boundary,sides=0)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    print('source closure',len(boundary),'boundaries;',sum(e.is_boundary for e in bm.edges),'remain',flush=True)
    bm.to_mesh(high.data)
    bm.free()
    high.data.update()
    for p in high.data.polygons:
        p.use_smooth = True
    low = high.copy()
    low.data = high.data.copy()
    bpy.context.collection.objects.link(low)
    low.name = args.code + '_clean_retopo'
    remesh = low.modifiers.new('voxel_clean', 'REMESH')
    remesh.mode = 'VOXEL'
    remesh.voxel_size = .0045 if args.code != 'B16_23' else .006
    remesh.use_smooth_shade = True
    apply(low, remesh)
    voxel_tris = triangles([low])
    bm = bmesh.new()
    bm.from_mesh(low.data)
    unseen = set(bm.verts)
    components = []
    while unseen:
        seed = unseen.pop()
        group = {seed}
        todo = [seed]
        while todo:
            for edge in todo.pop().link_edges:
                for v in edge.verts:
                    if v in unseen:
                        unseen.remove(v)
                        group.add(v)
                        todo.append(v)
        components.append(group)
    # Tiny detached AI debris collapses to degenerate triangles when smoothed.
    # Keep substantial hull/kit components; small intentional fittings removed
    # here need rebuilding later instead of retaining floating AI fragments.
    keep = [group for group in components if len(group) >= 32]
    dropped = [v for group in components if len(group) < 32 for v in group]
    bmesh.ops.delete(bm, geom=dropped, context='VERTS')
    bm.to_mesh(low.data)
    bm.free()
    smooth = low.modifiers.new('remove_AI_ripples', 'SMOOTH')
    smooth.factor = .55
    smooth.iterations = 10 if args.code != 'B16_23' else 6
    apply(low, smooth)
    bm = bmesh.new()
    bm.from_mesh(low.data)
    bmesh.ops.triangulate(bm, faces=list(bm.faces), quad_method='BEAUTY', ngon_method='BEAUTY')
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context='VERTS')
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    print('retopo input', len(bm.faces), 'nonmanifold vertices', sum(not v.is_manifold for v in bm.verts), 'bad edges',sum(not e.is_manifold for e in bm.edges),'flips',sum(e.is_manifold and not e.is_contiguous for e in bm.edges), flush=True)
    bm.to_mesh(low.data)
    bm.free()
    low.data.update()
    bpy.context.view_layer.update()
    low.data.calc_loop_triangles()
    ti = np.array([t.vertices[:] for t in low.data.loop_triangles])
    es = np.sort(np.concatenate([ti[:,[0,1]],ti[:,[1,2]],ti[:,[2,0]]]),axis=1)
    _,ec = np.unique(es,axis=0,return_counts=True)
    print('engine precondition',len(low.data.vertices),len(ti),'bad edges',int((ec!=2).sum()),'loose removed',len(loose),'active',low.name,flush=True)
    active(low)
    # Blender 4.5 rejects edges whose XYZ deltas are all below 1e-4, even on
    # manifold input. Work in centimetre-sized coordinates for the solver,
    # then restore ship units. Geometry is unchanged by this scale round trip.
    for v in low.data.vertices:
        v.co *= 100
    low.data.update()
    result = bpy.ops.object.quadriflow_remesh(target_faces=11000 if args.code != 'B16_23' else 9000, use_mesh_symmetry=False, use_preserve_sharp=False, use_preserve_boundary=False, seed=75)
    for v in low.data.vertices:
        v.co /= 100
    low.data.update()
    quads = sum(len(p.vertices) == 4 for p in low.data.polygons)
    assert result == {'FINISHED'} and 1000 < quads < 22000, 'Quad retopology failed'
    for p in low.data.polygons:
        p.use_smooth = True
    low_tree = BVHTree.FromObject(low,bpy.context.evaluated_depsgraph_get())
    sample = pos[::max(1,len(pos)//10000)]
    source_coverage = sum(low_tree.find_nearest(Vector(v))[3] < .025 for v in sample) / len(sample)
    assert source_coverage > .90, 'Remesh lost too much of the source hull'
    active(low)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=.001)
    bpy.ops.object.mode_set(mode='OBJECT')
    atlas = atlas_positions(low,args.res)
    coverage = bake_normal(high, low, folder, args.res,atlas[2])
    bpy.data.objects.remove(high, do_unlink=True)
    mask = pbr_maps(low, folder, args.code, args.res,atlas)
    low.data.materials.clear()
    low.data.materials.append(material(folder))
    return [low], dict(source=str(source), source_sha256=sha(source), source_triangles=len(idx), voxel_triangles=voxel_tris, detached_components_removed=len(components)-len(keep), quads=quads, source_surface_coverage=source_coverage, bake_positive_z_fraction=coverage, occupied_texels=int(mask.sum()), gpu='OPTIX', metallic=0 if args.code == 'B16_23' else 'paint and exposed metal', normal_method='selected-to-active tangent bake; low-frequency removal; 12 degree cap')


def part(obj, band, bevel=.001):
    active(obj)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    if bevel:
        mod = obj.modifiers.new('machined_edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 2
        apply(obj, mod)
    # Box projection per face into one of eight horizontal trim bands. Each
    # face spans a whole band; repeated lengths stay inside the shared atlas.
    uv = obj.data.uv_layers.new(name='trim')
    for p in obj.data.polygons:
        axis = np.argmax(np.abs(p.normal[:]))
        axes = [i for i in range(3) if i != axis]
        coords = np.array([[obj.data.vertices[obj.data.loops[li].vertex_index].co[i] for i in axes] for li in p.loop_indices])
        extent = np.maximum(np.ptp(coords, axis=0), 1e-7)
        q = (coords - coords.min(0)) / extent
        for li, c in zip(p.loop_indices, q):
            uv.data[li].uv = (.012 + c[0] * .976, (band + .07 + c[1] * .86) / 8)
    PARTS.append(obj)
    return obj


def box(name, center, size, band=0, bevel=.001):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return part(obj, band, bevel)


def cylinder(name, center, radius, depth, direction=(1, 0, 0), band=3, sides=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=sides, radius=radius, depth=depth, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = Vector(direction).to_track_quat('Z', 'Y').to_euler()
    return part(obj, band, .0007)


def loft(name, x0, x1, y, z, width, height, band=0):
    sections = [(x0, width * .75), (x0 + (x1-x0)*.18, width), (x1 - (x1-x0)*.22, width), (x1, width*.20)]
    ring = [(-.65, 1), (.65, 1), (1, .45), (1, -.45), (.65, -1), (-.65, -1), (-1, -.45), (-1, .45)]
    pos = [(x, y + w * a, z + height * b) for x, w in sections for a, b in ring]
    faces = [tuple(reversed(range(8))), tuple(range(24, 32))]
    for k in range(3):
        for j in range(8):
            faces.append((k*8+j, k*8+(j+1)%8, (k+1)*8+(j+1)%8, (k+1)*8+j))
    return part(mesh(name, pos, faces), band, .002)


def trim_maps(folder, res):
    yy, xx = np.mgrid[0:res, 0:res] / (res - 1)
    band = np.minimum(7, (yy * 8).astype(int))
    v = np.mod(yy * 8, 1)
    palette = np.array([[.17,.055,.026],[.30,.12,.045],[.38,.34,.25],[.095,.10,.11],[.25,.27,.28],[.018,.021,.025],[.24,.17,.024],[.4,.025,.007]])
    base = palette[band]
    n = noise(xx*22, yy*22, xx*0)
    base *= (.87 + n*.21)[:, :, None]
    wear = ((v < .10) | (v > .90)) & (n > .54)
    base[wear] = (.29,.28,.26)
    groove = ((v > .14) & (v < .17)) | ((v > .82) & (v < .85))
    base[groove] *= .33
    vent = (band == 5) & (np.mod(xx*64, 1) > .26)
    base[vent] = (.07,.075,.08)
    hazard = (band == 6) & (np.mod(xx*15+yy*15, 1) > .5)
    base[hazard] = (.015,.016,.018)
    rough = .52 + n*.16
    metal = np.where(wear, .9, .45)
    orm = np.stack([np.ones_like(xx), rough, metal], 2)
    normal = np.zeros_like(base) + (.5,.5,1)
    normal[:, :, 1] += (np.exp(-((v-.15)/.025)**2) - np.exp(-((v-.85)/.025)**2)) * .10
    emit = np.zeros_like(base)
    emit[(band == 7) & (v > .25) & (v < .75)] = (.8,.10,.015)
    for name, rgb, col in [('base', base, True), ('normal', normal, False), ('orm', orm, False), ('emission', emit, True)]:
        save_image(folder / ('trim_' + name + '.png'), rgb, col)


def audit_mounts():
    """All authored objects must connect to the main hull through real contact."""
    bpy.context.view_layer.update()
    trees = {}
    bounds = {}
    for obj in PARTS:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bm.transform(obj.matrix_world)
        trees[obj.name] = BVHTree.FromBMesh(bm)
        coords = [v.co.copy() for v in bm.verts]
        bounds[obj.name] = (Vector(tuple(min(v[i] for v in coords) for i in range(3))), Vector(tuple(max(v[i] for v in coords) for i in range(3))))
        bm.free()
    edges = {o.name: set() for o in PARTS}
    for i, a in enumerate(PARTS):
        lo, hi = bounds[a.name]
        for b in PARTS[i+1:]:
            lb, hb = bounds[b.name]
            if not all(lo[k]-.0015 <= hb[k] and lb[k]-.0015 <= hi[k] for k in range(3)):
                continue
            touch = bool(trees[a.name].overlap(trees[b.name]))
            if not touch:
                for v in a.data.vertices:
                    near = trees[b.name].find_nearest(a.matrix_world @ v.co)
                    if near[0] is not None and near[3] < .0015:
                        touch = True
                        break
            if touch:
                edges[a.name].add(b.name)
                edges[b.name].add(a.name)
    reached = {PARTS[0].name}
    todo = list(reached)
    while todo:
        for n in edges[todo.pop()] - reached:
            reached.add(n)
            todo.append(n)
    floating = sorted(set(edges) - reached)
    assert not floating, 'Disconnected parts: ' + ', '.join(floating)
    assert all(d[0] >= -.00001 for d in GUNS), 'Backward gun'
    return dict(connected_parts=len(reached), floating=floating, gun_directions=GUNS, backward_guns=0)


def route_a(args, folder):
    # Three salvaged hull masses, as today's assembled barge, using the
    # C19 kit's loft/bevel/mount pattern. No AI surface is retained.
    loft('main_hulk', -.49,.50,0,-.02,.137,.058)
    box('upper_weld',(-.06,.07,.061),(.55,.10,.054),3)
    loft('captured_upper',-.45,.28,.075,.113,.085,.043)
    box('side_weld',(-.045,-.156,-.019),(.49,.095,.046),3)
    loft('captured_flank',-.31,.32,-.213,-.025,.072,.045,4)
    for x in [-.29,-.15,-.01,.13,.27]:
        for s in [-1,1]:
            box('armour_panel',(x,s*.126,-.007),(.105,.032,.075),0 if x<.1 else 1)
            box('panel_cap',(x,s*.126,.029),(.107,.035,.007),2 if x<-.2 else 3)
    box('bridge_base',(-.10,.075,.162),(.16,.11,.028),3)
    loft('command_block',-.18,-.025,.075,.189,.044,.026,0)
    box('bridge_roof',(-.10,.075,.217),(.115,.075,.011),2)
    box('sensor_mount',(-.10,.075,.230),(.052,.045,.018),3)
    box('phased_sensor',(-.10,.075,.248),(.041,.034,.023),5)
    # Radiator banks, not funnels or masts.
    for x in [-.31,-.28,-.25]:
        box('radiator_foot',(x,.075,.164),(.014,.087,.018),3)
        box('radiator_vane',(x,.075,.189),(.007,.082,.044),5)
    # Matched flank guns, with base, drum and ball fixed into real armour.
    for x in [-.17,.19]:
        for s in [-1,1]:
            c = Vector((x,s*.137,.017))
            box('gun_mount',c,(.070,.034,.045),3)
            cylinder('turret_drum',c+Vector((0,s*.018,0)),.027,.034,(0,s,0),3)
            d = Vector((.65,s*.76,.035)).normalized()
            for dz in [-.008,.008]:
                start=c+Vector((.006,s*.026,dz))
                cylinder('forward_out_barrel',start+d*.030,.0045,.070,d,3,16)
                cylinder('muzzle',start+d*.063,.006,.014,d,3,16)
                GUNS.append(list(d))
    # Forward launcher rack on a solid column. Each tube points toward +X.
    box('launcher_base',(.16,.072,.166),(.12,.10,.024),3)
    for y in [.042,.066,.09]:
        for z in [.183,.207]:
            cylinder('forward_launcher',(.16,y,z),.012,.115,(1,0,0),3,16)
            GUNS.append([1,0,0])
    # Embedded engine collars, fins, ducts, hatches and stolen armour.
    for x,y,z,r in [(-.49,0,-.02,.047),(-.45,.075,.113,.033),(-.31,-.213,-.025,.032)]:
        cylinder('engine_collar',(x+.006,y,z),r,.035,(-1,0,0),3)
        cylinder('engine_core',(x-.013,y,z),r*.75,.006,(-1,0,0),7)
    for i,x in enumerate([-.35,-.23,-.11,.01,.13,.25,.37]):
        box('deck_patch',(x,-.032,.041),(.080,.074,.009),[0,2,3,1,4,0,2][i])
        for s in [-1,1]:
            box('deck_conduit',(x,s*(.05 if x>.30 else .087),.041),(.090,.009,.010),3)
    for x in [-.23,-.08,.07,.22]:
        box('donor_hatch',(x,-.213,.024),(.07,.075,.010),2 if x<0 else 3)
        box('vent_bank',(x,-.213,.031),(.041,.05,.005),5)
    trim_maps(folder,args.res)
    mat=material(folder,'trim_')
    for obj in PARTS:
        obj.data.materials.append(mat)
    checks=audit_mounts()
    active(PARTS[0])
    for obj in PARTS:
        obj.select_set(True)
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name='C19_authored_trim_kit'
    return [obj], dict(**checks, parts=len(PARTS), trim_sheet_bands=8, materials=1, geometry='clean authored lofts and bevelled kit parts; no AI mesh')


def export(objects, folder, route):
    # Triangulate explicitly so tangents are defined on the same topology in
    # Blender's exporter and Godot, including the authored loft caps.
    for obj in objects:
        mod = obj.modifiers.new('export_triangles', 'TRIANGULATE')
        apply(obj, mod)
    active(objects[0])
    for obj in objects:
        obj.select_set(True)
    expected=triangles(objects)
    path=folder / ('route'+route+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_tangents=True,export_extras=True)
    before=set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    new=[o for o in set(bpy.context.scene.objects)-before if o.type=='MESH']
    got=triangles(new)
    assert got==expected and all(math.isfinite(c) for o in new for v in o.data.vertices for c in v.co), 'Export round trip failed'
    for o in new:
        bpy.data.objects.remove(o,do_unlink=True)
    return dict(triangles=expected,reimport_triangles=got,reimport='PASS',bytes=path.stat().st_size,sha256=sha(path))


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--pc',type=Path,required=True)
    p.add_argument('--work',type=Path,required=True)
    p.add_argument('--code',choices=['C19_51','D21_23','B16_23'],required=True)
    p.add_argument('--route',choices=['A','B'],required=True)
    p.add_argument('--res',type=int,default=2048)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    assert args.route!='A' or args.code=='C19_51'
    folder=args.work/args.code/args.route
    folder.mkdir(parents=True,exist_ok=True)
    start=time.perf_counter()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objects,info=route_a(args,folder) if args.route=='A' else route_b(args,folder)
    info.update(export(objects,folder,args.route))
    info.update(code=args.code,route=args.route,seconds=time.perf_counter()-start)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'prototype.blend'))
    (folder/'build.json').write_text(json.dumps(info,indent=2)+'\n')
    print('[surface75] BUILD PASS',json.dumps(info))


if __name__=='__main__':
    main()
