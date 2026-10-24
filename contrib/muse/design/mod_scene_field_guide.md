# Mod scene field guide: what the wider modding world has already solved

From Rey (Muse), Oct 24, 2026. Commissioned by Ryan as the wide pass: all the mod repos and sites, space games, tactics games, roguelikes, and the big popular modded games (Cyberpunk, Red Dead Redemption 2, FTL, Mass Effect, Skyrim, Rogue Trader itself, Total War: Warhammer, Halo, Minecraft), mined for code examples, asset approaches, effects and open files and sounds that fit Voidsworn's open problems. Companion to GRAPHICS_REFERENCES.md in this folder: that document is reference games and repos to study; this one is mechanisms to steal and assets to grab, indexed by problem.

## The one pattern (read this even if you read nothing else)

Three research passes across very different scenes converged on the same three rules, because every durable mod ecosystem learned them the hard way. (Caveat, per the READING_PLAN errata: the three passes were briefed with the same problems, so their agreement is weaker evidence than three independent discoveries would be.)

1. **Stable string ids are forever.** RimWorld's rule is that a defName is patched and extended but never renamed. Slay the Spire mods prefix their ids for the same reason. Total War's database keys carry the same discipline. Voidsworn's save bricking id class (chair item 1) is exactly the failure these rules exist to prevent.
2. **Changes ship as deltas merged in a declared order, never as copied files.** Mass Effect's ConfigDelta files, FTL's .append convention, Skyrim's plugin load order, Darkest Dungeon's load order as API, Total War's partial tables: the mechanism differs, the shape is identical. Hull variants and balance patches want to be deltas over one base definition.
3. **A checker lives in the build.** RPFM ships diagnostics that hunt broken foreign keys in Total War tables. That is the checkpack idea, except the ecosystem treats it as core tooling rather than an optional extra.

Supporting evidence for all three is throughout Part 1 and Part 2. If Opus adopts nothing else from this document, adopting the pattern is the win.

## Top finds

- **Endless Sky's save integrity pair** (Part 2): save files record the names of all installed plugins, and a dedicated deprecated ships file keeps removed ships defined because old saves may still reference them. A retirement home for dead ids. This is the complete, shipped answer to the save brick class.
- **Mass Effect ConfigDelta** (Part 1): a closed game with one monolithic config got a real mod pipeline by merging small named delta files into a fresh coalesced file, install order enforced by tooling. The most transferable single mechanism in the pack.
- **Starsector's F8 live reload and .skin files** (Part 2): inside the combat simulator, F8 re-reads the JSON and CSV content live, and faction reskins are .skin files over shared geometry rather than duplicated hulls. The tuning loop and the paint answer in one game.
- **Cogmind's particle templates** (Part 2): every effect is an external text script, one template generates a family of variants by substituting colour, speed and lifetime, and particle data reloads in the running game because restart per tweak was too slow. Weapon families want exactly this.
- **Halo's multipurpose map** (Part 1): one bitmap whose channels carry faction colour mask, self illumination, reflection and detail. A concrete, proven answer to the faction paint problem the ship kit work order is solving.
- **Sonniss GameAudioGDC bundles** (Part 3): production grade sound effects, gigabytes per yearly bundle, lifetime royalty free with no attribution, usable in commercial projects. The only hard limits: sounds must sit inside a finished project and raw files cannot be redistributed. This closes most of the sound gap in one download.
- **ZzFX and JFXR** (Part 3): UI and light weapon sounds synthesized in code, exportable, free to use without restrictions. Zero shipped audio files, zero licence friction, faction variants are parameter changes.
- **Effekseer** (Part 3): MIT licensed particle authoring that bakes flipbooks (explosions, muzzle flashes, engine trails), so effects stop depending on found sprite sheets that happen to match the palette.

## Index by Voidsworn problem

- **Save integrity against renamed ids:** Endless Sky (deprecated file, plugin names in saves), RimWorld (defName is forever), Total War (key stability and RPFM diagnostics), Slay the Spire (mod prefixed ids). Part 1 Skyrim and Total War, Part 2 throughout.
- **Content as data:** Cyberpunk TweakDB record inheritance, Halo Blam tags, Minecraft data packs, Wesnoth WML, Cataclysm JSON, OpenXCom rulesets, Darkest Dungeon file overrides. Parts 1 and 2.
- **The tuning loop:** Starsector F8 reload, Cogmind dynamic particle reload, RimWorld TweakValues. Part 2.
- **Ship kit, paint and materials:** Halo channel packing, Starsector .skin, Material Maker's community library, Quaternius Modular Sci-Fi MegaKit and KayKit Space Base Bits (both CC0). Parts 1 to 3.
- **Effects:** Cogmind templates, Effekseer, godotshaders.com standouts (per post licences, check each), three.js examples as MIT ports, Babylon Node Material as the native route. Part 3, plus Part 2's Cogmind.
- **Sound:** Sonniss bundles, ZzFX and JFXR, the Freesound CC0 filter strategy (about half the library; never ship BY-NC or Sampling Plus), NASA audio under its media guidelines. Part 3.
- **UI text and icons:** Google Fonts candidates (Orbitron verified; Rajdhani, Share Tech Mono, Audiowide, Michroma), game-icons.net (CC BY 3.0 default with per author credit; two CC0 authors named), CC0 and CC BY UI sound packs. Part 3.

## Honesty notes

Each part flags its own gaps in place; the load-bearing ones: REDmod specifics are confirmed against CD Projekt Red's official modding support page (Oct 24, 2026 sweep); the Skyrim entry now rests on the opened SKSE site (AE build 2.3.1); Rogue Trader's data internals are inferred from mod behaviour, with no Owlcat developer document found; Hyperspace's licence is still not named in its source material (Oct 24, 2026 sweep: no licence file found); ESA audio terms went unverified and no terms are asserted for it; Materialize is GPLv3 with safe outputs (confirmed via the vendor FAQ, Oct 24, 2026 sweep). Licences are stated in plain words per entry, and anything free to download but not free to ship is flagged where it sits.

The three parts run about 9,300 words between them.

## Part 1: The big heavily modded games

Eight proprietary games with the deepest mod scenes in the industry, mined for mechanisms Voidsworn can steal. Voidsworn is a Babylon.js hex fleet tactics roguelite in one HTML build, with content in JS data files and persistent campaign saves. The recurring Voidsworn problems these entries speak to: content as data, hull manifests, save integrity against renamed IDs, effect and material pipelines, and tuning without code. Every game here is study only. Nothing below licenses reusing anyone's assets, code or data.

### Cyberpunk 2077: TweakDB, REDmod and WolvenKit

Almost all of Cyberpunk's tuning lives in TweakDB, a database of typed records and flat values addressed by dotted string IDs such as `Items.Preset_Katana_Default` and `BaseStats.ReloadTimeBonus`. Records inherit from base records and override individual fields, and stat changes are themselves data: a weapon mod is a record holding modifier objects typed Additive or Multiplier against named stats. REDmod, CD Projekt Red's official free modding DLC, compiles each mod at deploy time, scripts into a modded script blob and tweak files into a modded TweakDB blob, and it manages load order for those mods (legacy archive mods cannot be order managed). WolvenKit, the community editor, includes a Tweak Browser that flattens a record's inherited properties into a complete override file you can edit. TweakXL lets authors write tweaks as YAML, and Cyber Engine Tweaks allows live, non persistent value editing in game for fast experiments.

