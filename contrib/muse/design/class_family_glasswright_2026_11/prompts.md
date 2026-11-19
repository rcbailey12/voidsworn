# Glasswright: image prompts (issue 1146)

Generation pattern: the Sliver beauty was generated image-to-image from
the CD5 concept with a plain-clay instruction, then corrected once for
rigidity; the other beauties were generated from the corrected Sliver
beauty as the material and shape reference. Sheets are image-to-image
from each beauty. The Prism beauty and the family line-up each needed
corrective takes, recorded below; the line-up was finally built as a
scale composite instead (see designs.md).

## sliver_beauty (reference: CD5 concept)

Using the attached picture ONLY as the reference for the hull SHAPE (a
long flowing leaf of twisted pulled strands, symmetric about its long
axis): draw a much SMALLER frigate of the same family, a single spaceship
in deep space, three-quarter view from the front and above, bow pointing
left, rendered ENTIRELY in a plain matte light-grey clay material like an
unpainted sculptor's model: NO colour, NO glass, NO transparency, NO glow,
no lights of any kind. A narrow dart-like leaf hull, one continuous smooth
skin with a low ridge along the centreline. At the very tip of the bow,
three small smooth rounded beads sit in a tight row along the centreline,
grown out of the skin itself. The stern tapers to one single smooth
rounded drive bulb. No wings, no petals, no sails, no masts, no crystals,
nothing insect-like. Painterly realistic rendering of the grey clay form,
softly lit. No text, no other ships.

Correction take (the delivered beauty): redraw with a RIGID, taut, smooth
leaf like a carved wooden ship model, firm surfaces with gentle twisted
strands, NOT soft or cloth-like; bow points left with the three beads at
its tip; the stern drive bulb much smaller and blended into the taper, not
a ball on a stick.

## lancet_beauty (reference: sliver beauty, corrected)

Using the attached clay model as the reference for material and shape
language (plain matte light-grey clay, a rigid carved leaf hull with
braided strand grooves and a low centreline ridge): draw a LARGER
destroyer of the same family, three-quarter view from the front and above,
bow pointing left, same plain matte clay material, NO colour, NO glass, NO
glow. A longer, narrower rigid leaf hull. In the centre of the bow face
sits ONE large smooth rounded lens shape grown out of the hull, and around
its rim sit three small rounded beads in a crown. The hull tapers to the
stern, ending in TWO small rounded drive bulbs side by side blended into
the taper. No wings, no petals, no sails, no masts, no crystals, nothing
insect-like.

## prism_beauty (reference: sliver beauty, corrected)

Same preamble. A LARGER cruiser: a broad rigid leaf hull. From the bow
extend TWO long smooth tapered lance shapes, pulled out of the hull's own
substance, one above the other along the centreline, pointing forward. One
single smooth rounded lens shape sits in a gentle swell on the centreline
at the hull's widest point. The stern ends in TWO rounded drive bulbs side
by side blended into the taper.

Correction take (the delivered beauty): the first take spread the lances
to the flanks like tusks and inherited the Sliver's bow beads. Redraw: the
two lances grow out of the CENTRE of the bow, one directly above the other
on the centreline, close together; remove the beads completely; keep the
centreline lens swell; stern bulbs smaller and blended.

## aperture_beauty (reference: sliver beauty, corrected)

Same preamble. The LARGEST carrier: a very WIDE rigid leaf hull with a
thick centreline spine. ONE single long smooth tapered lance grows out of
the centre of the bow. Behind it, one small smooth rounded lens sits in a
swell on the spine. In the aft half, TWO large smooth oval holes pierce
the hull, one on each side of the spine, like windows through the leaf,
their rims smooth and rounded. The stern ends in THREE rounded drive
bulbs in a row blended into the taper.

## Sheets (template, one per ship, reference: that ship's beauty)

Using the attached picture as the exact design reference, draw a
three-view concept sheet of THE SAME clay-model ship on one page with a
flat neutral dark grey background: a true top view (bow pointing up the
page), a true side view (bow pointing left), and a front view, the whole
ship fully visible in every view, orthographic with no perspective
distortion, one soft light from forward and above in all views. Keep the
design exact and the material plain matte light-grey clay throughout:
[the ship's feature list from designs.md, in one sentence]. No colour, no
glass, no glow, no wings, no petals. No text, no labels, no other ships.

## family_lineup (NOT generated; composite)

Three generated takes were rejected: the first drew a top-view chart with
a hole in place of the Lancet's lens and four apertures on the carrier;
the second and third kept drawing three bow spikes on the two-lance hulls
despite explicit correction. The delivered family_lineup.png is a
composite built from the four sheets' side views and CD5's settled side
render, scaled to true game lengths with a short Python/PIL script
(crop each sheet's side panel by content band, resize at 56 px per game
unit, stack on a dark canvas; CD5 flipped so all bows point left).
