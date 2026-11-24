extends RefCounted

const BAKED_PLANET := preload("res://shaders/map_baked_planet.gdshader")

const BRIEFING_CLOUDS := preload("res://shaders/map_briefing_clouds.gdshader")
# Shaders for the 3D sector map (G3, R51): the star system around the Hollow Sun. Presentation only.
# Every shader uses only TIME and its own uniforms (no global uniforms), so the map never depends on the battle world's
# globals. HDR colours above 1 feed the map's glow (bloom).

const MAP_SKY := preload("res://shaders/map_sector_sky.gdshader")

const INFALL := preload("res://shaders/map_infall.gdshader")


# The deep background: three star layers (tiny and many, medium, few bright ones with a soft cross), the galaxy's band,
# nebula clouds in the sector's colours, dark dust lanes cutting through them. q = 1 high quality, 0 low.
const SKY := preload("res://shaders/map_sky.gdshader")

# Near stars as round points at a finite distance: when the camera moves they slide against the sky (parallax).
const STARPTS := preload("res://shaders/map_starpts.gdshader")

# A big soft nebula sheet below the chart: a parallax layer between the chart and the sky.
const NEB_SHEET := preload("res://shaders/map_neb_sheet.gdshader")

# A soft radial glow on a camera-facing quad (the Hollow Sun's haze, node halos, light flares).
const GLOW := preload("res://shaders/map_glow.gdshader")

# Planets, lit by the fire round the Hollow Sun: rocky, ocean world, gas giant bands, ice, lava with glowing cracks.
# kind: 0 rock, 1 terran, 2 gas, 3 ice, 4 lava, 5 barren moon.
const PLANET := preload("res://shaders/map_planet.gdshader")

# The atmosphere's rim: a slightly larger shell, brightest at the planet's edge on the side facing the fire.
const ATMO := preload("res://shaders/map_atmo.gdshader")

# Lit rocks and hull scraps for belts, wreck fields and the debris ring. INSTANCE_CUSTOM.r > 0.5 makes a scrap smoulder.
const ROCK := preload("res://shaders/map_rock.gdshader")

# Thin glowing orbit lines round the Hollow Sun (a ring strip in the chart plane: UV.x across, UV.y along).
# bright: 0..1 for the brighter arcs drawn near the stops.
const ORBIT := preload("res://shaders/map_orbit.gdshader")

# A jump lane: a glowing ribbon in the chart plane (UV.x across, UV.y from start to end). A bright core, a soft halo,
# energy pulses flowing toward the destination when flow > 0, red chevrons into an elite or the flagship when hazard > 0.
const LANE := preload("res://shaders/map_lane.gdshader")

# A route in the Briefing build (FINDINGS R165): one flat, solid line along the ribbon's centre, a fixed width on the screen
# (px is its half width in pixels), in exactly the colour it is given. No halo, no flow, no chevrons, and never brighter
# than its colour, so it cannot bloom.
const LANE_FLAT := preload("res://shaders/map_lane_flat.gdshader")

# The ring round a stop, drawn on a flat quad: a crisp circle with tick marks, a faint fill, turning dashes when you can
# jump there (dash = 1), a soft pulse. r = ring radius as a fraction of the quad's half size.
const RING := preload("res://shaders/map_ring.gdshader")

# A nebula pocket: soft clouds on camera-facing quads, value noise shaped, slowly churning; storm > 0 adds flickers.
const CLOUD := preload("res://shaders/map_cloud.gdshader")

# A faction halo on the chart plane round a rival's stop (and the flagship): a ring in the faction's light.
# look: 0 plain, 1 pulses in step (Hegemony), 2 a rainbow ring (Ithar crystal), 3 corona (Deathless).
const HALO := preload("res://shaders/map_halo.gdshader")

# Faction territory: a soft wash of the enemy's light over the far end of the chart.
const TERR := preload("res://shaders/map_terr.gdshader")

# ---- The Hollow Sun as a black hole (R51 round 2, lore round 4): the same look as G4's dead-star board
# (godot/world/world_shaders.gd DISC, DISC_FRONT, LENS), with TIME in place of the battle's scene_t global.

