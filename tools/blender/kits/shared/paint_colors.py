# Shared colour maths for faction paint stacks (issue 733). Palettes, hue boosts and whether to compensate for the game's
# battle lift stay in each faction stack. This module needs NumPy only, so the maths can be checked without Blender.
import os, re
import numpy as np

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..'))

# The game's light on a face at about 45 degrees to the key (look.gd: key 2.0, ambient 0.25 x key): the factor between an
# albedo and the tone the face shows, checked by the Hullbreaker sandbox preview under the game's light (issue 601).
LIGHT_GAIN = 1.45


def battle_lift(faction):
    """Read a faction's battle lift from godot/render/look.gd READ, its one home (R227)."""
    p = os.path.join(REPO, 'godot', 'render', 'look.gd')
    with open(p, encoding='utf-8') as f:
        m = re.search(r'"%s":\s*\{[^}]*"lift":\s*([0-9.]+)' % re.escape(faction), f.read())
    if not m: raise SystemExit('paint stack: no %s lift in godot/render/look.gd READ' % faction)
    return float(m.group(1))


def _linear(srgb):
    c = np.asarray(srgb, np.float64) / 255.0
    return np.where(c <= .04045, c / 12.92, ((c + .055) / 1.055) ** 2.4)


def lin(srgb, *, lift=1.0, saturation=None):
    """sRGB show-tone (0..255) to paint albedo, with the faction's lift and optional hue boost.

    No saturation step is applied unless requested; even a neutral boost would clip dark channels and change the paint.
    The default leaves the game's battle lift uncompensated, as the Hullbreaker palette requires.
    """
    c = _linear(srgb)
    if saturation is not None:
        y = float(c @ np.array((.2126, .7152, .0722))); c = np.clip(y + (c - y) * saturation, y * .15, None)
    return tuple(float(x) / (LIGHT_GAIN * lift) for x in c)


def lin_raw(srgb):
    """sRGB (0..255) to linear, without paint lighting compensation or a hue boost (for lights and tone steps)."""
    return tuple(float(x) for x in _linear(srgb))
