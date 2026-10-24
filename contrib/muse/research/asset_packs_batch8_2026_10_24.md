# Batch 8, leg 1 (Rey, search-based): asset packs, material packs, prebuilt assets, and template/kit systems (Oct 24, 2026)

Filing note: filed from the leg 1 research report, blind to the DeepSeek second leg. Method for this run only: web search plus two full page reads (Khronos glTF art pipeline, Godot Standard/ORM material docs). No sign-in, no posting, voting, or commenting, no purchase, no engine test. Nothing below was bought, imported, or rendered in Babylon or Godot. Prices, counts, formats, and licence terms are as stated in the source found this run, and must be rechecked on the vendor page before purchase or use, because store pages change and snippets can lag.

Scope for this run: a 3D turn-based fleet-tactics roguelite on PC, about 20 ships per battle, currently Babylon.js with an open question about moving to Godot. Space ships only, never naval ships. Colour law: cyan means shields, nothing else is cyan. Faction grammars: Ithar vertical-fin sails, Chorus grown flesh (never built things or familiar animal anatomy), Deathless machine intelligences with bone as metaphor only and no faces, guns never face backward. Public repo. Kit-first workflow: one hero ship, a Corsair battle-barge, is the worked example before any fleet-wide rollout.

Source strength is flagged inline. [STRONG] means official docs or a primary licence page. [WEAK] means a store listing, forum post, vendor blog, tutorial marketing page, or secondary aggregator. A [WEAK] source can still describe a real mechanism, but it is not proof of quality, performance, or licence safety.

## (a) Prebuilt ship and space asset packs

### Finding A1. Grey Fleet Armada: a matched fleet, but small and AI-assisted
Source: Appeal Foundry store listing [WEAK: vendor listing, self-certified checks]. It lists 6 models for $19.99: Sickle Wing Escort, Verdant Nose Escort, Longhaul Segment Escort, Vanguard Arrow Fighter, Grey Arrow Interceptor, and Grey Command Frigate. Each ship has 4 LODs (about 30k to 1.5k tris), convex collision, bounding-box sockets, 2K PBR on LOD0 with clearcoat and emissive engines, GLB plus FBX, and loose LOD0 maps (base colour, normal, ORM, emissive where present) so FBX can be textured in any engine. It states the workflow openly: AI concept art and Meshy 7 base meshes, finished with a LOD, collision, and material pass. Static exteriors only, no interiors, rigs, or animation.
Inference: the LOD range, GLB plus FBX choice, and socket claim are the closest match in this run to a 20-ship battle budget, because distant ships can drop to 1.5k tris. The "glowing cyan engines" in the same listing directly conflict with the project colour law unless engine emissive is recoloured. The AI-assisted origin does not by itself disqualify it, but it raises the cleanup and originality questions covered in Finding C7.
Decision: ADAPT - only as a reference for LOD and socket packaging, or for non-hero background hulls after a full cyan recolour and a mesh audit. Not a hero-ship source.

### Finding A2. Salvage Yard Armada: same vendor pattern, salvage look
Source: Appeal Foundry foundry page [WEAK: vendor listing]. It lists a matched salvage-crew fleet of 5 ships (Salvage Interceptor, Rustfang Fighter, Claw Salvage Tug, Ember Thruster Frigate, Cross-Arm Station), median 29,999 tris, GLB plus FBX, 289 MB, with 7 of 7 mesh checks passed on all 5 ships.
Inference: a salvage look is a plausible fit for Corsair-adjacent props or a station, but "matched" here means matched to that vendor's salvage line, not to Ithar sails, Chorus flesh, or Deathless bone-metaphor machines. Buying two vendor fleets would create two house styles, not one unified fleet style.
Decision: ADAPT - candidate only for salvage-flavoured props or stations, after style and licence checks. Not a fleet foundation.

### Finding A3. MSGDI Unity fleet packs: broad coverage, Unity-shaped packaging
Source: Unity Asset Store listings [WEAK: store listings]. Alien Spaceship Fleet Collection II ($22.50, 1.9 GB, version 1.1, May 3, 2026) lists 3 example stations, 1 resource collector, 1 refinery, 3 resource containers, 3 lowpoly asteroids, 6 weapon platforms, 6 probes, modular weapons, changeable decals, 8 damage decals, 6 texture sets, PBR textures (specular), and ready prefabs. Spaceship Fleet III Collection III lists 5 supersized capital ships (Super Dreadnought, Super Carrier, Dreadnought, Super Large Cargo Transport, Colonization Ship), modular weapons, torpedoes plus missiles, changeable decals, 8 damage decals, 6 texture sets, PBR (specular), and prefabs.
Inference: coverage is genuinely broad (hulls, stations, weapons, props, damage decals in one purchase), which is rare in this run. Two cautions follow from the listings themselves. First, "PBR (specular)" is not the same export as metallic-roughness ORM; a specular-to-metallic conversion step must be budgeted if the target is glTF/Babylon/Godot. Second, "prefabs" here means Unity prefabs, not Babylon or Godot templates, so the useful export is FBX plus textures, not the prefab structure.
Decision: ADAPT - worth shortlisting for stations, weapons, and damage decals if the specular conversion and per-ship style audit pass. Not a drop-in fleet.

### Finding A4. Menhars Frigate: a single cheap frigate with modular weapons
Source: Unity Asset Store listing [WEAK: store listing]. It lists one Menhars frigate with modular weapons, 9 turrets and a missile silo, 1 torpedo plus 1 missile, 6 texture sets, a PSD with intact layers, PBR textures (metallic), prefabs, 2048 and 1024 textures, about 1,200 tris depending on weapons fitted.
Inference: the low tri count, metallic PBR claim, and layered PSD are useful for a template experiment, because a layered source makes recolouring and trim replacement easier than a baked single texture. One frigate does not solve a fleet, and its house style is a single vendor's Enkar Republic look, not a faction grammar.
Decision: ADAPT - cheap test candidate for a modular-weapon template experiment. Not a fleet purchase on its own.

