# Builds the Qwen-Image-Edit job lists for the Nemesis pool (run with portrait_edit.py on the PC):
#   batches/n1fix.json      fixes to picked renders (caps the prompt said not to draw, a lookalike helmet), into comfy_io\PORTRAITS\nfix\
#   batches/n1s_a/b/c.json  the painted first scar (c: Chorus only while Ithar and Deathless looks are in review) for every picked Nemesis and every scar kind its faction can take, into ..\n1s\
# The picks (which render seed is the pool portrait) live in NEM_PICKS; a fixed render replaces its pick as the source.
# Run: python3 tools/portraits/make_edits.py
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
KEEP = " Keep the same character, face, pose, clothing, lighting, background and painting style; change nothing else."
# organisms and machines: no "face" or "clothing" in the keep line, which nudged the edit model toward a person
KEEP_OBJ = " Keep the same organism, its shape, colours, lighting, background and painting style; change nothing else."
# pool picks (Oct 26 review): faction -> seed per Nemesis 1..6; folder n1 (first renders) or n2 (Chorus, Deathless, Ithar reruns)
NEM_PICKS = {
 'voidsworn': ('n1', [23, 11, 11, 11, 11, 23]),
 'hegemony':  ('n1', [23, 23, 23, 23, 11, 11]),
 'corsair':   ('n1', [23, 11, 23, 11, 23, 11]),
 # a ('n3', seed) entry overrides the faction folder for that Nemesis
 # Chorus n3 picks (Oct 27): 2 s11 fungus bursting from a husk (s23/s37/s51 grew clawed hands), 3 s37 spiked dome (the others
 # have a fanged face and eyes), 4 s11 brain-backed leviathan (vetoable: the model drew the 'size of a whale' literally)
 'chorus':    ('n2', [11, ('n3', 11), ('n3', 37), ('n3', 11), 23, 11]),
 # Deathless on hold (lore round 3: the Undimmed look replaces it); n3 picks not made
 'deathless': ('n2', [('n3', 0), 11, 23, 37, 11, ('n3', 0)]),
 'ithar':     ('n2', [23, 37, 11, 23, 23, 23]),
}

def pick_path(nid):
    """render path (relative to comfy_io\\PORTRAITS\\) of a Nemesis's picked render, before any fix"""
    fac = nid.split('_')[1]; n = int(nid.split('_')[2]); folder, seeds = NEM_PICKS[fac]; s = seeds[n - 1]
    if isinstance(s, tuple): folder, s = s
    return '%s/%s_zit_s%d_00001_.png' % (folder, nid, s)
FIXES = {
 'nem_voidsworn_6': "Remove the peaked officer cap from this man's head and show his bare shaved head with a row of small ritual piercings along the brow.",
 'nem_hegemony_4':  "Remove the peaked officer cap from this man's head and show short slicked-back dark hair; keep the thin glowing visor across his eyes.",
 'nem_hegemony_5':  "Remove the peaked officer cap and show a bald head; make the chrome mask cover only the left half of the face, the right half is a pale, stern human face.",
 'nem_corsair_1':   "Remove the peaked officer cap from this woman's head and show a shaved undercut hairstyle with the long top swept to one side.",
 'nem_corsair_2':   "Replace the helmet with a crude faceplate welded together from mismatched rusty scrap plates with rivets and weld seams, a single round red optic on one side.",
}
SCAR = {
 'burn': {'human': "Add one large old healed burn scar to this person: waxy, puckered, pink-red burn tissue spreading over one cheek, the jaw and the side of the neck.",
          'chorus': "Add a large old burn wound to this organism: a patch of scorched, blistered, blackened flesh on one side, healed over with waxy pink scar tissue.",
          'ithar': "Add an old burn scar to this being: a patch of scorched, darkened porcelain skin on one side of the face and neck, its gold light channels broken and dark there.",
          'deathless': "Add burn damage to this machine: one side scorched black with heat-blistered, discoloured metal and melted edges."},
 'cyber': "Replace one of this person's eyes and the cheekbone around it with a crude bolted-on cybernetic implant: a dark gunmetal plate with rivets and a glowing red lens, raw scar tissue where it meets the skin.",
 'eye': "Add a deep old blade scar running vertically through one of this person's eyes from brow to cheek; that eye is milky white and blind, with old stitch marks along the scar.",
 # carapace v2 (Oct 27): v1 painted bright yellow lightning-like cracks running off the body into the background on 5 of 6 Chorus
 'carapace': "Add one deep half-healed wound to this organism's own shell or skin on one side of its body: a jagged split edged with raw pink tissue and a little dull yellow ooze, a few short cracks around it. The damage stays on the organism's body; the background does not change. No lightning, no glowing lines, no beams, no rays.",
 'porcelain': "Add a web of cracks across this being's porcelain skin on one side of the head and neck, golden light leaking from the cracks, a small chip of skin missing.",
 'machine': "Tear a jagged hole in this machine's plating on one side, exposing green-lit circuitry and tangled cables inside, the torn metal edges scorched.",
}
KINDS = {'voidsworn': ['burn', 'cyber', 'eye'], 'hegemony': ['burn', 'cyber', 'eye'], 'corsair': ['burn', 'cyber', 'eye'],
         'chorus': ['burn', 'carapace'], 'ithar': ['burn', 'porcelain'], 'deathless': ['burn', 'machine']}

