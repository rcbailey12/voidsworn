# Look references: shields, trails and sky in the eight reference games (issue 407)

Written for the Board's options sheets (the shield sheet under issues 371 and 372, the trails and beams kit under 367, the sky sheet in the space track of docs/playbooks/PROGRAM.md). Method: Rey blind leg first, DeepSeek and Qwen writing legs, Flash and Grok ideation, Rey chairs (leg files in this folder). Every claim below carries a source link or is marked UNSOURCED, which means the council believes it from play and no source the chair could find confirms it; the Board should treat UNSOURCED rows as leads, not facts. Where the legs disagreed with a source, the source won and the leg file says so.

## (a) Shields: at rest, on a hit, with a side down

| Game | What it does at the played camera |
|---|---|
| EVE Online | No resting shield read in the world; shield state lives in the HUD as the outermost of three rings, and the shield itself is modelled as a sphere just inside the ship's signature radius. Module effects shimmer over the hull from nose to tail; the shield booster's blue patterns flow around the ship offset from the hull surface, and hardener and booster colours depend on the ship's faction of origin, not the module. Sources: [Visual effects](https://wiki.eveuniversity.org/index.php?title=Visual_effects&diff=cur&oldid=133428), [Shields](https://wiki.eveuniversity.org/index.php?title=Shields&diff=cur&oldid=83537&mobileaction=toggle_view_mobile). The hit-flash itself beyond module effects: UNSOURCED. No per-side read. |
| Elite Dangerous | The shield is an invisible force field while it is up; the hull takes no damage while the shield is powered and charged. When it is fully depleted the generator needs time to recharge before the field can form again, so "down" is a timed state, not a flicker. Single field, no facings. Source: [Shield Generator](https://elite-dangerous.fandom.com/wiki/Shield_Generator). The ripple on a hit: UNSOURCED (all legs describe one; no source found). |
| Star Citizen | Shields are genuinely split into faces: per-face allocation is managed and monitored, higher-power shields split output among multiple faces, and impact shading accumulates simultaneous hits in an off-screen buffer rendered in a deferred pass, built so many impacts stay readable at capital scale. Source: [Design Notes: Shields and Management](https://starcitizen.tools/Comm-Link:Shields_and_Management). A cautionary data point: a 2026 update had to add distinct hit markers for shield vs hull vs armour because players could not read which layer a shot hit. Source: [Alpha 4.9 notes](https://ggwtb.com/blog/star-citizen-alpha-4-9-damage-markers-super-heavy-armor--siege-of-orison--and-loot-changes). The hex-tessellation hit visual the legs describe: UNSOURCED. |
| Sins of a Solar Empire 2 | Ships carry shield meshes (the TEC shield meshes were updated in a named patch), hit effects are oriented to the projectile's travel vector, and in the series the shield impact colour is set per race in the race data. Sources: [Omens of Conflict update](https://www.sinsofasolarempire2.com/article/521666/omens-of-conflict-update-sins-of-a-solar-empire-ii), [Stardock forums, directional shield FX](https://forums.stardock.com/429695/get;3289525). Resting visibility and any per-side read: UNSOURCED, and the legs disagree (faint rim at rest vs invisible). |
| Rogue Trader (space scenes) | The one sourced per-side system of the eight: the void shield has 4 sectors, each with its own independent charge; a depleted sector stops absorbing even while the other sectors are intact; charge does not recover on its own during a battle, only through the Restart Shields ability, and Reinforce Shields strengthens one sector. Source: [Space Combat](https://roguetrader.wiki.fextralife.com/Space+Combat). How a sector looks in the world when hit or down: UNSOURCED. |
| Battlefleet Gothic: Armada | In game terms the shield is a regenerating point pool that skills can supercharge, transfer or strip (a Disruption Bomb depletes every shield in its radius). Source: [Skills](https://battlefleetgothic-armada.fandom.com/wiki/Skills). The fiction both 40K games render describes the look: a translucent bubble that hazes light, ripples like gelatine under attack with a kaleidoscope of colours that indicates shield strength, energy flares at impact points sized by the attack, and collapse followed by re-raising in battle. Source (fiction, not a game capture): [Lexicanum, Void shield](https://wh40k.lexicanum.com/wiki/Void_shield). Per-side visual: none found. |
| Star Wars: Squadrons | Shields can be directed fully forward, fully rearward, or balanced, and the game is cockpit-only, so the shield read lives on cockpit instruments. Sources: [GameSpot review](https://www.gamespot.com/reviews/star-wars-squadrons-review-catch-me-if-you-can/1900-6417582/), [StrategyWiki](https://Strategywiki.org/wiki/Star_Wars:_Squadrons/Gameplay). Any external flash on the hull: UNSOURCED, and mostly irrelevant at a fleet camera. |
| BattleTech | Not applicable: a ground game, no ship shields. Its contribution is in section (b). |

Reads at small size: the localised flash at the impact point, and the change of hit character when a side is down (shots stop answering on the shield and start sparking on the hull). Noise at 60 to 200 px: hex or mesh tessellation, uniform dimming, subtle rim shimmer, recharge detail. A dark gap reads only as a clean arc and a wide one; Qwen's leg estimates 15 to 20 percent of the silhouette width as the floor (leg estimate, UNSOURCED).

Three directions for Voidsworn (all keep the R163 ruling: invisible at rest, faint edge glow on zoom, hover or recent hit, a down side as a dark gap, faction colours):

1. **Rim and Gap** (EVE and Elite's restraint, Rogue Trader's sectors): nothing at rest; the struck side answers with the staging table's own shield event (110 px flash, 156 px ripple disc, 1.1 s, issue 352) in faction colour; a down side is simply the arc of rim that no longer answers, and hits there spark on the hull.
2. **Face Flash** (Star Citizen's faces, Sins' directional impacts): four face arcs hug the hull; only the struck face lights, sized on the hit ladder; a down face stays dark while the others still answer. More gamey than Rim and Gap, and the per-face read is the strongest of the three.
3. **Veil, Then Local** (the 40K void shield, both games): the first hit after a quiet spell blooms a brief full veil in faction colour, later hits are local flares on the veil's arc; when a side drops, the veil never covers that arc again until the shield recharges. The most dramatic of the three, and the closest to Voidsworn's gothic neighbours.

The trap to avoid, named by the Grok leg and agreed by the chair: a persistent translucent bubble or mesh shell. It is the most common treatment across the eight and the least legible at this camera.

## (b) Trails, beams and engine flares

| Game | What it does at the played camera |
|---|---|
| EVE Online | Engine trails are glowing spline ribbons, rebuilt by CCP as ray-traced glowing cylinders on Hermite splines precisely so they stay smooth and cheap at fleet scale; size, length and colour are art-directed per ship. Source: [Re-inventing the trails](https://www.eveonline.com/news/view/re-inventing-the-trails). Beam and flare specifics: UNSOURCED beyond the legs' agreement that beams are thin, bright and bloomed. |
| Elite Dangerous | UNSOURCED: the legs agree on sustained coloured beam lines while held, discrete tracer dots for cannon, and boost plumes that lengthen and brighten with throttle. No solid source found. |
| Star Citizen | UNSOURCED: very large volumetric engine flares and lingering plumes at its close camera; the legs agree this grammar simplifies to bright dots and streaks at a wide camera. No standard combat beam class. |
| Sins of a Solar Empire 2 | UNSOURCED on trails (legs: short glowing streaks; beams thin lines with bloom); sourced only that its hit effects are oriented to the projectile's travel vector (Omens of Conflict update, linked in section (a)). |
| Battlefleet Gothic: Armada | UNSOURCED: lance batteries as thick, slightly widening beams that persist for the volley; torpedoes with short glowing trails; broad faction-coloured engine wakes. No solid source found; the legs agree with each other and with the game's tabletop lineage. |
| Rogue Trader (space scenes) | UNSOURCED: thick lance beams, torpedo trails, short warm exhaust. The space scenes are brief, which is itself the finding: Rogue Trader spends almost nothing here. |
| Star Wars: Squadrons | UNSOURCED on visuals (legs: discrete bright bolts, never sustained beams; engine flares the dominant exhaust read, tied to throttle and boost). Cockpit scale throughout. |
| BattleTech | UNSOURCED (no solid source found for the HBS game specifically): the PPC reads as a crackling blue-white lightning bolt, lasers as straight coloured beams, and LRM salvos as arcing swarms of smoke trails whose whole arc is visible, which is the standout read: you can see what is coming and where it will land. |

Reads at small size: a beam survives as a clean line defined by its endpoints and colour, with bloom at the impact end; an engine flare survives as one bright dot that scales with thrust; a trail survives only short, high-contrast and ribbon-flat. Noise: volumetric plume shading, particle sparkle, per-bolt animation, trails longer than about two ship-lengths (they smear into the sky).

Three directions for Voidsworn:

1. **Ribbons and Bloom** (EVE's trails, DeepSeek's bloom ladder): short faction-tinted ribbon trails sized by ship class; beams as clean lines whose impact bloom is taken from the staging ladder (las 40 px up to lance 78 px and beyond), so beam weight reads off the same scale as every other hit.
2. **Flare and Dash** (Squadrons and Star Citizen, via the legs): minimal trails; the engine read is one bright stern flare per ship that grows with thrust; guns speak in short bright dashes, not lines. The quietest of the three, and the kindest to the frame budget.
3. **Gothic Weight** (Battlefleet Gothic and BattleTech, via the legs): lances are thick strokes with a charge-up glow at the emitter and a widening burn at the target; torpedoes fly as visible arcing groups, so a salvo reads as an event with a destination, not a line.

## (c) The sky behind a fleet battle

| Game | What it does at the played camera |
|---|---|
| EVE Online | Every region has a unique skybox, and empire space is colour-coded by empire (Amarr gold, Caldari blue, Gallente green, Minmatar red); null-sec regions are mostly black with smaller coloured clouds; pilots identify wormhole destinations by skybox colour alone. The sky is an identity system, not wallpaper, and even EVE keeps its emptiest regions near-black. Source: [Visual wormhole identification](https://wiki.eveuniversity.org/index.php?title=Visual_wormhole_identification). |
| Elite Dangerous | The sky is computed from the ship's actual galactic position in a 1:1 Milky Way built from real data and star catalogues; 141 real nebulae are in the game at their real distances, so most combat skies are near-black with the galactic band, and a nebula fills the sky only when you are actually at one. Sources: [Galaxy](https://elite-dangerous.fandom.com/wiki/Galaxy), [Nebula](https://elite-dangerous.fandom.com/wiki/Nebula). |
| Star Citizen | UNSOURCED: the richest backdrop of the eight (dense stars, structured volumetric nebulae, shaded planets), and the legs agree it is the one that can compete with effects. |
| Sins of a Solar Empire 2 | UNSOURCED: painted nebula and starfield backdrops, muted, with planets as large spheres at the field edge; calm by RTS necessity. |
| Battlefleet Gothic: Armada | UNSOURCED: dark, painterly, warp-tinted skies, low star counts, broad muted nebula bands; the mood carrier of the eight after EVE. |
| Rogue Trader (space scenes) | UNSOURCED: near-black void, sparse stars, deep red or purple washes; a flat dark canvas under a few large ships. |
| Star Wars: Squadrons | UNSOURCED: composed film set pieces (a planet, a wreck, a nebula) at cockpit distance; the least transferable to a wide strategy camera. |
| BattleTech | Not applicable: skies over ground battlefields. |

Reads at small size: one or two large, low-frequency colour fields (EVE), or near-black with a single broad band (Elite). Noise: detailed nebula texture, dense starfields, bright knots behind small ships. This is the same failure audit pass 2 found in Voidsworn's own sky (flat speckle that fights the ships), so the bar is explicit: background peak brightness stays under the smallest hit (the 40 px las rung); Qwen's leg proposes under 15 percent peak luminance as the working number (leg estimate, UNSOURCED).

Three directions for Voidsworn:

1. **Regional Colour, Calmed** (EVE): each battle board gets a two-colour nebula identity of its own, desaturated and darkened toward EVE's null-sec calibration (mostly black, smaller coloured clouds), so the board is recognisable and the effects still win.
2. **True Dark, One Band** (Elite): near-black sky, one broad galactic band swept across the frame from remixed real data, star points few and never sub-pixel. The calmest option, and the one that makes the lime and shield-blue reads cheapest.
3. **Planet Limb** (Sins and Rogue Trader, via the legs, and the programme's own board): one large, low-contrast planet limb at the frame's edge, the board planet itself, built from real data remixed past recognition per R163; the rest of the sky stays quiet dark. Gives the battle a place, at the price of one busy edge.

## What this does not decide

The picks are Ryan's, from the Board's options sheets (PROGRAM.md decisions 4, 5 and 7). This file is the research those sheets are drawn from. The UNSOURCED register is deliberate: if the Board wants any UNSOURCED row promoted, the cheapest proof is a capture from that game at its played camera, not another model's say-so.
