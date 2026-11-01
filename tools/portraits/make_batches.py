# Builds the portrait batch files (tools/portraits/batches/*.json) from one shared style template.
# Run: python3 tools/portraits/make_batches.py   (sandbox), then queue portrait_run.py gen <batch> on the PC.
# Template rules (art_direction_rey.md Part E, sprint_decision_packs.md Sheet 3): three-quarter bust, lit from the left in the
# faction glow, dark faction plate behind, painterly finish, no text or insignia lettering, and every portrait reflects its Command.
# The thin faction-trim frame is added in post (tools/portraits/post.py), not by the model, so it is identical on every portrait.
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
STYLE = ("Painted grimdark science-fiction character portrait, oil painting with visible loose brushstrokes and palette-knife texture, "
 "dramatic chiaroscuro, square composition, three-quarter bust view, the subject lit hard from the left by {glow}, "
 "deep soft shadow on the right side, a dark painterly {plate} background softly out of focus, muted desaturated palette with one strong glow colour, "
 "museum-quality concept art for a dark space-opera strategy game. No text, no letters, no logo, no border, no frame, no watermark.")
F = {
 'chorus': dict(glow='sickly yellow-green bioluminescent light', plate='wet purple-black organic cavern of membrane and spore haze'),
 'voidsworn': dict(glow='warm orange candlelight and furnace glow', plate='gothic warship bridge interior with candles and reliquaries'),
 'hegemony': dict(glow='cool clinical blue-white light', plate='clean pale command deck with blue holographic displays'),
 'corsair': dict(glow='harsh red emergency light and sparks', plate='cramped rusty salvage-ship cockpit full of smoke'),
 'ithar': dict(glow='pale mint-green and soft gold radiance', plate='deep starfield with faint aurora light'),
 'deathless': dict(glow='cold emerald-green core light', plate='black tomb-like machine vault with faint green circuitry'),
}
CH = ("It is an alien grown organism, not a person and not an animal: no face, no eyes, no mouth with teeth, no limbs, no human features; "
      "no buildings, no machines, no instruments, no architecture. Glistening wet flesh, membrane, chitin, bile, gross deep-sea biology.")
SUBJECT = {
 # Chorus set (finish first). Mending: the Living Suture-Hive (Argon, chair lean). Matriarch: alternates to v3 from the DeepSeek 1.3 brief.
 # Voice v4 and Razormaw are final in Muse's local set; these two are style-matched alternates only.
 'chorus_mending': ('chorus',
  "Portrait of The Mending Throng, a Chorus bio-swarm admiral in the form of a Living Suture-Hive: a pulsing biological cocoon-graft, "
  "clusters of translucent amber nursing sacs glowing from within, curved pale chitin bone-needles growing out of the flesh and stitching "
  "glowing pink membrane webbing across a shattered dark carapace, fresh pink scar tissue knitting the cracks closed, new flesh visibly regrowing over old wounds. " + CH),
 'chorus_matriarch': ('chorus',
  "Portrait of The Matriarch of Nine Throats, a Chorus brood-mother organism: nine uneven fleshy throat-tubes of very different lengths and thicknesses, "
  "bent and leaning at odd angles, fused at the base into one swollen leaking brood mass, split wet openings at their tips exhaling clouds of tiny glowing spore swarms, "
  "translucent brood sacs bulging with swarming larvae shadows, purple-black flesh with ochre chitin ridges, an irregular organic silhouette. " + CH),
 'chorus_voice': ('chorus',
  "Portrait of Voice of the Deep, a Chorus organism shaped like a hollow dome of opaque abyssal membrane, its rim a ragged lip of regrowing flesh "
  "shedding strips into the dark, irregular fleshy ridges, acid-green spittle and droplets spraying outward as if singing. " + CH),
 'chorus_razormaw': ('chorus',
  "Portrait of Razormaw, a Chorus hunter-pack organism: a ring of curved chitin blades grown from purple-black flesh, arranged as a hunting formation "
  "that reads as a hungry maw around an empty dark centre where a single small lure light glows, strands of bile and torn membrane trailing behind it as if surging forward. " + CH),
 # One painted poster admiral per remaining faction: each faction's starting admiral (cost 0 in data.js).
 'voidsworn_vex': ('voidsworn',
  "Portrait of Admiral Roderic Vex of the Sunward Crusade, a stern weathered human fleet admiral in his late fifties, shaved scarred head with ritual oath scars, "
  "grey stubble, hard tired eyes, a high-collared dark armoured space-fleet greatcoat with ornate ceramite shoulder plates, red wax votive seals and parchment oath strips pinned to the chest, "
  "a small brass reliquary on a chain, behind him through a tall gothic viewport a distant line of battleships firing a broadside of orange lance beams into the void."),
 'hegemony_kassar': ('hegemony',
  "Portrait of First Admiral Ilsa Kassar of the Hegemony Navy, a composed precise human woman in her early fifties, silver hair in a severe short cut, cold grey eyes, "
  "a pale grey high-collared space-fleet dress uniform with rows of flat blue enamel rank bars and clean geometric shoulder boards, gloved hands clasped behind her back, "
  "faint blue targeting grids reflected on her face, behind her a pale clinical bridge where many identical firing-solution displays glow in perfect rows."),
 'corsair_grax': ('corsair',
  "Portrait of Warlord Grax Ironmaw of the Ashfall Hullbreakers, a hulking scarred human space pirate warlord, a crude riveted iron prosthetic lower jaw, "
  "a grin of steel, one cybernetic red eye, a shaved head with old burn scars, patchwork armour welded together from three different fleets' salvaged plates in clashing colours, "
  "mismatched stolen medals and torn insignia, grease and rust, a heavy boarding axe resting on his shoulder, sparks raining behind him in a cramped junk-built space-ship cockpit."),
 'ithar_aelith': ('ithar',
  "Portrait of Tamsa of the Clear Aperture, a Glasswright, an ancient dying elder alien race, a statuesque luminous alien being, clearly not human: an elongated skull and very long slender neck, "
  "huge wide-set solid black eyes, pale translucent porcelain skin with glowing gold light channels running beneath it, long seven-fingered hands raised gracefully, "
  "behind her a radiant fan of near-geometric light sails like stained glass made of light, a flight of tiny glowing star-craft wheeling around her like a murmuration. "
  "Nothing aquatic: no fins, no gills, no scales."),
 'deathless_nekhet': ('deathless',
  "Portrait of Nadir Aurex, Ninth Frame, of Eclipse, a machine intelligence with no humanoid body: a monumental broken ring of bone-white ceramic computation plates "
  "and black metal around a blazing green core, cracked segments floating apart and being reassembled by small attending service drones with thin green beams, "
  "ancient worn surfaces engraved with circuit patterns, sensor lights instead of a face, an ominous patient presence."),
}
# ---------- batch 2 (Oct 26 review of batch 1) ----------
# Batch 1 failures: every Mending render grew a face or a humanoid body (the "portrait of an admiral" framing pulls the
# models toward a person), every Nekhet render kept a torso or a face inside the ring, and Aelith came out as a nude
# five-fingered grey alien. For the non-humans the subject is now described as an organism or machine (CREATURE style,
# no "portrait", no "bust"); Aelith gets a robe, seven fingers and a regal crest.
CREATURE = ("Painted grimdark science-fiction creature concept art, oil painting with visible loose brushstrokes and palette-knife texture, "
 "dramatic chiaroscuro, square composition, the subject centred and filling the frame, lit hard from the left by {glow}, "
 "deep soft shadow on the right side, a dark painterly {plate} background softly out of focus, muted desaturated palette with one strong glow colour, "
 "museum-quality concept art for a dark space-opera strategy game. No text, no letters, no logo, no border, no frame, no watermark.")