# n1s_c2 picks (Oct 27): which seed's carapace edit is published per Chorus Nemesis (copied as the s11 file for nemesis_publish.py)
CARAPACE_PICK = {1: 23, 2: 23, 3: 11, 4: 23, 5: 23, 6: 23}

def src_of(fac, n):
    # scar edits paint on the bust crop (nemesis_crop.py), uploaded to comfy_io\PORTRAITS\ncrop\
    return 'ncrop/nem_%s_%d.png' % (fac, n)

def scar_prompt(fac, k):
    s = SCAR[k]
    if isinstance(s, dict): s = s.get(fac, s['human'])
    return s + (KEEP_OBJ if fac in ('chorus', 'deathless') else KEEP)

# ---------- round 8 looks (lore approved Oct 27, R59): restyle edits that keep each face and composition ----------
# batches/r8e.json -> comfy_io\PORTRAITS\r8e\<id>_r8_s<seed>_00001_.png. Chorus: recolour off purple (bible 5.3). Sunward Crusade:
# unaugmented, frost scars, no religious ornament (2.4, 2.5). Hegemony: tasteful implants, pale grey uniforms (3.3). Nemesis ids edit
# their bust crop; the touched-up crop is then re-scarred (r8s batches) so every scar is painted on the new look.
KEEP_P = " Keep the same face, pose, composition, lighting direction and painting style."
CHORUS_RC = ("Recolour this organism: dark olive-brown flesh and membrane instead of purple or pink, ochre bone and chitin, bile "
             "yellow-green glow, and a dark olive-brown cavern behind it instead of purple.")
CRUSADE = ("Make this a plain unaugmented human soldier: remove any glowing eyes, implants, religious ornaments, wax seals, parchment, "
           "scripture, censers, candles, crosses and skulls; plain black iron armour with names chalked on it in white; add pale frost "
           "scars on the exposed skin.")
HEGE = ("Give this officer tasteful implants: a small cortical-link port at the temple glowing faint blue, faint lines of blue data in "
        "the irises, and thin faint blue subdermal lines along the jaw; the uniform becomes pale grey with steel-blue trim.")
R8E = {
 'nem_chorus_%d' % n: ('ncrop/nem_chorus_%d.png' % n, CHORUS_RC + KEEP_OBJ, [11]) for n in range(1, 7)}
