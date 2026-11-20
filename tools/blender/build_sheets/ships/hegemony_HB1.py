"""hegemony_HB1: the Navy bomber wing craft (data.js bomber: cls 'Squadron', bombs T; hp 28, sp 5).

Issue 1373 (R362: anything solid near a ship is built from the ship part kits and takes the hull finish). The Navy had no
approved bomber, so the game drew a code-built box. HB1 is the bomber of Ryan's accepted Navy fighter HF1D (R259, Nov 15 2026):
this file builds HF1D's machined wedge (hegemony_HF1D.py) half as deep again, so it reads as the heavier craft of the same
family, and puts a bomb cassette (the Navy kit's rocket_rack: a machined module of two tubes) where the fighter carries its gun
cassette. Nothing hung under the hull, no canopy, no wings (R254). Size 1.6 (scale.md Squadron row), +X bow.
  blender -b -P tools/blender/build_sheets/build.py -- hegemony_HB1 OUT render
"""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location('hegemony_HF1D_for_HB1', Path(__file__).with_name('hegemony_HF1D.py'))
F = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(F)

CODE = 'hegemony_HB1'
NAME = 'Navy bomber (Hegemony Navy bomber wing craft, the HF1D family)'
FACTION = F.FACTION
CLASS = F.CLASS
LENGTH = F.LENGTH
GAME = "data.js bomber (cls 'Squadron'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)"
BEAUTY = F.BEAUTY
KIT = 'hegemony'
CONCEPT_SHEET = F.CONCEPT_SHEET
CONCEPT_VIEWS = getattr(F, 'CONCEPT_VIEWS', None)
CROPS = getattr(F, 'CROPS', None)
SHEET = dict(F.SHEET, version=1, round='first sheet (issue 1373, the HF1D family\'s bomber)', date='2026-11-20', blend='opus1373',
             blend_where='built in the issue 1373 cloud thread (Blender 4.5 bpy wheel, Cycles CPU); `build.py hegemony_HB1 <out> render` rebuilds it from this file',
             before='HF1D', before_note='The accepted Navy fighter\'s wedge, half as deep again, with a bomb cassette in place of the gun cassette.')
U = F.U

# the bomber's proportions on the shared wedge: deck and belly half as deep again (the plan stays the fighter's)
DEPTH_K = 1.5
F.CODE = CODE
F.ST = [(n, hw, zt * DEPTH_K, zb * DEPTH_K) for (n, hw, zt, zb) in F.ST]
F.HULL = [(U(r[0]), U(r[1]), U(r[1]), U(r[3]), U(r[2]), 0.0, 0.0) for r in F.ST]
BX = 0.36     # the cassette's station: the prow recess, its back clear of the sensor slit in the ridge's front face
CELL = 0.05   # the tube pitch (share of LENGTH)


def build(K):
    real_gun = K.gun
    K.gun = lambda *a, **k: None   # the fighter's gun cassette is not built: the bomb cassette takes its recess
    try:
        F.build(K)
    finally:
        K.gun = real_gun
    K.launcher('BT', (U(BX), 0.0, F.deck(BX) + U(CELL * 0.5)), 1, 2, cell=U(CELL), depth=U(0.085), yaw=0.0, pitch=0.0, slot='T', weapon='bombs',
               inv='bomb_cassette', note='the bomb payload (data.js bombs T, 2 shots): a machined cassette of two tubes in the prow recess, fixed forward; the craft turns onto its target')
    K.change('Built on the accepted HF1D fighter: the same machined wedge half as deep again, with a two-tube bomb cassette in the prow recess',
             'issue 1373: the Navy had no bomber model; one family per faction, the bomber reads as the heavier craft (R259, R362)')
