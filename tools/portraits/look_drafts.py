# DRAFTS, NOT TO RUN until Ryan signs off the new faction looks (lore bible, round 4 "science fiction pass", Oct 27).
# Builds ready-to-queue batch files for the factions whose look is changing, into tools/portraits/batches/drafts/:
#   draft_posters.json    a fresh poster admiral per changing faction (Z-Image Turbo and Qwen-Image-Edit, 4 seeds each)
#   draft_restyle.json    Qwen-Image-Edit passes on the current picks that keep the face and composition and change only the
#                         look (portrait_edit.py format): the cheap way to move the seven painted admirals to the new looks
#   draft_nem_<fac>.json  six new Nemesis subjects per changing faction (Z-Image Turbo, 3 seeds each)
# Run: python3 tools/portraits/look_drafts.py   then, after sign-off, copy a draft to portraits\tools\ on the PC and queue it
# like the other portrait jobs (portrait_run.py gen <batch> or portrait_edit.py <batch>).
#
# Looks used (lore bible round 4, sections 2.5, 3.3, 4.3, 5.3, 6.3, 7.3; round 3 is superseded where they differ):
#   voidsworn  (Sunward Crusade)  unaugmented humans: frost-scarred skin, surgical scars where implants were cut out, oath brands,
#              names chalked on armour plates; dark void-coats, heavy shoulder plates; black iron, ember, ash, frost white.
#              No saints, wax seals, parchment, reliquaries, candles or ceramite (lore 2.5 and the round 2 portrait note).
#   hegemony   composed humans with a neural-lace port at the temple (faint blue light), ocular implants with data in the iris,
#              thin subdermal lines along the jaw and hands; pale grey and steel blue, implant blue. No "commissar".
#   corsair    (Ashfall Hullbreakers) grimmer: burn scars, red cyber eyes, riveted iron jaws, armour welded from plates cut off
#              victims, trophies from every faction (crystal, link ports, violet plates), hooks and chains; soot, rust, dried blood.
#   ithar      (Glasswrights) biological, not human: tall, slender, long necks, elongated skulls, large dark eyes, pale skin,
#              layered crystal and mirror-thread fabrics, small light-cores as jewellery; clear crystal, silver, rainbow edge.
#   deathless  (the Eclipsed, was Undimmed) tall machine bodies of layered dark violet-black plates, a narrow white-gold visor,
#              a small core of trapped light in the chest; great minds are a broken ring of plates round a glowing core with
#              repair drones. White-gold and violet, never green; no tombs, crowns, thrones or Egyptian motifs (lore 7.2).
#   chorus     look unchanged in shape; colour proposed to move off purple to dark olive-brown flesh, ochre chitin and bile
#              yellow-green glow (lore 5.3). Only restyle edits are drafted for it (recolour the two painted Chorus admirals).
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from make_batches import STYLE, CREATURE, NEM_STYLE, NOBODY

F4 = {
 'voidsworn': dict(glow='warm ember-orange furnace light', plate='dark black-iron warship bridge, frost on the viewports, glowing ember-orange heat-radiator spires outside'),
 'hegemony': dict(glow='cool clinical blue-white light', plate='clean pale grey command deck with rows of steel-blue holographic displays'),
 'corsair': dict(glow='harsh red emergency light and sparks', plate='soot-black salvage-ship cockpit hung with chains and hooks, smoke and rust'),
 'ithar': dict(glow='warm white light split into faint rainbow fringes', plate='deep space seen through faceted crystal and silver mirrors'),
 'deathless': dict(glow='pale white-gold corona light', plate='black void around the dark disc of a black hole ringed by a thin white-gold glow'),
 'chorus': dict(glow='bile yellow-green bioluminescent light', plate='wet dark olive-brown organic cavern of membrane and spore haze'),
}
HUMAN = "A human, a space-fleet commander, nothing naval: no hats, no sailor uniforms."
GLASS = ("A Glasswright, a tall slender biological alien, clearly not human and not a grey alien: an elongated skull, a very long slender "
         "neck, large dark eyes, pale skin, wearing layered robes of crystal plates and mirror-thread fabric that catch the light, "
         "small glowing light-cores worn as jewellery.")
