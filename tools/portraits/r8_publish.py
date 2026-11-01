# Round 8 admiral paintings (lore approved Oct 27, R59): picked renders and restyles -> godot/portraits/painted/<id>.webp.
#   python3 tools/portraits/r8_publish.py <render_root>        render_root holds r8\, r8e\ and r8f\ as on the PC
# The round 7 painting each one replaces is kept as alts/<id>_r7.webp. Picks are vetoable calls (Oct 31 review).
import os, sys, json, shutil
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from post import framed, PD
PICKS = {
 'vex': ('voidsworn', 'r8/voidsworn_vex_r8_zit_s37_00001_.png', ['r8/voidsworn_vex_r8_zit_s23_00001_.png'],
         'Fresh r8c repaint: frost-scarred, implant-removal scars, black iron void-coat, ember radiator spires outside. The restyle edits kept wax seals or drew a sailing ship and lettering; the Qwen takes put naval-looking ships in the window.'),
 'kassar': ('hegemony', 'r8e/kassar_r8_s23_00001_.png', ['r8e/kassar_r8_s11_00001_.png'], 'Restyle of the round 7 painting: blue temple port, data in the iris.'),
 'grax': ('corsair', 'r8/corsair_grax_r8_qie_s11_00001_.png', ['r8/corsair_grax_r8_zit_s11_00001_.png'],
          'Bear-heavy, wolf-jawed, matted fur, chain harness, eyeshine. The Z-Image takes read as werewolves in power armour and two carried skull trophies.'),
 'aelith': ('ithar', 'r8f/aelith_r8f_s11_00001_.png', ['r8/ithar_aelith_r8_qie_s11_00001_.png'],
            'Glasswright: long neck, large dark eyes, light-storing skin patterns, crystal and mirror-thread robe, light-core in hand; pointed ears removed in the r8f pass.'),
 'nekhet': ('deathless', 'r8/deathless_nekhet_r8_zit_s37_00001_.png', ['r8/deathless_nekhet_r8_zit_s23_00001_.png'],
            'The broken ring mind (Nadir Aurex, Ninth Frame): violet-black plates round a white-gold core, repair drones. The Qwen recolour of the round 7 ring kept a green circuit background.'),
 'matriarch': ('chorus', 'r8e/matriarch_r8_s23_00001_.png', ['r8e/matriarch_r8_s11_00001_.png'], 'Round 7 painting recoloured: olive flesh, ochre chitin, bile light.'),
 'mending': ('chorus', 'r8e/mending_r8_s23_00001_.png', ['r8e/mending_r8_s11_00001_.png'], 'Round 7 painting recoloured: olive flesh, ochre bone needles, bile light.'),
}
def main(root):
    idx_path = os.path.join(PD, 'index.json'); idx = json.load(open(idx_path))
    for adm, (fac, pick, alts, note) in PICKS.items():
        old = os.path.join(PD, 'painted', adm + '.webp')
        if os.path.exists(old) and not os.path.exists(os.path.join(PD, 'alts', adm + '_r7.webp')):
            shutil.copyfile(old, os.path.join(PD, 'alts', adm + '_r7.webp'))
        framed(Image.open(os.path.join(root, pick)), fac).save(old, 'WEBP', quality=88, method=6)
        A = []
        for n, a in enumerate(alts):
            fn = 'alts/%s_r8alt%d.webp' % (adm, n + 1); framed(Image.open(os.path.join(root, a)), fac).save(os.path.join(PD, fn), 'WEBP', quality=80, method=6); A.append(fn)
        A.append('alts/%s_r7.webp' % adm)
        idx['painted'][adm] = {'faction': fac, 'pick': 'painted/%s.webp' % adm, 'alts': A, 'source': pick, 'alt_sources': alts, 'note': note}
        print('published', adm)
    json.dump(idx, open(idx_path, 'w'), indent=1)
if __name__ == '__main__':
    main(sys.argv[1])
