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
- Skipped in this pass: Homeworld Remastered, X4: Foundations and Cosmoteer were candidates for this slot and were not verified to the standard of the rest of this section at the time. They are covered properly in section 5.

## 5. Second top up: the three modding games skipped last time

These three were left out of section 4 because no source had been verified to the standard of the rest of the pack. They have now been checked properly. All three are here for the same reason: each one proves a different way of making ships out of data, and each one built a mod scene that outlived the original design team.

### Homeworld Remastered (Gearbox Software)

The ship is one file. A Homeworld ship lives in a .hod file that bundles the hull mesh with its turret and hardpoint structure, the anchor points where effects fire from, animations, and team colour and stripe texture data. The format has three generations (HOD1 from Homeworld 2 Classic, HOD2 before the 1.30 patch, HOD3 since the 2.0 patch), and a separate .ship script file beside it carries stats, abilities and subsystem definitions, referencing weapon files that a community tool (the HW2 Reference Investigator) can check for broken links. Authoring runs through a converter round trip: HODOR turns a structured .dae model into a game ready .hod, RODOH converts back, and DAEnerys is a visual editor for the result. Gearbox shipped official mod tools and Steam Workshop support at launch, with written tutorials (getting a simple ship in game, turrets, dock paths and latch points, capital ship engines, team colours and stripes). The 2.0 patch added a mod patching system so base assets can be altered nondestructively, instanced ship turrets, and stance and formation behaviour modifiers stored as data.

The mod scene is the lesson. The Complex mod was built by people who had worked on the Remastered core team, was scripted from scratch, and is still being updated a decade on; FX:Galaxy fits eight races into the same format and was publicly acknowledged by Gearbox. Total conversions survive that long only when the unit format is a real contract with tools that round trip.

Steal:
- The one file per hull contract. Mesh, hardpoints, effect anchors and paint channels in a single manifest is exactly the ship kit work order, proven at production scale.
- The converter round trip. Author in a friendly format, compile to the game format, and always be able to convert back. A format you cannot inspect backwards becomes a trap.
- Nondestructive patch overrides, so balance passes layer over base data instead of forking it.

Study it:
- KarosGraveyard wiki, the community's documentation mirror: Tool Reference (https://github-wiki-see.page/m/HWRM/KarosGraveyard/wiki/Tool-Reference) and the linked Tutorial Reference and Modding FAQ pages.
- Gearbox's own modding support article: https://support.gearboxsoftware.com/hc/en-us/articles/205281760 ; the Complex mod page: https://www.moddb.com/mods/homeworld-complex
- Licence and IP flags: Homeworld is Gearbox IP and the tools exist to mod that game. Read the format design, lift nothing else.

### X4: Foundations (Egosoft)

X4 is the opposite authoring bet: no compiled unit file at all. Everything is XML, mods live in an extensions folder and toggle in game, and a mod changes the game by patching it, using XPath style operations that add, replace or remove single nodes inside the game's own files. A rebalance mod therefore never copies a ship file; it states a diff. Above the data sits the Mission Director, an XML scripting system of cues, conditions and actions (shared with X Rebirth), and MD scripts carry versioned patch elements that are applied when an older save is loaded, so scripted content migrates forward instead of breaking.

Ship feel is data, and the official wiki shows its working. Engines define thrust plus boost and travel drive multipliers. The ship macro's physics block sets acceleration factors per direction. A jerk block shapes how acceleration itself ramps, with a worked example of a "soapy" heavy freighter whose every input arrives late. Steering curves cut turn rate as speed rises, and faction flavour is expressed in these numbers (Teladi and Terran ships brake better, Paranid ships are faster but unwieldy at speed). Ships and stations are both modular: a hull macro plus separate engine, thruster, shield and turret components, and stations assembled from placed modules.

The scene is huge and it feeds the studio. Steam Workshop is the main channel, shared infrastructure mods (SirNukes Mod Support APIs) exist purely so other mods can build on them, the VRO overhaul rewrites every ship and weapon behaviour in pure XML, and its author was later hired by Egosoft. When the data layer is fully exposed and patch based, the community becomes a second design team.

Steal:
- Diff based overrides for Voidsworn's data layer. State the change, never fork the file. This is the same discipline the save integrity findings ask for, applied to content.
- Ship feel as one small named parameter block per hull (thrust, acceleration factors, jerk, steering curve), tuned per faction. It is the flight model version of the FAC3D single source rule.
- Versioned patches applied on save load, so old runs migrate instead of bricking.

Study it:
- Egosoft's official wiki, Modding Support: the Mission Director Guide (https://wiki.egosoft.com/X%20Rebirth%20Wiki/Modding%20support/Mission%20Director%20Guide/) and the flight parameter guide, which is the jerk and steering material above (https://wiki.egosoft.com/X4%20Foundations%20Wiki/Modding%20Support/Assets%20Modding/Guides/JPMFlight/).
- The community x4modding wiki for how the object and spawn data is organised in practice: https://github-wiki-see.page/m/enenra/x4modding/wiki/god
- Licence and IP flags: X4 is Egosoft IP and the wiki documents modding that game. The patching pattern and the parameter blocks are ideas, free to adopt.