NOBODY = ("There is no person, no head, no face, no eyes, no mouth, no arms, no legs, no skeleton and no skull anywhere in the image; "
          "it does not stand or walk.")
SUBJECT.update({
 'chorus_mending_b1': ('chorus',
  "The Living Suture-Hive, a Chorus bio-swarm organism: a sprawling asymmetric living mass grafted over a cracked dark chitin shell, "
  "like a wasp nest made of wet flesh. Clusters of translucent amber nursing sacs glow from inside it. Hundreds of curved pale bone needles "
  "grow out of the mass and pull glowing pink membrane threads across the cracks of the shell like surgical sutures; fresh pink scar tissue "
  "knits the wounds shut and new flesh regrows over old wounds. One shapeless organic lump seen from slightly below. " + NOBODY),
 'chorus_mending_b2': ('chorus',
  "The Living Suture-Hive, a Chorus bio-swarm organism: a pulsing cocoon of veined pink membrane wrapped around the broken wreck of a dark "
  "organic hull, stitched closed with long rows of curved pale bone needles and glowing pink sinew threads, like a vast surgical wound "
  "being sewn shut. Swollen amber nursing sacs hang from the cocoon like fruit, glowing from within, dripping nutrient fluid onto raw new "
  "flesh that grows over the seams. An organic shape like a tumour or a hive, never a body. " + NOBODY),
 'deathless_nekhet_b': ('deathless',
  "The Undying, a Deathless machine intelligence: a monumental broken ring of bone-white ceramic computation plates and black metal, "
  "floating in a black tomb-like vault. Inside the ring there is only a blazing sphere of cold emerald-green light and nothing else. "
  "Cracked ring segments drift apart and small attending service drones repair them with thin green beams. Rows of small green sensor "
  "lights glow along the ring. Ancient worn surfaces engraved with circuit patterns. An ominous patient presence. "
  "No figure, no statue, no head, no face, no body, no robot inside the ring."),
 'ithar_aelith_b': ('ithar',
  "Portrait of Tamsa of the Clear Aperture, a Glasswright, an ancient dying elder alien race: a tall regal luminous alien noble, clearly not human and "
  "not a grey alien: an elongated crested skull and a very long slender neck, huge wide-set solid black eyes, pale translucent porcelain "
  "skin with glowing gold light channels running beneath it, wearing a high-collared flowing robe of woven pale light that covers the body "
  "to the neck, one hand raised gracefully showing seven very long slender fingers, behind her a radiant fan of near-geometric light sails "
  "like stained glass made of light, a flight of tiny glowing star-craft wheeling around her like a murmuration. "
  "Nothing aquatic: no fins, no gills, no scales."),
})
CREATURE_IDS = ('chorus_mending_b1', 'chorus_mending_b2', 'deathless_nekhet_b')
# ---------- Nemesis pool (R42): 6 per faction, same painted style, more villainous framing ----------
# Ids nem_<faction>_<1..6>. A red rim light from the right and a low camera mark every Nemesis apart from the named admirals;
# the red-black frame and the scars (burn, cyber, eye, carapace, porcelain, machine) are composited in post or in game.
NEM_STYLE = (" Villain portrait: low camera angle looking slightly up at the subject, menacing and threatening presence, "
 "a thin blood-red rim light from the right edge cutting through the shadow.")