R8E.update({
 'matriarch': ('b1/chorus_matriarch_zit_s51_00001_.png', CHORUS_RC + KEEP_OBJ, [11, 23]),
 'mending': ('b2/chorus_mending_b2_zit_s11_00001_.png', CHORUS_RC + KEEP_OBJ, [11, 23]),
 'nekhet': ('b2/deathless_nekhet_b_qie_s23_00001_.png', "Recolour this machine: the ring plates become layered dark violet-black armour, the "
            "green core becomes blazing white-gold light, every green beam and light becomes white-gold, a faint violet-white inner glow; "
            "no bone-white ceramic." + KEEP_OBJ, [11, 23]),
 'vex': ('b1/voidsworn_vex_qie_s11_00001_.png', "Remove every wax seal, parchment strip, reliquary, candle and gothic church window. Add pale "
         "frost scars across his face, an old burned oath brand on his brow, surgical scars at the temple where implants were cut out, and "
         "names chalked in white on his black iron shoulder plates; the window shows black iron warships with ember-orange radiator spires." + KEEP_P, [11, 23]),
 'kassar': ('b1/hegemony_kassar_qie_s23_00001_.png', "Add a small cortical-link port at her temple glowing faint blue, lines of blue data "
            "moving across her irises, and thin faint blue subdermal lines along her jaw." + KEEP_P, [11, 23]),
})
CR_EXTRA = {1: ' The eyes become plain hard tired human eyes.', 2: ' The brass rebreather becomes a battered black iron rebreather; no censers or chains of charms.',
            3: ' The head tattoos become old burned oath brands; the red sash goes.', 5: ' The skull visor becomes a plain black iron visor.',
            6: ' The glowing eyes become plain hard tired human eyes; the brow piercings become a row of burned oath brands.'}
HG_EXTRA = {1: ' The red eye lens becomes a subtle ocular implant with blue data in the iris.', 4: ' The visor goes; the implants are subtle.',
            5: ' The chrome half-mask becomes a smooth pale grey implant plate on the left side of the face.'}
for n in range(1, 7):
    R8E['nem_voidsworn_%d' % n] = ('ncrop/nem_voidsworn_%d.png' % n, CRUSADE + CR_EXTRA.get(n, '') + KEEP, [11])
    R8E['nem_hegemony_%d' % n] = ('ncrop/nem_hegemony_%d.png' % n, HEGE + HG_EXTRA.get(n, '') + KEEP, [11])

# round 8 scar prompts per faction look (kinds and ids unchanged: porcelain is the Glasswright kind, machine the Eclipse kind)
SCAR8 = {
 'corsair': {'burn': "Add one large old healed burn to this furred creature: a patch of fur burned away on one side of the face and neck, scorched bare puckered skin beneath.",
             'cyber': "Replace one of this creature's eyes with a crude bolted-on iron plate with rivets and a small glowing red lens, raw scarred skin and torn fur round it.",
             'eye': "Add a deep old claw scar running through one of this creature's eyes from brow to muzzle, the fur parted along it; that eye is milky white and blind."},
 'ithar': {'burn': "Add an old burn scar to this being: a patch of darkened, scorched skin on one side of the face and neck where the faint light patterns are broken and dark.",
           'porcelain': "Add a web of fine cracks across this being's light-storing skin on one side of the face and neck, soft light leaking from the cracks."},
 'deathless': {'burn': "Add burn damage to this machine: one side of the violet-black plating scorched, heat-blistered and discoloured, edges melted.",
               'machine': "Tear a jagged hole in this machine's violet-black plating on one side, exposing white-gold lit circuitry and tangled cables inside, the torn edges scorched."},
}
def r8_scar_items(facs, src_dir='ncrop8'):
    out = []
    for f in facs:
        for n in range(1, 7):
            for k in KINDS[f]:
                pr = SCAR8.get(f, {}).get(k) or (SCAR[k].get(f, SCAR[k]['human']) if isinstance(SCAR[k], dict) else SCAR[k])
                out.append({'id': 'nem_%s_%d' % (f, n), 'kind': k, 'seed': 11, 'src': '%s/nem_%s_%d.png' % (src_dir, f, n),
                            'prompt': pr + (KEEP_OBJ if f == 'chorus' or (f == 'deathless' and n == 6) else KEEP)})
    return out

