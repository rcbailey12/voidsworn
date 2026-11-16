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
# Nine pressure drums, each with its own shoulder and dark window band.
DRUMS = []
_z = CORE['bottom']
for _height, _radius in ((1.7,4.85),(2.2,5.45),(3.05,6.25),(1.5,5.65),
                          (3.1,6.05),(2.0,5.45),(2.6,5.95),(1.65,5.2),(3.1,5.65)):
    DRUMS.append(dict(bottom=_z, height=_height-.10, radius=_radius))
    _z += _height
VIEWPORT = dict(deck=5, angle=-108, degrees=54)
SERVICE_ARMS = [dict(angle=a, length=length, cooling=cooling)
                for a,length,cooling in ((22,3.0,False),(112,3.4,True),(158,2.8,False),
                                         (202,3.0,True),(232,2.6,True),(335,3.2,False))]
RING = dict(outer=17.0, inner=14.4, bottom=-0.9, height=2.8,
            slots=11, gap_degrees=40, service_angle=240, seized_offset=30, modules=6)
BREACHES = {2: (-95, 3.0), 4: (-140, 3.6), 6: (-45, 2.8), 7: (155, 3.3)}
SPOKES = (35, 145, 300)
# root, intact tip, bearing height, width, module count. Arm 3 is the stub.
ARMS = [dict(angle=0, root=4.8, tip=25.75, z=2.0, width=3.0, modules=5),
        dict(angle=60, root=4.8, tip=23.0, z=-2.7, width=1.65, modules=5),
        dict(angle=180, root=4.8, tip=25.75, z=2.0, width=4.4, modules=5),
        dict(angle=270, root=4.8, tip=14.0, z=-2.7, width=2.3, modules=3)]
# Each tower stands on its own radial service bridge, around the whole hub.
# Run 5, Ryan R290: every tower upright; heights and caps stay distinct.
TOWERS = [dict(x=-11.8, y=1.0, base=2.0, height=19.8, cap='pad', lean=0.0),
          dict(x=10.8, y=-5.3, base=1.9, height=9.2, cap='dishes', lean=0.0),
          dict(x=-5.0, y=10.8, base=1.9, height=16.0, cap='dome', lean=0.0),
          dict(x=8.6, y=7.0, base=1.9, height=12.2, cap='crane', lean=0.0),
          dict(x=-5.4, y=-10.3, base=1.9, height=5.4, cap='beacon', lean=0.0)]
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
             (-4.75, -3.98, 4.5), (-11.8, 1.0, 2.6), (-5.5, -15.0, 1.8)]
JOINTS = dict(core=[d['bottom'] for d in DRUMS[1:]],
              ring=[math.radians(290+i*320/11) for i in range(12)],
              arms='module collars; torn root and collar stay separate',
              towers='base ring, mast module rings, whole cap',
              radiators='header manifolds')
CHANGES = [
    'Run 5 follows Ryan R290: all five towers are upright, retaining the spread bridges, distinct heights and caps from R284.',
    'Nine core drums now vary in height and radius, with stepped shoulders, dark glazing bands and sparse lit markers. '
    'The four torn holes and torn top stay open. One continuous large observation pane faces the damage-side camera.',
    'Generic service pallets and unexplained raised blocks are removed. Habitat modules carry framed airlocks, '
    'wheel hatches and connected service pipes; docking arms carry cargo handling, a recessed hangar door and berth gear; '
    'towers carry sensors and cable trunks. The inventory records each fitting and its measured geometry.',
    'Six short trussed ring fingers carry three cold radiator combs and three solar wings. '
    'Four ring thruster quads have open nozzles; docking collars carry dark guide lenses and clamps. '
    'Maintenance routes have handrails. The four main radiators and attached run 3 damage remain. No debris field added.',
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