HUMAN = "A human, a space-fleet commander, nothing naval: no hats, no sailor uniforms."
NEM = {
 'voidsworn': [
  "a gaunt zealot inquisitor-admiral with a branded forehead, hollow burning eyes, an iron collar hung with chains and wax oath seals, dark armoured void-coat",
  "a massive armoured war-priest commander wearing a tarnished brass rebreather mask, smoking censers on chains, heavy ceramite plates covered in scripture",
  "a cold aristocratic flagellant-admiral woman, shaved head covered in litany tattoos, a blood-red sash over black armour, a thin cruel smile",
  "an old castellan with a white beard and a furious glare, one arm replaced by a heavy black iron mechanical arm, battered gothic armour",
  "a hooded executioner-commodore, a skull-shaped steel visor half raised over a scarred jaw, candle wax dripping down his armour",
  "a young fanatic commander with ritual piercings along the brow and glowing orange eye implants, a mad devout stare",
 ],
 'hegemony': [
  "a bald, surgeon-faced commissar-admiral with a single red targeting lens over one eye, thin lips, black gloves, pale grey high-collared uniform",
  "a severe woman admiral, platinum hair slicked back, a high black collar with flat enamel rank bars, face half lit by red alert light",
  "a heavyset grand marshal with heavy jowls, rows of flat blue enamel rank bars, pale contemptuous eyes",
  "a young prodigy admiral with razor-sharp features and a cold smile, a thin holographic tactical visor across the brow",
  "an intelligence chief in a grey uniform with a featureless chrome half-mask covering the left side of the face",
  "an elderly fleet lord with white hair and a medical exoskeleton brace around the neck, cruel patient eyes",
 ],
 'corsair': [
  "a tattooed raider queen with a shaved undercut, gold teeth, a chain of stolen dog tags, patchwork armour",
  "a hulking brute warlord with a welded steel faceplate and a single red optic, rusted armour plates from different fleets",
  "a wiry grinning knife-man with old acid burns, cracked goggles pushed up, a crest of braided cables instead of hair",
  "a fat smuggler baron in a stolen admiral's coat full of mismatched medals, rings on every finger, cigar smoke",
  "a weathered old scavenger captain with a battered respirator and patched hazard-striped armour, one squinting eye",
  "a feral young warlord with war paint of engine grease and a crude crown of bent shrapnel",
 ],
 'chorus': [
  "a ravenous maw-colony: a ring of grinding chitin plates around a dark pulsing hollow, dripping acid",
  "a parasite bloom: clusters of swollen pustule sacs and writhing feeding tendrils bursting out of a cracked host carapace",
  "a spined siege-organism: an armoured purple-black dome bristling with long bone spikes and glowing yellow vents",
  "a hive-mind mass: wrinkled translucent neural tissue lit from within, threaded with thick nerve cords",
  "a spore-mother: a towering stalk of fungal flesh shedding clouds of glowing spores",
  "a predator membrane: huge folded sheets of veined membrane with acid-yellow veins, wrapped around a dark core",
 ],
 'ithar': [
  "a gaunt Ithar inquisitor with an elongated skull crowned by sharp spikes of light, cold pitiless solid black eyes, white porcelain skin",
  "an Ithar seer with a veil of fine light threads over the face, long seven-fingered hands ending in blade-like fingertips",
  "a statuesque Ithar war-matriarch, gold light channels flaring red-gold under translucent skin, armour of glass-like petals",
  "an Ithar exile with dimmed flickering light channels, ash-grey skin, a crown of broken light sails",
  "an Ithar archon with a tall crested head and a smooth mask of mirrored light where the face should be",
  "an ancient Ithar with skin like aged ivory, an extremely long neck, eyes glowing a faint cruel red",
 ],
 'deathless': [
  "a cluster of black obelisk processors orbiting a single green sensor core, thin green data beams between them",
  "a towering lattice of green-lit segmented metal vertebrae around a cold core, no head, no face",
  "a swarm core: thousands of tiny black beetle-shaped drones forming a shifting mass around a green core",
  "a pale ceramic mask suspended in a field of floating black cables, green slit-light glowing behind it",
  "a sarcophagus-shaped machine split open down the front, revealing green-lit gears and coils",
  "a broken halo of rotating black blades around a dark core with a single green beam",
 ],
}
# Nemesis batch 2 (Oct 26 review of n1): every Chorus render was the same skull-headed humanoid, most Deathless renders had
# human faces or bodies, and the Ithar did not share Aelith's anatomy. Rewritten as organisms and machines with distinct
# silhouettes (CREATURE style, no body), and the Ithar get one shared anatomy line.
ITHAR = ("An Ithar, an ancient elder alien race: an elongated crested skull, a very long slender neck, huge solid black eyes, pale porcelain skin "
         "with glowing gold light channels beneath it, robed, seven-fingered hands; clearly not human and not a grey alien.")
NEM2 = {
 'chorus': [
  "a huge circular ring of grinding chitin plates around a dark pulsing hollow throat, dripping acid, the ring grown out of a mass of purple-black flesh",
  "clusters of swollen glowing pustule sacs and writhing feeding tendrils bursting out of a cracked grey host shell, like a fungus erupting from a carcass",
  "an armoured purple-black dome like a giant beetle shell with no head and no legs, bristling with long bone spikes and glowing yellow vents",
  "a floating mass of wrinkled translucent neural tissue lit from within, threaded with thick nerve cords that trail away into the dark like roots",
  "a towering stalk of fungal flesh like a giant puffball, shedding thick clouds of glowing yellow spores from gills under its cap",
  "huge folded sheets of veined membrane with acid-yellow veins wrapped like a cloak around a dark pulsing core, the edges lined with hooked barbs",
 ],
 'deathless': [
  "a cluster of black obelisk processors orbiting a single green sensor light, thin green data beams linking them",
  "a towering spine of green-lit segmented black metal vertebrae coiled around a cold green core, like a mechanical serpent with no head",
  "thousands of tiny black beetle-shaped drones forming a shifting sphere around a green core, streams of drones peeling away from it",
  "a monolithic black slab covered in moving green glyph lights, split down the middle by a glowing crack, cables pouring from its base",
  "an upright sarcophagus-shaped machine split open down the front, revealing only green-lit gears, coils and a glowing core inside",
  "a broken halo of rotating black blades around a dark core, a single green beam rising from it",
 ],
 'ithar': [
  "a gaunt Ithar inquisitor crowned by sharp spikes of light, a cold pitiless gaze, dark grey high-collared robes",
  "an Ithar seer with a veil of fine light threads over the eyes, long seven-fingered hands ending in blade-like fingertips, a high-collared robe",
  "a statuesque Ithar war-matriarch, gold light channels flaring red-gold under the skin, armour of glass-like petals over a long robe",
  "an Ithar exile with dimmed flickering light channels, ash-grey cracked skin, a crown of broken light sails, a ragged robe",
  "an Ithar archon with a tall crest and a smooth mask of mirrored light where the face should be, an ornate robe",
  "an ancient Ithar with skin like aged ivory, an extremely long neck, eyes glowing a faint cruel red, a heavy ceremonial collar",
 ],
}
DISP = {'chorus': 'the Chorus', 'deathless': 'Eclipse', 'ithar': 'the Glasswrights', 'voidsworn': 'the Sunward Crusade', 'hegemony': 'the Hegemony', 'corsair': 'the Hullbreakers'}
SUB2 = {}   # n2 subjects, same ids as n1 (nem_<faction>_<n>), rendered into n2\
for _fac, _L in NEM2.items():
    for _n, _d in enumerate(_L, 1):
        _k = 'nem_%s_%d' % (_fac, _n)
        if _fac == 'ithar':
            SUB2[_k] = (_fac, 'Portrait of a Nemesis, a rival enemy commander of the Glasswrights: %s. %s' % (_d, ITHAR) + NEM_STYLE, STYLE)
        else:
            SUB2[_k] = (_fac, 'A Nemesis of %s, a rival enemy war-organism: %s. %s' % (DISP[_fac], _d, NOBODY if _fac == 'chorus' else
                        'A machine with no figure, no statue, no head, no face, no body, no robot.') + NEM_STYLE, CREATURE)
