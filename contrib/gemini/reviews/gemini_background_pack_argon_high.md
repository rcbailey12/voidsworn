# Voidsworn Battlefield Background Pack (Gemini 4 Argon High)

Filed verbatim from the Gemini 4 Argon High run, October 24, 2026. Process note: the first generation run (sent 3:20 PM CDT) progressed through most of the response but the conversation then failed to persist in Gemini ("Couldn't load this chat. It doesn't exist or was deleted"). No usage cap or limit was reported, so the same prompt was re-run on a fresh chat with Argon High (sent 3:33 PM CDT). The second run completed in full and persisted as "Voidsworn Battlefield Background Pack Brief". No model was switched and nothing was retried after any cap notice.

## Part 1: Battlefield Backdrop Treatments

### 1. Belt (belt / bg_belt)

Backdrop description:

[OBSERVED]: This backdrop anchors the belt code terrain kind and builds directly upon the existing bg_belt concept plate without redesigning or replacing it. At battle zoom on PC in Babylon.js, ships appear small on screen and the background must never compete with them for attention.

[PROPOSED]: Behind the playable hex field, the camera looks down at an oblique angle into a deep, stratified mining and rubble plane stretched across a low-luminance void. The far skybox preserves the bg_belt composition of a dense, sunlit dust band bisecting a dark starfield, with massive, shadowed silicate and carbonaceous planetoids anchored in the deep background well below the combat plane. Far star points are clamped to low luminance (#7A746E PROPOSED maximum brightness) and slightly Gaussian-softened so they cannot read as distant weapon fire or engine flares at battle zoom.

Lighting and color grade:

[OBSERVED]: FAC3D is the single colour source, cyan is reserved exclusively for shields, gold is rationed strictly to patrons and Command UI, Chorus trim uses matte non-metallic chitin ridge ochre, Ithar trim uses non-metallic carved ivory filigree, and epic rarity uses violet-magenta.

[PROPOSED]: Key light enters from the upper-left at a 35-degree elevation with a warm-neutral dusty solar temperature (#D8C8B4 PROPOSED, intensity 1.15 PROPOSED). Fill/ambient hemisphere light comes from the lower-right dust bounce in cool charcoal-taupe (#2A2725 PROPOSED, intensity 0.45 PROPOSED). The global LUT color grade compresses highlights into a desaturated raw-umber and slate range (#181615 shadow floor to #8C7E70 highlight ceiling, both PROPOSED). Zero cyan (#00FFFF excluded), zero saturated patron/Command UI gold, and zero violet-magenta exist in the dust or skybox grade.

Midground dressing:

[OBSERVED]: Midground elements are background dressing only and must not alter gameplay. Any attempt to make drifting asteroids block line of sight, provide cover, or impede movement is a NEW mechanic requiring engineering scope, not a background treatment.

[PROPOSED]: Three parallax layers of jagged, pockmarked chondrite boulders and fractured slag clusters sit strictly beneath the hex plane (Z-depth offset well below ship keels-free space-frame bellies). A sparse ribbon of microscopic silicate dust motes sits between the middle boulder layer and the hex plane, lit only at grazing angles so the center of the combat arena stays visually quiet.

Hex-field treatment:

[OBSERVED]: The hex grid must remain legible at battle zoom without shouting over the ships.

[PROPOSED]: Over the dusty taupe tones of bg_belt, the standard hex grid shifts to a cool, low-saturation steel-slate line tint (#687482 PROPOSED at 0.22 alpha PROPOSED) with a faint dark-charcoal interior cell fill (#12100F PROPOSED at 0.18 alpha PROPOSED) over bright dust patches so grid lines never blend into sunlit rock faces. Edge glow is suppressed to zero on idle cells.

Ship readability:

[OBSERVED]: Deathless hulls are cold black, Ithar hulls are pale with ivory filigree trim, Chorus trim is chitin ridge ochre, and the remaining three FAC3D factions (referred to generically because their names are not given in the brief) must separate cleanly at battle zoom.

[PROPOSED]:

Collision (Chorus hulls and chitin ridge ochre trim): The warm dusty ochre and raw-umber illuminated faces of the bg_belt asteroids collide in hue and value with Chorus matte chitin ridge ochre trim and organic mid-tones. Fix: Apply a localized vignette and saturation clamp (-25% saturation PROPOSED, -18% value ceiling PROPOSED) to the bg_belt sunlit rock layer directly behind the playable hex footprint, shifting background rocks toward cool ash-grey (#4A4642 PROPOSED) so Chorus ochre remains the warmest mid-tone on screen.

Collision (Deathless cold black hulls): Deep crater shadows between boulders in bg_belt drop near pure black, swallowing Deathless silhouettes. Fix: Lift the shadow floor of the bg_belt skybox and midground boulders to a dusty charcoal minimum (#1E1C1B PROPOSED) and apply a subtle directional rim-light contribution (#B8C0C8 PROPOSED at 0.30 intensity PROPOSED) from the belt key light onto hull top/side bevels.

Collision (Generic FAC3D Faction 4 - Industrial Oxide/Rust-Iron hulls, name not given in brief): Warm iron-oxide hulls blend into brown-grey regolith. Fix: The same background desaturation clamp toward cool ash-grey (#4A4642 PROPOSED) separates warm hull materials from the rock bed.

Clean reads: Ithar pale hulls and ivory filigree pop cleanly against the darkened ash-taupe rock bed; Generic FAC3D Faction 5 (Cool Gunmetal/Slate hulls) and Generic FAC3D Faction 6 (Deep Crimson/Charcoal hulls) separate cleanly via value contrast and specular response.

Ambient motion:

[OBSERVED]: Ambient motion is restricted to slow background animation only (drift, shimmer, pulse), with nothing moving like a ship or drawing the eye during a decision.

[PROPOSED]: Midground boulders rotate on fixed axes at 0.15 to 0.35 degrees per second (PROPOSED) with zero translational velocity across the screen, preventing any peripheral confusion with moving ships. A broad, low-opacity dust sheet drifts diagonally at 2 pixels per second at 1080p equivalent scale (PROPOSED), and rare micro-impactors produce a soft, non-directional ochre dust puff (1.5-second fade-in, 3.0-second fade-out, PROPOSED) restricted to the outer margins outside the hex grid.

### 2. Station (station / bg_station)

Backdrop description:

[OBSERVED]: This backdrop anchors the station code terrain kind and builds on the existing bg_station concept plate. Ships follow space-ship rules (no wet-navy shapes or keels, guns facing forward or out to the side), and the battle tableau stand-in image is never used as a reference.

[PROPOSED]: Behind the hex field lies the vast, recessed superstructure of an orbital industrial spindle and docking ring from bg_station, viewed from above a maintenance approach sector. The far background shows shadowed structural trusses, unlit cargo bays, and cold radiator arrays receding into orbital night.

Lighting and color grade:

[OBSERVED]: Cyan is strictly reserved for shields, gold is rationed to patrons and Command UI only, epic rarity is violet-magenta, and FAC3D is the single colour source.

[PROPOSED]: Primary key light is a crisp, high-angle artificial flood and solar-reflector mix from the upper-right (#CFD8E3 PROPOSED, cool industrial white, intensity 1.20 PROPOSED). Ambient fill comes from deep structural bounce in muted petrol-slate (#1D242B PROPOSED, intensity 0.40 PROPOSED). All running lights, window strips, and beacon dots on the bg_station plate are color-clamped to muted sodium-amber (#A86A38 PROPOSED, kept dark and orange-shifted so it never reads as Command UI gold) or dim industrial olive-white (#8A948E PROPOSED). Any blue-green or cyan window tint on the raw concept plate is graded out to neutral slate (#485460 PROPOSED) so active ship shields remain the sole cyan element on screen.

Midground dressing:

[OBSERVED]: Station spars and structures are non-playable background dressing only. Treating station girders or docking arms as obstacles or cover is a NEW mechanic requiring engineering scope.

[PROPOSED]: Heavy box-truss gantry spars, recessed crane rails, and hexagonal thermal radiator fins frame the outer perimeter below the hex plane. A recessed dock floor grid lies deep beneath the playable hexes in dark gunmetal, broken up by occluded piping runs and umbilical cables that stay entirely static in silhouette.

Hex-field treatment:

[OBSERVED]: The grid must stay legible against structural geometry without shouting.

[PROPOSED]: Because bg_station contains straight architectural lines that can visually interfere with hex edges, a soft dark-slate scrim (#101418 PROPOSED at 0.32 alpha PROPOSED) is projected directly beneath the playable hex footprint to blur and darken underlying girder lines. The hex lines above use a warm tungsten-grey tint (#8C867E PROPOSED at 0.24 alpha PROPOSED) so the 60-degree hex geometry contrasts against the cool 90-degree station truss work below.

Ship readability:

[OBSERVED]: All six FAC3D factions must read clearly at battle zoom against bg_station, with all collisions named and fixed.

[PROPOSED]:

Collision (Generic FAC3D Faction 5 - Cool Gunmetal/Slate hulls, name not given in brief): Mid-grey metallic ship hulls collide directly with the steel and slate-grey plating of the bg_station superstructure. Fix: Drop the value of the bg_station plating beneath the hex footprint by 30% (capping background metal diffuse albedo at #323840 PROPOSED) and apply a roughness clamp so background girders have broad, flat matte specularity while ship hulls retain sharp specular highlights from the directional key light.

Collision (Deathless cold black hulls): Deep shadow gaps between station trusses drop to near-black and break up the silhouette of Deathless hulls crossing over gaps. Fix: Fill the inter-truss abyss beneath the hex grid with a low-lying atmospheric vent haze (#222830 PROPOSED at 0.35 alpha PROPOSED) that provides a continuous dark-grey floor behind Deathless ships, paired with a cool overhead specular rim (#9AA8B8 PROPOSED).

Clean reads: Ithar pale hulls and ivory filigree stand out sharply against the darkened slate superstructure; Chorus chitin ridge ochre hulls separate by warm-versus-cool temperature contrast; Generic FAC3D Faction 4 (Oxide/Rust-Iron) and Generic FAC3D Faction 6 (Deep Crimson/Charcoal) separate cleanly against the cool neutral steel.

Ambient motion:

[OBSERVED]: Slow background animation only; nothing may move like a ship or distract during decision-making.

[PROPOSED]: Linear motion (such as shuttles, cargo pods, or moving cranes) is completely excluded because linear translation mimics ship movement at battle zoom. Motion is limited to slow thermal steam/coolant vent plumes drifting vertically downward into the abyss (3-second cycle, #48525C PROPOSED), a slow 6-second sinusoidal dimmer pulse on distant sodium-amber warning beacons outside the hex perimeter, and slowly rotating radar/comm dishes on the far periphery (0.5 RPM PROPOSED).

### 3. Planet (planet / bg_planet)

Backdrop description:

[OBSERVED]: This backdrop anchors the planet code terrain kind and builds on the existing bg_planet concept plate.

[PROPOSED]: The camera looks across a high-orbital combat plane positioned over the sweeping curved limb of a terrestrial world from bg_planet. Roughly two-thirds of the frame sits over the sunlit/terminator cloud decks and weathered continental plates of the planet below, while the upper-right third falls off across the atmospheric limb into dark orbital space.

Lighting and color grade:

[OBSERVED]: FAC3D is the single colour source; cyan is reserved strictly for shields; gold is rationed to patrons and Command UI; Chorus uses matte chitin ridge ochre; Ithar uses carved ivory filigree; epic rarity is violet-magenta.

[PROPOSED]: Key light is crisp orbital sunlight arriving parallel to the planetary terminator (#F0E6D8 PROPOSED, intensity 1.25 PROPOSED), paired with a strong upward planetary albedo bounce light (#4A5868 PROPOSED, intensity 0.55 PROPOSED) that illuminates ship undersides and lateral faces. Critical Colour-Law Grade Shift: Planetary atmospheres naturally scatter toward cyan/cerulean at the limb. On bg_planet, the atmospheric Rayleigh scatter and ocean/cloud tints are strictly graded away from cyan into muted desaturated cobalt-indigo (#2C3E58 PROPOSED) and warm parchment-ochre cloud tops (#9E9284 PROPOSED), guaranteeing zero cyan in the planetary limb or clouds.

Midground dressing:

[OBSERVED]: Planetary limb elements are background dressing only and have no gameplay effect.

[PROPOSED]: Three parallax altitude bands of high-altitude stratocumulus cloud decks, a faint dust-haze terminator line, and tiny, out-of-focus sub-orbital tether tips or orbital marker buoys far below the hex plane give a sense of extreme altitude without cluttering the combat layer.

Hex-field treatment:

[OBSERVED]: The hex grid must remain legible across both the bright planetary disc and the dark space limb without a per-backdrop redesign.

[PROPOSED]: Because bg_planet is a split-value backdrop (bright cloud decks on one side, dark void on the other), the hex grid uses the unified dual-layer line shader (detailed in Part 2): a dark charcoal outer keyline (#161A20 PROPOSED at 0.35 alpha PROPOSED) framing a muted warm-alabaster core line (#B8B2A8 PROPOSED at 0.22 alpha PROPOSED), plus a subtle adaptive darkening fill (#141820 PROPOSED at 0.25 alpha PROPOSED) over the brightest cloud bands.

Ship readability:

[OBSERVED]: Ithar pale hulls against bright backdrops and Deathless cold black hulls against dark backdrops are high-priority collision risks that must be checked alongside all other factions.

[PROPOSED]:

Collision (Ithar pale hulls and ivory filigree trim over sunlit cloud decks): High-albedo cloud tops on bg_planet match the value and warm-ivory temperature of Ithar hulls, causing silhouette loss at battle zoom. Fix: Clamp the maximum luminance of the bg_planet cloud layer beneath the playable hex footprint to mid-tone parchment-slate (#6E6A64 PROPOSED maximum value) via an orbital shadow/terminator overlay, and enforce a subtle dark ambient-occlusion contact halo (#181C22 PROPOSED) in the hex cell beneath deployed ships.

Collision (Deathless cold black hulls over the dark space beyond the planetary limb): In the upper-right third where the planet curves into black space, Deathless hulls lose their outer edges. Fix: Extend a faint, high-altitude upper-atmosphere exosphere glow in muted indigo-slate (#222A38 PROPOSED) across the dark-space corner behind the hex grid so Deathless hulls always sit against at least a 15% luminance floor, aided by upward planetary bounce lighting on their lateral armor.

Collision (Chorus chitin ridge ochre over arid continental plates): Warm continental landmasses can approach Chorus ochre. Fix: Shift continental landmass hues beneath the cloud layer toward cool olive-basalt (#3A3E38 PROPOSED).

Clean reads: Generic FAC3D Factions 4, 5, and 6 read cleanly across the clamped mid-tone terminator zone.

Ambient motion:

[OBSERVED]: Slow background animation only; nothing that moves like a ship or pulls focus.

[PROPOSED]: Extremely slow planetary rotation and cloud-layer parallax drift (0.4 pixels per second at 1080p scale, PROPOSED) moving uniformly along the planetary curve, plus a slow dusk-side city-light or volcanic-fissure ember shimmer (#7A3E24 PROPOSED, deep rust-amber, never gold) near the terminator line.

### 4. Storm (storm / bg_storm)

Backdrop description:

[OBSERVED]: This backdrop anchors the storm code terrain kind and builds on the existing bg_storm concept plate.

[PROPOSED]: The hex field is suspended inside a turbulent magnetospheric plasma and ion-cloud front from bg_storm. Billowing, stratified walls of dark conductive dust and bruised-slate gas form a deep cauldron behind the battlefield, lit from within by diffused sheet-lightning cells located far behind the combat plane.

Lighting and color grade:

[OBSERVED]: FAC3D is the single colour source, cyan is strictly reserved for shields, gold is rationed to patrons and Command UI, and epic rarity is violet-magenta.

[PROPOSED]: Critical Colour-Law Restraint: Ion storms in sci-fi default to electric cyan, purple/magenta, or bright gold lightning, all three of which are forbidden here because cyan belongs exclusively to shields, violet-magenta belongs to epic rarity, and gold belongs to patrons/Command UI. Therefore, bg_storm is graded into a brooding, desaturated storm palette of deep storm-petrol (#161D24 PROPOSED), bruised slate-olive (#2E3836 PROPOSED), and copper-rust sheet discharges (#9E4E32 PROPOSED) with pale desaturated bone-white core arcs (#C8C2B8 PROPOSED). Key light is a diffused, high-angle storm-wall glow (#B8B0A4 PROPOSED, intensity 1.05 PROPOSED) with omnidirectional murky slate ambient fill (#262C30 PROPOSED, intensity 0.50 PROPOSED).

Midground dressing:

[OBSERVED]: Storm filaments are background dressing only. Any storm effect that alters weapon accuracy, strips shields, blocks line of sight, or damages hulls is a NEW mechanic requiring engineering scope, not a background treatment.

[PROPOSED]: Semi-transparent volumetric ribbons and ionized gas filaments curl beneath the hex grid in two depth layers, accompanied by sparse static-charge tendrils that bridge strictly between deep background cloud pillars well below the ship plane.

Hex-field treatment:

[OBSERVED]: The grid must remain stable and legible over shifting storm contrast.

[PROPOSED]: Over the churning mid-dark tones of bg_storm, the hex grid uses a crisp, desaturated bone-silver line (#9CA4AC PROPOSED at 0.25 alpha PROPOSED) backed by a dark charcoal under-stroke (#12161A PROPOSED at 0.30 alpha PROPOSED). Grid opacity is locked and completely unaffected by background sheet-lightning pulses so the tactical board never flickers.

Ship readability:

[OBSERVED]: Every faction collision against bg_storm must be named and resolved.

[PROPOSED]:

Collision (Generic FAC3D Faction 6 - Deep Crimson/Ember-Charcoal hulls, and Generic FAC3D Faction 4 - Oxide/Rust-Iron hulls, names not given in brief): Copper-rust storm discharges (#9E4E32 PROPOSED) and dark bruised clouds can collide with rust-iron or crimson-charcoal hulls during discharge peaks. Fix: Restrict copper-rust internal cloud illumination to the outer perimeter clouds beyond the hex grid, keeping the central arena cloud bed in cool desaturated slate-olive (#252D2C PROPOSED) so warm/crimson/oxide hulls pop by color temperature contrast.

Collision (Deathless cold black hulls in deep storm troughs): Dark cloud troughs between filaments can swallow Deathless hulls. Fix: Maintain a persistent, low-contrast internal cloud luminescence (#20262A PROPOSED minimum floor) across the central arena floor and boost the cool bone-white top specular rim (#C8C2B8 PROPOSED) on ship hulls.

Clean reads: Ithar pale hulls and ivory filigree read with high contrast against the dark slate-olive storm bed; Chorus chitin ridge ochre and Generic FAC3D Faction 5 (Gunmetal/Slate) separate cleanly against the desaturated olive-slate floor.

Ambient motion:

[OBSERVED]: Slow background animation only; no sudden flashes or fast arcs that draw the eye during a tactical decision.

[PROPOSED]: Sharp, stroboscopic lightning bolts are banned because sudden flashes hijack peripheral vision at battle zoom. Instead, deep background clouds undergo slow, rolling internal illumination swells (4-second ramp up, 5-second ramp down, maximum local luminance delta of +12% PROPOSED), while midground gas filaments drift lazily at 1.2 pixels per second (PROPOSED).

### 5. Graveyard (graveyard / bg_graveyard)

Backdrop description:

[OBSERVED]: This backdrop anchors the graveyard code terrain kind and builds on the existing bg_graveyard concept plate. All ship shapes must strictly obey Voidsworn fiction rules: space ships only, never wet-navy ships or keels, with guns facing forward or out to the side, never backward; the stand-in battle tableau image must never be used as a reference.

[PROPOSED]: The hex field hangs above a silent, ancient orbital debris stratum from bg_graveyard, filled with the drifting, bisected space-frames of dead capital hulls, shattered spine-trusses, and cold slag fields receding into a pale, dusty nebula veil.

Lighting and color grade:

[OBSERVED]: FAC3D is the single colour source, cyan is reserved for shields only, gold is rationed to patrons and Command UI, and epic rarity is violet-magenta.

[PROPOSED]: Key light is a cold, oblique graveyard sun from the upper-left (#C4CCD4 PROPOSED, intensity 1.10 PROPOSED) casting long, raking shadows across the deep wreck field, paired with a dusty, sepulchral moss-charcoal ambient fill (#1E2422 PROPOSED, intensity 0.42 PROPOSED). The background color grade heavily desaturates all midground wrecks into a narrow monochrome band of oxidized pewter and dead ash (#1A1E20 to #484E52 PROPOSED) so dead background hulks never display active FAC3D faction saturation.

Midground dressing:

[OBSERVED]: Wreck silhouettes are background dressing only. Any rule where wrecks block movement, provide cover, or scavenge resources is a NEW mechanic requiring engineering scope. All wreck silhouettes must be true space-ships (no wet-navy hulls or keels, only forward or lateral gun emplacements).

[PROPOSED]: Cleaved axial space-frames, skeletal engine rings, and blistered lateral-broadside casemate sections float at fixed angles 30% to 60% below the hex plane. Every midground wreck has its silhouette broken by structural fractures, missing plating, and a coat of flat matte micro-meteorite dust so it cannot be mistaken for an intact, active unit at battle zoom.

Hex-field treatment:

[OBSERVED]: The hex grid must clearly separate the playable combat plane from the complex wreck geometry below.

[PROPOSED]: A continuous, soft depth-fog plane (#181C1E PROPOSED at 0.38 alpha PROPOSED) sits immediately beneath the hex grid, pushing the midground wrecks visually downward into atmospheric recession. The hex grid lines on top use a muted sage-silver tint (#7E8A86 PROPOSED at 0.24 alpha PROPOSED) with zero idle edge glow.

Ship readability:

[OBSERVED]: Ship hulls are small at battle zoom and must never be outcompeted by background ship wrecks; all collisions must be identified and fixed.

[PROPOSED]:

Collision (All six FAC3D factions - Silhouette and Detail Frequency Collision): Because bg_graveyard contains space-ship wrecks, active ships at battle zoom risk blending into the mechanical greebles and hull lines of background wrecks directly underneath them. Fix: Apply a three-part depth separation law to all bg_graveyard midground wrecks: (1) low-pass spatial frequency filter (strip fine panel lines and small turrets from background wrecks so only macro-silhouettes remain), (2) 0% color saturation clamp (#282C30 to #42484C ash-pewter range PROPOSED), and (3) zero emissive lights on wrecks (only live ships on the hex board carry engine/window emissives and FAC3D saturation).

Collision (Deathless cold black hulls and Generic FAC3D Faction 5 Gunmetal hulls): Even desaturated, dark pewter wrecks and shadowed hull cavities can swallow Deathless black hulls and Gunmetal hulls. Fix: The depth-fog plane (#181C1E PROPOSED at 0.38 alpha PROPOSED) flattens the contrast of the wrecks beneath the hexes to a narrow #202426 to #383E42 (PROPOSED) band, allowing Deathless cold black (#0C0E10 PROPOSED) to read as a sharper, darker cutout with a crisp directional rim light (#C4CCD4 PROPOSED).

Clean reads: Once the depth-fog scrim and saturation clamp are applied to the wrecks, Ithar pale ivory hulls, Chorus chitin ridge ochre hulls, and Generic FAC3D Factions 4 and 6 read with unmistakable color and contrast authority.

Ambient motion:

[OBSERVED]: Nothing in the background may move like a ship or draw the eye during a decision.

[PROPOSED]: Midground capital wrecks are 100% stationary in translation and rotation so the player's eye never tracks a wreck thinking it is an advancing enemy ship. Ambient motion is restricted to tiny, non-ship debris splinters tumbling slowly in place (0.2 deg/sec PROPOSED) and a thin veil of graveyard dust drifting across the lower depth-fog plane at 1.0 pixel per second (PROPOSED).

### 6. Dead Star Finale (Dead Star / bg_dead_star)

Backdrop description:

[OBSERVED]: Dead Star is background only, with no gravity mechanics, serving as a finale-style backdrop at most; this is a settled ruling, not an open question. It builds directly on the existing bg_dead_star concept plate without replacing it.

[PROPOSED]: Framed as an endgame/finale vista, the hex field hangs at a steep tangent before the crushed, hyper-dense cinder of a collapsed stellar remnant from bg_dead_star. A dark, oblate iron-ash core sits off-center in the deep background, ringed by a fossilized accretion disc and a dying, filamentary magnetospheric corona against an abnormally empty, star-starved void.

Lighting and color grade:

[OBSERVED]: FAC3D is the single colour source, cyan is reserved strictly for shields, gold is rationed to patrons and Command UI only, Chorus uses matte chitin ridge ochre, Ithar uses carved ivory filigree, and epic rarity is violet-magenta.

[PROPOSED]: Critical Colour-Law Restraint: Dying stars and accretion discs often default to bright gold, violet-magenta, or cyan X-ray jets, all of which are forbidden by the colour law. bg_dead_star is graded into a stark, high-drama finale palette of cold obsidian-ash (#101216 PROPOSED), deep dying-ember crimson-rust (#6E2822 PROPOSED), and bleached bone-ash corona filaments (#B8ACA0 PROPOSED). Key light is a harsh, low-angle grazing rim light from the Dead Star corona (#D8C4B8 PROPOSED, intensity 1.30 PROPOSED) with a cold, desaturated ash ambient fill (#1C2026 PROPOSED, intensity 0.38 PROPOSED).

Midground dressing:

[OBSERVED]: Dead Star corona structure is background dressing only; there are no gravity mechanics. Adding gravitational pull, orbital drift, or radiation damage is excluded by settled ruling and would constitute a NEW mechanic requiring engineering scope.

[PROPOSED]: Calcified, vitrified planetary crust shards sit frozen in the outer fossilized accretion plane well below the hex grid, interlaced with faint, gossamer ribbons of bleached-ash coronal plasma and dark magnetic flux shadows that curve gracefully behind the battlefield.

Hex-field treatment:

[OBSERVED]: The hex grid must remain legible across both the dark stellar cinder and the brighter corona filaments.

[PROPOSED]: Over bg_dead_star, the hex grid uses a high-clarity warm-pewter line (#948C84 PROPOSED at 0.26 alpha PROPOSED) with a dark obsidian outer cuff (#0E1014 PROPOSED at 0.40 alpha PROPOSED) and a 0.22 alpha dark-slate interior hex scrim over the corona ribbon so the bright corona filaments never wash out hex edges.

Ship readability:

[OBSERVED]: Deathless cold black hulls against the dark Dead Star backdrop and Ithar pale hulls against the bright corona are primary collision risks, and all six factions must be evaluated.

[PROPOSED]:

Collision (Deathless cold black hulls against the dark Dead Star core and starless void): The obsidian skybox and dark cinder core of bg_dead_star will completely consume Deathless cold black hulls if left unadjusted. Fix: Position the broad, diffused outer fossil-dust halo (#242226 PROPOSED minimum luminance floor) directly behind the playable hex footprint while keeping the pitch-black stellar core offset to the upper margin outside the hex grid, and drive a crisp 1.35x grazing coronal rim highlight (#D8C4B8 PROPOSED) along Deathless hull edges.

Collision (Ithar pale hulls and ivory filigree against bleached bone-ash corona filaments): Where the inner corona arch crosses behind the hex board, its bleached bone-ash value collides with Ithar hulls. Fix: Cap the corona luminance beneath the hex footprint at #686058 (PROPOSED) using the hex-field under-scrim, reserving bright corona peaks (#B8ACA0 PROPOSED) for the far outer ring outside the playable grid.

Collision (Generic FAC3D Faction 6 - Deep Crimson/Ember-Charcoal hulls, name not given in brief): Deep crimson hulls can blend into the dying-ember crimson-rust (#6E2822 PROPOSED) outer accretion band. Fix: Restrict the crimson-rust accretion tint to the deep perimeter ring and grade the dust sheet directly under the hex grid toward neutral warm-ash (#282424 PROPOSED).

Clean reads: Chorus chitin ridge ochre, Generic FAC3D Faction 4 (Oxide/Rust-Iron), and Generic FAC3D Faction 5 (Gunmetal/Slate) separate cleanly against the neutral warm-ash arena floor.

Ambient motion:

[OBSERVED]: Slow background animation only; nothing moving like a ship or pulling attention during decisions.

[PROPOSED]: Coronal plasma filaments exhibit an ultra-slow, radial heat-shimmer undulation (8-second period, PROPOSED) and the outer fossilized accretion ring rotates imperceptibly (0.08 degrees per second, PROPOSED) around the dead core. No radial particle ejection or inward-falling sparks are permitted inside the hex footprint, both to avoid eye distraction and to prevent falsely implying a gravity pull mechanic.

## Part 2: Hex-Field Dressing System

### Unified Grid Architecture (All Six Backdrops)

[OBSERVED]: A single consistent grid treatment must operate across all six backdrops (bg_belt, bg_station, bg_planet, bg_storm, bg_graveyard, bg_dead_star) on PC in Babylon.js without requiring a per-backdrop redesign, while keeping clear of cyan (shields only), gold (patrons and Command UI only), and violet-magenta (epic rarity only).

[PROPOSED]: The hex grid is rendered as a single instanced or custom-shader Babylon.js mesh plane featuring a Dual-Stroke Contrast Envelope and an Adaptive Arena Under-Scrim:

Default Inner Core Line (PROPOSED): 1.5px screen-space width in neutral warm-steel (#8A9098 PROPOSED default base) at 0.24 alpha (PROPOSED), modulated by a plus-or-minus 12% per-backdrop tint uniform.

Default Outer Cuff / Keyline (PROPOSED): 1.0px dark charcoal-obsidian border (#12151A PROPOSED) at 0.35 alpha (PROPOSED) flanking both sides of the inner core line.

Distance Falloff (PROPOSED): Outer boundary hex edges fade smoothly by 20% opacity on their exterior faces so the board sits naturally inside the scene rather than looking like a hard-pasted sticker.

### Behaviour Over Bright vs. Dark Backdrops

[OBSERVED]: The grid must stay usable over both bright and dark backdrop zones without shouting over the ships.

[PROPOSED]:

Over Dark Backdrops (bg_graveyard hollows, bg_dead_star void, bg_station truss gaps): The dark outer cuff (#12151A PROPOSED) disappears naturally into the dark background while the lighter inner core line (#8A9098 PROPOSED at 0.24 alpha) carries the hex legibility cleanly without blooming.

Over Bright Backdrops (bg_planet sunlit cloud decks, bg_belt sunlit boulders, bg_dead_star corona crossings): Every playable hex cell includes a subtle interior Arena Under-Scrim fill (#14161A PROPOSED) whose alpha scales from 0.15 (over dark scenes) to 0.35 (over bright scenes), accompanied by the 1.0px dark outer cuff (#12151A PROPOSED). When a bright cloud or sunlit asteroid passes under a hex line, the dark outer cuff and interior under-scrim guarantee contrast so the pale inner line never washes out.

### Interactive Hex States (Hovered and Selected)

[OBSERVED]: Interactive states must never use cyan (reserved for shields), patron/Command UI gold, or epic violet-magenta.

[PROPOSED]:

Hovered Hex Treatment:

Line Color and Brightness (PROPOSED): Crisp tactical bone-white (#DCE2E8 PROPOSED) at 0.65 alpha (PROPOSED), expanding inner stroke width from 1.5px to 2.2px (PROPOSED).

Interior Fill (PROPOSED): Soft neutral slate-silver fill (#8A94A0 PROPOSED) at 0.12 alpha (PROPOSED) with an inward 4px soft gradient feather (zero bloom).

Selected Hex Treatment:

Line Color and Brightness (PROPOSED): High-clarity warm alabaster-platinum (#F2ECE4 PROPOSED, strictly desaturated bone/platinum so it never crosses into Command UI gold) at 0.90 alpha (PROPOSED), 2.5px stroke width with sharp corner ticks on the six hex vertices.

Interior Fill and Edge Glow (PROPOSED): Subtle inner bevel ring (#D8D2C8 PROPOSED at 0.22 alpha, 6px inset feather) and a dark grounding center fill (#101216 PROPOSED at 0.28 alpha) that increases contrast directly beneath the selected ship.

### Per-Backdrop Uniform Adjustments (PROPOSED)

| Backdrop | Core Line Tint (PROPOSED) | Line Alpha (PROPOSED) | Outer Cuff Alpha (PROPOSED) | Interior Under-Scrim Alpha (PROPOSED) | Purpose (PROPOSED) |
|---|---|---|---|---|---|
| bg_belt | #687482 (Cool Steel-Slate) | 0.22 | 0.32 | 0.18 | Separates cool hex lines from warm dusty taupe boulders. |
| bg_station | #8C867E (Warm Tungsten-Grey) | 0.24 | 0.38 | 0.32 | Separates warm hex geometry from cool rectilinear station girders. |
| bg_planet | #B8B2A8 (Warm Alabaster-Grey) | 0.22 | 0.35 | 0.25 | Dual-cuff contrast holds across bright clouds and dark orbital limb. |
| bg_storm | #9CA4AC (Bone-Silver) | 0.25 | 0.30 | 0.20 | Locks static grid legibility over dark olive-slate ion clouds. |
| bg_graveyard | #7E8A86 (Sage-Silver) | 0.24 | 0.35 | 0.38 | Heavy under-scrim fog pushes midground ship wrecks down in depth. |
| bg_dead_star | #948C84 (Warm Pewter) | 0.26 | 0.40 | 0.22 | Anchors board over both obsidian cinder and bleached-ash corona. |

## Part 3: Readability Collision Table

[OBSERVED]: This table evaluates all six factions across all six backdrops at battle zoom. Deathless (cold black hulls), Ithar (pale hulls with carved ivory filigree trim), and Chorus (matte chitin ridge ochre trim) are explicitly named in the brief. Because the remaining three faction names are not given in the brief, they are described generically by their FAC3D hull value/temperature families per the standing rule against inventing names.

| Faction (Observed Name or Generic FAC3D Descriptor) | belt (bg_belt) | station (bg_station) | planet (bg_planet) | storm (bg_storm) | graveyard (bg_graveyard) | Dead Star (bg_dead_star) |
|---|---|---|---|---|---|---|
| 1. Deathless (Cold black hulls) [OBSERVED] | COLLISION [PROPOSED] Deep shadow gaps between boulders swallow black hulls. Fix: Lift shadow floor to #1E1C1B (PROPOSED) and add 0.30 cool directional rim light (#B8C0C8 PROPOSED). | COLLISION [PROPOSED] Dark abyss gaps between station trusses merge with black hulls. Fix: Add #222830 (0.35 alpha PROPOSED) vent-haze floor beneath hexes plus #9AA8B8 (PROPOSED) top specular rim. | COLLISION [PROPOSED] Dark space beyond the planetary limb eats black hull edges. Fix: Extend #222A38 (PROPOSED) indigo-slate upper-atmosphere exosphere glow across the void corner plus planetary upward bounce light. | COLLISION [PROPOSED] Deep storm troughs drop too close to black. Fix: Clamp central storm floor to #20262A minimum (PROPOSED) and drive #C8C2B8 (PROPOSED) top rim specular. | COLLISION [PROPOSED] Shadowed wreck cavities collide with black silhouettes. Fix: Apply #181C1E (0.38 alpha PROPOSED) depth-fog plane over wrecks so wrecks flatten to #202426+ and Deathless hulls read as crisp dark cutouts. | COLLISION [PROPOSED] Obsidian void and dark cinder core swallow black hulls. Fix: Keep dark core outside hex footprint, place #242226 (PROPOSED) fossil-dust floor behind hexes, and boost grazing coronal rim (#D8C4B8 PROPOSED at 1.35x). |
| 2. Ithar (Pale hulls, carved ivory filigree trim) [OBSERVED] | CLEAN [PROPOSED] High-value pale ivory hulls separate cleanly against mid-dark ash-taupe boulders (#4A4642 ceiling PROPOSED). | CLEAN [PROPOSED] Pale ivory hulls and non-metallic filigree pop sharply against dark petrol-slate (#323840 ceiling PROPOSED) station plating. | COLLISION [PROPOSED] Sunlit cloud decks match Ithar pale hull value and warm-ivory tone. Fix: Clamp cloud luminance beneath hexes to #6E6A64 (PROPOSED) via terminator shadow and add #181C22 (PROPOSED) under-ship hex contact halo. | COLLISION [PROPOSED] Bright bone-white core arcs (#C8C2B8 PROPOSED) can clip Ithar silhouettes if placed under hexes. Fix: Restrict bright storm arcs to outer perimeter outside the hex grid; keep central cloud bed at #252D2C (PROPOSED). | CLEAN [PROPOSED] Pale ivory hulls stand out cleanly over desaturated dark pewter wrecks and #181C1E (PROPOSED) depth fog. | COLLISION [PROPOSED] Bleached bone-ash corona filaments (#B8ACA0 PROPOSED) collide with pale hulls. Fix: Clamp corona value under the hex grid to #686058 (PROPOSED) via the hex under-scrim; keep bright corona peaks outside the board. |
| 3. Chorus (Chitin ridge ochre trim, matte non-metallic) [OBSERVED] | COLLISION [PROPOSED] Warm sunlit silicate boulders match chitin ridge ochre hue and mid-tone value. Fix: Desaturate -25% and darken -18% the bg_belt rock bed under the hex grid toward cool ash (#4A4642 PROPOSED). | CLEAN [PROPOSED] Warm matte ochre chitin contrasts strongly against cool blue-slate (#1D242B to #323840 PROPOSED) metallic girders. | COLLISION [PROPOSED] Warm arid continental plates and parchment clouds approach ochre tones. Fix: Grade continental landmasses beneath the hexes toward cool olive-basalt (#3A3E38 PROPOSED). | CLEAN [PROPOSED] Matte ochre reads cleanly against cool bruised slate-olive (#252D2C PROPOSED) central storm clouds. | COLLISION [PROPOSED] Organic chitin ridge shapes can get busy over complex mechanical wreck silhouettes. Fix: The 0% saturation clamp and #181C1E (0.38 alpha PROPOSED) depth-fog scrim on wrecks isolates Chorus warm ochre saturation. | CLEAN [PROPOSED] Warm ochre separates cleanly against cold obsidian-ash (#282424 PROPOSED) and crimson-rust perimeter accents. |
| 4. Unlisted FAC3D Faction A (Warm Oxide / Rust-Iron Mid-Tone Hulls - name not in brief) [PROPOSED descriptor] | COLLISION [PROPOSED] Warm iron-oxide hulls blend into brown-taupe asteroid regolith. Fix: Shift bg_belt central rock bed toward cool desaturated ash-grey (#4A4642 PROPOSED). | CLEAN [PROPOSED] Warm rust-oxide hulls separate by color temperature against cool petrol-slate station trusses. | CLEAN [PROPOSED] Mid-dark warm oxide reads cleanly against cobalt-indigo limb and parchment-slate terminator clouds. | COLLISION [PROPOSED] Copper-rust storm discharges (#9E4E32 PROPOSED) match warm oxide hulls. Fix: Confine copper-rust glow to outer perimeter cloud walls; keep central arena clouds cool slate-olive (#252D2C PROPOSED). | COLLISION [PROPOSED] Weathered industrial hulls mimic damaged background wrecks. Fix: Enforce 0% saturation clamp, low-pass detail filter, and #181C1E (PROPOSED) fog scrim on all background wrecks. | COLLISION [PROPOSED] Warm oxide hulls approach the dying-ember rust (#6E2822 PROPOSED) outer accretion band. Fix: Grade the accretion dust directly beneath the hex grid to neutral warm-ash (#282424 PROPOSED). |
| 5. Unlisted FAC3D Faction B (Cool Gunmetal / Slate-Grey Hulls - name not in brief) [PROPOSED descriptor] | CLEAN [PROPOSED] Sharp metallic gunmetal specularity separates against matte dusty taupe rocks. | COLLISION [PROPOSED] Gunmetal/slate hulls collide directly in hue and value with bg_station steel plating. Fix: Cap station girder albedo under hexes at #323840 (PROPOSED) with flat matte roughness so ship specular highlights pop. | COLLISION [PROPOSED] Slate-grey hulls can merge into the mid-tone terminator transition band. Fix: Boost upward planetary albedo bounce (#4A5868 PROPOSED) and crisp solar key light (1.25 intensity PROPOSED) to create strong top/bottom bevel contrast on hulls. | COLLISION [PROPOSED] Slate-grey hulls approach the value of dark slate-olive storm clouds. Fix: Keep storm clouds soft and diffuse while driving sharp metallic specular highlights (#B8B0A4 PROPOSED key light) on hull armor bevels. | COLLISION [PROPOSED] Gunmetal active ships collide directly with desaturated pewter ship wrecks. Fix: Clamp background wrecks to flat matte roughness behind the #181C1E (0.38 alpha PROPOSED) fog scrim; keep active ship emissives and sharp speculars exclusive to the hex plane. | CLEAN [PROPOSED] Cool gunmetal hulls separate cleanly against the warm-ash and crimson-rust Dead Star palette. |
| 6. Unlisted FAC3D Faction C (Deep Crimson / Ember-Charcoal Hulls - name not in brief) [PROPOSED descriptor] | CLEAN [PROPOSED] Deep crimson-charcoal hulls separate cleanly against desaturated ash-taupe boulders. | CLEAN [PROPOSED] Saturated crimson-charcoal contrasts against cool neutral station steel (#1D242B PROPOSED). | CLEAN [PROPOSED] Deep crimson-charcoal stands out against both parchment-slate clouds and cobalt-indigo atmosphere. | COLLISION [PROPOSED] Deep crimson-charcoal hulls collide with dark storm troughs and copper-rust flashes. Fix: Floor central storm cloud luminance at #252D2C (PROPOSED) in cool olive-slate and move copper-rust flashes outside the hex perimeter. | COLLISION [PROPOSED] Dark charcoal hull sections merge with deep wreck shadows. Fix: The #181C1E (0.38 alpha PROPOSED) depth-fog floor lifts and flattens background shadows so dark crimson-charcoal hulls keep crisp edges. | COLLISION [PROPOSED] Deep crimson hulls collide directly with the dying-ember crimson-rust (#6E2822 PROPOSED) accretion disc. Fix: Restrict #6E2822 crimson-rust to the far outer ring outside the board; grade the central arena floor to neutral ash (#282424 PROPOSED). |

## Part 4: Desktop Presentation Notes

[OBSERVED]: The game is PC-only in Babylon.js with a desktop GPU budget as the design floor (no phone tier or phone readability requirement), building on the existing bg_belt, bg_station, bg_planet, bg_storm, bg_graveyard, and bg_dead_star concept plates. Any effort or cost estimate is labeled below as a rough guess.

### Per-Backdrop Load, Rendering Split, and Graceful Degradation (PROPOSED)

| Backdrop | Qualitative Ambient and Lighting Load (PROPOSED) | Static Image Elements (PROPOSED) | Live Babylon.js Rendering Elements (PROPOSED) | Graceful Degradation on Lower Desktop Quality Settings (PROPOSED) | Frame-Time / Setup Cost (PROPOSED - rough guess) |
|---|---|---|---|---|---|
| bg_belt | Light to Moderate | Deep skybox (bg_belt base plate, 4K BC7 DDS equirectangular/projected dome) and far dust band. | 24 to 40 hardware-instanced low-poly PBR asteroid meshes in 2 parallax tiers; 1 GPU dust-sheet billboard ribbon; directional solar key + hemisphere bounce light. | Drop instanced midground asteroid count by 50%, disable micro-impactor puff particles, and bake boulder lighting into unlit vertex/texture color. | ~0.25 ms to 0.40 ms GPU frame time on midrange desktop GPU (PROPOSED - rough guess). |
| bg_station | Light | Deep superstructure plate (bg_station 4K BC7 DDS) with baked ambient occlusion and sodium-amber emissive mask. | 2 parallax layers of modular low-poly gantry/radiator meshes around perimeter; 4 to 6 soft GPU steam-vent billboards; slow UV/sine pulse shader on beacon emissive mask. | Disable live steam-vent billboards, merge perimeter gantry meshes into a single static baked parallax card layer, and switch beacon pulse to static emissive. | ~0.20 ms to 0.35 ms GPU frame time (PROPOSED - rough guess). |
| bg_planet | Light | Planetary surface, continental base (bg_planet 4K BC7 DDS), and outer exosphere glow gradient card. | 2 UV-scrolling alpha-blended cloud-deck mesh domes with terminator normal-map grazing response; directional solar key + upward planetary bounce hemisphere light. | Collapse 2 live normal-mapped cloud domes into a single unlit UV-scrolling cloud layer and disable sub-orbital marker buoy parallax dots. | ~0.15 ms to 0.30 ms GPU frame time (PROPOSED - rough guess). |
| bg_storm | Heavy | Far storm cauldron base plate (bg_storm 4K BC7 DDS) with multi-channel illumination masks (R/G/B zones for rolling internal glow). | 12 to 18 overlapping volumetric-style soft-particle gas ribbons (depth-fade alpha billboards); live shader driving slow 3-zone internal cloud luminance swells. | Reduce overlapping gas-ribbon billboards by 60% to eliminate alpha-overdraw cost; keep the cheap 3-channel mask shader on the static bg_storm plate so the storm still swells without overdraw. | ~0.60 ms to 1.10 ms GPU frame time due to alpha overdraw (PROPOSED - rough guess). |
| bg_graveyard | Moderate | Far nebula veil and deep slag field (bg_graveyard 4K BC7 DDS) plus the continuous #181C1E depth-fog scrim plane. | 8 to 14 decimated, matte-clamped space-ship wreck hulls in midground (strictly forward/lateral gun geometry, zero wet-navy shapes); sparse tumbling micro-splinter instances. | Replace 3D midground wreck meshes with pre-rendered 2.5D parallax imposter cards (with baked depth-fog tint) and disable micro-splinter instances. | ~0.35 ms to 0.60 ms GPU frame time (PROPOSED - rough guess). |
| bg_dead_star | Moderate to Heavy | Obsidian void, dead stellar cinder core, and far accretion ring (bg_dead_star 4K BC7 DDS). | Custom UV-warping flow-map shader on the coronal plasma ribbon mesh; 15 to 25 instanced vitrified crust shards on an orbital transform node; high-intensity grazing rim light. | Freeze the 3D crust shard ring into a slow-rotating 2D ring card and step down the coronal flow-map shader from dual-octave distortion to a single-texture UV scroll. | ~0.45 ms to 0.80 ms GPU frame time (PROPOSED - rough guess). |

### Shared Babylon.js Desktop Implementation Notes (PROPOSED)

Zero Post-Process Bleed on Backdrops (PROPOSED): Keep all six skybox plates and midground dressing layers outside the bloom threshold (emissiveIntensity < 0.85 PROPOSED) so Babylon.js DefaultRenderingPipeline bloom activates exclusively on ship weapon fire, engine thrusters, and cyan shield impacts.

Unified Scene Lighting Rig (PROPOSED - rough guess): Every backdrop uses the exact same two-light rig cost (one DirectionalLight for the key/rim light + one HemisphericLight for the ambient/bounce floor, with shadow-map generation disabled on background dressing meshes), keeping per-ship shader compilation identical across all six terrains (~0.10 ms lighting overhead, PROPOSED - rough guess).
