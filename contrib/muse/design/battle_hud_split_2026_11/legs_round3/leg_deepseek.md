# Issue 1006 round 3, DeepSeek leg (iconography: silhouettes and glyph upgrade)

Model gate: DeepSeek, DeepThink ON and Search OFF, verified before the pack was pasted and again after the answer completed (a 63 second thinking block ran). New chat, pack pasted as text (paste-original used). Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule.

1. Ship silhouette construction
    
    Common rules: side profile, bow to the right, solid off-white ink shape, no outline, no tile. Use one flat shape with negative notches only where they change the outer contour. Draw on a 40 px tall anchor canvas and a 16 px tall fleet canvas from the same vector master. At 40 px, internal negative cuts are allowed. At 16 px, only outer contour, stern block, and one spine bump or step survive. State: full off-white for ready; muted damage colour replaces ink from the stern forward in flat steps, never a gradient; acting ship gets an ember underline below the silhouette, 2 px at 40 and 1 px at 16; unavailable drops to one third opacity. Red is never used except on a Nemesis hull mark.
    
    - Frigate. Length about 5.5 hull units, height about 1.4. Sharp wedge bow, low flush deck, single small dorsal fin near the stern, one compact engine block with one nozzle. Signature: the fin is set well aft and the bow is a clean knife point. At 16 px: short, low, pointed blob with a small stern bump. At 40 px only: bow antenna, nozzle ring, fin notch.
    - Destroyer. Length about 8 units, height about 1.8. Angular cutwater bow, squared stern with twin nozzles, one raised box amidships, low aft deck. Signature: two parallel dorsal rails running aft from the amidships box. At 16 px: longer than frigate, one clear amidships hump, twin stern notch. At 40 px only: rail gaps, nozzle rings, bow step.
    - Cruiser, Vigil pattern. Length about 10 units, height about 2.2. Flared clipper bow with slight overhang, three-nozzle engine block, continuous raised spine from forward third to aft third, bridge tower at about 60 percent length. Signature: a sensor gap notch in the spine just forward of the bridge. At 16 px: long low hull, continuous top ridge, pronounced stern block. At 40 px only: bridge tower profile, nozzle segmentation, spine gap.
    - Carrier. Length about 9.5 units, height about 3.0. Blunt bow with lower lip, flat flight deck spine, small island bump near stern, squared stern with four nozzles and deck overhang. Signature: rectangular hangar mouth cut into the forward side under the deck. At 16 px: tall slab, flat top, forward lower notch, big stern block. At 40 px only: hangar mouth, deck lip, launch rail ticks.
    - Capital hull. Length about 12 units, height about 4.0. Armoured ram bow with protruding lower jaw, stepped three-tier superstructure, massive five-nozzle stern block, ventral keel bulge amidships. Signature: the ram jaw and the stepped top together. At 16 px: very long, tall stepped blob, ram notch, huge stern block. At 40 px only: armour belt notches, secondary turret bumps, nozzle rings.
    
    2. Upgraded glyph constructions
    
    Common line rule: two stroke weights only. Main stroke about 6 percent of glyph height, detail stroke about 3 percent, clamped to 1 px minimum. At 32 px this is roughly 2 px and 1 px. At 20 px the detail stroke is hidden. Every glyph stays flat vector, no fill except the solid silhouette family.
    
    Weapon glyphs, about 20 px design size:
    
    Battery. Base: a shared recoil cradle holding three stacked barrels, with a short trunnion arc at the rear. Signature: the centre barrel is longer and carries a single muzzle-brake notch. Interior: one diagonal recoil lug behind the breech. At 20 px: cradle, three barrels, longer centre barrel. At 32 px only: muzzle notch, recoil lug.
    
    Lance. Base: a narrow tapered projector body on a pivot, with a rear counterweight ring. Signature: the emitter tip forks into two short prongs with a clean gap. Interior: one centreline from breech to fork and one small capacitor block at the rear. At 20 px: long triangle with a forked tip; if the fork closes, keep one notch. At 32 px only: capacitor block, pivot ring detail.
    
    Torpedo. Base: side-profile munition with a blunt notched nose, straight body, and forked tail. Signature: one transverse band behind the nose and two unequal tail fins. Interior: one centreline and one small fuel-cell tick. At 20 px: body, nose notch, forked tail. At 32 px only: band, fuel tick.
    
    Point defence. Base: low trapezoid mount on a ring base, two short barrels at different elevations, and a broken 90 degree sweep arc above. Signature: the arc carries three range ticks, and the barrels are deliberately unequal. At 20 px: mount, two barrels, arc. At 32 px only: range ticks, ring detail.
    
    Integrity glyphs, 12 to 20 px:
    
    Hull. Base: longitudinal keel plate with a raked bow and a stepped stern notch. Signature: one transverse frame rib near amidships. Interior: one centre ridge line. At 12 px: plate, bow rake, stern notch. At 20 px: frame rib and ridge. No rivets, no text.
    
    Shield. Base: hexagonal shield outline with an inner offset hex and a single vertical meridian. Signature: the top vertex is notched and the two lower edges carry one bevel tick each. At 12 px: outer hex and meridian. At 20 px: inner hex and bevel ticks. No fill, no blue except shield readouts.
    
    Order glyphs, about 32 px:
    
    Brace. Base: A-frame with a horizontal load beam and a central collar. Signature: one side carries a turnbuckle tick and the collar is a small open diamond. Interior: one short bolt tick on the beam. At 20 px: A-frame, beam, collar. At 32 px only: turnbuckle, bolt tick.
    
    Focus fire. Base: three arrowheads converging on a central open diamond, with one broken outer arc. Signature: the arc is deliberately broken into four segments and one segment is thicker. At 20 px: three arrowheads and centre diamond. At 32 px only: arc segments.
    
    Turn. Base: one hexagon corner with a heavy curved arrow wrapping two edges. Signature: the arrowhead is barbed and the hex corner carries a small pivot dot. At 20 px: arc and barbed head. At 32 px only: pivot dot and hex edge detail.
    
    Fire for effect. Base: a broken horizontal bracket over three staggered descending impact darts. Signature: the darts are unequal lengths and the bracket has two range ticks. At 20 px: bracket and three darts. At 32 px only: range ticks.
    
    End ship. Base: short ship-profile bar with a vertical end-stop at the bow and a single downward chevron beneath. Signature: the end-stop has a notch and the wake behind the bar is three diminishing dashes. At 20 px: bar, end-stop, one dash. At 32 px only: notch, remaining dashes.
    
    Command. Base: a command star with unequal points, one long forward point, and a small orbit arc. Signature: the centre is a hollow diamond and the long point is split. At 20 px: star and centre diamond. At 32 px only: split point and orbit arc.
    
    3. Detail budget
    
    Layer the glyph in four named layers and hide layers by size.
    
    Layer 1, contour: always present at every size. This is the base shape and any notch that changes the outer silhouette.
    
    Layer 2, primary interior: one centreline, one crossbar, one arc, or one frame rib. Survives to 20 px for weapons and orders, and to 12 px for integrity only as the single meridian or ridge.
    
    Layer 3, signature detail: the fork, notch, unequal barrels, staggered darts, turnbuckle, or hangar mouth. Survives to 20 px. At 16 px it survives only if it changes the contour.
    
    Layer 4, micro detail: secondary ticks, rivets, inner offsets, nozzle rings, rail gaps. Only at 32 to 40 px.
    
    Builder rule: if a detail cannot be removed without changing the glyph's identity, it belongs in Layer 1 or Layer 3. If it can be removed, it belongs in Layer 4. Below 20 px, allow at most one interior line. Below 16 px, allow no interior line except a contour notch. No stroke thinner than 1 px at design size. Test each glyph in monochrome on the dark veil with labels hidden; if the label is needed, remove Layer 3 and retest. At 16 px, silhouettes must read as distinct blobs by outer contour alone.
    
    4. What I would refuse
    
    Faction chrome, heraldry, filigree, or decorative borders.
    
    Skeuomorphic metal, bevels, highlights, drop shadows, glows, or gradients.
    
    Tiny text, numbers, or labels inside glyphs.
    
    Tiles, boxes, hex frames, or any background fill used to make a glyph read.
    
    More than two stroke weights.
    
    Red outside the Nemesis, glacier blue outside shield readouts, ember as decoration.
    
    Detail that only works at 40 px and collapses at 16 px.
    
    Animated glyph internals or particle effects inside the mark.
    
    Any glyph that needs a tooltip to be distinguished from its neighbour.
    
    5. Honest costs
    
    Agent cost: one agent pass for silhouette construction and 16 px contour reduction; one agent pass for the weapon glyph set; one agent pass for integrity and order glyphs; one agent pass for Godot import, state variants, and size contact sheets; one revision loop after review. No human days are assumed.
    
    Risk: richer glyphs can read worse at 20 px and 16 px because the added signature detail competes with the contour. The lance fork, point defence ticks, and carrier hangar mouth are the highest-risk shapes.
    
    Test before adoption: render the full set on the actual dark veil at 32, 20, 16, and 12 px, at 100 percent zoom, in off-white, dim, ember underline, and damage states. Hide all labels. Check that every weapon glyph is distinguishable at 20 px and every silhouette at 16 px by contour alone. Downsample to half size and back once to simulate shelf blur. If any glyph fails, drop Layer 3 for that glyph and retest. Adopt only the set that passes without labels.
