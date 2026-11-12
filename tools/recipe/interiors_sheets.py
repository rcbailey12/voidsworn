# Issue 557: label and arrange real Godot captures without rescaling their pixels.
# python interiors_sheets.py SHOTS (contains legacy/authored/moved_*_camera*.png)
import os, sys
from PIL import Image, ImageDraw, ImageFont

out = sys.argv[1]
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 22)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 17)

def sheet(radius, names, title, filename):
    canvas = Image.new('RGB', (1280, 720), '#10151e'); draw = ImageDraw.Draw(canvas)
    draw.text((20, 8), title, font=font, fill='#e4e9ed')
    for col, (tag, label) in enumerate(names):
        draw.text((col * 640 + 16, 43), label, font=font, fill='#b7cfe2')
        for row, stage in enumerate(('wound', 'death')):
            im = Image.open(os.path.join(out, f'{tag}_{stage}_camera{radius}.png')).convert('RGB')
            # Equal central crops, 1:1 pixels. The complete 1280x720 originals stay alongside this sheet.
            crop = im.crop((320, 220, 960, 520))
            canvas.paste(crop, (col * 640, 80 + row * 306))
    draw.text((16, 689), 'C15s_23 / Ab8 export fixture. Top: opened section. Bottom: death. Equal crops, original pixels.', font=small, fill='#c4cbd5')
    canvas.save(os.path.join(out, filename))

for radius in (170, 60):
    sheet(radius, [('legacy', 'Before: #167 runtime fallback'), ('authored', 'After: authored decks, frames, test machinery')],
          f'Issue 557 / same breaking ship / camera {radius}', f'comparison_camera{radius}.png')
sheet(60, [('authored', 'Original seam: x -0.125'), ('moved', 'Blender seam moved to x -0.225')],
      'Issue 557 / authored joint moved 0.10 ship units / camera 60', 'seam_moved_camera60.png')