### Finding A5. Fundamental Starships: Substance control, but promised features are not shipped features
Source: Unity Asset Store listing [WEAK: store listing]. It lists 5 vessels, each with a Substance file to control hull colour, wear level, and dirtiness, full PBR integration, textures up to 2048 (4K hoped for later), fully rigged ships, engine particle effects, and a test controller/scene, for $5.00. The same listing labels a LOD system, turret tracking, damaged versions, and death animations as "Planned Features" or "Far future ideas."
Inference: the Substance-driven wear and colour control is exactly the mechanism a kit wants, but the LOD and damage variants this project needs are explicitly not in the product yet. Buying it for LODs or damage states would be buying a roadmap.
Decision: SKIP - for this project's current needs. Revisit only if LODs and damage variants actually ship.

### Finding A6. BigMediumSmall Modelshop Greebles: kitbash parts, not finished ships
Source: BigMediumSmall store page [WEAK: vendor listing]. It lists 600+ items: 8 detailed hero spaceships, 35 greeble clusters including 550+ modular kit objects with UVs and textures, a signature shader, baked textures and masks, plus a rigged hero character with 42 preset poses. Formats: Blend 3.2+, OBJ, FBX, C4D, Unreal Project. It states assets are optimized for game engines and all major 3D packages.
Inference: this is the strongest kitbash-shaped offer in this run, because the value is in reusable clusters and hull parts rather than in one fixed hero. The risk is the opposite of Finding A5: with 550 parts and no faction grammar enforced by the pack, the output style is whatever discipline the kit author applies. The included character and shader are irrelevant to a ship-only battle game and should be ignored, not imported.
Decision: ADAPT - shortlist the kit objects and hero ships as raw kitbash stock for the barge experiment, subject to a style pass and a licence read. Do not import the pack wholesale.

### Finding A7. Modular Sci-Fi Environment Kit-bash (hangars): interiors and stations, not fleet hulls
Source: Unity Asset Store listing [WEAK: store listing]. It lists a Thunderpoly kitbash for spaceship hangars at $49.99, with props, materials, textures, a space shuttle in two variants, 105 unique meshes (2 to 11,000 tris), LODs: Yes, 42 materials, 91 textures at 2048, 3 space-themed 32-bit HDRIs, collision for all assets, and a game-ready example level. It explicitly excludes the convolution bloom and shield from its cinematic video.
Inference: LODs plus collision plus a bounded material count are good packaging signals, but the subject is hangar architecture and props, not battle hulls. It fits stations, docks, and background dressing better than it fits the 20-ship battle board.
Decision: ADAPT - only for station/hangar dressing, not for ships.

### Finding A8. Lowpoly itch pack and similar small packs: cheap, but style is the product
Source: itch.io listing for Lowpoly Space 3D Asset Pack by ejgarner118 [WEAK: store listing]. It lists 3 ship classes each in 4 colours (green, blue, orange, purple), planets, stars, asteroids, astronauts, FBX files, a Blender file, and a Unity package, described as vibrant lowpoly and game-ready.
Inference: lowpoly plus bright per-class colours is a coherent style, but it is not this project's style, and "4 colours" is not a faction system. Colour variants also risk breaking the colour law if a blue or cyan variant is used for anything other than shields.
Decision: SKIP - for hero or fleet hulls. The format lesson (FBX plus Blender source) is worth copying, the art is not.

### Finding A9. Synty POLYGON Sci-Fi Space Pack: the broadest modular pack, Unity-first and lowpoly
Source: Unity Asset Store and Synty Store listings [WEAK: store listings]. Both list 660 unique assets with 24 alternative texture colours, modular sections that piece together in combinations, ships (bombers, colossal, cruiser, fighter, galactic, carrier, massive transport, space station, stealth, transport, beacon, drones, escape pods, warp gates, VR cockpit), planets, asteroids, debris, buildings, 20 characters, 235 props, 47 signs, 7 weapons, 48 FX, plus demo scenes and a VR/first-person cockpit. Price listed as $149.99 on the Synty Store, with a subscription option unlocking the full library from $30/month.
Inference: this is the best "build your own ships from parts" catalogue in this run, and the 24 colour variants show a variant system done at catalogue scale. Three limits matter. First, it is a Unity package with URP support stated; Babylon/Godot use requires FBX/texture extraction and material rebuild, not a prefab import. Second, lowpoly plus flat colour variants will not read as painted metal, grime, and trim without a material pass. Third, characters, interiors, and cockpit content are dead weight for a ship-battle game.
Decision: ADAPT - the strongest paid reference for how a modular ship catalogue should be organised (parts, variants, colours). Buy only if a trial extraction proves the FBX plus texture path preserves the modular sections and the lowpoly look survives a PBR material pass. Do not adopt its look as the fleet look.

### Finding A10. No prebuilt pack in this run matches the faction grammars
Source: absence across all listings above. None of the ship, fleet, or kitbash listings found this run mention Ithar vertical-fin sails, Chorus grown flesh without animal anatomy, Deathless bone-metaphor machines without faces, or a forward-only gun rule. The closest style matches are generic military (Grey Fleet), salvage (Salvage Yard), lowpoly sci-fi (Synty, Kenney/KayKit), and single-vendor capital ships (MSGDI).
Inference: this is a negative finding with a direct consequence. Prebuilt packs can supply stations, props, weapons, greebles, and background hulls, but they cannot supply faction identity. Faction heroes must be kit-built or custom-built, with bought parts used only where they do not carry identity (panels, vents, mounts, generic greebles).
Decision: SKIP - any plan that starts from "buy a fleet pack and recolour it into six factions." Recolouring alone does not create sails, flesh, or bone-metaphor machines.

## (b) Material packs

