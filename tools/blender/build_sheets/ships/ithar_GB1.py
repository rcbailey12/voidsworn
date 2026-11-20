"""ithar_GB1: the Needle bomber, the Glasswright bomber wing craft (data.js bomber: cls 'Squadron', bombs T; hp 28, sp 5).

Issue 1373 (R362). The bomber of Ryan's GF1 pick (Nov 20 2026): the same family as the Needle fighter (ithar_GF1, whose body
this file builds with its own proportions), fuller in the beam and depth so it reads as the heavier craft, and built round its
payload: two cut green seed stones in launch wells either side of the bow, fixed forward (a craft turns onto its target on a
bombing run, weapon_match.py 'bombs'). Nothing hung under the hull (R254). Size 1.6 (scale.md Squadron row), +X bow.
  blender -b -P tools/blender/build_sheets/build.py -- ithar_GB1 OUT render
"""
import importlib.util
import math
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location('ithar_GF1_for_GB1', Path(__file__).with_name('ithar_GF1.py'))
F = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(F)

CODE = 'ithar_GB1'
NAME = 'The Needle bomber, the Glasswright bomber wing craft'
FACTION = F.FACTION
CLASS = F.CLASS
LENGTH = F.LENGTH
GAME = "data.js bomber (cls 'Squadron'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = 'docs/ship_pipeline/build_sheets/ithar_GF1/concept.jpg'
CONCEPT_SHEET = BEAUTY
SHEET = dict(F.SHEET, round='first sheet (the bomber of Ryan\'s GF1 pick)',
             blend_where='built in the issue 1373 cloud thread (Blender 4.5 bpy wheel, Cycles CPU); `build.py ithar_GB1 <out> render` rebuilds it from this file',
             before='The GF1 family', before_note='The Needle fighter\'s body at bomber proportions, with two seed-stone launch wells at the bow.')
CAMERA = F.CAMERA
U = F.U

# the bomber's proportions, set on the shared body (fuller: about 3.6 to 1, seven ribbons)
F.CODE = CODE
F.HW, F.HH = 0.13 * LENGTH, 0.092 * LENGTH
F.NRIB = 7
F.HALF = 0.25
F.CORE_NOTE = 'a fuller spindle about 3.6 to 1 (the heavier craft of the family), a point at the bow, a blunt stern face for the stones'
SEED_X = U(0.27)       # the launch wells' station
SEED_A = 0.42          # their section angle below the beam (radians)


def build(K):
    F.body(K)
    P = F.gw_kit('parts')
    from mathutils import Vector
    # ---------------- the payload: two cut green seed stones in launch wells, either side of the bow (bombs T, 2 shots) ----------------
    apertures, built_ids = [], []
    for side, sn in ((1, 'p'), (-1, 's')):
        fid = 'BT' + sn
        a = -SEED_A if side > 0 else math.pi + SEED_A
        c = Vector(F.core(SEED_X, a))
        nrm = Vector((0.0, c.y, c.z)).normalized()
        r = U(0.020)
        well = c + nrm * U(0.012)
        K._obj(fid + '_well_lip', *F.ellipsoid(tuple(well), (U(0.034), r * 1.25, r * 1.25), 16, 8), 'gw_silver', smooth=True, grp=fid)
        K._obj(fid + '_seed', *F.ellipsoid(tuple(well + nrm * U(0.004)), (U(0.028), r, r), 16, 8), 'gw_gem_green', smooth=True, grp=fid)
        tip = well + nrm * U(0.004) + Vector((U(0.028), 0, 0))
        K._obj(fid + '_seed_tip', *P.cut_lens(tuple(tip), (1, 0, 0), r * 0.7, r * 0.5, 8), 'gw_gem_green', grp=fid)
        for o in K.coll.objects:
            if o.get('grp') == fid:
                o['part_kind'] = 'launcher'; o['machine'] = 1
        ap = dict(pos=tuple(tip + Vector((r * 0.5, 0, 0))), dir=(1.0, 0.0, 0.0), r=r, length=LENGTH * 0.8, cone=4.0, what='launch well')
        apertures.append(ap)
        built_ids.append(fid)
    # one launcher with two wells (one bomb each, both every volley)
    fid = 'BT'
    for o in K.coll.objects:
        if o.get('grp') in ('BTp', 'BTs'):
            o['grp'] = fid
    cv = sum((Vector(a_['pos']) for a_ in apertures), Vector()) / 2
    lane = dict(apex=tuple(cv), dir=(1, 0, 0), u=(0, 1, 0), w=(0, 0, 1), hu=U(0.06), hw=U(0.04), half=4.0, length=LENGTH * 0.8, what='firing lane')
    K.fitdata.append(dict(id=fid, kind='launcher', slot='T', lanes=[lane], apertures=apertures))
    K.features.append(dict(id=fid, kind='launcher', what='two cut green seed stones in launch wells, fixed forward', count=2, pos=tuple(cv),
                           aim=(0.0, 0.0), slot='T', weapon='bombs', src='picture',
                           note='the bomb payload (data.js bombs T, 2 shots): a seed stone each side of the bow, both every volley; the craft turns onto its target',
                           inv=['seed_wells']))
    K.built.append(dict(id=fid, kind='launcher', type='bomb_tube', inv=['seed_wells'], shaped=True, detailed=True, subs=['silver lip', 'seed stone', 'cut tip']))
    K.change('The bomb payload is two cut green seed stones in silver-lipped wells either side of the bow, fixed forward',
             'R254: nothing hung under the hull; the Glasswrights fight with light from cut stones; the bomber turns onto its target (weapon_match.py bombs)')
    K.change('Fuller than the fighter (about 3.6 to 1 against 5 to 1) with seven ribbons', 'the bomber reads as the heavier craft of the same family')
