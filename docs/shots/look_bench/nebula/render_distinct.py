"""Run 4 sheets from actual same-board Godot captures, with native pixel crops."""
import argparse
import json
import statistics
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = Path(__file__).resolve().parent
BG = '#10141c'
INK = '#e5e9f0'


def label(sheet, xy, text, size=17):
    ImageDraw.Draw(sheet).text(xy, text, fill=INK, font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf', size))


def fit(sheet, im, box):
    im = im.copy()
    im.thumbnail(box[2:], Image.Resampling.LANCZOS)
    sheet.paste(im, (box[0] + (box[2] - im.width)//2, box[1] + (box[3] - im.height)//2))


def save(sheet, name, root):
    assert sheet.height <= 720
    for folder in (HERE, root):
        sheet.save(folder / name, quality=94)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--images-only', action='store_true', help='Compose stills before timing and hull analysis finish.')
    args = parser.parse_args()
    root = args.source
    for tier in ('max', 'high', 'low'):
        folders = [root / f'{phase}_{tier}_keep' for phase in ('before', 'after')]
        meta = [json.loads((folder/'distinct_metadata.json').read_text()) for folder in folders]
        assert meta[0]['terrain_sha256'] == meta[1]['terrain_sha256']
        assert meta[0]['centers'] == meta[1]['centers']
        pose_sets = [{row['file']: row for row in json.loads((folder/'capture_poses.json').read_text())} for folder in folders]
        for camera in (170, 60):
            for kind in ('neb', 'storm'):
                for state in ('calm', 'flash'):
                    name = f'{kind}_c{camera}_{state}.png'
                    before, after = [poses[name] for poses in pose_sets]
                    assert before['target'] == after['target']
                    for row in (before, after):
                        assert row['radius'] == camera and row['viewport'] == [1920, 1080]
                        assert abs(row['subject_screen'][0]-960) < 0.05 and abs(row['subject_screen'][1]-540) < 0.05
        for camera in (170, 60):
            sheet = Image.new('RGB', (1280, 720), BG)
            label(sheet, (12, 8), f'N368A_R4 | DISTINCT TERRAIN | {tier.upper()} | CAMERA {camera} | INSTALLED IN GAME', 21)
            label(sheet, (12, 38), 'Same seed 4207 board and lighting. Full view left in each cell, native center pixels right.', 16)
            for col, (phase, folder, record) in enumerate(zip(('RUN 3 BEFORE', 'RUN 4 AFTER'), folders, meta)):
                x = col*640+8
                label(sheet, (x, 66), f'{phase} | world {record["world_sha256"][:10]} / ion {record["ion_sha256"][:10]}', 16)
                for row, (kind, name) in enumerate((('neb', 'NEBULA: CALM'), ('storm', 'ION STORM: STRIKE'))):
                    y = 98+row*296
                    label(sheet, (x, y), name, 18)
                    im = Image.open(folder/f'{kind}_c{camera}_{"calm" if kind=="neb" else "flash"}.png').convert('RGB')
                    assert im.size == (1920, 1080)
                    fit(sheet, im, (x, y+27, 436, 245))
                    cx, cy = im.width//2, im.height//2
                    sheet.paste(im.crop((cx-90, cy-122, cx+90, cy+123)), (x+444, y+27))
            label(sheet, (12, 694), 'Actual Graphics settings: Low, High (middle), Max (top). Ryan approval pending. No terrain rules changed.', 16)
            save(sheet, f'N368A_R4_distinct_{tier}_c{camera}.jpg', root)
            if tier == 'max':
                sheet = Image.new('RGB', (1280, 720), BG)
                record = meta[1]
                label(sheet, (12, 8), f'N368A RUN 4 | NEBULA AND ION STORM | MAX C{camera} | INSTALLED IN GAME', 21)
                label(sheet, (12, 39), f'world {record["world_sha256"][:10]} / ion {record["ion_sha256"][:10]} | Same board and lighting | Approval pending', 17)
                for col, (kind, name) in enumerate((('neb', 'NEBULA: CALM PURPLE GAS'), ('storm', 'ION STORM: BLUE WEATHER AND LIGHTNING'))):
                    x = col*640+8
                    label(sheet, (x, 76), name, 18)
                    im = Image.open(folders[1]/f'{kind}_c{camera}_{"calm" if kind=="neb" else "flash"}.png').convert('RGB')
                    fit(sheet, im, (x, 108, 624, 351))
                    sheet.paste(im.crop((648, 432, 1272, 648)), (x, 470))
                label(sheet, (12, 694), 'Full camera views above. Native center pixels below. One real cruiser placed inside each generated patch.', 16)
                save(sheet, f'N368A_R4_after_c{camera}.jpg', root)
        sheet = Image.new('RGB', (1280, 720), BG)
        label(sheet, (12, 8), f'N368A_R4 | BOTH TYPES ON ONE BOARD | {tier.upper()} | C170 | INSTALLED IN GAME', 21)
        for col, (folder, record) in enumerate(zip(folders, meta)):
            x = col*640
            label(sheet, (x+8, 48), f'{"BEFORE" if col==0 else "AFTER"} | world {record["world_sha256"][:10]} / ion {record["ion_sha256"][:10]}', 17)
            im = Image.open(folder/'board_c170_flash.png').convert('RGB')
            fit(sheet, im, (x+8, 90, 624, 351))
            for kind, point in record['board_labels'].items():
                label(sheet, (x+8+int(point[0]*624/1920), 90+int(point[1]*351/1080)), 'NEBULA' if kind=='neb' else 'ION STORM', 17)
            # A wide native crop preserves both real patch centers on the board.
            sheet.paste(im.crop((648, 432, 1272, 648)), (x+8, 460))
        label(sheet, (12, 694), 'Same terrain, sky and lighting. Names mark generated patch centers. Native center crops below. Approval pending.', 16)
        save(sheet, f'N368A_R4_board_{tier}_c170.jpg', root)
    if args.images_only:
        return
    readability = []
    folder = root/'after_max_keep'
    revision = json.loads((folder/'distinct_metadata.json').read_text())
    for kind in ('neb', 'storm'):
        for camera in (170, 60):
            stem = f'{kind}_c{camera}_calm_4k'
            poses = {row['file']: row for row in json.loads((folder/'capture_poses.json').read_text())}
            assert poses[stem+'.png']['target'] == poses[stem+'_clear.png']['target']
            assert poses[stem+'_clear.png']['gas_nodes_hidden'] > 0
            gas = np.array(Image.open(folder/(stem+'.png')).convert('RGB'), dtype=float)
            clear = np.array(Image.open(folder/(stem+'_clear.png')).convert('RGB'), dtype=float)
            assert gas.shape == clear.shape == (2160,3840,3)
            mask_im = Image.open(folder/(stem+'_mask.png')).convert('L').filter(ImageFilter.MinFilter(5))
            mask = np.array(mask_im) > 240
            assert mask.sum() > 100
            lum = np.array([0.2126, 0.7152, 0.0722])
            g, c = gas[mask]@lum, clear[mask]@lum
            readability.append({'kind':kind, 'camera':camera, 'hull_pixels':int(mask.sum()),
                'contrast_retained':float(g.std()/c.std()), 'mean_luma_delta_255':float((g-c).mean()),
                'p95_rgb_difference_255':float(np.percentile(np.abs(gas[mask]-clear[mask]), 95))})
    gates = []
    for phase in ('before', 'after'):
        for case in ('nebula', 'storm'):
            for tier in (('max',) if phase=='before' else ('max','high','low')):
                file = root/f'gate_{phase}_{case}_{tier}_keep'/'scene_gate.json'
                raw = json.loads(file.read_text())
                base, four = raw['modes']['base'], raw['modes']['res_2160']
                assert raw['warmup_frames']==120 and raw['measured_frames']==720
                assert raw['renderer'] == 'forward_plus'
                assert len(base) == len(four) == (3 if tier == 'max' else 1)
                assert all(r['scaling_3d'] == 2 and r['viewport'] == [1920,1080] for r in four)
                gates.append({'phase':phase, 'case':case, 'tier':tier, 'source':str(file),
                    'frame_ms':statistics.median(r['frame_median'] for r in base),
                    'gpu_4k_ms':statistics.median(r['gpu_median'] for r in four),
                    'frame_sessions':[r['frame_median'] for r in base],
                    'gpu_sessions':[r['gpu_median'] for r in four],
                    'pass':all(r['frame_median']<=12.5 for r in base) and all(0<r['gpu_median']<=12.5 for r in four),
                    'probe_sha256':raw['probe_sha256'], 'adapter_sha256':raw['adapter_sha256']})
    assert len(gates) == 8
    assert len({row['probe_sha256'] for row in gates}) == 1
    assert len({row['adapter_sha256'] for row in gates}) == 1
    results = {'readability':readability, 'gates':gates}
    for dest in (HERE, root):
        (dest/'distinct_measurements.json').write_text(json.dumps(results,indent=2)+'\n',encoding='ascii')
    for kind in ('neb','storm'):
        frames = []
        for path in sorted(folder.glob(f'{kind}_c170_motion_*.png')):
            sheet = Image.new('RGB',(960,600),BG)
            fit(sheet,Image.open(path).convert('RGB'),(0,54,960,540))
            label(sheet,(8,3),f'N368A RUN 4 | {kind.upper()} | MAX C170 | FIXED CLOCK 12 FPS | INSTALLED IN GAME',17)
            label(sheet,(8,27),f'world {revision["world_sha256"][:10]} / ion {revision["ion_sha256"][:10]} | Approval pending',16)
            frames.append(sheet)
        if frames:
            for dest in (root, HERE):
                frames[0].save(dest/f'N368A_R4_{kind}_motion.gif',save_all=True,append_images=frames[1:],duration=83,loop=0)
    print(json.dumps(results,indent=2))


if __name__ == '__main__':
    main()