# The accretion disc of the dead star. Opaque where dense, so the lens pass bends its far side over and under the
# shadow (the arc a real black hole shows); differential rotation, spiral turbulence, temperature falling outward,
# Doppler beaming (the side coming toward the camera brighter and bluer). r_in, r_out in the disc mesh's local units.
const BH_DISC := preload("res://shaders/map_bh_disc.gdshader")

# The near half of the disc again, added on top after the lens, so the half in front of the hole stays in front.
const BH_FRONT := preload("res://shaders/map_bh_front.gdshader")

# Gravitational lensing on a camera-facing quad over the hole (G4's LENS): the picture behind the hole is pushed out
# round the Einstein ring and pulled in from the far side; inside the shadow nothing escapes, ringed by the photon ring.
# Only what lies behind the hole is bent (depth check), so the chart in front never moves.
const BH_LENS := preload("res://shaders/map_bh_lens.gdshader")

# Low quality (no lens): a camera-facing black shadow disc with the photon ring and a faint lensed glow round it.
const BH_SHADOW := preload("res://shaders/map_bh_shadow.gdshader")

# ---- Stop objects at full finish (R51 round 2, Ryan: "the actual icons still look kind of low poly").
# Bump mapping without textures: the height is computed in the fragment and turned into a normal with screen-space
# derivatives (surface gradient), so every procedural part carries panel seams, grit and craters in its lighting.

# Space hull plating for stations, gantries, docks, tenders and drones: panels in rows of varied widths on the face's
# main plane, recessed seams, a finer second panel layer, grime, a few accent panels in the faction colour, rows of lit
# windows. Lit by the Hollow Sun (PBR).
const HULL := preload("res://shaders/map_hull.gdshader")

# Neutral map wrecks reuse the plated hull shader, clipped into two solid-ended halves.
const WRECK_SPLIT := preload("res://shaders/map_wreck_split.gdshader")

# No circular polar ice mask or ocean specular disc on the Briefing landmark.
# Warped continents and drifting clouds describe one continuous surface.
const BRIEFING_WORLD := preload("res://shaders/map_briefing_world.gdshader")

const HOLLOW_ROCK := preload("res://shaders/map_hollow_rock.gdshader")

# Solar arrays: dark blue cells in a silver grid, a glossy sheen.
const SOLAR := preload("res://shaders/map_solar.gdshader")

# Heat radiators: dark fins whose cores glow a dull ember from the heat they shed.
const RADIATOR := preload("res://shaders/map_radiator.gdshader")

# Asteroid rock at full finish: strata and dust from 3D noise, fine grit and pitting in the lighting (bump), darker in
# the craters the mesh carries (COLOR.r is the crater depth), a faint rim from the sun. kind 0 stone, 1 iron, 2 ice.
const ROCK_HI := preload("res://shaders/map_rock_hi.gdshader")

# A planet's cloud layer: a slightly larger shell, clouds drifting, lit by the sun, transparent between.
const CLOUDS := preload("res://shaders/map_clouds.gdshader")

# The lensed image of the disc's far side, drawn on a camera-facing quad behind the shadow: the glowing arc that wraps
# over the top of the shadow and the thinner one under it (brightest above and below, fading where the disc itself
# passes at the sides), the disc's own colours and spin, then the thin bright photon ring at the shadow's edge. No
# screen copy, so nothing on the chart is ever bent and there are no seams at any camera angle. r_shadow is the
# shadow radius as a fraction of the quad's half size.
const BH_LENSED := preload("res://shaders/map_bh_lensed.gdshader")

# The threat marker over a fight (R51 round 3, replaces the lit gem): a crisp holographic diamond outline in the
# danger band's colour, an inner pip in the enemy faction's light, corner ticks, a scan line sweeping down it and a
# soft pulse ring going out. elite draws a second outline and a gold crown bar. Camera-facing.
const THREAT := preload("res://shaders/map_threat.gdshader")
