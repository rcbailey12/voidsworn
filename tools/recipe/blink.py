
# Issue 889: keep source revisions through crops and sheet composition.
import sys
from pathlib import Path as _PicturePath
sys.dont_write_bytecode = True
sys.path.insert(0, str(next(p for p in _PicturePath(__file__).resolve().parents if (p / 'tools/picture_provenance.py').is_file()) / 'tools'))
from picture_provenance import Review
PICTURES = Review('paint proof')

# Ship recipe: the blink sheet (outside audit pass 2, finding 13; FINDINGS R160). Ryan judges the bow by flipping the concept
# and the model at the same fitted concept camera, so a wrong front cannot hide in a single still. Round 7 made this by hand in
# tools/blender/r209/sheets7pc.py; this is the same sheet as a standing stage for every ship.
# usage: python blink.py CONCEPT.png MODEL.png OUT.gif [ms]
#   CONCEPT.png  the concept as the camera sees it (stage 1 or 3 writes it)
#   MODEL.png    the model at the same concept camera (stage 5 render.py writes <cell>_concept_cl.png)
# Writes two frames, concept then model, at the same 1024 px size, alternating every ms (default 700).
import os, sys
try:
    from PIL import Image
except ImportError:
    print('blink FAIL: Pillow is missing (run stage 3 once, it installs Pillow into Blender\'s python)')
    sys.exit(1)

def main(src_concept, src_model, out, ms=700):
    for p in (src_concept, src_model):
        if not os.path.exists(p):
            print(f'blink FAIL: missing {p}')
            return 1
    frames = []
    for p in (src_concept, src_model):
        im = PICTURES.open(p, reference=(p == src_concept)).convert('RGBA')
        bg = Image.new('RGBA', im.size, (14, 15, 18, 255))
        bg.alpha_composite(im)
        frames.append(bg.convert('RGB').resize((1024, 1024), Image.LANCZOS))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    PICTURES.save(frames[0], out, save_all=True, append_images=[frames[1]], duration=int(ms), loop=0)
    print('blink PASS', out, 'concept and model alternating at 1024 px')
    return 0

if __name__ == '__main__':
    a = sys.argv[1:]
    if len(a) < 3:
        print('usage: python blink.py CONCEPT.png MODEL.png OUT.gif [ms]')
        sys.exit(1)
    sys.exit(main(a[0], a[1], a[2], a[3] if len(a) > 3 else 700))