ECLIPSED = ("An Eclipsed machine being: a tall machine body built from layered dark violet-black armour plates, a narrow horizontal visor "
            "of white-gold light where a face would be, a small core of trapped white light glowing in the chest. Not a skeleton, "
            "no skull, no green light, no crown, no Egyptian motifs.")

POSTERS = {
 'voidsworn_vex_r4': ('voidsworn', STYLE,
  "Portrait of a Sunward Crusade fleet admiral, a stern weathered unaugmented human man in his late fifties, a shaved head, frost-scarred "
  "pale skin, old surgical scars at the temple and neck where implants were cut out, a burned oath brand on the brow, grey stubble, hard "
  "tired eyes, a high-collared dark void-coat with heavy black iron shoulder plates, names of the dead chalked in white on the plates, "
  "chalk dust on his gloves, behind him through a frosted viewport a line of black iron warships with glowing ember-orange radiator spires "
  "firing a broadside into the void."),
 'hegemony_kassar_r4': ('hegemony', STYLE,
  "Portrait of a Hegemony Navy grand admiral, a composed precise human woman in her early fifties, silver hair in a severe short cut, a "
  "small neural-lace port at her temple glowing faint blue, ocular implants with lines of data moving across her grey irises, thin glowing "
  "subdermal lines along her jaw, a pale grey high-collared dress uniform with flat steel-blue rank bars, gloved hands clasped behind her, "
  "calm to the point of eerie, behind her many identical firing-solution displays glowing in perfect rows."),
 'corsair_grax_r4': ('corsair', STYLE,
  "Portrait of a Hullbreaker warlord, a hulking burn-scarred human raider, a riveted iron prosthetic lower jaw, one cybernetic red eye, "
  "armour welded together from plates cut off the ships of his victims, trophies hung on chains across his chest: a shard of clear crystal, "
  "a torn neural link port, a dark violet machine plate, a heavy boarding hook over his shoulder, soot and dried blood, a grim cold stare."),
 'ithar_aelith_r4': ('ithar', STYLE,
  "Portrait of a Glasswright elder, " + GLASS + " A grieving dignified face, a high collar of faceted crystal, one long-fingered hand "
  "raised holding a small glowing light-core, behind her tall crystal vanes and silver mirrors that split the light into rainbow fringes. "
  "Nothing aquatic: no fins, no gills, no scales."),
 'deathless_ring_r4': ('deathless', CREATURE,
  "The greatest mind of the Eclipsed, a machine intelligence: a monumental broken ring of layered dark violet-black plates floating around "
  "a blazing core of white-gold light, cracked ring segments drifting apart and being refitted by tiny repair drones with thin white beams, "
  "a faint violet-white inner glow. No figure, no statue, no head, no face, no body, no robot inside the ring, no green light."),
 'deathless_body_r4': ('deathless', STYLE,
  "Portrait of an Eclipsed admiral. " + ECLIPSED + " Shoulders of overlapping plates like a heat shield, a cold patient grieving presence."),
}