**Steal this.** First, inheritance for hull variants: a variant hull should be a record that names a base hull and overrides three or four fields, not a copied block in data.js, which is exactly how TweakDB presets work and exactly what a hull manifest wants to be. Second, modifiers as data: boons, admiral perks and difficulty settings expressed as named modifier entries against named stats, applied by ID, so balance tuning never touches code. Third, steal the live edit loop: a debug overlay that changes data values mid session and exports the session's changes as a small patch file. Fourth, the load order rule: later layers override earlier ones field by field, and every record keeps one stable string ID for its whole life, because saves and other records point at that ID.

Study it: the community wiki's TweakDB walkthrough at https://wiki.redmodding.org/cyberpunk-2077-modding/for-mod-creators-theory/tweaks/tweaks/browsing-the-tweak-database and the TweakXL YAML format at https://github-wiki-see.page/m/psiberx/cp2077-tweak-xl/wiki/YAML-Tweaks

Licence and IP: Cyberpunk 2077 and REDengine are CD Projekt Red property. REDmod and the wiki are free to learn from. The game's records, assets and text are not yours to reuse.

### Skyrim: plugins, load order and the Bashed Patch

Skyrim's content is records in plugin files, each record identified by a FormID, loaded in a strict order where the last plugin to touch a record wins that whole record. The Creation Kit is Bethesda's official editor over that record model, Papyrus is the script language attached to records, and SKSE (the Skyrim Script Extender) extends the script system so deeply that most serious mods depend on it. LOOT sorts plugins using a community maintained masterlist of ordering metadata. The famous tool is Wrye Bash and its Bashed Patch: a generated plugin, rebuilt whenever your mod set changes, that merges the parts of many plugins that would otherwise clobber each other, above all leveled lists, so ten mods can all add items to the same loot table. The STEP community's long running critique adds the sharp edge: the patch is only as good as its import settings, and telling it to import names or stats makes it copy whole records and silently revert careful edits. A merged patch must be scoped and inspected, not trusted blindly.

**Steal this.** Voidsworn's content living in a few big JS files is the Skyrim problem at file scale: whoever edits a table last wins, silently. Build the Bashed Patch habit into the build. Data contributions should be declared as partial operations (add this row, patch this field on this hull), merged in a declared order by a build step that prints every collision it resolved. Keep an explicit ordering manifest rather than letting file names imply order. And take the FormID discipline seriously: content IDs are permanent, never recycled, because saves and cross references point at them.

The second Skyrim lesson is ENB. ENBSeries, by Boris Vorontsov, injects post processing (ambient occlusion, bloom, depth of field, colour correction) as an external layer configured by plain files, and a whole preset scene grew around it. The look of the game became data. Voidsworn's Babylon post pipeline should work the same way: one named look preset object per faction or sector, holding bloom, grading and fog values, editable without touching render code.

Study it: the STEP forum's Bashed Patch critique at https://stepmodifications.org/forum/topic/5195-bashed-patch-does-more-harm-than-good/ , its ENBSeries notes at https://stepmodifications.org/forum/topic/634-enbseries-by-boris-vorontsov/page/9/ and a Wrye Bash usage guide at https://vectorlinux.com/how-and-when-to-use-wrye-bash-sse/

Licence and IP: Skyrim, the Creation Kit and Papyrus are Bethesda and Zenimax property. SKSE and Wrye Bash are community tools with their own licences. Study the architecture, ship none of their content.

### Mass Effect Legendary Edition: ME3Tweaks and the coalesced problem

BioWare shipped no mod support, and the trilogy kept much of its tuning in Coalesced.bin, one binary bundle of INI files. Early mods replaced the whole bundle, so mods destroyed each other. The community fixed this in layers. ME3Tweaks Mod Manager (M3) installs mods as DLC style folders, keeps backups, validates packages with a suite of deployment checks, and enforces install order as a correctness rule: content mods first, texture mods after, because texture modding rebuilds a texture index that desyncs if content changes afterwards, and the manager warns you if you try it in the wrong order. Later versions merge small ConfigDelta files from many mods into a fresh coalesced file for the first game, so ten mods can each change a few lines of the same config. DLC mods go further and package their config edits inside their own DLC folder so they compose instead of overwriting the global file. Polygon's history of the scene records the other lesson: the community nearly died of gatekeeping and hostile tooling friction, and revived when the tools became approachable.

**Steal this.** ConfigDelta is the single most transferable idea in this cluster. Any Voidsworn override system (balance hotfixes, faction variants, event modifiers) should ship as small named deltas, sets of key changes that a merger combines in a defined order, never as copies of whole data files. Copy M3's other habits too: install and load order enforced by tooling with warnings, automatic backups before anything is applied, and packaging checks that fail loudly. The direct Voidsworn analogue is a content validator run at build time that refuses to ship when a data file references a hull, weapon or effect ID that does not exist.

Study it: ME3Tweaks Mod Manager on Nexus at https://www.nexusmods.com/masseffectlegendaryedition/mods/2?tab=description , the Legendary Explorer wiki guide to DLC coalesced mods at https://github-wiki-see.page/m/ME3Tweaks/LegendaryExplorer/wiki/How-to-make-your-LE2-Coal-Edits-into-the-more-compatible-DLC-Mods and Polygon's scene history at https://www.polygon.com/23612797/mass-effect-legendary-edition-mods

Licence and IP: Mass Effect is EA and BioWare property with no modding licence granted. ME3Tweaks tools are community software. The pipeline design is the lesson, not their code or the game's data.

### Red Dead Redemption 2: Lenny's Mod Loader and the virtual file system

Rockstar's RPF archives are closed, enormous and hostile to edit. Lenny's Mod Loader (LML, by LMS) sidesteps them entirely. It is a virtual file system layer loaded as vfs.asi that intercepts the game's file requests at runtime. Drop replacement files into the lml folder's replace tree, mirroring the game's internal paths, and the loader serves your file instead of the archived original, which is never modified. A stream folder provides loose, quick replacement for testing. Mods that add content rather than replace it ship an install.xml manifest telling the loader which files to add or replace, and LML can even take meta files (the game's YMT data) as editable XML and convert them back on load. A Mod Manager UI lists and toggles installed mods, and uninstalling is deleting a folder. Modding the game became safe because the original files are untouchable by design.

**Steal this.** The overlay principle, applied at the level of data IDs instead of files. Voidsworn ships as one HTML build, but its data loader can still resolve every hull, weapon and boon through an ordered stack of sources: base data first, then campaign pack, then any user or event tuning layer, taking the topmost definition of each ID. That gives you downloadable content behaviour and safe experiments inside a single file. Also steal the manifest: one small file per content layer declaring what it adds and what it replaces. That manifest is what a validator reads, and it is what a save should record (which layers, at which versions, were active when this campaign was written), which is the difference between a save that breaks mysteriously and one that can explain itself. Finally, the plaintext round trip: LML modders edit binary data as XML. Keep an export that dumps any Voidsworn data table back to readable text for diffing and review.

Study it: the official download page at https://www.rdr2mods.com/downloads/rdr2/tools/76-lennys-mod-loader-rdr/ and the Nexus comprehensive modding guide's LML chapters at https://www.nexusmods.com/reddeadredemption2/mods/6011

Licence and IP: RDR2 and the RAGE engine are Rockstar and Take Two property, and Rockstar's terms restrict modding to single player. LML is one author's freeware. Learn the pattern, reuse none of the game.

### Halo: Blam tags, content as typed data objects

In Bungie's Blam engine, nearly everything is a tag: a typed data object with a class (shader, bitmap, vehicle, weapon, effect, physics) and a published field layout. A vehicle tag, as documented field by field on the c20 wiki, holds floats and bounds for AI steering and throttle, and TagDependency fields that point at other tags for sounds, effects and material behaviour. Maps are compiled cache files full of tags. Guerilla is the tag editor, the Editing Kits released for the Master Chief Collection descend from Bungie's internal tools, and Assembly, the open source tool from XboxChaos, edits tags inside cache files and can poke changed values into a running game for live testing. TagTool exists to port tags between engine versions. The c20 documentation also shows the asset trick worth stealing outright: the multipurpose map, one bitmap whose separate channels are masks for colour change, reflections, self illumination and detail, so a single texture carries a model's whole material behaviour, including team or faction colours and lit windows.

