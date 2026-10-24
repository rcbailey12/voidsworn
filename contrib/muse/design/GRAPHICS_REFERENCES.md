# Graphics References for Opus

Purpose: a short, verified reading and looting list to speed up Voidsworn's visual work. Every link below was opened and checked during research (October 2026). Licence notes are in plain words. Anything paid, non-commercial, or risky is flagged where it appears.

Short version of the whole document: steal presentation systems, not assets. The games below are worth studying for how they solve readability at scale, and the repos are worth reading for effect structure. Almost nothing here should be copied as content into the game.

One study method that pays off across all five games: watch battle footage twice. First pass at full zoom out, where only icons, bars, beams, and silhouettes carry information. Second pass zoomed in, where hull paint, striping, and impact effects do the work. Every system listed below was chosen because it survives one of those two passes, and Voidsworn's battles need to survive both.

## 1. Reference games: what to steal and where to study it

### Sins of a Solar Empire II (Ironclad / Stardock)

The single closest reference for Voidsworn's target look, and unusually open about its production numbers.

Steal:
- Poly budgets by ship class. Their published targets: strikecraft about 1,500 tris, frigate 12,500, cruiser 25,000, capital 75,000, titan 225,000, with shipped assets usually well under. Voidsworn's kit budgets can be sanity checked against these.
- Texture channel discipline. Their mask texture packs team colour, emissive mask, and emissive hue into RGBA channels. One texture, four jobs. This maps directly onto the FAC3D single colour source rule.
- Combat geometry thinking. Their dev journals on turrets, missiles, and point defense are about how weapon behaviour reads at fleet scale, not about art.
- The zoom range icon system and Empire Tree: at full zoom out, ships become clean icons in a side panel and the game stays readable. Voidsworn's three delta-v bands need the same treatment.

Study it:
- Official mod tools repo, including SolarForge (editor for scenarios, particle effects, beam effects, meshes) and the official HLSL shader folder: https://github.com/StardockCorp/sins2modtools
  Licence flag: the tools repo is proprietary, all rights reserved. Read the budgets, channel layouts, and effect structure. Do not copy code, shaders, or assets into Voidsworn.
- Modding index with links to the developer journals (Dev Journal 24 on shaders, Combat Geometry parts 1 and 2, hardpointing notes): https://strategywiki.org/w/index.php?title=Sins_of_a_Solar_Empire_II/Modding&mobileaction=toggle_view_mobile

### Homeworld 3 (Blackbird Interactive)

Steal:
- Hull striping as a class code. Their art director describes it plainly: a Torpedo class ship gets two stripes aft, an Assault Frigate gets one, so role reads from silhouette and paint before any UI. This is the cheapest readability win available to the ship kit.
- Weapon VFX differentiation. Each weapon type has a distinct effect and impact so the player can tell who is shooting whom at a glance. Directly supports the per-faction effects languages already in the art direction doc.
- Scale honesty. A 3 km mothership next to 20 m fighters. They solve it with shape language and reuse, not with detail density.

Study it:
- Art director interview covering the striping system, shape tuning, and readability under scale: https://www.windowscentral.com/gaming/pc-gaming/homeworld-3-art-director-discusses-redesigning-spacecraft-for-a-pc-rts

### Falling Frontier (Stutter Fox, not yet released)

Steal:
- A shared colour language for ship function across all factions: white marks sensors, orange marks maintenance points, hatches, bays, and missile tubes. Same species of trick as the cyan-means-shields law, applied to hull paint.
- Sensor and recon UI presentation, tactical slow motion, and the free-range orbital camera in the trailers.
- FTL jump visuals and planetary shadow ambush framing: presentation of information states, not just combat.

Study it:
- Steam community news hub, which carries the developer's own art and systems updates: https://steamcommunity.com/app/1280190/allnews/
- Licence flag: unreleased commercial game. Trailer and screenshot study only, nothing to reuse.

### Battlefleet Gothic: Armada 2 (Tindalos Interactive)

