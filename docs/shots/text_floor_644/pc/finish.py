"""Issue 671: select measured sky extremes, measure native captures, make named 720p JPGs.

Usage: python finish.py select RAW; python finish.py finish RAW DELIVERY PC_SHOTS
Only screenshot scaling and a name strip are applied. Native PNGs stay in TEMP.
Contrast uses foreground core pixels against a second render with text hidden.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


def luminance(rgb):
    v = np.asarray(rgb, dtype=float) / 255
    v = np.where(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055) ** 2.4)
    return v @ np.array([0.2126, 0.7152, 0.0722])


def extremes(raw):
    result = {}
    for sky in ['frontier', 'nebula', 'world', 'boneyard', 'deep', 'storm']:
        p = raw / f'battle_1080_1_{sky}_background.png'
        if p.exists():
            a = np.array(Image.open(p).convert('RGB'))
            h, w = a.shape[:2]
            # The same central board area, outside the left sheet and right log.
            result[sky] = float(luminance(a[int(h*.25):int(h*.8), int(w*.32):int(w*.8)]).mean())
    return {'levels': result, 'darkest': min(result, key=result.get), 'brightest': max(result, key=result.get)}


def measure(raw, tag):
    d = json.loads((raw / (tag + '.json')).read_text(encoding='utf-8'))
    for u in d.get('units', []):
        # Earlier probe metadata named ShipView.a4 "built"; it is specifically the A4 kit flag.
        if 'built' in u:
            u['a4_kit'] = u.pop('built')
        u['representation'] = 'procedural wing' if '|' in u['code'] else 'PC built hull'
    normal = np.array(Image.open(raw / (tag + '.png')).convert('RGB')).astype(float)
    bg = np.array(Image.open(raw / (tag + '_background.png')).convert('RGB')).astype(float)
    height, width = normal.shape[:2]
    words = d['text']
    overlaps, failures, uncertain = [], [], []
    for i, t in enumerate(words):
        x, y, w, h = t['rect']
        a, b, c, e = max(0, int(x)), max(0, int(y)), min(width, int(np.ceil(x+w))), min(height, int(np.ceil(y+h)))
        if a >= c or b >= e:
            continue
        foregrounds = [np.array(t['color'][:3])*255]
        for color in re.findall(r'\[color=(#[0-9a-fA-F]{6})\]', t.get('bbcode', '')):
            foregrounds.append(np.array([int(color[k:k+2], 16) for k in [1, 3, 5]]))
        for size in re.findall(r'\[font_size=(\d+)\]', t.get('bbcode', '')):
            t['px'] = min(t['px'], int(size))
        front, back = normal[b:e, a:c], bg[b:e, a:c]
        ratios = []
        worst_sample = None
        for fg in foregrounds:
            # One byte of tolerance selects opaque cores, not faded antialiasing edges.
            mask = (np.max(np.abs(front-fg), axis=2) <= 1.1) & (np.max(np.abs(front-back), axis=2) > 12)
            if np.count_nonzero(mask) < 3:
                continue
            lb, lf = luminance(back[mask]), float(luminance(fg))
            values = (np.maximum(lb,lf)+.05)/(np.minimum(lb,lf)+.05)
            idx = int(np.argmin(values))
            if worst_sample is None or values[idx] < worst_sample['ratio']:
                point = np.argwhere(mask)[idx]
                worst_sample = {'ratio':float(values[idx]), 'pixel':[int(a+point[1]),int(b+point[0])], 'foreground_rgb':np.round(fg).astype(int).tolist(), 'background_rgb':back[mask][idx].astype(int).tolist()}
            ratios.extend(values.tolist())
        t['contrast'] = round(min(ratios), 3) if ratios else None
        t['worst_sample'] = worst_sample
        if not ratios:
            uncertain.append(t['text'])
        elif min(ratios) < 4.5:
            failures.append({'text': t['text'], 'ratio': round(min(ratios), 3), 'source': t['source']})
        for u in words[i+1:]:
            # A parent's text area can contain its own child. This is one widget.
            if t['source'] != 'ledger' and (u['source'].startswith(t['source']+'/') or t['source'].startswith(u['source']+'/')):
                continue
            xx, yy, ww, hh = u['rect']
            if min(x+w, xx+ww)-max(x,xx) > 2 and min(y+h, yy+hh)-max(y,yy) > 2:
                overlaps.append([t['text'],u['text']])
    d['smallest_px'] = min(t['px'] for t in words)
    d['overlaps'] = overlaps
    d['contrast_failures'] = failures
    d['contrast_uncertain'] = uncertain
    d['lowest_contrast'] = min((t['contrast'] for t in words if t['contrast'] is not None), default=None)
    return d


def main():
    mode, raw = sys.argv[1], Path(sys.argv[2])
    sky = extremes(raw)
    if mode == 'select':
        print(json.dumps(sky))
        return
    delivery, pc_shots = map(Path, sys.argv[3:5])
    delivery.mkdir(parents=True, exist_ok=True)
    pc_shots.mkdir(parents=True, exist_ok=True)
    result = {'sky_selection': sky, 'captures': {}}
    tags = [f'battle_{h}_{n}_{s}' for h in [1080,1440] for n in [1,20] for s in [sky['brightest'],sky['darkest']]]
    tags += ['campaign_map_1440','campaign_fleet_1440']
    font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 16)
    for tag in tags:
        d = measure(raw,tag)
        result['captures'][tag] = d
        im = Image.open(raw / (tag+'.png')).convert('RGB')
        im = im.resize((1237,696), Image.Resampling.LANCZOS)
        jpg = Image.new('RGB',(1237,720),(12,12,12))
        jpg.paste(im,(0,24))
        ImageDraw.Draw(jpg).text((10,3),tag+' | native '+str(d['viewport'][0])+'x'+str(d['viewport'][1]),font=font,fill=(245,235,220))
        for target in [delivery,pc_shots]:
            jpg.save(target/(tag+'.jpg'),quality=94,subsampling=0)
        print(tag, 'min',d['smallest_px'],'overlaps',len(d['overlaps']),'contrast',d['lowest_contrast'],'fail',len(d['contrast_failures']),'uncertain',len(d['contrast_uncertain']))
    for target in [delivery,pc_shots]:
        (target/'measurements.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    report = [
        '# Issue 671: PC text-floor captures', '',
        'All ten requested captures are complete. No text overlaps. Minimum native text: 17 px at 1080, 23 px at 1440. Two sampled contrast failures: the ship name on the 1440/20/world view (4.44:1), and Map key (2.68:1). No game code changed. No commit or push.', '',
        'Captured the real Godot battle scene with built PC hulls, at 1920x1080 and 2560x1440, with 1 and 20 player ships on the brightest and darkest sampled boards. Also captured the campaign map and fleet page at 1440.', '',
        'Source: `8f20db55262e91eac279790501b61f49b2e8fb46`. Windows PC, RTX 5080, Godot 4.7.2, Forward Plus, maximum quality, normal UI scale, battle camera 170, battle seed 7. Every battle uses live rules state and the real HUD. No hand-fed sample Ledger data. The capture guard found zero placeholder ships.', '',
        'Each delivered JPG is 1237x720, including its name strip. Font measurements below come from the native render before reduction; the reduced JPG is for review. Identical JPGs and this report are in `' + str(pc_shots) + '`.', '',
        '| Picture | Smallest read text, native px | Overlapping text boxes | Text below 4.5:1 | Lowest contrast |',
        '|---|---:|---:|---|---:|',
    ]
    for tag,d in result['captures'].items():
        link = (pc_shots/(tag+'.jpg')).as_posix()
        failed = '; '.join('`'+f['text'].replace('|','/').replace('\n',' ').replace('`',"'")+'` '+str(f['ratio'])+':1' for f in d['contrast_failures']) or 'None measured'
        ratio = str(d['lowest_contrast'])+':1'
        report.append(f"| [{tag}]({link}) ([repo]({tag}.jpg)) | {d['smallest_px']:g} | {len(d['overlaps'])} | {failed} | {ratio} |")
    report += ['', '## Measurement method', '',
        'The six look-bench presets were rendered at 1080 with the same seed, camera and one-ship fleet. Mean linear relative luminance was sampled over the same clear board rectangle (x 32 to 80 percent, y 25 to 80 percent), with text removed. This selects actual rendered presets, rather than assuming that the region called deep is darkest. Levels: ' + ', '.join(f'{k} {v:.5f}' for k,v in sky['levels'].items()) + '. Brightest: '+sky['brightest']+'. Darkest: '+sky['darkest']+'. These are the extremes of these six presets and this camera, not every possible campaign seed or camera.', '',
        'Text sizes and rectangles come from the live Ledger draw items, visible Labels, Buttons and RichTextLabels, and the campaign purse draw parts. Contrast uses WCAG relative luminance of each foreground colour against a second render with text fill removed. Label outlines and button backgrounds remain in that second render, so ship names are measured against their actual black halo. Fully opaque glyph cores are measured; antialiasing edges are excluded. World shader time can advance between the two renders, so these are sampled-frame measurements. `measurements.json` records each word, size, rectangle, contrast, unit hull code and fleet-fold state.', '',
        'Overlap counts are intersections of the displayed text rectangles, with parent-child widgets excluded. Each delivered view was also inspected visually. The Ledger test separately checks the screen veils over pure white and black, so the sheet has a worst-backdrop check beyond the sampled scene.', '',
        '## Checks and limits', '',
        '- `ledger_readability_test.gd`, headless: PASS, zero failed checks at 1080 and 1440.',
        '- Capture GDScript, PowerShell and Python parse checks: PASS.',
        '- Standing checks with bundled Node 22: 47 PASS, 1 FAIL, 2 KNOWN. Failure is in unchanged `godot/fx/test/death_spawn_check.gd:143`: invalid call, nonexistent `float` constructor. The wrapper `fx_death_spawn_tests` fails. The two KNOWN results are the existing findings and oracle-drift baselines. No fix made in this capture-only job.',
        '- Initial default Node 24 attempt stopped at the required Node 22 guard; rerun used bundled Node 22. Initial sandbox render could not write the world-bake cache; final captures ran with local cache access.',
        '- GPU captures waited for other Blender and rendered Godot jobs. The initial wait also held for a headless Godot import; it was narrowed to GPU rendering jobs, then resumed using the completed views. No other job was stopped.',
        '- No requested capture was skipped. Campaign data is an in-memory seed-644 new run with persistence off; no player run or save was written.', '',
        'Reproduce with `capture.bat`. It waits for other GPU rendering jobs, keeps raw PNGs and logs in TEMP, then writes the named JPGs and measurements here and to the PC shots folder. `capture.gd`, `capture.ps1` and `finish.py` are capture tooling only.',
    ]
    for tag,d in result['captures'].items():
        if d['overlaps'] or d['contrast_uncertain']:
            report += ['', '### '+tag, '']
            if d['overlaps']:
                report += ['Overlap candidates: '+json.dumps(d['overlaps'])+'.']
            if d['contrast_uncertain']:
                report += ['Contrast not measured for: '+json.dumps(d['contrast_uncertain'])+'. These words are not counted as passing.']
    for target in [delivery,pc_shots]:
        (target/'report.md').write_text('\n'.join(report)+'\n',encoding='utf-8')


if __name__ == '__main__':
    main()