### Finding B1. ORM packing is the shared Babylon/Godot/glTF contract
Source: Khronos glTF art pipeline, read in full [STRONG: standards body]. It states glTF Metallic-Roughness uses Base Color, Normal, and Emission as individual files (preferably PNG), and packs Ambient Occlusion, Roughness, and Metallic into a single channel-packed ORM texture to reduce texture loads: Red = Ambient Occlusion, Green = Roughness, Blue = Metallic. It gives the same packing for Photoshop, GIMP, and Substance Painter export, and states that in Blender the ORM texture wires to both the MetallicRoughness input and the Occlusion input, with the shader pulling the correct channel automatically.
Source: Godot 4.4 Standard/ORM Material docs, read in full [STRONG: official docs]. It states ORMMaterial3D differs from StandardMaterial3D only in that occlusion, roughness, and metallic come from a single ORM texture, and that Substance Painter and Armor Paint offer this export via their Unreal Engine preset.
Inference: ORM is not a vendor preference. It is the format-level reason a single material export can serve Babylon (via glTF) and Godot (via ORM material or glTF import) without maintaining two texture sets. Any material pack that ships only separate metallic, roughness, and AO maps is still usable, but it needs a packing step, and that step is where silent channel swaps happen.
Decision: ADOPT - ORM (R=AO, G=Roughness, B=Metallic) as the single material export contract for every ship template, with a packing check at export.

### Finding B2. Babylon PBR slot mapping needs a check, not an assumption
Source: Babylon.js forum thread on metallic/microSurface mapping [WEAK: forum]. The accepted-direction answer in the thread says: roughness texture to microSurfaceTexture, metalness texture to metallicTexture, ambient occlusion to ambientTexture, with roughness = 1 and metallic = 1 so the textures drive the values.
Inference: the forum answer is plausible and consistent with Finding B1, but a forum thread is not a Babylon docs page. The safe reading is that Babylon can consume the same ORM data, but the exact slot wiring must be verified against current Babylon docs and a test GLB before the kit locks its export preset.
Decision: ADAPT - use the forum mapping as a test hypothesis for the barge export, verify in Babylon docs plus a test import, then lock it in the template. Do not hard-code it from the forum alone.

### Finding B3. Smart materials are the practical way to get painted metal, wear, and grime
Source: ArtStation listing for Ultimate Metal and Iron Smart Material [WEAK: store listing]. It lists 40 metal and iron smart materials for Substance 3D Painter (version 7.4.1 or later), covering worn tool metal, raw metals, painted worn metals, polished metals, brushed metals, gold/silver/copper/nickel, sci-fi metal panels, and dot diamond floor metals, with 4K PBR textures included, at $7.00 for the listed tier.
Source: Substance Painter export guidance [WEAK: vendor blog/tutorial]. It describes smart materials plus masks controlling where materials apply, and export presets organised by resolution (4K/2K/1K), bit depth (albedo 8-bit sRGB, normal 8-bit, roughness/metallic 8-bit grayscale), and PNG for lossless delivery, with a dedicated ORM preset (R=AO, G=Roughness, B=Metallic).
Inference: smart materials solve the "painted hull plus wear at edges plus grime at seams" problem by parameter, not by hand-painting every ship. That is exactly what a 20-ship fleet needs, because the same smart material can be re-tuned per faction while the underlying maps stay consistent. The $7 price is not the whole cost: Substance Painter itself is a separate purchase/subscription, and the listing's licence tier needs a commercial read (see Finding B4).
Decision: ADOPT - the smart-material workflow (parameterised metal, painted panels, wear masks, ORM export) as the material method for the kit. ADAPT the specific pack choice after a licence and Painter-availability check.

### Finding B4. The $7 smart-material licence tier is a trap if read casually
Source: same ArtStation listing [WEAK: store listing]. It shows "Personal Use USD $7.00" and a "Standard License" note describing "For personal use and one commercial project (up to 2,000 sales or 20,000 views)" in the same block, with bundle discounts for buying 2 or 3 products from the seller.
Inference: a listing that mixes "personal use" pricing with a limited commercial allowance in one block is not a licence to ship freely. For a public repo game, the question is not only "can I use it in the game" but "can I ship the derived textures, and can I redistribute the source smart material." Those are different rights, and the snippet does not settle them.
Decision: SKIP - purchasing on the $7 tier without reading the full ArtStation licence and confirming redistribution of baked textures. If the licence allows baked-texture shipping, upgrade the decision to ADAPT.

### Finding B5. Free CC0 PBR libraries are strong for base metals, weak for faction trim
Source: Cinevva free-texture guide and 3DTexel comparison [WEAK: secondary aggregators, counts dated Oct 2026]. They list Poly Haven (over 850 PBR textures, over 990 HDRIs, over 520 models, CC0, 1K to 8K, JPG/PNG, glTF/Blend), ambientCG (over 2,000 PBR materials, CC0, JPG/PNG, 1K to 8K), 3DTextures.me and ShareTextures (CC0), and cgbookcase (CC0 1.0). A Second Life PBR wiki page [WEAK: community wiki] also lists ambientCG and Poly Haven as CC0 Metal-Rough libraries.
Inference: for generic metals, rust, and ground, CC0 libraries remove licence friction entirely. For faction trim (painted panels, panel lines, bolts, vents, faction-specific wear), generic scanned metals are raw ingredients, not finished trim. They still need a trim-sheet authoring pass (Finding B6) to become a fleet material.
Decision: ADOPT - Poly Haven plus ambientCG as the CC0 base-metal source. ADAPT every generic metal through the project's own trim/paint pass before it touches a hero ship.