Steal:
- Battlefield terrain that is also backdrop: gas clouds that conceal, asteroid fields that block fire, planets and stations kept in the background layer. This is exactly the four-layer background plate model, with the middle layers doing gameplay work.
- Per-ship floating gauges readable in the middle of a brawl (hull, shields, morale as separate coloured bars).
- Destruction with an afterlife: destroyed ships become drifting hulks that stay on the field as obstacles and hazards instead of vanishing in the explosion. Cheap to implement, and it makes a long battle accumulate visible history.
- Faction fleets that are visually unmistakable at a glance.

Study it:
- Review coverage with battlefield and terrain detail: https://voxelvoice.com/battlefleet-gothic-armada-2-review/
- Licence flag: Warhammer 40k IP. Presentation study only. Voidsworn's council already flagged borrowed 40k terms in data.js for purge, so treat this one as look, never language.

### Terra Invicta (Pavonis Interactive)

Steal:
- Plausible ship design language: hulls plus hardpoint modules, drives and radiators as visible design decisions (radiators retract under fire, and the player can see the tradeoff).
- Dense information presented in an organised way. Its combat UI is the opposite of minimal and still works, which is a useful counterweight when Voidsworn's battle UI feels crowded.
- Newtonian combat presentation where firing arcs and momentum are the drama.

Study it:
- Official wiki, including the ship design and combat pages: https://wiki.hoodedhorse.com/Terra_Invicta/Terra_Invicta

## 2. GitHub repos worth your time

### (a) Open source space games

**Endless Sky** - https://github.com/endless-sky/endless-sky
- Licence: code GPLv3. Artwork is public domain or various Creative Commons licences, tracked per asset in the repo copyright file. Check per asset before any reuse; treat as read-only by default.
- Activity: very active. About 10,000 commits, 55 releases, current stable line in 2026.
- Lift: the data-driven content model. Ships, outfits, and effects are defined in data files at a volume Voidsworn will not match for years, and the project stays manageable. The lesson is content discipline and definition patterns, not rendering. It is 2D and C++, so no code transfers.

**Naev** - https://github.com/naev/naev
- Licence: GPL (see gpl.txt in the tree).
- Activity: the GitHub repo is now a mirror only; the project moved to Codeberg. About 49,000 commits of history.
- Lift: more content and data patterns for a 2D space trading and combat game (C and Lua). Same caveat as Endless Sky: organisational lessons, not rendering code.

### (b) Babylon.js sources

**Babylon.js engine repo** - https://github.com/BabylonJS/Babylon.js
- Licence: Apache-2.0. Free to use, including commercially.
- Activity: extremely active, tens of thousands of commits.
- Lift: this is the primary effects library. The materials library, post-processes, particle systems, and the Playground examples linked from the README are where beam, shield, and skybox recipes live in working form. The shader creation tool (CYOS) linked from the README is the fast way to prototype a shield or nebula shader before porting it into the game. Read example code for structure; the engine itself is already Voidsworn's dependency.

**Babylon.js Editor** - https://github.com/BabylonJS/Editor
- Licence: Apache-2.0.
- Activity: active, current release 5.5.2, about 3,500 commits.
- Lift: a community visual editor for Babylon scenes, with templates. Useful for blocking out a background plate stack or an effects test scene without hand-writing scene boilerplate each time. Optional tooling, not a runtime dependency.

### (c) Vibe coded and AI assisted projects: honest notes

**Awesome AI-Built Games list** - https://github.com/lappemic/awesome-ai-built-games
- Licence: the list itself is CC0. Individual games keep their own licences, which are often unstated. Check each repo before reusing anything.
- Activity: actively curated since March 2025.
- Entries worth a look: ClaudeSpace (top-down space shooter with shields and shockwaves, Phaser), Dyson Defender (Three.js space defense), Null Range (multiplayer space dogfights, won a Best Art Direction nod at Vibe Jam 2026), Concordia (a full-scale rotating space station and city walkthrough built with Claude Code, Three.js), and World of ClaudeCraft (an open source browser MMORPG built with Claude).
- What they prove: an AI assisted developer can reach a playable, even charming, browser 3D game very fast, and effect prototyping (shields, shockwaves, space environments) is one of the strongest use cases.
- What they do not prove: architecture, performance discipline, or maintainability. These are mostly single-sprint projects. A widely reported METR trial found experienced developers were slower, not faster, with AI tools on a mature codebase, while feeling faster. Use these projects as proof that a weekend prototype of a beam or shield effect is realistic, not as a model for how the game code should be organised.