### Cosmoteer (Walpole Interactive / Wiley Vent)

Cosmoteer has had official mod packages since version 0.11.7 in 2017, with an in game Mods Manager for installing and enabling them, and the game ships with an Example Mod and an Example Translation as the starting point. There is no single official modding manual, and that is worth stating plainly: the living documentation is the changelog's Modding sections on cosmoteer.net, the developer blog, the shipped example, and the official forum. The format underneath is readable text throughout: each part is a folder holding a .txt definition in a custom text language, a mod is a mod.txt metadata file plus part folders, ship libraries and Strings language files. Numeric fields accept full mathematical equations with embedded references to other values, so a stat can be derived from another stat instead of duplicated. A Developer Mode inside the game adds a particle effect editor and a planet editor aimed at modders.

Two systems matter most for Voidsworn. First, painting. A ship gets a base paint colour and a pattern, then two decal layers on top (letters, numbers, symbols, icons, tile pieces), one colour per layer. Paint is free, the design is remembered and restored when destroyed parts are repaired, and saved Paint Schemes record colours and base pattern only, not decal layouts, so a scheme is portable data that can be applied to any hull. Later updates made decals resizable, stretchable and invertible, including modded decals. Second, construction and destruction. Ships are built module by module on a grid, crew are individually simulated and walk to operate parts, haul ammunition and fight fires, and in the game's real time battles every module can be targeted and destroyed, with ships breaking apart into separate pieces, all wrapped in a Career mode across a procedurally generated galaxy.

Steal:
- Paint as layered data decoupled from the hull (base colour, pattern, two decal layers). This is FAC3D with a player facing editor, and the scheme portability rule is the part to copy exactly.
- Part definitions in readable text with equations that reference other values. Balance that derives stays consistent when one number changes.
- Ship one tiny complete Example Mod as the documentation. The cheapest way to teach a format is a working sample of it.

Study it:
- The official site and its changelog, whose Modding sections are the real reference: https://cosmoteer.net/history.html ; the developer blog on the tooling Cosmoteer itself added for modders: https://blog.cosmoteer.net/2018/01/cosmoteer-0132-miscellaneous.html
- Licence and IP flags: Cosmoteer is its developer's IP; modding is officially encouraged for that game. The text format and paint scheme ideas are free to learn from, the assets are not.

## 6. Games actually like Voidsworn

Ryan's question, asked directly: is there anything remotely similar to this concept? Turn based or simultaneous turn space fleet tactics, a campaign or roguelike run wrapped around it, admiral and fleet progression, per ship damage that persists. The honest answer is that the pieces all exist and the combination almost does not. The entries below are precise about turn structure, because this corner of the genre blurs three different systems (alternating turns, simultaneous turns, pausable real time) and the difference is the whole design.

### Headline: Warhammer 40,000: Rogue Trader (Owlcat Games)

This is the benchmark because Ryan named it as one: asked which space battles scratched this itch most, he pointed here, to small fleets, strictly turn based, and fun. The voidship battles are a side system inside a large story CRPG, which makes the lesson sharper: a part time battle system with one ship still produced the feel, because every mechanic on that ship is a decision.

How it actually works, verified against the game's wiki:
- Strictly turn based on a cell grid. You command a single flagship (a frigate: Sword, Falchion or Firestorm class) against small enemy squadrons, usually outnumbered. Your flagship takes a full turn, then the enemy ships take theirs. There is no fleet campaign layer; progression is the flagship itself, which levels to 12, swaps looted components, and spends scrap won in battle on repairs and post upgrades.
- Movement has momentum. The speed stat is movement points per turn, and manoeuvrability is defined as how many cells the ship must travel before it may turn 45 degrees. Big ships plan their lines; nothing pivots for free.
- Facing is the game. Weapons sit in facing slots (prow, port, starboard), so the standard attack run is lance fire forward, close for the forward macro cannons, then swing past for a broadside. Shields enforce the same lesson: four sectors, one per side, each with an independent charge. Above half charge a sector absorbs all or half of incoming damage; below half, half or none; a depleted sector protects nothing until restarted.
- Torpedoes have flight time. A launched salvo keeps travelling on later turns under its own movement with limited turning, so torpedoes are aimed at where the target will be in roughly two turns. They can be sidestepped precisely because they cannot turn tightly, and their target is only chosen on the turn they arrive, so a salvo herds enemy movement even when it misses. The Torpedo Control post ability hands you control of the nearest salvo launched on an earlier turn and grants it extra movement.
- Six officer posts carry the tactics. Each post represents a major ship system, is staffed by a companion whose skills change what it can do, and holds up to two basic abilities on random cooldowns of one to three rounds (one usable per round) plus one ultimate that charges across rounds, with only one ultimate spendable per battle. Named examples: Reinforce Shields, Vulnerability Scan (marks a weak point that takes 30 percent extra damage), Shallow Jump five cells forward, and the Boarding Party ultimate, which starts fires and can cripple the target's engines for a round. System damage is tied to stations: the scan finds the weak point, the boarding party breaks the engines.