# n3: the five n2 subjects that still grew limbs or a body (Chorus 2, 3, 4; Deathless 1, 6), described as objects lying or floating
SUB3 = {}
for _k, _d in {
 'nem_chorus_2': "a heap of swollen glowing pustule sacs and writhing feeding tendrils erupting from a cracked grey husk that lies on its side on the cavern floor, like a fungus bursting from a carcass",
 'nem_chorus_3': "a giant armoured purple-black dome-shaped shell half sunk into the cavern floor, bristling with long bone spikes, glowing yellow vents along its rim, nothing beneath it",
 'nem_chorus_4': "a floating brain-like mass of wrinkled translucent neural tissue the size of a whale, lit from within, long nerve cords trailing beneath it like roots",
 'nem_deathless_1': "seven tall black obelisk processors floating in a ring around a single small green light, thin green data beams joining them, empty black space between them",
 'nem_deathless_6': "a huge broken ring of rotating black blades floating alone above a dark pit, a single green beam rising from the empty centre of the ring",
}.items():
    _fac = _k.split('_')[1]
    SUB3[_k] = (_fac, 'A Nemesis of %s, a rival enemy war-organism: %s. %s' % (DISP[_fac], _d, NOBODY if _fac == 'chorus' else
                'A machine with no figure, no statue, no head, no face, no body, no robot, no legs, no arms.') + NEM_STYLE, CREATURE)
for _fac, _L in NEM.items():
    for _n, _d in enumerate(_L, 1):
        _pre = HUMAN + ' ' if _fac in ('voidsworn', 'hegemony', 'corsair') else (CH + ' ' if _fac == 'chorus' else '')
        SUBJECT['nem_%s_%d' % (_fac, _n)] = (_fac, 'Portrait of a Nemesis, a rival enemy commander of the %s: %s. %s' % (DISP[_fac], _d, _pre) + NEM_STYLE)

def item(i, model, seeds, v2=False, v3=False):
    if v3: fac, p, style = SUB3[i]
    elif v2: fac, p, style = SUB2[i]
    else: fac, p = SUBJECT[i]; style = CREATURE if i in CREATURE_IDS else STYLE
    it = {'id': i, 'model': model, 'prompt': p + ' ' + style.format(**F[fac]), 'nosuffix': True, 'seeds': seeds}
    if model == 'qref':   # paint onto the faction's dark background plate (tools/portraits/plates.py)
        it['ref'] = 'plate_%s.png' % fac
        it['prompt'] = 'Paint a full new character portrait onto this dark background, filling the frame. ' + it['prompt']
    return it
S4 = [11, 23, 37, 51]
POSTERS = ('voidsworn_vex', 'hegemony_kassar', 'corsair_grax', 'ithar_aelith', 'deathless_nekhet')
# Each batch is one PC queue job of about 20 minutes or less; all write into comfy_io\PORTRAITS\b1\.
BATCHES = {
 'b1a': [item('chorus_mending', 'zit', S4), item('chorus_matriarch', 'zit', S4), item('chorus_voice', 'zit', S4[:3]), item('chorus_razormaw', 'zit', S4[:3])],
 'b1b': [item(k, 'zit', S4) for k in POSTERS] + [item('chorus_mending', 'qref', S4)],
 'b1c': [item('chorus_mending', 'qie', S4)] + [item(k, m, S4[:2]) for k in POSTERS for m in ('qie', 'qref')],
 # fallback with no download: only Qwen-Image-Edit 2511 (already on the PC)
 'b1q': [item('chorus_mending', 'qref', S4), item('chorus_mending', 'qie', S4[:2]), item('chorus_matriarch', 'qref', S4[:3])]
        + [item(k, 'qref', S4[:2]) for k in POSTERS],
 # Nemesis pool (R42): 3 candidates each on Z-Image Turbo, two jobs of about 10 to 15 minutes
 'n1a': [item('nem_%s_%d' % (f, n), 'zit', S4[:3]) for f in ('voidsworn', 'hegemony', 'corsair') for n in range(1, 7)],
 'n1b': [item('nem_%s_%d' % (f, n), 'zit', S4[:3]) for f in ('chorus', 'ithar', 'deathless') for n in range(1, 7)],
}
BATCHES['b2'] = [item('chorus_mending_b1', 'zit', S4), item('chorus_mending_b2', 'zit', S4), item('deathless_nekhet_b', 'zit', S4),
                  item('deathless_nekhet_b', 'qie', S4[:2]), item('ithar_aelith_b', 'qie', S4), item('ithar_aelith_b', 'qref', S4[:2])]
BATCHES['n2'] = [item('nem_%s_%d' % (f, n), 'zit', S4[:3], v2=True) for f in ('chorus', 'deathless', 'ithar') for n in range(1, 7)]
BATCHES['n3'] = [item(k, 'zit', S4, v3=True) for k in SUB3]
# ---------- round 8 looks (lore approved Oct 27, FINDINGS R59; contrib/opus/compute/lore_bible_r8.md 2.5 to 7.3) ----------
# Everything above is the superseded first pass, kept so old batches can be rebuilt. New work uses F8 and the R8 subjects.
# Ids and file names never change (voidsworn = Sunward Crusade, corsair = Ashfall Hullbreakers, ithar = Glasswrights,
# deathless = Eclipse). Display names wait for contrib/opus/compute/rename_map_final.md; no prompt below needs one.
F8 = {
 'voidsworn': dict(glow='warm ember-orange light', plate='black-iron warship bridge with frost on the viewports and ember-orange radiator spires glowing outside'),
 'hegemony': dict(glow='cool clinical blue-white light', plate='clean pale grey command deck with rows of steel-blue displays'),
 'corsair': dict(glow='dim red running lights and a red-orange engine glow', plate='dark soot-black ship interior hung with chains, scrap and hull plates'),
 'chorus': dict(glow='bile yellow-green bioluminescent light', plate='wet dark olive-brown organic cavern of membrane and spore haze'),
 'ithar': dict(glow='clear white light split into faint rainbow fringes', plate='dark space seen through faceted crystal and silver mirrors'),
 'deathless': dict(glow='pale white-gold corona light', plate='black void with the dark disc of a black hole ringed by a thin white-gold glow'),
}
BEAST = ("A Hullbreaker, a huge hunched furred alien predator, clearly not human and not a werewolf in clothes: bear-heavy shoulders, a long "
         "wolf-like muzzle full of teeth, thick matted fur, heavy claws, small fierce eyes that shine in the dark. Scrap armour harness "
         "strapped over the fur, made of hull plates torn from other ships. Trophies are machine parts and hull plates, never skulls or bones.")