# Qwen-Image-Edit passes on the current picks (src relative to comfy_io\PORTRAITS\). Keep face, pose and composition.
KEEP = " Keep the same face, pose, composition, lighting direction and painting style."
RESTYLE = {
 'vex': ('b1/voidsworn_vex_qie_s11_00001_.png',
  "Remove every wax seal, parchment strip and reliquary. Add frost scars across his face and an old burned oath brand on his brow, "
  "surgical scars at his temple where implants were cut out, and names chalked in white on his black iron shoulder plates. Make the "
  "colours black iron, ember orange, ash grey and frost white." + KEEP),
 'kassar': ('b1/hegemony_kassar_qie_s23_00001_.png',
  "Add a small neural-lace port at her temple glowing faint blue, lines of data moving across her irises, and thin faint blue subdermal "
  "lines along her jaw." + KEEP),
 'grax': ('b1/corsair_grax_qref_s23_00001_.png',
  "Make him grimmer: soot and dried blood on the armour, trophies on chains across his chest (a shard of clear crystal, a torn neural link "
  "port, a dark violet machine plate), the axe replaced by a heavy boarding hook, a cold stare instead of a grin." + KEEP),
 'nekhet': ('b2/deathless_nekhet_b_qie_s23_00001_.png',
  "Recolour this machine: the ring plates become layered dark violet-black armour, the green core becomes blazing white-gold light, every "
  "green beam and light becomes white-gold, a faint violet-white inner glow. Remove the bone-white ceramic look." + KEEP),
 'aelith': ('b2/ithar_aelith_b_qie_s37_00001_.png',
  "Replace the glowing gold channels under her skin with plain pale skin, dress her in layered robes of faceted crystal plates and "
  "mirror-thread fabric, add small glowing light-cores as jewellery, and turn the light sails behind her into tall crystal vanes and "
  "silver mirrors that split the light into rainbow fringes." + KEEP),
 'matriarch': ('b1/chorus_matriarch_zit_s51_00001_.png',
  "Recolour this organism: dark olive-brown flesh instead of purple, ochre chitin ridges, bile yellow-green glow, and a dark olive-brown "
  "cavern behind it instead of purple." + " Keep the same organism, its shape, composition, lighting direction and painting style."),
 'mending': ('b2/chorus_mending_b2_zit_s11_00001_.png',
  "Recolour this organism: dark olive-brown flesh and membrane instead of pink and purple, ochre bone needles, bile yellow-green glow, "
  "and a dark olive-brown cavern behind it." + " Keep the same organism, its shape, composition, lighting direction and painting style."),
}

NEM4 = {
 'voidsworn': [
  "a gaunt frost-scarred zealot commander, a fresh oath brand burned into the forehead, hollow burning eyes, a black iron collar, names chalked on the armour",
  "a massive armoured line-breaker with a battered black iron rebreather mask, frost on the plates, ember-orange light in the eye slits",
  "a cold aristocratic woman commander, shaved head criss-crossed with surgical scars where implants were torn out, black armour, a thin cruel smile",
  "an old white-bearded commodore with a furious glare, one arm replaced by a heavy hand-forged black iron mechanical arm, frost-bitten skin",
  "a hooded executioner-commodore, a black iron visor half raised over a scarred jaw, ash on his armour",
  "a young fanatic commander with a row of oath brands along the brow, frostbitten ears, a mad devout stare",
 ],
 'hegemony': [
  "a bald surgeon-faced political officer with a neural-lace port glowing at the temple and a red targeting implant in one iris, black gloves",
  "a severe woman admiral, platinum hair slicked back, subdermal blue lines glowing along her jaw, a high collar with flat steel-blue rank bars",
  "a heavyset fleet marshal with heavy jowls, twin neural ports behind the ear, data moving across pale contemptuous eyes",
  "a young prodigy admiral with razor-sharp features, a thin blue implant line across the brow, a cold smile",
  "an intelligence chief whose left half of the face is a smooth pale grey implant plate with a single blue lens",
  "an elderly fleet lord with white hair and a lattice of blue implant lights at the neck and temple, cruel patient eyes",
 ],
 'corsair': [
  "a raider queen with a burned scalp and a shaved undercut, gold teeth, a chain of stolen neural link ports round her neck",
  "a hulking brute with a welded steel faceplate cut from a Hegemony hull and a single red optic, hooks hanging from the shoulders",
  "a wiry knife-man with old acid burns, cracked goggles, a crest of braided cables, a shard of clear crystal set in his cheek",
  "a smuggler baron in a coat stitched from torn hull insignia, rings on every finger, a dark violet machine plate as a breastplate",
  "a weathered old wrecker captain with a battered respirator and chains wrapped round soot-black armour, one squinting red eye",
  "a feral young warlord with war paint of soot and dried blood, a necklace of trophy teeth and machine parts",
 ],
 'ithar': [
  "a gaunt Glasswright inquisitor with a cold pitiless gaze, a high collar of sharp crystal shards",
  "a Glasswright seer with a veil of fine mirror-threads over the eyes, long blade-like fingertips",
  "a Glasswright war-matriarch in armour of overlapping crystal petals that split light into rainbow fringes",
  "a Glasswright exile with dimmed cracked light-core jewellery and a ragged mirror-thread robe",
  "a Glasswright archon with a smooth mask of polished mirror where the face should be",
  "an ancient Glasswright with skin like aged ivory and an extremely long neck, a single dark eye reflecting a dead sun",
 ],
 'deathless': [
  "seven tall dark violet-black plate pylons floating in a ring round a single small white-gold light, thin white beams joining them",
  "a towering spine of layered dark violet-black plates coiled round a white-gold core, like a serpent of heat shields, no head",
  "thousands of tiny dark violet plates swarming in a shifting sphere round a white-gold core",
  "a tall machine figure of dark violet-black plates with a cracked white-gold visor, its chest core flickering",
  "a vast fan of overlapping dark violet heat-shield plates opening round a small white-gold core like an eclipse",
  "a broken ring of dark violet-black blades floating over a dark pit, a thin white-gold corona round its empty centre",
 ],
}

