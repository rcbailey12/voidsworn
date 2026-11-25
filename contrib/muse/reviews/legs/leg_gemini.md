# Leg: Gemini on Hydrogen (the Flash seat), issue 2156

Gate record: New chat on gemini.google.com. The model picker showed Hydrogen selected before pasting and still showed Hydrogen selected after generation. The brief was pasted as plain text, no file attached. Chat: "Art Direction Review of Space Sky", https://gemini.google.com/app/ac6dc7e537ff5d84

Response verbatim:

Q1. Findings (most important first)

Star count and brightness floor create "star snow" that competes with tactical silhouettes and UI.

Element: godot/world/world_sky.gd, SKY shader (star_layer)

Quote: "roughly 6,800 to 11,600 inside one 45-degree battle frame" and "a flat 0.15 floor, so the faintest kept star renders at 15 percent of full gain"

Status: OBSERVED

Why it matters: At battle camera height, thousands of mid-bright blobs turn the negative space into high-frequency visual noise, fighting against V2 ship exteriors, hex lines, and weapon fire.

Fix: Raise star_layer thresholds to hit the ~400-star budget and replace the flat 0.15 brightness floor with a steep power curve (pow(m, 3.0) or higher) with pinpoint radii.

Opaque dust lanes fail to occlude background stars, breaking atmospheric depth.

Element: godot/world/world_sky.gd, SKY shader and godot/world.gd (star_floor)

Quote: "star_floor defaults to 0.15 in the shader and in world.gd"

Status: OBSERVED

Why it matters: In real astrophotography and grounded sci-fi art, dark rifts carve sharp silhouettes out of starfields; letting 15 percent of stars bleed through makes dust clouds look like translucent grey smudges rather than massive, light-blocking structures.

Fix: Set the default star_floor to 0.0 in both world_sky.gd and world.gd while preserving the VS_STAR_FLOOR environment override.

Faction palettes violate the explicit ban on purple Eclipse nebulae and mustard fog.

Element: godot/fx/faction_looks.json (deathless and chorus entries) and world_sky.gd BAKE_BODY

Quote: "deathless (Eclipse): [0.1, 0.04, 0.16], [0.34, 0.14, 0.52]" and "chorus: [0.14, 0.16, 0.06], [0.55, 0.38, 0.12]"

Status: OBSERVED

Why it matters: RULEBOOK 10.11 explicitly forbids mustard fog and purple Eclipse nebulae, yet Deathless is coded as deep violet-purple and Chorus is coded as olive-mustard, creating garish, comic-book sky tints behind grounded V2 hulls.

Fix: Shift Deathless sky gas to cold steel-blue/charcoal with pale gold highlights, and shift Chorus to warm amber-ochre or muted dust-rose.

Post-march saturation and gain boosts push sky gas out of Band 1 and into foreground hull values.

Element: godot/world/world_sky.gd, BAKE_BODY

Quote: "col = max(mix(vec3(lum), col, 1.45), vec3(0.0))" and "boss multiplies neb by 1.6 and cover by 1.25"

Status: OBSERVED

Why it matters: Multiplying saturation by 1.45 and boosting brightness (especially in nebula regions at neb 1.0 or boss fights at 1.6x) pushes backdrop gas past the 0.015 Band 1 ceiling into Band 2/3 (0.03-0.30), flattening figure-ground separation against lit V2 ships.

Fix: Clamp post-march gas luminance to stay strictly within Band 1 (0.00 to 0.015) across most of the frame, reserving Band 2 (0.03 to 0.25) only for tight focal cores.

8-bit gamma bake causes visible posterization and color banding in dark space gradients.

Element: godot/world/world_sky.gd, BAKE_BODY (full_size)

Quote: "output is gamma-encoded into an 8-bit image with a per-pixel dither" and "dark gradients band at 8-bit"

Status: OBSERVED

Why it matters: Because grounded deep space lives in the 0.00 to 0.015 linear value band, 8-bit quantization leaves only a handful of discrete steps, creating ugly contour rings across the monitor at battle camera angles.

Fix: Land Issue 1502 by switching the bake target to linear 16-bit half-float (2048x1024, no mipmaps) so subtle dark gradients remain smooth.

Forced channel-swapped hue separation produces unnatural, bruised color clashes in the gas.

Element: godot/world/world_sky.gd, setting()

Quote: "c2 = c2.lerp(Vector3(c1.z, c1.x * 0.8, c1.y) * 0.6, 0.55)"

