import unittest
from qa_math import frame, direction_status, mirror_error


class GeometryContracts(unittest.TestCase):
    def test_coordinate_frames(self):
        self.assertEqual(frame("+X", "+Z"), ((1, 0, 0), (0, 0, 1), (0, 1, 0)))
        with self.assertRaises(ValueError):
            frame("+X", "-X")

    def test_tagged_weapon_direction(self):
        self.assertEqual(direction_status((-1, 0, 0), (1, 0, 0)), "BACKWARD")
        self.assertEqual(direction_status((0, 10, 0), (1, 0, 0)), "FORWARD_OR_SIDE")
        for v in [(0, 0, 0), (float("nan"), 0, 0)]:
            self.assertEqual(direction_status(v, (1, 0, 0)), "INVALID")

    def test_declared_pair_uses_ship_center(self):
        self.assertEqual(mirror_error((8, 12, 5), (8, 8, 5), (0, 1, 0), (7, 10, 4)), 0)
        self.assertAlmostEqual(mirror_error((8, 12, 5), (8, 7, 5), (0, 1, 0), (7, 10, 4)), 1)


if __name__ == "__main__":
    unittest.main()