**Survival Game (CptNope)** - https://github.com/CptNope/survival-game
- Licence: MIT.
- Activity: small and recent, created May 2025, about 47 commits, one star. A hobby project, not a reference implementation.
- Lift: a complete, readable Babylon.js game in plain JavaScript modules with a component layout (terrain, player, combat, UI), procedural generation, and a model viewer page for inspecting generated assets in isolation. The model viewer pattern is worth copying for the ship kit: every hull inspectable alone under studio lighting before it enters a battle scene.

### (d) Shader and material sources

**webgl-noise (Ashima / stegu)** - the GLSL noise library maintained by Stefan Gustavson, searchable under ashima/webgl-noise
- Licence: MIT.
- Activity: old and stable. The library is finished rather than abandoned; the maintainer's newer psrdnoise work exists separately.
- Lift: self-contained simplex and Perlin noise GLSL with no texture lookups. Drops into a Babylon ShaderMaterial or a Node Material custom block and is the standard starting point for shield shimmer, nebula churn, and engine glow flicker.

**Node Material snippet pattern** - Babylon's Node Material Editor graphs can be shared as JSON snippets and loaded at runtime, and the same JSON can be self-hosted instead.
- Licence flag: loading snippets from the public snippet server makes the game depend on a third party network service at runtime. Self-host the JSON and the dependency disappears. This pattern is already covered in the visual expansion research memo; it is repeated here only because it is the fastest route from a community shield or beam graph to a tested in-game material.

## 3. Kick-off assets

**Kenney space kits** - https://kenney.nl/assets/space-kit
- Licence: CC0. Free, no attribution required, safe to ship.
- The Space Kit has 150 plus models in OBJ, FBX, and glTF. Sibling kits cover space stations, modular ship parts, and five panoramic space skyboxes (search Kenney for Space Station Kit, Modular Space Kit, and Skyboxes Space).
- Use: greybox hulls, station blockouts, and placeholder skyboxes so effect and camera work is never blocked waiting on art. The low-poly style will not match the art direction and is not meant to. Placeholders only.

**Quaternius space packs** - https://quaternius.com
- Licence: CC0 per the pack pages and the Godot Asset Library listing for the Ultimate Spaceships Pack.
- Use: silhouette and blockout reference for hull proportions. Same placeholder logic as Kenney, with a slightly different style. Not final art.

**NASA 3D Resources** - https://science.nasa.gov/3d-resources/ (mirrored on GitHub under nasa/NASA-3D-Resources)
- Licence flag: free to download and use, but NASA media guidelines apply: no insignia misuse, no implied endorsement, and individual items can carry third party terms. Fine for reference and prototyping today; check the guidelines per item before anything ships in the game.
- Use: real spacecraft proportions, planet and nebula imagery reference, and texture reference that no stock library matches.

Also already in hand: the visual expansion research memo (contrib/muse/design/visual_expansion_research.md) covers CC0 texture libraries (ambientCG, Poly Haven), Kenney particle sprites, and KTX2 compression. This document deliberately does not repeat that list.

## Start here: the five highest value items, in order

1. Sins 2 mod tools repo and dev journals. Budgets, texture channel layout, and combat geometry, all from the closest reference game. Read first, before the next hull or texture pass.
2. Babylon.js Playground examples via the engine repo README. Working beam, shield, particle, and post-processing code in the actual engine, Apache-2.0.
3. Homeworld 3 art director interview. One sitting, and it hands you the hull striping class code, the cheapest readability system on this list.
4. webgl-noise. One MIT library that unlocks shield shimmer and nebula work in ShaderMaterial and Node Material alike.
5. Kenney Space Kit plus Skyboxes Space. CC0 placeholders that unblock camera, effects, and background work in the first week, with zero licence risk.
