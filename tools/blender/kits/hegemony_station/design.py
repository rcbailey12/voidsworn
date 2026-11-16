"""station_T2 build-sheet design. World units, +Z up. No ship-length normalization.

The build sheet is the design authority, including the station's module joints.
This is a review design, not an approved replacement for O1_37.
"""
import math

CODE = 'station_T2'
CONCEPT = 'contrib/muse/design/station_concept_2026_11/station_T2_beauty.jpg'
PLAN = 'contrib/muse/design/station_concept_2026_11/station_T2_scale.jpg'
PACK = 'contrib/muse/design/station_pack_2026_11/pack.md'
CORE = dict(decks=9, pitch=2.5, radius=5.0, bottom=-5.6, wall=0.22)
RING = dict(outer=17.0, inner=14.4, bottom=-0.9, height=2.8,
            slots=12, gap=10, modules=6)
# root, intact tip, bearing height, width, module count. Arm 3 is the stub.
ARMS = [dict(angle=0, root=4.8, tip=25.75, z=2.0, width=3.0, modules=5),
        dict(angle=60, root=4.8, tip=23.0, z=-2.7, width=1.65, modules=5),
        dict(angle=180, root=4.8, tip=25.75, z=2.0, width=4.4, modules=5),
        dict(angle=270, root=4.8, tip=9.7, z=-2.7, width=1.65, modules=2)]
# Five different caps on five different heights. Lean is on the array tower.
TOWERS = [dict(x=-9.2, y=6.0, base=2.0, height=17.5, cap='array', lean=-0.10),
          dict(x=-5.6, y=9.0, base=1.9, height=13.5, cap='dishes', lean=0.0),
          dict(x=-1.9, y=10.8, base=1.9, height=16.0, cap='dome', lean=0.0),
          dict(x=2.0, y=9.6, base=1.9, height=14.5, cap='crane', lean=0.0),
          dict(x=-18.2, y=0, base=4.3, height=6.2, cap='antenna', lean=0.0)]
RADIATORS = [dict(angle=a, radius=7.0, width=3.2, top=-5.5, bottom=-14.0)
             for a in (38, 142, 218, 322)]
MOTION = dict(pivot=(0, -10.0, -3.6), length=6.0, period=240.0,
              swing_degrees=3.0, swing_period=40.0, clearance_radius=4.0)
# Counts belong here, not in a second painted version of the station.
LIGHT_CLUSTERS = [dict(kind='core', deck=d, count=12, angle=42) for d in (0, 1, 2)] + [
    dict(kind='ring', slot=s, count=15) for s in (1, 2)] + [
    dict(kind='equipment', count=10), dict(kind='core', deck=4, count=14, angle=42)]
BATTERIES = [(-0.85, -9.7, -2.4), (8.2, -8.7, -0.2),
             (-4.8, -0.8, 1.3), (-9.2, 6.0, 2.6), (13.9, -8.0, 0.4)]
JOINTS = dict(core=[CORE['bottom'] + i * CORE['pitch'] for i in range(1, 9)],
              ring=[math.radians(i * 30) for i in range(12)],
              arms='module collars; torn root and collar stay separate',
              towers='base ring, mast module rings, whole cap',
              radiators='header manifolds')
CHANGES = [
    'The rules main station occupies seven cells (centre plus its six neighbours), not three cells. '
    'The source plan fits inside their union; the source footprint is three hex columns wide. '
    'R247 uniform review scaling now exceeds that live union; footprint integration remains open before a swap.',
    'The secondary spokes are offset from the docking arms; each tower has a bridge to a spoke or the bearing deck.',
    'The drum stack rises above the ring, toward the accepted beauty silhouette. Nine drums share one service shaft; '
    'the station does not gain a second core.',
    'The upper arm is angled 60 degrees into a blocked outer cell; a straight 90-degree arm would enter the '
    'unblocked notch between two cells in the source plan. The larger review still needs a matching live footprint.',
    'The loose arm is the six-unit fallback from the pack. Its collar sweeps in an isolated corridor below the ring '
    'and outside the core, on two torn conduits. A complete swept-volume check is still required before approval.',
    'The ring has six habitat modules over twelve bearing slots; slot 10 is open in the lower-right plan quadrant.',
    'Radiators use dense grooves and root manifolds, without a solar-cell grid.',
    'The design carries no weapons. lore_bible_r8.md describes the Reach and Hegemony but gives no station battery layout. '
    'The live defend objective has rules batteries; it is not the abandoned T2 visual target.',
    'The cause of the write-off stays off the player-facing sheet. The damage is permanent, not a running fire effect.',
]