Status: OBSERVED

Why it matters: Arbitrarily rotating RGB channels when c1 and c2 are close in hue forces complementary color clashes (e.g., cyan-orange or green-magenta splits) that read as procedural noise rather than cohesive astronomical lighting.

Fix: Remove the channel-swap hack and build c2 as a value-shifted, slightly cooler and desaturated shadow tone of c1.

The galactic band lacks dynamic range and crisp dark-rift contrast.

Element: godot/world/world_sky.gd, galaxy_band

Quote: "the whole band returns "col * lum * band * 0.06""

Status: OBSERVED

Why it matters: A flat 0.06 multiplier with a soft skirt makes the galaxy read as a faint, uniform smudge rather than a majestic, structured spine of dust and concentrated starlight that anchors camera orientation.

Fix: Increase the core-to-skirt contrast of the galactic band and sharpen the dark rift occlusion (star_floor = 0.0) so the band reads as an astronomical landmark.

Six embedded lamp stars with wide halos add unmotivated glare spots across the backdrop.

Element: godot/world/world_sky.gd, SKY shader (lamp stars)

Quote: "exp(-a * a / 0.00006) * 0.25 + 0.0006 / (0.0004 + a * a) * 0.08"

Status: OBSERVED

Why it matters: Six broad bloom halos scattered around the sky compete with Band 5 weapon emissives and engine flares, tricking the player's eye into tracking background light blobs as tactical units.

Fix: Tighten the halo falloff radius and reduce lamp star count to 1-2 hero beacons tied directly to the primary seeded nebula feature.

Near-camera 3D dust specks are over-populated in salvage and belt states, cluttering the tactical plane.

Element: godot/world.gd, dust() and fight-stop mood scaling

Quote: "2,600 in belt maps, 2,000 graveyard" and "salvage multiplies dust by 2.6"

Status: OBSERVED

Why it matters: Multiplying 2,000 graveyard specks by 2.6 yields 5,200 moving particles around and below the board, creating foreground snow that undermines RULEBOOK 10.11's calm negative space.

Fix: Cap maximum active 3D dust specks after mood multipliers (e.g., max 1,500) and fade their alpha near the focal plane of the ships.

Far galaxies are baked at 0.08 gain, risking confusion with medium-tier stars.

Element: godot/world/world_sky.gd, BAKE_BODY (far galaxies)

Quote: "Five far galaxies per sky (sizes 0.004 to 0.012 radians, spiral-arm shading, total gain 0.08)"

Status: INFERRED

Why it matters: At 0.004 radians (roughly 0.23 degrees), small spiral galaxies at 0.08 gain can read as fuzzy star blobs or UI artifacts rather than distant deep-field objects.

Fix: Reduce far galaxy count to 1-2 subtle landmarks and lower their gain so they sit cleanly inside Band 1/low Band 2 without mimicking stars.

Q2. Assessment of the 1766 direction after foreground V2 upgrades

The core 1766 direction is fundamentally right and becomes even more critical now that Planets V2, Asteroids V2, and ship exteriors V2 are live. With high-detail, grounded hulls and readable surface normals in the foreground, the old 8,000-star "snow" backdrop creates severe visual clutter and flattens depth perception. Cutting stars by ~96% to ~400 pinpoints, enforcing star_floor = 0.0, and anchoring the sky with a stronger, rift-carved galactic band directly establishes the figure-ground separation that V2 assets need to pop.

Where to adjust values, sequencing, and scope:

Values (Value Bands and Gas Gain): With V2 hulls sitting in Band 3 (0.04 to 0.30), the sky gas gain in nebula regions (neb 1.0) and boss moods (1.6x multiplier) is too hot. Keep 85% of the sky strictly inside Band 1 (0.00 to 0.015), and cap peak gas highlights (including boss multipliers) inside Band 2 (under 0.12) so backdrop gas never rivals lit ship armor.

Scope (Faction Sky Palettes vs. RULEBOOK 10.11): Issue 1766 notes "palette fixes," which must explicitly rewrite faction_looks.json for Deathless (currently purple) and Chorus (currently mustard) to comply with RULEBOOK 10.11, and remove the procedural RGB channel-swapping hack in world_sky.gd.

Sequencing: Pair Issue 1502 (linear 16-bit half-float bake at 2048x1024) as a hard prerequisite or simultaneous landing with 1766. Dropping the background to near-black (0.00 to 0.015) without 16-bit precision will immediately expose severe 8-bit gradient banding across the entire void.

