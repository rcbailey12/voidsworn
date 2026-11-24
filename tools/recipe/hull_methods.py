"""Place the shared hull geometry in a build sheet with the recipe's usual tags."""

from pathlib import Path
import sys

from mathutils import Vector

KITS = Path(__file__).resolve().parents[1] / 'blender' / 'kits'
sys.path[:0] = [str(KITS / 'shared'), str(KITS)]
from geom import Part
from hegemony.parts import module_panels
from hull_details import FlatSoleLoft, belly_cover, in_plate_keepout, slatted_cassette, stripe_runs


def loft_module(kit, name, profile, material, *, thickness, start=None, end=None, cap=True):
    """Make one pressure hull module with its recipe-readable inward shell."""
    if thickness <= 0:
        raise ValueError('pressure hull thickness must be positive')
    obj = kit.loft_rings(name, profile.rings(start, end), material, cap=cap)
    skin = obj.modifiers.new('shell', 'SOLIDIFY')
    skin.thickness = thickness
    skin.offset = -1
    skin.use_rim = True
    return obj


def plate_region(kit, name, rings, facets, *, pv, gap, unit, t_big, t_small,
                 mats=('hgrey', 'hpanel'), keep=None, keepouts=(), inv=None):
    """Place the Navy's two-size grid and return the objects grouped by material.

    keep is the sheet's land predicate. keepouts is an explicit list of
    (centre, reach) pairs for fittings that need bare land.
    """
    keepouts = tuple(keepouts)

    def reserved(centre, radius):
        return (keep is not None and keep(centre, radius)) or in_plate_keepout(centre, radius, keepouts)

    panels, _ = module_panels(rings, facets, pv=pv, gap=gap, unit=unit, t_big=t_big, t_small=t_small,
                              mats=mats, keep=reserved)
    objects = []
    for material, mesh in panels.items():
        obj = kit.hull_detail(f'{name}_{material}', mesh, material, inv=None if objects else inv,
                              kind='plate', subs=['panel', 'seam', 'module'])
        if obj is not None:
            objects.append(obj)
    return objects


def mount_service_part(kit, name, components, *, kind, pos, normal, forward=(1, 0, 0), inv=(), note=''):
    """Seat a cassette or cover through the sheet kit, sharing its fit and recipe tags."""
    part = Part(kind)
    for component in components:
        part.add(*component)
    return kit.organ(name, part, pos, normal, fwd=forward, inv=inv, src='designed', note=note)


def broken_stripe(kit, name, stations, doors, sample, *, clearance, race, stripe):
    """Lay trim and inlay using the same door cuts. sample(x) supplies a point and normal.

    Each layer is (width, thickness, material). The inlay lies on top of the race.
    """
    race_width, race_depth, race_mat = race
    stripe_width, stripe_depth, stripe_mat = stripe
    for i, run in enumerate(stripe_runs(stations, doors, clearance=clearance)):
        points, normals = zip(*(sample(x) for x in run))
        directions = [Vector(normal).normalized() for normal in normals]
        kit.strip(f'{name}_race_{i}', points, race_width, race_depth, directions, race_mat)
        inlay = [Vector(p) + n * race_depth for p, n in zip(points, directions)]
        kit.strip(f'{name}_stripe_{i}', inlay, stripe_width, stripe_depth, directions, stripe_mat)