Steal, mapped to Voidsworn:
- Small fleet activation weight. One ship taking a full turn carries a whole battle when every system on it is a choice. Voidsworn activates several ships per round; each activation should feel this dense, and if it cannot, that is the argument for fewer, heavier ships per side.
- Arc discipline with per facing shields. A shield that dies on one side only is what turns a facing diagram into a resource.
- Torpedo flight time as moving terrain. Multi turn travel with a limited turn rate makes a weapon into a threat area the enemy must route around, not a dice roll with a missile picture.
- System effects tied to posts. Let admirals and officers own the crits (this post can cripple engines, that one can mark a weak point), which is Voidsworn's admiral layer doing mechanical work instead of narrating.
- Boarding as a verb. A post ability with range, cooldown and consequences, not a cutscene and not a separate minigame.

Study it:
- The Space Combat page of the Rogue Trader wiki, which lists every post ability, the shield sector rules and the component system: https://roguetrader.wiki.fextralife.com/Space+Combat
- Licence and IP flags: Warhammer 40,000 is Games Workshop IP and Owlcat's game is a licensed product. Study the mechanics and import nothing: no names, terms or fiction. This matters doubly here, since the council audit already flagged borrowed 40k terms in Voidsworn's data.js for purge.

### Battlestar Galactica Deadlock (Black Lab Games / Slitherine)

Turn structure: WEGO, true simultaneous turns. Both sides issue orders to every ship, then End Turn resolves both fleets at once in real time. Fleets run to seven ships, with armour facings, subsystems, squadrons, and a per ship posture choice (attack or defence stance) set each turn. Between turns the battle can be replayed and scrubbed frame by frame. Campaign: a linear thirteen mission story campaign run from the Daidalos shipyard, with officers recruited and Quorum of Twelve politics between missions; skirmish and multiplayer use points budgets. Similarity: the closest structural relative for the battle layer, and no roguelike run or persistent fleet damage campaign behind it.

Steal: the per ship posture toggle as a one click stance with real tradeoffs, and the between turn replay as both a learning tool and a cinematic device.