**Steal this.** Make the hull manifest a tag. A typed record with a fixed schema, where fields have declared types and every mesh, material, effect and sound reference is an explicit dependency. Once references are explicit, a tool can walk the dependency graph and catch a missing mesh or effect before the game ships, which is the same service RPFM diagnostics and M3's checks provide in their scenes. Steal channel packing for hull textures next: one multipurpose texture per hull whose channels mask faction paint zones, emissive lights, wear and detail replaces several separate textures and makes faction recolouring a data change, not an art change. And steal Assembly's poke: a dev mode that adjusts a hull's stats mid battle to feel a balance change immediately, rather than rebuilding and replaying.

Study it: c20 tag documentation at https://c20.reclaimers.net/h1/tags/object/unit/vehicle/ and https://c20.reclaimers.net/h1/tags/shader/shader_model/ , the Reclaimers overview of the Halo 4 editing kit, Assembly and TagTool at https://reclaimers.net/h4/ and Assembly itself at https://github.com/XboxChaos/Assembly

Licence and IP: Halo and the Blam engine are Microsoft and 343 Industries property. The MCC editing kits are free for Halo modding only. Assembly is open source under its own licence. Tag schemas and the channel packing pattern are ideas; Halo's tags and assets are not.

### Minecraft: data packs, resource packs and lighting as data

Minecraft is the one game here where content layering is an official, documented feature. A data pack is a folder or zip identified by a pack.mcmeta file, a small JSON manifest carrying a description and a pack format version number. Inside, a namespaced data tree holds JSON definitions for recipes, loot tables, advancements, functions, tags and world generation. A resource pack has the same manifest and an assets tree of models, textures, sounds and language files. Packs stack in a player visible order, higher packs override lower ones file by file, data packs reload with a command and no restart, and the pack format number gates which game versions a pack can run on, with the game warning or refusing when the number is wrong. The shader scene adds the rendering half: OptiFine, and then Iris (a Fabric mod, normally paired with Sodium for performance), load shader packs in a standard GLSL format, so lighting, shadows, water and fog are pack supplied data and shader code, switchable in game, with settings surfaces generated from configuration the pack itself declares.

**Steal this.** Three things. First, the versioned manifest: every Voidsworn data layer and every campaign save should carry a format version that the loader checks, with a migration path when it bumps. When a hull ID has to be renamed, a rename map applied at save load is the same machinery as Minecraft's version gating, and it is the difference between a renamed ID breaking old campaigns and merely updating them. Second, namespaces: prefix every content ID with its source (core, faction, campaign), so content can grow without collisions. Third, hot reload for tuning: a dev build that reloads its data tables on a keypress, the way /reload works, shortens every balance iteration. The Iris lesson rides along: expose effect settings as data with generated controls, so per sector look presets and a graphics quality ladder are configuration, not code paths.

Study it: the official Minecraft Wiki on the pack manifest at https://minecraft.wiki/w/Pack.mcmeta and its data pack tutorial at https://minecraft.wiki/w/Tutorial:Creating_a_data_pack , plus a practical overview of the Iris and OptiFine shader ecosystem at https://guide-minecraft.com/shaders/

Licence and IP: Minecraft is Mojang and Microsoft property. Data packs and resource packs are officially supported for players' own content, and the wiki documents the formats. Iris is an open source community project; its official site is irisshaders.dev (irisshaders.org and iris-shaders.com are copycat domains, not the project). Minecraft assets and code stay theirs.

### Total War: Warhammer: the game is its database

A Total War game is, to a first approximation, its DB tables. data.pack holds hundreds of tables (land_units_tables, main_units_tables, factions_tables and hundreds more) where each row is a unit, building, effect or faction, keyed by a unique string key, with columns that reference keys in other tables. Creative Assembly's official Assembly Kit splits the work into TWeak, which edits the database and unit variants, and BOB, which builds finished pack files. The community standard tool is Rusted Pack File Manager (RPFM, by Frodo45127), which edits packs, builds a dependency cache from the Assembly Kit data, and runs a diagnostics window that flags broken keys, the single most common cause of mod crashes. A mod is simply a pack containing partial tables: only the rows you changed, loaded after the base data and overriding by key. A decade of that architecture produced total conversion mods that rebuild entire factions, new units, new rosters, new campaign rules, by shipping table rows and Lua scripts rather than code changes.

**Steal this.** This is the closest living proof of Voidsworn's own architecture, since Voidsworn content is also rows in tables keyed by string IDs, and the lessons transfer almost word for word. Partial overrides by key: a balance patch or a new faction pack should ship only changed rows, merged by key at load, never a copied table. Diagnostics are not optional: RPFM's broken key warnings are the model for a Voidsworn data linter, run at build time, that verifies every hull, weapon, boon, effect and admiral ID referenced anywhere actually exists. Keys are forever: total conversions survive official patches because Creative Assembly keeps keys stable and modders treat them as public API, and a renamed key breaks campaign saves there exactly as a renamed hull ID would break a Voidsworn campaign. Finally, the TWeak and BOB split: keep an authoring format that is readable and diffable, and a shipped format that is compact, with a build step between them.

Study it: RPFM releases and source at https://github.com/Frodo45127/rpfm/releases , a beginner guide covering the Assembly Kit and Pack File Manager workflow at https://steamcommunity.com/sharedfiles/filedetails/?l=swedish&id=702343155 and the RPFM manual's diagnostics and dependency features at https://manuals.plus/m/ffae3c467248719c054bf9e0652ec728814e2a76e2e2fc7a0ac1eb2f5608506b

Licence and IP: Total War and Warhammer Fantasy are Creative Assembly, Sega and Games Workshop property. The Assembly Kit is provided for modding those games. RPFM is open source community software. The table architecture is the lesson.

### Warhammer 40,000: Rogue Trader: blueprints, Toy Box and the save doctor

Owlcat builds its CRPGs on enumerable content: items, feats, abilities, quests and units exist as blueprint data with stable IDs, which is why the game's modding works the way it does. Owlcat shipped real support, including the Owlcat Modification Manager and Steam Workshop integration, and mods packaged for it can alter blueprints, quests and localisation. Alongside that sits the community track: Unity Mod Manager hosts Toy Box, by Narria, descended from the Bag of Tricks and Toy Box mods for Owlcat's Pathfinder games. Toy Box offers 500 or more cheats, tweaks and quality of life tools: editing party stats, inspecting quest state, and, most instructively, searching the game's entire catalogue of items, feats and features and adding any of them to a character. That search box is only possible because every piece of content in the game is listable data. Its other famous use is repair: players run it to unstick broken quests and fix campaign states that patches left behind.

**Steal this.** First, enumerable content as a design rule: because Rogue Trader's content is named data, a Toy Box style debug panel is nearly free once the data is organised, and Voidsworn's tables already qualify. A panel that searches all hulls, weapons, boons and encounters, spawns any of them, and inspects campaign flags is simultaneously a balance tool, a QA tool and a save doctor. Build it early rather than after the first corrupted campaign. Second, the save doctor lesson itself: long roguelite campaigns will eventually meet a renamed ID, a removed boon or a stuck event flag, and the tool that lists what a save references, and reports which of those references no longer resolve, is the tool that saves the run. Third, the dual track: Owlcat documents and supports its official route while tolerating the community one, and documentation is what let both flourish. For a small project the analogue is simply writing down your data formats as they stabilise.