### Finding B6. Trim sheets are the highest-density material technique in this run
Source: Skillshare/FastTrack course descriptions for trim-sheet creation [WEAK: course marketing]. They describe building an entire environment from one single trim sheet texture (base colour, normal, and a packed map combining roughness, metallic, emissive, and a crunch/detail map), using a modular workflow, blockout first, detailed trim planning for resolution, Substance Painter plus Photoshop for the sheet, weighted normals, and smart UV unwrapping to map models onto the sheet, plus a material with vertex-colour tinting and world-space dirt/grime controls.
Source: Tripo blog on tiling versus unique UVs [WEAK: vendor blog]. It defines trim sheets as texture sheets containing reusable details (edges, bolts, seams, panels) selectively applied via UV mapping, offering the custom look of unique texturing with the reuse benefits of a tiled material, and texture atlases as multiple unique assets packed into one sheet to optimise draw calls.
Inference: a trim sheet is the material equivalent of a kit: one well-planned sheet (panel lines, bolts, vents, edge wear, hazard strips, faction-neutral details) can dress dozens of hull parts with one material and very few texture binds. That directly serves 20 ships on screen, because material count, not just tri count, drives draw calls. The cost is planning: UVs must be deliberately mapped to trim regions, and unique hero details (sails, flesh folds, bone ridges) still need unique UV space or decals on top.
Decision: ADOPT - one master trim sheet (plus per-faction tint/wear variants) as the kit's core material. This is the material half of the highest-leverage starting point in section (e).

### Finding B7. Tiling, unique, trim, and atlas are four tools, not four rivals
Source: Tripo tiling-versus-unique guide [WEAK: vendor blog]. Its checklist is: large/repetitive = tiling; seen up close = unique UVs; specific non-repeating details = unique UVs; part of a set of similar objects = trim sheet; low performance budget = favour tiling/trim.
Inference: applied to ships, the split is clean. Hull plating and generic panels = trim sheet plus tiling grime. Hero silhouette parts (Ithar fin sails, Chorus growths, Deathless bone ridges) = unique UVs. Small repeated parts (vents, bolts, antennae) = atlas. Using only one method for everything either wastes texture memory (all unique) or flattens heroes (all tiling).
Decision: ADOPT - the four-way split as a kit rule, written into the template spec: trim for plating, unique for hero silhouette parts, atlas for small repeats, tiling only for grime/noise overlays.

### Finding B8. Free seamless metal textures are useful, but check the colour law on every one
Source: 3DTextures.me Metal Plate 049 [WEAK: free-texture site]. It describes a free seamless PBR texture of weathered industrial metal plating: bold red-painted steel panels, raised border frames, diagonal cross-bracing, dome-head rivets, rust, paint chipping, and bare-metal exposure, presented as suitable for ship hulls and reinforced walls.
Inference: red-painted panels plus rivets plus rust is a good Corsair-adjacent starting point, and "seamless" plus "free" lowers the cost of testing the trim workflow. The same texture would be wrong for Ithar or Deathless without a repaint, and any cyan or teal variant in a free pack must be screened out before use, because a stray cyan panel would read as shields under the colour law.
Decision: ADAPT - use as trim-test stock for the barge experiment, with a colour-law screen on every texture before it enters the kit.

## (c) Prebuilt assets generally: marketplaces, libraries, and AI generation

### Finding C1. The CC0 tier is the only tier that is safe for a public repo without further thought
Source: Cinevva licence guide and free-asset guide [WEAK: secondary aggregators, but mutually consistent]. They state Poly Haven, Kenney, Quaternius, KayKit, and ambientCG publish everything under CC0, so nothing from them needs attribution even in a commercial game. They contrast this with per-item or royalty-free sources (itch.io packs, Fab, CGTrader, TurboSquid, Mixamo) which are fine for shipping a game but not for redistributing the files.
Source: Kenney itch.io bundle page [WEAK: store listing, but primary for its own licence]. It states all included assets are public domain (CC0) and usable for commercial projects.
Inference: for a public repo, the distinction that matters is "can I ship the game" versus "can I commit the source files to a public repo where anyone can download them standalone." CC0 clears both. Royalty-free usually clears only the first. That single distinction should gate every marketplace purchase for this project.
Decision: ADOPT - CC0 as the default licence filter for anything committed to the public repo. Any non-CC0 asset needs a written redistribution check before commit.

### Finding C2. Kenney Space Station Kit: CC0, multi-format, station-shaped
Source: Kenney Space Station Kit on itch.io [WEAK: store listing, primary for its own terms]. It lists over 80 models to create space stations and ships, in OBJ, FBX, and glTF, working with Godot, Unity, Unreal, and more, under CC0 1.0 Universal, usable in any project including commercial, no permission needed, attribution not required but appreciated, and explicitly "No generative AI was used."
Inference: 80+ CC0 models in glTF plus FBX is the lowest-friction station/prop source in this run. The kit is station-shaped, not fleet-shaped, so it fits docks, stations, and background structures better than battle hulls. Its no-AI statement also removes one provenance question that AI packs raise.
Decision: ADOPT - Kenney Space Station Kit for stations and station props, subject to a style pass. It is not a ship fleet source.

### Finding C3. KayKit Space Base Bits: CC0, single-atlas, base-shaped
Source: KayKit Space Base Bits on itch.io [WEAK: store listing, primary for its own terms]. It lists 48+ lowpoly optimised models for modular space bases, textured with a single gradient atlas texture (1024x1024, downsampleable to 128x128), free for personal and commercial use with no attribution required (CC0), in OBJ, FBX, and glTF, compatible with Unity, Godot, Unreal, Roblox, and more. Extra version ($3.95+) adds 12 assets plus an alternate texture; Source version ($5.95+) adds .blend source files. The page asks users not to resell unmodified copies or claim them as their own, which is a request on top of CC0, not a CC0 restriction, but it signals community norms.
Inference: a single gradient atlas is a masterclass in material economy (one texture for a whole base kit), and it maps directly onto the trim/atlas idea in Finding B6. The limitation is subject: space bases, not ships. The Source tier is the useful tier for a kit, because .blend source allows editing and re-export, while the free tier only allows use.
Decision: ADOPT - KayKit Space Base Bits (Source tier if editing is needed) for base/station dressing and as an atlas-economy reference. Not a ship source.

