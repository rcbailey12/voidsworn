# Leg: blind Rey, issue 2061

Written before any external leg ran, from the brief pack alone (issue 2061, docs/playbooks/sound.md, contrib/opus/FINDINGS.md R247/R344/R79, issue 2034 run 1, and the issue 1572 sound synthesis).

## Question 1: layered nebula clouds

Pick: a three-layer card stack in backdrop space, all of it below the board plane, plus one optional whisper layer above it. Pre-baked textures, one shader, no volumetrics.

- Far layer (the body): 4 to 8 very large soft cards per cloud region, each a pre-baked radial cloud texture (fractal noise eroded by a second noise map, baked offline at 1024 or 2048), tinted in the approved family (slate teal, smoke grey, deep ember at the lit side only). Parallax factor about 0.2 against camera pan, so it moves like something far below the board. This layer carries the vastness: individual cards are several board-widths across, so a hex samples the cloud, never contains it (R247).
- Mid layer (the structure): smaller, denser cores with the key light baked in. One light direction per battle, matching the scene's key light (the dead star, the local star), brighter rim on the lit side, darker body away from it. Parallax about 0.5. This is the layer that sells volume at a fixed camera, because the light gradient stays consistent when the player pans.
- Near layer (the drift): sparse thin wisps, parallax about 0.8, alpha low, drifting very slowly (a full drift cycle in minutes, not seconds; motion must read as depth, never as weather). A handful of cards, recycled across the region.
- Dust lanes: dark cards multiply-blended across the mid layer, so lanes are places where the cloud is absent or shadowed, not black paint. Lanes are what separate this from a tinted fog patch: a cloud with holes and lanes has a shape; a uniform patch does not.
- Edge: the far and mid textures are noise-eroded, so the edge is fractal and soft at every zoom. The gameplay outline (R344) is drawn by the existing patch outline on the board, not by the cloud texture, so the readable game edge and the pretty cloud edge are allowed to disagree.
- Optional whisper layer: at most one wisp card above the board plane at 8 percent alpha or less, only inside nebula hexes. If it costs any readability in testing, it is cut first; the design does not depend on it.

Colour rules: hue comes from the tint, never from a rainbow texture. Per biome the tint shifts (nebula slate teal, storm grey with ember lit rims, dead star ember and ash), and purple and mustard stay banned at the texture-bake step, not by a shader fix.

GPU cost: the cost is overdraw, full stop. Large soft cards at 4K stack transparent pixels fast. Budget: total cloud coverage capped at roughly 1.5 full-screen equivalents of blended area in the worst pan position, 12 to 24 quads per region, one shader with two texture fetches (colour plus erosion), no per-pixel loops, no raymarching. Estimate: well under 1 ms of the 12.5 ms budget on the 5080. Lower presets: drop the near layer first, then halve the mid layer count, then bake far and mid into one static composite per region. The look degrades gracefully because the far layer alone still beats today's flat patch.

Readability: clouds never rise above the board except the optional whisper layer; the hex grid, terrain tints and the R344 patch outline are board-space elements drawn over the backdrop; ship models and markers are 3D and UI above both. The one real risk is brightness: a lit rim under a dark ship can eat its silhouette. Rule: backdrop luminance under the board stays below a set ceiling (the bake checks it), and lit rims are placed by the region layout, not randomly under the fighting.

Least-sure: the whisper layer. It is the only piece that puts cloud between the camera and the ships, and the difference between "depth" and "dirty lens" is a few percent of alpha.
Biggest risk: overdraw at minimum zoom. When the player zooms all the way out, every layer is on screen at once and the wisps stack; the coverage cap has to be tested at that zoom, not at the default.

## Question 2: biome ambience

Common shape for all six: two layers each, a base (continuous, looped 2 to 4 minutes, crossfaded loop so the seam is inaudible) and a swell layer (the same family of sound, gain riding a slow random cycle of 30 to 90 seconds, never periodic enough to notice). All beds sit on the Ambience bus, under Effects and Tactical cues. Ducking: the bed ducks 6 dB under sustained combat and 9 dB for the beat around a capital death (the mix already ducks for deaths; the bed joins that duck instead of fighting it). When objective urgency rises, the swell layer thins (its gain ceiling drops by half) rather than any new sound entering; tension comes from the music job's intensity feed (issue 2034), not from the bed getting louder or busier.

- Nebula. One line: a low gas hum breathing very slowly, like wind heard through a hull with the weather taken out of it. Base: lowpassed broadband wash with everything above the hiss band removed, centred low. Swell: the same wash swelling over 40 to 60 seconds. Character: none. This is the bed that replaces the rejected rain take, so it is the reference for what "no weather" means: if a listener can picture rain, it fails.
- Asteroid field. One line: near-silence with weight, a deep room tone and the faintest sense of mass moving far away. Base: the deep space bed at lower level. Swell: very slow sub swells, 60 to 90 seconds. Character: single soft rock knocks, one every few minutes at most, low and distant, never a pattern (the moment it repeats it becomes patter, so the scheduler is random with a long floor). Quietest bed of the six.
- Dead star. One line: a sub-bass pulse like gravity breathing, with a thin held shimmer far above it. Base: low rumble. Swell: the pulse itself, period 8 to 12 seconds, felt more than heard. Character: the shimmer (trapped light) at very low level, steady, not twinkling. This biome is a finale stage, so its bed is the most composed of the six.
- Planet orbit. One line: an airy low wash with a long orbital swell, the calmest open feeling in the game. Base: soft wash, slightly brighter than deep space but still lowpassed. Swell: one slow rise and fall over about 90 seconds. Character: none.
- Station. One line: a low mechanical hum with the life of a big building in it, heard from inside a docked ship. Base: softened mains-like hum fundamental with its harmonics kept low. Swell: distant machinery cycles, 20 to 40 seconds, very low. Character: a rare soft docking clunk or servo pass every minute or two, quiet enough to doubt you heard it. The electronic-sounding ban bites hardest here: no beeps, no servo whines at pitch, everything through the hull filter.
- Deep space. One line: almost nothing, a threshold hum that makes the other beds audible by contrast. Base: a very low room tone. Swell: a breathing gain so slow it reads as the player's own hearing. Character: none. This is the control bed: if deep space is interesting, it is wrong.

Build first: the nebula bed. It is the biome the owner has already rejected once, so it carries the acceptance test for the whole family (no rain, no hiss, no weather), and it is the most common battle biome, so its loop quality matters most.

Least-sure: the asteroid rock knocks. Sparse character sounds are where ambience plans go to die: too rare and they startle, too common and they pattern. The fallback is cutting them and letting the field be pure quiet.
Biggest risk: loop fatigue over a long session. A 2 to 4 minute loop under a 3 hour session repeats 50 to 100 times; the swell layer's random gain is the only thing standing between the design and a player who can hum the bed. If fatigue shows in testing, the fix is longer beds (6 to 8 minutes) for the base layer, at file-size cost, before any new sounds are added.

## Strongest objection

The brief treats the nebula as a backdrop problem, but R247 makes it a board problem too: nebula hexes are terrain the ships fly through, with rules attached. A backdrop-only cloud, however layered, still sits under the board while the rules say the ship is inside the cloud. If the two never meet visually (no wisp at ship level, no light change on a ship inside a nebula hex), the terrain will keep reading as a tint on a board rather than a place, and this job will have polished the wallpaper. The whisper layer is my own answer and I rated it my least-sure piece; the council should say plainly whether ship-level atmosphere is in scope or whether backdrop-only is the accepted limit.