Study it: Toy Box on Nexus at https://www.nexusmods.com/warhammer40kroguetrader/mods/1 and Fextralife's guide covering both Unity Mod Manager and the Owlcat Modification Manager at https://fextralife.com/how-to-install-warhammer-40000-rogue-trader-mods/

Licence and IP: Rogue Trader is Owlcat's game set in Games Workshop's Warhammer 40,000, and both layers of IP are strictly theirs. Toy Box is a community mod. The blueprint pattern and the save doctor idea are transferable; nothing else is.

### The pattern across all eight

Strip the eight scenes down and the same three mechanisms appear every time. Content is typed records with stable string IDs, whether they are called tweaks, tags, records, blueprints or table rows, and the scenes that thrive never rename or recycle those IDs. Overrides travel as small deltas, merged in a declared order by tooling that reports collisions, rather than as copied files that silently clobber each other; the Bashed Patch, ConfigDelta, RPFM's partial tables and LML's install manifest are one idea in four costumes. And every mature scene built a checker: M3's deployment checks, RPFM's diagnostics, LOOT's masterlist, Minecraft's format gating. Voidsworn already has the first mechanism in embryo in its data files. The field guide's advice is to build the second and third deliberately: a merge order for data layers, a rename map for saves, and a validator that runs on every build.

## Part 2: Peer codebases, open source and deeply moddable

These are the games whose content layers have been stress tested by thousands of strangers. Voidsworn already keeps content in JS data files, so the patterns below are not aspirational: most of them translate directly. Five problems recur, and each entry names the one it solves best: content as data, save integrity when ids are renamed or retired, live tuning without restarts, effect definitions as data, and event systems that content can hook without engine changes.

### FTL: XML blueprints, the .append convention, Hyperspace, and Multiverse

FTL (Subset Games) stores ships, weapons, drones, augments and events as XML. Ship blueprints live in blueprints.xml, events in events.xml and its siblings, and a mod never edits those files in place: Slipstream Mod Manager applies files named things like blueprints.xml.append, appending or overriding by blueprint name at patch time. The steal for content as data is the discipline this creates: one canonical definition per id, and every change expressed as a named layer over it. Voidsworn can copy the shape even inside one codebase by treating balance passes as append style overlays on data.js rather than edits scattered through it.

Hyperspace is the community built native API that sits under the XML. It adds a hyperspace.xml config file, custom crew races and augments defined in XML, custom event files the game loads by name, and a Lua module with explicit hooks: script.on_game_event hooks any named XML event or choice, and script.on_render_event hooks render layers. That is the event system lesson: name every event, let code subscribe by name, and content stops needing engine edits. Multiverse, built on Hyperspace, is the proof of scale: over 300 playable ships, over 200 new weapons and drones, over 30 new sectors, hundreds of events, all shipped as data plus Lua by a volunteer team.

Study: the ship editing tutorial at https://www.toothycat.net/~hologram/FTL/ShipEditingTutorial.html, the Hyperspace docs at https://ftl-hyperspace.github.io/FTL-Hyperspace/en/windows/easy-install/ and its Lua wiki at https://github-wiki-see.page/m/FTL-Hyperspace/FTL-Hyperspace/wiki/Lua-Script-Module, and the Multiverse wiki at https://ftlmultiverse.miraheze.org/wiki/Main_Page.

Licence in plain words: FTL is a commercial game, no reuse rights in its assets or code. Hyperspace is free open source community tooling on GitHub. Multiverse is a free mod, not a licence to lift its content.

### RimWorld: the Def system, XPath patches, Harmony, and TweakValues

RimWorld (Ludeon) defines nearly everything as a Def: an XML record with a unique defName, typed fields, and cross references to other defs by name. ThingDef, WeaponDef, ThoughtDef and hundreds more are all the same pattern. The engine resolves the web of names at load and reports config errors on startup, which is why a decade of mods rarely hard crash each other. The save integrity lesson is blunt: defName is forever. You can patch a def, extend it with a DefModExtension, or add fields, but renaming one orphans every save and every other mod that referenced it.

Two patch layers sit on top. XML patch operations use XPath to add, replace or conditionally edit nodes in other defs, with an official compatibility tutorial teaching defensive patching: scope your XPath tightly, use PatchOperationConditional so you compose with whoever got there first. Harmony is the code layer, a .NET runtime patching library offering Prefix (run before, optionally skip), Postfix (run after, adjust the result), Transpiler (rewrite the method body) and Finalizer hooks. The pattern worth stealing for Voidsworn is the ordering: data first, declarative patches second, code hooks last and smallest. RimWorld also ships TweakValues, documented in its own tutorial index as changing values on the fly for quick iteration, which is live tuning built into the debug tooling rather than bolted on.

Study: https://rimworldwiki.com/wiki/Modding_Tutorials/Compatibility and https://rimworldwiki.com/wiki/Modding_Tutorials/Compatibility_with_defs, plus Harmony docs at https://harmony.pardeike.net/v2/articles/basics.html.

Licence in plain words: RimWorld is commercial and its code is closed; the wiki documents the format, not a reuse grant. Harmony itself is MIT licensed, free to use including commercially, with attribution.

### OpenXCom: YAML rulesets and spreadsheet round trips

OpenXCom is the open source reimplementation of the 1994 X-COM, and its whole game is rulesets: YAML files where items, craft, armour, research, aliens and missions are lists of records keyed by string ids like STR_PISTOL. Mods are folders of .rul files that add or override records by id, layered over the base ruleset, with a separate nightly ruleset reference documenting fields the stable release does not have yet. Versioned documentation for a moving data format is itself a steal for any project whose content format keeps growing.

The tooling is the second lesson. The community maintains rul2csv and csv2rul, which extract ruleset fields into spreadsheets and rebuild rulesets from them, plus online ruleset checkers and formatters that validate and normalise YAML. That round trip is how you balance 500 weapons without editing 500 records by hand. Voidsworn already has census CSVs in its compute pack; OpenXCom shows the missing half, generating the data file back from the spreadsheet so the CSV becomes the editing surface, not just a report.

Study: the ruleset tools thread at https://openxcom.org/forum/index.php?topic=8003.0 and the nightly ruleset reference linked from it.

Licence in plain words: engine code is GPL v3, free to read, fork and ship under the same terms. It ships without the original game data, which remains MicroProse copyright and must come from a copy the player owns.

### Battle for Wesnoth: WML, or content language as the whole game

Wesnoth is a hex tactics game where everything, units, terrain, scenarios, campaigns, UI and even save files, is written in WML, the Wesnoth Markup Language, stored as plain .cfg text files. A unit is a [unit_type] block with an id, stats, attacks and advancement paths. A scenario is a map plus [event] blocks that fire on named triggers (first turn, unit death, village capture) and run arbitrary effects. Campaigns are just ordered scenario lists with carryover state, which is almost exactly Voidsworn's run structure of nodes, fleets and persistent admirals.

Two steals. First, the event model: events are data, declared inside the scenario they belong to, keyed to named engine triggers, so writers add ambushes, reinforcements and story beats without touching the engine. Second, distribution: an in game add-on server lets anyone publish campaigns and eras, and the project promotes the best user campaigns into the official release. Twenty years of that loop is why a volunteer project has seventeen shipped campaigns.

Study: the Create hub at https://wiki.wesnoth.org/index.php?title=Create&oldid=69137, which links the WML tutorial, unit creation and add-on structure guides.

Licence in plain words: GPL v2 or later, and unusually it covers everything, code, art, sound and music alike. Anything borrowed must stay GPL.