### Finding C4. Quaternius and Poly Haven models: CC0, but not ship catalogues
Source: Cinevva and Klyo free-asset guides [WEAK: secondary aggregators]. They describe Quaternius as CC0 lowpoly worlds, characters, monsters, weapons, and cities in glTF, and Poly Haven as CC0 photoreal models, textures, and HDRIs (521 models in the Sep 2026 API count cited by Cinevva), with no account needed and per-resolution downloads.
Inference: neither site is presented as a spaceship catalogue in this run. Their value is adjacent: Poly Haven for HDRIs and base materials, Quaternius for generic lowpoly props and characters if ever needed. Neither solves hulls.
Decision: ADAPT - Poly Haven for HDRIs/materials, Quaternius only for generic props. SKIP both as ship sources.

### Finding C5. Sketchfab: per-model licences, with two traps
Source: Sketchfab licence agreement [STRONG: primary licence page]. It prohibits sublicensing, selling, or distributing licensed material as a standalone file or in a way that allows third parties to download, extract, or access it as a standalone file; prohibits distributing a work whose primary value lies with the licensed material itself; and imposes extra conditions on Editorial material, including no commercial, promotional, endorsement, advertising, or merchandising use.
Source: Sketchfab licence guide [WEAK: secondary guide]. It summarises that free models use Creative Commons licences per creator, CC-BY and CC0 allow commercial use, CC-BY-NC does not, and CC-BY-ND does not allow modifications, and that store purchases include a royalty-free licence but models cannot be redistributed as standalone assets.
Inference: Sketchfab is a search engine over many licences, not a licence. A downloadable model can still be the wrong model if it is CC-BY-NC, CC-BY-ND, or Editorial. For a public repo, the standalone-file prohibition is the decisive trap: committing a purchased Sketchfab GLB to a public repo is close to the exact redistribution the licence forbids.
Decision: ADAPT - Sketchfab only with a per-model licence filter (CC0 or CC-BY, non-editorial, commercial allowed), and only for in-game use, never for committing the raw bought file to the public repo without a redistribution check. SKIP Editorial and CC-BY-NC entirely.

### Finding C6. CGTrader and Fab/Unity/Unreal stores: royalty-free means incorporated use, not redistribution
Source: CGTrader licence page [STRONG: primary licence page]. It grants a non-exclusive worldwide licence to reproduce, promote, license, sell, and display the product as an Incorporated Product, but states resale or redistribution of any product is expressly prohibited unless it is an Incorporated Product as licensed, and adds extra restrictions for Editorial products.
Source: CGTrader forum thread on free models [WEAK: forum]. It warns that free CGTrader models are distributed under Creative Commons by default, that CGTrader does not specify which CC licence applies to each free model, and that the buyer should contact the seller to clarify before planning game use, because some CC variants are restrictive.
Inference: the forum warning is weaker evidence than the licence page, but it points at a real gap: "free" on a marketplace does not mean "CC0," and "royalty-free" does not mean "public repo safe." The same logic applies to Fab and Unity/Unreal store purchases: the purchase buys incorporation into a shipped game, not a right to publish the asset files.
Decision: ADAPT - marketplace purchases only for incorporated in-game use, with the raw files kept out of the public repo (or replaced by a rebuilt kit version). SKIP any plan that commits bought FBX/GLB files directly to the public repo.

### Finding C7. AI generation: three different licence answers, not one
Source: Dev.to comparison of Tripo vs Meshy vs Rodin, checked Oct 12, 2026 [WEAK: secondary comparison, but it cites vendor pricing pages]. Its table states: Tripo free tier = No commercial use, free models are public, cheapest paid commercial tier Pro $20/month with 3,000 credits (about 200 models); Meshy free tier = Yes commercial, CC BY 4.0 with attribution required, Pro HK$170/month with 1,000 credits; Rodin free tier = Not stated, $24/month with "Commercial license included."
Source: TripoSR comparison pages [WEAK: secondary comparison sites with vendor interest]. They state TripoSR is MIT with no restrictions, Hunyuan3D 2.1 is under a Tencent Community License with commercial use permitted but with three conditions (separate licence if monthly active users exceed 1 million, agreement does not apply in the EU, UK, and South Korea, and outputs must not be used to improve any AI model other than Hunyuan3D 2.1 or derivatives), and TripoSR needs about 6 GB VRAM versus about 29 GB for the full Hunyuan3D shape-plus-texture pipeline (10 GB for shape alone).
Source: The AI Tools free-generator comparison [WEAK: secondary aggregator]. It summarises Meshy free as CC BY 4.0 with attribution, Tripo Studio free as non-commercial, TripoSR as MIT with no restrictions, Stable Fast 3D as allowed under $1M annual revenue under the Stability Community License, and Hunyuan3D as conditionally commercial under 1M monthly active users excluding EU, UK, and South Korea.
Inference: the three secondary sources agree on the shape (Tripo free = non-commercial, Meshy free = CC BY commercial, Hunyuan = conditional, TripoSR/TRELLIS = MIT), which raises confidence in the shape, but none of them replaces the vendor licence page for a shipping decision. The Hunyuan EU/UK/South Korea exclusion alone is a shipping trap for a public repo with unknown users.
Decision: ADAPT - Tripo paid tier or Meshy with attribution for AI-assisted prototyping only, TripoSR/TRELLIS (MIT) for local experiments, Hunyuan only after a territory and MAU check. SKIP Tripo free-tier outputs for anything that ships.

### Finding C8. AI quality caveats: backside guesswork, cleanup, and quotas are the norm, not the exception
Source: The AI Tools comparison [WEAK: secondary aggregator]. It lists cons: credit quotas are tight (3 to 13 models a month on hosted free tiers, credits do not roll over), back and underside geometry is always AI guesswork and should be expected to need fixing, printability and game-readiness are not guaranteed, and retopology and cleanup are often needed.
Source: Tripo vs Hunyuan comparison [WEAK: vendor-adjacent comparison]. It lists Tripo Smart Mesh P1.0 as a workflow for cleaner low-poly meshes with logical structures for real-time pipelines, implying that default AI output is not already production topology.
Inference: AI output is a concept-to-blockout accelerator, not a kit part. A fused or guessed backside is fatal for a kit, because a kit part must separate cleanly, carry hardpoints, and survive re-export. Every AI part therefore needs the same acceptance gate as a bought part (separation, UVs, ORM maps, scale, pivot), plus a licence gate.
Decision: ADAPT - AI only for blockout and reference, with a mandatory cleanup and licence gate before any AI mesh enters the kit. SKIP AI output as a direct kit part.

