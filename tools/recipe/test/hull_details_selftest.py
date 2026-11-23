"""Blender-free fixtures for the four opt-in hull methods."""

from collections import Counter
from math import isclose
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/blender/kits/shared'))
sys.path.insert(0, str(ROOT / 'contrib/codex/picket_astra_1122'))
from hull_details import FlatSoleLoft, belly_cover, recessed_plates, slatted_cassette, stripe_runs
import hegemony_H7A as astra


def bounds(component, axis):
    verts, _ = component[3]
    return min(p[axis] for p in verts), max(p[axis] for p in verts)


class HullDetailsTest(unittest.TestCase):
    def test_loft_preserves_astra_stations_and_interpolates_module_ends(self):
        profile = FlatSoleLoft(astra.STATIONS, sole=astra.SOLE, flank=(-.09, .036),
                               chine_height=.055, widths=(.83, .87, .77))
        self.assertEqual(len(profile.rings()), 9)
        for x in (-2.89, *profile.xs[1:-1], *astra.SEAMS, 2.94, 3.22):
            self.assertEqual(profile.ring(x), astra.ring(x))
        module = profile.rings(*astra.SEAMS)
        self.assertEqual([ring[0][0] for ring in module], [-1.76, -1.65, -.52, .38, 1.12, 1.57])
        other = FlatSoleLoft([(0, 2, 1), (4, 4, 3)], sole=-2, flank=(-1, 0),
                             chine_height=.5, widths=(.6, .85, .7))
        self.assertAlmostEqual(other.ring(2)[5][1], 2.1)
        self.assertEqual(other.ring(2)[5][2], -2)
        self.assertEqual(other.ring(2)[0][2], 2)
        with self.assertRaises(ValueError):
            other.rings(-1, 2)

    def test_plate_cuts_are_backed_and_leave_real_clearance(self):
        rings = [[(x, y, z) for y, z in ((-1, 0), (1, 0), (1, -1), (-1, -1))] for x in (0, 1, 2)]
        options = dict(pitch=1, gap=.1, depth=.2, seat=.02, bevel=.02)
        for ordered in (rings, rings[::-1]):
            verts, faces = recessed_plates(ordered, [0], **options)
            self.assertEqual((len(verts), len(faces)), (48, 40))
            channels = Counter(tuple(sorted((a, b))) for face in faces
                               for a, b in zip(face, face[1:] + face[:1]))
            self.assertEqual(set(channels.values()), {2})
            self.assertEqual({p[2] for p in verts}, {-.02, 0, .2})
            self.assertTrue(all(abs(p[1]) >= .05 for p in verts))
            self.assertTrue(all(abs(p[0] - 1) >= .05 - 1e-9 for p in verts))
        verts, _ = recessed_plates(rings, [2], **options)
        self.assertAlmostEqual(min(p[2] for p in verts), -1.2)
        verts, _ = recessed_plates(rings, [0], keep=lambda p, r: p[0] > 1, **options)
        self.assertEqual(len(verts), 24)
        self.assertEqual(recessed_plates(rings, [0], **(options | {'bevel': .5})), ([], []))

    def test_cassette_slats_and_cover_are_separate_and_seated(self):
        cassette = slatted_cassette(length=2, width=1, depth=.3, rim=.1, seat=.05,
                                    slats=4, slat_width=.2, materials=('back', 'rim', 'fin'))
        back, *frame, first, second, third, fourth = cassette
        self.assertEqual(len(frame), 4)
        self.assertEqual(bounds(back, 2), (-.05, 0))
        for a, b in ((first, second), (second, third), (third, fourth)):
            self.assertGreater(bounds(b, 0)[0], bounds(a, 0)[1])
            self.assertLess(bounds(a, 2)[1], bounds(frame[0], 2)[1])
        *flange, lid = belly_cover(length=1, width=.6, depth=.09, rim=.06, seat=.02, gap=.01,
                                  materials=('rim', 'lid'))
        self.assertEqual(lid[:3], ('lid', 'body', 'lid'))
        self.assertEqual(len(flange), 8)
        self.assertEqual(bounds(lid, 2), (.03, .09))
        self.assertEqual(bounds(flange[0], 2), (-.02, .03))
        self.assertGreater(bounds(flange[0], 0)[1], bounds(lid, 0)[0])
        self.assertAlmostEqual(bounds(lid, 0)[0] - bounds(flange[4], 0)[1], .01)
        for rail in flange:
            self.assertTrue(any(not lo < 0 < hi for lo, hi in (bounds(rail, 0), bounds(rail, 1))))

    def test_stripe_runs_clip_and_merge_door_keepouts(self):
        stations = [0, 1, 2, 3, 4, 5]
        self.assertEqual(stripe_runs(stations, [], clearance=0), [stations])
        self.assertEqual(stripe_runs(stations, [(-2, 8)], clearance=0), [])
        runs = stripe_runs(stations, [(2.2, 2.5), (-1, .3), (6, 7), (1.7, 2.15), (4.7, 6)], clearance=.1)
        self.assertEqual([len(run) for run in runs], [3, 4])
        for actual, expected in zip(runs, [[.4, 1, 1.6], [2.6, 3, 4, 4.6]]):
            self.assertTrue(all(isclose(a, b) for a, b in zip(actual, expected)))


if __name__ == '__main__':
    unittest.main()
