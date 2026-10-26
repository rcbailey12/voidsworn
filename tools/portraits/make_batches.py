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
  "Portrait of The Mending Choir, a Chorus bio-swarm admiral in the form of a Living Suture-Hive: a pulsing biological cocoon-graft, "
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
  "Portrait of Admiral Castellan Vex of the Voidsworn Crusade, a stern weathered human fleet admiral in his late fifties, shaved scarred head with ritual oath scars, "
  "grey stubble, hard tired eyes, a high-collared dark armoured space-fleet greatcoat with ornate ceramite shoulder plates, red wax votive seals and parchment oath strips pinned to the chest, "
  "a small brass reliquary on a chain, behind him through a tall gothic viewport a distant line of battleships firing a broadside of orange lance beams into the void."),
 'hegemony_kassar': ('hegemony',
  "Portrait of Grand Admiral Ilsa Kassar of the Hegemony Navy, a composed precise human woman in her early fifties, silver hair in a severe short cut, cold grey eyes, "
  "a pale grey high-collared space-fleet dress uniform with rows of flat blue enamel rank bars and clean geometric shoulder boards, gloved hands clasped behind her back, "
  "faint blue targeting grids reflected on her face, behind her a pale clinical bridge where many identical firing-solution displays glow in perfect rows."),
 'corsair_grax': ('corsair',
  "Portrait of Warlord Grax Ironjaw of the Ashfall Corsairs, a hulking scarred human space pirate warlord, a crude riveted iron prosthetic lower jaw, "
  "a grin of steel, one cybernetic red eye, a shaved head with old burn scars, patchwork armour welded together from three different fleets' salvaged plates in clashing colours, "
  "mismatched stolen medals and torn insignia, grease and rust, a heavy boarding axe resting on his shoulder, sparks raining behind him in a cramped junk-built space-ship cockpit."),
 'ithar_aelith': ('ithar',
  "Portrait of Aelith Dawnsail of the Ithar, an ancient dying elder alien race, a statuesque luminous alien being, clearly not human: an elongated skull and very long slender neck, "
  "huge wide-set solid black eyes, pale translucent porcelain skin with glowing gold light channels running beneath it, long seven-fingered hands raised gracefully, "
  "behind her a radiant fan of near-geometric light sails like stained glass made of light, a flight of tiny glowing star-craft wheeling around her like a murmuration. "
  "Nothing aquatic: no fins, no gills, no scales."),
 'deathless_nekhet': ('deathless',
  "Portrait of Overlord Nekhet the Undying of the Deathless Dynasty, a machine intelligence with no humanoid body: a monumental broken ring of bone-white ceramic computation plates "
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
  "Portrait of Aelith Dawnsail of the Ithar, an ancient dying elder alien race: a tall regal luminous alien noble, clearly not human and "
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
SUB2 = {}   # n2 subjects, same ids as n1 (nem_<faction>_<n>), rendered into n2\
for _fac, _L in NEM2.items():
    for _n, _d in enumerate(_L, 1):
        _k = 'nem_%s_%d' % (_fac, _n)
        if _fac == 'ithar':
            SUB2[_k] = (_fac, 'Portrait of a Nemesis, a rival enemy commander of the Ithar: %s. %s' % (_d, ITHAR) + NEM_STYLE, STYLE)
        else:
            SUB2[_k] = (_fac, 'A Nemesis of the %s, a rival enemy war-organism: %s. %s' % (_fac.capitalize(), _d, NOBODY if _fac == 'chorus' else
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
    SUB3[_k] = (_fac, 'A Nemesis of the %s, a rival enemy war-organism: %s. %s' % (_fac.capitalize(), _d, NOBODY if _fac == 'chorus' else
                'A machine with no figure, no statue, no head, no face, no body, no robot, no legs, no arms.') + NEM_STYLE, CREATURE)
for _fac, _L in NEM.items():
    for _n, _d in enumerate(_L, 1):
        _pre = HUMAN + ' ' if _fac in ('voidsworn', 'hegemony', 'corsair') else (CH + ' ' if _fac == 'chorus' else '')
        SUBJECT['nem_%s_%d' % (_fac, _n)] = (_fac, 'Portrait of a Nemesis, a rival enemy commander of the %s: %s. %s' % (_fac.capitalize(), _d, _pre) + NEM_STYLE)

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
OUT = {'n1a': 'n1', 'n1b': 'n1', 'b2': 'b2', 'n2': 'n2', 'n3': 'n3'}
if __name__ == '__main__':
    os.makedirs(os.path.join(HERE, 'batches'), exist_ok=True)
    for k, items in BATCHES.items():
        json.dump({'out': OUT.get(k, 'b1'), 'budget_s': 960, 'items': items}, open(os.path.join(HERE, 'batches', k + '.json'), 'w'), indent=1)
        print(k, len(items), 'items', sum(len(i['seeds']) for i in items), 'images')
