# Per-character setting, pose, framing and light for every portrait (Ryan, Nov 1 07:37: "portraits on different backgrounds,
# different poses, etc so the admirals and nemesis don't all look the same"). One entry per admiral id (data.js ADMIRALS keys) and
# Nemesis id. Each faction keeps its palette (PALETTE) so the set still reads as one faction; the setting, pose, framing and the
# direction and colour of the key light change per character. The face and eyes stay in the upper middle of the frame so the
# in-game crop (portrait frame and Nemesis bust crop) keeps them readable. Used by make_batches.py (v64 batches).
# v64 review (Nov 1): side and three-quarter heads grow a face on the Glasswright gem (Vaelen in profile on every seed), so Vaelen,
# Tamsa (aelith) and Glasswright Nemesis 2 now face the viewer; Hullbreaker Nemesis 4's 'hull of its ship' drew a sea ship with a
# mast and a white moon, so it stands in an airlock with the Hollow Sun described as a dark disc in a ring of light.
PALETTE = {
 'corsair': 'soot black, rust brown, dried-blood red and a red-orange glow',
 'ithar': 'clear crystal, silver and white light splitting into faint rainbow fringes',
 'voidsworn': 'black iron, frost white and ember orange',
 'hegemony': 'pale grey, steel blue and soft implant-blue light',
 'chorus': 'dark olive-brown flesh, ochre chitin and bile yellow-green light',
 'deathless': 'violet-black plating and white-gold corona light',
}
# id -> (setting, pose and framing, key light)
SPEC = {
 # Hullbreakers (void hunters)
 'grax': ("a trophy-strewn den aboard his ship, torn hull plates of every faction hung on chains along the walls",
          "seated on a crude throne welded from hull plates, leaning forward, one claw resting on a heavy boarding hook, half-body view",
          "a red-orange furnace glow from below on the right"),
 'sable': ("a narrow dark corridor of a stripped wreck, cables hanging from the ceiling",
           "looking back over its shoulder, a long curved scrap blade held low, three-quarter rear view, half-body",
           "a single red emergency lamp from above"),
 'mott': ("a cluttered junkyard hangar deck full of patched scrap fighter craft",
          "standing among the fighters with one claw on a fighter's hull, half-body view",
          "harsh orange welding sparks from the left"),
 'vesh': ("a scrap workshop piled with salvaged plates from every faction, molten metal in a crucible",
          "bent over a workbench welding a plate, seen in profile, half-body view",
          "a blue-white welding arc in front of it and an orange molten glow below"),
 'nem_corsair_1': ("the open bay of a boarding craft, the airlock of a target ship ahead",
                   "crouched low and ready to spring, three-quarter view, half-body", "flashing red warning strobes from above"),
 'nem_corsair_2': ("the cramped bridge of a raider, a viewport behind onto a burning wreck field",
                   "leaning on a console with both claws, tight head-and-shoulders bust", "fire glow from the viewport behind, as a rim light"),
 'nem_corsair_3': ("a listening room full of dish antennas and dim screens showing engine traces",
                   "head tilted, listening, seen in profile, tight bust", "dim amber screen light from below"),
 'nem_corsair_4': ("an open airlock of a scrap raider, black space beyond with a dark disc ringed by a thin band of pale light far away",
                   "standing tall, looking back over its shoulder, half-body", "pale cold ring light from behind and a red running light from the side"),
 'nem_corsair_5': ("a den hung with harnesses and machine plates, a fire pit",
                   "seated on a heap of scrap, one claw raised mid-gesture, half-body", "low firelight from the right"),
 'nem_corsair_6': ("the cramped cockpit of a gutship, banks of controls and red indicator lights",
                   "hunched in the pilot seat, looking forward out of frame, tight bust", "red cockpit instrument light from below"),
 # Glasswrights (living prism)
 'aelith': ("the hangar of a crystal carrier, rows of small crystal starling craft resting in glass cradles",
            "facing the viewer, one arm raised, launching a flock of tiny glass craft from her hand, half-body",
            "cool white light streaming through the open hangar doors behind her"),
 'vaelen': ("a dark observatory with a huge lens array overhead",
            "facing the viewer, holding up a clear lens at arm's length to one side that focuses a thin white beam, half-body", "the bright beam itself, from the side"),
 'thorne': ("a hall of angled mirrors that repeat its figure many times",
            "turned away, looking back over its shoulder, tight bust", "fractured light bouncing between the mirrors"),
 'mirelle': ("the bridge of a crystal warship, the dark disc and glowing ring of the Hollow Sun through a faceted window behind",
             "seated on a command chair of silver and crystal, hands resting on its arms, half-body",
             "white-gold ring light from the window behind and a soft prism glow in front"),
 'nem_ithar_1': ("a glass workshop with furnaces and half-made crystal vanes",
                 "shaping a glowing gather of molten glass with its long fingers, three-quarter view, half-body", "orange-white furnace glow from below"),
 'nem_ithar_2': ("a viewport onto the Ringing Field, crystal wrecks drifting outside",
                 "standing beside the viewport facing the viewer, one hand resting on the glass, half-body", "cold blue-white starlight from the viewport"),
 'nem_ithar_3': ("a war room over a glowing holographic map of a star system",
                 "leaning over the map table, tight bust seen from slightly below", "the map's glow from below"),
 'nem_ithar_4': ("a dim ruined chamber of cracked mirrors",
                 "seated hunched on cracked steps, half-body", "a single thin dim beam of light from high on the left"),
 'nem_ithar_5': ("a vault holding a caged core of blazing light",
                 "standing beside the cage, one hand on its bars, three-quarter view, half-body", "strong white light from the cage at its side"),
 'nem_ithar_6': ("an ancient archive of glowing glass tablets",
                 "very tall, looking down toward the viewer, half-body seen from below", "soft glow from the glass tablets all around"),
}