### Finding C9. Marketplace search is noisy: many listings are the same pack resold or mirrored
Source: Synty search results in this run. The same POLYGON Sci-Fi Space Pack description appears on the Unity Asset Store, the Synty Store, GameAssetDeals, 3DModelGenius, GFX-Hub, and GameAssetsFree, with the same 660-asset and 24-colour claims.
Inference: search results alone do not prove a listing is authorised. Unofficial mirrors and "free download" aggregators are a piracy and malware risk as well as a licence risk. The only safe purchase path is the vendor's own store or an authorised marketplace (Unity, Fab, Synty Store, itch.io author page).
Decision: SKIP - all aggregator/mirror listings, even if the description matches. Buy only from the author or authorised store.

## (d) Template and kit systems

### Finding D1. Godot scenes are the template system, if Godot wins
Source: Godot 4.2 and 4.4 instancing docs [STRONG: official docs]. They state a scene can be saved to disk, instanced as a child of another scene, and modified independently per instance (properties exposed by the source scene), and that each instance is an independent reproduction of the template scene. A Godot forum answer [WEAK: forum] summarises the same point as "there are no prefabs, instead we create a scene and then instantiate it," with scenes able to contain other scenes, and node-name lookup ($Weapon) allowing different weapons to be swapped into scenes that share the same node-name contract.
Inference: Godot's template contract is node names plus exposed properties, not a prefab file format. That maps well onto a ship kit if the kit defines a node-name contract (for example, a turret mount node always named the same way), because then a weapon scene can be swapped into any hull scene that honours the contract. The contract must be written down, or swapping will silently break.
Decision: ADOPT - if Godot wins, define the ship template as a Godot scene plus a written node-name and property contract. Do not rely on informal scene copying.

### Finding D2. Unity LOD Groups and prefabs are the reference, not the target
Source: Game Developer LOD tutorial [WEAK: tutorial]. It describes creating an empty GameObject, adding a LOD Group component, creating a child GameObject per LOD level with its own mesh filter/renderer, dragging each child into its LOD level, and tweaking distance thresholds (measured as screen-size percentage) by dragging the level bars.
Inference: the mechanism (one template object, multiple mesh children, distance/screen-size thresholds) is engine-agnostic, even though the component is Unity-specific. Babylon and Godot need the same data (which mesh at which distance, which damage state at which HP) stored in the template, even if the runtime switching code is custom.
Decision: ADAPT - copy the LOD Group data model (template plus ordered mesh list plus thresholds) into the project's own template spec, regardless of engine. Do not copy Unity prefabs.

### Finding D3. Blender Asset Browser: Link plus Library Override is the only live-update path
Source: Blender Artists threads on the Asset Browser [WEAK: forum, but consistent across three threads]. They state the Asset Browser offers Link, Append, and Append (Reuse Data); Append creates a local copy that does not update when the original changes; Link keeps the datablock linked from the original file, and a Library Override (Object menu, Relations, Make Library Override, or Outliner, ID Data, Make Library Override Hierarchy) is required to modify position and other properties in the scene file without editing the source; and a collection asset cannot be overridden from the current file, so the asset file and the animation/scene file must be separate.
Source: Blender Artists thread on material libraries [WEAK: forum]. It states Blender does not write to external files by default, so changing a material in a working file does not change the library file, and Append (Reuse Data) reuses an already-imported material instead of creating Material.001 duplicates.
Inference: the forum threads agree on a sharp rule that matters for approved parts. If a part is Appended, it is a copy, and later fixes to the approved part will not propagate. If it is Linked with an Override, the scene can move it but not silently rewrite it. That is the mechanical basis for "approved parts stay stable" in Blender, but it only works if the library file and the scene file are kept separate from the start.
Decision: ADOPT - Link plus Library Override (separate library file, separate scene file) as the Blender-side rule for approved kit parts. SKIP Append for anything that must stay in sync with an approved part.

### Finding D4. Frozen files plus override reset is the closest thing to a lock
Source: Blender Artists thread on locking a linked character [WEAK: forum]. It states the Library Override Reset operator reverts override changes but does not "lock" the character, and suggests disabling selection of the collection, making the file read-only, or handling it as a human process, with one commenter noting there may be no dedicated lock and that the problem is best solved on the human level.
Inference: Blender does not offer a true approved-part lock in the sources found this run. The workable approximation is a combination: read-only library file, linked (not appended) use, override reset as the revert path, and a human gate (a named approver plus a versioned file name) for any change to the library file. A purely technical lock should not be promised.
Decision: ADAPT - use read-only library files plus Link plus override reset plus a named approval step as the freeze mechanism. Do not claim Blender locks approved parts by itself.

### Finding D5. Geometry Nodes spaceship generators: fast variety, weak grammar
Source: Blender Market / Gumroad listings for Spaceship Generator [WEAK: store listings]. The Blender Market listing states $16, 800+ sales, Blender 3.6 to 5.2, Cycles and Eevee, Royalty Free licence, with procedural generation, randomisation, and customisable parameters. The Gumroad listing states a GeoNode setup using randomisation and customisable parameters (scale, complexity, colour) to create unique designs, with Eevee and Cycles shaders and notes in the node setup. A Blender Artists project post [WEAK: forum] describes a Geometry Nodes generator producing unlimited unique designs, with a modular system allowing custom components, responsive scaffolding, thrusters, and organic pipes, and a tidy node tree.
Source: 80.lv breakdown of a stylised ship [WEAK: trade publication]. It describes using custom Geometry Nodes with a single beam mesh plus a curve (adjustable subdivisions, twist, width) to place beams along a hull, plus Mirror and Array modifiers for structural beams, and modular elements created earlier for windows, metallic parts, and masts.
Inference: Geometry Nodes are excellent for scaffolding, beams, pipes, and repeated detail, and a generator can produce dozens of variants in minutes. Randomisation is the enemy of faction grammar unless the parameter ranges are constrained per faction (for example, Ithar fin parameters only, Chorus growth parameters only). An unconstrained generator will produce a fleet of one-offs, not a kit.
Decision: ADAPT - Geometry Nodes for scaffolding and repeatable detail inside a faction-constrained parameter set, with the barge as the parameter-lock test. SKIP unconstrained random generation as a fleet method.