# Oct 31 fix pass on the round 8 sources (batches/r8f.json -> comfy_io\PORTRAITS\r8f\<id>_r8f_s11_00001_.png):
# Crusade redone from the original crops (the first pass painted gibberish writing for "names chalked" and glyph-like brands),
# the two Hullbreakers that kept a skull trophy, and the Glasswrights' pointed ears (bible 6.3: light-storing skin, second eyelid).
CRUSADE2 = ("Make this a plain unaugmented human soldier: remove any glowing eyes, implants, religious ornaments, wax seals, parchment, "
            "scripture, writing, tattoos, censers, candles, crosses, flags and skulls; plain black iron armour with a few frost-white paint "
            "stripes and no writing; pale frost scars on the exposed skin.")
GLASS_FIX = ("Remove the pointed ears: smooth rounded sides of the head with no ears. Give the pale skin faint glowing patterns of stored "
             "light along the temples and neck, and give the large dark eyes a clear glassy second eyelid.")
CR2_EXTRA = {1: ' The eyes become plain hard tired human eyes.', 2: ' The brass rebreather becomes a battered black iron rebreather.',
             3: ' The head tattoos become a smooth old burn scar; the red sash and flag go.', 5: ' The skull visor becomes a plain black iron visor.',
             6: ' The glowing eyes become plain hard tired human eyes; the brow piercings become a smooth old burn scar.'}
R8F = {'nem_voidsworn_%d' % n: ('ncrop/nem_voidsworn_%d.png' % n, CRUSADE2 + CR2_EXTRA.get(n, '') + KEEP) for n in range(1, 7)}
R8F.update({'nem_corsair_%d' % n: ('ncrop8/nem_corsair_%d.png' % n, "Replace the skull trophy on the chest with a torn piece of machinery "
            "bolted to the harness; no skulls or bones anywhere." + KEEP) for n in (3, 5)})
R8F.update({'nem_ithar_%d' % n: ('ncrop8/nem_ithar_%d.png' % n, GLASS_FIX + KEEP) for n in range(1, 7)})
R8F['aelith'] = ('r8/ithar_aelith_r8_zit_s23_00001_.png', GLASS_FIX + KEEP_P)

# Nov 1 (R64 brief): Crusade Nemesis 3's three scar edits (n8s, seed 11) came back with the plain dark background turned into
# coloured block noise and the paint style drifted. Rerun on the same source with three other seeds and a line that pins the
# background; batches/f64.json -> comfy_io\PORTRAITS\f64\.
BG_KEEP = " The smooth dark background stays exactly as it is: plain, dark and unchanged, no noise, no pattern, no pixels."
# f64 picks (Nov 1, vetoable): burn s23 (a healed burn on cheek and neck; s51 too raw), cyber s37 (fewest red vein lines), eye s23
# (a white blind eye and one scar, like the other Crusade eye scars); published with nemesis_publish.py as the s11 files.
F64_PICK = {'burn': 23, 'cyber': 37, 'eye': 23}
# f64b: the same glitch, milder, on Crusade Nemesis 2 (pixel-grid background), 4 (teal and purple flecks) and 5 (green-purple
# speckle on the hood and armour); same rerun, -> comfy_io\\PORTRAITS\\f64\\ too.
# f64b picks (Nov 1, vetoable): no block noise on any of the 27; per Nemesis the healed-looking burn, the cyber plate with the
# fewest red vein lines, and the eye scar that whitens one eye only (N4 s23 and N5 s23 whitened both). Published like f64.
F64B_PICK = {2: {'burn': 37, 'cyber': 37, 'eye': 23}, 4: {'burn': 23, 'cyber': 37, 'eye': 51}, 5: {'burn': 37, 'cyber': 37, 'eye': 37}}
def f64b_items():
    return [{'id': 'nem_voidsworn_%d' % n, 'kind': k, 'seed': sd, 'src': 'ncrop8/nem_voidsworn_%d.png' % n,
             'prompt': (SCAR[k]['human'] if isinstance(SCAR[k], dict) else SCAR[k]) + KEEP + BG_KEEP}
            for n in (2, 4, 5) for k in KINDS['voidsworn'] for sd in (23, 37, 51)]
