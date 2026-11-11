# Leg: Grok (ideation), issue #486 cinematic audit

Landed Nov 11, 2026, 10:35 to 10:37 CST via grok.com (already signed in as Ryan Bailey; PACK.md attached by grant; no moderation refusal, no rewording needed). Raw leg text below, unedited except this header.

---

Top eight findings (short form: now / film instead / loosening)

Identical impact stamp on every hull hit.
Player sees the same small white glow + beige puff for macro, las, autocannon, scatter, plasma (m1/m5).
Film (Battlestar Galactica, The Expanse) differentiates kinetic spark/skip, energy splash/run, directional dirty bloom.
Loosen: give each weapon class its own impact grammar (spark cone, sear trail, molten spray, crater) and scale the puff/glow with shooter and target size.
One soft cotton-ball material for every explosion, hit and death.
Every event is a scaled beige-grey round puff; nothing throws fragments, sparks with trajectory, jets or lingering debris.
Film uses at least two materials at different speeds/directions (bright fast + slow dirty).
Loosen: add directional debris streamers, secondary sparks and a short-lived vent jet rooted to the impact point; keep the hot-core route B but stop making the gas the only visible product.
Perfect honeycomb ellipsoid shield that never reacts locally.
Shield is an identical flawless bubble; hits float a disconnected puff at the edge; damage states look the same.
Film/game (Star Trek local flares, Sins of a Solar Empire 2) answers at the impact point and writes condition on the surface.
Loosen: local cell brightening/ripple at hit, dark gaps for damage, and a true collapse that peels or fails in patches rather than a flash + halo.
No scale contrast between frigate and capital hits or deaths.
Same tracer, same impact size on Eclipse frigate and tomb-ark; small-ship and capital deaths differ mainly by puff diameter.
Film grammar is built on mass: capital main battery dwarfs fighter cannon; hit on capital is absorbed, not identical.
Loosen: enforce the 1.4× ladder more aggressively at camera 170 and make capital body/secondary counts and light-neighbour radius visibly larger.
Evenly spaced, identical chain blasts and perfectly round core flash.
Capital/cruiser death strips march identical sparkles or small fires at regular intervals; core is a centred cauliflower ball.
Real internal failure staggers size, timing and depth.
Loosen: randomise chain timing/size within the beat windows, offset the core flash to the torn face, and vary secondary count by cause (already named in deaths_and_hits.md).
Ruler-straight, hard-edged, constant-brightness beams.
Lance/ion are perfect white bars; gauss draws a hairline across the whole frame.
Filmed beams strain at source, heat the path, splash at the end.
Loosen: add source bloom, slight taper or flicker, a brighter head and a short contact burn that crawls while the beam dwells.
Nothing lights its neighbours; space resets clean after every event.
No reflected light, no scorch, no residue, no debris field left behind.
Film lets violence write on the world for seconds.
Loosen: implement the playbook’s already-stated “light on neighbours” for torpedo and death flashes, plus persistent wound scars that glow then darken.
Sound events are short, dry and thinly varied.
Many cues share the same layer set; tails are short or absent; max concurrent and gap numbers clamp density; some events still have only one or two synth takes.
Film space battle design (The Expanse, Sins) uses mechanical/electrical weight, longer low-end tails for big events, and continuous variation so repeated weapons never sound identical.
Loosen: enforce ≥4 distinct takes for every frequent cue, lengthen the low-body tail on boom_l / death sequences, and let size/distance modulate pitch and layer mix rather than only gain.

Staged tell writers are likely to miss

The playbooks themselves still mandate “flash and snuff out” with hard 0.70 s / 0.25 s flame caps and “never rolling fire.” That rule, written for readability and photosensitivity, forces every big moment into the same instantaneous on/off rhythm; the eye never sees lingering heat or cooling coals that would sell mass and violence. The FLASH_CAP of three large flashes per second compounds it. Drama has to live inside the cap (lingering colour, slower ramps, sound carrying the hit) rather than by adding more flashes.

Movement devices shortlist

Suit a top-down hex turn-based game with 1-2 s playback:

Main-engine plume only while accelerating along the nose, then dark while coasting.
Brief thruster puffs at bow/stern for pure rotation (independent of travel vector).
Drift while facing continues (nose not locked to path).
Short flip-and-burn or retro burn to stop or reverse.
Class weight: capital starts/stops/turns with longer burns and bigger plumes than frigates.

Do not suit: continuous banking/rolling like aircraft, curved road-like arcs with nose always on path, drag that slows the ship with no burn, wakes, or any motion that needs forward speed to turn.

One-line verdict

The single highest-leverage loosening is giving every weapon and death its own material language and true scale contrast (impact grammar + neighbour light + size ladder) so the board stops looking like one soft stamp applied at every size.
