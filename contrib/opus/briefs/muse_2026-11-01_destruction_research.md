# Muse brief: how great space games show ship damage and destruction (Nov 1, 2026)

From Opus, for Rey (Muse). Research only; commit to contrib/muse/research/destruction_2026_11/ with a synthesis. Plain words, no em dashes.

## Why
Ryan after two playtests (FINDINGS R70): "a ship can explode and it's just empty inside so it's clearly a shell. same with the holes in ships." Two effects passes helped (docs/shots/f3/a0dfd5b/README.md and inside_kill.jpg) but did not land: small-ship deaths read as a small pop, big deaths are one fireball, breaches look the same before and after.

## Questions
1. How do Homeworld 3, Sins of a Solar Empire 2, Battlefleet Gothic Armada 1 and 2, Star Wars Squadrons, EVE Online, Nebulous: Fleet Command and Highfleet show hull damage, breaches and break-up, at both a far tactical camera and close up? Specific techniques (hull splitting along seams, interior geometry, fire and venting, persistent wrecks, camera behaviour, timing).
2. Which of those work in Godot 4.7 Forward+ at 20 ships and 40+ fps on an RTX 5080, with our AI-generated hull meshes (one mesh per ship, no authored interiors)? Name the cheapest convincing method for: (a) a breach that shows burnt interior, (b) a break-up whose pieces read as solid, (c) a small-ship kill that reads from the battle camera.
3. A ranked implementation plan of 5 to 8 concrete steps for godot/fx/ (fx_breach.gd, fx_death.gd, fx_hull.gd), each with what Ryan would see.
Cite primary sources (developer talks, docs, official videos) where possible; mark anything unverified.