def f64_items():
    return [{'id': 'nem_voidsworn_3', 'kind': k, 'seed': sd, 'src': 'ncrop8/nem_voidsworn_3.png', 'prompt': SCAR[k]['human'] + KEEP + BG_KEEP
             if isinstance(SCAR[k], dict) else SCAR[k] + KEEP + BG_KEEP} for k in KINDS['voidsworn'] for sd in (23, 37, 51)]

# R64 repaint (Nov 1): scars for the new Hullbreaker (void hunter) and Glasswright (living prism) Nemesis, painted on the bust crops
# of the p64 picks (comfy_io\PORTRAITS\ncrop64\, made by p64_publish.py crops). Kinds and ids unchanged (corsair burn, cyber,
# eye; ithar burn, porcelain). Two seeds each; the background line is the plain KEEP, and a seed whose background turns to block
# noise (the n8s fault) is not picked. batches/s64h.json and s64g.json -> comfy_io\PORTRAITS\s64\.
SCAR64 = {
 'corsair': {'burn': "Add one large old healed burn to this creature: on one side of the head the mane is burned away to scorched bare hide, and the bony face plates there are blackened and blistered, with puckered scar tissue between them.",
             'cyber': "Replace two of this creature's row of small eyes with a crude bolted-on iron plate with rivets and one small glowing red lens, raw scarred hide round its edges.",
             'eye': "Add a deep old claw scar running down through one of this creature's small eyes and across its bony face plates, the plates cracked and split along it; that eye is milky white and blind."},
 'ithar': {'burn': "Add an old burn scar to this being: a patch of scorched, darkened flesh on one side of the neck and throat, the glass threads there blackened and broken, the crystal on that side of the head clouded and smoky.",
           'porcelain': "Add a web of fine cracks across one side of this being's crystal head, a small chip broken out of one facet, soft light leaking from the cracks."},
}
def s64_items(fac, seeds=(11, 23)):
    return [{'id': 'nem_%s_%d' % (fac, n), 'kind': k, 'seed': sd, 'src': 'ncrop64/nem_%s_%d.png' % (fac, n),
             'prompt': SCAR64[fac][k] + (KEEP if fac == 'corsair' else KEEP_OBJ)} for n in range(1, 7) for k in KINDS[fac] for sd in seeds]

# v64 (Ryan, Nov 1 07:37: varied backgrounds and poses): the Crusade, Hegemony, Chorus and Eclipse portraits move into their own
# settings (portrait_specs.SPEC) by an edit of the approved painting, seeds 11 and 23; -> comfy_io\PORTRAITS\e64\<id>_v64_s<seed>.
# The admiral sources are their published round 8 renders, the Nemesis sources their bust crops (ncrop8).
E64_ADM = {'vex': ('voidsworn', 'r8/voidsworn_vex_r8_zit_s37_00001_.png'), 'kassar': ('hegemony', 'r8e/kassar_r8_s23_00001_.png'),
           'matriarch': ('chorus', 'r8e/matriarch_r8_s23_00001_.png'), 'mending': ('chorus', 'r8e/mending_r8_s23_00001_.png'),
           'nekhet': ('deathless', 'r8/deathless_nekhet_r8_zit_s37_00001_.png')}
def e64_items(facs, admirals=True):
    import portrait_specs as PS
    out = []
    if admirals:
        out += [{'id': a, 'kind': 'v64', 'seed': sd, 'src': src, 'prompt': PS.edit_prompt(a, f, False)}
                for a, (f, src) in E64_ADM.items() if f in facs for sd in (11, 23)]
    out += [{'id': 'nem_%s_%d' % (f, n), 'kind': 'v64', 'seed': sd, 'src': 'ncrop8/nem_%s_%d.png' % (f, n),
             'prompt': PS.edit_prompt('nem_%s_%d' % (f, n), f, True)} for f in facs for n in range(1, 7) for sd in (11, 23)]
    return out

