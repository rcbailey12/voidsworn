# Builds the Qwen-Image-Edit job lists for the Nemesis pool (run with portrait_edit.py on the PC):
#   batches/n1fix.json      fixes to picked renders (caps the prompt said not to draw, a lookalike helmet), into comfy_io\PORTRAITS\nfix\
#   batches/n1s_a/b/c.json  the painted first scar for every picked Nemesis and every scar kind its faction can take, into ..\n1s\
# The picks (which render seed is the pool portrait) live in NEM_PICKS; a fixed render replaces its pick as the source.
# Run: python3 tools/portraits/make_edits.py
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
KEEP = " Keep the same character, face, pose, clothing, lighting, background and painting style; change nothing else."
# pool picks (Oct 26 review): faction -> seed per Nemesis 1..6; folder n1 (first renders) or n2 (Chorus, Deathless, Ithar reruns)
NEM_PICKS = {
 'voidsworn': ('n1', [23, 11, 11, 11, 11, 23]),
 'hegemony':  ('n1', [23, 23, 23, 23, 11, 11]),
 'corsair':   ('n1', [23, 11, 23, 11, 23, 11]),
}
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
 'carapace': "Crack this organism open on one side: a wide jagged split in its dark shell with glowing sickly yellow ooze and raw pink tissue showing in the gaps, cracks spreading outward from it.",
 'porcelain': "Add a web of cracks across this being's porcelain skin on one side of the head and neck, golden light leaking from the cracks, a small chip of skin missing.",
 'machine': "Tear a jagged hole in this machine's plating on one side, exposing green-lit circuitry and tangled cables inside, the torn metal edges scorched.",
}
KINDS = {'voidsworn': ['burn', 'cyber', 'eye'], 'hegemony': ['burn', 'cyber', 'eye'], 'corsair': ['burn', 'cyber', 'eye'],
         'chorus': ['burn', 'carapace'], 'ithar': ['burn', 'porcelain'], 'deathless': ['burn', 'machine']}

def src_of(fac, n):
    folder, seeds = NEM_PICKS[fac]; nid = 'nem_%s_%d' % (fac, n)
    if nid in FIXES: return 'nfix/%s_fix_s11_00001_.png' % nid
    return '%s/%s_zit_s%d_00001_.png' % (folder, nid, seeds[n - 1])

def scar_prompt(fac, k):
    s = SCAR[k]
    if isinstance(s, dict): s = s.get(fac, s['human'])
    return s + KEEP

if __name__ == '__main__':
    B = os.path.join(HERE, 'batches')
    fix = [{'id': nid, 'kind': 'fix', 'seed': 11, 'prompt': p + KEEP,
            'src': '%s/%s_zit_s%d_00001_.png' % (NEM_PICKS[nid.split('_')[1]][0], nid, NEM_PICKS[nid.split('_')[1]][1][int(nid[-1]) - 1])}
           for nid, p in FIXES.items()]
    json.dump({'out': 'nfix', 'budget_s': 1050, 'items': fix}, open(os.path.join(B, 'n1fix.json'), 'w'), indent=1)
    print('n1fix', len(fix))
    ready = [f for f in KINDS if f in NEM_PICKS]
    items = [{'id': 'nem_%s_%d' % (f, n), 'kind': k, 'seed': 11, 'src': src_of(f, n), 'prompt': scar_prompt(f, k)}
             for f in ready for n in range(1, 7) for k in KINDS[f]]
    third = (len(items) + 2) // 3
    for j, tag in enumerate('abc'):
        part = items[j * third:(j + 1) * third]
        if part:
            json.dump({'out': 'n1s', 'budget_s': 1050, 'items': part}, open(os.path.join(B, 'n1s_%s.json' % tag), 'w'), indent=1)
            print('n1s_' + tag, len(part), 'factions', sorted({i['id'].split('_')[1] for i in part}))