### Cataclysm: Dark Days Ahead: a JSON schema for an entire world

CDDA is a huge open source survival roguelike where content is JSON objects, each carrying a "type" and an "id": items, monsters, professions, mutations, martial arts, NPC dialogue trees, all of it. The base game and its mods use the identical format. A mod is a folder with a modinfo.json declaring its id, name, category and dependencies; the docs site walks a first time modder from that file to adding professions, scenarios and dialogue. NPC conversation is data too: talk_topic objects with conditional dynamic_line responses and topic graphs, which is a working template for Voidsworn's admiral and patron dialogue if it ever outgrows hardcoded strings.

The scale lesson is governance. With over a thousand contributors, CDDA survives because the JSON format is documented field by field in a generated reference (JSON_INFO), mods declare dependencies explicitly instead of overwriting silently, and content can be flagged obsolete so old saves degrade instead of dying. The "type plus id" registry also means a validator can walk every file and check every cross reference, the same referential integrity Voidsworn's compute pack already checks by hand.

Study: the official modding guide at https://docs.cataclysmdda.org/MODDING.html and the repo at https://github.com/CleverRaven/Cataclysm-DDA.

Licence in plain words: code and content alike are CC BY-SA 3.0. You may reuse with attribution, and anything you publish built on it must be shared under the same terms. Share alike on code is unusual, so read before lifting wholesale.

### Mindustry: content types, namespaced names, and extend()

Mindustry (Anuken) is an open source tower defence and factory game with a mod system Voidsworn should envy for its smallness. Content falls into a fixed registry of types: item, block, bullet, liquid, status, unit, weather, planet, and notably effect, a first class content type rather than a hardcoded visual. Mods define content three ways, JSON or HJSON files for pure data, JavaScript using an extend() call that subclasses a content type and overrides fields and behaviour, or full Java mods. Scripts listen on a typed event bus, Events.on(UnitDestroyEvent, ...), so behaviour hooks are named and discoverable in one source file.

The quiet steal is namespacing. Every piece of mod content is automatically prefixed with the mod name, so a block is always modname-blockname, and bundles key text as block.modname-name.name. Collisions between authors are impossible by construction, and save files referencing namespaced ids stay meaningful. Slay the Spire independently arrived at the same answer, which suggests it is the right one. Voidsworn's ids are currently bare strings in a single namespace; prefixing by content pack or faction costs nothing now and pays off the first time two systems coin the same name.

Study: https://mindustrygame.github.io/wiki/modding/1-modding/ and the scripting page at https://mindustrygame.github.io/wiki/modding/3-scripting/, source at https://github.com/Anuken/Mindustry.

Licence in plain words: GPL v3 for the game code. Reading and borrowing architecture is safe; shipping its code obliges you to ship yours under GPL too.

### Slay the Spire: BaseMod hooks and mod prefixed ids

Slay the Spire (Mega Crit) is a closed game, but its modding stack is the cleanest example of a hook API designed by the community. ModTheSpire loads mods and applies patches; BaseMod sits on top offering registration calls (addCard, addRelic, addCharacter, addColor) and lifecycle hooks that fire at defined points, such as receivePostInitialize, so a mod adds content by registering it and subscribing to events instead of editing game classes. Cards themselves are a class plus a JSON strings file loaded through BaseMod, separating text from behaviour so localisation and balance edits never touch code.

The detail to steal is in the wiki's own words: content ids are prefixed with the mod id, so a card is beans:Strike, specifically to avoid conflicts and keep references stable. Combined with BaseMod's dev console, it is a complete small system: namespaced registry, hook bus, data driven text. Voidsworn's relics, boons and commands are one registry refactor away from the same shape.

Study: the BaseMod wiki at https://github-wiki-see.page/m/daviscook477/BaseMod/wiki/Custom-Cards and the BasicMod walkthrough at https://github-wiki-see.page/m/Alchyr/BasicMod/wiki/Adding-Content.

Licence in plain words: the game is commercial and closed. BaseMod is MIT licensed; ModTheSpire is a free open source community project on GitHub. Patterns travel freely, game assets and code do not.

### Darkest Dungeon: data files all the way down, with load order as the API

Darkest Dungeon (Red Hook) was built data first and officially opened to modding with a Steam Workshop and an official guide. Hero classes live in per class folders as .info.darkest files (JSON in structure) defining stats, resistances, skills and rank preferences; effects and buffs are defined in shared .darkest effect files that skills reference by name; trinkets are entries in JSON files such as base.entries.trinkets.json; monsters, curios, quests and town events follow the same pattern. A mod is a folder mirroring the game's own directory tree plus a project.xml, and the game resolves conflicts by mod priority: higher in the load order wins, file by file.

The steal is that load order plus file mirroring is the entire compatibility API. There is no patch language; you override a whole file or add a new one, and priority decides. It is cruder than RimWorld's XPath, and it still produced thousands of class and rebalance mods because the contract is learnable in an afternoon. For Voidsworn, the transferable part is the effects file: one shared library of named effects (buffs, debuffs, damage over time, stress) that every skill, weapon and event references, instead of bespoke code per weapon.

Study: the modder tools index at https://darkestdungeon.fandom.com/wiki/Modder_tools, which links the official guide and the priority guide.

Licence in plain words: commercial game, modding is invited but the assets and code stay Red Hook's. Study the formats, ship nothing of theirs.

### Cogmind: the Grid Sage dev blog, a masterclass in effects and audio as data

Cogmind (Grid Sage Games) is a commercial ASCII roguelike, and developer Josh Ge (Kyzrati) has written up its systems in unusual depth. Three posts matter here. ASCII Particle Effects and Making Particles document the particle system: every effect is defined in external text scripts, a library of styles (7 ballistic projectiles, 12 lasers, 24 explosions and so on) where a recolored variant costs one line, and templates the engine expands automatically, substituting colour, speed and lifetime to generate families of effects from one definition. Critically, particle data reloads dynamically in the running game, because, in his words, guessing and restarting with every tweak was slow and miserable. Sound and colour are designed together: Weapon SFX describes categorising every weapon sound by type and power band before creating any of them, so a weapon's look, sound and strength read consistently.

The UI writing is just as transferable: the innovation page catalogues drag and drop inventory, automatic labelling of objects entering view, and a fully animated interface inside a two colour per cell constraint. For Voidsworn the headline is the template idea. Its weapons already fall into families; defining one particle script per family with per weapon substitutions (colour, scale, speed) replaces dozens of hand tuned effects with a dozen templates, and the reload at a keypress is the same live tuning loop Starsector and Naev both converged on.

Study: https://www.gridsagegames.com/blog/2014/03/particle-effects/, https://www.gridsagegames.com/blog/2014/04/making-particles/, http://www.gridsagegames.com/blog/2014/05/weapon-sfx/, and https://gridsagegames.com/cogmind/innovation.html.

Licence in plain words: commercial game, closed code. The blog is free to read and learn from; that is the whole offer, and it is a generous one.

### Starsector: the deep version

Starsector (Fractal Softworks) is the closest commercial cousin to Voidsworn's structure, space tactics with a campaign layer, and it has been modded for over a decade while still in development. Its content layer splits by kind. Balance numbers live in CSVs: ship_data.csv, weapon_data.csv, hullmods.csv, ship_systems.csv, wing_data.csv, descriptions.csv. Structure lives in JSON flavoured files: a .ship file defines hull geometry, bounds, weapon slots and engine positions; a .variant file fits a hull with weapons and hullmods; a .skin file reskins a hull with new stats and faction colours, which is how pirate versions of ships exist without duplicating geometry. A .wpn file defines a weapon's sprites, animation and behaviour, a .proj file its projectile. Rules.csv drives campaign interaction text. A Java API (the com.fs.starfarer.api packages) covers whatever data cannot: ship systems, hullmod effects, campaign plugins, custom AI.