# e64c (Nov 1, P helper 3): the e64 misses redrawn from the same sources with portrait_specs' corrected entries and its CLEAN line,
# new seeds 37 and 51 -> comfy_io\\PORTRAITS\\e64\\ (same names, so the picks just name a seed).
E64C = ['vex', 'kassar', 'nem_voidsworn_3', 'nem_voidsworn_4', 'nem_voidsworn_5', 'nem_voidsworn_6', 'nem_hegemony_5', 'nem_chorus_1',
        'nem_deathless_1', 'nem_deathless_2']
def e64c_items(seeds=(37, 51)):
    import portrait_specs as PS
    out = []
    for i in E64C:
        if i.startswith('nem_'):
            f = i.split('_')[1]; src = 'ncrop8/%s.png' % i; nem = True
        else:
            f, src = E64_ADM[i]; nem = False
        out += [{'id': i, 'kind': 'v64', 'seed': sd, 'src': src, 'prompt': PS.edit_prompt(i, f, nem) + PS.CLEAN} for sd in seeds]
    return out

# v64h4 (Nov 1, P helper 3): v64h2 has the right beast bodies, settings and poses, but the head plates paint as rusty riveted metal
# caps (the palette's "rust" and the riveted harness bleed onto the face); v64h3 (Ryan's A1 picture edited into each setting) kept
# the A1 face but gave every character a bare bodybuilder chest and the same snarl, so it is dropped. v64h4 edits the best v64h2
# render of each character so only the head plates turn to matte living horn. -> comfy_io\\PORTRAITS\\v64b\\<id>_horn_s<seed>.
H4_SRC = {'corsair_grax': 11, 'corsair_sable': 51, 'corsair_mott': 51, 'corsair_vesh': 51, 'nem_corsair_1': 11, 'nem_corsair_2': 51,
          'nem_corsair_3': 61, 'nem_corsair_4': 11, 'nem_corsair_5': 51, 'nem_corsair_6': 51}
HORN = ("Change only the head of this creature: every plate on its face and head becomes living horn, dull and matte grey-brown like a "
        "pangolin's scales or old tortoiseshell, uneven and organic, grown from the skin, with dark leathery skin in the creases between "
        "the plates. No rivets, bolts or shine on the head. Keep the same creature, pose, mane, eyes, jaw, teeth, harness, claws, setting, "
        "lighting and oil-painting style; change nothing else.")
HORN_EXTRA = {'nem_corsair_4': " Also turn the bright white moon behind it into a black disc ringed by a thin band of pale light."}
def v64h4_items(seeds=(11, 23)):
    return [{'id': t, 'kind': 'horn', 'seed': sd, 'src': 'v64b/%s_v8_s%d_oil_zi2i_s%d_00001_.png' % (t, s, s),
             'prompt': HORN + HORN_EXTRA.get(t, '') + ' The paint surface stays smooth and even, with no noise, speckle or pixels.'}
            for t, s in H4_SRC.items() for sd in seeds]