def poster(i, model, seeds):
    fac, style, p = POSTERS[i]
    it = {'id': i, 'model': model, 'prompt': p + ' ' + style.format(**F4[fac]), 'nosuffix': True, 'seeds': seeds}
    if model == 'qref':
        it['ref'] = 'plate_%s.png' % fac
        it['prompt'] = 'Paint a full new character portrait onto this dark background, filling the frame. ' + it['prompt']
    return it

def nem(fac, n, d):
    if fac in ('voidsworn', 'hegemony', 'corsair'):
        p, style = 'Portrait of a Nemesis, a rival enemy commander: %s. %s' % (d, HUMAN), STYLE
    elif fac == 'ithar':
        p, style = 'Portrait of a Nemesis, a rival enemy commander of the Glasswrights: %s. %s' % (d, GLASS), STYLE
    else:
        machine = n == 4   # the one Eclipsed body; the rest are machines with no figure
        p = 'A Nemesis of the Eclipsed: %s. %s' % (d, ECLIPSED if machine else 'A machine with no figure, no statue, no head, no face, no body, no robot, no green light.')
        style = STYLE if machine else CREATURE
    return {'id': 'nem_%s_%d' % (fac, n), 'model': 'zit', 'prompt': p + NEM_STYLE + ' ' + style.format(**F4[fac]), 'nosuffix': True, 'seeds': [11, 23, 37]}

if __name__ == '__main__':
    D = os.path.join(HERE, 'batches', 'drafts'); os.makedirs(D, exist_ok=True)
    note = 'DRAFT: do not queue until Ryan signs off the new faction looks (lore round 4). Built by tools/portraits/look_drafts.py.'
    S4 = [11, 23, 37, 51]
    items = [poster(k, 'zit', S4) for k in POSTERS] + [poster(k, 'qie', S4[:2]) for k in POSTERS if POSTERS[k][1] is STYLE]
    json.dump({'note': note, 'out': 'r4', 'budget_s': 1050, 'items': items}, open(os.path.join(D, 'draft_posters.json'), 'w'), indent=1)
    print('draft_posters', len(items), 'items', sum(len(i['seeds']) for i in items), 'images')
    ed = [{'id': a, 'kind': 'r4', 'seed': s, 'src': src, 'prompt': p} for a, (src, p) in RESTYLE.items() for s in (11, 23)]
    json.dump({'note': note, 'out': 'r4e', 'budget_s': 1050, 'items': ed}, open(os.path.join(D, 'draft_restyle.json'), 'w'), indent=1)
    print('draft_restyle', len(ed), 'edits')
    for fac, L in NEM4.items():
        it = [nem(fac, n, d) for n, d in enumerate(L, 1)]
        json.dump({'note': note, 'out': 'n4', 'budget_s': 1050, 'items': it}, open(os.path.join(D, 'draft_nem_%s.json' % fac), 'w'), indent=1)
        print('draft_nem_' + fac, len(it), 'items', sum(len(i['seeds']) for i in it), 'images')