GLASS8 = ("A Glasswright, a tall slender biological alien, plainly not human, not a grey alien and not an elf: a very long slender neck, "
          "large dark eyes behind a clear transparent second eyelid, pale skin that stores light and glows faintly in fine patterns, wearing "
          "layered robes of crystal plates and mirror-thread fabric that catch the light, small glowing light-cores worn as jewellery.")
ECL = ("An Eclipse machine being: a tall machine body built from layered dark violet-black armour plates, a narrow horizontal visor of "
       "white-gold light where a face would be, a small core of trapped white light glowing in the chest. Not a skeleton, no skull, "
       "no green light, no crown, no throne, no Egyptian or tomb motifs.")
NOMACH = 'A machine with no figure, no statue, no head, no face, no body, no robot inside it, no green light.'
CROW = 'A grown organism, not a person and not an animal: no face, no eyes, no mouth with teeth, no limbs, no human features.'
R8 = {
 # posters (the painted admirals): fresh renders for the three factions whose people changed
 'corsair_grax_r8': ('corsair', STYLE,
  "Portrait of the warlord of the Ashfall Hullbreakers. " + BEAST + " An old scarred alpha with grey and rust-brown fur, a riveted steel "
  "plate bolted along the lower jaw like a steel grin, heavy claws resting on a boarding hook, harness plates in clashing colours from "
  "three different fleets, chains across the chest."),
 'ithar_aelith_r8': ('ithar', STYLE,
  "Portrait of a Glasswright elder. " + GLASS8 + " A grieving dignified face, a high collar of faceted crystal, one long-fingered hand "
  "raised holding a small glowing light-core, behind her tall crystal vanes and silver mirrors that split the light into rainbow fringes. "
  "Nothing aquatic: no fins, no gills, no scales."),
 'deathless_nekhet_r8': ('deathless', CREATURE,
  "The great ring mind of Eclipse, a machine intelligence: a monumental broken ring of layered dark violet-black plates floating around "
  "a blazing core of white-gold light, cracked ring segments drifting apart and being refitted by tiny repair drones with thin white "
  "beams, a faint violet-white inner glow. " + NOMACH),
}
NEM8 = {
 'corsair': [
  "a grizzled grey alpha with a torn ear, a harness of pale grey Hegemony hull panels and chains across the chest",
  "a black-furred brute with a welded iron guard over its long jaws, one eye shining in the dark",
  "a lean rust-brown hunter with long ears, small listening dishes strapped to its harness, scrap plates across the shoulders",
  "a huge old pack-lord with a grey muzzle and heavy claws, shards of clear crystal strapped into its harness",
  "a scarred matted black she-beast baring her teeth, a harness of dark violet machine plates",
  "a young feral one with rust and grey fur, chains wrapped round its forearms, a boarding hook on its back",
 ],
 'ithar': [
  "a gaunt Glasswright keeper with a cold pitiless gaze, a high collar of sharp crystal shards",
  "a Glasswright with a veil of fine mirror-thread over the brow, long fingers cupping a light-core",
  "a Glasswright war-leader in armour of overlapping crystal plates that split light into rainbow fringes",
  "a Glasswright exile whose light-storing skin has gone dark and cracked, a ragged mirror-thread robe",
  "a Glasswright keeper with a smooth mirrored visor and a caged light-core worn at the chest",
  "an ancient Glasswright with an extremely long neck, the light patterns in the skin glowing brightly, the second eyelids half closed",
 ],
 'deathless': [
  "a gaunt archivist frame with a mantle of thin data plates, its visor narrowed to a slit",
  "a heavy armoured frame with heat-shield fans rising from the shoulders like a raised hood",
  "a frame rebuilt many times from mismatched violet-black plates, old repair seams across it",
  "a slender frame with a cracked visor, the chest core flickering",
  "a frame sheltering behind a raised fan of overlapping heat-shield plates, only the visor showing above it",
  "a broken ring of dark violet-black blades floating over a dark pit, a thin white-gold corona round its empty centre",
 ],
}
def r8_nem(fac, n, d):
    if fac == 'corsair':
        p, style = 'Portrait of a Nemesis, a rival enemy warlord of the Hullbreakers: %s. %s' % (d, BEAST), STYLE
    elif fac == 'ithar':
        p, style = 'Portrait of a Nemesis, a rival enemy commander of the Glasswrights: %s. %s' % (d, GLASS8), STYLE
    elif n == 6:
        p, style = 'A Nemesis of Eclipse: %s. %s' % (d, NOMACH), CREATURE
    else:
        p, style = 'Portrait of a Nemesis of Eclipse: %s. %s' % (d, ECL), STYLE
    return {'id': 'nem_%s_%d' % (fac, n), 'model': 'zit', 'prompt': p + NEM_STYLE + ' ' + style.format(**F8[fac]), 'nosuffix': True, 'seeds': [11, 23, 37]}
def r8_poster(i, model, seeds):
    fac, style, p = R8[i]
    return {'id': i, 'model': model, 'prompt': p + ' ' + style.format(**F8[fac]), 'nosuffix': True, 'seeds': seeds}
# Oct 31 review: the Vex restyle edits kept wax seals and a church window, or drew a sailing ship and lettering, so Vex is
# repainted fresh. No chalked names in any prompt: the models turn them into gibberish writing.
R8['voidsworn_vex_r8'] = ('voidsworn', STYLE,
  "Portrait of a Sunward Crusade fleet admiral, a stern weathered unaugmented human man in his late fifties, a shaved head, pale "
  "frost-scarred skin, old surgical scars at the temple and neck where implants were cut out, an old burn scar on the brow, grey stubble, "
  "hard tired eyes, a high-collared dark void-coat with heavy black iron shoulder plates striped with frost-white paint, behind him through a "
  "frosted viewport black iron space warships with glowing ember-orange heat radiator spires firing into the void. No writing, no letters, "
  "no candles, no church windows, no seals, no sailing ships.")
BATCHES['r8c'] = [r8_poster('voidsworn_vex_r8', 'zit', S4), r8_poster('voidsworn_vex_r8', 'qie', S4[:2])]
# r8a about 9 minutes (Hullbreakers and Glasswrights), r8b about 8 minutes (Eclipse, plus the Qwen poster takes); out r8\
BATCHES['r8a'] = [r8_poster(k, 'zit', S4) for k in ('corsair_grax_r8', 'ithar_aelith_r8')] + \
                 [r8_nem(f, n, d) for f in ('corsair', 'ithar') for n, d in enumerate(NEM8[f], 1)]
