"""Encode the existing R01 bake for the PC pack job. No downloads or deletion."""
import hashlib
import io
import json
import os
from pathlib import Path
import time

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
DEST = ROOT / 'godot/world/rocks/r01'
RAW = Path(os.environ['TEMP']) / 'voidsworn_issue369_sources/r01_remix'
ENCODED = RAW / 'webp'


def run():
    started = time.perf_counter()
    ENCODED.mkdir(exist_ok=True)
    meta = json.loads((DEST / 'bake.json').read_text())
    meta['files'] = {}
    meta['storage'] = 'WebP payloads inside Godot Resources; sixteen tiles per 8K map'
    meta['pack_script'] = 'tools/pc/jobs/planet369_pack.py and planet369_pack.gd'
    meta['pixel_loss'] = ('Colour: WebP quality 90. Height: rounded to 11 bits, '
                          'maximum 16/65535 error. Roughness and clouds: rounded '
                          'to six bits, maximum 2/255 error. No spatial reduction.')
    for name in ['colour', 'relief', 'roughness']:
        original = Image.open(RAW / (name + '.png'))
        assert original.size == (8192, 4096)
        pixels = np.array(original)
        if name == 'relief':
            h = pixels[:, :, 0].astype(np.uint32) * 256 + pixels[:, :, 1]
            h = np.minimum((h + 16) // 32 * 32, 65535)
            pixels[:, :, 0], pixels[:, :, 1] = h >> 8, h & 255
            pixels[:, :, 2:] = np.minimum((pixels[:, :, 2:].astype(np.uint16) + 2) // 4 * 4, 255)
        elif name == 'roughness':
            pixels = np.minimum((pixels.astype(np.uint16) + 2) // 4 * 4, 255).astype(np.uint8)
        image = Image.fromarray(pixels)
        decoded = Image.new('RGB' if name == 'colour' else 'RGBA' if name == 'relief' else 'L', image.size)
        desc = {'size': list(image.size), 'format': {'colour': 4, 'relief': 5, 'roughness': 0}[name],
                'encoding': 'webp_resource_v1', 'tiles': []}
        for y in range(4):
            for x in range(4):
                tile = image.crop((x*2048, y*1024, (x+1)*2048, (y+1)*1024))
                data = io.BytesIO()
                tile.save(data, format='WEBP', lossless=name != 'colour', quality=90, method=4, exact=True)
                file = f'{name}_{x}_{y}'
                (ENCODED / (file + '.webp')).write_bytes(data.getvalue())
                reconstructed = Image.open(io.BytesIO(data.getvalue())).convert(decoded.mode)
                if name != 'colour':
                    assert reconstructed.tobytes() == tile.tobytes(), file
                decoded.paste(reconstructed, (x*2048, y*1024))
                desc['tiles'].append({'file': file + '.res', 'x': x*2048, 'y': y*1024, 'size': [2048, 1024]})
        desc['pixel_sha256'] = hashlib.sha256(decoded.tobytes()).hexdigest()
        desc['source_pixel_sha256'] = hashlib.sha256(original.tobytes()).hexdigest()
        a, b = np.array(original).astype(np.int32), np.array(decoded).astype(np.int32)
        desc['max_channel_error'] = np.abs(a-b).reshape(-1, 1 if a.ndim == 2 else a.shape[2]).max(axis=0).tolist()
        if name == 'relief':
            desc['max_height_error_steps'] = int(np.abs((a[:,:,0]*256+a[:,:,1])-(b[:,:,0]*256+b[:,:,1])).max())
            desc['height_error_note'] = 'RG is one 16-bit value. Low-byte differences include carries; compare decoded height.'
            assert desc['max_height_error_steps'] <= 16
        (DEST / (name + '.json')).write_text(json.dumps(desc, indent=2)+'\n', encoding='ascii')
        print('R01_ENCODE', name, desc['max_channel_error'], flush=True)
    meta['cold_encode_seconds'] = time.perf_counter()-started
    (DEST / 'bake.json').write_text(json.dumps(meta, indent=2)+'\n', encoding='ascii')


if __name__ == '__main__':
    run()