VSTYLE = ("Painted grimdark science-fiction character portrait, oil painting with visible loose brushstrokes and palette-knife texture, "
          "dramatic chiaroscuro, square composition. Pose and framing: {pose}. Setting: {setting}, painterly and softly out of focus behind "
          "the subject. Key light: {light}; deep shadow elsewhere; muted desaturated palette of {palette}. Museum-quality concept art for a "
          "dark space-opera strategy game. No text, no letters, no logo, no border, no frame, no watermark.")


def style(cid, fac):
    setting, pose, light = SPEC[cid]
    return VSTYLE.format(pose=pose, setting=setting, light=light, palette=PALETTE[fac])

# The other four factions keep their approved characters: each existing portrait is moved into its own setting by a
# Qwen-Image-Edit pass (EDIT below, make_edits.py e64 batches), then the Nemesis scars are repainted on the new base.
# Nemesis keep the head where it is in the frame (the bust crop and scar anchors stay valid); admirals may change pose.
SPEC.update({
 # Sunward Crusade (unaugmented humans, black iron, frost, ember; no religious ornament)
 'vex': ("a war room of frost-rimed black iron walls around a map table lit by ember lamps",
         "leaning forward on the map table with both fists, half-body", "warm ember lamplight from below the table"),
 'nem_voidsworn_1': ("a frozen hangar deck, black iron gunships behind, snow drifting in through the open bay doors",
                     "arms folded across the chest", "cold white light from the open bay doors behind"),
 'nem_voidsworn_2': ("a smoke-filled engine room, ember-orange radiator coils glowing behind", "turned a little to one side",
                     "orange radiator glow from behind and below"),
 'nem_voidsworn_3': ("an observation deck, a dim orange sun beyond frosted glass", "glancing back over one shoulder",
                     "low orange sunlight from the window at the side"),
 'nem_voidsworn_4': ("the gun deck of a black iron warship, huge ember-glowing gun breeches", "one hand resting on a gun breech",
                     "ember glow from the gun breech beside him"),
 'nem_voidsworn_5': ("a dark frozen corridor lit by a single ember lamp", "stepping toward the viewer", "a single ember lamp from above"),
 'nem_voidsworn_6': ("the bridge of a black iron warship, frost on the viewports, stars outside", "seated in a high-backed command chair",
                     "cold starlight from the viewports and ember instrument light from below"),
 # Hegemony Navy (implanted humans, pale grey, steel blue)
 'kassar': ("a briefing room with a glowing blue holographic map of fleet positions", "mid-gesture, one hand pointing into the map, three-quarter, half-body",
            "the blue glow of the holo-map from the front"),
 'nem_hegemony_1': ("a sterile corridor of white wall panels", "hands clasped behind the back", "flat cold white ceiling light"),
 'nem_hegemony_2': ("a drone bay with rows of sleek grey combat drones", "standing among the drones, chin raised", "blue indicator light from the drones"),
 'nem_hegemony_3': ("an orbital station window above a blue planet", "turned in three-quarter view toward the window", "blue planet-light from the window"),
 'nem_hegemony_4': ("a server vault of tall racks with rows of small blue lights", "head tilted, listening to an earpiece", "rows of small blue lights all around"),
 'nem_hegemony_5': ("the bridge of a pale grey dreadnought, a fleet in formation outside", "standing at a railing", "white light from the viewport behind"),
 'nem_hegemony_6': ("a quiet office with a tall window onto a capital city at night", "seated at a desk, fingers steepled", "city glow through the window"),
 # Chorus (grown organisms, no face or limbs): the setting and light change, the organism stays
 'matriarch': ("open space above a planet being consumed, clouds of spores drifting down into its atmosphere", "the organism seen from below, filling the frame",
               "the planet's pale light from below and bile glow from within"),
 'mending': ("the gutted hull of a captured warship overgrown with flesh and sinew", "the organism nestled among broken bulkheads",
             "a shaft of cold light through a hole in the hull"),
 'nem_chorus_1': ("the inside of a wreck being overgrown by flesh", "", "bile glow from below"),
 'nem_chorus_2': ("a dim olive nebula with drifting spores", "", "soft diffuse light from the nebula behind"),
 'nem_chorus_3': ("an asteroid hollowed into a hive, honeycomb chambers", "", "light from glowing egg sacs in the walls"),
 'nem_chorus_4': ("the surface of a moon covered in fleshy growth, a ringed planet in the sky", "", "cold light from the ringed planet"),
 'nem_chorus_5': ("a swamp of bile under a low ceiling of membrane", "", "yellow-green glow rising from the bile"),
 'nem_chorus_6': ("open space with the dark ring of the Hollow Sun far behind", "", "a pale rim of light from the distant ring"),
 # Eclipse (machine beings and the ring mind)
 'nekhet': ("a vast dark machine hall of siphon arrays draining a star seen through an opening", "the ring seen at an angle",
            "white-gold starlight pouring through the opening"),
 'nem_deathless_1': ("a cold archive of floating data plates", "", "faint white light from the data plates"),
 'nem_deathless_2': ("a siphon platform over a star being drained into a thin stream of light", "", "blazing starlight from below"),
 'nem_deathless_3': ("a repair dock, small drones refitting plates", "", "the white beams of the repair drones"),
 'nem_deathless_4': ("the surface of a dead grey planet under a black sky", "", "a low white-gold sun at the horizon"),
 'nem_deathless_5': ("a long corridor of violet light panels", "", "violet light panels on both sides"),
 'nem_deathless_6': ("deep space with a dim dying star behind", "", "the faint red glow of the dying star"),
})
# e64 review (Nov 1, P helper 3): redraws for e64c. Kassar's holo map came out as Earth; Vex's paper map grew a text-like legend;
# the Crusade gun deck drew a sailing ship with rigging and the Hegemony fleet sea ships on an ocean; Crusade 3's window view and
# Eclipse 1's data plates turned to blocky pixels and text lines; Crusade 5 and 6, Hegemony 5 and Eclipse 2 shrank to small full
# figures (their pose lines dropped so the head stays where it was); Chorus 1 hardly moved (s11) or grew a human face (s23).
SPEC.update({
 'vex': ("a war room of frost-rimed black iron walls around a table that glows with a star chart drawn in lines of ember light",
         "leaning forward on the table with both fists, half-body", "warm ember light from the star chart below"),
 'kassar': ("a briefing room with a glowing blue holographic star map of planets, orbit rings and small fleet markers",
            "mid-gesture, one hand pointing into the map, three-quarter, half-body", "the blue glow of the holo-map from the front"),
 'nem_voidsworn_3': ("an observation deck aboard a black iron warship, a dim orange sun in black space beyond frosted glass", "glancing back over one shoulder",
                     "low orange sunlight from the window at the side"),
 'nem_voidsworn_4': ("the enclosed gun deck inside a black iron starship, a low steel ceiling, huge ember-glowing gun breeches along the steel wall",
                     "one hand resting on a gun breech", "ember glow from the gun breech beside him"),
 'nem_voidsworn_5': ("a dark frozen corridor of black iron lit by a single ember lamp", "", "a single ember lamp from above"),
 'nem_voidsworn_6': ("the bridge of a black iron warship, frost on the viewports, stars outside, the high back of a command chair behind him", "",
                     "cold starlight from the viewports and ember instrument light from below"),
 'nem_hegemony_5': ("the bridge of a pale grey dreadnought, sleek grey starships in formation in black space beyond the viewport", "",
                    "white light from the viewport behind"),
 'nem_chorus_1': ("the hollow inside of a broken warship hull overgrown with flesh and sinew, torn bulkheads and cables all around", "",
                  "bile-green glow from below and a shaft of cold light from above"),
 'nem_deathless_1': ("a cold archive of floating blank glass plates glowing faintly", "", "faint white light from the glass plates"),
 'nem_deathless_2': ("a siphon platform over a star being drained into a thin stream of light", "", "blazing starlight from below"),
})
# e64c review: Kassar's holo map came out as Earth twice and Crusade 3's "warship" deck grew sailing-ship rigging twice (black iron
# and frost read as the age of sail), so e64d gives both settings with no map and no ship deck.
SPEC.update({
 'kassar': ("an orbital dock gallery, a huge pale grey dreadnought under construction beyond the long window, work lights along its hull",
            "mid-gesture, one hand raised toward the window, three-quarter, half-body", "cold white light from the window and blue implant glow"),
 'nem_voidsworn_3': ("a small round observation pod of black iron and frosted glass in deep space, a dim orange sun beyond the glass",
                     "glancing back over one shoulder", "low orange sunlight from the window at the side"),
})
CLEAN = " The paint surface is smooth and even everywhere, with no noise, speckle, pixels, writing or lettering."
KEEP_WHAT = {'voidsworn': 'person, face, scars, hair and clothing', 'hegemony': 'person, face, implants, hair and uniform',
             'chorus': 'organism, its shape and colours', 'deathless': 'machine, its shape and colours'}
EDIT = ("Move this same {what} into a new setting: {setting}.{pose} Key light: {light}. Keep the same {what}, and keep the oil-painting "
        "style with loose brushstrokes; muted palette of {palette}. No text, no letters.")


def edit_prompt(cid, fac, nemesis):
    setting, pose, light = SPEC[cid]
    what = KEEP_WHAT[fac]
    p = ''
    if nemesis: p = ' Keep the head and face in the same place in the frame' + ('; ' + pose if pose else '') + '.'
    elif pose: p = ' New pose and framing: ' + pose + '.'
    return EDIT.format(what=what, setting=setting, pose=p, light=light, palette=PALETTE[fac])
