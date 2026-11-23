"""Place the shared hull geometry in a build sheet with the recipe's usual tags."""

from pathlib import Path
import sys

from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'blender' / 'kits' / 'shared'))
from geom import Part
from hull_details import FlatSoleLoft, belly_cover, recessed_plates, slatted_cassette, stripe_runs


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


def plate_region(kit, name, rings, facets, material, *, pitch, gap, depth, seat, bevel, keep=None, inv=None):
    """Lay plate cuts after mounts are in place, including any sheet-specific reserves."""
    def reserved(centre, radius):
        point = Vector(centre)
        return (keep is not None and keep(point, radius)) or any(
            (point - origin).length < reach + radius for origin, reach in kit.keepouts)

    mesh = recessed_plates(rings, facets, pitch=pitch, gap=gap, depth=depth,
                           seat=seat, bevel=bevel, keep=reserved)
    return kit.hull_detail(name, mesh, material, inv=inv, kind='plate', subs=['panel', 'seam', 'module'])


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