The tuning loop is the famous part. Enable devMode in settings.json, and inside the combat simulator pressing F8 re-reads the .json and .csv files, so a modder edits a damage value, taps one key and watches the same fight run with it. The dev mode page also lists the surrounding kit: a variant editor on the main menu, ship control swapping, on demand damage, and d-mod overlays cycled live with number keys. The wiki's modding hub and its guidelines page add the social contract: prefix your ids, do not alter vanilla content without documenting it, ask before reusing assets. That combination, data first content, prefixed ids, one key reload, written etiquette, is most of why the mod scene compounds instead of fragmenting.

Study: https://starsector.fandom.com/wiki/Modding and https://starsector.fandom.com/wiki/Dev_mode. The wiki is community documentation and its dev mode page flags itself as verified to version 0.95.1, so treat fine details as version sensitive.

Licence in plain words: commercial, closed source, sold direct by the developer. There is no reuse licence for code or assets. Everything above is pattern, free to imitate, nothing to copy.

### Three genuine surprises from open source space games

**Endless Sky solves the renamed id problem in production.** The whole game is plain text data files (ships, outfits, missions, conversations) parsed into a node tree, and plugins are folders of the same data that load alongside the core. Its 0.10.0 changelog records two quiet features Voidsworn should copy verbatim. Save files now record the names of all installed plugins, so a save knows what content it depends on. And the team created a deprecated ships file: ships removed from use stay defined there because old saves and plugins may still reference them. That pair, dependency recording plus a retirement home for dead ids, is the complete answer to saves surviving content renames and removals. Missions are a state machine of triggers (offer, accept, complete, fail) and condition tests, another data first event system. Changelog: https://github.com/endless-sky/endless-sky/blob/v0.10.0/changelog, plugin structure: https://github-wiki-see.page/m/Fzzr/endless-sky/wiki/CreatingPlugins. Licence: code and text GPL v3 or later; art mostly CC BY-SA 4.0 with some CC BY and public domain pieces mixed in, checked per file.

**Naev hot reloads its missions.** Naev, the open source Escape Velocity alike now developed on Codeberg, scripts missions and events in Lua against a large documented API. Buried in that API are two developer functions: naev.missionReload(name) and naev.eventReload(name), which reload a mission or event script live, explicitly, per the docs, to test without corrupting game state. Same lesson as Cogmind and Starsector from a third codebase: the reload is a first class feature, not a hack. Naev also applies world changes through a diff system, so events modify the universe as reversible named patches. API index: https://naev.org/api/, mission scripting guide: https://codeberg.org/naev/naev/wiki/Mission-Scripting. Licence: code GPL v3; artwork lives in a separate submodule under Creative Commons terms, checked per asset.

**Pioneer writes its save policy down.** Pioneer, the open source Elite alike, defines ships as Lua data files (gun mounts as vectors, equipment slot limits, hull mass driving health) and keeps a SAVEBUMP.txt in the repo root whose entire job is recording every change that bumps the save format. A one file changelog for save compatibility is a tiny habit that prevents the worst class of bug this whole cluster keeps circling. Repo: https://github.com/pioneerspacesim/pioneer, ship definitions: https://wiki.pioneerspacesim.net/wiki/Creating_Ships_and_Stations. Licence: code GPL v3, artwork CC BY-SA 3.0, fonts under the SIL Open Font License, three licences in one repo, each labelled.

## Part 3: Open assets, effects techniques and sound

Scope: reusable sources for Voidsworn's current pushes (procedural ship materials and paneling, faction readable effects and beams, background plates under the readability cap, UI clarity, cinematic camera work, and the missing sound layer). Every entry below was verified on its real page on Oct 23, 2026. Licence lines are plain words, not legal advice. FLAG means free to download but not free to ship, or a condition that needs action before shipping.

### 1. Asset libraries beyond Kenney, ambientCG and Poly Haven