if __name__ == '__main__':
    B = os.path.join(HERE, 'batches')
    fix = [{'id': nid, 'kind': 'fix', 'seed': 11, 'prompt': p + KEEP, 'src': pick_path(nid)} for nid, p in FIXES.items()]
    json.dump({'out': 'nfix', 'budget_s': 1050, 'items': fix}, open(os.path.join(B, 'n1fix.json'), 'w'), indent=1)
    print('n1fix', len(fix))
    # scar jobs: a = Voidsworn + Hegemony minus the tail, b = the rest of the humans, c = Chorus, Ithar, Deathless (36 each at most)
    def items_for(facs):
        return [{'id': 'nem_%s_%d' % (f, n), 'kind': k, 'seed': 11, 'src': src_of(f, n), 'prompt': scar_prompt(f, k)}
                for f in facs if f in NEM_PICKS for n in range(1, 7) for k in KINDS[f]]
    human = items_for(['voidsworn', 'hegemony', 'corsair'])
    # c: Chorus only. Ithar and Deathless are on hold until Ryan signs off lore round 3 (Glasswrights, Undimmed).
    jobs = {'a': human[:27], 'b': human[27:], 'c': items_for(['chorus'])}
    for tag, part in jobs.items():
        if part:
            json.dump({'out': 'n1s', 'budget_s': 1050, 'items': part}, open(os.path.join(B, 'n1s_%s.json' % tag), 'w'), indent=1)
            print('n1s_' + tag, len(part), 'factions', sorted({i['id'].split('_')[1] for i in part}))
    # n1s_c2: the Chorus carapace rerun with the v2 prompt, two seeds, into ..\n1s_c2\ (publish takes the picked seed per Nemesis)
    c2 = [dict(it, seed=sd) for it in items_for(['chorus']) if it['kind'] == 'carapace' for sd in (11, 23)]
    json.dump({'out': 'n1s_c2', 'budget_s': 1050, 'items': c2}, open(os.path.join(B, 'n1s_c2.json'), 'w'), indent=1)
    print('n1s_c2', len(c2))
    r8e = [{'id': i, 'kind': 'r8', 'seed': sd, 'src': src, 'prompt': p} for i, (src, p, seeds) in R8E.items() for sd in seeds]
    json.dump({'out': 'r8e', 'budget_s': 1100, 'items': r8e}, open(os.path.join(B, 'r8e.json'), 'w'), indent=1)
    print('r8e', len(r8e))
    r8f = [{'id': i, 'kind': 'r8f', 'seed': 11, 'src': src, 'prompt': p} for i, (src, p) in R8F.items()]
    json.dump({'out': 'r8f', 'budget_s': 1100, 'items': r8f}, open(os.path.join(B, 'r8f.json'), 'w'), indent=1)
    print('r8f', len(r8f))
    # round 8 scars into ..\n8s\, painted on ncrop8\ (the final round 8 sources); c waits for the r8f fix pass
    allsc = r8_scar_items(['corsair', 'deathless', 'chorus', 'hegemony', 'ithar', 'voidsworn'])
    later = {'nem_corsair_3', 'nem_corsair_5'} | {'nem_ithar_%d' % n for n in range(1, 7)} | {'nem_voidsworn_%d' % n for n in range(1, 7)}
    parts = {'a': [i for i in allsc if i['id'].split('_')[1] in ('corsair', 'deathless') and i['id'] not in later],
             'b': [i for i in allsc if i['id'].split('_')[1] in ('chorus', 'hegemony')],
             'c': [i for i in allsc if i['id'] in later]}
    for tag, part in parts.items():
        json.dump({'out': 'n8s', 'budget_s': 1100, 'items': part}, open(os.path.join(B, 'r8s_%s.json' % tag), 'w'), indent=1)
        print('r8s_' + tag, len(part))
    json.dump({'out': 'f64', 'budget_s': 900, 'items': f64_items()}, open(os.path.join(B, 'f64.json'), 'w'), indent=1)
    print('f64', len(f64_items()))
    json.dump({'out': 'f64', 'budget_s': 1100, 'items': f64b_items()}, open(os.path.join(B, 'f64b.json'), 'w'), indent=1)
    print('f64b', len(f64b_items()))
    for tag, fac in (('s64h', 'corsair'), ('s64g', 'ithar')):
        json.dump({'out': 's64', 'budget_s': 1100, 'items': s64_items(fac)}, open(os.path.join(B, tag + '.json'), 'w'), indent=1)
        print(tag, len(s64_items(fac)))
    for tag, facs in (('e64a', ['voidsworn', 'hegemony']), ('e64b', ['chorus', 'deathless'])):
        json.dump({'out': 'e64', 'budget_s': 1100, 'items': e64_items(facs)}, open(os.path.join(B, tag + '.json'), 'w'), indent=1)
        print(tag, len(e64_items(facs)))
    json.dump({'out': 'e64', 'budget_s': 1100, 'items': e64c_items()}, open(os.path.join(B, 'e64c.json'), 'w'), indent=1)
    print('e64c', len(e64c_items()))
    json.dump({'out': 'v64b', 'budget_s': 1100, 'items': v64h4_items()}, open(os.path.join(B, 'v64h4.json'), 'w'), indent=1)
    print('v64h4', len(v64h4_items()))
