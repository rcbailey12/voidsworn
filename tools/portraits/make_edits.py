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