BATCHES['r8b'] = [r8_poster('deathless_nekhet_r8', 'zit', S4)] + [r8_nem('deathless', n, d) for n, d in enumerate(NEM8['deathless'], 1)] + \
                 [r8_poster(k, 'qie', S4[:2]) for k in ('corsair_grax_r8', 'ithar_aelith_r8')]
# ---------- R64 redesign (Ryan, Nov 1): Hullbreakers "void hunters", Glasswrights "living prism" (lore_bible_r8.md 4.3, 6.3) ----------
# Concept round c64: four takes per species, Z-Image seeds 11/23/37/51 plus Qwen seeds 11/51 (Ryan leans to s51). Ryan picks one take,
# then every Hullbreaker and Glasswright admiral and Nemesis is repainted in it. The words "bear" and "wolf" are kept out of the
# prompts on purpose: the round 8 renders show the models draw a literal bear or werewolf as soon as either word appears.
VOID = ("A Hullbreaker, a huge hunched alien predator, plainly an alien and not an animal from Earth: no snout, no muzzle, no nose, "
        "no round furry ears, no fur on the face. Massive heavy rounded shoulders and thick forearms ending in heavy claws. A coarse shaggy "
        "mane of {mane} fur only over the neck and shoulders; the rest of the body is tough dark leathery hide. The face is bare and armoured "
        "in overlapping bony plates. The jaw is split vertically down the middle into two hinged halves that open sideways like mandibles, "
        "lined with teeth. Four small glowing eyes sit in one straight row across the brow, with small heat-sensing pits beside them. "
        "Ridged armour plates run down the back and over the shoulders. A scrap armour harness of hull plates torn from other ships is "
        "strapped over the body. Trophies are machine parts and hull plates, never skulls or bones. Not a bear, not a wolf, not a werewolf, "
        "not a human in a costume.")
PRISM = ("A Glasswright, a living alien whose flesh is clear and see-through like glass, plainly not human: the body is transparent, laced "
         "inside with crystal structures and fine glowing threads that carry light through it like fibre optics, and the light splits into "
         "rainbow colours at every edge. Tall and slender with a long neck. The head is faceted like a cut crystal gem, with no eyes, no "
         "mouth, no nose and no ears. Long tapering fingers. Not a grey alien, not a green alien, no big black eyes, no smooth grey skin, "
         "not a robot, not a statue, not an elf, nothing aquatic.")
C64 = {
 'hb_a': ('corsair', "Portrait of a Hullbreaker hunter. " + VOID.format(mane='grey and black') + " The two jaw halves are closed, the "
          "split seam plain down the chin, four amber eyes in a row, calm and patient menace."),
 'hb_b': ('corsair', "Portrait of a Hullbreaker raider mid-snarl. " + VOID.format(mane='black') + " The two jaw halves are spread wide "
          "apart sideways, showing rows of inner teeth, the four eyes in a row glowing red."),
 'hb_c': ('corsair', "Portrait of a Hullbreaker seen from behind and to the side, looking back over its shoulder. " + VOID.format(mane='rust-brown') +
          " The ridged back plates are the clearest thing in the picture, rimed with frost; the four eyes in a row glint over the shoulder."),
 'hb_d': ('corsair', "Portrait of an old Hullbreaker pack-lord. " + VOID.format(mane='grey') + " Slate-dark hide, the face plates scarred "
          "and chipped with pale worn edges, the heat pits glowing faint orange, a harness of dark violet machine plates and a small "
          "listening dish strapped to one shoulder."),
 'gw_a': ('ithar', "Portrait of a Glasswright elder. " + PRISM + " The faceted head is long and smooth, soft bands of coloured light "
          "pulsing across its facets as it speaks, wearing layered robes of crystal plates and mirror-thread fabric."),
 'gw_b': ('ithar', "Portrait of a Glasswright keeper. " + PRISM + " The facets of the head rise into a tall tapering crystal crest; "
          "white light enters the crest and fans out behind the head as a rainbow, a high collar of mirror-thread."),
 'gw_c': ('ithar', "Portrait of a Glasswright. " + PRISM + " The flesh is milky and soft like a jellyfish rather than hard glass, "
          "clusters of clear crystal growing along the neck and shoulders, a warm light glowing deep inside the chest, the face a few soft facets."),
 'gw_d': ('ithar', "Portrait of a Glasswright light-shaper. " + PRISM + " One hand is raised, its long tapering fingers shaping a "
          "glowing shard of glass, threads of light running down the arm into the fingertips, a ripple of colour running across the faceted head."),
}
def c64(i, model, seeds):
    fac, p = C64[i]
    return {'id': i, 'model': model, 'prompt': p + ' ' + STYLE.format(**F8[fac]), 'nosuffix': True, 'seeds': seeds}
BATCHES['c64'] = [c64(k, 'zit', S4) for k in C64] + [c64(k, 'qie', [11, 51]) for k in C64]
# c64 review (Nov 1, not shown to Ryan): both models ignore negations. "Not a bear" and "never skulls" drew literal bears, werewolves
# and skull trophies on every Hullbreaker; the Glasswright bodies were right (glass flesh, light threads, rainbow edges) but every head
# kept eyes and a mouth, and the bodies came out nude and full length. c64b says only what should be there: a plated ankylosaur-like
# head, named machine trophies, a faceless faceted head, a covering robe, and a close head-and-shoulders framing.
VOID2 = ("Close-up head-and-shoulders portrait of a Hullbreaker, a massive alien predator from a cold heavy-gravity world. Its head is a "
         "broad, low, flat-faced wedge covered in overlapping slate-grey armour plates, like the plated head of an ankylosaur. Its jaw is "
         "two heavy plated halves split down the middle of the chin and hinged at the sides, opening sideways like mandibles, each half "
         "lined with rows of small sharp teeth. Four small glowing {eye} eyes sit in one straight row across the plated brow, with rows of "
         "small dark heat-sensing pits along the cheeks below them. A coarse shaggy mane of {mane} hair grows from the back of the head "
         "down the neck and over the huge hunched shoulders. Thick dark leathery hide. Ridged armour plates rise along the spine and over "
         "the shoulders. A scrap armour harness of rusty hull plates and cables is strapped across the chest, hung with machine trophies: "
         "a cracked sensor lens, a torn circuit board, a bent antenna.")
