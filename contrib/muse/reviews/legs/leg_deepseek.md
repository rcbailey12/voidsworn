# Leg: DeepSeek (DeepThink on, Search off), issue 2156

Gate record: New chat, signed in as Ryan Bailey. DeepThink ON and Search OFF verified before sending and again after generation. The first paste became a file attachment; the browser removed it and re-entered the brief as plain text in chunks, verifying a single plain-text message before sending. Chat: "Sky art direction review", https://chat.deepseek.com/a/chat/s/6d87ebb8-dd67-41af-a0fa-dde72e0fc33f

Response verbatim:

Q1. Findings, most important first

1. SKY shader star_layer line: quote "roughly 6,800 to 11,600 inside one 45-degree battle frame". OBSERVED. At battle camera height this is star snow, not the 400 pinpoints in 10.11, so Band 1 negative space is filled and ships, hex lines, and weapon fire lose separation. Fix: land the 1766 density target and retune thresholds to about 400 in frame.

2. star_layer brightness: quote "gain * (0.15 + 2.6 * m)". OBSERVED. At battle camera height the flat 0.15 floor keeps the faintest stars too bright, so there is no quiet faint population and the curve is not steep enough. Fix: remove the floor and use a steeper curve with only a few hero stars.

3. star_layer size: quote "sig = px * (0.65 + 0.9 * m)". OBSERVED. At battle camera height these are soft blobs, not pinpoints, so the sky reads as haze or noise instead of hard star points. Fix: shrink the base size and slope, and clamp maximum size.

4. star_floor default in world_sky.gd and world.gd: quote "star_floor defaults to 0.15". OBSERVED. At battle camera height dust lanes only black out 85 percent of stars, so opaque rifts look milky and fail 10.11. Fix: default star_floor to 0.0 and keep VS_STAR_FLOOR only for tuning sheets.

5. BAKE_BODY output: quote "full_size = vec2(4096.0, 2048.0)". OBSERVED. At battle camera height the 8-bit gamma bake will band in dark gradients and dust lane edges, especially in deep and boneyard. Fix: implement issue 1502 as 16-bit half float, linear, no mipmaps, and check whether 2048x1024 softens dust lanes.

6. Bake saturation: quote "mix(vec3(lum), col, 1.45)". OBSERVED. At battle camera height this pushes faction gas toward saturated green, orange, or purple walls that can fight the board and weapon HDR. Fix: cap saturation and luminance after the bake, then test every faction palette.

7. faction_looks.json deathless: quote "deathless (Eclipse): [0.1, 0.04, 0.16], [0.34, 0.14, 0.52], [1.0, 0.84, 0.55]". OBSERVED. The Eclipse mid colour is purple, so Eclipse sky gas can become the purple Eclipse nebula that 10.11 bans. Fix: clamp Eclipse sky gas toward neutral or rose, or reserve purple for on-board effects only.

8. Fight-stop boss mood: quote "boss multiplies neb by 1.6 and cover by 1.25". OBSERVED. At battle camera height the nebula region can go from cover 0.72 to 0.90, filling the frame behind the board and erasing calm space. Fix: cap cover and neb for boss mood, or localize boss gas away from the board centre.

9. Region table, world_sky.gd line 36: quote "nebula: neb 1.0, cover 0.72". OBSERVED. At battle camera height this region can put full-brightness gas over most of the frame even before mood multipliers. Fix: lower cover or keep a clear central corridor for the tactical board.

10. Bake feature direction: quote "brightest part of the gas is placed by a seeded feature direction below the board". OBSERVED, placement effect INFERRED. At battle camera height a bright gas feature below the board can pull the eye off the fight and reduce contrast under ships. Fix: keep the feature peripheral and below the Law 1 Band 1 luminance range at camera height.

Q2. Is 1766 still right