**Quaternius** (https://quaternius.com/)
What: a large low poly 3D catalogue by one author. The space relevant packs are the Modular Sci-Fi MegaKit (270 plus textured models, covered at https://80.lv/articles/a-free-modular-asset-pack-with-over-270-game-ready-models/), the Sci-Fi Essentials Kit, the Ultimate Space Kit, the Ultimate Spaceships Pack, the Ultimate Modular Sci-Fi Pack, the Sci-Fi Modular Gun Pack and the Cyberpunk Game Kit.
Voidsworn use: kitbash vocabulary and stand-in meshes for the parametric ship kit (turrets, antennae, greeble blocks), station and dockyard dressing on the campaign map, and silhouette study for hull grammar.
Licence: the site FAQ states all models are under CC0. Use them in commercial work, no attribution, no permission needed. Paid tiers only add source Blender files; the free downloads carry the same CC0 terms.

**KayKit (Kay Lousberg)** (https://kaylousberg.itch.io/bits-bundle-1)
What: hand built low poly packs. The space entry is Space Base Bits, modular space base and station pieces, sold inside the Bits Bundle on itch; the author's asset index is at https://kaylousberg.com/game-assets/characters-adventurers.
Voidsworn use: station modules, dock arms and habitat blocks for campaign map set dressing and debris fields.
Licence: CC0, free for personal and commercial use, no attribution. The author asks that you not resell the packs unmodified or present them as your own work.

**OpenGameArt space highlights** (entry point: https://opengameart.org/art-search-advanced?field_art_tags_tid=starship)
Licences are per item on this site, so check every page. Verified standouts:
- ansimuz, Space Ship Shooter Pixel Art Assets, CC0: loopable background, player and enemy ships, explosion, lasers, bolts, power ups, layered PSD included.
- Master484, 16x16 Ship Collection, CC0: https://opengameart.org/content/1616-ship-collection
- sujit1717, Complete Spaceship Game art pack, CC0: https://opengameart.org/content/complete-spaceship-game-art-pack
- CraftPix, Enemy Spaceship 2D Sprites, OGA-BY 3.0 (attribution required): https://opengameart.org/content/enemy-spaceship-2d-sprites-pixel-art
- Skorpio, Space Ship Construction Kit, dual licensed CC BY-SA 3.0 and GPL 3.0: https://opengameart.org/content/space-ship-construction-kit FLAG. Share-alike and GPL terms travel with derivatives, so treat this kit (including its stars and nebulae set, muzzle flashes and engine exhaust sheets) as reference only unless the project accepts copyleft.
Voidsworn use: 2D sprites for campaign map markers and fallback rendering, explosion and laser sheets for quick effect tests, background star layers under the 40 percent luminance cap.

**itch.io CC0 space packs**
- Majadroid, 3D LowPoly Spaceships and Components: 14 low poly ships plus the component parts they are assembled from, with Blender, FBX and OBJ files. Page states attribution is not required and the pack is free to use in any project, also commercial (CC0). https://majadroid.itch.io/3d-lowpoly-spaceships-and-components-cc0
- MattWalkden, Free Space Runner Pack: explicitly CC0, credit appreciated but not required. https://mattwalkden.itch.io/free-space-runner-pack
- Wisedawn, 200+ CC0 Spaceship Assets: 200 plus public domain 2D ship sprites in four styles, found via the itch space tag listings at https://itch.io/game-assets/tag-space/tag-spaceship?page=3 (the pack page itself was not opened in this pass).
- PanksCreations, Galactic Invaders: FLAG partial. The free tier carries a custom licence (free for personal or commercial projects) but the full content is a paid premium tier. https://pankscreations.itch.io/galactic-invaders-2d-spaceships-pack
Voidsworn use: component parts are the useful layer here, a ready made vocabulary of noses, wings, engines and turrets to compare against the parametric loft kit before hull 2 is built.

**Awesome lists**
Calinou's awesome-gamedev is the maintained index of engines, tools and asset sources: https://github.com/calinou/awesome-gamedev
Licence caveat, stated plainly: the list itself is CC0, and that covers the list text only. Every entry it links carries its own licence, which the list annotates per entry (MIT, GPL, CC BY-SA and so on all appear). Being linked from a CC0 list makes nothing CC0. Use it as a discovery index, then verify each tool on its own page.

### 2. Procedural textures and PBR painting

**Material Maker, the community library** (tool: https://godotengine.org/showcase/material-maker, docs: https://www.materialmaker.org/doc)
What: free and open source (MIT) node based procedural texture tool built on Godot, 200 plus nodes, exports full PBR map sets with presets for Godot, Unity and Unreal, and includes a 3D painting mode. A paid Steam listing exists but the itch build is free, pay what you want.
The deeper find is the sharing site at materialmaker.org. Users publish materials, nodes, environments and brushes; assets import from inside the app (File, Load material from website; the Library panel browses community nodes) with no account needed to import. Each shared asset has its own page where the submitter sets a licence, so community assets need a per asset licence check even though the tool itself is MIT.
Voidsworn use: the offline paneling pipeline. Generate per faction hull plate sets (albedo, normal, roughness, metallic) as data, feed them to Babylon PBR materials through FAC3D tinting, and compress with KTX2 before shipping.

**ArmorPaint** (https://armorpaint.org, cloud library: https://armorpaint.org/cloud)
What: GPU accelerated PBR texture painting with node based materials, the open Substance Painter alternative from the Armory3D project. Source code is on GitHub under the zlib/libpng licence. FLAG on cost, not on rights: prebuilt binaries are a paid one time download (19 dollars at https://armorpaint.org/download); building from source is free.
Its in-app Cloud library bundles assets from ArmorPaint, ambientCG and Poly Haven, stated as CC0.
Voidsworn use: hand finishing hero hulls where procedural tiling reads flat: faction wear, scorch near weapon mounts, painted markings that must survive close camera work.

**Laigter** (https://azagaya.itch.io/laigter)
What: generates normal, specular, parallax and ambient occlusion maps from a single flat image, aimed at sprites and 2D textures. Open source on GitHub. FLAG: official binaries are now paid on itch, so build from source or pay. The author confirms in the itch comments that the licence covers the tool code only; maps you generate are fully yours, commercial use, no attribution.
Voidsworn use: turning painted panel art and 2D plate layers into lit materials, and normal maps for sprite based effects so explosions and shields respond to scene lighting.

**Materialize** (walkthrough: https://www.thesketchupessentials.com/free-texture-and-map-generation-with-materialize-easy-texture-creator)
What: free standalone tool from Bounding Box Software that builds a full PBR set (height, normal, metallic, smoothness, AO, edge and detail maps) from one diffuse image, with seamless tiling help.
Licence caution: verified through a third party walkthrough only; its own licence page was not opened in this pass. Check the official terms before shipping outputs.
Voidsworn use: fast conversion of a painted or photographic texture into a Babylon ready map set for background props and station surfaces.

**TextureLab**
Free and open source procedural texture editor in the same node graph family as Material Maker. A credible second option if Material Maker's Godot based UI does not suit; no Voidsworn specific advantage found.

### 3. Shaders and effects technique sources

**godotshaders.com** (licence policy: https://godotshaders.com/about-godot-shaders/)
What: the Godot community shader library. The site states shaders are free under CC0, MIT or GNU GPL v3, varying per post, and each post prints its own licence. Two verified standouts:
- Scrolling Starry Background, CC0: layered scrolling starfield with a noise nebula. https://godotshaders.com/shader/scrolling-starry-background/
- Magical Shield Shader #4 by arlez80, MIT: a readable energy shield dome. https://godotshaders.com/shader/magical-shield-shader-4/
Caveats: images and videos inside posts are not covered by the shader licence, and GPL v3 posts carry copyleft obligations if you port the code.
Voidsworn use: background plate motion layers and the shield dome in fx3d. Godot shader language is close to GLSL, so ports to Babylon ShaderMaterial are modest edits; the CC0 and MIT posts are the safe hunting ground.

**Shadertoy** FLAG, the standing warning.
Default licence on Shadertoy is CC BY-NC-SA 3.0: attribution, non-commercial, share-alike. That means the default shader is study only and cannot ship in a commercial release. Some authors override the default in the shader header; the well known Star Nest nebula, for example, is MIT in its header (visible in porting write ups such as https://defold.com/tutorials/shadertoy/).
Rule for Voidsworn: mine Shadertoy for technique (nebula raymarching, fresnel shield falloff, warp tunnels, beam noise), reimplement the idea, and copy code only when the header grants MIT, CC0 or an equivalent permissive licence.

**three.js examples** (index: https://threejs.org/examples/#webgl_tonemapping)
three.js is MIT licensed and the examples ship under the same licence, so example GLSL can be ported to Babylon ShaderMaterial or rebuilt in Node Material; keep the MIT notice with ported code. The transferable set for Voidsworn: fresnel shell shields, additive beam and glow sprites, points based starfields, and the post processing chain (bloom, tonemapping) that the cinematic camera work depends on. Individual example pages were not opened in this pass; the claim here is at library level.

**Babylon Node Material** (https://doc.babylonjs.com/features/featuresDeepDive/materials/node_material/)
The native route. The official docs hub covers the node material system, the Node Material Editor, and dedicated pages for node material post processes, procedural textures and particle shaders. Building the shield, beam and nebula looks as node graphs avoids hand ported GLSL entirely, keeps the materials inspectable in the editor, and lets one graph serve both the WebGL and WebGPU paths.

**RealtimeVFX** (https://realtimevfx.com/latest?no_definitions=true)
The professional real time VFX community forum: breakdowns, sketchbooks and monthly sketch topics covering shields, beams and explosions by working artists. Study source only. Posts belong to their authors and carry no asset licence; the value is technique, timing and art direction reference for the effects language, not files.

### 4. Particles and sprites

**Effekseer** (https://effekseer.github.io/en/)
Free, open source particle effect editor, MIT licensed. Effects export as baked 2D animation sequences (flipbooks) or run through runtime integrations, including WebGL via Emscripten. The site also hosts community sample effects described as free to use and free to edit.
Voidsworn use: this is the flipbook generation tooling pick. Author explosions, muzzle flashes and engine trails once, bake sprite sheets, and drive them from Babylon particle systems, instead of hunting for sheets that happen to match the faction palette.

**OpenGameArt explosion flipbook** by johndekale: animated explosion at 256x256, CC0. http://opengameart.org/content/explosion-10
Voidsworn use: hull death and torpedo impact placeholder that can ship as is.

**Animations2023 collection** by JoesAlotofthings: https://Opengameart.org/content/animations2023
Impact and explosion sheets, muzzle flash sets, a shield electric effect, bursts and flares as transparent PNG sheets. Stated usable in commercial and non-commercial projects, with credit to JoesAlotofthings requested.
Voidsworn use: the shield hit ripple and beam impact set, matched to the cyan shield colour law.

Skorpio's construction kit (section 1) also includes muzzle flash and engine exhaust sheets, under the same share-alike FLAG.

### 5. Sound, the big gap

**Freesound, with a CC0 filter strategy** (licence FAQ: https://freesound.org/help/faq/)
What: 730,000 plus user uploaded sounds. Licences are per sound: CC0 is about 52 percent of the library (roughly 381,000 sounds), CC BY requires credit, CC BY-NC bans commercial use, and the legacy Sampling Plus licence should be avoided entirely.
Strategy in plain words: filter every search to CC0 and there is nothing to track. Allow CC BY only with an attribution log kept next to the asset. Never ship BY-NC or Sampling Plus in a paid game. One quality caveat: uploads are user moderated, so a sound ripped from a film or game can slip through with a CC0 tag; prefer uploaders who describe how they recorded the sound.
Voidsworn use: the recorded layer synthesis cannot fake: metal stress and impacts, room tone for the bridge, radio static and squelch under admiral voice lines.

**Sonniss #GameAudioGDC bundles** (https://sonniss.com/gameaudiogdc, licence: https://sonniss.com/gdc-bundle-license/?disabled)
What: an annual free bundle of production sound effects from commercial libraries, released around GDC; the 2026 bundle is 7.47 GB across 347 WAV files, and the archive of earlier bundles stays downloadable.
Licence in plain words: a custom royalty free licence, not a Creative Commons licence. Worldwide, non-exclusive, unlimited projects for your lifetime, commercial use allowed, no attribution required, modification allowed. Two hard limits: the sounds must be synchronised inside your project (the game), and you may not hand the sound files themselves to anyone else, standalone or bundled as a sound library. Using them to train AI or ML models is also prohibited. So: free to ship inside the game, not free to redistribute raw.
Voidsworn use: the fastest way to close the sound gap. Weapon fire, impacts, UI and ambience layers at production quality, zero bookkeeping. Practical note: transcode the picks to OGG before shipping; the raw WAVs are large.

**Synthesised SFX: the sfxr lineage**
- jsfxr (sfxr.me) is the JavaScript port of DrPetter's sfxr, maintained by Chris McCormick; a late 2025 update added OGG, MP3 and SFXR export and sound packs.
- JFXR (jfxr.frozenfractal.com, by Thomas ten Cate) extends the same idea with more controls, and its README states that all sounds created with JFXR are free to use without restrictions, including commercial projects. Terms summary: https://deepwiki.com/ttencate/jfxr
- ZzFX (Frank Force, KilledByAPixel) is the modern successor built for web games: a tiny JavaScript synth that pre-renders samples and plays them through Web Audio AudioBuffers.
Voidsworn use: the whole UI and light weapon layer can be generated, with zero audio files shipped. ZzFX presets inside the Babylon build give clicks, confirms, laser zaps and small explosions, and per faction variants are just parameter changes (pitch, filter, decay) on one preset, which matches the faction readability goal.

**Ambient and sci-fi music, CC and free-with-credit sources**
- alkakrab on itch publishes looped sci-fi packs (Free Sci-Fi Game Music Pack, Vol. 2 with 6 tracks, Vol. 3 with 30 tracks). Terms gathered from the pack pages and the author's own comments: free for commercial and non-commercial projects with credit ("Music by alkakrab"); the free pack licence text ships as a PDF inside the download. Vol. 2 comments: https://alkakrab.itch.io/free-sci-fi-music-2/comments. His paid 30 track sci-fi pack states the same free for commercial use terms: https://alkakrab.itch.io/sci-fi-space-30-tracks-game-music-pack
- Incompetech (Kevin MacLeod) is CC BY 4.0: usable commercially, attribution required.
- Pixabay Music runs under the Pixabay Content License (no attribution, no standalone resale), per secondary licence guides; verify on the track page before shipping.
Voidsworn use: ambient beds for the campaign map and sector backgrounds, low intensity battle loops, and short faction stingers on admiral introduction.

**NASA audio** (https://www.nasa.gov/historical-sounds, Artemis library: https://www.nasa.gov/artemisaudio/)
What: free MP3 downloads of shuttle, Apollo and mission control audio, liftoffs, plus instrument sonifications (Cassini Saturn radio emissions, Voyager plasma sounds) and the Quindar comms beeps. The Artemis Audio Library states its files are free to download and cleared for use in accordance with NASA's media usage guidelines.
Terms in plain words: NASA's own recordings are US government material and generally not copyrighted, so commercial use is fine with NASA credited as the source. Follow the media usage guidelines: no implied NASA endorsement of the game, and do not use NASA insignia as branding.
Voidsworn use: comms chatter under orders and acknowledgements, engine rumble layers for capital ships, and authentic mission ambience beds that no synth pack matches.
ESA audio: terms were not verified in this pass. Treat ESA sound as unverified until its own page is checked; do not assume it matches NASA.

### 6. Fonts, icons and UI sound

**Google Fonts** (licence FAQ: https://developers.google.com/fonts/faq?tid=312025023)
Google's own FAQ states all Google Fonts are open source, free to use commercially, including inside products that are sold. Most families are SIL Open Font License 1.1; a smaller set use Apache 2.0 or the Ubuntu Font License. OFL in plain words: use, embed and modify freely, ship commercially, no attribution required; you cannot sell the font file by itself, and redistributed derivatives must stay under the OFL.
Candidates for Voidsworn: Orbitron (geometric display face, variable weights; OFL, verified via https://fontalternatives.com/fonts/orbitron/) for headers, hull names and faction wordmarks; Rajdhani for UI body text; Share Tech Mono for data readouts and logs; Audiowide and Michroma as alternate display faces. The non-Orbitron families are named as candidates under the blanket Google Fonts licence above; confirm each family's licence line on its specimen page before shipping.

**game-icons.net** (licence framework: https://deepwiki.com/game-icons/icons/2-licensing-and-legal-framework)
What: 4,000 plus monochrome SVG icons (weapons, shields, planets, rockets, upgrade pips) that recolor cleanly, ideal for HUD and ability icons tinted by faction colour.
Licence in plain words: the default is CC BY 3.0, attribution to the individual icon author (Lorc, Delapouite and others) is required. Two contributors, Viscious Speed and Zeromancer, have released their icons under CC0. Practical rule: keep a per icon credit list in the game credits, or restrict picks to the CC0 authors and skip the bookkeeping.

**Open UI sound packs**
- Kenney audio packs (Interface Sounds, Sci-Fi Sounds and the wider audio set) are CC0, designed as matched sets so a click and its error tone sound like the same machine; pack summary via http://app.cinevva.com/guides/free-sound-effects-music
- MalikethWorks, Retro UI SFX CC0: 23 short WAV sounds (clicks, hovers, confirm, cancel, error, notification, menu open and close), CC0, no credit needed. https://malikethworks.itch.io/retro-ui-sfx-cc0
- PulseLite UI SFX free tier: 20 menu sounds in WAV and OGG, CC BY 4.0, credit line supplied on the page.
Voidsworn use: a matched UI sound set is the difference between a prototype menu and a shipped one; pair one of these packs with ZzFX variants so repeated clicks do not fatigue.

### Shortlist and shipping flags

Strongest three finds: (1) Sonniss GDC bundles, production grade SFX under a lifetime royalty free, no attribution licence; the sound gap closes fastest here. (2) ZzFX plus JFXR, a complete UI and weapon sound layer generated in code or exported free, with zero shipped assets and zero licence friction; the native fit for a web game. (3) Effekseer, MIT particle authoring that bakes exactly the flipbooks the effects work needs.
Close fourth: the Material Maker community library, which turns a known tool into a per faction paneling pipeline.

Check before you ship: Shadertoy default licence (non-commercial, study only). Skorpio construction kit (share-alike and GPL). Freesound CC BY-NC and Sampling Plus tags. godotshaders GPL v3 posts, and the images inside any post. ESA audio (terms unverified). Materialize (GPLv3, outputs safe to ship). PanksCreations Galactic Invaders free tier (partial content, custom licence).
