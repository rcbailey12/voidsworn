"""Refs #975. Native-pixel close crops and concept comparisons, stamped."""
import json
from pathlib import Path
import shutil
import sys
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPO/'tools'))
from picture_provenance import Review


def label(image, title, subtitle):
    draw = ImageDraw.Draw(image)
    draw.rectangle((0,0,image.width,80), fill='#10161d')
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
    small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    draw.text((18,10),title,fill='#e8e3d8',font=font)
    draw.text((18,45),subtitle,fill='#b8c8d8',font=small)


def main():
    raw, out = map(Path, sys.argv[1:3])
    report = json.loads((raw/'production_captures.json').read_text())
    concept = REPO/'contrib/muse/design/station_concept_2026_11/station_T2_beauty.jpg'
    for name, title in [('docking','DOCKING ARM END'),('habitat','HABITAT WINDOW BANDS'),('arrays','TOWER ARRAYS')]:
        review = Review('installed in game')
        src = review.open(raw/('station_T2_closest_'+name+'.png'))
        # No resizing: one image pixel is one native 1920x1080 render pixel.
        image = src.crop((0,180,1920,900)).convert('RGB')
        label(image,'station_T2 | CLOSEST BATTLE CAMERA / '+title,
              'Radius %g | Native 1080p pixels, 1:1 crop | %s cruiser crop at the same depth' %
              (report['closest_radius'], report['cruiser_code']))
        review.save(image,out/('station_T2_closest_'+name+'.png'))
    for radius in (170,60):
        review = Review('installed in game')
        capture = review.open(raw/('station_T2_camera'+str(radius)+'.png'))
        ref = review.open(concept,reference=True).convert('RGB')
        sheet = Image.new('RGB',(1280,720),'#080c12')
        left = capture.convert('RGB').resize((768,432),Image.Resampling.LANCZOS)
        right = ref.resize((512,375),Image.Resampling.LANCZOS)
        sheet.paste(left,(0,115))
        sheet.paste(right,(768,145))
        label(sheet,'station_T2 | CAMERA '+str(radius)+' / INSTALLED PAINT BESIDE ACCEPTED CONCEPT',
              'Left: game lighting and C15s_23 cruiser | Right: accepted T2 beauty, direction matched by eye')
        review.save(sheet,out/('station_T2_compare'+str(radius)+'.png'))
    shutil.copy2(raw/'production_captures.json',out/'production_captures.json')
    print('T2 PICTURES PASS: three native crops, two concept comparisons')


if __name__ == '__main__': main()