Yes, the core 1766 direction is still right, and it is more right after the foreground V2 pass. The foreground now has more detail, brighter hulls, stations, nebula, and storm effects, so the sky should be calmer, darker, and more hierarchical, not busier. The player needs near-black negative space and a few landmarks so V2 assets and weapon fire read.

Where I would adjust it: first, sequencing. The pack says 1766 is in build, but the code facts on main still show 6,800 to 11,600 stars and star_floor default 0.15. Land 1766 and 1502 on main, audit the actual defaults, and then judge. Second, values. Make star_floor 0.0 the default, not only an override. Make about 400 stars in a 45-degree frame the actual shader result. Remove the 0.15 brightness floor and shrink star size. Third, scope. Do 16-bit bake before palette tweaks, because banding changes how dark gradients and dust lanes read. Fourth, cap mood multipliers and faction gas so boss and Eclipse cannot recreate a wall of colour.

Where I disagree: I would not make "stronger galactic band" the headline if stronger means higher contrast. After foreground V2, the band should be low-frequency, faint, and mostly a landmark with dark rifts, not a bright ribbon. I also disagree with treating the approved 1766 direction as shipped reality; the main code in this pack still looks like the old sky. On Dead Star, the pack says the seam is scoped and the painted 8K panorama sits under the gas with the black hole; that sounds right in direction, but the actual look is not enough info.

Q3. Top 5 upgrades, ranked

1. Land 1766 star density and star_floor defaults. On screen: the sky becomes mostly near-black with about 400 pinpoints, dust lanes actually black out stars, and ships, hexes, and shots separate cleanly.

2. Fix star brightness curve and size. On screen: stars become hard pinpoints with a few hero gleams, not fuzzy blobs or low-contrast noise.

3. Ship 16-bit linear bake for issue 1502. On screen: dark gradients and dust lanes stop stair-stepping in deep space and boneyard, so the backdrop looks cinematic rather than 8-bit.

4. Constrain faction gas, Eclipse purple, and boss mood. On screen: faction tint stays subtle, Eclipse stops looking like a purple nebula wall, and boss fights keep a calm centre behind the board.

5. Tune the galactic band and landmarks as low-frequency hierarchy. On screen: the player sees a tilted faint band with dark rifts, plus occasional lamp stars and far galaxies as landmarks, not wallpaper.

Q4. References

Homeworld 2 Remastered: take its near-black tactical sky and distant nebula landmarks; ships and UI own the contrast.

Freespace 2: take restrained star density, a readable galactic band, and dark dust lanes that do not turn milky.

Elite Dangerous: take the realistic band with rifts and star colour temperature; do not copy its dense star fields.

EVE Online: take faction colour as peripheral gas and distant landmarks, not a full-frame wash behind the board.

2001: A Space Odyssey: take hard pinpoints and a near-black void with no atmospheric fog.

Interstellar: take dust lanes and luminous gas as rare landmarks, not as wallpaper.

Star Wars original trilogy: take sparse hero-star skies; avoid the special-edition star snow.

Strongest objection: the chair will likely synthesize "1766 is right, so land it and tune values." My objection is that the pack shows main still at 6,800 to 11,600 stars and star_floor default 0.15, while boss mood can push cover to 0.90, so approving the direction without auditing shipped defaults and mood caps will leave the player seeing the old star snow and milky dust.

Not checked:

- Actual rendered sky at battle camera height, since the pack has no screenshots or captures.
- Whether 1766 and 1502 are already on main or only in build; the pack is contradictory.
- Exact line numbers for many shader functions and the bake body.
- Luminance histograms against Law 1 bands.
- Performance and memory cost of the 16-bit 2048x1024 bake.
- Dead Star seam and painted 8K panorama look in motion.
- Readability of V2 foreground assets, UI, hex lines, and weapon HDR against the sky.
- Final faction palette intent, especially whether Eclipse purple is allowed in sky gas.
- Platform gamma, colour management, and display calibration.
- Camera motion, parallax, dust specks, and lamp star halos during play.