Q3. Top 5 upgrades, ranked

Enforce the 400-star pinpoint budget with a steep brightness curve and zero dust-bleed (star_floor = 0.0).

On-screen change: The noisy wall-to-wall field of fuzzy grey-white dots disappears, replaced by a crisp, near-black void dotted with razor-sharp pinpoint stars where only 10-15 hero stars gleam brightly, and dark dust rifts carve pitch-black silhouettes across the starfield.

Ship Issue 1502 (16-bit linear half-float nebula bake at 2048x1024, no mipmaps).

On-screen change: Concentric color banding and noisy dithering rings vanish from the dark margins of nebulae and deep-space gradients, producing smooth, filmic transitions into pure black.

Re-calibrate faction sky palettes and strip the procedural RGB channel-swap hack.

On-screen change: Purple Eclipse skies and mustard-yellow Chorus fog are replaced by grounded, cohesive astronomical hues (cold steel-blues, deep iron-reds, warm hydrogen-amber) where shadow tones naturally deepen instead of shifting into clashing complementary colors.

Clamp sky gas and boss-mood multipliers to Cohesion Law 1 value bands (Band 1 void 0.00-0.015, Band 2 landmarks 0.03-0.25).

On-screen change: Even in dense nebula sectors or boss encounters, the backdrop stays subordinate behind V2 ships, asteroids, and hex grids, making ship silhouettes and Band 5 weapon tracers read effortlessly at a glance.

Sculpt a high-contrast galactic band with sharp dark rifts and tie lamp stars to the primary nebula feature.

On-screen change: Instead of a faint, washed-out haze and six random glare halos, the player sees a sweeping, tilted galactic spine split by dark dust lanes and illuminated by one or two cohesive focal cores that give immediate spatial orientation as the camera orbits.

Q4. References: space games and films to learn from

Homeworld 1 & 2 (and Homeworld: Deserts of Kharak skyboxes): Masterclass in using low-frequency, painterly color fields and stark negative space so tiny tactical ships, trails, and selection brackets remain 100% readable at any zoom level.

Homeworld: Cataclysm / Emergence: Demonstrates how deep, ominous void tones paired with restrained, localized focal light sources create dread and scale without cluttering the tactical plane.

EVE Online (modernized nebula cubemaps): Shows how to structure crisp dark dust rifts that completely occlude background stars, giving gas clouds tangible volume and massive astronomical scale.

Nebulous: Fleet Command: Uses grounded, realistic starfields with high dynamic range (few bright stars, dark void) specifically tuned so tactical overlays, sensor cones, and point-defense tracers never fight the skybox.

Battlestar Galactica (2004 series, space exteriors): Proves that near-black space punctuated by a single strong directional sun and subtle, desaturated galactic dust makes metallic ship hulls look heavy, real, and tactile.

The Expanse (TV series): Uses a strict near-black deep-space void with sharp, pinpoint stars and zero ambient "space soup," allowing thrusters, railgun slugs, and ship running lights to command full visual attention.

Interstellar (Gargantua and endurance transit sequences): Shows how to balance an extraordinary hero cosmic landmark (like the Dead Star black hole) against pitch-black surrounding space with disciplined exposure and zero background star noise.

Strongest objection to the chair's likely synthesis

The chair will likely treat Issue 1766's ~400-star budget and Band 1 darkness (0.00-0.015) as a simple value-slider tweak that solves readability on its own, overlooking the aesthetic risk of an overly sterile, "empty black box" sky. When you strip out 96% of the stars and crush gas values down to 0.015 without simultaneously upgrading the large-scale structural silhouette of the galactic band, dark dust rifts, and subtle parallax depth cues, the tactical board can lose its sense of vast astronomical scale and feel like miniature models floating in an unlit void rather than ships fighting across a living star system.

Not checked:

Actual rendered screenshots, frame captures, or in-engine linear luminance histograms of the current main build or the Nov 22 1766 build.

The visual appearance, seam quality, and luminance values of the Dead Star 8K painted panorama and black hole shader.

How the V2 foreground assets (Planets V2, Asteroids V2, ship exteriors V2) and the rose-colored on-board nebula (RULEBOOK 10.9) composite visually against the sky at gameplay camera angles.

The exact shader implementation of the sun, star temperature color ramp, and far-galaxy spiral shading inside world_sky.gd.

Performance and VRAM impact of switching the nebula bake from 4096x2048 8-bit to 2048x1024 16-bit half-float on target hardware.