### Finding D6. Code-driven generation and asset-as-code: a real pattern, but not evidenced as a ship-kit product this run
Source: 80.lv breakdown above [WEAK: trade publication] plus the Geometry Nodes project post [WEAK: forum]. Both describe code/node-driven placement (curves, arrays, mirrors, parameters) rather than hand-placing every detail, and the 80.lv piece explicitly calls the approach modular and procedural.
Inference: the pattern (a small set of authored parts plus a rule that places them) is the same pattern as a kit, whether the rule lives in Geometry Nodes, a Blender script, or game code. No dedicated "asset-as-code ship kit" product with a documented DSL surfaced in this run's searches, so no product can be recommended on this evidence. The project should define its own rule (part list plus placement rules plus naming) rather than buying a DSL.
Decision: ADAPT - adopt the pattern (authored parts plus explicit placement rules) with the project's own spec. SKIP buying a code-generation product on this evidence alone.

### Finding D7. There is no universal hardpoint standard in the sources found
Source: Arma 3 vehicle loadout wiki [WEAK: game wiki, different engine]. It shows hardpoints as string arrays (for example, B_BOMB_PYLON, B_MISSILE_PYLON, DAGR), where a weapon can be used when one or more hardpoint strings match between magazine and pylon and mass is acceptable, plus muzzlePos and muzzleEnd markers.
Source: Star Citizen ship components wiki [WEAK: fan wiki, different game]. It describes components in size classes (Size 1 fighter to Size 4 capital, weapons Size 1 to 5), where a component of a specific size can only be fitted to a hardpoint of the same size, and turrets can only be swapped for the same type of turret (hull-locked).
Inference: both systems agree on the shape (named mount plus size/type compatibility plus a muzzle marker), but neither is a standard this project can import. Star Citizen's system is also another game's IP-shaped design, not a neutral spec. The project needs its own naming scheme, and the scheme must encode the forward-only gun rule (a mount's forward arc is part of the mount data, not a hope).
Decision: ADOPT - invent a project hardpoint scheme now (mount name, size class, allowed weapon types, forward arc, muzzle marker) and write it into the template spec. SKIP importing Arma or Star Citizen naming verbatim.

### Finding D8. Damage-state variants: decals are cheap, geometry swaps are the real variant
Source: MSGDI listings [WEAK: store listings]. Both fleet packs list 8 damage decals, plus changeable decals, as part of the pack, alongside modular weapons and texture sets.
Inference: decals are a damage-state mechanism (scorch, impact marks overlaid on the intact hull), but they are not a damage-state variant (a hull with a missing panel, exposed structure, or a destroyed turret). A turn-based tactics game needs damage to read at a glance from the board, which decals alone may not do at distance. The template should therefore define damage states as explicit variants (intact, damaged, crippled, wrecked) with their own meshes or material swaps, with decals as an additional layer, not the whole system.
Decision: ADAPT - define damage states as template variants with mesh/material swaps, plus decals as a surface layer. SKIP a decals-only damage system for hero ships.

### Finding D9. LODs should be derived from the hero mesh, not re-modelled
Source: Polycount forum thread on LODs [WEAK: forum]. It advises creating lower LODs by cutting geometry manually from the highest LOD already unwrapped, so no re-unwrap is needed as long as no edge on a UV border is removed, and notes that if LODs are different models, each must be unwrapped and maps projected from the highest LOD.
Inference: deriving LODs from the hero preserves UVs, trim mapping, and hardpoint positions, which is exactly what a kit needs. Re-modelling each LOD separately risks drifting hardpoints and trim alignment, and it multiplies the approval burden (each LOD becomes a separate approved part).
Decision: ADOPT - derive LODs by reduction from the approved hero mesh, preserving UV borders and hardpoint markers, with a per-LOD silhouette check. SKIP independently modelled LODs for kit ships.

### Finding D10. Diff review for approved parts: no single tool surfaced, so the process must be the tool
Source: no dedicated "approved part diff" product surfaced in this run's searches for Blender/Godot/Babylon kit workflows. The closest mechanisms found are Blender Link plus Library Override Reset (Finding D4), versioned library files, and the general practice of comparing renders against a locked reference (described in the trim-sheet and asset-library forum threads, [WEAK: forums]).
Inference: the absence is itself a finding. If no diff tool is bought, the project must define diff review as a process: every re-export produces a render from fixed angles plus a file hash plus a changelog, and the approver compares the new render against the locked reference render before the library file is replaced. Without that process, "frozen" is just a filename.
Decision: ADAPT - define re-export diff review as a process (fixed-angle renders, hash, changelog, approver sign-off) and keep it in the template spec. SKIP assuming any tool in this run provides approved-part diffing out of the box.

### Finding D11. Houdini-style procedural approaches: not evidenced this run
Source: no Houdini-specific ship-kit product, tutorial, or workflow surfaced in this run's searches, despite searching procedural generation broadly. The procedural evidence that did surface was Blender Geometry Nodes (Finding D5) and code/node placement (Finding D6).
Inference: Houdini may well be capable of this work, but this run found no Houdini ship-kit evidence to recommend, price, or licence-check. Recommending Houdini on this evidence would be inventing a finding.
Decision: SKIP - Houdini as a recommendation from this run. If Houdini is considered later, it needs its own search and cost/licence pass.

### Finding D12. Prefab/variant systems in Babylon: the template must be data, not just a mesh
Source: no Babylon-specific prefab/variant system surfaced as a product in this run. The engine-agnostic evidence is Godot instancing (Finding D1), Unity LOD Groups (Finding D2), and the general template-plus-threshold model.
Inference: for Babylon, the template cannot be a Unity prefab or a Godot scene. It must be a data file (ship template JSON or equivalent) that lists: hull mesh plus LODs, material plus trim sheet, hardpoints with arcs and muzzle markers, damage-state variants, and variant overrides (faction tint, weapon loadout). The runtime then builds the ship from that data. This is a design decision, not a purchase.
Decision: ADOPT - a data-first ship template (mesh list, material, hardpoints, damage variants, overrides) as the Babylon-side contract, mirroring the Godot scene contract in Finding D1 so a future engine move does not require re-authoring the kit.

## (e) Fit to this project

### Fit summary
The evidence points to one conclusion: buy almost no finished ships, buy or borrow almost no finished materials, and build one template system instead. Prebuilt packs are strongest where identity does not matter (stations, props, greebles, base metals, HDRIs) and weakest where identity matters most (faction heroes, sails, flesh, bone machines). The kit-first workflow is not just a preference in the brief; it is the only workflow in this run that reconciles six factions, one colour law, and 20 ships on screen.

Worth adopting now:
- ORM as the material contract (Finding B1).
- One master trim sheet plus per-faction tint/wear variants (Finding B6), with the four-way tiling/unique/trim/atlas split (Finding B7).
- CC0 base sources for stations, props, and metals: Kenney Space Station Kit, KayKit Space Base Bits (Source tier for editing), Poly Haven plus ambientCG (Findings C2, C3, C1).
- Link plus Library Override with read-only library files and a render-plus-hash diff process for approved parts (Findings D3, D4, D10).
- LODs derived from the hero mesh, damage states as explicit variants, and a project hardpoint scheme with forward arcs (Findings D9, D8, D7).
- A data-first ship template (Babylon) mirroring a scene-plus-contract template (Godot), so the engine question does not force re-authoring (Findings D12, D1).

Worth adapting with a test first:
- Grey Fleet Armada packaging (LODs, sockets, GLB plus FBX) as a reference, after cyan recolour (Finding A1).
- MSGDI packs for stations, weapons, and damage decals, after specular-to-ORM conversion and style audit (Finding A3).
- BigMediumSmall greebles and Synty modular organisation as kitbash stock and catalogue reference, after style and licence checks (Findings A6, A9).
- Smart materials for painted metal and wear, after confirming Substance Painter availability and the full licence (Finding B3).
- Geometry Nodes for scaffolding and repeatable detail inside faction-constrained parameters (Finding D5).
- AI generation for blockout and reference only, with cleanup plus licence gates (Findings C7, C8).

Worth skipping:
- Buying a fleet pack and recolouring it into six factions (Finding A10).
- Fundamental Starships for LODs/damage that are only planned (Finding A5).
- Lowpoly bright-colour packs as fleet art (Finding A8).
- Sketchfab Editorial, CC-BY-NC, and CC-BY-ND models, and any aggregator/mirror listing (Findings C5, C9).
- Tripo free-tier outputs for shipping, and Hunyuan outputs without a territory/MAU check (Finding C7).
- Houdini as a recommendation on this run's evidence (Finding D11).
- Any plan that commits bought FBX/GLB files directly to the public repo without a redistribution check (Findings C1, C5, C6).

### Single highest-leverage starting point
Build the barge template first, and build it as a material plus geometry contract, not as a single mesh. Concretely: one Corsair battle-barge hull, modelled as separable kit parts (hull, plating, mounts, engines, greebles), dressed by one master trim sheet plus one ORM export, with a written hardpoint scheme (forward arcs, muzzle markers), derived LODs, and explicit damage-state variants, all stored as a data-first template with a read-only library file and a fixed-angle render diff on every re-export. If that template works for the barge, it scales to 20 ships because every later ship reuses the same trim, ORM, hardpoint, LOD, and damage machinery. If it does not work for the barge, no fleet pack purchase will fix it, because the failure will be in the template, not in the catalogue.

### Single biggest licensing or consistency trap
The trap is two traps wearing one coat: buying a mixed set of royalty-free or per-model-licenced packs, then committing those files to a public repo and recolouring them into factions. The licensing half is that royalty-free usually means incorporated use in a shipped game, not redistribution of the raw files, and Sketchfab/CGTrader licences explicitly prohibit standalone redistribution (Findings C5, C6). Committing a bought GLB to a public repo risks exactly that prohibition. The consistency half is that mixed packs bring mixed house styles, mixed tri counts, mixed texture resolutions, and mixed colour choices (including cyan engines that violate the shield-only colour law), and recolouring does not create Ithar sails, Chorus flesh, or Deathless bone machines (Finding A10). Either half alone would stall the kit; together they produce a fleet that is both legally unsafe to publish and visually incoherent on the board. The guard is simple: CC0 or fully licence-checked sources only in the public repo, and bought or AI parts only as incorporated, audited, rebuilt kit stock, never as raw committed files and never as faction identity.

### Open questions this run did not settle
- No Babylon-specific prefab/variant product was found; the data-first template in Finding D12 is a design proposal, not a bought solution, and needs a Babylon implementation test.
- No Houdini ship-kit evidence was found; Houdini is neither recommended nor ruled out on this evidence.
- No price was found in the snippets for BigMediumSmall Greebles or for Substance Painter itself; both need a vendor-page check before budgeting.
- No 20-ship performance measurement was found for any pack in this run; LOD ranges and tri counts are vendor claims, not benchmarks on this game.
- The Babylon PBR slot mapping in Finding B2 rests on a forum thread and needs a docs-plus-test confirmation before the export preset is locked.
