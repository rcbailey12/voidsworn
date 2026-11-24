extends RefCounted
# Issue 1582 item 5: six faction movement personalities. One table, read by ShipView for its manoeuvring jets and its
# ignition beat. Colours come from fx/faction_looks.json (the one faction colour file, R367) where a jet takes the drive's
# colour; the jet tints here are the gas or light a faction's jets give off, not new faction colours.
# Stage 1's rules hold for all six: turn, then burn, then turn; no skating; no roll on warships (RULEBOOK 7.1 to 7.5).
# Every number is a tuning value chosen by eye at camera 170 (RULEBOOK 7.7).
#
# style:  gas     a compressed-gas puff that leaves the nozzle and spreads (Sunward, Directorate, Hullbreakers)
#         glint   a short prismatic flash that stays on the hull's vanes, hue walking along the spectrum (Glasswrights)
#         pulse   a soft bioluminescent swell at the vent that breathes out and fades, no jet of gas (Chorus)
#         ripple  a cold violet ring that opens out from the drive ring and fades, no flame or gas (Eclipse)
# ign:    the ignition beat against Stage 1's (spool-up lag before the hull breaks inertia)
# size:   jet size against Stage 1's; life: how long it lasts against Stage 1's; spread: how far a puff spreads
# speed:  how fast the gas leaves the nozzle against Stage 1's
# sparks: bright grit thrown with each puff (Hullbreakers' overburn)
# jitter: how rough the puffs are (size and timing scatter)
# drive_pulse: a slow glow swell on the main drive while it burns (Sunward radiators)

const DEFAULT := {"style": "gas", "tint": Color(0.85, 0.88, 0.95), "ign": 1.0, "size": 1.0, "life": 1.0, "spread": 5.0,
	"speed": 1.0, "sparks": 0, "jitter": 0.0, "drive_pulse": 0.0}

const TABLE := {
	# Sunward Crusade: heavy industrial inertia, a clear spool-up lag, chunky white compressed-gas puffs, radiator pulse
	"voidsworn": {"style": "gas", "tint": Color(0.96, 0.95, 0.92), "ign": 1.6, "size": 1.35, "life": 1.35, "spread": 6.5,
		"speed": 0.8, "drive_pulse": 0.18},
	# Meridian Directorate: crisp blue-white, computer-timed, tidy and short; no wasted rattle
	"hegemony": {"style": "gas", "tint": Color(0.78, 0.9, 1.0), "ign": 0.75, "size": 0.85, "life": 0.6, "spread": 3.0,
		"speed": 1.25},
	# Ashfall Hullbreakers: a hot amber overburn kick off the line, rough punchy counter-blasts with sparks and grit
	"corsair": {"style": "gas", "tint": Color(1.0, 0.62, 0.32), "ign": 0.6, "size": 1.25, "life": 0.9, "spread": 7.0,
		"speed": 1.35, "sparks": 3, "jitter": 0.35},
	# The Glasswrights: hardly any gas; a prismatic light shimmer along the vanes as the hull trims
	"ithar": {"style": "glint", "tint": Color(1.0, 0.86, 0.53), "ign": 0.9, "size": 0.9, "life": 1.4, "spread": 0.0,
		"speed": 0.0},
	# The Chorus: bioluminescent vent surges with an organic pulse cadence instead of mechanical jets
	"chorus": {"style": "pulse", "tint": Color(0.72, 0.95, 0.3), "ign": 1.2, "size": 1.3, "life": 2.2, "spread": 1.6,
		"speed": 0.15},
	# Eclipse: cold violet-black null ripples round the drive rings, no flame or gas; silent, dead-level precision
	"deathless": {"style": "ripple", "tint": Color(0.57, 0.38, 0.96), "ign": 0.5, "size": 1.3, "life": 2.0, "spread": 3.2,
		"speed": 0.0},
}


static func of(faction: String) -> Dictionary:
	var p: Dictionary = DEFAULT.duplicate()
	p.merge(TABLE.get(faction, {}), true)
	return p
