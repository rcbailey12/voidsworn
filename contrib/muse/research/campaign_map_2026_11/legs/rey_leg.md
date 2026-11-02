# Campaign map: next step

## 1. Headline

Keep the one screen per sector system G3 built, and spend the next pass on matching it to the battle world and making route choice readable at a glance. Reuse the battle sky bake, side lit planets, and five rock kinds so map and battles look like the same places, and rebuild panels and text in that register. The technique that matters most is zoom dependent information, from Sins of a Solar Empire 2 and Homeworld 3: far out the map shows only the decision, near in it shows the detail, so cinematic scale and clear danger and reward never fight.

## 2. Research notes per game

### Sins of a Solar Empire 2

Camera. The official wiki describes zoom from the whole galaxy to the smallest fighter, zoom to cursor as default, a standard centre zoom, and double click to lock onto an object (https://wiki.sinsofasolarempire.com/index.php?title=Gameplay&direction=prev&oldid=472&mobileaction=toggle_view_mobile). One view carries strategy and battle, with no separate map screen.

Scale tricks. Stardock says planets orbit, migrating across the map and severing and forging new phase lane connections, with forecast tools for future positions (https://www.stardock.com/games/article/528030/evolution-of-sins-ii-pt-1---top-new-features). The wiki notes distances of millions of miles are crossed by phase jumps taking seconds (wiki link above). Scale comes from orbit motion and jump time, not literal distance.

Icons over 3D. The wiki describes an Empire Tree on the left edge listing planets, structures, and ships, giving control without panning (wiki link above). My impression: the tree, pins, and report icons do the work labels cannot do at galaxy zoom, while 3D objects carry identity near in.

Route lines. The wiki says reachable pairs are shown by faint phase lanes, and lanes create bottlenecks (wiki link above). Stardock adds that orbiting planets change which lanes exist (Stardock link above). Danger on a lane shows as change and forecast, not only colour.

Fog and information hiding. No full fog model is established by these sources, so this is my impression: reports, pings, and the Empire Tree privilege owned and observed space over a fully revealed board.

Danger and reward advertising. Stardock frames orbiting planets as making secure planets vulnerable, with forecast tools to plan invasions or defences in advance (Stardock link above). Danger is advertised as future lane change, before commitment.

### Stellaris

Camera. This is my impression, as no clean primary camera statement was reachable: Stellaris splits a flat galaxy view of stars and hyperlanes from a detailed system view, and crossing that boundary is the main camera move, not free 3D orbit.

Scale tricks. The game settings wiki lists galaxies of 200 to 1,000 stars and hyperlane density from 0.5 times to full, where full density removes clusters and choke points (https://stellaris.fandom.com/wiki/Game_settings). Scale is a density choice: sparse lanes make geography, dense lanes flatten it.

Icons over 3D. A patch note summary says the galaxy map shows only claimable resources and colonisable planets while details map mode is off, with ship counts grouped below fleet power. My impression: icons are filtered by map mode so the far view stays legible.

Route lines. The settings wiki shows hyperlane density as a generation setting (settings link above). Coverage of the Nemesis update describes hyperlanes creating choke points and roundabout routes (https://www.gamingonlinux.com/2021/01/stellaris-will-get-more-mysterious-with-intel-gathering-and-espionage-systems/page=1/). Lines are plain and permanent; meaning comes from ownership and what sits at each end.

Fog and information hiding. Reporting on the Paradox dev diaries says the newer fog of war blocks more information, and intel from 0 to 100 across government, military, diplomatic, economic, and technology categories gates what reports reveal (GamingOnLinux link above). A second summary says only the highest intel reveals military resources and deployment (https://solarcrossgames.co.uk/stellaris/intel-and-infiltration-in-stellaris-nemesis/). Information is tiered, not binary.

Danger and reward advertising. My impression: danger is advertised late by design, with fleet detail only at high intel, while resources and colonisable worlds surface early as rewards.

### Homeworld (Homeworld 3, with Homeworld 2 manual evidence)

Camera. The Homeworld 2 manual says entering the Sensors Manager zooms out to show the entire circular mission map, with a compass beyond the active area (https://archive.org/download/Macintosh_Garden_Manuals_2021_G-I/homeworld2_manual_text.pdf). Homeworld 3 keeps a free 3D battle camera, and its developer update discusses faster default camera movement and a legacy scheme matching Homeworld 2 Remastered (https://www.homeworlduniverse.com/war-games-feedback/).

Scale tricks. The developer update explains NLIPS, Non Linear Inverse Perspective Scrolling, which scales ships up relative to camera distance so fighters can be seen and selected when zoomed far out (Homeworld Universe link above). Scale is faked openly, and the Sensors Manager replaces the pretty view with an abstract one when distance would defeat it.

Icons over 3D. The Homeworld 2 manual says sensor fields show only in the Sensors Manager as blue spheres, enemy ships in red, neutral and allied ships in yellow, your ships in green, and all activities including building and jumps can be done there (manual link above). Colour coded dots replace models in that view.

Route lines. No fixed lane network appears in these sources, so this is my impression: movement is free in 3D, shown by orders and waypoints, and long moves are plotted in the Sensors Manager. Lanes are a readability aid this game already has and Homeworld does without.

Fog and information hiding. The manual ties visibility to sensor range spheres in the Sensors Manager (manual link above). My impression: fog is local and sensor based, centred on your fleet, not a galaxy wide intel tier.

Danger and reward advertising. Secondary guide coverage notes the Sensors Manager visualises nearby threats and resource nodes easily (sourced, not primary). Switch view, and threats and resources become symbols first, models second.

### Endless Space 2

Camera. The official manual says drag to move the Galaxy Map, scroll at borders or use arrow keys, and zoom with the mouse wheel or Page Up and Page Down (https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/392110/manuals/ES2_PC_OM_JAN_2018_210x297_UK_HR.PDF?t=1789465620). It is a node map camera, closest to this game.

Scale tricks. The manual says the galaxy is nodes connected by starlanes, each node a point of interest such as a star system or asteroid field, some nodes reachable only by warp drive outside starlanes, and linked groups forming constellations (manual link above). Scale comes from constellation grouping and zoom to system detail, not empty distance.

Icons over 3D. The manual lists node traits including strategic or luxury resources, anomalies, and curiosities (manual link above). My impression: small trait icons beside the node do the advertising, and the scan view in the manual contents is the alternate information view over the same nodes.

Route lines. Starlanes are the default movement graph and warp is the slower free movement exception (manual link above). Off lane movement reads as special precisely because it has no line.

Fog and information hiding. The manual says at the start you see little beyond your first fleets, unexplored areas carry a blue geometric overlay that disappears as fleets move or probes launch, and discovered areas outside vision become darker (manual link above). Three states, unexplored, known but unwatched, and watched, show by overlay and brightness alone.

Danger and reward advertising. My impression from the manual: rewards advertise early through node traits and curiosities, while danger is mostly what fog withholds. Probes buy information before a fleet commits.

## 3. Steal and avoid

Steal, tied to pack section 4:

1. Zoom dependent information (Sins 2, Homeworld 3 NLIPS). One fleet, one screen per sector, route choice as the core decision. Far out show stop kind, danger band, and best reward only. Near in show names, tags, and faction detail. This serves R72, cinematic first with information on demand.
2. Three state shading (Endless Space 2). Presentation only version: visited and burned stops dim and cool, stops ahead stay bright, and the boss stays partly veiled in disc light until the player is two stops away. No scouting mechanic is added; states describe progress the run already tracks.
3. Tiered intel presentation (Stellaris). Presentation only version: a stop one lane away shows full danger and reward, a stop two or more lanes away shows danger band and reward kind but not exact numbers, matching how the Nemesis clock and cores reveal more as the player closes in.
4. Forecast strip, not a moving map (Sins 2). Show the next sector as a fixed preview arc at the map edge: faction colours, sky colour, boss silhouette. The player plans without any lane ever moving.
5. Scan style alternate view (Endless Space 2, Homeworld). A held key flattens the system to symbols, threat diamonds, lane colours, and reward tags over the dimmed 3D scene, then releases back to cinematic. One fleet and about a dozen stops make this cheap, and it solves panel crowding.

Avoid:

1. Orbiting stops and changing lanes (Sins 2). They contradict forward only lanes and a fixed reachable elite route, and would make safest and richest route lighting dishonest.
2. Galaxy scale map modes (Stellaris). Hundreds of stars need modes; one sector does not. Modes would hide the danger and reward choice the run turns on.
3. A separate abstract manager as the real map (Homeworld). It works for free 3D battles that are hard to read. Here the 3D system is what the owner asked for in R51; replacing it with dots would undo G3.
4. Full fog of war (Endless Space 2, Stellaris). Hiding stop kinds or rewards would fight route choice under scarcity, which needs advertised trade offs. Keep only the light veiling in steal item 2.
5. NLIPS enlargement of stop objects. G3 fixed small hulls with rim light and framing (docs/shots/g3_campaign/README.md:25). Enlarging objects with zoom would break shared scale with battle planets and moons.

## 4. The design

System view. Keep one 3D system per sector, Hollow Sun at the centre. Change the sky to the battle bake for that sector (world_bake.gd), so map sky and battle sky are one bake per region, with pin sharp stars and the galaxy band. Relight the Hollow Sun with the battle dead star treatment: two part disc, sky lensing, bent far side over the shadow. The G3 sun already has lensed arcs, a photon ring, and Doppler beaming (docs/shots/g3_campaign/README.md:25); this unifies its build with the battle version instead of keeping a cousin. Add battle depth cues at map scale: dust near camera, gas wisps at middle distance.

Lanes. Keep forward only lanes and fleet token flight. Draw a dim base line for every lane ahead, brighter directional flow on lanes from the current stop, and extend the existing safest and richest lighting so hovering a stop two lanes away lights the whole chain. Burned lanes behind fade to dark ash and lose flow, showing no going back without text. Use the board look holo register from board_look.gd for lane glow, so battle and map share a language.

Stops. Planet edge stops use world_planet.gd planets with side lighting, atmosphere glow, clouds, night lights, rings, and moons, replacing the flatter G3 planet stop. Belt stops use world_rocks.gd with the region rock kind, shader craters, true dark side, and slow tumble, as a belt stream segment. Graveyard stops keep real death pieces, plus one tumbling battle sized rock for scale. Station, shipyard, drydock, and tender keep their G3 silhouettes, taking battle lighting: side key, warm rim, and cool fill. Every stop gains a small marker ring in the holder faction colour, visible far out, while the object carries detail near in.

Panels and text. This is the main spend, as panels and text are the least rebuilt part. Use one panel family styled on the battle pages that already sit over the dimmed system (docs/shots/g3_campaign/README.md:45): same dim level, same headers, one type scale, short labels. At full zoom a stop shows name and one reward tag only, following existing label priority rules. Hover shows kind, holder, danger band, and reward in four short lines. The sidebar keeps admiral, fleet, and cores in range, and loses repeated place type text, already moved to hover only by G3. All text uses current lore names, with no leftover terms.

Sector transitions. Beating the boss triggers a jump flight: the camera follows the fleet token out toward the Hollow Sun, disc light fills the screen, and the next sector resolves on the other side with its own sky bake and faction colours. Before the boss, the next sector shows only as the forecast arc from steal item 4, beyond the boss stop toward the Hollow Sun. The three sectors ring the same Hollow Sun, so the sun stays the fixed centre and only disc tint and sky change per sector.

Information layer. Danger stays as holographic threat diamonds in the danger band colour (docs/shots/g3_campaign/README.md:25), with diamond count visible at all zooms and size growing on hover. Rewards show one tag far out, full lines on hover. Cores in range move from a sidebar list into the sky: each core gets a faint coloured point on the disc rim toward the sector where it can appear, name on hover, with the sidebar list kept as the text version. The Nemesis clock becomes a ring segment around the Hollow Sun shadow, filling in Nemesis colour, keeping the existing full state change to every fight. The scan toggle is the fallback whenever this crowds.

## 5. Mock layout per sector

Sector 1. Hollow Sun centre frame, slightly high, disc running left to right. Stops fan forward from lower left, where the fleet arrives, to upper right, where the flagship waits beyond a belt stop. On arrival the player sees four to five bright stops ahead, the boss as a large flagship silhouette, and the sector 2 forecast arc as a Hegemony blue and Hullbreaker orange smear beyond the boss. Mid sector, burned stops dim behind, and two chains compete: one past a side lit terran planet stop, one through the belt at the edge of Hegemony space. At the boss the default view tightens, the flagship fills the right third, and threat diamonds stack in the highest band. Look: warm disc light, stone and iron rocks, steel blue and scrap orange rings, the calmest sky bake.

Sector 2. Same centre sun, Chorus flesh tones and Glasswrights clear light entering. Stops sit in two arcs: an inner arc near the disc with event signals in nebula pockets, an outer arc with shipyard and drydock. On arrival the inner arc reads first, unknown signals pulsing in gas wisps. Mid sector, routes split between a rich inner line past a volcanic planet stop and a safer outer line past repair stops, and safest and richest lighting points to different chains. At the boss the flagship waits across the disc shadow, framed by lensed arcs, with two core points on the disc rim. Look: shifted sky bake hue, carbon and ice rocks added, wet organic light on Chorus stops, faceted crystal glints on Glasswrights stops using battle crystal rock material at small scale.

Sector 3. The sun reads largest: stops sit closer to the disc in a tighter spiral ending at a flagship almost touching the photon ring. Eclipse dark violet and black enters, with trapped light points on Eclipse stops. On arrival the player sees fewer, larger stops, longer lanes across open dark, and the Nemesis ring at its fullest. Mid sector, burned stops leave a dark trail and every remaining stop shows a high danger band, so reward tags carry the choice. At the boss, disc light is the main light, an ice world sits at the edge, ice rocks tumble slowly, and the flagship is lit from the disc alone. Look: coldest sky bake, ice and crystal rocks, low ambient light, strongest contrast, and the Hollow Sun feeling like the destination, not the backdrop.

## 6. Build order

1. Unify the sky. One world_bake.gd bake per sector for map and battles. Owner sees map shots with battle skies behind the stops. Low fallback: lower bake resolution and fewer stars, as current Low already does.
2. Relight planets and belts. Map planet stops to world_planet.gd, belt stops to world_rocks.gd. Owner sees before and after close ups beside matching battle shots. Low fallback: fewer rocks, no cloud motion.
3. Lane pass. Directional flow ahead, ash fade behind, whole chain lighting on hover. Owner sees one wide and one hover shot per sector showing safest and richest chains. No Low fallback needed.
4. Panels and text. One panel family, one type scale, short hover cards, sidebar cleanup. Owner sees hover card, fleet page, and shipyard page over the dimmed system, beside the old set. No Low fallback needed.
5. Information layer. Core points on the disc rim, Nemesis ring, threat diamond sizing, one reward tag far out. Owner sees full map shots at three clock states: empty, half, full. Low fallback: core points and Nemesis ring as flat sprites if particle cost appears.
6. Scan toggle. Held key flattens the view to symbols over the dimmed system. Owner sees one scan shot per sector beside its cinematic twin. This is itself the Low friendly view, so no fallback needed.
7. Sector transition and forecast arc. Boss jump flight through disc light, next sector preview arc. Owner sees the sector 2 arrival shot and a short transition capture. Low fallback: fade through disc light instead of the full flight.

## 7. Not checked

The pack does not establish the map scene node structure, so I assume the sky bake, planet, and rock builders can be called from the campaign scene without a new pipeline. I did not verify lane shader code, panel code, or exact stop counts; layouts assume roughly ten to fourteen stops per sector. I did not check whether the Nemesis clock full state is driven from campaign data the map ring can read directly. Performance assumes the pack figure that the heaviest battle setting holds 60 fps on the owner machine, and that the map stays lighter than a battle scene. Stellaris camera and reward notes, and parts of the Sins 2 and Homeworld fog notes, are marked as impressions where primary sources did not settle them.