PRISM2 = ("Close-up head-and-shoulders portrait of a Glasswright, a tall slender living alien whose flesh is clear and see-through like "
          "glass. Inside its transparent neck and shoulders run crystal structures and fine glowing threads that carry light like fibre "
          "optics, and the light splits into rainbow colours at every edge. Its head is faceless and featureless: a smooth faceted crystal "
          "form like a long cut gemstone, flat polished facets all over, soft light glowing inside it. A long slender neck. It wears a "
          "high-collared layered robe of crystal plates and silver mirror-thread fabric that covers the body.")
C64B = {
 'hb_a': ('corsair', VOID2.format(eye='amber', mane='grey and black') + " The two jaw halves are closed, the split seam plain down the "
          "chin, a calm and patient menace."),
 'hb_b': ('corsair', VOID2.format(eye='red', mane='black') + " The two jaw halves are spread wide apart sideways in a snarl, showing "
          "rows of inner teeth."),
 'hb_c': ('corsair', VOID2.format(eye='pale blue', mane='rust-brown') + " Seen from behind and to the side, looking back over its "
          "shoulder, the ridged spine plates rimed with white frost."),
 'hb_d': ('corsair', VOID2.format(eye='amber', mane='grey') + " An old pack-lord: the face plates scarred and chipped with pale worn "
          "edges, the heat pits glowing faint orange, a harness of dark violet machine plates with a small listening dish on one shoulder."),
 'gw_a': ('ithar', PRISM2 + " Soft bands of coloured light pulse across the facets of its faceless head as it speaks."),
 'gw_b': ('ithar', PRISM2 + " The facets of its head rise into a tall tapering crystal crest; white light enters the crest and fans "
          "out behind the head as a rainbow."),
 'gw_c': ('ithar', PRISM2 + " Its glass flesh is milky and soft like a jellyfish, the head a rounded faceted dome of milky glass, "
          "clusters of clear crystal growing along the neck and shoulders, a warm light glowing deep inside the chest."),
 'gw_d': ('ithar', PRISM2 + " One hand is raised beside the head, its very long tapering glass fingers shaping a glowing shard of "
          "glass, threads of light running down into the fingertips, a ripple of colour across the faceted head."),
}
def c64b(i, model, seeds):
    fac, p = C64B[i]
    return {'id': i, 'model': model, 'prompt': p + ' ' + STYLE.format(**F8[fac]), 'nosuffix': True, 'seeds': seeds}
BATCHES['c64b'] = [c64b(k, 'zit', S4) for k in C64B] + [c64b(k, 'qie', [11, 51]) for k in C64B]
# c64b review (Nov 1, not shown to Ryan): the Hullbreakers turned plainly alien but swung to a film-monster look (a long domed
# head, cable dreadlocks for a mane, no bear or wolf left in them); the Glasswrights read right (glass, prism light, robes) but a
# faint human face with closed eyes and lips still sits inside most glass heads. c64c: a real fur mane, a shoulder hump and a
# blunt short plated face sunk into it (no dome, no cables); for the Glasswrights the front of the head is one blank mirror facet
# and the glass is living, soft flesh.
VOID3 = ("Close-up head-and-shoulders portrait of a Hullbreaker, a massive alien predator from a cold heavy-gravity world, with the "
         "heavy build of a great hunting beast: a huge muscular shoulder hump and thick forearms with long claws. A thick shaggy mane of "
         "coarse {mane} fur covers the shoulder hump, the neck and the back of the head and frames the face. The face inside the mane is "
         "bare, short, blunt and broad, armoured in overlapping horn-like plates like a pangolin's scales, set low between the shoulders. "
         "Its jaw is two heavy plated halves split down the middle of the chin and hinged at the sides, opening sideways, each half lined "
         "with rows of small sharp teeth. Four small glowing {eye} eyes sit in one straight row across the plated brow, with rows of small "
         "dark heat-sensing pits along the cheeks. Thick dark leathery hide on the arms. Ridged armour plates show through the mane along "
         "the spine. A scrap armour harness of rusty riveted hull plates and leather straps is strapped across the chest, hung with machine "
         "trophies: a cracked sensor lens, a torn circuit board, a bent antenna.")
PRISM3 = ("Close-up head-and-shoulders portrait of a Glasswright, a tall slender living alien whose flesh is soft, clear and see-through "
          "like the living glass body of a jellyfish, faintly pulsing. Inside its transparent neck and shoulders run crystal structures and "
          "fine glowing threads that carry light like fibre optics, and the light splits into rainbow colours at every edge. Its head is a "
          "tall smooth faceted crystal shape like a long cut gemstone; the whole front of the head is one large flat blank polished facet "
          "like a mirror, reflecting the light, with glowing colour moving deep inside the head behind it. A long slender neck. It wears a "
          "high-collared layered robe of crystal plates and silver mirror-thread fabric that covers the body.")
C64C = {
 'hb_a': ('corsair', VOID3.format(eye='amber', mane='grey and black') + " The two jaw halves are closed, the split seam plain down the "
          "chin, a calm and patient menace."),
 'hb_b': ('corsair', VOID3.format(eye='red', mane='black') + " The two jaw halves are spread wide apart sideways in a snarl, showing "
          "rows of inner teeth."),
 'hb_c': ('corsair', VOID3.format(eye='pale blue', mane='rust-brown') + " Seen from behind and to the side, looking back over its "
          "shoulder, white frost on the mane and on the ridged spine plates."),
 'hb_d': ('corsair', VOID3.format(eye='amber', mane='grey') + " An old pack-lord: the face plates scarred and chipped with pale worn "
          "edges, the heat pits glowing faint orange, a harness of dark violet machine plates with a small listening dish on one shoulder."),
 'gw_a': ('ithar', PRISM3 + " Soft bands of coloured light pulse across the mirror facet of its head as it speaks."),
 'gw_b': ('ithar', PRISM3 + " The facets of its head rise into a tall tapering crystal crest; white light enters the crest and fans "
          "out behind the head as a rainbow."),
 'gw_c': ('ithar', PRISM3 + " Its glass flesh is milky and soft, clusters of clear crystal growing along the neck and shoulders, a warm "
          "light glowing deep inside the chest."),
 'gw_d': ('ithar', PRISM3 + " One hand is raised beside the head, its very long tapering glass fingers shaping a glowing shard of "
          "glass, threads of light running down into the fingertips, a ripple of colour across the mirror facet."),
}
def c64c(i, model, seeds):
    fac, p = C64C[i]
    return {'id': i, 'model': model, 'prompt': p + ' ' + STYLE.format(**F8[fac]), 'nosuffix': True, 'seeds': seeds}
