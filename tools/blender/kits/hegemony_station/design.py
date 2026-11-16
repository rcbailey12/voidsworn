"""station_T2 build-sheet design. World units, +Z up. No ship-length normalization.

The build sheet is the design authority, including the station's module joints.
This is a review design, not an approved replacement for O1_37.
"""
import math

CODE = 'station_T2'
CONCEPT = 'contrib/muse/design/station_concept_2026_11/station_T2_beauty.jpg'
PLAN = 'contrib/muse/design/station_concept_2026_11/station_T2_scale.jpg'
PACK = 'contrib/muse/design/station_pack_2026_11/pack.md'
CORE = dict(decks=9, pitch=2.5, radius=6.4, bottom=-5.6, wall=0.22)
RING = dict(outer=17.0, inner=14.4, bottom=-0.9, height=2.8,
            slots=11, gap_degrees=40, service_angle=240, seized_offset=30, modules=6)
BREACHES = {2: (-95, 3.0), 4: (-140, 3.6), 6: (-45, 2.8), 7: (155, 3.3)}
SPOKES = (35, 145, 300)
# root, intact tip, bearing height, width, module count. Arm 3 is the stub.
ARMS = [dict(angle=0, root=4.8, tip=25.75, z=2.0, width=3.0, modules=5),
        dict(angle=60, root=4.8, tip=23.0, z=-2.7, width=1.65, modules=5),
        dict(angle=180, root=4.8, tip=25.75, z=2.0, width=4.4, modules=5),
        dict(angle=270, root=4.8, tip=14.0, z=-2.7, width=2.3, modules=3)]
# Five different caps on five different heights. Lean is on the array tower.
TOWERS = [dict(x=-9.2, y=6.0, base=2.0, height=17.5, cap='pad', lean=-math.radians(5)),
          dict(x=-5.6, y=9.0, base=1.9, height=13.5, cap='dishes', lean=0.0),
          dict(x=-1.9, y=10.8, base=1.9, height=16.0, cap='dome', lean=0.0),
          dict(x=2.0, y=9.6, base=1.9, height=14.5, cap='crane', lean=0.0),
          dict(x=-18.2, y=0, base=4.3, height=6.2, cap='beacon', lean=0.0)]
RADIATORS = [dict(angle=a, radius=7.0, width=3.2, top=-5.5, bottom=-14.0)
             for a in (38, 142, 218, 322)]
MOTION = dict(pivot=(7*math.cos(math.radians(322))+1.6*math.sin(math.radians(322)),
                    7*math.sin(math.radians(322))-1.6*math.cos(math.radians(322)),-5.5),
              period=240.0, swing_degrees=3.0, swing_period=240.0,
              rest_degrees=27, part='radiator_4', axis='local Y')
# Counts belong here, not in a second painted version of the station.
LIGHT_CLUSTERS = [dict(kind='core', deck=d, count=15, angle=a) for d,a in ((1,-70),(5,-35))] + [
    dict(kind='ring', angle=a, count=n) for a,n in ((205,14),(325,13),(85,13))] + [
    dict(kind='equipment', count=20)]
BATTERIES = [(1.0, -13.3, -2.4), (3.8, -9.4, -1.4),
             (-4.9, -4.2, 6.0), (-9.2, 6.0, 2.6), (-5.5, -15.0, 1.8)]
JOINTS = dict(core=[CORE['bottom'] + i * CORE['pitch'] for i in range(1, 9)],
              ring=[math.radians(290+i*320/11) for i in range(12)],
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
    'Run 3 replaces the old tethered arm animation with radiator 4 on one surviving hinge. The torn arm has no berth collar.',
    'The ring gap is 40 degrees centred on the stub arm at 270 degrees, seized 30 degrees from its service angle. '
    'Eleven bearing sectors occupy the remaining 320 degrees; five joint plates are sprung open.',
    'The concept inventory governs run 3: three spokes, one bent stub, three held pods, four side holes plus a torn top drum, '
    'five dead caps, four cold radiators and six scattered light clusters. The older pack called for four spokes and a tethered arm.',
    'Radiators use dense grooves and root manifolds, without a solar-cell grid.',
    'The design carries no weapons. lore_bible_r8.md describes the Reach and Hegemony but gives no station battery layout. '
    'The live defend objective has rules batteries; it is not the abandoned T2 visual target.',
    'The cause of the write-off stays off the player-facing sheet. The damage is permanent, not a running fire effect.',
]
