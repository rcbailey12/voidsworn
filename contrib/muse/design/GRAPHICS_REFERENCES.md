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

## 4. Top up (added 24 October 2026): the three omissions, EVE, and the BattleTech and MechWarrior masterclass

Added after the first pass. This section covers the three games the original list missed, Ryan's EVE question, the BattleTech and MechWarrior pair, and one extra that earned its place. Every game below was checked against a live source page during this pass. Where a source is a community wiki, a forum thread, or a pre-release document, that is flagged in place, because the sourcing tier matters.

### Stellaris (Paradox Interactive)

Steal:
- Graphical culture as a pure skin layer. A ship's function is composed once (a ship size, section templates that mount on it, component templates that fill the sections), and its look is a named graphical entity per culture and ship size. The empire picks its graphical culture independently of its stats, and the naming convention has a fallback: if the exact culture entity is missing, the game degrades through culture prefixes to a default. Six Voidsworn factions could share hull function while wearing completely different entity sets, and a missing faction variant degrades gracefully instead of breaking.
- Locator discipline. Sections declare named slots, components attach at locators on the model, and a weapon entity needs a turret_muzzle_01 locator that defines where projectiles spawn. That is the contract the ship kit needs: named hardpoint and muzzle locators on every hull, recorded in the hull manifest.
- Ship sets as a modding genre. The Steam Workshop carries large numbers of community ship sets, which is what a clean data contract produces over a decade.

Study it:
- Ship modding page, Stellaris Wiki (community wiki on Fandom): https://stellaris.fandom.com/wiki/Ship_modding
- Stale source flag: parts of that page were last verified against game version 3.0, so use it as a map of the system, not as current gospel. The official Paradox wiki modding pages would not load during this pass. Many Workshop ship sets port other franchises' fleets (Amarr, Ferengi, Vaygr and similar); those are other studios' IP, study only.

### Star Wars: Empire at War (Petroglyph, 2006) and Forces of Corruption

Steal:
- XML-driven units, completely. Ships, weapons, costs and ranges live in plain XML files, and hardpoints are defined per ship as their own health pools, destroyed independently of the hull. The mod scene is still receiving new work nearly twenty years after launch (the Forces of Corruption ModDB page took new mods and updates in October 2026), and that longevity is what a fully data-driven unit format buys.
- The Empire at War Remake mod as the presentation benchmark. Its changelog reads like a Voidsworn wishlist: remodelled ships with individually lit windows, weapon batteries that visibly track targets and can engage several at once, ships that catch fire as they take damage so damage state reads at a glance, destroyed ships persisting as wreck states (the mod calls them deathclones), and a pass that re-optimised almost all particle effects for smoothness. Reviewers single out the turbolaser particles, the moving batteries, and steam venting from overheated barrels.

Study it:
- Beginner modding guide for the XML format and hardpoint basics: https://gamefaqs.gamespot.com/pc/932730-star-wars-empire-at-war-forces-of-corruption/faqs/45886
- The Remake mod's own pages on ModDB: https://www.moddb.com/mods/empire-at-war-re/images/victory and the Forces of Corruption mods index for the scene itself: https://www.moddb.com/games/star-wars-empire-at-war-forces-of-corruption/mods
- IP flag: this is Star Wars. Ships, names and factions are Lucasfilm IP. Study the systems, reuse nothing.

### Endless Space 2 (Amplitude Studios)

Steal:
- The Battle Director. Amplitude's own design document describes battles built as cinema from the ground up: a Battle Director analyses what is happening and selects what to show, inside a five phase structure (cinematic arrival, three battle phases, cinematic resolution). Voidsworn battles are already simulated, so a director layer that picks camera beats from the event log is the cheapest cinematic upgrade anywhere in this document.
- Visible, destructible weapon modules. Modules sit on the hull, traverse, fire, take damage and can be destroyed, and the post-battle report shows fleet movement plus which sections and modules each ship lost. Damage you can see, then damage you can review.
- Scale and arena discipline. Ship size classes step up by roughly 3x, so class reads from size alone, and the arena is generated from the system being fought over (planet, anomalies, star type), including localised hazards. The backdrop does gameplay work.

Study it:
- Community GDD 4: Battle Overview, on Amplitude's official community site: https://community.amplitude-studios.com/amplitude-studios/endless-space-2/forums/66-game-design/threads/20675-community-gdd-4-update-battle-overview?page=1
- Flag: this is a pre-release design document, so it describes intent. The shipped game kept the broad shape, but check any single mechanic against footage before treating it as fact. Modding tools ship behind the --enablemoddingtools launch flag, documented on the same community forums.

### EVE Online (CCP, now Fenris Creations)