BATCHES['c64c'] = [c64c(k, 'zit', S4) for k in C64C] + [c64c(k, 'qie', [11, 51]) for k in C64C]
# ---------- R64 picks (Ryan, Nov 1 06:02): Hullbreakers A1, Glasswrights A; lore_bible_r8.md 4.3 and 6.3 ----------
# Hullbreakers A1 (c64c/hb_b_qie_s51), "but careful about them looking too much like the Predator": the prompt says only what is
# there (a fur mane, a beast's hunched bulk with the chest under a harness, bony scale plates growing from the hide, a chin split
# into two halves) so no Predator tell gets drawn (quills, tusks, mesh, a domed helmet head, a bodybuilder's bare torso).
# Glasswrights A (c64c/gw_a_qie_s51), "not literally glass": living skin, sinew and soft flesh with glass threads and crystal
# inlays grown into it; the faceless front of the head stays one blank crystal facet (the line that kept faces away in c64c).
# Both are pushed toward the oil paint of the other portraits: the Qwen render fixes the design, then Z-Image repaints it at
# partial strength (zi2i in portrait_run.py) so the design holds and the finish turns to oil paint.
VOID4 = ("Close-up head-and-shoulders portrait of a Hullbreaker, a huge alien hunting beast from a cold heavy-gravity world, hunched "
         "forward with the heavy rounded bulk of a great predator: a tall shoulder hump, a thick short neck, a broad barrel body and "
         "thick forearms ending in heavy curved claws. A thick coarse shaggy mane of {mane} fur covers the hump, the shoulders, the neck "
         "and the back of the head and frames the face; the arms are thick dark leathery hide with coarse hair. The head is low, broad "
         "and blunt, sunk into the mane between the shoulders. The face is bare: overlapping grey bony plates like a pangolin's scales "
         "grow out of the hide, worn and chipped at the edges. The jaw is split down the middle of the chin into two plated halves "
         "hinged at the sides, {jaw}. A row of four small glowing {eye} eyes sits in one straight line across the plated brow, and "
         "rows of small dark heat-sensing pits run along the cheeks below them. A heavy scrap armour harness of rusty riveted hull "
         "plates from other ships and thick leather straps covers the chest and belly{gear}.")
JAW_OPEN = "the two halves spread apart to the left and right in a snarl, rows of small sharp teeth lining the inner edges"
JAW_SHUT = "the two halves closed, a deep seam running down the middle of the chin"
TROPHY = ", hung with machine trophies: a cracked sensor lens, a torn circuit board, a bent antenna"
PRISM4 = ("Close-up head-and-shoulders portrait of a Glasswright, a tall slender living alien of flesh and blood that grows glass into "
          "its own body. Its skin is pearl-white and soft with a warm pink flush, thin and faintly translucent like wax, so soft flesh "
          "and fine pink sinew show through at the neck and throat. Fine threads of clear glass and small faceted crystal inlays are "
          "grown into the skin in flowing lines along the neck, the collarbones and the hands, like veins of glass in living flesh; "
          "light runs along the glass threads like fibre optics and splits into rainbow colours where it leaves the crystal inlays. "
          "A long slender neck. The head is a long smooth living head of pale skin, plated with grown crystal facets fused into the "
          "skin, skin and sinew showing at the seams between the plates; the whole front of the head is one large flat blank polished "
          "crystal facet like a mirror, with soft coloured light moving deep behind it. Long tapering fingers. {gear}")
ROBE = "It wears a high-collared layered robe of crystal plates and silver mirror-thread fabric."
K64 = {
 'hb_snarl': ('corsair', VOID4.format(mane='black', jaw=JAW_OPEN, eye='red', gear=TROPHY)),
 'hb_calm': ('corsair', VOID4.format(mane='grey and black', jaw=JAW_SHUT, eye='amber', gear=TROPHY) + " The heat pits glow faint "
             "orange; a calm, patient menace."),
 'gw_speak': ('ithar', PRISM4.format(gear=ROBE) + " Soft bands of coloured light pulse across the crystal of its head and down the "
              "glass threads of its neck as it speaks."),
 'gw_hand': ('ithar', PRISM4.format(gear=ROBE) + " One hand is raised beside the head, its very long tapering fingers of pale skin "
             "inlaid with glass threads shaping a glowing shard of glass, light running down the threads into the fingertips."),
}
def k64(i, model, seeds, ref=None, denoise=None, tag=None):
    fac, p = K64[i]
    it = {'id': tag or i, 'model': model, 'prompt': p + ' ' + STYLE.format(**F8[fac]), 'nosuffix': True, 'seeds': seeds}
    if ref: it['ref'] = ref; it['denoise'] = denoise
    return it
# check round k64 (one sheet per species, seed 51): the Qwen design, Z-Image alone, the Qwen design repainted by Z-Image at
# 0.50 and 0.65 strength, and Ryan's pick itself repainted at 0.55
BATCHES['k64'] = ([k64(k, 'qie', [51]) for k in K64] + [k64(k, 'zit', [51]) for k in K64] +
                  [k64(k, 'zi2i', [51], 'k64/%s_qie_s51_00001_.png' % k, d, '%s_p%d' % (k, d * 100)) for k in K64 for d in (0.5, 0.65)] +
                  [k64('hb_snarl', 'zi2i', [51], 'c64c/hb_b_qie_s51_00001_.png', 0.55, 'hb_a1_p55'),
                   k64('gw_speak', 'zi2i', [51], 'c64c/gw_a_qie_s51_00001_.png', 0.55, 'gw_a1_p55')])
OUT = {'n1a': 'n1', 'n1b': 'n1', 'b2': 'b2', 'n2': 'n2', 'n3': 'n3', 'r8a': 'r8', 'r8b': 'r8', 'r8c': 'r8', 'c64': 'c64', 'c64b': 'c64b', 'c64c': 'c64c', 'k64': 'k64'}
if __name__ == '__main__':
    os.makedirs(os.path.join(HERE, 'batches'), exist_ok=True)
    for k, items in BATCHES.items():
        json.dump({'out': OUT.get(k, 'b1'), 'budget_s': 960, 'items': items}, open(os.path.join(HERE, 'batches', k + '.json'), 'w'), indent=1)
        print(k, len(items), 'items', sum(len(i['seeds']) for i in items), 'images')