Study it: the game manual (https://cdn-cms.f-static.net/uploads/4405929/normal_604ca81f0259c.pdf) and Slitherine's own description of the WEGO system (https://www6.slitherine.com/news/battlestar-galactica-deadlock-is-out-on-playstation-4-and-xbox-one-08-12-17). IP flag: Battlestar Galactica is NBCUniversal property. Study only.

### Star Hammer: The Vanguard Prophecy (Black Lab Games)

Deadlock's predecessor, and the same WEGO skeleton: at round start you plot a movement trajectory for every ship, the enemy does the same unseen, you press play and both fleets execute simultaneously in real time, then the game pauses for the next round. Its distinction is verticality: several horizontal planes, with ships changing planes at a rate set by their agility (fast ships shift planes easily, capitals barely), and ghosted trajectory projections that flash red where a collision is predicted. A shared energy core is routed between engines, weapons and shields per ship. Campaign: roughly 60 missions with branching paths and scarce reinforcements. Similarity: the plane system is the closest shipped relative of Voidsworn's three delta-v bands.

Steal: trajectory ghosts with collision warnings (show the planned path, mark the danger on it), and energy routing as the per ship stance instead of a posture toggle.

Study it: the Matrix Games manual (https://ftp.matrixgames.com/pub/StarHammer/SH-Manual-%5bPRINT-FRIENDLY%5d.pdf) and the GameWatcher review for the round structure in plain language (https://www.gamewatcher.com/reviews/star-hammer-the-vanguard-prophecy-review/12263).

### Flotilla (Blendo Games, 2010)

The purest simultaneous turn game on this list. Every 30 seconds you issue orders; both fleets then execute them simultaneously in real time for 30 seconds; the game freezes and you order again. Movement is fully three dimensional, ships rotate in any direction, and there are exactly three order types: attack move, flank move (faster, but weapons stay silent until the ship stops), and focus fire (higher fire rate, much slower movement). The single player adventure is a randomly generated run of about 30 minutes, upgrades and artifacts are bolted onto your fleet's ships between encounters, and your captain dies at the end of every adventure, so permadeath is built into the fiction. Hardcore mode removes the order timer. Similarity: the turn engine is a near twin of a WEGO mode for Voidsworn; everything around it is a sketch where Voidsworn has a campaign.

Steal: proof that simultaneous turns need a small verb vocabulary, not more orders. Flank move's speed for silence trade is a complete tactic in one rule.

Study it: the Wikipedia summary is accurate and sourced (https://en.wikipedia.org/wiki/Flotilla_(video_game)) and the Steam page carries the developer's own description.

### Crying Suns (Alt Shift)

Turn structure: pausable real time, not turn based, and the distinction matters. You command one battleship on a hex grid battlefield plus deployable squadrons with rock paper scissors matchups; you target the enemy's hull, weapons or squadron bays, damaged sections generate heat that stalls them until repaired, and officers assigned to ship systems improve those systems in combat. Run structure: a true roguelite. You play a clone of Admiral Ellys Idaho, and death grows a new clone back at Gehenna, so the run reset is fiction. Six chapters of three sectors each, mini bosses, a chapter boss, a fuel and scrap economy, and over 300 events, some offering extra options when you carry a particular Hero. Similarity: the run and the officer to system assignment are close cousins; the battle is a duel, not fleet tactics.

Steal: officers slotted into systems during combat (the Rogue Trader post idea inside a roguelite frame), and a run reset the fiction explains, so permadeath needs no apology.

Study it: the Kickstarter page, where the developers lay the design out themselves: https://www.kickstarter.com/projects/106952529/crying-suns/description

### Halcyon 6: Starbase Commander (Massive Damage)

Turn structure: turn based in the JRPG pattern, not simultaneous. Up to three ships a side, activation order within the round set by ship speed, each ship acting with three or more ship powers plus up to four officer powers, on cooldowns, with some powers costing the ship its next turn. The core system is statuses plus the Exploit rule: one ship applies a status effect, another ship's power exploits it for double damage and consumes it, so combination play is the entire battle. Campaign: a roguelite frame around a starbase you excavate and build up, colonies to defend, research trees, and officers whose class (Science, Engineering, Tactical) gates which ships they may pilot. Similarity: officers, ships and status combos are Voidsworn's admiral layer in miniature, at 3v3 scale with no facing or manoeuvre grid.

Steal: the Exploit contract. A status that another ship cashes in is the cheapest mechanism on this list for making a fleet feel like a team instead of parallel shooters.

Study it: the Rock Paper Shotgun review, which explains the Exploit loop clearly: https://www.rockpapershotgun.com/2016/09/16/halcyon-6-starbase-commander-review/

### FTL: Faster Than Light (Subset Games)

Turn structure: pausable real time, the benchmark the whole subgenre measures itself against. One ship, and the tactics are system management: target individual enemy systems (weapons, shields, engines, oxygen), route a finite reactor between your own systems, and send crew to repair damage, fight fires and repel boarders, because fire and hull breaches are damage that keeps happening until someone deals with it. Run structure: a node map across sectors with a pursuing rebel fleet as the clock, permadeath, scrap spent on upgrades, runs of about an hour. Similarity: no fleet and no turns, but it owns two things Voidsworn wants, system damage as the real target (hull is only the score) and a run with external time pressure.

Steal: damage that creates work instead of only subtracting health, and pursuit pressure on the node map so route choice is a resource decision.

Study it: the launch review at The Artifice walks the pause, targeting and permadeath loop in detail: https://the-artifice.com/ftl-faster-than-light-review/

### Star Traders: Frontiers (Trese Brothers)

Turn structure: turn based with simultaneous orders, verified in the official wiki. Each captain issues move, weapon and talent orders against a Reactor Point budget and both sides resolve together on End Turn. It is always a duel, one ship per side, and distance is a single range band from 5 (farthest) to 1 (boarding close). Weapons and talents are gated by range, crippling hits damage components and kill crew, and closing to boarding range opens a separate turn based crew battle. Campaign: not a bounded run but an open ended captain career, procedurally generated galaxy and characters, 33 captain jobs, 45 hulls, over 350 upgrades, individually recruited crew with jobs, talents, traits and gear, and faction politics with vendettas. Similarity: the scale is wrong for Voidsworn, but the crew layer is the deepest version in this niche of officers as RPG characters, and its order resolution is WEGO thinking at duel scale.

Steal: talents gated by range band, so an ability that only exists at range 2 is itself an argument for a position; and persistent named crew whose talents are the ship's real build.

Study it: the official wiki's Ship Combat page: https://startraders.fandom.com/wiki/Ship_Combat

### Void War (Tundra Interactive, 2025)

Verified and recent: released June 2, 2025 on Steam and itch.io. An FTL shaped roguelite in a techno gothic skin: one ancient starship, a sector and node map, hundreds of randomly generated encounters per run, a commander plus crew recruited from six factions with equippable wargear, weapons, modules and reactor power managed in pausable real time combat in the FTL pattern, upgrade combinations arranged to dismantle enemy ships system by system, and boarding actions fought by your crew. Similarity: the run structure and system damage are kin; it is a single ship game, not fleet tactics. It also carries the sharpest IP lesson in this document: in early 2026 the game was pulled from Steam after a Games Workshop DMCA claim that reportedly came down to a single shoulder pad image, per the developer's account reported by IGN. A game can be mechanically original and still be dragged down by borrowed visual vocabulary.

Steal: combo building as a build language (upgrades arranged into combinations that dismantle specific systems), which gives a run's loot a grammar instead of a pile.

Study it: the community wiki (https://void-war.fandom.com/wiki/Void_War) and the developer's itch.io page (http://tundra-interactive.itch.io/void-war). IP flag: the aesthetic deliberately courts Warhammer 40,000, which is Games Workshop IP; the DMCA episode is the cautionary tale, not a model.

### Tabletop ancestors: Star Wars Armada and Dropfleet Commander

One short entry for the two paper games, because Voidsworn's campaign layer has tabletop DNA. Star Wars Armada (Fantasy Flight, now Atomic Mass Games) is the planning ancestor: in the Command Phase every ship secretly stacks command dials, one per round, as many rounds ahead as its command value (capital ships plan three rounds out, small ships one). In the Ship Phase players alternate activating a single ship: reveal its dial, attack, manoeuvre. A revealed dial can instead be banked as a token giving a weaker version of the same command later. Steal: commitment depth scaled by ship size, and the dial or token choice, full effect now versus weak effect when needed. Dropfleet Commander (Hawk Wargames, now TTCombat) is the layers ancestor: battlegroups alternate activations with order set by strategy cards, ships fight across three orbital layers (Atmosphere, Low Orbit, High Orbit) with only rated ships allowed into the lowest, weapon range is your scan stat plus the target's signature, and acting spikes your signature (firing, launching, special orders), while Silent Running sheds spikes and can drop signature to zero at the cost of not shooting. Battles are usually about landing troops on surface sectors, not just kills. Steal: signature as the price of action, and layers that stay readable because each layer has a job tied to the objective; Dropfleet is the standing proof that three layers work when they are load bearing. Study Armada in the official Rules Reference (https://images-cdn.fantasyflightgames.com/filer_public/3a/13/3a13aa9c-7857-4b98-8a08-5ba9aaaedd89/swm_rules_reference_guide_150.pdf) and Dropfleet in its rulebook (https://www.scribd.com/document/553227712/Desktop-Dropfleet-Rulebook-1-2). IP flags: Star Wars is Lucasfilm and Disney IP; Dropfleet Commander is TTCombat's. Mechanics only.

### The honest verdict on the niche

Count the true simultaneous turn fleet tactics games: Deadlock, Star Hammer, Flotilla. Across roughly fifteen years that is close to the entire genre, and two of the three come from one small studio. Turn based fleet tactics with a run around it adds Halcyon 6 at 3v3 scale and Rogue Trader's single flagship inside a story CRPG, and then the shelf is bare. The crowded shelf nearby is single ship roguelikes (FTL, Crying Suns, Void War), where the fleet is one hull and the tactics are system management under pausable real time. So the exact Voidsworn combination, turn based or simultaneous fleet tactics plus a roguelike run plus admiral progression plus per ship persistent damage, has no famous direct occupant. That cuts both ways: there is no incumbent to be compared against shot for shot, and there is no proven template to copy, which is why this section loots neighbours instead (WEGO from Deadlock, posts and torpedo flight time from Rogue Trader, the Exploit contract from Halcyon 6, layers and signature from Dropfleet). The niche is not empty because the idea is bad; it is empty because each neighbouring genre took one piece of it and stopped.

## 7. Top up (added 24 October 2026): Star Citizen and Squadron 42, graphics and effects only

### Star Citizen and Squadron 42 (Cloud Imperium Games)

This entry is for graphics and effects learning ONLY. It does not add Star Citizen or Squadron 42 to Voidsworn's feel mix. That mix stays BattleTech plus Sins of a Solar Empire 2 plus Rogue Trader space battles, as ruled in CONVERSATION_CONTEXT.md section 9. Nothing here changes it. What follows is what a PC-only Babylon tactics game can steal from the most expensive-looking space game ever made, and what it honestly cannot.

Status as of October 2026, checked against live sources in this pass: Star Citizen is still in Alpha. Alpha 4.10.2 went live on October 9, 2026, and Alpha 4.10.3 was in public test at the time of writing, with server meshing (quasi-dynamic meshing in 4.10) distributing players and locations across servers. Squadron 42, the single-player campaign, opened Steam wishlists on October 10, 2026 with a new trailer and full cast reveal, targeting a Q2 2027 window after a delay from late 2026. The delay reason most outlets report is avoiding competition with Grand Theft Auto VI; treat that reason as reported, not confirmed by CIG in the sources opened here. The Steam listing is reported to specify a 150 GB install and modest minimums (16 GB RAM, 8 GB VRAM GPU baseline); that listing detail rests on news summaries, not on the Steam page itself, which was not opened in this pass. Early backer and creator preview sessions in October 2026 praised cinematic presentation, space combat and character detail, with bugs and polish remaining; those impressions rest on news summaries and community posts, flagged as secondhand.

Steal:

- **A physical light discipline, not a lighting budget.** StarEngine treats the sun as a physical light source, renders PBR throughout, grades through an ACES filmic curve, and simulates eye exposure from a histogram of scene brightness. The lesson for Voidsworn is not the machinery, it is the discipline: one key light per region, fixed exposure per region, no auto-adaptation. That is already the rule in graphics_craft.md; Star Citizen is the proof that it scales to the most demanding space renderer in production, and the warning that breaking it (an exposure shift that changes which ships read) is a gameplay bug, not a look preference.
- **Damage as shader stages on the same hull.** CIG's older damage pipeline, described in its own Comm-Link design notes, stages damage in the shader: clean hull, burn colour, dents, bumps from burnt paint and metal, exposed underlying metal, then holes cut through the hull with dented borders for depth. When a part detaches, squibs and particles fire along the separation edge so the break looks torn, not swapped. For Voidsworn this is the damage states system at near zero geometry cost: per-section darkening, venting and emissive changes driven by section state, exactly as the BattleTech paper doll entry in this pack already proposes, but with the shader staging as the mechanism.
- **Destruction that leaves an afterlife, at two scales.** The incoming Maelstrom system breaks objects physically by material and structural integrity, so a rifle chips a barricade and a grenade launcher razes a structure, and destroyed ships become debris fields rather than vanishing. Maelstrom's ship-wide rollout status is the least certain claim in this entry (see the flag below). The stealable half is already proven in older CIG tech and in Armada 2's hulks: a destroyed ship should persist as a drifting wreck with fires and debris, because a long battle should accumulate visible history.
- **Weapon reads built from rate, bolt, trail and count.** Star Citizen splits weapons into ballistic, energy, distortion and missile families, and the split is visible before it is statistical. Ballistics are slower solid projectiles that partly penetrate shields (20 to 60 percent depending on the shield) and run on ammunition with minimal heat. Energy weapons (laser repeaters at high rate and low damage, laser cannons at medium rate and medium damage, neutron guns at low rate and high damage, tachyon cannons at extremely high velocity and long range, scatterguns dispersing in a cone) are fully absorbed by shields and run hot. Distortion weapons drain shields, including adjacent shield faces, and degrade power systems until the ship goes dark, which is how you disable without destroying. Missiles and torpedoes are rack-launched, guided (infrared by heat, electromagnetic by emissions, defeated by flares and chaff), and read by visible count and smoke trail. The lesson is the same five axes as the BattleTech entry (colour, trail, count, smoke, timing), applied to a four-family split Voidsworn can copy with template families instead of bespoke art per weapon.
- **Capital presence sold by reference, not by numbers.** A capital ship reads as huge because something small sits next to it: an escort on approach, a fighter launching from its bay, a station docking arm, a planet behind it. Star Citizen sells this with seamless nesting (object containers and local physics grids let a player walk from a hangar to a bridge with no loading screen, and ships sit inside ships inside rotating stations). Voidsworn has no interiors and no walking, so the transferable part is camera discipline only: frame every capital event with a smaller ship or station element in shot for scale, and never present a capital alone against empty space.
- **Squadron 42's cinematic grammar, minus the budget.** The campaign's selling point is full performance capture (face and body) woven into gameplay rather than restricted to cutscenes, with a cast including Mark Hamill, Gary Oldman, Gillian Anderson, Henry Cavill and Mark Strong, as a spiritual successor to Wing Commander. The transferable grammar is not the capture, it is the direction: the capital event beat already specified in the beauty corner spec (HUD fade, letterbox, slow push-in, 3.5 second arrival, release) is exactly this grammar at tactics-game cost. Character presence in Voidsworn comes from admiral portraits and voice lines, not from capture, and the entry says so plainly so nobody budgets for the wrong thing.

Rendering foundation, in brief:

StarEngine descends from CryEngine through Amazon Lumberyard, and CIG has rebuilt it in place since. The load-bearing ideas, per Digital Foundry's technical coverage and the engine's own feature lists: 64-bit world coordinates (Digital Foundry puts the playable space at 536,870,912 times larger than a 32-bit float space) with camera-relative rendering so the renderer keeps 32-bit precision and pays no performance hit for the large world; object containers that nest planets, stations, cities and ships with their own local frames; local physics grids so ships move inside moving ships; procedural planets (Planet Tech v5 in current patch notes); PBR with GGX normal map filtering; physically based bloom and atmosphere; volumetric fog and clouds with light shafts; a GPU particle system built for the engine (CIG's own claim for the older damage pipeline is 10 to 100 times more GPU particles than CPU particles for the same cost; that multiplier is CIG marketing, not a measured figure); tiled lighting upgrades; a pooled shadow system; real-time environment probe capture; and temporal upscaling through DLSS, FSR and CIG's own TSR. The Vulkan client has been discussed for years and was still described as future work in the 2023 Digital Foundry coverage; do not assert it as shipped. Server meshing is the multiplayer half of the same scale story and has no Voidsworn equivalent: it distributes players across servers, and a single-player tactics game needs none of it.

What Voidsworn can steal, mapped to its own systems:

1. **Shader-staged damage states, mapped to damage states.** One hull, five shader stages (clean, scorched, dented, exposed metal, holed), driven by per-section state, plus separation-edge squibs and debris when a section dies. Cost: shader work and one damage mask per hull, no new geometry. Does not transfer: Maelstrom physical fracturing, which needs a physics engine, material simulation and a tech art team. Voidsworn fakes the break with particles and decals; it must never promise real fracturing.
2. **Four-family weapon reads, mapped to the effects language.** Ballistic (tracer, slower, punch through), energy (bolt, faster, shield first), distortion (crackling discharge, shield drain plus system dimming, the disable-without-destroy verb), missile (rack count visible, smoke trail, guided arc). Each family gets fixed rate, bolt size, velocity, trail and impact, and no family borrows another's look. Does not transfer: per-weapon bespoke art and CIG's weapon count. Voidsworn needs template families with per-weapon substitutions, the way Empire at War's particle templates work.
3. **The directed capital event, mapped to capital event presentation.** HUD fade, letterbox, slow push-in, capital framed against escorts or a planet for scale, release back to play. This is already specified in the beauty corner spec; this entry is its justification, not a new requirement. Does not transfer: performance capture, cutscene animation, or any real-time character acting.
4. **Fixed exposure and a physical key light, mapped to lighting.** One sun per region, ACES grade, fixed exposure per region, bloom threshold set so plates never bloom. This confirms the graphics_craft rule rather than changing it. Does not transfer: real-time probe capture, volumetric clouds at CIG fidelity, or eye-exposure simulation. Babylon approximations (baked probes, fog, fixed exposure) are the honest ceiling.
5. **Scale reference in every capital shot, mapped to camera.** No capital is ever framed alone. A smaller ship, a station element, or a planet limb sits in frame as the scale anchor, and fleet view keeps a scale anchor in the corner of the shot. Does not transfer: 64-bit world space, seamless interiors, multi-crew, or any sense of walking the ship. The camera does all the scale work, because there is nothing else to do it.

Shield presentation, worth its own note because Voidsworn already has per-facing shields:

Star Citizen shields are face-based: energy fire is fully absorbed by the struck face until it drops, ballistic fire partly penetrates, and distortion fire drains the struck face plus adjacent faces. The visual consequence is that a shield hit reads as a local event, not a whole-ship flash: the impact point flares, the face shimmers, and the rest of the ship stays clean. That maps directly onto Voidsworn's shield ripple language, with one addition worth stealing: adjacent-face bleed for distortion-style weapons. A distortion hit in Voidsworn should visibly dim the neighbouring facings as well as the struck one, so the disable-without-destroy verb reads at a glance instead of living in a tooltip. What does not transfer is the bubble itself: Star Citizen renders a hull-hugging shield volume, which costs a transparent shell pass per ship. Voidsworn's ripple on the hull surface is the cheaper equivalent, and the ripple shape (already faction-coded in the art direction doc) carries the identity the bubble would have carried.

Atmosphere as backdrop, the cheapest steal in this entry:

StarEngine's atmosphere work (physically based scattering, volumetric clouds with light shafts, ground fog that follows terrain, dynamic weather, gas clouds in asteroid fields listed as Space Fog) exists to make empty space feel like a place. Voidsworn does not need any of it simulated. It needs the backdrop lesson: a background plate that carries weather and atmosphere (a storm plate with lit cloud tops, a gas cloud plate with light shafts, a dead star plate with hard rim light) does more for presence than a sharper ship model, because the backdrop is in every shot and the ship is in one. The Babylon translation is layered transparent planes plus fog plus a fixed key light, all inside the existing 40 percent luminance cap. The cap is what keeps this steal honest: Star Citizen can afford a bright sky because its ships are lit by the same sun; Voidsworn plates must stay dimmer than an unlit hull facet, or the atmosphere eats the tactics.

Squadron 42's structure, and what it means for a tactics game with no walking:

The trailer coverage describes a campaign built from space combat, first-person sections, ship customisation, off-duty crew interactions, a hacking mini-game, and narrative choices that feed back into encounters. None of that structure transfers to a hex tactics game, and this entry does not pretend otherwise. What transfers is the pacing idea underneath it: quiet beats between loud ones. A campaign that only ever shows combat exhausts its own spectacle, while a campaign that alternates a capital arrival, a briefing beat (admiral portrait plus a line of dialogue), and a battle makes each battle land harder. Voidsworn already has the pieces for the quiet beats (portraits, the campaign layer, the end card); the Squadron 42 lesson is to treat them as part of the presentation budget, not as menus between the real game.

Study it:

- Digital Foundry's Star Citizen technical coverage, on seamless scaling from gas giants to surface detail, 64-bit coordinates and object containers: https://www.digitalfoundry.net/articles/digitalfoundry-2020-star-citizen-tech-focus-alpha-3-point-8
- StarEngine feature list (community wiki, so secondhand where it is not corroborated by Digital Foundry or CIG material): https://starcitizen.tools/Star_Engine
- CIG's own damage pipeline design notes, for shader-staged damage and separation-edge effects: https://starcitizen.tools/Comm-Link:The_New_Damage_System
- Maelstrom summary (community summary of CIG material, secondhand; the rollout status flag below applies): https://wildknightsquadron.com/what-we-know-maelstrom/
- Ship weapon families (community wiki, secondhand on fine stats, reliable on the family split): https://starcitizen.tools/index.php?title=Ship_weapons&oldid=31383
- Current patch state, Alpha 4.10.2 live notes and Alpha 4.10.3 public test notes: https://timesaver.gg/blog/star-citizen-alpha-4-10-2-patch-notes-discovery-month and https://robertsspaceindustries.com/spectrum/community/SC/forum/190048/thread/star-citizen-alpha-4-10-3-ptu-patch-notes

What to re-check after Squadron 42 ships:

This entry is written before the game exists. When Squadron 42 releases in its Q2 2027 window, three claims in it deserve a re-check against the shipped game before Opus treats them as settled: whether the campaign's cinematic presentation holds up outside trailers and preview sessions, whether capital ship framing in missions matches the trailer grammar described here, and whether Maelstrom has reached ships at all. Until then, the entry's stance is deliberate: steal the grammar and the shader techniques, which are proven in Star Citizen's live Alpha, and treat everything Squadron 42 specific as a trailer claim.

Sourcing and honesty flags:

- Least certain claim in this entry: Maelstrom's current ship-wide status. Community summaries describe it as in development since about 2016 and planned for both games, the 1.0 roadmap lists it for structures, and engineering-system preview coverage explicitly says armour is faked for now and the full Maelstrom armour system comes later. Whether any Maelstrom ship destruction is live in October 2026 is not established by the sources opened here, so this entry claims only the direction and the older shader damage pipeline, never a shipped Maelstrom.
- Secondhand throughout: the Star Citizen wiki (starcitizen.tools) is a community wiki, and several of its pages carry their own outdated-information warnings. Use it as a map, not as gospel, and prefer Digital Foundry and CIG's own Comm-Link notes where they cover the same ground.
- Pre-release material: Squadron 42 is unreleased. Everything about its campaign structure, performance and final scope rests on trailers, CIG statements and preview sessions, not on a shipped game. Check any single mechanic against the shipped game after Q2 2027 before treating it as fact.
- Licence and IP flags: Star Citizen, Squadron 42, StarEngine and all ships, characters, names and fiction are Cloud Imperium Games property. StarEngine is not for sale and not open source. Adopt techniques (shader-staged damage, weapon family reads, capital framing, fixed exposure), never reuse names, designs, fiction or assets. No code, shader or asset from these games transfers into Voidsworn.

## Start here: the eight highest value items, in order

1. Sins 2 mod tools repo and dev journals. Budgets, texture channel layout, and combat geometry, all from the closest reference game. Read first, before the next hull or texture pass.
2. Babylon.js Playground examples via the engine repo README. Working beam, shield, particle, and post-processing code in the actual engine, Apache-2.0.
3. Homeworld 3 art director interview. One sitting, and it hands you the hull striping class code, the cheapest readability system on this list.
4. webgl-noise. One MIT library that unlocks shield shimmer and nebula work in ShaderMaterial and Node Material alike.
5. Kenney Space Kit plus Skyboxes Space. CC0 placeholders that unblock camera, effects, and background work in the first week, with zero licence risk.
6. Endless Space 2 Battle Overview GDD (top up, section 4). One design document that hands over the Battle Director and the five phase battle structure: the cheapest route to battles that feel directed, not just rendered.
7. Starsector modding hub (top up, section 4). The hull, variant, skin data split and the F8 live reload tuning loop, which is the closest model on this list for how Voidsworn's own data layer should behave.
8. Rogue Trader wiki, Space Combat page (second top up, section 6). The feel benchmark Ryan named himself: six officer posts, per facing shield sectors, torpedoes with multi turn flight time, all on one page. Read it before the next battle rules pass.