Steal:
- Layered paint: SKIN and SKINR. The older SKIN system (2015) is licence based: buy a licence, apply it to your character, permanent even if the ship dies. SKINR (Equinox expansion, June 2024) is a design tool. Each design has five slots: four nanocoatings plus one pattern, and the pattern carries a nested nanocoating slot of its own. Elements are Basic and Metallic nanocoatings and Patterns, each in Unlimited or Limited form, bought, sold and earned in game, and even the finish is a number (gloss materials 0.75, satin 0.60, matt 0.40). Finished designs are saveable and tradable. For Voidsworn this maps straight onto the FAC3D single colour source: a faction scheme as a small fixed set of data slots (base coat, accent, pattern, finish, glow) gives every hull a family look at tiny asset cost.
- Graceful degradation of the picture. In space, every object wears a bracket (an icon), and the overview, a sortable and filterable list, is the primary interface in a big fight. EVE University's overview guidance is blunt: in very large fleet fights, turn brackets off and fly from the list. The lesson is the layering: full 3D up close, icons at range, a clean list when the field gets huge, and every layer stays playable. Same conclusion as the Sins zoom icons in section 1, reached independently by a live game under real load.
- Time dilation as a performance tool. When a system overloads, the simulation itself slows down (automated, to as low as 10 percent speed) rather than dropping commands. CCP's design rule, as reported from CCP Veritas's dev blog: timers a player would check on a watch do not dilate, combat flow timers do. A turn based game does not need TiDi itself; the stealable principle is to slow the presentation clock before cutting simulation fidelity when a late battle gets heavy.
- Sky as place. The Crucible expansion replaced generic backdrops with per-region nebulae so location reads from the sky alone, realigned stargates to point at their actual destinations, and drew star fields from real neighbouring systems. Voidsworn's 18 plate background catalogue can do the same job: one recognisable sky per campaign region.
- Open source: the Carbon engine. In July 2026 Fenris Creations (CCP's new name after its 2026 independence buyback) open sourced the Carbon framework on GitHub (github.com/carbonengine): more than two dozen modules, most under the MIT licence, two under Apache 2.0 and the Python Software Foundation licence. Trinity is the renderer behind EVE's look, Destiny the simulation and pathfinding core, and there is a Wwise spatial audio clustering plugin worth reading for fleet audio. Caveats, flagged in place: it is a framework, not a turnkey engine, there is no editor, launch coverage noted that some Destiny dependencies were not included and an example project was still only planned. Read it for architecture, not as a build target.

Study it:
- SKINR: EVE University Wiki, Ship SKINR: https://wiki.eveuniversity.org/Ship_SKINR
- Overview and brackets: EVE University Wiki, Overview article (the wiki's canonical guide to overview setup, bracket filters, tab presets and tagging).
- Time Dilation dev blog by CCP Veritas: https://www.eveonline.com/news/view/introducing-time-dilation-tidi and the Crucible patch notes, which shipped TiDi and the new nebulae together: https://www.eveonline.com/article/patch-notes-for-crucible-1
- Carbon coverage with the module list: https://www.gamedeveloper.com/production/eve-online-s-cross-platform-game-engine-framework-is-now-fully-open-source
- Honesty flag: no CCP document found in this pass describes automatic client side effect culling or scaling in fleet battles. The documented scaling is TiDi on the server, bracket and overview discipline on the client, and player controlled graphics settings. Anything stronger is folklore.

### BattleTech (Harebrained Schemes, 2018) and MechWarrior (Piranha Games: MechWarrior 5 and MechWarrior Online)

This pair is the masterclass for Voidsworn's open problem: telling weapons and damage states apart at a glance, in the middle of a fight.

Steal:
- Colour is calibre. The series convention, stated plainly on the official MechWarrior Online forums: small, medium and large lasers are red, green and blue respectively, while PPCs are lightning blue. One colour per weapon class, held across decades of games, learnable once and readable at any range. Voidsworn's weapon set needs the same ruthlessness, and it extends the colour law already in the art direction pack: cyan means shields, so weapon colours get their own fixed assignments and no colour is ever reused across classes.
- Shape and rhythm separate what colour cannot. Lasers are sustained beams whose duration is the signature. PPCs are a single crackling bolt with travel time. Autocannons are discrete tracer shells with recoil and a cadence you can count. Gauss is near invisible in flight and enormous on impact. Missile racks fire physical swarms whose visible count is the rack size, so an LRM 20 reads as twenty missiles because it is twenty missiles. A MechWarrior Online mod, BattleTech Feel: Weapon Visuals, catalogues the next level down: Clan versus Inner Sphere PPC trail widths and plasma ball sizes, distinct gauss trail colours, laser brightness scaling by class, missile smoke colours, and volley desync so a salvo ripples instead of firing as one blob. Five cheap axes (colour, trail, count, smoke, timing) differentiate a whole arsenal before a single new model is built.
- The paper doll. BattleTech gives every mech eight separate locations (head, both arms, all three torso sections, both legs), each with armour first and structure underneath, drawn on a front and rear doll. Destroy a location and its remaining damage transfers inward toward the centre torso, so a mech dies from the outside in and the readout tells that story. Floating bars over the mech repeat the code at range: white squares for armour (first half front, second half rear), orange for structure, a red bar for heat, yellow for stability. For Voidsworn capitals, steal it whole: a per-section doll on the ship card, section state mirrored on the model (darkened plating, venting, turrets gone silent), and segmented bars over the hull in the same colour order. It converges with Empire at War's hardpoints and Endless Space 2's module damage, from the UI side.
- Heat as visible pressure. The heat bar sits beside the damage bars, a full bar shuts the mech down, and structure damage prints in orange, so weapon choice is visibly a heat budget. Whatever Voidsworn's equivalent resource is (heat, flux, capacitor), it belongs in the same readout, not in a tooltip.
- Weight framing. Mechs read heavy through low angles, kicked up dust and debris, and recoil scaled to weapon class. The translation for Voidsworn is impact flash, shake and debris scaled by weapon class and budgeted, so the biggest guns stay special instead of everything maxing out.

Modding setups:
- BattleTech has no official mod support and no Steam Workshop, and it scarcely mattered. The community stack is BTML (a Harmony based injector) plus ModTek, and content is JSON: mechs and chassis are JSON definition files, and each mod ships a mod.json whose only required field is a Name and whose Manifest lists typed entries (MechDef, ChassisDef and friends) pointing at the definition files the loader merges into the game data. Distribution is Nexus Mods and GitHub. Format doc: MOD_JSON_FORMAT.md in the ModTek repo: https://github.com/BattletechModders/ModTek
- MechWarrior 5 takes the opposite route: an official Unreal Engine 4 mod editor, downloaded through the Epic Launcher under its own mod editor EULA. The documented workflow is substitution: open a game asset (the editor guide's worked example is a level 5 Gauss Rifle), Save To Mod to duplicate it into the mod's override folder, edit stats in the copy, and the editor loads the override automatically. Mods distribute through Steam Workshop, Epic and Nexus. Start at Piranha's modding resources page: https://mw5mercs.com/resources/2020/01/29-modding-resources
- More study: the comprehensive BattleTech guide on Steam Community, for the paper doll, the eight location pools and damage transfer: https://steamcommunity.com/sharedfiles/filedetails/?id=1376736707 ; the laser and PPC colour thread on the official MWO forums: https://mwomercs.com/forums/topic/148045-different-color-for-er-versions-of-large-laser-and-ppc/ (a 2014 thread, but the convention it states is the one the games still ship); the Weapon Visuals mod page: https://www.nexusmods.com/mechwarrioronline/mods/63?tab=description
- Licence and IP flags: ModTek and BTML are community tools, check each repo's licence before reusing code. The MW5 editor is free to download but governed by its EULA. BattleTech and MechWarrior are licensed IP (Microsoft and licensors): adopt the visual language, do not reuse names, designs or fiction.

### One more: Starsector (Fractal Softworks, in development)

Only one extra earns its place, for the purest version of the data driven lesson. Starsector's whole content layer is editable text: a ship is a CSV row plus three small files (.ship for the hull, .variant for the loadout, .skin for a reskin), a weapon is a CSV row plus .wpn and .proj files, hullmods and ship systems follow the same pattern, hull and engine styles are JSON, and even damage decals are a data sheet. The hull, variant, skin split is the same three layer separation Stellaris uses, proven at two person team scale, and the mod library runs to thousands of entries because of it. The tuning loop matters as much as the format: dev mode lets modders reload JSON and CSV live in the simulator (F8), so weapon feel can be iterated without a restart.

Study it:
- Modding hub, Starsector Wiki: https://starsector.fandom.com/wiki/Modding
- Flags: the game is still in development and sold direct, not on Steam, so the scene lives on the developer's forum and this wiki; the wiki itself warns its mod articles are not guaranteed current and points to the official forum as canonical. Community libraries (MagicLib, which includes data driven projectile trail definitions) carry their own licences; check before any reuse.
- Skipped, deliberately: Homeworld Remastered, X4: Foundations and Cosmoteer were candidates for this slot and were not verified to the standard of the rest of this section in this pass, so they are left out rather than padded in.

## Start here: the seven highest value items, in order

1. Sins 2 mod tools repo and dev journals. Budgets, texture channel layout, and combat geometry, all from the closest reference game. Read first, before the next hull or texture pass.
2. Babylon.js Playground examples via the engine repo README. Working beam, shield, particle, and post-processing code in the actual engine, Apache-2.0.
3. Homeworld 3 art director interview. One sitting, and it hands you the hull striping class code, the cheapest readability system on this list.
4. webgl-noise. One MIT library that unlocks shield shimmer and nebula work in ShaderMaterial and Node Material alike.
5. Kenney Space Kit plus Skyboxes Space. CC0 placeholders that unblock camera, effects, and background work in the first week, with zero licence risk.
6. Endless Space 2 Battle Overview GDD (top up, section 4). One design document that hands over the Battle Director and the five phase battle structure: the cheapest route to battles that feel directed, not just rendered.
7. Starsector modding hub (top up, section 4). The hull, variant, skin data split and the F8 live reload tuning loop, which is the closest model on this list for how Voidsworn's own data layer should behave.
